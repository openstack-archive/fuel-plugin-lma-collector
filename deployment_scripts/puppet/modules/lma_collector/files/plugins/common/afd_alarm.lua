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

local ipairs = ipairs
local pairs = pairs
local string = string
local setmetatable = setmetatable

-- LMA libs
local utils = require 'lma_utils'
local consts = require 'gse_constants'
local afd = require 'afd'
local Rule = require 'afd_rule'

local STATUS = {
  warn = consts.WARN,
  warning = consts.WARN,
  unknown = consts.UNKW,
  critical = consts.CRIT,
  crit = consts.CRIT,
  down = consts.DOWN,
}

local Alarm = {}
Alarm.__index = Alarm

setfenv(1, Alarm) -- Remove external access to contain everything in the module

function Alarm.new(alarm)
  local a = {}
  setmetatable(a, Alarm)
  a._metrics_list = nil
  a.alarm = alarm
  if alarm.trigger.logical_operator then
    a.logical_operator = string.lower(alarm.trigger.logical_operator)
  else
    a.logical_operator = 'or'
  end
  a.severity = STATUS[string.lower(alarm.severity)]
  a.rules = {}
  a.initial_wait = 0
  for _, rule in ipairs(alarm.trigger.rules) do
    local r = Rule.new(rule)
    a.rules[#a.rules+1] = r
    local wait = r.window * r.periods
    if wait > a.initial_wait then
        a.initial_wait = wait * 1e9
    end
  end
  a.start_time_ns = 0

  return a
end

-- return a Set of metrics used by the alarm
function Alarm:get_metrics()
  if self._metrics_list then
    return self._metrics_list
  end
  local metrics = {}
  for _, rule in ipairs(self.rules) do
    if not utils.table_find(rule.metric, metrics) then
      metrics[#metrics+1] = rule.metric
    end
  end
  self._metrics_list = metrics
  return metrics
end

-- return a list of field name used for the metric
-- (can have duplicate names)
function Alarm:get_metric_fields(metric_name)
  local fields = {}
  for _, rule in ipairs(self.rules) do
    if rule.metric == metric_name then
      for k, _ in pairs(rule.fields) do
        fields[#fields+1] = k
      end
    end
  end
  return fields
end

function Alarm:has_metric(metric)
  local metrics = self:get_metrics()
  if utils.table_find(metric, metrics) then
    return true
  end
  return false
end

local all_fields = '__all__'
-- dispatch datapoint in datastores
function Alarm:add_value(ts, metric, value, fields)
  local data
--  if not fields or utils.table_length(fields) == 0 then
--    -- special case when no fields is specified
--    fields = {}
--    fields[all_fields]=all_fields
--  end
  for id, rule in pairs(self.rules) do
    if rule.metric == metric then
      rule:add_value(ts, metric, value, fields)
    end
  end
end

-- convert fields to fields map
-- {foo="bar"} --> {name="foo", value="bar"}
-- {"__all__"="__all__" } --> {}
local function convert_field_list(fields)
  local named_fields = {}
  for name, value in pairs(fields or {}) do
      if name ~= all_fields then
          named_fields[#named_fields+1] = {name=name, value=value}
      end
  end
  return named_fields
end

-- return: state of alarm and a list of the alert
--
-- with alert list:
-- {
--  { rule = <rule object>,
--    value = <current value>,
--    fields = <metric fields table>,
--    message = <string>,
--  }
-- }
function Alarm:evaluate()
  local state = consts.OKAY
  local all_alerts = {}
  for _, rule in ipairs(self.rules) do
    local boom, context_list = rule:evaluate()
    if boom then
      for _, context in ipairs(context_list) do
        local rule_alerts = {
            rule=rule,
            ['function'] = rule.fct,
            metric_name = rule.metric_name,
            relational_operator = rule.relational_operator,
            threshold = rule.threshold,
            window = rule.window,
            periods = rule.periods,
            value=context.value,
            fields=convert_field_list(context.fields),
            message=self.alarm.description,
        }
        all_alerts[#all_alerts+1] = rule_alerts
      end
    elseif self.logical_operator == 'and' then
      all_alerts = {}
      break
    end
  end
  if #all_alerts > 0 then
    state = self.severity
  end
  return state, all_alerts
end

function Alarm:set_start_time(ns)
    self.start_time_ns = ns
end

function Alarm:can_evaluate(ns)
    local delta = ns - self.start_time_ns
    if self.start_time_ns > 0 and delta >= self.initial_wait then
        return true
    end
    return false
end

return Alarm
