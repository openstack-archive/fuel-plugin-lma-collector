define heka::splitter::token (
  $ensure = present,
  $config_dir,
  $delimiter,
) {

  include heka::params

  file { "${config_dir}/splitter-${title}.toml":
    ensure  => $ensure,
    content => template('heka/splitter/token.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}

