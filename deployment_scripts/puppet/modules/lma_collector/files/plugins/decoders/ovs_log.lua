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

local l      = require 'lpeg'
l.locale(l)

local syslog = require "syslog"
local patt   = require 'patterns'
local utils  = require 'lma_utils'

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Paload      = nil,
    Logger      = 'ovs',
    Pid         = nil,
    Fields      = nil,
    Severity    = nil,
}

local pipe = l.P'|'

local function_name = l.Cg((l.R("az", "AZ", "09") + l.P"." + l.P"-" + l.P"_" + l.P"(" + l.P")")^1, 'function_name')
local pid       = l.Cg(patt.Pid, "Pid")
local timestamp = l.Cg(patt.Timestamp, "Timestamp")
local severity = l.Cg(syslog.severity, 'Severity')
local message = l.Cg(l.P(1 - l.P"\n")^0, "Message")

local ovs_grammar = l.Ct(timestamp * pipe * pid * pipe * function_name * pipe * severity * pipe * message)

function process_message ()
    local log = read_message("Payload")
    local logger = read_message("Logger")
    local m

    msg.Fields = {}
    m = ovs_grammar:match(log)
    if not m then
        return -1
    end
    msg.Timestamp = m.Timestamp
    msg.Payload = m.function_name .. ': ' .. m.Message
    msg.Pid = m.Pid
    msg.Severity = m.Severity or 5
    msg.Fields.severity_label = utils.severity_to_label_map[m.Severity]
    msg.Fields.programname = logger

    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end
