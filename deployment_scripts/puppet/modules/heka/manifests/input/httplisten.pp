define heka::input::httplisten (
  $ensure = present,
  $config_dir,
  $decoder,
  $address = '127.0.0.1',
  $port,
) {

  include heka::params

  file { "${config_dir}/httplisten-${title}.toml":
    ensure  => $ensure,
    content => template('heka/input/httplisten.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
