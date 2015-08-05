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

-- The filter accumulates data into a table and emits regularly a message per
-- service with a payload like this:
-- {
-- "vip_active_at": 1435829917607,
-- "name": "nova",
-- "states": {
--     "check_api":{
--         "nova":{
--             "down":{
--                 "value":0,
--                 "group_name":"endpoint",
--                 "last_seen":1433252000524
--             },
--             "up":{
--                 "value":1,
--                 "group_name":"endpoint",
--                 "last_seen":1433252000524
--             }
--         },
--         ...
--     },
--     "workers":{
--         "scheduler":{
--             "down":{
--                 "value":0,
--                 "group_name":"services",
--                 "last_seen":1433251999229
--             },
--             "disabled":{
--                 "value":1,
--                 "group_name":"services",
--                 "last_seen":1433251999226
--             },
--             "up":{
--                 "value":2,
--                 "group_name":"services",
--                 "last_seen":1433251999227
--             }
--         },
--         ...
--     },
--     "haproxy":{
--         "nova-api":{
--             "down":{
--                 "value":0,
--                 "group_name":"pool",
--                 "last_seen":1433252000957
--             },
--             "up":{
--                 "value":3,
--                 "group_name":"pool",
--                 "last_seen":1433252000954
--             }
--         }
--     }
--         ...
-- }
-- }

require 'cjson'
require 'string'
require 'math'
local floor = math.floor
local utils  = require 'lma_utils'

_PRESERVATION_VERSION = 1
-- variables with global scope are preserved between restarts
services = {}
vip_active_at = 0

local payload_name = read_config('inject_payload_name') or 'service_status'

function process_message ()
    local ts = floor(read_message("Timestamp")/1e6) -- ms
    local metric_name = read_message("Fields[name]")
    local value = read_message("Fields[value]")
    local name
    local top_entry
    local item_name
    local group_name
    local state

    if string.find(metric_name, '^pacemaker.resource.vip__public') then
        if value == 1 then
            vip_active_at = ts
        else
            vip_active_at = 0
        end
        return 0
    end

    if string.find(metric_name, '%.up$') then
        state = utils.state_map.UP
    elseif string.find(metric_name, '%.down$') then
        state = utils.state_map.DOWN
    elseif string.find(metric_name, '%.disabled$') then
        state = utils.state_map.DISABLED
    end

    if string.find(metric_name, '^openstack') then
        name, group_name, item_name = string.match(metric_name, '^openstack%.([^._]+)%.([^._]+)%.([^._]+)')
        top_entry = 'workers'
        if not item_name then
            -- A service can have several API checks, by convention the service name
            -- is written down "<name>-<item>" or just "<name>".
            item_name = string.match(metric_name, '^openstack%.([^.]+)%.check_api$')
            name, _ = string.match(item_name, '^([^-]+)\-(.*)')
            if not name then
                name = item_name
            end

            top_entry = 'check_api'
            group_name = 'endpoint'
            -- retrieve the current state
            state = utils.check_api_status_to_state_map[value]
            -- and always override value to 1
            value = 1
        end

    elseif string.find(metric_name, '^haproxy%.backend') then
        top_entry = 'haproxy'
        group_name = 'pool'
        item_name = string.match(metric_name, '^haproxy%.backend%.([^.]+)%.servers')
        name = string.match(item_name, '^([^-]+)')
    end
    if not name or not item_name then
      return -1
    end

    -- table initialization for the first time we see a service
    if not services[name] then services[name] = {} end
    if not services[name][top_entry] then services[name][top_entry] = {} end
    if not services[name][top_entry][item_name] then services[name][top_entry][item_name] = {} end

    local service = services[name][top_entry][item_name]
    service[state] = {last_seen=ts, value=value, group_name=group_name}

    -- In the logic to treat check_api results like others, group by up/down
    -- and reset the counterpart w/ value=0
    if top_entry == 'check_api' then
        local invert_state
        if state == utils.state_map.UP then
            invert_state = utils.state_map.DOWN
        elseif state == utils.state_map.DOWN then
            invert_state = utils.state_map.UP
        end
        if invert_state then
            if not service[invert_state] then
                service[invert_state] = {}
            end
            service[invert_state] = {last_seen=ts, value=0, group_name=group_name}
        end
    end
    return 0
end

function timer_event(ns)
    for name, states in pairs(services) do
       inject_payload('json', payload_name,
                      cjson.encode({vip_active_at=vip_active_at, name=name, states=states}))
    end
end
