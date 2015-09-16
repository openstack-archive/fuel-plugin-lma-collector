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

require 'table'
require 'string'

local afd = require 'afd'

local statuses = {}

local concat_string = '\n'

function process_message()
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

    local text
    if #alarms == 0 then
        text = 'no detail'
    else
        text = table.concat(afd.alarms_for_human(alarms), concat_string)
    end

    local title
    if not previous.status and status == consts.OKAY then
        -- don't send a email when we detect a new cluster which is OKAY
        return 0
    elseif not previous.status then
        title = string.format('%s status is %s',
                              cluster,
                              consts.status_label(status))
    elseif status ~= previous.status then
        title = string.format('%s status %s -> %s',
                              cluster,
                              consts.status_label(previous.status),
                              consts.status_label(status))
    elseif previous.text ~= text then
        title = string.format('%s status remains %s',
                              cluster,
                              consts.status_label(status))
    else
        -- nothing has changed since the last message
        return 0
    end

    inject_payload('txt', '', table.concat({title, text}, concat_string))

    -- store the last status and text for future messages
    previous.status = status
    previous.text = text

    return 0
end
