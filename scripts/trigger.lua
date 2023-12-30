local gui = require("scripts.gui")
local util = require("util")

local trigger = { }
local gather_function_name = "better-victory-screen-statistics"

--- Gather statistics from other mods
local function gather_statistics()
    local statistics = { by_force = { }, by_player = { } }
    for interface, functions in pairs(remote.interfaces) do
        if functions[gather_function_name] then
            local received_statistics = remote.call(interface, gather_function_name) --[[@as table]]
            statistics = util.merge{statistics, received_statistics}
        end
    end
    return statistics
end

local function show_victory_screen()

    local other_statistics = gather_statistics()

    for _, force in pairs(game.forces) do
        if trigger.statistics.is_force_blacklisted(force.name) then goto continue end

        local force_statistics = trigger.statistics.for_force(force)
        local other_force_statistics = other_statistics.by_force[force.name] or { }

        for _, player in pairs(force.connected_players) do

            -- Clear the cursor because it's annoying if it's still there
            player.clear_cursor()

            local other_player_statistics = other_statistics.by_player[player.index] or { }
            gui.create(player, util.merge{
                -- Order is important. Later will override previous
                force_statistics,
                trigger.statistics.for_player(player),
                other_force_statistics,
                other_player_statistics,
            })
        end

        ::continue::
    end

    if not game.is_multiplayer() then
        game.tick_paused = true
    end
end

--- Trigger the victory screen
---@param force LuaForce
local function trigger_victory(force)
    if global.finished[force.name] then return end
    global.finished[force.name] = true

    show_victory_screen()
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
		end,

        --- @param force LuaForce
        trigger_victory = function(force)
            trigger_victory(force)
        end
    })
end

function trigger.add_commands()
    commands.add_command("show-victory-screen", nil, function(command)
        show_victory_screen()
    end)
end

trigger.events = {
    [defines.events.on_rocket_launched] = on_rocket_launched,
}

function trigger.on_init(event)
    remote.call("silo_script", "set_no_victory", true)

    global.finished = {}

    ---@type table<string, table> Stats for every force
    global.statistics = {}
end

return trigger