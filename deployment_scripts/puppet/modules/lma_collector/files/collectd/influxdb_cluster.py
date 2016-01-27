#!/usr/bin/python
# Copyright 2016 Mirantis, Inc.
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

import base
import requests

NAME = 'influxdb_cluster'
SERIES = ['cluster', 'httpd', 'runtime', 'write']
METRIC_TYPES = {
    # cluster
    'writeShardPointsReq': ('write_shard_points_request', 'gauge'),
    'writeShardReq': ('write_shard_request', 'gauge'),

    # httpd
    'authFail': ('auth_failed', 'gauge'),
    'pingReq': ('ping_request', 'gauge'),
    'pointsWrittenOK': ('points_written_ok', 'gauge'),
    'queryReq': ('query_request', 'gauge'),
    'queryRespBytes': ('query_respond_bytes', 'gauge'),
    'req': ('request', 'gauge'),
    'writeReq': ('write_request', 'gauge'),
    'writeReqBytes': ('write_request_bytes', 'gauge'),

    # write
    'pointReq': ('point_request', 'gauge'),
    'pointReqLocal': ('point_request_local', 'gauge'),
    'pointReqRemote': ('point_req_remote', 'gauge'),
    # Same metric name already mapped from 'httpd'
    #'req': ('', 'gauge'),
    'subWriteOk': ('sub_write_ok', 'gauge'),
    'writeOk': ('ok', 'gauge'),

    # runtime
    'Alloc': ('alloc', 'gauge'),
    'Frees': ('frees', 'gauge'),
    'HeapAlloc': ('heap_alloc', 'gauge'),
    'HeapIdle': ('heap_idle', 'gauge'),
    'HeapInUse': ('heap_in_use', 'gauge'),
    'HeapObjects': ('heap_objects', 'gauge'),
    'HeapReleased': ('heap_released', 'gauge'),
    'HeapSys': ('heap_system', 'gauge'),
    'Lookups': ('lookups', 'gauge'),
    'Mallocs': ('mallocs', 'gauge'),
    'NumGC': ('num_garbage_collector', 'gauge'),
    'NumGoroutine': ('num_go_routine', 'gauge'),
    'PauseTotalNs': ('pause_total', 'gauge'),
    'Sys': ('system', 'gauge'),
    'TotalAlloc': ('total_alloc', 'gauge'),
}

class InfluxDBClusterPlugin(base.Base):
    def __init__(self, *args, **kwargs):
        super(InfluxDBClusterPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.session = requests.Session()
        self.payload = {'q': 'show stats'}
        self.url = "http://localhost:8086/query"

    def config_callback(self, conf):
        super(InfluxDBClusterPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'Username':
                username = node.values[0]
            elif node.key == 'Password':
                password = node.values[0]

        if username is None or password is None:
            self.logger.error("Credentials are not set to access InfluxDB stats")
        else:
            self.session.auth = (username, password)

    def itermetrics(self):

        try:
            r = self.session.get(self.url, params=self.payload)
        except Exception as e:
            self.logger.error("Got {0} when getting stats from {1}".format(
                e, self.url))
            return

        if r.status_code != 200:
            self.logger.error("Got responds {} from {}".format(
                r.status_code,  self.url))
            return

        data = r.json()
        try:
            series_list = data['results'][0]['series']
        except:
            self.logger.error("Failed to retrieve series for InfluxDB cluster")
            return

        for serie in series_list:
            if not serie['name'] in SERIES:
                continue
            for i in range(len(serie['columns'])):
                metric_name = serie['columns'][i]
                if metric_name in METRIC_TYPES:
                    yield {
                        'type_instance': "{}_{}".format(
                            serie['name'],
                            METRIC_TYPES[metric_name][0]),
                        'type': METRIC_TYPES[metric_name][1],
                        'values': [serie['values'][0][i]],
                    }


plugin = InfluxDBClusterPlugin()

def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback)
