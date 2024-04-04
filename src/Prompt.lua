local class        = require("lib.30log")
local string_split = require("src.polyfill.string_split")
local list_reduce  = require("src.polyfill.list_reduce")
local parse_key    = require("src.parse_key")
local get_os       = require("src.get_os")
local icons        = require("src.icons")
local stringify    = require("src.stringify")

local lgi          = require("lgi")
local GLib         = lgi.require("GLib")

-- TODO probably a good idea to allow userdata with pairs/ipairs to be inspected

---@class LuaInspect.Prompt : Log.BaseFunctions
---@field expand boolean
---@field mainloop unknown
---@field identifier string
---@field fancy { os: "unix", tty: string, chars: {} }?
---@field path string[]
---@field object any
---
---@operator call:LuaInspect.Prompt
local Prompt       = class("Prompt")

-- determine if fancy terminal can be done using stty.
function Prompt:detect_can_fancy()
    local systemos = get_os()

    -- TODO does mac os support fancy xterm shit? also fancy mode should be disable-able.
    -- system is unix
    if systemos == "linux" or systemos == "mac-os" then
        local handle = io.popen("which stty", "r")

        -- system has stty
        if handle and handle:read("l") then
            local tty = self:stty("-echo", "cbreak")

            -- stty can save
            if tty then
                self.fancy = { os = "unix", tty = tty, chars = {} }

                --[[
                    Enable mouse clicking
                        - https://unix.stackexchange.com/questions/418901/how-some-applications-accept-mouse-click-in-bash-over-ssh
                        - https://stackoverflow.com/questions/5966903/how-to-get-mousemove-and-mouseclick-in-bash
                        - https://www.x.org/docs/xterm/ctlseqs.pdf
                    TODO \027[?1001h should allow highlight reporting but my terminals seem to not support it.
                ]]

                io.output():write("\027[?1000h")
                io.output():write("\027[?1006h")
                io.output():write("\027[?1015h")
            end
        end
    end
end

function Prompt:fancy_cleanup()
    if self.fancy then
        -- restore tty state
        self:stty(self.fancy.tty)

        io.output():write("\027[?1000l")
        io.output():write("\027[?1006l")
        io.output():write("\027[?1015l")

        -- TODO fixme only print this if clean exit
        print()

        self.fancy = nil
    end
end

-- http://lua-users.org/lists/lua-l/2012-09/msg00360.html
---@param ... string
---@return string|nil
function Prompt:stty(...)
    local ok, p = pcall(io.popen, "stty -g")

    if not ok or not p then return nil end

    local state = p:read()
    p:close()

    if state and #... then
        os.execute(table.concat({ "stty", ... }, " "))
    end

    return state
end

function Prompt:init(obj)
    self.expand = false

    self.identifier = "unknown"
    if debug and debug.getlocal then
        local index = 1

        repeat
            local name, value = debug.getlocal(4, index)

            if value == obj then
                self.identifier = name

                break
            end

            index = index + 1
        until name == nil
    end

    self.mainloop = GLib.MainLoop()

    -- TODO FIXME fancy mode is disabled for now as stringify needs work.
    -- self:detect_can_fancy()

    GLib.idle_add(GLib.PRIORITY_DEFAULT, function()
        local ok = xpcall(function()
            self:wait()
        end, function(err)
            self:fancy_cleanup()

            local trace = debug.traceback(err)
            print(trace)

            self:command_exit()
        end)

        return ok
    end)

    self.path = {}

    self.object = obj
end

function Prompt:recurse_path()
    return list_reduce(self.path, function(object, key)
        return object[key]
    end, self.object)
end

-- TODO include top bar in something similar to clear - every 'page' should have this top bar.

function Prompt:print()
    self:clear()

    -- Top bar
    if self.fancy then
        io.output():write(icons.ARROW_UP, " ")
    end
    print(string.format("[%s] %s", self.identifier, table.concat(self.path, ".")))

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
    self.mainloop:quit()

    self:fancy_cleanup()
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
        elseif subcommand == "help" then
            self:warn_user("Show this page")
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

--- Detect mouse releases based on the 3 DIFFERENT formats terminals might return.
--- XTerm interrupts are terrible.
--- TODO what happens when scroll
function Prompt:fancy_detect_mouse_release()
    local input = table.concat(self.fancy.chars)

    -- TODO perhaps match "exit\n" ?

    local pattern_1000 = "\027%[M#(.)(.)$"
    if input:match(pattern_1000) then
        local x_str, y_str = input:match(pattern_1000)

        local x_off, y_off = string.byte(x_str), string.byte(y_str)
        local x, y = x_off - 32, y_off - 32

        self.fancy.chars = {}

        return x, y
    end

    local pattern_1000_1006 = "\027%[<0;(%d+);(%d+)m"
    if input:match(pattern_1000_1006) then
        local x_str, y_str = input:match(pattern_1000_1006)
        local x, y = tonumber(x_str), tonumber(y_str)

        self.fancy.chars = {}

        return x, y
    end

    local pattern_1000_1015 = "\027%[35;(%d+);(%d+)M"
    if input:match(pattern_1000_1015) then
        local x_str, y_str = input:match(pattern_1000_1015)
        local x, y = tonumber(x_str), tonumber(y_str)

        self.fancy.chars = {}

        return x, y
    end

    return nil, nil
end

function Prompt:fancy_handle_click()
    local x, y = self:fancy_detect_mouse_release()

    if not x or not y then
        return
    end

    if x == 1 and y == 2 then
        self:command_expand()
    end

    if x == 1 and y == 1 then
        self:command_up()
    end

    -- self:warn_user(tostring(x) .. " " .. tostring(y))
    -- TODO let table keys register their positions somehow - both in flat and expanded mode.

    self:prompt()
end

function Prompt:wait()
    if self.fancy then
        local char = io.input():read(1)

        -- local keycode = string.byte(char)
        -- print(char, keycode)


        table.insert(self.fancy.chars, char)

        self:fancy_handle_click()
    else
        self:prompt()

        local cmd = io.input():read("l")

        self:command(cmd)
    end
end

function Prompt:start()
    self:prompt()

    self.mainloop:run()
end

return Prompt
