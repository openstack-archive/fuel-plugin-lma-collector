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
local time = os.time
local string = string
local table = table
local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local type = type

local Accumulator = {}
Accumulator.__index = Accumulator

setfenv(1, Accumulator) -- Remove external access to contain everything in the module

-- Create a new Accumulator
--
-- flush_count: the maximum number of items to accumulate before flushing
-- flush_interval: the maximum number of seconds to wait before flushing
-- callback: the function to call back when flushing the accumulator, it will
-- receive the table of accumulated items as parameter.
function Accumulator.new(flush_count, flush_interval, callback)
    local a = {}
    setmetatable(a, Accumulator)
    a.flush_count = flush_count
    a.flush_interval = flush_interval
    a.flush_cb = callback
    a.last_flush = time() * 1e9
    a.buffer = {}
    return a
end

-- Flush the buffer if flush_count or flush_interval are met
--
-- ns: the current timestamp in nanosecond (optional)
function Accumulator:flush(ns)
    local now = ns or time() * 1e9
    if #self.buffer > self.flush_count or now - self.last_flush > self.flush_interval then
        self.flush_cb(self.buffer)
        self.buffer = {}
        self.last_flush = now
    end
end

-- Append an item to the buffer and flush the buffer if needed
function Accumulator:append(item)
    self.buffer[#self.buffer+1] = item
    self:flush()
end

return Accumulator
