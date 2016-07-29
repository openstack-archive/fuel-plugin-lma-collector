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

import collectd

import collectd_base as base

INTERVAL = 60


class CephPoolPlugin(base.CephBase):
    """ Collect Ceph pool metrics and OSD daemons state"""

    def __init__(self, *args, **kwargs):
        super(CephPoolPlugin, self).__init__(*args, **kwargs)
        self.plugin = 'ceph_pool'

    def itermetrics(self):
        df = self.execute_to_json('ceph df --format json')
        if not df:
            self.add_failure("Fail to run 'ceph df'")
            return

        objects_count = 0
        for pool in df['pools']:
            objects_count += pool['stats'].get('objects', 0)
            for m in ('bytes_used', 'max_avail', 'objects'):
                yield {
                    'type': 'pool_%s' % m,
                    'type_instance': pool['name'],
                    'values': pool['stats'].get(m, 0),
                }

        yield {
            'type': 'objects_count',
            'values': objects_count
        }
        yield {
            'type': 'pool_count',
            'values': len(df['pools'])
        }

        if 'total_bytes' in df['stats']:
            # compatibility with 0.84+
            total = df['stats']['total_bytes']
            used = df['stats']['total_used_bytes']
            avail = df['stats']['total_avail_bytes']
        else:
            # compatibility with <0.84
            total = df['stats']['total_space'] * 1024
            used = df['stats']['total_used'] * 1024
            avail = df['stats']['total_avail'] * 1024

        yield {
            'type': 'pool_total_bytes',
            'values': [used, avail, total]
        }
        yield {
            'type': 'pool_total_percent',
            'values': [100.0 * used / total, 100.0 * avail / total]
        }

        stats = self.execute_to_json('ceph osd pool stats --format json')
        if not stats:
            self.add_failure("Fail to run 'ceph osd pool stats'")
            return

        for pool in stats:
            client_io_rate = pool.get('client_io_rate', {})
            yield {
                'type': 'pool_bytes_rate',
                'type_instance': pool['pool_name'],
                'values': [client_io_rate.get('read_bytes_sec', 0),
                           client_io_rate.get('write_bytes_sec', 0)]
            }
            yield {
                'type': 'pool_ops_rate',
                'type_instance': pool['pool_name'],
                'values': client_io_rate.get('op_per_sec', 0)
            }

        osd = self.execute_to_json('ceph osd dump --format json')
        if not osd:
            self.add_failure("Fail to run 'ceph osd dump'")
            return

        for pool in osd['pools']:
            for name in ('size', 'pg_num', 'pg_placement_num'):
                yield {
                    'type': 'pool_%s' % name,
                    'type_instance': pool['pool_name'],
                    'values': pool[name]
                }

        _up, _down, _in, _out = (0, 0, 0, 0)
        for osd in osd['osds']:
            if osd['up'] == 1:
                _up += 1
            else:
                _down += 1
            if osd['in'] == 1:
                _in += 1
            else:
                _out += 1

        yield {
            'type': 'osd_count',
            'values': [_up, _down, _in, _out]
        }

plugin = CephPoolPlugin(collectd)


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
