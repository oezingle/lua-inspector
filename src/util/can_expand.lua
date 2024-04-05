
local can_expand_functions = debug and debug.getinfo

---@param obj any
---@return boolean
local function can_expand (obj)
    local t = type(obj)

    return t == "table" or (can_expand_functions and t == "function")
end

return can_expand