local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("Broker_FindGroup", "enUS", true)
if not L then return end

L["Tank"] = true
L["Healer"] = true
L["DPS"] = true

L["In Party"] = true
L["Assembling group..."] = true
L["Find Group"] = true

L["Right click to teleport out."] = true
L["Right click to teleport in."] = true
L["Queued for: "] = true
L["Click to open the dungeon finder."] = true
