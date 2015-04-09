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

import dbbase
import collectd

INTERVAL = 15


CLUSTER_STATUS_MAP = {
    'Primary': 1,
    'Non-Primary': 2,
    'Disconnected': 3,
}

STATUS_VAR = {
    'wsrep_ready': lambda x: 1 if x == "ON" else 0,
    'wsrep_connected': lambda x: 1 if x == "ON" else 0,
    'wsrep_cluster_size': int,
    'wsrep_replicated': int,
    'wsrep_replicated_bytes': int,
    'wsrep_received_bytes': int,
    'wsrep_received': int,
    'wsrep_cluster_status': lambda x: CLUSTER_STATUS_MAP[x],
    'wsrep_local_commits': int,
    'wsrep_local_cert_failures': int,
    'wsrep_local_send_queue': int,
    'Slow_queries': int,
}

sql_status = "SHOW STATUS WHERE Variable_name in ("
sql_status += ','.join(["'{}'".format(x) for x in STATUS_VAR]) + ')'


def rename_metric(name):
    return name.replace('wsrep_', 'cluster.').replace('cluster_', '').lower()

queries = [
    {
        'name': 'cluster',
        'query': sql_status,
        'value': 'Value',
        'value_func': int,
        'value_map_func': STATUS_VAR,
        'map_to_metric': {'Variable_name': '%s'},
        'rename_func': {'Variable_name': rename_metric},
    },
]


class MySQLClusterPlugin(dbbase.DBBase):
    """ Class to report metrics on MySQL cluster.
    """

    def get_metrics(self):
        self.plugin = 'mysql_status'
        self.plugin_instance = ''
        return self.queries_to_metrics(queries)

plugin = MySQLClusterPlugin()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
