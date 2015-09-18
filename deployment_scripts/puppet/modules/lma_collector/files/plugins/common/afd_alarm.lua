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
local gse = require 'gse'
local afd = require 'afd'
local Rule = require 'afd_rule'

local STATUS = {
    warning = consts.WARN,
    unknown = consts.UNKW,
    critical = consts.CRIT,
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
    a.name = alarm.name
    a.description = alarm.description
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

-- return the Set of metrics used by the alarm
function Alarm:get_metrics()
    if not self._metrics_list then
        self._metrics_list = {}
        for _, rule in ipairs(self.rules) do
            if not utils.table_find(rule.metric, metrics) then
                self._metrics_list[#self._metrics_list+1] = rule.metric
            end
        end
    end
    return self._metrics_list
end

-- return a list of field names used for the metric
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

-- dispatch datapoint in datastores
function Alarm:add_value(ts, metric, value, fields)
    local data
    for id, rule in pairs(self.rules) do
        if rule.metric == metric then
            rule:add_value(ts, value, fields)
        end
    end
end

-- convert fields to fields map
-- {foo="bar"} --> {name="foo", value="bar"}
local function convert_field_list(fields)
    local named_fields = {}
    for name, value in pairs(fields or {}) do
        named_fields[#named_fields+1] = {name=name, value=value}
    end
    return named_fields
end

-- return: state of alarm and a list of alarm details.
--
-- with alarm list when state != OKAY:
-- {
--  {
--    value = <current value>,
--    fields = <metric fields table>,
--    message = <string>,
--  },
-- }
function Alarm:evaluate(ns)
    local state = consts.UNKW
    local all_alerts = {}
    local function add_alarm(rule, value, message, fields)
        all_alerts[#all_alerts+1] = {
            severity = self.alarm.severity,
            ['function'] = rule.fct,
            metric = rule.metric,
            operator = rule.relational_operator,
            threshold = rule.threshold,
            window = rule.window,
            periods = rule.periods,
            value = value,
            fields = fields,
            message = message
        }
    end
    local previous_state
    for _, rule in ipairs(self.rules) do
        local boom, context_list = rule:evaluate(ns)
        if boom == afd.MATCH then
            state = self.severity
            for _, context in ipairs(context_list) do
                add_alarm(rule, context.value, self.alarm.description,
                          convert_field_list(context.fields))
            end
        else
            if boom == afd.MISSINGDATAPOINT then
                -- TODO: remove this if/else when UNKW weight is decreased
                if state == consts.OKAY then
                    state = consts.UNKW
                else
                    state = gse.max_status(state, consts.UNKW)
                end
                local msg = 'Missing datapoints for the last ' .. rule.observation_window .. ' seconds'
                add_alarm(rule, -2, msg, convert_field_list(rule.fields))
            elseif boom == afd.NODATAPOINT then
                -- TODO: remove this if/else when UNKW weight is decreased
                if state == consts.OKAY then
                    state = consts.UNKW
                else
                    state = gse.max_status(state, consts.UNKW)
                end
                add_alarm(rule, -1, 'No datapoint for evaluation', convert_field_list(rule.fields))
            else
                if self.logical_operator == 'and' then
                    if state ~= consts.UNKW then
                         all_alerts = {}
                         state = consts.OKAY
                         break
                    end
                end
                state = gse.max_status(state, consts.OKAY)
            end
        end
    end
    return state, all_alerts
end

function Alarm:set_start_time(ns)
    self.start_time_ns = ns
end

function Alarm:is_evaluation_time(ns)
    local delta = ns - self.start_time_ns
    if delta >= self.initial_wait then
        return true
    end
    return false
end

return Alarm
