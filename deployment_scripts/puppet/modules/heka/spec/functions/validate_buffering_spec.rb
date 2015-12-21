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

describe 'validate_buffering' do
    it { is_expected.to run.with_params().and_raise_error(Puppet::ParseError, /wrong number of arguments/i) }
    it { is_expected.to run.with_params('foo', 'bar', 'drop').and_raise_error(Puppet::ParseError, /bad argument/i) }
    it { is_expected.to run.with_params(1024, 2048, 'drop').and_raise_error(Puppet::ParseError, /should be greater/i) }
    it { is_expected.to run.with_params(2048, 1024, 'foo').and_raise_error(Puppet::ParseError, /should be either/i) }
    it { is_expected.to run.with_params(0, '', 'shutdown') }
    it { is_expected.to run.with_params(2048, 1024, 'shutdown') }
    it { is_expected.to run.with_params(1024*1024*1024, 0, 'block') }
end
