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

local anomaly = require('anomaly')
local circular_buffer = require('circular_buffer')
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local math = require 'math'
local string = string
local table = table
local assert = assert
local type = type

-- LMA libs
local utils = require 'lma_utils'
local table_utils = require 'table_utils'
local consts = require 'gse_constants'
local gse_utils = require 'gse_utils'
local afd = require 'afd'
local matching = require 'value_matching'

local MIN_WINDOW = 10
local MIN_PERIOD = 1
local SECONDS_PER_ROW = 5

local Rule = {}
Rule.__index = Rule

setfenv(1, Rule) -- Remove external access to contain everything in the module

function Rule.new(rule)
    local r = {}
    setmetatable(r, Rule)

    local win = MIN_WINDOW
    if rule.window and rule.window + 0 > 0 then
        win = rule.window + 0
    end
    r.window = win
    local periods = MIN_PERIOD
    if rule.periods and rule.periods + 0 > 0 then
        periods = rule.periods + 0
    end
    r.periods = periods
    r.relational_operator = rule.relational_operator
    r.metric = rule.metric
    r.fields = rule.fields or {}

    -- build field matching
    r.field_matchers = {}
    for f, expression in pairs(r.fields) do
        r.field_matchers[f] = matching.new(expression)
    end

    r.fct = rule['function']
    r.threshold = rule.threshold + 0
    r.value_index = rule.value or nil -- Can be nil

    -- build unique rule id
    local arr = {r.metric, r.fct, r.window, r.periods}
    for f, v in table_utils.orderedPairs(r.fields or {}) do
        arr[#arr+1] = string.format('(%s=%s)', f, v)
    end
    r.rule_id = table.concat(arr, '/')

    r.group_by = rule.group_by or {}

    if r.fct == 'roc' then
        -- We use the name of the metric as the payload_name.
        --
        -- The ROC algorithm needs the following parameters:
        --   - the number of intervals in the analysis window
        --   - the number of intervals in the historical analysis window
        --   - the threshold
        --
        -- r.window is an interval in seconds. So to get the number of
        -- intervals we divide r.window by the number of seconds per row.
        --
        -- r.periods represents the number of windows that we want to use for
        -- the historical analysis. As we tell the ROC algorithm to use all
        -- remaining buffer for the historical window we need to allocate
        -- r.periods * (r.window / SECONDS_PER_ROW) for the historical
        -- analysis and 2 additional periods for the previous and current
        -- analysis windows.
        --
        local cfg_str = string.format('roc("%s",1,%s,0,%s,false,false)',
                                       r.metric,
                                       math.ceil(r.window/SECONDS_PER_ROW),
                                       r.threshold)
        r.roc_cfg = anomaly.parse_config(cfg_str)
        r.cbuf_size = math.ceil(r.window / SECONDS_PER_ROW) * (r.periods + 2)
    else
        r.roc_cfg = nil
        r.cbuf_size = math.ceil(r.window * r.periods / SECONDS_PER_ROW)
    end
    r.ids_datastore = {}
    r.datastore = {}
    r.observation_window = math.ceil(r.window * r.periods)

    return r
end

function Rule:get_datastore_id(fields)
    if #self.group_by == 0 or fields == nil then
        return self.rule_id
    end

    local arr = {}
    arr[#arr + 1] = self.rule_id
    for _, g in ipairs(self.group_by) do
        arr[#arr + 1] = fields[g]
    end
    return table.concat(arr, '/')
end

function Rule:fields_accepted(fields)
    if not fields then
        fields = {}
    end
    local matched_fields = 0
    local no_match_on_fields = true
    for f, expression in pairs(self.field_matchers) do
        no_match_on_fields = false
        for k, v in pairs(fields) do
            if k == f then
                if expression:matches(v) then
                    matched_fields = matched_fields + 1
                else
                    return false
                end
            end
        end
    end
    return no_match_on_fields or matched_fields > 0
end

function Rule:get_circular_buffer()
    local cbuf
    if self.fct == 'avg' then
        cbuf = circular_buffer.new(self.cbuf_size, 2, SECONDS_PER_ROW)
        cbuf:set_header(1, self.metric, 'sum', 'sum')
        cbuf:set_header(2, self.metric, 'count', 'sum')
    elseif self.fct == 'min' or self.fct == 'max' then
        cbuf = circular_buffer.new(self.cbuf_size, 1, SECONDS_PER_ROW)
        cbuf:set_header(1, self.metric, self.fct)
    else
        cbuf = circular_buffer.new(self.cbuf_size, 1, SECONDS_PER_ROW)
        cbuf:set_header(1, self.metric)
    end
    return cbuf
end

-- store datapoints in cbuf, create the cbuf if not exists.
-- value can be a table where the index to choose is referenced by self.value_index
function Rule:add_value(ts, value, fields)
    if not self:fields_accepted(fields) then
        return
    end
    if type(value) == 'table' then
        value = value[self.value_index]
    end
    if value == nil then
        return
    end

    local data
    local uniq_field_id = self:get_datastore_id(fields)
    if not self.datastore[uniq_field_id] then
        self.datastore[uniq_field_id] = {
            fields = self.fields,
            cbuf = self:get_circular_buffer()
        }
        if #self.group_by > 0 then
            self.datastore[uniq_field_id].fields = fields
        end

        self:add_datastore(uniq_field_id)
    end
    data = self.datastore[uniq_field_id]

    if self.fct == 'avg' then
        data.cbuf:add(ts, 1, value)
        data.cbuf:add(ts, 2, 1)
    else
        data.cbuf:set(ts, 1, value)
    end
end

function Rule:add_datastore(id)
    if not table_utils.item_find(id, self.ids_datastore) then
        self.ids_datastore[#self.ids_datastore+1] = id
    end
end

function Rule:compare_threshold(value)
    return gse_utils.compare_threshold(value, self.relational_operator, self.threshold)
end

local function isnumber(value)
    return value ~= nil and not (value ~= value)
end

local available_functions = {last=true, avg=true, max=true, min=true, sum=true,
                             variance=true, sd=true, diff=true, roc=true}

-- evaluate the rule against datapoints
-- return a list: match (bool or string), context ({value=v, fields=list of field table})
--
-- examples:
--   true, { {value=100, fields={{queue='nova'}, {queue='neutron'}}, ..}
--   false, { {value=10, fields={}}, ..}
-- with 2 special cases:
--   - never receive one datapoint
--      'nodata', {}
--   - no more datapoint received for a metric
--      'missing', {value=-1, fields={}}
-- There is a drawback with the 'missing' state and could leads to emit false positive
-- state. For example when the monitored thing has been renamed/deleted,
-- it's normal to don't receive datapoint anymore .. for example a filesystem.
function Rule:evaluate(ns)
    local fields = {}
    local one_match, one_no_match, one_missing_data = false, false, false
    for _, id in ipairs(self.ids_datastore) do
        local data = self.datastore[id]
        if data then
            local cbuf_time = data.cbuf:current_time()
            -- if we didn't receive datapoint within the observation window this means
            -- we don't receive anymore data and cannot compute the rule.
            if ns - cbuf_time > self.observation_window * 1e9 then
                one_missing_data = true
                fields[#fields+1] = {value = -1, fields = data.fields}
            else
                assert(available_functions[self.fct])
                local result

                if self.fct == 'roc' then
                    local anomaly_detected, _ = anomaly.detect(ns, self.metric, data.cbuf, self.roc_cfg)
                    if anomaly_detected then
                        one_match = true
                        fields[#fields+1] = {value=-1, fields=data.fields}
                    else
                        one_no_match = true
                    end
                elseif self.fct == 'avg' then
                    local total
                    total = data.cbuf:compute('sum', 1)
                    local count = data.cbuf:compute('sum', 2)
                    result = total/count
                elseif self.fct == 'last' then
                    local last
                    local t = ns
                    while (not isnumber(last)) and t >= ns - self.observation_window * 1e9 do
                        last = data.cbuf:get(t, 1)
                        t = t - SECONDS_PER_ROW * 1e9
                    end
                    if isnumber(last) then
                        result = last
                    else
                        one_missing_data = true
                        fields[#fields+1] = {value = -1, fields = data.fields}
                    end
                elseif self.fct == 'diff' then
                    local first, last

                    local t = ns
                    while (not isnumber(last)) and t >= ns - self.observation_window * 1e9 do
                        last = data.cbuf:get(t, 1)
                        t = t - SECONDS_PER_ROW * 1e9
                    end

                    if isnumber(last) then
                        t = ns - self.observation_window * 1e9
                        while (not isnumber(first)) and t <= ns do
                            first = data.cbuf:get(t, 1)
                            t = t + SECONDS_PER_ROW * 1e9
                        end
                    end

                    if not isnumber(last) or not isnumber(first) then
                        one_missing_data = true
                        fields[#fields+1] = {value = -1, fields = data.fields}
                    else
                        result = last - first
                    end
                else
                    result = data.cbuf:compute(self.fct, 1)
                end

                if result then
                    local m = self:compare_threshold(result)
                    if m then
                        one_match = true
                        fields[#fields+1] = {value=result, fields=data.fields}
                    else
                        one_no_match = true
                    end
                end
            end
        end
    end
    if one_match then
        return afd.MATCH, fields
    elseif one_missing_data then
        return afd.MISSING_DATA, fields
    elseif one_no_match then
        return afd.NO_MATCH, {}
    else
        return afd.NO_DATA, {{value=-1, fields=self.fields}}
    end
end

return Rule
