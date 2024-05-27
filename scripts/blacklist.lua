local util = require("util")

local blacklist = { }

-- This is a smart blacklist. It needs to be hooked up to some events.

---@class BlacklistGlobalData
---@field surfaces table<string, boolean>   blacklisted surface names
---@field forces table<string, boolean>     blacklisted force names

local data_key = "_bvs_blacklist_cache"

---@type BlacklistGlobalData
data = {
    surfaces = { },
    forces = { },
}

--- List of hardcoded surface names to ignore
---@type table<string, boolean>
local surface_names_hardcoded = util.list_to_map{
    "aai-signals",      -- AAI Signal Transmission
}

--- List of patterns of blacklisted surface names
---@type string[]
local surface_name_patterns = {
    "^EE_TESTSURFACE_", -- Editor Extensions
    "^BPL_TheLab",      -- The Blueprint Designer Lab
    "^bpsb-",           -- Blueprint Sandboxes
}

---@param surface_name string
---@return boolean
local function is_surface_blacklisted(surface_name)
    is_blacklisted = false
    if surface_names_hardcoded[surface_name] then return true end
    for _, pattern in pairs(surface_name_patterns) do
        if string.match(surface_name, pattern) ~= nil then return true end
    end
    return false
end

---@param surface_name string
---@return boolean is_blacklisted
function blacklist.surface(surface_name)
    -- First attempt to use the cached value
    local is_blacklisted = data.surfaces[surface_name]
    if is_blacklisted ~= nil then return is_blacklisted end

    -- No cached value yet. Need to calculate it and then cache it
    is_blacklisted = is_surface_blacklisted(surface_name)
    data.surfaces[surface_name] = is_blacklisted -- Cache it
    return is_blacklisted
end

--- List of hardcoded force names to ignore
---@type table<string, boolean>
local force_names_hardcoded = util.list_to_map{
    "enemy",

    "conquest",             -- Space Exploration
    "ignore",               -- Space Exploration
    "capture",              -- Space Exploration
    "friendly",             -- Space Exploration

    "kr-internal-turrets",  -- Krastorio 2
}

--- List of patterns of blacklisted force names
---@type string[]
local force_name_patterns = {
    "^EE_TESTFORCE_",   -- Editor Extensions
    "^BPL_TheLab",      -- The Blueprint Designer Lab
    "^bpsb-",           -- Blueprint Sandboxes
}

---@param force_name string
---@return boolean
local function is_force_blacklisted(force_name)
    if force_names_hardcoded[force_name] then return true end
    for _, pattern in pairs(force_name_patterns) do
        if string.match(force_name, pattern) ~= nil then return true end
    end
    return false
end

---@param force_name string
---@return boolean
function blacklist.force(force_name)
    -- First attempt to use the cached value
    local is_blacklisted = data.forces[force_name]
    if is_blacklisted ~= nil then return is_blacklisted end

    -- No cached value yet. Need to calculate it and then cache it
    is_blacklisted = is_force_blacklisted(force_name)
    data.forces[force_name] = is_blacklisted
    return is_blacklisted
end

local function initialize_cache()
    global[data_key] = global[data_key] or data
    data = global[data_key] --[[@as BlacklistGlobalData]]
end

local function reset_cache()
    data.surfaces = { }
    data.forces = { }
end

blacklist.on_init = initialize_cache
blacklist.on_load = function() data = global[data_key] or data end
blacklist.on_configuration_changed = reset_cache

return blacklist