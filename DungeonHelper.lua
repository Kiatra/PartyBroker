-- DungeonHelper by yess, starfire@fantasymail.de
local LibStub = LibStub
local ldb = LibStub:GetLibrary("LibDataBroker-1.1",true)
local L = LibStub("AceLocale-3.0"):GetLocale("DungeonHelper")
local AceCfgDlg = LibStub("AceConfigDialog-3.0")
local path = "Interface\\AddOns\\DungeonHelper\\media\\"
local db = {}
local candy, porposalBar, dataobj
local delay, counter = 1, 0
local frame = CreateFrame("Frame")
local dungeonInProgress = false
local startTime = 0
local _G, select, string, mod, tostring, type = _G, select, string, mod, tostring, type
local MiniMapLFGFrame, GetLFGQueueStats, LFDSearchStatus, LFDQueueFrame = MiniMapLFGFrame, GetLFGQueueStats, LFDSearchStatus, LFDQueueFrame
local GetTime, TIME_UNKNOWN, SecondsToTime, GetLFGMode, GetLFGRoleShortageRewards = GetTime, TIME_UNKNOWN, SecondsToTime, GetLFGMode, GetLFGRoleShortageRewards
--GLOBALS: strjoin, LFDSearchStatus_Update, 

local function Debug(...)
	 --@debug@
	local s = "Dungeon Helper Debug:"
	for i=1,select("#", ...) do
		local x = select(i, ...)
		s = strjoin(" ",s,tostring(x))
	end
	_G.DEFAULT_CHAT_FRAME:AddMessage(s)
	--@end-debug@
end

local version = GetAddOnMetadata("DungeonHelper","X-Curse-Packaged-Version") or ""
local aceoptions = { 
    name = "Dungeon Helper".." "..version,
    handler = DungeonHelper,
	type='group',
	desc = "Dungeon Helper",
    args = {
		general = {
			inline = true,
			name = L["General"],
			type="group",
			order = 1,
			args={
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
			},
		},
		databroker = {
			inline = true,
			name = L["Data Broker"],
			type="group",
			order = 3,
			args={
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
				instancename = {
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
			},
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
	--timer = timer + elapsed
	if counter >= delay then
		counter = 0
		if db.showTime then 
			frame:UpdateText()
		end
	end
end

function frame:UpdateText()
	local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats();
	if (hasData) then
		frame:SetScript("OnUpdate", OnUpdate)
		local dpshas = 3 - dpsNeeds 
		local text=""
		local green = "|cff00ff00"
		local red = "|cffdd3a00"
		local tankColor = green
		local damageColor = green
		local healerColor = green
		local textank = "|TInterface\\LFGFrame\\LFGRole:18:18:0:0:64:16:32:48:0:16|t"
		local texheal = "|TInterface\\LFGFrame\\LFGRole:18:18:0:0:64:16:48:64:0:16|t"
		local texdps = "|TInterface\\LFGFrame\\LFGRole:18:18:0:0:64:16:16:32:0:16|t"
		local texdps_grey = "|TInterface\\AddOns\\DungeonHelper\\media\\dps_grey.tga:18:18:0:0|t"
		
		if tankNeeds > 0 then
			tankColor = red
			textank = "|TInterface\\AddOns\\DungeonHelper\\media\\tank_grey.tga:18:18:0:0|t"
		end
		if healerNeeds > 0 then
			healerColor = red
			texheal = "|TInterface\\AddOns\\DungeonHelper\\media\\heal_grey.tga:18:18:0:0|t"
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
			--Debug("queuedTime=",queuedTime)
			dataobj.text = text.." "..L["Time"]..": "..GetTimeString(GetTime() - queuedTime).."/"..GetTimeString(myWait).." "
		else
			dataobj.text = text
		end
		--dataobj.OnEnter = MiniMapLFGFrame_OnEnter
	else
		--frame:SetScript("OnUpdate", nil)
		local mode, submode = GetLFGMode();
		if mode == "lfgparty" then
			--frame:SetScript("OnUpdate", OnUpdate)
			dataobj.text = L["In Party"]..": "..GetTimeString(GetTime() - startTime)
		elseif mode == "queued" then
			dataobj.text = L["Assembling group..."]
		else -- not using the LFD at all
			if GetLFGRoleShortageRewards then
				local text = L["Find Group"]
				local dungeonID = LFDQueueFrame.type
				
				--local textank = "|TInterface\\LFGFrame\\LFGRole:18:18:0:0:64:16:32:48:0:16|t"
				--local texheal = "|TInterface\\LFGFrame\\LFGRole:18:18:0:0:64:16:48:64:0:16|t"
				--local texdps = "|TInterface\\LFGFrame\\LFGRole:18:18:0:0:64:16:16:32:0:16|t"
				--/dump GetLFGRoleShortageRewards(LFDQueueFrame.type, 1)
				if ( type(dungeonID) == "number" ) then
					--for i=1, LFG_ROLE_NUM_SHORTAGE_TYPES do
					local eligible, forTank, forHealer, forDamage, itemCount, money, xp = GetLFGRoleShortageRewards(dungeonID, 1)
					if ( forTank ) then
						text = text.." ".."|TInterface\\LFGFrame\\LFGRole:14:14:0:0:64:16:32:48:0:16|t"
					end
					if ( forHealer ) then
						text = text.." ".."|TInterface\\LFGFrame\\LFGRole:14:14:0:0:64:16:48:64:0:16|t"
					end
					if ( forDamage ) then
						text = text.." ".."|TInterface\\LFGFrame\\LFGRole:14:14:0:0:64:16:16:32:0:16|t"
					end
				end
				dataobj.text = text
			else
				dataobj.text = L["Find Group"]
			end
		end
	end
end

local function Teleport()
	if _G.IsInInstance() then
		_G.LFGTeleport(true)
	else
		_G.LFGTeleport(false)
	end
end

local function Onclick(self, button, ...) 
	if button == "RightButton" then
		_G.InterfaceOptionsFrame_OpenToCategory("Dungeon Helper")
	elseif button == "MiddleButton" then
		Teleport()
	else --left click
		if _G.IsControlKeyDown() then
			Teleport()
		else
			_G.LFDMicroButton:GetScript("OnClick")(self, button, ...)
		end
	end
end

local titleWaitFS = LFDSearchStatus:CreateFontString(nil, nil, "GameFontNormal")
--titleWaitFS:SetPoint("BOTTOMLEFT",LFDSearchStatus,"TOPLEFT",120,-135)
titleWaitFS:SetPoint("CENTER",LFDSearchStatusDamage1,0,-55)
titleWaitFS:SetText("Wait time as:")
local dpsWaitFS = LFDSearchStatus:CreateFontString(nil, nil, "GameFontHighlight")
dpsWaitFS:SetPoint("CENTER",titleWaitFS,0,-20)

--post hook LFDSearchStatus_Update
local OrgLFDSearchStatus_Update = LFDSearchStatus_Update
local function MyLFDSearchStatus_Update(...)
	OrgLFDSearchStatus_Update(...)
	LFDSearchStatus:SetHeight(LFDSearchStatus:GetHeight()+40)
	
	local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats()
	_G.LFDSearchStatusTitle:SetText(L["Queued for: "]..instanceName)
	if hasData then
		local test = string.format("|TInterface\\LFGFrame\\LFGRole:18:18:0:2:64:16:32:48:0:16|t %s", tankWait == -1 and TIME_UNKNOWN or SecondsToTime(tankWait, false, false, 1))
		test = test..string.format(" |TInterface\\LFGFrame\\LFGRole:18:18:0:2:64:16:48:64:0:16|t %s", healerWait == -1 and TIME_UNKNOWN or SecondsToTime(healerWait, false, false, 1))			
		test = test..string.format(" |TInterface\\LFGFrame\\LFGRole:18:18:0:2:64:16:16:32:0:16|t %s", damageWait == -1 and TIME_UNKNOWN or SecondsToTime(damageWait, false, false, 1))		
		dpsWaitFS:SetText(test)
	end
end
LFDSearchStatus_Update = MyLFDSearchStatus_Update

LFDSearchStatus._Show = LFDSearchStatus.Show
local function LFDSearchStatus_Show(...)
	LFDSearchStatus:_Show(...)
	LFDSearchStatus:SetHeight(LFDSearchStatus:GetHeight()+40)
end
LFDSearchStatus.Show = LFDSearchStatus_Show

local function OnEnter(anchor)
	local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats();
	local mode, submode = GetLFGMode();
	
	if (mode == "queued" or mode == "listed") and instanceName then
		local LFDSearchStatus = LFDSearchStatus
		LFDSearchStatus:ClearAllPoints()
		LFDSearchStatus:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
		LFDSearchStatus:Show()
	else
		local tooltip = _G.GameTooltip 
		tooltip:SetOwner(anchor, "ANCHOR_NONE")
		tooltip:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
		tooltip:AddLine(L["Click to open the dungeon finder."])
		tooltip:AddLine(L["Ctrl-Click or Middle-Click Teleport."])
		tooltip:AddLine(L["Right-Click for options."])
		tooltip:Show()
	end
end

local function OnLeave()
	LFDSearchStatus:ClearAllPoints()
	LFDSearchStatus:SetPoint("TOPRIGHT", MiniMapLFGFrame, "TOPLEFT")
	LFDSearchStatus:Hide()
	_G.GameTooltip:Hide()
end

dataobj = ldb:NewDataObject("DungeonHelper", {
	type = "data source",
	icon = path.."lfg.tga",
	label = "DungeonHelper",
	text  = "",
	OnClick = Onclick,
	--OnTooltipShow = OnEnter
	OnEnter = OnEnter,
	OnLeave = OnLeave
})

local function OnEvent(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		--Debug("OnEvent", event, ...)
		db = _G.DungeonHelperDB or {display="icons",showTime=true,hideMinimap=false,reportTime=true,playAlarm=true}
		_G.DungeonHelperDB = db
		LibStub("AceConfig-3.0"):RegisterOptionsTable("DungeonHelper", aceoptions)
		AceCfgDlg:AddToBlizOptions("DungeonHelper", "Dungeon Helper")
		frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	--elseif event == "LFG_PROPOSAL_UPDATE" then
	elseif event == "LFG_PROPOSAL_FAILED" then
		porposalBar:Stop()
	--elseif event == "LFG_BOOT_PROPOSAL_UPDATE" then
	elseif event == "LFG_PROPOSAL_SHOW" then
		local candy = candy or LibStub("LibCandyBar-3.0")
		porposalBar = candy:New("Interface\\AddOns\\ChocolateBar\\pics\\DarkBottom", _G.LFDDungeonReadyPopup:GetWidth()-5, 14)
		porposalBar:SetPoint("CENTER",0,120)
		--porposalBar:SetStrata("FULLSCREEN_DIALOG")
		porposalBar:SetColor(1, 0, 0, 1)
		porposalBar:SetLabel(L["Remaining"].."...")
		porposalBar:SetDuration(40)
		--mybar:AddUpdateFunction( function(bar) Debug(bar.remaining) end )
		porposalBar:Start()
		if db.playAlarm then
			_G.PlaySoundFile("Interface\\AddOns\\DungeonHelper\\media\\alert.mp3","Master")
		end
	elseif event == "LFG_PROPOSAL_SUCCEEDED" then
		porposalBar:Stop()
		-- going in or new player
		if not dungeonInProgress then
			--timer = 0
			startTime = GetTime()
			dungeonInProgress = true
		end
		frame:SetScript("OnUpdate", OnUpdate)
	elseif event == "LFG_COMPLETION_REWARD" then
		-- dungeon done (random only)
		frame:SetScript("OnUpdate", nil)
		local dur = GetTime() - startTime
		if db.reportTime and dur > 0 then
			_G.SendChatMessage(L["Dungeon completed in"]..": "..GetTimeString(dur),"party",nil,nil)
		end
		dataobj.text = L["Completed in"]..": "..GetTimeString(dur)
		dungeonInProgress = false
	
	elseif event == "PARTY_MEMBERS_CHANGED" then
		--leave party
		if _G.GetNumPartyMembers() == 0 then
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
