if not mods["space-age"] then return end

---@param root table
---@param lookup string[]
---@return table?
local function find_table_safe(root, lookup)
    local key = lookup[1]
    if not key then return root end
    if not root[key] then return nil end
    return find_table_safe(root[key], { table.unpack(lookup, 2) })
end


data:extend{
    {
        type = "custom-event",
        name = "bvs-biter-hatch",
    }
}

local add_trigger_to_biter_egg = function()
    local egg = data.raw.item["biter-egg"]
    if not egg then return end

    ---@type data.TriggerEffectItem?
    local source_effects = find_table_safe(egg, {
        "spoil_to_trigger_result",
        "trigger",
        "action_delivery",
        "source_effects"
    })
    if not source_effects then return end
    table.insert(source_effects, {
        type = "script",
        effect_id = "", -- Why can't we have this nil boskid?
        custom_event = "bvs-biter-hatch",
    })
end
add_trigger_to_biter_egg()
