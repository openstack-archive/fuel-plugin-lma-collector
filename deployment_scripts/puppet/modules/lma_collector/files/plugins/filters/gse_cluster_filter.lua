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

local cjson = require 'cjson'

local afd = require 'afd'
local gse = require 'gse'
local lma = require 'lma_utils'

local output_message_type = read_config('output_message_type') or error('output_message_type must be specified!')
local cluster_field = read_config('cluster_field')
local member_field = read_config('member_field') or error('member_field must be specified!')
local output_metric_name = read_config('output_metric_name') or error('output_metric_name must be specified!')
local source = read_config('source') or error('source must be specified!')
local topology_file = read_config('topology_file') or error('topology_file must be specified!')
local policies_file = read_config('policies_file') or error('policies_file must be specified!')
local interval = (read_config('interval') or error('interval must be specified!')) + 0
local interval_in_ns = interval * 1e9
local max_inject = (read_config('max_inject') or 10) + 0
local warm_up_period = ((read_config('warm_up_period') or 0) + 0) * 1e9
local activate_alerting = read_config('activate_alerting') or true

local is_active = false
local first_tick
local last_tick = 0
local last_index = nil

local topology = require(topology_file)
local policies = require(policies_file)

for cluster_name, attributes in pairs(topology.clusters) do
    local policy = policies.find(attributes.policy)
    if not policy then
        error('Cannot find ' .. attributes.policy .. ' policy!')
    end
    gse.add_cluster(cluster_name, attributes.members, attributes.hints, attributes.group_by, policy)
end

function process_message()
    local name = read_message('Fields[name]')
    local hostname = read_message('Fields[hostname]')
    if name and name == 'pacemaker_local_resource_active' and read_message("Fields[resource]") == 'vip__management' then
        -- Skip pacemaker_local_resource_active metrics that don't
        -- concern the local node
        if read_message('Hostname') == hostname then
            if read_message('Fields[value]') == 1 then
                is_active = true
            else
                is_active = false
            end
        end
        return 0
    end

    local member_id = afd.get_entity_name(member_field)
    if not member_id then
        return -1, "Cannot find entity's name in the AFD/GSE message"
    end

    local status = afd.get_status()
    if not status then
        return -1, "Cannot find status in the AFD/GSE message"
    end

    local alarms = afd.extract_alarms()
    if not alarms then
        return -1, "Cannot find alarms in the AFD/GSE message"
    end

    local cluster_ids
    if cluster_field then
        local cluster_id = afd.get_entity_name(cluster_field)
        if not cluster_id then
            return -1, "Cannot find the cluster's name in the AFD/GSE message"
        elseif not gse.cluster_exists(cluster_id) then
            -- Just ignore AFD/GSE messages which aren't part of a cluster's definition
            return 0
        end
        cluster_ids = { cluster_id }
    else
        cluster_ids = gse.find_cluster_memberships(member_id)
    end

    -- update all clusters that depend on this entity
    for _, cluster_id in ipairs(cluster_ids) do
        gse.set_member_status(cluster_id, member_id, status, alarms, hostname)
    end
    return 0
end

function timer_event(ns)
    if not is_active then
        -- not running as the aggregator
        return
    elseif not first_tick then
        first_tick = ns
        return
    elseif ns - first_tick <= warm_up_period then
        -- not started for a long enough period
        return
    elseif last_index == nil and (ns - last_tick) < interval_in_ns then
        -- nothing to send it
        return
    end
    last_tick = ns

    local injected = 0
    for i, cluster_name in ipairs(gse.get_ordered_clusters()) do
        if last_index == nil or i > last_index then
            gse.inject_cluster_metric(
                output_message_type,
                cluster_name,
                output_metric_name,
                interval,
                source,
                activate_alerting
            )
            last_index = i
            injected = injected + 1

            if injected >= max_inject then
                return
            end
        end
    end

    last_index = nil
end
