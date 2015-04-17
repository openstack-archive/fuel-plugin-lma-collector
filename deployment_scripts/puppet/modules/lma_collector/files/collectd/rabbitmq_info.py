# Name: rabbitmq-collectd-plugin - rabbitmq_info.py
# Author: https://github.com/phrawzty/rabbitmq-collectd-plugin/commits/master
# Description: This plugin uses Collectd's Python plugin to obtain RabbitMQ
#              metrics.
#
# Copyright 2012 Daniel Maher
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
import re

import base


NAME = 'rabbitmq_info'
# Override in config by specifying 'RmqcBin'.
RABBITMQCTL_BIN = '/usr/sbin/rabbitmqctl'
# Override in config by specifying 'PmapBin'
PMAP_BIN = '/usr/bin/pmap'
# Override in config by specifying 'PidFile.
PID_FILE = "/var/run/rabbitmq/pid"
# Override in config by specifying 'Vhost'.
VHOST = "/"

# Used to find disk nodes and running nodes.
CLUSTER_STATUS = re.compile('.*disc,\[([^\]]+)\].*running_nodes,\[([^\]]+)\]',
                            re.S)


class RabbitMqPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(RabbitMqPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.rabbitmqctl_bin = RABBITMQCTL_BIN
        self.pidfile = PID_FILE
        self.pmap_bin = PMAP_BIN
        self.vhost = VHOST

    def config_callback(self, conf):
        super(RabbitMqPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'RmqcBin':
                self.rabbitmqctl_bin = node.values[0]
            elif node.key == 'PmapBin':
                self.pmap_bin = node.values[0]
            elif node.key == 'PidFile':
                self.pidfile = node.values[0]
            elif node.key == 'Vhost':
                self.vhost = node.values[0]
            else:
                self.logger.warning('Unknown config key: %s' % node.key)

    def get_metrics(self):
        stats = {}
        stats['messages'] = 0
        stats['memory'] = 0
        stats['consumers'] = 0
        stats['queues'] = 0
        stats['pmap_mapped'] = 0
        stats['pmap_used'] = 0
        stats['pmap_shared'] = 0

        out, err = self.execute([self.rabbitmqctl_bin, '-q', 'cluster_status'],
                                shell=False)
        if not out:
            self.logger.error('%s: Failed to get the cluster status' %
                              self.rabbitmqctl_bin)
            return

        # TODO: Need to be modified in case we are using RAM nodes.
        status = CLUSTER_STATUS.findall(out)
        if len(status) == 0:
            self.logger.error('%s: Failed to parse (%s)' %
                              (self.rabbitmqctl_bin, out))
        else:
            stats['total_nodes'] = len(status[0][0].split(","))
            stats['running_nodes'] = len(status[0][1].split(","))

        out, err = self.execute([self.rabbitmqctl_bin, '-q',
                                 'list_connections'], shell=False)
        if not out:
            self.logger.error('%s: Failed to get the number of connections' %
                              self.rabbitmqctl_bin)
            return
        stats['connections'] = len(out.split('\n'))

        out, err = self.execute([self.rabbitmqctl_bin, '-q', 'list_exchanges'],
                                shell=False)
        if not out:
            self.logger.error('%s: Failed to get the number of exchanges' %
                              self.rabbitmqctl_bin)
            return
        stats['exchanges'] = len(out.split('\n'))

        out, err = self.execute([self.rabbitmqctl_bin, '-q', '-p', self.vhost,
                                 'list_queues', 'name', 'messages', 'memory',
                                 'consumers'], shell=False)
        if not out:
            self.logger.error('%s: Failed to get the list of queues' %
                              self.rabbitmqctl_bin)
            return

        for line in out.split('\n'):
            ctl_stats = line.split()
            try:
                ctl_stats[1] = int(ctl_stats[1])
                ctl_stats[2] = int(ctl_stats[2])
                ctl_stats[3] = int(ctl_stats[3])
            except:
                continue
            queue_name = ctl_stats[0]
            stats['queues'] += 1
            stats['messages'] += ctl_stats[1]
            stats['memory'] += ctl_stats[2]
            stats['consumers'] += ctl_stats[3]
            stats['%s.messages' % queue_name] = ctl_stats[1]
            stats['%s.memory' % queue_name] = ctl_stats[2]
            stats['%s.consumers' % queue_name] = ctl_stats[3]

        if not stats['memory'] > 0:
            self.logger.warning(
                '%s reports 0 memory usage. This is probably incorrect.' %
                self.rabbitmqctl_bin)

        # get the PID of the RabbitMQ process
        try:
            with open(self.pidfile, 'r') as f:
                pid = f.read().strip()
        except:
            self.logger.error('Unable to read %s' % self.pidfile)
            return

        # use pmap to get proper memory stats
        out, err = self.execute([self.pmap_bin, '-d', pid], shell=False)
        if not out:
            self.logger.error('Failed to run %s' % self.pmap_bin)
            return

        out = out.split('\n')[-1]
        if re.match('mapped', out):
            m = re.match(r"\D+(\d+)\D+(\d+)\D+(\d+)", out)
            stats['pmap_mapped'] = int(m.group(1))
            stats['pmap_used'] = int(m.group(2))
            stats['pmap_shared'] = int(m.group(3))
        else:
            self.logger.warning('%s returned something strange.' %
                                self.pmap_bin)

        return stats


plugin = RabbitMqPlugin()


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(plugin.config_callback)
collectd.register_read(plugin.read_callback)
