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

require('luaunit')
package.path = package.path .. ";files/plugins/common/?.lua;tests/lua/mocks/?.lua"
local lma_alarm = require('afd_alarms')
local consts = require('gse_constants')

local alarms = {
  { -- 1
    name = 'RabbitMQ-Critical',
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
          ['function'] = 'avg',
          threshold = "500",
        },
      },
      logical_operator = 'or',
    },
    severity = 'critical',
  },
  { -- 2
    name = 'RabbitMQ-Warning',
    description = 'Number of messages becomes hight',
    enabled = true,
    trigger = {
      rules = {
        {
          relational_operator = '>=',
          metric = 'rabbitmq_queue_messages',
          fields = { queue = '*', hostname = '*'},
          window = 120,
          periods = 0,
          ['function'] = 'avg',
          threshold = 120,
        },
        {
          relational_operator = '>=',
          metric = 'rabbitmq_queue_messages',
          fields = { queue = 'nova', hostname = '*'},
          window = 60,
          periods = 0,
          ['function'] = 'max',
          threshold = 250,
        },
      },
    },
    severity = 'warning',
  },
  { -- 3
    name = 'CPU-Critical-Controller',
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
          fields = { hostname = '*' },
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
    name = 'CPU-Warning-Controller',
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
          fields = { hostname = '*' },
          ['function'] = 'avg',
          relational_operator = '>=',
          threshold = 25,
        },
      },
      logical_operator = 'or',
    },
    severity = 'critical',
  },
  { -- 5
    name = 'CPU-Critical-Controller-AND',
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
    name = 'FS-root',
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
    name = 'FS-all',
    description = 'FS all',
    enabled = true,
    trigger = {
      rules = {
        {
          metric = 'fs_space_percent_free',
          window = 120,
          ['function'] = 'avg',
          fields = { fs='*'},
          relational_operator = '<=',
          threshold = 10,
        },
      },
      logical_operator = 'and',
    },
    severity = 'warning',
  },
  { -- 8
    name = 'FS-all-no-field',
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
    severity = 'down',
  },
}

TestLMAAlarm = {}

local current_time = 1

function TestLMAAlarm:tearDown()
  lma_alarm.reset_alarms()
  current_time = 1
end

local function next_time(inc)
    if not inc then inc = 10 end
    current_time = current_time + (inc*1e9)
    return current_time
end

function TestLMAAlarm:test_start_evaluation()
  lma_alarm.load_alarm(alarms[3]) -- window=120 period=2
  lma_alarm.set_start_time(current_time)
  local alarm = lma_alarm.get_alarm('CPU-Critical-Controller')
  assertEquals(alarm:can_evaluate(next_time(10)), false) -- 10 seconds
  assertEquals(alarm:can_evaluate(next_time(50)), false) -- 60 seconds
  assertEquals(alarm:can_evaluate(next_time(60)), false) -- 120 seconds
  assertEquals(alarm:can_evaluate(next_time(120)), true) -- 240 seconds
  assertEquals(alarm:can_evaluate(next_time(1000)), true) -- later
end

function TestLMAAlarm:test_lookup_fields_for_metric()
  lma_alarm.load_alarms(alarms)
  local fields_required = lma_alarm.get_metric_fields('rabbitmq_queue_messages')
  assertItemsEquals(fields_required, {"queue", "hostname"})
end

function TestLMAAlarm:test_lookup_empty_fields_for_metric()
  lma_alarm.load_alarms(alarms)
  local fields_required = lma_alarm.get_metric_fields('cpu_idle')
  assertItemsEquals(fields_required, {})
  local fields_required = lma_alarm.get_metric_fields('cpu_wait')
  assertItemsEquals(fields_required, {'hostname'})
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
  assertEquals(num, 8)
end

function TestLMAAlarm:test_default_state()
  lma_alarm.load_alarms(alarms)
  local t = next_time(1000)
  local state, result = lma_alarm.evaluate(t)
  assertEquals(state, consts.OKAY)
  assertEquals(result, {})
end

function TestLMAAlarm:test_rules_logical_op_and_no_alert()
  lma_alarm.load_alarm(alarms[5])
  -- cpu_wait crosses its threshold (avg()>30)
  lma_alarm.add_value(next_time(1), 'cpu_wait', 50)
  lma_alarm.add_value(next_time(1), 'cpu_wait', 40)
  lma_alarm.add_value(next_time(1), 'cpu_wait', 30)
  -- but not cpu_idle (avg()> 3)
  lma_alarm.add_value(next_time(), 'cpu_idle', 30)
  lma_alarm.add_value(next_time(), 'cpu_idle', 10)
  lma_alarm.add_value(next_time(), 'cpu_idle', 10)
  lma_alarm.add_value(next_time(), 'cpu_idle', 20)
  local state, result = lma_alarm.evaluate(current_time)
  assertEquals(state, consts.OKAY)
  assertEquals(#result, 0) -- avg(cpu_wait)>=30 but avg(cpu_idle)>3
end

function TestLMAAlarm:test_rules_logical_op_and_with_alerts()
  lma_alarm.load_alarm(alarms[5])
  local cpu_critical_and = lma_alarm.get_alarm('CPU-Critical-Controller-AND')
  lma_alarm.add_value(next_time(1), 'cpu_wait', 25)
  lma_alarm.add_value(next_time(1), 'cpu_wait', 30)
  lma_alarm.add_value(next_time(1), 'cpu_wait', 35)

  lma_alarm.add_value(next_time(2), 'cpu_idle', 0)
 lma_alarm.add_value(next_time(2), 'cpu_idle', 1)
  lma_alarm.add_value(next_time(2), 'cpu_idle', 7)
  lma_alarm.add_value(next_time(2), 'cpu_idle', 2)
  local state, result = cpu_critical_and:evaluate()
  assertEquals(state, consts.CRIT)
  assertEquals(#result, 2) -- avg(cpu_wait)>=25 and avg(cpu_idle)<=15
end

function TestLMAAlarm:test_rules_logical_op_or_one_alert()
  lma_alarm.load_alarm(alarms[4])
  local cpu_critical_and = lma_alarm.get_alarm('CPU-Warning-Controller')
  lma_alarm.add_value(next_time(), 'cpu_wait', 15)
  lma_alarm.add_value(next_time(), 'cpu_wait', 10)
  lma_alarm.add_value(next_time(), 'cpu_wait', 20)

  lma_alarm.add_value(next_time(), 'cpu_idle', 11)
  lma_alarm.add_value(next_time(), 'cpu_idle', 8)
  lma_alarm.add_value(next_time(), 'cpu_idle', 7)
  local state, result = cpu_critical_and:evaluate()
  assertEquals(state, consts.CRIT)
  assertEquals(#result, 1) -- avg(cpu_wait) IS NOT >=25 and avg(cpu_idle)<=15
end

function TestLMAAlarm:test_rules()
  lma_alarm.load_alarms(alarms)
  lma_alarm.set_start_time(current_time)

  lma_alarm.add_value(next_time(), 'rabbitmq_messages', 400)
  lma_alarm.add_value(next_time(), 'rabbitmq_messages', 660)
  local rabbitmq_critical = lma_alarm.get_alarm('RabbitMQ-Critical')
  assertEquals(rabbitmq_critical.severity, consts.CRIT)
  local state_crit, result = rabbitmq_critical:evaluate()
  assertEquals(#result, 1)
  assertEquals(state_crit, consts.CRIT)
  assertEquals(result[1].value, 530) -- avg()>500

  local rabbitmq_warning = lma_alarm.get_alarm('RabbitMQ-Warning')
  lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 0, {queue = 'queue-XX', hostname = 'node-x'})
  lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 3, {queue = 'queue-XX', hostname = 'node-x'})
  lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 260, {queue = 'queue-XX', hostname = 'node-x'})
  lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 200, {queue = 'queue-XX', hostname = 'node-x'})
  lma_alarm.add_value(next_time(), 'rabbitmq_queue_messages', 152, {queue = 'queue-XX', hostname = 'node-x'})
  local state_warn, result = rabbitmq_warning:evaluate()
  assertEquals(rabbitmq_warning.severity, consts.WARN)
  assertEquals(state_warn, consts.WARN)
  assertEquals(#result, 1)  -- only one rule is evaluate since queue != nova
  assertEquals(result[1].value, 123) -- avg()>120

  -- one alarm is warning another is critical
  local afd_state, alerts = lma_alarm.evaluate(next_time(1900))
  assertEquals(#alerts, 2)
  assertEquals(alerts[1].state, state_warn)
  assertEquals(alerts[2].state, consts.CRIT)
  assertEquals(afd_state, consts.CRIT)
end

function TestLMAAlarm:test_fields_match()
  lma_alarm.load_alarms(alarms)
  lma_alarm.set_start_time(current_time)

  lma_alarm.add_value(next_time(), 'fs_space_percent_free', 6, {fs = '/'})
  lma_alarm.add_value(next_time(), 'fs_space_percent_free', 5)
  lma_alarm.add_value(next_time(), 'fs_space_percent_free', 5, {fs = 'foo'})
  local state, result = lma_alarm.evaluate(next_time(600))
  assertEquals(#result, 6)
  assertEquals(state, consts.DOWN) -- FS-all-no-field severity, the worst one
  local root_fs = lma_alarm.get_alarm('FS-root')
  local state, result = root_fs:evaluate(next_time())
  assertEquals(#result, 1)
  local root_fs = lma_alarm.get_alarm('FS-all')
  local state, result = root_fs:evaluate(next_time())
  assertEquals(#result, 2)
  local root_fs = lma_alarm.get_alarm('FS-all-no-field')
  local state, result = root_fs:evaluate(next_time())
  assertEquals(#result, 3)
end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
