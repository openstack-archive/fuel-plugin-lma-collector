define heka::decoder::sandbox (
  $ensure = present,
  $config_dir,
  $filename,
  $config = {},
) {

  include heka::params

  validate_hash($config)

  file { "${config_dir}/decoder-${title}.toml":
    ensure  => $ensure,
    content => template('heka/decoder/sandbox.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
