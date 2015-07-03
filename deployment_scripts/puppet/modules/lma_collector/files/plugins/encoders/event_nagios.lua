require 'table'
require 'string'
require 'cjson'
local utils = require 'lma_utils'

local host = read_config('nagios_host') or 'localhost'

local data = {
   cmd_typ = '30',
   cmd_mod = '2',
   host    = host,
   service = nil,
   plugin_state = nil,
   plugin_output = nil,
   performance_data = '',
}

function url_encode(str)
  if (str) then
    str = string.gsub (str, "([^%w %-%_%.%~])",
        function (c) return string.format ("%%%02X", string.byte(c)) end)
    str = string.gsub (str, " ", "+")
  end
  return str
end

local nagios_break_line = '\\n'

function process_message()
    local ok, event = pcall(cjson.decode, read_message("Payload"))
    if not ok then return -1 end

    if event.type == utils.event_type_map.STATUS or
       event.type == utils.event_type_map.STATUS_TRANSITION or
       event.type == utils.event_type_map.STATUS_IDENTICAL_WITH_CHANGES then

    data['service'] = read_config(event.name) or '????'
    data['plugin_state'] = event.status or 0 -- UNKNOWN
    if #event.events > 0 then
        local text = table.concat(event.events, nagios_break_line)
        data['plugin_output'] =  event.title .. nagios_break_line .. text
    else
        data['plugin_output'] =  event.title
    end

    local params = {}
    for k, v in pairs(data) do
        params[#params+1] = string.format("%s=%s", k, url_encode(v))
    end
    local p = table.concat(params, '&')
    inject_payload('txt', 'nagios', p)

    end

   return 0
end
