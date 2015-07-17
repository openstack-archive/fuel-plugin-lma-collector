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
local field_util = require 'field_util'
local string = require 'string'
local table = require 'table'
local l = require 'lpeg'
l.locale(l)

-- tag_fields is a list of tags separated by spaces
local tag_grammar = l.Ct((l.C((l.P(1) - l.P" ")^1) * l.P" "^0)^0)
local tag_fields = tag_grammar:match(read_config("tag_fields") or "")

local default_tenant_id = read_config("default_tenant_id") or error("default_tenant_id must be specified")
local default_user_id = read_config("default_user_id") or error("default_user_id must be specified")

local defaults = {
    tenant_id=default_tenant_id,
    user_id=default_user_id,
}

function escape_string(str)
    return tostring(str):gsub("([ ,])", "\\%1")
end

function encode_tag(tag, default_value)
    local value = read_message(string.format('Fields[%s]', tag))

    if not value or value == '' then
        if default_value ~= nil then
            value = default_value
        else
            return nil
        end
    end

    return escape_string(tag) .. '=' .. escape_string(value)
end

-- TODO(pasquier-s): support messages with multiple points
-- TODO(pasquier-s): support points with multiple fields
function process_message()
    local point
    local tags = {}
    local value = read_message("Fields[value]")
    -- Fields[tag_fields] is expected to be a table
    local msg_tag_fields = read_message("Fields[tag_fields]") or {}

    if value == nil then
        return -1
    end

    -- Add common tags
    for _, tag in ipairs(tag_fields) do
        local t = encode_tag(tag, defaults[tag])
        if t then
            table.insert(tags, t)
        end
    end

    -- Add specific tags
    for _, tag in ipairs(msg_tag_fields) do
        local t = encode_tag(tag)
        if t then
            table.insert(tags, t)
        end
    end

    -- Encode the value field
    if type(value) == "string" then
        -- string values need to be double quoted
        value = '"' .. value:gsub('"', '\\"') .. '"'
    elseif type(value) == "number" or string.match(value, "^[%d.]+$") then
        -- Always send numbers as formatted floats, so InfluxDB will accept
        -- them if they happen to change from ints to floats between
        -- points in time.  Forcing them to always be floats avoids this.
        value = string.format("%.6f", value)
    end

    if #tags > 0 then
        -- for performance reasons, it is recommended to always send the tags
        -- in the same order.
        table.sort(tags)
        point = string.format("%s,%s value=%s %d\n",
            escape_string(read_message('Fields[name]')),
            table.concat(tags, ','),
            value,
            field_util.message_timestamp('m'))
    else
        point = string.format("%s value=%s %d\n",
            escape_string(read_message('Fields[name]')),
            value,
            field_util.message_timestamp('m'))
    end

    inject_payload("txt", "influxdb_line", point)
    return 0
end
