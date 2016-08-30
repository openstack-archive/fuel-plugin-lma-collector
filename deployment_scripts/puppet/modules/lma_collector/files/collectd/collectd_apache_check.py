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

NAME = 'Apache'


class ApacheCheckPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(ApacheCheckPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.url = None

    def config_callback(self, conf):
        super(ApacheCheckPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'url':
                self.url = node.values[0]

        if self.url is None:
            self.logger.error('Missing URL parameter')

    def read_callback(self):
        pass
        # try:
        #     # Try to connect
        #     pass
        # except Exception as e:
        #     self.logger.error(msg)
        #     self.dispatch_check_metric(self.FAIL, msg)


plugin = ApacheCheckPlugin(collectd)


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback)
