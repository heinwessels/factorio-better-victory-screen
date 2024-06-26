local gui = require("scripts.gui")
local util = require("util")
local statistics = require("scripts.statistics")
local compatibility = require("scripts.compatibility")
local debug = require("scripts.debug")

local trigger = { }
trigger.gather_function_name = "better-victory-screen-statistics"

---A list of forces to show the victory screen to
---@return LuaForce[]
local function get_forces_to_show()
    local forces_to_show = { }
    for _, force in pairs(game.forces) do
        if #force.connected_players == 0 then goto continue end
        table.insert(forces_to_show, force)
        ::continue::
    end
    return forces_to_show
end

trigger.remote = remote
--- Gather statistics from other mods
---@param winning_force LuaForce
---@param forces LuaForce   list of forces that the GUI will be shown to
function trigger.gather_statistics(winning_force, forces)
    local gathered_statistics = { by_force = { }, by_player = { } }
    for interface, functions in pairs(trigger.remote.interfaces) do
        if functions[trigger.gather_function_name] then
            -- We don't know the quality of the other mod's code and if it will return the correct things.
            -- So we will wrap it all in a pcall. This includes remote call, as well as merging the returned
            -- stats into our stats. That way we don't really need to sanitize the data. It's also okay because
            -- downstream code is written to be robust as well and make any expectations about the data.
            local success, error_message = pcall(function()
                local mod_statistics = trigger.remote.call(interface, trigger.gather_function_name, winning_force, forces)
                gathered_statistics = util.merge{gathered_statistics, mod_statistics --[[@as table]]}
                log("Successfully gathered statistics from: " .. interface)
            end)
            debug.debug_assert(success, error_message)
        end
    end
    return gathered_statistics
end

---Show the victory screen for all connected players
---@param winning_force LuaForce
---@param winning_message string|LocalisedString ? to show instead of the default victory message
---@param losing_message string|LocalisedString ? if provided will be shown to forces that's not the winning force.
function trigger.show_victory_screen(winning_force, winning_message, losing_message)

    ---@type table<string, LuaProfiler>
    local profilers = nil
    if true then -- Keep this to false for releases
        profilers = {
            gather          = game.create_profiler(true),
            infrastructure  = game.create_profiler(true),
            peak_power      = game.create_profiler(true),
            chunk_counter   = game.create_profiler(true),
            total           = game.create_profiler(false), -- Start this profiler
        }
    end

    local forces_to_show = get_forces_to_show()

    local force_names = { }
    for _, force in pairs(forces_to_show) do table.insert(force_names, force.name) end
    log("Showing to forces: "..serpent.line(force_names))

    if profilers then profilers.gather.reset() end
    local other_statistics = trigger.gather_statistics(winning_force, forces_to_show)
    if profilers then profilers.gather.stop() end

    local compatibility_stats = compatibility.gather(forces_to_show)

    for _, force in pairs(forces_to_show) do
        local force_statistics = statistics.for_force(force, profilers)
        local compatibility_force_statistics = compatibility_stats.by_force[force.name] or { }
        local other_force_statistics = other_statistics.by_force[force.name] or { }

        -- Determine message to show
        local message   -- nil means the showing the default text
        if winning_message then
            if force == winning_force or not losing_message then
                message = winning_message
            else
                message = losing_message
            end
        end

        for _, player in pairs(force.connected_players) do

            -- Clear the cursor because it's annoying if it's still there
            player.clear_cursor()

            local compat_player_statistics = compatibility_stats.by_player[player.index] or { }
            local other_player_statistics = other_statistics.by_player[player.index] or { }

            gui.create(player, util.merge{
                -- Order is important. Later will override previous
                force_statistics,
                statistics.for_player(player, profilers),

                compatibility_force_statistics,
                compat_player_statistics,

                other_force_statistics,
                other_player_statistics,
            }, message)
        end
    end

    if profilers then
        profilers.total.stop()

        log({"",
            "Statistics collection profiling:\n",
            "\tOther mods: ", profilers.gather, "\n",
            "\tInfrastructure: ", profilers.infrastructure, "\n",
            "\tPeak Power: ", profilers.peak_power, "\n",
            "\tChunk counter: ", profilers.chunk_counter, "\n",
            "\tTOTAL: ", profilers.total, "\n",
        })
    end

    -- This will also handle the case when victory is reached in an headless server
    -- without any online players. The risk is that the game is paused accidentally.
    -- However, in MP it will never pause, and in single player there will always
    -- be a player. So it will all work nicely, not pausing accidentally.
    if not game.is_multiplayer() then
        game.tick_paused = true
    end
end

--- Trigger the game's victory condition and then
--- show our custom victory screen 
---@param winning_force LuaForce
---@param override boolean? true if victory should be triggered regardless of it being triggered before
---@param winning_message string|LocalisedString ? to show instead of the default message
---@param losing_message string|LocalisedString ? if provided will be shown to forces that's not the winning force.
function trigger.attempt_trigger_victory(winning_force, override, winning_message, losing_message)

    if not override then
        -- Do not trigger if another mod already triggered a normal victory
        -- condition. Note: This will not prevent BVS from triggering twice,
        -- because we don't set the `finished` game state, meaning these two
        -- values will never be true for a BVS triggered victory.
        if game.finished or game.finished_but_continuing then return end

        -- Check if this a force has already finished cache
        if global.finished then return end
    end

    global.finished = true

    -- Set the game state to victory without setting game_finished.
    -- This will trigger the achievements without showing the vanilla GUI.
    -- Thanks Rseding!
    game.set_game_state({ player_won = true, victorious_force = winning_force })

    -- Show our GUI
    trigger.show_victory_screen(winning_force, winning_message, losing_message)
end

-- There are some "rockets" that we will ignore for the winning condition
local rocket_name_blacklist = util.list_to_map{
    "ballistic-missile",            -- Ballistic Missile
}

---@param event EventData.on_rocket_launched
local function on_rocket_launched(event)
    if global.disable_vanilla_victory then return end

    local rocket = event.rocket
    if not (rocket and rocket.valid) then return end
    if rocket_name_blacklist[rocket.name] then return end

    trigger.attempt_trigger_victory(rocket.force --[[@as LuaForce]])
end

---Stores if BVS should trigger on the vanilla victory.
---Also resets the stored game state if it was maybe called
---erroniously previously.
---@param no_vanilla_victory boolean
local function disable_vanilla_victory(no_vanilla_victory)

    -- This is a function because there was a hacky migration here...

    global.disable_vanilla_victory = no_vanilla_victory
end

trigger.add_remote_interface = function()
	remote.add_interface("better-victory-screen", {

		--- @param no_victory boolean true to ignore vanilla victory conditions
		set_no_victory = function(no_victory)
            disable_vanilla_victory(no_victory)
		end,

        ---This remote is called by other mods when victory has been achieved.
        ---@param winning_force LuaForce
        ---@param override boolean? True if then victory GUI will be shown regardless of if it has been shown before
        ---@param winning_message string|LocalisedString ? to show instead of the default message
        ---@param losing_message string|LocalisedString ? if provided will be shown to forces that's not the winning force.
        trigger_victory = function(winning_force, override, winning_message, losing_message)

            -- We are not sanitizing the input messages, but when we display them
            -- will will wrap them in a pcall. For a reason that I can't remember why
            -- we will only allow a losing message if there is a winning message.
            if not winning_message then losing_message = nil end

            trigger.attempt_trigger_victory(winning_force, override, winning_message, losing_message)
        end
    })
end

function trigger.add_commands()

    if settings.startup["bvs-enable-show-victory-screen-command"].value or script.active_mods["debugadapter"] then
        local show_victory_help_message = [[
            Show the Victory GUI as if victory has been reached, without actually triggering the victory.
            This is mainly for development purposes, but might be interesting for some players.
            This command does not have any impact on the game.
            [Mod: Better Victory Screen]
            ]]
            ---@param command CustomCommandData
        commands.add_command("show-victory-screen", show_victory_help_message, function(command)
            if script.active_mods["debugadapter"] and command.parameter == "victory" then
                local player = game.get_player(command.player_index)
                if not player then return end       -- Should never happen.
                if not player.admin then return end -- Some kind of safety net

                -- Add additional option to trigger the actual victory, but
                -- only while the debugger is active. In normal game play it
                -- should not be possible, that would be bad.
                game.print("[Better Victory Screen] Forcing an actual victory.")
                trigger.attempt_trigger_victory(game.forces.player, true)
                return
            end

            -- Normal operation
            trigger.show_victory_screen(game.forces.player)
        end)
    end

    local reset_command_help_message = [[
        **USE WITH CAUTION!** 
        This command will reset your victory so that it's possible to be trigger again by Better Victory Screen.
        However, it cannot revert if the vanilla victory screen has been displayed. In that case you cannot trigger another victory condition.
        This action cannot be reverted, and this command can only be executed by an admin.
        [Mod: Better Victory Screen]
        ]]
        ---Reset the victory condition if something went wrong
        ---@param command CustomCommandData
    commands.add_command("reset-victory-condition", reset_command_help_message, function(command)
        local player = game.get_player(command.player_index)
        if not player then return end -- Should never happen.

        if not player.admin then
            player.print("Only admins can use this command")
            return
        end

        if not global.finished then
            player.print("A custom victory has not been reached. Nothing to do")
            return
        end

        global.finished = false -- So that a force can win again
        game.print("Victory tracked by Better Victory Screen has been reset.")

        -- We can't set the internal game state again to haven't won. But
        -- if we triggered a victory prematurely then it doesn't matter
        -- because we don't set the `finished` flag. Which means our
        -- victory-attempt will always be successful. And setting the
        -- game_state again will just show the victory screen again
        -- anyway, even triggering the vanilla victory from an unsupported mod.
    end)

    local pending_victory_help_message = [[
        This command will tell you if there is still a pending victory,
        or if victory should still be reached. It will also say if the pending victory will occur
        on the first rocket launch ("Vanilla") or a custom victory condition.
        This command doesn't have any impact on anything.
        [Mod: Better Victory Screen]
    ]]
    ---Check if a victory is still possible
    ---@param command CustomCommandData
    commands.add_command("is-victory-pending", pending_victory_help_message, function(command)
        local player = game.get_player(command.player_index)
        if not player then return end -- Should never happen.
        local pending_type = global.disable_vanilla_victory and "Custom" or "Vanilla"
        if global.finished then
            player.print("No. Better Victory Screen has already created a victory condition [Type: " .. pending_type .. "]. Use '/reset-victory-condition` to revert.")
        elseif game.finished or game.finished_but_continuing then
            player.print("No. Vanilla victory condition has already been reached without Better Victory Screen.")
        else
            player.print("Victory condition is still pending [Type: " .. pending_type .. "].")
        end
    end)
end

trigger.events = {
    [defines.events.on_rocket_launched] = on_rocket_launched,
}

---Determine if we should create soft compatibility with the current mod set.
---This means we will disable the vanilla victory condition for mods that we
---know have custom victory conditions, but are not yet fully supported. This
---means the victory screen will at least not trigger on the first rocket launch.
---This has the added benifit of this mod being safe to add to playthroughs even
---though there is no full compatibility yet. Only downside is that the vanilla
---victory screen will still be shown. When full compatibility is finally added
---by the other mod everything will continue working as it should.
local function handle_soft_compatibilities()
    local soft_compatibilities = {
        "space-exploration",
        "Krastorio2",
        "SpaceMod",
        "pycoalprocessing",
        "Satisfactorio",
    }

    for _, mod_name in pairs(soft_compatibilities) do
        if script.active_mods[mod_name] then
            disable_vanilla_victory(true)
            return -- Only need to do this once
        end
    end
end

function trigger.on_init(event)
    handle_soft_compatibilities()

    -- We always disable the vanilla victory condition because we
    -- should be the main controller victory screens. 
    if remote.interfaces["silo_script"] then
        remote.call("silo_script", "set_no_victory", true)
    end
end

function trigger.on_configuration_changed(event)

    -- We will reset this every time to account for when
    -- mods that disable the vanilla victory condition is removed.
    -- All mods that call our disable interface should have a dependency
    -- on BVS and will therefore run after this, and thus disable it again.
    global.disable_vanilla_victory = false

    -- We will always disable vanilla victory in some cases though
    handle_soft_compatibilities()
end

return trigger
