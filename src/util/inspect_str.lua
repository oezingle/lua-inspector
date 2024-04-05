local can_expand          = require("src.util.can_expand")
local stringify_flat      = require("src.util.stringify_flat")
local icons               = require("src.util.icons")
local stringify           = require("src.util.stringify")

---@param obj any
---@param expanded boolean
---@return string
local function inspect_str(obj, expanded)
    if can_expand(obj) then
        return string.format("%s %s %s",
            expanded and icons.ARROW_OPEN or icons.ARROW_CLOSED,
            type(obj),
            stringify(obj, expanded and 2 or 1))
    else
        return type(obj) .. " " .. stringify_flat(obj, false)
    end
end

return inspect_str