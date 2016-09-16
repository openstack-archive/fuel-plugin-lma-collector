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
local lma_alarm = require('afd_alarms')
local consts = require('gse_constants')

local alarms = {
    { -- 1
        name = 'FS_all_no_field',
        description = 'FS all no field',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'fs_space_percent_free',
                    window = 120,
                    ['function'] = 'avg',
                    relational_operator = '<=',
                    threshold = 11,
                },
            },
            logical_operator = 'and',
        },
        severity = 'warning',
    },
    { -- 2
        name = 'RabbitMQ_Critical',
        description = 'Number of messages in queue is critical',
        enabled = true,
        trigger = {
            rules = {
                {
                    relational_operator = '>=',
                    metric = 'rabbitmq_messages',
                    fields = {},
                    window = "300",
                    periods = "0",
                    ['function'] = 'min',
                    threshold = "50",
                },
            },
            logical_operator = 'or',
        },
        severity = 'critical',
    },
    { -- 3
        name = 'CPU_Critical_Controller',
        description = 'CPU is critical for the controller',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'cpu_idle',
                    window = 120,
                    periods = 2,
                    ['function'] = 'avg',
                    relational_operator = '<=',
                    threshold = 5,
                },
                {
                    metric = 'cpu_wait',
                    window = 120,
                    periods = 1,
                    ['function'] = 'avg',
                    relational_operator = '>=',
                    threshold = 20,
                },
            },
            logical_operator = 'or',
        },
        severity = 'critical',
    },
    { -- 4
        name = 'CPU_Warning_Controller',
        description = 'CPU is warning for controller',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'cpu_idle',
                    window = 100,
                    periods = 2,
                    ['function'] = 'avg',
                    relational_operator = '<=',
                    threshold = 15,
                },
                {
                    metric = 'cpu_wait',
                    window = 60,
                    periods = 0,
                    ['function'] = 'avg',
                    relational_operator = '>=',
                    threshold = 25,
                },
            },
            logical_operator = 'or',
        },
        severity = 'warning',
    },
    { -- 5
        name = 'CPU_Critical_Controller_AND',
        description = 'CPU is critical for controller',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'cpu_idle',
                    window = 120,
                    periods = 2,
                    ['function'] = 'avg',
                    relational_operator = '<=',
                    threshold = 3,
                },
                {
                    metric = 'cpu_wait',
                    window = 60,
                    periods = 1,
                    ['function'] = 'avg',
                    relational_operator = '>=',
                    threshold = 30,
                },
            },
            logical_operator = 'and',
        },
        severity = 'critical',
    },
    { -- 6
        name = 'FS_root',
        description = 'FS root',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'fs_space_percent_free',
                    window = 120,
                    ['function'] = 'avg',
                    fields = { fs='/'},
                    relational_operator = '<=',
                    threshold = 10,
                },
            },
            logical_operator = 'and',
        },
        severity = 'critical',
    },
    { -- 7
        name = 'Backend_errors_5xx',
        description = 'Errors 5xx on backends',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'haproxy_backend_response_5xx',
                    window = 30,
                    periods = 1,
                    ['function'] = 'diff',
                    relational_operator = '>',
                    threshold = 0,
                },
            },
            logical_operator = 'or',
        },
        severity = 'warning',
    },
    { -- 8
        name = 'nova_logs_errors_rate',
        description = 'Rate of change for nova logs in error is too high',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'log_messages',
                    window = 60,
                    periods = 4,
                    ['function'] = 'roc',
                    threshold = 1.5,
                },
            },
        },
        severity = 'warning',
    },
    { -- 9
        name = 'heartbeat',
        description = 'No metric!',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'foo_heartbeat',
                    window = 60,
                    periods = 1,
                    ['function'] = 'last',
                    relational_operator = '==',
                    threshold = 0,
                },
            },
        },
        severity = 'down',
    },
}

afd_on_multivalue = {
    name = 'keystone-high-http-response-times',
    description = 'The 90 percentile response time for Keystone is too high',
    enabled = true,
    trigger = {
        rules = {
            {
                metric = 'http_response_times',
                window = 60,
                periods = 1,
                ['function'] = 'max',
                threshold = 5,
                fields = { http_method = 'POST' },
                relational_operator = '>=',
                value = 'upper_90',
            },
        },
    },
    severity = 'warning',
}

missing_value_afd_on_multivalue = {
    name = 'keystone-high-http-response-times',
    description = 'The 90 percentile response time for Keystone is too high',
    enabled = true,
    trigger = {
        rules = {
            {
                metric = 'http_response_times',
                window = 30,
                periods = 2,
                ['function'] = 'max',
                threshold = 5,
                fields = { http_method = 'POST' },
                relational_operator = '>=',
                -- value = 'upper_90',
            },
        },
    },
    severity = 'warning',
}

TestLMAAlarm = {}

local current_time = 0

function TestLMAAlarm:tearDown()
    lma_alarm.reset_alarms()
    current_time = 0
end

local function next_time(inc)
    if not inc then inc = 10 end
    current_time = current_time + (inc*1e9)
    return current_time
end

function TestLMAAlarm:test_start_evaluation()
    lma_alarm.load_alarm(alarms[3]) -- window=120 period=2
    lma_alarm.set_start_time(current_time)
    local alarm = lma_alarm.get_alarm('CPU_Critical_Controller')
    assertEquals(alarm:is_evaluation_time(next_time(10)), false) -- 10 seconds
    assertEquals(alarm:is_evaluation_time(next_time(50)), false) -- 60 seconds
    assertEquals(alarm:is_evaluation_time(next_time(60)), false) -- 120 seconds
    assertEquals(alarm:is_evaluation_time(next_time(120)), true) -- 240 seconds
    assertEquals(alarm:is_evaluation_time(next_time(240)), true) -- later
end

function TestLMAAlarm:test_not_the_time()
    lma_alarm.load_alarms(alarms)
    lma_alarm.set_start_time(current_time)
    local state, _ = lma_alarm.evaluate(next_time()) -- no alarm w/ window <= 10s
    assertEquals(state, nil)
end

function TestLMAAlarm:test_lookup_fields_for_metric()
    lma_alarm.load_alarms(alarms)
    local fields_required = lma_alarm.get_metric_fields('fs_space_percent_free')
    assertItemsEquals(fields_required, {"fs"})
end

function TestLMAAlarm:test_lookup_empty_fields_for_metric()
    lma_alarm.load_alarms(alarms)
    local fields_required = lma_alarm.get_metric_fields('cpu_idle')
    assertItemsEquals(fields_required, {})
    local fields_required = lma_alarm.get_metric_fields('fs_space_percent_free')
    assertItemsEquals(fields_required, {'fs'})
end

function TestLMAAlarm:test_lookup_interested_alarms()
    lma_alarm.load_alarms(alarms)
    local alarms = lma_alarm.get_interested_alarms('foometric')
    assertEquals(#alarms, 0)
    local alarms = lma_alarm.get_interested_alarms('cpu_wait')
    assertEquals(#alarms, 3)

end

function TestLMAAlarm:test_get_alarms()
    lma_alarm.load_alarms(alarms)
    local all_alarms = lma_alarm.get_alarms()
    local num = 0
    for _, _ in pairs(all_alarms) do
        num = num + 1
    end
    assertEquals(num, #alarms)
end

function TestLMAAlarm:test_no_datapoint()
    lma_alarm.load_alarms(alarms)
    lma_alarm.set_start_time(current_time)
    local t = next_time(300) -- at this time all alarms can be evaluated
    local state, results = lma_alarm.evaluate(t)
    assertEquals(state, consts.UNKW)
    assert(#results > 0)
    for _, result in ipairs(results) do
        assertEquals(result.alert.message, 'No datapoint have been received ever')
        assertNotEquals(result.alert.fields, nil)
    end
end

function TestLMAAlarm:test_rules_logical_op_and_no_alert()
    lma_alarm.load_alarms(alarms)
    local alarm = lma_alarm.get_alarm('CPU_Critical_Controller_AND')
    lma_alarm.set_start_time(current_time)
    local t1 = next_time(60) -- 60s
    local t2 = next_time(60) -- 120s
    local t3 = next_time(60) -- 180s
    local t4 = next_time(60) -- 240s
    lma_alarm.add_value(t1, 'cpu_wait', 3)
    lma_alarm.add_value(t2, 'cpu_wait', 10)
    lma_alarm.add_value(t3, 'cpu_wait', 1)
    lma_alarm.add_value(t4, 'cpu_wait', 10)

    lma_alarm.add_value(t1, 'cpu_idle', 30)
    lma_alarm.add_value(t2, 'cpu_idle', 10)
    lma_alarm.add_value(t3, 'cpu_idle', 10)
    lma_alarm.add_value(t4, 'cpu_idle', 20)
    local state, result = alarm:evaluate(t4)
    assertEquals(#result, 0)
    assertEquals(state, consts.OKAY)
end

function TestLMAAlarm:test_rules_logical_missing_datapoint__op_and()
    lma_alarm.load_alarm(alarms[5])
    lma_alarm.set_start_time(current_time)
    local t1 = next_time(60)
    local t2 = next_time(60)
    local t3 = next_time(60)
    local t4 = next_time(60)
    lma_alarm.add_value(t1, 'cpu_wait', 0) -- 60s
    lma_alarm.add_value(t2, 'cpu_wait', 2) -- 120s
    lma_alarm.add_value(t3, 'cpu_wait', 5) -- 180s
    lma_alarm.add_value(t4, 'cpu_wait', 6) -- 240s
    lma_alarm.add_value(t1, 'cpu_idle', 20) -- 60s
    lma_alarm.add_value(t2, 'cpu_idle', 20) -- 120s
    lma_alarm.add_value(t3, 'cpu_idle', 20) -- 180s
    lma_alarm.add_value(t4, 'cpu_idle', 20) -- 240s
    local state, result = lma_alarm.evaluate(t4) -- 240s we can evaluate
    assertEquals(state, consts.OKAY)
    assertEquals(#result, 0)
    local state, result = lma_alarm.evaluate(next_time(60)) -- 60s w/o datapoint
    assertEquals(state, consts.OKAY)
    --  cpu_wait have no data within its observation period
    local state, result = lma_alarm.evaluate(next_time(1)) -- 61s w/o datapoint
    assertEquals(state, consts.UNKW)
    assertEquals(#result, 1)
    assertEquals(result[1].alert.metric, 'cpu_wait')
    assert(result[1].alert.message:match('No datapoint have been received over the last'))

    --  both cpu_idle and cpu_wait have no data within their observation periods
    local state, result = lma_alarm.evaluate(next_time(180)) -- 241s w/o datapoint
    assertEquals(state, consts.UNKW)
    assertEquals(#result, 2)
    assertEquals(result[1].alert.metric, 'cpu_idle')
    assert(result[1].alert.message:match('No datapoint have been received over the last'))
    assertEquals(result[2].alert.metric, 'cpu_wait')
    assert(result[2].alert.message:match('No datapoint have been received over the last'))

    -- datapoints come back for both metrics
    lma_alarm.add_value(next_time(), 'cpu_idle', 20)
    lma_alarm.add_value(next_time(), 'cpu_idle', 20)
    lma_alarm.add_value(next_time(), 'cpu_wait', 20)
    lma_alarm.add_value(next_time(), 'cpu_wait', 20)
    local state, result = lma_alarm.evaluate(next_time()) -- 240s we can evaluate
    assertEquals(state, consts.OKAY)
    assertEquals(#result, 0)
end

function TestLMAAlarm:test_rules_logical_missing_datapoint__op_and_2()
    lma_alarm.load_alarm(alarms[5])
    lma_alarm.set_start_time(current_time)
    local t1 = next_time(60)
    local t2 = next_time(60)
    local t3 = next_time(60)
    local t4 = next_time(60)
    lma_alarm.add_value(t1, 'cpu_wait', 0) -- 60s
    lma_alarm.add_value(t2, 'cpu_wait', 2) -- 120s
    lma_alarm.add_value(t3, 'cpu_wait', 5) -- 180s
    lma_alarm.add_value(t4, 'cpu_wait', 6) -- 240s
    lma_alarm.add_value(t1, 'cpu_idle', 20) -- 60s
    lma_alarm.add_value(t2, 'cpu_idle', 20) -- 120s
    lma_alarm.add_value(t3, 'cpu_idle', 20) -- 180s
    lma_alarm.add_value(t4, 'cpu_idle', 20) -- 240s
    local state, result = lma_alarm.evaluate(t4) -- 240s we can evaluate
    assertEquals(state, consts.OKAY)
    assertEquals(#result, 0)
    local state, result = lma_alarm.evaluate(next_time(60)) -- 60s w/o datapoint
    assertEquals(state, consts.OKAY)
    --  cpu_wait have no data within its observation period
    local state, result = lma_alarm.evaluate(next_time(1)) -- 61s w/o datapoint
    assertEquals(state, consts.UNKW)
    assertEquals(#result, 1)
    assertEquals(result[1].alert.metric, 'cpu_wait')
    assert(result[1].alert.message:match('No datapoint have been received over the last'))

    lma_alarm.add_value(next_time(170), 'cpu_wait', 20)
    --  cpu_idle have no data within its observation period
    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(state, consts.UNKW)
    assertEquals(#result, 1)
    assertEquals(result[1].alert.metric, 'cpu_idle')
    assert(result[1].alert.message:match('No datapoint have been received over the last'))

    -- datapoints come back for both metrics
    lma_alarm.add_value(next_time(), 'cpu_idle', 20)
    lma_alarm.add_value(next_time(), 'cpu_idle', 20)
    lma_alarm.add_value(next_time(), 'cpu_wait', 20)
    lma_alarm.add_value(next_time(), 'cpu_wait', 20)
    local state, result = lma_alarm.evaluate(next_time()) -- 240s we can evaluate
    assertEquals(state, consts.OKAY)
    assertEquals(#result, 0)
end

function TestLMAAlarm:test_rules_logical_op_and()
    lma_alarm.load_alarm(alarms[5])
    local cpu_critical_and = lma_alarm.get_alarm('CPU_Critical_Controller_AND')
    lma_alarm.add_value(next_time(1), 'cpu_wait', 30)
    lma_alarm.add_value(next_time(1), 'cpu_wait', 30)
    lma_alarm.add_value(next_time(1), 'cpu_wait', 35)

    lma_alarm.add_value(next_time(2), 'cpu_idle', 0)
    lma_alarm.add_value(next_time(2), 'cpu_idle', 1)
    lma_alarm.add_value(next_time(2), 'cpu_idle', 7)
    lma_alarm.add_value(next_time(2), 'cpu_idle', 2)
    local state, result = cpu_critical_and:evaluate(current_time)
    assertEquals(state, consts.CRIT)
    assertEquals(#result, 2) -- both rules match: avg(cpu_wait)>=30 and avg(cpu_idle)<=15

    lma_alarm.add_value(next_time(120), 'cpu_idle', 70)
    lma_alarm.add_value(next_time(), 'cpu_idle', 70)
    lma_alarm.add_value(next_time(), 'cpu_idle', 70)
    lma_alarm.add_value(next_time(), 'cpu_wait', 40)
    lma_alarm.add_value(next_time(), 'cpu_wait', 38)
    local state, result = cpu_critical_and:evaluate(current_time)
    assertEquals(state, consts.OKAY)
    assertEquals(#result, 0) -- avg(cpu_wait)>=30 matches but not avg(cpu_idle)<=15

    lma_alarm.add_value(next_time(200), 'cpu_idle', 70)
    lma_alarm.add_value(next_time(), 'cpu_idle', 70)
    local state, result = cpu_critical_and:evaluate(current_time)
    assertEquals(state, consts.UNKW)
    assertEquals(#result, 1) -- no data for avg(cpu_wait)>=30 and avg(cpu_idle)<=3 doesn't match

    next_time(240) -- spend enough time to invalidate datapoints of cpu_wait
    lma_alarm.add_value(current_time, 'cpu_idle', 2)
    lma_alarm.add_value(next_time(), 'cpu_idle', 2)
    local state, result = cpu_critical_and:evaluate(current_time)
    assertEquals(state, consts.UNKW)
    assertEquals(#result, 2) -- no data for avg(cpu_wait)>=30 and avg(cpu_idle)<=3 matches
end

function TestLMAAlarm:test_rules_logical_op_or_one_alert()
    lma_alarm.load_alarms(alarms)
    local cpu_warn_and = lma_alarm.get_alarm('CPU_Warning_Controller')
    lma_alarm.add_value(next_time(), 'cpu_wait', 15)
    lma_alarm.add_value(next_time(), 'cpu_wait', 10)
    lma_alarm.add_value(next_time(), 'cpu_wait', 20)

    lma_alarm.add_value(next_time(), 'cpu_idle', 11)
    lma_alarm.add_value(next_time(), 'cpu_idle', 8)
    lma_alarm.add_value(next_time(), 'cpu_idle', 7)
    local state, result = cpu_warn_and:evaluate(current_time)
    assertEquals(state, consts.WARN)
    assertEquals(#result, 1) -- avg(cpu_wait) IS NOT >=25 and avg(cpu_idle)<=2
end

function TestLMAAlarm:test_rules_logical_op_or_all_alert()
    lma_alarm.load_alarm(alarms[4])
    local cpu_warn_and = lma_alarm.get_alarm('CPU_Warning_Controller')
    lma_alarm.add_value(next_time(), 'cpu_wait', 35)
    lma_alarm.add_value(next_time(), 'cpu_wait', 20)
    lma_alarm.add_value(next_time(), 'cpu_wait', 32)

    lma_alarm.add_value(next_time(), 'cpu_idle', 3)
    lma_alarm.add_value(next_time(), 'cpu_idle', 2.5)
    lma_alarm.add_value(next_time(), 'cpu_idle', 1.5)
    local state, result = cpu_warn_and:evaluate(current_time)
    assertEquals(state, consts.WARN)
    assertEquals(#result, 2) -- avg(cpu_wait) >=25 and avg(cpu_idle)<=3
end

function TestLMAAlarm:test_min()
    lma_alarm.load_alarms(alarms)
    lma_alarm.add_value(next_time(), 'rabbitmq_messages', 50)
    lma_alarm.add_value(next_time(), 'rabbitmq_messages', 100)
    lma_alarm.add_value(next_time(), 'rabbitmq_messages', 75)
    lma_alarm.add_value(next_time(), 'rabbitmq_messages', 81)
    local rabbitmq_critical = lma_alarm.get_alarm('RabbitMQ_Critical')
    assertEquals(rabbitmq_critical.severity, consts.CRIT)
    local state_crit, result = rabbitmq_critical:evaluate(current_time)
    assertEquals(state_crit, consts.CRIT) -- min()>=50
    assertEquals(#result, 1)
    assertEquals(result[1].value, 50)
end

 function TestLMAAlarm:test_max()
    local a = {
        name = 'foo alert',
        description = 'foo description',
        trigger = {
            rules = {
                {
                    metric = 'rabbitmq_queue_messages',
                    window = 30,
                    periods = 2,
                    ['function'] = 'max',
                    threshold = 200,
                    relational_operator = '>=',
                },
            },
        },
        severity = 'warning',
    }
     lma_alarm.load_alarm(a)
     lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 0, {queue = 'queue-XX', hostname = 'node-x'})
     lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 260, {queue = 'queue-XX', hostname = 'node-x'})
     lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 200, {queue = 'queue-XX', hostname = 'node-x'})
     lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 152, {queue = 'queue-XX', hostname = 'node-x'})
     lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 152, {queue = 'nova', hostname = 'node-x'})
     lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 532, {queue = 'nova', hostname = 'node-x'})
     local state_warn, result = lma_alarm.evaluate(current_time)
     assertEquals(state_warn, consts.WARN)
     assertEquals(#result, 1)
     assertEquals(result[1].alert['function'], 'max')
     assertEquals(result[1].alert.value, 532)
 end

function TestLMAAlarm:test_diff()
    lma_alarm.load_alarms(alarms)
    local errors_5xx = lma_alarm.get_alarm('Backend_errors_5xx')
    assertEquals(errors_5xx.severity, consts.WARN)

    -- with 5xx errors
    lma_alarm.add_value(next_time(), 'haproxy_backend_response_5xx', 1)
    lma_alarm.add_value(next_time(), 'haproxy_backend_response_5xx', 11) -- +10s
    lma_alarm.add_value(next_time(), 'haproxy_backend_response_5xx', 21) -- +10s
    local state, result = errors_5xx:evaluate(current_time)
    assertEquals(state, consts.WARN)
    assertEquals(#result, 1)
    assertEquals(result[1].value, 20)

    -- without 5xx errors
    lma_alarm.add_value(next_time(), 'haproxy_backend_response_5xx', 21)
    lma_alarm.add_value(next_time(), 'haproxy_backend_response_5xx', 21) -- +10s
    lma_alarm.add_value(next_time(), 'haproxy_backend_response_5xx', 21) -- +10s
    local state, result = errors_5xx:evaluate(current_time)
    assertEquals(state, consts.OKAY)
    assertEquals(#result, 0)

    -- missing data
    local state, result = errors_5xx:evaluate(next_time(60))
    assertEquals(state, consts.UNKW)
end

function TestLMAAlarm:test_roc()
    lma_alarm.load_alarms(alarms)
    local errors_logs = lma_alarm.get_alarm('nova_logs_errors_rate')
    assertEquals(errors_logs.severity, consts.WARN)
    local m_values = {}

    -- Test one error in the current window
    m_values = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- historical window 0
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- historical window 0
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- historical window 3
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- historical window 4
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- previous window
                 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0 } -- current window
    for _,v in pairs(m_values) do
        lma_alarm.add_value(next_time(5), 'log_messages', v, {service = 'nova', level = 'error'})
    end
    local state, _ = errors_logs:evaluate(current_time)
    assertEquals(state, consts.WARN)

    -- Test one error in the historical window
    m_values = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- historical window 0
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- historical window 0
                 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,  -- historical window 3
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- historical window 4
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  -- previous window
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } -- current window
    for _,v in pairs(m_values) do
        lma_alarm.add_value(next_time(5), 'log_messages', v, {service = 'nova', level = 'error'})
    end
    local state, _ = errors_logs:evaluate(current_time)
    assertEquals(state, consts.OKAY)

    -- with rate errors
    m_values = { 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- historical window 1
                 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- historical window 2
                 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- historical window 3
                 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- historical window 4
                 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- previous window
                 1, 2, 1, 1, 1, 2, 1, 5, 5, 7, 1, 7 } -- current window
    for _,v in pairs(m_values) do
        lma_alarm.add_value(next_time(5), 'log_messages', v, {service = 'nova', level = 'error'})
    end
    local state, _ = errors_logs:evaluate(current_time)
    assertEquals(state, consts.WARN)

    -- without rate errors
    m_values = { 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- historical window 1
                 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- historical window 2
                 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- historical window 3
                 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- historical window 4
                 1, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 2,  -- previous window
                 1, 2, 1, 1, 1, 2, 1, 3, 4, 3, 3, 4 } -- current window
    for _,v in pairs(m_values) do
        lma_alarm.add_value(next_time(5), 'log_messages', v, {service = 'nova', level = 'error'})
    end
    local state, _ = errors_logs:evaluate(current_time)
    assertEquals(state, consts.OKAY)
end

function TestLMAAlarm:test_alarm_first_match()
    lma_alarm.load_alarm(alarms[3]) --  cpu critical (window 240s)
    lma_alarm.load_alarm(alarms[4]) --  cpu warning (window 120s)
    lma_alarm.set_start_time(current_time)

    next_time(240) -- both alarms can now be evaluated
    lma_alarm.add_value(next_time(), 'cpu_idle', 15)
    lma_alarm.add_value(next_time(), 'cpu_wait', 9)
    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(state, consts.WARN) -- 2nd alarm raised
    assertEquals(#result, 1) -- cpu_idle match (<= 15) and cpu_wait don't match (>= 25)

    next_time(240) -- both alarms can now be evaluated with new datapoints
    lma_alarm.add_value(next_time(), 'cpu_wait', 15)
    lma_alarm.add_value(next_time(), 'cpu_idle', 4)
    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(state, consts.CRIT) -- first alarm raised
    assertEquals(#result, 1) -- cpu_idle match (<= 5) and cpu_wait don't match (>= 20)
end

function TestLMAAlarm:test_rules_fields()
    lma_alarm.load_alarm(alarms[1]) -- FS_all_no_field
    lma_alarm.load_alarm(alarms[6]) -- FS_root
    lma_alarm.set_start_time(current_time)

    local t = next_time()
    lma_alarm.add_value(t, 'fs_space_percent_free', 6, {fs = '/'})
    lma_alarm.add_value(t, 'fs_space_percent_free', 6 )
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 12, {fs = '/'})
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 17 )
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 6, {fs = '/'})
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 6, {fs = 'foo'})
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 3, {fs = 'foo'})
    local t = next_time()

    local root_fs = lma_alarm.get_alarm('FS_root')
    local state, result = root_fs:evaluate(t)
    assertEquals(#result, 1)
    assertItemsEquals(result[1].fields, {fs='/'})
    assertEquals(result[1].value, 8)


    local root_fs = lma_alarm.get_alarm('FS_all_no_field')
    local state, result = root_fs:evaluate(t)
    assertEquals(#result, 1)

    assertItemsEquals(result[1].fields, {})
    assertEquals(result[1].value, 8)
end

function TestLMAAlarm:test_last_fct()
    lma_alarm.load_alarm(alarms[9])
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(), 'foo_heartbeat', 1)
    lma_alarm.add_value(next_time(), 'foo_heartbeat', 1)
    lma_alarm.add_value(next_time(), 'foo_heartbeat', 0)
    lma_alarm.add_value(next_time(), 'foo_heartbeat', 1)
    lma_alarm.add_value(next_time(), 'foo_heartbeat', 0)
    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(state, consts.DOWN)
    next_time(61)
    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(state, consts.UNKW)
    lma_alarm.add_value(next_time(), 'foo_heartbeat', 0)
    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(state, consts.DOWN)
    lma_alarm.add_value(next_time(), 'foo_heartbeat', 1)
    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(state, consts.OKAY)
end

function TestLMAAlarm:test_rule_with_multivalue()
    lma_alarm.load_alarm(afd_on_multivalue)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 0.4, foo = 1}, {http_method = 'POST'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 0.2, foo = 1}, {http_method = 'POST'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 6, foo = 1}, {http_method = 'POST'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 3, foo = 1}, {http_method = 'POST'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 4, foo = 1}, {http_method = 'POST'})
    local state, result = lma_alarm.evaluate(next_time()) -- window 60 second
    assertEquals(state, consts.WARN)
    assertItemsEquals(result[1].alert.fields, {http_method='POST'})
    assertEquals(result[1].alert.value, 6)
end

function TestLMAAlarm:test_nocrash_missing_value_with_multivalue_metric()
    lma_alarm.load_alarm(missing_value_afd_on_multivalue)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 0.4, foo = 1}, {http_method = 'POST'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 0.2, foo = 1}, {http_method = 'POST'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 6, foo = 1}, {http_method = 'POST'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 3, foo = 1}, {http_method = 'POST'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 4, foo = 1}, {http_method = 'POST'})
    local state, result = lma_alarm.evaluate(next_time()) -- window 60 second
    assertEquals(state, consts.UNKW)
end

function TestLMAAlarm:test_complex_field_matching_alarm_trigger()
    local alert = {
        name = 'keystone-high-http-response-times',
        description = 'The 90 percentile response time for Keystone is too high',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'http_response_times',
                    window = 30,
                    periods = 2,
                    ['function'] = 'max',
                    threshold = 5,
                    fields = { http_method = 'POST || GET',
                               http_status = '2xx || ==3xx'},
                    relational_operator = '>=',
                    value = 'upper_90',
                },
            },
        },
        severity = 'warning',
    }
    lma_alarm.load_alarm(alert)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 0.4, foo = 1}, {http_method = 'POST', http_status = '2xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 0.2, foo = 1}, {http_method = 'POST', http_status = '2xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 6, foo = 1}, {http_method = 'POST', http_status = '3xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 999, foo = 1}, {http_method = 'POST', http_status = '5xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 3, foo = 1}, {http_method = 'GET', http_status = '2xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 4, foo = 1}, {http_method = 'POST', http_status = '2xx'})
    local state, result = lma_alarm.evaluate(next_time()) -- window 60 second
    assertEquals(state, consts.WARN)
    assertEquals(result[1].alert.value, 6) -- the max
    assertItemsEquals(result[1].alert.fields, {http_method='POST || GET', http_status='2xx || ==3xx'})
end

function TestLMAAlarm:test_complex_field_matching_alarm_ok()
    local alert = {
        name = 'keystone-high-http-response-times',
        description = 'The 90 percentile response time for Keystone is too high',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'http_response_times',
                    window = 30,
                    periods = 2,
                    ['function'] = 'avg',
                    threshold = 5,
                    fields = { http_method = 'POST || GET',
                               http_status = '2xx || 3xx'},
                    relational_operator = '>=',
                    value = 'upper_90',
                },
            },
        },
        severity = 'warning',
    }

    lma_alarm.load_alarm(alert)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 0.4, foo = 1}, {http_method = 'POST', http_status = '2xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 0.2, foo = 1}, {http_method = 'POST', http_status = '2xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 6, foo = 1}, {http_method = 'POST', http_status = '2xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 3, foo = 1}, {http_method = 'GET', http_status = '2xx'})
    lma_alarm.add_value(next_time(), 'http_response_times', {upper_90 = 4, foo = 1}, {http_method = 'POST', http_status = '2xx'})
    local state, result = lma_alarm.evaluate(next_time()) -- window 60 second
    assertEquals(state, consts.OKAY)
end

function TestLMAAlarm:test_group_by_required_field()
    local alert = {
        name = 'foo-alarm',
        description = 'foo description',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'foo_metric_name',
                    window = 30,
                    periods = 1,
                    ['function'] = 'avg',
                    fields = { foo = 'bar', bar = 'foo' },
                    group_by = {'fs'},
                    relational_operator = '<=',
                    threshold = 5,
                },
            },
        },
        severity = 'warning',
    }
    lma_alarm.load_alarm(alert)
    local fields = lma_alarm.get_metric_fields('foo_metric_name')
    assertItemsEquals(fields, { "fs", "foo", "bar" })

    local fields = lma_alarm.get_metric_fields('non_existant_metric')
    assertItemsEquals(fields, {})
end

function TestLMAAlarm:test_group_by_one_field()
    local alert = {
        name = 'osd-filesystem-warning',
        description = 'free space is too low',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'fs_space_percent_free',
                    window = 30,
                    periods = 1,
                    ['function'] = 'avg',
                    fields = { fs = '=~ osd%-%d && !~ /var/log' },
                    group_by = {'fs'},
                    relational_operator = '<=',
                    threshold = 5,
                },
            },
        },
        severity = 'warning',
    }
    lma_alarm.load_alarm(alert)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 5, {fs = 'osd-1'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 4, {fs = 'osd-2'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 80, {fs = 'osd-3'})
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 4, {fs = 'osd-1'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 3, {fs = 'osd-2'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 80, {fs = 'osd-3'})
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 4, {fs = 'osd-1'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 2, {fs = 'osd-2'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 80, {fs = 'osd-3'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 1, {fs = '/var/log/osd-3'})

    local state, result = lma_alarm.evaluate(next_time()) -- window 60 second
    assertEquals(#result, 2)
    assertEquals(state, consts.WARN)

    next_time(100) -- spend enough time to invalidate datapoints
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 50, {fs = 'osd-1'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 50, {fs = 'osd-2'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 50, {fs = 'osd-3'})
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 50, {fs = 'osd-1'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 50, {fs = 'osd-2'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 50, {fs = 'osd-3'})
    local state, result = lma_alarm.evaluate(next_time()) -- window 60 second
    assertEquals(#result, 0)
    assertEquals(state, consts.OKAY)
end

function TestLMAAlarm:test_group_by_several_fields()
    local alert = {
        name = 'osd-filesystem-warning',
        description = 'free space is too low',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'fs_space_percent_free',
                    window = 30,
                    periods = 1,
                    ['function'] = 'last',
                    fields = {},
                    group_by = {'fs', 'osd'},
                    relational_operator = '<=',
                    threshold = 5,
                },
            },
        },
        severity = 'warning',
    }
    lma_alarm.load_alarm(alert)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 5, {fs = '/foo', osd = '1'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 4, {fs = '/foo', osd = '2'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 80, {fs = '/foo', osd = '3'})

    local state, result = lma_alarm.evaluate(next_time(20))
    assertEquals(state, consts.WARN)
    -- one item for {fs = '/foo', osd = '1'} and another one for {fs = '/foo', osd = '2'}
    assertEquals(#result, 2)

    next_time(100) -- spend enough time to invalidate datapoints

    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 5, {fs = '/foo', osd = '1'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 4, {fs = '/foo', osd = '2'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 80, {fs = '/foo', osd = '3'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 15, {fs = '/bar', osd = '1'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 14, {fs = '/bar', osd = '2'})
    lma_alarm.add_value(current_time, 'fs_space_percent_free', 2, {fs = '/bar', osd = '3'})
    local state, result = lma_alarm.evaluate(next_time(20))
    assertEquals(state, consts.WARN)
    -- one item for {fs = '/foo', osd = '1'}, another one for {fs = '/foo', osd = '2'}
    -- and another one for {fs = '/bar', osd = '3'}
    assertEquals(#result, 3)
end

function TestLMAAlarm:test_group_by_missing_field_is_unknown()
    local alert = {
        name = 'osd-filesystem-warning',
        description = 'free space is too low',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'fs_space_percent_free',
                    window = 30,
                    periods = 1,
                    ['function'] = 'avg',
                    fields = { fs = '=~ osd%-%d && !~ /var/log' },
                    group_by = {'fs'},
                    relational_operator = '<=',
                    threshold = 5,
                },
            },
        },
        severity = 'warning',
    }
    lma_alarm.load_alarm(alert)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 5)
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 4)
    lma_alarm.add_value(next_time(), 'fs_space_percent_free', 4)

    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(#result, 1)
    assertEquals(state, consts.UNKW)
end

function TestLMAAlarm:test_no_data_policy_okay()
    local alarm = {
        name = 'foo-alarm',
        description = 'foo description',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'foo_metric_name',
                    window = 30,
                    periods = 1,
                    ['function'] = 'avg',
                    fields = { foo = 'bar', bar = 'foo' },
                    group_by = {'fs'},
                    relational_operator = '<=',
                    threshold = 5,
                },
            },
        },
        severity = 'warning',
        no_data_policy = 'okay',
    }
    lma_alarm.load_alarm(alarm)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(100), 'another_metric', 5)

    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(#result, 0)
    assertEquals(state, consts.OKAY)
end

function TestLMAAlarm:test_no_data_policy_critical()
    local alarm = {
        name = 'foo-alarm',
        description = 'foo description',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'foo_metric_name',
                    window = 30,
                    periods = 1,
                    ['function'] = 'avg',
                    fields = { foo = 'bar', bar = 'foo' },
                    group_by = {'fs'},
                    relational_operator = '<=',
                    threshold = 5,
                },
            },
        },
        severity = 'critical',
        no_data_policy = 'critical',
    }
    lma_alarm.load_alarm(alarm)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(100), 'another_metric', 5)

    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(#result, 1)
    assertEquals(state, consts.CRIT)
end

function TestLMAAlarm:test_no_data_policy_skip()
    local alarm = {
        name = 'foo-alarm',
        description = 'foo description',
        enabled = true,
        trigger = {
            rules = {
                {
                    metric = 'foo_metric_name',
                    window = 30,
                    periods = 1,
                    ['function'] = 'avg',
                    fields = { foo = 'bar', bar = 'foo' },
                    group_by = {'fs'},
                    relational_operator = '<=',
                    threshold = 5,
                },
            },
        },
        severity = 'critical',
        no_data_policy = 'skip',
    }
    lma_alarm.load_alarm(alarm)
    lma_alarm.set_start_time(current_time)

    lma_alarm.add_value(next_time(100), 'another_metric', 5)

    local state, result = lma_alarm.evaluate(next_time())
    assertEquals(state, nil)
end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
