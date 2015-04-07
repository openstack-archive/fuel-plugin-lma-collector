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
local table  = require 'table'
local dt     = require "date_time"
local l      = require 'lpeg'
l.locale(l)

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

function format_uuid(t)
    return table.concat(t, '-')
end

function anywhere (patt)
  return l.P {
    patt + 1 * l.V(1)
  }
end

sp = l.space
colon = l.P":"
dash = l.P"-"

local x4digit = l.xdigit * l.xdigit * l.xdigit * l.xdigit
local uuid_dash = l.C(x4digit * x4digit * dash * x4digit * dash * x4digit * dash * x4digit * dash * x4digit * x4digit * x4digit)
local uuid_nodash = l.Ct(l.C(x4digit * x4digit) * l.C(x4digit) * l.C(x4digit) * l.C(x4digit) * l.C(x4digit * x4digit * x4digit)) / format_uuid

-- Return a UUID string in canonical format (eg with dashes)
Uuid = uuid_nodash + uuid_dash

-- Parse a datetime string and return a table with the following keys
--   year (string)
--   month (string)
--   day (string)
--   hour (string)
--   min (string)
--   sec (string)
--   sec_frac (number less than 1, can be nil)
--   offset_sign ('-' or '+', can be nil)
--   offset_hour (number, can be nil)
--   offset_min (number, can be nil)
--
-- The datetime string can be formatted as
-- 'YYYY-MM-DD( |T)HH:MM:SS(.ssssss)?(offset indicator)?'
TimestampTable = l.Ct(dt.rfc3339_full_date * (sp + l.P"T") * dt.rfc3339_partial_time * (dt.rfc3339_time_offset + dt.timezone_offset)^-1)

-- Returns the parsed datetime converted to nanosec
Timestamp = TimestampTable / dt.time_to_ns

programname   = (l.R("az", "AZ", "09") + l.P"." + dash + l.P"_")^1
Pid           = l.digit^1
SeverityLabel = l.P"CRITICAL" + l.P"ERROR" + l.P"WARNING" + l.P"INFO" + l.P"AUDIT" + l.P"DEBUG"
Message       = l.P(1)^0

return M
