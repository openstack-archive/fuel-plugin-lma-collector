define heka::input::process (
  $config_dir,
  $decoder,
  $commands,
  $splitter = false,
  $ticker_interval = '60',
  $stdout = true,
  $stderr = false,
  $ensure = present,
) {

  include heka::params

  file { "${config_dir}/process-${title}.toml":
    ensure  => $ensure,
    content => template('heka/input/process.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
