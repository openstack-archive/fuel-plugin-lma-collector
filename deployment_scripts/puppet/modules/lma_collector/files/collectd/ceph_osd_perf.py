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
import glob
import re

import collectd_base as base

INTERVAL = 60
RE_OSD_ID = re.compile(".*?osd\.(\d+)\.asok$")


class CephOSDPerfPlugin(base.CephBase):
    """Collect OSD performance counters of OSD daemons running on the host."""

    # Collect only metrics from the 'osd' namespace
    PREFIXES = ('osd')

    def __init__(self, *args, **kwargs):
        super(CephOSDPerfPlugin, self).__init__(*args, **kwargs)
        self.plugin = 'ceph_osd_perf'
        self.socket_glob = None

    def config_callback(self, conf):
        super(CephOSDPerfPlugin, self).config_callback(conf)
        for node in conf.children:
            if node.key == "AdminSocket":
                self.socket_glob = node.values[0]

        if not self.socket_glob:
            raise Exception("AdminSocket not defined")

    @staticmethod
    def convert_to_collectd_value(value):
        # See for details
        # https://www.mail-archive.com/ceph-users@lists.ceph.com/msg18705.html
        if isinstance(value, dict):
            if value['avgcount'] > 0:
                return value['sum'] / value['avgcount']
            else:
                return 0.0
        else:
            return value

    @staticmethod
    def convert_to_collectd_type(*args):
        return '_'.join([s.replace('::', '_').replace('-', '_').lower() for s
                         in args])

    def itermetrics(self):
        for socket_name in glob.glob(self.socket_glob):
            m = RE_OSD_ID.match(socket_name)
            if not m:
                continue

            osd_id = m.group(1)
            perf_dump = self.execute_to_json('ceph --admin-daemon %s perf dump'
                                             % socket_name)
            if not perf_dump:
                self.add_failure(
                    "Fail to run 'ceph perf dump' for OSD {}".format(osd_id))
                continue

            for prefix, stats in perf_dump.iteritems():
                if prefix not in self.PREFIXES or not stats:
                    continue

                for k in sorted(stats.iterkeys()):
                    yield {
                        'type': self.convert_to_collectd_type(prefix, k),
                        'type_instance': osd_id,
                        'values': self.convert_to_collectd_value(stats[k])
                    }

plugin = CephOSDPerfPlugin(collectd)


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_init(init_callback)
collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
