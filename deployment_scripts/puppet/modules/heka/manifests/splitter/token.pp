define heka::splitter::token (
  $config_dir,
  $delimiter,
  $ensure = present,
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

