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
require "circular_buffer"
require "string"
local alert         = require "alert"
local annotation    = require "annotation"
local anomaly       = require "anomaly"

local title             = "Severity stats"
local rows              = read_config("rows") or 1440
local sec_per_row       = read_config("sec_per_row") or 60 -- message count per minute
local anomaly_config    = anomaly.parse_config(read_config("anomaly_config"))
annotation.set_prune(title, rows * sec_per_row * 1e9)

cbuf = circular_buffer.new(rows, 3, sec_per_row)

local INFO = cbuf:set_header(1, "INFO and lower", "count")
local WARNING = cbuf:set_header(2, "WARNING", "count")
local ERROR = cbuf:set_header(3, "ERROR and higher", "count")

local severity_to_cbuf_index = {
[0] = ERROR,
[1] = ERROR,
[2] = ERROR,
[3] = ERROR,
[4] = WARNING,
[5] = INFO,
[6] = INFO ,
[7] = INFO,
}

function process_message ()
    local ts = read_message("Timestamp")
    local severity = read_message("Severity")
    cbuf:add(ts, severity_to_cbuf_index[severity], 1)
    return 0
end

function timer_event(ns)
    if anomaly_config then
        if not alert.throttled(ns) then
            local msg, annos = anomaly.detect(ns, title, cbuf, anomaly_config)
            if msg then
                annotation.concat(title, annos)
                alert.send(ns, msg)
            end
        end
        inject_payload("cbuf", title, annotation.prune(title, ns), cbuf)
    else
        inject_payload("cbuf", title, cbuf)
    end
end
