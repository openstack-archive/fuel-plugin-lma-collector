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

local msg_type = read_config('msg_type') or error('msg_type must be defined')

local msg = {
    Type = msg_type,
    Severity = 7, -- debug
    Payload = nil,
    Fields = nil,
}

function process_message ()
    inject_message(msg)

    return 0
end
