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

INTERVAL = 30
HEALTH_MAP = {
    'HEALTH_OK': 1,
    'HEALTH_WARN': 2,
    'HEALTH_ERR': 3,
}


class CephMonPlugin(base.CephBase):
    """ Collect states and metrics about ceph cluster and placement groups."""

    def __init__(self, *args, **kwargs):
        super(CephMonPlugin, self).__init__(*args, **kwargs)
        self.plugin = 'ceph_mon'

    def itermetrics(self):
        status = self.execute_to_json('ceph -s --format json')
        if not status:
            self.add_failure("Fail to execute 'ceph -s'")
            return

        yield {
            'type': 'health',
            'values': HEALTH_MAP[status['health']['overall_status']],
        }

        if 'mons' in status['monmap']:
            monitor_nb = len(status['monmap']['mons'])
        else:
            monitor_nb = 0
        yield {
            'type': 'monitor_count',
            'values': monitor_nb
        }

        yield {
            'type': 'quorum_count',
            'values': len(status.get('quorum', []))
        }

        pgmap = status['pgmap']
        yield {
            'type': 'pg_bytes',
            'values': [pgmap['bytes_used'], pgmap['bytes_avail'],
                       pgmap['bytes_total']],
        }
        yield {
            'type': 'pg_data_bytes',
            'values': pgmap['data_bytes']
        }
        yield {
            'type': 'pg_count',
            'values': pgmap['num_pgs']
        }

        for state in pgmap['pgs_by_state']:
            yield {
                'type': 'pg_state_count',
                'type_instance': state['state_name'],
                'values': state['count']
            }

plugin = CephMonPlugin(collectd)


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
