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

import base
import collectd

INTERVAL = 60


class CephOSDStatsPlugin(base.CephBase):
    """ Collect per OSD stats about store size and commit latency."""

    def __init__(self, *args, **kwargs):
        super(CephOSDStatsPlugin, self).__init__(*args, **kwargs)
        self.plugin = 'ceph_osd'

    def itermetrics(self):
        osd_stats = self.execute_to_json('ceph pg dump osds --format json')
        if not osd_stats:
            return

        for osd in osd_stats:
            osd_id = osd['osd']

            yield {
                'type_instance': osd_id,
                'type': 'osd_space',
                'values': [osd['kb_used'] * 1000, osd['kb'] * 1000],
            }

            yield {
                'type_instance': osd_id,
                'type': 'osd_latency',
                'values': [osd['fs_perf_stat']['apply_latency_ms'],
                           osd['fs_perf_stat']['commit_latency_ms']],
            }

plugin = CephOSDStatsPlugin()


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
