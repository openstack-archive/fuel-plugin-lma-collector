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

local timeout = read_config("timeout") or 60

services = {
    nova = { api = { up = {}, down = {}, name="api"}, workers = { up = {}, down = {}, name="services"}},
    cinder = { api = { up = {}, down = {}, name="api"}, workers = { up = {}, down = {}, name="services"}},
    neutron = { api = { up = {}, down = {}, name="api"}, workers = {up = {}, down = {}, name="agents"}},
    glance = { api = { up = {}, down = {}, name="api"}},
--    heat = { api = { up = {}, down = {}}},
--    horizon = { api = { up = {}, down = {} }},
--    keystone = { api = {up = {}, down = {}}},
--    sahara = { api = { up = {}, down = {} }},
--    murano = { api = { up = {}, down = {} }},
--    swift = { api = { up = {}, down = {} }},
}

-- nova.status
-- nova.services.compute.status
-- nova.services.scheduler.status
-- nova.api.status
-- nova.api-ec2.status

local is_active = nil
local hostname = nil

function process_message ()
    local ts = floor(read_message("Timestamp")/1e6) -- in ms
    local metric_name = read_message("Fields[name]")
    local value = read_message("Fields[value]")
    hostname = read_message("Fields[hostname]")

    if string.find(metric_name, 'pacemaker.resource.vip__public') then
         if value == 1 then is_active = ts end
         return 0
    end

    local service_name = nil
    local backend_name = nil
    local worker_name = nil

    local status = nil
    if string.find(metric_name, '%.up$') then 
        status = 'up'
    elseif string.find(metric_name, '%.down$') then
        status = 'down'
    else
        return -1
    end

    if string.find(metric_name, 'openstack') then
         service_name = string.match(metric_name, '^openstack%.([^._]+)')
         worker_name = string.match(metric_name, '^openstack%.[^._]+%.[^._]+%.([^._]+)')
    elseif string.find(metric_name, 'haproxy%.backend') then
         backend_name = string.match(metric_name, '^haproxy%.backend%.([^._]+)%.servers')
         service_name = string.match(backend_name, '^([^-]+)') -- haproxy looks like 'nova-api-2'
	 --debug({backend_name=backend_name, service_name=service_name, metric_name=metric_name})
    else
         return -1
    end

    if service_name == nil then return -1 end

    local service = services[service_name]
    if service == nil then return 0 end

    if backend_name then -- API
        local api = { name=backend_name, value=value, last_seen=ts}
        services[service_name]["api"][status][backend_name] = api
    else -- Services/Agents
        local worker = { name=worker_name, value=value, last_seen=ts }
        services[service_name]["workers"][status][worker_name] = worker
    end

    return 0
end

function workers_status(datapoints, current_time, elts_name, name, service)
    --local datapoints = {}
    local down_elts = {}
    local down_elts_count = 0
    local zero_up = {}
    local one_up = {}
    local zero_up_count = 0
    local total_elts = 0
    local status = utils.service_status_map.UNKNOWN
--    if elts_name == 'api' then debug(service[elts_name]) return 1 end

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

    -- global workers status
    if zero_up_count > 0 or down_elts_count > 0 then
       status = utils.service_status_map.DEGRADED
    end
    if zero_up_count > 0 and zero_up_count == total_elts then
       status = utils.service_status_map.DOWN
    end
    if zero_up_count == 0 and down_elts_count == 0 then
       status = utils.service_status_map.OK
    end
    if total_elts == 0 then status = utils.service_status_map.UNKNOWN end
    prev = service[elts_name].previous_status
    if prev ~= nil and prev ~= status then
       annotate(name .. " " .. elts_name, prev, status)
    end
    service[elts_name].previous_status = status

    -- per workers status
    for worker_name, worker in pairs(zero_up) do
        s = service[elts_name]['status']
        local prev = nil
        if s == nil then
            service[elts_name].status = {}
        else
            prev = service[elts_name].status[worker_name]
        end
        service[elts_name].status[worker_name]=utils.service_status_map.DOWN
        -- if prev ~= nil and prev ~= utils.service_status_map.DOWN then
        --     annotate(name .. " " .. worker_name, prev, utils.service_status_map.DOWN)
        -- end
        datapoints[#datapoints+1] = {
            name = string.format('%s.openstack.%s.%s.%s.status',
                   hostname, name, service[elts_name].name, worker_name),
            columns = {"time", "value" },
            points = {{current_time, utils.service_status_map.DOWN}}
        }
    end
    for worker_name, worker in pairs(down_elts) do
        s = service[elts_name]['status']
        local prev = nil
        if s == nil then
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
        if prev ~= nil and prev ~= service[elts_name].status[worker_name] then
               annotate(name .. " " .. worker_name, prev, utils.service_status_map.DEGRADED)
        end
    end

    for worker_name, worker in pairs(one_up) do
        if not zero_up[worker_name] and not down_elts[worker_name] then
            s = service[elts_name]['status']
            local prev = nil
            if s == nil then
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
    debug({zero_up=zero_up, down_elts=down_elts, one_up=one_up, total=total_elts})
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
    local status_worker = nil
    local global_status = nil

    for service_name, service in pairs(services) do

        -- workers (services/agents)
        if service.workers then
            status_worker = workers_status(datapoints, current_time, 'workers', service_name, service)
        end

        status_api = workers_status(datapoints, current_time, 'api', service_name, service)
        --status_api = api_status(datapoints, current_time, service_name, service)
        if status_worker == nil then
            global_status = status_api
        elseif status_api > status_worker then
            global_status = status_api
        else
            global_status = status_worker
        end

        prev = service['previous_global_status']
        if prev ~= nil and prev ~= global_status then
            annotate(service_name, prev, global_status)
        end
        service.previous_global_status = global_status

        -- emit global service status
        datapoints[#datapoints+1] = {
            name = string.format('%s.%s.status', hostname, service_name),
            columns = {"time", "value" },
            points = {{current_time, global_status}}
        }
    end
    if #datapoints > 0 then
        inject_payload("json", "FOOO", cjson.encode(datapoints))
        inject_payload("json", "FOOO", cjson.encode(services))
    end
end
