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
local utils  = require 'lma_utils'

local measurement_name = read_config('measurement_name') or 'annotations'
local html_break_line = '<br />'

-- Transform a status message into an InfluxDB datapoint
function process_message ()
    local title
    local text = ''
    local status = read_message('Fields[status]')
    local prev_status = read_message('Fields[previous_status]')

    local ok, details = pcall(cjson.decode, read_message('Payload'))
    if ok then
        text = table.concat(details, html_break_line)
    end

    if prev_status ~= status then
        title = string.format('General status %s -> %s',
                              utils.global_status_to_label_map[prev_status],
                              utils.global_status_to_label_map[status])
    else
        title = string.format('General status remains %s',
                              utils.global_status_to_label_map[status])
    end

    local msg = {
        Timestamp = read_message('Timestamp'),
        Type = 'multivalue_metric',
        Severity = utils.label_to_severity_map.INFO,
        Hostname = read_message('Hostname'),
        Payload = cjson.encode({title=title, tags=read_message('Field[service]'), text=text}),
        Fields = {
            name = measurement_name,
            tag_fields = { 'service' },
            service = read_message('Fields[service]'),
            source = 'influxdb_annotation'
      }
    }
    utils.inject_tags(msg)
    inject_message(msg)

    return 0
end
