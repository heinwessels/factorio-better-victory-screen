# Mod Compatibility

## Handling custom victories

This mod is automatically compatible with any custom victories because it uses the [on_pre_scenario_finished](https://lua-api.factorio.com/latest/events.html#on_pre_scenario_finished) event. 

## Custom victory message

You can have change the victory message displayed above the statistics by depending on this mod and overwriting the appropriate one of following locale strings:
```
[better-victory-screen]
victory-message
victory-message-space-age
stats-message
stats-message-player
```

## Adding custom entries to the victory GUI

It's possible to add or remove any custom entries to the victory GUI. This is done by adding a remote interface to your mod that can supply the extra victory statistics. This is done by

```lua
remote.add_interface("your-mod-name-but-doesn't-matter", {
    ---@param forces LuaForce[] list of one force
    ["better-victory-screen-statistics"] = function(forces)
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
                ["breweries"]   = { value=6,    has_tooltip=true,   order="a" },
                ["asphalt"]     = { value=100,  unit="area",        order="b", localised_name = {"custom.name"} },
            }}
        },
    },

    by_player = {
        -- Will only be shown for the player `stringweasel`
        ["stringweasel"] = {

            -- This is a category
            ["gymnastics"] = { order = "b", stats = {

                -- This in an entry in that category
                ["highest-jump"]    = { value = 100000, unit="distance", localised_tooltip = {"custom.tooltip"}}
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

**Important:** As mentioned on the mod page, the player specific information is only shown if there's only one player connected at the moment of victory.

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