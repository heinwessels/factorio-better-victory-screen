local blacklist = require("scripts.blacklist")
local tracker = require("scripts.tracker")

local statistics = { }

local all_machines = {
    "assembling-machine",
    "furnace",
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

--- The amount of machines/buildings
---@param force LuaForce calculate statistics for
---@return integer
local function get_total_machines(force)
    return tracker.get_entity_count_by_type(force.name --[[@as ForceName]], all_machines)
end

---@param force LuaForce calculate statistics for
---@return uint32 in m
local function get_total_belt_length(force)
    local distance = 0

    -- Assume each belt has a distance of 1m.
    -- This isn't really true for corners, but meh. 
    local belts = tracker.get_entity_count_by_type(force.name --[[@as ForceName]], "transport-belt")
    distance = distance + belts

    -- Assume each splitter has a distance of 2m.
    local splitters = tracker.get_entity_count_by_type(force.name --[[@as ForceName]], "splitter")
    distance = distance + (splitters * 2)

    -- Assume the undergroundies have an average extend length of 50% of the maximum distance
    for prototype_name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "underground-belt"}}) do
        local amount = tracker.get_entity_count_by_name(force.name --[[@as ForceName]], prototype_name)
        -- Remember to take into a account we loop over single entities, and not pairs of undergroundies
        local average_length_per_single_underground = prototype.max_underground_distance / 2 / 2
        distance = distance + amount + (amount * average_length_per_single_underground)
    end

    return math.floor(distance) -- Flooring to the nearest meter
end

---@param force LuaForce calculate statistics for
---@return uint32 in m
local function get_total_rail_length(force)
    local distance = 0

    -- Assume each belt has a distance of 2m.
    -- This isn't really true for diagonal pieces but meh
    local straight = tracker.get_entity_count_by_name(force.name --[[@as ForceName]], "straight-rail")
    distance = distance + (straight * 2)

    -- Assume each curved rail has a length of 8m.
    -- TODO This can be estimated better! 
    local curved = tracker.get_entity_count_by_name(force.name --[[@as ForceName]], "curved-rail")
    distance = distance + (curved * 8)

    return math.floor(distance)
end

---@param force LuaForce calculate statistics for
---@return uint32 in m
local function get_total_pipe_length(force)
    local distance = 0

    -- Assume all pipes have a size of 1m. TODO is this true for Fluid Must Flow?
    local pipe = tracker.get_entity_count_by_type(force.name --[[@as ForceName]], "pipe")
    distance = distance + pipe

    -- Let's say a tank adds 3m of pipeline. TODO This is a bad assumption for non vanilla!
    local tanks = tracker.get_entity_count_by_type(force.name --[[@as ForceName]], "storage-tank")
    distance = distance + (tanks * 3)

    -- TODO take pumps into account?

    -- Assume an average extend length of 50% of the maximum distance
    for prototype_name, prototype in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "pipe-to-ground"}}) do
        local amount = tracker.get_entity_count_by_name(force.name --[[@as ForceName]], prototype_name)
        -- Remember to take into a account we loop over single entities, and not pairs of undergroundies
        local average_length_per_single_underground = prototype.max_underground_distance / 2 / 2
        distance = distance + amount + (amount * average_length_per_single_underground)
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
    return tracker.get_entity_count_by_name(force.name --[[@as ForceName]], {"train-stop"})
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
        if blacklist.surface(surface.name) then goto continue end

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
        if blacklist.surface(surface.name) then goto continue end

        for chunk in surface.get_chunks() do
            if force.is_chunk_charted(surface, chunk) then
                chunks_charted = chunks_charted + 1
            end
        end

        ::continue::
    end

    -- Convert chunks to km2
    return chunks_charted * ( 32 * 32 ) / (1000 * 1000)
end

---@param force LuaForce
---@param profilers table<string, LuaProfiler>?
---@return table containing statistics
function statistics.for_force(force, profilers)
    local stats = {}

    if profilers then profilers.infrastructure.reset() end
    stats["infrastructure"] = {order = "e", stats = {
        ["machines"] =          {value = get_total_machines(force),                         order="a"},
        ["transport-belts"] =   {value = get_total_belt_length(force), unit="distance",     order="b"},
        ["rails"] =             {value = get_total_rail_length(force), unit="distance",     order="c"},
        ["pipes"] =             {value = get_total_pipe_length(force), unit="distance",     order="d"},
        ["trains"] =            {value = get_total_trains(force),                           order="e"},
        ["train-stations"] =    {value = get_total_train_stations(force),                   order="f"},
    }}
    if profilers then profilers.infrastructure.stop() end

    if profilers then profilers.peak_power.reset() end
    local peak_power_generation = get_peak_power_generation(force)
    if profilers then profilers.peak_power.stop() end

    stats["production"] = {order = "f", stats = {
        ["peak-power"] =        {value = peak_power_generation, unit="power"},
        ["items-produced"] =    {value = get_items_produced(force)},
        ["science-consumed"] =  {value = get_total_science_packs_consumed(force)},
    }}

    if profilers then profilers.chunk_counter.reset() end
    local area_explored = get_total_area_explored(force)
    if profilers then profilers.chunk_counter.stop() end

    stats["miscellaneous"] = {order = "g", stats = {
        ["total-enemy-kills"] = {value = get_total_enemy_kills(force)},
        ["total-train-kills"] = {value = get_total_kills_by_train(force)},
        ["area-explored"] =     {value = area_explored, unit="area"},
    }}

    return stats
end

---@param player LuaPlayer
---@param profilers table<string, LuaProfiler>?
---@return table containing statistics
function statistics.for_player(player, profilers)
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

    if not player_data then
        -- This should never happen, right? Then why did it?
        -- I'll take this small UPS cost for now.
        -- It only happens in multiplayer.
        -- TODO: What is up with this?
        statistics.setup_player(player)
        player_data = global.statistics.players[event.player_index]
    end

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
    if global.statistics.players[player.index] then return end
    global.statistics.players[player.index] = {
        deaths = 0,
        kills = 0,

        distance_walked = 0,
        distance_drove = 0,
        last_posistion = nil,

        ticks_crafted = 0,
    }
end

-- We will offload as much processing as possible to be done while the game loads
-- so that it doesn't all happen when the GUI is trying to draw
local function setup_trackers()
    tracker.track_entity_count_by_type(all_machines)

    tracker.track_entity_count_by_type{"transport-belt", "splitter"}
    for prototype_name, _ in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "underground-belt"}}) do
        tracker.track_entity_count_by_name{prototype_name}
    end

    tracker.track_entity_count_by_name{"straight-rail", "curved-rail"}

    tracker.track_entity_count_by_type{"pipe", "storage-tank"}
    for prototype_name, _ in pairs(game.get_filtered_entity_prototypes{{filter = "type", type = "pipe-to-ground"}}) do
        tracker.track_entity_count_by_name{prototype_name}
    end

    tracker.track_entity_count_by_name{"train-stop"}
end

---@param force LuaForce
function statistics.setup_force(force)
    if blacklist.force(force.name) then return end
    ---@type StatisticsForceData
    global.statistics.forces[force.index] = { }
end

function statistics.on_init (event)
    global.statistics = {
        forces = { },

        ---@type table<uint, StatisticsPlayerData>
        players = { },
    }

    setup_trackers()
end

---@param event ConfigurationChangedData
function statistics.on_configuration_changed(event)
    setup_trackers()
end

return statistics