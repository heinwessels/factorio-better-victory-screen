---@diagnostic disable: need-check-nil

local tracker = require("scripts.tracker")
local test_util = require("tests.test_util")

local tracker_tests = { tests = { } }
local tests = tracker_tests.tests

---@return LuaSurface
local function get_surface() return game.surfaces.nauvis end

---@return LuaSurface
local function reset_surface()
    local surface = get_surface()

    -- Clear the surface. Can't use surface.clear because that removes the chunks
    -- as well, which acts weird when placing entities on them now.
    for _, entity in pairs(surface.find_entities_filtered{}) do
        entity.destroy { raise_destroy = true }
    end

    return surface
end

---Return a force with given name. Create it if neccesary

---@param force_name string
---@return LuaForce
local function get_force_with_name(force_name)
    local force = game.forces[force_name]

    if not force then
        -- Let's assume there is not 64 forces created.
        force = game.create_force(force_name)
    end

    -- Mimick a player coming into this force by mimicking an event
    ---@diagnostic disable-next-line: missing-fields
    tracker.on_player_changed_force{ force = { name = force_name}}

    return force
end

-- Resets the trackers internal state
local function reset_tracker()
    ---@type TrackerGlobalData
    local tracker_cache = global["_bvs_tracker_cache"]
    for _, tracker_to_reset in pairs(tracker_cache.trackers) do
        tracker_to_reset.counters = { }
        tracker_to_reset.tracking = { }
    end
    tracker_cache.tracked_forces = { ["player"] = true }
end

---This is a sneaky function to trick the tracker to think
---the last calculation was done in the previous tick, because
---all these tests will be executed in the same tick. It relies
---heavily on the internals of the tracker, so it might break
---at any time, but it's less maintenance than allowing tests
---to pass time.
local function decrease_last_recalculation_by_one_tick()
    ---@type table<TrackerType, TrackerClass>
    local trackers = global["_bvs_tracker_cache"].trackers
    for _, tracker in pairs(trackers) do
        for _, force_counter in pairs(tracker.counters) do
            for _, counter in pairs(force_counter) do
                if counter.last_recount then
                    counter.last_recount = counter.last_recount - 1
                end
            end
        end
    end
end

function tracker_tests.setup()
    reset_surface()
    reset_tracker()
end

function tests.runtime_count_by_name()
    local surface = get_surface()

    tracker.track_entity_count_by_name("iron-chest")
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        0
    )

    local chest = surface.create_entity{
        name = "iron-chest", position = {0, 0},
        force="player", raise_built = true,
    }
    test_util.assert_valid_entity(chest)
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        1
    )

    chest.destroy{raise_destroy=true}
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        0
    )
end

function tests.recount_count_by_name()
    local surface = get_surface()
    local N = 5

    for x=1,N do
        local chest = surface.create_entity{
            name = "iron-chest", position = {x, 0},
            force="player", raise_built = true,
        }
        test_util.assert_valid_entity(chest)
    end

    -- This will trigger a recount
    tracker.track_entity_count_by_name("iron-chest")
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        N
    )

    -- This will be an dynamic count
    local chest = surface.create_entity{
        name = "iron-chest", position = {N+1, 0},
        force="player", raise_built = true,
    }
    test_util.assert_valid_entity(chest)
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        N + 1
    )

    -- Trigger another recount
    decrease_last_recalculation_by_one_tick()
    tracker.on_configuration_changed()
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        N + 1
    )

    -- Now create an entity without raising the event. This means
    -- the tracker won't know about it until the next recount. This
    -- will be a good test if the recount actually works.
    chest = surface.create_entity{
        name = "iron-chest", position = {N+1, 0},
        force="player", raise_built = false --[[ IMPORTANT ]],
    }
    test_util.assert_valid_entity(chest)
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        N + 1 --[[ Actually N+2 but tracker doesn't know ]]
    )

    -- Now trigger the recound
    decrease_last_recalculation_by_one_tick()
    tracker.on_configuration_changed()
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        N + 2
    )

    -- Make sure dynamic downcouting still works
    chest.destroy{raise_destroy=true}
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        N + 1
    )
end

function tests.count_by_name_multiple_forces_dynamic()
    local surface = get_surface()

    local teams = {
        {
            force_name  = "player",
            N           = 10,
        },
        {
            force_name  = get_force_with_name("other").name,
            N           = 15,
        },
    }

    tracker.track_entity_count_by_name("iron-chest")

    -- Nothing has been created yet, counter should be zero
    for _, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name, "iron-chest"),
            0
        )
    end

    -- Create a different amount of item for each team
    for index, team in pairs(teams) do
        for x=1,team.N do
            local chest = surface.create_entity{
                name = "iron-chest", position = {x, index},
                force=team.force_name, raise_built = true,
            }
            test_util.assert_valid_entity(chest)
        end
    end

    -- Make sure the tracker knows about the new entities
    for index, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name, "iron-chest"),
            team.N
        )
    end

    -- Make sure removing still works by removing a different amount
    -- from each force
    for index, team in pairs(teams) do
        for i=1,index do
            local chest = surface.find_entities_filtered{
                name="iron-chest", force=team.force_name, limit = 1}[1]
            chest.destroy{raise_destroy=true}
        end
    end

    -- Make sure the tracker knows some entities are deleted
    for index, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name, "iron-chest"),
            team.N - index
        )
    end
end

function tests.count_by_name_multiple_forces_recount()
    local surface = get_surface()

    local teams = {
        {
            force_name  = "player",
            N           = 10,
        },
        {
            force_name  = get_force_with_name("other").name,
            N           = 15,
        },
    }

    tracker.track_entity_count_by_name("iron-chest")

    for _, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name, "iron-chest"),
            0
        )
    end

    -- Create chests silently
    for index, team in pairs(teams) do
        for x=1,team.N do
            local chest = surface.create_entity{
                name = "iron-chest", position = {x, index},
                force=team.force_name, raise_built = false --[[ IMPORTANT ]],
            }
            test_util.assert_valid_entity(chest)
        end
    end

    -- Counters should still read zero
    for _, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name, "iron-chest"),
            0
        )
    end

    -- Trigger a recound by mimicking on_configuration_changed
    decrease_last_recalculation_by_one_tick()
    tracker.on_configuration_changed()

    -- Counters should now be correct
    for _, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name, "iron-chest"),
            team.N
        )
    end

    -- Make sure removing still works by removing a different amount
    -- from each force
    for index, team in pairs(teams) do
        for i=1,index do
            local chest = surface.find_entities_filtered{
                name="iron-chest", force=team.force_name, limit = 1}[1]
            chest.destroy{raise_destroy=true}
        end
    end

    -- Make sure the tracker knows some entities are deleted
    for index, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name, "iron-chest"),
            team.N - index
        )
    end
end

function tests.retreive_count_for_untracked_force()
    tracker.track_entity_count_by_name("iron-chest")
    test_util.assert_death(
        tracker.get_entity_count_by_name, {"enemy", "iron-chest"},
        "Untracked force counter requested"
    )
end

function tests.merge_forces_both_tracked()
    local surface = get_surface()

    local teams = {
        {
            force_name  = get_force_with_name("a").name,
            N           = 10,
        },
        {
            force_name  = get_force_with_name("b").name,
            N           = 15,
        },
    }

    tracker.track_entity_count_by_name("iron-chest")

    -- Nothing has been created yet, counter should be zero
    for _, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name --[[@as ForceName]], "iron-chest"),
            0
        )
    end

    -- Create a different amount of item for each team
    for index, team in pairs(teams) do
        for x=1,team.N do
            local chest = surface.create_entity{
                name = "iron-chest", position = {x, index},
                force=team.force_name, raise_built = true,
            }
            test_util.assert_valid_entity(chest)
        end
    end

    -- Make sure the tracker knows about the new entities
    for _, team in pairs(teams) do
        test_util.assert_equal(
            tracker.get_entity_count_by_name(team.force_name --[[@as ForceName]], "iron-chest"),
            team.N
        )
    end

    -- Now do the force merge. We will mimick this because 
    -- it doesn't complete within this tick
    ---@diagnostic disable-next-line: missing-fields
    tracker.on_forces_merged{
        source_name = "a",
        destination = { name = "b"},
    } -- Merge force a into force b
    local combined_N = teams[1].N + teams[2].N

    -- Now the receiving force should have the total count of both teams
    test_util.assert_equal(
        tracker.get_entity_count_by_name("b", "iron-chest"),
        combined_N
    )

    -- And requesting the count of the deleted force should be death!
    test_util.assert_death(
        tracker.get_entity_count_by_name, {"a", "iron-chest"},
        "Untracked force counter requested"
    )
end

function tests.merge_forces_source_untracked()
    local surface = get_surface()
    local untracked = "EE_TESTFORCE_vogon"

    local teams = {
        {
            force_name  = get_force_with_name(untracked).name,
            N           = 10,
        },
        {
            force_name  = "player",
            N           = 15,
        },
    }

    tracker.track_entity_count_by_name("iron-chest")

    -- Create a different amount of item for each team
    -- Do this anyway to ensure the count is now ignored
    for index, team in pairs(teams) do
        for x=1,team.N do
            local chest = surface.create_entity{
                name = "iron-chest", position = {x, index},
                force=team.force_name, raise_built = true,
            }
            test_util.assert_valid_entity(chest)
        end
    end

    -- Make sure the count is there, and the untracked is ignored
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        teams[2].N
    )
    test_util.assert_death(tracker.get_entity_count_by_name, {untracked, "iron-chest"})

    -- Now merge the untracked into the tracked force. We will mimick this because 
    -- it doesn't complete within this tick
    ---@diagnostic disable-next-line: missing-fields
    tracker.on_forces_merged {
        source_name = untracked,
        destination = { name = "untracked"},
    }

    -- Now make sure the counts remain the same
    test_util.assert_equal(
        tracker.get_entity_count_by_name("player", "iron-chest"),
        teams[2].N
    )
    test_util.assert_death(tracker.get_entity_count_by_name, {untracked, "iron-chest"})
end

function tests.merge_forces_destination_untracked()
    local surface = get_surface()

    local tracked = "tracked"
    local untracked = "EE_TESTFORCE_vogon"

    local teams = {
        {
            force_name  = get_force_with_name(untracked).name,
            N           = 10,
        },
        {
            force_name  = get_force_with_name(tracked).name,
            N           = 15,
        },
    }

    tracker.track_entity_count_by_name("iron-chest")

    -- Create a different amount of item for each team
    -- Do this anyway to ensure the count is now ignored
    for index, team in pairs(teams) do
        for x=1,team.N do
            local chest = surface.create_entity{
                name = "iron-chest", position = {x, index},
                force=team.force_name, raise_built = true,
            }
            test_util.assert_valid_entity(chest)
        end
    end

    -- Make sure the count is there, and the untracked is ignored
    test_util.assert_equal(
        tracker.get_entity_count_by_name(tracked, "iron-chest"),
        teams[2].N
    )
    test_util.assert_death(tracker.get_entity_count_by_name, {untracked, "iron-chest"})

    -- Now merge the tracked force into the untracked force.
    -- We will mimick this because it doesn't complete within this tick
    ---@diagnostic disable-next-line: missing-fields
    tracker.on_forces_merged {
        source_name = tracked,
        destination = { name = untracked},
    }

    -- Now make sure the counts are now available
    test_util.assert_death(tracker.get_entity_count_by_name, {tracked, "iron-chest"})
    test_util.assert_death(tracker.get_entity_count_by_name, {untracked, "iron-chest"})
end

return tracker_tests