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
local utils = require 'lma_utils'
local Accumulator = require 'accumulator'
local Influxdb = require 'influxdb'
local l = require 'lpeg'
l.locale(l)

local flush_count = (read_config('flush_count') or 100) + 0
local flush_interval = (read_config('flush_interval') or 5) + 0
local time_precision = read_config("time_precision")
local payload_name = read_config("payload_name") or "influxdb"
local bulk_metric_type_matcher = read_config("bulk_metric_type_matcher") or "bulk_metric$"

-- the tag_fields parameter is a list of tags separated by spaces
local tag_grammar = l.Ct((l.C((l.P(1) - l.P" ")^1) * l.P" "^0)^0)
local tag_fields = tag_grammar:match(read_config("tag_fields") or "")

function flush_cb(datapoints)
    if #datapoints > 0 then
        datapoints[#datapoints+1] = ''
        utils.safe_inject_payload("txt", payload_name, table.concat(datapoints, "\n"))
    end
end
local accumulator = Accumulator.new(flush_count, flush_interval, flush_cb)
local encoder = Influxdb.new(time_precision)

-- return a table containing the common tags from the message
function get_common_tags()
    local tags = {}
    for _, t in ipairs(tag_fields) do
        tags[t] = read_message(string.format('Fields[%s]', t))
    end
    return tags
end

-- process a single metric
function process_single_metric()
    local name = read_message("Fields[name]")

    if not name then
        return 'Fields[name] is missing'
    end
    local ok, value = utils.get_values_from_metric()
    if not ok then
        return value
    end

    -- collect tags from Fields[tag_fields]
    local tags = get_common_tags()
    local i = 0
    while true do
        local t = read_message("Fields[tag_fields]", 0, i)
        if not t then
            break
        end
        tags[t] = read_message(string.format('Fields[%s]', t))
        i = i + 1
    end

    accumulator:append(
        encoder:encode_datapoint(
            read_message('Timestamp'),
            name,
            value,
            tags))
    return
end

function process_bulk_metric()
    -- The payload of the message contains a list of datapoints.
    --
    -- Each point is formatted either like this:
    --
    --  {name='foo',
    --   value=1,
    --   tags={k1=v1,...}}
    --
    -- or like this for multi-value points:
    --
    --  {name='bar',
    --   values={k1=v1, ..},
    --   tags={k1=v1,...}
    --
    local ok, points = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        return 'Invalid payload value for bulk metric'
    end

    local common_tags = get_common_tags()
    local msg_timestamp = read_message('Timestamp')
    for _, point in ipairs(points) do
        point.tags = point.tags or {}
        for k,v in pairs(common_tags) do
            if point.tags[k] == nil then
                point.tags[k] = v
            end
        end
        accumulator:append(
            encoder:encode_datapoint(
                msg_timestamp,
                point.name,
                point.value or point.values,
                point.tags))
    end
    return
end

function process_message()
    local err_msg
    local msg_type = read_message("Type")
    if msg_type:match(bulk_metric_type_matcher) then
        err_msg = process_bulk_metric()
    else
        err_msg = process_single_metric()
    end

    if err_msg then
        return -1, err_msg
    else
        return 0
    end
end

function timer_event(ns)
    accumulator:flush(ns)
end
