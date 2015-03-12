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

PLUGIN_NAME = 'glance'
INTERVAL = 60


class CinderStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Glance service.

        number of image broken down by state
        total size of images usable and in error state
    """

    plugin_name = PLUGIN_NAME
    interval = INTERVAL

    def config_callback(self, config):
        super(CinderStatsPlugin, self).config_callback(config)

    def read_callback(self):

        def is_snap(d):
            return d.get('properties', {}).get('image_type') == 'snapshot'

        def groupby(d):
            p = 'public' if d.get('is_public', True) else 'private'
            status = d.get('status', 'unknown').lower()
            if is_snap(d):
                return '%s.snapshot.%s' % (p, status)
            return '%s.%s' % (p, status)

        images_details = self.get_objects_details('glance', 'images',
                                                  api_version='v1',
                                                  params='is_public=None')
        self.dispatch_count_objects_group_by('images',
                                             images_details,
                                             group_by_func=groupby)
        total_img_size_gb, total_img_err_size_gb = 0, 0
        total_snap_size_gb, total_snap_err_size_gb = 0, 0
        for i in images_details:
            issnap = is_snap(i)
            if 'active' in i['status']:
                if issnap:
                    total_snap_size_gb += i['size']
                else:
                    total_img_size_gb += i['size']
            else:
                if issnap:
                    total_snap_err_size_gb += i['size']
                else:
                    total_img_err_size_gb += i['size']

        self.dispatch_value('size.images', 'active', total_img_size_gb)
        self.dispatch_value('size.images', 'other', total_img_err_size_gb)
        self.dispatch_value('size.snapshots', 'active', total_snap_size_gb)
        self.dispatch_value('size.snapshots', 'other', total_snap_err_size_gb)

plugin = CinderStatsPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)


