---@diagnostic disable: missing-fields

if not script.active_mods["space-age"] then return { } end

local space_age = require("scripts.compatibility.space-age")
local test_util = require("tests.test_util")
local util = require("util")

local space_age_tests = { tests = { } }
local tests = space_age_tests.tests

function tests.player_visited_planets()
    local player = game.player
    if not player then error("BAD") end

    ---@type SpaceAgePlayerStatistics
    local player_data = storage.space_age.players[player.index]
    player_data.last_visited_name = nil
    player_data.times_visited_planet = { }

    test_util.assert_true(player.surface.name == "nauvis")

    player.teleport({0, 5}, "vulcanus")
    space_age.on_player_changed_position({ player_index = player.index})
    player.teleport({5, 0}, "fulgora")
    space_age.on_player_changed_position({ player_index = player.index})
    player.teleport({0, 5}, "fulgora")
    space_age.on_player_changed_position({ player_index = player.index})
    player.teleport({5, 0}, "vulcanus")
    space_age.on_player_changed_position({ player_index = player.index})
    player.teleport({0, 5}, "nauvis")
    space_age.on_player_changed_position({ player_index = player.index})

    test_util.assert_equal(player_data.times_visited_planet["vulcanus"], 2)
    test_util.assert_equal(player_data.times_visited_planet["fulgora"], 1)
    test_util.assert_equal(player_data.times_visited_planet["nauvis"], 1)
end

return space_age_tests