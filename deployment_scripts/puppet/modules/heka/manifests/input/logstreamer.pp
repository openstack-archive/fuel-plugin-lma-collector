define heka::input::logstreamer(
  $config_dir,
  $decoder,
  $splitter = undef,
  $log_directory = '/var/log',
  $file_match = undef,
  $differentiator = undef,
  $ensure = present,
) {

  include heka::params

  file { "${config_dir}/logstreamer-${title}.toml":
    ensure  => $ensure,
    content => template('heka/input/logstreamer.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
