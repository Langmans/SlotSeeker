-- Which bags are upgrades and in what order: the bag each would replace, the sources a player can
-- use (faction, class, profession, bind), how far out of reach each is, and the prices.

---A logged-in client; `setup` changes the player before login.
---@param setup fun(client: table)?
---@param opts TestClientOptions?
local function client(setup, opts)
    local c = NewClient(opts)
    if setup then setup(c) end
    return c:login()
end

---The row for an item, or nil.
local function row(c, item)
    for _, r in ipairs(c.Addon:Upgrades()) do
        if r.item == item then return r end
    end
end

---The items of the rows, in order.
local function items(c)
    local out = {}
    for i, r in ipairs(c.Addon:Upgrades()) do
        out[i] = r.item
    end
    return out
end

describe("the quest tiers", function()
    it("follow the quest log's colours: yellow and below now, orange hard, red too hard", function()
        local A = NewClient().Addon
        local T = A.tiers
        assert.are.equal(T.now, A.QuestTier(17, 13, 30)) -- grey
        assert.are.equal(T.now, A.QuestTier(17, 13, 15)) -- yellow, two above
        assert.are.equal(T.hard, A.QuestTier(17, 13, 14)) -- orange
        assert.are.equal(T.tooHard, A.QuestTier(17, 1, 12)) -- red
    end)

    it("are too hard while the player cannot take the quest yet", function()
        local A = NewClient().Addon
        assert.are.equal(A.tiers.tooHard, A.QuestTier(14, 13, 12))
    end)
end)

describe("the bag a candidate replaces", function()
    it("is the smallest plain bag in the four bag slots, an empty slot counting as none", function()
        local c = client(function(c)
            c.bags[1] = { item = ITEMS.heavy, slots = 10 }
        end)
        assert.are.equal(0, c.Addon:Baseline(c.Addon.groups.bags))
        c:equipBag(2, ITEMS.heavy):equipBag(3, ITEMS.heavy):equipBag(4, ITEMS.satchel)
        assert.are.equal(8, c.Addon:Baseline(c.Addon.groups.bags))
    end)

    it("leaves quivers and soul bags in the bag slots out", function()
        local c = client(function(c)
            c.classID = 3
            for bag = 1, 3 do
                c.bags[bag] = { item = ITEMS.heavy, slots = 10 }
            end
            c.bags[4] = { item = ITEMS.quiver, slots = 6 }
        end)
        assert.are.equal(10, c.Addon:Baseline(c.Addon.groups.bags))
        assert.are.equal(6, c.Addon:Baseline(c.Addon.groups.ammo))
    end)

    it("is the soul bag for a warlock's soul bags", function()
        local c = client(function(c)
            c.classID = 9
            c.bags[1] = { item = ITEMS.soulPouch, slots = 20 }
        end)
        assert.are.equal(20, c.Addon:Baseline(c.Addon.groups.soul))
        assert.are.equal(0, c.Addon:Baseline(c.Addon.groups.bags))
    end)

    it("is the reagent slot's bag for reagent and profession bags", function()
        local c = client()
        assert.are.equal(0, c.Addon:Baseline(c.Addon.groups.reagent))
        c:equipBag(5, ITEMS.reagent)
        assert.are.equal(8, c.Addon:Baseline(c.Addon.groups.reagent))
    end)

    it("counts a bag the client cannot name by its slots alone", function()
        local c = client(function(c)
            for bag = 1, 4 do
                c.bags[bag] = { item = 99999, slots = 14 }
            end
        end)
        assert.are.equal(14, c.Addon:Baseline(c.Addon.groups.bags))
    end)
end)

describe("the upgrades", function()
    it("list every bigger bag the player can get, reachable ones first, then by slots gained", function()
        local c = client()
        assert.are.same({
            ITEMS.huge, -- 12, auction house (Horde vendor only)
            ITEMS.knapsack, -- 12, auction house
            ITEMS.mageweave, -- 12, auction house
            ITEMS.heavy, -- 10, Alliance vendor
            ITEMS.deviate, -- 10, quest 17 at level 20
            ITEMS.murloc, -- 10, auction house
            ITEMS.satchel, -- 8, vendor
            ITEMS.linen, -- 6, auction house; a tie goes by name
            ITEMS.pouch, -- 6, auction house
            ITEMS.herb, -- 12, reagent slot, vendor
            ITEMS.reagent, -- 8, reagent slot, auction house
            ITEMS.onyxia, -- 18, bind on pickup, drop at 60: too hard
        }, items(c))
    end)

    it("put bags of the same name in item ID order", function()
        local c = client()
        local getName = C_Item.GetItemNameByID
        C_Item.GetItemNameByID = function()
            return "Bag"
        end
        local order = items(c)
        C_Item.GetItemNameByID = getName
        assert.are.equal(ITEMS.pouch, order[8])
        assert.are.equal(ITEMS.linen, order[9])
    end)

    it("prefer the easiest source of a bag: owned, vendor, quest, craft, auction house, drop", function()
        local c = client(function(c)
            c.skills[SKILLS.tailoring] = 225
        end)
        local S = c.Addon.sources
        assert.are.equal(S.vendor, row(c, ITEMS.satchel).source)
        assert.are.equal(S.quest, row(c, ITEMS.deviate).source)
        assert.are.equal(S.craft, row(c, ITEMS.mageweave).source)
        assert.are.equal(S.auction, row(c, ITEMS.knapsack).source)
        assert.are.equal(S.drop, row(c, ITEMS.onyxia).source)
        c:put(0, 3, ITEMS.satchel)
        assert.are.equal(S.owned, row(c, ITEMS.satchel).source)
    end)

    it("leave out bags no bigger than the one they would replace", function()
        local c = client(function(c)
            for bag = 1, 4 do
                c.bags[bag] = { item = ITEMS.heavy, slots = 10 }
            end
        end)
        assert.is_nil(row(c, ITEMS.satchel))
        assert.is_nil(row(c, ITEMS.heavy))
        assert.are.equal(2, row(c, ITEMS.huge).gain)
    end)

    it("leave out a faction's vendors and quests for the other faction", function()
        local horde = client(function(c)
            c.faction = "Horde"
        end)
        local S = horde.Addon.sources
        assert.are.equal(S.vendor, row(horde, ITEMS.huge).source)
        assert.are.equal(S.auction, row(horde, ITEMS.heavy).source)
        assert.are.equal(500, row(horde, ITEMS.satchel).vendor)
        local alliance = client()
        assert.is_nil(row(alliance, ITEMS.redBag))
        assert.are.equal(526, row(alliance, ITEMS.satchel).vendor)
    end)

    it("count a craft only with the profession at its skill; below it, it is hard", function()
        local c = client(function(c)
            c.skills[SKILLS.tailoring] = 100
        end)
        assert.are.equal(c.Addon.sources.auction, row(c, ITEMS.mageweave).source)
        c:learn(SKILLS.tailoring, 225)
        local r = row(c, ITEMS.mageweave)
        assert.are.equal(c.Addon.sources.craft, r.source)
        assert.are.equal("Tailoring 225", r.where)
    end)

    it("rank a quest by its level against the player's, and follow a level up", function()
        local c = client(function(c)
            c.level = 14
        end)
        local T = c.Addon.tiers
        local r = row(c, ITEMS.deviate)
        assert.are.equal(T.hard, r.tier)
        assert.are.equal(17, r.level)
        assert.are.equal("Deviate Hides (level 17)", r.where)
        c:levelUp(16)
        assert.are.equal(T.now, row(c, ITEMS.deviate).tier)
    end)

    it("rank drops by the creature's level, a world drop by the bag's", function()
        local c = client(function(c)
            c.faction = "Horde"
            c.level = 50
        end)
        local r = row(c, ITEMS.onyxia)
        assert.are.equal(c.Addon.tiers.tooHard, r.tier)
        assert.are.equal("World drop (level 60)", r.where)
        local red = row(c, ITEMS.redBag)
        assert.are.equal(c.Addon.tiers.tooHard, red.tier)
    end)

    it("name a named creature's drop with its level", function()
        local c = client()
        c.Addon.data.bags[ITEMS.murloc].bop = true
        local r = row(c, ITEMS.murloc)
        assert.are.equal(c.Addon.sources.drop, r.source)
        assert.are.equal("Gelihast (level 25)", r.where)
        assert.are.equal(c.Addon.tiers.tooHard, r.tier)
    end)

    it("show quivers to hunters and soul bags to warlocks only", function()
        local warrior = client()
        assert.is_nil(row(warrior, ITEMS.medium))
        assert.is_nil(row(warrior, ITEMS.soulPouch))
        local hunter = client(function(c)
            c.classID = 3
        end)
        assert.are.equal(hunter.Addon.groups.ammo, row(hunter, ITEMS.medium).group)
        local warlock = client(function(c)
            c.classID = 9
        end)
        assert.are.equal(warlock.Addon.groups.soul, row(warlock, ITEMS.soulPouch).group)
    end)

    it("respect a bag's class restriction", function()
        local c = client()
        c.Addon.data.bags[ITEMS.satchel].reqclass = 4 -- Hunters only: class 3 is the mask's bit 4
        assert.is_nil(row(c, ITEMS.satchel))
    end)

    it("take the auction house price from Auctionator and the cheaper price per slot gained", function()
        local c = client(nil, { auction = { [ITEMS.satchel] = 400, [ITEMS.knapsack] = 6000 } })
        local satchel = row(c, ITEMS.satchel)
        assert.are.equal(526, satchel.vendor)
        assert.are.equal(400, satchel.auction)
        assert.are.equal(50, satchel.perSlot)
        assert.are.equal(500, row(c, ITEMS.knapsack).perSlot)
        assert.is_nil(row(c, ITEMS.pouch).perSlot)
        assert.are.equal(c.Addon.NAME, c.auctionCallers[1])
    end)

    it("live without Auctionator, or with one whose API fails", function()
        local c = client()
        assert.is_nil(row(c, ITEMS.knapsack).auction)
        _G.Auctionator = {
            API = {
                v1 = {
                    GetAuctionPriceByItemID = function()
                        error("broken")
                    end,
                },
            },
        }
        assert.is_nil(row(c, ITEMS.knapsack).auction)
    end)

    it("send a message after working the list out again", function()
        local c = client()
        local heard
        local listener = {}
        LibStub("AceEvent-3.0"):Embed(listener)
        listener:RegisterMessage(c.Addon.messages.updated, function(_, rows)
            heard = rows
        end)
        local rows = c.Addon:Upgrades()
        assert.are.equal(rows, heard)
    end)
end)
