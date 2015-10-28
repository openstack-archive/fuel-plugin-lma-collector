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
local gse_utils = require 'gse_utils'
local table_utils = require 'table_utils'

local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local assert = assert
local type = type

local GseCluster = {}
GseCluster.__index = GseCluster

setfenv(1, GseCluster) -- Remove external access to contain everything in the module

local VALID_STATUSES = {
    [consts.OKAY]=true,
    [consts.WARN]=true,
    [consts.CRIT]=true,
    [consts.DOWN]=true,
    [consts.UNKW]=true
}

function GseCluster.new(members, hints, group_by, policy_rules)
    assert(type(members) == 'table')
    assert(type(hints) == 'table')
    assert(type(policy_rules) == 'table')

    local cluster = {}
    setmetatable(cluster, GseCluster)

    cluster.members = members
    cluster.hints = hints
    cluster.policy_rules = policy_rules
    -- when group_by is 'hostname', facts are stored by hostname then member
    -- when group_by is 'member', facts are stored by member only
    -- otherwise facts are stored by member then hostname
    if group_by == 'hostname' or group_by == 'member' then
        cluster.group_by = group_by
    else
        cluster.group_by = 'none'
    end
    cluster.status = consts.UNKW
    cluster.facts = {}
    cluster.alarms = {}
    cluster.member_index = {}
    for _, v in ipairs(members) do
        cluster.member_index[v] = true
    end

    return cluster
end

function GseCluster:has_member(member)
    return self.member_index[member]
end

-- Update the facts table for a cluster's member
function GseCluster:update_fact(member, hostname, value, alarms)
    assert(VALID_STATUSES[value])
    assert(type(alarms) == 'table')

    local key1, key2 = member, hostname
    if self.group_by == 'hostname' then
        key1 = hostname
        key2 = member
    elseif self.group_by == 'member' then
        key2 = '__anyhost__'
    end

    if not self.facts[key1] then
        self.facts[key1] = {}
    end
    self.facts[key1][key2] = {
        status=value,
        alarms=table_utils.deepcopy(alarms),
        member=member
    }
    if self.group_by == 'hostname' then
        -- store the hostname for later reference in the alarms
        self.facts[key1][key2].hostname = hostname
    end
end

-- Compute the status and alarms of the cluster according to the current facts
-- and the cluster's policy
function GseCluster:refresh_status()
    local alarms = {}
    local status_breakdown = {}

    self.status = consts.UNKW
    self.alarms = {}

    for group_key, _ in table_utils.orderedPairs(self.facts) do
        local group_status = consts.UNKW
        for sub_key, fact in table_utils.orderedPairs(self.facts[group_key]) do
            group_status = gse_utils.max_status(group_status, fact.status)
            if fact.status ~= consts.OKAY then
                for _, v in ipairs(fact.alarms) do
                    alarms[#alarms+1] = table_utils.deepcopy(v)
                    if not alarms[#alarms]['tags'] then
                        alarms[#alarms]['tags'] = {}
                    end
                    alarms[#alarms].tags['dependency_name'] = fact.member
                    alarms[#alarms].tags['dependency_level'] = 'direct'
                    if fact.hostname then
                        alarms[#alarms].hostname = fact.hostname
                    end
                end
            end
        end
        status_breakdown[group_status] = (status_breakdown[group_status] or 0) + 1
    end
    for _, policy_rule in ipairs(self.policy_rules) do
        if policy_rule:evaluate(status_breakdown) then
            self.status = policy_rule.status
            break
        end
    end
    if self.status ~= consts.OKAY then
        self.alarms = alarms
    end

    return self.status
end

-- Return the alarms from another cluster which aren't already known by this
-- cluster
function GseCluster:subtract_alarms(cluster)
    local subset = {}
    if cluster then
        for _, alarm in ipairs(cluster.alarms) do
            if alarm.tags and alarm.tags['dependency_name'] and not self:has_member(alarm.tags['dependency_name']) then
                subset[#subset+1] = alarm
            end
        end
    end
    return subset
end

return GseCluster
