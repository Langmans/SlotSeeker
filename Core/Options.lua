local _, ns = ...

-- The options: one AceConfig page, in Settings > AddOns and in its own window (/seek options).

---@type Addon
local Addon = ns
local L = Addon.L

---The options table, asked for each time the page draws.
---@return table
function Addon:OptionsTable()
    local profile = self.db.profile
    local options = {
        type = "group",
        name = self.NAME,
        args = {
            tooltip = {
                type = "toggle",
                name = L.OPTION_TOOLTIP,
                desc = L.OPTION_TOOLTIP_DESC,
                width = "full",
                order = 1,
                get = function()
                    return profile.tooltip
                end,
                ---@param _ table AceConfig's info
                ---@param value boolean
                set = function(_, value)
                    profile.tooltip = value
                end,
            },
            open = {
                type = "execute",
                name = L.OPTION_OPEN,
                order = 2,
                func = function()
                    self:ShowWindow()
                end,
            },
        },
    }
    if self.DevOptions then options.args.dev = self:DevOptions() end
    return options
end

function Addon:SetupOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.NAME, function()
        return self:OptionsTable()
    end)
    local dialog = LibStub("AceConfigDialog-3.0")
    dialog:SetDefaultSize(self.NAME, 480, 280)
    dialog:AddToBlizOptions(self.NAME, self.NAME)
end

---Opens the options in their own window.
function Addon:OpenOptions()
    LibStub("AceConfigDialog-3.0"):Open(self.NAME)
end
