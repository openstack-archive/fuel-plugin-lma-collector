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

CURRENT_TIME=$(date +%Y-%m-%d-%H-%M-%S)
TIMEOUT=$(which timeout)
TAR=$(which tar)

GRAFANA_PORT=8000
NAGIOS_PORT=8001
ES_PORT=9200
INFLUXDB_PORT=8086

echo $(hostname) role $(hiera roles)
echo $CURRENT_TIME
TWO_COLLECTORS=""

function has_collector {
   if [ -d /etc/log_collector ]; then
     TWO_COLLECTORS="yes"
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
   if which crm >/dev/null; then
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
    echo "'$process' process does not LISTEN on port: $port"
  elif [ "$cnt" -ne "$expect" ]; then
    echo "$cnt LISTEN ports for process $process, $expect expected on port: $port!"
  fi

  return $cnt
}

function check_process {
  process=$1
  out=$2
  expect=${3:-1}
  ps auxf | grep -v grep | grep "$process" > $out
  cnt=$(ps auxf | grep -v grep | grep "$process" | wc -l)
  if [ "$cnt" -eq 0 ]; then
    echo "'$process' process not found"
  elif [ "$expect" != "any" ] && [ "$cnt" -ne "$expect" ]; then
    echo "$cnt processes found, $expect expected!"
  fi
  return $cnt
}

function tail_file {
    file="$1"
    out="$2"
    num=${3:-10000}
    tail -n $num "$file" >> "$out" 2>&1
    return $?
}

function diag_collectd {
  diag_output="${DIAG_DIR}/collectd"
  mkdir -p "${diag_output}/etc"
  cp -rf /etc/collectd "${diag_output}/etc/"
  mkdir -p "${diag_output}/plugins"
  cp -rf /usr/lib/collectd/*py "${diag_output}/plugins/" 2>/dev/null
  tail_file /var/log/collectd.log "${diag_output}/last.log"
  check_process "collectd -C" "${diag_output}/processes"
  check_process collectdmon "${diag_output}/processes"
}

function diag_influxdb {
  diag_output="${DIAG_DIR}/influxdb"
  mkdir -p "${diag_output}/etc"
  cp -rf /etc/influxdb "${diag_output}/etc/"
  tail_file /var/log/influxdb/influxd.log "${diag_output}/last.log"
  check_process "/usr/bin/influxd" "${diag_output}/processes"

  check_net_listen influxd "${diag_output}/netstat" 1 $INFLUXDB_PORT
  listening=$?
  if [ $listening -gt 0 ]; then
    local_address=$(netstat -apn | grep LISTEN | grep ":$INFLUXDB_PORT" | awk '{print $4}')
    $TIMEOUT 5 curl -v -q "$local_address/ping" > "${diag_output}/test_ping" 2>&1
    if [ $? -ne 0 ]; then
      echo "Fail to reach Influxdb ($local_address)"
    fi
  fi

  address=$(hiera lma::influxdb::vip)
  if [ "$address" != "nil" ]; then
    address=$address:$INFLUXDB_PORT
    $TIMEOUT 5 curl -v -q "${address}/ping" > "${diag_output}/test_ping.vip" 2>&1
    if [ $? -ne 0 ]; then
      echo "Fail to reach Influxdb ($address)"
    fi
  fi

  diag_output="${DIAG_DIR}/grafana"
  mkdir -p "${diag_output}/etc"
  cp -rf /etc/grafana "${diag_output}/etc"
  tail_file /var/log/grafana/grafana.log "${diag_output}/last.log"

  check_process grafana-server "${diag_output}/processes"
  check_net_listen grafana "${diag_output}/netstat" 1 $GRAFANA_PORT

  $TIMEOUT 5 curl -v -q "${address}/login" > "${diag_output}/vip_test" 2>&1
  if [ $? -ne 0 ]; then
    echo "Fail to reach Grafana ($address:$GRAFANA_PORT)"
  fi
}

function diag_elasticsearch {
  diag_output="${DIAG_DIR}/elasticsearch"
  mkdir -p "${diag_output}/etc"
  cp -rf /etc/elasticsearch "${diag_output}/etc/"
  for l in $(ls /var/log/elasticsearch/es-01/*.log); do
    tail_file "$l" "${diag_output}/last.log"
  done

  # Get previous logs
  for l in $(ls /var/log/elasticsearch/es-01/*.log.2*| tail -n 2); do
    tail_file "$l" "${diag_output}/previous.log"
  done
  check_process elasticsearch "${diag_output}/processes"
  check_net_listen java "${diag_output}/netstat.$ES_PORT" 1 $ES_PORT
  listening=$?
  local_address=$(netstat -apn | grep LISTEN | grep ":$ES_PORT" | awk '{print $4}')
  if [ $listening -gt 0 ]; then
    $TIMEOUT 5 curl -v -q "$local_address/_cat/indices?v" > "${diag_output}/indices" 2>&1
    $TIMEOUT 5 curl -v -q "$local_address/_cluster/health?pretty" > "${diag_output}/cluster_health" 2>&1
    if [ $? -ne 0 ]; then
      echo "Fail to reach local Elasticsearch ($address)"
    fi
  fi

  address=$(hiera lma::elasticsearch::vip)
  if [ "$address" != "nil" ]; then
    address="${address}:${ES_PORT}"

    $TIMEOUT 5 curl -v -q "${address}/_cluster/health?pretty" > "${diag_output}/cluster_health.vip" 2>&1
    if [ $? -ne 0 ]; then
      echo "Fail to reach Elasticsearch through the VIP ($address)"
    else
      $TIMEOUT 5 curl -v -q "${address}/_cat/indices?v" > "${diag_output}/indices.vip" 2>&1
    fi
  fi
}

function diag_collector {
  diag_output="${DIAG_DIR}/collector"
  mkdir -p "$diag_output"
  check_process hekad "${diag_output}/processes" 2

  # Dashboard
  check_net_listen hekad "${diag_output}/netstat.4352" 1 4352
  # HTTP input
  check_net_listen hekad "${diag_output}/netstat.8325" 1 8325

  if [ -n "$TWO_COLLECTORS" ]; then
    # TCP metric input
    check_net_listen hekad "${diag_output}/netstat.5567" 1 5567
    # Dashboard
    check_net_listen hekad "${diag_output}/netstat.4353" 1 4353
  fi

  mkdir -p "${DIAG_DIR}/collector/etc/"
  etc_dir="/etc/lma_collector /etc/log_collector /etc/metric_collector"
  for d in $etc_dir; do
    if [ ! -d "$d" ]; then
       continue
    fi
    cp -rf $d "${DIAG_DIR}/collector/etc/"
  done

  mkdir -p "${DIAG_DIR}/collector/lua_modules/"
  for d in /usr/share/lma_collector /usr/share/lma_collector_modules; do
    cp -rf $d "${DIAG_DIR}/collector/lua_modules/"
  done

  cache_dir="/var/cache/lma_collector /var/cache/log_collector /var/cache/metric_collector"
  for d in $cache_dir; do
     if [ ! -d "$d" ]; then
       continue
     fi
     collector_name=$(basename $d)
     out="${DIAG_DIR}/collector/${collector_name}.cache"
     find "$d" -ls |grep -v "dashboard/" > "$out"
     find "$d" -name checkpoint.txt | while read f; do
      echo $f >> "$out"
      cat $f >> "$out"
      echo  >> "$out"
     done
  done

  log_file="/var/log/lma_collector.log /var/log/log_collector.log /var/log/metric_collector.log"
  log_file="${log_file} /var/log/upstart/lma_collector.log /var/log/upstart/log_collector.log /var/log/upstart/metric_collector.log"
  logs_dir="${DIAG_DIR}/collector/logs"
  mkdir -p "$logs_dir"
  for l in $log_file; do
    if [ ! -f "$l" ]; then
       continue
    fi
    collector_name=$(echo $l|tr '/' _)
    tail_file "$l" "$logs_dir/${collector_name}"
  done
}

function diag_nagios {
  diag_output="${DIAG_DIR}/nagios"
  mkdir -p $diag_output/etc
  cp -rf /etc/nagios3/ $diag_output/etc

  nagios3  -v /etc/nagios3/nagios.cfg > $diag_output/configuration_validation 2>&1
  if [ $? -ne 0 ]; then
    echo "Nagios configuration error"
  fi

  check_process nagios3 "$diag_output/processes.nagios3"
  check_process apache2 "$diag_output/processes.apache2" any

  tail_file /var/nagios/nagios.log "$diag_output/last.log"
  tail_file /var/log/apache2/nagios_error.log "$diag_output/apache_error.log"
  tail_file /var/log/apache2/nagios_access.log "$diag_output/apache_access.log"

  # lma_infrastructure_alerting >= v0.9
  address=$(hiera lma::infrastructure_alerting::vip)
  if [ "$address" == "nil" ]; then
    # lma_infrastructure_alerting v0.8
    address="127.0.0.1"
  fi
  $TIMEOUT 2 curl -v -q "$address:$NAGIOS_PORT" > "${diag_output}/nagios_ui_test" 2>&1
  if [ $? -ne 0 ]; then
    echo "Fail to reach Apache/Nagios ($address:$NAGIOS_PORT)"
  fi
}

function diag_pacemaker {
  diag_output="${DIAG_DIR}/pacemaker"
  CRM=$(which crm)
  $TIMEOUT 5 $CRM status > "${diag_output}.status" 2>&1
  $TIMEOUT 5 $CRM configure show > "${diag_output}.configuration" 2>&1
}

function diag_node {
  seconds=10

  touch "${DIAG_DIR}/$(hostname)"
  diag_output="${DIAG_DIR}/node"
  mkdir "$diag_output" || return 1
  uptime > $diag_output/uptime
  dmesg | tail -n 100 > $diag_output/dmesg
  vmstat 1 $seconds > $diag_output/vmstat
  mpstat -P ALL 1 $seconds > $diag_output/mpstat
  pidstat 1 $seconds > $diag_output/pidstat
  iostat -xz 1 $seconds > $diag_output/iostat
  lshw > $diag_output/lshw
  cat /proc/cpuinfo > $diag_output/cpuinfo
  df -h > $diag_output/df
  crontab -l > $diag_output/crontab

  if which "iptables-save" >/dev/null; then
    iptables-save > $diag_output/iptables
  fi

  mkdir -p "${DIAG_DIR}/hiera"
  cp -rf /etc/*.yaml /etc/hiera "${DIAG_DIR}/hiera"

  ls -l /etc/fuel/plugins > "${DIAG_DIR}/fuel_plugins"

  cp -f /var/log/puppet.log $DIAG_DIR
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

diag_node

exit 0
