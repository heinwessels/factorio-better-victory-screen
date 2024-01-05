local test_lib = { }

---@alias Test fun()

---@class TestSuite
---@field setup fun()? Optional function to call before each test
---@field tests table<string, Test>

---@type table<string, TestSuite>
local test_suites = {
    ["tracker"]     = require("tests.tracker"),
    ["blacklist"]   = require("tests.blacklist"),
    -- ["formatting"]  = require("tests.formatting"), -- Needs some love
}

function test_lib.add_commands()
    commands.add_command("bvs-test", nil, function(command)
        local suite_count = 0
        local count = 0
        for test_suite_name, test_suite in pairs(test_suites) do
            local suit_test_count = 0
            for _, test in pairs(test_suite.tests) do
                if test_suite.setup then test_suite.setup() end
                test()
                suit_test_count = suit_test_count + 1
            end
            game.print("[TESTS] Finished "..suit_test_count.." tests in '"..test_suite_name.."' suite.")
            count = count + suit_test_count
            suite_count = suite_count + 1
        end
        game.print("[TESTS] Success! Executed "..count.." tests across "..suite_count.." suites.")
    end)
end

return test_lib