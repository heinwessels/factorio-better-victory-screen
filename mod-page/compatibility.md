# Mod Compatibility

## When is specific compatibility required?

- If your mod has a custom victory condition then extra plumping is required to instead trigger this mod.
- If you want to show (or hide) extra statistics in the victory GUI.

## Supporting custom victory conditions 

Your mod has a custom victory condition if at `on_init` you call `remote.call("silo_script", "set_no_victory", true)` and when you decide the player is victorious you trigger the victory by calling `game.set_game_state(...)`.

To support Better Victory Screen you will also have to notify this mod to `set_no_victory`. And then when you deem the player victorious call a remote call in this mod, instead of setting the game state.

### Disabling the vanilla victory condition 

Normally this is done during `on_init`, but in order to support existing save games we will have to do it during `on_configuration_changed` as well. 

```lua
local function better_victory_screen_support() do
  for interface, functions in pairs(remote.interfaces) do
    if (functions["set_no_victory"] ~= nil) then
      remote.call(interface, "set_no_victory", true)
    end
  end
end

script.on_init(function()
    better_victory_screen_support()
end)

script.on_configuration_changed(function()
    better_victory_screen_support()
end)
```

### Triggering the Better Victory Screen

When you deem the player to be victorious you will have to to replace the regular `game.set_game_state(...)` call with:

```lua
    if remote.interfaces["better-victory-screen"] and remote.interfaces["better-victory-screen"]["trigger_victory"] then
      remote.call("better-victory-screen", "trigger_victory", force)
    else
      game.set_game_state{
        game_finished=true, 
        player_won=true,
	    can_continue=true, 
        victorious_force=force}
    end
```

## Adding custom entries to the victory GUI

It's possible to add or remove any custom entries to the victory GUI. This is done by adding a remote interface to your mod that can supply the extra victory statistics. This is done by

```lua
remote.add_interface("your-mod-name-but-doesn't-matter", {
    ---@param winning_force LuaForce
    ["better-victory-screen-statistics"] = function(winning_force)
        return table_containing_custom_statistics -- Will explain this now
    end
})
```

This `table_containing_custom_statistics`-table contains information about the stats that should be displayed. Stats can either be by `player` or by `force`. The GUI will have multiple categories, where each category can have multiple entries.

```lua
table_containing_custom_statistics = {
    by_force = {
        -- Will be shown for all players in the `player` force
        ["player"] = {

            -- This is a category
            ["industry"] = { order = "a", stats = {

                -- These are all the entries in that category
                ["breweries"]   = { value = 6,                      order="a" },
                ["asphalt"]     = { value = 100,    unit="area",    order="b" },
            }}
        },
    },

    by_player = {
        -- Will only be shown for the player `stringweasel`
        ["stringweasel"] = {

            -- This is a category
            ["gymnastics"] = { order = "b", stats = {

                -- This in an entry in that category
                ["highest-jump"]    = { value = 100000, unit="distance"}
            }}
        },

        -- Will only be shown for the player `otherweasel`
        ["otherweasel"] = {

            -- This is a category
            ["gymnastics"] = { order = "b", stats = {

                -- This in an entry in that category
                ["highest-jump"]    = { value = 1, unit="distance"}
            }}
        },
    },
}
```

There is a bit of information here, which is:
- `value` (_required_): The raw value to be shown. Might be formatted when shown.
- `unit` (_optional_): If this number is a unit. Supports:
    - `number` just a raw number.
    - `distance` in m.
    - `area` in km2
    - `time` in ticks
    - `power` in Watt
    - `percentage` as a value between 0 and 1.
- `order` (_optional_): Order the categories/statistics. Defaults to `m`

This localization for this is done using normal localization where the key-name is the the localization key. For the snippet above the `locale/en/en.cfg` might look like:

```
[bvs-categories]
industry=Industry
gymnastics=Gymnastics

[bvs-stats]
breweries=Breweries Built
asphalt=Asphalt Roads
highest-jump=Highest Jump
```

You can also add an optional tooltip that will be shown be hovering over the statistic's name as follows:
```
[bvs-stat-tooltip]
highest-jump=The highest the player could jump during gymnastics class.
```

## Hiding existing categories or statistics

It's possible to hide some stats created by this mod itself (or other mods) by adding an ignore flag to some category or statistic. For example if your overhaul does not have biters then you could hide some inappropriate stats like this:

```lua
table_containing_custom_statistics = {
    by_force = {
        -- Will be shown for all players in the `player` force
        ["player"] = {
            ["miscellaneous"] = {stats={["total-enemy-kills"] = {ignore=true}}},
            -- This works because all tables (force and player) are merged before displaying 
            ["player"]        = {stats={["kills"]             = {ignore=true}}},
        },
    },
}
```