local gui = require("scripts.gui")
local util = require("util")

local trigger = { }

local function show_victory_screen()
    for _, force in pairs(game.forces) do
        if trigger.statistics.is_force_blacklisted(force.name) then goto continue end

        local force_statistics = trigger.statistics.for_force(force)
        for _, player in pairs(force.connected_players) do
            gui.create(player, util.merge{
                trigger.statistics.for_player(player),
                force_statistics,
            })
        end

        ::continue::
    end

    if not game.is_multiplayer() then
        game.tick_paused = true
    end
end

---@param event EventData.on_rocket_launched
local function on_rocket_launched(event)
    local rocket = event.rocket
    if not (rocket and rocket.valid) then return end

    local rocket_force = rocket.force
    if global.finished[rocket_force.name] then return end
    global.finished[rocket_force.name] = true

    show_victory_screen()
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