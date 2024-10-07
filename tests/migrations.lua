---@diagnostic disable: missing-fields

local migrations = require("scripts.migrations")
local test_util = require("tests.test_util")
local util = require("util")

local migration_tests = { tests = { } }
local tests = migration_tests.tests

local function trigger_migrations()
    storage.migrations = { }
    migrations.on_configuration_changed{}
end

function tests.fix_crazy_distance_walked()
    local player = game.player
    if not player then error("BAD") end
    local player_data = storage.statistics.players[player.index]

    player_data.distance_walked = 9200*1000
    trigger_migrations()
    test_util.assert_equal(player_data.distance_walked, 9200*1000)

    player_data.distance_walked = 15000*1000
    trigger_migrations()
    test_util.assert_equal(player_data.distance_walked, 0)
end

return migration_tests