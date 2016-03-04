# Configure an AFD filter that computes the mean value of CPU idle over the
# last 2 minutes and emits AFD metrics with severity:
# - CRITICAL when this value is less than 2%
# - WARNING when this value is between 2% and 5%
# - OKAY otherwise
lma_collector::afd_filter { 'cpu_alarm':
  type               => 'node',
  cluster_name       => 'controllers',
  logical_name       => 'cpu',
  alarms             => ['cpu_critical', 'cpu_warning'],
  alarms_definitions => [{
    name        => 'cpu_critical',
    description => 'The CPU usage is too high.',
    severity    => 'critical',
    trigger     => {
      logical_name => 'or',
      rules        => [{
        metric              => 'cpu_idle',
        relational_operator => '<',
        threshold           => 2,
        window              => 120,
        'function'          => 'avg',
      }]
    }
  }, {
    name        => 'cpu_warning',
    description => 'The CPU usage is high.',
    severity    => 'warning',
    trigger     => {
      logical_name => 'or',
      rules        => [{
        metric              => 'cpu_idle',
        relational_operator => '<',
        threshold           => 5,
        window              => 120,
        'function'          => 'avg',
      }]
    }
  }],
  message_matcher    => 'Fields[name] == \'cpu_idle\'',
}

# Configure an AFD filter that computes the minimum value of outstanding
# messages in RabbitMQ over the last 5 minutes and emits AFD metrics with
# severity:
# - WARNING when this value is more than 1000
# - OKAY otherwise
lma_collector::afd_filter { 'rabbitmq_messgaes':
  type               => 'service',
  cluster_name       => 'rabbitmq',
  logical_name       => 'queues',
  alarms             => ['too_many_messages'],
  alarms_definitions => [{
    name        => 'too_many_messages',
    description => 'The number of outstanding messages is too high.',
    severity    => 'warning',
    trigger     => {
      logical_name => 'or',
      rules        => [{
        metric              => 'rabbitmq_messages',
        relational_operator => '>',
        threshold           => 1000,
        window              => 300,
        'function'          => 'min',
      }]
    }
  }],
  message_matcher    => 'Fields[name] == \'rabbitmq_messages\'',
}

# Configure the output filter that send the AFD metrics to the aggregator
class { 'lma_collector::aggregator::client':
  address => 'aggregator.example.com',
}

# Send AFD node metrics to Nagios
lma_collector::afd_nagios { 'nodes':
  ensure   => present,
  hostname => $::hostname,
  url      => 'http://nagios.example.com/cgi-bin/cmd.cgi',
  user     => 'nagiosadmin',
  password => 'secret',
}
