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
import datetime
import dateutil.parser
import dateutil.tz
import collectd
import requests
import simplejson as json


class OSClient(object):
    """ Base class for querying the OpenStack API endpoints.

    It uses the Keystone service catalog to discover the API endpoints.
    """
    EXPIRATION_TOKEN_DELTA = datetime.timedelta(0, 30)

    def __init__(self, username, password, tenant, keystone_url, timeout,
                 logger):
        self.logger = logger
        self.username = username
        self.password = password
        self.tenant_name = tenant
        self.keystone_url = keystone_url
        self.service_catalog = []
        self.tenant_id = None
        self.timeout = timeout
        self.token = None
        self.valid_until = None
        self.get_token()

    def is_valid_token(self):
        now = datetime.datetime.now(tz=dateutil.tz.tzutc())
        return self.token and self.valid_until and self.valid_until > now

    def clear_token(self):
        self.token = None
        self.valid_until = None

    def get_token(self):
        self.clear_token()
        data = json.dumps({
            "auth":
            {
                'tenantName': self.tenant_name,
                'passwordCredentials':
                {
                    'username': self.username,
                    'password': self.password
                    }
                }
            }
        )
        self.logger.info("Trying to get token from '%s'" % self.keystone_url)
        r = self.make_request(requests.post,
                              '%s/tokens' % self.keystone_url, data=data,
                              token_required=False)
        if not r:
            self.logger.error("Cannot get a valid token from %s" %
                              self.keystone_url)
            return

        if r.status_code < 200 or r.status_code > 299:
            self.logger.error("%s responded with code %d" %
                              (self.keystone_url, r.status_code))
            return

        data = r.json()
        self.logger.debug("Got response from Keystone: '%s'" % data)
        self.token = data['access']['token']['id']
        self.tenant_id = data['access']['token']['tenant']['id']
        self.valid_until = dateutil.parser.parse(
            data['access']['token']['expires']) - self.EXPIRATION_TOKEN_DELTA
        self.service_catalog = []
        for item in data['access']['serviceCatalog']:
            endpoint = item['endpoints'][0]
            self.service_catalog.append({
                'name': item['name'],
                'region': endpoint['region'],
                'service_type': item['type'],
                'url': endpoint['internalURL'],
            })

        self.logger.debug("Got token '%s'" % self.token)
        return self.token

    def make_request(self, func, url, data=None, token_required=True):
        kwargs = {
            'url': url,
            'timeout': self.timeout,
            'allow_redirects': True,
            'headers': {'Content-type': 'application/json'}
        }
        if token_required and not self.is_valid_token() and \
           not self.get_token():
            self.logger.error("Aborting request, no valid token")
            return
        else:
            kwargs['headers']['X-Auth-Token'] = self.token

        if data is not None:
            kwargs['data'] = data

        try:
            r = func(**kwargs)
            r.json()
        except Exception as e:
            self.logger.error("Got exception for '%s': '%s'" %
                              (kwargs['url'], e))
            return

        self.logger.info("%s responded with status code %d" %
                         (kwargs['url'], r.status_code))
        if r.status_code == 401:
            # Clear token in case it is revoked or invalid
            self.clear_token()

        return r


class CollectdPlugin(object):
    plugin_name = None
    interval = None

    def __init__(self, logger, plugin_name=None, interval=None):
        self.os_client = None
        self.logger = logger
        self.timeout = 5
        self.extra_config = {}

    def _build_url(self, service, resource):
        url = (self.get_service(service) or {}).get('url')
        if url:
            if url[-1] != '/':
                url += '/'
            url = "%s%s" % (url, resource)
        else:
            self.logger.error("Service '%s' not found in catalog" % service)
        return url

    def get(self, service, resource):
        url = self._build_url(service, resource)
        if not url:
            return
        self.logger.info("GET '%s'" % url)
        return self.os_client.make_request(requests.get, url)

    def post(self, service, resource, data):
        url = self._build_url(service, resource)
        if not url:
            return
        self.logger.info("POST '%s'" % url)
        return self.os_client.make_request(requests.post, url, data)

    @property
    def service_catalog(self):
        return self.os_client.service_catalog

    def get_service(self, service_name):
        return next((x for x in self.service_catalog
                    if x['name'] == service_name), None)

    def config_callback(self, config):
        for node in config.children:
            if node.key == 'Timeout':
                self.timeout = int(node.values[0])
            elif node.key == 'Username':
                username = node.values[0]
            elif node.key == 'Password':
                password = node.values[0]
            elif node.key == 'Tenant':
                tenant_name = node.values[0]
            elif node.key == 'KeystoneUrl':
                keystone_url = node.values[0]
        self.os_client = OSClient(username, password, tenant_name,
                                  keystone_url, self.timeout, self.logger)

    def read_callback(self):
        raise "read_callback method needs to be overriden!"

    def get_objects_details(self, project, object_name,
                            api_version='', params='all_tenants=1'):
        """ Return object details list

            the version is not always included in url endpoint (glance)
            use api_version param to include the version in resource url
        """

        if api_version:
            resource = '%s/%s/detail?%s' % (api_version, object_name, params)
        else:
            resource = '%s/detail?%s' % (object_name, params)

        # TODO(scroiset): use pagination to handle large collection
        r = self.get(project, resource)
        if not r:
            self.logger.warning('Could not find %s %s' % (project,
                                                          object_name))
            return []
        return r.json().get(object_name, [])

    def dispatch_count_objects_group_by(self, object_name, list_object,
                                        group_by_func=None):

        """ Dispatch values of object number grouped by criteria."""

        status = {}
        for obj in list_object:
            s = group_by_func(obj)
            if s in status:
                status[s] += 1
            else:
                status[s] = 1
        for s, nb in status.iteritems():
            self.dispatch_value(object_name, s, nb)
        return status

    def dispatch_value(self, plugin_instance, name, value):
        v = collectd.Values(
            plugin=self.plugin_name,  # metric source
            plugin_instance=plugin_instance,
            type='gauge',
            type_instance=name,
            interval=self.interval,
            # w/a for https://github.com/collectd/collectd/issues/716
            meta={'0': True},
            values=[value]
        )
        v.dispatch()
