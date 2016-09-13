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
import http_check


NAME = 'check_local_endpoint'


class CheckLocalEndpoint(http_check.HTTPCheckPlugin):

    def __init__(self, *args, **kwargs):
        super(CheckLocalEndpoint, self).__init__(*args, **kwargs)
        self.plugin = NAME

plugin = CheckLocalEndpoint(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.conditional_read_callback()


collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, base.INTERVAL)
