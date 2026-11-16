-- English strings, also the fallback for every other client language. Every string has a comment
-- saying where it appears and what each placeholder holds, for translators.
local addonName = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

-- One string per line, however long.
-- stylua: ignore start

-- The window's title.
L.TITLE = "SlotSeeker"
-- The window, when no bag is bigger than what you carry.
L.NONE = "No bigger bag within reach. Nice bags!"

-- The list's column headers.
L.COLUMN_BAG = "Bag"
L.COLUMN_SLOTS = "Slots"
L.COLUMN_GAIN = "Gain"
L.COLUMN_GROUP = "Slot"
L.COLUMN_SOURCE = "Source"
L.COLUMN_TIER = "Reach"
L.COLUMN_LEVEL = "Level"
L.COLUMN_WHERE = "Where"
L.COLUMN_VENDOR = "Vendor"
L.COLUMN_AUCTION = "Auction"
L.COLUMN_PER_SLOT = "Per slot"

-- Which bag slot a bag goes in (the Slot column).
L.GROUP_BAGS = "Bag"
L.GROUP_REAGENT = "Reagent"
L.GROUP_AMMO = "Quiver"
L.GROUP_SOUL = "Soul bag"

-- Where a bag comes from (the Source column).
L.SOURCE_OWNED = "In your bags"
L.SOURCE_VENDOR = "Vendor"
L.SOURCE_QUEST = "Quest"
L.SOURCE_CRAFT = "Craft"
L.SOURCE_AUCTION = "Auction house"
L.SOURCE_DROP = "Drop"

-- How far a bag is out of reach (the Reach column): now, a bit hard (an orange quest), too hard.
L.TIER_NOW = "Now"
L.TIER_HARD = "Hard"
L.TIER_TOO_HARD = "Too hard"

-- The Where column. A quest: its name and level.
L.WHERE_QUEST = "%s (level %d)"
-- A craft: the profession and the skill it needs.
L.WHERE_CRAFT = "%s %d"
-- A drop from a named creature: its name and level.
L.WHERE_DROP = "%s (level %d)"
-- A drop from many creatures, around a level.
L.WORLD_DROP = "World drop (level %d)"
-- A creature or quest the data has no name for; %d is its ID.
L.UNKNOWN = "#%d"

-- The professions that make bags.
L.PROFESSION_TAILORING = "Tailoring"
L.PROFESSION_LEATHERWORKING = "Leatherworking"
L.PROFESSION_ENGINEERING = "Engineering"

-- The item tooltip, under a bag. %d: how many more slots than the bag it would replace.
L.TOOLTIP_GAIN = "+%d slots over your smallest bag"
L.TOOLTIP_GAIN_REAGENT = "+%d slots over your reagent bag"
L.TOOLTIP_GAIN_AMMO = "+%d slots over your quiver"
L.TOOLTIP_GAIN_SOUL = "+%d slots over your soul bag"
-- The item tooltip, under a bag no bigger than the one it would replace.
L.TOOLTIP_NO_GAIN = "Not a bigger bag"

-- Chat, after a click on a row nothing can route to.
L.NO_ROUTE = "No spot to go to for %s."

-- The slash command's list.
L.HELP_TOGGLE = "show or hide the list"
L.HELP_OPTIONS = "open the options"

-- The options page.
L.OPTION_TOOLTIP = "Tooltip line"
L.OPTION_TOOLTIP_DESC = "Under a bag's tooltip, how many slots it gains over the bag it would replace."
L.OPTION_OPEN = "Open the list"
-- stylua: ignore end
