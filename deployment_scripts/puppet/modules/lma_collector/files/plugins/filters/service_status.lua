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
is_active = 0
services = {
    nova = { haproxy = { up = {}, down = {}, name="api"},
             workers = { up = {}, down = {}, name="services"},
             check_api = {}},
    cinder = { haproxy = { up = {}, down = {}, name="api"},
               workers = { up = {}, down = {}, name="services"},
               check_api = {}},
    neutron = { haproxy = { up = {}, down = {}, name="api"},
                workers = {up = {}, down = {}, name="agents"},
                check_api = {}},
    glance = { haproxy = { up = {}, down = {}, name="api"},
               check_api = {}},
    heat = { haproxy = { up = {}, down = {}, name="api"},
             check_api = {}},
    keystone = { haproxy = {up = {}, down = {}, name="api"},
                 check_api = {}},
    horizon = { haproxy = { up = {}, down = {}, name="api"}},
    sahara = { haproxy = { up = {}, down = {}, name="api"}},
    murano = { haproxy = { up = {}, down = {}, name="api"}},
    swift = { haproxy = { up = {}, down = {}, name="api"}},
    mysqld = { haproxy = { up = {}, down = {}, name="lb", prefix="mysql"}},
}

-- local scope variables
local hostname
local timeout = read_config("timeout") or 60
local all_annotations = {}
local html_break_line = '<br />'

function process_message ()
    local ts = floor(read_message("Timestamp")/1e6) -- in ms
    local metric_name = read_message("Fields[name]")
    local value = read_message("Fields[value]")
    hostname = read_message("Fields[hostname]")

    if string.find(metric_name, '^pacemaker.resource.vip__public') then
         if value == 1 then is_active = ts end
         return 0
    end

    local service_name
    local backend_name
    local worker_name
    local check_api
    local status

    if string.find(metric_name, '%.up$') then
        status = 'up'
    elseif string.find(metric_name, '%.down$') then
        status = 'down'
    end
    if string.find(metric_name, '^openstack') then
         service_name, worker_name = string.match(metric_name,
                                     '^openstack%.([^._]+)%.[^._]+%.([^._]+)')
         if not worker_name then
             service_name, check_api = string.match(metric_name,
                                     '^openstack%.([^.]+)%.(check.api)$')
         end

    elseif string.find(metric_name, '^haproxy%.backend') then
         backend_name = string.match(metric_name,
                                     '^haproxy%.backend%.([^._]+)%.servers')
         service_name = string.match(backend_name, '^([^-]+)')
    end

    if not service_name then return 0 end

    local service = services[service_name]
    if not service then return 0 end

    local name = backend_name or worker_name
    local item = {last_seen=ts}
    if name then
        item.name=name
        item.value=value
        if backend_name then
            top_entry='haproxy'
        elseif worker_name then
            top_entry='workers'
        else
            return -1
        end
        service[top_entry][status][name] = item
    elseif check_api then
        item.value=utils.check_api_to_status_map[value]
        service.check_api.value = item.value
        service.check_api.last_seen = item.last_seen
    else
        return -1
    end
    --if backend_name then -- Haproxy
    --    local haproxy = { name=backend_name, value=value, last_seen=ts }
    --    service["haproxy"][status][backend_name] = haproxy
    --elseif worker_name then -- Services/Agents
    --    local worker = { name=worker_name, value=value, last_seen=ts }
    --    service["workers"][status][worker_name] = worker
    --elseif check_api then
    --    if service.check_api then
    --        service.check_api.value=utils.check_api_to_status_map[value]
    --        service.check_api.last_seen=ts
    --    else
    --        return -1
    --    end
    --else
    --    return -1
    --end

    return 0
end

function push_metric(datapoints, name, points)
    datapoints[#datapoints+1] = {
        name = name,
        columns = {"time", "value" },
        points = {points}
    }
end

function compute_status(events, datapoints, current_time, elts_name, name, service)
    local down_elts = {}
    local down_elts_count = 0
    local zero_up = {}
    local zero_up_count = 0
    local one_up = {}
    local not_expired_count = 0
    local total_elts = 0
    local status = utils.service_status_map.UNKNOWN

    for worker, data in pairs(service[elts_name].down) do
        if not expired(current_time, data.last_seen) then
            not_expired_count = not_expired_count + 1
            total_elts = total_elts + 1
            if data.value > 0 then
                down_elts[worker] = data
                down_elts_count = down_elts_count + 1
            end
        end
    end
    for worker, data in pairs(service[elts_name].up) do
        if not expired(current_time, data.last_seen) then
            not_expired_count = not_expired_count + 1
            if data.value > 0 then
                one_up[worker] = data
            else
                zero_up[worker] = data
                zero_up_count = zero_up_count + 1
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
    else
    -- no metric came in so far
       status = utils.service_status_map.UNKNOWN
    end

    -- elements clearly down
    for worker_name, worker in pairs(zero_up) do
        s = service[elts_name]['status']
        local prev = nil
        if not s then
            service[elts_name].status = {}
        else
            prev = service[elts_name].status[worker_name]
        end
        service[elts_name].status[worker_name]=utils.service_status_map.DOWN
        if prev and prev ~= utils.service_status_map.DOWN then
            events[#events+1] = string.format(
                                  "%s status %s -> %s",
                                  worker_name,
                                  utils.service_status_to_label_map[prev],
                                  utils.service_status_to_label_map[2]) -- DOWN

        end
        local metric_prefix = service[elts_name].prefix
        if not metric_prefix then metric_prefix = 'openstack' end

        push_metric(datapoints,
                    string.format('%s.%s.%s.%s.%s.status',
                    hostname, metric_prefix, name, service[elts_name].name, worker_name),
                    {current_time, utils.service_status_map.DOWN})
    end
    -- elements down or degraded
    for worker_name, worker in pairs(down_elts) do
        s = service[elts_name]['status']
        local prev = nil
        if not s then
            service[elts_name].status = {}
        else
            prev = service[elts_name].status[worker_name]
        end
        local new_s = nil
        if one_up[worker_name] then
            new_s = utils.service_status_map.DEGRADED
        else
            new_s = utils.service_status_map.DOWN
        end
        service[elts_name].status[worker_name]=new_s

        local metric_prefix = service[elts_name].prefix
        if not metric_prefix then metric_prefix = 'openstack' end
        push_metric(datapoints, string.format("%s.%s.%s.%s.%s.status",
                    hostname, metric_prefix, name, service[elts_name].name, worker_name),
                    {current_time, new_s})

        if prev and prev ~= service[elts_name].status[worker_name] then
               events[#events+1] = string.format(
                                     "%s status %s -> %s",
                                     worker_name,
                                     utils.service_status_to_label_map[prev],
                                     utils.service_status_to_label_map[new_s])
        end
    end

    -- elements ok
    for worker_name, worker in pairs(one_up) do
        if not zero_up[worker_name] and not down_elts[worker_name] then
            s = service[elts_name]['status']
            local prev = nil
            if not s then
                service[elts_name].status = {}
            else
                prev = service[elts_name].status[worker_name]
            end
            service[elts_name].status[worker_name]=utils.service_status_map.OK
            if prev and prev ~= utils.service_status_map.OK then
               events[#events+1] = string.format(
                                     "%s status %s -> %s",
                                     worker_name,
                                     utils.service_status_to_label_map[prev],
                                     utils.service_status_to_label_map[0]) -- OK
            end
            local metric_prefix = service[elts_name].prefix
            if not metric_prefix then metric_prefix = 'openstack' end
            push_metric(datapoints, string.format("%s.%s.%s.%s.%s.status",
                        hostname, metric_prefix, name, service[elts_name].name, worker_name),
                        {current_time, service[elts_name].status[worker_name]})
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
    if not expired(current_time, is_active) then
        local text = table.concat(events, html_break_line)
        all_annotations[#all_annotations+1] = {
            time=current_time,
            title=title,
            name=name,
            tag=name,
            text=text,
        }
    end
end

function timer_event(ns)
    local current_time = floor(ns / 1e6) -- in ms
    local datapoints = {}

    for service_name, service in pairs(services) do
        local worker_status = -1
        local check_api_status = -1
        local haproxy_server_status = utils.service_status_map.UNKNOWN
        local general_status
        local events = {}

        if service.workers then
            worker_status = compute_status(events, datapoints, current_time, 'workers', service_name, service)
        end

        if service.check_api and service.check_api.value then
            check_api_status = service.check_api.value
            local prev_check_api_status = service.check_api.status
            service.check_api.status = check_api_status
            if prev_check_api_status and prev_check_api_status ~= check_api_status then
                events[#events+1] = string.format("check api %s -> %s",
                                      utils.service_status_to_label_map[prev_check_api_status],
                                      utils.service_status_to_label_map[check_api_status])
            end
        end
        haproxy_server_status = compute_status(events, datapoints, current_time, 'haproxy', service_name, service)
        general_status = max(worker_status, check_api_status, haproxy_server_status)

        local service_annotation
        local prev = service['previous_general_status']
        if prev and prev ~= general_status then
            service_annotation = string.format("General status %s -> %s",
                                  utils.service_status_to_label_map[prev],
                                  utils.service_status_to_label_map[general_status])
        elseif #events > 0 then
            service_annotation = string.format("General status stays %s",
                                  utils.service_status_to_label_map[general_status])
        end
        if service_annotation then
             annotate(current_time, service_name, service_annotation, events)
        end
        service.previous_general_status = general_status

        -- global service status
        push_metric(datapoints,
                    string.format('%s.openstack.%s.status', hostname, service_name),
                    {current_time, general_status})
    end
    if #datapoints > 0 then
        inject_payload("json", "influxdb", cjson.encode(datapoints))
    end

    if #all_annotations > 0 then
        inject_payload("json", "annotation", cjson.encode(all_annotations))
        all_annotations = {}
    end
end
