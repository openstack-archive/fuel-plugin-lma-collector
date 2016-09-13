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
local consts = require 'gse_constants'
local string = require 'string'
local table = require 'table'
local GseCluster = require 'gse_cluster'
local lma = require 'lma_utils'
local table_utils = require 'table_utils'

local pairs = pairs
local ipairs = ipairs
local assert = assert
local type = type
local read_message = read_message

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

-- Hash of GseCluster instances organized by name
local clusters = {}
-- Reverse index table to map cluster's members to clusters
local reverse_cluster_index = {}
-- Array of cluster names ordered by dependency
local ordered_clusters = {}

function add_cluster(cluster_id, members, hints, group_by, policy_rules)
    assert(type(members) == 'table')
    assert(type(hints) == 'table')
    assert(type(policy_rules) == 'table')

    local cluster = GseCluster.new(members, hints, group_by, policy_rules)
    clusters[cluster_id] = cluster

    -- update the reverse index
    for _, member in ipairs(members) do
        if not reverse_cluster_index[member] then
            reverse_cluster_index[member] = {}
        end
        local reverse_table = reverse_cluster_index[member]
        if not table_utils.item_find(cluster_id, reverse_table) then
            reverse_table[#reverse_table+1] = cluster_id
        end
    end

    if not table_utils.item_find(cluster_id, ordered_clusters) then
        local after_index = 1
        for current_pos, id in ipairs(ordered_clusters) do
            if table_utils.item_find(id, cluster.hints) then
                after_index = current_pos + 1
            end
        end

        local index = after_index
        for _, item in pairs(clusters) do
            for _, hint in pairs(item.hints) do
                if hint == cluster_id then
                    local pos = table_utils.item_pos(hint, cluster_orderings)
                    if pos and pos <= index then
                        index = pos
                    elseif index > after_index then
                        error('circular dependency between clusters!')
                    end
                end
            end
        end
        table.insert(ordered_clusters, index, cluster_id)
    end
end

function get_ordered_clusters()
    return ordered_clusters
end

function cluster_exists(cluster_id)
    return clusters[cluster_id] ~= nil
end

-- return the list of clusters which depends on a given member
function find_cluster_memberships(member_id)
    return reverse_cluster_index[member_id] or {}
end

-- store the status of a cluster's member and its current alarms
function set_member_status(cluster_id, member, value, alarms, hostname)
    local cluster = clusters[cluster_id]
    if cluster then
        cluster:update_fact(member, hostname, value, alarms)
    end
end

-- The cluster status depends on the status of its members.
-- The status of the related clusters (defined by cluster.hints) doesn't modify
-- the overall status but their alarms are returned.
function resolve_status(cluster_id)
    local cluster = clusters[cluster_id]
    assert(cluster)

    cluster:refresh_status()
    local alarms = table_utils.deepcopy(cluster.alarms)

    if cluster.status ~= consts.OKAY then
        -- add hints if the cluster isn't healthy
        for _, other_id in ipairs(cluster.hints or {}) do
            for _, v in pairs(cluster:subtract_alarms(clusters[other_id])) do
                alarms[#alarms+1] = table_utils.deepcopy(v)
                alarms[#alarms].tags['dependency_name'] = other_id
                alarms[#alarms].tags['dependency_level'] = 'hint'
            end
        end
    end

    return cluster.status, alarms
end

-- compute the cluster metric and inject it into the Heka pipeline
-- the metric's value is computed using the status of its members
function inject_cluster_metric(msg_type, cluster_name, metric_name, interval, source, to_alerting)
    local payload
    local status, alarms = resolve_status(cluster_name)

    if #alarms > 0 then
        payload = lma.safe_json_encode({alarms=alarms})
        if not payload then
            return
        end
    else
        -- because cjson encodes empty tables as objects instead of arrays
        payload = '{"alarms":[]}'
    end

    local no_alerting
    if to_alerting ~= nil and to_alerting == false then
        no_alerting = true
    end

    local msg = {
        Type = msg_type,
        Payload = payload,
        Fields = {
            name=metric_name,
            value=status,
            cluster_name=cluster_name,
            tag_fields={'cluster_name'},
            interval=interval,
            source=source,
            no_alerting=no_alerting,
        }
    }
    lma.inject_tags(msg)
    lma.safe_inject_message(msg)
end

return M
