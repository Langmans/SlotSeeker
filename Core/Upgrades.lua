local _, ns = ...

-- The upgrade list: every bag bigger than the one it would replace that this player can get, each
-- with its easiest source, how far out of reach that is, and its prices. Sorted reachable first,
-- then by slot group, slots gained, effort and name. Worked out when the window shows or the bags,
-- level or skills change while it does; the rows are kept and refilled, not rebuilt.

---@type Addon
local Addon = ns
local L = Addon.L
local S, T, F = Addon.sources, Addon.tiers, Addon.factions

local NONE = {}

---How far out of reach something of this level is for a player of that level, in the quest log's
---colour bands: up to two above is yellow (now), three or four orange (hard), five red (too hard).
---@param level number
---@param playerLevel number
---@return number tier
function Addon.LevelTier(level, playerLevel)
    local over = level - playerLevel
    if over >= 5 then return T.tooHard end
    if over >= 3 then return T.hard end
    return T.now
end

---A quest's tier: by its level, and too hard while the player is below its minimum level.
---@param level number
---@param minLevel number
---@param playerLevel number
---@return number tier
function Addon.QuestTier(level, minLevel, playerLevel)
    if playerLevel < minLevel then return T.tooHard end
    return Addon.LevelTier(level, playerLevel)
end

---A profession's name, by skill line ID.
---@type table<number, string>
local professionNames = {}
for key, skill in pairs(Addon.professions) do
    professionNames[skill] = L["PROFESSION_" .. key:upper()]
end

-- The player as the list sees them, read again for each list: skills are ranks by skill line ID.
---@type { level: number, faction: string, classBit: number, skills: table<number, number> }
local player = { level = 1, faction = "", classBit = 0, skills = {} }

---@param self Addon
local function ReadPlayer(self)
    player.level = self:PlayerLevel()
    player.faction = UnitFactionGroup("player")
    player.classBit = 2 ^ (select(3, UnitClass("player")) - 1)
    wipe(player.skills)
    for i = 1, C_SkillInfo.GetNumSkillLines() do
        local info = C_SkillInfo.GetSkillLineInfo(i)
        if info and not info.isHeader then player.skills[info.skillID] = info.rank end
    end
end

---Whether a vendor or quest of this side serves the player.
---@param side string
---@return boolean
local function Serves(side)
    return side == F.both or side == player.faction
end

---Takes a source for the row when it beats the row's current one: a lower tier, or the same tier
---and less effort. Returns whether it took it.
---@param row AddonRow
---@param source number
---@param tier number
---@param level number?
---@param where string?
---@return boolean
local function Consider(row, source, tier, level, where)
    if row.source and (row.tier < tier or (row.tier == tier and row.source <= source)) then return false end
    row.source, row.tier, row.level, row.where = source, tier, level, where
    return true
end

---Auctionator's last price for an item, through its public API; nil without it, or when it fails.
---@param itemID number
---@return number?
local function AuctionPrice(itemID)
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    local GetPrice = api and api.GetAuctionPriceByItemID
    if not GetPrice then return nil end
    local ok, price = pcall(GetPrice, Addon.NAME, itemID)
    if ok then return price end
    return nil
end

---Fills a row's source, tier, level, where and prices from the bag's sources. Returns whether the
---player can get the bag at all.
---@param self Addon
---@param row AddonRow
---@param bag AddonBag
---@return boolean
local function Evaluate(self, row, bag)
    local data = self.data
    row.source, row.tier, row.level, row.where, row.quest = nil, nil, nil, nil, nil
    row.vendor, row.auction, row.perSlot = nil, nil, nil
    if self:Owned(row.item) then Consider(row, S.owned, T.now) end
    local cheapest
    for _, offer in ipairs(bag.vendors or NONE) do
        local npc = data.npcs[offer.npc]
        if npc and Serves(npc.side) and (not row.vendor or offer.cost < row.vendor) then
            row.vendor, cheapest = offer.cost, npc
        end
    end
    if cheapest then Consider(row, S.vendor, T.now, nil, cheapest.name) end
    for _, id in ipairs(bag.quests or NONE) do
        local quest = data.quests[id]
        if quest and Serves(quest.side) then
            local tier = Addon.QuestTier(quest.level, quest.min, player.level)
            if Consider(row, S.quest, tier, quest.level, L.WHERE_QUEST:format(quest.name, quest.level)) then
                row.quest = id
            end
        end
    end
    for _, craft in ipairs(bag.crafts or NONE) do
        local rank = player.skills[craft.skill]
        if rank then
            local where = L.WHERE_CRAFT:format(professionNames[craft.skill], craft.rank)
            Consider(row, S.craft, rank >= craft.rank and T.now or T.hard, nil, where)
        end
    end
    if not bag.bop then
        row.auction = AuctionPrice(row.item)
        Consider(row, S.auction, T.now)
    end
    for _, drop in ipairs(bag.drops or NONE) do
        local npc = data.npcs[drop.npc]
        local name = npc and npc.name or L.UNKNOWN:format(drop.npc)
        Consider(
            row,
            S.drop,
            Addon.LevelTier(drop.level, player.level),
            drop.level,
            L.WHERE_DROP:format(name, drop.level)
        )
    end
    if bag.worldDrop then
        Consider(row, S.drop, Addon.LevelTier(bag.level, player.level), bag.level, L.WORLD_DROP:format(bag.level))
    end
    local price = row.vendor and row.auction and math.min(row.vendor, row.auction) or row.vendor or row.auction
    if price then row.perSlot = math.floor(price / row.gain + 0.5) end
    return row.source ~= nil
end

---The list's order: reachable first, then the slot group, more slots gained, less effort, name.
---Only rows with a source are in the list, so tier and source are set.
---@param a AddonRow
---@param b AddonRow
---@return boolean
local function Before(a, b)
    local aTier = a.tier --[[@as number]]
    local bTier = b.tier --[[@as number]]
    if aTier ~= bTier then return aTier < bTier end
    if a.group ~= b.group then return a.group < b.group end
    if a.gain ~= b.gain then return a.gain > b.gain end
    local aSource = a.source --[[@as number]]
    local bSource = b.source --[[@as number]]
    if aSource ~= bSource then return aSource < bSource end
    if a.name ~= b.name then return a.name < b.name end
    return a.item < b.item
end

-- The list, and a row per bag kept for the next list.
---@type AddonRow[]
local rows = {}
---@type table<number, AddonRow>
local pool = {}

---The bag's name as the client has it, else its item ID.
---@param itemID number
---@return string
function Addon.BagName(itemID)
    return C_Item.GetItemNameByID(itemID) or ("item:" .. itemID)
end

---Works the upgrade list out (the same table every time, refilled) and says so with the updated
---message.
---@return AddonRow[]
function Addon:Upgrades()
    ReadPlayer(self)
    wipe(rows)
    for itemID, bag in pairs(self.data.bags) do
        local gain, group = self:Gain(itemID)
        local classOk = not bag.reqclass or bit.band(bag.reqclass, player.classBit) ~= 0
        if gain and gain > 0 and classOk then
            local row = pool[itemID] or { item = itemID }
            pool[itemID] = row
            row.slots, row.gain, row.group, row.name = bag.slots, gain, group, Addon.BagName(itemID)
            if Evaluate(self, row, bag) then rows[#rows + 1] = row end
        end
    end
    table.sort(rows, Before)
    self:SendMessage(self.messages.updated, rows)
    return rows
end
