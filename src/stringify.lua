---@param obj any
---@param expand_level 2 | 1 | 0
---@return string
local function stringify_safe(obj, expand_level) 
    return ""
end

---@param obj any
---@param expand_level 2 | 1 | 0
local function stringify(obj, expand_level)
    local t = type(obj)

    if t == "string" or t == "number" or t == "boolean" then
        return string.format("%q", obj)
    elseif t == "table" or t == "userdata" then
        if expand_level >= 1 then
            local kvpairs = {}

            local iter = getmetatable(obj).__pairs or getmetatable(obj).__ipairs or pairs

            for k, v in iter(obj) do
                local k_str = string.format("[%q]", k)
                local v_str = stringify_safe(v, expand_level - 1)

                table.insert(kvpairs, k_str .. " = " .. v_str)
            end

            if expand_level == 2 then
                return string.format("{\n    %s\n}", table.concat(kvpairs, ",\n    "))
            else
                return string.format("{ %s }", table.concat(kvpairs, ", "))
            end
        else
            return "{...}"
        end
    elseif t == "function" then
        if expand_level == 2 then
            local info = debug.getinfo(obj, "S")

            local src_file = io.open(info.short_src)

            if not src_file then
                return string.format(
                    "function %s:%d\nUnable to expand - cannot open source file",
                    info.short_src, info.linedefined
                )
            end

            local lines = {}
            local line_index = 1
            for line in src_file:lines("l") do
                if line_index >= info.linedefined and line_index <= info.lastlinedefined then
                    table.insert(lines, line)
                end

                line_index = line_index + 1
            end

            return "\n" .. table.concat(lines, "\n")
        elseif expand_level == 1 then
            local info = debug.getinfo(obj, "S")

            return string.format("function %s:%d", info.short_src, info.linedefined)
        else
            return "function"
        end
    end

    return t
end

---@param obj any
---@param expand_level 2 | 1 | 0
---@return string
stringify_safe = function(obj, expand_level)
    local _, str = xpcall(function()
        return stringify(obj, expand_level)
    end, function()
        return "<Unable to stringify (error)>"
    end)

    return str
end

return stringify_safe
