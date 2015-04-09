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

sql_up = 'select services.binary, count(services.id) as value from services where disabled=0 and deleted=0 and timestampdiff(SECOND,updated_at,utc_timestamp())<60 group by services.binary;'
sql_down = 'select services.binary, count(services.id) as value from services where disabled=0 and deleted=0 and timestampdiff(SECOND,updated_at,utc_timestamp())>60 group by services.binary;'
sql_disabled = 'select services.binary, count(services.id) as value from services where disabled=1 and deleted=0 group by services.binary;'

queries = [
    {
        'name': 'up',
        'query': sql_up,
        'value': 'value',
        'value_func': int,
        'map_to_metric': {'binary': '%s.up'},
        'invert': ['down', 'disabled'],
        'invert_value': 0,
    },
    {
        'name': 'down',
        'query': sql_down,
        'value': 'value',
        'value_func': int,
        'map_to_metric': {'binary': '%s.down'},
        'invert': ['up', 'disabled'],
        'invert_value': 0,
    },
    {
        'name': 'disabled',
        'query': sql_disabled,
        'value': 'value',
        'value_func': int,
        'map_to_metric': {'binary': '%s.disabled'},
        'invert': ['up', 'down'],
        'invert_value': 0,
    },
]


class CinderSericeStatusPlugin(dbbase.DBBase):
    """ Class to report metrics on Cinder service.

        number of services by state up, down or disabled
    """

    def get_metrics(self):
        self.plugin = 'cinder'
        self.plugin_instance = 'services'
        return self.queries_to_metrics(queries)

plugin = CinderSericeStatusPlugin()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
