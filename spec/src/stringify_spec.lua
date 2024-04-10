
local stringify = require("src.stringify")

describe("stringify", function ()
    describe("stringifies", function ()
        it("strings", function ()
            local str = stringify("hello", 0)

            assert.equal("\"hello\"", str)
        end)

        it("numbers", function ()
            local str = stringify(1, 0)
    
            assert.equal("1", str)
        end)
    
        it("booleans", function ()
            local str = stringify(false, 0)

            assert.equal("false", str)
        end)
        
        it("tables", function ()
            local str = stringify({ "a", "b", "c" }, 1)

            assert.equal("{ [1] = \"a\", [2] = \"b\", [3] = \"c\" }", str)
        end)

        it("tables but not subtables", function ()
            local t = { { "a" } }
            
            local str = stringify(t, 1)

            assert.equal("{ [1] = {...} }", str)

            local str = stringify(t, 0)

            assert.equal("{...}", str)
        end)

        it("nil", function ()
            local str = stringify(nil, 0)

            assert.equal("nil", str)
        end)

        it("functions", function ()
            local fn = function () end

            local str = stringify(fn, 1)

            assert.has.match("^function %S+:%d+$", str)

            local str = stringify(fn, 0)

            assert.equal("function", str)
        end)
        
        -- TODO test tables that fail to __index / userdata
    end)
    
    -- TODO expand_level 2 tests
end)