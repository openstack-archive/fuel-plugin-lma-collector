$lma_collector_hash = hiera('lma_collector')

if $lma_collector_hash['influxdb_mode'] != 'disabled' {
  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))
  # Only install this python collectd plugin if ceph-osd is deployed on a
  # dedicated node.
  if size($roles) == 1 {
    class { 'lma_collector::collectd::ceph_osd': }
  }else{
    notice('ceph_osd_perf not configured to avoid messing of collectd python plugin configuration!')
  }
}
