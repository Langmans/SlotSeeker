local _, ns = ...

-- Names and spots: the addon's own data, and QuestieDB's when it is installed. QuestieDB (GPL)
-- is only read at run time through its public API, LibQuestieDB, never copied into the data:
-- quest and NPC names in the client's language, quest givers and spawn spots where the data has
-- none. An incompatible contract or a read that fails leaves the addon's own data.

---@type Addon
local Addon = ns
local L = Addon.L

local CONTRACT = 4 -- LibQuestieDB's contract version this file is written against
-- QuestieDB's ZoneDB keeps its AreaID -> uiMapID tables as Lua text; the override goes last.
local ZONE_TABLES = { "areaIdToUiMapId", "areaIdToUiMapIdOverride" }

-- LibQuestieDB when it speaks the contract, false when it is absent or does not; nil: not asked.
---@type LibQuestieDB|false|nil
local questie
-- AreaID -> uiMapID, read from QuestieDB once.
---@type table<number, number>?
local maps

---LibQuestieDB, when it is installed and speaks the contract.
---@return LibQuestieDB?
local function Questie()
    if questie == nil then
        local lib = rawget(_G, "LibQuestieDB") --[[@as LibQuestieDB?]]
        local ok, speaks = pcall(function()
            return lib and lib.RequireContract(CONTRACT)
        end)
        questie = ok and speaks and lib or false
    end
    return questie or nil
end

---What QuestieDB has for an ID; nil without QuestieDB, or when its read fails.
---@generic T
---@param read fun(lib: LibQuestieDB, id: number): T
---@param id number
---@return T?
local function Ask(read, id)
    local lib = Questie()
    if not lib then return nil end
    local ok, value = pcall(read, lib, id)
    if ok then return value end
    return nil
end

---@param lib LibQuestieDB
---@param id number
---@return string?
local function QuestTitle(lib, id)
    return lib.Quest.name(id)
end

---@param lib LibQuestieDB
---@param id number
---@return LibQuestieDBStartedBy?
local function QuestStarters(lib, id)
    return lib.Quest.startedBy(id)
end

---@param lib LibQuestieDB
---@param id number
---@return string?
local function NpcTitle(lib, id)
    return lib.Npc.name(id)
end

---@param lib LibQuestieDB
---@param id number
---@return LibQuestieDBSpawns?
local function NpcSpawns(lib, id)
    return lib.Npc.spawns(id)
end

---The uiMapID of an AreaID, from QuestieDB's zone table; nil for none (an instance, or no table).
---@param lib LibQuestieDB
---@param area number
---@return number?
local function MapOf(lib, area)
    if not maps then
        maps = {}
        local zone = lib.Support.Get("ZoneDB")
        ---@type table<string, string|table>
        local tables = zone and zone["private"] or {}
        for _, key in ipairs(ZONE_TABLES) do
            local source = tables[key]
            local chunk = type(source) == "string" and loadstring(source)
            if chunk then
                local loaded = chunk() --[[@as table<number, number>]]
                for area, uiMap in pairs(loaded) do
                    maps[area] = uiMap
                end
            end
        end
    end
    local uiMap = maps[area]
    if uiMap and uiMap ~= 0 then return uiMap end
    return nil
end

---A quest's name: QuestieDB's (the client's language), else the data's.
---@param id number
---@return string
function Addon:QuestName(id)
    local quest = self.data.quests[id]
    return Ask(QuestTitle, id) or (quest and quest.name) or L.UNKNOWN:format(id)
end

---An NPC's name: QuestieDB's (the client's language), else the data's.
---@param id number
---@return string
function Addon:NpcName(id)
    local npc = self.data.npcs[id]
    return Ask(NpcTitle, id) or (npc and npc.name) or L.UNKNOWN:format(id)
end

---Who gives a quest: the data's giver, else QuestieDB's first NPC starter.
---@param id number
---@return number?
function Addon:QuestGiver(id)
    local quest = self.data.quests[id]
    if quest and quest.giver then return quest.giver end
    local startedBy = Ask(QuestStarters, id) --[[@as LibQuestieDBStartedBy?]]
    local npcs = startedBy and startedBy[1]
    return npcs and npcs[1]
end

---Adds an NPC's spawn spots to a list of points ({ map, x, y, name }, x and y from 0 to 1): the
---data's pins, else QuestieDB's spawns on the map of their zone. Spots QuestieDB marks unknown
---(-1, -1) and zones without a map are left out.
---@param points table[]
---@param id number
function Addon:AddNpcSpots(points, id)
    local name = self:NpcName(id)
    local npc = self.data.npcs[id]
    if npc and next(npc.pins) then
        for map, pins in pairs(npc.pins) do
            for i = 1, #pins, 2 do
                points[#points + 1] = { map, pins[i] / 100, pins[i + 1] / 100, name }
            end
        end
        return
    end
    local spawns = Ask(NpcSpawns, id) --[[@as LibQuestieDBSpawns?]]
    if not spawns then return end
    local lib = Questie() --[[@as LibQuestieDB]]
    for area, spots in pairs(spawns) do
        local map = MapOf(lib, area)
        for _, spot in ipairs(map and spots or {}) do
            if spot[1] >= 0 then points[#points + 1] = { map, spot[1] / 100, spot[2] / 100, name } end
        end
    end
end
