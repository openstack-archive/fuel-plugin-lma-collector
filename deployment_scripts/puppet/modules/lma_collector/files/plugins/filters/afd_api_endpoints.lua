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

local afd = require 'afd'
local consts = require 'gse_constants'

local haproxy_backend_states = {}
local check_api_states = {}

-- emit AFD event metrics based on HAProxy backends and check_api metrics
function process_message()
    local metric_name = read_message('Fields[name]')
    local value = read_message('Fields[value]')
    local service
    local state = consts.OKAY

    if metric_name == 'haproxy_backend_servers' then
        service = read_message('Fields[backend]')
        if not haproxy_backend_states[service] then
            haproxy_backend_states[service] = {}
        end
        haproxy_backend_states[service][read_message('Fields[state]')] = value
    else
        service = read_message('Fields[service]') .. '-api'
        check_api_states[service] = value
    end

    if not (haproxy_backend_states[service] and haproxy_backend_states[service].up and haproxy_backend_states[service].down) then
        if not check_api_states[service] then
            -- not enough data for now
            return 0
        end
        -- else the check_api result is enough to emit the AFD event
    elseif haproxy_backend_states[service].up == 0 then
        state = consts.DOWN
        afd.add_to_alarms(consts.DOWN,
                          'last',
                          string.format("%s[service=%s,state=up]", metric_name, service),
                          '==',
                          0,
                          nil,
                          nil,
                          string.format("All %s endpoints are down", service))
    elseif haproxy_backend_states[service].down >= haproxy_backend_states[service].up then
        state = consts.CRIT
        afd.add_to_alarms(consts.CRIT,
                          'last',
                          string.format("%s[service=%s,state=down]", metric_name, service),
                          '>=',
                          haproxy_backend_states[service].up,
                          nil,
                          nil,
                          string.format("The number of down endpoints for %s is greater than or equal to the number of up endpoints", service))
    elseif haproxy_backend_states[service].down > 0 then
        state = consts.WARN
        afd.add_to_alarms(consts.WARN,
                          'last',
                          string.format("%s[service=%s,state=down]", metric_name, service),
                          '>',
                          0,
                          nil,
                          nil,
                          string.format("%d %s endpoints(s) is/are down", haproxy_backend_states[service].down, service))
    end

    if check_api_states[service] and check_api_states[service] == 0 then
        state = consts.DOWN
        afd.add_to_alarms(consts.DOWN,
                          'last',
                          metric_name,
                          '==',
                          0,
                          nil,
                          nil,
                          string.format("Service check for service %s is failed", service))
    end

    afd.inject_afd_service_event(service, state, 0, 'afd_api')
    return 0
end
