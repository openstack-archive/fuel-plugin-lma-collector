-- Copyright 2016 Mirantis, Inc.
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
require 'table'
require 'math'

local patt = require 'patterns'
local utils = require 'lma_utils'
local l = require 'lpeg'
l.locale(l)

function normalize_uuid(uuid)
    return patt.Uuid:match(uuid)
end

-- the metadata_fields parameter is a list of words separated by space
local fields_grammar = l.Ct((l.C((l.P(1) - l.P" ")^1) * l.P" "^0)^0)
local metadata_fields = fields_grammar:match(
    read_config("metadata_fields") or ""
)

local decode_resources = read_config('decode_resources') or false

local sample_msg = {
    Timestamp = nil,
    -- This message type has the same structure than 'bulk_metric'.
    Type = "ceilometer_samples",
    Payload = nil
}

local resource_msg = {
    Timestamp = nil,
    Type = "ceilometer_resource",
    Fields = nil,
}

function inject_metadata(metadata, tags)
    local value
    for _, field in ipairs(metadata_fields) do
        value = metadata[field]
        if value ~= nil and type(value) ~= 'table' then
            tags["metadata." .. field] = value
        end
    end
end

function add_resource_to_payload(sample, payload)

    local resource_data = {
        timestamp = sample.timestamp,
        resource_id = sample.resource_id,
        source = sample.source or "",
        metadata = sample.resource_metadata,
        user_id = sample.user_id,
        project_id = sample.project_id,
        meter = {
            [sample.counter_name] = {
                type = sample.counter_type,
                unit = sample.counter_unit
            }
        }
    }
    payload[sample.resource_id] = resource_data
end


function add_sample_to_payload(sample, payload)
    local sample_data = {
        name='sample',
        timestamp = patt.Timestamp:match(sample.timestamp),
        values = {
            value = sample.counter_volume,
            message_id = sample.message_id,
            recorded_at = sample.recorded_at,
            timestamp = sample.timestamp,
            message_signature = sample.signature,
            type = sample.counter_type,
            unit = sample.counter_unit
        }
    }
    local tags = {
        meter = sample.counter_name,
        resource_id = sample.resource_id,
        project_id = sample.project_id ,
        user_id = sample.user_id,
        source = sample.source
    }

    inject_metadata(sample.resource_metadata or {}, tags)
    sample_data["tags"] = tags
    table.insert(payload, sample_data)
end

function process_message ()
    local data = read_message("Payload")
    local ok, message = pcall(cjson.decode, data)
    if not ok then
        return -1, "Cannot decode Payload"
    end
    local ok, message_body = pcall(cjson.decode, message["oslo.message"])
    if not ok then
        return -1, "Cannot decode Payload[oslo.message]"
    end
    local sample_payload = {}
    local resource_payload = {}
    for _, sample in ipairs(message_body["payload"]) do
        add_sample_to_payload(sample, sample_payload)
        if decode_resources then
            add_resource_to_payload(sample, resource_payload)
        end
    end
    sample_msg.Payload = cjson.encode(sample_payload)
    sample_msg.Timestamp = patt.Timestamp:match(message_body.timestamp)
    utils.safe_inject_message(sample_msg)

    if decode_resources then
        resource_msg.Payload = cjson.encode(resource_payload)
        resource_msg.Timestamp = patt.Timestamp:match(message_body.timestamp)
        utils.safe_inject_message(resource_msg)
    end

    return 0
end
