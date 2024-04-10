local class          = require("lib.30log")
local string_split   = require("src.polyfill.string_split")
local list_reduce    = require("src.polyfill.list_reduce")
local parse_key      = require("src.parse_key")
local icons          = require("src.icons")
local stringify      = require("src.stringify")

-- TODO probably a good idea to allow userdata with pairs/ipairs to be inspected

---@class LuaInspect.Prompt : Log.BaseFunctions
---@field expand boolean
---@field stopped boolean
---@field identifier string
---@field path string[]
---@field object any
---
---@operator call:LuaInspect.Prompt
local Prompt         = class("Prompt")

local PATH_METATABLE = {} -- don't have to worry about matching strings.

function Prompt:init(obj)
    self.expand = false

    self.identifier = "unknown"
    if debug and debug.getlocal then
        local index = 1

        repeat
            -- TODO level 4 only works for loca locals scoped by caller.
            -- TODO Maybe try up to level 16?
            local name, value = debug.getlocal(4, index)

            if value == obj then
                self.identifier = name

                break
            end

            index = index + 1
        until name == nil
    end

    self.path = {}

    self.object = obj
end

function Prompt:recurse_path()
    return list_reduce(self.path, function(object, key)
        if key == PATH_METATABLE then
            return getmetatable(object)
        else
            return object[key]
        end
    end, self.object)
end

-- TODO include top bar in something similar to clear - every 'page' should have this top bar.

function Prompt:print()
    self:clear()

    -- Top bar
    local path = {}
    for _, path_elem in ipairs(self.path) do
        if path_elem == PATH_METATABLE then
            table.insert(path, "__mt")
        else
            table.insert(path, path_elem)
        end
    end

    print(string.format("[%s] %s", self.identifier, table.concat(path, ".")))

    local obj = self:recurse_path()
    local obj_str = stringify(obj, self.expand and 2 or 1)

    print(string.format(
        "%s %s %s",
        self.expand and icons.ARROW_OPEN or icons.ARROW_CLOSED,
        type(obj),
        obj_str
    ))
end

function Prompt:clear()
    io.output():write("\027[2J\027[0;0H")
end

--- Warn the user of something, waiting until they press enter.
function Prompt:warn_user(msg)
    self:clear()

    print(msg)
    print()

    io.output():write("Press enter to continue. ")

    local _ = io.input():read("l")
end

function Prompt:command_expand()
    self.expand = not self.expand
end

function Prompt:command_exit()
    self.stopped = true
end

--- Add metatable to the path
function Prompt:command_mt()
    table.insert(self.path, PATH_METATABLE)
end

--- Move down the path given the key to a child
function Prompt:command_down(child)
    local current_object = self:recurse_path()

    if not child then
        self:warn_user("down: must provide a key to traverse")

        return
    end

    local key = parse_key(child, current_object)

    if current_object[key] == nil then
        local keys = {}

        for k, _ in pairs(current_object) do
            table.insert(keys, string.format("%q", k))
        end

        local fmt = string.format(
            "Object doesn't have key %q.\n\nValid keys:\n\t%s",
            key,
            table.concat(keys, " ")
        )

        self:warn_user(fmt)
    else
        table.insert(self.path, key)
    end
end

function Prompt:command_up()
    if #self.path == 0 then
        self:warn_user("Cannot move further up - this is the root.")
    else
        table.remove(self.path, #self.path)
    end
end

---@param subcommand string?
function Prompt:command_help(subcommand)
    if subcommand == nil then
        self:warn_user(table.concat({
            "LuaInspect help page. Valid commands:",
            "exit\t\texit the inspector",
            "expand\ttoggle expanded (multiline) view",
            "up\t\tmove explore path up",
            "down <key>\tmove explore path down by key",
            "mt\t\tView this table's metatable",
            "help [cmd]\tthis page and help for commands"
        }, "\n\t- "))
    else
        if subcommand == "exit" then
            self:warn_user("exit\n\nExit the inspector")
        elseif subcommand == "expand" then
            self:warn_user("expand\n\nToggle expanded (multiline) view")
        elseif subcommand == "up" then
            self:warn_user("up\n\nMove explore path up")
        elseif subcommand == "down" then
            -- TODO FIXME expand
            self:warn_user(table.concat({
                "down <key>",
                "",
                "Move explore path down by a key. The key is interpreted given the keys in the current table.",
                "",
                "Valid key formats:",
                "\tnumeric - any decimal or integer number",
                "\tboolean - true or false",
                "\taddress - hexidecimal address of a function, table, thread, or userdata key, preceded by 0x",
                "\tstring - any value not recognized by the previous matchers. Quoted values will always be matched as strings, double quoted values will be matched as strings surrounded by quotes."
            }, "\n"))
        elseif subcommand == "mt" then
            self:warn_user("mt\n\nMove the explore path to this object's metatable")
        elseif subcommand == "help" then
            self:warn_user("help\n\nShow this page")
        else
            self:warn_user(string.format("Unknown command \"%s\"", subcommand))
        end
    end
end

---@param command string
function Prompt:command(command)
    -- remove wrapping whitespace
    command = command:gsub("^%s*(%S+)%s*$", "%1")

    local args = string_split(command)

    -- TODO logic to do with how many args each command expects?

    if args[1] == "exit" then
        self:command_exit()
    elseif args[1] == "expand" then
        self:command_expand()
    elseif args[1] == "down" then
        self:command_down(args[2])
    elseif args[1] == "mt" then
        self:command_mt()
    elseif args[1] == "up" then
        self:command_up()
    elseif args[1] == "help" then
        self:command_help(args[2])
    else
        self:warn_user(string.format("Unknown command \"%s\"", args[1]))
    end
end

function Prompt:prompt()
    self:print()

    io.output():write("inspect: ")
end

function Prompt:wait()
    self:prompt()

    local cmd = io.input():read("l")

    self:command(cmd)
end

function Prompt:start()
    self.stopped = false

    repeat
        local ok = xpcall(function()
            self:wait()
        end, function(err)
            local trace = debug.traceback(err)
            print(trace)

            self:command_exit()
        end)
    until not ok or self.stopped
end

return Prompt
