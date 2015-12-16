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

local common_log_format = require 'common_log_format'
local patt = require 'patterns'

local msg = {
    Timestamp   = nil,
    Type        = 'log',
    Hostname    = nil,
    Payload     = nil,
    Pid         = nil,
    Fields      = nil,
    Severity    = 6,
}

local apache_log_pattern = read_config("apache_log_pattern") or error(
    "apache_log_pattern configuration must be specificed")
local apache_grammar = common_log_format.build_apache_grammar(apache_log_pattern)
local request_grammar = l.Ct(patt.http_version)

function process_message ()
    local logger = read_message("Logger")
    local log = read_message("Payload")

    local m

    m = apache_grammar:match(log)
    if m then
        msg.Timestamp = m.time

        msg.Fields = {}
        msg.Fields.http_status = m.status
        msg.Fields.http_response_time = m.request_time / 1e6 -- us to sec

        local request = m.request
        m = request_grammar:match(request)
        if m then
            msg.Fields.http_method = m.http_method
            msg.Fields.http_url = m.http_url
            msg.Fields.http_version = m.http_version
        end
    end

    return -1, string.format("Failed to parse %s log: %s", logger, string.sub(log, 1, 64))
end
