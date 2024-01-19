local lib = require("scripts.lib")
local debug = require("scripts.debug")

local formatter = { }

---@param ticks uint
---@return string
function formatter.format_time(ticks)
    ticks = math.abs(ticks) -- Negative doesn't make sense
    local seconds = ticks / 60 -- number is in ticks
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    seconds = math.floor(seconds - 60 * minutes)
    minutes = math.floor(minutes - 60 * hours)
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

---@type table<string, string>
local suffixes = {
    ["-18"]  = "a",
    ["-15"]  = "f",
    ["-12"]  = "p",
    ["-9"]  = "n",
    ["-6"]  = "u",
    ["-3"]  = "m",
    ["3"]   = "k",
    ["6"]   = "M",
    ["9"]   = "G",
    ["12"]  = "T",
    ["15"]  = "P",
    ["18"]  = "E",
}

---Finds the suffix divider for a given number
---For example, 1234 to 1.2k
---@param number number
---@return number
---@return string?
local function get_suffix(number)
    local magnitude = lib.math.magnitude(number)
    local divider = lib.math.sign(magnitude) * math.floor(math.abs(magnitude) / 3) * 3
    local suffix = suffixes[tostring(divider)]
    if suffix then number = number / math.pow(10, divider) end
    return number, suffix
end
if debug.debugger_active then formatter.get_suffix = get_suffix end -- For tests

---Combine a number into a string
---@param number number
---@param suffix string?
---@param unit string?
---@return string
local function combine(number, suffix, unit)
    if not (suffix or unit) then
        return tostring(number)
    elseif suffix and unit then
        return number .. " " .. suffix .. unit
    else
        return number .. " " .. (suffix or unit)
    end
end

---Different formatters to use for different units
---@type table<string, fun(number:number):string>
local formatters = {
    ["number"] = function(number)
        if not lib.math.has_decimals(number)
            and number <= 9999 then
            -- We're okay with four digits if there is no suffix or decimals
            return combine(number)
        end

        number, suffix = get_suffix(number)
        return combine(lib.math.round(number, 2), suffix)
    end,
    ["power"] = function(number)
        number = math.abs(number) -- Negative doesn't make sense
        number, suffix = get_suffix(number)
        return combine(lib.math.round(number, 3), suffix, "W")
    end,
    ["distance"] = function(number)
        number = math.abs(number) -- Negative doesn't make sense
        if number <= 9999 then
            return lib.math.round(number, 0) .. " m"
        end
        return lib.math.round(number /  1000, 2) .. " km"
    end,
    ["area"] = function(number)
        number = math.abs(number) -- Negative doesn't make sense
        if number < 10 then
            number = lib.math.round(number, 3)
        elseif number < 1000 then
            number = lib.math.round(number, 2)
        else
            number = lib.math.round(number)
        end
        return number .. " km2"
    end,
    ["time"] = formatter.format_time,
    ["percentage"] = function(number)
        number = number * 100

        if math.abs(number) < 10 then
            number = lib.math.round(number, 3)
        elseif math.abs(number) > 100 then
            number = lib.math.round(number, 1)
        else
            number = lib.math.round(number, 2)
        end

        return number .. " %"
    end,
}

---Format a number
---@param number integer|float
---@param unit string Defaults to "number"
---@return string
function formatter.format(number, unit)
    if not unit then unit = "number" end
    local fn = formatters[unit]
    debug.debug_assert(fn ~= nil, "Unsupported unit '"..unit.."'!")
    if not fn then fn = formatters["number"] end
    return fn(number)
end

local tooltip_units = {
    ["distance"] = "m",
    ["area"] = "km2",
    ["power"] = "W",
    ["percentage"] = "%",
}

---Format a number to use as a tooltip
---@param number integer|float
---@param unit string Defaults to "number"
---@return string
function formatter.format_tooltip(number, unit)
    if unit == "time" then return "" end
    local unit_str = tooltip_units[unit]
    local decimals = (unit ~= "area") and 2 or 3
    number = lib.math.round(number, decimals)
    return number .. ( unit_str and (" "..unit_str) or "")
end

return formatter