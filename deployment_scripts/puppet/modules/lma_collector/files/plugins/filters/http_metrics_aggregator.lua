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
require 'math'
require 'os'
local utils = require 'lma_utils'
local tab = require 'table_utils'
local table = require 'table'

local hostname = read_config('hostname') or error('hostname must be specified')
local interval = (read_config('interval') or error('interval must be specified')) + 0
-- max_timer_inject is the maximum number of injected messages by timer_event()
local max_timer_inject = (read_config('max_timer_inject') or 10) + 0
-- bulk_size is the maximum number of metrics embedded by a bulk_metric within the Payload.
-- The bulk_size depends on the hekad max_message_size (64 KB by default).
-- At most, there are 45 metrics/service * 300B (per bucket) =~ 13KB * 4 services = 52KB for 225 metrics.
-- With a max_message_size set to 256KB, it's possible to embed more than 800 metrics.
local bulk_size = (read_config('bulk_size') or 225) + 0
local percentile_thresh = (read_config('percentile') or 90) + 0
-- grace_time is used to palliate the time precision difference
-- (in second or millisecond for logs versus nanosecond for the ticker)
-- and also to compensate the delay introduced by log parsing/decoding
-- which leads to arrive too late in its interval.
local grace_time = (read_config('grace_time') or 0) + 0

local inject_reached_error = 'too many metrics to aggregate, adjust bulk_size and/or max_timer_inject parameters'

local percentile_field_name = string.format('upper_%s', percentile_thresh)
local msg_source = 'http_metric_filter'
local last_tick = os.time() * 1e9
local interval_in_ns = interval * 1e9

local http_verbs = {
    GET = true,
    POST = true,
    OPTIONS = true,
    DELETE = true,
    PUT = true,
    HEAD = true,
    TRACE = true,
    CONNECT = true,
    PATCH = true,
}

local metric_bucket = {
    min = 0,
    max = 0,
    sum = 0,
    count = 0,
    times = {},
    [percentile_field_name] = 0,
    rate = 0,
}
local all_times = {}
local num_metrics = 0

function process_message ()
    local severity = read_message("Fields[severity_label]")
    local logger = read_message("Logger")
    local timestamp = read_message("Timestamp")
    local http_method = read_message("Fields[http_method]")
    local http_status = read_message("Fields[http_status]")
    local response_time = read_message("Fields[http_response_time]")

    if timestamp < last_tick - grace_time then
        -- drop silently old logs
        return 0
    end
    if http_method == nil or http_status == nil or response_time == nil then
        return -1
    end

    -- keep only the first 2 tokens because some services like Neutron report
    -- themselves as 'openstack.<service>.server'
    local service = string.gsub(read_message("Logger"), '(%w+)%.(%w+).*', '%1_%2')
    if service == nil then
        return -1, "Cannot match any service from " .. logger
    end

    -- coerce http_status to integer
    http_status = http_status + 0
    local http_status_family
    if http_status >= 100 and http_status < 200 then
        http_status_family = '1xx'
    elseif http_status >= 200 and http_status < 300 then
        http_status_family = '2xx'
    elseif http_status >= 300 and http_status < 400 then
        http_status_family = '3xx'
    elseif http_status >= 400 and http_status < 500 then
        http_status_family = '4xx'
    elseif http_status >= 500 and http_status < 600 then
        http_status_family = '5xx'
    else
        return -1, "Unsupported http_status " .. http_status
    end

    if not http_verbs[http_method] then
        return -1, "Unsupported http_method " .. http_method
    end

    if not all_times[service] then
        all_times[service] = {}
    end
    if not all_times[service][http_method] then
        all_times[service][http_method] = {}
    end
    if not all_times[service][http_method][http_status_family] then
        -- verify that the sandbox has enough capacity to emit all metrics
        if num_metrics > (bulk_size * max_timer_inject) then
            return -1, inject_reached_error
        end
        all_times[service][http_method][http_status_family] = tab.deepcopy(metric_bucket)
        num_metrics = num_metrics + 1
    end

    local bucket = all_times[service][http_method][http_status_family]
    bucket.times[#bucket.times + 1] = response_time
    bucket.count = bucket.count + 1
    bucket.sum = bucket.sum + response_time
    if bucket.max < response_time then
        bucket.max = response_time
    end
    if bucket.min == 0 or bucket.min > response_time then
        bucket.min = response_time
    end

    return 0
end

function timer_event(ns)

    last_tick = ns

    local num = 0
    local msg_injected = 0
    for service, methods in pairs(all_times) do
        for method, statuses in pairs(methods) do
            for status, bucket in pairs(statuses) do
                local metric_name = service .. '_http_response_times'
                bucket.rate = bucket.count / interval
                bucket[percentile_field_name] = bucket.max
                if bucket.count > 1 then
                    table.sort(bucket.times)
                    local tmp = ((100 - percentile_thresh) / 100) * bucket.count
                    local idx = bucket.count - math.floor(tmp + .5)
                    if idx > 0 and bucket.times[idx] then
                        bucket[percentile_field_name] = bucket.times[idx]
                    end
                end
                bucket.times = nil
                utils.add_to_bulk_metric(metric_name, bucket, {http_method=method, http_status=status})
                all_times[service][method][status] = nil
                num = num + 1
                num_metrics = num_metrics - 1
                if num >= bulk_size then
                    if msg_injected < max_timer_inject then
                        utils.inject_bulk_metric(ns, hostname, msg_source)
                        msg_injected = msg_injected + 1
                        num = 0
                        num_metrics = 0
                    end
                end
            end
            all_times[service][method] = nil
        end
        all_times[service] = nil
    end
    if num > 0 then
        utils.inject_bulk_metric(ns, hostname, msg_source)
        num = 0
        num_metrics = 0
    end
end
