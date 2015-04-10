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

import json
import subprocess
import time
import traceback

import collectd


class Base(object):
    """ Base class for python plugin.
    """

    def __init__(self, *args, **kwargs):
        self.debug = False
        self.timeout = 5
        self.logger = collectd
        self.plugin = None
        self.plugin_instance = ''

    def config_callback(self, conf):
        for node in conf.children:
            if node.key == "Debug":
                if node.values[0] in ['True', 'true']:
                    self.debug = True
            if node.key == "Timeout":
                self.timeout = int(node.values[0])

    def read_callback(self):
        try:
            metrics = self.get_metrics()
        except Exception as e:
            self.logger.error('Failed to get metrics: %s: %s' %
                              (e, traceback.format_exc()))
        else:
            self.dispatch(metrics)

    def get_metrics(self):
        raise NotImplemented("Must be subclassed!")

    def dispatch(self, metrics):
        for metric, data in metrics.iteritems():
            if isinstance(data, dict):
                self.dispatch_metric(metric, data['value'], _type=data['type'])
            else:
                self.dispatch_metric(metric, data)

    def dispatch_metric(self, metric, value, _type='gauge'):
        v = collectd.Values(
            plugin=self.plugin,
            type=_type,
            plugin_instance=self.plugin_instance,
            type_instance=metric,
            values=[value],
            # w/a for https://github.com/collectd/collectd/issues/716
            meta={'0': True}
        )
        v.dispatch()


class Execute(object):

    def execute(self, cmd, shell=True, cwd=None):
        start_time = time.time()
        try:
            proc = subprocess.Popen(
                cmd,
                cwd=cwd,
                shell=shell,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            (stdout, stderr) = proc.communicate()
        except Exception as e:
            self.logger.error("Cannot execute command '%s': %s : %s" %
                              (cmd, str(e), traceback.format_exc()))
            return None

        returncode = proc.returncode

        if returncode != 0:
            self.logger.error("Command '%s' failed (return code %d): %s" %
                              (cmd, returncode, stderr))
            return None
        elapsedtime = time.time() - start_time

        if self.debug:
            self.logger.info("Command '%s' return %s in %0.3fs" %
                             (cmd, returncode, elapsedtime))

        if not stdout and self.debug:
            self.logger.info("Command '%s' return nothing!")

        return (stdout, stderr)

    def execute_to_json(self, *args, **kwargs):
        outputs = self.execute(*args, **kwargs)
        if outputs:
            return json.loads(outputs[0])
        return None


class CephBase(Base, Execute):

    def __init__(self, *args, **kwargs):
        super(CephBase, self).__init__(*args, **kwargs)
        self.cluster = 'ceph'
        self.plugin = 'ceph'

    def config_callback(self, conf):
        super(CephBase, self).config_callback(conf)

        for node in conf.children:
            if node.key == "Cluster":
                self.cluster = node.values[0]
        self.plugin_instance = 'cluster-%s' % self.cluster
