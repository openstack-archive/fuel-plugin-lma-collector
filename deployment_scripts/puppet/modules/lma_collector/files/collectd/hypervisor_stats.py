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
INTERVAL = 60


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

    def dispatch_value(self, hostname, name, value):
        v = collectd.Values(
            plugin=PLUGIN_NAME,
            plugin_instance=hostname,
            type='gauge',
            type_instance=name,
            interval=INTERVAL,
            values=[value]
        )
        v.dispatch()

    def read_callback(self):
        r = self.get('nova', 'os-hypervisors/detail')
        if not r:
            self.logger.warning("Could not get hypervisor statistics")
            return

        for h in r.json().get('hypervisors', {}):
            # keep only system's hostname
            hostname = h['hypervisor_hostname'].split('.')[0]
            for k, v in self.VALUE_MAP.iteritems():
                self.dispatch_value(hostname,
                                    v, h.get(k, 0))
            if 'cpu_ratio' in self.extra_config:
                vcpus = int(self.extra_config['cpu_ratio'] * h.get('vcpus', 0))
                self.dispatch_value(hostname,
                                    'free_vcpus',
                                    vcpus - h.get('vcpus_used', 0))


plugin = HypervisorStatsPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
