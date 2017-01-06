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
require 'cjson'
require 'string'
require 'math'
local utils  = require 'lma_utils'

function process_table(typ, array)
    -- NOTE: It has been written for "filters" and "decoders". If we need to
    -- use it to collect metrics from other components  of the Heka pipeline,
    -- we need to ensure that JSON provides names and table with
    -- ProcessMessageCount and ProcessMessageAvgDuration:
    --
    --    "decoder": {
    --        ...
    --        },
    --        "Name": "a name",
    --        "ProcessMessageCount" : {
    --            "representation": "count",
    --            "value": 12
    --        },
    --        "ProcessMessageAvgDuration" : {
    --            "representation": "ns",
    --            "value": 192913
    --        },
    --        { ... }}
    --
    for _, v in pairs(array) do
        if type(v) == "table" then
            -- strip off the '_decoder'/'_filter' suffix
            local name = v['Name']:gsub("_" .. typ, "")

            local tags = {
                ['type'] = typ,
                ['name'] = name,
            }

            utils.add_to_bulk_metric('hekad_msg_count', v.ProcessMessageCount.value, tags)
            utils.add_to_bulk_metric('hekad_msg_avg_duration', v.ProcessMessageAvgDuration.value, tags)
            if v.Memory then
                utils.add_to_bulk_metric('hekad_memory', v.Memory.value, tags)
             end
            if v.TimerEventAvgDuration then
                utils.add_to_bulk_metric('hekad_timer_event_avg_duration', v.TimerEventAvgDuration.value, tags)
            end
            if v.TimerEventSamples then
                utils.add_to_bulk_metric('hekad_timer_event_count', v.TimerEventSamples.value, tags)
            end
        end
    end
end

function singularize(str)
    return str:gsub('s$', '')
end

function process_message ()
    local ok, data = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        return -1
    end

    local hostname = read_message("Hostname")
    local ts = read_message("Timestamp")

    for k, v in pairs(data) do
        if k == "filters" or k == "decoders" then
            process_table(singularize(k), v)
        end
    end

    utils.inject_bulk_metric(ts, hostname, 'heka_monitoring', 'internal')
    return 0
end
