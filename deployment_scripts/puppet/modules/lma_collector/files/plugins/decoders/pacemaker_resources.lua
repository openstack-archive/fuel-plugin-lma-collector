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
local l = require 'lpeg'
local utils = require 'lma_utils'
l.locale(l)

local msg = {
    Timestamp = nil,
    Type = "metric",
    Payload = nil,
    Severity = 6, -- INFO
    Fields = nil
}

local word = (l.R("az", "AZ", "09") + l.P"." + l.P"_" + l.P"-")^1
local grammar = l.Ct(l.Cg(word, 'resource') * " " * l.Cg(l.xdigit, 'active'))

function process_message ()
    local data = read_message("Payload")
    local m = grammar:match(data)
    if not m then
        return -1
    end
    msg.Timestamp = read_message("Timestamp")
    msg.Payload = data
    msg.Fields = {}
    msg.Fields.source = 'pacemaker'
    msg.Fields.type = utils.metric_type['GAUGE']
    msg.Fields.hostname = read_message('Hostname')
    utils.inject_tags(msg)

    msg.Fields.name= string.format('pacemaker.resource.%s.active', m.resource)
    msg.Fields.value = tonumber(m.active)
    return utils.safe_inject_message(msg)
end
