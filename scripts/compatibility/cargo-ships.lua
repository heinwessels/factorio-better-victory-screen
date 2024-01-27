if not script.active_mods["cargo-ships"] then return { } end

local util = require("util")
local tracker = require("scripts.tracker")

local module = { }

local function setup()
    tracker.track_entity_count_by_name("straight-water-way")
    tracker.track_entity_count_by_name("curved-water-way")
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

            -- Assume each belt has a distance of 2m.
            -- This isn't really true for diagonal pieces but meh
            local straight = tracker.get_entity_count_by_name(force.name --[[@as ForceName]], "straight-water-way")
            distance = distance + (straight * 2)

            -- Assume each curved rail has a length of 8m.
            -- TODO This can be estimated better! 
            local curved = tracker.get_entity_count_by_name(force.name --[[@as ForceName]], "curved-water-way")
            distance = distance + (curved * 8)

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