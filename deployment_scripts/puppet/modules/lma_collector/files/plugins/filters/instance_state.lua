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
local utils = require 'lma_utils'

local msg = {
    Type = "metric", -- will be prefixed by "heka.sandbox."
    Timestamp = nil,
    Severity = 6,
}

count = 0

function process_message ()
    local state = read_message("Fields[state]")
    local old_state = read_message("Fields[old_state]")
    if old_state ~= nil and state == old_state then
        -- nothing to do
        return 0
    end
    msg.Timestamp = read_message("Timestamp")
    msg.Fields = {
        source = read_message('Logger'),
        name = "openstack_nova_instance_state",
        -- preserve the original hostname in the Fields attribute because
        -- sandboxed filters cannot override the Hostname attribute
        hostname = read_message("Fields[hostname]"),
        type = utils.metric_type['COUNTER'],
        value = 1,
        tenant_id = read_message("Fields[tenant_id]"),
        user_id = read_message("Fields[user_id]"),
        state = state,
        tag_fields = { 'state' },
    }
    utils.inject_tags(msg)

    return utils.safe_inject_message(msg)
end
