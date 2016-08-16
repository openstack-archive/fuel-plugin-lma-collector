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
local patterns_config = read_config('patterns') or error('patterns must be specified')
local patterns = {}
for pattern in string.gmatch(patterns_config, "/(%S+)/") do
   patterns[#patterns + 1] = pattern
end
-- Heka cannot guarantee that logs are processed in real-time so the
-- grace_interval parameter allows to take into account log messages that are
-- received in the current interval but emitted before it.
local grace_interval = (read_config('grace_interval') or 0) + 0

local msg_source = 'hdd_errors_filter'
local metric_name = "hdd_error"
local error_counters = {}
local discovered_devices = {}
local enter_at
local start_time = os.time()
local pcall = pcall

local function convert_to_sec(ns)
    return math.floor(ns/1e9)
end

function process_message ()

    -- timestamp values should be converted to seconds because log timestamps
    -- have a precision of one second (or millisecond sometimes)

    if convert_to_sec(read_message('Timestamp')) + grace_interval < math.max(convert_to_sec(enter_at or 0), start_time) then
        -- skip the log message if it doesn't fall into the current interval
        return 0
    end

    local payload = read_message('Payload')

    if payload then
        -- example of kern.log lines:
        -- <3>Jul 24 14:42:21 node-164 kernel: [505801.068621] Buffer I/O error on device sdd2, logical block 51184
        -- <4>Aug 22 09:37:09 node-164 kernel: [767975.369264] XFS (sda): xfs_log_force: error 5 returned.
        -- <1>May 17 23:07:11 sd-os1-stor05 kernel: [ 2119.105909] XFS (sdf3): metadata I/O error: block 0x68c2b7d8 ("xfs_trans_read_buf_map") error 121 numblks 8

        local device = nil
        for _, pattern in ipairs(patterns) do
            local ok, dev = pcall(string.match, payload, pattern)
            if not ok then
                return -1, dev -- dev contains error message
            end
            device = device or dev
            if device then
                break
            end
        end
        if device then
            if not error_counters[device] then
                -- a new device has been discovered
                discovered_devices[#discovered_devices + 1] = device
                error_counters[device] = 0
            end
            error_counters[device] = error_counters[device] + 1
        end
    end
    return 0
end


function timer_event(ns)

    enter_at = ns

    if #discovered_devices == 0 then
        return 0
    end

    for dev, value in pairs(error_counters) do
        utils.add_to_bulk_metric(metric_name, value, {device=dev, level="error"})
        error_counters[dev] = 0
    end

    utils.inject_bulk_metric(ns, hostname, msg_source)

    return 0
end