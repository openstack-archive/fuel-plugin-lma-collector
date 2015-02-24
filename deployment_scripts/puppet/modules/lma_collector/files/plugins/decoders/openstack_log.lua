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
local dt     = require "date_time"
local l      = require 'lpeg'
l.locale(l)

local syslog = require "syslog"
local patt   = require 'patterns'
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

local syslog_pattern = read_config("syslog_pattern") or error("syslog_pattern configuration must be specified")
local syslog_grammar = syslog.build_rsyslog_grammar(syslog_pattern)

local sp    = l.space
local colon = l.P":"

local timestamp = l.Cg(patt.Timestamp, "Timestamp")
local pid       = l.Cg(patt.Pid, "Pid")
local severity  = l.Cg(patt.SeverityLabel, "SeverityLabel")
local message   = l.Cg(patt.Message, "Message")

-- Horizon logs have no colon after the severity level
local openstack_grammar_5_0 = l.Ct(severity * colon^-1 * sp * message)
local openstack_grammar_5_1 = l.Ct(timestamp * sp * pid * sp * severity * colon^-1 * sp * message)
local openstack_grammar     = openstack_grammar_5_0 + openstack_grammar_5_1

local neutron_grammar = l.Ct(timestamp * sp * pid * sp * severity * sp * l.Cg(patt.programname, "programname") * sp * message)

-- the RequestId string is enclosed between square brackets and it may be
-- prefixed by other stuff like the Python module name.
-- RequestId may be formatted as 'req-xxx' or 'xxx' depending on the project.
-- UserId and TenantId may not be present depending on the OpenStack release.
local request_grammar = (l.P(1) - "[" )^0 * "[" * l.P"req-"^-1 * l.Ct(l.Cg(patt.Uuid, "RequestId") * sp * ((l.Cg(patt.Uuid, "UserId") * sp * l.Cg(patt.Uuid, "TenantId")) + l.P(1)^0)) - "]"


function process_message ()
    local log = read_message("Payload")
    local m

    -- need to assign an empty table first otherwise
    msg.Fields = {}
    if utils.parse_syslog_message(syslog_grammar, log, msg) then
        m = openstack_grammar:match(msg.Payload)
        if m then
            if m.Pid then msg.Pid = m.Pid end
            if m.Timestamp then msg.Timestamp = m.Timestamp end
            msg.Payload = m.Message
            msg.Fields.severity_label = m.SeverityLabel
        end
    else
        -- parse with the Neutron grammar
        m = neutron_grammar:match(log)
        if m then
            msg.Timestamp = m.Timestamp
            msg.Pid = m.Pid
            msg.Payload = m.Message
            msg.Severity = utils.label_to_severity_map[m.SeverityLabel] or 5

            msg.Fields = {}
            msg.Fields.severity_label = m.SeverityLabel
            msg.Fields.programname = m.programname
        else
            return -1
        end
    end

    m = request_grammar:match(msg.Payload)
    if m then
        msg.Fields.request_id = m.RequestId
        if m.UserId then msg.Fields.user_id = m.UserId end
        if m.TenantId then msg.Fields.tenant_id = m.TenantId end
    end

    inject_message(msg)
    return 0
end
