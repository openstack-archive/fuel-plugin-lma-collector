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

local afd = require 'afd'
local consts = require 'gse_constants'

local check_api_states = {}

-- emit AFD event metrics based on the check_api metrics
-- TODO(spasquier): check for all types of endpoints (eg public, internal and admin)
function process_message()
    local metric_name = read_message('Fields[name]')
    local value = read_message('Fields[value]')
    local service = read_message('Fields[service]') .. '-endpoint'
    local state = consts.OKAY

    check_api_states[service] = value

    if value == 0 then
        state = consts.DOWN
        afd.add_to_alarms(consts.DOWN,
                          'last',
                          metric_name,
                          '==',
                          0,
                          nil,
                          nil,
                          string.format("Endpoint check for service %s is failed", service))
    end

    afd.inject_afd_service_event(service, state, 0, 'afd_api_endpoint')
    return 0
end
