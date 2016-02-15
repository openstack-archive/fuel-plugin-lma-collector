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

from functools import wraps
import json
import signal
import subprocess
import sys
import time
import traceback


INTERVAL = 10


# A decorator that will call the decorated function only when the plugin has
# detected that it is currently active.
def read_callback_wrapper(f):
    @wraps(f)
    def wrapper(self, *args, **kwargs):
        if self.do_collect_data:
            f(self, *args, **kwargs)

    return wrapper


class Base(object):
    """Base class for writing Python plugins."""

    FAIL = 0
    OK = 1
    UNKNOWN = 2

    MAX_IDENTIFIER_LENGTH = 63

    def __init__(self, collectd):
        self.debug = False
        self.timeout = 5
        self.max_retries = 3
        self.logger = collectd
        self.collectd = collectd
        self.plugin = None
        self.plugin_instance = ''
        # attributes controlling whether the plugin is in collect mode or not
        self.depends_on_resource = None
        self.do_collect_data = True

    def config_callback(self, conf):
        for node in conf.children:
            if node.key == "Debug":
                if node.values[0] in ['True', 'true']:
                    self.debug = True
            elif node.key == "Timeout":
                self.timeout = int(node.values[0])
            elif node.key == 'MaxRetries':
                self.max_retries = int(node.values[0])
            elif node.key == 'DependsOnResource':
                self.depends_on_resource = node.values[0]

    @read_callback_wrapper
    def conditional_read_callback(self):
        self.read_callback()

    def read_callback(self):
        try:
            for metric in self.itermetrics():
                self.dispatch_metric(metric)
        except Exception as e:
            self.logger.error('%s: Failed to get metrics: %s: %s' %
                              (self.plugin, e, traceback.format_exc()))
            return

    def itermetrics(self):
        """Iterate over the collected metrics

        This class must be implemented by the subclass and should yield dict
        objects that represent the collected values. Each dict has 3 keys:
            - 'values', a scalar number or a list of numbers if the type
            defines several datasources.
            - 'type_instance' (optional)
            - 'plugin_instance' (optional)
            - 'type' (optional, default='gauge')

        For example:

            {'type_instance':'foo', 'values': 1}
            {'type_instance':'bar', 'type': 'DERIVE', 'values': 1}
            {'type': 'dropped_bytes', 'values': [1,2]}
        """
        raise NotImplemented("Must be implemented by the subclass!")

    def dispatch_metric(self, metric):
        values = metric['values']
        if not isinstance(values, list) and not isinstance(values, tuple):
            values = (values,)

        type_instance = str(metric.get('type_instance', ''))
        if len(type_instance) > self.MAX_IDENTIFIER_LENGTH:
            self.logger.warning(
                '%s: Identifier "%s..." too long (length: %d, max limit: %d)' %
                (self.plugin, type_instance[:24], len(type_instance),
                 self.MAX_IDENTIFIER_LENGTH))

        v = self.collectd.Values(
            plugin=self.plugin,
            type=metric.get('type', 'gauge'),
            plugin_instance=self.plugin_instance,
            type_instance=type_instance,
            values=values,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta={'0': True}
        )
        v.dispatch()

    def execute(self, cmd, shell=True, cwd=None):
        """Executes a program with arguments.

        Args:
            cmd: a list of program arguments where the first item is the
            program name.
            shell: whether to use the shell as the program to execute (default=
            True).
            cwd: the directory to change to before running the program
            (default=None).

        Returns:
            A tuple containing the standard output and error strings if the
            program execution has been successful.

            ("foobar\n", "")

            None if the command couldn't be executed or returned a non-zero
            status code
        """
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
            stdout = stdout.rstrip('\n')
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
            self.logger.info("Command '%s' returned %s in %0.3fs" %
                             (cmd, returncode, elapsedtime))

        if not stdout and self.debug:
            self.logger.info("Command '%s' returned no output!", cmd)

        return (stdout, stderr)

    def execute_to_json(self, *args, **kwargs):
        """Executes a program and decodes the output as a JSON string.

        See execute().

        Returns:
            A Python object or None if the execution of the program failed.
        """
        outputs = self.execute(*args, **kwargs)
        if outputs:
            return json.loads(outputs[0])
        return

    @staticmethod
    def restore_sigchld():
        """Restores the SIGCHLD handler for Python <= v2.6.

        This should be provided to collectd as the init callback by plugins
        that execute external programs.

        Note that it will BREAK the exec plugin!!!

        See https://github.com/deniszh/collectd-iostat-python/issues/2 for
        details.
        """
        if sys.version_info[0] == 2 and sys.version_info[1] <= 6:
            signal.signal(signal.SIGCHLD, signal.SIG_DFL)

    def notification_callback(self, notification):
        if not self.depends_on_resource:
            return

        try:
            data = json.loads(notification.message)
        except ValueError:
            return

        if 'value' not in data:
            self.logger.warning(
                "%s: missing 'value' in notification" %
                self.__class__.__name__)
        elif 'resource' not in data:
            self.logger.warning(
                "%s: missing 'resource' in notification" %
                self.__class__.__name__)
        elif data['resource'] == self.depends_on_resource:
            do_collect_data = data['value'] > 0
            if self.do_collect_data != do_collect_data:
                # log only the transitions
                self.logger.notice("%s: do_collect_data=%s" %
                                   (self.__class__.__name__, do_collect_data))
            self.do_collect_data = do_collect_data


class CephBase(Base):

    def __init__(self, *args, **kwargs):
        super(CephBase, self).__init__(*args, **kwargs)
        self.cluster = 'ceph'

    def config_callback(self, conf):
        super(CephBase, self).config_callback(conf)

        for node in conf.children:
            if node.key == "Cluster":
                self.cluster = node.values[0]
        self.plugin_instance = self.cluster
