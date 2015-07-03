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

function extract_data_from_json(table)
    -- We extract:
    --   - the name of the metric
    --   - the number of processed messages
    --   - the average duration for processing a message (nanoseconds)
    msgCount = table['ProcessMessageCount']
    avgDuration = table['ProcessMessageAvgDuration']

    return table['Name'], msgCount['value'], avgDuration['value']
end

function process_table(datapoints, timestamp, hostname, kind, array)
    -- NOTE: It has been written for "filters" and "decoders". If we need
    -- to use it to process other part of the Heka pipeline we need to ensure
    -- that JSON provides names and table with ProcessMessageCount and
    -- ProcessMessageAvgDuration:
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
    for _, v in pairs(array) do
        if type(v) == "table" then
            name, msgCount, avgDuration = extract_data_from_json(v)
            -- sanitize the name
            name = name:gsub("_filter", "")
            name = name:gsub("_decoder", "")
            utils.add_metric(datapoints,
                             string.format('%s.lma_components.hekad.%s.%s.count', hostname, kind, name),
                             {timestamp, msgCount})
            utils.add_metric(datapoints,
                             string.format('%s.lma_components.hekad.%s.%s.duration', hostname, kind, name),
                             {timestamp, avgDuration})
        end
    end
end

function process_message ()
    local ok, json = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        return -1
    end

    local hostname = read_message("Hostname")
    local ts = read_message("Timestamp")
    local ts_ms = math.floor(ts/1e6)
    local datapoints = {}

    for k, v in pairs(json) do
        if k == "filters" or k == "decoders" then
            process_table(datapoints, ts_ms, hostname, k, v)
        end
    end

    if #datapoints > 0 then
        inject_payload("json", "influxdb", cjson.encode(datapoints))
        return 0
    end

    -- We should not reach this point
    return -1

end
