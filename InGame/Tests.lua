--@debug@
-- In-game tests, run by WoWUnit at login in a copy straight from the repository: each checks an
-- assumption tests/wow.lua makes about the client (README > Development). A red one means the
-- busted specs on that point test a fiction.
local Unit = WoWUnit
if not Unit then return end
local AreEqual, IsTrue, Exists = Unit.AreEqual, Unit.IsTrue, Unit.Exists
local Tests = Unit((...), "PLAYER_LOGIN")

function Tests:ContainerApi()
    Exists(C_Container.GetContainerNumSlots)
    Exists(C_Container.GetContainerNumFreeSlots)
    Exists(C_Container.ContainerIDToInventoryID)
    Exists(C_Container.GetContainerItemID)
end

function Tests:ReagentSlotIsBagFive()
    AreEqual(5, Enum.BagIndex.ReagentBag)
end

function Tests:BackpackIsAPlainBag()
    local _, family = C_Container.GetContainerNumFreeSlots(0)
    AreEqual(0, family)
end

function Tests:ItemClasses()
    AreEqual(1, Enum.ItemClass.Container)
    AreEqual(11, Enum.ItemClass.Quiver)
end

function Tests:SkillLines()
    Exists(C_SkillInfo.GetNumSkillLines)
    Exists(C_SkillInfo.GetSkillLineInfo)
    IsTrue(C_SkillInfo.GetNumSkillLines() >= 0)
end

function Tests:TooltipAndChat()
    Exists(TooltipDataProcessor)
    Exists(ChatFrameUtil and ChatFrameUtil.InsertLink)
    Exists(C_CurrencyInfo.GetCoinTextureString)
end

function Tests:PlayerLevelIsANumber()
    IsTrue(type(UnitLevel("player")) == "number")
end
--@end-debug@
