define heka::splitter::regex (
  $ensure = present,
  $config_dir,
  $delimiter,
  $delimiter_eol = undef
) {

  include heka::params

  file { "${config_dir}/splitter-${title}.toml":
    ensure  => $ensure,
    content => template('heka/splitter/regex.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
    require => File[$config_dir],
  }
}
