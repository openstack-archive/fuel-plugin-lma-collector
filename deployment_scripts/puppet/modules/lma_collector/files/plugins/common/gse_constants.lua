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

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

OKAY="okay"
WARN="warn"
CRIT="crit"
DOWN="down"
UNKW="unkw"

-- for consistency, numerical statuses are mapped to Nagios states
NUMERICAL_STATUS = {
    [OKAY]=0,
    [WARN]=1,
    [CRIT]=2,
    [UNKW]=3,
    [DOWN]=4
}

return M
