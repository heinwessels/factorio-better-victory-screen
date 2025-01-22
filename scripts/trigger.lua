local util = require("util")
local statistics = require("scripts.statistics")
local compatibility = require("scripts.compatibility")
local debug = require("scripts.debug")
local builder = require("scripts.builder")

local trigger = { }
trigger.gather_function_name = "better-victory-screen-statistics"

trigger.remote = remote
--- Gather statistics from other mods
---@param forces LuaForce[]   list of forces that the GUI will be shown to
function trigger.gather_statistics(forces)
    local gathered_statistics = { by_force = { }, by_player = { } }
    for interface, functions in pairs(trigger.remote.interfaces) do
        if functions[trigger.gather_function_name] then
            -- We don't know the quality of the other mod's code and if it will return the correct things.
            -- So we will wrap it all in a pcall. This includes remote call, as well as merging the returned
            -- stats into our stats. That way we don't really need to sanitize the data. It's also okay because
            -- downstream code is written to be robust as well and make any expectations about the data.
            local success, error_message = pcall(function()
                local mod_statistics = trigger.remote.call(interface, trigger.gather_function_name, forces)
                gathered_statistics = util.merge{gathered_statistics, mod_statistics --[[@as table]]}
                log("Successfully gathered statistics from: " .. interface)
            end)
            debug.debug_assert(success, error_message)
        end
    end
    return gathered_statistics
end

---@return LuaForce? force to show statistics of
---@return LuaPlayer? player to show statistics of (if there's only one player)
function trigger.get_observers()
    ---@type LuaForce?
    local force

    for _, this_force in pairs(game.forces) do
        if table_size(this_force.connected_players) >= 1 then
            force = this_force
            break
        end
    end

    if not force then return end

    local connected_players = force.connected_players
    if #connected_players > 1 then
        -- Too many players, so don't show any player specific stats.
        return force
    end

    return force, connected_players[1]
end

---Show the victory screen for all connected players
function trigger.set_ending_info()

    ---@type table<string, LuaProfiler>
    local profilers = nil
    if true then -- Keep this to false for releases
        profilers = {
            gather          = game.create_profiler(true),
            infrastructure  = game.create_profiler(true),
            peak_power      = game.create_profiler(true),
            chunk_counter   = game.create_profiler(true),
            total           = game.create_profiler(false), -- Start this profiler
        }
    end

    -- Decide who we're gonna show it too.
    local force, player = trigger.get_observers()
    if not force then
        log("[BVS] Could not determine force to show it for, so not showing anything")
        return
    else
        log("[BVS] Showing victory screen for force: " .. force.name .. " and player: " .. (player and player.name or "-"))
    end

    if profilers then profilers.gather.reset() end
    local third_party_statistics = trigger.gather_statistics({ force })
    if profilers then profilers.gather.stop() end

    local compatibility_stats = compatibility.gather({ force })

    local all_statistics = util.merge{ -- Order is important. Later will override previous

        -- Our main statistics
        statistics.for_force(force, profilers),
        player and statistics.for_player(player, profilers) or { },

        -- Our compatability statistics
        compatibility_stats.by_force[force.name] or { },
        player and compatibility_stats.by_player[player.name] or { },

        -- Statistics gathered from other mods
        third_party_statistics.by_force[force.name] or { },
        player and third_party_statistics.by_player[player.name] or { },

    }

    -- Determine message
    local is_space_age = script.active_mods["space-age"]
    local victory_message = {"",
        is_space_age and {"better-victory-screen.victory-message-space-age"} or {"better-victory-screen.victory-message"},
        "\n\n",
        {"better-victory-screen.stats-message"},
        player and {"", " ", {"better-victory-screen.stats-message-player", player.name}} or "",
    }

    game.set_win_ending_info{
        image_path = is_space_age and "__base__/script/freeplay/victory-space-age.png" or "__base__/script/freeplay/victory.png",
        title = {"gui-game-finished.victory"},
        message = builder.unflatten(builder.build( victory_message, all_statistics )),
        final_message = {"victory-final-message"},
    }

    if profilers then
        profilers.total.stop()

        log({"",
            "Statistics collection profiling:\n",
            "\tOther mods: ", profilers.gather, "\n",
            "\tInfrastructure: ", profilers.infrastructure, "\n",
            "\tPeak Power: ", profilers.peak_power, "\n",
            "\tChunk counter: ", profilers.chunk_counter, "\n",
            "\tTOTAL: ", profilers.total, "\n",
        })
    end
end

---@param event EventData.on_pre_scenario_finished
function trigger.on_pre_scenario_finished(event)
    if not event.player_won then return end

    -- Set ending info
    trigger.set_ending_info()
end

trigger.events = {
    [defines.events.on_pre_scenario_finished] = trigger.on_pre_scenario_finished,
}

return trigger
