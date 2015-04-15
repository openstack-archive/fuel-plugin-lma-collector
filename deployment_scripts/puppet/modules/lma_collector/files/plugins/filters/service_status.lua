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

    if backend_name then -- Haproxy
        local haproxy = { name=backend_name, value=value, last_seen=ts }
        service["haproxy"][status][backend_name] = haproxy
    elseif worker_name then -- Services/Agents
        local worker = { name=worker_name, value=value, last_seen=ts }
        service["workers"][status][worker_name] = worker
    elseif check_api then
        local check = { value=utils.check_api_to_status_map[value], last_seen=ts }
        service["check_api"] = check
    else
        return -1
    end

    return 0
end

function compute_status(datapoints, current_time, elts_name, name, service)
    local down_elts = {}
    local down_elts_count = 0
    local zero_up = {}
    local one_up = {}
    local zero_up_count = 0
    local total_elts = 0
    local status = utils.service_status_map.UNKNOWN

    for worker, data in pairs(service[elts_name].down) do
        -- TODO status=UNKNOWN and continue if check last_seen > timeout
        if data.value > 0 then
            down_elts[worker] = data
            down_elts_count = down_elts_count + 1
        end
        total_elts = total_elts + 1
    end
    for worker, data in pairs(service[elts_name].up) do
        -- TODO status=UNKNOWN and continue if check last_seen > timeout
        if data.value > 0 then
            one_up[worker] = data
        else
            zero_up[worker] = data
            zero_up_count = zero_up_count + 1
        end
    end

    -- general element status
    if zero_up_count > 0 or down_elts_count > 0 then
       if elts_name == 'haproxy' then
           status = utils.service_status_map.DOWN
       else
           status = utils.service_status_map.DEGRADED
       end
    end
    if zero_up_count > 0 and zero_up_count == total_elts then
       status = utils.service_status_map.DOWN
    end
    if zero_up_count == 0 and down_elts_count == 0 then
       status = utils.service_status_map.OK
    end
    -- no metric came in so far
    if total_elts == 0 then status = utils.service_status_map.UNKNOWN end

    --prev = service[elts_name].previous_status
    --if prev ~= nil and prev ~= status then
    --   annotate(name .. " " .. elts_name, prev, status)
    --end
    --service[elts_name].previous_status = status

    -- per element status
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
            annotate(name .. " " .. worker_name, prev, utils.service_status_map.DOWN)
        end
        local metric_prefix = service[elts_name].prefix
        if not metric_prefix then metric_prefix = 'openstack' end

        datapoints[#datapoints+1] = {
            name = string.format('%s.%s.%s.%s.%s.status',
                   hostname, metric_prefix, name, service[elts_name].name, worker_name),
            columns = {"time", "value" },
            points = {{current_time, utils.service_status_map.DOWN}}
        }
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
        if one_up[worker_name] then
            service[elts_name].status[worker_name]=utils.service_status_map.DEGRADED
            datapoints[#datapoints+1] = {
                name = string.format("%s.openstack.%s.%s.%s.status",
                       hostname, name, service[elts_name].name, worker_name),
                columns = {"time", "value"},
                points = {{current_time, service[elts_name].status[worker_name]}}
            }
        else
            service[elts_name].status[worker_name]=utils.service_status_map.DOWN
        end
        if prev and prev ~= service[elts_name].status[worker_name] then
               annotate(name .. " " .. worker_name, prev, service[elts_name].status[worker_name])
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
            if prev ~= nill and prev ~= utils.service_status_map.OK then
               annotate(name .. " " .. worker_name, prev, utils.service_status_map.OK)
            end
            datapoints[#datapoints+1] = {
                name = string.format("%s.openstack.%s.%s.%s.status",
                       hostname, name, service[elts_name].name, worker_name),
                columns = {"time", "value"},
                points = {{current_time, service[elts_name].status[worker_name]}}
            }
        end
    end
    return status
end

function debug(foo)
    inject_payload('DEBUG', 'FOOO', cjson.encode(foo))
    return 0
end

function annotate(name, prev, status)
    -- TODO if active
    local str = string.format("Service %s status switch from %s to %s",
                name,
                utils.service_status_to_label_map[prev],
                utils.service_status_to_label_map[status])
    inject_payload('annotation', 'FOOO', str)
    return 0
end

function timer_event(ns)
    local current_time = floor(ns / 1e6) -- in ms
    local datapoints = {}

    for service_name, service in pairs(services) do
        local status_worker = -1
        local status_check_api = -1
        local status_api = utils.service_status_map.UNKNOWN
        local global_status
        -- workers (services/agents)
        if service.workers then
            status_worker = compute_status(datapoints, current_time, 'workers', service_name, service)
        end

        if service.check_api and service.check_api.value then
            status_check_api = service.check_api.value
        end
        status_api = compute_status(datapoints, current_time, 'haproxy', service_name, service)
        global_status = max(status_worker, status_check_api, status_api)

        prev = service['previous_global_status']
        if prev and prev ~= global_status then
            annotate(service_name, prev, global_status)
        end
        service.previous_global_status = global_status

        -- global service status
        datapoints[#datapoints+1] = {
            name = string.format('%s.openstack.%s.status', hostname, service_name),
            columns = {"time", "value" },
            points = {{current_time, global_status}}
        }
    end
    if #datapoints > 0 then
        debug()
        inject_payload("json", "influxdb", cjson.encode(datapoints))
    end
end
