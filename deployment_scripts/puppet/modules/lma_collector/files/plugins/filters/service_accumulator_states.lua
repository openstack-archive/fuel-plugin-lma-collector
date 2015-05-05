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
            name = string.match(metric_name, '^openstack%.([^.]+)%.check.api$')
            top_entry = 'check_api'
        end

    elseif string.find(metric_name, '^haproxy%.backend') then
        top_entry = 'haproxy'
        group_name = 'api'
        item_name = string.match(metric_name, '^haproxy%.backend%.([^._]+)%.servers')
        name = string.match(item_name, '^([^-]+)')
    end
    if not name then
      return -1
    end

    -- table initialization for the first time we see a service
    if not services[name] then services[name] = {} end
    if not services[name][top_entry] then services[name][top_entry] = {} end

    local service = services[name]
    local item = {last_seen=ts, value=value}
    if item_name then
        if not service[top_entry][item_name] then
            service[top_entry][item_name] = {}
        end
        item.group_name = group_name
        service[top_entry][item_name][state] = item
    else
        service[top_entry] = item
    end
    return 0
end

function timer_event(ns)
    inject_payload('json', payload_name, cjson.encode({vip_active_at=vip_active_at, services=services}))
end
