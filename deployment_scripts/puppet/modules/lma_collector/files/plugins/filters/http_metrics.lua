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
require 'string'
local utils = require 'lma_utils'

local msg = {
    Type = "metric", -- will be prefixed by "heka.sandbox."
    Timestamp = nil,
    Severity = 6,
    Fields = nil
}

function process_message ()
    local http_method = read_message("Fields[http_method]")
    local http_status = read_message("Fields[http_status]")
    local response_time = read_message("Fields[http_response_time]")

    if http_method == nil or http_status == nil or response_time == nil then
        return -1
    end

    -- keep only the first 2 tokens because some services like Neutron report
    -- themselves as 'openstack.<service>.server'
    local service = string.gsub(read_message("Logger"), '(%w+)%.(%w+).*', '%1_%2')

    msg.Timestamp = read_message("Timestamp")
    msg.Fields = {
        hostname = read_message("Hostname"),
        source = read_message('Fields[programname]') or service,
        name = service .. '_http_responses',
        type = utils.metric_type['GAUGE'],
        value = {value = response_time, representation = 's'},
        tenant_id = read_message('Fields[tenant_id]'),
        user_id = read_message('Fields[user_id]'),
        http_method = http_method,
        http_status = http_status,
        tag_fields = {'http_method', 'http_status'},
    }
    utils.inject_tags(msg)
    return utils.safe_inject_message(msg)
end
