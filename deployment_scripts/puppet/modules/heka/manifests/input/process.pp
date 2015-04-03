define heka::input::process (
  $config_dir,
  $decoder,
  $command,
  $args = [],
  $splitter = false,
  $interval = '60',
  $stdout = 'true',
  $stderr = 'false',
  $ensure = present,
) {

  include heka::params

  validate_array($args)

  $arguments = join(['"',join($args, '", ')], '"')

  file { "${config_dir}/process-${title}.toml":
    ensure  => $ensure,
    content => template('heka/input/process.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
