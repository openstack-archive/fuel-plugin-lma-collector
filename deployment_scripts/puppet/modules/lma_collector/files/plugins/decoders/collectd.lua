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
require 'table'

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

function replace_dot_by_sep (str)
    return string.gsub(str, '%.', sep)
end

function split_service_and_state_and_hostname(str)
    -- Possible values:
    --   services.compute.down.node-1.test.domain.local
    --   services.scheduler.up
    --   agents.dhcp.down.node-44
    --   agents.dhcp.up
    --   services.scheduler.disabled.rbd:volumes
    local service, state, hostname = string.match(str, '^%w+%.([%w-]+)%.([%w-]+)%.?(.-)$')
    -- remove domain part of the hostname or nil if string is empty
    hostname = string.match(hostname, '^([^.]+)')
    return replace_dot_by_sep(service), state, hostname
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
            if metric_source == 'df' then
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
            elseif metric_source == 'interface' then
                msg['Fields']['name'] = sample['type'] .. sep .. sample['dsnames'][i]
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
                if sample['type_instance'] ~= nil and sample['type_instance'] ~= '' then
                    msg['Fields']['os_region'] = sample['type_instance']
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
                if sample['meta'] and sample['meta']['host'] then
                    msg['Fields']['hostname'] = sample['meta']['host']
                end
                if sample['meta'] and sample['meta']['aggregate'] then
                    msg['Fields']['aggregate'] = sample['meta']['aggregate']
                    if msg['Fields']['tag_fields'] then
                        table.insert(msg['Fields']['tag_fields'], 'aggregate')
                    else
                        msg['Fields']['tag_fields'] = { 'aggregate' }
                    end
                end
                if sample['meta'] and sample['meta']['aggregate_id'] then
                    msg['Fields']['aggregate_id'] = sample['meta']['aggregate_id']
                    if msg['Fields']['tag_fields'] then
                        table.insert(msg['Fields']['tag_fields'], 'aggregate_id')
                    else
                        msg['Fields']['tag_fields'] = { 'aggregate_id' }
                    end
                end
            elseif metric_source == 'rabbitmq_info' then
                if sample['type_instance'] ~= 'consumers' and
                   sample['type_instance'] ~= 'messages' and
                   sample['type_instance'] ~= 'memory' and
                   sample['type_instance'] ~= 'used_memory' and
                   sample['type_instance'] ~= 'unmirrored_queues' and
                   sample['type_instance'] ~= 'vm_memory_limit' and
                   sample['type_instance'] ~= 'disk_free_limit' and
                   sample['type_instance'] ~= 'disk_free' and
                   sample['type_instance'] ~= 'remaining_memory' and
                   sample['type_instance'] ~= 'remaining_disk' and
                   (string.match(sample['type_instance'], '%.consumers$') or
                   string.match(sample['type_instance'], '%.messages$') or
                   string.match(sample['type_instance'], '%.memory$')) then
                    local q, m = string.match(sample['type_instance'], '^(.+)%.([^.]+)$')
                    msg['Fields']['name'] = 'rabbitmq_queue' .. sep .. m
                    msg['Fields']['queue'] = q
                    msg['Fields']['tag_fields'] = { 'queue' }
                else
                    msg['Fields']['name'] = 'rabbitmq' .. sep .. sample['type_instance']
                end
            elseif metric_source == 'nova' then
                msg['Fields']['name'] = 'openstack' .. sep .. 'nova' .. sep .. replace_dot_by_sep(sample['plugin_instance'])
                msg['Fields']['tag_fields'] = { 'state' }
                msg['Fields']['state'] = sample['type_instance']
            elseif metric_source == 'cinder' then
                msg['Fields']['name'] = 'openstack' .. sep .. 'cinder' .. sep .. replace_dot_by_sep(sample['plugin_instance'])
                msg['Fields']['tag_fields'] = { 'state' }
                msg['Fields']['state'] = sample['type_instance']
            elseif metric_source == 'glance' then
                -- TODO(pasquier-s): check if the collectd plugin can send state as type_instance
                local resource, visibility, state = string.match(sample['type_instance'], '^([^.]+)%.([^.]+)%.(.+)$')
                msg['Fields']['name'] = 'openstack'  .. sep .. 'glance' .. sep .. replace_dot_by_sep(resource)
                msg['Fields']['tag_fields'] = { 'state', 'visibility' }
                msg['Fields']['state'] = state
                msg['Fields']['visibility'] = visibility
            elseif metric_source == 'keystone' then
                -- TODO(pasquier-s): check if the collectd plugin can send state as type_instance
                if sample['type_instance'] == 'roles' then
                    msg['Fields']['name'] = 'openstack'  .. sep .. 'keystone' .. sep .. sample['type_instance']
                else
                    local resource, state = string.match(sample['type_instance'], '^([^.]+)%.(.+)$')
                    msg['Fields']['name'] = 'openstack'  .. sep .. 'keystone' .. sep .. replace_dot_by_sep(resource)
                    msg['Fields']['tag_fields'] = { 'state' }
                    msg['Fields']['state'] = state
                end
            elseif metric_source == 'neutron' then
                if sample['type_instance'] == 'networks' or sample['type_instance'] == 'ports' or sample['type_instance'] == 'routers' or sample['type_instance'] == 'floatingips' then
                    skip_it = true
                elseif sample['type_instance'] == 'subnets' then
                    msg['Fields']['name'] = 'openstack'  .. sep .. 'neutron' .. sep .. 'subnets'
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
                if not string.match(sample['type_instance'], '^frontend') and
                   not string.match(sample['type_instance'], '^backend') then
                    msg['Fields']['name'] = 'haproxy' .. sep .. sample['type_instance']
                elseif string.match(sample['type_instance'], '^[^.]+%.[^.]+$') then
                    skip_it = true
                else
                    local side, name, m, state = string.match(sample['type_instance'], '^([^.]+)%.([^.]+)%.([^.]+)%.([^.]+)$')
                    if not side then
                        side, name, m = string.match(sample['type_instance'], '^([^.]+)%.([^.]+)%.([^.]+)$')
                    end
                    msg['Fields']['name'] = 'haproxy' .. sep .. side .. sep .. m
                    msg['Fields']['tag_fields'] = { side } -- backend or frontend
                    msg['Fields'][side] = name
                    if state then
                        msg['Fields']['tag_fields'][2] = 'state'
                        msg['Fields']['state'] = state
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
            elseif metric_source ==  'dbi' and sample['plugin_instance'] == 'services_nova' then
                local service, state, hostname = split_service_and_state_and_hostname(sample['type_instance'])
                if hostname then
                    msg['Fields']['name'] = 'openstack' .. sep .. 'nova' .. sep .. 'service'
                    msg['Fields']['hostname'] = hostname
                else
                    msg['Fields']['name'] = 'openstack' .. sep .. 'nova' .. sep .. 'services'
                end
                msg['Fields']['tag_fields'] = { 'service', 'state' }
                msg['Fields']['service'] = service
                msg['Fields']['state'] = state
            elseif metric_source ==  'dbi' and sample['plugin_instance'] == 'services_cinder' then
                local service, state, hostname = split_service_and_state_and_hostname(sample['type_instance'])
                if hostname then
                    msg['Fields']['name'] = 'openstack' .. sep .. 'cinder' .. sep .. 'service'
                    msg['Fields']['hostname'] = hostname
                else
                    msg['Fields']['name'] = 'openstack' .. sep .. 'cinder' .. sep .. 'services'
                end
                msg['Fields']['tag_fields'] = { 'service', 'state' }
                msg['Fields']['service'] = service
                msg['Fields']['state'] = state
            elseif metric_source ==  'dbi' and sample['plugin_instance'] == 'agents_neutron' then
                local service, state, hostname = split_service_and_state_and_hostname(sample['type_instance'])
                if hostname then
                    msg['Fields']['name'] = 'openstack' .. sep .. 'neutron' .. sep .. 'agent'
                    msg['Fields']['hostname'] = hostname
                else
                    msg['Fields']['name'] = 'openstack' .. sep .. 'neutron' .. sep .. 'agents'
                end
                msg['Fields']['tag_fields'] = { 'service', 'state' }
                msg['Fields']['service'] = service
                msg['Fields']['state'] = state
            elseif metric_source == 'pacemaker_resource' then
                msg['Fields']['name'] = 'pacemaker_local_resource_active'
                msg['Fields']['tag_fields'] = { 'resource' }
                msg['Fields']['resource'] = sample['type_instance']
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
            end
        end
    end

    return 0
end
