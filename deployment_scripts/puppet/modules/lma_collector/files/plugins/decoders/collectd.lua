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

local sep = '.'

function process_message ()
    local ok, samples = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        -- TODO: log error
        return -1
    end

    for _, sample in ipairs(samples) do
        local metric_prefix = sample['type']
        if sample['type_instance'] ~= "" then metric_prefix = metric_prefix .. sep .. sample['type_instance'] end

        local metric_source = sample['plugin']

        for i, value in ipairs(sample['values']) do
            local metric_name = metric_prefix
            if sample['dsnames'][i] ~= "value" then metric_name = metric_name .. sep .. sample['dsnames'][i] end

            local msg = {
                Timestamp = sample['time'] * 1e9, -- Heka expects nanoseconds
                Hostname = sample['host'],
                Logger = "collectd",
                Payload = cjson.encode(sample),
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
                local mount = sample['plugin_instance']
                local entity
                if sample['type'] == 'df_inodes' then
                    entity = 'inodes'
                else -- sample['type'] == 'df_complex'
                    entity = 'space'
                end
                msg['Fields']['name'] = 'fs' .. sep .. mount .. sep .. entity .. sep .. sample['type_instance']
                msg['Fields']['device'] = '/' .. string.gsub(mount, '-', '/')
            elseif metric_source == 'disk' then
                msg['Fields']['device'] = sample['plugin_instance']
                msg['Fields']['name'] = 'disk' .. sep .. sample['plugin_instance'] .. sep .. metric_name
            elseif metric_source == 'cpu' then
                msg['Fields']['device'] = 'cpu' .. sample['plugin_instance']
                msg['Fields']['name'] = 'cpu' .. sep .. sample['plugin_instance'] .. sep .. sample['type_instance']
            elseif metric_source == 'interface' then
                msg['Fields']['device'] = sample['plugin_instance']
                msg['Fields']['name'] = 'net' .. sep .. sample['plugin_instance'] .. sep .. sample['type'] .. sep .. sample['dsnames'][i]
            elseif metric_source == 'processes' then
                if sample['type'] == 'ps_state' then
                    msg['Fields']['name'] = 'processes' .. sep .. 'state' .. sep .. sample['type_instance']
                else
                    msg['Fields']['name'] = 'processes' .. sep .. sample['type']
                end
            elseif metric_source == 'mysql' then
                if sample['type'] == 'threads' then
                    msg['Fields']['name'] = 'mysql_' .. metric_name
                else
                    msg['Fields']['name'] = metric_name
                end
            elseif metric_source == 'check_openstack_api' then
                -- OpenStack API metrics
                -- 'plugin_instance' = <service name>
                msg['Fields']['name'] = 'openstack' .. sep .. sample['plugin_instance'] .. sep .. 'check_api'
                if sample['type_instance'] ~= nil and sample['type_instance'] ~= '' then
                    msg['Fields']['os_region'] = sample['type_instance']
                end
            elseif metric_source == 'hypervisor_stats' then
                -- OpenStack hypervisor metrics
                -- 'plugin_instance' = <hostname>
                -- 'type_instance' = <metric name> which can end by _MB or _GB
                msg['Fields']['hostname'] = sample['plugin_instance']
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
            elseif metric_source == 'nova' then
                msg['Fields']['name'] = 'openstack.nova' .. sep .. sample['plugin_instance'] .. sep .. sample['type_instance']
            elseif metric_source == 'cinder' then
                msg['Fields']['name'] = 'openstack.cinder' .. sep .. sample['plugin_instance'] .. sep .. sample['type_instance']
            elseif metric_source == 'glance' then
                msg['Fields']['name'] = 'openstack.glance' .. sep .. sample['type_instance']
            elseif metric_source == 'keystone' then
                msg['Fields']['name'] = 'openstack.keystone' .. sep .. sample['type_instance']
            elseif metric_source == 'memcached' then
                msg['Fields']['name'] = 'memcached' .. sep .. string.gsub(metric_name, 'memcached_', '')
            elseif metric_source == 'haproxy' then
                msg['Fields']['name'] = 'haproxy' .. sep .. sample['type_instance']
            else
                msg['Fields']['name'] = metric_name
            end
            utils.inject_tags(msg)
            inject_message(msg)
        end
    end

    return 0
end
