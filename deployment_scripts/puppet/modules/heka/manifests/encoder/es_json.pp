define heka::encoder::es_json (
  $config_dir,
  $es_index_from_timestamp = false,
  $index = undef,
  $ensure = present,
) {

  include heka::params

  file { "${config_dir}/encoder-${title}.toml":
    ensure  => $ensure,
    content => template('heka/encoder/es_json.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
