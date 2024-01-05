local gui = require("scripts.gui")
local util = require("util")
local blacklist = require("scripts.blacklist")
local statistics = require("scripts.statistics")

local trigger = { }
local gather_function_name = "better-victory-screen-statistics"

--- Gather statistics from other mods
---@param winning_force LuaForce
local function gather_statistics(winning_force)
    local gathered_statistics = { by_force = { }, by_player = { } }
    for interface, functions in pairs(remote.interfaces) do
        if functions[gather_function_name] then
            local received_statistics = remote.call(interface, gather_function_name, winning_force) --[[@as table]]
            gathered_statistics = util.merge{gathered_statistics, received_statistics}
        end
    end
    return gathered_statistics
end

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
            total           = game.create_profiler(false),
        }
    end

    if profilers then profilers.gather.reset() end
    local other_statistics = gather_statistics(winning_force)
    if profilers then profilers.gather.stop() end

    for _, force in pairs(game.forces) do
        if #force.connected_players == 0 then goto continue end
        if blacklist.force(force.name) then goto continue end

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

        ::continue::
    end

    if profilers then
        profilers.total.stop()

        log({"",
            "Better Victory Screen Statistics collection:\n",
            "\tOther mods: ", profilers.gather, "\n",
            "\tInfrastructure: ", profilers.gather, "\n",
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
---@param force LuaForce
local function trigger_victory(force)
    if global.finished[force.name] then return end
    global.finished[force.name] = true

    -- Set the game state to victory without setting game_finished.
    -- This will trigger the achievements without showing the vanilla GUI.
    -- Thanks Rseding!
    game.set_game_state({ player_won = true, victorious_force = force })

    -- Show our GUI
    show_victory_screen(force)
end

---@param event EventData.on_rocket_launched
local function on_rocket_launched(event)
    if global.disable_vanilla_victory then return end

    local rocket = event.rocket
    if not (rocket and rocket.valid) then return end

    trigger_victory(rocket.force --[[@as LuaForce]])
end

trigger.add_remote_interface = function()
	remote.add_interface("better-victory-screen", {

		--- @param no_victory boolean true to ignore vanilla victory conditions
		set_no_victory = function(no_victory)
            global.disable_vanilla_victory = no_victory
            remote.call("silo_script", "set_no_victory", true) -- Make sure it's disabled
		end,

        --- @param force LuaForce
        trigger_victory = function(force)
            trigger_victory(force)
        end
    })
end

function trigger.add_commands()

    ---@param command CustomCommandData
    commands.add_command("show-victory-screen", nil, function(command)
        if script.active_mods["debugadapter"] then
            -- Add additional option to trigger the actual victory, but
            -- only while the debugger is active.
            if command.parameter == "victory" then
                trigger_victory(game.forces.player)
                return
            end
        end

        -- Normal operation
        show_victory_screen(game.forces.player)
    end)
end

trigger.events = {
    [defines.events.on_rocket_launched] = on_rocket_launched,
}

function trigger.on_init(event)
    remote.call("silo_script", "set_no_victory", true)

    -- Keep track of the forces who finished
    global.finished = { }
end

return trigger