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


NAME = 'http_check'
OK = {'values': 1}
DOWN = {'values': 0}


class HTTPCheckPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(HTTPCheckPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.max_retries = 3
        self.session = requests.Session()
        self.session.mount(
            'http://',
            requests.adapters.HTTPAdapter(max_retries=self.max_retries)
        )
        self.session.mount(
            'https://',
            requests.adapters.HTTPAdapter(max_retries=self.max_retries)
        )
        self.urls = {}

    def config_callback(self, config):
        super(HTTPCheckPlugin, self).config_callback(config)
        for node in config.children:
            if node.key == "Url":
                self.urls[node.values[0]] = node.values[1]

    @base.read_callback_wrapper
    def read_callback(self):

        for name, url in self.urls.items():
            try:
                r = self.session.get(url)
            except Exception as e:
                self.logger.error("Got exception for '{}': {}".format(url, e))
                yield {'type_instance': name, 'values': self.FAIL}
                return

            if r.status_code != 200:
                self.logger.error("{} responded with code {}".format(
                    url, r.status_code))
                yield {'type_instance': name, 'values': self.FAIL}
                return

            data = r.text
            self.logger.debug("Got response from Elasticsearch: '%s'" % data)
            yield {'type_instance': name, 'values': self.OK}

plugin = HTTPCheckPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, base.INTERVAL)
