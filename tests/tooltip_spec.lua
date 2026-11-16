-- The line under a bag's tooltip: how many slots it gains over the bag it would replace.

---The texts of the lines a hover added.
local function texts(lines)
    local out = {}
    for i, line in ipairs(lines) do
        out[i] = line[1]
    end
    return out
end

describe("the tooltip line", function()
    it("says how many slots a bag gains over the smallest bag carried", function()
        local c = NewClient():login()
        assert.are.same({ "+8 slots over your smallest bag" }, texts(c:hoverItem(ITEMS.satchel)))
        c:equipBag(1, ITEMS.heavy):equipBag(2, ITEMS.heavy):equipBag(3, ITEMS.heavy):equipBag(4, ITEMS.heavy)
        assert.are.same({ "+2 slots over your smallest bag" }, texts(c:hoverItem(ITEMS.huge)))
    end)

    it("says when a bag is no bigger, in grey", function()
        local c = NewClient()
        for bag = 1, 4 do
            c.bags[bag] = { item = ITEMS.heavy, slots = 10 }
        end
        c:login()
        local lines = c:hoverItem(ITEMS.satchel)
        assert.are.same({ "Not a bigger bag" }, texts(lines))
        assert.are.same({ 0.6, 0.6, 0.6 }, { lines[1][2], lines[1][3], lines[1][4] })
    end)

    it("compares reagent bags with the reagent slot's bag, quivers with the quiver", function()
        local c = NewClient()
        c.classID = 3
        c.bags[1] = { item = ITEMS.quiver, slots = 6 }
        c:login()
        assert.are.same({ "+12 slots over your reagent bag" }, texts(c:hoverItem(ITEMS.herb)))
        assert.are.same({ "+4 slots over your quiver" }, texts(c:hoverItem(ITEMS.medium)))
    end)

    it("names the soul bag for a warlock", function()
        local c = NewClient()
        c.classID = 9
        c:login()
        assert.are.same({ "+20 slots over your soul bag" }, texts(c:hoverItem(ITEMS.soulPouch)))
    end)

    it("says nothing under other items, a quiver for a warrior, or a hidden item", function()
        local c = NewClient():login()
        assert.are.same({}, c:hoverItem(ITEMS.shard))
        assert.are.same({}, c:hoverItem(ITEMS.medium))
        assert.are.same({}, c:hoverItem(SECRET))
        assert.are.same({}, c:hoverItem(nil))
    end)

    it("can be switched off", function()
        local c = NewClient():login()
        c.Addon.db.profile.tooltip = false
        assert.are.same({}, c:hoverItem(ITEMS.satchel))
    end)

    it("needs a client with TooltipDataProcessor", function()
        local c = NewClient({ noTooltipData = true }):login()
        assert.are.same({}, c.errors)
        assert.are.same({}, c:hoverItem(ITEMS.satchel))
    end)
end)
