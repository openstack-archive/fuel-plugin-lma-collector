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

require('luaunit')
package.path = package.path .. ";files/plugins/common/?.lua;tests/lua/mocks/?.lua"

local table_utils = require('table_utils')

TestTableUtils = {}

    function TestTableUtils:setUp()
        self.array = { 'a', 'b', 'c' }
        self.dict = { c='C', a='A', b='B' }
    end

    function TestTableUtils:test_item_pos_with_match()
        assertEquals(table_utils.item_pos('b', self.array), 2)
    end

    function TestTableUtils:test_item_pos_without_match()
        assertEquals(table_utils.item_pos('z', self.array), nil)
    end

    function TestTableUtils:test_item_find_with_match()
        assertEquals(table_utils.item_find('b', self.array), true)
    end

    function TestTableUtils:test_item_find_without_match()
        assertEquals(table_utils.item_find('z', self.array), false)
    end

    function TestTableUtils:test_deep_copy()
        local copy = table_utils.deepcopy(self.array)
        assertEquals(#copy, #self.array)
        assertEquals(copy[1], self.array[1])
        assertEquals(copy[2], self.array[2])
        assertEquals(copy[3], self.array[3])
        assert(copy ~= self.array)
    end

    function TestTableUtils:test_orderedPairs()
        local t = {}
        for k,v in table_utils.orderedPairs(self.dict) do
            t[#t+1] = { k=k, v=v }
        end
        assertEquals(#t, 3)
        assertEquals(t[1].k, 'a')
        assertEquals(t[1].v, 'A')
        assertEquals(t[2].k, 'b')
        assertEquals(t[2].v, 'B')
        assertEquals(t[3].k, 'c')
        assertEquals(t[3].v, 'C')
    end

    function TestTableUtils:test_table_equal_with_equal_keys_and_values()
        assertTrue(table_utils.table_equal({a = 'a', b = 'b'}, {a = 'a', b = 'b'}))
    end

    function TestTableUtils:test_table_equal_with_nonequal_values()
        assertFalse(table_utils.table_equal({a = 'a', b = 'b'}, {a = 'a', b = 'c'}))
    end

    function TestTableUtils:test_table_equal_with_nonequal_keys_1()
        assertFalse(table_utils.table_equal({a = 'a', b = 'b'}, {a = 'a', c = 'b'}))
    end

    function TestTableUtils:test_table_equal_with_nonequal_keys_2()
        assertFalse(table_utils.table_equal({a = 'a', b = 'b'},
                                            {a = 'a', b = 'b', c = 'c'}))
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
