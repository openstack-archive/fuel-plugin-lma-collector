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
local pairs = pairs
local inject_message = inject_message
local read_message = read_message
local pcall = pcall

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

service_status_map = {
    UP = 0,
    DEGRADED = 1,
    DOWN = 2,
    UNKNOWN = 3,
}

service_status_to_label_map = {
    [0] = 'UP',
    [1] = 'DEGRADED',
    [2] = 'DOWN',
    [3] = 'UNKNOWN',
}

global_status_map = {
    OKAY = 0,
    WARN = 1,
    FAIL = 2,
    UNKNOWN = 3,
}

global_status_to_label_map = {
    [0] = 'OKAY',
    [1] = 'WARN',
    [2] = 'FAIL',
    [3] = 'UNKNOWN',
}

check_api_to_status_map = {
    [0] = 2, -- DOWN
    [1] = 0, -- UP
    [2] = 3, -- UNKNOWN
}

check_api_status_to_state_map = {
    [0] = 'down',
    [1] = 'up',
    [2] = 'unknown',
}

state_map = {
    UP = 'up',
    DOWN = 'down',
    DISABLED = 'disabled',
    UNKNOWN = 'unknown'
}

function add_metric(datapoints, name, points)
    datapoints[#datapoints+1] = {
        name = name,
        columns = {"time", "value" },
        points = {points}
    }
end

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

    local msg = {
        Hostname = hostname,
        Timestamp = ts,
        Payload = cjson.encode(bulk_datapoints),
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
    inject_message(msg)
end

-- Return a list of datapoints, each point being a table formatted like this:
-- {name='foo',value=1,tags={k1=v1,...}}
function decode_bulk_metric()
    local ok, datapoints = pcall(cjson.decode, read_message("Payload"))

    return datapoints or {}
end

local global_status_to_severity_map = {
    [global_status_map.OKAY] = label_to_severity_map.INFO,
    [global_status_map.WARN] = label_to_severity_map.WARNING,
    [global_status_map.FAIL] = label_to_severity_map.CRITICAL,
    [global_status_map.UNKNOWN] = label_to_severity_map.NOTICE,
}

function inject_status_message(time, service, status, prev_status, updated, details)
    local msg = {
        Timestamp = time,
        Payload = details,
        Type = 'status', -- prepended with 'heka.sandbox'
        Severity = global_status_to_severity_map[status],
        Fields = {
          service = service,
          status = status,
          previous_status = prev_status,
          updated = updated,
        }
    }
    inject_message(msg)
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

return M
