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

local gse_utils = require('gse_utils')
local consts = require('gse_constants')

TestGseUtils = {}

    function TestGseUtils:test_max_status()
        local status = gse_utils.max_status(consts.DOWN, consts.WARN)
        assertEquals(consts.DOWN, status)
        local status = gse_utils.max_status(consts.OKAY, consts.WARN)
        assertEquals(consts.WARN, status)
        local status = gse_utils.max_status(consts.OKAY, consts.DOWN)
        assertEquals(consts.DOWN, status)
        local status = gse_utils.max_status(consts.UNKW, consts.DOWN)
        assertEquals(consts.DOWN, status)
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
