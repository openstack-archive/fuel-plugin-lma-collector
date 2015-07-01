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
local max = math.max
local utils  = require 'lma_utils'

_PRESERVATION_VERSION = 2
-- variables with global scope are preserved between restarts
all_service_status = {}

-- local scope variables
local timeout = read_config("timeout") or 60
local hostname
local datapoints = {}

function process_message ()
    local ok, data = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        return -1
    end
    local timestamp = read_message('Timestamp')
    local ts = floor(timestamp/1e6) -- in ms
    hostname = read_message("Hostname")
    local service_name = data.name
    local states = data.states

    local worker_status = -1
    local check_api_status = -1
    local haproxy_server_status = -1
    local global_status
    local events = {}
    local not_up_status = {}
    local msg_event

    if not all_service_status[service_name] then all_service_status[service_name] = {} end

    if states.workers then
        worker_status = compute_status(events, not_up_status, ts, 'workers', service_name, states.workers, true)
    end

    if states.check_api then
        check_api_status = compute_status(events, not_up_status, ts, 'check_api', service_name, states.check_api, false)
    end
    if states.haproxy then
        haproxy_server_status = compute_status(events, not_up_status, ts, 'haproxy', service_name, states.haproxy, true)
    end
    global_status = max(worker_status, check_api_status, haproxy_server_status)
    -- global service status
    utils.add_metric(datapoints,
                string.format('%s.openstack.%s.status', hostname, service_name),
                {ts, global_status})

    -- only emit status if the public vip is active
    if not expired(ts, data.vip_active_at) then
        local prev = all_service_status[service_name].global_status or utils.global_status_map.UNKNOWN
        local updated = false
        if prev ~= global_status or #events > 0 then
            updated = true
        end
        if updated then -- append not UP status elements in details
            for k, v in pairs(not_up_status) do events[#events+1] = v end
        end
        local details = ''
        if #events > 0 then
            details = cjson.encode(events)
        end
        local status_msg = utils.make_status_message(timestamp, service_name,
                                                     global_status, prev,
                                                     updated, details)
        inject_message(status_msg)
    end

    all_service_status[service_name].global_status = global_status

    if #datapoints > 0 then
        inject_payload("json", "influxdb", cjson.encode(datapoints))
        datapoints = {}
    end
    return 0
end

function get_previous_status(service_name, top_entry, name)
    if not all_service_status[service_name] then
         all_service_status[service_name] = {}
    end
    if not all_service_status[service_name][top_entry] then
         all_service_status[service_name][top_entry] = {}
    end
    if not all_service_status[service_name][top_entry][name] then
         all_service_status[service_name][top_entry][name] = utils.service_status_map.UNKNOWN
    end
    return all_service_status[service_name][top_entry][name]
end

function set_status(service_name, top_entry, name, status)
     all_service_status[service_name][top_entry][name] = status
end

function compute_status(events, not_up_status, current_time, elts_name, name, states, display_num)
    local down_elts = {}
    local down_elts_count = 0
    local zero_up = {}
    local zero_up_count = 0
    local one_up = {}
    local one_disabled = {}
    local one_disabled_count = 0
    local service_status = utils.service_status_map.UNKNOWN
    local up_elements = {}
    local total_elements = {}

    for worker, worker_data in pairs(states) do
        if not total_elements[worker] then
            total_elements[worker] = 0
        end
        if not up_elements[worker] then
            up_elements[worker] = 0
        end
        for state, data in pairs(worker_data) do
            if not expired(current_time, data.last_seen) then
                total_elements[worker] = total_elements[worker] + data.value
                if state == utils.state_map.DOWN and data.value > 0 then
                    down_elts[worker] = data
                    down_elts_count = down_elts_count + 1
                end
                if state == utils.state_map.UP then
                    if data.value > 0 then
                        one_up[worker] = data
                    else
                        zero_up[worker] = data
                        zero_up_count = zero_up_count + 1
                    end
                    up_elements[worker] = data.value
                end
                if state == utils.state_map.DISABLED and data.value > 0 then
                     one_disabled[worker] = data
                     one_disabled_count = one_disabled_count + 1
                end
            end
        end
    end
    -- general element status
    if zero_up_count > 0 then
       service_status = utils.service_status_map.DOWN
    elseif down_elts_count > 0 then
       service_status = utils.service_status_map.DEGRADED
    elseif down_elts_count == 0 then
       service_status = utils.service_status_map.UP
    end

    -- elements clearly down
    for worker_name, worker in pairs(zero_up) do
        local prev = get_previous_status(name, elts_name, worker_name)
        local DOWN = utils.service_status_map.DOWN
        local event_detail = ""
        set_status(name, elts_name, worker_name, DOWN)
        if display_num then
            event_detail = string.format("(%s/%s UP)", up_elements[worker_name],
                                                       total_elements[worker_name])
        end

        if prev and prev ~= DOWN then
            events[#events+1] = string.format("%s %s %s -> %s %s", worker_name,
                                              worker.group_name,
                                              utils.service_status_to_label_map[prev],
                                              utils.service_status_to_label_map[DOWN],
                                              event_detail)

        else
            not_up_status[#not_up_status+1] = string.format("%s %s %s %s",
                                              worker_name,
                                              worker.group_name,
                                              utils.service_status_to_label_map[DOWN],
                                              event_detail)
        end
        utils.add_metric(datapoints, string.format('%s.openstack.%s.%s.%s.status',
                    hostname, name, worker.group_name, worker_name),
                    {current_time, utils.service_status_map.DOWN})
    end
    -- elements down or degraded
    for worker_name, worker in pairs(down_elts) do
        local prev = get_previous_status(name, elts_name, worker_name)
        local new_status
        local event_detail
        if one_up[worker_name] then
            new_status = utils.service_status_map.DEGRADED
        else
            new_status = utils.service_status_map.DOWN
        end
        set_status(name, elts_name, worker_name, new_status)
        utils.add_metric(datapoints,
                         string.format("%s.openstack.%s.%s.%s.status",
                         hostname, name, worker.group_name, worker_name),
                         {current_time, new_status})

        if display_num then
            event_detail = string.format("(%s/%s UP)", up_elements[worker_name],
                                                       total_elements[worker_name])
        else
            event_detail = ""
        end
        if prev ~= new_status then
           events[#events+1] = string.format("%s %s %s -> %s %s", worker_name,
                                             worker.group_name,
                                             utils.service_status_to_label_map[prev],
                                             utils.service_status_to_label_map[new_status],
                                             event_detail)
        elseif not zero_up[worker_name] then
           not_up_status[#not_up_status+1] = string.format("%s %s %s %s", worker_name,
                                             worker.group_name,
                                             utils.service_status_to_label_map[new_status],
                                             event_detail)
        end
    end

    -- elements up
    for worker_name, worker in pairs(one_up) do
        if not zero_up[worker_name] and not down_elts[worker_name] then
            local prev = get_previous_status(name, elts_name, worker_name)
            local UP = utils.service_status_map.UP
            set_status(name, elts_name, worker_name, UP)
            if prev and prev ~= utils.service_status_map.UP then
               events[#events+1] = string.format("%s %s %s -> %s", worker_name,
                                                 worker.group_name,
                                                 utils.service_status_to_label_map[prev],
                                                 utils.service_status_to_label_map[UP])
            end
            utils.add_metric(datapoints, string.format("%s.openstack.%s.%s.%s.status",
                        hostname, name, worker.group_name, worker_name),
                        {current_time, utils.service_status_map.UP})
        end
    end
    return service_status
end

function expired(current_time, last_time)
    if last_time > 0 and current_time - last_time <= timeout * 1000 then
       return false
    end
    return true
end
