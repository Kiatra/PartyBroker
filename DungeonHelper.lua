-- DungeonHelper by yess, starfire@fantasymail.de
local LibStub = LibStub
local DungeonHelper = LibStub("AceAddon-3.0"):NewAddon("DungeonHelper", "AceConsole-3.0", "AceEvent-3.0")
local ldb = LibStub:GetLibrary("LibDataBroker-1.1",true)
local L = LibStub("AceLocale-3.0"):GetLocale("DungeonHelper")
local LSM = LibStub("LibSharedMedia-3.0")
local acetimer = LibStub("AceTimer-3.0")
local path = "Interface\\AddOns\\DungeonHelper\\media\\"
local db
local candy
local porposalBar, dataobj
local delay, counter = 1, 0
local frame = CreateFrame("Frame")
local dungeonInProgress = false
local startTime = GetTime()

local _G, select, string, mod, floor, format, tostring, type = _G, select, string, mod, floor, format, tostring, type
local MiniMapLFGFrame, GetLFGQueueStats, LFDSearchStatus, LFDQueueFrame, IsInInstance = MiniMapLFGFrame, GetLFGQueueStats, LFDSearchStatus, LFDQueueFrame, IsInInstance
local GetTime, TIME_UNKNOWN, SecondsToTime, GetLFGMode, GetLFGRoleShortageRewards = GetTime, TIME_UNKNOWN, SecondsToTime, GetLFGMode, GetLFGRoleShortageRewards
local TIME_UNIT_DELIMITER, RequestLFDPlayerLockInfo, RequestLFDPartyLockInfo, LFDParentFrame = TIME_UNIT_DELIMITER, RequestLFDPlayerLockInfo, RequestLFDPartyLockInfo, LFDParentFrame

local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime
local formattedText = ""
local texTank, texHeal, texDps, texDpsGrey, texHankGrey, texHealGrey
local _, bonusTimer, firstEnterDungeon
-- save the last status to check for updates
local needZalandariTank, needZalandariHeal, needZalandariDps
local needCataTank, needCataHeal, needCataDps

local function Debug(...)
	 --@debug@
	local s = "Dungeon Helper Debug:"
	for i=1,select("#", ...) do
		local x = select(i, ...)
		s = _G.strjoin(" ",s,tostring(x))
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
	childGroups = "tab",
    args = {
		--[[
		label = {
			order = 0,
			type = "description",
			name = "Version",
		},
		--]]
		general = {
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
					order = 2,
					name = L["Report Time to Party"],
					desc = L["Report Time to Party"],
					get = function(info, value)
						return db.reportTime
					end,
					set = function(info, value)
						db.reportTime = value
					end,
				},
				timerBar = {
					type = 'toggle',
					order = 3,
					name = L["Show Timer Bar"],
					desc = L["Show Timer Bar"],
					get = function(info, value)
						return db.showTimerBar
					end,
					set = function(info, value)
						db.showTimerBar = value
					end,
				},
				playAlarm = {
					type = 'toggle',
					order = 4,
					name = L["Play Invitation Sound"],
					desc = L["Play the selected Sound when the group is ready."],
					get = function(info, value)
						return db.playAlarm
					end,
					set = function(info, value)
						db.playAlarm = value
					end,
				},
				bonusSoundFile = {
					type = 'select',
					dialogControl = 'LSM30_Sound',
					values = AceGUIWidgetLSMlists.sound,
					order = 5,
					name = L["Select Sound"],
					desc = L["Warning: Some of the sounds may depend on other addons."],
					get = function() 
						return db.porposalSoundName
					end,
					set = function(info, value)
						db.porposalSoundFile = LSM:Fetch("sound", value)
						db.porposalSoundName = value
					end,
				},
			},
		},
		bonusWatch = {
			--inline = true,
			name = L["Call To Arms"],
			type="group",
			order = 3,
			args={
				label = {
					order = 0,
					type = "description",
					name = L["Watch for Call To Arms (Bonus rewards) availability."],
				},
				bonusChatAlert = {
					type = 'toggle',
					order = 1,
					name = L["Report To Chat"],
					desc = L["Report To Chat"],
					get = function(info, value)
						return db.bonusChatAlert
					end,
					set = function(info, value)
						db.bonusChatAlert = value
					end,
				},
				bonusSoundAlert = {
					type = 'toggle',
					order = 2,
					name = L["Play Bonus Sound"],
					desc = L["Play Bonus Sound"],
					get = function(info, value)
						return db.bonusSoundAlert
					end,
					set = function(info, value)
						db.bonusSoundAlert = value
					end,
				},
				bonusSoundFile = {
					type = 'select',
					dialogControl = 'LSM30_Sound',
					values = AceGUIWidgetLSMlists.sound,
					order = 3,
					name = L["Select Sound"],
					desc = L["Warning: Some of the sounds may depend on other addons."],
					get = function() 
						return db.bonusSoundName
					end,
					set = function(info, value)
						db.bonusSoundFile = LSM:Fetch("sound", value)
						db.bonusSoundName = value
					end,
				},
				watchCata= {
					inline = true,
					name = function() local name, _, _, _, _, _, _, _ = _G.GetLFGDungeonInfo(301); return L["Watch"].." "..name end,
					type="group",
					order = 3,
					args={
						tank = {
							type = 'toggle',
							order = 1,
							name = L["Tank"],
							desc = L["Tank"],
							get = function(info, value)
								return db.watchCataTank
							end,
							set = function(info, value)
								db.watchCataTank = value
								db.watchCata = db.watchCataTank or db.watchCataHeal or db.watchCataDPS
								RequestLFDPlayerLockInfo()
							end,
						},
						healer = {
							type = 'toggle',
							order = 2,
							name = L["Healer"],
							desc = L["Healer"],
							get = function(info, value)
								return db.watchCataHeal
							end,
							set = function(info, value)
								db.watchCataHeal = value
								db.watchCata = db.watchCataTank or db.watchCataHeal or db.watchCataDPS
								RequestLFDPlayerLockInfo()
							end,
						},
						dps = {
							type = 'toggle',
							order = 3,
							name = L["DPS"],
							desc = L["DPS"],
							get = function(info, value)
								return db.watchCataDPS
							end,
							set = function(info, value)
								db.watchCataDPS = value
								db.watchCata = db.watchCataTank or db.watchCataHeal or db.watchCataDPS
								RequestLFDPlayerLockInfo()
							end,
						},
					},
				},
				watchZandalari = {
					inline = true,
					name = function() local name, _, _, _, _, _, _, _ = _G.GetLFGDungeonInfo(341); return L["Watch"].." "..name end,
					type="group",
					order = 3,
					args={
						tank = {
							type = 'toggle',
							order = 1,
							name = L["Tank"],
							desc = L["Tank"],
							get = function(info, value)
								return db.watchZandalariTank
							end,
							set = function(info, value)
								db.watchZandalariTank = value
								db.watchZandalari = db.watchZandalariTank or db.watchZandalariHeal or db.watchZandalariDPS
								RequestLFDPlayerLockInfo()
							end,
						},
						healer = {
							type = 'toggle',
							order = 2,
							name = L["Healer"],
							desc = L["Healer"],
							get = function(info, value)
								return db.watchZandalariHeal
							end,
							set = function(info, value)
								db.watchZandalariHeal = value
								db.watchZandalari = db.watchZandalariTank or db.watchZandalariHeal or db.watchZandalariDPS
								RequestLFDPlayerLockInfo()
							end,
						},
						dps = {
							type = 'toggle',
							order = 3,
							name = L["DPS"],
							desc = L["DPS"],
							get = function(info, value)
								return db.watchZandalariDPS
							end,
							set = function(info, value)
								db.watchZandalariDPS = value
								db.watchZandalari = db.watchZandalariTank or db.watchZandalariHeal or db.watchZandalariDPS
								RequestLFDPlayerLockInfo()
							end,
						},
					},
				},
				--[[
				dungeons= {
					inline = true,
					name = L["Dungeons to Watch"],
					type="group",
					order = 3,
					args={
						watchCata = {
							type = 'toggle',
							order = 2,
							name = function() local name, _, _, _, _, _, _, _ = GetLFGDungeonInfo(301); return name end,
							desc = function() local name, _, _, _, _, _, _, _ = GetLFGDungeonInfo(301); return name end,
							get = function(info, value)
								return db.watchCata
							end,
							set = function(info, value)
								db.watchCata = value
								registerBonusTimer()
								RequestLFDPlayerLockInfo()
							end,
						},
						watchZandalari = {
							type = 'toggle',
							order = 2,
							name = function() local name, _, _, _, _, _, _, _ = GetLFGDungeonInfo(341); return name end,
							desc = function() local name, _, _, _, _, _, _, _ = GetLFGDungeonInfo(341); return name end,
							get = function(info, value)
								return db.watchZandalari
							end,
							set = function(info, value)
								db.watchZandalari = value
								registerBonusTimer()
								RequestLFDPlayerLockInfo()
							end,
						},
					},
				},
				roles = {
					inline = true,
					name = L["Roles to Watch"],
					type="group",
					order = 3,
					args={
						tank = {
							type = 'toggle',
							order = 1,
							name = L["Tank"],
							desc = L["Tank"],
							get = function(info, value)
								return db.watchTank
							end,
							set = function(info, value)
								db.watchTank = value
								RequestLFDPlayerLockInfo()
							end,
						},
						healer = {
							type = 'toggle',
							order = 2,
							name = L["Healer"],
							desc = L["Healer"],
							get = function(info, value)
								return db.watchHeal
							end,
							set = function(info, value)
								db.watchHeal = value
								RequestLFDPlayerLockInfo()
							end,
						},
						dps = {
							type = 'toggle',
							order = 3,
							name = L["DPS"],
							desc = L["DPS"],
							get = function(info, value)
								return db.watchDPS
							end,
							set = function(info, value)
								db.watchDPS = value
								RequestLFDPlayerLockInfo()
							end,
						},
					},
				},
				--]]
			},
		},
		databroker = {
			--inline = true,
			name = L["Data Broker"],
			type="group",
			order = 4,
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
					order = 2,
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
					order = 3,
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
				iconSize = {
					type = 'range',
					disabled = function() return db.display ~= "icons" end,
					order = 4,
					name = L["Icon Size"],
					desc = L["Icon Size"],
					min = 1,
					max = 30,
					step = 1,
					bigStep = 1,
					--isPercent = true,
					get = function(name)
						return db.iconSize
					end,
					set = function(info, value)
						if value > 30 then
							value = 30
						elseif value < 1 then
							value = 1
						end
						db.iconSize = value
						frame:UpdateText()
					end,
				},
			},
		},
	}
}

local function barstopped( callback, bar )
  --print( bar.candybarLabel:GetText(), "stopped")
  Debug("stopped")
  porposalBar = nil
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

local function GetTimeStringLong(seconds)
	local time = "";
	local tempTime;
	if not seconds or seconds < 1 or seconds >= 36000 then
		return "-"
	end
	seconds = floor(seconds);
	if seconds >= 3600 then
		if time ~= "" then time = time..TIME_UNIT_DELIMITER end
		tempTime = floor(seconds / 3600);
		if tempTime > 1 then
			time = tempTime.." "..L["Hours"]
		else
			time = tempTime.." "..L["Hour"]
		end
		seconds = mod(seconds, 3600);
	end
	if seconds >= 60 then
		if time ~= "" then time = time..TIME_UNIT_DELIMITER end
		tempTime = floor(seconds / 60);
		if tempTime > 1 then
			time = time..tempTime.." "..L["Minutes"]
		else
			time = time..tempTime.." "..L["Minute"]
		end
		seconds = mod(seconds, 60);
	end
	if seconds > 0 then
		if time ~= "" then time = time..TIME_UNIT_DELIMITER end
		if seconds > 1 then
			seconds = format("%d", seconds)
			time = time..seconds.." "..L["Seconds"]
		else
			seconds = format("%d", seconds)
			time = time..seconds.." "..L["Second"]
		end
		
	end
	return time;
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

local function bonusAlert()
	if db.bonusSoundAlert then
		_G.PlaySoundFile(db.bonusSoundFile,"Master")
	end
	if db.bonusChatAlert then
		_G.print(L["Dungeon Helper: Bonus available!"])
	end
end

local function updateCallToArms()
	local eligible, forTank, forHealer, forDamage, itemCount, money, xp = GetLFGRoleShortageRewards(301, 1)
	if forTank ~= needCataTank then 
		needCataTank = forTank
		Debug("cata TankChanged")
		if forTank and db.watchCataTank then bonusAlert() end
	end
	if forHealer ~= needCataHeal then 
		needCataHeal = forHealer
		Debug("cata HealChanged")
		if forHeal and db.watchCataHeal then bonusAlert() end
	end
	if forDamage ~= needCataDps then 
		needCataDps = forDamage
		Debug("cata DPSChanged")
		if forDPS and db.watchCataDPS then bonusAlert() end
	end
	
	local eligible, forTank, forHealer, forDamage, itemCount, money, xp = GetLFGRoleShortageRewards(341, 1)
	if forTank ~= needZalandariTank then 
		needZalandariTank = forTank
		Debug("za TankChanged")
		if forTank and db.watchZandalariTank then bonusAlert() end
	end
	if forHealer ~= needZalandariHeal then 
		needZalandariHeal = forHealer
		Debug("za HealChanged")
		if forHealer and db.watchZandalariHeal then bonusAlert() end
	end
	if forDamage ~= needZalandariDPS then 
		needZalandariDPS = forDamage
		Debug("za HealChanged")
		if forDamage and db.watchZandalariDPS then bonusAlert() end
	end
end

function frame:UpdateText()
	--local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats();
	if (hasData) then
		frame:SetScript("OnUpdate", OnUpdate)
		local dpshas = 3 - dpsNeeds 
		local text=""
		local green = "|cff00ff00"
		local red = "|cffdd3a00"
		local tankColor, healerColor, damageColor = green,green,green
		local tmpTank, tmpHeal, tmpDps --intext textures
		
		if tankNeeds > 0 then
			tankColor = red
			tmpTank = "|TInterface\\AddOns\\DungeonHelper\\media\\tank_grey.tga:"..db.iconSize..":"..db.iconSize..":0:0|t"
		else
			tmpTank = texTank
		end
		if healerNeeds > 0 then
			healerColor = red
			tmpHeal = "|TInterface\\AddOns\\DungeonHelper\\media\\heal_grey.tga:"..db.iconSize..":"..db.iconSize..":0:0|t"
		else
			tmpHeal = texHeal
		end
		if dpsNeeds > 0 then damageColor = red end
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
			local dpsText = ""
			for i=1,3 do
				--Debug("i=",i)
				if i <= dpshas then
					dpsText = dpsText..texDps
				else
					dpsText = dpsText..texDpsGrey
				end
			end
			text = prefix..tmpTank..tmpHeal..dpsText
		elseif db.display == "short" then
			text = string.format("%s%s%s|r/%s%s|r/%s%s %i|r",prefix, tankColor,L["T"], healerColor,L["H"], damageColor,L["D"], dpshas)
		else
			text = string.format("%s%s%s|r/%s%s|r/%s%s %i|r",prefix, tankColor,L["Tank"], healerColor,L["Healer"], damageColor,L["DPS"], dpshas)
		end
		
		if db.showTime then
			formattedText = text.." "..L["Time"]..": "..GetTimeString(GetTime() - queuedTime).."/"..GetTimeString(myWait).." "
		else
			formattedText = text
		end
	else
		local mode, submode = GetLFGMode();
		if mode == "lfgparty" then
			--frame:SetScript("OnUpdate", OnUpdate)
			formattedText = L["In Party"]..": "..GetTimeString(GetTime() - startTime)
		elseif mode == "queued" then
			formattedText = _G.ASSEMBLING_GROUP
		else -- not using the LFD at all
			local roles, text = "", ""
			if needCataTank and db.watchCataTank then roles = roles.." "..texTank end
			if needCataHeal and db.watchCataHeal then roles = roles.." "..texHeal end
			if needCataDps and db.watchCataDPS then roles = roles.." "..texDps end
			if roles ~= "" then 
				text = L["Cata"]..":"..roles.." " 
			end
			roles = ""
			if needZalandariTank and db.watchZandalariTank then roles = roles.." "..texTank end
			if needZalandariHeal and db.watchZandalariHeal then roles = roles.." "..texHeal end
			if needZalandariDps and db.watchZandalariDPS  then roles = roles.." "..texDps end
			if roles ~= "" then
				formattedText = text..L["Zandalari"]..":"..roles
			else
				formattedText = L["Find Group"]
			end
		end
	end
	dataobj.text = formattedText
end

local function Teleport()
	if IsInInstance() then
		_G.LFGTeleport(true)
	else
		_G.LFGTeleport(false)
	end
end

local test =1
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
local OrgLFDSearchStatus_Update = _G.LFDSearchStatus_Update
local function MyLFDSearchStatus_Update(...)
	OrgLFDSearchStatus_Update(...)
	--LFDSearchStatus:SetHeight(LFDSearchStatus:GetHeight()+40)
	LFDSearchStatus:SetHeight(210)
	
	local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats()
	_G.LFDSearchStatusTitle:SetText(L["Queued for: "]..instanceName)
	if hasData then
		local test = string.format("|TInterface\\LFGFrame\\LFGRole:18:18:0:2:64:16:32:48:0:16|t %s", tankWait == -1 and TIME_UNKNOWN or SecondsToTime(tankWait, false, false, 1))
		test = test..string.format(" |TInterface\\LFGFrame\\LFGRole:18:18:0:2:64:16:48:64:0:16|t %s", healerWait == -1 and TIME_UNKNOWN or SecondsToTime(healerWait, false, false, 1))			
		test = test..string.format(" |TInterface\\LFGFrame\\LFGRole:18:18:0:2:64:16:16:32:0:16|t %s", damageWait == -1 and TIME_UNKNOWN or SecondsToTime(damageWait, false, false, 1))		
		dpsWaitFS:SetText(test)
	end
end
_G.LFDSearchStatus_Update = MyLFDSearchStatus_Update

LFDSearchStatus._Show = LFDSearchStatus.Show
local function LFDSearchStatus_Show(...)
	LFDSearchStatus:_Show(...)
	--LFDSearchStatus:SetHeight(LFDSearchStatus:GetHeight()+40)
	LFDSearchStatus:SetHeight(210)
end
LFDSearchStatus.Show = LFDSearchStatus_Show

--[[
local LFDQueueFrame_SetType_ORG = LFDQueueFrame_SetType
LFDQueueFrame_SetType = function(value, ...) 
	LFDQueueFrame_SetType_ORG(value, ...)
	frame:UpdateText()
end
--]]

local function OnEnter(anchor)
	local hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats();
	local mode, submode = GetLFGMode();
	
	if (mode == "queued" or mode == "listed") and instanceName then
		local LFDSearchStatus = LFDSearchStatus
		LFDSearchStatus:ClearAllPoints()
		LFDSearchStatus:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
		LFDSearchStatus:SetParent(anchor)
		LFDSearchStatus:SetFrameStrata("FULLSCREEN_DIALOG")
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
	LFDSearchStatus:SetParent(MiniMapLFGFrame)
	LFDSearchStatus:SetFrameStrata("FULLSCREEN_DIALOG")
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
	--Debug("OnEvent", event, ...)
	hasData,  leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, instanceType, instanceName, averageWait, tankWait, healerWait, damageWait, myWait, queuedTime = GetLFGQueueStats();
	if event == "PLAYER_ENTERING_WORLD" then
		if firstEnterDungeon then
			Debug("HI")
			firstEnterDungeon = false
		end
	elseif event == "LFG_PROPOSAL_FAILED" then
		if porposalBar then porposalBar:Stop() end
	elseif event == "LFG_PROPOSAL_SHOW" then
		if db.playAlarm then
			_G.PlaySoundFile(db.porposalSoundFile,"Master")
		end
		Debug(db.showTimerBar,candy)
		if db.showTimerBar and candy then
			porposalBar = candy:New("Interface\\AddOns\\ChocolateBar\\pics\\DarkBottom", _G.LFDDungeonReadyPopup:GetWidth()-5, 14)
			porposalBar:SetPoint("CENTER",0,120)
			porposalBar:SetFrameStrata("FULLSCREEN_DIALOG")
			porposalBar:SetColor(1, 0, 0, 1)
			porposalBar:SetLabel(L["Remaining"].."...")
			porposalBar:SetDuration(39)
			porposalBar:Set("anchor",nil)
			porposalBar:Start()
		end
	elseif event == "LFG_PROPOSAL_SUCCEEDED" then
		-- going in or new player
		if porposalBar then porposalBar:Stop() end
		if not dungeonInProgress then
			--timer = 0
			startTime = GetTime()
			dungeonInProgress = true
			firstEnterDungeon = true
		end
		frame:SetScript("OnUpdate", OnUpdate)
	elseif event == "LFG_COMPLETION_REWARD" then
		-- dungeon done (random only)
		--frame:SetScript("OnUpdate", nil)
		local dur = GetTime() - startTime
		if db.reportTime and dur > 0 then
			_G.SendChatMessage(L["Dungeon completed in"]..": "..GetTimeStringLong(dur),"party",nil,nil)
		end
		dataobj.text = L["Completed in"]..": "..GetTimeString(dur)
		dungeonInProgress = false
	elseif event == "PARTY_MEMBERS_CHANGED" then
		--leave party
		if _G.GetNumPartyMembers() < 1 then
			dungeonInProgress = false
		end
	elseif event == "LFG_UPDATE_RANDOM_INFO" then
		updateCallToArms()
	end
	frame:UpdateText()
	if MiniMapLFGFrame and db.hideMinimap then
		MiniMapLFGFrame:Hide()
	end
end

local function registerBonusTimer()
	if db.watchCata or db.watchZalandari then
		bonusTimer = acetimer:ScheduleRepeatingTimer(function()
			if not IsInInstance() then
				if not LFDParentFrame:IsShown() then
					RequestLFDPlayerLockInfo()
					--RequestLFDPartyLockInfo()
				end
			end
		end, 10)
	else
		acetimer:CancelTimer(bonusTimer,true)
	end
end


function DungeonHelper:OnInitialize()
	local oldDB = _G.DungeonHelperDB or {display="icons",showTime=true,hideMinimap=false,reportTime=true,playAlarm=true,showTimerBar=true,iconSize=12}
    local defaults = {
		profile = {
			display=oldDB.display, showTime=oldDB.showTime, hideMinimap=oldDB.hideMinimap, reportTime=oldDB.reportTime, 
			playAlarm=oldDB.playAlarm, showTimerBar=oldDB.showTimerBar, iconSize=12,
			watchCata=true, watchCataTank=true, watchCataHeal=true, watchCataDPS=true,
			watchZandalari=true,watchZandalariTank=true,watchZandalariHeal=true,watchZandalariDPS=true,
			bonusSoundAlert=true,bonusChatAlert=true,porposalSoundName="Red Alert"
		}
	}
	
	self.db = LibStub("AceDB-3.0"):New("DungeonHelperDB", defaults, "Default")
	db = self.db.profile
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("DungeonHelper", aceoptions)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DungeonHelper", "Dungeon Helper")
	
	LSM:Register("sound", "Red Alert","Interface\\AddOns\\DungeonHelper\\media\\alert.mp3")
	LSM:Register("sound", "Blizzard: Alarm Clock 3",  "Sound\\Interface\\AlarmClockWarning3.wav")
	db.bonusSoundFile = LSM:Fetch("sound", db.bonusSoundName) or LSM:Fetch("sound", "Blizzard: Alarm Clock 3")
	db.porposalSoundFile = LSM:Fetch("sound", db.porposalSoundName) or LSM:Fetch("sound", "Red Alert")
	
	texTank = "|TInterface\\LFGFrame\\LFGRole:"..db.iconSize..":"..db.iconSize..":0:0:64:16:32:48:0:16|t"
	texHeal = "|TInterface\\LFGFrame\\LFGRole:"..db.iconSize..":"..db.iconSize..":0:0:64:16:48:64:0:16|t"
	texDps = "|TInterface\\LFGFrame\\LFGRole:"..db.iconSize..":"..db.iconSize..":0:0:64:16:16:32:0:16|t"
	texDpsGrey = "|TInterface\\AddOns\\DungeonHelper\\media\\dps_grey.tga:"..db.iconSize..":"..db.iconSize..":0:0|t"
	texHankGrey = "|TInterface\\AddOns\\DungeonHelper\\media\\tank_grey.tga:"..db.iconSize..":"..db.iconSize..":0:0|t"
	texHealGrey = "|TInterface\\AddOns\\DungeonHelper\\media\\heal_grey.tga:"..db.iconSize..":"..db.iconSize..":0:0|t"
	
	_, needCataTank, needCataHeal, needCataDps, _, _, _ = GetLFGRoleShortageRewards(301, 1)
	_, needZalandariTank, needZalandariHeal, needZalandariDps, _, _, _ = GetLFGRoleShortageRewards(341, 1)
	registerBonusTimer()
end

function DungeonHelper:OnEnable()
	candy = LibStub("LibCandyBar-3.0")
	candy:RegisterCallback("LibCandyBar_Stop", barstopped)
end

frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
frame:RegisterEvent("LFG_PROPOSAL_UPDATE")
frame:RegisterEvent("LFG_BOOT_PROPOSAL_UPDATE")
frame:RegisterEvent("LFG_PROPOSAL_SHOW")
frame:RegisterEvent("LFG_PROPOSAL_FAILED")
frame:RegisterEvent("LFG_PROPOSAL_SUCCEEDED")
frame:RegisterEvent("LFG_UPDATE")
frame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
frame:RegisterEvent("LFG_ROLE_CHECK_HIDE")
frame:RegisterEvent("LFG_ROLE_UPDATE")
frame:RegisterEvent("LFG_UPDATE_RANDOM_INFO")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("LFG_COMPLETION_REWARD")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")