-- Broker_FindGroup by yess, yessica@fantasymail.de
local ldb = LibStub:GetLibrary("LibDataBroker-1.1",true)
local L = LibStub("AceLocale-3.0"):GetLocale("Broker_FindGroup")
local AceCfgDlg = LibStub("AceConfigDialog-3.0")
local dataobj
local path = "Interface\\AddOns\\Broker_FindGroup\\media\\"
local db = {}
local dropdown
local delay = 1
local counter = 0
local timer = 0
local waittimer = 0
local frame = CreateFrame("Frame")
local dungeonInProgress = false

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

local version = GetAddOnMetadata("Broker_FindGroup","X-Curse-Packaged-Version") or ""
local aceoptions = { 
    name = "Broker FindGroup".." "..version,
    handler = Broker_FindGroup,
	type='group',
	desc = "Broker FindGroup",
    args = {
		hideMinimap = {
			type = 'toggle',
			order = 1,
			name = L["Hide Minimap Button"],
			desc = L["Hide Minimap Button"],
			get = function(info, value)
				return db.hideMinimap
			end,
			set = function(info, value)
				if MiniMapLFGFrame then
					if value then
						MiniMapLFGFrame:Hide()
					else
						MiniMapLFGFrame:Show()
					end
				end
				db.hideMinimap = value
			end,
		},
		locked = {
			type = 'toggle',
			order = 1,
			name = L["Show Instance Name"],
			desc = L["Show Instance Name"],
			get = function(info, value)
				return db.showText
			end,
			set = function(info, value)
				db.showText = value
				frame:UpdateText()
			end,
		},
		showTime = {
			type = 'toggle',
			order = 1,
			name = L["Show Wait Time"],
			desc = L["Show Wait Time"],
			get = function(info, value)
				return db.showTime
			end,
			set = function(info, value)
				db.showTime = value
				frame:UpdateText()
			end,
		},
		display = {
			type = 'select',
			order = 1,
			values = {icons="Icons",text="Text", short="Short Text"},
			name = L["Display Type"],
			desc = L["Display Type"],
			get = function(info, value)
				return db.display
			end,
			set = function(info, value)
				db.display = value
				frame:UpdateText()
			end,
		},
		reportTime = {
			type = 'toggle',
			order = 1,
			name = L["Report Time to Party"],
			desc = L["Report Time to Party"],
			get = function(info, value)
				return db.reportTime
			end,
			set = function(info, value)
				db.reportTime = value
			end,
		},
		playAlarm = {
			type = 'toggle',
			order = 1,
			name = L["Play Alert"],
			desc = L["Play Alert"],
			get = function(info, value)
				return db.playAlarm
			end,
			set = function(info, value)
				db.playAlarm = value
			end,
		},
	}
}

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
	waittimer = waittimer + elapsed
	if counter >= delay then
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
		
		local texdps = "|TInterface\\AddOns\\Broker_FindGroup\\media\\dps.tga:20|t"
		local texdps_grey = "|TInterface\\AddOns\\Broker_FindGroup\\media\\dps_grey.tga:20|t"
		local textank = "|TInterface\\AddOns\\Broker_FindGroup\\media\\tank.tga:24|t"
		local texheal = "|TInterface\\AddOns\\Broker_FindGroup\\media\\heal.tga:20|t"
		if tankNeeds > 0 then
			tankColor = red
			textank = "|TInterface\\AddOns\\Broker_FindGroup\\media\\tank_grey.tga:24|t"
		end
		if healerNeeds > 0  then
			healerColor = red
			texheal = "|TInterface\\AddOns\\Broker_FindGroup\\media\\heal_grey.tga:20|t"
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
		local text = ""
		if db.display == "icons" then
			local dpstext = ""
			for i=1,3 do
				--Debug("i=",i)
				if i <= dpshas then
					dpstext = dpstext..texdps
				else
					dpstext = dpstext..texdps_grey
				end
			end
			text = textank..texheal..dpstext
		elseif db.display == "short" then
			text = string.format("%s%s%s|r/%s%s|r/%s%s %i|r",prefix, tankColor,L["T"], healerColor,L["H"], damageColor,L["D"], dpshas)
		else
			text = string.format("%s%s%s|r/%s%s|r/%s%s %i|r",prefix, tankColor,L["Tank"], healerColor,L["Healer"], damageColor,L["DPS"], dpshas)
		end
		
		if db.showTime then
			dataobj.text = text.." "..L["Time"]..": "..GetTimeString(waittimer).."/"..GetTimeString(myWait).." "
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
			-- not using the lfg at all
			dataobj.text = L["Find Group"]
			waittimer = 0
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
	local mode, submode = GetLFGMode();
	if mode == "lfgparty" or mode == "abandonedInDungeon" then
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
		
		dropdownmenu[#dropdownmenu + 1] = {
				text = L["Teleport In/Out"], 
				func = Teleport,
		}
		dropdownmenu[#dropdownmenu + 1] = {
				text = " ",
				disabled = true
		}
		dropdownmenu[#dropdownmenu + 1] = {
			text = L["Options"],
			func = function() InterfaceOptionsFrame_OpenToCategory("Broker FindGroup") end,
		}	
		EasyMenu(dropdownmenu, dropdown)
	else
		InterfaceOptionsFrame_OpenToCategory("Broker FindGroup")
		--AceCfgDlg:Open("Broker_FindGroup")
	end
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
	
	if (mode == "queued" or mode == "listed") and instanceName then
		tooltip:AddLine(L["Queued for: "]..instanceName )
		tooltip:AddLine(" ")
		tooltip:AddDoubleLine(L["Waiting for:"],GetTimeString(waittimer),1,1,1)
		tooltip:AddDoubleLine(L["My estimated wait time:"],GetTimeString(myWait),1,1,1)
		tooltip:AddLine(" ")
		tooltip:AddLine(L["Wait time as:"])
		tooltip:AddDoubleLine(L["DPS"],GetTimeString(damageWait),1,1,1)
		tooltip:AddDoubleLine(L["Healer"],GetTimeString(healerWait),1,1,1)
		tooltip:AddDoubleLine(L["Tank"],GetTimeString(tankWait),1,1,1)
		tooltip:AddLine(" " )
	else
		tooltip:AddLine(L["Click to open the dungeon finder."])
		tooltip:AddLine(L["Right click for options."])
	end
	
	--@debug@
	tooltip:AddLine(" " )
	tooltip:AddLine("Debug:")
	tooltip:AddDoubleLine("instanceType",instanceType)
	tooltip:AddDoubleLine("LFDQueueFrame.type",LFDQueueFrame.type)
	tooltip:AddDoubleLine("GetLFGMode() mode", mode)
	tooltip:AddDoubleLine("GetLFGMode() submode", submode)
	--@end-debug@
	tooltip:Show()
end

function dataobj:OnLeave()
	GameTooltip:Hide()
end

local function OnEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		--Debug("OnEvent", event, ...)
		db = Broker_FindGroupDB or {display="icons",showTime=true,hideMinimap=true,reportTime=true,playAlarm=true}
		Broker_FindGroupDB = db
		LibStub("AceConfig-3.0"):RegisterOptionsTable("Broker_FindGroup", aceoptions)
		AceCfgDlg:AddToBlizOptions("Broker_FindGroup", "Broker FindGroup")
		frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	--elseif event == "LFG_PROPOSAL_UPDATE" then
	--	local proposalExists, typeID, id, name, texture, role, hasResponded, totalEncounters, completedEncounters, numMembers, isLeader = GetLFGProposal();
	--	Debug("typeID=",typeID,"id=",id,"name=",name,"hasResponded=",hasResponded,"totalEncounters=",totalEncounters,"completedEncounters=",completedEncounters)
	--elseif event == "LFG_PROPOSAL_FAILED" then
	elseif event == "LFG_PROPOSAL_SHOW" then
		if db.playAlarm then
			PlaySoundFile("Interface\\AddOns\\Broker_FindGroup\\media\\alert.mp3")
		end
	elseif event == "LFG_PROPOSAL_SUCCEEDED" then
		-- going in or new player
		if not dungeonInProgress then
			timer = 0
			dungeonInProgress = true
		end
		frame:SetScript("OnUpdate", OnUpdate)
	elseif event == "LFG_COMPLETION_REWARD" then
		-- dungeon done (random only)
		frame:SetScript("OnUpdate", nil)
		if db.reportTime then
			SendChatMessage(L["Dungeon completed in"]..": "..GetTimeString(timer),"party",nil,nil)
		end
		dataobj.text = L["Completed in"]..": "..GetTimeString(timer)
		dungeonInProgress = false
	--elseif event == "LFG_BOOT_PROPOSAL_UPDATE" then
	--	local inProgress, didVote, myVote, targetName, totalVotes, bootVotes, timeLeft, reason = GetLFGBootProposal();
	--	Debug(inProgress, didVote, myVote, targetName, totalVotes, bootVotes, timeLeft, reason);
	elseif event == "PARTY_MEMBERS_CHANGED" then
		--leave party
		if GetNumPartyMembers() == 0 then
			dungeonInProgress = false
		end
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
frame:RegisterEvent("PARTY_MEMBERS_CHANGED");
