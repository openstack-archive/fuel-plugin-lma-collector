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

local output_message_type = read_config('output_message_type') or error('output_message_type must be specified!')
local entity_field = read_config('entity_field') or error('entity_field must be specified!')
local output_metric_name = read_config('output_metric_name') or error('output_metric_name must be specified!')
local hostname = read_config('hostname') or error('hostname must be specified!')
local source = read_config('source') or error('source must be specified!')
local topology_file = read_config('topology_file') or error('topology_file must be specified!')
local interval = (read_config('interval') or error('interval must be specified!')) + 0
local interval_in_ns = interval * 1e9

local last_tick = 0
local entities = {}
local topology = require(topology_file)

for parent, children in pairs(topology.level_1_dependencies) do
    entities[#entities+1] = parent
    for _, v in ipairs(children) do
        gse.level_1_dependency(parent, v)
    end
end
for parent, children in pairs(topology.level_2_dependencies) do
    for _, v in ipairs(children) do
        gse.level_2_dependency(parent, v)
    end
end

function process_message()
    local name = afd.get_entity_name(entity_field)
    local status = afd.get_status()
    local alarms = afd.extract_alarms()
    if not name then
        return -1, "Cannot find entity's name in the AFD event message"
    end
    if not status then
        return -1, "Cannot find status in the AFD event message"
    end
    if not name then
        return -1, "Cannot find alarms in the AFD event message"
    end

    gse.set_status(name, status, alarms)
    return 0
end

function timer_event(ns)
    if (ns - last_tick) < interval_in_ns then
        return
    end
    last_tick = ns

    for _, cluster_name in ipairs(entities) do
        gse.inject_cluster_metric(
            output_message_type,
            cluster_name,
            output_metric_name,
            hostname,
            interval,
            source
        )
    end
end
