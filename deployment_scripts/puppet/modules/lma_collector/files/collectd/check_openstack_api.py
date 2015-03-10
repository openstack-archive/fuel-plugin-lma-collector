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
# Collectd plugin for checking the status of OpenStack API services
import collectd
import openstack

PLUGIN_NAME = 'check_openstack_api'
INTERVAL = 60


class APICheckPlugin(openstack.CollectdPlugin):
    """ Class to check the status of OpenStack API services.
    """
    OK = 0
    FAIL = 1
    UNKNOWN = 2

    # TODO(pasquier-s): add heat-cfn, nova_ec2, cinderv2, ceilometer, murano,
    # sahara
    RESOURCE_MAP = {
        'cinder': 'volumes',
        'glance': 'v1/images',
        'heat': 'stacks',
        'keystone': 'tenants',
        'neutron': 'v2.0/networks',
        'nova': 'flavors',
    }

    def check_api(self):
        """ Check the status of all the API services.

            Yields a list of dict items with 'service', 'status' (either OK,
            FAIL or UNKNOWN) and 'region' keys.
        """
        catalog = self.service_catalog
        for service in catalog:
            if service['name'] not in self.RESOURCE_MAP:
                self.logger.warning("Don't know how to check service '%s'" %
                                    service['name'])
                status = self.UNKNOWN
            else:
                r = self.get(service['name'],
                             self.RESOURCE_MAP[service['name']])
                if not r or r.status_code < 200 or r.status_code > 299:
                    status = self.FAIL
                else:
                    status = self.OK

            yield {
                'service': service['name'],
                'status': status,
                'region': service['region']
            }

    def read_callback(self):
        for item in self.check_api():
            value = collectd.Values(
                plugin=PLUGIN_NAME,
                plugin_instance=item['service'],
                type='gauge',
                type_instance=item['region'],
                interval=INTERVAL
            )
            if item['status'] == self.OK:
                value.values = [1]
            elif item['status'] == self.FAIL:
                value.values = [0]
            else:
                # skip if status is UNKNOWN
                continue
            value.dispatch()


plugin = APICheckPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
