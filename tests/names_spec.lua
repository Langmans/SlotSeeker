-- Every name the game and other addons see is made from the addon's folder name, so a rename is the
-- folder and the .toc (README > Renaming). Loaded here as "Tester" to prove it.

describe("the addon's names", function()
    it("start from the folder's name", function()
        local c = NewClient({ addonName = "Tester" }):login()
        assert.are.same({}, c.errors)
        local addon = c.Addon
        assert.are.equal("Tester", addon.NAME)
        assert.are.equal(addon, LibStub("AceAddon-3.0"):GetAddon("Tester"))
        assert.are.equal("TESTER_UPDATED", addon.messages.updated)
        assert.is_table(_G.TesterDB)
    end)

    it("name the window, the slash command, the options page and the route owner", function()
        local c = NewClient({ addonName = "Tester" }):login()
        c:slash("")
        assert.is_table(_G.TesterWindow)
        assert.are.same({ "Tester" }, c.pageNames)
        c.grids[1]:OnRowClick(c.Addon:Upgrades()[7], "LeftButton")
        assert.are.equal("Tester", c.routes[1].owner)
    end)
end)

describe("the names that cannot be made from the folder", function()
    it("match it in the .toc: the saved data", function()
        local c = NewClient():login()
        assert.are.equal(c.Addon.NAME .. "DB", TOC_SAVED)
    end)
end)
