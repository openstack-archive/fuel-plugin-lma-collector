# Configure the aggregator input plugin
class { 'lma_collector::aggregator::server':
  listen_address  => '0.0.0.0',
}

# Configure the cluster policies
$policies = parseyaml('
---
highest_severity:
  - status: down
    trigger:
      logical_operator: or
      rules:
        - function: count
          arguments: [ down ]
          relational_operator: ">"
          threshold: 0
  - status: critical
    trigger:
      logical_operator: or
      rules:
        - function: count
          arguments: [ critical ]
          relational_operator: ">"
          threshold: 0
  - status: warning
    trigger:
      logical_operator: or
      rules:
        - function: count
          arguments: [ warning ]
          relational_operator: ">"
          threshold: 0
  - status: okay
    trigger:
      logical_operator: or
      rules:
        - function: count
          arguments: [ okay ]
          relational_operator: ">"
          threshold: 0
  - status: unknown
')

class { 'lma_collector::gse_policies':
  policies => $policies
}

# Configure the GSE cluster filter for the services
lma_collector::gse_cluster_filter { 'services':
  input_message_types => ['afd_service_metric'],
  aggregator_flag     => true,
  cluster_field       => 'service',
  member_field        => 'source',
  output_message_type => 'gse_service_cluster_metric',
  output_metric_name  => 'cluster_service_status',
  interval            => 10,
  warm_up_period      => 80,
  clusters            => {
    rabbitmq => {
      policy   => 'majority_of_members',
      group_by => 'hostname',
      members  => ['queues']
    }
  }
}

# Configure the GSE cluster filter for the nodes
lma_collector::gse_cluster_filter { 'nodes':
  input_message_types => ['afd_node_metric'],
  aggregator_flag     => true,
  cluster_field       => 'node_role',
  member_field        => 'source',
  output_message_type => 'gse_node_cluster_metric',
  output_metric_name  => 'cluster_node_status',
  interval            => 10,
  warm_up_period      => 80,
  clusters            => {
    controllers => {
      policy   => 'majority_of_members',
      group_by => 'hostname',
      members  => ['cpu']
    }
  }
}

# Configure the GSE global cluster filter
lma_collector::gse_cluster_filter { 'global':
  input_message_types => ['gse_node_cluster_metric',
                          'gse_service_cluster_metric'],
  aggregator_flag     => false,
  cluster_field       => 'cluster_name',
  member_field        => 'source',
  output_message_type => 'gse_cluster_metric',
  output_metric_name  => 'cluster_status',
  interval            => 10,
  warm_up_period      => 80,
  clusters            => {
    rabbitmq => {
      policy   => 'majority_of_members',
      group_by => 'member',
      members  => ['controllers', 'rabbitmq']
    }
  }
}

# Send GSE global metrics to Nagios
lma_collector::gse_nagios { 'global_clusters':
  openstack_deployment_name => 'prod',
  url                       => 'http://nagios.example.com/cgi-bin/cmd.cgi',
  user                      => 'nagiosadmin',
  password                  => 'secret',
  message_type              => 'gse_cluster_metric',
  virtual_hostname          => 'global_clusters',
}
