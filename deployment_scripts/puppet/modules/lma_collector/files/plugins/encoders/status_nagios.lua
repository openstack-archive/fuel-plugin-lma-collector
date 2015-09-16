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

local host = read_config('nagios_host')
local data = {
   cmd_typ = '30',
   cmd_mod = '2',
   host    = host,
   service = nil,
   plugin_state = nil,
   plugin_output = nil,
   performance_data = '',
}
local nagios_break_line = '\\n'

function url_encode(str)
  if (str) then
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

function process_message()
    local service = read_message('Fields[service]')
    local service_name = read_config(service)
    if not service_name then
        return -1
    end
    local status = read_message('Fields[status]')
    local payload = read_message('Payload')
    data['service'] = service_name
    data['plugin_state'] = status
    local ok, details = pcall(cjson.decode, payload)
    if not ok or not details then details = {'no detail'} end
    local title = string.format('%s %s',
                                service_name,
                                utils.global_status_to_label_map[status])
    table.insert(details, 1, title)
    data['plugin_output'] = table.concat(details, nagios_break_line)
    data['btnSubmit'] = 'Commit'

    local params = {}
    for k, v in pairs(data) do
        params[#params+1] = string.format("%s=%s", k, url_encode(v))
    end
    local p = table.concat(params, '&')
    inject_payload('txt', 'nagios', p)

   return 0
end
