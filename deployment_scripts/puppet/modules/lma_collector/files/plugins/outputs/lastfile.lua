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
require "io"

local path = read_config('path') or error('path required')
local field = read_config('field') or 'Payload'

-- Very simple output sandbox that writes the value of one of the message's
-- fields ('Payload' by default) to a file.
function process_message()
    local fh = io.open(path, "w")
    io.output(fh)
    io.write(read_message(field))
    io.close()
    return 0
end
