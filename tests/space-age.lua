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
    player.teleport({5, 0}, "fulgora")
    player.teleport({0, 5}, "fulgora")
    player.teleport({5, 0}, "vulcanus")
    player.teleport({0, 5}, "nauvis")

    test_util.assert_equal(player_data.times_visited_planet["vulcanus"], 2)
    test_util.assert_equal(player_data.times_visited_planet["fulgora"], 1)
    test_util.assert_equal(player_data.times_visited_planet["nauvis"], 1)
end

function tests.biters_hatched()
    local player = game.player
    if not player then error("BAD") end
    
    local surface = game.player.surface
    storage.space_age.biter_eggs_hatched = 0
    local expected = 5

    for i=1,5 do
        local entities = surface.spill_item_stack{ position = { 0, 0}, stack = {name = "biter-egg", count = 1 }}
        test_util.assert_equal(#entities, 1)        
        entities[1].stack.item.item_stack.spoil()
    end

    test_util.assert_equal(storage.space_age.biter_eggs_hatched, expected)
    game.forces["enemy"].kill_all_units()
end

function tests.busiest_platform()
    local force = game.forces["player"]

    -- Make sure our platforms beat any that might already exist
    local existing_max = 0
    for _, platform in pairs(force.platforms) do
        existing_max = math.max(existing_max, platform.completed_trips)
    end

    local function create(name, trips, hidden)
        local platform = force.create_space_platform{ name = name, planet = "nauvis", starter_pack = "space-platform-starter-pack" }
        if not platform then error("Failed to create platform '"..name.."'") end
        platform.completed_trips = existing_max + trips
        platform.hidden = hidden
        return platform
    end

    local quiet = create("bvs-test-quiet", 1, false)
    local busy = create("bvs-test-busy", 5, false)
    local hidden = create("bvs-test-hidden", 10, true) -- Busiest, but hidden so should be ignored

    local busiest = space_age.get_busiest_platform(force)
    test_util.assert_not_nil(busiest)
    ---@cast busiest -?
    test_util.assert_equal(busiest.name, "bvs-test-busy")
    test_util.assert_equal(busiest.completed_trips, existing_max + 5)

    for _, platform in pairs({ quiet, busy, hidden }) do platform.destroy() end
end

return space_age_tests