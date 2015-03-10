define heka::output::http (
  $ensure          = present,
  $config_dir,
  $url,
  $encoder         = $title,
  $message_matcher = 'FALSE',
  $username        = undef,
  $password        = undef,
  $timeout         = undef,
  $method          = 'POST',
) {

  include heka::params

  file { "${config_dir}/output-${title}.toml":
    ensure  => $ensure,
    content => template('heka/output/http.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
 }
}

