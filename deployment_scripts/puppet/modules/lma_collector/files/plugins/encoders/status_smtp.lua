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

require 'table'
require 'string'
require 'cjson'
local utils = require 'lma_utils'

function process_message()
    local service = read_message('Fields[service]')
    local status = read_message('Fields[status]')
    local previous_status = read_message('Fields[previous_status]')

    local payload = read_message('Payload')
    local ok, details = pcall(cjson.decode, payload)
    if not ok or not details then
        details = {'no detail'}
    end
    local title
    if status ~= previous_status then
        title = string.format('%s status %s -> %s',
                              service,
                              utils.global_status_to_label_map[previous_status],
                              utils.global_status_to_label_map[status])
    else
        title = string.format('%s status remains %s',
                              service,
                              utils.global_status_to_label_map[status])
    end
    table.insert(details, 1, title)
    local text = table.concat(details, '\n')
    inject_payload('txt', '', text)

    return 0
end
