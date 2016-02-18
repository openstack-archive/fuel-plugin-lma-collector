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

local dt     = require "date_time"
local patt   = require "patterns"
local syslog = require "syslog"
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

-- This grammar is intended for debug and info messages which aren't emitted
-- through Syslog. For example:
-- Apr 29 13:23:46 [13545] node-32.domain.tld pacemakerd: INFO: get_cluster_type: Detected an active 'corosync' cluster
local sp    = l.space
local colon = l.P":"

local timestamp   = l.Cg(dt.rfc3164_timestamp / dt.time_to_ns, "Timestamp")
local pid         = l.Cg(patt.Pid, "Pid")
local severity    = l.Cg((l.R"AZ" + l.R"az")^1 /  string.upper, "SeverityLabel")
local programname = l.Cg(patt.programname, "programname")
local message     = l.Cg(patt.Message, "Message")

local fallback_grammar = l.Ct(timestamp * sp^1 * l.P'[' * pid * l.P']' * sp^1 *
    (l.P(1) - sp)^0 * sp^1 * programname * colon * sp^1 * severity * colon *
    sp^1 * message)

function process_message ()
    local log = read_message("Payload")

    if utils.parse_syslog_message(syslog_grammar, log, msg) then
        return utils.safe_inject_message(msg)
    else
        local m = fallback_grammar:match(log)
        if m then
            msg.Timestamp = m.Timestamp
            msg.Payload = m.Message
            msg.Pid = m.Pid
            msg.Severity = utils.label_to_severity_map[m.SeverityLabel] or 7

            msg.Fields = {}
            msg.Fields.severity_label = utils.severity_to_label_map[msg.Severity]
            msg.Fields.programname = m.programname
            utils.inject_tags(msg)

            return utils.safe_inject_message(msg)
        end
    end

    return -1
end
