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

local discovered_services = {}
local logs_counters = {}
local current_service = 1
local enter_at
local interval = (read_config('interval') or error('interval must be specified!')) + 0
local interval_in_ns = interval * 1e9
local msg = {
    Type = "metric",
    Timestamp = nil,
    Severity = 6,
}

function process_message ()
    local severity = read_message("Severity")
    local logger = read_message("Logger")

    local service = string.match(logger, "^openstack.(%a+)$")
    if service == nil then
        return -1, "Cannot match any services from logger"
    end

    if not logs_counters[service] then
        -- a new service has been discovered
        discovered_services[#discovered_services + 1] = service
        logs_counters[service] = {}
        for _,label in pairs(utils.severity_to_label_map) do
            logs_counters[service][label] = 0
        end
    end

    severity = utils.severity_to_label_map[severity]
    logs_counters[service][severity] = logs_counters[service][severity] + 1

    return 0
end

function timer_event(ns)

    -- We can only send a maximum of ten events per call.
    -- So we send all metrics about one service and we will proceed with
    -- others services in the next run.

    if #discovered_services == 0 then
        return 0
    end

    -- Initialize enter_at during the first call to timer_event
    if not enter_at then
        enter_at = ns
    end

    -- To be able to send a metric we need to check if we are within the
    -- interval specified in the configuration and if we haven't already sent
    -- all metrics.
    if ns - enter_at < interval_in_ns and current_service <= #discovered_services then
        service_name = discovered_services[current_service]
        for level, val in pairs(logs_counters[service_name]) do

           msg.Fields = {
               name = 'log_messages',
               type = utils.metric_type['COUNTER'],
               value = val,
               service = service_name,
               level = string.lower(level),
               tag_fields = {'service', 'level'},
           }

           utils.inject_tags(msg)
           ok, err = utils.safe_inject_message(msg)
           if ok ~= 0 then
             return -1, err
           end

           -- reset the counter
           logs_counters[service_name][level] = 0

        end
        current_service = current_service + 1
    end

    if ns - enter_at >= interval_in_ns then
        enter_at = ns
        current_service = 1
    end

    return 0
end
