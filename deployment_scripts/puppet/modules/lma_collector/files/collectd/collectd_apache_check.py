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
import requests

NAME = 'apache'


class ApacheCheckPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(ApacheCheckPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.url = None

    def config_callback(self, conf):
        super(ApacheCheckPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'Url':
                self.url = node.values[0]

        if self.url is None:
            self.logger.error("{}: Missing Url parameter".format(NAME))

    def read_callback(self):
        try:
            requests.get(self.url, timeout=5)
            self.dispatch_check_metric(self.OK)
        except Exception as err:
            msg = "{}: Failed to check service: {}".format(NAME, err)
            self.logger.error(msg)
            self.dispatch_check_metric(self.FAIL, msg)


plugin = ApacheCheckPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback)
