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
require 'string'
local utils = require 'lma_utils'

local timeout = (read_config("timeout") or 30) * 1e9 -- in ns
local hostname

services = {}

function process_message ()
    local ts = read_message('Timestamp')
    local service = string.match(read_message("Fields[name]"), '^[^_]+')
    if not hostname then
        hostname = read_message("Fields[hostname]")
    end

    local entry = services[service]
    if entry then
        entry.last_seen = ts
    else
        services[service] = {last_seen = ts}
    end

    return 0
end

function timer_event(ns)
    for service, data in pairs(services) do
        local status = 1
        if ns - data.last_seen > timeout then
            status = 0
        end
        utils.add_to_bulk_metric(service .. '_status', status)
    end

    utils.inject_bulk_metric(ns, hostname, 'service_heartbeat')
end
