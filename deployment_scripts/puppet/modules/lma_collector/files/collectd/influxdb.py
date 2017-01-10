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
import requests

import collectd_base as base

NAME = 'influxdb'
METRICS_BY_NAME = {
    'cluster': {
        'writeShardPointsReq': ('cluster_write_shard_points_requests',
                                'gauge'),
        'writeShardReq':       ('cluster_write_shard_requests', 'gauge')},

    'httpd': {
        'authFail':        ('httpd_failed_auths', 'gauge'),
        'pingReq':         ('httpd_ping_requests', 'gauge'),
        'pointsWrittenOK': ('httpd_write_points_ok', 'gauge'),
        'queryReq':        ('httpd_query_requests', 'gauge'),
        'queryRespBytes':  ('httpd_query_response_bytes', 'gauge'),
        'req':             ('httpd_requests', 'gauge'),
        'writeReq':        ('httpd_write_requests', 'gauge'),
        'writeReqBytes':   ('httpd_write_request_bytes', 'gauge')},

    'write': {
        'pointReq':       ('write_point_requests', 'gauge'),
        'pointReqLocal':  ('write_point_local_requests', 'gauge'),
        'pointReqRemote': ('write_point_remote_requests', 'gauge'),
        'req':            ('write_requests', 'gauge'),
        'subWriteOk':     ('write_sub_ok', 'gauge'),
        'writeOk':        ('write_ok', 'gauge')},

    'runtime': {
        'Alloc':        ('memory_alloc', 'gauge'),
        'TotalAlloc':   ('memory_total_alloc', 'gauge'),
        'Sys':          ('memory_system', 'gauge'),
        'Lookups':      ('memory_lookups', 'gauge'),
        'Mallocs':      ('memory_mallocs', 'gauge'),
        'Frees':        ('memory_frees', 'gauge'),
        'HeapIdle':     ('heap_idle', 'gauge'),
        'HeapInUse':    ('heap_in_use', 'gauge'),
        'HeapObjects':  ('heap_objects', 'gauge'),
        'HeapReleased': ('heap_released', 'gauge'),
        'HeapSys':      ('heap_system', 'gauge'),
        'NumGC':        ('garbage_collections', 'gauge'),
        'NumGoroutine': ('go_routines', 'gauge')}
}


class InfluxDBClusterPlugin(base.Base):
    def __init__(self, *args, **kwargs):
        super(InfluxDBClusterPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.session = requests.Session()
        self.address = "localhost"
        self.port = "8086"
        self.session.mount(
            'http://',
            requests.adapters.HTTPAdapter(max_retries=3)
        )

    def config_callback(self, conf):
        super(InfluxDBClusterPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'Username':
                username = node.values[0]
            elif node.key == 'Password':
                password = node.values[0]
            elif node.key == 'Address':
                self.address = node.values[0]
            elif node.key == 'Port':
                self.port = node.values[0]

        if username is None or password is None:
            self.logger.error("Username and Password parameters are required")
        else:
            self.session.auth = (username, password)

    def itermetrics(self):

        payload = {'q': 'show stats'}
        url = "http://{}:{}/query".format(self.address, self.port)

        try:
            r = self.session.get(url, params=payload)
        except Exception as e:
            msg = "Got {0} when getting stats from {1}".format(e, url)
            raise base.CheckException(msg)

        if r.status_code != 200:
            msg = "Got response {0} from {0}".format(r.status_code, url)
            raise base.CheckException(msg)

        data = r.json()
        try:
            series_list = data['results'][0]['series']
        except:
            self.logger.error("Failed to retrieve series for InfluxDB cluster")
            return

        for serie in series_list:
            metrics_list = METRICS_BY_NAME.get(serie['name'], None)
            if not metrics_list:
                continue
            for i in range(len(serie['columns'])):
                metric_name = serie['columns'][i]
                if metric_name in metrics_list:
                    yield {
                        'type_instance': metrics_list[metric_name][0],
                        'type': metrics_list[metric_name][1],
                        'values': [serie['values'][0][i]],
                    }


plugin = InfluxDBClusterPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback)
