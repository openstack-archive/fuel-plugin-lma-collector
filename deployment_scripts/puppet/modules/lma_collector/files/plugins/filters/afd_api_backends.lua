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

-- emit AFD event metrics based on HAProxy backends
function process_message()
    local metric_name = read_message('Fields[name]')
    local value = read_message('Fields[value]')
    local service = read_message('Fields[backend]')
    local state = consts.OKAY

    if not haproxy_backend_states[service] then
        haproxy_backend_states[service] = {}
    end
    haproxy_backend_states[service][read_message('Fields[state]')] = value

    if not (haproxy_backend_states[service].up and haproxy_backend_states[service].down) then
       -- not enough data for now
       return 0
   end

   if haproxy_backend_states[service].up == 0 then
        state = consts.DOWN
        afd.add_to_alarms(consts.DOWN,
                          'last',
                          metric_name,
                          {service=service,state='up'},
                          {},
                          '==',
                          haproxy_backend_states[service].up,
                          0,
                          nil,
                          nil,
                          string.format("All %s backends are down", service))
    elseif haproxy_backend_states[service].down >= haproxy_backend_states[service].up then
        state = consts.CRIT
        afd.add_to_alarms(consts.CRIT,
                          'last',
                          metric_name,
                          {service=service,state='down'},
                          {},
                          '>=',
                          haproxy_backend_states[service].down,
                          haproxy_backend_states[service].up,
                          nil,
                          nil,
                          string.format("More backends for %s are down than up", service))
    elseif haproxy_backend_states[service].down > 0 then
        state = consts.WARN
        afd.add_to_alarms(consts.WARN,
                          'last',
                          metric_name,
                          {service=service,state='down'},
                          {},
                          '>',
                          haproxy_backend_states[service].down,
                          0,
                          nil,
                          nil,
                          string.format("At least one %s backend is down", service))
    end

    afd.inject_afd_service_metric(service,
                                  state,
                                  read_message('Fields[hostname]'),
                                  0,
                                  'backends')

    -- reset the cache for this service
    haproxy_backend_states[service] = {}

    return 0
end
