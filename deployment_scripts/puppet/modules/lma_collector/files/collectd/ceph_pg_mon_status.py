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


HEALTH_MAP = {
    'HEALTH_OK': 1,
    'HEALTH_WARN': 2,
    'HEALTH_ERR': 3,
}

class CephPlugin(base.CephBase):

    def __init__(self, *args, **kwargs):
        super(CephPlugin, self).__init__(*args, **kwargs)
#* pg.bytes_avail
#* pg.bytes_total
#* pg.bytes_used
#* pg.data_bytes
#* pg.num_pgs
#* pg.state.<state>

#* health
#* monitor
#* quorum

    def get_metrics(self):
        status = self.execute_to_json('ceph -s --format json')
        if not status:
            return {}

        metrics = {}
        metrics['health'] = HEALTH_MAP[status['health']['overall_status']]
        if 'mons' in status['monmap']:
            metrics['monitor'] = len(status['monmap']['mons'])
        else:
            metrics['monitor'] = 0

        if 'quorum' in status:
            metrics['quorum'] = len(status['quorum'])
        else:
            metrics['monitor'] = 0

        pgmap = status['pgmap']
        metrics['pg.bytes_avail'] = pgmap['bytes_avail']
        metrics['pg.bytes_total'] = pgmap['bytes_total']
        metrics['pg.bytes_used'] = pgmap['bytes_used']
        metrics['pg.data_bytes'] = pgmap['data_bytes']
        metrics['pg.number'] = pgmap['num_pgs']

        for state in pgmap['pgs_by_state']:
            metric = "pg.state.%s" % state['state_name']
            metrics[metric] = state['count']

        return metrics

plugin = CephPlugin()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, plugin.interval)
