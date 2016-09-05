# haproxy-collectd-plugin - haproxy.py
#
# Original Author: Michael Leinartas
# Substantial additions by Mirantis
# Description: This is a collectd plugin which runs under the Python plugin to
# collect metrics from haproxy.
# Plugin structure and logging func taken from
# https://github.com/phrawzty/rabbitmq-collectd-plugin

# Copyright (c) 2011 Michael Leinartas
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import collectd
import csv
import itertools
import socket

import collectd_base as base

from collections import defaultdict

NAME = 'haproxy'
RECV_SIZE = 1024
SERVER_METRICS = {
    'CurrConns': ('connections', 'gauge'),
    'CurrSslConns': ('ssl_connections', 'gauge'),
    'PipesUsed': ('pipes_used', 'gauge'),
    'PipesFree': ('pipes_free', 'gauge'),
    'Run_queue': ('run_queue', 'gauge'),
    'Tasks': ('tasks', 'gauge'),
    'Uptime_sec': ('uptime', 'gauge'),
}
FRONTEND_METRIC_TYPES = {
    'bin': ('bytes_in', 'gauge'),
    'bout': ('bytes_out', 'gauge'),
    'dresp': ('denied_responses', 'gauge'),
    'dreq': ('denied_requests', 'gauge'),
    'ereq': ('error_requests', 'gauge'),
    'hrsp_1xx': ('response_1xx', 'gauge'),
    'hrsp_2xx': ('response_2xx', 'gauge'),
    'hrsp_3xx': ('response_3xx', 'gauge'),
    'hrsp_4xx': ('response_4xx', 'gauge'),
    'hrsp_5xx': ('response_5xx', 'gauge'),
    'hrsp_other': ('response_other', 'gauge'),
    'stot': ('session_total', 'gauge'),
    'scur': ('session_current', 'gauge'),
}
BACKEND_METRIC_TYPES = {
    'bin': ('bytes_in', 'gauge'),
    'bout': ('bytes_out', 'gauge'),
    'downtime': ('downtime', 'gauge'),
    'dresp': ('denied_responses', 'gauge'),
    'dreq': ('denied_requests', 'gauge'),
    'econ': ('error_connection', 'gauge'),
    'eresp': ('error_responses', 'gauge'),
    'hrsp_1xx': ('response_1xx', 'gauge'),
    'hrsp_2xx': ('response_2xx', 'gauge'),
    'hrsp_3xx': ('response_3xx', 'gauge'),
    'hrsp_4xx': ('response_4xx', 'gauge'),
    'hrsp_5xx': ('response_5xx', 'gauge'),
    'hrsp_other': ('response_other', 'gauge'),
    'qcur': ('queue_current', 'gauge'),
    'stot': ('session_total', 'gauge'),
    'scur': ('session_current', 'gauge'),
    'wredis': ('redistributed', 'gauge'),
    'wretr': ('retries', 'gauge'),
    'status': ('status', 'gauge'),
}

STATUS_MAP = {
    'DOWN': 0,
    'UP': 1,
}

FRONTEND_TYPE = '0'
BACKEND_TYPE = '1'
BACKEND_SERVER_TYPE = '2'

HAPROXY_SOCKET = '/var/lib/haproxy/stats'
DEFAULT_PROXY_MONITORS = ['server', 'frontend', 'backend', 'backend_server']


class HAProxySocket(object):
    def __init__(self, socket_file):
        self.socket_file = socket_file

    def connect(self):
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(self.socket_file)
        return s

    def communicate(self, command):
        '''Send a command to the socket and return a response (raw string).'''

        s = self.connect()
        if not command.endswith('\n'):
            command += '\n'
        s.send(command)
        result = ''
        buf = ''
        buf = s.recv(RECV_SIZE)
        while buf:
            result += buf
            buf = s.recv(RECV_SIZE)
        s.close()
        return result

    def get_server_info(self):
        result = {}
        output = self.communicate('show info')
        for line in output.splitlines():
            try:
                key, val = line.split(':')
            except ValueError:
                continue
            result[key.strip()] = val.strip()
        return result

    def get_server_stats(self):
        output = self.communicate('show stat')
        # sanitize and make a list of lines
        output = output.lstrip('# ').strip()
        output = [l.strip(',') for l in output.splitlines()]
        csvreader = csv.DictReader(output)
        result = [d.copy() for d in csvreader]
        return result


class HAProxyPlugin(base.Base):
    def __init__(self, *args, **kwargs):
        super(HAProxyPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.names_mapping = {}
        self.proxy_monitors = []
        self.proxy_ignore = []
        self.socket = HAPROXY_SOCKET

    def get_proxy_name(self, pxname):
        if pxname not in self.names_mapping:
            self.logger.info('Mapping missing for "%s"' % pxname)
        return self.names_mapping.get(pxname, pxname)

    def itermetrics(self):
        haproxy = HAProxySocket(self.socket)

        # Collect server statistics
        if 'server' in self.proxy_monitors:
            try:
                stats = haproxy.get_server_info()
            except socket.error:
                msg = "Unable to connect to HAProxy socket at {}".format(
                    self.socket)
                raise base.CheckException(msg)
            else:
                for k, v in stats.iteritems():
                    if k not in SERVER_METRICS:
                        continue
                    type_instance = SERVER_METRICS[k][0]
                    type_ = SERVER_METRICS[k][1]
                    yield {
                        'type_instance': type_instance,
                        'type': type_,
                        'values': int(v),
                    }

        try:
            stats = haproxy.get_server_stats()
        except socket.error:
            msg = "Unable to connect to HAProxy socket at {}".format(
                self.socket)
            raise base.CheckException(msg)

        def match(x):
            if x['pxname'] in self.proxy_ignore:
                return False
            return (x['svname'].lower() in self.proxy_monitors or
                    x['pxname'].lower() in self.proxy_monitors or
                    ('backend_server' in self.proxy_monitors and
                     x['type'] == BACKEND_SERVER_TYPE))
        stats = filter(match, stats)
        for stat in stats:
            stat['pxname'] = self.get_proxy_name(stat['pxname'])

        # Collect statistics for the frontends and the backends
        for stat in itertools.ifilter(lambda x: x['type'] == FRONTEND_TYPE or
                                      x['type'] == BACKEND_TYPE, stats):
            if stat['type'] == FRONTEND_TYPE:
                metrics = FRONTEND_METRIC_TYPES
                side = 'frontend'
            else:
                metrics = BACKEND_METRIC_TYPES
                side = 'backend'
            for k, metric in metrics.iteritems():
                if k not in stat:
                    self.logger.warning("Can't find {} metric".format(k))
                    continue
                value = stat[k]

                metric_name = '{}_{}'.format(side, metric[0])
                meta = {
                    side: stat['pxname']
                }

                if metric[0] == 'status':
                    value = STATUS_MAP[value]
                else:
                    value = int(value) if value else 0

                yield {
                    'type_instance': metric_name,
                    'type': metric[1],
                    'values': value,
                    'meta': meta
                }

        # Count the number of servers per backend and state
        backend_server_states = {}
        for stat in itertools.ifilter(lambda x:
                                      x['type'] == BACKEND_SERVER_TYPE, stats):
            pxname = stat['pxname']
            if pxname not in backend_server_states:
                backend_server_states[pxname] = defaultdict(int)

            # The status field for a server has the following syntax when a
            # transition occurs with HAproxy >=1.6: "DOWN 17/30" or "UP 1/3".
            status = stat['status'].split(' ')[0]

            # We only pick up the UP and DOWN status while it can be one of
            # NOLB/MAINT/MAINT(via)...
            if status in STATUS_MAP:
                backend_server_states[pxname][status] += 1
                # Emit metric for the backend server
                yield {
                    'type_instance': 'backend_server',
                    'values': STATUS_MAP[status],
                    'meta': {
                        'backend': pxname,
                        'state': status.lower(),
                        'server': stat['svname'],
                    }
                }

        for pxname, states in backend_server_states.iteritems():
            for s in STATUS_MAP.keys():
                yield {
                    'type_instance': 'backend_servers',
                    'values': states.get(s, 0),
                    'meta': {
                        'backend': pxname,
                        'state': s.lower()
                    }
                }

    def config_callback(self, conf):
        for node in conf.children:
            if node.key == "ProxyMonitor":
                self.proxy_monitors.append(node.values[0])
            elif node.key == "ProxyIgnore":
                self.proxy_ignore.append(node.values[0])
            elif node.key == "Socket":
                self.socket = node.values[0]
            elif node.key == "Mapping":
                self.names_mapping[node.values[0]] = node.values[1]
            else:
                self.logger.warning('Unknown config key: %s' % node.key)

        if not self.proxy_monitors:
            self.proxy_monitors += DEFAULT_PROXY_MONITORS
        self.proxy_monitors = [p.lower() for p in self.proxy_monitors]


plugin = HAProxyPlugin(collectd)


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback)
