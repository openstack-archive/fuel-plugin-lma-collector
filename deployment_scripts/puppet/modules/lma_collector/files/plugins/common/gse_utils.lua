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

local consts = require 'gse_constants'

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local STATUS_WEIGHTS = {
    [consts.UNKW]=0,
    [consts.OKAY]=1,
    [consts.WARN]=2,
    [consts.CRIT]=3,
    [consts.DOWN]=4
}

function max_status(val1, val2)
    if not val1 then
        return val2
    elseif not val2 then
        return val1
    elseif STATUS_WEIGHTS[val1] > STATUS_WEIGHTS[val2] then
        return val1
    else
        return val2
    end
end

function compare_threshold(value, op, threshold)
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

return M
