---@diagnostic disable: missing-fields

local statistics = require("scripts.statistics")
local test_util = require("tests.test_util")
local util = require("util")

local space_age_tests = { tests = { } }
local tests = space_age_tests.tests

function tests.hello()
end

return space_age_tests