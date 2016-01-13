-- Copyright 2016 Mirantis, Inc.
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

require 'string'
local utils = require 'lma_utils'

local logs_counters = {}
local service_to_index = {}
local index_to_service = {}
local service_count = 0
local current_service = 0
local msg = {
    Type = "metric",
    Timestamp = nil,
    Severity = 6,
    Fields = {
        type = utils.metric_type['COUNTER'],
    }
}

function process_message ()
    local severity = read_message("Severity")
    local logger = read_message("Logger")

    local service = string.match(logger, "^openstack.(%a+)$")
    if service == nil then
        return -1, "Cannot match any services from logger"
    end

    if not service_to_index[service] then
        -- a new service has been discovered
        service_to_index[service] = service_count
        index_to_service[service_count] = service
        logs_counters[service_count] = {}
        for _,label in pairs(utils.severity_to_label_map) do
            logs_counters[service_count][label] = 0
        end

        service_count = service_count + 1
    end

    severity = utils.severity_to_label_map[severity]
    logs_counters[service_to_index[service]][severity] = logs_counters[service_to_index[service]][severity] + 1

    return 0
end

function timer_event(ns)

    -- We can only send a maximum of ten events per call.
    -- So we send all metrics about one service and we will proceed with
    -- others services in the next run.

    if service_count == 0 then
        return 0
    end

    for level, val in pairs(logs_counters[current_service]) do

       msg.Fields = {
           name = 'log_messages',
           value = val,
           service = index_to_service[current_service],
           level = string.lower(level),
           tag_fields = {'service', 'level'},
       }

       utils.inject_tags(msg)
       ok, err = utils.safe_inject_message(msg)
       if ok ~= 0 then
         return -1, err
       end

       -- reset the counter
       logs_counters[current_service][level] = 0

    end

    current_service = (current_service + 1) % service_count

    return 0
end
