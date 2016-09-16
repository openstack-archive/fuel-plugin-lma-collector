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

EXPORT_ASSERT_TO_GLOBALS=true
require('luaunit')
package.path = package.path .. ";files/plugins/common/?.lua;tests/lua/mocks/?.lua"

-- mock the inject_message() function from the Heka sandbox library
local last_injected_msg
function inject_message(msg)
    last_injected_msg = msg
end

local afd = require('afd')
local consts = require('gse_constants')
local extra = require('extra_fields')

TestAfd = {}

    function TestAfd:setUp()
        afd.reset_alarms()
    end

    function TestAfd:test_add_to_alarms()
        afd.add_to_alarms(consts.CRIT, 'last', 'metric_1', {}, {}, '==', 0, 0, nil, nil, "crit message")
        local alarms = afd.get_alarms()
        assertEquals(alarms[1].severity, 'CRITICAL')
        assertEquals(alarms[1].metric, 'metric_1')
        assertEquals(alarms[1].message, 'crit message')

        afd.add_to_alarms(consts.WARN, 'last', 'metric_2', {}, {}, '>=', 10, 2, 5, 600, "warn message")
        alarms = afd.get_alarms()
        assertEquals(alarms[2].severity, 'WARN')
        assertEquals(alarms[2].metric, 'metric_2')
        assertEquals(alarms[2].message, 'warn message')
    end

    function TestAfd:test_inject_afd_service_metric_without_alarms()
        afd.inject_afd_service_metric('nova-scheduler', consts.OKAY, 'node-1', 10, 'some_source')

        local alarms = afd.get_alarms()
        assertEquals(#alarms, 0)
        assertEquals(last_injected_msg.Type, 'afd_service_metric')
        assertEquals(last_injected_msg.Fields.value, consts.OKAY)
        assertEquals(last_injected_msg.Fields.hostname, 'node-1')
        assertEquals(last_injected_msg.Payload, '{"alarms":[]}')
    end

    function TestAfd:test_inject_afd_service_metric_with_alarms()
        afd.add_to_alarms(consts.CRIT, 'last', 'metric_1', {}, {}, '==', 0, 0, nil, nil, "important message")
        afd.inject_afd_service_metric('nova-scheduler', consts.CRIT, 'node-1', 10, 'some_source')

        local alarms = afd.get_alarms()
        assertEquals(#alarms, 0)
        assertEquals(last_injected_msg.Type, 'afd_service_metric')
        assertEquals(last_injected_msg.Fields.value, consts.CRIT)
        assertEquals(last_injected_msg.Fields.hostname, 'node-1')
        assertEquals(last_injected_msg.Fields.environment_id, extra.environment_id)
        assert(last_injected_msg.Payload:match('"message":"important message"'))
        assert(last_injected_msg.Payload:match('"severity":"CRITICAL"'))
    end

    function TestAfd:test_alarms_for_human_without_fields()
        local alarms = afd.alarms_for_human({{
            severity='WARNING',
            ['function']='avg',
            metric='load_longterm',
            fields={},
            tags={},
            operator='>',
            value=7,
            threshold=5,
            window=600,
            periods=0,
            message='load too high',
        }})

        assertEquals(#alarms, 1)
        assertEquals(alarms[1], 'load too high (WARNING, rule=\'avg(load_longterm)>5\', current=7.00)')
    end

    function TestAfd:test_alarms_for_human_with_fields()
        local alarms = afd.alarms_for_human({{
            severity='CRITICAL',
            ['function']='avg',
            metric='fs_space_percent_free',
            fields={fs='/'},
            tags={},
            operator='<=',
            value=2,
            threshold=5,
            window=600,
            periods=0,
            message='free disk space too low'
        }})

        assertEquals(#alarms, 1)
        assertEquals(alarms[1], 'free disk space too low (CRITICAL, rule=\'avg(fs_space_percent_free[fs="/"])<=5\', current=2.00)')
    end

    function TestAfd:test_alarms_for_human_with_hostname()
        local alarms = afd.alarms_for_human({{
            severity='WARNING',
            ['function']='avg',
            metric='load_longterm',
            fields={},
            tags={},
            operator='>',
            value=7,
            threshold=5,
            window=600,
            periods=0,
            message='load too high',
            hostname='node-1'
        }})

        assertEquals(#alarms, 1)
        assertEquals(alarms[1], 'load too high (WARNING, rule=\'avg(load_longterm)>5\', current=7.00, host=node-1)')
    end

    function TestAfd:test_alarms_for_human_with_hints()
        local alarms = afd.alarms_for_human({{
            severity='WARNING',
            ['function']='avg',
            metric='load_longterm',
            fields={},
            tags={dependency_level='hint',dependency_name='controller'},
            operator='>',
            value=7,
            threshold=5,
            window=600,
            periods=0,
            message='load too high',
            hostname='node-1'
        }})

        assertEquals(#alarms, 2)
        assertEquals(alarms[1], 'Other related alarms:')
        assertEquals(alarms[2], 'load too high (WARNING, rule=\'avg(load_longterm)>5\', current=7.00, host=node-1)')
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
