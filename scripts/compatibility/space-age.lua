if not script.active_mods["space-age"] then return { } end

local blacklist = require("scripts.blacklist")
local lib = require("scripts.lib")

local module = { }

---@class SpaceAgeForceStatistics
---@field rockets_launched uint
---@field fastest_platform_speed double
---@field fastest_platform_name string

---@class SpaceAgePlayerStatistics
---@field last_visited_name string? the planet name
---@field times_visited_planet table<string, number> number of times moved to this planet from another surface


---@param force_name string
---@return SpaceAgeForceStatistics
local function get_make_force_data(force_name)
    ---@type SpaceAgeForceStatistics
    local force_data = storage.space_age.forces[force_name] or { 
        rockets_launched = 0,
        fastest_platform_speed = 0,
    }
    storage.space_age.forces[force_name] = force_data
    return force_data
end

---@param player_index uint
---@return SpaceAgePlayerStatistics
local function get_make_player_data(player_index)
    ---@type SpaceAgePlayerStatistics
    local player_data = storage.space_age.players[player_index] or { 
        times_visited_planet = { },
    }
    storage.space_age.players[player_index] = player_data
    return player_data
end

---@param event EventData.on_rocket_launched
function module.on_rocket_launched(event)
    local force_name = event.rocket.force.name
    if not force_name then return end
    if blacklist.force(force_name) then return end
    local force_data = get_make_force_data(force_name)
    force_data.rockets_launched = (force_data.rockets_launched or 0) + 1
end

local character_controller = defines.controllers.character
---@param event EventData.on_player_changed_position
function module.on_player_changed_position(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    if player.controller_type ~= character_controller then return end

    local player_data = get_make_player_data(player.index)

    local planet = player.surface.planet
    local planet_name = planet and planet.name or nil
    if planet_name and planet_name ~= player_data.last_visited_name then                
        player_data.times_visited_planet[planet_name] = (player_data.times_visited_planet[planet_name] or 0) + 1
    end
    player_data.last_visited_name = planet_name
end

---@param player_data SpaceAgePlayerStatistics
---@return LocalisedString?
local function get_localised_most_visited_planet_name(player_data)
    local most_visisted_planet_name = lib.table.key_at_max_value(player_data.times_visited_planet or { })
    if not most_visisted_planet_name then return end

    local prototype = prototypes.space_location[most_visisted_planet_name]
    if not prototype then return end

    return prototype.localised_name
end

---@param event EventData.on_script_trigger_effect
function module.biter_hatch(event)
    -- items have no owner, so just add the stat to all forces
    storage.space_age.biter_eggs_hatched = (storage.space_age.biter_eggs_hatched or 0) + 1
end

---@param event EventData.on_tick
function module.on_tick(event)
    for _, force in pairs(game.forces) do
        if blacklist.force(force.name) then goto continue end
        if (event.tick + force.index) % 60 ~= 0 then goto continue end
        local force_data = get_make_force_data(force.name)

        for _, platform in pairs(force.platforms) do
            if platform.speed > (force_data.fastest_platform_speed or 0) then
                force_data.fastest_platform_speed = platform.speed * 60 -- Convert to km/h
                force_data.fastest_platform_name = platform.name
            end
        end

        ::continue::
    end
end

---@param forces LuaForce[] to gather statistics from
function module.gather(forces)
    local players = storage.space_age.players --[[@as table<uint, SpaceAgePlayerStatistics>]]
    local stats = { by_force = { }, by_player = { } }
    for _, force in pairs(forces) do

        
        ---@type SpaceAgeForceStatistics
        local force_data = storage.space_age.forces[force.name]
        if force_data then
            stats.by_force[force.name] = {
                ["space-age"] = { order = "9", stats = {
                    ["sa-rockets-launched"] = { value = force_data.rockets_launched or 0, order = "a" },
                    ["sa-fastest-platform-speed"] = { value = force_data.fastest_platform_speed or 0, unit = "speed", order = "b" },
                }}
            }                

            if storage.space_age.biter_eggs_hatched > 0 then
                stats.by_force[force.name]["space-age"].stats["sa-biters-hatched"] = { value = storage.space_age.biter_eggs_hatched or 0, order = "c" }
            end
        end

        for _, player in pairs(force.connected_players) do
            local player_data = players[player.index]
            if not player_data then goto continue end

            local localised_planet_name = get_localised_most_visited_planet_name(player_data)
            if localised_planet_name then
                stats.by_player[player.name] = {
                    ["space-age"] = { order = "5", stats = {
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
        ---@type number
        biter_eggs_hatched = 0,

        ---@type table<string, SpaceAgeForceStatistics>
        forces = { },

        ---@type table<uint, SpaceAgePlayerStatistics>
        players = { },
    }
end

module.on_init = setup
module.on_configuration_changed = setup

module.events = {
    [defines.events.on_tick] = module.on_tick,
    [defines.events.on_rocket_launched] = module.on_rocket_launched,
    [defines.events.on_player_changed_position] = module.on_player_changed_position,
    ["bvs-biter-hatch"] = module.biter_hatch,
}

return module