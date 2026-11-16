---@meta
-- WoWUnit (github.com/Jaliborc/WoWUnit), the addon the in-game tests run in: only what
-- InGame\Tests.lua uses.

---A group of tests: each function set on it is a test.
---@class WoWUnitGroup: { [string]: fun(self: WoWUnitGroup) }

---@class WoWUnitLibrary
---@overload fun(name: string, ...: string): WoWUnitGroup
---@field AreEqual fun(expected: GameValue, actual: GameValue)
---@field IsTrue fun(value: GameValue)
---@field IsFalse fun(value: GameValue)
---@field Exists fun(value: GameValue|function)

---@type WoWUnitLibrary?
WoWUnit = nil
