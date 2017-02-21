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

EXPORT_ASSERT_TO_GLOBALS=true
require('luaunit')
require('os')
package.path = package.path .. ";files/plugins/common/?.lua;tests/lua/mocks/?.lua"

local patt = require('patterns')
local l = require('lpeg')

TestPatterns = {}

    function TestPatterns:test_Uuid()
        assertEquals(patt.Uuid:match('be6876f2-c1e6-42ea-ad95-792a5500f0fa'),
                                     'be6876f2-c1e6-42ea-ad95-792a5500f0fa')
        assertEquals(patt.Uuid:match('be6876f2c1e642eaad95792a5500f0fa'),
                                     'be6876f2-c1e6-42ea-ad95-792a5500f0fa')
        assertEquals(patt.Uuid:match('ze6876f2c1e642eaad95792a5500f0fa'),
                                     nil)
        assertEquals(patt.Uuid:match('be6876f2-c1e642eaad95792a5500f0fa'),
                                     nil)
    end

    function TestPatterns:test_Timestamp()
        -- note that Timestamp:match() returns the number of nanosecs since the
        -- Epoch in the local timezone
        local_epoch = os.time(os.date("!*t",0)) * 1e9
        assertEquals(patt.Timestamp:match('1970-01-01 00:00:01+00:00'),
                                          local_epoch + 1e9)
        assertEquals(patt.Timestamp:match('1970-01-01 00:00:02'),
                                          local_epoch + 2e9)
        assertEquals(patt.Timestamp:match('1970-01-01 00:00:03'),
                                          local_epoch + 3e9)
        assertEquals(patt.Timestamp:match('1970-01-01T00:00:04-00:00'),
                                          local_epoch + 4e9)
        assertEquals(patt.Timestamp:match('1970-01-01 01:00:05+01:00'),
                                          local_epoch + 5e9)
        assertEquals(patt.Timestamp:match('1970-01-01 00:00:00.123456+00:00'),
                                          local_epoch + 0.123456 * 1e9)
        assertEquals(patt.Timestamp:match('1970-01-01 00:01'),
                                          nil)
    end

    function TestPatterns:test_programname()
        assertEquals(l.C(patt.programname):match('nova-api'), 'nova-api')
        assertEquals(l.C(patt.programname):match('nova-api foo'), 'nova-api')
    end

    function TestPatterns:test_anywhere()
        assertEquals(patt.anywhere(l.C(patt.dash)):match(' - '), '-')
        assertEquals(patt.anywhere(patt.dash):match(' . '), nil)
    end

    function TestPatterns:test_openstack()
        local_epoch = os.time(os.date("!*t",0)) * 1e9
        assertEquals(patt.openstack:match(
            '1970-01-01 00:00:02 3434 INFO oslo_service.periodic_task [-] Blabla...'),
            {Timestamp = local_epoch + 2e9, Pid = '3434', SeverityLabel = 'INFO',
             PythonModule = 'oslo_service.periodic_task', Message = '[-] Blabla...'})
    end

    function TestPatterns:test_openstack_request_context()
        assertEquals(patt.openstack_request_context:match('[-]'), nil)
        assertEquals(patt.openstack_request_context:match(
            "[req-4db318af-54c9-466d-b365-fe17fe4adeed - - - - -]"),
            {RequestId = '4db318af-54c9-466d-b365-fe17fe4adeed'})
        assertEquals(patt.openstack_request_context:match(
            "[req-4db318af-54c9-466d-b365-fe17fe4adeed 8206d40abcc3452d8a9c1ea629b4a8d0 112245730b1f4858ab62e3673e1ee9e2 - - -]"),
            {RequestId = '4db318af-54c9-466d-b365-fe17fe4adeed',
             UserId = '8206d40a-bcc3-452d-8a9c-1ea629b4a8d0',
             TenantId = '11224573-0b1f-4858-ab62-e3673e1ee9e2'})
    end

    function TestPatterns:test_openstack_http()
        assertEquals(patt.openstack_http:match(
            '"OPTIONS / HTTP/1.0" status: 200 len: 497 time: 0.0006731'),
            {http_method = 'OPTIONS', http_url = '/', http_version = '1.0',
             http_status = 200, http_response_size = 497,
             http_response_time = 0.0006731})
        assertEquals(patt.openstack_http:match(
            'foo "OPTIONS / HTTP/1.0" status: 200 len: 497 time: 0.0006731 bar'),
            {http_method = 'OPTIONS', http_url = '/', http_version = '1.0',
             http_status = 200, http_response_size = 497,
             http_response_time = 0.0006731})
    end

    function TestPatterns:test_openstack_http_with_extra_space()
        assertEquals(patt.openstack_http:match(
            '"OPTIONS / HTTP/1.0" status: 200  len: 497 time: 0.0006731'),
            {http_method = 'OPTIONS', http_url = '/', http_version = '1.0',
             http_status = 200, http_response_size = 497,
             http_response_time = 0.0006731})
        assertEquals(patt.openstack_http:match(
            'foo "OPTIONS / HTTP/1.0" status: 200  len: 497 time: 0.0006731 bar'),
            {http_method = 'OPTIONS', http_url = '/', http_version = '1.0',
             http_status = 200, http_response_size = 497,
             http_response_time = 0.0006731})
    end

    function TestPatterns:test_ip_address()
        assertEquals(patt.ip_address:match('192.168.1.2'),
            {ip_address = '192.168.1.2'})
        assertEquals(patt.ip_address:match('foo 192.168.1.2 bar'),
            {ip_address = '192.168.1.2'})
        assertEquals(patt.ip_address:match('192.1688.1.2'), nil)
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
