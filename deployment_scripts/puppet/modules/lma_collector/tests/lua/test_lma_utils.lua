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

function inject_message(msg)
    if msg == 'fail' then
        error('fail')
    end
end

function inject_payload(payload_type, payload_name, data)
    if data == 'fail' then
        error('fail')
    end
end

local lma_utils = require('lma_utils')

TestLmaUtils = {}

    function TestLmaUtils:test_safe_json_encode_with_valid_data()
        local ret = lma_utils.safe_json_encode({})
        assertEquals(ret, '{}')
    end

    function TestLmaUtils:test_safe_inject_message_without_error()
        local ret, msg = lma_utils.safe_inject_message({})
        assertEquals(ret, 0)
        assertEquals(msg, nil)
    end

    function TestLmaUtils:test_safe_inject_message_with_error()
        local ret, msg = lma_utils.safe_inject_message('fail')
        assertEquals(ret, -1)
        assert(msg:match(': fail'))
    end

    function TestLmaUtils:test_safe_inject_payload_without_error()
        local ret, msg = lma_utils.safe_inject_payload('txt', 'foo', {})
        assertEquals(ret, 0)
        assertEquals(msg, nil)
    end

    function TestLmaUtils:test_safe_inject_payload_with_error()
        local ret, msg = lma_utils.safe_inject_payload('txt', 'foo', 'fail')
        assertEquals(ret, -1)
        assert(msg:match(': fail'))
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
