-- Copyright 2015 Mirantis, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
require "string"
require "cjson"

local utils = require 'lma_utils'

local sep = '_'

local processes_map = {
    ps_code = 'memory_code',
    ps_count = '',
    ps_cputime = 'cputime',
    ps_data = 'memory_data',
    ps_disk_octets = 'disk_bytes',
    ps_disk_ops = 'disk_ops',
    ps_pagefaults = 'pagefaults',
    ps_rss = 'memory_rss',
    ps_stacksize = 'stacksize',
    ps_vm = 'memory_virtual',
}

-- this is needed for the libvirt metrics because in that case, collectd sends
-- the instance's ID instead of the hostname in the 'host' attribute
local hostname = read_config('hostname') or error('hostname must be specified')
local swap_size = (read_config('swap_size') or 0) + 0

function replace_dot_by_sep (str)
    return string.gsub(str, '%.', sep)
end

function process_message ()
    local ok, samples = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        -- TODO: log error
        return -1
    end

    for _, sample in ipairs(samples) do
        local metric_prefix = sample['type']
        if sample['type_instance'] ~= "" then
            metric_prefix = metric_prefix .. sep .. sample['type_instance']
        end

        local metric_source = sample['plugin']

        for i, value in ipairs(sample['values']) do
            local skip_it = false
            local metric_name = metric_prefix
            if sample['dsnames'][i] ~= "value" then
                metric_name = metric_name .. sep .. sample['dsnames'][i]
            end

            local msg = {
                Timestamp = sample['time'] * 1e9, -- Heka expects nanoseconds
                Hostname = sample['host'],
                Logger = "collectd",
                Payload = utils.safe_json_encode(sample) or '',
                Severity = 6,
                Type = "metric",
                Fields = {
                    hostname = sample['host'],
                    interval = sample['interval'],
                    source =  metric_source,
                    type =  sample['dstypes'][i],
                    value =  value,
                }
            }

            -- Normalize metric name, unfortunately collectd plugins aren't
            -- always consistent on metric namespaces so we need a few if/else
            -- statements to cover all cases.

            if sample['meta'] and sample['meta']['service_check'] then
                msg['Fields']['name'] = sample['meta']['service_check'] .. sep .. 'check'
                msg['Fields']['details'] = sample['meta']['failure']
            elseif metric_source == 'df' then
                local entity
                if sample['type'] == 'df_inodes' then
                    entity = 'inodes'
                elseif sample['type'] == 'percent_inodes' then
                    entity = 'inodes_percent'
                elseif sample['type'] == 'percent_bytes' then
                    entity = 'space_percent'
                else -- sample['type'] == 'df_complex'
                    entity = 'space'
                end

                local mount = sample['plugin_instance']
                if mount == 'root' then
                    mount  = '/'
                else
                    mount = '/' .. mount:gsub('-', '/')
                end

                msg['Fields']['name'] = 'fs' .. sep .. entity .. sep .. sample['type_instance']
                msg['Fields']['fs'] = mount
                msg['Fields']['tag_fields'] = { 'fs' }
            elseif metric_source == 'disk' then
                msg['Fields']['name'] = metric_name
                msg['Fields']['device'] = sample['plugin_instance']
                msg['Fields']['tag_fields'] = { 'device' }
            elseif metric_source == 'cpu' then
                msg['Fields']['name'] = 'cpu' .. sep .. sample['type_instance']
                msg['Fields']['cpu_number'] = sample['plugin_instance']
                msg['Fields']['tag_fields'] = { 'cpu_number' }
            elseif metric_source == 'netlink' then
                local netlink_metric = sample['type']

                if netlink_metric == 'if_rx_errors' then
                    netlink_metric = 'if_errors_rx'
                elseif netlink_metric == 'if_tx_errors' then
                    netlink_metric = 'if_errors_tx'
                end

                -- Netlink plugin can send one or two values. Use dsnames only when needed.
                if sample['dsnames'][i] ~= 'value' then
                    netlink_metric = netlink_metric .. sep .. sample['dsnames'][i]
                end
                -- and type of errors is set in type_instance
                if sample['type_instance'] ~= '' then
                    netlink_metric = netlink_metric .. sep .. sample['type_instance']
                end
                msg['Fields']['name'] = netlink_metric
                msg['Fields']['interface'] = sample['plugin_instance']
                msg['Fields']['tag_fields'] = { 'interface' }
            elseif metric_source == 'processes' then
                if processes_map[sample['type']] then
                    -- metrics related to a specific process
                    msg['Fields']['service'] = sample['plugin_instance']
                    msg['Fields']['tag_fields'] = { 'service' }
                    msg['Fields']['name'] = 'lma_components'
                    if processes_map[sample['type']] ~= '' then
                        msg['Fields']['name'] = msg['Fields']['name'] .. sep .. processes_map[sample['type']]
                    end
                    if sample['dsnames'][i] ~= 'value' then
                        msg['Fields']['name'] = msg['Fields']['name'] .. sep .. sample['dsnames'][i]
                    end

                    -- For ps_cputime, convert it to a percentage: collectd is
                    -- sending us the number of microseconds allocated to the
                    -- process as a rate so within 1 second.
                    if sample['type'] == 'ps_cputime' then
                        msg['Fields']['value'] = 100 * value / 1e6
                    end
                else
                    -- metrics related to all processes
                    msg['Fields']['name'] = 'processes'
                    if sample['type'] == 'ps_state' then
                        msg['Fields']['name'] = msg['Fields']['name'] .. sep .. 'count'
                        msg['Fields']['state'] = sample['type_instance']
                        msg['Fields']['tag_fields'] = { 'state' }
                    else
                        msg['Fields']['name'] = msg['Fields']['name'] .. sep .. sample['type']
                    end
                end
            elseif metric_source ==  'dbi' and sample['plugin_instance'] == 'mysql_status' then
                msg['Fields']['name'] = 'mysql' .. sep .. replace_dot_by_sep(sample['type_instance'])
            elseif metric_source == 'mysql' then
                if sample['type'] == 'threads' then
                    msg['Fields']['name'] = 'mysql_' .. metric_name
                elseif sample['type'] == 'mysql_commands' then
                    msg['Fields']['name'] = sample['type']
                    msg['Fields']['statement'] = sample['type_instance']
                    msg['Fields']['tag_fields'] = { 'statement' }
                elseif sample['type'] == 'mysql_handler' then
                    msg['Fields']['name'] = sample['type']
                    msg['Fields']['handler'] = sample['type_instance']
                    msg['Fields']['tag_fields'] = { 'handler' }
                else
                    msg['Fields']['name'] = metric_name
                end
            elseif metric_source == 'check_openstack_api' then
                -- For OpenStack API metrics, plugin_instance = <service name>
                msg['Fields']['name'] = 'openstack_check_api'
                msg['Fields']['service'] = sample['plugin_instance']
                msg['Fields']['tag_fields'] = { 'service' }
                if sample['meta'] then
                    msg['Fields']['os_region'] = sample['meta']['region']
                end
            elseif metric_source == 'hypervisor_stats' then
                -- Metrics from the OpenStack hypervisor metrics where
                -- type_instance = <metric name> which can end by _MB or _GB
                msg['Fields']['name'] = 'openstack' .. sep .. 'nova' .. sep
                local name, unit
                name, unit = string.match(sample['type_instance'], '^(.+)_(.B)$')
                if name then
                    msg['Fields']['name'] = msg['Fields']['name'] .. name
                    msg.Fields['value'] = {value = msg.Fields['value'], representation = unit}
                else
                    msg['Fields']['name'] = msg['Fields']['name'] .. sample['type_instance']
                end
            elseif metric_source == 'rabbitmq_info' then
                msg['Fields']['name'] = 'rabbitmq' .. sep .. sample['type_instance']
                if sample['meta'] and sample['meta']['queue'] then
                    msg['Fields']['queue'] = sample['meta']['queue']
                    msg['Fields']['tag_fields'] = { 'queue' }
                end
            elseif metric_source == 'nova' then
                if sample['plugin_instance'] == 'nova_services' or
                   sample['plugin_instance'] == 'nova_service'  then
                    msg['Fields']['name'] = 'openstack_' .. sample['plugin_instance']
                    msg['Fields']['tag_fields'] = { 'service', 'state' }
                    msg['Fields']['service'] = sample['meta']['service']
                    msg['Fields']['state'] = sample['meta']['state']
                    if sample['plugin_instance'] == 'nova_service'  then
                        msg['Fields']['hostname'] = sample['meta']['host']
                    end
                else
                    msg['Fields']['name'] = 'openstack' .. sep .. 'nova' .. sep .. replace_dot_by_sep(sample['plugin_instance'])
                    msg['Fields']['tag_fields'] = { 'state' }
                    msg['Fields']['state'] = sample['type_instance']
                end
            elseif metric_source == 'cinder' then
                if sample['plugin_instance'] == 'cinder_services' or
                   sample['plugin_instance'] == 'cinder_service' then
                    msg['Fields']['name'] = 'openstack_' .. sample['plugin_instance']
                    msg['Fields']['tag_fields'] = { 'service', 'state' }
                    msg['Fields']['service'] = sample['meta']['service']
                    msg['Fields']['state'] = sample['meta']['state']
                    if sample['plugin_instance'] == 'cinder_service' then
                        msg['Fields']['hostname'] = sample['meta']['host']
                    end
                else
                    msg['Fields']['name'] = 'openstack' .. sep .. 'cinder' .. sep .. replace_dot_by_sep(sample['plugin_instance'])
                    msg['Fields']['tag_fields'] = { 'state' }
                    msg['Fields']['state'] = sample['type_instance']
                end
            elseif metric_source == 'glance' then
                msg['Fields']['name'] = 'openstack'  .. sep .. 'glance' .. sep .. sample['type_instance']
                msg['Fields']['tag_fields'] = { 'state', 'visibility' }
                msg['Fields']['state'] = sample['meta']['status']
                msg['Fields']['visibility'] = sample['meta']['visibility']
            elseif metric_source == 'keystone' then
               msg['Fields']['name'] = 'openstack'  .. sep .. 'keystone' .. sep .. sample['type_instance']
               if sample['meta']['state'] then
                   msg['Fields']['tag_fields'] = { 'state' }
                   msg['Fields']['state'] = sample['meta']['state']
               end
            elseif metric_source == 'neutron' then
                if sample['type_instance'] == 'networks' or sample['type_instance'] == 'ports' or sample['type_instance'] == 'routers' or sample['type_instance'] == 'floatingips' then
                    skip_it = true
                elseif sample['type_instance'] == 'subnets' then
                    msg['Fields']['name'] = 'openstack'  .. sep .. 'neutron' .. sep .. 'subnets'
                elseif sample['type_instance'] == 'neutron_agents' or
                       sample['type_instance'] == 'neutron_agent' then
                    msg['Fields']['name'] = 'openstack_' .. sample['type_instance']
                    msg['Fields']['tag_fields'] = { 'service', 'state' }
                    msg['Fields']['service'] = sample['meta']['service']
                    msg['Fields']['state'] = sample['meta']['state']
                    if sample['type_instance'] == 'neutron_agent'  then
                        msg['Fields']['hostname'] = sample['meta']['host']
                    end
                elseif string.match(sample['type_instance'], '^ports') then
                    local resource, owner, state = string.match(sample['type_instance'], '^([^.]+)%.([^.]+)%.(.+)$')
                    msg['Fields']['name'] = 'openstack'  .. sep .. 'neutron' .. sep .. replace_dot_by_sep(resource)
                    msg['Fields']['tag_fields'] = { 'owner', 'state' }
                    msg['Fields']['owner'] = owner
                    msg['Fields']['state'] = state
                else
                    local resource, state = string.match(sample['type_instance'], '^([^.]+)%.(.+)$')
                    msg['Fields']['name'] = 'openstack'  .. sep .. 'neutron' .. sep .. replace_dot_by_sep(resource)
                    msg['Fields']['tag_fields'] = { 'state' }
                    msg['Fields']['state'] = state
                end
            elseif metric_source == 'memcached' then
                msg['Fields']['name'] = 'memcached' .. sep .. string.gsub(metric_name, 'memcached_', '')
            elseif metric_source == 'haproxy' then
                msg['Fields']['name'] = 'haproxy' .. sep .. sample['type_instance']
                if sample['meta'] then
                    if sample['meta']['backend'] then
                        msg['Fields']['tag_fields'] = { 'backend' }
                        msg['Fields']['backend'] = sample['meta']['backend']
                        if sample['meta']['state'] then
                            msg['Fields']['state'] = sample['meta']['state']
                            table.insert(msg['Fields']['tag_fields'], 'state')
                        end
                        if sample['meta']['server'] then
                            msg['Fields']['server'] = sample['meta']['server']
                            table.insert(msg['Fields']['tag_fields'], 'server')
                        end
                    elseif sample['meta']['frontend'] then
                        msg['Fields']['tag_fields'] = { 'frontend' }
                        msg['Fields']['frontend'] = sample['meta']['frontend']
                    end
                end
            elseif metric_source == 'apache' then
                metric_name = string.gsub(metric_name, 'apache_', '')
                msg['Fields']['name'] = 'apache' .. sep .. string.gsub(metric_name, 'scoreboard', 'workers')
            elseif metric_source == 'ceph_osd_perf' then
                msg['Fields']['name'] = 'ceph_perf' .. sep .. sample['type']

                msg['Fields']['tag_fields'] = { 'cluster', 'osd' }
                msg['Fields']['cluster'] = sample['plugin_instance']
                msg['Fields']['osd'] = sample['type_instance']
            elseif metric_source:match('^ceph') then
                msg['Fields']['name'] = 'ceph' .. sep .. sample['type']
                if sample['dsnames'][i] ~= 'value' then
                    msg['Fields']['name'] = msg['Fields']['name'] .. sep .. sample['dsnames'][i]
                end

                msg['Fields']['tag_fields'] = { 'cluster' }
                msg['Fields']['cluster'] = sample['plugin_instance']

                if sample['type_instance'] ~= '' then
                    local additional_tag
                    if string.match(sample['type'], '^pool_') then
                        additional_tag = 'pool'
                    elseif string.match(sample['type'], '^pg_state') then
                        additional_tag = 'state'
                    elseif string.match(sample['type'], '^osd_') then
                        additional_tag = 'osd'
                    end
                    if additional_tag then
                        msg['Fields']['tag_fields'][2] = additional_tag
                        msg['Fields'][additional_tag] = sample['type_instance']
                    end
                end
            elseif metric_source == 'pacemaker' then
                msg['Fields']['name'] = metric_source .. sep .. sample['type_instance']

                -- add dimension fields
                local t = {}
                for _, v in ipairs({'status', 'resource'}) do
                    if sample['meta'] and sample['meta'][v] then
                        t[#t+1] = v
                        msg['Fields'][v] = sample['meta'][v]
                    end
                end
                if #t > 0 then
                    msg['Fields']['tag_fields'] = t
                end

                if sample['meta'] and sample['meta']['host'] then
                    msg['Fields']['hostname'] = sample['meta']['host']
                end
            elseif metric_source ==  'users' then
                -- 'users' is a reserved name for InfluxDB v0.9
                msg['Fields']['name'] = 'logged_users'
            elseif metric_source ==  'libvirt' then
                -- collectd sends the instance's ID in the 'host' field
                msg['Fields']['instance_id'] = sample['host']
                msg['Fields']['tag_fields'] = { 'instance_id' }
                msg['Fields']['hostname'] = hostname
                msg['Hostname'] = hostname
                if string.match(sample['type'], '^disk_') then
                    msg['Fields']['name'] = 'virt' .. sep .. sample['type'] .. sep .. sample['dsnames'][i]
                    msg['Fields']['device'] = sample['type_instance']
                    msg['Fields']['tag_fields'][2] = 'device'
                elseif string.match(sample['type'], '^if_') then
                    msg['Fields']['name'] = 'virt' .. sep .. sample['type'] .. sep .. sample['dsnames'][i]
                    msg['Fields']['interface'] = sample['type_instance']
                    msg['Fields']['tag_fields'][2] = 'interface'
                elseif sample['type'] == 'virt_cpu_total' then
                    msg['Fields']['name'] = 'virt_cpu_time'
                elseif sample['type'] == 'virt_vcpu' then
                    msg['Fields']['name'] = 'virt_vcpu_time'
                    msg['Fields']['vcpu_number'] = sample['type_instance']
                    msg['Fields']['tag_fields'][2] = 'vcpu_number'
                else
                    msg['Fields']['name'] = 'virt' .. sep .. metric_name
                end
            elseif metric_source == 'elasticsearch_cluster' or metric_source == 'influxdb' then
                msg['Fields']['name'] = metric_source .. sep .. sample['type_instance']
            elseif metric_source == 'http_check' then
                msg['Fields']['name'] = metric_source
                msg['Fields']['service'] = sample['type_instance']
                msg['Fields']['tag_fields'] = { 'service' }
            else
                msg['Fields']['name'] = replace_dot_by_sep(metric_name)
            end

            if not skip_it then
                utils.inject_tags(msg)
                utils.safe_inject_message(msg)
                if metric_source == 'swap' and metric_name == 'swap_used' and swap_size > 0 then
                    -- collectd 5.4.0 doesn't report the used swap in
                    -- percentage, this is why the metric is computed and
                    -- injected by this plugin.
                    msg['Fields']['name'] = 'swap_percent_used'
                    msg['Fields']['value'] = value / swap_size
                    utils.safe_inject_message(msg)
                end
            end
        end
    end

    return 0
end
