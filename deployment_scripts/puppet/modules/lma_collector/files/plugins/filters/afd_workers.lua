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

--require 'math'
--local inspect = require 'inspect'

require 'string'

local afd = require 'afd'
local consts = require 'gse_constants'
local T = require 'table_utils'

local max_timer_inject = read_config('max_timer_inject') * 1 or 10
local is_detail_metric= {
    ['openstack_nova_service']  = true,
    ['openstack_cinder_service'] = true,
    ['openstack_neutron_agent'] = true
}
local worker_states = {}

function process_message()
    local ts = read_message('Timestamp')
    local metric_name = read_message('Fields[name]')
    local value = read_message('Fields[value]')
    local state = read_message('Fields[state]')
    local hostname = read_message('Fields[hostname]')
    local service = string.format('%s-%s',
                                  string.match(metric_name, 'openstack_([^_]+)'),
                                  read_message('Fields[service]'))
    local worker_key = service

    local status = consts.OKAY
    if not worker_states[worker_key] then
        worker_states[worker_key] = {
            hostname = hostname,
            service = service,
            metric = metric_name,
            status = status,
            down_list = {},
            disabled_list = {},
            last_by_host = {}
        }
    end

    local worker = worker_states[worker_key]
    if worker.last and worker.last > ts then
       --inject_payload('debug', 'debugOLDER', metric_name)
       -- drop this out dated metric
       return 0
    end
    if is_detail_metric[metric_name] then
        if worker.last_by_host[hostname] and worker.last_by_host[hostname] > ts then
            -- drop this out dated metric
            -- inject_payload('debug', 'debugOUTDATED', metric_name)
            return 0
        end
        worker.last_by_host[hostname] = ts
        if state ~= 'up' then
            local field = string.format("%s_list", state)
            if not T.item_find(hostname, worker[field]) then
                 worker[field][#worker[field] + 1] = hostname
            end
        else
            local del_id = T.item_pos(hostname, worker.down_list)
            if del_down then
                 worker.down_list[del_id] = nil
            end
            local del_id = T.item_pos(hostname, worker.disabled_list)
            if del_id then
                 worker.disabled_list[del_id] = nil
            end
        end
        return 0
    end

    worker[state] = value
    if not(worker.up and worker.down) then
        -- not enough data for now
        return 0
    end

    worker.status = status
    worker.last = ts
    if worker.up == 0 then
        worker.status = consts.DOWN
        worker.value = 'up'
        worker.op = '=='
        worker.lv = 0
        worker.rv = 0
        worker.str = string.format("All instances for the service %s are down or disabled", service)

    elseif worker.down >= worker.up then
        worker.status = consts.CRIT
        worker.value = 'down'
        worker.op = '>='
        worker.lv = worker.down
        worker.rv = worker.up
        worker.str = string.format("More instances of %s are down than up", service)
    elseif worker.down > 0 then
        worker.status = consts.WARN
        worker.value = 'down'
        worker.op = '>'
        worker.lv = worker.down
        worker.rv = 0
        worker.str = string.format("At least one %s instance is down", service)
    end
    return 0
end

local function got_all_nodes(worker)
    if worker.down > 0 and worker.disabled > 0 then
       return worker.down == #worker.down_list and worker.disabled == #worker.disabled_list
    elseif worker.down > 0 then
       return worker.down == #worker.down_list
    elseif worker.disabled > 0 then
       return worker.disabled == #worker.disabled_list
    end
    return true
end

local function nodes_list(state, nodes)
   if not nodes or #nodes == 0 then
      return ''
   end
   return state .. ': ' .. table.concat(nodes, ',')
end

-- emit AFD event metrics based on openstack_nova_service(s), openstack_cinder_service(s) and openstack_neutron_agent()s metrics
function timer_event(ns)
    injected = 0
    for name, w in pairs(worker_states) do
      if injected < max_timer_inject and w.disabled and w.down then -- and got_all_nodes(w) then
          if got_all_nodes(w) then
               -- inject_payload('debug', 'GOTALL', inspect.inspect(w))
               if w.status ~= consts.OKAY then
                   local nodes = nodes_list('down', w.down_list)
                   nodes = nodes .. nodes_list('disabled', w.disabled_list)
                   afd.add_to_alarms(w.status, 'last', w.metric,
                                     {{name='service',value=w.service},
                                     {name='state',value=w.value}},
                                     {hostnames=nodes}, w.op, w.lv, w.rv,
                                     nil, nil, w.str)
               end
               afd.inject_afd_service_metric(w.service, w.status, w.hostname, 0, 'workers')
               -- reset worker state
               worker_states[name] = nil
               injected = injected + 1
         -- else
         --      inject_payload('debug', 'debugMISSING', inspect.inspect(w))
         --      injected = injected + 1
          end
      end
    end
end
