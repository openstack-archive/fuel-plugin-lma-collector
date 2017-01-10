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

import collectd_base as base

from pymemcache.client import base as memcache

NAME = 'memcached'


class MemcachedCheckPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(MemcachedCheckPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.host = None
        self.port = 11211

    def config_callback(self, conf):
        super(MemcachedCheckPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'Host':
                self.host = node.values[0]
            if node.key == 'Port':
                # Must coerce to integer to avoid getting a float value.
                self.port = int(node.values[0])

        if self.host is None:
            self.logger.error('Missing Host parameter')

    def read_callback(self):
        try:

            mc = memcache.Client((self.host, self.port))
            mc.get('__get_non_existent_key__')
            self.dispatch_check_metric(self.OK)
        except Exception as e:
            msg = 'Fail to query memcached ({}:{}): {}'.format(self.host,
                                                               self.port,
                                                               e)
            self.logger.error(msg)
            self.dispatch_check_metric(self.FAIL, msg)


plugin = MemcachedCheckPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback)
