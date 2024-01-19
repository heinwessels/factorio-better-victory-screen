local glib = require("scripts.glib")
local lib = require("scripts.lib")
local formatter = require("scripts.formatter")
local debug = require("scripts.debug")

local gui = { handlers = { } }
local handlers = gui.handlers
local e = defines.events

local name_column_width = 137
local value_column_width = 82   -- Keeps the golden ration used by vanilla gui

---@param player LuaPlayer
---@param categories StatisticCategories
---@param message string|LocalisedString ? to show instead of default victory message
function gui.create(player, categories, message)
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
        args = {type = "frame", name = "bvs_game_finished", direction = "vertical", caption = {"gui-game-finished.title"}},
        style_mods = {maximal_height = 930},
        handlers = {[e.on_gui_closed] = handlers.continue},
        children = {{
            args = {type = "frame", direction = "vertical", style = "window_content_frame_packed"},
            children = {{
                args = {type = "frame", style = "finished_game_subheader_frame"},
                style_mods = {horizontally_stretchable = true},
                children = {{
                    args = {type = "label", name = "victory_label",  caption = {"gui-game-finished.victory"}},
                }}
            }, {
                args = {type = "scroll-pane", name = "statistics", style = "scroll_pane_under_subheader"},
                style_mods = {horizontally_squashable = true},
                children = {{
                    args = {type = "table", column_count = 2, style = "finished_game_table"}, -- can't get rid of inner borders on the style yet
                    children = {{
                        args = {type = "flow"},
                        children = {{
                            args = {type = "label", caption = {"gui-game-finished.time-played"}, style = "caption_label"},
                        }, {
                            args = {type = "empty-widget"},
                            style_mods = {minimal_width = name_column_width, horizontally_stretchable = true},
                        }}
                    }, {
                        args = {type = "label", caption = formatter.format_time(game.tick)},
                        style_mods = {minimal_width = value_column_width, horizontal_align = "right"}, -- width required because can't sync table column widths yet
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

    if message then
        -- Attempt to add the victory (losing) message. We will do this in a safe way
        -- so that if something goes wrong for some reason then we will ignore it
        local success, error_message = pcall(function(caption)
            refs.victory_label.caption = caption end, message)
        debug.debug_assert(success, error_message)
    end

    -- Now start adding the statistics
    local stats_gui = refs.statistics
    for _, category_name in pairs(lib.table.ordered_keys(categories)) do
        local category = categories[category_name]
        if category.ignore then goto continue_category end
        if not category.stats then log("Category: '" .. category_name .. "' has no stats. Ignoring") goto continue_category end

        local def = {
            args = {type = "table", column_count = 2, style = "finished_game_table"},
            children = {{
                args = {type = "label", caption = {"bvs-categories."..category_name}, style = "caption_label"},
                style_mods = {horizontally_stretchable = true},
            }, {
                args = {type = "empty-widget"},
                style_mods = {minimal_width = value_column_width, horizontal_align = "right"}, -- width required because can't sync table column widths yet
            }}
        }

        local category_table = glib.add(stats_gui, def)

        for _, stat_name in pairs(lib.table.ordered_keys(category.stats or { })) do
            local stat = category.stats[stat_name]
            if stat.ignore then goto continue_stat end

            if not stat.value then log("Statistic: '" .. stat_name .. "' has no value. Ignoring") goto continue_stat end

            -- Safely format the value, and ignore it if the formatting crashes
            local formatted_value
            local formatted_tooltip
            local success, error_message = pcall(function()
                formatted_value = formatter.format(stat.value, stat.unit)
                formatted_tooltip = formatter.format_tooltip(stat.value, stat.unit)
            end)
            debug.debug_assert(success, error_message)
            if not success then goto continue_stat end

            category_table.add{
                type = "label", 
                caption = {"", {"bvs-stats."..stat_name}, ":"},
                tooltip = {"?", {"bvs-stat-tooltip."..stat_name}, ""}
            }

            category_table.add{
                type = "label",
                caption = formatted_value,
                tooltip = formatted_tooltip,
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
