-- Copyright 2016 Mirantis, Inc.
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

local influxdb = require('influxdb')

TestInfluxDB = {}

    function TestInfluxDB:test_ms_precision_encoder()
        encoder = influxdb.new("ms")
        assertEquals(encoder:encode_datapoint(1e9 * 1000, 'foo', 1), 'foo value=1.000000 1000000')
        assertEquals(encoder:encode_datapoint(1e9 * 1000, 'foo', 'bar'), 'foo value="bar" 1000000')
        assertEquals(encoder:encode_datapoint(1e9 * 1000, 'foo', 'b"ar'), 'foo value="b\\"ar" 1000000')
        assertEquals(encoder:encode_datapoint(1e9 * 1000, 'foo', 1, {tag2="t2",tag1="t1"}), 'foo,tag1=t1,tag2=t2 value=1.000000 1000000')
        assertEquals(encoder:encode_datapoint(1e9 * 1000, 'foo', {a=1, b=2}), 'foo a=1.000000,b=2.000000 1000000')
    end

    function TestInfluxDB:test_second_precision_encoder()
        encoder = influxdb.new("s")
        assertEquals(encoder:encode_datapoint(1e9 * 1000, 'foo', 1), 'foo value=1.000000 1000')
    end

    function TestInfluxDB:test_us_precision_encoder()
        encoder = influxdb.new("us")
        assertEquals(encoder:encode_datapoint(1e9 * 1000, 'foo', 1), 'foo value=1.000000 1000000000')
    end

    function TestInfluxDB:test_encoder_with_bad_input()
        encoder = influxdb.new()
        assertEquals(encoder:encode_datapoint(1e9 * 1000, nil, 1), '')
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )


