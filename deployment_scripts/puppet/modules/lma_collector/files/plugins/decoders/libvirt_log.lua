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

local string = require 'string'
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

-- libvirt message logs are formatted like this:
--
-- 2015-03-26 17:24:52.126+0000: <PID>: <SEV> : Message

local timestamp = l.Cg(patt.Timestamp, "Timestamp")
local pid  = l.Cg(patt.Pid, "Pid")
local severity = l.Cg(l.P"debug" + "info" + "warning" + "error", "Severity")
local message = l.Cg(patt.Message, "Message")

local grammar = l.Ct(timestamp * ": " * pid * ": " * severity * " : " * message)

function process_message ()
    local log = read_message("Payload")

    local m = grammar:match(log)
    if not m then
        return -1
    end

    m.Severity = string.upper(m.Severity)

    msg.Timestamp = m.Timestamp
    msg.Pid = m.Pid
    msg.Payload = m.Message
    msg.Severity = utils.label_to_severity_map[m.Severity]

    msg.Fields = {}
    msg.Fields.severity_label = m.Severity
    msg.Fields.programname = 'libvirt'
    utils.inject_tags(msg)

    return utils.safe_inject_message(msg)
end
