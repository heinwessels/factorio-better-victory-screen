---@diagnostic disable: need-check-nil, duplicate-set-field, missing-fields

local trigger = require("scripts.trigger")
local test_util = require("tests.test_util")

local trigger_tests = { tests = { } }
local tests = trigger_tests.tests

function trigger_tests.setup()
    -- Reset state
    global.disable_vanilla_victory = nil
    global.finished = nil


    game.reset_game_state()
    test_util.reset_surface()
end

function tests.on_init_config_vanilla_victory_expected()
    trigger.on_init()
    trigger.on_configuration_changed()

    test_util.assert_falsy(global.disable_vanilla_victory)
end

function tests.remote_disable_vanilla_victory()
    test_util.assert_falsy(global.disable_vanilla_victory)

    remote.call("better-victory-screen", "set_no_victory", true)

    test_util.assert_true(global.disable_vanilla_victory)
end

function tests.remote_disable_vanilla_victory_migrate_after_recorded_victory()
    test_util.assert_falsy(global.disable_vanilla_victory)

    global.finished = true

    remote.call("better-victory-screen", "set_no_victory", true)

    test_util.assert_falsy(global.finished)
    test_util.assert_true(global.disable_vanilla_victory)
end

function tests.on_rocket_vanilla_trigger_victory()
    local surface = test_util.get_surface()

    local called = false
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(winning_force, override, winning_message, losing_message)
        called = true
        test_util.assert_equal(winning_force, game.player.force)
        test_util.assert_nil(override)
        test_util.assert_nil(winning_message)
        test_util.assert_nil(winning_message)
    end

    local rocket = surface.create_entity{name="iron-chest", force="player", position={0, 0}}
    test_util.assert_valid_entity(rocket)
    if not rocket then return error("What?") end -- Assert should catch this
    trigger.events[defines.events.on_rocket_launched]({rocket = rocket})

    test_util.assert_true(called)
    trigger.attempt_trigger_victory = store_function
end

function tests.on_rocket_vanilla_disabled_doesnt_trigger_victory()
    local surface = test_util.get_surface()

    global.disable_vanilla_victory = true

    local called = false
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(_, _, _, _)
        called = true
    end

    local rocket = surface.create_entity{name="iron-chest", force="player", position={0, 0}}
    test_util.assert_valid_entity(rocket)
    if not rocket then return error("What?") end -- Assert should catch this
    trigger.events[defines.events.on_rocket_launched]({rocket = rocket})

    test_util.assert_false(called)
    trigger.attempt_trigger_victory = store_function
end

function tests.remote_trigger_victory()
    global.disable_vanilla_victory = true

    local called = false
    local store_function = trigger.attempt_trigger_victory
    trigger.attempt_trigger_victory = function(winning_force, override, winning_message, losing_message)
        called = true
        test_util.assert_equal(winning_force, game.player.force)
        test_util.assert_nil(override)
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)
    end

    remote.call("better-victory-screen", "trigger_victory", game.forces.player)

    test_util.assert_true(called)
    trigger.attempt_trigger_victory = store_function
end

function tests.remote_trigger_victory_valid_winning_and_losing_message()
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

function tests.remote_trigger_victory_no_winning_but_losing_message()
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

function tests.remote_trigger_victory_no_winning_or_losing_message()
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

function tests.attempt_trigger_victory_show_victory()
    local store_function = trigger.show_victory_screen

    local called = false
    trigger.show_victory_screen = function(winning_force, winning_message, losing_message)
        called = true
        test_util.assert_equal(winning_force, game.player.force)
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)
    end

    trigger.attempt_trigger_victory(game.player.force)

    test_util.assert_true(called)
    trigger.show_victory_screen = store_function
end

function tests.attempt_trigger_victory_show_victory_ignore_second_time()
    local store_function = trigger.show_victory_screen

    local count = 0
    trigger.show_victory_screen = function(winning_force, winning_message, losing_message)
        count = count + 1
        test_util.assert_equal(winning_force, game.player.force)
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)
    end

    trigger.attempt_trigger_victory(game.player.force)
    trigger.attempt_trigger_victory(game.player.force)

    test_util.assert_equal(count, 1)
    trigger.show_victory_screen = store_function
end

function tests.attempt_trigger_victory_show_victory_override_doesnt_ignore_second_time()
    local store_function = trigger.show_victory_screen

    local count = 0
    trigger.show_victory_screen = function(winning_force, winning_message, losing_message)
        count = count + 1
        test_util.assert_equal(winning_force, game.player.force)
        test_util.assert_nil(winning_message)
        test_util.assert_nil(losing_message)
    end

    trigger.attempt_trigger_victory(game.player.force)
    trigger.attempt_trigger_victory(game.player.force, true)

    test_util.assert_equal(count, 2)
    trigger.show_victory_screen = store_function
end

return trigger_tests