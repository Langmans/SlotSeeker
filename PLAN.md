# SlotSeeker — plan

An addon that answers one question: **where do I get a bigger bag than the smallest one I carry,
at my level, with my professions?** It compares the bags you have equipped (carried, reagent
slot, bank) with every bag that exists on the client and lists the reachable upgrades with their
source: vendor, quest, craft, drop. Targets: WoW: Forever (16001) first, Classic Era later.

No code yet. This file is the plan.

**Name**: SlotSeeker (free on CurseForge on 2026-11-16; Wago and WoWInterface not checked for
this name). Avoids "bag upgrade", which on CurseForge means *gear upgrades in your bags*
(Upgrade Spotter, GearBot, Bag Upgrades, BetterBags Upgrade Glow). Every name the game sees is
built from the folder name, as in Huntsworn.

Nearest existing addon: **Bag Butler** (snazzyatoms, all clients) auto-equips new bags into
empty slots and replaces smaller ones, but it only handles bags you already have and does not
tell you where to get one.

**Own addon**, not a Huntsworn module: bags matter to every class. Huntsworn may later read
it for quivers/ammo pouches through a public message, not the other way round.

Inspiration: Wowhead's Forever guide "Bags & Storage Overview" (2026-11-14). It is a hand-written
list with known errors (its comments: Red Linen Bag is 8 slots not 6, the second Wizbang's
Gunnysack is 8, Light Leather Reagent Bag is Leatherworking, Bottomless Bag 18 vs 20). So the
guide is a checklist, **not** the data source.

## 1. What the player sees

- **Upgrade list**: a LibDataGrid grid in its own resizable window, so filtering and sorting
  come from the library instead of hand-rolled code. One row per candidate bag; a slot-kind
  filter (carried, reagent, ammo/quiver for hunters, soul bag for warlocks, bank) replaces
  separate sections. Columns:

  | Column | Content |
  |---|---|
  | Bag | item link + icon |
  | Slots / `+N` | slots, and the gain over the bag it would replace |
  | Kind | slot kind / family (enum) |
  | Source | vendor, quest, craft, drop, AH |
  | Requirement | level, faction, reputation, Tailoring/Leatherworking skill |
  | Difficulty | tier from §4 (quest/mob level against player level) |
  | Vendor price | buy price at the vendor (from the data table; empty when not sold) |
  | AH price | Auctionator's last-scan price when Auctionator is loaded, else hidden |
  | Price / slot gained | cheapest known price ÷ `+N`, the "best value" column |
  | Route | button for vendors and quest givers (LibGoThere) |

  Default sort is the ranking in §4; the player can re-sort on any column (price per slot, for
  example) and filter with LibDataGrid's BETWEEN on slots or level.
- **Tooltip line** on any bag item, anywhere (bags, AH, loot, chat link, vendor):
  `+4 slots over your smallest bag` / `Not an upgrade` / `Equip this — bag slot empty`.
- **Nudge** once per level-up or login when an upgrade became reachable (e.g. you hit the level
  of a quest that rewards a 10-slot bag, or your Tailoring skill reached a better bag). Off by
  default or behind an option — to decide.
- **Unequipped bag in your bags that beats an equipped one** → highlighted at the top.

## 2. What the client gives us (checked with the API index, flavor forever)

- `C_Container.GetContainerNumSlots(bagIndex)` and `GetContainerNumFreeSlots` (returns
  `bagFamily`) for equipped bags.
- `Enum.BagIndex`: Backpack 0, Bag_1..4 = 1..4, **ReagentBag = 5** (Forever has the reagent slot),
  CharacterBankTab_1..9 = 6..14, Keyring -1.
- `C_Container.ContainerIDToInventoryID` → `GetInventoryItemID("player", invID)` for the bag's
  item ID.
- `C_Item.GetItemFamily(item)` → the bag-family bitmask (quiver, ammo pouch, soul bag, herb,
  enchanting, reagent).
- Slot count of a bag that is **not** equipped: no API; the tooltip text ("16 Slot Bag") or our
  own data table. The data table already has it, so no tooltip parsing.
- Bank bags are only readable while the bank is open → cache per character in SavedVariables.

## 3. Data

Static table per client (`Data\Forever\Bags.lua`, later `Data\Era\Bags.lua`), one row per bag:
`itemID, slots, family, sources[]` where a source is one of
`vendor (npcID, faction)`, `quest (questID, minLevel, questLevel, faction)`,
`craft (profession, skill, spellID)`, `drop (npcID or level range)`, `ah` (tradeable flag).
Prices come from addons that already have them, not from our own data:

- **AH price**: Auctionator's public API, `Auctionator.API.v1.GetAuctionPriceByItemID(callerID,
  itemID)` (in its Forever build: `Source/API/v1/GetAuctionPrice.lua`). It is the de-facto
  standard other addons call. Optional dependency, checked at runtime; without it the column
  hides. The old `GetAuctionBuyout` global is not defined by anything installed on Forever.
- **Vendor buy price**: ReagentRecipeVendorTooltips already has vendor NPCs with prices. Either
  reuse its data/parser output or read it at runtime when RRVT is loaded; no second vendor table.
  The client itself only knows a vendor's price while that vendor is open.
- **Sell price** from `C_Item.GetItemInfo` (`sellPrice`) is a hint only, not a cost.
- **Bags on alts**: Syndicator (installed, used by Baganator) knows other characters' bags; a
  bag an alt has spare can be listed as "on <alt>".

Generated like ReagentRecipeVendorTooltips' data: the local parser with a browser scrape that
respects Wowhead's rate limit, cross-checked against the guide's list. The repo only notes that a
local parser generated it; parser paths stay in the gitignored TODO. RRVT already has vendor
NPC data — see whether its parser can emit the bag rows too instead of a second scraper.

Use fixed-set enums for families and source kinds (`families.quiver`, `sources.vendor`).

## 4. Ranking

For each bag slot kind: the bag to replace is the **smallest equipped** one (empty slot = 0).
A candidate counts when its family fits the slot kind, the player meets level/faction/profession
(or it is tradeable, then it is an AH candidate), and it has more slots.

Sort order:

1. **Difficulty tier** first, so a bag you can get now beats a bigger one you can't do yet:
   doable now → a bit hard → too hard. Bags that aren't quests count as "doable now" once their
   requirement is met.
2. Within a tier: slots (most first), then effort: owned > vendor > quest > own craft > AH > drop.

Quest difficulty uses the **quest level against the player level**, the same bands as the quest
log colours (Blizzard's FrameXML `GetQuestDifficultyColor(level)` in `DifficultyUtil.lua`, a
UI function, not a C_ API — or the same grey-green-yellow-orange-red rule copied as a pure
function so it is testable): yellow and below
is doable now, orange is a bit hard, red is too hard. Too-hard quests stay in the list (greyed,
with the level shown) instead of being hidden, so the player sees what is coming. For a quest
chain the rewarding quest's level counts, and the row notes that a chain leads to it. Drops with
a level range get the same treatment from the mob level. The list re-sorts on `PLAYER_LEVEL_UP`.

## 5. Open questions (for Ruben)

- Other AH addons besides Auctionator worth reading (TSM, Auctioneer) on Forever?
- Era in v1, or Forever only first?

## 6. In-game checks needed (only Ruben)

- Does `GetContainerNumSlots(5)` return the reagent bag size on Forever, and 0 when empty?
- What does `GetItemFamily` return for the Forever reagent bags (general vs. herb vs. mining)?
- Bank bag slot prices in the guide (10 / 1 / 10 / 25 / 50 / 100) look wrong; not needed for the
  addon, but a comment mentions slots 7 and 8 at 200 / 400 gold.
