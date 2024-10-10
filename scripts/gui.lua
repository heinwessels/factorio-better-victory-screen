local glib = require("scripts.glib")
local lib = require("scripts.lib")
local formatter = require("scripts.formatter")
local debug = require("scripts.debug")

local gui = { handlers = { } }
local handlers = gui.handlers
local e = defines.events

local name_column_width = 137
local value_column_width = 82   -- Keeps the golden ration used by vanilla gui

---@class StatisticEntry
---@field value number
---@field unit string
---@field ignore boolean?
---@field has_tooltip boolean? Then assumes valid entry exists in locale
---@field localised_name LocalisedString? To supply a custom name
---@field localised_tooltip LocalisedString? If supplied then has_tooltip is ignored

---@class StatisticCategory
---@field stats table<string, StatisticEntry>
---@field ignore boolean?

---@alias StatisticCategories table<string, StatisticCategory>

---@param player LuaPlayer
---@param categories StatisticCategories
function gui.create(player, categories)
    player.play_sound{path = "utility/game_won"}
    ---@diagnostic disable: missing-fields

    --- Create the semi-transparent backdrop that prevents other GUIs from being clickable
    local resolution = player.display_resolution
    local scale = player.display_scale
    glib.add(player.gui.screen, {
        args = {type = "frame", name = "bvs_backdrop", style = "bvs_frame_semitransparent", position = {0, 0}},
        style_mods = {minimal_width=resolution.width / scale, minimal_height=resolution.height / scale},
        handlers = {[e.on_gui_click] = handlers.backdrop}
    })

    --- Create the actual GUI
    local frame, refs = glib.add(player.gui.screen, {
        args = {type = "frame", name = "bvs_game_finished", direction = "vertical", caption = {"gui-game-finished.victory"}},
        style_mods = {maximal_height = 930},
        handlers = {[e.on_gui_closed] = handlers.continue},
        children = {{
            args = {type = "frame", direction = "horizontal", style = "subheader_frame"},
            style_mods = {horizontally_stretchable = true, horizontally_squashable = true},
            children = {{
                args = {type = "label",  caption = {"gui-game-finished.time-played"}, style="subheader_caption_label"},
            }},
        }, {
            args = {type = "frame", name="content_frame", style = "inside_shallow_frame_with_padding"},
            children = {{
                args = {type = "flow", name="inner_flow", style = "inset_frame_container_horizontal_flow"},
                children = {{ -- The image
                    args = {type = "frame", name="content_frame", direction = "vertical", style = "deep_frame_in_shallow_frame"},
                    style_mods = {horizontally_stretchable = true, horizontally_squashable = true},
                    children = {{
                        args = {type = "sprite", sprite = "bvs-victory-sprite"}
                    }}
                }, { -- The stats
                    args = {type = "frame", style = "deep_frame_in_shallow_frame_for_description"},
                    style_mods = { padding = 4, maximal_width = 400, maximal_height = 600 },
                    children = {{
                        args = {type = "scroll-pane", name = "statistics", style = "scroll_pane_under_subheader"},
                        style_mods = { padding = 0, maximal_width = 400, maximal_height = 600 },
                        -- style_mods = { horizontally_squashable = true },
                        children = { }
                    }}
                }}
            }}
        }, {
            args = {type = "flow", direction = "horizontal", style = "dialog_buttons_horizontal_flow"},
            children = {{
                args = {type = "button", caption = {"gui-game-finished.finish"}, style = "red_back_button",
                        enabled=false, tooltip = "Modded GUIs cannot exit the game. It is still possible to 'Continue' and exit manually."},
            }, {
                args = {type = "empty-widget"},
                style_mods = {horizontally_stretchable = true},
            }, {
                args = {type = "button", caption = {"gui-game-finished.continue"}, style = "confirm_button_without_tooltip"},
                handlers = {[e.on_gui_click] = handlers.continue}
            }}
        }}
    })
    frame.force_auto_center()
    player.opened = frame

    -- Now start adding the statistics
    local stats_gui = refs.statistics
    for _, category_name in pairs(lib.table.ordered_keys(categories)) do
        local category = categories[category_name]
        if category.ignore then goto continue_category end
        if not category.stats then log("Category: '" .. category_name .. "' has no stats. Ignoring") goto continue_category end

        local def = {
            args = {type = "frame", style = "bvs_finished_game_frame"},
            style_mods = { maximal_width = 400 },
            children = {{
                args = {type = "table", column_count = 2},
                children = {{
                    args = {type = "label", caption = {"bvs-categories."..category_name}, style = "caption_label"},
                    style_mods = {horizontally_stretchable = true},
                }, {
                    args = {type = "empty-widget"},
                    style_mods = {minimal_width = value_column_width, horizontal_align = "right"}, -- width required because can't sync table column widths yet
                }}
            }}
        }

        local category_table = glib.add(stats_gui, def).children[1]

        for _, stat_name in pairs(lib.table.ordered_keys(category.stats or { })) do
            local stat = category.stats[stat_name]
            if stat.ignore then goto continue_stat end

            if not stat.value then log("Statistic: '" .. stat_name .. "' has no value. Ignoring") goto continue_stat end
            local has_tooltip = stat.has_tooltip or (stat.localised_tooltip ~= nil)

            -- Safely format the value, and ignore it if the formatting crashes
            local formatted_value
            local fomatted_value_tooltip
            local success, error_message = pcall(function()
                formatted_value = formatter.format(stat.value, stat.unit)
                fomatted_value_tooltip = formatter.format_tooltip(stat.value, stat.unit)
            end)
            debug.debug_assert(success, error_message)
            if not success then goto continue_stat end

            -- TODO: These two are still a little unsafe because other mods can pass us anything.
            -- We could somehow verify that it's indeed a localised string, or somehow pcall it
            local localised_name = stat.localised_name or {"bvs-stats."..stat_name}
            local localised_tooltip = stat.localised_tooltip or {"bvs-stat-tooltip."..stat_name}

            category_table.add{
                type = "label",
                caption = {"", localised_name, ":", (has_tooltip and " [img=info]" or "")},
                tooltip = has_tooltip and localised_tooltip or ""
            }

            category_table.add{
                type = "label",
                caption = formatted_value,
                tooltip = fomatted_value_tooltip,
            }

            ::continue_stat::
        end

        ::continue_category::
    end
    ---@diagnostic enable: missing-fields
end

function handlers.backdrop(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    player.gui.screen.bvs_game_finished.bring_to_front()
end

function handlers.continue(event)
    local player = game.get_player(event.player_index) --[[@as LuaPlayer]]
    player.gui.screen.bvs_backdrop.destroy()
    player.gui.screen.bvs_game_finished.destroy()
    game.tick_paused = false
end

glib.add_handlers(handlers)

return gui
