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
local interval = (read_config('interval') or error('interval must be specified')) + 0
local patterns = read_config('patterns') or error('patterns must be specified')
-- Heka cannot guarantee that logs are processed in real-time so the
-- grace_interval parameter allows to take into account log messages that are
-- received in the current interval but emitted before it.
local grace_interval = (read_config('grace_interval') or 0) + 0

local msg_source = 'hdd_errors_filter'
local injected = false
local metric_name = "hdd_error"
local error_counters = {}
local discovered_devices = {}
local enter_at
local interval_in_ns = interval * 1e9
local start_time = os.time()


function convert_to_sec(ns)
    return math.floor(ns/1e9)
end

function process_message ()

    -- timestamp values should be converted to seconds because log timestamps
    -- have a precision of one second (or millisecond sometimes)

    local payload = read_message('Payload')
    if payload then
        local dev = nil
        for pattern in string.gmatch(patterns, "/(%S+)/") do
            dev = dev or string.match(payload, pattern)
        end
        if dev then
            if convert_to_sec(read_message('Timestamp')) + grace_interval < math.max(convert_to_sec(enter_at or 0), start_time) then
                -- skip the log message if it doesn't fall into the current interval
                return 0
            end
            if not error_counters[dev] then
                -- a new device has been discovered
                discovered_devices[#discovered_devices + 1] = dev
                error_counters[dev] = 0
            end
            error_counters[dev] = error_counters[dev] + 1
        end
    end
    return 0
end


function timer_event(ns)

    if #discovered_devices == 0 then
        return 0
    end

    -- Initialize enter_at during the first call to timer_event
    if not enter_at then
        enter_at = ns
    end

    -- To be able to send a metric we need to check if we are within the
    -- interval specified in the configuration and if we haven't already
    -- injected all metrics.

    if ns - enter_at < interval_in_ns and not injected then
        for dev, value in pairs(error_counters) do
            utils.add_to_bulk_metric(metric_name, value, {device=dev, level="error"})
            error_counters[dev] = nil
        end

        utils.inject_bulk_metric(ns, hostname, msg_source)
        injected = true
    end

    if ns - enter_at >= interval_in_ns then
        enter_at = ns
        injected = false
    end

    return 0
end