---@diagnostic disable: need-check-nil, duplicate-set-field

local trigger = require("scripts.trigger")
local test_util = require("tests.test_util")

local trigger_tests = { tests = { } }
local tests = trigger_tests.tests

function tests.trigger_victory_valid_winning_and_losing_message()
    local store_function = trigger.attempt_trigger_victory

    local called = false
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        called = true
        test_util.assert_table_equal(winning_message, {"item-name.iron-plate"})
        test_util.assert_string_equal(losing_message, "what")
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false,
        {"item-name.iron-plate"},
        "what"
    )

    test_util.assert_true(called)
    trigger.attempt_trigger_victory = store_function
end

function tests.trigger_victory_no_winning_but_losing_message()
    local store_function = trigger.attempt_trigger_victory

    local called = false
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        called = true
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false,
        nil,
        "can't have a losing message but no winning message because."
    )

    test_util.assert_true(called)
    trigger.attempt_trigger_victory = store_function
end

function tests.trigger_victory_no_winning_or_losing_message()
    local store_function = trigger.attempt_trigger_victory

    local called = false
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        called = true
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false
    )

    test_util.assert_true(called)
    trigger.attempt_trigger_victory = store_function
end


return trigger_tests