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

-- mock the inject_message() function from the Heka sandbox library
local last_injected_msg
function inject_message(msg)
    last_injected_msg = msg
end

local afd = require('afd')
local extra = require('extra_fields')

TestAfd = {}

    function TestAfd:setUp()
        afd.reset_alarms()
    end

    function TestAfd:test_add_to_alarms()
        afd.add_to_alarms('crit', 'last', 'metric_1', '==', 0, nil, nil, "crit message")
        local alarms = afd.get_alarms()
        assertEquals(alarms[1].metric, 'metric_1')
        assertEquals(alarms[1].message, 'crit message')

        afd.add_to_alarms('warn', 'last', 'metric_2', '>=', 2, 5, 600, "warn message")
        alarms = afd.get_alarms()
        assertEquals(alarms[2].metric, 'metric_2')
        assertEquals(alarms[2].message, 'warn message')
    end

    function TestAfd:test_inject_afd_service_event_without_alarms()
        afd.inject_afd_service_event('nova-scheduler', 'okay', 10, 'some_source')

        local alarms = afd.get_alarms()
        assertEquals(#alarms, 0)
        assertEquals(last_injected_msg.Type, 'afd_service_metric')
        assertEquals(last_injected_msg.Fields.value, 'okay')
        assertEquals(last_injected_msg.Payload, '{"alarms":[]}')
    end

    function TestAfd:test_inject_afd_service_event_with_alarms()
        afd.add_to_alarms('crit', 'last', 'metric_1', '==', 0, nil, nil, "crit message")
        afd.inject_afd_service_event('nova-scheduler', 'crit', 10, 'some_source')

        local alarms = afd.get_alarms()
        assertEquals(#alarms, 0)
        assertEquals(last_injected_msg.Type, 'afd_service_metric')
        assertEquals(last_injected_msg.Fields.value, 'crit')
        assertEquals(last_injected_msg.Fields.environment_id, extra.environment_id)
        assert(last_injected_msg.Payload:match('crit message'))
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
