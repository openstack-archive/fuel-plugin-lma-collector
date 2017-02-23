#!/usr/bin/python
# Copyright 2017 Mirantis, Inc.
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
# Collectd plugin for getting statistics from Cinder
import collectd
from collections import Counter
from collections import defaultdict
import re

import collectd_openstack as openstack

PLUGIN_NAME = 'cinder'
INTERVAL = openstack.INTERVAL


class CinderServiceStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Cinder services.

        state of workers broken down by state
    """

    states = {'up': 0, 'down': 1, 'disabled': 2}
    cinder_re = re.compile('^cinder-')

    def __init__(self, *args, **kwargs):
        super(CinderServiceStatsPlugin, self).__init__(*args, **kwargs)
        self.plugin = PLUGIN_NAME
        self.interval = INTERVAL

    def itermetrics(self):

        # Get information of the state per service
        # State can be: 'up', 'down' or 'disabled'
        aggregated_workers = defaultdict(Counter)

        for worker in self.iter_workers('cinder'):
            host = worker['host'].split('.')[0]
            service = self.cinder_re.sub('', worker['service'])
            state = worker['state']

            aggregated_workers[service][state] += 1
            yield {
                'plugin_instance': 'cinder_service',
                'values': self.states[state],
                'meta': {'host': host, 'service': service, 'state': state},
            }

        for service in aggregated_workers:
            totalw = sum(aggregated_workers[service].values())

            for state in self.states:
                prct = (100.0 * aggregated_workers[service][state]) / totalw
                yield {
                    'plugin_instance': 'cinder_services_percent',
                    'values': prct,
                    'meta': {'state': state, 'service': service}
                }
                yield {
                    'plugin_instance': 'cinder_services',
                    'values': aggregated_workers[service][state],
                    'meta': {'state': state, 'service': service},
                }


plugin = CinderServiceStatsPlugin(collectd, PLUGIN_NAME,
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
