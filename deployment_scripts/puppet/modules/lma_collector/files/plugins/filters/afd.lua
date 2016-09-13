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

local string = require 'string'

local utils = require 'lma_utils'
local afd = require 'afd'

-- node or service
local afd_type = read_config('afd_type') or error('afd_type must be specified!')
local to_alerting = read_config('activate_alerting') or true
local msg_type
local msg_field_name
local afd_entity

if afd_type == 'node' then
    msg_type = 'afd_node_metric'
    msg_field_name = 'node_status'
    afd_entity = 'node_role'
elseif afd_type == 'service' then
    msg_type = 'afd_service_metric'
    msg_field_name = 'service_status'
    afd_entity = 'service'
else
    error('invalid afd_type value')
end

-- ie: controller for node AFD / rabbitmq for service AFD
local afd_entity_value = read_config('afd_cluster_name') or error('afd_cluster_name must be specified!')

-- ie: cpu for node AFD / queue for service AFD
local msg_field_source = read_config('afd_logical_name') or error('afd_logical_name must be specified!')

local hostname = read_config('hostname') or error('hostname must be specified')

local afd_file = read_config('afd_file') or error('afd_file must be specified')
local all_alarms = require(afd_file)
local A = require 'afd_alarms'
A.load_alarms(all_alarms)

function process_message()

    local metric_name = read_message('Fields[name]')
    local ts = read_message('Timestamp')

    local ok, value = utils.get_values_from_metric()
    if not ok then
        return -1, value
    end
    -- retrieve field values
    local fields = {}
    for _, field in ipairs (A.get_metric_fields(metric_name)) do
        local field_value = afd.get_entity_name(field)
        if not field_value then
            return -1, "Cannot find Fields[" .. field .. "] for the metric " .. metric_name
        end
        fields[field] = field_value
    end
    A.add_value(ts, metric_name, value, fields)
    return 0
end

function timer_event(ns)
    if A.is_started() then
        local state, alarms = A.evaluate(ns)
        if state then -- it was time to evaluate at least one alarm
            for _, alarm in ipairs(alarms) do
                afd.add_to_alarms(
                    alarm.state,
                    alarm.alert['function'],
                    alarm.alert.metric,
                    alarm.alert.fields,
                    {}, -- tags
                    alarm.alert.operator,
                    alarm.alert.value,
                    alarm.alert.threshold,
                    alarm.alert.window,
                    alarm.alert.periods,
                    alarm.alert.message)
            end

            afd.inject_afd_metric(msg_type, afd_entity, afd_entity_value, msg_field_name,
                state, hostname, interval, msg_field_source, to_alerting)
        end
    else
        A.set_start_time(ns)
    end
end
