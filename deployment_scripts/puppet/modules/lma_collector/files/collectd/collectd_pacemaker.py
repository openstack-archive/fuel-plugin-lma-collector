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
from collections import Counter
from collections import defaultdict
from sets import Set
import socket
import xml.etree.ElementTree as ET

import collectd_base as base

NAME = 'pacemaker'
CRM_MON_BINARY = '/usr/sbin/crm_mon'

# Node status
OFFLINE_STATUS = 0
MAINTENANCE_STATUS = 1
ONLINE_STATUS = 2


class CrmMonitorPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(CrmMonitorPlugin, self).__init__(*args, **kwargs)
        self.plugin = NAME
        self.crm_mon_binary = CRM_MON_BINARY
        self.hostname = socket.getfqdn()
        self.notify_resource = None
        self.resources = {}
        self.history = {}

    def config_callback(self, conf):
        super(CrmMonitorPlugin, self).config_callback(conf)

        for node in conf.children:
            if node.key == 'Hostname':
                self.hostname = node.values[0]
            elif node.key == 'CrmMonBinary':
                self.crm_mon_binary = node.values[0]
            elif node.key == 'Resource':
                self.resources[node.values[0]] = node.values[-1]
            elif node.key == 'NotifyResource':
                self.notify_resource = node.values[0]

    def itermetrics(self):
        def str_to_bool(v):
            return str(v).lower() == 'true'

        def str_to_boolint(v):
            if str_to_bool(v):
                return 1
            else:
                return 0

        def shorten_hostname(v):
            return v.split('.')[0]

        def same_hostname(v):
            if v is not None and v.get('name') == self.hostname:
                return 1
            return 0

        out, err = self.execute([self.crm_mon_binary, '--as-xml', '-r', '-f'],
                                shell=False)
        if not out:
            raise base.CheckException(
                "Failed to execute crm_mon '{}'".format(err))

        try:
            root = ET.fromstring(out)
        except ET.ParseError:
            raise base.CheckException(
                "Failed to parse XML '{}'".format(out[:64]))

        if self.notify_resource:
            # Notify the other collectd plugins whether the resource runs
            # locally or not
            node = root.find('resources/resource[@id="{}"]/node'.format(
                self.notify_resource))
            self.collectd.Notification(
                type='gauge',
                message='{{"resource":"{}","value":{}}}'.format(
                    self.notify_resource, same_hostname(node)),
                severity=self.collectd.NOTIF_OKAY
            ).dispatch()
            # The metric needs to be emitted too for the Lua plugins executed
            # by the metric_collector service
            yield {
                'type_instance': 'local_resource_active',
                'values': same_hostname(node),
                'meta': {'resource': self.notify_resource,
                         'host': shorten_hostname(self.hostname)}
            }

        summary = root.find('summary')
        current_dc = summary.find('current_dc')
        # The metric needs to be emitted for the alarms that leverage the other
        # metrics emitted by the plugin
        yield {
            'type_instance': 'local_dc_active',
            'values': same_hostname(current_dc),
            'meta': {'host': shorten_hostname(self.hostname)}
        }

        if current_dc.get('name') != self.hostname:
            # The other metrics are only collected from the cluster's DC
            return

        # Report global cluster metrics
        yield {
            'type_instance': 'dc',
            'values': str_to_boolint(current_dc.get('present', 'false'))
        }

        yield {
            'type_instance': 'quorum_status',
            'values': str_to_boolint(current_dc.get('with_quorum', 'false'))
        }
        yield {
            'type_instance': 'configured_nodes',
            'values': int(summary.find('nodes_configured').get('number'))
        }
        yield {
            'type_instance': 'configured_resources',
            'values': int(summary.find('resources_configured').get('number'))
        }

        # Report node status metrics
        cluster_nodes = []
        aggregated_nodes_status = {'online': 0, 'offline': 0, 'maintenance': 0}
        nodes_total = 0
        for node in root.find('nodes').iter('node'):
            nodes_total += 1
            hostname = shorten_hostname(node.get('name'))
            cluster_nodes.append(node.get('name'))
            if str_to_bool(node.get('online')):
                if str_to_bool(node.get('maintenance')):
                    aggregated_nodes_status['maintenance'] += 1
                    yield {
                        'type_instance': 'node_status',
                        'values': MAINTENANCE_STATUS,
                        'meta': {'status': 'maintenance', 'host': hostname}
                    }
                else:
                    aggregated_nodes_status['online'] += 1
                    yield {
                        'type_instance': 'node_status',
                        'values': ONLINE_STATUS,
                        'meta': {'status': 'online', 'host': hostname}
                    }
            else:
                aggregated_nodes_status['offline'] += 1
                yield {
                    'type_instance': 'node_status',
                    'values': OFFLINE_STATUS,
                    'meta': {'status': 'offline', 'host': hostname}
                }

        for status, cnt in aggregated_nodes_status.items():
            yield {
                'type_instance': 'nodes_count',
                'values': cnt,
                'meta': {'status': status}
            }
            yield {
                'type_instance': 'nodes_percent',
                'values': 100.0 * cnt / nodes_total,
                'meta': {'status': status}
            }

        # Report the number of resources per status
        # Clone resources can run on multipe nodes while "simple" resources run
        # only one node at the same time
        aggregated_resources = defaultdict(Counter)
        resources = root.find('resources')
        for resource_id, resource_name in self.resources.iteritems():
            resource_elts = []
            simple_resource = None
            clone_resource = resources.find(
                'clone/resource[@id="{}"]/..'.format(resource_id))
            if not clone_resource:
                simple_resource = resources.find('resource[@id="{}"]'.format(
                    resource_id))
                if simple_resource:
                    resource_elts = [simple_resource]
            else:
                resource_elts = clone_resource.findall('resource')

            if not resource_elts:
                self.logger.error("{}: Couldn't find resource '{}'".format(
                    self.plugin, resource_id))
                continue

            total = 0
            for item in resource_elts:
                total += 1
                if (item.get('role') in ('Slave', 'Master') and
                   not str_to_bool(item.get('failed'))):
                    # Multi-master resource
                    aggregated_resources[resource_name]['up'] += 1
                elif item.get('role') == 'Started':
                    aggregated_resources[resource_name]['up'] += 1
                else:
                    aggregated_resources[resource_name]['down'] += 1

            if simple_resource:
                # Report on which node the "simple" resource is running
                for node in cluster_nodes:
                    yield {
                        'type_instance': 'local_resource_active',
                        'values': str_to_boolint(
                            node == simple_resource.find('node').get('name')),
                        'meta': {'resource': resource_name,
                                 'host': shorten_hostname(node)}
                    }

            for status in ('up', 'down'):
                cnt = aggregated_resources[resource_name][status]
                yield {
                    'type_instance': 'resource_count',
                    'values': cnt,
                    'meta': {'status': status, 'resource': resource_name}
                }
                yield {
                    'type_instance': 'resource_percent',
                    'values': 100.0 * cnt / total,
                    'meta': {'status': status, 'resource': resource_name}
                }

        # Collect operations' history metrics for the monitored resources
        #
        # The reported count for the resource's operations is an approximate
        # value because crm_mon doesn't provide the exact number. To estimate
        # the number of operations applied to a resource, the plugin keeps a
        # copy of call_ids and compares it with the current value.
        for node in root.find('node_history').iter('node'):
            hostname = shorten_hostname(node.get('name'))
            if hostname not in self.history:
                self.history[hostname] = {}

            for resource_id, resource_name in self.resources.iteritems():
                if resource_id not in self.history[hostname]:
                    self.history[hostname][resource_id] = {
                        'fail_count': 0,
                        'ops_count': 0,
                        'call_ids': Set([])
                    }
                v = self.history[hostname][resource_id]

                res_history = node.find('resource_history[@id="{}"]'.format(
                    resource_id))
                if res_history:
                    # For simple resources, the resource_history element only
                    # exists for the node that runs the resource
                    v['fail_count'] += int(res_history.get('fail-count', 0))
                    call_ids = Set([
                        i.get('call') for i in res_history.findall(
                            'operation_history')])
                    if call_ids:
                        v['ops_count'] += len(call_ids - v['call_ids'])
                        v['call_ids'] = call_ids

                yield {
                    'type_instance': 'resource_failures',
                    'values': v['fail_count'],
                    'meta': {'resource': resource_name, 'host': hostname}
                }
                yield {
                    'type_instance': 'resource_operations',
                    'values': v['ops_count'],
                    'meta': {'resource': resource_name, 'host': hostname}
                }


plugin = CrmMonitorPlugin(collectd)


def init_callback():
    plugin.restore_sigchld()


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback)
