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
require('os')
package.path = package.path .. ";files/plugins/common/?.lua;tests/lua/mocks/?.lua"

local patt = require('patterns')
local l = require('lpeg')

TestPatterns = {}

    function TestPatterns:test_Uuid()
        assertEquals(patt.Uuid:match('be6876f2-c1e6-42ea-ad95-792a5500f0fa'),
                                     'be6876f2-c1e6-42ea-ad95-792a5500f0fa')
        assertEquals(patt.Uuid:match('be6876f2c1e642eaad95792a5500f0fa'),
                                     'be6876f2-c1e6-42ea-ad95-792a5500f0fa')
        assertEquals(patt.Uuid:match('ze6876f2c1e642eaad95792a5500f0fa'),
                                     nil)
        assertEquals(patt.Uuid:match('be6876f2-c1e642eaad95792a5500f0fa'),
                                     nil)
    end

    function TestPatterns:test_Timestamp()
        -- note that Timestamp:match() returns the number of nanosecs since the
        -- Epoch in the local timezone
        local_epoch = os.time(os.date("!*t",0)) * 1e9
        assertEquals(patt.Timestamp:match('1970-01-01 00:00:01+00:00'),
                                          local_epoch + 1e9)
        assertEquals(patt.Timestamp:match('1970-01-01 00:00:02'),
                                          local_epoch + 2e9)
        assertEquals(patt.Timestamp:match('1970-01-01 00:00:03'),
                                          local_epoch + 3e9)
        assertEquals(patt.Timestamp:match('1970-01-01T00:00:04-00:00'),
                                          local_epoch + 4e9)
        assertEquals(patt.Timestamp:match('1970-01-01 01:00:05+01:00'),
                                          local_epoch + 5e9)
        assertEquals(patt.Timestamp:match('1970-01-01 00:00:00.123456+00:00'),
                                          local_epoch + 0.123456 * 1e9)
        assertEquals(patt.Timestamp:match('1970-01-01 00:01'),
                                          nil)
    end

    function TestPatterns:test_programname()
        assertEquals(l.C(patt.programname):match('nova-api'), 'nova-api')
        assertEquals(l.C(patt.programname):match('nova-api foo'), 'nova-api')
    end

    function TestPatterns:test_anywhere()
        assertEquals(patt.anywhere(l.C(patt.dash)):match(' - '), '-')
        assertEquals(patt.anywhere(patt.dash):match(' . '), nil)
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
