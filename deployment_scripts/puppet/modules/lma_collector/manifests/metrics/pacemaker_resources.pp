class lma_collector::metrics::pacemaker_resources (
  $interval = $lma_collector::params::pacemaker_resources_interval,
) inherits lma_collector::params {

  include heka::params

  file { $lma_collector::params::pacemaker_resources_script:
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

  $pacemaker_resource_cmd = {"${lma_collector::params::pacemaker_resources_script}" => []}

  heka::input::process { 'pacemaker_resource':
    config_dir        => $lma_collector::params::config_dir,
    commands          => [$pacemaker_resource_cmd],
    decoder           => 'pacemaker_resource',
    splitter          => 'pacemaker_resource',
    ticker_interval   => $interval,
    notify            => Class['lma_collector::service'],
  }

  heka::decoder::sandbox { 'pacemaker_resource':
    config_dir  => $lma_collector::params::config_dir,
    filename    => "${lma_collector::params::plugins_dir}/decoders/pacemaker_resources.lua",
    notify      => Class['lma_collector::service'],
  }
}
