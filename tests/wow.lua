-- A simulated WoW: Forever client: the API SlotSeeker and its libraries touch, with every value a
-- test may want to vary exposed on the client object. NewClient() resets the globals and loads the
-- .toc's files (the libraries included) into a fresh namespace, so tests never share state. The
-- load order and the .toc's metadata come from tests/helper.lua. The frame and Ace3 plumbing
-- follows FishCatchVisualizer's tests/wow.lua. LibDataGrid's schema and view run for real; its
-- widgets, and LibGoThere's routing, are stand-ins that record what they were given.

-- What a hidden value looks like to the addon: only issecretvalue tells it apart.
SECRET = setmetatable({}, {
    __tostring = function()
        return "<secret>"
    end,
})

-- The test world's items: real Classic bag IDs, with the sizes and sources the fixture gives them.
ITEMS = {
    backpack = 0, -- not an item: the backpack slot's own 16 slots
    pouch = 805, -- Small Red Pouch, 6, world drop
    satchel = 4498, -- Brown Leather Satchel, 8, Alliance and Horde vendors
    heavy = 4497, -- Heavy Brown Bag, 10, Alliance vendor only
    huge = 4499, -- Huge Brown Sack, 12, Horde vendor only
    deviate = 918, -- Deviate Hide Pack, 10, quest level 17 (from 13)
    linen = 4238, -- Linen Bag, 6, Tailoring 5
    mageweave = 10050, -- Mageweave Bag, 12, Tailoring 225
    murloc = 1470, -- Murloc Skin Bag, 10, drop from one level 25 creature
    knapsack = 1725, -- Large Knapsack, 12, world drop around 40
    onyxia = 17966, -- Onyxia Hide Backpack, 18, bind on pickup, drop
    redBag = 18, -- a made-up 16-slot bag from a quest for Horde only, level 55
    reagent = 287000, -- a made-up 8-slot general reagent bag, Tailoring 50
    herb = 22250, -- Herb Pouch, 12, herb bag from a vendor
    quiver = 2101, -- Light Quiver, 6, vendor
    medium = 11362, -- Medium Quiver, 10, vendor
    soulPouch = 21340, -- Soul Pouch, 20, Tailoring 260
    shard = 6265, -- Soul Shard, not a bag
}
NPCS = { goldshire = 151, orgrimmar = 3000, nalpak = 5767, gelihast = 6243, grunt = 4000, bowyer = 1201 }
QUESTS = { deviate = 1486, red = 9001 }
SKILLS = { tailoring = 197 }
MAPS = { elwynn = 1429, durotar = 1411 }

-- What the client knows about each item: name, class and subclass (1 Container: 0 bag, 1 soul,
-- 2 herb, 11 reagent; 11 Quiver: 2 quiver, 3 ammo pouch; 15 Miscellaneous), quality.
local ITEM_INFO = {
    [ITEMS.pouch] = { name = "Small Red Pouch", class = 1, subclass = 0, quality = 1 },
    [ITEMS.satchel] = { name = "Brown Leather Satchel", class = 1, subclass = 0, quality = 1 },
    [ITEMS.heavy] = { name = "Heavy Brown Bag", class = 1, subclass = 0, quality = 1 },
    [ITEMS.huge] = { name = "Huge Brown Sack", class = 1, subclass = 0, quality = 1 },
    [ITEMS.deviate] = { name = "Deviate Hide Pack", class = 1, subclass = 0, quality = 2 },
    [ITEMS.linen] = { name = "Linen Bag", class = 1, subclass = 0, quality = 1 },
    [ITEMS.mageweave] = { name = "Mageweave Bag", class = 1, subclass = 0, quality = 1 },
    [ITEMS.murloc] = { name = "Murloc Skin Bag", class = 1, subclass = 0, quality = 1 },
    [ITEMS.knapsack] = { name = "Large Knapsack", class = 1, subclass = 0, quality = 1 },
    [ITEMS.onyxia] = { name = "Onyxia Hide Backpack", class = 1, subclass = 0, quality = 4 },
    [ITEMS.redBag] = { name = "Red Bag", class = 1, subclass = 0, quality = 2 },
    [ITEMS.reagent] = { name = "Woolen Reagent Bag", class = 1, subclass = 11, quality = 1 },
    [ITEMS.herb] = { name = "Herb Pouch", class = 1, subclass = 2, quality = 1 },
    [ITEMS.quiver] = { name = "Light Quiver", class = 11, subclass = 2, quality = 1 },
    [ITEMS.medium] = { name = "Medium Quiver", class = 11, subclass = 2, quality = 1 },
    [ITEMS.soulPouch] = { name = "Soul Pouch", class = 1, subclass = 1, quality = 2 },
    [ITEMS.shard] = { name = "Soul Shard", class = 15, subclass = 0, quality = 1 },
}

---The bags as Data\Forever\Bags.lua would have them, in the addon's enums.
---@param A table the addon
---@return table
local function Fixture(A)
    local K, F, P = A.kinds, A.factions, A.professions
    return {
        bags = {
            [ITEMS.pouch] = { slots = 6, kind = K.bag, level = 5, worldDrop = true },
            [ITEMS.satchel] = {
                slots = 8,
                kind = K.bag,
                level = 10,
                vendors = { { npc = NPCS.goldshire, cost = 526 }, { npc = NPCS.orgrimmar, cost = 500 } },
            },
            [ITEMS.heavy] = {
                slots = 10,
                kind = K.bag,
                level = 20,
                vendors = { { npc = NPCS.goldshire, cost = 2500 } },
            },
            [ITEMS.huge] = {
                slots = 12,
                kind = K.bag,
                level = 30,
                vendors = { { npc = NPCS.orgrimmar, cost = 10000 } },
            },
            [ITEMS.deviate] = { slots = 10, kind = K.bag, level = 17, bop = true, quests = { QUESTS.deviate } },
            [ITEMS.linen] = { slots = 6, kind = K.bag, level = 5, crafts = { { skill = P.tailoring, rank = 5 } } },
            [ITEMS.mageweave] = {
                slots = 12,
                kind = K.bag,
                level = 35,
                crafts = { { skill = P.tailoring, rank = 225 } },
            },
            [ITEMS.murloc] = { slots = 10, kind = K.bag, level = 25, drops = { { npc = NPCS.gelihast, level = 25 } } },
            [ITEMS.knapsack] = { slots = 12, kind = K.bag, level = 40, worldDrop = true },
            [ITEMS.onyxia] = { slots = 18, kind = K.bag, level = 60, bop = true, worldDrop = true },
            [ITEMS.redBag] = { slots = 16, kind = K.bag, level = 55, bop = true, quests = { QUESTS.red } },
            [ITEMS.reagent] = {
                slots = 8,
                kind = K.reagent,
                level = 15,
                crafts = { { skill = P.tailoring, rank = 50 } },
            },
            [ITEMS.herb] = {
                slots = 12,
                kind = K.herb,
                level = 20,
                vendors = { { npc = NPCS.goldshire, cost = 4000 } },
            },
            [ITEMS.quiver] = { slots = 6, kind = K.quiver, level = 1, vendors = { { npc = NPCS.bowyer, cost = 4 } } },
            [ITEMS.medium] = {
                slots = 10,
                kind = K.quiver,
                level = 10,
                vendors = { { npc = NPCS.bowyer, cost = 2000 } },
            },
            [ITEMS.soulPouch] = {
                slots = 20,
                kind = K.soul,
                level = 50,
                crafts = { { skill = P.tailoring, rank = 260 } },
            },
        },
        quests = {
            [QUESTS.deviate] = { name = "Deviate Hides", level = 17, min = 13, side = F.both, giver = NPCS.nalpak },
            [QUESTS.red] = { name = "Red Bag Blues", level = 55, min = 50, side = F.horde, giver = NPCS.grunt },
        },
        npcs = {
            [NPCS.goldshire] = { name = "Brog Hamfist", side = F.alliance, pins = { [MAPS.elwynn] = { 42.5, 67.0 } } },
            [NPCS.orgrimmar] = { name = "Shop Keeper", side = F.horde, pins = { [MAPS.durotar] = { 51.0, 41.5 } } },
            [NPCS.nalpak] = { name = "Nalpak", side = F.both, pins = { [MAPS.durotar] = { 46.0, 36.0, 47.0, 37.5 } } },
            [NPCS.gelihast] = { name = "Gelihast", side = F.both, pins = {} },
            [NPCS.grunt] = { name = "Grunt", side = F.horde, pins = {} },
            [NPCS.bowyer] = { name = "Bowyer", side = F.both, pins = { [MAPS.elwynn] = { 43.0, 66.0 } } },
        },
    }
end

---A file's source as the client gets it: from a release, where the packager comments out every line
---between `--@debug@` and `--@end-debug@`, unless `dev` (a copy straight from the repository).
---The line count stays, so coverage still points at the right lines.
---@param file string
---@param dev boolean
---@return string
local function AsPackaged(file, dev)
    local handle = assert(io.open(file, "rb"))
    local source = handle:read("*a")
    handle:close()
    if dev or not source:find("--@debug@", 1, true) then return source end
    local lines, inDebug = {}, false
    for line in (source .. "\n"):gmatch("(.-)\r?\n") do
        if line:match("^%s*%-%-@end%-debug@") then
            inDebug = false
        elseif inDebug then
            line = "--" .. line
        elseif line:match("^%s*%-%-@debug@") then
            inDebug = true
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n")
end

---Compiled once per run and kind of copy: a file's chunk runs again for every client.
---@type table<string, function>
local chunks = {}
local function Chunk(file, dev)
    local key = (dev and "dev:" or "release:") .. file
    chunks[key] = chunks[key] or assert(loadstring(AsPackaged(file, dev), "@" .. file))
    return chunks[key]
end

---Packs varargs with their count, nils included (Lua 5.1 has no table.pack).
local function pack(...)
    return { n = select("#", ...), ... }
end

-- WoW's Lua 5.1 passes xpcall's extra arguments on to the function, as Lua 5.2 does; plain 5.1
-- drops them. Ace3 relies on it.
local plainXpcall = xpcall
function xpcall(func, handler, ...)
    local args = pack(...)
    return plainXpcall(function()
        return func(unpack(args, 1, args.n))
    end, handler)
end

---@class TestClientOptions
---@field saved table? SlotSeekerDB as the saved file left it
---@field addonName string? the addon's folder name, SlotSeeker by default
---@field dev boolean? a copy straight from the repository: `--@debug@` blocks run
---@field noTooltipData boolean? a client without TooltipDataProcessor
---@field realData boolean? keep the generated Data\ file instead of the fixture
---@field auction table<number, number>? Auctionator's prices by item ID; nil: no Auctionator

---@param opts TestClientOptions?
function NewClient(opts)
    opts = opts or {}
    local addonName = opts.addonName or "SlotSeeker"
    local function noop() end
    local client = {
        time = 100,
        frames = {},
        printed = {},
        errors = {},
        loggedIn = false,
        -- The player.
        level = 20,
        faction = "Alliance",
        classID = 1, -- 1 Warrior, 3 Hunter, 9 Warlock
        skills = {}, -- skill line ID -> rank
        -- The equipped bags by bag index (0 the backpack, 1-4 the bag slots, 5 the reagent slot):
        -- { item = itemID, slots = n }; nil: an empty slot. contents[bag][slot]: the item there.
        bags = { [0] = { item = ITEMS.backpack, slots = 16 } },
        contents = {},
        shift = false,
    }

    function GetLocale()
        return "enUS"
    end
    function GetTime()
        return client.time
    end
    time, date = os.time, os.date
    client.screenshots = 0
    function Screenshot()
        client.screenshots = client.screenshots + 1
    end
    function IsLoggedIn()
        return client.loggedIn
    end
    function geterrorhandler()
        return function(err)
            client.errors[#client.errors + 1] = tostring(err)
        end
    end
    function securecallfunction(func, ...)
        return func(...)
    end
    function hooksecurefunc(target, name, hook)
        if type(target) ~= "table" then
            target, name, hook = _G, target, name
        end
        local original = target[name]
        target[name] = function(...)
            local results = pack(original(...))
            hook(...)
            return unpack(results, 1, results.n)
        end
    end
    function InCombatLockdown()
        return false
    end
    C_EventUtils = {
        IsEventValid = function()
            return true
        end,
    }
    function issecretvalue(value)
        return value == SECRET
    end
    function IsShiftKeyDown()
        return client.shift
    end

    -- The player.
    function UnitName()
        return "Seeker"
    end
    UnitNameUnmodified = UnitName
    function UnitLevel(unit)
        assert(unit == "player")
        return client.level
    end
    function UnitClass()
        return "Class", "CLASS", client.classID
    end
    function UnitRace()
        return "Human", "Human", 1
    end
    function UnitFactionGroup()
        return client.faction, client.faction
    end
    function GetRealmName()
        return "Doomhowl"
    end
    function GetCurrentRegion()
        return 3
    end
    function GetCurrentRegionName()
        return "EU"
    end

    -- Skills: client.skills, one line each (a header first, as the client lists them).
    C_SkillInfo = {
        GetNumSkillLines = function()
            local n = 1
            for _ in pairs(client.skills) do
                n = n + 1
            end
            return n
        end,
        GetSkillLineInfo = function(index)
            if index == 1 then return { isHeader = true, skillID = 0, rank = 0, name = "Professions" } end
            local i = 1
            for id, rank in pairs(client.skills) do
                i = i + 1
                if i == index then return { isHeader = false, skillID = id, rank = rank, name = "Skill" } end
            end
        end,
    }

    Enum = {
        ItemClass = { Container = 1, Quiver = 11, Miscellaneous = 15 },
        BagIndex = { Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5 },
        TooltipDataType = { Item = 0, Spell = 1 },
    }

    -- Bags: client.bags and client.contents. A bag's family is 0 for a plain bag and a bit mask for
    -- the others, as the client gives it.
    local FAMILIES = { [0] = 0, [1] = 4, [2] = 32, [11] = 0 }
    local function familyOf(item)
        local info = ITEM_INFO[item]
        if not info then return 0 end
        if info.class == 11 then return info.subclass == 2 and 1 or 2 end
        return FAMILIES[info.subclass] or 0
    end
    C_Container = {
        GetContainerNumSlots = function(bag)
            local entry = client.bags[bag]
            return entry and entry.slots or 0
        end,
        GetContainerNumFreeSlots = function(bag)
            local entry = client.bags[bag]
            if not entry then return 0, nil end
            return entry.slots, familyOf(entry.item)
        end,
        ContainerIDToInventoryID = function(bag)
            assert(bag >= 1 and bag <= 5, "only the bag slots have an inventory slot")
            return 30 + bag
        end,
        GetContainerItemID = function(bag, slot)
            return client.contents[bag] and client.contents[bag][slot]
        end,
    }
    function GetInventoryItemID(unit, slot)
        assert(unit == "player")
        local entry = client.bags[slot - 30]
        return entry and entry.item
    end

    -- Items: what the client knows about the items in ITEM_INFO.
    local function idOf(item)
        if type(item) == "number" then return item end
        return tonumber(tostring(item):match("item:(%d+)"))
    end
    C_Item = {
        GetItemInfoInstant = function(item)
            local id = idOf(item)
            local info = ITEM_INFO[id]
            if not info then return nil end
            return id, "", "", "", 133000 + id, info.class, info.subclass
        end,
        GetItemNameByID = function(item)
            local info = ITEM_INFO[idOf(item)]
            return info and info.name
        end,
        GetItemQualityByID = function(item)
            local info = ITEM_INFO[idOf(item)]
            return info and info.quality
        end,
        GetItemIconByID = function(item)
            return 133000 + idOf(item)
        end,
        GetItemInfo = function(item)
            local id = idOf(item)
            local info = ITEM_INFO[id]
            if not info then return nil end
            return info.name, ("|cffffffff|Hitem:%d::::::::20:::::|h[%s]|h|r"):format(id, info.name)
        end,
    }
    ITEM_QUALITY_COLORS = {}
    for quality = 0, 5 do
        ITEM_QUALITY_COLORS[quality] = { r = 1, g = 1, b = 1, hex = ("|cff%06d"):format(quality) }
    end
    C_CurrencyInfo = {
        GetCoinTextureString = function(amount)
            return amount .. "c"
        end,
    }

    -- Auctionator, when opts.auction gives its prices. client.auctionCallers: who asked.
    client.auctionCallers = {}
    Auctionator = opts.auction
            and {
                API = {
                    v1 = {
                        GetAuctionPriceByItemID = function(caller, itemID)
                            client.auctionCallers[#client.auctionCallers + 1] = caller
                            return opts.auction[itemID]
                        end,
                    },
                },
            }
        or nil

    -- The chat box's link insertion. client.linked: every link put in.
    client.linked = {}
    ChatFrameUtil = {
        InsertLink = function(link)
            client.linked[#client.linked + 1] = link
            return true
        end,
    }

    -- The client's bit library; plain Lua 5.1 has none.
    bit = {
        band = function(a, b)
            local result, place = 0, 1
            while a > 0 and b > 0 do
                if a % 2 == 1 and b % 2 == 1 then result = result + place end
                a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
            end
            return result
        end,
    }

    -- WoW's string and table shorthands.
    strmatch, strfind, strsub, strlower, strupper, strlen, format, gsub =
        string.match, string.find, string.sub, string.lower, string.upper, string.len, string.format, string.gsub
    tinsert, tremove, tconcat = table.insert, table.remove, table.concat
    min, max, floor = math.min, math.max, math.floor
    function strtrim(text, chars)
        chars = chars or " \t\r\n"
        local class = "[" .. chars:gsub("[%]%%%-%^]", "%%%0") .. "]"
        return (text:gsub("^" .. class .. "+", ""):gsub(class .. "+$", ""))
    end
    function strsplit(sep, text, limit)
        local parts, start = {}, 1
        while true do
            if limit and #parts == limit - 1 then break end
            local at = text:find(sep, start, true)
            if not at then break end
            parts[#parts + 1] = text:sub(start, at - 1)
            start = at + #sep
        end
        parts[#parts + 1] = text:sub(start)
        return unpack(parts)
    end
    string.split = strsplit
    function strlenutf8(text)
        return select(2, text:gsub("[^\128-\191]", ""))
    end
    function strjoin(sep, ...)
        return table.concat({ ... }, sep)
    end
    function wipe(tbl)
        for key in pairs(tbl) do
            tbl[key] = nil
        end
        return tbl
    end
    table.wipe = wipe
    function tostringall(...)
        local out = pack(...)
        for i = 1, out.n do
            out[i] = tostring(out[i])
        end
        return unpack(out, 1, out.n)
    end

    -- Blizzard's Mixin and CreateFromMixins, and CallbackRegistryMixin as far as LibDataGrid's
    -- view uses it.
    function Mixin(object, ...)
        for i = 1, select("#", ...) do
            for k, v in pairs((select(i, ...))) do
                object[k] = v
            end
        end
        return object
    end
    function CreateFromMixins(...)
        return Mixin({}, ...)
    end
    CallbackRegistryMixin = {
        OnLoad = function(self)
            self.callbackTables = {}
        end,
        GenerateCallbackEvents = function(self, events)
            self.Event = self.Event or {}
            for _, event in ipairs(events) do
                self.Event[event] = event
            end
        end,
        RegisterCallback = function(self, event, func, owner)
            self.callbackTables[event] = self.callbackTables[event] or {}
            self.callbackTables[event][owner] = func
            return owner
        end,
        TriggerEvent = function(self, event, ...)
            for owner, func in pairs(self.callbackTables[event] or {}) do
                func(owner, ...)
            end
        end,
    }

    -- Frames: a frame keeps its events, scripts, shown state, points, size and text; any other
    -- capitalised method is a no-op.
    local Region = {}
    Region.__index = function(_, key)
        if Region[key] then return Region[key] end
        if type(key) == "string" and key:match("^%u") then return noop end
    end
    function Region:Show()
        if self.shown then return end
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function Region:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function Region:SetShown(shown)
        if shown then
            self:Show()
        else
            self:Hide()
        end
    end
    function Region:IsShown()
        return self.shown
    end
    function Region:IsVisible()
        return self.shown
    end
    function Region:RegisterEvent(event)
        self.events[event] = true
    end
    function Region:RegisterUnitEvent(event, unit)
        self.events[event] = unit
    end
    function Region:UnregisterEvent(event)
        self.events[event] = nil
    end
    function Region:UnregisterAllEvents()
        self.events = {}
    end
    function Region:IsEventRegistered(event)
        return self.events[event] ~= nil
    end
    function Region:SetScript(script, handler)
        self.scripts[script] = handler
    end
    function Region:GetScript(script)
        return self.scripts[script]
    end
    function Region:HookScript(script, handler)
        local original = self.scripts[script]
        self.scripts[script] = function(...)
            if original then original(...) end
            handler(...)
        end
    end
    ---Runs a script as the client would: the frame first, then the script's own arguments.
    function Region:Run(script, ...)
        local fn = self.scripts[script]
        if fn then fn(self, ...) end
    end
    function Region:GetName()
        return self.name
    end
    function Region:GetParent()
        return self.parent
    end
    function Region:SetWidth(width)
        self.width = width
    end
    function Region:SetHeight(height)
        self.height = height
    end
    function Region:SetSize(width, height)
        self.width, self.height = width, height
    end
    function Region:GetWidth()
        return self.width or 100
    end
    function Region:GetHeight()
        return self.height or 20
    end
    function Region:GetSize()
        return self:GetWidth(), self:GetHeight()
    end
    function Region:GetStringWidth()
        return #(self.text or "") * 6
    end
    for _, getter in ipairs({ "GetTop", "GetBottom", "GetLeft", "GetRight", "GetStringHeight", "GetFrameLevel" }) do
        Region[getter] = function()
            return 0
        end
    end
    function Region:GetEffectiveScale()
        return 1
    end
    function Region:SetPoint(point, relativeTo, relativePoint, x, y)
        self.points = self.points or {}
        self.points[#self.points + 1] = { point, relativeTo, relativePoint, x, y }
    end
    function Region:ClearAllPoints()
        self.points = {}
    end
    function Region:GetPoint(index)
        local p = self.points and self.points[index or 1]
        if p then return p[1], p[2], p[3], p[4], p[5] end
    end
    function Region:GetNumPoints()
        return self.points and #self.points or 0
    end
    function Region:StartMoving()
        self.moving = true
    end
    function Region:StartSizing()
        self.sizing = true
    end
    function Region:StopMovingOrSizing()
        self.moving, self.sizing = false, false
    end
    function Region:SetResizeBounds(minWidth, minHeight)
        self.resizeBounds = { minWidth, minHeight }
    end
    function Region:GetText()
        return self.text
    end
    function Region:SetText(text)
        self.text = text
    end
    function Region:SetFormattedText(pattern, ...)
        self.text = pattern:format(...)
    end
    function Region:SetFont(path, size, flags)
        self.font = { path, size, flags }
        return true
    end
    function Region:GetFont()
        return "Fonts\\FRIZQT__.TTF", 12, ""
    end
    function Region:SetTexture(texture)
        self.texture = texture
    end
    local function newRegion(fields)
        fields = fields or {}
        fields.shown = true
        fields.events, fields.scripts = {}, {}
        return setmetatable(fields, Region)
    end
    function Region:CreateTexture()
        return newRegion({ parent = self, kind = "Texture" })
    end
    function Region:CreateFontString()
        return newRegion({ parent = self, kind = "FontString" })
    end
    for _, getter in ipairs({
        "GetNormalTexture",
        "GetPushedTexture",
        "GetHighlightTexture",
        "GetDisabledTexture",
        "GetCheckedTexture",
        "GetFontString",
    }) do
        Region[getter] = function(self)
            local key = "_" .. getter
            if not rawget(self, key) then rawset(self, key, newRegion()) end
            return rawget(self, key)
        end
    end
    local TEMPLATE_CHILDREN = { UIDropDownMenuTemplate = { "Left", "Middle", "Right", "Button", "Text" } }
    function CreateFrame(kind, name, parent, template)
        local frame = newRegion({ kind = kind, name = name, parent = parent, template = template })
        client.frames[#client.frames + 1] = frame
        if name then _G[name] = frame end
        for _, suffix in ipairs(name and TEMPLATE_CHILDREN[template] or {}) do
            _G[name .. suffix] = newRegion({ name = name .. suffix })
        end
        return frame
    end
    UIParent = newRegion({ name = "UIParent" })
    WorldFrame = newRegion()
    UISpecialFrames = {}

    -- The game's tooltip. client.tooltipLines: the lines added since the last hover, { text, r, g, b }.
    GameTooltip = newRegion({ name = "GameTooltip" })
    client.tooltipLines = {}
    function GameTooltip:AddLine(text, r, g, b)
        client.tooltipLines[#client.tooltipLines + 1] = { text, r, g, b }
    end
    client.tooltipPostCalls = {}
    TooltipDataProcessor = not opts.noTooltipData
            and {
                AddTooltipPostCall = function(dataType, callback)
                    client.tooltipPostCalls[dataType] = client.tooltipPostCalls[dataType] or {}
                    table.insert(client.tooltipPostCalls[dataType], callback)
                end,
            }
        or nil

    -- Global strings and constants the Ace3 GUI reads.
    FONT_COLOR_CODE_CLOSE, NORMAL_FONT_COLOR_CODE = "|r", "|cffffd200"
    NORMAL_FONT_COLOR = { r = 1, g = 0.82, b = 0 }
    ACCEPT, CANCEL, CLOSE, OKAY, NOT_BOUND, YES, NO = "Accept", "Cancel", "Close", "Okay", "Not Bound", "Yes", "No"
    WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_CAMELOT = 1, 2, 18
    WOW_PROJECT_ID = WOW_PROJECT_CAMELOT

    -- The settings window. client.pageNames: the pages added, in order; client.opened: the IDs opened.
    client.categories, client.pageNames, client.opened = {}, {}, {}
    local nextID = 1
    local function newCategory(frame, name, parent)
        local category = { frame = frame, name = name, parent = parent, ID = nextID }
        nextID = nextID + 1
        function category:GetID()
            return self.ID
        end
        return category
    end
    Settings = {
        RegisterCanvasLayoutCategory = newCategory,
        RegisterCanvasLayoutSubcategory = function(parent, frame, name)
            local category = newCategory(frame, name, parent)
            client.categories[category.ID] = category
            client.pageNames[#client.pageNames + 1] = name
            return category
        end,
        RegisterAddOnCategory = function(category)
            client.categories[category.ID] = category
            client.pageNames[#client.pageNames + 1] = category.name
        end,
        GetCategory = function(id)
            return client.categories[id]
        end,
        OpenToCategory = function(id)
            client.opened[#client.opened + 1] = id
        end,
    }

    -- client.timers: pending C_Timer callbacks; client:advance runs the ones that come due.
    client.timers = {}
    C_Timer = {
        After = function(seconds, callback)
            client.timers[#client.timers + 1] = { at = client.time + seconds, callback = callback }
        end,
    }

    -- client.printed: every chat line, whether through print or the default chat frame.
    DEFAULT_CHAT_FRAME = newRegion()
    function DEFAULT_CHAT_FRAME:AddMessage(text)
        client.printed[#client.printed + 1] = text
    end
    function print(...)
        client.printed[#client.printed + 1] = table.concat({ tostringall(...) }, " ")
    end

    C_AddOns = {
        GetAddOnMetadata = function(name, key)
            if name == addonName then return TOC_METADATA[key] end
        end,
        IsAddOnLoaded = function()
            return false, false
        end,
    }

    SlashCmdList = {}
    hash_SlashCmdList = {}
    _G[TOC_SAVED] = opts.saved

    LibStub = nil
    local ns = {}
    for _, file in ipairs(TOC_FILES) do
        Chunk(file, opts.dev == true)(addonName, ns)
    end
    client.Addon = ns
    if not opts.realData then ns.data = Fixture(ns) end

    -- LibDataGrid's widgets as stand-ins: a frame that keeps its view, columns (key, width or
    -- weight), rows and handlers. client.grids, client.filterBoxes: every one made.
    local DG = LibStub("LibDataGrid-1.0")
    client.grids, client.filterBoxes = {}, {}
    function DG:CreateGrid(parent, view, skin, ...)
        local grid = newRegion({ parent = parent, view = view, skin = skin, columns = {}, rows = nil })
        for i = 1, select("#", ...) do
            for k, v in pairs((select(i, ...))) do
                grid[k] = v
            end
        end
        function grid:AddFillColumn(key, weight)
            self.columns[#self.columns + 1] = { key = key, weight = weight or 1 }
        end
        function grid:AddFixedWidthColumn(key, width)
            self.columns[#self.columns + 1] = { key = key, width = width }
        end
        function grid:SetRows(rows)
            self.rows = rows
            self.shown = {}
            view:Refresh(rows, self.shown)
        end
        function grid:Refresh()
            view:Refresh(self.rows, self.shown)
        end
        client.grids[#client.grids + 1] = grid
        return grid
    end
    function DG:CreateFilterBox(parent, view, skin)
        local box = newRegion({ parent = parent, view = view, skin = skin })
        client.filterBoxes[#client.filterBoxes + 1] = box
        return box
    end
    -- LibGoThere's routing as a stand-in. client.routes: { owner, points } per call.
    local GoThere = LibStub("LibGoThere-1.0")
    client.routes = {}
    function GoThere:NavigateNearest(owner, points)
        client.routes[#client.routes + 1] = { owner = owner, points = points }
        return "tomtom", 1
    end

    ---Delivers an event to every frame registered for it.
    function client:fire(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
        return self
    end

    ---Moves the clock on and runs the C_Timer callbacks that came due.
    function client:advance(seconds)
        self.time = self.time + seconds
        local due = {}
        for i = #self.timers, 1, -1 do
            if self.timers[i].at <= self.time then table.insert(due, 1, table.remove(self.timers, i)) end
        end
        for _, timer in ipairs(due) do
            timer.callback()
        end
        return self
    end

    ---The next frame drawn: every shown frame's OnUpdate runs (AceConfigDialog closes its window there).
    function client:nextFrame()
        for _, frame in ipairs(self.frames) do
            local onUpdate = frame.scripts.OnUpdate
            if frame.shown and onUpdate then onUpdate(frame, 0.016) end
        end
        return self
    end

    ---What the client does at login: ADDON_LOADED, PLAYER_LOGIN, then the loading screen ends.
    function client:login()
        self:fire("ADDON_LOADED", addonName)
        self.loggedIn = true
        self:fire("PLAYER_LOGIN")
        self:fire("PLAYER_ENTERING_WORLD", true, false)
        return self
    end

    ---Puts a bag in a bag slot (nil empties it): its size from the fixture, then BAG_UPDATE_DELAYED.
    ---@param bag number 1-4 a bag slot, 5 the reagent slot
    ---@param item number?
    ---@param slots number? its size; the fixture's when not given
    function client:equipBag(bag, item, slots)
        if item then
            local known = self.Addon.data.bags[item]
            self.bags[bag] = { item = item, slots = slots or known.slots }
        else
            self.bags[bag] = nil
        end
        return self:fire("BAG_UPDATE_DELAYED")
    end

    ---Puts an item in a bag's slot, then BAG_UPDATE_DELAYED.
    function client:put(bag, slot, item)
        self.contents[bag] = self.contents[bag] or {}
        self.contents[bag][slot] = item
        return self:fire("BAG_UPDATE_DELAYED")
    end

    ---The player levels up to `level`: PLAYER_LEVEL_UP.
    function client:levelUp(level)
        self.level = level
        return self:fire("PLAYER_LEVEL_UP", level)
    end

    ---The player learns a skill or raises it: SKILL_LINES_CHANGED.
    function client:learn(skill, rank)
        self.skills[skill] = rank
        return self:fire("SKILL_LINES_CHANGED")
    end

    ---The mouse over an item: the item post-calls run; returns the lines they added.
    ---@param itemID any a number, or SECRET
    function client:hoverItem(itemID)
        self.tooltipLines = {}
        for _, callback in ipairs(self.tooltipPostCalls[Enum.TooltipDataType.Item] or {}) do
            callback(GameTooltip, { type = Enum.TooltipDataType.Item, id = itemID })
        end
        return self.tooltipLines
    end

    ---Runs a line of the addon's slash command the way the chat box does; `command` picks another
    ---of its commands (the alias), the addon's own name by default.
    function client:slash(message, command)
        SlashCmdList["ACECONSOLE_" .. (command or addonName):upper()](message)
        return self
    end

    function client:printedContains(text)
        for _, line in ipairs(self.printed) do
            if line:find(text, 1, true) then return true end
        end
        return false
    end

    return client
end

function Saved()
    return _G[TOC_SAVED]
end
