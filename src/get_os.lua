---@return "windows" | "linux" | "mac-os" | "unknown"
local function get_os()
    -- https://stackoverflow.com/questions/295052/how-can-i-determine-the-os-of-the-system-from-within-a-lua-script (modified)
    local binary_format = package.cpath:match("%.[\\|/]%?%.(%a+)")

    if binary_format == "dll" then
        return "windows"
    elseif binary_format == "so" then
        return "linux"
    elseif binary_format == "dylib" then
        return "mac-os"
    end
    binary_format = nil

    return "unknown"
end

return get_os
