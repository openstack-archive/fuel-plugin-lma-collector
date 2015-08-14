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

local payload_name = read_config('payload_name') or error('payload_name is required')
local payload = read_config('payload')

-- Very simple filter that emits a fixed message or the current timestamp (in
-- second) every ticker interval. It can be used to check the liveness of the
-- Heka service.
function timer_event(ns)
   inject_payload("txt", payload_name, payload or math.floor(ns / 1e9))
end
