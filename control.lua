---@diagnostic disable: different-requires
local handler = require("__core__/lualib/event_handler")
handler.add_libraries({
    require("scripts.blacklist"),
    require("scripts.trigger"),
    require("scripts.statistics"),
    require("scripts.tracker"),
    require("scripts.migrations"),  -- This should happen _after_ other things
})

if script.active_mods["debugadapter"] then
    handler.add_lib(require("tests.tests"))
end