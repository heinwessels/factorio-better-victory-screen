local blacklist = require("scripts.blacklist")
local test_util = require("tests.test_util")

local blacklist_tests = { tests = { } }

local blacklist_cache_name = "_bvs_blacklist_cache"

---@param surface_name string
---@return boolean?
local function get_cached_surface(surface_name)
    return global[blacklist_cache_name].surfaces[surface_name]
end

---@param force_name string
---@return boolean?
local function get_cached_force(force_name)
    return global[blacklist_cache_name].forces[force_name]
end

function blacklist_tests.setup()
    -- Sneakily delete the blacklist's internal cache before each test
    global[blacklist_cache_name].surfaces = { }
    global[blacklist_cache_name].forces = { }
end

function blacklist_tests.tests.nauvis_not_blacklisted()
    test_util.assert_false(blacklist.surface("nauvis"))
    -- Check the cached value as well
    test_util.assert_false(get_cached_surface("nauvis"))
end

function blacklist_tests.tests.new_surface_not_blacklisted()
    test_util.assert_nil(get_cached_surface("new-surface"))
    test_util.assert_false(blacklist.surface("new-surface"))
    test_util.assert_false(get_cached_surface("new-surface"))
end

function blacklist_tests.tests.new_surface_hardcoded_blacklisted()
    local name = "aai-signals" -- Know this should be blacklisted
    test_util.assert_nil(get_cached_surface(name))
    test_util.assert_true(blacklist.surface(name))
    test_util.assert_true(get_cached_surface(name))
end

function blacklist_tests.tests.new_surface_pattern_blacklisted()
    local name = "EE_TESTSURFACE_hello!" -- Know this should be blacklisted
    test_util.assert_nil(get_cached_surface(name))
    test_util.assert_true(blacklist.surface(name))
    test_util.assert_true(get_cached_surface(name))
end

function blacklist_tests.tests.on_config_changed_resets_surface_cache()
    test_util.assert_nil(get_cached_surface("new-surface"))
    test_util.assert_false(blacklist.surface("new-surface"))
    test_util.assert_false(get_cached_surface("new-surface"))

    blacklist.on_configuration_changed()

    test_util.assert_nil(get_cached_surface("new-surface"))
    test_util.assert_false(blacklist.surface("new-surface"))
    test_util.assert_false(get_cached_surface("new-surface"))
end


function blacklist_tests.tests.default_forces_correctly_blacklisted()
    test_util.assert_false(blacklist.force("player"))
    test_util.assert_false(get_cached_force("player"))

    test_util.assert_false(blacklist.force("neutral"))
    test_util.assert_false(get_cached_force("neutral"))

    test_util.assert_true(blacklist.force("enemy"))
    test_util.assert_true(get_cached_force("enemy"))
end

function blacklist_tests.tests.new_force_not_blacklisted()
    local name = "vogon"
    test_util.assert_nil(get_cached_force(name))
    test_util.assert_false(blacklist.force(name))
    test_util.assert_false(get_cached_force(name))
end

function blacklist_tests.tests.new_force_pattern_blacklisted()
    local name = "EE_TESTFORCE_!" -- Know this should be blacklisted
    test_util.assert_nil(get_cached_force(name))
    test_util.assert_true(blacklist.force(name))
    test_util.assert_true(get_cached_force(name))
end

function blacklist_tests.tests.on_config_changed_resets_force_cache()
    local name = "vogon"

    test_util.assert_nil(get_cached_force(name))
    test_util.assert_false(blacklist.force(name))
    test_util.assert_false(get_cached_force(name))

    blacklist.on_configuration_changed()

    test_util.assert_nil(get_cached_force(name))
    test_util.assert_false(blacklist.force(name))
    test_util.assert_false(get_cached_force(name))
end

return blacklist_tests