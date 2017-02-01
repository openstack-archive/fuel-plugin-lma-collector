# Copyright 2016 Mirantis, Inc.
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

notice('fuel-plugin-lma-collector: collectd.pp')

if hiera('lma::collector::influxdb::server', false) {
  prepare_network_config(hiera_hash('network_scheme', {}))

  $fuel_version = 0 + hiera('fuel_version')
  $management_vip  = hiera('management_vip')
  $mgmt_address    = get_network_role_property('management', 'ipaddr')
  $lma_collector   = hiera_hash('lma_collector')
  $node_profiles   = hiera_hash('lma::collector::node_profiles')
  $is_controller   = $node_profiles['controller']
  $is_base_os      = $node_profiles['base_os']
  $is_mysql_server = $node_profiles['mysql']
  $is_rabbitmq     = $node_profiles['rabbitmq']
  $is_compute      = $node_profiles['compute']
  $is_ceph_osd     = $node_profiles['ceph_osd']
  $is_elasticsearch_node = $node_profiles['elasticsearch']
  $is_influxdb_node      = $node_profiles['influxdb']
  $nova    = hiera_hash('nova', {})
  $neutron = hiera_hash('quantum_settings', {})
  $cinder  = hiera_hash('cinder', {})
  $haproxy_socket  = '/var/lib/haproxy/stats'
  $storage_options = hiera_hash('storage', {})
  if $storage_options['volumes_ceph'] or $storage_options['images_ceph'] or
      $storage_options['objects_ceph'] or $storage_options['ephemeral_ceph']{
    $ceph_enabled = true
  } else {
    $ceph_enabled = false
  }

  if $is_controller or $is_rabbitmq {
    Service<| title == 'metric_collector' |> {
      provider => 'pacemaker'
    }
  }

  if $is_elasticsearch_node {
    $process_matches = [{name => 'elasticsearch', regex => 'java'}]
  } else {
    $process_matches = undef
  }
  if $is_influxdb_node {
    $processes = ['influxd', 'grafana-server', 'hekad', 'collectd']
  } else {
    $processes = ['hekad', 'collectd']
  }
  if $is_controller {
    # collectd plugins on controller do many network I/O operations, so
    # it is recommended to increase this value
    $read_threads = 10
  } else {
    $read_threads = 5
  }
  class { 'lma_collector::collectd::base':
    processes       => $processes,
    process_matches => $process_matches,
    # Purge the default configuration shipped with the collectd package
    purge           => true,
    read_threads    => $read_threads,
  }

  if $is_mysql_server {
    class { 'lma_collector::collectd::mysql':
      username => hiera('lma::collector::monitor::mysql_username'),
      password => hiera('lma::collector::monitor::mysql_password'),
      socket   => hiera('lma::collector::monitor::mysql_socket'),
      require  => Class['lma_collector::collectd::base'],
    }

    lma_collector::collectd::dbi_mysql_status { 'mysql_status':
      username => hiera('lma::collector::monitor::mysql_username'),
      dbname   => hiera('lma::collector::monitor::mysql_db'),
      password => hiera('lma::collector::monitor::mysql_password'),
      require  => Class['lma_collector::collectd::base'],
    }
  }

  if $is_rabbitmq {
    $rabbit = hiera_hash('rabbit')
    if $rabbit['user'] {
      $rabbitmq_user = $rabbit['user']
    }
    else {
      $rabbitmq_user = 'nova'
    }
    class { 'lma_collector::collectd::rabbitmq':
      username => $rabbitmq_user,
      password => $rabbit['password'],
      require  => Class['lma_collector::collectd::base'],
    }
  }

  # Configure Pacemaker plugin
  if $is_controller {
    $pacemaker_master_resource = 'vip__management'
    $controller_resources = {
      'vip__public'      => 'vip__public',
      'vip__management'  => 'vip__management',
      'vip__vrouter_pub' => 'vip__vrouter_pub',
      'vip__vrouter'     => 'vip__vrouter',
      'p_haproxy'        => 'haproxy',
    }
  } else {
    $pacemaker_master_resource = undef
    $controller_resources = {}
  }
  # Deal with detach-* plugins
  if $is_mysql_server {
    if $fuel_version < 9.0 {
      $mysql_resource_name = 'p_mysql'
    } else {
      $mysql_resource_name = 'p_mysqld'
    }
    $mysql_resource = {
      "${mysql_resource_name}" => 'mysqld',
    }
  }
  else {
    $mysql_resource = {}
  }
  if $is_rabbitmq {
    $rabbitmq_resource = {
      'p_rabbitmq-server' => 'rabbitmq',
    }
  }
  else {
    $rabbitmq_resource = {}
  }
  $resources = merge($controller_resources, $mysql_resource, $rabbitmq_resource)

  if ! empty($resources) {
    class { 'lma_collector::collectd::pacemaker':
      resources       => $resources,
      notify_resource => $pacemaker_master_resource,
      hostname        => $::fqdn,
      require         => Class['lma_collector::collectd::base'],
    }
  }

  if $is_controller {
    # Configure OpenStack plugins
    $openstack_service_config = {
      user                      => 'nova',
      password                  => $nova['user_password'],
      tenant                    => 'services',
      keystone_url              => "http://${management_vip}:5000/v2.0",
      pacemaker_master_resource => $pacemaker_master_resource,
      require                   => Class['lma_collector::collectd::base'],
    }
    $openstack_services = {
      'nova_services'   => $openstack_service_config,
      'cinder_services' => $openstack_service_config,
      'keystone'        => $openstack_service_config,
      'neutron_agents'  => $openstack_service_config,
    }

    $nova_polling = {
      'polling_interval' => 60,
      'pagination_limit' => 500,
    }
    $cinder_polling = {
      'polling_interval' => 60,
      'pagination_limit' => 500,
    }
    $glance_polling = {
      'polling_interval' => 60,
      'pagination_limit' => 25,
    }
    $neutron_polling = {
      'polling_interval' => 60,
      'pagination_limit' => 100,
    }
    $openstack_resources = {
      'nova'            => merge($openstack_service_config, $nova_polling),
      'cinder'          => merge($openstack_service_config, $cinder_polling),
      'glance'          => merge($openstack_service_config, $glance_polling),
      'neutron'         => merge($openstack_service_config, $neutron_polling),
    }
    create_resources(lma_collector::collectd::openstack, $openstack_services)
    create_resources(lma_collector::collectd::openstack, $openstack_resources)

    # FIXME(elemoine) use the special attribute * when Fuel uses a Puppet version
    # that supports it.
    class { 'lma_collector::collectd::openstack_checks':
      user                      => $openstack_service_config[user],
      password                  => $openstack_service_config[password],
      tenant                    => $openstack_service_config[tenant],
      keystone_url              => $openstack_service_config[keystone_url],
      pacemaker_master_resource => $openstack_service_config[pacemaker_master_resource],
      require                   => Class['lma_collector::collectd::base'],
    }

    # FIXME(elemoine) use the special attribute * when Fuel uses a Puppet version
    # that supports it.
    class { 'lma_collector::collectd::hypervisor':
      user                      => $openstack_service_config[user],
      password                  => $openstack_service_config[password],
      tenant                    => $openstack_service_config[tenant],
      keystone_url              => $openstack_service_config[keystone_url],
      pacemaker_master_resource => $openstack_service_config[pacemaker_master_resource],
      # Fuel sets cpu_allocation_ratio to 8.0 in nova.conf
      cpu_allocation_ratio      => 8.0,
      require                   => Class['lma_collector::collectd::base'],
    }

    class { 'lma_collector::collectd::haproxy':
      socket       => $haproxy_socket,
      # Ignore internal stats ('Stats' for 6.1, 'stats' for 7.0), lma proxies and
      # Nova EC2
      proxy_ignore => ['Stats', 'stats', 'lma', 'nova-api-1'],
      proxy_names  => {
        'ceilometer'          => 'ceilometer-api',
        'cinder-api'          => 'cinder-api',
        'glance-api'          => 'glance-api',
        'glance-registry'     => 'glance-registry-api',
        'heat-api'            => 'heat-api',
        'heat-api-cfn'        => 'heat-cfn-api',
        'heat-api-cloudwatch' => 'heat-cloudwatch-api',
        'horizon'             => 'horizon-web',
        'horizon-ssl'         => 'horizon-https',
        'keystone-1'          => 'keystone-public-api',
        'keystone-2'          => 'keystone-admin-api',
        'murano'              => 'murano-api',
        'mysqld'              => 'mysqld-tcp',
        'neutron'             => 'neutron-api',
        # starting with Mitaka (and later)
        'nova-api'            => 'nova-api',
        # before Mitaka
        'nova-api-2'          => 'nova-api',
        'nova-novncproxy'     => 'nova-novncproxy-websocket',
        'nova-metadata-api'   => 'nova-metadata-api',
        'sahara'              => 'sahara-api',
        'swift'               => 'swift-api',
      },
      require      => Class['lma_collector::collectd::base'],
    }

    if $ceph_enabled {
      class { 'lma_collector::collectd::ceph_mon':
      require => Class['lma_collector::collectd::base'],
      }
    }

    class { 'lma_collector::collectd::memcached':
      host    => get_network_role_property('mgmt/memcache', 'ipaddr'),
      require => Class['lma_collector::collectd::base'],
    }

    # Enable the Apache status module
    class { 'fuel_lma_collector::mod_status': }
    class { 'lma_collector::collectd::apache':
      require  => Class['lma_collector::collectd::base'],
    }

    # Check local endpoint
    $cinder_api     = get_network_role_property('cinder/api', 'ipaddr')
    $glance_api     = get_network_role_property('glance/api', 'ipaddr')
    $heat_api       = get_network_role_property('heat/api', 'ipaddr')
    $keystone_api   = get_network_role_property('keystone/api', 'ipaddr')
    $neutron_api    = get_network_role_property('neutron/api', 'ipaddr')
    $nova_api       = get_network_role_property('nova/api', 'ipaddr')
    $swift_api      = get_network_role_property('swift/api', 'ipaddr')
    if $fuel_version < 9.0 {
      $cinder_expected_code = 200
    } else {
      # Since Mitaka, Cinder returns 300 instead of 200 in previous releases
      $cinder_expected_code = 300
    }
    class { 'lma_collector::collectd::check_local_endpoint':
      urls           => {
        'cinder-api'          => "http://${cinder_api}:8776",
        'glance-api'          => "http://${glance_api}:9292",
        'heat-api'            => "http://${heat_api}:8004",
        'heat-cfn-api'        => "http://${heat_api}:8000",
        'keystone-public-api' => "http://${keystone_api}:5000",
        'neutron-api'         => "http://${neutron_api}:9696",
        'nova-api'            => "http://${nova_api}:8774",
        'swift-api'           => "http://${swift_api}:8080/info",
      },
      expected_codes => {
        'cinder-api'          => $cinder_expected_code,
        'glance-api'          => 300,
        'heat-api'            => 300,
        'heat-cfn-api'        => 300,
        'keystone-public-api' => 300,
        'neutron-api'         => 200,
        'nova-api'            => 200,
        'swift-api'           => 200,
      },
      timeout        => 1,
      max_retries    => 3,
      require        => Class['lma_collector::collectd::base'],
    }

    $influxdb_server = hiera('lma::collector::influxdb::server')
    $influxdb_port = hiera('lma::collector::influxdb::port')
    class { 'lma_collector::collectd::http_check':
      urls                      => {
        'influxdb-cluster' => "http://${influxdb_server}:${influxdb_port}/ping",
      },
      expected_codes            => {
        'influxdb-cluster' => 204
      },
      timeout                   => 1,
      max_retries               => 3,
      pacemaker_master_resource => $pacemaker_master_resource,
      require                   => Class['lma_collector::collectd::base'],
    }
  }

  # Compute
  if $is_compute {
    class { 'lma_collector::collectd::libvirt':
      require  => Class['lma_collector::collectd::base'],
    }
    class { 'lma_collector::collectd::libvirt_check':
      require  => Class['lma_collector::collectd::base'],
    }
  }

  # Ceph OSD
  if $is_ceph_osd {
    class { 'lma_collector::collectd::ceph_osd':
      require  => Class['lma_collector::collectd::base'],
    }
  }

  # InfluxDB
  if $is_influxdb_node {
    class { 'lma_collector::collectd::influxdb':
      username => 'root',
      password => hiera('lma::collector::influxdb::root_password'),
      address  => hiera('lma::collector::influxdb::listen_address'),
      port     => hiera('lma::collector::influxdb::influxdb_port', 8086),
      require  => Class['lma_collector::collectd::base'],
    }
  }

  # Elasticsearch
  if $is_elasticsearch_node {
    class { 'lma_collector::collectd::elasticsearch':
      address => hiera('lma::collector::elasticsearch::listen_address'),
      port    => hiera('lma::collector::elasticsearch::rest_port', 9200),
      require => Class['lma_collector::collectd::base'],
    }
  }

  if $is_influxdb_node or $is_elasticsearch_node {
    class { 'lma_collector::collectd::haproxy':
      socket  => $haproxy_socket,
      require => Class['lma_collector::collectd::base'],
    }
  }
}
