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

local cjson = require 'cjson'
local math = require 'math'
local string = require 'string'

local afd = require 'afd'
local inspect = require 'inspect'

-- node or service
local afd_type = read_config('afd_type') or error('afd_type must be specified!')

local afd_entity = 'node'
if afd_type == 'service' then
    afd_entity = 'cluster_name'
end

-- ie: controller for node AFD / rabbitmq for service AFD
local afd_cluster_name = read_config('afd_cluster_name') or error('afd_cluster_name must be specified!')

-- ie: system for node AFD / queue for service AFD
local afd_logical_name = read_config('afd_logical_name') or error('afd_logical_name must be specified!')

local msg_type = string.format('afd_%s_metric', afd_type)
local msg_field_name = string.format('%s_status', afd_type)
local msg_field_source = string.format('afd_%s_%s', afd_type, afd_cluster_name)
local alarm_lib = string.format('lma_alarms_%s_%s', afd_type, afd_cluster_name, afd_logical_name)

-- used by services AFD but overided by node AFD
local afd_entity_value = string.format('%s-%s', afd_cluster_name, afd_logical_name)
-- used by node AFD
local hostname

local all_alarms = require(alarm_lib)
local A = require 'afd_alarms'
A.load_alarms(all_alarms)

function process_message()

  local metric_name = read_message('Fields[name]')
  local value = read_message('Fields[value]')
  local ts = read_message('Timestamp')
  -- we assume all node AFD run on a local node
  hostname = read_message('Hostname')

  -- retrieve field values
  local fields = {}
  for _, field in ipairs (A.get_metric_fields(metric_name)) do
    local field_value = afd.get_entity_name(field)
    if not field_value then
      return -1, "Cannot find Fields[" .. field .. "] in the metric " .. metric_name
    end
    fields[field] = field_value
  end
    --inject_payload('debug', 'debug', inspect({metric=metric_name, v=value, fields=fields}))
  A.add_value(ts, metric_name, value, fields)
  return 0
end

function timer_event(ns)
  if A.is_started() then
    local global_state, alarms = A.evaluate(ns)
    for _, alarm in ipairs(alarms) do
        afd.add_to_alarms(
          alarm.state,
          alarm.alert['function'],
          alarm.alert.metric_name,
          alarm.alert.fields,
          {rule_type='threshold'},
          alarm.alert.relational_operator,
          alarm.alert.value,
          alarm.alert.threshold,
          alarm.alert.window,
          alarm.alert.periods,
          alarm.alert.message)
    end
    if afd_type == 'node' then
      afd_entity_value = hostname
    end

    afd.inject_afd_metric(msg_type, afd_entity, afd_entity_value, msg_field_name,
                          global_state, hostname, interval, msg_field_source)
  else
    A.set_start_time(ns)
  end
end
