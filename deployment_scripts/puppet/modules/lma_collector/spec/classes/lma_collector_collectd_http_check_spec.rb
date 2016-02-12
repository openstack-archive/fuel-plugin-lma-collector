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
require 'spec_helper'

describe 'lma_collector::collectd::http_check' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :concat_basedir => '/foo'}
    end

    describe 'urls with return codes' do
        let(:params) do
            {:urls => {
                'vip_test' => 'http://foo.com:99',
                'vip_foo' => 'http://bar.com:9200',
                'vip_bar' => 'https://ok.com',
            },
            :expected_codes => {
                'vip_test' => 401,
                'vip_foo' => 204,
            },
            :timeout => 5,
            :max_retries => 1,
            }
        end
        it { is_expected.to contain_lma_collector__collectd__python('http_check') \
             .with_config({
                            'Url' => {
                                '"vip_test"' => '"http://foo.com:99"',
                                '"vip_foo"' => '"http://bar.com:9200"',
                                '"vip_bar"' => '"https://ok.com"',
                            },
                            'ExpectedCode' => {
                                '"vip_test"' => '"401"',
                                '"vip_foo"' => '"204"',
                            },
                            'Timeout' => '"5"',
                            'MaxRetries' => '"1"',
                          })
        }
        it { is_expected.to contain_file('/etc/collectd/conf.d/python-config.conf') }
        it { is_expected.to contain_concat__fragment('collectd_plugin_python_conf_http_check') \
             .with_content(/Url "vip_test" "http:\/\/foo.com:99"/) \
             .with_content(/Url "vip_foo" "http:\/\/bar.com:9200"/) \
             .with_content(/Url "vip_bar" "https:\/\/ok.com"/) \
             .with_content(/ExpectedCode "vip_test" "401"/) \
             .with_content(/ExpectedCode "vip_foo" "204"/) \
             .with_content(/Timeout "5"/) \
             .with_content(/MaxRetries "1"/)
        }
    end

    describe 'urls without expected codes' do
        let(:params) do
            {:urls => {
                'vip_bar' => 'https://ok.com',
            },
            }
        end
        it { is_expected.to contain_lma_collector__collectd__python('http_check') \
             .with_config({
                            'Url' => {
                                '"vip_bar"' => '"https://ok.com"',
                            },
                            'ExpectedCode' => {},
                            'Timeout' => '"1"',
                            'MaxRetries' => '"3"',
                          })
        }
        it { is_expected.to contain_file('/etc/collectd/conf.d/python-config.conf') }
        it { is_expected.to contain_concat__fragment('collectd_plugin_python_conf_http_check') \
             .with_content(/Url "vip_bar" "https:\/\/ok.com"/) \
             .without_content(/ExpectedCode/)
        }
    end
    describe 'urls with Dependancy' do
        let(:params) do
            {:urls => {
                'vip_bar' => 'https://ok.com',
            },
            :pacemaker_master_resource => 'vip__foobar',
            }
        end
        it { is_expected.to contain_lma_collector__collectd__python('http_check') \
             .with_config({
                            'Url' => {
                                '"vip_bar"' => '"https://ok.com"',
                            },
                            'ExpectedCode' => {},
                            'Timeout' => '"1"',
                            'MaxRetries' => '"3"',
                            'DependsOnResource' => '"vip__foobar"',
                          })
        }
        it { is_expected.to contain_file('/etc/collectd/conf.d/python-config.conf') }
        it { is_expected.to contain_concat__fragment('collectd_plugin_python_conf_http_check') \
             .with_content(/Url "vip_bar" "https:\/\/ok.com"/) \
             .without_content(/ExpectedCode/) \
             .with_content(/DependsOnResource "vip__foobar"/)
        }
    end
end

