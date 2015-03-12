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
# Collectd plugin for getting hypervisor statistics from Cinder
import collectd
import openstack

PLUGIN_NAME = 'cinder'
INTERVAL = 60


class CinderStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Cinder service.

        number of volumes broken down by state
        total size of volumes usable and in error state
    """

    plugin_name = PLUGIN_NAME
    interval = INTERVAL

    def config_callback(self, config):
        super(CinderStatsPlugin, self).config_callback(config)

    def read_callback(self):
        volumes_details = self.get_objects_details('cinder', 'volumes')

        def groupby(d):
            return d.get('status', 'unknown').lower()
        status = self.count_objects_group_by(volumes_details,
                                             group_by_func=groupby)
        for s, nb in status.iteritems():
            self.dispatch_value('volumes', s, nb)

        total_vol_size_gb, total_vol_err_size_gb = 0, 0
        for v in volumes_details:
            if 'error' in v['status']:
                total_vol_err_size_gb += v['size']
            else:
                total_vol_size_gb += v['size']
        self.dispatch_value('size.volumes', 'usable', total_vol_size_gb)
        self.dispatch_value('size.volumes', 'in_error', total_vol_err_size_gb)

        snaps_details = self.get_objects_details('cinder', 'snapshots')
        status_snaps = self.count_objects_group_by(snaps_details,
                                                   group_by_func=groupby)
        for s, nb in status_snaps.iteritems():
            self.dispatch_value('snapshots', s, nb)

plugin = CinderStatsPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)

