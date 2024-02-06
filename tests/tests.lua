local test_util = require("tests.test_util")

local test_lib = { }

---@alias Test fun()

---@class TestSuite
---@field setup fun()? Optional function to call before each test
---@field cleanup fun()? Optional function to call after each test
---@field tests table<string, Test>

---@type table<string, TestSuite>
local test_suites = {
    ["tracker"]     = require("tests.tracker"),
    ["blacklist"]   = require("tests.blacklist"),
    ["trigger"]     = require("tests.trigger"),
    ["formatting"]  = require("tests.formatting"),
    ["gui"]         = require("tests.gui"),
    ["statistics"]  = require("tests.statistics"),
    ["migrations"]  = require("tests.migrations"),
}

function test_lib.add_commands()
    commands.add_command("bvs-test", nil, function(command)
        game.reload_script()

        local profiler = game.create_profiler(false)

        local suite_count = 0
        local count = 0
        for test_suite_name, test_suite in pairs(test_suites) do
            local suit_test_count = 0
            for _, test in pairs(test_suite.tests) do
                test_util.mock_release(false) -- Hard reset
                if test_suite.setup then test_suite.setup() end
                test()
                if test_suite.cleanup then test_suite.cleanup() end
                suit_test_count = suit_test_count + 1
            end
            game.print("[TESTS] Finished "..suit_test_count.." tests in '"..test_suite_name.."' suite.")
            count = count + suit_test_count
            suite_count = suite_count + 1
        end

        profiler.stop()
        game.print({"",
            "[TESTS] Success! ",
            "Executed "..count.." tests across "..suite_count.." suites. ",
            profiler,
            "."
        })
    end)
end

return test_lib