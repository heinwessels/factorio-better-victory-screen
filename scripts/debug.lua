local lib = { }

lib.debugger_active = script.active_mods["debugadapter"] ~= nil

---A assertion that will only be asserted while the debugger is active
---If the debugger isn't active it will only log the error as a warning 
---@param condition any
---@param message any
function lib.debug_assert(condition, message)
    if condition then return end
    if not lib.debugger_active or global.__testing_release then
        log("Warning: "..serpent.block(message))
    else
        error(message)
    end
end

---log something only when in debug mode
---@param message string
function lib.debug_log(message)
    if not lib.debugger_active then return end
    log(message)
end

return lib