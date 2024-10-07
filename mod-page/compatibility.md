# Mod Compatibility

## When is specific compatibility required?

- If your mod has a custom victory condition then extra plumping is required to instead trigger this mod.
- If you want to show (or hide) extra statistics in the victory GUI.

## Supporting custom victory conditions 

Your mod has a custom victory condition if at `on_init` you call `remote.call("silo_script", "set_no_victory", true)` and when you decide the player is victorious you trigger the victory by calling `game.set_game_state(...)`.

To support Better Victory Screen you will also have to notify this mod to `set_no_victory`. And then when you deem the player victorious call a remote call in this mod, instead of setting the game state.

### Depend on Better Victory Screen

First you need to add a [dependency](https://wiki.factorio.com/Tutorial:Mod_structure#dependencies) to Better Victory Screen.

### Disabling the vanilla victory condition 

Normally this is done during `on_init`, but in order to support existing save games we will have to do it during `on_configuration_changed` as well. 

```lua
local function better_victory_screen_support() do
  for _, interface in pairs{"silo_script", "better-victory-screen"} do
    if remote.interfaces[interface] and remote.interfaces[interface]["set_no_victory"] then
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

If the `remote.call` is has some additional parameters to better suit your needs. Here is the function header for some more information:
```lua
---This remote is called by other mods when victory has been achieved.
---@param winning_force LuaForce
---@param override boolean? True if then victory GUI will be shown regardless of if it has been shown before
---@param winning_message string|LocalisedString ? to show instead of the default message
---@param losing_message string|LocalisedString ? if provided will be shown to forces that's not the winning force.
```

**IMPORTANT:** Triggering a victory through this remote interface does not set `game.finished` or `game.finished_but_continuing`, which is what allows showing a custom GUI. This might confuse some of your mod's logic, even though BVS keeps track internally of victories and won't show the victory screen twice. The recommended way to circumvent this is:

```lua
-- In the function where the victory is triggered, where you (likely) first check
-- if it hasn't been reached already

if game.finished or game.finished_but_continuing or storage.finished then return end
storage.finished = true
```

Only real effect of not adding this code, except for possibly confusing your mod logic, is that if Better Victory Screen is removed _after_ victory is reached, then your mod might trigger it again.

## Adding custom entries to the victory GUI

It's possible to add or remove any custom entries to the victory GUI. This is done by adding a remote interface to your mod that can supply the extra victory statistics. This is done by

```lua
remote.add_interface("your-mod-name-but-doesn't-matter", {
    ---@param winning_force LuaForce
    ---@param forces LuaForce[] list of forces that GUI will be show to
    ["better-victory-screen-statistics"] = function(winning_force, forces)
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

You can also add an optional tooltip that will be shown be hovering over the statistic's name as follows. This will only be shown if the entry has `has_tooltip=true`. You can instead pass your own localised string to be shown as tooltip: `localised_tooltip = {"custom.tooltip}`
```
[bvs-stat-tooltip]
breweries=Historic breweries in your area.
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