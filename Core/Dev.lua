--@debug@
local _, ns = ...

-- Screenshots for development: the first time each kind of moment from the in-game checks
-- happens (the window, the window with nothing bigger, a tooltip line, a route, the options), a
-- grey chat line says which, then one screenshot. It hooks in like any other addon could. The
-- whole file is a --@debug@ block, so only a copy straight from the repository has it; off until
-- switched on, English only (README > Screenshots while testing in game).

---@type Addon
local Addon = ns

local SHOT_DELAY = 0.3 -- seconds for the game to draw what changed before the screenshot
local SHOT_GAP = 2 -- seconds at least between two screenshots
local lastShot = -SHOT_GAP
-- The kinds noticed in the moment being looked at, for one screenshot together.
---@type string[]
local pending = {}

---The saved development data, made on first use.
---@return AddonDevData
local function Dev()
    local global = Addon.db.global
    global.dev = global.dev or { on = false, shots = {} }
    return global.dev
end

---The screenshot itself. C_Timer.After takes only a Lua function, not the client's Screenshot.
local function TakeScreenshot()
    Screenshot()
end

---Notes a kind for this moment's screenshot, when switched on and not shot yet.
---@param kind string
local function Notice(kind)
    local dev = Dev()
    if not dev.on or dev.shots[kind] then return end
    for _, noticed in ipairs(pending) do
        if noticed == kind then return end
    end
    pending[#pending + 1] = kind
end

---One screenshot for the kinds noticed, each said in chat first. Within SHOT_GAP of the last one
---there is none, and the kinds stay unmarked, so they are shot the next time.
local function Flush()
    if #pending == 0 then return end
    if GetTime() - lastShot < SHOT_GAP then
        wipe(pending)
        return
    end
    local shots = Dev().shots
    for _, kind in ipairs(pending) do
        shots[kind] = true
        print("|cff888888[" .. Addon.NAME .. " dev] " .. kind .. "|r")
    end
    wipe(pending)
    lastShot = GetTime()
    C_Timer.After(SHOT_DELAY, TakeScreenshot)
end

---@param self Addon
hooksecurefunc(Addon, "UpdateWindow", function(self)
    local window = self.window
    if not window or not window.frame:IsShown() then return end
    Notice("window")
    if window.empty:IsShown() then Notice("window: nothing bigger") end
    Flush()
end)

---@param self Addon
---@param _ GameTooltip
---@param data AddonTooltipData?
hooksecurefunc(Addon, "AddGainLine", function(self, _, data)
    local itemID = data and data.id
    if not self.db.profile.tooltip or not self.Readable(itemID) then return end
    local gain = self:Gain(itemID --[[@as number]])
    if not gain then return end
    Notice(gain > 0 and "tooltip: gain" or "tooltip: no gain")
    Flush()
end)

hooksecurefunc(Addon, "Route", function()
    Notice("route")
    Flush()
end)

hooksecurefunc(Addon, "OpenOptions", function()
    if not LibStub("AceConfigDialog-3.0").OpenFrames[Addon.NAME] then return end
    Notice("options window")
    Flush()
end)

---The switch and the forget button, a box on the options page.
---@return table
function Addon:DevOptions()
    return {
        type = "group",
        inline = true,
        name = "Development",
        order = 100,
        args = {
            on = {
                type = "toggle",
                name = "Dev screenshots",
                desc = "A screenshot the first time each kind of moment from the in-game checks happens. Repository copies only.",
                order = 1,
                get = function()
                    return Dev().on
                end,
                ---@param _ table AceConfig's info
                ---@param value boolean
                set = function(_, value)
                    Dev().on = value
                end,
            },
            forget = {
                type = "execute",
                name = "Forget the screenshots taken",
                order = 2,
                func = function()
                    wipe(Dev().shots)
                end,
            },
        },
    }
end
--@end-debug@
