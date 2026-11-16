---@meta
-- The addon's own types. Not loaded by the client: the .toc does not list this folder. The types
-- carry no addon name (`Addon...`), so a rename leaves them alone.

---The addon object, which is also the namespace the client hands every file; other addons reach
---it through AceAddon. What one file defines and another uses is listed here, so every file
---knows it.
---@class Addon: AceAddon, AceConsole-3.0, AceEvent-3.0
---@field NAME string the folder's name; every name the game sees starts from it
---@field SLASH_ALIAS string the slash command's short name
---@field Global fun(suffix: string): string a global name of the addon's own, NAME first
---@field Readable fun(value: GameValue): boolean not nil and not a secret value
---@field L table<string, string> the client language's strings
---@field db AddonDB
---@field DEFAULTS table the AceDB defaults (Core\Addon.lua)
---@field data AddonData the bags of the client the .toc loads (Data\)
---@field kinds table<string, string> what a bag holds: kinds.quiver is "quiver"
---@field groups { bags: number, reagent: number, ammo: number, soul: number } the slots a bag competes for
---@field GROUP_ORDER string[] the groups' keys in the list's order
---@field sources { owned: number, vendor: number, quest: number, craft: number, auction: number, drop: number } by effort
---@field SOURCE_ORDER string[]
---@field tiers { now: number, hard: number, tooHard: number } how far out of reach
---@field TIER_ORDER string[]
---@field factions { alliance: string, horde: string, both: string } whom a vendor or quest serves
---@field professions { tailoring: number, leatherworking: number, engineering: number } skill line IDs
---@field classes { hunter: number, warlock: number } class IDs with a bag slot of their own
---@field messages { updated: string } public AceEvent messages
---@field leveledTo? number the level PLAYER_LEVEL_UP gave, before UnitLevel has it
---@field window? AddonWindow the list window, once made
---@field DevOptions? fun(self: Addon): table the development box of the options, only in a copy from the repository
---@field LevelTier fun(level: number, playerLevel: number): number
---@field QuestTier fun(level: number, minLevel: number, playerLevel: number): number
---@field BagName fun(itemID: number): string

---Any value the game hands over, before the addon checks it.
---@alias GameValue string|number|boolean|table|nil

---The saved variables (<NAME>DB), through AceDB.
---@class AddonDB: AceDBObject-3.0
---@field profile AddonProfile
---@field global AddonGlobal

---The settings, per AceDB profile.
---@class AddonProfile
---@field tooltip boolean the gain line under bag tooltips
---@field window? AddonPlace the list window's place and size
---@field filter? LibDataGridGroup the list's filter tree
---@field sort? LibDataGridSortKey[] the list's sort

---Where a window sits (relative to UIParent) and its size.
---@class AddonPlace
---@field point FramePoint
---@field relativePoint FramePoint
---@field x number
---@field y number
---@field width number
---@field height number

---The account-wide data.
---@class AddonGlobal
---@field dev? AddonDevData Core\Dev.lua's, in a copy from the repository

---@class AddonDevData
---@field on boolean
---@field shots table<string, true> by kind

---The generated data: bags by item ID, the quests and NPCs they come from.
---@class AddonData
---@field bags table<number, AddonBag>
---@field quests table<number, AddonQuest>
---@field npcs table<number, AddonNpc>

---A bag and where it comes from.
---@class AddonBag
---@field slots number
---@field kind string an Addon.kinds value
---@field level number its item level: a world drop's level
---@field reqclass? number the classes that may use it, a bit per class ID
---@field bop? boolean binds when picked up: never on the auction house
---@field vendors? AddonOffer[]
---@field quests? number[] the quests that reward it
---@field crafts? AddonCraft[]
---@field drops? AddonDrop[] the named creatures that drop it
---@field worldDrop? boolean dropped by many creatures

---@class AddonOffer
---@field npc number
---@field cost number copper

---@class AddonCraft
---@field skill number a skill line ID (Addon.professions)
---@field rank number the skill it needs

---@class AddonDrop
---@field npc number
---@field level number the creature's level

---@class AddonQuest
---@field name string
---@field level number
---@field min number the level to take it
---@field side string an Addon.factions value
---@field giver? number the NPC who gives it

---@class AddonNpc
---@field name string
---@field side string an Addon.factions value
---@field pins table<number, number[]> spawn spots per uiMapID, flattened x1, y1, x2, y2 in map percent

---A row of the upgrade list (Core\Upgrades.lua), kept per bag and refilled.
---@class AddonRow
---@field item number
---@field name string the bag's name when the list was worked out, for its order
---@field slots number
---@field gain number slots over the bag it would replace
---@field group number an Addon.groups value
---@field source? number an Addon.sources value: the easiest
---@field tier? number an Addon.tiers value
---@field level? number the quest's or creature's level
---@field where? string the vendor, quest, craft or creature, worded
---@field quest? number the quest, when the source is one
---@field vendor? number the cheapest vendor's price, copper
---@field auction? number Auctionator's price, copper
---@field perSlot? number the cheaper price per slot gained, copper

---The list window's parts (Core\Window.lua).
---@class AddonWindow
---@field frame Frame
---@field view LibDataGridView
---@field box LibDataGridFilterBoxMixin
---@field grid LibDataGridGridMixin
---@field empty FontString
---@field close Button
---@field grip Button

---What TooltipDataProcessor hands an item post-call.
---@class AddonTooltipData
---@field id GameValue the item ID; secret in some places

---A slash command.
---@class AddonCommand
---@field help string what it does
---@field run fun()
