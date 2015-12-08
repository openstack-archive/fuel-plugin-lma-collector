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
require "string"
local l      = require 'lpeg'
l.locale(l)

local patt = require 'patterns'
local utils  = require 'lma_utils'

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = nil,
    Severity    = nil,
}

local sp   = patt.sp
local dash = patt.dash
local dot   = l.P'.'
local quote = l.P'"'

-- OpenStack log messages are of this form:
-- 2015-11-30 08:38:59.306 3434 INFO oslo_service.periodic_task [-] Blabla...
--
-- [-] is the "request" part, it can take multiple forms, see below.

local timestamp = l.Cg(patt.Timestamp, "Timestamp")
local pid       = l.Cg(patt.Pid, "Pid")
local severity  = l.Cg(patt.SeverityLabel, "SeverityLabel")
local message   = l.Cg(patt.Message, "Message")

local openstack_grammar = l.Ct(timestamp * sp * pid * sp * severity * sp *
    patt.programname * sp * message)

-- The OpenStack Request context is enclosed between square brackets. It takes one of these forms:
--
-- [-]
-- [req-0fd2a9ba-448d-40f5-995e-33e32ac5a6ba - - - - -]
-- [req-4db318af-54c9-466d-b365-fe17fe4adeed 8206d40abcc3452d8a9c1ea629b4a8d0 - - - -]
-- [req-4db318af-54c9-466d-b365-fe17fe4adeed 8206d40abcc3452d8a9c1ea629b4a8d0 112245730b1f4858ab62e3673e1ee9e2 - - -]
--
-- The request id  may be formatted as 'req-xxx' or 'xxx' depending on the project.
-- The user id and tenant id may not be present depending on the OpenStack release.
local request_grammar = (l.P(1) - "[" )^0 * "[" * l.P"req-"^-1 * l.Ct(l.Cg(patt.Uuid, "RequestId") *
    sp * ((l.Cg(patt.Uuid, "UserId") * sp * l.Cg(patt.Uuid, "TenantId")) + l.P(1)^0)) - "]"

-- Grammar for parsing HTTP response attributes from OpenStack logs
local http_method = l.Cg(l.R"AZ"^3, "http_method")
local url = l.Cg( (1 - sp)^1, "http_url")
local http_version = l.Cg(l.digit * dot * l.digit, "http_version")
-- Nova changes the default log format of eventlet.wsgi (see nova/wsgi.py) and
-- prefixes the HTTP status, response size and response time values with
-- respectively "status: ", "len: " and "time: ".
-- Other OpenStack services just rely on the default log format.
-- TODO(pasquier-s): build the LPEG grammar based on the log_format parameter
-- passed to eventlet.wsgi.server similar to what the build_rsyslog_grammar
-- function does for RSyslog.
local http_status = l.P"status: "^-1 * l.Cg(l.digit^3, "http_status")
local response_size = l.P"len: "^-1 * l.Cg(l.digit^1 / tonumber, "http_response_size")
local response_time = l.P"time: "^-1 * l.Cg(l.digit^1 * dot^0 * l.digit^0 / tonumber, "http_response_time")
local http_grammar = patt.anywhere(l.Ct(
    quote * http_method * sp * url * sp * l.P'HTTP/' * http_version * quote *
    sp * http_status * sp * response_size * sp * response_time
))

local ip_address_grammar = patt.anywhere(l.Ct(
    l.Cg(l.digit^-3 * dot * l.digit^-3 * dot * l.digit^-3 * dot * l.digit^-3, "ip_address")
))

function process_message ()

    -- Logger is of form "<service>/<program>" (e.g. "nova/nova-api",
    -- "neutron/l3-agent").
    local logger = read_message("Logger")
    local service, program = string.match(logger, '([^/]+)/(.+)')

    local log = read_message("Payload")
    local m

    m = openstack_grammar:match(log)
    if not m then
        return -1, string.format("Failed to parse %s log: %s", logger, string.sub(log, 1, 64))
    end

    -- Change Logger to the form "openstack.<service>" (e.g. "openstack.nova")
    msg.Logger = 'openstack.' .. service

    msg.Timestamp = m.Timestamp
    msg.Payload = m.Message
    msg.Pid = m.Pid
    msg.Severity = utils.label_to_severity_map[m.SeverityLabel] or 7
    msg.Fields = {}
    msg.Fields.severity_label = m.SeverityLabel
    msg.Fields.programname = program

    m = request_grammar:match(msg.Payload)
    if m then
        msg.Fields.request_id = m.RequestId
        if m.UserId then
          msg.Fields.user_id = m.UserId
        end
        if m.TenantId then
          msg.Fields.tenant_id = m.TenantId
        end
    end

    m = http_grammar:match(msg.Payload)
    if m then
        msg.Fields.http_method = m.http_method
        msg.Fields.http_status = m.http_status
        msg.Fields.http_url = m.http_url
        msg.Fields.http_version = m.http_version
        msg.Fields.http_response_size = m.http_response_size
        msg.Fields.http_response_time = m.http_response_time
        m = ip_address_grammar:match(msg.Payload)
        if m then
            msg.Fields.http_client_ip_address = m.ip_address
        end
    end

    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end
