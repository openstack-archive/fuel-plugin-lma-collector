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
import os.path
import pymysql

NAME = 'mysql'


class MySQLCheckPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(MySQLCheckPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.host = None
        self.socket = None
        self.port = '3306'
        self.sql = 'SELECT VERSION()'
        self.username = None
        self.password = None
        self.database = None

    def config_callback(self, conf):
        super(MySQLCheckPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'Socket':
                self.socket = node.values[0]
            if node.key == 'Host':
                self.host = node.values[0]
            if node.key == 'Port':
                self.port = int(node.values[0])
            if node.key == 'Username':
                self.username = node.values[0]
            if node.key == 'Password':
                self.password = node.values[0]
            if node.key == 'Database':  # Optional
                self.database = node.values[0]
            if node.key == 'SQL':
                self.sql = node.values[0]

        if not self.socket and not self.host:
            # Try to find MySQL socket
            for sock in ('/var/run/mysqld/mysqld.sock',
                         '/run/mysqld/mysqld.sock'):
                if os.path.exists(sock):
                    self.socket = sock
                    self.logger.info('Use socket {} as a fallback'.format(
                        sock))
                    break

            if not self.socket:
                self.logger.error('Missing parameter: Host or Socket')

        if self.socket:
            # The hostname must be set to localhost to work with socket
            self.host = 'localhost'
            self.logger.info('Use Socket={}'.format(self.socket))

        if not self.username:
            self.logger.warning('Missing parameter Username')

    def read_callback(self):
        cnx = None
        try:
            cnx = pymysql.connect(host=self.host,
                                  port=self.port,
                                  unix_socket=self.socket,
                                  user=self.username,
                                  password=self.password,
                                  db=self.database,
                                  connect_timeout=3)

            with cnx.cursor() as cursor:
                cursor.execute(self.sql)
                cursor.fetchone()
                self.dispatch_check_metric(self.OK)
        except Exception as e:
            msg = 'Fail to query MySQL "{}": {}'.format(self.sql, e)
            self.logger.error(msg)
            self.dispatch_check_metric(self.FAIL, msg)

        finally:
            if cnx is not None:
                cnx.close()


plugin = MySQLCheckPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback)
