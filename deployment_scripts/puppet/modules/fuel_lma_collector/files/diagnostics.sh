#!/bin/bash
# Copyright 2016 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

DIAG_DIR=/var/lma_diagnostics
rm -rf "$DIAG_DIR"
mkdir -p "$DIAG_DIR" || exit 1

GRAFANA_PORT=8000
NAGIOS_PORT=8001
ES_PORT=9200
INFLUXDB_PORT=8086
NUM_COLLECTORS=1
DIAG_LOG_FILENAME="$DIAG_DIR/diagnostics.log"

function log_info {
  echo "$(date +%Y-%m-%d-%H-%M-%S) INFO $@" | tee -a $DIAG_LOG_FILENAME
}

function log_err {
  echo "$(date +%Y-%m-%d-%H-%M-%S) ERROR $@" | tee -a $DIAG_LOG_FILENAME
}

log_info $(hostname) role $(hiera roles)

function has_collector {
   if [ -d /etc/log_collector ]; then
     NUM_COLLECTORS=2
     return 0
   fi
   if [ -d /etc/lma_collector ]; then
     return 0
   fi
   return 1
}
function has_collectd {
   if [ -d /etc/collectd ]; then
     return 0
   fi
   return 1
}
function has_influxdb {
   if [ -d /etc/influxdb ]; then
     return 0
   fi
   return 1
}
function has_elasticsearch {
   if [ -d /etc/elasticsearch ]; then
     return 0
   fi
   return 1
}

function has_nagios {
   if [ -d /etc/nagios3 ]; then
     return 0
   fi
   return 1
}

function has_pacemaker {
   if which crm > /dev/null 2>&1; then
     return 0
   fi
   return 1
}

function check_net_listen {
  process=$1
  out=$2
  expect=${3:-1}
  port=$4

  if [ -n "$port" ]; then
    netstat -apn | grep LISTEN | grep "$process"|grep -E ":$port" > "$out"
  else
    netstat -apn | grep LISTEN | grep "$process" > "$out"
    port='any'
  fi
  cnt=$(cat "$out" | wc -l)
  if [ "$cnt" -eq 0 ]; then
    log_err "'$process' process does not LISTEN on port: $port"
  elif [ "$cnt" -ne "$expect" ]; then
    log_err "$cnt LISTEN ports for process $process, $expect expected on port: $port!"
  else
    log_info "$expect process(es) $process is/are listening on port $port"
  fi

  return $cnt
}

function check_process {
  process=$1
  out=$2
  expect=${3:-1}
  ps auxf | grep -v grep | grep -E -- "$process" > $out
  cnt=$(ps auxf | grep -v grep | grep -E -- "$process" | wc -l)
  if [ "$cnt" -eq 0 ]; then
    log_err "'$process' process not found"
  elif [ "$expect" != "any" ] && [ "$cnt" -ne "$expect" ]; then
    log_err "$cnt '$process' processes found, $expect expected!"
  else
    log_info "$cnt process(es) '$process' found"
  fi
  return $cnt
}

function tail_file {
  file="$1"
  base_dir=${2:-$DIAG_DIR}
  path=$(dirname "$file")
  filename=$(basename "$file")
  out="${base_dir}${path}/${filename}"
  mkdir -p $(dirname "$out")
  num=${3:-10000}

  if [ -f "$file" ]; then
    tail -n $num "$file" >> "$out" 2>&1
    log_info "tail -n $num $file -> $out"
  else
    log_err "$file doesn't exist"
  fi
  return $?
}

function copy_file {
  src="$1"
  base_dir=${2:-$DIAG_DIR}

  path=$(dirname "$src")
  out_dir="${base_dir}${path}"
  mkdir -p "$out_dir"
  if [ -d "$src" ]; then
    log_info "Copy directory $src -> $out_dir"
    cp -rf "$src" "$out_dir" 2>/dev/null || log_err "Failed to copy $src into $out_dir/"
  elif [ -f "$src" ]; then
    log_info "Copy file $src -> $out_dir/"
    cp -f "$src" "$out_dir" 2>/dev/null || log_err "Failed to copy $src into $out_dir/"
  else
    log_err "Fail to copy .. '$src' doesn't exist"
  fi
}

function run_cmd {
  cmd=$1
  output_file=$2
  to=${3:-11}
  log_info "Running command: '$cmd' -> $output_file"
  eval "timeout $to $cmd" > "$output_file" 2>&1
  if [ $? -ne 0 ]; then
    log_err "command failed: '$cmd', check $output_file"
    return 1
  fi
  return 0
}

function diag_collectd {
  log_info "** Collectd"
  copy_file /etc/collectd
  find "/usr/lib/collectd/" -name '*.py' | while read f; do
    copy_file "$f"
  done

  diag_output="${DIAG_DIR}/diag.collectd"
  mkdir -p "${diag_output}"
  tail_file /var/log/collectd.log
  check_process "collectd -C" "${diag_output}/processes"
  check_process collectdmon "${diag_output}/processes"
}

function diag_influxdb {
  log_info "** InfluxDB"
  copy_file /etc/influxdb
  tail_file /var/log/influxdb/influxd.log

  diag_output="${DIAG_DIR}/diag.influxdb"
  mkdir -p "${diag_output}"
  check_process "/usr/bin/influxd" "${diag_output}/processes"
  check_net_listen influxd "${diag_output}/netstat" 1 $INFLUXDB_PORT
  listening=$?
  if [ $listening -gt 0 ]; then
    local_address=$(netstat -apn | grep LISTEN | grep ":$INFLUXDB_PORT" | awk '{print $4}')
    run_cmd "curl -S -i $local_address/ping" "${diag_output}/test_ping" 5
    if [ $? -ne 0 ]; then
      log_err "Fail to reach Influxdb ($local_address)"
    fi
  fi

  address=$(hiera lma::influxdb::vip)
  if [ "$address" != "nil" ]; then
    address=$address:$INFLUXDB_PORT
    run_cmd "curl -S -i ${address}/ping" "${diag_output}/test_ping.vip" 5
    if [ $? -ne 0 ]; then
      log_err "Fail to reach Influxdb ($address)"
    fi
  fi

  copy_file /etc/grafana
  tail_file /var/log/grafana/grafana.log

  diag_output="${DIAG_DIR}/diag.grafana"
  mkdir -p "${diag_output}"
  check_process grafana-server "${diag_output}/processes"
  check_net_listen grafana "${diag_output}/netstat" 1 $GRAFANA_PORT

  run_cmd "curl -S -i ${address}/login" "${diag_output}/vip_test" 5
  if [ $? -ne 0 ]; then
    log_err "Fail to reach Grafana ($address:$GRAFANA_PORT)"
  fi
}

function diag_elasticsearch {
  log_info "** Elasticsearch"
  copy_file /etc/elasticsearch
  for l in $(ls /var/log/elasticsearch/es-01/*.log); do
    tail_file "$l"
  done
  # Get previous logs
  es_previous_logs=$(ls /var/log/elasticsearch/es-01/*.log.2* 2>/dev/null | tail -n 2 )
  if [ -n "$es_previous_logs" ]; then
    for l in ; do
      tail_file "$l"
    done
  fi

  diag_output="${DIAG_DIR}/diag.elasticsearch"
  mkdir -p "${diag_output}"
  check_process "-cp.*elasticsearch-.*\.jar" "${diag_output}/processes"
  check_net_listen java "${diag_output}/netstat.$ES_PORT" 1 $ES_PORT
  listening=$?
  local_address=$(netstat -apn | grep LISTEN | grep ":$ES_PORT" | awk '{print $4}')
  if [ $listening -gt 0 ]; then
    run_cmd "curl -S -i $local_address/_cat/indices?v" "${diag_output}/indices" 5
    run_cmd "curl -S -i $local_address/_cluster/health?pretty" "${diag_output}/cluster_health" 5
    if [ $? -ne 0 ]; then
      log_err "Fail to reach local Elasticsearch ($address)"
    fi
  fi

  address=$(hiera lma::elasticsearch::vip)
  if [ "$address" != "nil" ]; then
    address="${address}:${ES_PORT}"

    run_cmd "curl -S -i ${address}/_cluster/health?pretty" "${diag_output}/cluster_health.vip" 5
    if [ $? -ne 0 ]; then
      log_err "Fail to reach Elasticsearch through the VIP ($address)"
    fi
  fi
}

function diag_collector {
  log_info "** LMA Collector"
  diag_output="${DIAG_DIR}/diag.collector"
  mkdir -p "$diag_output"
  check_process "hekad -config" "${diag_output}/processes" $NUM_COLLECTORS

  # Dashboard
  check_net_listen hekad "${diag_output}/netstat.4352" 1 4352
  # HTTP input
  check_net_listen hekad "${diag_output}/netstat.8325" 1 8325

  if [ $NUM_COLLECTORS -eq 2 ]; then
    # TCP metric input
    check_net_listen hekad "${diag_output}/netstat.5567" 1 5567
    # Dashboard
    check_net_listen hekad "${diag_output}/netstat.4353" 1 4353
  fi

  etc_dir="/etc/lma_collector /etc/log_collector /etc/metric_collector"
  for d in $etc_dir; do
    if [ -d "$d" ]; then
      copy_file "$d"
    fi
  done

  for d in /usr/share/lma_collector /usr/share/lma_collector_modules; do
    copy_file "$d"
  done

  cache_dir="/var/cache/lma_collector /var/cache/log_collector /var/cache/metric_collector"
  for d in $cache_dir; do
     if [ ! -d "$d" ]; then
       continue
     fi
     collector_name=$(basename $d)
     out="${diag_output}/${collector_name}.cache"
     find "$d" -ls |grep -v "dashboard/" > "$out"
     find "$d" -name checkpoint.txt | while read f; do
       echo $f >> "$out"
       cat $f >> "$out"
       echo >> "$out"
     done
  done

  log_file="/var/log/lma_collector.log /var/log/log_collector.log /var/log/metric_collector.log"
  log_file="${log_file} /var/log/upstart/lma_collector.log /var/log/upstart/log_collector.log /var/log/upstart/metric_collector.log"
  for l in $log_file; do
    if [ -f "$l" ]; then
      tail_file "$l"
    fi
  done
}

function diag_nagios {
  log_info "** Nagios"
  diag_output="${DIAG_DIR}/diag.nagios"
  mkdir -p "$diag_output"
  copy_file /etc/nagios3/

  run_cmd "nagios3 -v /etc/nagios3/nagios.cfg" "$diag_output/configuration_validation"
  if [ $? -ne 0 ]; then
    log_err "Nagios configuration error"
  fi

  check_process "nagios3 -d" "$diag_output/processes.nagios3"
  check_process "apache2 -k" "$diag_output/processes.apache2" any

  tail_file /var/nagios/nagios.log
  tail_file /var/log/apache2/nagios_error.log
  tail_file /var/log/apache2/nagios_access.log

  # lma_infrastructure_alerting >= v0.9
  address=$(hiera lma::infrastructure_alerting::vip)
  if [ "$address" == "nil" ]; then
    # lma_infrastructure_alerting v0.8
    address="127.0.0.1"
  fi
  run_cmd "curl -S -i $address:$NAGIOS_PORT" "${diag_output}/nagios_ui_test"
  if [ $? -ne 0 ]; then
    log_err "Fail to reach Apache/Nagios ($address:$NAGIOS_PORT)"
  fi
}

function diag_pacemaker {
  log_info "** Pacemaker"
  diag_output="${DIAG_DIR}/diag.pacemaker"
  mkdir -p "$diag_output"
  run_cmd "crm status" "${diag_output}/status"
  run_cmd "crm configure show" "${diag_output}/configuration"
  tail_file /var/log/pacemaker.log
}

function diag_system {
  log_info "** System"

  seconds=10
  diag_output="${DIAG_DIR}/diag.system"
  mkdir -p "$diag_output"
  run_cmd hostname "${diag_output}/hostname"
  run_cmd uptime  $diag_output/uptime
  run_cmd "dmesg | tail -n 100" $diag_output/dmesg
  run_cmd "vmstat 1 $seconds" $diag_output/vmstat
  run_cmd "mpstat -P ALL 1 $seconds" $diag_output/mpstat
  run_cmd "pidstat 1 $seconds" $diag_output/pidstat
  run_cmd "iostat -xz 1 $seconds" $diag_output/iostat
  run_cmd lshw $diag_output/lshw
  run_cmd "df -h" $diag_output/df
  run_cmd "crontab -l" $diag_output/crontab
  copy_file /proc/cpuinfo

  if which "iptables-save" >/dev/null; then
    run_cmd iptables-save $diag_output/iptables
  fi

  find "/etc/hiera" -name '*.yaml' | while read f; do
    copy_file "$f"
  done
  copy_file /etc/hiera.yaml

  ls -l /etc/fuel/plugins > "${DIAG_DIR}/fuel_plugins"

  tail_file /var/log/puppet.log
  run_cmd 'grep -E "MODULAR|fuel-plugin-" /var/log/puppet.log' $diag_output/puppet_tasks.list

  run_cmd "ip route" $diag_output/ip_route
  run_cmd "ip link" $diag_output/ip_link
  run_cmd "ip address" $diag_output/ip_address
  run_cmd "ip netns" $diag_output/ip_netns
  for netns in $(ip netns 2>/dev/null); do
    run_cmd "ip netns exec $netns ip route" "$diag_output/netns_${netns}_ip_route"
    run_cmd "ip netns exec $netns ip link" "$diag_output/netns_${netns}_ip_link"
    run_cmd "ip netns exec $netns ip address" "$diag_output/netns_${netns}_ip_address"
  done
  if which "brctl" >/dev/null; then
      run_cmd "brctl show" $diag_output/brctl_show
  fi
}

if has_collector; then
  diag_collector
fi
if has_pacemaker; then
  diag_pacemaker
fi
if has_collectd; then
  diag_collectd
fi
if has_influxdb; then
  diag_influxdb
fi
if has_elasticsearch; then
  diag_elasticsearch
fi
if has_nagios; then
  diag_nagios
fi

diag_system

exit 0
