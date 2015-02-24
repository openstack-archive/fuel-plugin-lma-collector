define heka::input::logstreamer(
  $ensure = present,
  $config_dir,
  $decoder,
  $log_directory = '/var/log',
  $file_match = undef,
  $differentiator = undef,
  $parser_type = undef,
  $delimiter = undef,
  $delimiter_location = undef,
) {

  include heka::params

  file { "${config_dir}/logstreamer-${title}.toml":
    ensure  => $ensure,
    content => template('heka/input/logstreamer.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
    require => File[$config_dir],
  }
}
