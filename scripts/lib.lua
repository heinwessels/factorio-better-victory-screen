local lib = { table = { }, math = { } }

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

---Return the keys ordered to the order value
---@param t table
---@return any[]
function lib.table.ordered_keys(t)
    local sorted_keys = { }
    for key, _ in pairs(t) do table.insert(sorted_keys, key) end
    table.sort(sorted_keys, function(a, b)
        local a_order = t[a].order or "m"
        local b_order = t[b].order or "m"
        return a_order < b_order
    end)
    return sorted_keys
end

---@param array any[]
---@param query any
---@return boolean
function lib.table.in_array(array, query)
    for _, element in pairs(array) do
        if element == query then return true end
    end
    return false
end

---@param number number
---@return number
function lib.math.sign(number)
    return number > 0 and 1 or (number == 0 and 0 or -1)
end

---The magnitude of a number, f.i. 100 -> 2
---@param number number
---@return number
function lib.math.magnitude(number)
    return math.floor(math.log(math.abs(number), 10))
end

---@param number number
---@param decimals integer? defaults to 0
---@return number
function lib.math.round(number, decimals)
    if not decimals then decimals = 0 end
    rounded_number = tonumber(string.format("%."..decimals.."f", number))
    if not rounded_number then error("Can't round '"..number .."'") end
    return rounded_number
end

---@param number number
---@return boolean 
function lib.math.has_decimals(number)
    return math.floor(number) ~= number
end


return lib