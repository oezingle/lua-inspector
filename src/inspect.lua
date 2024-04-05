local Prompt = require "src.Prompt"

---@param obj any
local function inspect (obj)
    local prompt = Prompt(obj)

    prompt:start()
end

return inspect