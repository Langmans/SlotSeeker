local _, ns = ...

-- The item tooltip: under a bag this player can use, how many slots it gains over the bag it would
-- replace ("+4 slots over your smallest bag"), or that it is no bigger.

---@type Addon
local Addon = ns
local L = Addon.L
local G = Addon.groups

local GAIN_TEXTS = {
    [G.bags] = L.TOOLTIP_GAIN,
    [G.reagent] = L.TOOLTIP_GAIN_REAGENT,
    [G.ammo] = L.TOOLTIP_GAIN_AMMO,
    [G.soul] = L.TOOLTIP_GAIN_SOUL,
}

---Adds the gain line to an item's tooltip. Runs on every item tooltip: the bags are read only
---after they changed, and it makes no tables.
---@param tooltip GameTooltip
---@param data AddonTooltipData?
function Addon:AddGainLine(tooltip, data)
    if not self.db.profile.tooltip then return end
    local itemID = data and data.id
    if not Addon.Readable(itemID) then return end
    local gain, group = self:Gain(itemID --[[@as number]])
    if not gain then return end
    if gain > 0 then
        tooltip:AddLine(GAIN_TEXTS[group]:format(gain), 0.4, 0.8, 1)
    else
        tooltip:AddLine(L.TOOLTIP_NO_GAIN, 0.6, 0.6, 0.6)
    end
end

---Hooks the item tooltips; a client without TooltipDataProcessor gets none.
function Addon:SetupTooltip()
    if not TooltipDataProcessor then return end
    ---@param tooltip GameTooltip
    ---@param data AddonTooltipData
    local function OnItemTooltip(tooltip, data)
        self:AddGainLine(tooltip, data)
    end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
end
