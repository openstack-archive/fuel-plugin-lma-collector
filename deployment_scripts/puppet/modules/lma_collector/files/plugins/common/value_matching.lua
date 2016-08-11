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

local l = require "lpeg"
l.locale(l)

local patterns = require 'patterns'
local error = error
local setmetatable = setmetatable
local tonumber = tonumber

local C = l.C
local P = l.P
local S = l.S
local V = l.V
local Ct = l.Ct
local Cc = l.Cc

local Space = patterns.sp^0
local Only_spaces = patterns.sp^1 * -1

local function space(pat)
    return Space * pat * Space
end

local Number = P"-"^-1 * l.xdigit^1 * (S(".,") * l.xdigit^1 )^-1 / tonumber

local EQ = P'=='
local NEQ = P'!='
local GT = P'>'
local LT = P'<'
local GTE = P'>='
local LTE = P'<='
local MATCH = P'=~'
local NO_MATCH = P'!~'

local OR = P'||'
local AND = P'&&'

local function default_relational_operator(op)
    if op == '' then
        return '=='
    end
    return op
end

local ops_number = (EQ + NEQ + LTE + GTE + GT + LT )^-1 / default_relational_operator
local sub_exp_number = space(ops_number) * Number * Space
local is_numeric = (sub_exp_number * ((OR^1 + AND^1) * sub_exp_number)^0) * -1

local quoted_string = (P'"' * C((P(1) - (P'"'))^1) * P'"' + C((P(1) - patterns.sp)^1))
local ops_string = (EQ + NEQ + MATCH + NO_MATCH)^-1 / default_relational_operator
local sub_exp_string = space(ops_string) * quoted_string * Space
local is_string = (sub_exp_string * ((OR^1 + AND^1) * sub_exp_string)^0) * -1

local expr_number = P {
    'OR';
    AND = Ct(Cc('and') * V'SUB' * space(AND) * V'AND' + V'SUB'),
    OR = Ct(Cc('or') * V'AND' * space(OR) * V'OR' + V'AND'),
    SUB = Ct(sub_exp_number)
} * -1

local expr_string = P {
    'OR';
    AND = Ct(Cc('and') * V'SUB' * space(AND) * V'AND' + V'SUB'),
    OR = Ct(Cc('or') * V'AND' * space(OR) * V'OR' + V'AND'),
    SUB = Ct(sub_exp_string)
} * -1

local is_complex = patterns.anywhere(EQ + NEQ + LTE + GTE + GT + LT + MATCH + NO_MATCH + OR + AND)

local function eval_tree(tree, value)
    local match = false
    local op

    if type(tree[1]) == 'table' then
        match = eval_tree(tree[1], value)
    else
        local what = tree[1]
        local comp = tree[2]
        if what == 'and' or what == 'or' then
            op = tree[1]
            match = eval_tree(tree[2], value)
            for i=3, #tree, 1 do
                local m = eval_tree(tree[i], value)
                if op == 'or' then
                    match = match or m
                else
                    match = match and m
                end
            end
        else
            if what == '==' then
                return value == comp
            elseif what == '!=' then
                return value ~= comp
            elseif what == '>' then
                return value > comp
            elseif what == '<' then
                return value < comp
            elseif what == '>=' then
                return value >= comp
            elseif what == '<=' then
                return value <= comp
            elseif what == '=~' then
                -- TODO(scroiset): use lpeg.re
                return false
            elseif what == '!~' then
                -- TODO(scroiset): use lpeg.re
                return false
            end
        end
    end
    return match
end

local Match = {}
Match.__index = Match

setfenv(1, Match) -- Remove external access to contain everything in the module

function Match.new(expression)
    local r = {}
    setmetatable(r, Match)
    if is_complex:match(expression) then
        r.is_numeric_exp = is_numeric:match(expression) ~= nil

        if r.is_numeric_exp then
            r.tree = expr_number:match(expression)
        elseif is_string:match(expression) ~= nil then
            r.tree = expr_string:match(expression)
        end
        if r.tree == nil then
            error('Invalid expression: ' .. expression)
        end
    else
        if expression == '' or Only_spaces:match(expression) then
            error('Expression is empty')
        end
        r.is_simple_equality_matching = true
    end
    r.expression = expression

    return r
end

function Match:matches(value)
    if self.is_simple_equality_matching then
        return self.expression == value or
                tonumber(self.expression) == value or
                tonumber(value) == self.expression
    end
    if self.is_numeric_exp then
        value = tonumber(value)
        if value == nil then
            return false
        end
    end
    return eval_tree(self.tree, value)
end

return Match
