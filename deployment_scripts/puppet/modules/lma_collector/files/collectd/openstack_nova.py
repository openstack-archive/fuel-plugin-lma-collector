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
# Collectd plugin for getting statistics from Nova
import collectd
from collections import Counter
from collections import defaultdict
import re

import collectd_openstack as openstack

PLUGIN_NAME = 'nova'
INTERVAL = openstack.INTERVAL


class NovaStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Nova service.

        status per service and number of instances broken down by state
    """

    states = {'up': 0, 'down': 1, 'disabled': 2}
    nova_re = re.compile('^nova-')

    def collect(self):

        # Get information of the state per service
        # State can be: 'up', 'down' or 'disabled'
        aggregated_workers = defaultdict(Counter)

        for worker in self.iter_workers('nova'):
            host = worker['host'].split('.')[0]
            service = self.nova_re.sub('', worker['service'])
            state = worker['state']

            aggregated_workers[service][state] += 1
            self.dispatch_value('nova_service', '',
                                self.states[state],
                                {'host': host,
                                 'service': service,
                                 'state': state})

        for service in aggregated_workers:
            totalw = aggregated_workers[service]['up'] + \
                aggregated_workers[service]['down'] + \
                aggregated_workers[service]['disabled']

            for state in self.states:
                self.dispatch_value('nova_services_percent', '',
                        (100.0 * aggregated_workers[service][state]) / totalw,
                        {'state': state, 'service': service})

                self.dispatch_value('nova_services', '',
                        aggregated_workers[service][state],
                        {'state': state, 'service': service})

        servers_details = self.get_objects_details('nova', 'servers')

        def groupby(d):
            return d.get('status', 'unknown').lower()
        status = self.count_objects_group_by(servers_details,
                                             group_by_func=groupby)
        for s, nb in status.iteritems():
            self.dispatch_value('instances', s, nb)

    def dispatch_value(self, plugin_instance, name, value, meta=None):
        v = collectd.Values(
            plugin=PLUGIN_NAME,  # metric source
            plugin_instance=plugin_instance,
            type='gauge',
            type_instance=name,
            interval=INTERVAL,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta=meta or {'0': True},
            values=[value]
        )
        v.dispatch()

plugin = NovaStatsPlugin(collectd, PLUGIN_NAME)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.conditional_read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, INTERVAL)
