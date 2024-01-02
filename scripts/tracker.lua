local tracker = { }

--[[
    This is a standalone module that can tracker to keep a count of the number
    of entities of a given name (or type) so that it all doesn't have to be computed
    while drawing the GUI. It works like this:

    - On configuration changed it will recount all existing entities on all surfaces
        - This is to handle the case some entities being removed beause it no longer exists
    - From then on the counter is only updated in created/destroyed events
    
    You can set an entity to be tracked in `on_init` and `on_configuration_changed`, and
    retreive that value at any time. This module take care of it's own internal state. You
    only have to hook up the events, which works out of the box with the provided event handler.
]]

local data_key = "_tracker_cache"

---@class CounterClass
---@field counters              table<string, uint32> a counter for each force name
---@field last_recalc           table<string, uint32> tick last calculated for each name
---@field tracked               table<string, boolean>

--- @class TrackerGlobalData
--- @field entities_by_name     CounterClass
--- @field entities_by_type     CounterClass

---@type TrackerGlobalData
local data = {
    entities_by_name = { counters = { }, last_recalc = { }, tracked = { }, },
    entities_by_type = { counters = { }, last_recalc = { }, tracked = { }, },
}

local function initialize_data()
    global[data_key] = global[data_key] or data
    data = global[data_key] --[[@as TrackerGlobalData]]

    for _, force in pairs(game.forces) do
        data.entities_by_name.counters[force.name] = data.entities_by_name.counters[force.name] or { }
        data.entities_by_type.counters[force.name] = data.entities_by_type.counters[force.name] or { }
    end
end

---@param entity_name string
local function refresh_entity_count_by_name(entity_name)
    if data.entities_by_name.last_recalc[entity_name]
        and data.entities_by_name.last_recalc[entity_name] == game.tick 
            then return end
    data.entities_by_name.last_recalc[entity_name] = game.tick

    local count = 0
    for force_name, _ in pairs(data.entities_by_name.counters) do
        for _, surface in pairs(game.surfaces) do
            -- TODO blacklist surfaces
            count = count + surface.count_entities_filtered{name = entity_name, force = force_name}
        end
    end

    data.entities_by_name.counters[entity_name] = count
end

---@param entity_type string
local function refresh_entity_count_by_type(entity_type)
    if data.entities_by_name.last_recalc[entity_type]
        and data.entities_by_name.last_recalc[entity_type] == game.tick 
            then return end
    data.entities_by_name.last_recalc[entity_type] = game.tick

    local count = 0
    for force_name, _ in pairs(data.entities_by_name.counters) do
        for _, surface in pairs(game.surfaces) do
            -- TODO blacklist surfaces
            count = count + surface.count_entities_filtered{type = entity_type, force = force_name}
        end
    end

    data.entities_by_name.counters[entity_name] = count
end

local function reset_counters()

    for entity_name, _ in pairs(data.entities_by_name.tracked) do
        refresh_entity_count_by_name(entity_name)
    end

    for entity_type, _ in pairs(data.entities_by_type.tracked) do
        refresh_entity_count_by_type(entity_type)
    end
end

tracker.on_init = initialize_data
tracker.on_load = initialize_data
tracker.on_configuration_changed = reset_counters



--- Start tracking an specifc entity (or array of entities)
--- This should be called during on_init and on_configuration_changed
---@param entity_names string|string[]
function tracker.track_entity_count_by_name(entity_names)
    initialize_data() -- So that no dependency on this mod is requried
    if type(entity_names) == "string" then entity_names = { entity_names } end
    for _, entity_name in pairs(entity_names) do
        
    end
end

---Get the tracked entity count of an entity by some force
---@param force LuaForce to track entities from
---@param entity_names string|string[]
---@return integer
function tracker.get_entity_count(force, entity_names)
    local count = 0
    if type(entity_names) == "string" then entity_names = { entity_names } end
    local counters = data.entities_by_name[force.name]
    for _, entity_name in pairs(entity_names) do
        count = count + (counters[entity_name] or 0)
    end
    return count
end

---@param event EventData.on_robot_built_entity|EventData.on_built_entity|EventData.script_raised_built|EventData.script_raised_revive|EventData.on_entity_cloned
function tracker.on_entity_created(event)
    local entity = event.created_entity or event.entity or event.destination
    if not entity or not entity.valid then return end
    if not data.tracked_entities_by_name[entity.name] then return end

    local force_cache = data.entities_by_name[entity.force.name]
    force_cache[entity.name] = force_cache[entity.name] + 1
end

function tracker.on_entity_removed(event)
    local entity = event.created_entity or event.entity
    if not entity or not entity.valid then return end
    if not data.tracked_entities_by_name[entity.name] then return end

    local force_cache = data.entities_by_name[entity.force.name]
    force_cache[entity.name] = force_cache[entity.name] - 1
end

---@param event EventData.on_force_created
function tracker.on_force_created(event)
    local force = event.force
    data.entities_by_name[force.name] = { }
    for entity_name, _ in pairs(data.tracked_entities_by_name) do
        data.entities_by_name[force.name][entity_name] = 0
    end
end

tracker.events = {
    [defines.events.on_robot_built_entity]  = tracker.on_entity_created,
    [defines.events.on_built_entity]        = tracker.on_entity_created,
    [defines.events.script_raised_built]    = tracker.on_entity_created,
    [defines.events.script_raised_revive]   = tracker.on_entity_created,
    [defines.events.on_entity_cloned]       = tracker.on_entity_created,

    [defines.events.on_player_mined_entity] = tracker.on_entity_removed,
    [defines.events.on_robot_mined_entity]  = tracker.on_entity_removed,
    [defines.events.on_entity_died]         = tracker.on_entity_removed,
    [defines.events.script_raised_destroy]  = tracker.on_entity_removed,

    [defines.events.on_force_created]       = tracker.on_force_created,
}

return tracker