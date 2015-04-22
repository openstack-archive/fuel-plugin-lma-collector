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
    local ok, events = pcall(cjson.decode, read_message("Payload"))
    if not ok then return -1 end

    for _, event in ipairs(events) do
        if event.name then
            local name = string.gsub(event.name, ' ', '_')
            serie_name = string.format('%s.%s', base_serie_name, name)
        else
            serie_name = base_serie_name
        end

        local text = table.concat(event.events, html_break_line)
        datapoints[#datapoints+1] = {
            name = serie_name,
            columns = {"time", "title", "tag", "text"},
            points = {{event.time, event.title, event.name, text}}
        }
    end

    flush()
    return 0
end

function timer_event(ns)
    flush()
end
