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

local circular_buffer = require('circular_buffer')
local setmetatable = setmetatable
local ipairs = ipairs
local math = require 'math'
local string = string
local table = table

-- LMA libs
local utils = require 'lma_utils'
local consts = require 'gse_constants'

--local print = print
--local inspect = require 'inspect'

local MIN_WINDOW = 10
local MIN_PERIOD = 1
local SECONDS_PER_RAW = 5

local Rule = {}
Rule.__index = Rule

setfenv(1, Rule) -- Remove external access to contain everything in the module

local function get_datastore_id(metric, fields, fct, window, periods)
  local arr = {metric, fct, window, periods}
  for f, v in utils.orderedPairs(fields) do
    table.insert(arr, string.format('(%s=%s)', f, v))
  end
  return table.concat(arr, '/')
end

function Rule.new(rule, datastore)
  local r = {}
  setmetatable(r, Rule)

  local win = MIN_WINDOW
  if rule.window and rule.window > 0 then
    win = rule.window
  end
  r.window = win
  local periods = MIN_PERIOD
  if rule.periods and rule.periods > 0 then
    periods = rule.periods
  end
  r.periods = periods
  r.relational_operator = rule.relational_operator
  r.metric = rule.metric
  r.fields = rule.fields or {}
  r.fct = rule['function']
  r.threshold = rule.threshold
  r.ids_datastore = {}
  r.datastore = datastore

  return r
end

-- store datapoints in cbuf, create the cbuf if not exists
function Rule:add_value(ts, metric, value, fields)
  local data
  if self.metric == metric then
    local uniq_field_id = get_datastore_id(metric, fields, self.fct, self.window, self.periods)
    if not self.datastore[uniq_field_id] then
      local size = math.floor(self.window * self.periods)
      if self.fct == 'avg' then
        cbuf = circular_buffer.new(size, 2, SECONDS_PER_RAW)
        cbuf:set_header(1, self.metric, 'sum', 'sum')
        cbuf:set_header(2, self.metric, 'count', 'sum')
      elseif self.fct == 'min' or self.fct == 'max' then
        cbuf = circular_buffer.new(size, 1, SECONDS_PER_RAW)
        cbuf:set_header(1, self.metric, self.fct)
      else
        cbuf = circular_buffer.new(size, 1, SECONDS_PER_RAW)
        cbuf:set_header(1, self.metric)
      end
      self.datastore[uniq_field_id] = {
        fields = fields,
        cbuf = cbuf,
      }
      self:add_datastore(uniq_field_id)
    end
    data = self.datastore[uniq_field_id]

    if self.fct == 'avg' then
      data.cbuf:add(ts, 1, value)
      data.cbuf:add(ts, 2, 1)
    elseif self.fct == 'min' or self.fct == 'max' then
      data.cbuf:add(ts, 1, value)
    else
      data.cbuf:set(ts, 1, value)
    end
  end
end

function Rule:add_datastore(id)
  if not utils.table_find(id, self.ids_datastore) then
    self.ids_datastore[#self.ids_datastore+1] = id
  end
end

local function compare_threshold(value, op, threshold)
  local rule_matches = false
  if op == '==' or op == 'eq' then
    rule_matches = value == threshold
  elseif op == '!=' or op == 'ne' then
    rule_matches = value ~= threshold
  elseif op == '>=' or op == 'gte' then
    rule_matches = value >= threshold
  elseif op == '>' or op == 'gt' then
    rule_matches = value > threshold
  elseif op == '<=' or op == 'lte' then
    rule_matches = value <= threshold
  elseif op == '<' or op == 'lt' then
    rule_matches = value < threshold
  end
  return rule_matches
end

-- evaluate the rule again datapoints
-- return a list: status(bool), a value, a table of fields table
-- examples:
--   true,  { value=100, fields={{queue='nova'}, {queue='neutron'}}
--   false, { value=10, fields={}}
--
-- TODO: detect missing data to be able to set UNKNOWN state
function Rule:evaluate()
  local fields = {}
  local match = false
  for _, id in ipairs(self.ids_datastore) do
    local data = self.datastore[id]
    if data then
      if self.fct == 'avg' or self.fct == 'max' or self.fct == 'min' or self.fct == 'sum' or self.fct == 'sd' or self.fct == 'variance' or self.fct == 'avg' then
        local result
        if self.fct == 'avg' then
          local total = data.cbuf:compute('sum', 1)
          local count = data.cbuf:compute('sum', 2)
          result = total/count
        else
          result = data.cbuf:compute(self.fct, 1)
        end
        if result then
          match = compare_threshold(result, self.relational_operator, self.threshold)
        --print('RESULT: v:' .. result .. ' thresh: ' .. self.threshold .. ' op: '.. self.relational_operator .. ' match:' .. inspect(match) .. ' metric:' .. self.metric)
        end
        if match then
          fields[#fields+1] = {value=result, fields=data.fields}
        end
      end
    end
  end
  return match, fields
end

return Rule
