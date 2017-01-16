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

import collectd_openstack as openstack

PLUGIN_NAME = 'hypervisor_stats'
INTERVAL = openstack.INTERVAL


class HypervisorStatsPlugin(openstack.CollectdPlugin):
    """ Class to report the statistics on Nova hypervisors."""
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

    def dispatch_value(self, name, value, meta=None):
        v = collectd.Values(
            plugin=PLUGIN_NAME,
            type='gauge',
            type_instance=name,
            interval=INTERVAL,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta=meta or {'0': True},
            values=[value]
        )
        v.dispatch()

    def collect(self):
        nova_aggregates = {}
        r = self.get('nova', 'os-aggregates')
        if not r:
            self.logger.warning("Could not get nova aggregates")
        else:
            aggregates_list = r.json().get('aggregates', [])
            for agg in aggregates_list:
                nova_aggregates[agg['name']] = {
                    'id': agg['id'],
                    'hosts': agg['hosts'],
                    'free_vcpus': 0,
                }
                for f in self.VALUE_MAP.keys():
                    nf = self.VALUE_MAP.get(f, f)
                    nova_aggregates[agg['name']][nf] = 0

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
                self.dispatch_value(v, stats.get(k, 0), {'host': host})
                total_stats[v] += stats.get(k, 0)
                for agg in nova_aggregates.keys():
                    agg_hosts = nova_aggregates[agg]['hosts']
                    if stats['hypervisor_hostname'] in agg_hosts:
                        nf = self.VALUE_MAP.get(k, k)
                        nova_aggregates[agg][nf] += stats.get(k, 0)
            if 'cpu_ratio' in self.extra_config:
                free = (int(self.extra_config['cpu_ratio'] *
                        stats.get('vcpus', 0))) - stats.get('vcpus_used', 0)
                self.dispatch_value('free_vcpus', free, {'host': host})
                total_stats['free_vcpus'] += free
                for agg in nova_aggregates.keys():
                    agg_hosts = nova_aggregates[agg]['hosts']
                    if stats['hypervisor_hostname'] in agg_hosts:
                        free = ((int(self.extra_config['cpu_ratio'] *
                                     stats.get('vcpus', 0))) -
                                stats.get('vcpus_used', 0))
                        nova_aggregates[agg]['free_vcpus'] += free

        # Dispatch the aggregate metrics
        for agg in nova_aggregates.keys():
            nova_aggregates[agg].pop('hosts')
            agg_id = nova_aggregates[agg].pop('id')
            agg_total_free_ram = (
                nova_aggregates[agg]['free_ram_MB'] +
                nova_aggregates[agg]['used_ram_MB']
            )
            if agg_total_free_ram != 0:
                nova_aggregates[agg]['free_ram_percent'] = round(
                    (100.0 * nova_aggregates[agg]['free_ram_MB']) /
                    agg_total_free_ram,
                    2)
            for k, v in nova_aggregates[agg].iteritems():
                self.dispatch_value('aggregate_{}'.format(k), v,
                                    {'aggregate': agg,
                                     'aggregate_id': agg_id})
        # Dispatch the global metrics
        for k, v in total_stats.iteritems():
            self.dispatch_value('total_{}'.format(k), v)

plugin = HypervisorStatsPlugin(collectd, PLUGIN_NAME)


def config_callback(conf):
    plugin.config_callback(conf)


def notification_callback(notification):
    plugin.notification_callback(notification)


def read_callback():
    plugin.conditional_read_callback()

collectd.register_config(config_callback)
collectd.register_notification(notification_callback)
collectd.register_read(read_callback, INTERVAL)
