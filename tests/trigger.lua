---@diagnostic disable: need-check-nil, duplicate-set-field, missing-fields

local trigger = require("scripts.trigger")
local test_util = require("tests.test_util")

local trigger_tests = { tests = { } }
local tests = trigger_tests.tests

function trigger_tests.setup()
    -- Reset state
    storage.disable_vanilla_victory = nil
    storage.finished = nil


    game.reset_game_state()
    test_util.reset_surface()
end

function tests.on_init_config_vanilla_victory_expected()
    trigger.on_init()
    trigger.on_configuration_changed()

    test_util.assert_falsy(storage.disable_vanilla_victory)
end

function tests.remote_disable_vanilla_victory()
    test_util.assert_falsy(storage.disable_vanilla_victory)

    remote.call("better-victory-screen", "set_no_victory", true)

    test_util.assert_true(storage.disable_vanilla_victory)
end

function tests.on_pre_scenario_finished_triggers()
    local called = false
    local store_function = trigger.attempt_trigger_victory
    trigger.show_victory_screen = function() called = true end -- Mock

    game.set_game_state({player_won = true, can_continue = true})
    trigger.events[defines.events.on_pre_scenario_finished]()

    test_util.assert_true(called)
    test_util.assert_true(game.finished_but_continuing)
    trigger.show_victory_screen = store_function
end

function tests.gather_statistics_by_force()
    local statistics_to_gather = { by_force = {
        ["player"] = {
            ["gymnastics"] = { order = "b", stats = {
                ["highest-jump"] = { value = 100000, unit="distance"}
            }}
        }
    }}

    local store_function = trigger.remote
    local called = false
    trigger.remote = {
        interfaces = { ["mock-interface"] = util.list_to_map{trigger.gather_function_name} },
        call = function(interface, function_name, forces)
            called = true
            test_util.assert_string_equal(interface, "mock-interface")
            test_util.assert_string_equal(function_name, trigger.gather_function_name)
            test_util.assert_table_equal(forces, {game.player.force})
            return statistics_to_gather
        end
    }

    local statistics = trigger.gather_statistics({game.player.force})
    test_util.assert_true(called)
    test_util.assert_table_equal(statistics, { by_force = {
        ["player"] = {
            ["gymnastics"] = { order = "b", stats = {
                ["highest-jump"] = { value = 100000, unit="distance"}
            }}
        }
    }, by_player = { }})

    trigger.remote = store_function
end

function tests.gather_statistics_by_force_merge_multiple()
    local statistics_to_gather_A = { by_force = {
        ["player"] = {
            ["gymnastics"] = { order = "b", stats = {
                ["highest-jump"] = { value = 100000, unit="distance"}
            }}
        }
    }}
    local statistics_to_gather_B = { by_force = {
        ["player"] = {
            ["hobbies"] = { order = "c", stats = {
                ["gnome-collection"] = { value = 500 }
            }}
        },
        ["enemy"] = {
            ["hobbies"] = { order = "d", stats = {
                ["stamp-collection"] = { value = 2 }
            }}
        },
    }}

    local called_a = false
    local called_b = false
    local store_function = trigger.remote
    trigger.remote = {
        interfaces = {
            ["interface-a"] = util.list_to_map{trigger.gather_function_name},
            ["interface-b"] = util.list_to_map{trigger.gather_function_name},
        },
        call = function(interface, function_name, winning_force, forces)
            if interface == "interface-a" then
                called_a = true
                return statistics_to_gather_A
            elseif interface == "interface-b" then
                called_b = true
                return statistics_to_gather_B
            end
            error("Should never reach here")
        end
    }

    local statistics = trigger.gather_statistics({game.player.force})
    test_util.assert_true(called_a)
    test_util.assert_true(called_b)
    test_util.assert_table_equal(statistics, {
        by_force = {
            ["player"] = {
                ["gymnastics"] = { order = "b", stats = {
                    ["highest-jump"] = { value = 100000, unit="distance"}
                }},
                ["hobbies"] = { order = "c", stats = {
                    ["gnome-collection"] = { value = 500 }
                }},
            },
            ["enemy"] = {
                ["hobbies"] = { order = "d", stats = {
                    ["stamp-collection"] = { value = 2 }
                }}
            },
        },
        by_player = { }, -- Just something the function does
    })

    trigger.remote = store_function
end

function tests.gather_statistics_call_error_debug_death()
    local store_function = trigger.remote
    trigger.remote = {
        interfaces = { ["mock-interface"] = util.list_to_map{trigger.gather_function_name} },
        call = function(interface, function_name, winning_force, forces)
            test_util.assert_string_equal(interface, "mock-interface")
            test_util.assert_string_equal(function_name, trigger.gather_function_name)
            test_util.assert_equal(winning_force, game.player.force)
            test_util.assert_table_equal(forces, {game.player.force})
            error("Other mod made a mistake in the code. Oops")
        end
    }

    test_util.assert_death(trigger.gather_statistics, {game.player.force --[[@as LuaForce]], {game.player.force}})

    trigger.remote = store_function
end

function tests.gather_statistics_call_error_release_ignore()
    test_util.mock_release()

    local store_function = trigger.remote
    trigger.remote = {
        interfaces = { ["mock-interface"] = util.list_to_map{trigger.gather_function_name} },
        call = function(interface, function_name, winning_force, forces)
            test_util.assert_string_equal(interface, "mock-interface")
            test_util.assert_string_equal(function_name, trigger.gather_function_name)
            test_util.assert_equal(winning_force, game.player.force)
            test_util.assert_table_equal(forces, {game.player.force})
            error("Other mod made a mistake in the code. Oops")
        end
    }

    trigger.gather_statistics({game.player.force})
    -- Nothing useful to do with result. Just check that it doesn't crash

    trigger.remote = store_function
end

function tests.gather_statistics_return_nil_release_ignore()
    test_util.mock_release()

    local store_function = trigger.remote
    trigger.remote = {
        interfaces = { ["mock-interface"] = util.list_to_map{trigger.gather_function_name} },
        call = function() return nil end
    }

    trigger.gather_statistics({game.player.force})
    -- Nothing useful to do with result. Just check that it doesn't crash

    trigger.remote = store_function
end

function tests.gather_statistics_return_non_table_release_ignore()
    test_util.mock_release()

    local store_function = trigger.remote
    trigger.remote = {
        interfaces = { ["mock-interface"] = util.list_to_map{trigger.gather_function_name} },
        call = function() return 6 end
    }

    trigger.gather_statistics({game.player.force})
    -- Nothing useful to do with result. Just check that it doesn't crash

    trigger.remote = store_function
end

return trigger_tests