define heka::encoder::payload (
  $config_dir,
  $append_newlines = false,
  $prefix_ts       = false,
  $ensure          = present,
) {

  include heka::params

  file { "${config_dir}/encoder-${title}.toml":
    ensure  => $ensure,
    content => template('heka/encoder/payload.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}

