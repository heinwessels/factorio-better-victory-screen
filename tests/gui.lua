local gui = require("scripts.gui")
local test_util = require("tests.test_util")
local util = require("util")

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

-- Recursively looks through a table's values to find a string
---@param t table
---@param target string
---@return boolean?
local function find_in_table_recursively(t, target)
    for _, v in pairs(t) do
        if type(v) == "table" then
            return find_in_table_recursively(v, target)
        elseif type(v) == "string" then
            if v == target then return true end -- Found it!
        end
    end
end

---@param caption string to find in localized string tables
---@param element LuaGuiElement?
---@return boolean?
local function caption_exists_in_gui(caption, element)
    if type(caption) ~= "string" then error("Expects only string captions") end
    if not element then element = game.player.gui.screen.bvs_game_finished end

    if element.caption and type(element.caption) == "table" then
        if find_in_table_recursively(element.caption --[[@as table]], caption) then
            return true -- Found it!
        end
    end

    for _, child in pairs(element.children) do
        if caption_exists_in_gui(caption, child) then
            -- Propagate what the child up through the generations
            return true
        end
    end
end

---@param tooltip string to find in localized string tables
---@param element LuaGuiElement?
---@return boolean?
local function tooltip_exists_in_gui(tooltip, element)
    if type(tooltip) ~= "string" then error("Expects only string tooltips") end
    if not element then element = game.player.gui.screen.bvs_game_finished end

    if element.tooltip and type(element.tooltip) == "table" then
        if find_in_table_recursively(element.tooltip --[[@as table]], tooltip) then
            return true -- Found it!
        end
    end

    for _, child in pairs(element.children) do
        if tooltip_exists_in_gui(tooltip, child) then
            -- Propagate what the child up through the generations
            return true
        end
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

function tests.create_gui_with_invalid_message_debug_death()
    test_util.assert_death(gui.create, {game.player, { }, {hungry = true}})
end

function tests.create_gui_with_invalid_message_release_ignore()
    test_util.mock_release()

    gui.create(game.player, { }, {sleepy = true})

    test_util.assert_table_equal(find_victory_label(), {"gui-game-finished.victory"})
end

function tests.create_statistics()
    local statistics = { gymnastics = { stats = {
        jumping = { value = 5, unit = "distance", order = "b" }
    }}}
    gui.create(game.player, statistics)

    test_util.assert_true(caption_exists_in_gui("bvs-categories.gymnastics"))
    test_util.assert_true(caption_exists_in_gui("bvs-stats.jumping"))
    test_util.assert_falsy(tooltip_exists_in_gui("bvs-stat-tooltip.jumping"))
end

function tests.create_stat_with_tooltip_shown()
    local statistics = { gymnastics = { stats = {
        jumping = { value = 5, unit = "distance", order = "b" , has_tooltip = true}
    }}}
    gui.create(game.player, statistics)

    test_util.assert_true(caption_exists_in_gui("bvs-categories.gymnastics"))
    test_util.assert_true(caption_exists_in_gui("bvs-stats.jumping"))
    test_util.assert_true(tooltip_exists_in_gui("bvs-stat-tooltip.jumping"))
end

function tests.create_category_has_no_stats_ignored()
    local statistics = { gymnastics = {  } }
    gui.create(game.player, statistics)

    test_util.assert_falsy(caption_exists_in_gui("bvs-categories.gymnastics"))
end

function tests.create_statistics_stat_has_no_value_ignored()
    local statistics = { gymnastics = { stats = {
        jumping = {  }
    }}}
    gui.create(game.player, statistics)

    test_util.assert_true(caption_exists_in_gui("bvs-categories.gymnastics"))
    test_util.assert_falsy(caption_exists_in_gui("bvs-stats.jumping"))
end

function tests.create_statistics_stat_has_no_unit_not_ignored()
    local statistics = { gymnastics = { stats = {
        jumping = { value = 5, order = "b" }
    }}}
    gui.create(game.player, statistics)

    test_util.assert_true(caption_exists_in_gui("bvs-categories.gymnastics"))
    test_util.assert_true(caption_exists_in_gui("bvs-stats.jumping"))
end

function tests.create_statistics_unexpected_value_debug_death()
    local statistics = { gymnastics = { stats = {
        jumping = { value = {fish = "hungry"}, unit = "distance", order = "b" }
    }}}
    test_util.assert_death(gui.create, {game.player, statistics})
end

function tests.create_statistics_unexpected_value_release_ignored()
    test_util.mock_release()

    local statistics = { gymnastics = { stats = {
        jumping = { value = {invalid="value"}, unit = "distance", order = "b" }
    }}}
    gui.create(game.player, statistics)

    test_util.assert_true(caption_exists_in_gui("bvs-categories.gymnastics"))
    test_util.assert_falsy(caption_exists_in_gui("bvs-stats.jumping"))
end

return gui_tests