if not script.active_mods["space-age"] then return { } end

local blacklist = require("scripts.blacklist")
local lib = require("scripts.lib")

local module = { }

---@class SpaceAgePlayerStatistics
---@field last_visited_name string? the planet name
---@field times_visited_planet table<string, number> number of times moved to this planet from another surface

---@param players table<uint, SpaceAgePlayerStatistics>
---@param player_index uint
---@return SpaceAgePlayerStatistics
local function get_make_player_data(players, player_index)
    ---@type SpaceAgePlayerStatistics
    local player_data = players[player_index] or { 
        times_visited_planet = { },
    }
    players[player_index] = player_data
    return player_data
end 

local character_controller = defines.controllers.character
module.on_nth_tick = {
    ---@param event NthTickEventData
    [60] = function(event)
        local players = storage.space_age.players --[[@as table<uint, SpaceAgePlayerStatistics>]]
        for _, player in pairs(game.connected_players) do
            if player.controller_type ~= character_controller then goto continue end
            if blacklist.force(player.force.name) then goto continue end
            local surface_name = player.surface.name
            if blacklist.surface(surface_name) then goto continue end
            
            local player_data = get_make_player_data(players, player.index)

            local planet = player.surface.planet
            local planet_name = planet and planet.name or nil
            if planet_name and planet_name ~= player_data.last_visited_name then                
                player_data.times_visited_planet[planet_name] = (player_data.times_visited_planet[planet_name] or 0) + 1
            end
            player_data.last_visited_name = planet_name

            ::continue::
        end
    end,
}


---@param player_data SpaceAgePlayerStatistics
---@return LocalisedString?
local function get_localised_most_visited_planet_name(player_data)
    local most_visisted_planet_name = lib.table.key_at_max_value(player_data.times_visited_planet or { })
    if not most_visisted_planet_name then return end

    local prototype = prototypes.space_location[most_visisted_planet_name]
    if not prototype then return end

    return prototype.localised_name
end

---@param forces LuaForce[] to gather statistics from
function module.gather(forces)
    local players = storage.space_age.players --[[@as table<uint, SpaceAgePlayerStatistics>]]
    local stats = { by_player = { } }
    for _, force in pairs(forces) do
        for _, player in pairs(force.connected_players) do
            local player_data = players[player.index]
            if not player_data then goto continue end

            local localised_planet_name = get_localised_most_visited_planet_name(player_data)
            if localised_planet_name then
                stats.by_player[player.name] = {
                    ["player"] = { stats = {
                        ["sa-most-visited-planet"] = { value = localised_planet_name, unit = "localised-string", order = "a" }
                    }}
                }
            end

            ::continue::
        end
    end

    return stats
end

local function setup()
    storage.space_age = {

        ---@type table<uint, SpaceAgePlayerStatistics>
        players = { },
    }
end

module.on_init = setup
module.on_configuration_changed = setup

return module