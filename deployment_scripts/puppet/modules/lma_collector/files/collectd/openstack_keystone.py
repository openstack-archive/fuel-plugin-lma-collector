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
# Collectd plugin for getting statistics from Keystone
import collectd

import base
import openstack

PLUGIN_NAME = 'keystone'
INTERVAL = openstack.INTERVAL


class KeystoneStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Keystone service.

        number of tenants, users broken down by state
        number of roles
    """

    @base.read_callback_wrapper
    def read_callback(self):

        def groupby(d):
            return 'enabled' if d.get('enabled') else 'disabled'

        # tenants
        r = self.get('keystone', 'projects')
        if not r:
            self.logger.warning('Could not find Keystone tenants')
            return
        tenants_details = r.json().get('projects', [])
        status = self.count_objects_group_by(tenants_details,
                                             group_by_func=groupby)
        for s, nb in status.iteritems():
            self.dispatch_value('tenants.' + s, nb)

        # users
        r = self.get('keystone', 'users')
        if not r:
            self.logger.warning('Could not find Keystone users')
            return
        users_details = r.json().get('users', [])
        status = self.count_objects_group_by(users_details,
                                             group_by_func=groupby)
        for s, nb in status.iteritems():
            self.dispatch_value('users.' + s, nb)

        # roles
        r = self.get('keystone', 'roles')
        if not r:
            self.logger.warning('Could not find Keystone roles')
            return
        roles = r.json().get('roles', [])
        self.dispatch_value('roles', len(roles))

    def dispatch_value(self, name, value):
        v = collectd.Values(
            plugin=PLUGIN_NAME,  # metric source
            type='gauge',
            type_instance=name,
            interval=INTERVAL,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta={'0': True},
            values=[value]
        )
        v.dispatch()

plugin = KeystoneStatsPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, INTERVAL)
