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
local lma = require 'lma_utils'

local pairs = pairs
local ipairs = ipairs
local assert = assert
local type = type
local inject_message = inject_message
local read_message = read_message

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local facts = {}
local level_1_deps = {}
local level_2_deps = {}

local VALID_STATUSES = {
    [consts.OKAY]=true,
    [consts.WARN]=true,
    [consts.CRIT]=true,
    [consts.DOWN]=true,
    [consts.UNKW]=true
}

local STATUS_MAPPING_FOR_LEVEL_1 = {
    [consts.OKAY]=consts.OKAY,
    [consts.WARN]=consts.WARN,
    [consts.CRIT]=consts.CRIT,
    [consts.DOWN]=consts.DOWN,
    [consts.UNKW]=consts.UNKW
}

local STATUS_MAPPING_FOR_LEVEL_2 = {
    [consts.OKAY]=consts.OKAY,
    [consts.WARN]=consts.OKAY,
    [consts.CRIT]=consts.WARN,
    [consts.DOWN]=consts.CRIT,
    [consts.UNKW]=consts.OKAY
}

local STATUS_WEIGHTS = {
    [consts.UNKW]=0,
    [consts.OKAY]=1,
    [consts.WARN]=2,
    [consts.CRIT]=3,
    [consts.DOWN]=4
}

function deepcopy(t)
    if type(t) == 'table' then
        local copy = {}
        for k, v in pairs(t) do
            copy[k] = deepcopy(v)
        end
        return copy
    end
    return t
end

local function dependency(deps, superior, subordinate)
    if not deps[superior] then
        deps[superior] = {}
    end
    local subordinates = deps[superior]
    subordinates[#subordinates+1] = subordinate
end

-- define a first degree dependency between 2 entities.
function level_1_dependency(superior, subordinate)
    return dependency(level_1_deps, superior, subordinate)
end

-- define a second degree dependency between 2 entities.
function level_2_dependency(superior, subordinate)
    return dependency(level_2_deps, superior, subordinate)
end

-- store the status of a service and a list of alarms
function set_status(service, value, alarms)
    assert(VALID_STATUSES[value])
    assert(type(alarms) == 'table')
    facts[service] = {
        status=value,
        alarms=alarms
    }
end

-- return the status of a service, the alarms associated to the level-1
-- dependencies and the alarms associated to the level-2 dependencies
function resolve_status(name)
    local service_status = consts.UNKW
    local alarms = {}

    function max(other_status)
        if not other_status or STATUS_WEIGHTS[service_status] >= STATUS_WEIGHTS[other_status] then
            return service_status
        else
            return other_status
        end
    end

    for _, level_1_dep in ipairs(level_1_deps[name] or {}) do
        if facts[level_1_dep] then
            local status = STATUS_MAPPING_FOR_LEVEL_1[facts[level_1_dep].status]
            if status ~= consts.OKAY then
                for _, v in ipairs(facts[level_1_dep].alarms) do
                    alarms[#alarms+1] = deepcopy(v)
                    if not alarms[#alarms]['labels'] then
                        alarms[#alarms]['labels'] = {}
                    end
                    alarms[#alarms].labels['dependency'] = level_1_dep
                    alarms[#alarms].labels['dependency_level'] = 'direct'
                end
            end
            service_status = max(status)
        end

        for _, level_2_dep in ipairs(level_2_deps[level_1_dep] or {}) do
            if facts[level_2_dep] then
                local status = STATUS_MAPPING_FOR_LEVEL_2[facts[level_2_dep].status]
                if status ~= consts.OKAY then
                    for _, v in ipairs(facts[level_2_dep].alarms) do
                        alarms[#alarms+1] = deepcopy(v)
                        if not alarms[#alarms]['labels'] then
                            alarms[#alarms]['labels'] = {}
                        end
                        alarms[#alarms].labels['dependency'] = level_2_dep
                        alarms[#alarms].labels['dependency_level'] = 'indirect'
                    end
                end
                service_status = max(status)
            end
        end
    end

    return service_status, alarms
end

-- compute the cluster metric and inject it into the Heka pipeline
-- the metric's value is computed using the status of the subordinates
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
