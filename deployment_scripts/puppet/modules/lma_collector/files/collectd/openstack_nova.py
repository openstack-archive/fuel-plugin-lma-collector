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

import collectd_openstack as openstack
from itertools import groupby
from operator import methodcaller


PLUGIN_NAME = 'nova'
INTERVAL = openstack.INTERVAL


class NovaInstanceStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Nova instances.

        Number of instances broken down by state
    """
    def __init__(self, *args, **kwargs):
        super(NovaInstanceStatsPlugin, self).__init__(*args, **kwargs)
        self.plugin = PLUGIN_NAME
        self.interval = INTERVAL
        self.pagination_limit = 500
        self._cache = {}

    def itermetrics(self):
        server_details = self.get_objects('nova', 'servers',
                                          params={'all_tenants': 1},
                                          detail=True, since=True)

        for s in server_details:
            _id = s.get('id')
            if s.get('status', 'unknown').lower() == 'deleted':
                try:
                    self.logger.notice(
                        'remove from cache deleted instance {}'.format(_id))
                    del self._cache[_id]
                except KeyError:
                    self.logger.warning(
                        'missing instance in cache {}'.format(_id))
            else:
                self._cache[_id] = s

        get_status = methodcaller('get', 'status', 'unknown')
        servers = sorted(self._cache.values(), key=get_status)
        for s, g in groupby(servers, key=get_status):
            count = len(map(get_status, g))
            yield {
                'plugin_instance': 'instances',
                'values': count,
                'type_instance': s.lower(),
            }


plugin = NovaInstanceStatsPlugin(collectd, PLUGIN_NAME)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.conditional_read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, INTERVAL)
