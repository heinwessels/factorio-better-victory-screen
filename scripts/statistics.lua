local lib = require("scripts.lib")
local util = require("util")

local statistics = { }

local surface_blacklist = {}

local force_blacklist = util.list_to_map{
    "enemy", "neutral",
}
---@param force_name string
---@return boolean
function statistics.is_force_blacklisted(force_name)
    if force_blacklist[force_name] then return true end
    if force_name:find("EE_TESTFORCE_") then return true end
    return false
end

--- The amount of machines/buildings
---@param force LuaForce calculate statistics for
---@return integer
local function get_total_machines(force)
    local count = 0
    for _, surface in pairs(game.surfaces) do
        if surface_blacklist[surface.name] then goto continue end

        count = count + surface.count_entities_filtered{
            force = force,
            type = {
                "assembling-machine",
                "lab",
                "boiler",
                "generator",
                "burner-generator",
                "reactor",
                "heat-interface",
                "mining-drill",
                "roboport",
                "beacon",
                "radar",
                "rocket-silo",
            }
        }

        ::continue::
    end

    return count
end

---@param force LuaForce calculate statistics for
---@return uint32 in m
local function get_total_belt_length(force)
    local distance = 0
    for _, surface in pairs(game.surfaces) do
        if surface_blacklist[surface.name] then goto continue end

        -- Assume each belt has a distance of 1m.
        -- This isn't really true for corners, but meh. 
        local belts = surface.count_entities_filtered{type = "transport-belt", force = force}
        distance = distance + belts

        -- Assume each splitter has a distance of 2m.
        local splitters = surface.count_entities_filtered{type = "splitter", force = force}
        distance = distance + (splitters * 2)

        -- Assume an average extend length of 50% of the maximum distance
        for prototype_name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "underground-belt"}}) do
            local amount = surface.count_entities_filtered{name=prototype_name, force=force}
            -- Remember to take into a account we loop over single entities, and not pairs of undergroundies
            local average_length_per_single_underground = prototype.max_underground_distance / 2 / 2
            distance = distance + amount + (amount * average_length_per_single_underground)
        end

        ::continue::
    end

    return math.floor(distance)
end

---@param force LuaForce calculate statistics for
---@return uint32 in m
local function get_total_rail_length(force)
    local distance = 0
    for _, surface in pairs(game.surfaces) do
        if surface_blacklist[surface.name] then goto continue end

        -- Assume each belt has a distance of 2m.
        -- This isn't really true for diagonal pieces but meh
        local straight = surface.count_entities_filtered{type = "straight-rail", force = force}
        distance = distance + (straight * 2)

        -- Assume each curved rail has a length of 8m.
        -- TODO This can be estimated better! 
        local curved = surface.count_entities_filtered{type = "curved-rail", force = force}
        distance = distance + (curved * 8)

        ::continue::
    end

    return math.floor(distance)
end

---@param force LuaForce calculate statistics for
---@return uint32 in m
local function get_total_pipe_length(force)
    local distance = 0
    for _, surface in pairs(game.surfaces) do
        if surface_blacklist[surface.name] then goto continue end

        local pipe = surface.count_entities_filtered{type = "pipe", force = force}
        distance = distance + pipe

        local tanks = surface.count_entities_filtered{type = "storage-tank", force = force}
        distance = distance + (tanks * 3) -- Let's say a tank adds 3m of pipeline

        -- Assume an average extend length of 50% of the maximum distance
        for prototype_name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "pipe-to-ground"}}) do
            local amount = surface.count_entities_filtered{name=prototype_name, force=force}
            -- Remember to take into a account we loop over single entities, and not pairs of undergroundies
            local average_length_per_single_underground = prototype.max_underground_distance / 2 / 2
            distance = distance + amount + (amount * average_length_per_single_underground)
        end

        ::continue::
    end

    return math.floor(distance)
end

---@param force LuaForce calculate statistics for
---@return integer
local function get_total_trains(force)
    return #force.get_trains()
end

---@param force LuaForce calculate statistics for
---@return integer
local function get_total_train_stations(force)
    local count = 0
    for _, surface in pairs(game.surfaces) do
        if surface_blacklist[surface.name] then goto continue end

        count = count + surface.count_entities_filtered{type = "train-stop", force = force}

        ::continue::
    end

    return count
end


local FLOW_PRECISION_BRACKETS = {
    defines.flow_precision_index.one_thousand_hours,
    defines.flow_precision_index.two_hundred_fifty_hours,
    defines.flow_precision_index.fifty_hours,
    defines.flow_precision_index.ten_hours,
    defines.flow_precision_index.one_hour,
    defines.flow_precision_index.ten_minutes,
    defines.flow_precision_index.one_minute,
    defines.flow_precision_index.five_seconds,
}

---@param force LuaForce
---@return integer
local function get_peak_power_generation(force)
    -- TODO Ahhh, this will be soooo slow! There is no robust event-driven way to do this!
    -- Or at least I can't think of one
    -- https://forums.factorio.com/viewtopic.php?p=588649#p588649

    local peak = 0

    local found_networks = { }
    for _, surface in pairs(game.surfaces) do
        if surface_blacklist[surface.name] then goto continue end

        for _, pole in pairs(surface.find_entities_filtered{type = "electric-pole", force = force}) do
            local network_id = pole.electric_network_id
            if network_id and not found_networks[network_id] then
                -- This is a new network
                local flow = pole.electric_network_statistics

                -- We will just find the peak in all brackets. There's probably
                -- some averaging done in longer brackets with less accuracy, with
                -- older peaks probably being be lower than due to averaging. Bleh,
                -- this is a proof of concept mod.

                -- For each bracket we have to count it all for every entity!?
                -- That's rediculous, but I want this in the mod!

                -- First create a list of all the prototypes tracked in this flow
                local prototypes = { }
                for prototype, _ in pairs(flow.output_counts) do
                    table.insert(prototypes, prototype)
                end

                -- Now go through all the brackets to look for the peak
                -- But only if there actually power generated.
                if #prototypes > 0 then
                    for _, bracket in pairs(FLOW_PRECISION_BRACKETS) do
                        -- Calculate the peak at each timestep
                        -- Note: This can be smarter, don't need samples covered by previous bracket
                        for index = 1,300 do
                            local sum = 0
                            -- By summing together all prototype values
                            for _, prototype in pairs(prototypes) do
                                sum = sum + flow.get_flow_count{
                                    name = prototype,
                                    input = false,
                                    precision_index = bracket,
                                    sample_index = index,
                                }
                            end

                            if sum > peak then
                                peak = sum
                            end
                        end
                    end
                end

                found_networks[network_id] = true
            end
        end

        ::continue::
    end

    return peak * 60 -- Was in joule per tick
end


---@param force LuaForce
---@return integer
local function get_items_produced(force)
    local count = 0

    for _, amount in pairs(force.item_production_statistics.input_counts) do
        count = count + amount
    end

    return count
end

---@param force LuaForce
---@return integer
local function get_total_science_packs_consumed(force)
    local count = 0

    local force_stats = force.item_production_statistics
    for science_pack_name, _ in pairs(game.get_filtered_item_prototypes{{filter="tool"}}) do
        count = count + force_stats.get_output_count(science_pack_name)
    end

    return count
end

---@param force LuaForce
---@return integer
local function get_total_enemy_kills(force)
    local count = 0

    local force_stats = force.kill_count_statistics
    for enity_type, _ in pairs(game.get_filtered_entity_prototypes
        {{filter = "type", type = {"unit", "unit-spawner"}}}
    ) do
        count = count + force_stats.get_input_count(enity_type)
    end

    return count
end

---@param force LuaForce
---@return integer
local function get_total_kills_by_train(force)
    local count = 0

    for _, train in pairs(force.get_trains()) do
        count = count + train.kill_count
    end

    return count
end

---@param force LuaForce
---@return integer
local function get_total_area_explored(force)
    local chunks_charted = 0

    -- This is very inefficient. This will currently be run for each force,
    -- which is unnecesary chunk iterations. But this is the structure we have
    -- now, so it's good enough. For vanilla-ish playthroughs this is fine anyway.
    for _, surface in pairs(game.surfaces) do
        if surface_blacklist[surface.name] then goto continue end

        for chunk in surface.get_chunks() do
            if force.is_chunk_charted(surface, chunk) then
                chunks_charted = chunks_charted + 1
            end
        end

        ::continue::
    end

    return chunks_charted * ( 16 * 16)
end

---@param force LuaForce
---@return table containing statistics
function statistics.for_force(force)
    local stats = {}

    stats["infrastructure"] = {order = "e", stats = {
        ["machines"] =          {value = get_total_machines(force),                         order="a"},
        ["transport-belts"] =   {value = get_total_belt_length(force), unit="distance",     order="b"},
        ["rails"] =             {value = get_total_rail_length(force), unit="distance",     order="c"},
        ["pipes"] =             {value = get_total_pipe_length(force), unit="distance",     order="d"},
        ["trains"] =            {value = get_total_trains(force),                           order="e"},
        ["train-stations"] =    {value = get_total_train_stations(force),                   order="f"},
    }}

    stats["production"] = {order = "f", stats = {
        ["peak-power"] =        {value = get_peak_power_generation(force), unit="power"},
        ["items-produced"] =    {value = get_items_produced(force)},
        ["science-consumed"] =  {value = get_total_science_packs_consumed(force)},
    }}

    stats["miscellaneous"] = {order = "g", stats = {
        ["total-enemy-kills"] = {value = get_total_enemy_kills(force)},
        ["total-train-kills"] = {value = get_total_kills_by_train(force)},
        ["area-explored"] =     {value = get_total_area_explored(force), unit="area"},
    }}

    return stats
end

---@param player LuaPlayer
---@return table containing statistics
function statistics.for_player(player)
    local stats = {}
    local player_data = global.statistics.players[player.index] --[[@as StatisticsPlayerData]]

    stats["player"] = {order = "d", stats = {
        ["deaths"] =            {value = player_data.deaths,                                order="a"},
        ["kills"] =             {value = player_data.kills,                                 order="b"},
        ["distance-walked"] =   {value = player_data.distance_walked,   unit="distance",    order="c"},
        ["distance-drove"] =    {value = player_data.distance_drove,    unit="distance",    order="d"},
        ["handcrafting-time"] = {value = player_data.ticks_crafted,     unit="time",        order="e"},
    }}

    return stats
end

---@param event EventData.on_entity_died
local function on_entity_died(event)
    local cause = event.cause
    if not cause then return end
    if cause.type ~= "character" then return end
    local player = cause.player
    if not player then return end
    local data = global.statistics.players[player.index] --[[@as StatisticsPlayerData ]]
    data.kills = data.kills + 1
end

---@param event EventData.on_player_changed_position
local function on_player_changed_position(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    local player_data = global.statistics.players[event.player_index]


    -- Only measure distance when character controller.
    if player.controller_type ~= defines.controllers.character then
        player_data.last_posistion = nil
        return
    elseif not player_data.last_posistion then
        player_data.last_posistion = player.position
        return
    end

    local old = player_data.last_posistion
    local new = player.position
    local distance = math.sqrt((old.x - new.x)^2 + (old.y - new.y)^2)
    player_data.last_posistion = new

    if player.driving then
        player_data.distance_drove = player_data.distance_drove + distance
    else
        player_data.distance_walked = player_data.distance_walked + distance
    end
end

statistics.on_nth_tick = {
    --- There are no nice events when hand crafting starts and stops
    ---@param event NthTickEventData
    [10] = function(event)
        for _, player in pairs(game.connected_players) do
            if player.controller_type ~= defines.controllers.character then goto continue end
            if player.crafting_queue_progress == 0 then goto continue end

            local data = global.statistics.players[player.index] --[[@as StatisticsPlayerData ]]
            data.ticks_crafted = data.ticks_crafted + event.nth_tick

            ::continue::
        end
    end,
}

statistics.events = {
    [defines.events.on_player_changed_position] = on_player_changed_position,
    [defines.events.on_entity_died] = on_entity_died,

    [defines.events.on_player_died] = function(event)
        global.statistics.players[event.player_index].deaths
            = global.statistics.players[event.player_index].deaths + 1
    end,

    ---@param event EventData.on_force_created
    [defines.events.on_force_created] = function (event)
        statistics.setup_force(event.force)

        -- TODO I'm not dealing with forces being merged. I'd rather have
        -- undefined behaviour than a weird crash during your game or the
        -- victory screen.
    end,

    [defines.events.on_player_created] = function (event)
        local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
        statistics.setup_player(player)
    end,
    script.on_event(defines.events.on_player_removed, function(event)
        global.players[event.player_index] = nil
    end)
}

---@class StatisticsPlayerData
---@field deaths integer
---@field kills integer
---@field distance_walked integer
---@field distance_drove integer
---@field last_posistion MapPosition?
---@field ticks_crafted uint

---@class StatisticsForceData

---@param player LuaPlayer
function statistics.setup_player(player)
    ---@type StatisticsPlayerData
    global.statistics.players[player.index] = {
        deaths = 0,
        kills = 0,

        distance_walked = 0,
        distance_drove = 0,
        last_posistion = nil,

        ticks_crafted = 0,
    }
end

---@param force LuaForce
function statistics.setup_force(force)
    if statistics.is_force_blacklisted(force.name) then return end
    ---@type StatisticsForceData
    global.statistics.forces[force.index] = { }
end

function statistics.on_init (event)
    global.statistics = {
        forces = { },

        ---@type table<uint, StatisticsPlayerData>
        players = { },
    }
end

return statistics