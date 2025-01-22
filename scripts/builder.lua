local lib = require("scripts.lib")
local formatter = require("scripts.formatter")
local debug = require("scripts.debug")

local builder = { }

---@class StatisticEntry
---@field value number
---@field unit string
---@field ignore boolean?
---@field localised_name LocalisedString? To supply a custom name
---@field localised_tooltip LocalisedString? If supplied then has_tooltip is ignored

---@class StatisticCategory
---@field stats table<string, StatisticEntry>
---@field ignore boolean?

---@alias StatisticCategories table<string, StatisticCategory>

---@param victory_message StatisticCategories
---@param categories StatisticCategories
---@return LocalisedString message
function builder.build(victory_message, categories)
    local message = {""}
    local first = true

    table.insert(message, victory_message)
    table.insert(message, "\n\n")

    for _, category_name in pairs(lib.table.ordered_keys(categories)) do
        local category = categories[category_name]
        if category.ignore then goto continue_category end
        if not category.stats then log("Category: '" .. category_name .. "' has no stats. Ignoring") goto continue_category end

        if not first then table.insert(message, "\n") end
        table.insert(message, {"", "[font=default-bold][color=255,230,192]", {"bvs-categories."..category_name}, "[/color][/font]\n"})
        first = false

        for _, stat_name in pairs(lib.table.ordered_keys(category.stats or { })) do
            local stat = category.stats[stat_name]
            if stat.ignore then goto continue_stat end

            if not stat.value then log("Statistic: '" .. stat_name .. "' has no value. Ignoring") goto continue_stat end

            -- Safely format the value, and ignore it if the formatting crashes
            local formatted_value
            local success, error_message = pcall(function()
                formatted_value = formatter.format(stat.value, stat.unit)
            end)
            debug.debug_assert(success, error_message)
            if not success then goto continue_stat end

            -- TODO: These two are still a little unsafe because other mods can pass us anything.
            -- We could somehow verify that it's indeed a localised string, or somehow pcall it
            local localised_name = stat.localised_name or {"bvs-stats."..stat_name}

            table.insert(message, {"", "[color=0.7,0.7,0.7]", localised_name, "[/color]"})
            table.insert(message, ":   ")
            table.insert(message, {"", "[font=default-semibold]", formatted_value, "[/font]"})
            table.insert(message, "\n")

            ::continue_stat::
        end

        ::continue_category::
    end

    return message
end

---A localised string can only have 20 parameters. But you can embed
---another complete localised string with 20 into a single parameter...
---@param message LocalisedString
---@return LocalisedString condensed_message
function builder.unflatten(message)
    local condensed_message = {""}
    local index = 1
    for i=1,20 do
        if not message[index] then break end

        local line = {""}

        for j=1,20 do
            if not message[index] then break end
            table.insert(line, message[index])
            index = index + 1
        end

        table.insert(condensed_message, line)
    end
    return condensed_message
end

return builder