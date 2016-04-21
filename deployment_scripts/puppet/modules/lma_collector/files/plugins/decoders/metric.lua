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

local deserialize_bulk_metric_for_loggers = read_config("deserialize_bulk_metric_for_loggers") or false

local utils = require 'lma_utils'

function process_message ()
    local msg = decode_message(read_message("raw"))
    if deserialize_bulk_metric_for_loggers and
       string.match(msg.Type, 'bulk_metric$') and
       string.match(msg.Logger, deserialize_bulk_metric_for_loggers) then

        local ok, metrics = pcall(cjson.decode, msg.Payload)
        if not ok then
            return -1
        end
        for _, metric in ipairs(metrics) do
            local fields = {}
            local metric_type
            if metric.value then
                metric_type = 'metric'
                fields['value'] = metric.value
            else
                metric_type = 'multivalue_metric'
                local value_fields = {}
                for k, v in pairs(metric.values) do
                    fields[k] = v
                    table.insert(value_fields, k)
                end
                fields['value_fields'] = value_fields
            end
            local tags = {}
            local tag_fields = {}
            for t, v in pairs(metric.tags or {}) do
                fields[t] = v
                table.insert(tag_fields, t)
            end
            fields['tag_fields'] = tag_fields
            fields['name'] = metric.name
            fields['hostname'] = msg.Hostname

            local new_msg = {
                Timestamp = msg.Timestamp,
                Hostname = msg.Hostname,
                Severity = msg.Severity,
                Logger = msg.Logger,
                Type = metric_type,
                Payload = '',
                Fields = fields,
            }

            utils.inject_tags(new_msg)
            ok, err = utils.safe_inject_message(new_msg)
            if ok ~= 0 then
                return -1, err
            end
        end
    else -- simple metric
        utils.inject_tags(msg)
        ok, err = utils.safe_inject_message(msg)
        if ok ~= 0 then
            return -1, err
        end
    end
    return 0
end

