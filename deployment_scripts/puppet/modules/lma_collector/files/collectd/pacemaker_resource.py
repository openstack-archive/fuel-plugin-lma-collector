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

import collectd
import socket

import base

NAME = 'pacemaker_resource'
CRM_RESOURCE_BIN = '/usr/sbin/crm_resource'


class PacemakerResourcePlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(PacemakerResourcePlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.crm_resource_bin = CRM_RESOURCE_BIN
        self.hostname = socket.getfqdn()
        self.resources = []

    def config_callback(self, conf):
        super(PacemakerResourcePlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'Resource':
                self.resources.extend(node.values)
            elif node.key == 'Hostname':
                self.hostname = node.values[0]
            elif node.key == 'CrmResourceBin':
                self.crm_resource_bin = node.values[0]

    def itermetrics(self):
        for resource in self.resources:
            out, err = self.execute([self.crm_resource_bin, '--locate',
                                     '--quiet', '--resource', resource],
                                    shell=False)
            if not out:
                self.logger.error("%s: Failed to get the status for '%s'" %
                                  (self.plugin, resource))

            else:
                value = 0
                if self.hostname == out.lstrip("\n"):
                    value = 1
                yield {
                    'type_instance': resource,
                    'values': value
                }

plugin = PacemakerResourcePlugin()


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback)
