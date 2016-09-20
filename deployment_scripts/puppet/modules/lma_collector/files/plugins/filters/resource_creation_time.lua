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
require 'math'
local patt = require 'patterns'
local utils = require 'lma_utils'

local msg = {
    Type = "metric", -- will be prefixed by "heka.sandbox."
    Timestamp = nil,
    Severity = 6,
}

local event_type_to_name = {
    ["compute.instance.create.end"] = "openstack_nova_instance_creation_time",
    ["volume.create.end"] = "openstack_cinder_volume_creation_time",
    ["volume.attach.end"] = "openstack_cinder_volume_attachment_time",
}

function process_message ()
    local metric_name = event_type_to_name[read_message("Fields[event_type]")]
    if not metric_name then
        return -1
    end

    local started_at, completed_at

    if metric_name == "openstack_cinder_volume_attachment_time" then
        --[[ To compute the metric we need fields that are not available
          directly in the Heka message. So we need to decode the message,
          check if it is a full notification or not and extract the needed
          values. ]]--
        local data = read_message("Payload")
        local ok, notif = pcall(cjson.decode, data)
        if not ok then
          return -1
        end

        notif = notif.payload or notif
        local t = unpack(notif['volume_attachment'])
        started_at   = t.created_at or ''
        completed_at = t.attach_time or ''
    else
        started_at = read_message("Fields[created_at]") or ''
        completed_at = read_message("Fields[launched_at]") or ''
    end

    started_at = patt.Timestamp:match(started_at)
    completed_at = patt.Timestamp:match(completed_at)
    if started_at == nil or completed_at == nil or started_at == 0 or completed_at == 0 or started_at > completed_at then
        return -1
    end

    msg.Timestamp = read_message("Timestamp")
    msg.Fields = {
        source = read_message('Logger'),
        name = metric_name,
        -- preserve the original hostname in the Fields attribute because
        -- sandboxed filters cannot override the Hostname attribute
        hostname = read_message("Fields[hostname]"),
        type = utils.metric_type['GAUGE'],
        -- Having a millisecond precision for creation time is good enough given
        -- that the started_at field has only a 1-second precision.
        value = {value = math.floor((completed_at - started_at)/1e6 + 0.5) / 1e3, representation = 's'},
        tenant_id = read_message("Fields[tenant_id]"),
        user_id = read_message("Fields[user_id]"),
    }
    utils.inject_tags(msg)

    return utils.safe_inject_message(msg)
end
