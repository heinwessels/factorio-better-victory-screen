local gui = require("scripts.gui")
local util = require("util")
local blacklist = require("scripts.blacklist")
local statistics = require("scripts.statistics")

local trigger = { }
local gather_function_name = "better-victory-screen-statistics"

---A list of forces to show the victory screen to
---@return LuaForce[]
local function get_forces_to_show()
    local forces_to_show = { }
    for _, force in pairs(game.forces) do
        if #force.connected_players == 0 then goto continue end
        if blacklist.force(force.name) then goto continue end
        table.insert(forces_to_show, force)
        ::continue::
    end
    return forces_to_show
end

--- Gather statistics from other mods
---@param winning_force LuaForce
---@param forces LuaForce   list of forces that the GUI will be shown to
local function gather_statistics(winning_force, forces)
    local gathered_statistics = { by_force = { }, by_player = { } }
    for interface, functions in pairs(remote.interfaces) do
        if functions[gather_function_name] then
            local received_statistics = remote.call(interface, gather_function_name, winning_force, forces) --[[@as table]]
            gathered_statistics = util.merge{gathered_statistics, received_statistics}
        end
    end
    return gathered_statistics
end

---Show the victory screen for all connected players
---@param winning_force LuaForce
local function show_victory_screen(winning_force)

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
    local other_statistics = gather_statistics(winning_force, forces_to_show)
    if profilers then profilers.gather.stop() end

    for _, force in pairs(forces_to_show) do
        local force_statistics = statistics.for_force(force, profilers)
        local other_force_statistics = other_statistics.by_force[force.name] or { }
        for _, player in pairs(force.connected_players) do

            -- Clear the cursor because it's annoying if it's still there
            player.clear_cursor()

            local other_player_statistics = other_statistics.by_player[player.index] or { }
            gui.create(player, util.merge{
                -- Order is important. Later will override previous
                force_statistics,
                statistics.for_player(player, profilers),
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

    if not game.is_multiplayer() then
        game.tick_paused = true
    end
end

--- Trigger the game's victory condition and then
--- show our custom victory screen 
---@param winning_force LuaForce
---@param override boolean? true if victory should be triggered regardless of it being triggered before
local function attempt_trigger_victory(winning_force, override)

    if not override then
        -- Do not trigger if another mod already triggered a normal victory
        -- condition. Note: This will not prevent BVS from triggering twice,
        -- because we don't set the `finished` game state, meaning these two
        -- values will never be true for a BVS triggered victory.
        if game.finished or game.finished_but_continuing then return end

        -- Check if this a force has already finished cache
        if global.finished then return end
    end

    global.finished = true

    -- Set the game state to victory without setting game_finished.
    -- This will trigger the achievements without showing the vanilla GUI.
    -- Thanks Rseding!
    game.set_game_state({ player_won = true, victorious_force = winning_force })

    -- Show our GUI
    show_victory_screen(winning_force)
end

---@param event EventData.on_rocket_launched
local function on_rocket_launched(event)
    if global.disable_vanilla_victory then return end

    local rocket = event.rocket
    if not (rocket and rocket.valid) then return end

    attempt_trigger_victory(rocket.force --[[@as LuaForce]])
end

trigger.add_remote_interface = function()
	remote.add_interface("better-victory-screen", {

		--- @param no_victory boolean true to ignore vanilla victory conditions
		set_no_victory = function(no_victory)

            -- First handle some possible migration issues
            if not global.disable_vanilla_victory                                   -- Previously assumed vanilla victory condition
                and no_victory                                                      -- Now we should wait for remote trigger
                and global.finished                                                 -- We already did trigger the screen though
                and not (game.finished or game.finished_but_continuing) then        -- And the other mod hasn't triggered actual victory
                -- This is the first time that the vanilla victory condition is disabled
                -- but we've already triggered a victory condition. And the vanilla
                -- victory condition has never been reached. This can only happen when
                -- a mod didn't have support, but was added mid-run.
                game.print("[Better Victory Screen] Detected newly added support while victory was erroneously shown previously. Reseting victory state. No further action required.")
                global.finished = false
            end

            global.disable_vanilla_victory = no_victory
		end,

        ---This remote is called by other mods when victory is achieved 
        ---@param winning_force LuaForce
        ---@param override boolean? True if then victory GUI will be shown regardless of if it has been shown before
        trigger_victory = function(winning_force, override)
            attempt_trigger_victory(winning_force, override)
        end
    })
end

function trigger.add_commands()

    local show_victory_help_message = [[
        Show the Victory GUI as if victory has been reached, without actually triggering the victory.
        This is mainly for development purposes, but might be interesting for some players.
        This command does not have any impact on the game.
        [Mod: Better Victory Screen]
        ]]
        ---@param command CustomCommandData
    commands.add_command("show-victory-screen", show_victory_help_message, function(command)
        if script.active_mods["debugadapter"] and command.parameter == "victory" then
            local player = game.get_player(command.player_index)
            if not player then return end       -- Should never happen.
            if not player.admin then return end -- Some kind of safety net

            -- Add additional option to trigger the actual victory, but
            -- only while the debugger is active. In normal game play it
            -- should not be possible, that would be bad.
            game.print("[Better Victory Screen] Forcing an actual victory.")
            attempt_trigger_victory(game.forces.player, true)
            return
        end

        -- Normal operation
        show_victory_screen(game.forces.player)
    end)

    local reset_command_help_message = [[
        **USE WITH CAUTION!** 
        This command will reset your victory so that it's possible to be trigger again by Better Victory Screen.
        However, it cannot revert if the vanilla victory screen has been displayed. In that case you cannot trigger another victory condition.
        This action cannot be reverted, and this command can only be executed by an admin.
        [Mod: Better Victory Screen]
        ]]
        ---Reset the victory condition if something went wrong
        ---@param command CustomCommandData
    commands.add_command("reset-victory-condition", reset_command_help_message, function(command)
        local player = game.get_player(command.player_index)
        if not player then return end -- Should never happen.

        if not player.admin then
            player.print("Only admins can use this command")
            return
        end

        if not global.finished then
            player.print("A custom victory has not been reached. Nothing to do")
            return
        end

        global.finished = false -- So that a force can win again
        game.print("Victory tracked by Better Victory Screen has been reset.")

        -- We can't set the internal game state again to haven't won. But
        -- if we triggered a victory prematurely then it doesn't matter
        -- because we don't set the `finished` flag. Which means our
        -- victory-attempt will always be successful. And setting the
        -- game_state again will just show the victory screen again
        -- anyway, even triggering the vanilla victory from an unsupported mod.
    end)

    local pending_victory_help_message = [[
        This command will tell you if there is still a pending victory,
        or if victory should still be reached. It will also say if the pending victory will occur
        on the first rocket launch ("Vanilla") or a custom victory condition.
        This command doesn't have any impact on anything.
        [Mod: Better Victory Screen]
    ]]
    ---Check if a victory is still possible
    ---@param command CustomCommandData
    commands.add_command("is-victory-pending", pending_victory_help_message, function(command)
        local player = game.get_player(command.player_index)
        if not player then return end -- Should never happen.
        local pending_type = global.disable_vanilla_victory and "Custom" or "Vanilla"
        if global.finished then
            player.print("No. Better Victory Screen has already created a victory condition [Type: " .. pending_type .. "]. Use '/reset-victory-condition` to revert.")
        elseif game.finished or game.finished_but_continuing then
            player.print("No. Vanilla victory condition has already been reached without Better Victory Screen.")
        else
            player.print("Victory condition is still pending [Type: " .. pending_type .. "].")
        end
    end)
end

trigger.events = {
    [defines.events.on_rocket_launched] = on_rocket_launched,
}

function trigger.on_init(event)
    if remote.interfaces["silo_script"] then
        remote.call("silo_script", "set_no_victory", true)
    end
end

return trigger