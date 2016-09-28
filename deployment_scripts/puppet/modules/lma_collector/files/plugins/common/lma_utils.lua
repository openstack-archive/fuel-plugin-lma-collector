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
local math = require 'math'

local pairs = pairs
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
-- The 'value' parameter can be a table to support multi-value metric
function add_to_bulk_metric(name, value, tags)
    bulk_datapoints[#bulk_datapoints+1] = {
        name = name,
        tags = tags or {},
    }
    if type(value) == 'table' then
        bulk_datapoints[#bulk_datapoints].values = value
    else
        bulk_datapoints[#bulk_datapoints].value = value
    end
end

-- Send the bulk metric message to the Heka pipeline
function inject_bulk_metric(ts, hostname, source)
    if #bulk_datapoints == 0 then
        return
    end

    local payload = safe_json_encode(bulk_datapoints)
    if not payload then
        -- Reset the table otherwise it may grow infinitely and the sandbox
        -- will eventually be killed by Heka.
        -- See https://bugs.launchpad.net/lma-toolchain/+bug/1545743
        bulk_datapoints = {}
        return
    end

    local msg = {
        Hostname = hostname,
        Timestamp = ts,
        Payload = payload,
        Type = 'bulk_metric', -- prepended with 'heka.sandbox'
        Severity = label_to_severity_map.INFO,
        Fields = {
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

function truncate(str, max_length, delimiter)
    if string.len(str) <= max_length then
        return str
    end

    local pos = 1
    while true do
        local next_pos1, next_pos2 = string.find(str, delimiter, pos)
        if not next_pos1 or next_pos1 - 1 > max_length then
            pos = pos - string.len(delimiter) - 1
            if pos < 1 then
                pos = max_length
            end
            break
        end
        pos = next_pos2 + 1
    end

    return string.sub(str, 1, pos)
end

-- Convert a nanosecond timestamp to a lower precision timestamp.
-- Arguments:
--   timestamp_precision: one of 'us', 'ms', 's', 'm' or 'h'.
--   timestamp: a timestamp in nanosecond, if not provided the message Timestamp is used.
function message_timestamp(timestamp_precision, timestamp)
    -- Default is to divide ns to ms
    local timestamp_divisor = 1e6
    -- Divide ns to s
    if timestamp_precision == "s" then
        timestamp_divisor = 1e9
    -- Divide ns to us
    elseif timestamp_precision == "us" then
        timestamp_divisor = 1e3
    -- Divide ns to m
    elseif timestamp_precision == "m" then
        timestamp_divisor = 1e9 * 60
    -- Divide ns to h
    elseif timestamp_precision == "h" then
        timestamp_divisor = 1e9 * 60 * 60
    end
    if timestamp == nil then
        timestamp = read_message("Timestamp")
    end
    return math.floor(timestamp / timestamp_divisor)
end

-- Extract the metric value(s) from the message.
-- The value can be either a scalar value or a table for mulitvalue metrics.
-- Returns true plus the value or if it fails, returns false plus the error message.
function get_values_from_metric()
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
           return false, 'Fields[value_fields] does not list any valid field'
        end
    else
        value = read_message("Fields[value]")
        if not value then
            return false, 'Fields[value] is missing'
        end
    end

    return true, value
end

return M
