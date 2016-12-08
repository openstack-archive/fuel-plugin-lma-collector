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
require "string"
require "cjson"

local patt = require 'patterns'
local utils = require 'lma_utils'

local msg = {
    Timestamp = nil,
    Type = "notification",
    Payload = nil,
    Fields = nil
}

-- Mapping table from event_type prefixes to notification loggers
local logger_map = {
    --cinder
    volume = 'cinder',
    snapshot = 'cinder',
    -- glance
    image = 'glance',
    -- heat
    orchestration = 'heat',
    -- keystone
    identity = 'keystone',
    -- nova
    compute = 'nova',
    compute_task = 'nova',
    scheduler = 'nova',
    keypair = 'nova',
    -- neutron
    floatingip = 'neutron',
    security_group = 'neutron',
    security_group_rule = 'neutron',
    network = 'neutron',
    port = 'neutron',
    router = 'neutron',
    subnet = 'neutron',
    -- sahara
    sahara = 'sahara',
}

-- Mapping table between the attributes in the notification's payload and the
-- fields in the Heka message
local payload_fields = {
    -- all
    tenant_id = 'tenant_id',
    user_id = 'user_id',
    display_name = 'display_name',
    -- nova
    vcpus = 'vcpus',
    availability_zone = 'availability_zone',
    instance_id = 'instance_id',
    instance_type = 'instance_type',
    image_name = 'image_name',
    memory_mb = 'memory_mb',
    disk_gb = 'disk_gb',
    state = 'state',
    old_state = 'old_state',
    old_task_state = 'old_task_state',
    new_task_state = 'new_task_state',
    created_at = 'created_at',
    launched_at = 'launched_at',
    deleted_at = 'deleted_at',
    terminated_at = 'terminated_at',
    -- neutron
    network_id = 'network_id',
    subnet_id = 'subnet_id',
    port_id = 'port_id',
    -- cinder
    volume_id = 'volume_id',
    size = 'size',
    status = 'state',
    replication_status = 'replication_status',
}

function normalize_uuid(uuid)
    return patt.Uuid:match(uuid)
end

-- Mapping table defining transformation functions to be applied, keys are the
-- attributes in the notification's payload and values are Lua functions
local transform_functions = {
    created_at = utils.format_datetime,
    launched_at = utils.format_datetime,
    deleted_at = utils.format_datetime,
    terminated_at = utils.format_datetime,
    user_id = normalize_uuid,
    tenant_id = normalize_uuid,
    instance_id = normalize_uuid,
    network_id = normalize_uuid,
    subnet_id = normalize_uuid,
    port_id = normalize_uuid,
    volume_id = normalize_uuid,
}

local include_full_notification = read_config("include_full_notification") or false

function process_message ()
    local data = read_message("Payload")
    local ok, notif = pcall(cjson.decode, data)
    if not ok then
        return -1, string.format("Failed to parse notification: %s: '%s'", notif, string.sub(data or 'N/A', 1, 64))
    end

    local oslo_version = notif['oslo.version']
    if oslo_version then
        -- messagingv2 notifications
        ok, notif = pcall(cjson.decode, notif['oslo.message'])
        if not ok then
            return -1, string.format("Failed to parse v%s notification: %s: '%s'", oslo_version, notif, string.sub(data or 'N/A', 1, 64))
        end
    end

    if include_full_notification then
        msg.Payload = data
    else
        msg.Payload = utils.safe_json_encode(notif.payload) or '{}'
    end

    msg.Fields = {}
    msg.Logger = logger_map[string.match(notif.event_type, '([^.]+)')]
    msg.Severity = utils.label_to_severity_map[notif.priority]
    msg.Timestamp = patt.Timestamp:match(notif.timestamp)
    msg.Fields.publisher, msg.Hostname = string.match(notif.publisher_id, '([^.]+)%.([%w_-]+)')
    if notif.payload.host ~= nil then
        msg.Hostname = string.match(notif.payload.host, '([%w_-]+)')
    end

    msg.Fields.event_type = notif.event_type
    msg.Fields.severity_label = notif.priority
    msg.Fields.hostname = msg.Hostname

    for k, v in pairs(payload_fields) do
        local val = notif.payload[k]
        if val ~= nil then
            local name = payload_fields[k] or k
            local transform = transform_functions[k]
            if transform ~= nil then
                msg.Fields[name] = transform(val)
            else
                msg.Fields[name] = val
            end
        end
    end
    utils.inject_tags(msg)

    return utils.safe_inject_message(msg)
end
