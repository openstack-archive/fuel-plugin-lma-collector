#    Copyright 2015 Mirantis, Inc.
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
require 'spec_helper'

describe 'lma_collector::gse_policies' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with some policies' do
        yaml_policies =<<EOS
highest_severity:
  - status: down
    trigger:
      logical_operator: or
      rules:
        - function: count
          arguments: [ down ]
          relational_operator: '>'
          threshold: 0
  - status: critical
    trigger:
      logical_operator: or
      rules:
        - function: count
          arguments: [ critical ]
          relational_operator: '>'
          threshold: 0
  - status: warning
    trigger:
      logical_operator: or
      rules:
        - function: count
          arguments: [ warning ]
          relational_operator: '>'
          threshold: 0
  - status: okay
    trigger:
      logical_operator: or
      rules:
        - function: count
          arguments: [ okay ]
          relational_operator: '>'
          threshold: 0
  - status: unknown
EOS
        let(:params) do {
           :policies => YAML.load(yaml_policies)
        }
        end

        it { is_expected.to contain_file('gse_policies') }
    end
end
