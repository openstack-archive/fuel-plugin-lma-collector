#!/usr/bin/python
# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Collectd plugin for getting resource statistics from Neutron
import collectd
from collections import Counter
from collections import defaultdict
import re

import collectd_openstack as openstack

PLUGIN_NAME = 'neutron'
INTERVAL = openstack.INTERVAL


class NeutronAgentStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Neutron agents.

        state of agents
    """

    neutron_re = re.compile('^neutron-')
    agent_re = re.compile('-agent$')
    states = {'up': 0, 'down': 1, 'disabled': 2}

    def __init__(self, *args, **kwargs):
        super(NeutronAgentStatsPlugin, self).__init__(*args, **kwargs)
        self.plugin = PLUGIN_NAME
        self.interval = INTERVAL

    def itermetrics(self):

        # Get information of the state per agent
        # State can be up or down
        aggregated_agents = defaultdict(Counter)

        for agent in self.iter_workers('neutron'):
            host = agent['host'].split('.')[0]
            service = self.agent_re.sub(
                '', self.neutron_re.sub('', agent['service']))
            state = agent['state']

            aggregated_agents[service][state] += 1

            yield {
                'type_instance': 'neutron_agent',
                'values': self.states[state],
                'meta': {'host': host, 'service': service, 'state': state}
            }

        for service in aggregated_agents:
            totala = sum(aggregated_agents[service].values())

            for state in self.states:
                prct = (100.0 * aggregated_agents[service][state]) / totala
                yield {
                    'type_instance': 'neutron_agents_percent',
                    'values': prct,
                    'meta': {'service': service, 'state': state},
                }
                yield {
                    'type_instance': 'neutron_agents',
                    'values': aggregated_agents[service][state],
                    'meta': {'service': service, 'state': state},
                }


plugin = NeutronAgentStatsPlugin(collectd, PLUGIN_NAME,
                                 disable_check_metric=True)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.conditional_read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, INTERVAL)
