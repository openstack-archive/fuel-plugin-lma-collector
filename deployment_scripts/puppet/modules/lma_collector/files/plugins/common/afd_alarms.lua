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

local pairs = pairs
local ipairs = ipairs
local lma = require 'lma_utils'
local table_utils = require 'table_utils'
local consts = require 'gse_constants'
local gse_utils = require 'gse_utils'
local Alarm = require 'afd_alarm'

local all_alarms = {}

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

-- return a list of field names required for the metric
function get_metric_fields(metric_name)
    local fields = {}
    for name, alarm in pairs(all_alarms) do
        local mf = alarm:get_metric_fields(metric_name)
        if mf then
            for _, field in pairs(mf) do
                if not table_utils.item_find(field, fields) then
                    fields[#fields+1] = field
                end
            end
        end
    end
    return fields
end

-- return list of alarms interested by a metric
function get_interested_alarms(metric)
    local interested_alarms = {}
    for _, alarm in pairs(all_alarms) do
        if alarm:has_metric(metric) then

            interested_alarms[#interested_alarms+1] = alarm
        end
    end
    return interested_alarms
end

function add_value(ts, metric, value, fields)
    local interested_alarms = get_interested_alarms(metric)
    for _, alarm in ipairs (interested_alarms) do
        alarm:add_value(ts, metric, value, fields)
    end
end

function reset_alarms()
    all_alarms = {}
end

function evaluate(ns)
    local global_state
    local all_alerts = {}
    for _, alarm in pairs(all_alarms) do
        if alarm:is_evaluation_time(ns) then
            local state, alerts = alarm:evaluate(ns)
            global_state = gse_utils.max_status(state, global_state)
            for _, a in ipairs(alerts) do
                all_alerts[#all_alerts+1] = { state=state, alert=a }
            end
            -- raise the first triggered alarm except for OKAY/UNKW states
            if global_state ~= consts.UNKW and global_state ~= consts.OKAY then
                break
            end
        end
    end
    return global_state, all_alerts
end

function get_alarms()
    return all_alarms
end
function get_alarm(alarm_name)
    for _, a in ipairs(all_alarms) do
        if a.name == alarm_name then
            return a
        end
    end
end

function load_alarm(alarm)
    local A = Alarm.new(alarm)
    all_alarms[#all_alarms+1] = A
end

function load_alarms(alarms)
    for _, alarm in ipairs(alarms) do
        load_alarm(alarm)
    end
end

local started = false
function set_start_time(ns)
    for _, alarm in ipairs(all_alarms) do
        alarm:set_start_time(ns)
    end
    started = true
end

function is_started()
    return started
end

return M
