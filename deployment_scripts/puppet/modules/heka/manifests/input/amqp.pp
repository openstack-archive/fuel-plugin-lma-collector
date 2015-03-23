define heka::input::amqp (
  $config_dir,
  $decoder,
  $user,
  $password,
  $host,
  $port,
  $exchange,
  $queue,
  $exchange_durability = false,
  $exchange_auto_delete = false,
  $queue_auto_delete = true,
  $exchange_type = 'topic',
  $routing_key = '*',
  $ensure = present,
) {

  include heka::params

  file { "${config_dir}/amqp-${title}.toml":
    ensure  => $ensure,
    content => template('heka/input/amqp.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
