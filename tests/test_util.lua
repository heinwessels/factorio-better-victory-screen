local test_util = { }

local pre = "Assertion failed: "

function test_util.assert_true(a)
    if a ~= true then error(pre.."Value is not false") end
end

function test_util.assert_false(a)
    if a ~= false then error(pre.."Value is not false") end
end

function test_util.assert_not_nil(a)
    if a == nil then error(pre.. a .." is nil") end
end

function test_util.assert_nil(a)
    if a ~= nil then error(pre.. a .." is not nil") end
end

function test_util.assert_equal(a, b)
    if a ~= b then error(pre .. a .. " ~= " .. b) end
end

function test_util.assert_string_equal(a, b)
    test_util.assert_not_nil(a)
    test_util.assert_not_nil(b)
    if type(a) ~= "string" then a = tostring(a) end
    if type(b) ~= "string" then b = tostring(b) end
    if a ~= b then error(pre .. "'" .. a .. "'" .. " ~= " .. "'" .. b .. "'") end
end

---@param entity LuaEntity?
function test_util.assert_valid_entity(entity)
    if not entity then
        error(pre .. "Entity is nil")
    elseif not entity.valid then
        error(pre .. "Entity is not valid")
    end
end

--- Assert if the function called with given arguments
--- do not error with a message that matches the pattern
---@param fn fun(...) to call
---@param args table of arguments to pass to function
---@param pattern string? to match error message to
function test_util.assert_death(fn, args, pattern)
    local no_crash, message = pcall(fn, table.unpack(args))
    if no_crash then error(pre .. "Function didn't error!") end
    if pattern then if string.match(message, pattern) == nil then
        error(pre .. "Error message '"..message.."' do not match pattern '"..pattern.."'")
    end end
end

return test_util