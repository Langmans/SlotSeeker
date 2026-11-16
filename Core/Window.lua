local _, ns = ...

-- The list window: LibDataGrid's filter box and grid over the upgrade list, in a plain movable and
-- resizable frame. A row click routes to the source, a shift-click puts the bag's link in chat.
-- Its place, size, filter and sort are kept in the profile. Made the first time it opens.

---@type Addon
local Addon = ns
local L = Addon.L
local DG = LibStub("LibDataGrid-1.0") --[[@as LibDataGrid]]
local DT = DG.types

local DEFAULT_WIDTH, DEFAULT_HEIGHT = 820, 380
local MIN_WIDTH, MIN_HEIGHT = 560, 220

---An enum's choices in its order, worded by L[prefix .. KEY].
---@param enum table<string, number>
---@param order string[]
---@param prefix string
---@return LibDataGridChoice[]
local function Choices(enum, order, prefix)
    local choices = {}
    for i, key in ipairs(order) do
        choices[i] = { value = enum[key], text = L[prefix .. key:gsub("%u", "_%0"):upper()] }
    end
    return choices
end

---Copper as coins; nothing for no price.
---@param copper number?
---@return string
local function Money(copper)
    if not copper then return "" end
    return C_CurrencyInfo.GetCoinTextureString(copper)
end

---@param key string
---@return fun(row: AddonRow): string
local function MoneyText(key)
    return function(row)
        return Money(row[key])
    end
end

---@type LibDataGridColumnDef[]
local COLUMNS = {
    {
        key = "bag",
        label = L.COLUMN_BAG,
        ---@param row AddonRow
        ---@return string
        value = function(row)
            return Addon.BagName(row.item)
        end,
        ---@param row AddonRow
        ---@return string
        text = function(row)
            ---@type { hex: string }
            local color = ITEM_QUALITY_COLORS[C_Item.GetItemQualityByID(row.item) or 1]
            return color.hex .. Addon.BagName(row.item) .. "|r"
        end,
    },
    { key = "slots", label = L.COLUMN_SLOTS, type = DT.number, align = DG.aligns.right },
    { key = "gain", label = L.COLUMN_GAIN, type = DT.number, align = DG.aligns.right },
    {
        key = "group",
        label = L.COLUMN_GROUP,
        type = DT.enum,
        choices = Choices(Addon.groups, Addon.GROUP_ORDER, "GROUP_"),
    },
    {
        key = "source",
        label = L.COLUMN_SOURCE,
        type = DT.enum,
        choices = Choices(Addon.sources, Addon.SOURCE_ORDER, "SOURCE_"),
    },
    { key = "tier", label = L.COLUMN_TIER, type = DT.enum, choices = Choices(Addon.tiers, Addon.TIER_ORDER, "TIER_") },
    { key = "level", label = L.COLUMN_LEVEL, type = DT.number, align = DG.aligns.right },
    { key = "where", label = L.COLUMN_WHERE },
    { key = "vendor", label = L.COLUMN_VENDOR, type = DT.number, align = DG.aligns.right, text = MoneyText("vendor") },
    {
        key = "auction",
        label = L.COLUMN_AUCTION,
        type = DT.number,
        align = DG.aligns.right,
        text = MoneyText("auction"),
    },
    {
        key = "perSlot",
        label = L.COLUMN_PER_SLOT,
        type = DT.number,
        align = DG.aligns.right,
        text = MoneyText("perSlot"),
    },
}
-- The grid's columns: a fixed width, or a share of the room left (weight).
---@type { key: string, width?: number, weight?: number }[]
local WIDTHS = {
    { key = "bag", weight = 2 },
    { key = "slots", width = 44 },
    { key = "gain", width = 40 },
    { key = "group", width = 64 },
    { key = "source", width = 90 },
    { key = "tier", width = 64 },
    { key = "level", width = 44 },
    { key = "where", weight = 2 },
    { key = "vendor", width = 70 },
    { key = "auction", width = 70 },
    { key = "perSlot", width = 64 },
}

---Keeps the window's place and size in the profile.
---@param frame Frame
local function SavePlace(frame)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    local width, height = frame:GetSize()
    Addon.db.profile.window =
        { point = point, relativePoint = relativePoint, x = x, y = y, width = width, height = height }
end

---@param frame Frame
local function StopMoving(frame)
    frame:StopMovingOrSizing()
    SavePlace(frame)
end

---A row clicked: the link in chat with Shift, else the way there.
---@param row AddonRow
function Addon:RowClicked(row)
    if IsShiftKeyDown() then
        local _, link = C_Item.GetItemInfo(row.item)
        if link then ChatFrameUtil.InsertLink(link) end
        return
    end
    self:Route(row)
end

---Makes the window.
---@return AddonWindow
function Addon:CreateWindow()
    local profile = self.db.profile
    local frame = CreateFrame("Frame", Addon.Global("Window"), UIParent, "BackdropTemplate")
    DG.SkinMixin:Backdrop(frame)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)
    frame:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    frame:SetScript("OnMouseUp", StopMoving)
    tinsert(UISpecialFrames, frame:GetName())
    ---@type AddonPlace?
    local place = profile.window
    frame:ClearAllPoints()
    if place then
        frame:SetPoint(place.point, UIParent, place.relativePoint, place.x, place.y)
        frame:SetSize(place.width, place.height)
    else
        frame:SetPoint("CENTER")
        frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText(L.TITLE)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        frame:Hide()
    end)
    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        StopMoving(frame)
    end)

    local view = DG:NewSchema(COLUMNS):NewView()
    if profile.filter then view:SetFilterModel(profile.filter) end
    view:SetSort(profile.sort or {})
    view:RegisterCallback(DG.events.FilterChanged, function(_, changed)
        profile.filter = changed:GetFilterModel()
    end, self)
    view:RegisterCallback(DG.events.SortChanged, function(_, changed)
        profile.sort = changed:GetSort()
    end, self)
    local box = DG:CreateFilterBox(frame, view)
    box:SetPoint("TOPLEFT", 10, -32)
    box:SetPoint("TOPRIGHT", -10, -32)
    local grid = DG:CreateGrid(frame, view, nil, {
        ---@param _ LibDataGridGridMixin
        ---@param row AddonRow
        OnRowClick = function(_, row)
            self:RowClicked(row)
        end,
    })
    grid:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -6)
    grid:SetPoint("BOTTOMRIGHT", -10, 22)
    for _, column in ipairs(WIDTHS) do
        if column.width then
            grid:AddFixedWidthColumn(column.key, column.width)
        else
            grid:AddFillColumn(column.key, column.weight)
        end
    end
    local empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER", grid, "CENTER")
    empty:SetText(L.NONE)
    frame:SetScript("OnShow", function()
        self:UpdateWindow()
    end)
    return { frame = frame, view = view, box = box, grid = grid, empty = empty, close = close, grip = grip }
end

---Shows the window, made the first time, with the list worked out (by its OnShow when it was
---hidden; a frame just made already shows).
function Addon:ShowWindow()
    self.window = self.window or self:CreateWindow()
    local frame = self.window.frame
    if frame:IsShown() then
        self:UpdateWindow()
    else
        frame:Show()
    end
end

---Shows the window, or hides it when it shows.
function Addon:ToggleWindow()
    if self.window and self.window.frame:IsShown() then
        self.window.frame:Hide()
    else
        self:ShowWindow()
    end
end

---Works the list out again into the grid, while the window shows.
function Addon:UpdateWindow()
    local window = self.window
    if not window or not window.frame:IsShown() then return end
    local rows = self:Upgrades()
    window.grid:SetRows(rows)
    window.empty:SetShown(#rows == 0)
end
