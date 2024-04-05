
local inspect_str = require("src.util.inspect_str")
local icons       = require("src.util.icons")

describe("inspect_str", function ()
    it("doesn't show arrows for values that cannot be expanded", function ()
        local str = inspect_str(1, false)

        assert.equal("number 1", str)
    end)

    it("lets tables be expanded", function ()
        local str = inspect_str({ "a" }, false)

        assert.equal(icons.ARROW_CLOSED .. " table { [1] = \"a\" }", str)
    end)

    it("expands tables", function ()
        local str = inspect_str({ "a" }, true)

        -- TODO FIXME finish tests
        -- print(str)
    end)
end)