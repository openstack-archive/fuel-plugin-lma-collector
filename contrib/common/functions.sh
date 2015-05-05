#!/bin/bash
# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

function docker_pull_image {
    if [[ $(docker images -q "${1}") == "" ]]; then
        docker pull "${1}"
    fi
}

function docker_get_id {
    docker inspect --format="{{ .Id }}" "${1}" 2>/dev/null
}

function docker_is_running {
    local IS_RUNNING
    IS_RUNNING=$(docker inspect --format="{{ .State.Running }}" "${1}" 2>/dev/null)
    [[ "${IS_RUNNING}" == "true" ]]
}

function docker_shorten_id {
    echo "${1}" | cut -c 1-12
}
