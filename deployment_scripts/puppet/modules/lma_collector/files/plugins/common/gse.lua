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
local consts = require 'gse_constants'
local string = require 'string'
local table = require 'table'
local lma = require 'lma_utils'
local table_utils = require 'table_utils'

local pairs = pairs
local ipairs = ipairs
local assert = assert
local type = type
local inject_message = inject_message
local read_message = read_message

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local clusters = {}
local reverse_cluster_index = {}
local ordered_clusters = {}

local VALID_STATUSES = {
    [consts.OKAY]=true,
    [consts.WARN]=true,
    [consts.CRIT]=true,
    [consts.DOWN]=true,
    [consts.UNKW]=true
}

local STATUS_MAPPING_FOR_CLUSTERS = {
    [consts.OKAY]=consts.OKAY,
    [consts.WARN]=consts.WARN,
    [consts.CRIT]=consts.CRIT,
    [consts.DOWN]=consts.DOWN,
    [consts.UNKW]=consts.UNKW
}

local STATUS_WEIGHTS = {
    [consts.UNKW]=0,
    [consts.OKAY]=1,
    [consts.WARN]=2,
    [consts.CRIT]=3,
    [consts.DOWN]=4
}

function add_cluster(cluster_id, members, hints, group_by_hostname)
    assert(type(members) == 'table')
    assert(type(hints) == 'table')

    if not clusters[cluster_id] then
        clusters[cluster_id] = {}
    end
    local cluster = clusters[cluster_id]

    cluster.members = members
    cluster.hints = hints
    cluster.facts = {}
    cluster.status = consts.UNKW
    cluster.alarms={}
    if group_by_hostname then
        cluster.group_by_hostname = true
    else
        cluster.group_by_hostname = false
    end

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
    assert(VALID_STATUSES[value])
    assert(type(alarms) == 'table')

    local cluster = clusters[cluster_id]
    if not cluster then
        return
    end

    local group_key = '__all_hosts__'
    if cluster.group_by_hostname then
        group_key = hostname
    end

    if not cluster.facts[member] then
        cluster.facts[member] = {}
    end
    cluster.facts[member][group_key] = {
        status=value,
        alarms=alarms
    }
    if cluster.group_by_hostname then
        cluster.facts[member][group_key].hostname = hostname
    end
end

function max_status(current, status)
    if not status or STATUS_WEIGHTS[current] > STATUS_WEIGHTS[status] then
        return current
    else
        return status
    end
end

-- The cluster status depends on the status of its members.
-- The status of the related clusters (defined by cluster.hints) doesn't modify
-- the overall status but their alarms are returned.
function resolve_status(cluster_id)
    local cluster = clusters[cluster_id]
    assert(cluster)

    cluster.status = consts.UNKW
    local alarms = {}
    local members_with_alarms = {}

    for _, member in ipairs(cluster.members) do
        for _, fact in pairs(cluster.facts[member] or {}) do
            local status = STATUS_MAPPING_FOR_CLUSTERS[fact.status]
            if status ~= consts.OKAY then
                members_with_alarms[member] = true
                -- append alarms only if the member affects the healthiness
                -- of the cluster
                for _, v in ipairs(fact.alarms) do
                    alarms[#alarms+1] = table_utils.deepcopy(v)
                    if not alarms[#alarms]['tags'] then
                        alarms[#alarms]['tags'] = {}
                    end
                    alarms[#alarms].tags['dependency_name'] = member
                    alarms[#alarms].tags['dependency_level'] = 'direct'
                    if fact.hostname then
                        alarms[#alarms].hostname = fact.hostname
                    end
                end
            end
            cluster.status = max_status(cluster.status, status)
        end
    end
    cluster.alarms = table_utils.deepcopy(alarms)

    if cluster.status ~= consts.OKAY then
        -- add hints if the cluster isn't healthy
        for _, member in ipairs(cluster.hints or {}) do
            local other_cluster = clusters[member]
            if other_cluster and other_cluster.status ~= OKAY and #other_cluster.alarms > 0 then
                for _, v in ipairs(other_cluster.alarms) do
                    if not (v.tags and v.tags.dependency_name and members_with_alarms[v.tags.dependency_name]) then
                        -- this isn't an alarm related to a member of the cluster itself
                        alarms[#alarms+1] = table_utils.deepcopy(v)
                        if not alarms[#alarms]['tags'] then
                            alarms[#alarms]['tags'] = {}
                        end
                        alarms[#alarms].tags['dependency_name'] = member
                        alarms[#alarms].tags['dependency_level'] = 'hint'
                    end
                end
            end
        end
    end

    return cluster.status, alarms
end

-- compute the cluster metric and inject it into the Heka pipeline
-- the metric's value is computed using the status of its members
function inject_cluster_metric(msg_type, cluster_name, metric_name, hostname, interval, source)
    local payload
    local status, alarms = resolve_status(cluster_name)

    if #alarms > 0 then
        payload = cjson.encode({alarms=alarms})
    else
        -- because cjson encodes empty tables as objects instead of arrays
        payload = '{"alarms":[]}'
    end

    local msg = {
        Type = msg_type,
        Payload = payload,
        Fields = {
            name=metric_name,
            value=status,
            cluster_name=cluster_name,
            tag_fields={'cluster_name'},
            hostname=hostname,
            interval=interval,
            source=source,
        }
    }
    lma.inject_tags(msg)

    inject_message(msg)
end

return M
