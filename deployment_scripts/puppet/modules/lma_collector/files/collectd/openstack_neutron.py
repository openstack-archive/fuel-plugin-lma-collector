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

import collectd_openstack as openstack

PLUGIN_NAME = 'neutron'
INTERVAL = openstack.INTERVAL


class NeutronStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Neutron objects.

        number of networks broken down by status
        number of subnets
        number of ports broken down by owner and status
        number of routers broken down by status
        number of floating IP addresses broken down by free/associated
    """

    def __init__(self, *args, **kwargs):
        super(NeutronStatsPlugin, self).__init__(*args, **kwargs)
        self.plugin = PLUGIN_NAME
        self.interval = INTERVAL
        self.pagination_limit = 100

    def itermetrics(self):

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

        # Networks
        networks = self.get_objects('neutron', 'networks', api_version='v2.0',
                                    params={'fields': ['id', 'status']})
        status = self.count_objects_group_by(networks,
                                             group_by_func=groupby_network)
        for s, nb in status.iteritems():
            yield {'type_instance': s, 'values': nb}
        yield {'type_instance': 'networks', 'values': len(networks)}

        # Subnets
        subnets = self.get_objects('neutron', 'subnets', api_version='v2.0',
                                   params={'fields': ['id', 'status']})
        yield {'type_instance': 'subnets', 'values': len(subnets)}

        # Ports
        ports = self.get_objects('neutron', 'ports', api_version='v2.0',
                                 params={'fields': ['id', 'status',
                                                    'device_owner']})
        status = self.count_objects_group_by(ports,
                                             group_by_func=groupby_port)
        for s, nb in status.iteritems():
            yield {'type_instance': s, 'values': nb}
        yield {'type_instance': 'ports', 'values': len(ports)}

        # Routers
        routers = self.get_objects('neutron', 'routers', api_version='v2.0',
                                   params={'fields': ['id', 'status']})
        status = self.count_objects_group_by(routers,
                                             group_by_func=groupby_router)
        for s, nb in status.iteritems():
            yield {'type_instance': s, 'values': nb}
        yield {'type_instance': 'routers', 'values': len(routers)}

        # Floating IP addresses
        floatingips = self.get_objects('neutron', 'floatingips',
                                       api_version='v2.0',
                                       params={'fields': ['id', 'status',
                                                          'port_id']})
        status = self.count_objects_group_by(floatingips,
                                             group_by_func=groupby_floating)
        for s, nb in status.iteritems():
            yield {'type_instance': s, 'values': nb}
        yield {'type_instance': 'floatingips', 'values': len(routers)}


plugin = NeutronStatsPlugin(collectd, PLUGIN_NAME, disable_check_metric=True)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.conditional_read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, INTERVAL)
