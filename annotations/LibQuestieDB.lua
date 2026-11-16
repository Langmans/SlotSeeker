---@meta
-- QuestieDB's public API (LibQuestieDB, contract 4), as far as the addon reads it. QuestieDB
-- ships its own full types in its Types\ folder; this is the slice the addon relies on.

---A quest's starters: NPCs, objects, items.
---@class LibQuestieDBStartedBy
---@field [1] number[]? NPC IDs
---@field [2] number[]? object IDs
---@field [3] number[]? item IDs

---A spawn spot in zone percent; { -1, -1 } for an unknown one.
---@class LibQuestieDBSpot
---@field [1] number x
---@field [2] number y

---Spawn spots per AreaID.
---@class LibQuestieDBSpawns
---@field [number] LibQuestieDBSpot[]

---@class LibQuestieDBQuest
---@field name fun(id: number): string?
---@field startedBy fun(id: number): LibQuestieDBStartedBy?

---@class LibQuestieDBNpc
---@field name fun(id: number): string?
---@field spawns fun(id: number): LibQuestieDBSpawns?

---A support module; its data is under the key "private" (ZoneDB's AreaID -> uiMapID tables as
---Lua text). Read as zone["private"]: `private` is an annotation keyword to the LS.
---@class LibQuestieDBSupport
---@field Get fun(name: string): table<string, table<string, string|table>>?

---@class LibQuestieDB
---@field RequireContract fun(required: number): boolean, string?
---@field Quest LibQuestieDBQuest
---@field Npc LibQuestieDBNpc
---@field Support LibQuestieDBSupport

---@type LibQuestieDB?
LibQuestieDB = nil
