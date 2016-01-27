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

local hostname = read_config('hostname') or error('hostname must be specified')
local interval = (read_config('interval') or error('interval must be specified!')) + 0

local discovered_services = {}
local logs_counters = {}
local current_service = 1
local enter_at
local interval_in_ns = interval * 1e9
local msg = {
    Type = "metric",
    Timestamp = nil,
    Severity = 6,
}

function process_message ()
    local severity = read_message("Fields[severity_label]")
    local logger = read_message("Logger")

    local service = string.match(logger, "^openstack%.(%a+)$")
    if service == nil then
        return -1, "Cannot match any services from " .. logger
    end

    if not logs_counters[service] then
        -- a new service has been discovered
        discovered_services[#discovered_services + 1] = service
        logs_counters[service] = {}
        logs_counters[service]['last_timer_event'] = 0
        for _, label in pairs(utils.severity_to_label_map) do
            logs_counters[service][label] = 0
        end
    end

    logs_counters[service][severity] = logs_counters[service][severity] + 1

    return 0
end

function timer_event(ns)

    -- We can only send a maximum of ten events per call.
    -- So we send all metrics about one service and we will proceed with
    -- the following services at the next ticker event.

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
        local service_name = discovered_services[current_service]
        local last_timer_event = logs_counters[service_name]['last_timer_event']
        local delta_sec = (ns - last_timer_event) / 1e9

        for level, val in pairs(logs_counters[service_name]) do

           -- We don't send the first value
           if last_timer_event ~= 0 and delta_sec ~= 0 then
               msg.Timestamp = ns
               msg.Fields = {
                   name = 'log_messages',
                   type = utils.metric_type['DERIVE'],
                   value = val / delta_sec,
                   service = service_name,
                   level = string.lower(level),
                   hostname = hostname,
                   tag_fields = {'service', 'level'},
               }

               utils.inject_tags(msg)
               ok, err = utils.safe_inject_message(msg)
               if ok ~= 0 then
                 return -1, err
               end
           end

           -- reset the counter
           logs_counters[service_name][level] = 0

        end

        logs_counters[service_name]['last_timer_event'] = ns
        current_service = current_service + 1
    end

    if ns - enter_at >= interval_in_ns then
        enter_at = ns
        current_service = 1
    end

    return 0
end
