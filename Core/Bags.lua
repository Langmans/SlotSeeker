local _, ns = ...

-- The bags the player carries: per group, the size of the bag an upgrade would replace (the
-- baseline), and the bags lying unequipped in them. The client's bag family tells a plain bag (0)
-- from a quiver, ammo pouch or soul bag, so a bag the data does not know still counts. Read once
-- after each bag change, not on every tooltip.

---@type Addon
local Addon = ns
local G, K = Addon.groups, Addon.kinds

local BAG_SLOTS = 4 -- Enum.BagIndex.Bag_1 .. Bag_4
local REAGENT_SLOT = 5 -- Enum.BagIndex.ReagentBag
-- The bag family bits (C_Container.GetContainerNumFreeSlots's second return).
local FAMILY_QUIVER, FAMILY_AMMO, FAMILY_SOUL = 1, 2, 4

-- A bag kind -> its group. Profession bags go in the reagent slot with the reagent bags.
local KIND_GROUP = {
    [K.bag] = G.bags,
    [K.reagent] = G.reagent,
    [K.herb] = G.reagent,
    [K.enchanting] = G.reagent,
    [K.mining] = G.reagent,
    [K.leather] = G.reagent,
    [K.quiver] = G.ammo,
    [K.ammo] = G.ammo,
    [K.soul] = G.soul,
}
-- The groups only one class has.
local GROUP_CLASS = { [G.ammo] = Addon.classes.hunter, [G.soul] = Addon.classes.warlock }

---The group a kind competes in for this player; nil when it has none, or it is another class's.
---@param kind string?
---@return number?
function Addon:GroupOf(kind)
    local group = KIND_GROUP[kind]
    local class = GROUP_CLASS[group]
    if class and select(3, UnitClass("player")) ~= class then return nil end
    return group
end

-- Per group, the baseline; rebuilt by ScanBags.
---@type table<number, number>
local baselines = {}
-- The bag items lying in the bags, by item ID.
---@type table<number, boolean>
local owned = {}
-- Whether the bags changed since the last scan.
local stale = true

---The bags changed: the next question reads them again.
function Addon:BagsChanged()
    stale = true
end

---Reads the equipped bags and what lies in them, when they changed since the last time.
function Addon:ScanBags()
    if not stale then return end
    stale = false
    wipe(baselines)
    wipe(owned)
    local smallest, ammo, soul
    for bag = 1, BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag)
        local _, family = C_Container.GetContainerNumFreeSlots(bag)
        family = family or 0
        if slots == 0 or family == 0 then
            smallest = math.min(smallest or slots, slots)
        elseif bit.band(family, FAMILY_QUIVER + FAMILY_AMMO) ~= 0 then
            ammo = math.max(ammo or 0, slots)
        elseif bit.band(family, FAMILY_SOUL) ~= 0 then
            soul = math.max(soul or 0, slots)
        end
    end
    baselines[G.bags] = smallest
    baselines[G.reagent] = C_Container.GetContainerNumSlots(REAGENT_SLOT)
    baselines[G.ammo] = ammo or 0
    baselines[G.soul] = soul or 0
    for bag = 0, REAGENT_SLOT do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemID(bag, slot)
            if item and self.data.bags[item] then owned[item] = true end
        end
    end
end

---The size of the bag an upgrade in this group would replace; nil when every bag slot holds
---a bag of another group.
---@param group number
---@return number?
function Addon:Baseline(group)
    self:ScanBags()
    return baselines[group]
end

---Whether a bag lies unequipped in the bags.
---@param itemID number
---@return boolean
function Addon:Owned(itemID)
    self:ScanBags()
    return owned[itemID] == true
end

---How many slots a bag gains over the one it would replace, and its group; nil for an item that
---is no bag this player can use, or whose size the data does not know.
---@param itemID number
---@return number? gain
---@return number? group
function Addon:Gain(itemID)
    local bag = self.data.bags[itemID]
    local group = bag and self:GroupOf(bag.kind)
    if not group then return nil end
    local baseline = self:Baseline(group)
    if not baseline then return nil end
    return bag.slots - baseline, group
end
