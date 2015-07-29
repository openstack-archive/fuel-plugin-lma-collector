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
    ["compute.instance.create.end"] = "openstack.nova.instance_creation_time",
    ["volume.create.end"] = "openstack.cinder.volume_creation_time",
}

function process_message ()
    local metric_name = event_type_to_name[read_message("Fields[event_type]")]
    if not metric_name then
        return -1
    end

    local created_at = read_message("Fields[created_at]") or ''
    local launched_at = read_message("Fields[launched_at]") or ''

    created_at = patt.Timestamp:match(created_at)
    launched_at = patt.Timestamp:match(launched_at)
    if created_at == nil or launched_at == nil or created_at == 0 or launched_at == 0 or created_at > launched_at then
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
        -- that the created_at field has only a 1-second precision.
        value = {value = math.floor((launched_at - created_at)/1e6 + 0.5) / 1e3, representation = 's'},
        tenant_id = read_message("Fields[tenant_id]"),
        user_id = read_message("Fields[user_id]"),
    }
    utils.inject_tags(msg)

    inject_message(msg)
    return 0
end
