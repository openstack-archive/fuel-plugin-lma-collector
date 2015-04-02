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

local timeout = read_config("timeout") or 30

services = {}
local floor = math.floor

function process_message ()
    local ts = floor(read_message("Timestamp")/1e6) -- in ms
    local service_name = string.match(read_message("Fields[name]"), '^[^._]+')
    local hostname = read_message("Fields[hostname]")
    local key = string.format('%s.%s', hostname, service_name)

    local service = services[key]
    if service then
        service.last_seen = ts
    else
        service = {last_seen = ts, status = 1, host = hostname, name = service_name}
        services[key] = service
    end
    return 0
end

function timer_event(ns)
    local current_time = floor(ns / 1e6) -- in ms
    local datapoints = {}

    for k, service in pairs(services) do
        if current_time - service.last_seen > timeout * 1000 then
            service.status = 0
        else
            service.status = 1
        end
        datapoints[#datapoints+1] = {
            name = string.format('%s.%s.status', service.host, service.name),
            columns = {"time", "value"},
            points = {{service.last_seen, service.status}}
        }
    end

    if #datapoints > 0 then
        inject_payload("json", "influxdb", cjson.encode(datapoints))
    end
end
