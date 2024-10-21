local gui = require("scripts.gui")
local util = require("util")
local statistics = require("scripts.statistics")
local compatibility = require("scripts.compatibility")
local debug = require("scripts.debug")

local trigger = { }
trigger.gather_function_name = "better-victory-screen-statistics"

---A list of forces to show the victory screen to
---@return LuaForce[]
local function get_forces_to_show()
    local forces_to_show = { }
    for _, force in pairs(game.forces) do
        if #force.connected_players == 0 then goto continue end
        table.insert(forces_to_show, force)
        ::continue::
    end
    return forces_to_show
end

trigger.remote = remote
--- Gather statistics from other mods
---@param forces LuaForce   list of forces that the GUI will be shown to
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

---Show the victory screen for all connected players
function trigger.show_victory_screen()

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

    local forces_to_show = get_forces_to_show()

    local force_names = { }
    for _, force in pairs(forces_to_show) do table.insert(force_names, force.name) end
    log("Showing to forces: "..serpent.line(force_names))

    if profilers then profilers.gather.reset() end
    local other_statistics = trigger.gather_statistics(forces_to_show)
    if profilers then profilers.gather.stop() end

    local compatibility_stats = compatibility.gather(forces_to_show)

    for _, force in pairs(forces_to_show) do
        local force_statistics = statistics.for_force(force, profilers)
        local compatibility_force_statistics = compatibility_stats.by_force[force.name] or { }
        local other_force_statistics = other_statistics.by_force[force.name] or { }

        for _, player in pairs(force.connected_players) do

            -- Clear the cursor because it's annoying if it's still there
            player.clear_cursor()

            local compat_player_statistics = compatibility_stats.by_player[player.index] or { }
            local other_player_statistics = other_statistics.by_player[player.index] or { }

            gui.create(player, util.merge{
                -- Order is important. Later will override previous
                force_statistics,
                statistics.for_player(player, profilers),

                compatibility_force_statistics,
                compat_player_statistics,

                other_force_statistics,
                other_player_statistics,
            })
        end
    end

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

    -- This will also handle the case when victory is reached in an headless server
    -- without any online players. The risk is that the game is paused accidentally.
    -- However, in MP it will never pause, and in single player there will always
    -- be a player. So it will all work nicely, not pausing accidentally.
    if not game.is_multiplayer() then
        game.tick_paused = true
    end
end

function trigger.add_commands()

    if settings.startup["bvs-enable-show-victory-screen-command"].value or script.active_mods["debugadapter"] then
        local show_victory_help_message = [[
            Show the Victory GUI as if victory has been reached, without actually triggering the victory.
            This is mainly for development purposes, but might be interesting for some players.
            This command does not have any impact on the game.
            [Mod: Better Victory Screen]
            ]]
            ---@param command CustomCommandData
        commands.add_command("show-victory-screen", show_victory_help_message, function(command)
            if script.active_mods["debugadapter"] and command.parameter == "victory" then
                -- Add additional option to trigger the actual victory, but
                -- only while the debugger is active. In normal game play it
                -- should not be possible, that would be bad.
                local player = game.get_player(command.player_index)
                if not player then return end       -- Should never happen.
                if not player.admin then return end -- Some kind of safety net

                game.print("[Better Victory Screen] Forcing an actual victory.")
                game.set_game_state{player_won=true, game_finished=true, can_continue=true}
                return
            end

            -- Normal operation
            trigger.show_victory_screen()
        end)
    end
end

---@param event EventData.on_pre_scenario_finished
function trigger.on_pre_scenario_finished(event)

    -- Ah! There's currently no way to know in this event if the player won or lost.
    -- The game is set to "finished" when the player lost as well.
    -- Meaning it can also be called when the player dies! Until I get the changes into
    -- source I'll just silence any victories within the next tick after a player's death.
    -- TODO: Be better.
    if storage.silence_finished_until and event.tick <= storage.silence_finished_until then
        return
    end

    -- Set the game state to victory without setting game_finished.
    -- This will trigger the achievements without showing the vanilla GUI.
    -- Thanks Rseding!
    game.set_game_state({ player_won = true, game_finished = false })

    game.print("pre scenario finished "..event.tick)
    -- Show our GUI
    trigger.show_victory_screen()
end

---@param event EventData.on_player_died
function trigger.on_player_died(event)
    storage.silence_finished_until = event.tick + 1
end

trigger.events = {
    [defines.events.on_pre_scenario_finished] = trigger.on_pre_scenario_finished,
    [defines.events.on_player_died] = trigger.on_player_died,
}

return trigger
