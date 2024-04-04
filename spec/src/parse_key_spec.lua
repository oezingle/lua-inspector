
local parse_key = require("src.parse_key")

describe("parse_key", function ()
    it("parses booleans", function ()
        assert.equal(true, parse_key("true", {}))
        assert.equal(false, parse_key("false", {}))
    end)

    it("parses numbers", function ()
        assert.equal(1, parse_key("1", {}))
        assert.equal(0.1, parse_key("0.1", {}))
    end)

    it("parses addresses", function ()
        local t = {}
        
        local obj = { [t] = "Hello World!" }

        local addr = tostring(t):match("0x%S+")

        assert.equal(t, parse_key(addr, obj))
    end)

    it("parses strings", function ()
        assert.equal("Hello World", parse_key("Hello World", {}))
        assert.equal("Hello World", parse_key("\"Hello World\"", {}))
        assert.equal("\"Hello World\"", parse_key("\"\"Hello World\"\"", {}))
    end)
end)