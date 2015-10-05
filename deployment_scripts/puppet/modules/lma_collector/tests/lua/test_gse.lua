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

local gse = require('gse')
local consts = require('gse_constants')

-- configure relations and dependencies
gse.level_1_dependency("keystone", "keystone_admin")
gse.level_1_dependency("keystone", "keystone_main")
gse.level_1_dependency("neutron", "neutron_api")
gse.level_1_dependency("nova", "nova_api")
gse.level_1_dependency("nova", "keystone_api")
gse.level_1_dependency("nova", "nova_ec2_api")
gse.level_1_dependency("nova", "nova_scheduler")
gse.level_1_dependency("glance", "glance_api")
gse.level_1_dependency("glance", "glance_registry")

gse.level_2_dependency("nova_api", "neutron_api")
gse.level_2_dependency("nova_scheduler", "rabbitmq")

-- provision facts
gse.set_status("keystone_admin", consts.OKAY, {})
gse.set_status("neutron_api", consts.DOWN, {{message="All neutron endpoints are down"}})
gse.set_status("keystone_api", consts.CRIT, {{message="All keystone endpoints are critical"}})
gse.set_status("nova_api", consts.OKAY, {})
gse.set_status("nova_ec2_api", consts.OKAY, {})
gse.set_status("nova_scheduler", consts.OKAY, {})
gse.set_status("rabbitmq", consts.WARN, {{message="1 RabbitMQ node out of 3 is down"}})
gse.set_status("glance_api", consts.WARN, {{message="glance-api endpoint is down on node-1"}})
gse.set_status("glance_registry", consts.DOWN, {{message='glance-registry endpoints are down'}})

TestGse = {}

    function TestGse:test_keystone_is_okay()
        local status, alarms = gse.resolve_status('keystone')
        assertEquals(status, consts.OKAY)
        assertEquals(#alarms, 0)
    end

    function TestGse:test_cinder_is_unknown()
        local status, alarms = gse.resolve_status('cinder')
        assertEquals(status, consts.UNKW)
        assertEquals(#alarms, 0)
    end

    function TestGse:test_neutron_is_down()
        local status, alarms = gse.resolve_status('neutron')
        assertEquals(status, consts.DOWN)
        assertEquals(#alarms, 1)
        assertEquals(alarms[1].tags.dependency, 'neutron_api')
        assertEquals(alarms[1].tags.dependency_level, 'direct')
    end

    function TestGse:test_nova_is_critical()
        local status, alarms = gse.resolve_status('nova')
        assertEquals(status, consts.CRIT)
        assertEquals(#alarms, 3)
        assertEquals(alarms[1].tags.dependency, 'neutron_api')
        assertEquals(alarms[1].tags.dependency_level, 'indirect')
        assertEquals(alarms[2].tags.dependency, 'keystone_api')
        assertEquals(alarms[2].tags.dependency_level, 'direct')
        assertEquals(alarms[3].tags.dependency, 'rabbitmq')
        assertEquals(alarms[3].tags.dependency_level, 'indirect')
    end

    function TestGse:test_glance_is_down()
        local status, alarms = gse.resolve_status('glance')
        assertEquals(status, consts.DOWN)
        assertEquals(#alarms, 2)
        assertEquals(alarms[1].tags.dependency, 'glance_api')
        assertEquals(alarms[1].tags.dependency_level, 'direct')
        assertEquals(alarms[2].tags.dependency, 'glance_registry')
        assertEquals(alarms[2].tags.dependency_level, 'direct')
    end

    function TestGse:test_inject_cluster_metric_for_nova()
        gse.inject_cluster_metric(
            'gse_service_cluster_metric',
            'nova',
            'service_cluster_status',
            'node-1',
            10,
            'gse_service_cluster_plugin'
        )
        local metric = last_injected_msg
        assertEquals(metric.Type, 'gse_service_cluster_metric')
        assertEquals(metric.Fields.cluster_name, 'nova')
        assertEquals(metric.Fields.name, 'service_cluster_status')
        assertEquals(metric.Fields.value, consts.CRIT)
        assertEquals(metric.Fields.hostname, 'node-1')
        assertEquals(metric.Fields.interval, 10)
        assert(metric.Payload:match("All neutron endpoints are down"))
    end

    function TestGse:test_inject_cluster_metric_for_glance()
        gse.inject_cluster_metric(
            'gse_service_cluster_metric',
            'glance',
            'service_cluster_status',
            'node-1',
            10,
            'gse_service_cluster_plugin'
        )
        local metric = last_injected_msg
        assertEquals(metric.Type, 'gse_service_cluster_metric')
        assertEquals(metric.Fields.cluster_name, 'glance')
        assertEquals(metric.Fields.name, 'service_cluster_status')
        assertEquals(metric.Fields.value, consts.DOWN)
        assertEquals(metric.Fields.hostname, 'node-1')
        assertEquals(metric.Fields.interval, 10)
        assert(metric.Payload:match("glance%-registry endpoints are down"))
        assert(metric.Payload:match("glance%-api endpoint is down on node%-1"))
    end

    function TestGse:test_inject_cluster_metric_for_keystone()
        gse.inject_cluster_metric(
            'gse_service_cluster_metric',
            'keystone',
            'service_cluster_status',
            'node-1',
            10,
            'gse_service_cluster_plugin'
        )
        local metric = last_injected_msg
        assertEquals(metric.Type, 'gse_service_cluster_metric')
        assertEquals(metric.Fields.cluster_name, 'keystone')
        assertEquals(metric.Fields.name, 'service_cluster_status')
        assertEquals(metric.Fields.value, consts.OKAY)
        assertEquals(metric.Fields.hostname, 'node-1')
        assertEquals(metric.Fields.interval, 10)
        assertEquals(metric.Payload, '{"alarms":[]}')
    end

    function TestGse:test_max_status()
        local status = gse.max_status(consts.DOWN, consts.WARN)
        assertEquals(consts.DOWN, status)
        local status = gse.max_status(consts.OKAY, consts.WARN)
        assertEquals(consts.WARN, status)
        local status = gse.max_status(consts.OKAY, consts.DOWN)
        assertEquals(consts.DOWN, status)
        local status = gse.max_status(consts.UNKW, consts.DOWN)
        assertEquals(consts.DOWN, status)
    end

lu = LuaUnit
lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
