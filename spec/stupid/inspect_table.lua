
local inspect = require("inspect")

local function main ()
    local table = {
        "a",
        "b",
        {
            a = true, 
            b = false,
            c = function ()
                print("im a function!")
            end
        }
    }
    
    inspect(table)
end

main()