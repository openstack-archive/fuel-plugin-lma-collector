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
local string = require 'string'

local lma = require 'lma_utils'
local consts = require 'gse_constants'

local inject_message = inject_message
local read_message = read_message
local assert = assert
local ipairs = ipairs
local pcall = pcall
local table = table

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

function get_entity_name(field)
    return read_message(string.format('Fields[%s]', field))
end

function get_status()
    return read_message('Fields[value]')
end

function extract_alarms()
    local ok, payload = pcall(cjson.decode, read_message('Payload'))
    if not ok or not payload.alarms then
        return nil
    end
    return payload.alarms
end

-- return a list of alarm objects as a list of human-readable messages
-- for instance: "CPU load too high (WARNING, rule='last(load_midterm)>=5', current=7)"
function alarms_for_human(alarms)
    local alarm_messages = {}
    for _, v in ipairs(alarms) do
        local metric
        if #(v.fields) > 0 then
            local fields = {}
            for _, field in ipairs(v.fields) do
                fields[#fields+1] = field.name .. '="' .. field.value .. '"'
            end
            metric = string.format('%s[%s]', v.metric, table.concat(fields, ','))
        else
            metric = v.metric
        end
        alarm_messages[#alarm_messages+1] = string.format(
            "%s (%s, rule='%s(%s)%s%s', current=%s)",
            v.message,
            v.severity,
            v['function'],
            metric,
            v.operator,
            v.threshold,
            v.value
        )
    end
    return alarm_messages
end

local alarms = {}

-- append an alarm to the list of pending alarms
-- the list is sent when inject_afd_service_metric is called
function add_to_alarms(status, fn, metric, fields, tags, operator, value, threshold, window, periods, message)
    local severity = consts.status_label(status)
    assert(severity)
    alarms[#alarms+1] = {
        severity=severity,
        ['function']=fn,
        metric=metric,
        fields=fields or {},
        tags=tags or {},
        operator=operator,
        value=value,
        threshold=threshold,
        window=window or 0,
        periods=periods or 0,
        message=message
    }
end

function get_alarms()
    return alarms
end

function reset_alarms()
    alarms = {}
end

-- inject an AFD service event into the Heka pipeline
function inject_afd_service_metric(service, value, hostname, interval, source)
    local payload

    if #alarms > 0 then
        payload = cjson.encode({alarms=alarms})
        reset_alarms()
    else
        -- because cjson encodes empty tables as objects instead of arrays
        payload = '{"alarms":[]}'
    end

    local msg = {
        Type = 'afd_service_metric',
        Payload = payload,
        Fields = {
            service=service,
            name='service_status',
            value=value,
            hostname=hostname,
            interval=interval,
            source=source,
            tag_fields={'service'}
        }
    }
    lma.inject_tags(msg)

    inject_message(msg)
end

MATCH = true
NOMATCH = false
NODATAPOINT = 1
MISSINGDATAPOINT = 2

return M
