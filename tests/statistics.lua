---@diagnostic disable: missing-fields

local statistics = require("scripts.statistics")
local test_util = require("tests.test_util")
local util = require("util")

local statistics_tests = { tests = { } }
local tests = statistics_tests.tests

function tests.on_init_and_config_determine_ores()
    local backup = global.statistics

    global.statistics = { } -- Reset
    statistics.on_init({})
    test_util.assert_greater_than(#global.statistics.ore_names, 0)

    global.statistics = { } -- Reset
    statistics.on_configuration_changed({})
    test_util.assert_greater_than(#global.statistics.ore_names, 0)

    global.statistics = backup
end

function tests.on_player_changed_position_straight()
    local player = game.player
    if not player then error("BAD") end
    local player_data = global.statistics.players[player.index]

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
    local player_data = global.statistics.players[player.index]

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
    local player_data = global.statistics.players[player.index]

    player_data.distance_walked = 10
    player_data.last_posistion = nil

    player.teleport({0, 0})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    player.teleport({0, 1000})
    statistics.events[defines.events.on_player_changed_position]{player_index=player.index}

    test_util.assert_equal(player_data.distance_walked, 10)

    player.teleport({0, 0}) -- Bring player back to not be annoying
end

return statistics_tests