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
import threading
import time
import traceback


INTERVAL = 10


class CheckException(Exception):
    pass


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

    def __init__(self, collectd, service_name=None, local_check=True,
                 disable_check_metric=False):
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

        self.service_name = service_name
        self.local_check = local_check
        self.disable_check_metric = disable_check_metric

    def config_callback(self, conf):
        for node in conf.children:
            if node.key == "Debug":
                if node.values[0].lower() == 'true':
                    self.debug = True
            elif node.key == "Timeout":
                self.timeout = int(node.values[0])
            elif node.key == 'MaxRetries':
                self.max_retries = int(node.values[0])
            elif node.key == 'DependsOnResource':
                self.depends_on_resource = node.values[0]
            elif node.key == 'DisableCheckMetric':
                if node.values[0].lower() == 'true':
                    self.disable_check_metric = True

    @read_callback_wrapper
    def conditional_read_callback(self):
        self.read_callback()

    def read_callback(self):
        try:
            for metric in self.itermetrics():
                self.dispatch_metric(metric)
        except CheckException as e:
            msg = '{}: {}'.format(self.plugin, e)
            self.logger.warning(msg)
            self.dispatch_check_metric(self.FAIL, msg)
        except Exception as e:
            msg = '{}: Failed to get metrics: {}'.format(self.plugin, e)
            self.logger.error('{}: {}'.format(msg, traceback.format_exc()))
            self.dispatch_check_metric(self.FAIL, msg)
        else:
            self.dispatch_check_metric(self.OK)

    def dispatch_check_metric(self, value, failure=None):
        """Send a check metric reporting whether or not the plugin succeeded

        """
        if self.disable_check_metric:
            return

        metric = {
            'meta': {'service_check': self.service_name or self.plugin,
                     'local_check': self.local_check},
            'values': value,
        }

        if failure is not None:
            metric['meta']['failure'] = failure

        self.dispatch_metric(metric)

    def itermetrics(self):
        """Iterate over the collected metrics

        This class must be implemented by the subclass and should yield dict
        objects that represent the collected values. Each dict has 6 keys:
            - 'values', a scalar number or a list of numbers if the type
            defines several datasources.
            - 'type_instance' (optional)
            - 'plugin_instance' (optional)
            - 'type' (optional, default='gauge')
            - 'meta' (optional)
            - 'hostname' (optional)

        For example:

            {'type_instance':'foo', 'values': 1}
            {'type_instance':'bar', 'type': 'DERIVE', 'values': 1}
            {'type_instance':'bar', 'type': 'DERIVE', 'values': 1,
                'meta':   {'tagA': 'valA'}}
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

        plugin_instance = metric.get('plugin_instance', self.plugin_instance)
        v = self.collectd.Values(
            plugin=self.plugin,
            host=metric.get('hostname', ''),
            type=metric.get('type', 'gauge'),
            plugin_instance=plugin_instance,
            type_instance=type_instance,
            values=values,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta=metric.get('meta', {'0': True})
        )
        v.dispatch()

    def execute(self, cmd, shell=True, cwd=None, log_error=True):
        """Executes a program with arguments.

        Args:
            cmd: a list of program arguments where the first item is the
            program name.
            shell: whether to use the shell as the program to execute (default=
            True).
            cwd: the directory to change to before running the program
            (default=None).
            log_error: whether to log an error when the command returned a
            non-zero status code (default=True).

        Returns:
            A tuple containing the return code, the standard output and the
            standard error if the program has been executed.

            (0, "foobar\n", "")

            (-1, None, None) if the program couldn't be executed at all.
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
            return (-1, None, None)

        returncode = proc.returncode

        if returncode != 0 and log_error:
            self.logger.error("Command '%s' failed (return code %d): %s" %
                              (cmd, returncode, stderr))
        if self.debug:
            elapsedtime = time.time() - start_time
            self.logger.info("Command '%s' returned %s in %0.3fs" %
                             (cmd, returncode, elapsedtime))

        return (returncode, stdout, stderr)

    def execute_to_json(self, *args, **kwargs):
        """Executes a program and decodes the output as a JSON string.

        See execute().

        Returns:
            A Python object or
            None if the execution of the program or JSON decoding fails.
        """
        (retcode, out, err) = self.execute(*args, **kwargs)
        if retcode == 0:
            try:
                return json.loads(out)
            except ValueError as e:
                self.logger.error("{}: document: '{}'".format(e, out))

    @staticmethod
    def restore_sigchld():
        """Restores the SIGCHLD handler.

        This should be provided to collectd as the init callback by plugins
        that execute external programs and want to check the return code.

        Note that it will BREAK the exec plugin!!!

        See contrib/python/getsigchld.py in the collectd project for details.
        """
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


class AsyncPoller(threading.Thread):
    """Execute an independant thread to execute a function periodically

       Args:
           collectd: used for logging
           polling_function: a function to execute periodically
           interval: the interval in second
           name: (optional) the name of the thread
           reset_on_read: (default False) if True, all results returned by the
                          polling_function() are accumulated until they are
                          read.
    """

    def __init__(self, collectd, polling_function, interval, name=None,
                 reset_on_read=False):
        super(AsyncPoller, self).__init__(name=name)
        self.collectd = collectd
        self.polling_function = polling_function
        self.interval = interval
        self._results = []
        self._reset_on_read = reset_on_read

    def run(self):
        self.collectd.info('Starting thread {}'.format(self.name))
        while True:
            try:
                started_at = time.time()

                self.results = self.polling_function()
                tosleep = self.interval - (time.time() - started_at)
                if tosleep > 0:
                    time.sleep(tosleep)
                else:
                    self.collectd.warning(
                        'Polling took more than {}s for {}'.format(
                            self.interval, self.name
                        )
                    )

            except Exception as e:
                self.results = []
                self.collectd.error('{} fails: {}'.format(self.name, e))
                time.sleep(10)

    @property
    def results(self):
        r = self._results
        if self._reset_on_read:
            self._results = []
        return r

    @results.setter
    def results(self, value):
        if self._reset_on_read:
            self._results.extend(value)
        else:
            self._results = value
