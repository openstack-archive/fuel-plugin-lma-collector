#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
class lma_collector::collectd::check_local_endpoint (
  $urls,
  $expected_codes = {},
  $timeout = 1,
  $max_retries = 3,
) {

  validate_hash($urls)
  validate_hash($expected_codes)
  validate_integer($timeout)
  validate_integer($max_retries)

  # Add quotes around the hash keys and values
  $urls_keys = suffix(prefix(keys($urls), '"'), '"')
  $urls_values = suffix(prefix(values($urls), '"'), '"')
  $real_urls= hash(flatten(zip($urls_keys, $urls_values)))
  if ! empty($expected_codes) {
    $expected_codes_keys = suffix(prefix(keys($expected_codes), '"'), '"')
    $expected_codes_values = suffix(prefix(values($expected_codes), '"'), '"')
    $real_expected_codes= hash(flatten(zip($expected_codes_keys, $expected_codes_values)))
  } else {
    $real_expected_codes= {}
  }

  lma_collector::collectd::python { 'check_local_endpoint':
    config => {
      'Url'          => $real_urls,
      'ExpectedCode' => $real_expected_codes,
      'Timeout'      => "\"${timeout}\"",
      'MaxRetries'   => "\"${max_retries}\"",
    },
  }
}
