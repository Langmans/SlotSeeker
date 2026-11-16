-- QuestieDB, when installed: quest and NPC names in the client's language, quest givers and spawn
-- spots where the addon's own data has none. Read through its public API (LibQuestieDB, contract
-- 4) at run time only; without it, or with an incompatible one, the addon's own data stands.

-- Durotar's AreaID and uiMapID, and Blackfathom Deeps' (an instance: no map).
local AREAS = { durotar = 14, blackfathom = 719 }

---QuestieDB's French view of the fixture.
---@return table
local function questie()
    return {
        quests = {
            [QUESTS.deviate] = { name = "Peaux déviantes", startedBy = { { NPCS.nalpak } } },
            [QUESTS.red] = { name = "Le blues du sac rouge", startedBy = { { 9100 } } },
        },
        npcs = {
            [NPCS.goldshire] = { name = "Brog Poing-de-jambon" },
            [NPCS.gelihast] = {
                name = "Gélihast",
                spawns = { [AREAS.durotar] = { { 50, 50 }, { -1, -1 } }, [AREAS.blackfathom] = { { 10, 10 } } },
            },
            [9100] = { name = "Grognard", spawns = { [AREAS.durotar] = { { 20, 30 } } } },
        },
        maps = { [AREAS.durotar] = MAPS.durotar, [AREAS.blackfathom] = 0 },
    }
end

---A logged-in client, the window shown.
local function shown(opts, setup)
    local c = NewClient(opts)
    if setup then setup(c) end
    return c:login():slash("")
end

local function gridRow(c, item)
    for _, r in ipairs(c.grids[1].rows) do
        if r.item == item then return r end
    end
end

describe("QuestieDB", function()
    it("names quests and NPCs in the client's language", function()
        local c = shown({ questie = questie() })
        assert.are.equal("Peaux déviantes (level 17)", gridRow(c, ITEMS.deviate).where)
        assert.are.equal("Brog Poing-de-jambon", gridRow(c, ITEMS.satchel).where)
        c.Addon.data.bags[ITEMS.murloc].bop = true
        c:fire("BAG_UPDATE_DELAYED")
        assert.are.equal("Gélihast (level 25)", gridRow(c, ITEMS.murloc).where)
    end)

    it("gives spawn spots where the data has none, on the map of their zone", function()
        local c = shown({ questie = questie() })
        c.Addon.data.bags[ITEMS.murloc].bop = true
        c:fire("BAG_UPDATE_DELAYED")
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.murloc), "LeftButton")
        assert.are.same({ { MAPS.durotar, 0.5, 0.5, "Gélihast" } }, c.routes[1].points)
    end)

    it("keeps the data's own spots, under QuestieDB's name", function()
        local c = shown({ questie = questie() })
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.satchel), "LeftButton")
        assert.are.same({ { MAPS.elwynn, 0.425, 0.67, "Brog Poing-de-jambon" } }, c.routes[1].points)
    end)

    it("gives a quest's giver where the data has none", function()
        local c = shown({ questie = questie() }, function(c)
            c.faction = "Horde"
            c.level = 55
        end)
        c.Addon.data.quests[QUESTS.red].giver = nil
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.redBag), "LeftButton")
        assert.are.same({ { MAPS.durotar, 0.2, 0.3, "Grognard" } }, c.routes[1].points)
    end)

    it("is left alone when its contract is not one the addon speaks", function()
        local db = questie()
        db.contract = 3
        local c = shown({ questie = db })
        assert.are.equal("Deviate Hides (level 17)", gridRow(c, ITEMS.deviate).where)
    end)

    it("is left alone where its API fails", function()
        local db = questie()
        db.broken = true
        local c = shown({ questie = db })
        assert.are.equal("Deviate Hides (level 17)", gridRow(c, ITEMS.deviate).where)
        c.Addon.data.bags[ITEMS.murloc].bop = true
        c:fire("BAG_UPDATE_DELAYED")
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.murloc), "LeftButton")
        assert.are.equal(0, #c.routes)
    end)

    it("works without its zone table", function()
        local db = questie()
        db.maps = nil
        local c = shown({ questie = db })
        c.Addon.data.bags[ITEMS.murloc].bop = true
        c:fire("BAG_UPDATE_DELAYED")
        c.grids[1]:OnRowClick(gridRow(c, ITEMS.murloc), "LeftButton")
        assert.are.equal(0, #c.routes)
        assert.are.equal("Gélihast (level 25)", gridRow(c, ITEMS.murloc).where)
    end)

    it("falls back to the data's names where it has none", function()
        local db = questie()
        db.quests[QUESTS.deviate].name = nil
        db.npcs[NPCS.goldshire] = nil
        local c = shown({ questie = db })
        assert.are.equal("Deviate Hides (level 17)", gridRow(c, ITEMS.deviate).where)
        assert.are.equal("Brog Hamfist", gridRow(c, ITEMS.satchel).where)
    end)
end)
