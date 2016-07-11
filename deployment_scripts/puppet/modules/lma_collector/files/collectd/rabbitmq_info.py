# Name: rabbitmq-collectd-plugin - rabbitmq_info.py
# Description: This plugin uses Collectd's Python plugin to obtain RabbitMQ
#              metrics.
#
# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import collectd

import collectd_base as base
import requests

NAME = 'rabbitmq_info'
# Override in config by specifying 'Host'.
HOST = '127.0.0.1'
# Override in config by specifying 'Port'.
PORT = '15672'


class RabbitMqPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(RabbitMqPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.username = None
        self.password = None
        self.nodename = None
        self.host = HOST
        self.port = PORT
        self.session = None

    def config_callback(self, conf):
        super(RabbitMqPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.values[0] == '':
                continue
            if node.key == 'Username':
                self.username = node.values[0]
            if node.key == 'Password':
                self.password = node.values[0]
            if node.key == 'Host':
                self.host = node.values[0]
            if node.key == 'Port':
                self.port = node.values[0]

        if not (self.username and self.password):
            self.logger.error('Missing Username and Password configurations')

        self.session = requests.Session()
        self.session.auth = (self.username, self.password)
        self.session.mount(
            'http://',
            requests.adapters.HTTPAdapter(max_retries=self.max_retries)
        )
        url = "http://{}:{}".format(self.host, self.port)
        self.api_nodes_url = "{}/api/nodes".format(url)
        self.api_overview_url = "{}/api/overview".format(url)

    def itermetrics(self):
        stats = {}
        try:
            r = self.session.get(self.api_overview_url, timeout=self.timeout)
            overview = r.json()
        except Exception as e:
            self.logger.warning("Got exception for '{}': {}".format(
                self.api_nodes_url, e)
            )
            return
        objects = overview['object_totals']
        stats['queues'] = objects['queues']
        stats['consumers'] = objects['consumers']
        stats['connections'] = objects['connections']
        stats['exchanges'] = objects['exchanges']
        stats['channels'] = objects['channels']
        stats['messages'] = overview['queue_totals']['messages']
        stats['running_nodes'] = len(overview['contexts'])

        for k, v in stats.iteritems():
            yield {'type_instance': k, 'values': v}

        stats = {}
        nodename = overview['node']
        try:
            r = self.session.get("{}/{}".format(self.api_nodes_url, nodename),
                                 timeout=self.timeout)
            node = r.json()
        except Exception as e:
            self.logger.warning("Got exception for '{}': {}".format(
                self.api_node_url, e)
            )
            return

        stats['disk_free_limit'] = node['disk_free_limit']
        stats['disk_free'] = node['disk_free']
        stats['remaining_disk'] = node['disk_free'] - node['disk_free_limit']

        stats['used_memory'] = node['mem_used']
        stats['vm_memory_limit'] = node['mem_limit']
        stats['remaining_memory'] = node['mem_limit'] - node['mem_used']

        for k, v in stats.iteritems():
            yield {'type_instance': k, 'values': v}


plugin = RabbitMqPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback)
