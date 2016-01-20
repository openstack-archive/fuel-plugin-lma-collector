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
#
# Collectd plugin for getting hypervisor statistics from Nova
import collectd
import openstack

PLUGIN_NAME = 'hypervisor_stats'
INTERVAL = openstack.INTERVAL


class HypervisorStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Nova hypervisors.
    """
    VALUE_MAP = {
        'current_workload': 'running_tasks',
        'running_vms': 'running_instances',
        'local_gb_used': 'used_disk_GB',
        'free_disk_gb': 'free_disk_GB',
        'memory_mb_used': 'used_ram_MB',
        'free_ram_mb': 'free_ram_MB',
        'vcpus_used': 'used_vcpus',
    }

    def config_callback(self, config):
        super(HypervisorStatsPlugin, self).config_callback(config)
        for node in config.children:
            if node.key == 'CpuAllocationRatio':
                self.extra_config['cpu_ratio'] = float(node.values[0])
        if 'cpu_ratio' not in self.extra_config:
            self.logger.warning('CpuAllocationRatio parameter not set')

    def dispatch_value(self, name, value, host=None):
        v = collectd.Values(
            plugin=PLUGIN_NAME,
            type='gauge',
            type_instance=name,
            interval=INTERVAL,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta={'0': True},
            values=[value]
        )
        if host:
            v.host = host
        v.dispatch()

    @openstack.read_callback_wrapper
    def read_callback(self):
        r = self.get('nova', 'os-hypervisors/detail')
        if not r:
            self.logger.warning("Could not get hypervisor statistics")
            return

        total_stats = {v: 0 for v in self.VALUE_MAP.values()}
        total_stats['free_vcpus'] = 0
        hypervisor_stats = r.json().get('hypervisors', [])
        for stats in hypervisor_stats:
            # remove domain name and keep only the hostname portion
            host = stats['hypervisor_hostname'].split('.')[0]
            for k, v in self.VALUE_MAP.iteritems():
                self.dispatch_value(v, stats.get(k, 0), host)
                total_stats[k] += stats.get(k, 0)
            if 'cpu_ratio' in self.extra_config:
                free = (int(self.extra_config['cpu_ratio'] *
                        stats.get('vcpus', 0))) - stats.get('vcpus_used', 0)
                self.dispatch_value('free_vcpus', free, host)
                total_stats['free_vcpus'] += free

        # Dispatch the global metrics
        for k, v in total_stats.iteritems():
            self.dispatch_value('total_%s'.format(k), v)


plugin = HypervisorStatsPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, INTERVAL)
