---@diagnostic disable: missing-fields

local statistics = require("scripts.statistics")
local test_util = require("tests.test_util")
local util = require("util")

local statistics_tests = { tests = { } }
local tests = statistics_tests.tests

function tests.on_init_and_config_determine_ores()
    local backup = storage.statistics

    storage.statistics = { } -- Reset
    statistics.on_init({})
    test_util.assert_greater_than(#storage.statistics.ore_names, 0)

    storage.statistics = { } -- Reset
    statistics.on_configuration_changed({})
    test_util.assert_greater_than(#storage.statistics.ore_names, 0)

    storage.statistics = backup
end

function tests.on_player_changed_position_straight()
    local player = game.player
    if not player then error("BAD") end
    local player_data = storage.statistics.players[player.index]

    player_data.distance_walked = 10
    player_data.last_posistion = nil

    player.teleport({0, 0})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    player.teleport({0, 2})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    test_util.assert_equal(player_data.distance_walked, 12)

    player.teleport({4, 2})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    test_util.assert_equal(player_data.distance_walked, 16)
end

function tests.on_player_changed_position_diagonal()
    local player = game.player
    if not player then error("BAD") end
    local player_data = storage.statistics.players[player.index]

    player_data.distance_walked = 10
    player_data.last_posistion = nil

    player.teleport({0, 0})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    player.teleport({2, 3})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    test_util.assert_near(player_data.distance_walked, 13.605, 0.05)
end

function tests.on_player_changed_position_unreasonable_ignored()
    local player = game.player
    if not player then error("BAD") end
    local player_data = storage.statistics.players[player.index]

    player_data.distance_walked = 10
    player_data.last_posistion = nil

    player.teleport({0, 0})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    player.teleport({0, 1000})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    test_util.assert_equal(player_data.distance_walked, 10)

    player.teleport({0, 0}) -- Bring player back to not be annoying
end

function tests.player_time_on_new_surface()
    local player = game.player
    if not player then error("BAD") end
    local times_on_surfaces = storage.statistics.players[player.index].times_on_surfaces

    statistics.on_nth_tick[60]{tick=1, nth_tick=60}
    test_util.assert_greater_than(times_on_surfaces["nauvis"], 0)
    local previous_nauvis_time = times_on_surfaces["nauvis"]

    local new_surface = game.create_surface("new_surface")
    player.teleport({0, 0}, new_surface)

    statistics.on_nth_tick[60]{tick=1, nth_tick=60}
    test_util.assert_equal(times_on_surfaces["new_surface"], 60)
    test_util.assert_equal(times_on_surfaces["nauvis"], previous_nauvis_time)
    statistics.on_nth_tick[60]{tick=1, nth_tick=60}
    test_util.assert_equal(times_on_surfaces["new_surface"], 120)
    test_util.assert_equal(times_on_surfaces["nauvis"], previous_nauvis_time)
end

function tests.player_time_on_renamed_surface()
    local player = game.player
    if not player then error("BAD") end
    local times_on_surfaces = storage.statistics.players[player.index].times_on_surfaces
    local surface = game.get_surface("new_surface")

    test_util.assert_greater_than(times_on_surfaces["new_surface"], 0)
    local ticks = times_on_surfaces["new_surface"]
    test_util.assert_nil(times_on_surfaces["renamed"])

    surface.name = "renamed"

    test_util.assert_equal(times_on_surfaces["renamed"], ticks)
    test_util.assert_nil(times_on_surfaces["new_surface"])
end

function tests.delete_surface_doesnt_clear_time()
    local player = game.player
    if not player then error("BAD") end
    local times_on_surfaces = storage.statistics.players[player.index].times_on_surfaces
    local prev_time = times_on_surfaces["renamed"]
    test_util.assert_greater_than(prev_time, 0)

    player.teleport({0, 0}, "nauvis")
    game.delete_surface("renamed") -- Only happens later, so techincally this test is flawed. Need multi-tick tests.

    test_util.assert_equal(times_on_surfaces["renamed"], prev_time)
end

return statistics_tests