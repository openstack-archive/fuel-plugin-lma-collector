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
require 'table'
require "os"
require 'math'

local floor = math.floor
local utils  = require 'lma_utils'
local last_flush = os.time()
local datapoints = {}
local base_serie_name = 'annotation'
local html_break_line = '<br />'

local flush_count = read_config('flush_count') or 100
local flush_interval = read_config('flush_interval') or 5

function flush ()
    local now = os.time()
    if #datapoints > 0 and (#datapoints > flush_count or now - last_flush > flush_interval) then
        inject_payload("json", "influxdb", cjson.encode(datapoints))

        datapoints = {}
        last_flush = now
    end
end

function process_message ()
    local ts = floor(read_message('Timestamp')/1e6) -- ms
    local msg_type = read_message('Type')
    local payload = read_message('Payload')
    local service = read_message('Fields[service]')
    local name = string.gsub(service, ' ', '_')
    local serie_name = string.format('%s.%s', base_serie_name, name)
    local title

    if msg_type == 'heka.sandbox.status' then
        local status = read_message('Fields[status]')
        local prev_status = read_message('Fields[previous_status]')
        local ok, details = pcall(cjson.decode, payload)
        if not ok then details = {'no detail'} end
        if prev_status ~= status then
            title = string.format('General status %s -> %s',
                                  utils.global_status_to_label_map[prev_status],
                                  utils.global_status_to_label_map[status])
        else
            title = string.format('General status remains %s',
                                  utils.global_status_to_label_map[status])
        end
        local text = table.concat(details, html_break_line)
        datapoints[#datapoints+1] = {
            name = serie_name,
            columns = {"time", "title", "tag", "text"},
            points = {{ts, title, service, text}}
        }
    end
    flush()
    return 0
end

function timer_event(ns)
    flush()
end
