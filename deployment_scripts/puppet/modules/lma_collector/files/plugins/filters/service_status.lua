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

-- global scope variables
service_status = {}

-- local scope variables
local timeout = read_config("timeout") or 60
local hostname
local html_break_line = '<br />'
local datapoints = {}
local annotations = {}

function process_message ()
    ok, data = pcall(cjson.decode, read_message("Payload"))
    if not ok then
        return -1
    end
    local ts = floor(read_message("Timestamp")/1e6) -- in ms
    local services = data.services
    hostname = read_message("Hostname")

    for service_name, service in pairs(services) do
        local worker_status = -1
        local check_api_status = -1
        local haproxy_server_status = -1
        local general_status = utils.service_status_map.UNKNOWN
        local events = {}

        if not service_status[service_name] then service_status[service_name] = {} end

        if service.workers then
            worker_status = compute_status(events, ts, 'workers', service_name, service)
        end

        if service.check_api and service.check_api.value then
            check_api_status = utils.check_api_to_status_map[service.check_api.value]
            local prev_check_api_status = utils.service_status_map.UNKNOWN
            if service_status[service_name].check_api then
                prev_check_api_status = service_status[service_name].check_api
            end
            service_status[service_name].check_api = check_api_status
            if prev_check_api_status and prev_check_api_status ~= check_api_status then
                events[#events+1] = string.format("check api %s -> %s",
                                      utils.service_status_to_label_map[prev_check_api_status],
                                      utils.service_status_to_label_map[check_api_status])
            end
        end
        haproxy_server_status = compute_status(events, ts, 'haproxy', service_name, service)
        general_status = max(worker_status, check_api_status, haproxy_server_status)
        -- global service status
        utils.add_metric(datapoints,
                    string.format('%s.openstack.%s.status', hostname, service_name),
                    {ts, general_status})

        -- only emit annotation if the public vip is active
        if not expired(ts, data.vip_active_at) then
            local service_annotation
            local prev = service_status[service_name].general_status or utils.service_status_map.UNKNOWN
            if prev and prev ~= general_status then
                service_annotation = string.format("General status %s -> %s",
                                      utils.service_status_to_label_map[prev],
                                      utils.service_status_to_label_map[general_status])
            elseif #events > 0 then
                service_annotation = string.format("General status stays %s",
                                      utils.service_status_to_label_map[general_status])
            end
            if service_annotation then
                 annotate(ts, service_name, service_annotation, events)
            end
        end

        service_status[service_name].general_status = general_status
    end
    return 0
end

function get_previous_status(service_name, top_entry, name)
    if not service_status[service_name] then
         service_status[service_name] = {}
    end
    if not service_status[service_name][top_entry] then
         service_status[service_name][top_entry] = {}
    end
    if not service_status[service_name][top_entry][name] then
         service_status[service_name][top_entry][name] = utils.service_status_map.UNKNOWN
    end
    return service_status[service_name][top_entry][name]
end

function set_status(service_name, top_entry, name, status)
     service_status[service_name][top_entry][name] = status
end

function compute_status(events, current_time, elts_name, name, service)
    local down_elts = {}
    local down_elts_count = 0
    local zero_up = {}
    local zero_up_count = 0
    local one_up = {}
    local one_disabled = {}
    local one_disabled_count = 0
    local not_expired_count = 0
    local total_elts = 0
    local status = utils.service_status_map.UNKNOWN

    for worker, worker_data in pairs(service[elts_name]) do
        for state, data in pairs(worker_data) do
            if not expired(current_time, data.last_seen) then
                not_expired_count = not_expired_count + 1
                total_elts = total_elts + 1
                if state == 'down' and data.value > 0 then
                    down_elts[worker] = data
                    down_elts_count = down_elts_count + 1
                end
                if state == 'up' then
                    if data.value > 0 then
                        one_up[worker] = data
                    else
                        zero_up[worker] = data
                        zero_up_count = zero_up_count + 1 
                    end
                end
                if state == 'disabled' and data.value > 0 then
                     one_disabled[worker] = data
                     one_disabled_count = one_disabled_count + 1
                end
            end
        end
    end
    -- general element status
    if zero_up_count > 0 then
       status = utils.service_status_map.DOWN
    elseif down_elts_count > 0 then
       status = utils.service_status_map.DEGRADED
    elseif down_elts_count == 0 then
       status = utils.service_status_map.OK
    else -- no metric came in so far
       status = utils.service_status_map.UNKNOWN
    end

    -- elements clearly down
    for worker_name, worker in pairs(zero_up) do
        prev = get_previous_status(name, elts_name, worker_name)
        set_status(name, elts_name, worker_name, utils.service_status_map.DOWN)
        if prev and prev ~= utils.service_status_map.DOWN then
            events[#events+1] = string.format("%s status %s -> %s", worker_name,
                                              utils.service_status_to_label_map[prev],
                                              utils.service_status_to_label_map[2]) -- DOWN

        end
        utils.add_metric(datapoints, string.format('%s.openstack.%s.%s.%s.status',
                    hostname, name, worker.group_name, worker_name),
                    {current_time, utils.service_status_map.DOWN})
    end
    -- elements down or degraded
    for worker_name, worker in pairs(down_elts) do
        prev = get_previous_status(name, elts_name, worker_name)
        local new_s
        if one_up[worker_name] then
            new_s = utils.service_status_map.DEGRADED
        else
            new_s = utils.service_status_map.DOWN
        end
        set_status(name, elts_name, worker_name, new_s)
        utils.add_metric(datapoints,
                         string.format("%s.openstack.%s.%s.%s.status",
                         hostname, name, worker.group_name, worker_name),
                         {current_time, new_s})

        if prev ~= new_s then
           events[#events+1] = string.format("%s status %s -> %s", worker_name,
                                             utils.service_status_to_label_map[prev],
                                             utils.service_status_to_label_map[new_s])
        end
    end

    -- elements ok
    for worker_name, worker in pairs(one_up) do
        if not zero_up[worker_name] and not down_elts[worker_name] then
            prev = get_previous_status(name, elts_name, worker_name)
            set_status(name, elts_name, worker_name, utils.service_status_map.OK)
            if prev and prev ~= utils.service_status_map.OK then
               events[#events+1] = string.format("%s status %s -> %s", worker_name,
                                                 utils.service_status_to_label_map[prev],
                                                 utils.service_status_to_label_map[0]) -- OK
            end
            utils.add_metric(datapoints, string.format("%s.openstack.%s.%s.%s.status",
                        hostname, name, worker.group_name, worker_name),
                        {current_time, utils.service_status_map.OK})
        end
    end
    return status
end

function expired(current_time, last_time)
    if last_time > 0 and current_time - last_time <= timeout * 1000 then
       return false
    end
    return true
end

function annotate(current_time, name, title, events)
    local text = table.concat(events, html_break_line)
    annotations[#annotations+1] = {
        time=current_time,
        title=title,
        name=name,
        tag=name,
        text=text,
    }
end

function timer_event(ns)
    local current_time = floor(ns / 1e6) -- in ms
    if #datapoints > 0 then
        inject_payload("json", "influxdb", cjson.encode(datapoints))
        datapoints = {}
    end
    if #annotations > 0 then
        inject_payload("json", "annotation", cjson.encode(annotations))
        annotations = {}
    end
end
