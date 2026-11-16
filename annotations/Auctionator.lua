---@meta
-- Auctionator's public API, as far as the addon calls it (Source/API/v1 in Auctionator).

---@class AuctionatorApiV1
---@field GetAuctionPriceByItemID fun(callerID: string, itemID: number): number?

---@class AuctionatorGlobal
---@field API { v1: AuctionatorApiV1 }

---@type AuctionatorGlobal?
Auctionator = nil
