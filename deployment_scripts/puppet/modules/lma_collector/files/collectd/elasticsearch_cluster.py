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

NAME = 'elasticsearch_cluster'
HEALTH_MAP = {
    'green': 1,
    'yellow': 2,
    'red': 3,
}
METRICS = ['number_of_nodes', 'active_primary_shards', 'active_primary_shards',
           'active_shards', 'relocating_shards', 'unassigned_shards',
           'number_of_pending_tasks', 'initializing_shards']


class ElasticsearchClusterHealthPlugin(base.Base):
    def __init__(self, *args, **kwargs):
        super(ElasticsearchClusterHealthPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.address = '127.0.0.1'
        self.port = 9200
        self._node_id = None
        self.session = requests.Session()
        self.url = None
        self.session.mount(
            'http://',
            requests.adapters.HTTPAdapter(max_retries=self.max_retries)
        )

    def config_callback(self, conf):
        super(ElasticsearchClusterHealthPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'Address':
                self.address = node.values[0]
            if node.key == 'Port':
                self.port = node.values[0]

        self.url = "http://{address}:{port}/".format(
            **{
                'address': self.address,
                'port': int(self.port),
            })

    def query_api(self, resource):
        url = "{}{}".format(self.url, resource)
        try:
            r = self.session.get(url)
        except Exception as e:
            msg = "Got exception for '{}': {}".format(url, e)
            raise base.CheckException(msg)

        if r.status_code != 200:
            msg = "{} responded with code {}".format(url, r.status_code)
            raise base.CheckException(msg)

        return r.json()

    @property
    def node_id(self):
        if self._node_id is None:
            local_node = self.query_api('_nodes/_local')
            self._node_id = local_node.get('nodes', {}).keys()[0]

        return self._node_id

    def itermetrics(self):
        # Collect cluster metrics only from the elected master
        master_node = self.query_api('_cluster/state/master_node')
        if master_node.get('master_node', '') != self.node_id:
            return

        data = self.query_api('_cluster/health')
        self.logger.debug("Got response from Elasticsearch: '%s'" % data)

        yield {
            'type_instance': 'health',
            'values': HEALTH_MAP[data['status']]
        }

        for metric in METRICS:
            value = data.get(metric)
            if value is None:
                # Depending on the Elasticsearch version, not all metrics are
                # available
                self.logger.info("Couldn't find {} metric".format(metric))
                continue
            yield {
                'type_instance': metric,
                'values': value
            }

plugin = ElasticsearchClusterHealthPlugin(collectd, 'elasticsearch')


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback)
