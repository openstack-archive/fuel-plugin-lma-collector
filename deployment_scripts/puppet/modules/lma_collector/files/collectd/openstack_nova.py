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
import openstack

PLUGIN_NAME = 'nova'
INTERVAL = 60


class NovaStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Nova service.

        number of instances broken down by state
        number of services by state enabled or disabled
    """

    def config_callback(self, config):
        super(NovaStatsPlugin, self).config_callback(config)

    def _count_services_by_state(self):
        r = self.get('nova', 'os-services')
        if not r:
            self.logger.warning("Could not get services statistics")
            return {}

        services = {}
        for s in r.json().get('services'):
            if s['binary'] not in services:
                services[s['binary']] = {
                    'disabled': 0,
                    'up': 0, 'down': 0
                }
            if s['status'] != 'enabled':
                services[s['binary']]['disabled'] += 1
            elif s['state'] == 'up':
                services[s['binary']]['up'] += 1
            else:
                services[s['binary']]['down'] += 1
        return services

    def read_callback(self):
        servers_details = self.get_objects_details('nova', 'servers')

        def groupby(d):
            return d.get('status', 'unknown').lower()
        status = self.count_objects_group_by(servers_details,
                                             group_by_func=groupby)
        for s, nb in status.iteritems():
            self.dispatch_value('instances', s, nb)

        services = self._count_services_by_state()
        for service_name, states in services.iteritems():
            for s in states.keys():
                self.dispatch_value('services.' + service_name,
                                    s, services[service_name][s])

    def dispatch_value(self, plugin_instance, name, value):
        v = collectd.Values(
            plugin=PLUGIN_NAME,  # metric source
            plugin_instance=plugin_instance,
            type='gauge',
            type_instance=name,
            interval=INTERVAL,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta={'0': True},
            values=[value]
        )
        v.dispatch()

plugin = NovaStatsPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
