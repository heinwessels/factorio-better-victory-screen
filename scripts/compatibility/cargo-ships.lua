if not script.active_mods["cargo-ships"] then return { } end

local util = require("util")
local tracker = require("scripts.tracker")

local module = { }

-- Cargo ships builds its waterways from rail prototypes, so the
-- lengths match the ones used for rails in the total rail length.
local waterway_lengths = {
    ["straight-waterway"] = 2, -- This isn't really true for diagonal pieces but meh
    ["half-diagonal-waterway"] = 4.47,
    ["curved-waterway-a"] = 5.06,
    ["curved-waterway-b"] = 5.06,
    ["legacy-straight-waterway"] = 2,
    ["legacy-curved-waterway"] = 8,
}

local function setup()
    for name in pairs(waterway_lengths) do
        if prototypes.entity[name] then
            tracker.track_entity_count_by_name(name)
        end
    end
end

module.on_init = setup
module.on_configuration_changed = setup

---@param forces LuaForce[] to gather statistics from
function module.gather(forces)
    local stats = { by_force = { } }
    local tracked_force_names = util.list_to_map(tracker.get_tracked_forces())
    for _, force in pairs(forces) do
        if tracked_force_names[force.name] then

            local distance = 0
            for name, length in pairs(waterway_lengths) do
                if prototypes.entity[name] then
                    local count = tracker.get_entity_count_by_name(force.name --[[@as ForceName]], name)
                    distance = distance + (count * length)
                end
            end

            stats.by_force[force.name] = {
                ["infrastructure"] = { stats = {
                    ["waterways"] = { value = math.floor(distance), unit = "distance", order = "h" }
                }}
            }

        end
    end
    return stats
end

return module
