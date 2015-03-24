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


class CephPoolPlugin(base.CephBase):

    def __init__(self, *args, **kwargs):
        super(CephPoolPlugin, self).__init__(*args, **kwargs)

    def get_metrics(self):
        df = self.execute_to_json("ceph df --format json")
        if not df:
            return {}

        metrics = {}
        for pool in df['pools']:
            for m in ('bytes_used', 'max_avail', 'objects'):
                metric = "pool.%s.%s" % (pool['name'], m)
                if m in pool['stats']:
                    metrics[metric] = pool['stats'][m]
                else:
                    metrics[metric] = 0

        metrics['pool.total_number'] = len(df['pools'])

        if 'total_bytes' in df['stats']:
            # compatibility with 0.84+
            metrics['pool.total_bytes'] = df['stats']['total_bytes']
            metrics['pool.total_used_bytes'] = df['stats']['total_used_bytes']
            metrics['pool.total_avail_bytes'] = df['stats']['total_avail_bytes']
        else:
            # compatibility with <0.84
            metrics['pool.total_bytes'] = df['stats']['total_space'] * 1024
            metrics['pool.total_used_bytes'] = df['stats']['total_used'] * 1024
            metrics['pool.total_avail_bytes'] = df['stats']['total_avail'] * 1024

        stats = self.execute_to_json("ceph osd pool stats --format json")
        if not stats:
            return metrics

        for pool in stats:
            for m in ('read_bytes_sec', 'write_bytes_sec', 'op_per_sec'):
                metric = "pool.%s.%s" % (pool['pool_name'], m)
                if m in pool['client_io_rate']:
                    metrics[metric] = pool['client_io_rate'][m]
                else:
                    metrics[metric] = 0

        osd = self.execute_to_json("ceph osd dump --format json")
        if not osd:
            return metrics

        for pool in osd['pools']:
            for name in ('size', 'pg_num', 'pg_num_placement'):
                if name in pool:  # pg_num_placement not present w/ ceph 0.80.7
                    metric = 'pool.%s.%s' % (pool['pool_name'], name)
                    metrics[metric] = pool[name]

        metrics['osd.up'] = 0
        metrics['osd.down'] = 0
        metrics['osd.in'] = 0
        metrics['osd.out'] = 0
        for osd in osd['osds']:
            if osd['up'] == 1:
                metrics['osd.up'] += 1
            else:
                metrics['osd.down'] += 1
            if osd['in'] == 1:
                metrics['osd.in'] += 1
            else:
                metrics['osd.out'] += 1

        return metrics


plugin = CephPoolPlugin()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, plugin.interval)
