---@diagnostic disable: different-requires
local blacklist = require("__better-victory-screen__.scripts.blacklist")
local lib = require("__better-victory-screen__.scripts.lib")
local debug = require("__better-victory-screen__.scripts.debug")

local tracker_lib = { }

--[[
    This is a standalone module that can tracker to keep a count of the number
    of entities of a given name (or type) so that it all doesn't have to be computed
    while drawing the GUI. It works like this:

    - On configuration changed it will recount all existing entities on all surfaces
        - This is to handle the case some entities being removed beause it no longer exists
    - From then on the counter is only updated in created/destroyed events
    
    You can set an entity to be tracking in `on_init` and `on_configuration_changed`, and
    retreive that value at any time. This module take care of it's own internal state. You
    only have to hook up the events, which works out of the box with the provided event handler.

    Functions are written where possible to not crash with unexpected data, but instead return
    zeros or do nothing. Nobody wants the game to crash just as you achieved victory.

    NOTE: If you're requiring this file into your mod remember to hook up the plumbing
    to blacklist.lua to ensure the cache is invalidated when it should be.
]]

local data_key = "_bvs_tracker_cache"

---@enum TrackerType
local TRACKER_TYPE = {
	ENTITY_BY_NAME  = 0,
	ENTITY_BY_TYPE  = 1,
}

---@class Filter        : string
---@class ForceName     : string

---@class (exact) CounterClass
---@field count             uint
---@field last_recount      uint?

---@class (exact) TrackerClass
---@field type              TrackerType
---@field counters          table<ForceName, table<Filter, CounterClass>>
---@field tracking           table<Filter, boolean>

---@class (exact) TrackerGlobalData
---@field trackers          table<TrackerType, TrackerClass>
---@field tracked_forces    table<ForceName, boolean>

---@param tracker_type TrackerType
---@return TrackerClass
local function create_tracker(tracker_type)
    return {
        type = tracker_type,
        counters = { },
        tracking = { },
    }
end

---@type TrackerGlobalData
local data = {
    trackers = {
        [TRACKER_TYPE.ENTITY_BY_NAME]   = create_tracker(TRACKER_TYPE.ENTITY_BY_NAME),
        [TRACKER_TYPE.ENTITY_BY_TYPE]   = create_tracker(TRACKER_TYPE.ENTITY_BY_TYPE),
    },
    tracked_forces = { ["player"] = true },
}

--- Determines if this is a valid filter
---@type table<TrackerType, fun(filter: Filter): boolean>
local is_valid_filter_functions = {
    [TRACKER_TYPE.ENTITY_BY_NAME] = function (filter)
        return game.entity_prototypes[filter] ~= nil
    end,
    [TRACKER_TYPE.ENTITY_BY_TYPE] = function (filter)
        return defines.prototypes['entity'][filter] ~= nil
    end,
}

---Functions to recount each tracker type. Thiese functions will not be called often,
---and will only execute while the game is loading
---@type table<TrackerType, fun(filter: Filter, force_name : ForceName): uint>
local recounting_functions = {
    [TRACKER_TYPE.ENTITY_BY_NAME] = function (filter, force_name)
        local entity_name_exists = is_valid_filter_functions[TRACKER_TYPE.ENTITY_BY_NAME](filter)
        debug.debug_assert(entity_name_exists, "Invalid entity name '"..filter.."'")
        if not entity_name_exists then return 0 end -- Important, otherwise the search would crash

        local count = 0
        for _, surface in pairs(game.surfaces) do
            if blacklist.surface(surface.name) then goto continue end
            count = count + surface.count_entities_filtered{name = filter, force = force_name}
            ::continue::
        end
        return count
    end,

    [TRACKER_TYPE.ENTITY_BY_TYPE] = function (filter, force_name)
        local prototype_type_exists = is_valid_filter_functions[TRACKER_TYPE.ENTITY_BY_TYPE](filter)
        debug.debug_assert(prototype_type_exists ~= nil, "Invalid prototype type '"..filter.."'")
        if not prototype_type_exists then return 0 end -- Important, otherwise the search would crash

        local count = 0
        for _, surface in pairs(game.surfaces) do
            if blacklist.surface(surface.name) then goto continue end
            count = count + surface.count_entities_filtered{type = filter, force = force_name}
            ::continue::
        end
        return count
    end,
}

---Removes outdated filters that no longer exist due to mods
-- changing or whatever
---@param tracker    TrackerClass
local function sanitize_tracker(tracker)
    -- First clean up old forces that no longer exist. Don't think this will happen often
    lib.table.remove_keys_filtered(
        tracker.counters,
        function(force_name) return data.tracked_forces[force_name] ~= true end
    )

    -- Then clean up old filters that no longer exist due to mod changes
    local is_valid_filter = is_valid_filter_functions[tracker.type]
    for force_name, _ in pairs(data.tracked_forces) do
        if not tracker.counters[force_name] then
            tracker.counters[force_name] = { }
        else
            lib.table.remove_keys_filtered(
                tracker.counters[force_name],
                function (filter) return not is_valid_filter(filter --[[@as Filter]]) end
            )
        end
    end
end

---Recounts a tracker if it hasn't been recounted this tick. Will also create any
---tables that do not exist yet, so it can be used to setup a new tracker filter
---@param tracker               TrackerClass
---@param filter_to_recount     Filter? ensure a counters for this filter exists 
local function refresh_tracker(tracker, filter_to_recount)
    ---@type table<Filter, boolean>
    local filters -- The filters that we will recount
    if filter_to_recount then
        tracker.tracking[filter_to_recount] = true -- Ensure it exists
        filters = { [filter_to_recount] = true}
    else
        filters = tracker.tracking
    end

    local tick = game.tick

    for force_name, _ in pairs(data.tracked_forces) do
        for filter, _ in pairs(filters) do

            local force_counters = tracker.counters[force_name]
            if not force_counters then
                tracker.counters[force_name] = { }
                force_counters = tracker.counters[force_name]
            end

            local counter = force_counters[filter]
            if not counter then
                force_counters[filter] = { count = 0 }
                counter = force_counters[filter]
            end

            if not counter.last_recount or counter.last_recount ~= tick then
                counter.count = recounting_functions[tracker.type](filter, force_name)
                counter.last_recount = tick
            end
        end
    end
end

local function initialize_data()
    global[data_key] = global[data_key] or data
    data = global[data_key] --[[@as TrackerGlobalData]]
end

--- Recounts all counters if they have not been recounted already this tick
local function reset_trackers()
    -- First remove some left over forces that we might still be trying to track, or if
    -- we changed a blacklist in the meantime.
    lib.table.remove_keys_filtered(
        data.tracked_forces,
        function(force_name) return
            game.forces[force_name] == nil
            or blacklist.force(force_name --[[@as ForceName]])
        end
    )
    debug.debug_assert(next(data.tracked_forces) ~= nil, "No forces being tracked!")

    -- Now sanitize the actual trackers
    for tracker_type, tracker in pairs(data.trackers) do
        debug.debug_assert(tracker_type == tracker.type, "Oops. Mismatch in tracker types!")
        sanitize_tracker(tracker)
        refresh_tracker(tracker)
    end
end

tracker_lib.on_init = initialize_data
tracker_lib.on_load = function() data = global[data_key] or data end
tracker_lib.on_configuration_changed = reset_trackers

---@param tracker_to_update     TrackerClass
---@param force_name            ForceName         
---@param filter                Filter
---@param delta                 integer to add the count. Can be negative
local function update_tracker_count(tracker_to_update, force_name, filter, delta)
    -- We will assume that we already checked the force is tracking, and that
    -- this filter type is indeed tracking

    local force_counters = tracker_to_update.counters[force_name]
    if not force_counters then
        tracker_to_update.counters[force_name] = { }
        force_counters = tracker_to_update.counters[force_name]
    end

    local counter = force_counters[filter]
    if not counter then
        force_counters[filter] = { count = 0 }
        counter = force_counters[filter]

        -- Don't do anything else if we are decrementing, otherwise
        -- we will end up with negative counts
        if delta < 0 then return end
    end

    counter.count = (counter.count or 0) + delta
    if counter.count < 0 then counter.count = 0 end -- Clamp
end

---@param tracker_type  TrackerType
---@param force_name    ForceName         
---@param filters       Filter[]
---@return uint
local function get_tracker_count(tracker_type, force_name, filters)
    if not data.tracked_forces[force_name] then return 0 end
    local tracker = data.trackers[tracker_type]
    local counters = tracker.counters[force_name]
    if not counters then return 0 end

    local count = 0
    for _, filter in pairs(filters) do
        debug.debug_assert(tracker.tracking[filter], "No type "..tracker_type.." tracking for filter '"..filter.."'")
        debug.debug_assert(counters[filter] and counters[filter].count, "Counter doesn't exist")

        if counters[filter] and counters[filter].count then
            count = count + counters[filter].count
        end
    end

    return count
end

---Retreive a list of the forces being tracked by this tracker
---This could be useful when calculating statistics when the
-- victory screen is triggered.
---@return string[]
function tracker_lib.get_tracked_forces()
    -- Make a copy of the table, and turn it into an array.
    -- Don't want to give away a reference to an internal field
    local tracked_forces = { }
    for force_name, _ in pairs(data.tracked_forces) do
      table.insert(tracked_forces, force_name)
    end
    return tracked_forces
end

--- Start tracking an specifc entity (or array of entities) by name
--- This should be called during on_init and on_configuration_changed
---@param entity_names string|string[]
function tracker_lib.track_entity_count_by_name(entity_names)
    initialize_data() -- So that no dependency on this mod is requried
    if type(entity_names) == "string" then entity_names = { entity_names } end
    for _, entity_name in pairs(entity_names) do
        debug.debug_assert(
            is_valid_filter_functions[TRACKER_TYPE.ENTITY_BY_NAME](entity_name --[[@as Filter]]), 
            "Invalid entity name '"..entity_name.."'")
        refresh_tracker(data.trackers[TRACKER_TYPE.ENTITY_BY_NAME], entity_name --[[@as Filter]])
    end
end

--- Start tracking an specifc entity (or array of entities) by type
--- This should be called during on_init and on_configuration_changed
---@param entity_types string|string[]
function tracker_lib.track_entity_count_by_type(entity_types)
    initialize_data() -- So that no dependency on this mod is requried
    if type(entity_types) == "string" then entity_types = { entity_types } end
    for _, entity_type in pairs(entity_types) do
        debug.debug_assert(
            is_valid_filter_functions[TRACKER_TYPE.ENTITY_BY_TYPE](entity_type --[[@as Filter]]),
            "Invalid prototype type '"..entity_type.."'")
        refresh_tracker(data.trackers[TRACKER_TYPE.ENTITY_BY_TYPE], entity_type --[[@as Filter]])
    end
end

---Get the tracking entity count of an entity by some force
---@param force_name    ForceName to track entities from
---@param entity_names  string|string[]
---@return integer
function tracker_lib.get_entity_count_by_name(force_name, entity_names)
    debug.debug_assert(data.tracked_forces[force_name] ~= nil, "Untracked force counter requested `"..force_name.."'")
    if not data.tracked_forces[force_name] then return 0 end
    if type(entity_names) == "string" then entity_names = { entity_names } end
    if debug.debugger_active then for _, entity_name in pairs(entity_names) do
        debug.debug_assert(
            is_valid_filter_functions[TRACKER_TYPE.ENTITY_BY_NAME](entity_name --[[@as Filter]]), 
            "Invalid entity name '"..entity_name.."'")
    end end
    return get_tracker_count(TRACKER_TYPE.ENTITY_BY_NAME, force_name, entity_names)
end

---Get the tracking entity count of an entity by some force
---@param force_name    ForceName to track entities from
---@param entity_types  string|string[]
---@return integer
function tracker_lib.get_entity_count_by_type(force_name, entity_types)
    debug.debug_assert(data.tracked_forces[force_name] ~= nil, "Untracked force counter requested `"..force_name.."'")
    if not data.tracked_forces[force_name] then return 0 end
    if type(entity_types) == "string" then entity_types = { entity_types } end
    if debug.debugger_active then for _, entity_type in pairs(entity_types) do
        debug.debug_assert(
            is_valid_filter_functions[TRACKER_TYPE.ENTITY_BY_TYPE](entity_type --[[@as Filter]]), 
            "Invalid prototype type'"..entity_type.."'")
    end end
    return get_tracker_count(TRACKER_TYPE.ENTITY_BY_TYPE, force_name, entity_types)
end

---@param event EventData.on_robot_built_entity|EventData.on_built_entity|EventData.script_raised_built|EventData.script_raised_revive|EventData.on_entity_cloned
function tracker_lib.on_entity_created(event)
    local entity = event.created_entity or event.entity or event.destination
    if not entity or not entity.valid then return end
    if blacklist.surface(entity.surface.name) then return end
    local force_name = entity.force.name --[[@as ForceName]]
    if not data.tracked_forces[force_name] then return end  -- Will handle blacklist

    local trackers = data.trackers

    local entity_name = entity.name --[[@as Filter]]
    local tracker = trackers[TRACKER_TYPE.ENTITY_BY_NAME]
    if tracker.tracking[entity_name] then
        update_tracker_count(tracker, force_name, entity_name, 1)
    end

    local entity_type = entity.type --[[@as Filter ]]
    tracker = trackers[TRACKER_TYPE.ENTITY_BY_TYPE]
    if tracker.tracking[entity_type] then
        update_tracker_count(tracker, force_name, entity_type, 1)
    end
end

function tracker_lib.on_entity_removed(event)
    local entity = event.created_entity or event.entity or event.destination
    if not entity or not entity.valid then return end
    if blacklist.surface(entity.surface.name) then return end
    local force_name = entity.force.name --[[@as ForceName]]
    if not data.tracked_forces[force_name] then return end  -- Will handle blacklist

    local trackers = data.trackers

    local entity_name = entity.name --[[@as Filter]]
    local tracker = trackers[TRACKER_TYPE.ENTITY_BY_NAME]
    if tracker.tracking[entity_name] then
        update_tracker_count(tracker, force_name, entity_name, -1)
    end

    local entity_type = entity.type --[[@as Filter]]
    local tracker = trackers[TRACKER_TYPE.ENTITY_BY_TYPE]
    if tracker.tracking[entity_type] then
        update_tracker_count(tracker, force_name, entity_type, -1)
    end
end

---@param event EventData.on_player_changed_force
function tracker_lib.on_player_changed_force(event)
    local force_name = event.force.name
    if blacklist.force(force_name) then return end
    data.tracked_forces[force_name] = true
end

---Transfer the counters from the old force to the new force
---@param event EventData.on_forces_merged
function tracker_lib.on_forces_merged(event)
    local deleted_force_name = event.source_name --[[@as ForceName]]
    if not data.tracked_forces[deleted_force_name] then return end

    local merged_force_name = event.destination.name  --[[@as ForceName]]
    if not data.tracked_forces[merged_force_name] then
        -- Just stop tracking the deleted force. The actual data will be deleted later
        data.tracked_forces[deleted_force_name] = nil
        return -- nothing further to do
    end

    -- Transfer the counts
    for tracker_type, tracker in pairs(data.trackers) do
        for filter, _ in pairs(tracker.tracking) do
            local count_from_old_force = get_tracker_count(tracker_type, deleted_force_name, {filter})
            update_tracker_count(tracker, merged_force_name, filter, count_from_old_force)
        end
    end

    -- stop tracking the deleted force. The actual data will be deleted later
    data.tracked_forces[deleted_force_name] = nil
end

tracker_lib.events = {
    [defines.events.on_robot_built_entity]  = tracker_lib.on_entity_created,
    [defines.events.on_built_entity]        = tracker_lib.on_entity_created,
    [defines.events.script_raised_built]    = tracker_lib.on_entity_created,
    [defines.events.script_raised_revive]   = tracker_lib.on_entity_created,
    [defines.events.on_entity_cloned]       = tracker_lib.on_entity_created,

    [defines.events.on_player_mined_entity] = tracker_lib.on_entity_removed,
    [defines.events.on_robot_mined_entity]  = tracker_lib.on_entity_removed,
    [defines.events.on_entity_died]         = tracker_lib.on_entity_removed,
    [defines.events.script_raised_destroy]  = tracker_lib.on_entity_removed,

    [defines.events.on_player_changed_force]= tracker_lib.on_player_changed_force,
}

return tracker_lib