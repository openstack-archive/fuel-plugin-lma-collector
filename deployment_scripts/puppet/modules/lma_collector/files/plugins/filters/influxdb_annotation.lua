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
local consts = require 'gse_constants'
local afd = require 'afd'

local measurement_name = read_config('measurement_name') or 'annotations'
local html_break_line = '<br />'

local statuses = {}

-- Transform a GSE cluster metric into an annotation stored into InfluxDB
function process_message ()
    local previous
    local text
    local cluster = afd.get_entity_name('cluster_name')
    local status = afd.get_status()
    local alarms = afd.extract_alarms()

    if not cluster or not status or not alarms then
        return -1
    end

    if not statuses[cluster] then
        statuses[cluster] = {}
    end
    previous = statuses[cluster]

    text = table.concat(afd.alarms_for_human(alarms), html_break_line)

    -- build the title
    if not previous.status and status == consts.OKAY then
        -- don't send an annotation when we detect a new cluster which is OKAY
        return 0
    elseif not previous.status then
        title = string.format('General status is %s',
                              consts.status_label(status))
    elseif previous.status ~= status then
        title = string.format('General status %s -> %s',
                              consts.status_label(previous.status),
                              consts.status_label(status))
-- TODO(pasquier-s): generate an annotation when the set of alarms has changed.
-- the following code generated an annotation whenever at least one value
-- associated to an alarm was changing. This led to way too many annotations
-- with alarms monitoring the CPU usage for instance.
--    elseif previous.text ~= text then
--        title = string.format('General status remains %s',
--                              consts.status_label(status))
    else
        -- nothing has changed since the last message
        return 0
    end

    local msg = {
        Timestamp = read_message('Timestamp'),
        Type = 'metric',
        Severity = utils.label_to_severity_map.INFO,
        Hostname = read_message('Hostname'),
        Fields = {
            name = measurement_name,
            tag_fields = { 'cluster' },
            value_fields = { 'title', 'tags', 'text' },
            title = title,
            tags = cluster,
            text = text,
            cluster = cluster,
            source = 'influxdb_annotation'
      }
    }
    utils.inject_tags(msg)

    -- store the last status and alarm text for future messages
    previous.status = status
    previous.text = text

    return utils.safe_inject_message(msg)
end
