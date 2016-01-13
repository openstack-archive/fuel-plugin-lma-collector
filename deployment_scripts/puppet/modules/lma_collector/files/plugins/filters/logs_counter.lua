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

local logs_counters = {}
local msg = {
    Type = "metric",
    Timestamp = nil,
    Severity = 6,
    Fields = {
        type = utils.metric_type['COUNTER'],
    }
}

function process_message ()
    local severity = read_message("Severity")
    local logger = read_message("Logger")

    local service = string.match(logger, "openstack.(%a+)")

    if not logs_counters[service] then
        logs_counters[service] = {}
    end
    if not logs_counters[service][severity] then
        logs_counters[service][severity] = 1
    else
        logs_counters[service][severity] = logs_counters[service][severity] + 1
    end

    return 0
end

function timer_event(ns)


    for service, tab in pairs(logs_counters) do
        for level, val in pairs(tab) do

            msg.Fields = {
                name = 'logs_counters',
                value = val,
                service = service,
                level = string.lower(utils.severity_to_label_map[level]),
                tag_fields = {'service', 'level'},
            }

            utils.inject_tags(msg)
            ok, err = utils.safe_inject_message(msg)

            if ok ~= 0 then
              return -1, err
            end
        end
    end

    return 0
end
