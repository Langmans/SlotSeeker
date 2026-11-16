-- Screenshots for development (Core\Dev.lua): only in a copy straight from the repository, never
-- in a release (the packager comments it out), off until switched on. The first time each kind of
-- moment from the in-game checks happens, a grey chat line says which, then one screenshot.

---A development copy, logged in, with the screenshots switched on.
---@return table
local function shooting()
    local c = NewClient({ dev = true }):login()
    local dev = c.Addon:DevOptions().args
    assert.is_false(dev.on.get(), "off until switched on")
    dev.on.set(nil, true)
    return c
end

describe("development screenshots", function()
    it("take one of the window the first time it shows, after saying which", function()
        local c = shooting()
        c:slash("")
        assert.is_true(c:printedContains("|cff888888[SlotSeeker dev] window|r"))
        assert.are.equal(0, c.screenshots, "not before the window is drawn")
        c:advance(0.5)
        assert.are.equal(1, c.screenshots)
    end)

    it("take each kind once, kept across sessions, until forgotten", function()
        local c = shooting()
        c:slash(""):advance(3):slash(""):advance(3):slash(""):advance(3)
        assert.are.equal(1, c.screenshots, "the same window again")
        assert.is_true(c.Addon.db.global.dev.shots["window"])
        c.Addon:DevOptions().args.forget.func()
        c:slash(""):slash(""):advance(1)
        assert.are.equal(2, c.screenshots)
    end)

    it("take at most one every two seconds; a kind skipped comes again later", function()
        local c = shooting()
        c:slash("")
        c:hoverItem(ITEMS.satchel)
        c:advance(0.5)
        assert.are.equal(1, c.screenshots)
        assert.is_nil(c.Addon.db.global.dev.shots["tooltip: gain"], "too soon, not marked")
        c:advance(3)
        c:hoverItem(ITEMS.satchel)
        c:advance(0.5)
        assert.are.equal(2, c.screenshots)
    end)

    it("know the moments from the in-game checks", function()
        local c = shooting()
        local function step(fn)
            fn()
            c:advance(3)
        end
        step(function()
            c:hoverItem(ITEMS.satchel)
        end)
        step(function()
            c:equipBag(1, ITEMS.onyxia):equipBag(2, ITEMS.onyxia):equipBag(3, ITEMS.onyxia):equipBag(4, ITEMS.onyxia)
            c:hoverItem(ITEMS.satchel)
        end)
        step(function()
            c:equipBag(5, ITEMS.herb)
            c:slash("")
        end)
        step(function()
            c:equipBag(5, nil)
            c.grids[1]:OnRowClick(c.Addon:Upgrades()[1], "LeftButton")
        end)
        step(function()
            c:slash("options")
        end)
        step(function()
            c.Addon:OptionsTable().args.open.func()
        end)
        local kinds = {}
        for kind in pairs(c.Addon.db.global.dev.shots) do
            kinds[#kinds + 1] = kind
        end
        table.sort(kinds)
        assert.are.same({
            "options window",
            "route",
            "tooltip: gain",
            "tooltip: no gain",
            "window",
            "window: nothing bigger",
        }, kinds)
    end)

    it("are not in a release", function()
        local c = NewClient():login()
        assert.is_nil(c.Addon.DevOptions)
        c:slash(""):advance(1)
        assert.are.equal(0, c.screenshots)
    end)
end)
