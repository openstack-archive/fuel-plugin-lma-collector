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

from urlparse import urlparse

PLUGIN_NAME = 'check_openstack_api'
INTERVAL = 60


class APICheckPlugin(openstack.CollectdPlugin):
    """ Class to check the status of OpenStack API services.
    """
    OK = 0
    FAIL = 1
    UNKNOWN = 2

    # TODO: nova_ec2, sahara
    CHECK_MAP = {
        'keystone': {'resource': '/', 'expect': 300},  # 300 Multiple Choices
        'cinder': {'resource': '/', 'expect': 300},    # 300 Multiple Choices
        'cinderv2': {'resource': '/', 'expect': 300},  # 300 Multiple Choices
        'heat': {'resource': '/', 'expect': 300},      # 300 Multiple Choices
        'heat-cfn': {'resource': '/', 'expect': 300},  # 300 Multiple Choices
        'glance': {'resource': '/', 'expect': 200},
        'neutron': {'resource': '/', 'expect': 200},
        'nova': {'resource': '/', 'expect': 200},
        'ceilometer': {'resource': 'v2/capabilities', 'expect': 200, 'auth': True},
        'swift': {'resource': 'healthcheck', 'expect': 200},
        'swift_s3': {'resource': 'healthcheck', 'expect': 200},
    }

    def _service_url(self, endpoint, resource):
        url = urlparse(endpoint)
        u = '%s://%s' % (url.scheme, url.netloc)
        if resource != '/':
            u = '%s/%s' % (u, resource)
        return u

    def check_api(self):
        """ Check the status of all the API services.

            Yields a list of dict items with 'service', 'status' (either OK,
            FAIL or UNKNOWN) and 'region' keys.
        """
        catalog = self.service_catalog
        for service in catalog:
            name = service['name']
            if name not in self.CHECK_MAP:
                self.logger.notice("Skip check service '%s'" % name)
                status = self.UNKNOWN
            else:
                url = self._service_url(service['url'],
                                        self.CHECK_MAP[name]['resource'])
                r = self.raw_get(
                    url, token_required=self.CHECK_MAP[name].get('auth', False)
                )

                if not r or r.status_code != self.CHECK_MAP[name]['expect']:
                    status = self.FAIL
                else:
                    status = self.OK

            yield {
                'service': name,
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
                interval=INTERVAL,
                # w/a for https://github.com/collectd/collectd/issues/716
                meta={'0': True}
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
