---@diagnostic disable: missing-fields

local statistics = require("scripts.statistics")
local test_util = require("tests.test_util")
local util = require("util")

local statistics_tests = { tests = { } }
local tests = statistics_tests.tests

function tests.on_init_and_config_determine_ores()
    global.statistics = { } -- Reset
    statistics.on_init({})
    test_util.assert_greater_than(#global.statistics.ore_names, 0)

    global.statistics = { } -- Reset
    statistics.on_configuration_changed({})
    test_util.assert_greater_than(#global.statistics.ore_names, 0)
end

return statistics_tests