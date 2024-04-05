
--- Parse a key for a table as a number
---@param key string
---@param obj any
---@return number?
local function parse_key_as_number (key, obj)
    if not key:match("^%d*%.?%d+$") then
        return nil
    end

    return tonumber(key)
end

--- Parse a key for a table as a boolean
---@param key string
---@param obj any
---@return boolean?
local function parse_key_as_boolean (key, obj)
    if key == "true" or key == "false" then
        return key == "true"
    end
end

--- Parse a key for a table as an address
---@param key string
---@param obj any
---@return table | userdata | thread | function | nil
local function parse_key_as_addr (key, obj)
    -- TODO match correct alphanumerics for hex
    if not key:match("^0x") then
        return nil
    end

    local addresses = {}

    for k, _ in pairs(obj) do
        local k_str = tostring(k)
        local address = k_str:match("^%S+ (0x%S+)$")

        if address then            
            addresses[address] = k
        end
    end

    if addresses[key] then
        return addresses[key]
    end
end

---@param key string
---@return string
local function parse_key_as_string (key, obj)
    -- remove one set of quotes, so "a" -> a. however, ""a"" SHOULD become "a"
    -- todo test above behaviour.
    local sub = key:gsub("^\"(.*)\"$", "%1")

    return sub
end

---@param key string
---@param obj any
---@return any
local function parse_key(key, obj)
    local bool = parse_key_as_boolean(key, obj)

    if bool ~= nil then
        return bool
    end

    local number = parse_key_as_number(key, obj)

    if number ~= nil then
        return number
    end

    local addr = parse_key_as_addr(key, obj)

    if addr ~= nil then
        return addr
    end

    return parse_key_as_string(key, obj)
end

return parse_key