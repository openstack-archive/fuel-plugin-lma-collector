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
    FAIL = 0
    OK = 1
    UNKNOWN = 2

    # TODO: nova_ec2, sahara
    CHECK_MAP = {
        'keystone': {'path': '/', 'expect': 300},  # 300 Multiple Choices
        'heat': {'path': '/', 'expect': 300},      # 300 Multiple Choices
        'heat-cfn': {'path': '/', 'expect': 300},  # 300 Multiple Choices
        'glance': {'path': '/', 'expect': 300},    # 300 Multiple Choices
        'cinder': {'path': '/', 'expect': 200},
        'cinderv2': {'path': '/', 'expect': 200, 'map': 'cinder-v2'},
        'neutron': {'path': '/', 'expect': 200},
        'nova': {'path': '/', 'expect': 200},
        # Ceilometer requires authentication for all paths
        'ceilometer': {'path': 'v2/capabilities', 'expect': 200, 'auth': True},
        'swift': {'path': 'healthcheck', 'expect': 200},
        'swift_s3': {'path': 'healthcheck', 'expect': 200, 'map': 'swift-s3'},
    }

    def _service_url(self, endpoint, path):
        url = urlparse(endpoint)
        u = '%s://%s' % (url.scheme, url.netloc)
        if path != '/':
            u = '%s/%s' % (u, path)
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
                self.logger.notice("No check found for service '%s', skipping it" % name)
                status = self.UNKNOWN
            else:
                check = self.CHECK_MAP[name]
                url = self._service_url(service['url'], check['path'])
                r = self.raw_get(url, token_required=check.get('auth', False))

                if r is None or r.status_code != check['expect']:
                    def _status(ret):
                        return 'N/A' if r is None else r.status_code

                    self.logger.notice(
                        "Service %s check failed "
                        "(returned '%s' but expected '%s')" % (
                            name, _status(r), check['expect'])
                    )
                    status = self.FAIL
                else:
                    status = self.OK

            yield {
                'service': check.get('map', name),
                'status': status,
                'region': service['region']
            }

    def read_callback(self):
        for item in self.check_api():
            if item['status'] == self.UNKNOWN:
                # skip if status is UNKNOWN
                continue

            value = collectd.Values(
                plugin=PLUGIN_NAME,
                plugin_instance=item['service'],
                type='gauge',
                type_instance=item['region'],
                interval=INTERVAL,
                values=[item['status']],
                # w/a for https://github.com/collectd/collectd/issues/716
                meta={'0': True}
            )
            value.dispatch()


plugin = APICheckPlugin(collectd)


def config_callback(conf):
    plugin.config_callback(conf)


def read_callback():
    plugin.read_callback()

collectd.register_config(config_callback)
collectd.register_read(read_callback, INTERVAL)
