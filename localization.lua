
-- CHANGES TO LOCALIZATION SHOULD BE MADE USING http://www.wowace.com/addons/Broker_FindGroup/localization/

local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale("DungeonHelper", "enUS", true)

if L then
	L["End Message"] = true
	L["Start Message"] = true
	L["Sends a message to the party chat at the beginning of the dungeon."] = true
	L["Sends a message to the party chat at the end of the dungeon."] = true
	L["Clear the box to disable this."] = true
	L["hi"] = true
	L["thanks, bb"] = true
	
	L["Show Time"] = true 
	L["You need to have a Data Broker Display to see this Plugin."] = true  
	
	L["Play Invitation Sound"] = true
	L["Play the selected Sound when the group is ready."] = true
	L["Select Sound"] = true
	L["Play Bonus Sound"] = true
	L["Warning: Some of the sounds may depend on other addons."] = true
	L["Dungeon Helper: Bonus available!"] = true
	L["Watch"] = true
	L["Report To Chat"] = true
	L["Watch for Call To Arms (Bonus rewards) availability."] = true
	L["Call To Arms"] = true
	
	L["Hour"] = true
	L["Minute"] = true
	L["Second"] = true
	L["Hours"] = true
	L["Minutes"] = true
	L["Seconds"] = true
	L["Icon Size"] = true
	L["Zandalari"] = true
	L["Cata"] = true
	L["Show Timer Bar"] = true
	L["Remaining"] = true
	L["General"] = true
	L["Data Broker"] = true
	L["Play Alert"] = true
	L["Options"] = true
	L["Display Type"] = true

	L["Report Time to Party"] = true
	L["Dungeon completed in"] = true
	L["Completed in"] = true
	L["Hide Minimap Button"] = true

	L["Show Instance Name"] = true
	L["Short Text"] = true
	L["Teleport In/Out"] = true
	L["T"] = true
	L["H"] = true
	L["D"] = true
	L["Waiting for:"] = true
	L["My estimated wait time:"] = true
	L["Wait time as:"] = true
	L["Time"] = true
	L["Tank"] = true
	L["Healer"] = true
	L["DPS"] = true
	L["In Party"] = true
	L["Find Group"] = true
	L["Queued for: "] = true
	L["Click to open the dungeon finder."] = true
	L["Ctrl-Click or Middle-Click Teleport."] = true
	L["Right-Click for options."] = true
end

local L = AceLocale:NewLocale("DungeonHelper", "deDE")
if L then 
	-- disable default party messages until localization is set
	L["hi"] = ""
	L["Thanks, bb"] = ""
	--@localization(locale="deDE", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="ignore")@
	return
end

local L = AceLocale:NewLocale("DungeonHelper", "frFR")
if L then
	-- disable default party messages until localization is set
	L["hi"] = ""
	L["Thanks, bb"] = ""
	--@localization(locale="frFR", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="ignore")@
	return
end

local L = AceLocale:NewLocale("DungeonHelper", "koKR")
if L then
	-- disable default party messages until localization is set
	L["hi"] = ""
	L["Thanks, bb"] = ""
	--@localization(locale="koKR", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="ignore")@
	return
end

local L = AceLocale:NewLocale("DungeonHelper", "zhTW")
if L then
	-- disable default party messages until localization is set
	L["hi"] = ""
	L["Thanks, bb"] = ""
	--@localization(locale="zhTW", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="ignore")@
	return
end

local L = AceLocale:NewLocale("DungeonHelper", "zhCN")
if L then
	-- disable default party messages until localization is set
	L["hi"] = ""
	L["Thanks, bb"] = ""
	--@localization(locale="zhCN", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="ignore")@
	return
end

local L = AceLocale:NewLocale("DungeonHelper", "ruRU")
if L then
	-- disable default party messages until localization is set
	L["hi"] = ""
	L["Thanks, bb"] = ""
	--@localization(locale="ruRU", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="ignore")@
	return
end

local L = AceLocale:NewLocale("DungeonHelper", "esES")
if L then
	-- disable default party messages until localization is set
	L["hi"] = ""
	L["Thanks, bb"] = ""
	--@localization(locale="esES", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="ignore")@
	return
end

local L = AceLocale:NewLocale("DungeonHelper", "esMX")
if L then
	-- disable default party messages until localization is set
	L["hi"] = ""
	L["Thanks, bb"] = ""
	--@localization(locale="esMX", format="lua_additive_table", handle-subnamespaces="concat", handle-unlocalized="ignore")@
	return
end