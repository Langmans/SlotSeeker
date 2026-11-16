local addonName, ns = ...

-- The addon object, its fixed value sets and its saved settings. The addon object is the namespace
-- the client hands every file (`Addon`); every name the game and other addons see is made from the
-- folder's name, NAME (README > Renaming).

---@type Addon
local Addon = LibStub("AceAddon-3.0"):NewAddon(ns, addonName, "AceConsole-3.0", "AceEvent-3.0")
Addon.L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- The folder's name; the slash command is NAME in lower case, plus SLASH_ALIAS.
Addon.NAME = addonName
Addon.SLASH_ALIAS = "seek"

---A global name of the addon's own (a frame's, the saved variables'), NAME first.
---@param suffix string
---@return string
function Addon.Global(suffix)
    return addonName .. suffix
end

---A string enum whose keys are its values: { "bag" } gives { bag = "bag" }.
---@param values string[]
---@return table<string, string>
local function SelfKeyed(values)
    local enum = {}
    for _, value in ipairs(values) do
        enum[value] = value
    end
    return enum
end

-- What a bag holds, from its item class and subclass (Data\ uses these names).
Addon.kinds = SelfKeyed({
    "bag",
    "soul",
    "herb",
    "enchanting",
    "engineering",
    "gem",
    "mining",
    "leather",
    "inscription",
    "tackle",
    "cooking",
    "reagent",
    "quiver",
    "ammo",
})
-- The bag slots a bag competes for: the four bag slots (plain bags), the reagent slot, the
-- quiver or ammo pouch of a hunter, the soul bag of a warlock. Numbered in the list's order.
Addon.groups = { bags = 1, reagent = 2, ammo = 3, soul = 4 }
Addon.GROUP_ORDER = { "bags", "reagent", "ammo", "soul" }
-- Where a bag comes from, numbered by effort: the easiest first.
Addon.sources = { owned = 1, vendor = 2, quest = 3, craft = 4, auction = 5, drop = 6 }
Addon.SOURCE_ORDER = { "owned", "vendor", "quest", "craft", "auction", "drop" }
-- How far out of reach a source is: now, a bit hard (an orange quest), too hard (red, or not
-- yet allowed).
Addon.tiers = { now = 1, hard = 2, tooHard = 3 }
Addon.TIER_ORDER = { "now", "hard", "tooHard" }
-- Which faction a vendor or quest serves; the player's comes from UnitFactionGroup.
Addon.factions = { alliance = "Alliance", horde = "Horde", both = "both" }
-- The professions that make bags, by skill line ID.
Addon.professions = { tailoring = 197, leatherworking = 165, engineering = 202 }
-- The classes with a bag slot of their own, by class ID.
Addon.classes = { hunter = 3, warlock = 9 }

-- Public messages (AceEvent SendMessage). updated: the upgrade list was worked out again; it
-- comes with the list (see Core\Upgrades.lua).
Addon.messages = { updated = addonName:upper() .. "_UPDATED" }

-- The bags of the client the .toc loads, filled by Data\<client>\Bags.lua.
Addon.data = { bags = {}, quests = {}, npcs = {} }

local DEFAULTS = {
    profile = {
        tooltip = true,
        -- The list window: { point, relativePoint, x, y, width, height }, its filter tree and sort.
        window = nil,
        filter = nil,
        sort = nil,
    },
    global = {},
}
Addon.DEFAULTS = DEFAULTS

---Whether the game hands over a value the addon may read: not nil and not a secret value.
---@param value GameValue
---@return boolean
function Addon.Readable(value)
    return value ~= nil and not (issecretvalue and issecretvalue(value))
end

function Addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New(Addon.Global("DB"), DEFAULTS, true) --[[@as AddonDB]]
    self:SetupCommands()
    self:SetupOptions()
    self:SetupTooltip()
end

function Addon:OnEnable()
    self:RegisterEvent("BAG_UPDATE_DELAYED", "Changed")
    self:RegisterEvent("PLAYER_LEVEL_UP", "LevelUp")
    self:RegisterEvent("SKILL_LINES_CHANGED", "Changed")
end

---Bags or skills changed: the list is worked out again when it shows.
function Addon:Changed()
    self:BagsChanged()
    self:UpdateWindow()
end

---PLAYER_LEVEL_UP comes before UnitLevel gives the new level, so the event's own is kept.
---@param _ string the event
---@param level number
function Addon:LevelUp(_, level)
    self.leveledTo = level
    self:Changed()
end

---The player's level, the one just reached included.
---@return number
function Addon:PlayerLevel()
    return math.max(UnitLevel("player"), self.leveledTo or 0)
end
