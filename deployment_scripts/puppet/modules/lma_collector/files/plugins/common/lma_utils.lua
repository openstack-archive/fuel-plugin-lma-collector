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
local cjson = require 'cjson'
local string = require 'string'
local extra = require 'extra_fields'
local patt  = require 'patterns'
local table = require 'table'

local pairs = pairs
local ipairs = ipairs
local inject_message = inject_message
local inject_payload = inject_payload
local read_message = read_message
local pcall = pcall
local type = type

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

severity_to_label_map = {
    [0] = 'EMERGENCY',
    [1] = 'ALERT',
    [2] = 'CRITICAL',
    [3] = 'ERROR',
    [4] = 'WARNING',
    [5] = 'NOTICE',
    [6] = 'INFO',
    [7] = 'DEBUG',
}

label_to_severity_map = {
    EMERGENCY = 0,
    ALERT = 1,
    CRITICAL = 2,
    ERROR = 3,
    WARNING = 4,
    NOTICE = 5,
    INFO= 6,
    DEBUG = 7,
}

metric_type = {
    COUNTER = "counter",
    GAUGE = "gauge",
    DERIVE = "derive",
}

local default_severity = 7

local bulk_datapoints = {}

-- Add a datapoint to the bulk metric message
function add_to_bulk_metric(name, value, tags)
    bulk_datapoints[#bulk_datapoints+1] = {
        name = name,
        value = value,
        tags = tags or {},
    }
end

-- Send the bulk metric message to the Heka pipeline
function inject_bulk_metric(ts, hostname, source)
    if #bulk_datapoints == 0 then
        return
    end

    local payload = safe_json_encode(bulk_datapoints)
    if not payload then
        return
    end

    local msg = {
        Hostname = hostname,
        Timestamp = ts,
        Payload = payload,
        Type = 'bulk_metric', -- prepended with 'heka.sandbox'
        Severity = label_to_severity_map.INFO,
        Fields = {
            hostname = hostname,
            source = source
      }
    }
    -- reset the local table storing the datapoints
    bulk_datapoints = {}

    inject_tags(msg)
    safe_inject_message(msg)
end

-- Encode a Lua variable as JSON without raising an exception if the encoding
-- fails for some reason (for instance, the encoded buffer exceeds the sandbox
-- limit)
function safe_json_encode(v)
    local ok, data = pcall(cjson.encode, v)

    if not ok then
        return
    end

    return data
end

--  Decode the Payload field as JSON data
function decode_json_payload()
    local ok, data = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        return
    end

    return data
end

-- Call inject_payload() wrapped by pcall()
function safe_inject_payload(payload_type, payload_name, data)
    local ok, err_msg = pcall(inject_payload, payload_type, payload_name, data)
    if not ok then
        return -1, err_msg
    else
        return 0
    end
end

-- Call inject_message() wrapped by pcall()
function safe_inject_message(msg)
    local ok, err_msg = pcall(inject_message, msg)
    if not ok then
        return -1, err_msg
    else
        return 0
    end
end

-- Parse a Syslog-based payload and update the Heka message
-- Return true if successful, false otherwise
function parse_syslog_message(grammar, payload, msg)
    -- capture everything after the first backslash because syslog_grammar will
    -- drop it
    local extra_msg = string.match(payload, '^[^\n]+\n(.+)\n$')

    local fields = grammar:match(payload)
    if not fields then
        return false
    end

    msg.Timestamp = fields.timestamp
    fields.timestamp = nil

    msg.Hostname = fields.hostname
    fields.hostname = nil

    msg.Pid = fields.syslogtag.pid or 0
    fields.programname = fields.syslogtag.programname
    fields.syslogtag = nil

    if fields.pri then
        msg.Severity = fields.pri.severity
        fields.syslogfacility = fields.pri.facility
        fields.pri = nil
    else
        msg.Severity = fields.syslogseverity or fields["syslogseverity-text"]
            or fields.syslogpriority or fields["syslogpriority-text"]
            or default_severity
        fields.syslogseverity = nil
        fields["syslogseverity-text"] = nil
        fields.syslogpriority = nil
        fields["syslogpriority-text"] = nil
    end
    fields.severity_label = severity_to_label_map[msg.Severity]

    if extra_msg ~= nil then
        msg.Payload = fields.msg .. "\n" .. extra_msg
    else
        msg.Payload = fields.msg
    end
    fields.msg = nil

    msg.Fields = fields

    inject_tags(msg)

    return true
end

-- Inject tags into the Heka message
function inject_tags(msg)
    for k,v in pairs(extra.tags) do
        if msg.Fields[k] == nil then
            msg.Fields[k] = v
        end
    end
end

-- Convert a datetime string to the RFC3339 format
-- it supports a variety of datetime formats.
-- Return the string unmodified if the datetime couldn't be parsed
function format_datetime (raw_datetime)
    local datetime
    local t = patt.TimestampTable:match(raw_datetime)
    if t then
        local frac = 0
        local offset_sign = '+'
        local offset_hour = 0
        local offset_min = 0
        if t.sec_frac then frac = t.sec_frac end
        if t.offset_sign then offset_sign = t.offset_sign end
        if t.offset_hour then offset_hour = t.offset_hour end
        if t.offset_min then offset_min = t.offset_min end
        datetime = string.format("%04d-%02d-%02dT%02d:%02d:%02d.%06d%s%02d:%02d",
            t.year, t.month, t.day, t.hour, t.min, t.sec, frac*1e6, offset_sign,
            offset_hour, offset_min)
    end
    return datetime
end

function chomp(s)
    return string.gsub(s, "\n$", "")
end

function deepcopy(t)
    if type(t) == 'table' then
        local copy = {}
        for k, v in pairs(t) do
            copy[k] = deepcopy(v)
        end
        return copy
    end
    return t
end

-- return the position (index) of an item in a list, nil if not found
function table_pos(item, list)
  if type(list) == 'table' then
    for i, v in ipairs(list) do
      if v == item then
        return i
      end
    end
  end
end

-- return true if an item is present in the list, else false
function table_find(item, list)
    return table_pos(item, list) ~= nil
end

-- from http://lua-users.org/wiki/SortedIteration
function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    key = nil
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

return M
