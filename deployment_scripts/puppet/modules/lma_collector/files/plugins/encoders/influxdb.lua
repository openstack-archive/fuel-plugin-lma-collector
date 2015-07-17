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
require 'field_util'
local string = require 'string'
local table = require 'table'

local tag_fields = field_util.field_map(read_config("tag_fields") or "")
local default_tenant_id = read_config("default_tenant_id") or error("default_tenant_id must be specified")
local default_user_id = read_config("default_user_id") or error("default_user_id must be specified")

local defaults = {
    tenant_id=default_tenant_id,
    user_id=default_user_id,
}

function escape_string(str)
    return tostring(str):gsub("([ ,])", "\\%1")
end

function encode_tag(msg, tag, default_value)
    local value
    if msg.Fields[tag] and msg.Fields[tag] == '' then
        value = msg.Fields[tag]
    elseif default_value ~= nil then
        value = default_value
    else
            return nil
    end
    return escape_string(tag) .. '=' .. escape_string(value)
end

-- TODO(pasquier-s): support messages with multiple points
-- TODO(pasquier-s): support points with multiple fields
-- TODO(pasquier-s): support string values for fields
function process_message()
    local msg = decode_message(read_message("raw"))
    local point
    local value
    local tags = {}

    -- Append common tags
    for _, tag in ipairs(tag_fields) do
        local t = encode_tag(msg, tag, defaults[tag])
        if t then
            table.insert(tags, t)
        end
    end

    -- Append specific tags
    if msg.tag_fields then
        for _, tag in ipairs(msg.tag_fields) do
            local t = encode_tag(msg, tag)
            if t then
                table.insert(tags, t)
            end
        end
    end

    if type(value) == "string" then
        value = '"' .. value:gsub('"', '\\"') .. '"'
    elseif type(value) == "number" or string.match(value, "^[%d.]+$") then
        -- Always send numbers as formatted floats, so InfluxDB will accept
        -- them if they happen to change from ints to floats between
        -- points in time.  Forcing them to always be floats avoids this.
        value = string.format("%.6f", value)
    end

    if #tags > 0 then
        point = string.format("%,%s value=%s %d\n",
            escape_string(msg.Fields.name),
            table.concat(tags, ','),
            string.format("%.6f", msg.Fields.value),
            field_util.message_timestamp('m'))
    else
        point = string.format("% value=%s %d\n",
            escape_string(msg.Fields.name),
            string.format("%.6f", msg.Fields.value),
            field_util.message_timestamp('m'))
    end

    inject_payload("txt", "influx_line", point)
    return 0
end
