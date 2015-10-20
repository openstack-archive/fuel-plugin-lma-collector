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
        msg.Logger = string.gsub(read_message('Logger'), '%.log$', '')
        return utils.safe_inject_message(msg)
    end

    return -1
end
