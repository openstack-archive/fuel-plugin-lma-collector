define heka::filter::sandbox (
  $config_dir,
  $filename,
  $preserve_data = false,
  $message_matcher = 'FALSE',
  $ticker_interval = undef,
  $config = {},
  $ensure = present,
) {

  include heka::params

  validate_hash($config)

  file { "${config_dir}/filter-${title}.toml":
    ensure  => $ensure,
    content => template('heka/filter/sandbox.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
