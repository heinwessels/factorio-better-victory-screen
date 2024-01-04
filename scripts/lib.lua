local lib = { table = { } }

---Removes all keys from a table that passes a filter
---@param t         table
---@param filter    fun(key: Any) : boolean should return true if should delete the key-value
function lib.table.remove_keys_filtered(t, filter)
    local keys_to_remove = { }
    for key, _ in pairs(t) do
        if filter(key) then table.insert(keys_to_remove, key) end
    end
    for _, key in pairs(keys_to_remove) do t[key] = nil end
end

---@param amount any
---@param append_suffix boolean?
---@param decimals uint?
---@return string
function lib.format_number(amount, append_suffix, decimals)
    local suffix = ""

    if append_suffix then
        local suffix_list = {
            ["T"] = 1000000000000,
            ["G"] = 1000000000,   -- `G` and not `B`!
            ["M"] = 1000000,
            ["k"] = 1000,
            [""] = 1  -- Otherwise below 1k formats odd. Probably hack and not actual problems
        }

        for letter, limit in pairs (suffix_list) do
            if math.abs(amount) >= limit then
                amount = math.floor(amount/(limit/10))/10
                suffix = letter
                break
            end
        end
    end

    if decimals then
        amount = tonumber(string.format("%."..decimals.."f", amount))
    end

    return amount .. " " .. suffix
end

function lib.format_power(amount)
    return lib.format_number(amount, true, 3).."W"
end

function lib.format_distance(amount)
    local suffix = ""

    if amount > 1000 then
        local suffix_list = {
            ["k"] = 1000,
            [""] = 1  -- Otherwise below 1k formats odd. Probably hack and not actual problemssa
        }

        for letter, limit in pairs (suffix_list) do
            if math.abs(amount) >= limit then
                amount = math.floor(amount/(limit/10))/10
                suffix = letter
                break
            end
        end
    end

    -- Trim some decimals
    if amount >= 1000 then
        amount = math.floor(amount)
    else
        amount = lib.format_number(amount, false, 1)
    end

    return amount .. " " .. suffix .. "m"
end

function lib.format_area(amount)

    if amount < 1000 then
        amount = lib.format_number(amount, false, 3)
    else
        amount = math.floor(amount)
    end

    return amount .. " km2"
end

---@param ticks uint
function lib.format_time(ticks)
    local seconds = ticks / 60
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    seconds = math.floor(seconds - 60 * minutes)
    minutes = math.floor(minutes - 60 * hours)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end


return lib