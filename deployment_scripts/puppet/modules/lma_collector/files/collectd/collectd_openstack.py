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
import re
import requests
import simplejson as json

import collectd_base as base

from collections import defaultdict

# By default, query OpenStack API endpoints every 50 seconds. We choose a value
# less than the default group by interval (which is 60 seconds) to avoid gaps
# in the Grafana graphs.
INTERVAL = 50

MARKER_RE = re.compile('.*marker=([^&]+)')


class KeystoneException(Exception):
    pass


class OSClient(object):
    """ Base class for querying the OpenStack API endpoints.

    It uses the Keystone service catalog to discover the API endpoints.
    """
    EXPIRATION_TOKEN_DELTA = datetime.timedelta(0, 30)

    def __init__(self, username, password, tenant, keystone_url, timeout,
                 logger, max_retries):
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

        # Note: prior to urllib3 v1.9, retries are made on failed connections
        # but not on timeout and backoff time is not supported.
        # (at this time we ship requests 2.2.1 and urllib3 1.6.1 or 1.7.1)
        self.session = requests.Session()
        self.session.mount(
            'http://', requests.adapters.HTTPAdapter(max_retries=max_retries))
        self.session.mount(
            'https://', requests.adapters.HTTPAdapter(max_retries=max_retries))

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
        })
        self.logger.info("Trying to get token from '%s'" % self.keystone_url)
        r = self.make_request('post',
                              '%s/tokens' % self.keystone_url, data=data,
                              token_required=False)
        if not r:
            raise KeystoneException("Cannot get a valid token from %s" %
                                    self.keystone_url)

        if r.status_code < 200 or r.status_code > 299:
            raise KeystoneException("%s responded with code %d" %
                                    (self.keystone_url, r.status_code))

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
                'admin_url': endpoint['adminURL'],
            })

        self.logger.debug("Got token '%s'" % self.token)
        return self.token

    def make_request(self, verb, url, data=None, token_required=True,
                     params=None):
        kwargs = {
            'url': url,
            'timeout': self.timeout,
            'headers': {'Content-type': 'application/json'}
        }
        if token_required and not self.is_valid_token() and \
           not self.get_token():
            self.logger.error("Aborting request, no valid token")
            return
        elif token_required:
            kwargs['headers']['X-Auth-Token'] = self.token

        if data is not None:
            kwargs['data'] = data

        if params is not None:
            kwargs['params'] = params

        func = getattr(self.session, verb.lower())

        try:
            r = func(**kwargs)
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


class CollectdPlugin(base.Base):

    def __init__(self, *args, **kwargs):
        super(CollectdPlugin, self).__init__(*args, **kwargs)
        # The timeout/max_retries are defined according to the observations on
        # 200 nodes environments with 600 VMs. See #1554502 for details.
        self.timeout = 20
        self.max_retries = 2
        self.os_client = None
        self.extra_config = {}
        self._threads = {}
        self.pagination_limit = None
        self.polling_interval = 60
        self._last_run = None
        self.changes_since = False

    def _build_url(self, service, resource):
        s = (self.get_service(service) or {})
        url = s.get('url')
        # v3 API must be used in order to obtain tenants in multi-domain envs
        if service == 'keystone' and (resource in ['projects',
                                                   'users', 'roles']):
            url = url.replace('v2.0', 'v3')

        if url:
            if url[-1] != '/':
                url += '/'
            url = "%s%s" % (url, resource)
        else:
            self.logger.error("Service '%s' not found in catalog" % service)
        return url

    def raw_get(self, url, token_required=False):
        return self.os_client.make_request('get', url,
                                           token_required=token_required)

    def iter_workers(self, service):
        """ Return the list of workers and their state

        Here is an example of returned dictionnary:
        {
          'host': 'node.example.com',
          'service': 'nova-compute',
          'state': 'up'
        }

        where 'state' can be 'up', 'down' or 'disabled'
        """

        if service == 'neutron':
            endpoint = 'v2.0/agents'
            entry = 'agents'
        else:
            endpoint = 'os-services'
            entry = 'services'

        ost_services_r = self.get(service, endpoint)

        msg = "Cannot get state of {} workers".format(service)
        if ost_services_r is None:
            self.logger.warning(msg)
        elif ost_services_r.status_code != 200:
            msg = "{}: Got {} ({})".format(
                msg, ost_services_r.status_code, ost_services_r.content)
            self.logger.warning(msg)
        else:
            try:
                r_json = ost_services_r.json()
            except ValueError:
                r_json = {}

            if entry not in r_json:
                msg = "{}: couldn't find '{}' key".format(msg, entry)
                self.logger.warning(msg)
            else:
                for val in r_json[entry]:
                    data = {'host': val['host'], 'service': val['binary']}

                    if service == 'neutron':
                        if not val['admin_state_up']:
                            data['state'] = 'disabled'
                        else:
                            data['state'] = 'up' if val['alive'] else 'down'
                    else:
                        if val['status'] == 'disabled':
                            data['state'] = 'disabled'
                        elif val['state'] == 'up' or val['state'] == 'down':
                            data['state'] = val['state']
                        else:
                            msg = "Unknown state for {} workers:{}".format(
                                service, val['state'])
                            self.logger.warning(msg)
                            continue

                    yield data

    def get(self, service, resource, params=None):
        url = self._build_url(service, resource)
        if not url:
            return
        self.logger.info('GET({}) {}'.format(url, params))
        return self.os_client.make_request('get', url, params=params)

    @property
    def service_catalog(self):
        if not self.os_client.service_catalog:
            # In case the service catalog is empty (eg Keystone was down when
            # collectd started), we should try to get a new token
            self.os_client.get_token()
        return self.os_client.service_catalog

    def get_service(self, service_name):
        return next((x for x in self.service_catalog
                    if x['name'] == service_name), None)

    def config_callback(self, config):
        super(CollectdPlugin, self).config_callback(config)
        for node in config.children:
            if node.key == 'Username':
                username = node.values[0]
            elif node.key == 'Password':
                password = node.values[0]
            elif node.key == 'Tenant':
                tenant_name = node.values[0]
            elif node.key == 'KeystoneUrl':
                keystone_url = node.values[0]
            elif node.key == 'PaginationLimit':
                self.pagination_limit = int(node.values[0])
            elif node.key == 'PollingInterval':
                self.polling_interval = int(node.values[0])

        self.os_client = OSClient(username, password, tenant_name,
                                  keystone_url, self.timeout, self.logger,
                                  self.max_retries)

    def get_objects(self, project, object_name, api_version='',
                    params=None, detail=False, since=False):
        """ Return a list of OpenStack objects

            The API version is not always included in the URL endpoint
            registered in Keystone (eg Glance). In this case, use the
            api_version parameter to specify which version should be used.

        """
        self.changes_since = since
        if params is None:
            params = {}

        if api_version:
            resource = '%s/%s' % (api_version, object_name)
        else:
            resource = '%s' % (object_name)

        if detail:
            resource = '{}/detail'.format(resource)

        opts = {}
        if self.pagination_limit:
            opts['limit'] = self.pagination_limit

        opts.update(params)

        def openstack_api_poller():
            _objects = []
            _opts = {}
            _opts.update(opts)

            if self.changes_since and self._last_run:
                _opts['changes-since'] = self._last_run.isoformat()

            # Keep track of the initial request time
            last_run = datetime.datetime.now(tz=dateutil.tz.tzutc())
            has_failure = False

            while True:
                r = self.get(project, resource, params=_opts)
                if not r or object_name not in r.json():
                    has_failure = True
                    if r is None:
                        err = ''
                    else:
                        err = r.text
                    self.collectd.warning('Could not find {}: {} {}'.format(
                        project, object_name, err
                    ))
                    # Avoid to provide incomplete data by reseting current
                    # set.
                    _objects = []
                    break

                resp = r.json()
                bulk_objs = resp.get(object_name)
                if not bulk_objs:
                    # emtpy list
                    break

                _objects.extend(bulk_objs)

                if self.pagination_limit is None:
                    # Either the pagination is not supported or there is
                    # no more data
                    # In both cases, we got at this stage all the data we
                    # can have.
                    break

                links = resp.get('{}_links'.format(object_name))
                if links is not None:
                    # if there is no 'next' link in the response, all data has
                    # been read.
                    if len([i for i in links if i.get('rel') == 'next']) == 0:
                        break
                    _opts['marker'] = bulk_objs[-1]['id']

                elif resp.get('next'):
                    m = MARKER_RE.match(resp.get('next'))
                    if not m:
                        break
                    _opts['marker'] = m.group(1)
                else:
                    break

            if not has_failure:
                self._last_run = last_run

            return _objects

        poller_id = '{}:{}'.format(project, resource)
        if poller_id not in self._threads:
            t = base.AsyncPoller(self.collectd,
                                 openstack_api_poller,
                                 self.polling_interval,
                                 poller_id, self.changes_since)
            t.start()
            self._threads[poller_id] = t

        t = self._threads[poller_id]
        if not t.is_alive():
            self.logger.warning("Unexpected end of the thread {}".format(
                t.name))
            del self._threads[poller_id]
            return []

        return t.results

    def count_objects_group_by(self,
                               list_object,
                               group_by_func,
                               count_func=None):

        """ Count the number of items grouped by arbitrary criteria."""

        counts = defaultdict(int)
        for obj in list_object:
            s = group_by_func(obj)
            try:
                counts[s] += count_func(obj) if count_func else 1
            except TypeError:
                # Ignore when count_func() doesn't return a number
                pass
        return counts
