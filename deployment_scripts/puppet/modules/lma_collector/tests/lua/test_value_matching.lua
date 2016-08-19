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
package.path = package.path .. ";files/plugins/common/?.lua;tests/lua/mocks/?.lua"
local M = require('value_matching')

TestValueMatching = {}

function TestValueMatching:test_simple_matching()
    local tests = {
        {'/var/log',        '/var/log'},
        {'== /var/log',     '/var/log'},
        {'==/var/log',      '/var/log'},
        {'==/var/log ',      '/var/log'},
        {'==\t/var/log',    '/var/log'},
        {'=="/var/log"',    '/var/log'},
        {'== "/var/log"',   '/var/log'},
        {'== " /var/log"',  ' /var/log'},
        {'== "/var/log "',  '/var/log '},
        {'== " /var/log "', ' /var/log '},
        {8,                 8},
        {8,                '8'},
        {"9",               "9"},
        {"==10",            " 10"},
        {"10",              10},
        {"== 10",           " 10"},
        {"== 10.0",         " 10.0"},
        {"== -10.01",       " -10.01"},
        {"== 10 ",          " 10 "},
        {' <=11',           '-11'},
        {"!= -12",          42},
        {"!= 12",           42},
        {" > 13",            42},
        {">= 13",           13},
        {">= -13",           42},
        {"< 14",            -0},
        {"<= 14 ",           0},
        {"<= 14",           "14"},
    }
    local r
    for _, v in ipairs(tests) do
        local exp, value = v[1], v[2]
        local m = M.new(exp)
        r = m:matches(value)
        assertTrue(r)
    end
end

function TestValueMatching:test_simple_not_matching()
    local tests = {
        {'/var/log',       '/var/log/mysql'},
        {'== "/var/log"'   , '/var/log '},
        {'"/var/log"',     '/var/log '},
        {'"/var/log "',    '/var/log'},
        {'nova-api',       'nova-compute'},
        {'== /var/log',    '/var/log/mysql'},
        {'==/var/log',     '/var/log/mysql'},
        {'!=/var/log',     '/var/log'},
        {'!= /var/log',    '/var/log'},
        {'>10',            '5'},
        {'> 10',           '5 '},
        {' <11',           '11'},
        {' >=11',          '-11'},
        {' >=11 && <= 42', '-11'},
        {' >=11 || == 42', '-11'},
    }

    for _, v in ipairs(tests) do
        local exp, value = v[1], v[2]
        local m = M.new(exp)
        r = m:matches(value)
        assertFalse(r)
    end
end

function TestValueMatching:test_string_matching()
    local tests = {
        {'== "foo.bar"', "foo.bar", true},
        {'== foo.bar', "foo.bar", true},
        {'== foo.bar ', "foo.bar", true},
        {'== foo || bar', "bar", true},
        {'== foo || bar', "foo", true},
        {'== foo || bar', "??", false},
        {'!= foo || != bar', "42", true},
    }

    for _, v in ipairs(tests) do
        local exp, value, expected = v[1], v[2], v[3]
        local m = M.new(exp)
        r = m:matches(value)
        assertEquals(r, expected)
    end

end

function TestValueMatching:test_invalid_expression()
    local tests = {
        '&& 1 && 1',
        ' && 1',
        '|| == 1',
        '&& != 12',
        ' ',
        '   ',
        '\t',
        '',
        nil,
    }
    for _, exp in ipairs(tests) do
        assertError(M.new, exp)
    end
end

function TestValueMatching:test_range_matching()
    local tests = {
        {'>= 200 && < 300', 200, true},
        {'>=200&&<300'    , 200, true},
        {' >=200&&<300'   , 200, true},
        {'>= 200 && < 300', 204, true},
        {'>= 200 && < 300', 300, false},
        {'>= 200 && < 300', 42,  false},
        {'>= 200 && < 300', 0,  false},
    }

    for _, v in ipairs(tests) do
        local exp, value, expected = v[1], v[2], v[3]
        local m = M.new(exp)
        r = m:matches(value)
        assertEquals(r, expected)
    end
end

function TestValueMatching:test_wrong_data()
    local tests = {
        {'>= 200 && < 300', "foo", false},
        {'>= 200 && < 300', ""   , false},
        {'== 200'         , "bar", false},
        {'== foo'         , "10" , false},
        {'!= foo'         , " 10", true},
    }
    for _, v in ipairs(tests) do
        local exp, value, expected = v[1], v[2], v[3]
        local m = M.new(exp)
        r = m:matches(value)
        assertEquals(r, expected)
    end
end

function TestValueMatching:test_precedence()
    local tests = {
        {'>= 200 && < 300 || >500', "200", true},
        {'>= 200 && < 300 || >500', "501", true},
        {'>= 200 && < 300 || >=500', "500", true},
        {'>400 || >= 200 && < 300', "500", true},
        {'>=300 && <500 || >= 200 && < 300', "300", true},
        {'>=300 && <500 || >= 200 && < 300', "500", false},
    }

    for _, v in ipairs(tests) do
        local exp, value, expected = v[1], v[2], v[3]
        local m = M.new(exp)
        r = m:matches(value)
        assertEquals(r, expected)
    end
end

function TestValueMatching:test_pattern_matching()
    local tests = {
        {'=~ /var/lib/ceph/osd/ceph%-%d+', "/var/lib/ceph/osd/ceph-1", true},
        {'=~ /var/lib/ceph/osd/ceph%-%d+', "/var/lib/ceph/osd/ceph-42", true},
        {'=~ ^/var/lib/ceph/osd/ceph%-%d+$', "/var/lib/ceph/osd/ceph-42", true},
        {'=~ "/var/lib/ceph/osd/ceph%-%d+"', "/var/lib/ceph/osd/ceph-42", true},
        {'=~ "ceph%-%d+"', "/var/lib/ceph/osd/ceph-42", true},
        {'=~ "/var/lib/ceph/osd/ceph%-%d+$"', "/var/lib/ceph/osd/ceph-42 ", false}, -- trailing space
        {'=~ /var/lib/ceph/osd/ceph%-%d+', "/var/log", false},
        {'=~ /var/lib/ceph/osd/ceph%-%d+ || foo', "/var/lib/ceph/osd/ceph-1", true},
        {'=~ "foo||bar" || foo', "foo||bar", true},
        {'=~ "foo||bar" || foo', "foo", true},
        {'=~ "foo&&bar" || foo', "foo&&bar", true},
        {'=~ "foo&&bar" || foo', "foo", true},
        {'=~ bar && /var/lib/ceph/osd/ceph%-%d+', "/var/lib/ceph/osd/ceph-1", false},
        {'=~ -', "-", true},
        {'=~ %-', "-", true},
        {'!~ /var/lib/ceph/osd/ceph', "/var/log", true},
        {'!~ /var/lib/ceph/osd/ceph%-%d+', "/var/log", true},
        {'!~ .+osd%-%d+', "/var/log", true},
        {'!~ osd%-%d+', "/var/log", true},
        --{'=~ [', "[", true},
    }

    for _, v in ipairs(tests) do
        local exp, value, expected = v[1], v[2], v[3]
        local m = M.new(exp)
        r = m:matches(value)
        assertEquals(r, expected)
    end
end

function TestValueMatching:test_wrong_patterns_never_match()
    -- These patterns raise errors like:
    -- malformed pattern (missing ']')
    local tests = {
        {'=~ [', "[", false},
        {'!~ [', "[", false},
    }

    for _, v in ipairs(tests) do
        local exp, value, expected = v[1], v[2], v[3]
        local m = M.new(exp)
        r = m:matches(value)
        assertEquals(r, expected)
    end
end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
