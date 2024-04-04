---@alias LuaInspect.Stringify.Registrar fun (x: integer, y: integer, length: integer, event: { type: "key", key: string } | { type: "expand" })

---@param obj any
---@param expand_level 2 | 1 | 0
---@param register_click LuaInspect.Stringify.Registrar ?
local function stringify(obj, expand_level, register_click)
    local t = type(obj)

    ---@type LuaInspect.Stringify.Registrar
    local register_click = register_click or function(x, y, length, event)

    end

    if t == "string" or t == "number" or t == "boolean" then
        return string.format("%q", obj)
    elseif t == "table" then
        if expand_level >= 1 then
            local kvpairs = {}

            for k, v in pairs(obj) do
                local k_str = string.format("[%q]", k)
                -- TODO needs to pass in a modified register_click here - clicks need to be offset by v_str's position.
                local v_str = stringify(v, expand_level - 1, register_click)

                -- TODO register click events

                table.insert(kvpairs, k_str .. " = " .. v_str)
            end

            if expand_level == 2 then
                return string.format("{\n    %s\n}", table.concat(kvpairs, ",\n    "))
            else
                return string.format("{ %s }", table.concat(kvpairs, ", "))
            end
        else
            register_click(1, 1, 5, { type = "expand" })

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

return stringify
