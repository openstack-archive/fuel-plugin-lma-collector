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

local patt   = require 'patterns'
local syslog = require 'syslog'
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

local timestamp = l.Cg(patt.Timestamp, "Timestamp")
local sp        = l.space
local pid       = l.Cg(patt.Pid, "Pid")
local severity  = l.Cg(patt.SeverityLabel, "SeverityLabel")
local message   = l.Cg(patt.Message, "Message")

local openstack_grammar = l.Ct(timestamp * sp * pid * sp * severity * sp * message)

-- This grammar is intended for log messages that are generated before RSYSLOG
-- is fully configured
local fallback_syslog_pattern = read_config("fallback_syslog_pattern")
local fallback_syslog_grammar
if fallback_syslog_pattern then
    fallback_syslog_grammar = syslog.build_rsyslog_grammar(fallback_syslog_pattern)
end

function process_message ()
    local log = read_message("Payload")

    if utils.parse_syslog_message(syslog_grammar, log, msg) or
       (fallback_syslog_grammar and utils.parse_syslog_message(fallback_syslog_grammar, log, msg)) then
        -- We are only interested by program named "main" and "admin"
        if (msg.Fields.programname == "main" or msg.Fields.programname == "admin") then
            msg.Fields.programname = "keystone-" .. msg.Fields.programname

            local m = openstack_grammar:match(msg.Payload)
            if m then
                if m.Pid then msg.Pid = m.Pid end
                if m.Timestamp then msg.Timestamp = m.Timestamp end
                msg.Payload = m.Message
                msg.Fields.severity_label = m.SeverityLabel
            end

            inject_message(msg)
        end
        return 0
    end

    return -1
end
