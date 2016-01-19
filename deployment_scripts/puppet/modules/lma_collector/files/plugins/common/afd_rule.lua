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

-- LMA libs
local utils = require 'lma_utils'
local table_utils = require 'table_utils'
local consts = require 'gse_constants'
local gse_utils = require 'gse_utils'
local afd = require 'afd'

local MIN_WINDOW = 10
local MIN_PERIOD = 1
local SECONDS_PER_ROW = 5

local Rule = {}
Rule.__index = Rule

setfenv(1, Rule) -- Remove external access to contain everything in the module

local function get_datastore_id(metric, fields, fct, window, periods)
    local arr = {metric, fct, window, periods}
    for f, v in table_utils.orderedPairs(fields or {}) do
        arr[#arr+1] = string.format('(%s=%s)', f, v)
    end
    return table.concat(arr, '/')
end

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
    r.fct = rule['function']
    if r.fct == 'roc' then
        r.roc_cfg = anomaly.parse_config(rule.metric, 1, rule.window, 0,
                                         rule.threshold, true, false)
    else
        r.roc_cfg = nil
    end
    r.threshold = rule.threshold + 0
    r.ids_datastore = {}
    r.datastore = {}
    r.observation_window = math.ceil(r.window * r.periods)
    r.cbuf_size = math.ceil(r.window * r.periods / SECONDS_PER_ROW)

    return r
end

function Rule:fields_accepted(fields)
    if not fields then
        fields = {}
    end
    local matched_fields = 0
    local no_match_on_fields = true
    for f, wanted in pairs(self.fields) do
        no_match_on_fields = false
        for k, v in pairs(fields) do
            if k == f and wanted == '*' then
                matched_fields = matched_fields + 1
            elseif k == f and v == wanted then
                matched_fields = matched_fields + 1
            elseif k == f and v ~= wanted then
                return false
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

-- store datapoints in cbuf, create the cbuf if not exists
function Rule:add_value(ts, value, fields)
    if not self:fields_accepted(fields) then
        return
    end
    local data
    local uniq_field_id = get_datastore_id(self.metric, fields, self.fct, self.window, self.periods)
    if not self.datastore[uniq_field_id] then
        self.datastore[uniq_field_id] = {
            fields = fields,
            cbuf = self:get_circular_buffer()
        }
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

local available_functions = {avg=true, max=true, min=true, sum=true,
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
                if available_functions[self.fct] then
                    local result
                    if self.fct == 'avg' then
                        local total
                        total = data.cbuf:compute('sum', 1)
                        local count = data.cbuf:compute('sum', 2)
                        result = total/count
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
                    elseif self.fct == 'roc' then
                        result, annot = anomaly.detect(ns, self.metric,
                                                       data.cbuf, self.roc_cfg)
                    else
                        result = data.cbuf:compute(self.fct, 1)
                    end
                    if result then
                        if self.fct == 'roc' then
                            one_match = true
                            fields[#fields+1] = {value=annot[1].x, fields=data.fields}
                        else
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
