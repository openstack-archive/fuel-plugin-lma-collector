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
local gse_utils = require 'gse_utils'

local assert = assert
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local string = string
local tonumber = tonumber
local type = type

local print = print
local inspect = require 'inspect'
local GsePolicy = {}
GsePolicy.__index = GsePolicy

setfenv(1, GsePolicy) -- Remove external access to contain everything in the module

local STATUS_VALUES = {
    okay=consts.OKAY,
    warning=consts.WARN,
    unknown=consts.UNKW,
    critical=consts.CRIT,
    down=consts.DOWN
}

function GsePolicy.new(policy)
    local p = {}
    setmetatable(p, GsePolicy)

    p.status = STATUS_VALUES[string.lower(policy.status)]
    assert(p.status)

    p.require_percent = false
    p.rules = {}
    if policy.trigger then
        p.logical_op = string.lower(policy.trigger.logical_operator or 'or')
        for _, r in ipairs(policy.trigger.rules or {}) do
            assert(r['function'] == 'count' or r['function'] == 'percent')
            p.require_percent = p.require_percent or r['function'] == 'percent'
            local rule = {
                ['function']=r['function'],
                relational_op=r.relational_operator,
                threshold=tonumber(r.threshold),
                arguments={}
            }
            for _, v in ipairs(r.arguments) do
                assert(STATUS_VALUES[v])
                rule.arguments[#rule.arguments+1] = STATUS_VALUES[v]
            end
            p.rules[#p.rules+1] = rule
        end
    end

    return p
end

-- return true or false depending on whether the facts match the policy
function GsePolicy:evaluate(facts)
    local total = 0
    if self.require_percent then
        for _, v in pairs(facts) do
            total = total + v
        end
    end

    for _, r in ipairs(self.rules) do
        local rule_match = false
        local value = 0
        for _, status in ipairs(r.arguments) do
            if facts[status] then
                value = value + facts[status]
            end
        end
        if r['function'] == 'percent' then
            value = value * 100 / total
        end

        if gse_utils.compare_threshold(value, r.relational_op, r.threshold) then
            if self.logical_op == 'or' then
                return true
            end
        elseif self.logical_op == 'and' then
            return false
        end
    end

    return true
end

return GsePolicy
