-- The generated bag data (Data\Forever\Bags.lua): every reference in it points at something it
-- has, in the addon's own enums, so a builder mistake shows here and not in the game.

describe("the generated bag data", function()
    local c = NewClient({ realData = true }):login()
    local A = c.Addon
    local data = A.data

    ---Whether a value is one of an enum's values.
    local function isOneOf(enum, value)
        for _, v in pairs(enum) do
            if v == value then return true end
        end
        return false
    end

    it("loads without errors and has bags", function()
        assert.are.same({}, c.errors)
        assert.is_true(next(data.bags) ~= nil)
    end)

    it("gives every bag a size, a kind and at least one source", function()
        for id, bag in pairs(data.bags) do
            assert(bag.slots > 0, id .. ": no slots")
            assert(isOneOf(A.kinds, bag.kind), id .. ": unknown kind " .. tostring(bag.kind))
            local sourced = bag.vendors or bag.quests or bag.crafts or bag.drops or bag.worldDrop
            assert(sourced, id .. ": no source")
        end
    end)

    it("names only vendors, quests, givers and creatures it has", function()
        for id, bag in pairs(data.bags) do
            for _, offer in ipairs(bag.vendors or {}) do
                assert(data.npcs[offer.npc], id .. ": vendor " .. offer.npc)
                assert(offer.cost >= 0, id .. ": cost")
            end
            for _, quest in ipairs(bag.quests or {}) do
                assert(data.quests[quest], id .. ": quest " .. quest)
            end
            for _, drop in ipairs(bag.drops or {}) do
                assert(data.npcs[drop.npc], id .. ": creature " .. drop.npc)
            end
            for _, craft in ipairs(bag.crafts or {}) do
                assert(isOneOf(A.professions, craft.skill), id .. ": profession " .. tostring(craft.skill))
            end
        end
        for id, quest in pairs(data.quests) do
            assert(isOneOf(A.factions, quest.side), id .. ": side")
            assert(not quest.giver or data.npcs[quest.giver], id .. ": giver " .. tostring(quest.giver))
        end
        for id, npc in pairs(data.npcs) do
            assert(isOneOf(A.factions, npc.side), id .. ": side")
            assert.is_table(npc.pins)
        end
    end)
end)
