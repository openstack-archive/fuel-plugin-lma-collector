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

local lma = require 'lma_utils'

local inject_message = inject_message

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local alarms = {}

-- append an alarm to the list of pending alarms
-- the list is reste when inject_afd_service_event is called
function add_to_alarms(severity, fn, metric, operator, threshold, window, periods, message)
    alarms[#alarms+1] = {
        severity=severity,
        ['function']=fn,
        metric=metric,
        operator=operator,
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
function inject_afd_service_event(service, value, interval, source)
    local payload

    if #alarms > 0 then
        payload = cjson.encode({alarms=alarms})
    else
        -- because cjson encodes empty tables as objects instead of arrays
        payload = '{"alarms":[]}'
    end
    reset_alarms()

    local msg = {
        Type = 'afd_service_metric',
        Payload = payload,
        Fields = {
            service=service,
            name='service_status',
            value=value,
            interval=interval,
            source=source,
            tags_fields={'service'}
        }
    }
    lma.inject_tags(msg)

    inject_message(msg)
end

return M
