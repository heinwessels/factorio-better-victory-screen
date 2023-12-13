local glib = require("scripts.glib")
local lib = require("scripts.lib")

local gui = {}

local handlers = {}
local e = defines.events

local name_column_width = 137
local value_column_width = 82   -- Keeps the golden ration used by vanilla gui

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
        args = {type = "frame", name = "bvs_game_finished", direction = "vertical", caption = {"gui-game-finished.title"}},
        style_mods = {maximal_height = 930},
        handlers = {[e.on_gui_closed] = handlers.continue},
        children = {{
            args = {type = "frame", direction = "vertical", style = "window_content_frame_packed"},
            children = {{
                args = {type = "frame", style = "finished_game_subheader_frame"},
                style_mods = {horizontally_stretchable = true},
                children = {{
                    args = {type = "label", caption = {"gui-game-finished.victory"}},
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
                        args = {type = "label", caption = lib.format_time(game.tick)},
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

    local stats_gui = refs.statistics

    for category_name, category in pairs(categories) do
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

        for stat_name, stat in pairs(category.stats or {}) do
            category_table.add{
                type = "label", 
                caption = {"", {"bvs-stats."..stat_name}, ":"},
                tooltip = {"?", {"bvs-stat-tooltip."..stat_name}, ""}
            }
            category_table.add{type = "label", caption = stat.value}
        end
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
