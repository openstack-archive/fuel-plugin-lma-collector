-- Copyright 2016 Mirantis, Inc.
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
local string = string
local table = table
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local type = type

local utils = require 'lma_utils'

local InfluxEncoder = {}
InfluxEncoder.__index = InfluxEncoder

setfenv(1, InfluxEncoder) -- Remove external access to contain everything in the module

local function escape_string(str)
    return tostring(str):gsub("([ ,])", "\\%1")
end

local function encode_scalar_value(value)
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

local function encode_value(value)
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

-- Create a new InfluxDB encoder
--
-- time_precision: "s", "m", "ms", "us" or "ns" (default: "ns")
function InfluxEncoder.new(time_precision)
    local e = {}
    setmetatable(e, InfluxEncoder)
    e.time_precision = time_precision or 'ns'
    return e
end

-- Encode a single datapoint using the InfluxDB line protocol
--
-- timestamp: the timestamp in nanosecond
-- name:  the measurement's name
-- value: a scalar value or a list of key-value pairs
-- tags:  a list of key-value pairs encoded as InfluxDB tags
function InfluxEncoder:encode_datapoint(timestamp, name, value, tags)
    if timestamp == nil or type(name) ~= 'string' or value == nil or type(tags or {}) ~= 'table' then
        -- fail silently if any input parameter is invalid
        return ""
    end

    local ts = timestamp
    if self.time_precision ~= 'ns' then
        ts = utils.message_timestamp(self.time_precision, ts)
    end

    local tags_array = {}
    for k,v in pairs(tags or {}) do
        if k ~= '' and v ~= '' then
            -- empty tag name and value aren't allowed by InfluxDB
            table.insert(tags_array, escape_string(k) .. '=' .. escape_string(v))
        end
    end

    if #tags_array > 0 then
        -- for performance reasons, it is recommended to always send the tags
        -- in the same order.
        table.sort(tags_array)
        return string.format("%s,%s %s %d",
            escape_string(name),
            table.concat(tags_array, ','),
            encode_value(value),
            ts)
    else
        return string.format("%s %s %d",
            escape_string(name),
            encode_value(value),
            ts)
    end
end

return InfluxEncoder
