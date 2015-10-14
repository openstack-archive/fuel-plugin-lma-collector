require 'spec_helper'

describe 'sanitize_name_for_lua' do
    it { is_expected.not_to eq(nil) }
    it { is_expected.to run.with_params().and_raise_error(Puppet::ParseError, /wrong number of arguments/i) }
    it { is_expected.to run.with_params('un', 'deux').and_raise_error(Puppet::ParseError, /wrong number of arguments/i) }
    it { is_expected.to run.with_params('').and_return('')}
    it { is_expected.to run.with_params('one-two-three').and_return('one_two_three')}
end
