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

import base
import collectd
import glob
import re


RE_OSD_ID = re.compile(".*?osd\.(\d+)\.asok$")


class CephOSDPerfPlugin(base.CephBase):

    def __init__(self, *args, **kwargs):
        super(CephOSDPerfPlugin, self).__init__(*args, **kwargs)
        self.socket_glob = None

    def config_callback(self, conf):
        super(CephOSDPerfPlugin, self).__init__(conf)
        for node in conf.children:
            if node.key == "AdminSocket":
                self.socket_glob = node.values[0]

        if not self.socket_glob:
            raise Exception("AdminSocket not defined")

    def flatten_metrics(self, prefix, stats):
        metrics = {}
        for key, value in stats.iteritems():
            metric = "%s.%s" % (prefix, key)
            if isinstance(value, dict):
                v = value['avgcount']
            else:
                v = value
            metrics[metric] = v
        return metrics

    def get_metrics(self):
        metrics = {}
        for socket_name in glob.glob(self.socket_glob):
            m = RE_OSD_ID.match(socket_name)
            if not m:
                continue
            osd_id = m.group(1)
            perf_dump = self.execute_to_json(
                "ceph --admin-daemon %s perf dump" % socket_name
            )
            for prefix, stats in perf_dump.iteritems():
                prefix = "osd-%s.%s" % (osd_id, prefix)
                if not stats:
                    continue
                m = self.flatten_metrics(prefix, stats)
                metrics.update(m)
        return metrics

plugin = CephOSDPerfPlugin()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, plugin.interval)
