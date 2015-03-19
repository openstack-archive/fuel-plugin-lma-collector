define heka::input::amqp (
  $ensure = present,
  $config_dir,
  $decoder,
  $user,
  $password,
  $host,
  $port,
  $exchange,
  $exchange_durability = false,
  $exchange_auto_delete = false,
  $queue_auto_delete = true,
  $exchange_type = "topic",
  $queue,
  $routing_key = "*",
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
