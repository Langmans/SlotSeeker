local _, ns = ...

-- A row's way there: the spots of the vendors that serve the player, the quest's giver, or the
-- creatures that drop the bag (Core\Questie.lua: the data's, else QuestieDB's), handed to
-- LibGoThere, which picks the nearest and the player's route or waypoint addon.

---@type Addon
local Addon = ns
local L = Addon.L
local S, F = Addon.sources, Addon.factions
local GoThere = LibStub("LibGoThere-1.0") --[[@as LibGoThere]]

local NONE = {}

---The spots a row's source can be found at; empty for one that is nowhere in particular.
---@param row AddonRow
---@return table[]
function Addon:RoutePoints(row)
    local data, points = self.data, {}
    local bag = data.bags[row.item]
    if row.source == S.vendor then
        local faction = UnitFactionGroup("player")
        for _, offer in ipairs(bag.vendors or NONE) do
            local npc = data.npcs[offer.npc]
            if npc and (npc.side == F.both or npc.side == faction) then self:AddNpcSpots(points, offer.npc) end
        end
    elseif row.source == S.quest then
        local giver = self:QuestGiver(row.quest --[[@as number]])
        if giver then self:AddNpcSpots(points, giver) end
    elseif row.source == S.drop then
        for _, drop in ipairs(bag.drops or NONE) do
            self:AddNpcSpots(points, drop.npc)
        end
    end
    return points
end

---Sends the player to the nearest spot of a row's source, or says there is none.
---@param row AddonRow
function Addon:Route(row)
    local points = self:RoutePoints(row)
    if #points == 0 then
        self:Print(L.NO_ROUTE:format(Addon.BagName(row.item)))
        return
    end
    GoThere:NavigateNearest(self.NAME, points)
end
