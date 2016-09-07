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


class NeutronStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Neutron service.

        state of agents
        number of networks broken down by status
        number of subnets
        number of ports broken down by owner and status
        number of routers broken down by status
        number of floating IP addresses broken down by free/associated
    """

    neutron_re = re.compile('^neutron-')
    agent_re = re.compile('-agent$')
    states = {'up': 0, 'down': 1, 'disabled': 2}

    def collect(self):

        def groupby_network(x):
            return "networks.%s" % x.get('status', 'unknown').lower()

        def groupby_router(x):
            return "routers.%s" % x.get('status', 'unknown').lower()

        def groupby_port(x):
            owner = x.get('device_owner', 'none')
            if owner.startswith('network:'):
                owner = owner.replace('network:', '')
            elif owner.startswith('compute:'):
                # The part after 'compute:' is the name of the Nova AZ
                owner = 'compute'
            else:
                owner = 'none'
            status = x.get('status', 'unknown').lower()
            return "ports.%s.%s" % (owner, status)

        def groupby_floating(x):
            if x.get('port_id', None):
                status = 'associated'
            else:
                status = 'free'
            return "floatingips.%s" % status

        # Get information of the state per agent
        # State can be up or down
        aggregated_agents = defaultdict(Counter)

        for agent in self.iter_workers('neutron'):
            host = agent['host'].split('.')[0]
            service = self.agent_re.sub(
                '', self.neutron_re.sub('', agent['service']))
            state = agent['state']

            aggregated_agents[service][state] += 1
            self.dispatch_value('neutron_agent',
                                self.states[state],
                                {'host': host,
                                 'service': service,
                                 'state': state})

        for service in aggregated_agents:
            totala = aggregated_agents[service]['up'] + \
                aggregated_agents[service]['down'] + \
                aggregated_agents[service]['disabled']

            for state in self.states:
                self.dispatch_value('neutron_agents_percent',
                        (100.0 * aggregated_agents[service][state]) / totala,
                        {'service': service, 'state': state})

                self.dispatch_value('neutron_agents',
                        aggregated_agents[service][state],
                        {'service': service, 'state': state})

        # Networks
        networks = self.get_objects('neutron', 'networks', api_version='v2.0')
        status = self.count_objects_group_by(networks,
                                             group_by_func=groupby_network)
        for s, nb in status.iteritems():
            self.dispatch_value(s, nb)
        self.dispatch_value('networks', len(networks))

        # Subnets
        subnets = self.get_objects('neutron', 'subnets', api_version='v2.0')
        self.dispatch_value('subnets', len(subnets))

        # Ports
        ports = self.get_objects('neutron', 'ports', api_version='v2.0')
        status = self.count_objects_group_by(ports,
                                             group_by_func=groupby_port)
        for s, nb in status.iteritems():
            self.dispatch_value(s, nb)
        self.dispatch_value('ports', len(ports))

        # Routers
        routers = self.get_objects('neutron', 'routers', api_version='v2.0')
        status = self.count_objects_group_by(routers,
                                             group_by_func=groupby_router)
        for s, nb in status.iteritems():
            self.dispatch_value(s, nb)
        self.dispatch_value('routers', len(routers))

        # Floating IP addresses
        floatingips = self.get_objects('neutron', 'floatingips',
                                       api_version='v2.0')
        status = self.count_objects_group_by(floatingips,
                                             group_by_func=groupby_floating)
        for s, nb in status.iteritems():
            self.dispatch_value(s, nb)
        self.dispatch_value('floatingips', len(floatingips))

    def dispatch_value(self, name, value, meta=None):
        v = collectd.Values(
            plugin=PLUGIN_NAME,  # metric source
            type='gauge',
            type_instance=name,
            interval=INTERVAL,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta=meta or {'0': True},
            values=[value]
        )
        v.dispatch()

plugin = NeutronStatsPlugin(collectd, PLUGIN_NAME)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.conditional_read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, INTERVAL)
