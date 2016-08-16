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
-- Heka cannot guarantee that logs are processed in real-time so the
-- grace_interval parameter allows to take into account log messages that are
-- received in the current interval but emitted before it.
local grace_interval = (read_config('grace_interval') or 0) + 0

local error_counters = {}
local discovered_devices = {}
local last_timer_events = {}
local current_device = 1
local enter_at
local interval_in_ns = interval * 1e9
local start_time = os.time()
local msg = {
    Type = "metric",
    Timestamp = nil,
    Severity = 6,
}

local err_pattern_1 = "error.+([sv]d[a-z][a-z]?%d?)"
local err_pattern_2 = "([sv]d[a-z][a-z]?%d?).+error"

function convert_to_sec(ns)
    return math.floor(ns/1e9)
end

function process_message ()

    -- timestamp values should be converted to seconds because log timestamps
    -- have a precision of one second (or millisecond sometimes)

    local payload = read_message('Payload')
    if payload then
        local dev = string.match(payload, err_pattern_1)
        dev = dev or string.match(payload, err_pattern_2)
        if dev then
            if convert_to_sec(read_message('Timestamp')) + grace_interval < math.max(convert_to_sec(last_timer_events[dev] or 0), start_time) then
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


-- [Question]
-- What type of metric message evaluation is better:
-- message for one device per timer_event or
-- messages for all devices per timer_event?

function timer_event(ns)

    -- We can only send a maximum of ten events per call.
    -- So we send all metrics about one service and we will proceed with
    -- the following services at the next ticker event.

    if #discovered_devices == 0 then
        return 0
    end

    -- Initialize enter_at during the first call to timer_event
    if not enter_at then
        enter_at = ns
    end

    -- To be able to send a metric we need to check if we are within the
    -- interval specified in the configuration and if we haven't already sent
    -- all metrics.

    if ns - enter_at < interval_in_ns and current_device <= #discovered_devices then

        local device_name = discovered_devices[current_device]
        local val = error_counters[device_name]

        msg.Timestamp = ns
        msg.Fields = {
            name = 'hdd_error',
            type = utils.metric_type['COUNTER'],
            -- [Question] What should be value for this metric:
            -- count of errors per interval or count of errors per second?
            value = val,
            device = device_name,
            level = "error",
            hostname = hostname,
            tag_fields = {'hostname', 'device', 'level'},
        }

        utils.inject_tags(msg)
        ok, err = utils.safe_inject_message(msg)
        if ok ~= 0 then
          return -1, err
        end

        -- reset the counter
        error_counters[device_name] = 0
        last_timer_events[device_name] = ns
        current_device = current_device + 1
    end

    if ns - enter_at >= interval_in_ns then
        enter_at = ns
        current_device = 1
    end

    return 0
end