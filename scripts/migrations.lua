-- Yes, this is basically a recreation of the vanilla mechanics. Meh

local handler = { }

local statistics = require("scripts.statistics")

local migrations = {
    ["0.1.0"] = function()
        -- When this mod is added to an existing save then existing
        -- players need to be added to the tables
        for _, player in pairs(game.players) do
            statistics.setup_player(player)
        end
    end,
    ["0.2.8"] = function()
        -- We're changing to only store if victory has been reached. Not by who
        if global.finished and type(global.finished) == "table" then
            global.finished = next(global.finished) ~= nil
        end
    end,
}

local function handle_migrations(event)
    -- A list of all migrations ran
    ---@type table<string, boolean>
    global.migrations = global.migrations or { }

    for migration_name, migration in pairs(migrations) do
        if not global.migrations[migration_name] then
            log("Running migration: '"..migration_name.."'")
            migration()
            global.migrations[migration_name] = true
        end
    end
end

handler.on_init = handle_migrations
handler.on_configuration_changed = handle_migrations

return handler