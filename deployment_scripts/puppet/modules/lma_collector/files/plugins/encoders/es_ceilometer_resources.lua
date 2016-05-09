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
local elasticsearch = require "elasticsearch"

local index = read_config("index") or "index"
local type_name = read_config("type_name") or "message"

function process_message()
    local ns
    local resources = cjson.decode(read_message("Payload"))
    for resource_id, resource in pairs(resources) do
        local update = cjson.encode({update = {_index = index, _type = type_name,
            _id = resource_id}})
        local body = {
            script = 'ctx._source.meters += meter;' ..
            'ctx._source.user_id = user_id;' ..
            'ctx._source.project_id = project_id;' ..
            'ctx._source.source = source; ' ..
            'ctx._source.metadata =  ' ..
            'ctx._source.last_sample_timestamp <= timestamp ? ' ..
            'metadata : ctx._source.metadata;' ..
            'ctx._source.last_sample_timestamp = ' ..
            'ctx._source.last_sample_timestamp < timestamp ?' ..
            'timestamp : ctx._source.last_sample_timestamp;' ..
            'ctx._source.first_sample_timestamp = ' ..
            'ctx._source.first_sample_timestamp > timestamp ?' ..
            'timestamp : ctx._source.first_sample_timestamp;',
            params = {
                meter = resource.meter,
                metadata = resource.metadata,
                timestamp = resource.timestamp,
                user_id = resource.user_id or '',
                project_id = resource.project_id or '',
                source = resource.source or '',
            },
            upsert = {
                first_sample_timestamp = resource.timestamp,
                last_sample_timestamp = resource.timestamp,
                project_id = resource.project_id or '',
                user_id = resource.user_id or '',
                source = resource.source or '',
                metadata = resource.metadata,
                meters = resource.meter
            }
        }
        body = cjson.encode(body)

        add_to_payload(update, "\n", body, "\n")
    end

    inject_payload()
    return 0
end
