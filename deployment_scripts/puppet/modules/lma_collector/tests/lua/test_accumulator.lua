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

EXPORT_ASSERT_TO_GLOBALS=true
require('luaunit')
require('os')
package.path = package.path .. ";files/plugins/common/?.lua;tests/lua/mocks/?.lua"

local accumulator = require('accumulator')

TestAccumulator = {}

    function TestAccumulator:test_flush_on_append()
        local sentinel = false
        local function test_cb(items)
            assertEquals(#items, 3)
            sentinel = true
        end
        local accum = accumulator.new(2, 5, test_cb)
        accum:append(1)
        assertEquals(sentinel, false)
        accum:append(2)
        assertEquals(sentinel, false)
        accum:append(3)
        assertEquals(sentinel, true)
    end

    function TestAccumulator:test_flush_interval_with_buffer()
        local now = os.time()
        local sentinel = false
        local function test_cb(items)
            assertEquals(#items, 1)
            sentinel = true
        end
        local accum = accumulator.new(20, 1, test_cb)
        accum:append(1)
        assertEquals(sentinel, false)
        accum:flush((now + 2) * 1e9)
        assertEquals(sentinel, true)
    end

    function TestAccumulator:test_flush_interval_with_empty_buffer()
        local now = os.time()
        local sentinel = false
        local function test_cb(items)
            assertEquals(#items, 0)
            sentinel = true
        end
        local accum = accumulator.new(20, 1, test_cb)
        accum:flush((now + 2) * 1e9)
        assertEquals(sentinel, true)
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )

