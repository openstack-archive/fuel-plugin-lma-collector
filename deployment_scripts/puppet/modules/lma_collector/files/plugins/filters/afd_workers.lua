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

local worker_states = {}

-- emit AFD event metrics based on openstack_nova_services, openstack_cinder_services and openstack_neutron_agents metrics
function process_message()
    local metric_name = read_message('Fields[name]')
    local service = string.format('%s-%s',
                                  string.match(metric_name, 'openstack_([^_]+)'),
                                  read_message('Fields[service]'))
    local worker_key = string.format('%s.%s', metric_name, service)

    if not worker_states[worker_key] then
        worker_states[worker_key] = {}
    end

    local worker = worker_states[worker_key]
    worker[read_message('Fields[state]')] = read_message('Fields[value]')

    local state = consts.OKAY
    if not(worker.up and worker.down) then
        -- not enough data for now
        return 0
    end

    if worker.up == 0 then
        state = consts.DOWN
        afd.add_to_alarms(consts.DOWN,
                          'last',
                          metric_name,
                          {service=service,state='up'},
                          {},
                          '==',
                          worker.up,
                          0,
                          nil,
                          nil,
                          string.format("All instances for the service %s are down or disabled", service))
    elseif worker.down >= worker.up then
        state = consts.CRIT
        afd.add_to_alarms(consts.CRIT,
                          'last',
                          metric_name,
                          {service=service,state='down'},
                          {},
                          '>=',
                          worker.down,
                          worker.up,
                          nil,
                          nil,
                          string.format("More instances of %s are down than up", service))
    elseif worker.down > 0 then
        state = consts.WARN
        afd.add_to_alarms(consts.WARN,
                          'last',
                          metric_name,
                          {service=service,state='down'},
                          {},
                          '>',
                          worker.down,
                          0,
                          nil,
                          nil,
                          string.format("At least one %s instance is down", service))
    end

    afd.inject_afd_service_metric(service,
                                  state,
                                  read_message('Fields[hostname]'),
                                  0,
                                  'workers')

    -- reset the cache for this worker
    worker_states[worker_key] = {}

    return 0
end
