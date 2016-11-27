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

local utils = require 'lma_utils'
local consts = require 'gse_constants'
local afd = require 'afd'

local debug_mode = read_config('debug_mode') or false
local not_ok_mode = read_config('not_ok_mode') or false
-- not_ok_mode: state change notify + WARN, UNKNOWN, CRITICAL, DOWN states notify
-- debug_mode: every state notify


local statuses = {}

function process_message()
    local cluster
    local node_role
    -- object:
    --   cluster_name  for gse_cluster, gse_node_cluster and gse_service_cluster;
    --   node_role     for afd_node;
    --   service       for afd_service.
    local object
    local previous
    local service
    local alarm_source
    local title

    local hostname = read_message('Hostname')
    local type = read_message('Type')
    local payload = read_message('Payload')

    if not statuses[type] then
        statuses[type] = {}
    end

    local status = afd.get_status()
    if not status then
        return -1
    end

    if type == 'heka.sandbox.gse_cluster_metric'
            or type == 'heka.sandbox.gse_node_cluster_metric'
            or type == 'heka.sandbox.gse_service_cluster_metric' then
        cluster = afd.get_entity_name('cluster_name')
        alarm_source = '-'
        if not cluster then
            return -1
        end
        object = cluster
    else
        alarm_source = afd.get_entity_name('source')
        if not alarm_source then
            return -1
        end
        if type == 'heka.sandbox.afd_node_metric' then
            node_role = afd.get_entity_name('node_role')
            object = node_role
        else
            service = afd.get_entity_name('service')
            object = service
        end
        object = object .. '/' .. hostname
    end

    if not statuses[type][object] then
        statuses[type][object] = {}
    end
    previous = statuses[type][object]

    if not previous.status or (status ~= consts.OKAY and not_ok_mode) or debug_mode then
        title = string.format('General status is %s',
                              consts.status_label(status))
    elseif previous.status ~= status then
        title = string.format('General status %s -> %s',
                              consts.status_label(previous.status),
                              consts.status_label(status))
    else
        -- nothing has changed since the last message
        return 0
    end

    local msg = {
        Timestamp = read_message('Timestamp'),
        Type = 'gse_afd_notification',
        Payload = payload,
        Severity = utils.label_to_severity_map.INFO,
        Hostname = hostname,
        Fields = {
            alarm_source = alarm_source,
            object = object,
            source = 'gse_afd_tcp_notifier',
            title = title,
            type = type
        }
    }
    utils.inject_tags(msg)

    -- store the last status for future messages
    previous.status = status

    return utils.safe_inject_message(msg)
end
