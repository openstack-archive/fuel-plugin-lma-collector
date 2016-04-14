# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

notice('fuel-plugin-lma-collector: check_environment_configuration.pp')

# This manifest is only executed on the primrary-controller to verify that the
# plugin's configuration matches with the environment.

$lma_collector = hiera_hash('lma_collector')
$network_metadata = hiera('network_metadata')

$elasticsearch_mode = $lma_collector['elasticsearch_mode']
if $elasticsearch_mode == 'local' {
  # Check that the Elasticsearch-Kibana plugin is enabled for that environment
  # and that the node names match
  $elasticsearch_kibana = hiera_hash('elasticsearch_kibana', false)
  if ! $elasticsearch_kibana {
    fail('Could not get the Elasticsearch parameters. The Elasticsearch-Kibana plugin is probably not installed.')
  }
  elsif ! $elasticsearch_kibana['metadata']['enabled'] {
    fail('Could not get the Elasticsearch parameters. The Elasticsearch-Kibana plugin is probably not enabled for this environment.')
  }

  # Check that the Elasticsearch-Kibana node exists in the environment
  $es_nodes = get_nodes_hash_by_roles($network_metadata, ['elasticsearch_kibana', 'primary-elasticsearch_kibana'])
  if size(keys($es_nodes)) < 1 {
    fail("Could not find node with role 'elasticsearch_kibana' in the environment")
  }
}

$influxdb_mode = $lma_collector['influxdb_mode']
if $influxdb_mode == 'local' {
  # Check that the InfluxDB-Grafana plugin is enabled for that environment
  # and that the node names match
  $influxdb_grafana = hiera_hash('influxdb_grafana', false)
  if ! $influxdb_grafana {
    fail('Could not get the InfluxDB parameters. The InfluxDB-Grafana plugin is probably not installed.')
  }
  elsif ! $influxdb_grafana['metadata']['enabled'] {
    fail('Could not get the InfluxDB parameters. The InfluxDB-Grafana plugin is probably not enabled for this environment.')
  }
  # Check that the InfluxDB-Grafana node exists in the environment
  $influxdb_nodes = get_nodes_hash_by_roles($network_metadata, ['influxdb_grafana', 'primary-influxdb_grafana'])
  if size(keys($influxdb_nodes)) < 1 {
    fail("Could not find node with role 'influxdb_grafana' in the environment")
  }
}
