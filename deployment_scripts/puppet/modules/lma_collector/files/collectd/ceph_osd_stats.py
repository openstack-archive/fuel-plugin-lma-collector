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


class CephOSDStatsPlugin(base.CephBase):

    def get_metrics(self):
        pgs = self.execute_to_json('ceph pg dump --format json')
        if not pgs:
            return {}

        metrics = {}
        for osd in pgs['osd_stats']:
            metric = "osd.%s" % osd['osd']
            used = "%s.used" % metric
            metrics[used] = osd['kb_used'] * 1000
            total = "%s.total" % metric
            metrics[total] = osd['kb'] * 1000
            # queue = "%s.snap_trim_queue_len" % metric
            # metrics[queue] = osd['snap_trim_queue_len']
            # trimming = "%s.num_snap_trimming" % metric
            # metrics[trimming] = osd['num_snap_trimming']
            apply_latency = "%s.apply_latency" % metric
            metrics[apply_latency] = osd['fs_perf_stat']['apply_latency_ms']
            commit_latency = "%s.commit_latency" % metric
            metrics[commit_latency] = osd['fs_perf_stat']['commit_latency_ms']

        return metrics

plugin = CephOSDStatsPlugin()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, plugin.interval)
