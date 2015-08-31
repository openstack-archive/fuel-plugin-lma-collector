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
package.path = package.path .. ";files/plugins/common/?.lua" 
local alarms = require('alarms')
local consts = require('gse_constants')

TestAlarms = {}

    function TestAlarms:test_create_cluster_alarm()
        local alarm = alarms.create_cluster_alarm(
            'controller',
            'gse_node_cluster_metric',
            'node_cluster_status',
            'critical',
            10,
            'gse_node_cluster_plugin',
            {message="some error"},
            {}
        )
        assertEquals(alarm.Type, 'gse_node_cluster_metric')
        assertEquals(alarm.Fields.cluster_name, 'controller')
        assertEquals(alarm.Fields.name, 'node_cluster_status')
        assertEquals(alarm.Fields.value, 'critical')
        assertEquals(alarm.Fields.interval, 10)
        assert(alarm.Payload:match("some error"))
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
