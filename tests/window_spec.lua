-- The list window: a LibDataGrid filter box and grid over the upgrades, a row click routing to the
-- source, its place, size, filter and sort kept.

---A logged-in client with the window shown.
local function shown(setup, opts)
    local c = NewClient(opts)
    if setup then setup(c) end
    c:login():slash("")
    return c
end

---The grid's row for an item.
local function gridRow(c, item)
    for _, r in ipairs(c.grids[1].rows) do
        if r.item == item then return r end
    end
end

---A column definition of the grid's schema, by key.
local function column(c, key)
    return c.grids[1].view.schema:Column(key)
end

describe("the window", function()
    it("opens and closes with the slash command, by the folder's name or the alias", function()
        local c = NewClient():login()
        assert.is_nil(c.Addon.window)
        c:slash("")
        local frame = c.Addon.window.frame
        assert.is_true(frame:IsShown())
        c:slash("", "seek")
        assert.is_false(frame:IsShown())
        assert.are.equal(c.Addon.Global("Window"), frame:GetName())
        assert.are.same({ frame:GetName() }, UISpecialFrames)
    end)

    it("lists the upgrades in a grid with a filter box", function()
        local c = shown()
        assert.are.equal(1, #c.grids)
        assert.are.equal(1, #c.filterBoxes)
        assert.are.equal(c.Addon:Upgrades(), c.grids[1].rows)
        local keys = {}
        for i, col in ipairs(c.grids[1].columns) do
            keys[i] = col.key
        end
        assert.are.same({
            "bag",
            "slots",
            "gain",
            "group",
            "source",
            "tier",
            "level",
            "where",
            "vendor",
            "auction",
            "perSlot",
        }, keys)
    end)

    it("shows a bag in its quality colour, money as coins, and the words of each choice", function()
        local c = shown(nil, { auction = { [ITEMS.satchel] = 400 } })
        local satchel = gridRow(c, ITEMS.satchel)
        assert.are.equal("|cff000001Brown Leather Satchel|r", column(c, "bag"):CellText(satchel))
        assert.are.equal("526c", column(c, "vendor"):CellText(satchel))
        assert.are.equal("400c", column(c, "auction"):CellText(satchel))
        assert.are.equal("50c", column(c, "perSlot"):CellText(satchel))
        assert.are.equal("", column(c, "auction"):CellText(gridRow(c, ITEMS.heavy)))
        assert.are.equal("Brown Leather Satchel", column(c, "bag"):Value(satchel))
        assert.are.equal("Vendor", column(c, "source"):CellText(satchel))
        local texts = {}
        for _, key in ipairs({ "group", "source", "tier" }) do
            for _, choice in ipairs(column(c, key):Choices()) do
                texts[#texts + 1] = choice.text
            end
        end
        assert.are.same({
            "Bag",
            "Reagent",
            "Quiver",
            "Soul bag",
            "In your bags",
            "Vendor",
            "Quest",
            "Craft",
            "Auction house",
            "Drop",
            "Now",
            "Hard",
            "Too hard",
        }, texts)
    end)

    it("names a bag the client has not cached by its ID", function()
        local c = shown()
        local r = gridRow(c, ITEMS.satchel)
        local getName = C_Item.GetItemNameByID
        C_Item.GetItemNameByID = function() end
        assert.are.equal("|cff000001item:4498|r", column(c, "bag"):CellText(r))
        C_Item.GetItemNameByID = getName
    end)

    it("works the list out again when bags, level or skills change while it is open", function()
        local c = shown()
        assert.is_not_nil(gridRow(c, ITEMS.satchel))
        for bag = 1, 4 do
            c:equipBag(bag, ITEMS.heavy)
        end
        assert.is_nil(gridRow(c, ITEMS.satchel))
        c:levelUp(21):learn(SKILLS.tailoring, 1)
        assert.are.same({}, c.errors)
    end)

    it("says so when nothing is bigger", function()
        local c = shown(function(c)
            for bag = 1, 4 do
                c.bags[bag] = { item = ITEMS.onyxia, slots = 18 }
            end
            c.bags[5] = { item = ITEMS.herb, slots = 12 }
        end)
        assert.is_true(c.Addon.window.empty:IsShown())
        assert.are.equal("No bigger bag within reach. Nice bags!", c.Addon.window.empty:GetText())
        c:equipBag(5, nil)
        assert.is_false(c.Addon.window.empty:IsShown())
    end)

    it("routes to the nearest vendor or quest giver of a row, on a click", function()
        local c = shown()
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.satchel), "LeftButton")
        assert.are.same({
            owner = c.Addon.NAME,
            points = { { MAPS.elwynn, 0.425, 0.67, "Brog Hamfist" } },
        }, c.routes[1])
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.deviate), "LeftButton")
        assert.are.same({
            { MAPS.durotar, 0.46, 0.36, "Nalpak" },
            { MAPS.durotar, 0.47, 0.375, "Nalpak" },
        }, c.routes[2].points)
    end)

    it("routes to the creatures that drop a bag", function()
        local c = shown()
        c.Addon.data.bags[ITEMS.murloc].bop = true
        c.Addon.data.npcs[NPCS.gelihast].pins = { [MAPS.durotar] = { 50.0, 50.0 } }
        c:fire("BAG_UPDATE_DELAYED")
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.murloc), "LeftButton")
        assert.are.same({ { MAPS.durotar, 0.5, 0.5, "Gelihast" } }, c.routes[1].points)
    end)

    it("says when a row has nowhere to go", function()
        local c = shown()
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.knapsack), "LeftButton")
        assert.are.equal(0, #c.routes)
        assert.is_true(c:printedContains("No spot to go to for Large Knapsack."))
    end)

    it("puts the bag's link in chat on a shift-click", function()
        local c = shown()
        c.shift = true
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.satchel), "LeftButton")
        assert.are.same({ "|cffffffff|Hitem:4498::::::::20:::::|h[Brown Leather Satchel]|h|r" }, c.linked)
        assert.are.equal(0, #c.routes)
    end)

    it("keeps its place and size, and its filter and sort", function()
        local c = shown()
        local frame = c.Addon.window.frame
        frame:Run("OnMouseDown", "LeftButton")
        assert.is_true(frame.moving)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -50)
        frame:SetSize(700, 400)
        frame:Run("OnMouseUp", "LeftButton")
        assert.is_false(frame.moving)
        c.Addon.window.grip:Run("OnMouseDown", "LeftButton")
        assert.is_true(frame.sizing)
        c.Addon.window.grip:Run("OnMouseUp", "LeftButton")
        local view = c.grids[1].view
        assert.is_true(view:SetFilterText("[Gain] >= 10"))
        view:ToggleSort("vendor")
        local profile = c.Addon.db.profile
        assert.are.same(
            { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 40, y = -50, width = 700, height = 400 },
            profile.window
        )
        assert.are.same({ { key = "vendor" } }, profile.sort)
        assert.is_table(profile.filter)

        local again = NewClient({ saved = Saved() }):login():slash("")
        local f = again.Addon.window.frame
        assert.are.same({ "TOPLEFT", UIParent, "TOPLEFT", 40, -50 }, f.points[1])
        assert.are.same({ 700, 400 }, { f:GetSize() })
        assert.are.equal("[Gain] >= 10", again.grids[1].view:GetFilterText())
        assert.are.same({ { key = "vendor" } }, again.grids[1].view:GetSort())
    end)

    it("closes with its close button", function()
        local c = shown()
        c.Addon.window.close:Run("OnClick")
        assert.is_false(c.Addon.window.frame:IsShown())
    end)
end)
