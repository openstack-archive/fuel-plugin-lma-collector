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
#
module Puppet::Parser::Functions
  newfunction(:validate_buffering, :doc => <<-'ENDHEREDOC') do |args|
      Validate that the parameters used for buffering are consistent.

      The function takes 3 arguments:
      - max_buffer_size
      - max_file_size
      - full_action

      In practice, max_buffer_size must be greater than max_file_size.

      The following values will pass:

        $max_buffer_size = 2048
        $max_file_size = 1024
        validate_buffering($max_buffer_size, $max_file_size, 'drop')

      The following values will fail:

        $max_buffer_size = 1024
        $max_file_size = 2048
        validate_buffering($max_buffer_size, $max_file_size, 'drop')

        $max_buffer_size = 2048
        $max_file_size = 1024
        validate_buffering($max_buffer_size, $max_file_size, 'foo')

    ENDHEREDOC

    unless args.length == 3 then
        raise Puppet::ParseError, ("validate_buffering(): wrong number of arguments (#{args.length}; must be 3)")
    end

    unless args[0].to_s =~ /^\d+$/ then
        raise Puppet::ParseError, ("validate_buffering(): bad argument (#{args[0]}}; must be integer)")
    end
    max_buffer_size = args[0].to_i

    # When passing undef as args[1], it will be seen as the empty string and
    # evaluated as 0 which means no limit
    unless args[1].to_s =~ /^\d*$/ then
        raise Puppet::ParseError, ("validate_buffering(): bad argument (#{args[0]}}; must be integer)")
    end
    max_file_size = args[1].to_i
    max_file_size = 512 * 1024 * 1024 if max_file_size == 0

    if max_buffer_size > 0 and max_buffer_size < max_file_size then
        raise(Puppet::ParseError, "validate_buffering(): max_buffer_size (" +
            "#{max_buffer_size}) should be greater than max_file_size (#{max_file_size})")
    end

    unless ["drop", "shutdown", "block"].include?(args[2]) then
        raise(Puppet::ParseError, "validate_buffering(): full_action (" +
            "#{args[2]}) should be either drop, shutdown or block")
    end
  end
end
