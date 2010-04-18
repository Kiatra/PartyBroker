-- Broker_FindGroup by yess, yessica@fantasymail.de
local ldb = LibStub:GetLibrary("LibDataBroker-1.1",true)
local L = LibStub("AceLocale-3.0"):GetLocale("Broker_FindGroup")
local dataobj
local path = "Interface\\AddOns\\Broker_FindGroup\\media\\"
local db = {}
local dropdown
local delay = 1
local counter = 0
local timer = 0
local frame = CreateFrame("Frame")
local laststatus = ""

local function Debug(...)
	 --@debug@
	local s = "Broker_FindGroup Debug:"
	for i=1,select("#", ...) do
		local x = select(i, ...)
		s = strjoin(" ",s,tostring(x))
	end
	DEFAULT_CHAT_FRAME:AddMessage(s)
	--@end-debug@
end

local function GetTimeString(seconds)
	if seconds > 0 then
		local min = (seconds / 60)
		local sec = mod(seconds, 60)
		if( sec < 10) then
			return string.format("%i:0%i", min, sec)
		end
		return string.format("%i:%i", min, sec)
	else
		return "-"
	end
end

local function OnUpdate(self, elapsed)
	counter = counter + elapsed
	timer = timer + elapsed
	if counter >= delay then
		--timer = timer + 1
		counter = 0
		if db.showTime then 
			frame:UpdateText()
		end
	end
end

function frame:UpdateText()
	local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait = GetLFGQueueStats();
	if (hasData) then
		frame:SetScript("OnUpdate", OnUpdate)
		local dpshas = 3 - dpsNeeds 
		local text=""
		local green = "|cff00ff00"
		local red = "|cffdd3a00"
		local tankColor = green
		local damageColor = green
		local healerColor = green
		if tankNeeds > 0 then
			tankColor = red
		end
		if healerNeeds > 0  then
			healerColor = red
		end
		if dpsNeeds > 0 then
			damageColor = red
		end
		if instanceType == 261 then
			instanceName = "Normal"
		elseif instanceType == 262 then
			instanceName = "Heroic"
		else
			--instanceName = "Custom"
		end
		local prefix = db and db.showText and instanceName and instanceName..": " or ""
		--[[
		if db.showText then 
			prefix = instanceName
		end
		--]]
		local text = ""
		if db.shortText then
			text = string.format("%s%s%s|r/%s%s|r/%s%s %i|r",prefix, tankColor,L["T"], healerColor,L["H"], damageColor,L["D"], dpshas)
		else
			text = string.format("%s%s%s|r/%s%s|r/%s%s %i|r",prefix, tankColor,L["Tank"], healerColor,L["Healer"], damageColor,L["DPS"], dpshas)
		end
		
		if db.showTime then
			dataobj.text = text.." "..L["Time"]..": "..GetTimeString(timer).."/"..GetTimeString(myWait).." "
		else
			dataobj.text = text
		end
		--dataobj.OnEnter = MiniMapLFGFrame_OnEnter
	else
		--frame:SetScript("OnUpdate", nil)
		local mode, submode = GetLFGMode();
		if mode == "lfgparty" then
			--frame:SetScript("OnUpdate", OnUpdate)
			dataobj.text = L["In Party"]..": "..GetTimeString(timer)
		elseif mode == "queued" then
			dataobj.text = L["Assembling group..."]
		else
			local dps = "|TInterface\\AddOns\\Broker_FindGroup\\media\\dps.tga:20|t"
			local tank = "|TInterface\\AddOns\\Broker_FindGroup\\media\\tank.tga:24|t"
			local heal = "|TInterface\\AddOns\\Broker_FindGroup\\media\\heal.tga:20|t"
			dataobj.text = L["Find Group"]
			timer = 0
		end
	end
end

local function Teleport()
	if ( IsInLFGDungeon() ) then
		LFGTeleport(true)
	elseif ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) then
		LFGTeleport(false)
	end
end

local dropdownmenu
local function OpenMenu(parent)
	GameTooltip:Hide()
	local mode, submode = GetLFGMode()
	
	if not dropdown then
		dropdown = CreateFrame("Frame", "EMPDropDown", nil, "UIDropDownMenuTemplate")
		dropdown.xOffset = 0
		dropdown.yOffset = 0
		dropdown.point = "TOPLEFT"
		dropdown.relativePoint = "BOTTOMLEFT"
		dropdown.displayMode = "MENU"
	end
	
	dropdown.relativeTo = parent
	dropdownmenu = {}
	if mode == "lfgparty" or mode == "abandonedInDungeon" then
		dropdownmenu[#dropdownmenu + 1] = {
				text = L["Teleport In/Out"], 
				func = Teleport,
		}
		dropdownmenu[#dropdownmenu + 1] = {
				text = " ",
				disabled = true
		}
	end
	dropdownmenu[#dropdownmenu + 1] = {
			text = L["Show Instance Name"], 
			checked = db.showText,
			func = function() db.showText = not db.showText; frame:UpdateText() end,
	} 
	dropdownmenu[#dropdownmenu + 1] = {
			text = L["Show Wait Time"],
			checked = db.showTime,
			func = function() db.showTime = not db.showTime; frame:UpdateText() end,
	}
	dropdownmenu[#dropdownmenu + 1] = {
			text = L["Short Text"],
			checked = db.shortText,
			func = function() db.shortText = not db.shortText; frame:UpdateText() end,
	}
	dropdownmenu[#dropdownmenu + 1] = {
			text = L["Report Time to Party"],
			checked = db.reportTime,
			func = function() db.reportTime = not db.reportTime; Debug("db.reportTime:", db.reportTime) end,
	}
	dropdownmenu[#dropdownmenu + 1] = {
			text = L["Hide Minimap Button"],
			checked = db.hideMinimap,
			func = function() 
				db.hideMinimap = not db.hideMinimap 
				if MiniMapLFGFrame then
					if db.hideMinimap then
						MiniMapLFGFrame:Hide()
					else
						MiniMapLFGFrame:Show()
					end
				end
			end,
	}
	EasyMenu(dropdownmenu, dropdown)
end

local function Onclick(self, button, ...) 
	if button == "RightButton" then
		if IsControlKeyDown() then
			-- teleport
			if ( IsInLFGDungeon() ) then
					LFGTeleport(true)
			elseif ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) then
					LFGTeleport(false)
			--[[
			else -- or join/leave
				local mode, submode = GetLFGMode();
				if not mode then
					LFDQueueFrameFindGroupButton:GetScript("OnClick")(self, button, ...)
				elseif mode == "queued" or mode == "listed" then
					LeaveLFG()
				end
			--]]
			end
		else
			OpenMenu(self)
		end
	else
		LFDMicroButton:GetScript("OnClick")(self, button, ...) 	
	end
end

dataobj = ldb:NewDataObject("Broker_FindGroup", {
	type = "data source",
	icon = path.."lfg.tga",
	label = "FindGroup",
	text  = "",
	OnClick = Onclick
})

function dataobj:OnEnter()
	local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait = GetLFGQueueStats();
	local mode, submode = GetLFGMode();
	local tooltip = GameTooltip 
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	--dataobj.OnTooltipShow(GameTooltip)
	
	if (mode == "queued" or mode == "listed") and instanceName then
		tooltip:AddLine(L["Queued for: "]..instanceName )
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(L["Waiting for:"],GetTimeString(timer),1,1,1)
		tooltip:AddDoubleLine(L["My estimated wait time:"],GetTimeString(myWait),1,1,1)
		tooltip:AddLine(" ")
		--yTooltip:AddDoubleLine("Left", "Right", 1,0,0, 0,0,1);
		tooltip:AddLine(L["Wait time as:"])
		tooltip:AddDoubleLine(L["DPS"],GetTimeString(damageWait),1,1,1)
		tooltip:AddDoubleLine(L["Healer"],GetTimeString(healerWait),1,1,1)
		tooltip:AddDoubleLine(L["Tank"],GetTimeString(tankWait),1,1,1)
		tooltip:AddLine(" " )
		--tooltip:AddDoubleLine("Average wait time:",GetTimeString(averageWait),1,1,1)
	else
		tooltip:AddLine(L["Click to open the dungeon finder."])
		tooltip:AddLine(L["Right click for options."])
	end
	
	--@debug@
	tooltip:AddLine(" " )
	tooltip:AddLine("Debug:")
	tooltip:AddDoubleLine("instanceType",instanceType)
	tooltip:AddDoubleLine("LFDQueueFrame.type",LFDQueueFrame.type)
	--UIDropDownMenu_SetSelectedValue(LFDQueueFrameTypeDropDown, LFDQueueFrame.type);
	tooltip:AddDoubleLine("GetLFGMode() mode", mode)
	tooltip:AddDoubleLine("GetLFGMode() submode", submode)
	--@end-debug@
	tooltip:Show()
end

function dataobj:OnLeave()
	GameTooltip:Hide()
end

local function OnEvent(self, event, ...)
	--DEFAULT_CHAT_FRAME:AddMessage(event)
	Debug("OnEvent", event)
	if event == "PLAYER_ENTERING_WORLD" then
		Debug("OnEvent", event, ...)
		db = Broker_FindGroupDB or {showText=true,showTime=true,hideMinimap=true,reportTime=true}
		Broker_FindGroupDB = db
		frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	elseif event == "LFG_PROPOSAL_SUCCEEDED" then
		if laststatus == "complete" then
			timer = 0
		end
		frame:SetScript("OnUpdate", OnUpdate)
		Debug("OnUpdate", OnUpdate)
	elseif event == "LFG_COMPLETION_REWARD" then
		frame:SetScript("OnUpdate", nil)
		Debug("db.reportTime:", db.reportTime)
		if db.reportTime then
			SendChatMessage("[Broker_FindGroup] "..L["Dungeon completed in"]..": "..GetTimeString(timer),"party",nil,nil)
		end
		dataobj.text = L["Completed in"]..": "..GetTimeString(timer)
		laststatus = "complete"
	end
	frame:UpdateText()
	if MiniMapLFGFrame and db.hideMinimap then
		MiniMapLFGFrame:Hide()
	end
end

frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
frame:RegisterEvent("LFG_PROPOSAL_UPDATE");
frame:RegisterEvent("LFG_PROPOSAL_SHOW");
frame:RegisterEvent("LFG_PROPOSAL_FAILED");
frame:RegisterEvent("LFG_PROPOSAL_SUCCEEDED");
frame:RegisterEvent("LFG_UPDATE");
frame:RegisterEvent("LFG_ROLE_CHECK_SHOW");
frame:RegisterEvent("LFG_ROLE_CHECK_HIDE");
frame:RegisterEvent("LFG_BOOT_PROPOSAL_UPDATE");
frame:RegisterEvent("LFG_ROLE_UPDATE");
frame:RegisterEvent("LFG_UPDATE_RANDOM_INFO");
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("LFG_COMPLETION_REWARD");

--frame:RegisterAllEvents()