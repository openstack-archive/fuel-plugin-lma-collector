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
require 'string'
local l = require 'lpeg'
local utils = require 'lma_utils'
l.locale(l)

function anywhere (patt)
  return l.P {
    patt + 1 * l.V(1)
  }
end

local sp = l.P' '^1
local dot = l.P'.'
local quote = l.P'"'
local http_method = l.Cg(l.R"AZ"^3, "http_method")
local url = l.Cg( (1 - l.space)^1, "url")
local http_version = l.Cg(l.digit * dot * l.digit, "http_version")
-- Nova changes the default log format of eventlet.wsgi (see nova/wsgi.py) and
-- prefixes the HTTP status, response size and response time values.
-- Other OpenStack services just rely on the default log format.
-- TODO(pasquier-s): build the LPEG grammar based on the log_format parameter
-- passed to eventlet.wsgi.server similar to what the build_rsyslog_grammar
-- function does for RSyslog.
local http_status = l.P"status: "^-1 * l.Cg(l.digit^3, "http_status")
local response_size = l.P"len: "^-1 * l.Cg(l.digit^1 / tonumber, "response_size")
local response_time = l.P"time: "^-1 * l.Cg(l.digit^1 * dot^0 * l.digit^0 / tonumber, "response_time")

local grammar = anywhere(l.Ct(
    quote * http_method * sp * url * sp * l.P'HTTP/' * http_version * quote *
    sp * http_status * sp * response_size * sp * response_time
))

local msg = {
    Type = "metric", -- will be prefixed by "heka.sandbox."
    Timestamp = nil,
    Severity = 6,
    Fields = nil
}

function process_message ()
    local m = grammar:match(read_message("Payload"))
    if m then
        -- keep only the first 2 tokens because some services like Neutron report
        -- themselves as 'openstack.<service>.server'
        local service = string.gsub(read_message("Logger"), '(%w+)%.(%w+).*', '%1.%2')
        msg.Timestamp = read_message("Timestamp")
        msg.Fields = {
            source = read_message('Fields[programname]') or service,
            name = string.format("%s.http.%s.%s", service, m.http_method, m.http_status),
            type = utils.metric_type['GAUGE'],
            value = {value = m.response_time, representation = 's'},
            tenant_id = read_message('Fields[tenant_id]'),
            user_id = read_message('Fields[user_id]'),
        }
        utils.inject_tags(msg)
        inject_message(msg)
    end
    return 0
end
