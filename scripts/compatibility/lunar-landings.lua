if not script.active_mods["LunarLandings"] then return { } end

local module = { }

---@param forces LuaForce[] to gather statistics from
function module.gather(forces)
    local players = global.statistics.players
    local stats = { by_player = { } }
    for _, force in pairs(forces) do
        for _, player in pairs(force.connected_players) do
            local player_data = players[player.index]
            if not player_data then goto continue end
            local luna_time = player_data and player_data.times_on_surfaces["luna"]
            if not luna_time then goto continue end

            stats.by_player[player.index] = {
                ["player"] = { stats = {
                    ["ll-luna-time"] = { value = luna_time, unit = "time", order = "a" }
                }}
            }

            ::continue::
        end
    end

    return stats
end

return module