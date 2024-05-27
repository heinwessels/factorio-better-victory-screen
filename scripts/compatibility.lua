local util = require("util")

---@class Compatibility
---@field initialize fun(event_handler: unknown)
---@field gather fun(forces: LuaForce[]): unknown

local module = { }

---@class CompatibilityWrapper
---@field gather fun(forces:LuaForce[]):table ?

---@type CompatibilityWrapper[]
local compatibilities = {
    require("scripts.compatibility.cargo-ships"),
    require("scripts.compatibility.lunar-landings"),
}

function module.initialize(event_handler)
    for _, compat in pairs(compatibilities) do
        event_handler.add_lib(compat)
    end
end

---Gathers statistics for all built in compatibilities
---@param forces LuaForce[] to gather statistics from
---@retun table
function module.gather(forces)
    local stats = { by_force = { }, by_player = { } }
    for _, compat in pairs(compatibilities) do
        if compat.gather then
            stats = util.merge{stats, compat.gather(forces)}
        end
    end
    return stats
end

return module --[[@as Compatibility]]