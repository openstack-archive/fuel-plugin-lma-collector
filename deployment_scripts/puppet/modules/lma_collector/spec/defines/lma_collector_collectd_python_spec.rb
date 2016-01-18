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

describe 'lma_collector::collectd::python' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :concat_basedir => '/foo'}
    end

    describe 'with title = haproxy' do
        let(:title) { :haproxy }
        let(:params) {{:config => {"Foo" => "Bar"}}}
        it { is_expected.to contain_collectd__plugin__python__module('module_haproxy') \
             .with_module('haproxy') \
             .with_modulepath('/usr/lib/collectd') \
             .with_config({"Foo" => "Bar"}) }
    end

    describe 'with complex config' do
        let(:title) { :haproxy }
        let(:params) do
            {:config => {"key1" => ["elt0", "elt1"],
                         "key2" => {"k1" => "v1", "k2" => "v2"}}}
        end
        it { is_expected.to contain_collectd__plugin__python__module('module_haproxy') \
             .with_module('haproxy') \
             .with_modulepath('/usr/lib/collectd') \
             .with_config({"key1 elt0" => "", "key1 elt1" => "",
                           "key2 k1" => "v1", "key2 k2" => "v2"}) }
    end
end
