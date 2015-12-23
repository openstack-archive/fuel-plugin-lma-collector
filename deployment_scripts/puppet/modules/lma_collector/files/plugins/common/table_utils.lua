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
local table = require 'table'
local pairs = pairs
local ipairs = ipairs
local type = type

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

-- return a clone of the passed table
function deepcopy(t)
    if type(t) == 'table' then
        local copy = {}
        for k, v in pairs(t) do
            copy[k] = deepcopy(v)
        end
        return copy
    end
    return t
end

-- return the position (index) of an item in a list, nil if not found
function item_pos(item, list)
  if type(list) == 'table' then
    for i, v in ipairs(list) do
      if v == item then
        return i
      end
    end
  end
end

-- return true if an item is present in the list, false otherwise
function item_find(item, list)
    return item_pos(item, list) ~= nil
end

-- from http://lua-users.org/wiki/SortedIteration
function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    key = nil
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1,table.getn(t.__orderedIndex) do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

-- Shallow comparison between two tables.
-- Return true if the two tables have the same keys with identical
-- values, otherwise false.
function table_equal(t1, t2)
    -- all key-value pairs in t1 must be in t2
    for k, v in pairs(t1) do
        if t2[k] ~= v then return false end
    end
    -- there must not be other keys in t2
    for k, v in pairs(t2) do
        if t1[k] == nil then return false end
    end
    return true
end

return M
