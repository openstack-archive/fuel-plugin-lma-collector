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


NAME = 'http_check'


class HTTPCheckPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(HTTPCheckPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
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
        self.expected_codes = {}

    def config_callback(self, config):
        super(HTTPCheckPlugin, self).config_callback(config)
        for node in config.children:
            if node.key == "Url":
                self.urls[node.values[0]] = node.values[1]
            elif node.key == 'ExpectedCode':
                self.expected_codes[node.values[0]] = int(node.values[1])

    def itermetrics(self):
        for name, url in self.urls.items():
            try:
                r = self.session.get(url, timeout=self.timeout)
            except Exception as e:
                self.logger.warning("Got exception for '{}': {}".format(
                    url, e)
                )
                yield {'type_instance': name, 'values': self.FAIL}
            else:

                expected_code = self.expected_codes.get(name, 200)
                if r.status_code != expected_code:
                    self.logger.warning(
                        ("{} ({}) responded with code {} "
                         "while {} is expected").format(name, url,
                                                        r.status_code,
                                                        expected_code))
                    yield {'type_instance': name, 'values': self.FAIL}
                else:
                    self.logger.debug(
                        "Got response from {}: '{}'".format(url, r.content))
                    yield {'type_instance': name, 'values': self.OK}

plugin = HTTPCheckPlugin(collectd, disable_check_metric=True)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.conditional_read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, base.INTERVAL)
