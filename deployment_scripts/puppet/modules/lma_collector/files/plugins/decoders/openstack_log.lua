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

-- OpenStack log messages are of this form:
-- 2015-11-30 08:38:59.306 3434 INFO oslo_service.periodic_task [-] Blabla...
--
-- [-] is the "request" part, it can take multiple forms.

function process_message ()

    -- Logger is of form "<service>/<program>" (e.g. "nova/nova-api",
    -- "neutron/l3-agent").
    local logger = read_message("Logger")
    local service, program = string.match(logger, '([^/]+)/(.+)')

    local log = read_message("Payload")
    local m

    m = patt.openstack:match(log)
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
    msg.Fields.python_module = m.PythonModule
    msg.Fields.programname = program

    m = patt.openstack_request_context:match(msg.Payload)
    if m then
        msg.Fields.request_id = m.RequestId
        if m.UserId then
          msg.Fields.user_id = m.UserId
        end
        if m.TenantId then
          msg.Fields.tenant_id = m.TenantId
        end
    end

    m = patt.openstack_http:match(msg.Payload)
    if m then
        msg.Fields.http_method = m.http_method
        msg.Fields.http_status = m.http_status
        msg.Fields.http_url = m.http_url
        msg.Fields.http_version = m.http_version
        msg.Fields.http_response_size = m.http_response_size
        msg.Fields.http_response_time = m.http_response_time
        m = patt.ip_address:match(msg.Payload)
        if m then
            msg.Fields.http_client_ip_address = m.ip_address
        end
    end

    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end
