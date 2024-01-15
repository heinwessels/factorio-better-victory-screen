local gui = require("scripts.gui")
local test_util = require("tests.test_util")

local gui_tests = { tests = { } }
local tests = gui_tests.tests

---Recursively find the victory label
---@param element LuaGuiElement?
---@return any?
local function find_victory_label(element)
    if not element then element = game.player.gui.screen.bvs_game_finished end
    if element.name == "victory_label" then return element.caption end
    for _, child in pairs(element.children) do
        local caption = find_victory_label(child)
        if caption then return caption end
    end
end

function gui_tests.cleanup()
    if game.player.gui.screen.bvs_game_finished then
        gui.handlers.continue({player_index = game.player.index})
    end
end

function tests.create_gui()
    gui.create(game.player, { })

    -- If no message is given then the default message is shown
    test_util.assert_table_equal(find_victory_label(), {"gui-game-finished.victory"})
end

function tests.create_gui_with_string_message()
    gui.create(game.player, { }, "hello")

    test_util.assert_string_equal(find_victory_label(), "hello")
end

function tests.create_gui_with_localized_message()
    gui.create(game.player, { }, {"item-name.iron-plate"})

    test_util.assert_table_equal(find_victory_label(), {"item-name.iron-plate"})
end

return gui_tests