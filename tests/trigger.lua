---@diagnostic disable: need-check-nil, duplicate-set-field

local trigger = require("scripts.trigger")
local test_util = require("tests.test_util")

local trigger_tests = { tests = { } }
local tests = trigger_tests.tests

function tests.trigger_victory_valid_winning_and_losing_message()
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        test_util.assert_table_equal(winning_message, {"entity-name.iron-plate"})
        test_util.assert_string_equal(losing_message, "what")
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false,
        {"entity-name.iron-plate"},
        "what"
    )

    trigger.attempt_trigger_victory = store_function
end

function tests.trigger_victory_valid_winning_message()
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        test_util.assert_string_equal(winning_message, "what")
        test_util.assert_nil(losing_message)
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false,
        "what"
    )

    trigger.attempt_trigger_victory = store_function
end

function tests.trigger_victory_nil_winning_and_valid_losing_message()
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false,
        nil,
        "what"
    )

    trigger.attempt_trigger_victory = store_function
end

function tests.trigger_victory_invalid_winningmessage()
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)    -- Force losing to nil if no valid winnig
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false,
        game.forces.player -- This is not a valid message
    )

    trigger.attempt_trigger_victory = store_function
end

function tests.trigger_victory_invalid_winning_and_valid_losing_message()
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)    -- Force losing to nil if no valid winnig
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false,
        game.forces.player, -- This is not a valid message
        "hello"
    )

    trigger.attempt_trigger_victory = store_function
end

function tests.trigger_victory_valid_winning_and_invalid_losing_message()
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(_, _, winning_message, losing_message)
        test_util.assert_table_equal(winning_message, {"entity-name.iron-plate"})
        test_util.assert_nil(losing_message)
    end

    remote.call("better-victory-screen", "trigger_victory",
        game.forces.player,
        false,
        {"entity-name.iron-plate"},
        game.forces.player      -- invalid
    )

    trigger.attempt_trigger_victory = store_function
end

return trigger_tests