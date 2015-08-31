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

-- configure relations and dependencies
service("nova", "nova_api")
service("nova", "nova_ec2_api")
service("nova", "nova_scheduler")
service("glance", "glance_api")
service("glance", "glance_registry")
service("keystone", "keystone_admin")
service("keystone", "keystone_main")

dependency("nova_api", "neutron_api")
dependency("nova_scheduler", "rabbitmq")


-- provision facts
status("neutron_api", STATUS.down, {{message="All neutron endpoints are down"}})
status("nova_api", STATUS.okay, {})
status("nova_ec2_api", STATUS.okay, {})
status("nova_scheduler", STATUS.okay, {})
status("rabbitmq", STATUS.warn, {{message="1 RabbitMQ node out of 3 is down"}})
status("glance_api", STATUS.warn, {{message="glance-api endpoint is down on node-1"}})
status("glance_registry", STATUS.down, {{message='glance-registry endpoints are down'}})
status("keystone_admin", STATUS.okay, {})

-- ask
for _, v in ipairs({'nova','amqp','glance','cinder', 'keystone'}) do
    local gstatus, alarms_1, alarms_2 = resolve_status(v)
    print(string.format('%s is %s', v, gstatus))
    print("  alarms_1:")
    for _, a in ipairs(alarms_1) do
        print("  - " .. a.message)
    end
    print("  alarms_2:")
    for _, a in ipairs(alarms_2) do
        print("  - " .. a.message)
    end
end
