
local can_expand = require("src.util.can_expand")

describe("can_expand", function ()
    describe("knows it can expand", function ()
        it("functions", function ()
            assert.True(can_expand(function () end))
        end)

        it("tables", function ()
            assert.True(can_expand({}))
        end)
    end)

    describe("knows it cannot expand", function ()
        it("numbers", function ()
            assert.False(can_expand(1))
        end)

        it("booleans", function ()
            assert.False(can_expand(false))
        end)

        it("strings", function ()
            assert.False(can_expand("Hello!"))
        end)

        it("nil", function ()
            assert.False(can_expand(nil))
        end)
    end)
end)