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
local a = require 'lma_alarms'
local inspect = require 'inspect'

local afd_type = read_config('afd_type') or error('afd_type must be specified!')
local afd_name = read_config('afd_name') or error('afd_name must be specified!')
local afd_tag_field = read_config('afd_tag_field') or error('afd_tag_field must be specified!')

local msg_type = string.format('afd_%s_metric', afd_type)
local msg_field_name = string.format('%s_status', afd_type)
local msg_tag_fields = string.format('%s', afd_tag_field)
local msg_afd_source = string.format('afd_%d_%s', afd_type, afd_name)
local alarm_lib = string.format('lma_alarms_%s_%s', afd_type, afd_name)
local all_alarms = require(alarm_lib)
a.load_alarms(all_alarms)

function process_message()

  local metric_name = read_message('Fields[name]')
  local value = read_message('Fields[value]')
  local ts = read_message('Timestamp')

  -- retrieve field values
  local fields = {}
  for _, field in ipairs (a.get_fields_for_metric(metric_name)) do
    local field_value = afd.get_entity_name(field)
    if not field_value then
      return -1, "Cannot find Fields[" .. field .. "] in the metric " .. metric_name
    end
    fields[field] = field_value
  end
  a.add_value(ts, metric_name, value, fields)
  return 0
end

function timer_event(ns)
  if a.is_started() then
    local global_state, alarms = a.evaluate()
    inject_payload('debug', 'debug', cjson.encode(alarms))
    for _, a in ipairs(alarms) do
        afd.add_to_alarms(
          a.state,
          a.rule.fct,
          a.rule.metric_name,
          a.fields,
          {},
          a.rule.relational_operator,
          a.value,
          a.rule.threshold,
          a.rule.window,
          a.rule.periods,
          a.message,
        )
    end
  else
    inject_payload('debug', 'debug', cjson.encode(all_alarms))
    a.set_start_time(ns)
  end
end
