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

require 'math'
require 'os'
require 'string'
local utils = require 'lma_utils'

local hostname = read_config('hostname') or error('hostname must be specified')
-- The filter can receive messages that should be discarded because they are
-- way too old (Heka cannot guarantee that logs are processed in real-time).
-- The 'grace_interval' parameter allows to define which log messages should be
-- kept and which should be discarded. For instance, a value of '10' means that
-- the filter will take into account log messages that are at most 10 seconds
-- older than the current time.
local grace_interval = (read_config('grace_interval') or 0) + 0
local logger_matcher = read_config('logger_matcher') or '.*'
local metric_logger = read_config('logger')
local metric_source = read_config('source')

local discovered_services = {}
local logs_counters = {}
local last_timer_event = os.time() * 1e9

function process_message ()
    local severity = read_message("Fields[severity_label]")
    local logger = read_message("Logger")

    local service = string.match(logger, logger_matcher)
    if service == nil then
        return -1, "Cannot match any service from " .. logger
    end

    -- timestamp values should be converted to seconds because log timestamps
    -- have a precision of one second (or millisecond sometimes)
    if utils.convert_to_sec(read_message('Timestamp')) + grace_interval < utils.convert_to_sec(last_timer_event) then
        -- skip the the log message if it doesn't fall into the current interval
        return 0
    end

    if not logs_counters[service] then
        -- a new service has been discovered
        discovered_services[#discovered_services + 1] = service
        logs_counters[service] = {}
        for _, label in pairs(utils.severity_to_label_map) do
            logs_counters[service][label] = 0
        end
    end

    logs_counters[service][severity] = logs_counters[service][severity] + 1
    return 0
end

function timer_event(ns)
    for service, counters in pairs(logs_counters) do
        local delta_sec = (ns - last_timer_event) / 1e9

        for level, val in pairs(counters) do
            utils.add_to_bulk_metric(
                'log_messages',
                val / delta_sec,
                {hostname=hostname, service=service, level=string.lower(level)})

            -- reset the counter
            counters[level] = 0
        end
    end

    last_timer_event = ns

    ok, err = utils.inject_bulk_metric(ns, hostname, metric_logger, metric_source, utils.metric_type['DERIVE'])
    if ok ~= 0 then
        return -1, err
    end

    return 0
end
