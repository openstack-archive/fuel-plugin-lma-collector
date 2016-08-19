-- Copyright 2016 Mirantis, Inc.
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
local pcall = pcall
local string = require 'string'

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

local Optional_space = patterns.sp^0
local Only_spaces = patterns.sp^1 * -1

local function space(pat)
    return Optional_space * pat * Optional_space
end

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

local function get_operator(op)
    if op == '' then
        return '=='
    end
    return op
end

local numerical_operator = (EQ + NEQ + LTE + GTE + GT + LT )^-1 / get_operator
local sub_numerical_expression = space(numerical_operator) * patterns.Number * Optional_space
local is_plain_numeric = (sub_numerical_expression * ((OR^1 + AND^1) * sub_numerical_expression)^0) * -1

local quoted_string = (P'"' * C((P(1) - (P'"'))^1) * P'"' + C((P(1) - patterns.sp)^1))
local string_operator = (EQ + NEQ + MATCH + NO_MATCH)^-1 / get_operator
local sub_string_expression = space(string_operator) * quoted_string * Optional_space
local is_plain_string = (sub_string_expression * ((OR^1 + AND^1) * sub_string_expression)^0) * -1

local numerical_expression = P {
    'OR';
    AND = Ct(Cc('and') * V'SUB' * space(AND) * V'AND' + V'SUB'),
    OR = Ct(Cc('or') * V'AND' * space(OR) * V'OR' + V'AND'),
    SUB = Ct(sub_numerical_expression)
} * -1

local string_expression = P {
    'OR';
    AND = Ct(Cc('and') * V'SUB' * space(AND) * V'AND' + V'SUB'),
    OR = Ct(Cc('or') * V'AND' * space(OR) * V'OR' + V'AND'),
    SUB = Ct(sub_string_expression)
} * -1

local is_complex = patterns.anywhere(EQ + NEQ + LTE + GTE + GT + LT + MATCH + NO_MATCH + OR + AND)

local function eval_tree(tree, value)
    local match = false

    if type(tree[1]) == 'table' then
        match = eval_tree(tree[1], value)
    else
        local operator = tree[1]
        if operator == 'and' or operator == 'or' then
            match = eval_tree(tree[2], value)
            for i=3, #tree, 1 do
                local m = eval_tree(tree[i], value)
                if operator == 'or' then
                    match = match or m
                else
                    match = match and m
                end
            end
        else
            local matcher = tree[2]
            if operator == '==' then
                return value == matcher
            elseif operator == '!=' then
                return value ~= matcher
            elseif operator == '>' then
                return value > matcher
            elseif operator == '<' then
                return value < matcher
            elseif operator == '>=' then
                return value >= matcher
            elseif operator == '<=' then
                return value <= matcher
            elseif operator == '=~' then
                local ok, m = pcall(string.find, value, matcher)
                return ok and m ~= nil
            elseif operator == '!~' then
                local ok, m = pcall(string.find, value, matcher)
                return ok and m == nil
            end
        end
    end
    return match
end

local MatchExpression = {}
MatchExpression.__index = MatchExpression

setfenv(1, MatchExpression) -- Remove external access to contain everything in the module

function MatchExpression.new(expression)
    local r = {}
    setmetatable(r, MatchExpression)
    if is_complex:match(expression) then
        r.is_plain_numeric_exp = is_plain_numeric:match(expression) ~= nil

        if r.is_plain_numeric_exp then
            r.tree = numerical_expression:match(expression)
        elseif is_plain_string:match(expression) ~= nil then
            r.tree = string_expression:match(expression)
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

function MatchExpression:matches(value)
    if self.is_simple_equality_matching then
        return self.expression == value or
                tonumber(self.expression) == value or
                tonumber(value) == self.expression
    end
    if self.is_plain_numeric_exp then
        value = tonumber(value)
        if value == nil then
            return false
        end
    end
    return eval_tree(self.tree, value)
end

return MatchExpression
