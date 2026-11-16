local _, ns = ...

-- The slash command, NAME in lower case or SLASH_ALIAS (/slotseeker, /seek): on its own it shows or
-- hides the list; the first word picks a command; anything else lists the commands.

---@type Addon
local Addon = ns
local L = Addon.L

---Command word -> what it does and its function; and the words in list order.
---@type table<string, AddonCommand>
local commands = {}
---@type string[]
local order = {}

---@param word string lower case
---@param help string
---@param run fun()
local function AddCommand(word, help, run)
    commands[word] = { help = help, run = run }
    order[#order + 1] = word
end

---Prints every command with what it does.
local function Usage()
    for _, word in ipairs(order) do
        Addon:Print(("/%s %s - %s"):format(Addon.SLASH_ALIAS, word, commands[word].help))
    end
end

AddCommand("toggle", L.HELP_TOGGLE, function()
    Addon:ToggleWindow()
end)
AddCommand("options", L.HELP_OPTIONS, function()
    Addon:OpenOptions()
end)
-- Left out of the list: the bare command and the options' other name.
commands[""] = commands.toggle
commands.config = commands.options

---@param line string
local function OnSlash(line)
    local command = commands[strtrim(line):lower()]
    if command then
        command.run()
    else
        Usage()
    end
end

function Addon:SetupCommands()
    self:RegisterChatCommand(self.NAME:lower(), OnSlash)
    self:RegisterChatCommand(self.SLASH_ALIAS, OnSlash)
end
