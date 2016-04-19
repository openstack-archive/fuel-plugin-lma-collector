-- Copyright 2015 Mirantis, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
require 'cjson'
require 'os'
require 'string'
require 'table'
local field_util = require 'field_util'
local utils = require 'lma_utils'
local l = require 'lpeg'
l.locale(l)

local flush_count = read_config('flush_count') or 100
local flush_interval = read_config('flush_interval') or 5
local default_tenant_id = read_config("default_tenant_id")
local default_user_id = read_config("default_user_id")
local time_precision = read_config("time_precision")

-- the tag_fields parameter is a list of tags separated by spaces
local tag_grammar = l.Ct((l.C((l.P(1) - l.P" ")^1) * l.P" "^0)^0)
local tag_fields = tag_grammar:match(read_config("tag_fields") or "")

local defaults = {
    tenant_id=default_tenant_id,
    user_id=default_user_id,
}
local last_flush = os.time()
local datapoints = {}

function escape_string(str)
    return tostring(str):gsub("([ ,])", "\\%1")
end

-- Flush the datapoints to InfluxDB if enough items are present or if the
-- timeout has expired
function flush ()
    local now = os.time()
    if #datapoints > 0 and (#datapoints > flush_count or now - last_flush > flush_interval) then
        datapoints[#datapoints+1] = ''
        utils.safe_inject_payload("txt", "influxdb", table.concat(datapoints, "\n"))

        datapoints = {}
        last_flush = now
    end
end

-- Return the Payload field decoded as JSON data, nil if the payload isn't a
-- valid JSON string
function decode_json_payload()
    local ok, data = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        return
    end

    return data
end

function process_single_metric()
    local tags = {}
    local name = read_message("Fields[name]")
    local value

    if not name then
        return 'Fields[name] is missing'
    end

    if read_message('Fields[value_fields]') then
        value = {}
        local i = 0
        local val
        while true do
            local f = read_message("Fields[value_fields]", 0, i)
            if not f then
                break
            end
            val = read_message(string.format('Fields[%s]', f))
            if val ~= nil then
                value[f] = val
                i = i + 1
            end
        end
        if i == 0 then
           return 'Fields[value_fields] does not list any valid field'
        end
    else
        value = read_message("Fields[value]")
        if not value then
            return 'Fields[value] is missing'
        end
    end

    -- collect Fields[tag_fields]
    local i = 0
    while true do
        local t = read_message("Fields[tag_fields]", 0, i)
        if not t then
            break
        end
        tags[t] = read_message(string.format('Fields[%s]', t))
        i = i + 1
    end

    encode_datapoint(name, value, tags)
end

function process_bulk_metric()
    -- The payload contains a list of datapoints, each point being formatted
    -- like this: {name='foo',value=1,tags={k1=v1,...}}
    local datapoints = decode_json_payload()
    if not datapoints then
        return 'Invalid payload value'
    end

    for _, point in ipairs(datapoints) do
        encode_datapoint(point.name, point.value, point.tags or {})
    end
end

function encode_scalar_value(value)
    if type(value) == "number" then
        -- Always send numbers as formatted floats, so InfluxDB will accept
        -- them if they happen to change from ints to floats between
        -- points in time.  Forcing them to always be floats avoids this.
        return string.format("%.6f", value)
    elseif type(value) == "string" then
        -- string values need to be double quoted
        return '"' .. value:gsub('"', '\\"') .. '"'
    elseif type(value) == "boolean" then
        return '"' .. tostring(value) .. '"'
    end
end

function encode_value(value)
    if type(value) == "table" then
        local values = {}
        for k,v in pairs(value) do
            table.insert(
                values,
                string.format("%s=%s", escape_string(k), encode_scalar_value(v))
            )
        end
        return table.concat(values, ',')
    else
        return "value=" .. encode_scalar_value(value)
    end
end

-- encode a single datapoint using the InfluxDB line protocol
--
-- name:  the measurement's name
-- value: a scalar value or a list of key-value pairs
-- tags:  a table of tags
--
-- Timestamp is taken from the Heka message
function encode_datapoint(name, value, tags)
    if type(name) ~= 'string' or value == nil or type(tags) ~= 'table' then
        -- fail silently if any input parameter is invalid
        return
    end

    local ts
    if time_precision  and time_precision ~= 'ns' then
        ts = field_util.message_timestamp(time_precision)
    else
        ts = read_message('Timestamp')
    end

    -- Add the common tags
    for _, t in ipairs(tag_fields) do
        tags[t] = read_message(string.format('Fields[%s]', t)) or defaults[t]
    end

    local tags_array = {}
    for k,v in pairs(tags) do
        if k ~= '' and v ~= '' then
            -- empty tag name and value aren't allowed
            table.insert(tags_array, escape_string(k) .. '=' .. escape_string(v))
        end
    end
    -- for performance reasons, it is recommended to always send the tags
    -- in the same order.
    table.sort(tags_array)

    if #tags_array > 0 then
        point = string.format("%s,%s %s %d",
            escape_string(name),
            table.concat(tags_array, ','),
            encode_value(value),
            ts)
    else
        point = string.format("%s %s %d",
            escape_string(name),
            encode_value(value),
            ts)
    end

    datapoints[#datapoints+1] = point
end

function process_message()
    local err_msg
    local msg_type = read_message("Type")
    if msg_type:match('bulk_metric$') then
        err_msg = process_bulk_metric()
    else
        err_msg = process_single_metric()
    end

    flush()

    if err_msg then
        return -1, err_msg
    else
        return 0
    end
end

function timer_event(ns)
    flush()
end
