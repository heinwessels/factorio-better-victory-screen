local handler = require("__core__/lualib/event_handler")

local trigger = require("scripts.trigger")
local statistics = require("scripts.statistics")
local migrations = require("scripts.migrations")

trigger.statistics = statistics
migrations.statistics = statistics

handler.add_libraries({
    trigger,
    statistics,
    migrations,
})
