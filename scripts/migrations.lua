-- Yes, this is basically a recreation of the vanilla mechanics. Meh

local handler = { }

local migrations = {
    ["0.1.0"] = function()
        -- When this mod is added to an existing save then existing
        -- players need to be added to the tables
        for _, player in pairs(game.players) do
            handler.statistics.setup_player(player)
        end
    end,
}

local function handle_migrations(event)
    -- A list of all migrations ran
    ---@type table<string, boolean>
    global.migrations = global.migrations or { }

    for migration_name, migration in pairs(migrations) do
        if not global.migrations[migration_name] then
            migration()
            global.migrations[migration_name] = true
        end
    end
end

handler.on_init = handle_migrations
handler.on_configuration_changed = handle_migrations

return handler