class lma_collector::metrics::pacemaker_resources (
  $interval = lma_collector::params::pacemaker_resources_interval,
) inherits lma_collector::params {

  include heka::params

  file { "${lma_collector::params::pacemaker_resources_script}":
    ensure  => present,
    source  => 'puppet:///modules/lma_collector/pacemaker/locate_resources.sh',
    mode    => '0750',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }

  heka::splitter::token { 'pacemaker_resource':
    config_dir => $lma_collector::params::config_dir,
    delimiter  => '\n',
  }

  heka::input::process { 'pacemaker_resource':
    config_dir => $lma_collector::params::config_dir,
    decoder    => 'pacemaker_resource',
    command    => $lma_collector::params::pacemaker_resources_script,
    splitter   => 'pacemaker_resource',
    notify     => Class['lma_collector::service'],
  }

  heka::decoder::sandbox { 'pacemaker_resource':
    config_dir  => $lma_collector::params::config_dir,
    filename    => "${lma_collector::params::plugins_dir}/filters/pacemaker_resources.lua",
    notify      => Class['lma_collector::service'],
  }
}
