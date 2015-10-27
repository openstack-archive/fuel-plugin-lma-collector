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

local gse_policy = require('gse_policy')
local consts = require('gse_constants')

local test_policy_down = gse_policy.new({
    status='down',
    trigger={
        logical_operator='or',
        rules={{
            ['function']='count',
            arguments={'down'},
            relational_operator='>',
            threshold=0
        }}
    }
})

local test_policy_critical = gse_policy.new({
    status='critical',
    trigger={
        logical_operator='and',
        rules={{
            ['function']='count',
            arguments={'critical'},
            relational_operator='>',
            threshold=0
        }, {
            ['function']='percent',
            arguments={'okay', 'warning'},
            relational_operator='<',
            threshold=50
        }}
    }
})

local test_policy_warning = gse_policy.new({
        status='warning',
        trigger={
            logical_operator='or',
            rules={{
                ['function']='percent',
                arguments={'okay'},
                relational_operator='<',
                threshold=50
            }, {
                ['function']='percent',
                arguments={'warning'},
                relational_operator='>',
                threshold=30
            }}
        }
})

local test_policy_okay = gse_policy.new({
        status='okay'
})

TestGsePolicy = {}

    function TestGsePolicy:test_policy_down()
        assertEquals(test_policy_down.status, consts.DOWN)
        assertEquals(test_policy_down.logical_op, 'or')
        assertEquals(#test_policy_down.rules, 1)
        assertEquals(test_policy_down.rules[1]['function'], 'count')
        assertEquals(#test_policy_down.rules[1].arguments, 1)
        assertEquals(test_policy_down.rules[1].arguments[1], consts.DOWN)
        assertEquals(test_policy_down.rules[1].relational_op, '>')
        assertEquals(test_policy_down.rules[1].threshold, 0)
        assertEquals(test_policy_down.require_percent, false)
    end

    function TestGsePolicy:test_policy_okay_evaluate()
        local facts = {
            [consts.OKAY]=5,
            [consts.WARN]=0,
            [consts.CRIT]=0,
            [consts.DOWN]=0,
            [consts.UNKW]=0,
        }
        assertEquals(test_policy_okay:evaluate(facts), true)
    end

    function TestGsePolicy:test_policy_warn_evaluate()
        local facts = {
            [consts.OKAY]=2,
            [consts.WARN]=2,
            [consts.CRIT]=0,
            [consts.DOWN]=0,
            [consts.UNKW]=1,
        }
        assertEquals(test_policy_warning:evaluate(facts), true)
    end

    function TestGsePolicy:test_policy_warn_evaluate_again()
        local facts = {
            [consts.OKAY]=3,
            [consts.WARN]=2,
            [consts.CRIT]=0,
            [consts.DOWN]=0,
            [consts.UNKW]=0,
        }
        assertEquals(test_policy_warning:evaluate(facts), true)
    end

    function TestGsePolicy:test_policy_crit_evaluate()
        local facts = {
            [consts.OKAY]=1,
            [consts.WARN]=1,
            [consts.CRIT]=3,
            [consts.DOWN]=0,
            [consts.UNKW]=0,
        }
        assertEquals(test_policy_critical:evaluate(facts), true)
    end

    function TestGsePolicy:test_policy_down_evaluate()
        local facts = {
            [consts.OKAY]=2,
            [consts.WARN]=2,
            [consts.CRIT]=0,
            [consts.DOWN]=1,
            [consts.UNKW]=0,
        }
        assertEquals(test_policy_down:evaluate(facts), true)
    end

lu = LuaUnit
lu:setVerbosity( 1 )
os.exit( lu:run() )
