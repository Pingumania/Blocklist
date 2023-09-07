local ADDON_NAME, ns = ...

local L = ns.L
local recentPlayers = {}
local groupWarning = {}
local popup
local doWarn
local inCombat
ns.recentPlayers = recentPlayers

local function OnClickHide()
	popup:Hide()
end

do
	popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	popup:SetSize(450, 80)
	popup:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"})
	popup:SetPoint("CENTER", UIParent, "CENTER")
	popup:SetFrameStrata("TOOLTIP")
	popup:Hide()

	local border = CreateFrame("Frame", nil, popup, "DialogBorderDarkTemplate")
	border:SetPoint("TOPLEFT", popup, "TOPLEFT", -5, 5)
	border:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", 5, -5)
	popup.border = border

	local text = popup:CreateFontString()
	text:SetFontObject(GameFontNormal)
	text:SetSize(400, 40)
	text:SetPoint("TOP", popup, "TOP", 0, 0)
	popup.text = text

	local confirm = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	confirm:SetSize(96, 22)
	confirm:SetPoint("BOTTOM", popup, "BOTTOM", 0, 8)
	confirm:SetScript("OnClick", OnClickHide)
	confirm:SetText(L["Okay"])

	local cancel = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
	cancel:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -3, -3)
	cancel:SetScript("OnClick", OnClickHide)
end

local function Popup(tbl)
	popup.text:SetText(L["FoundPlayers"])

	local prev
	local size = 0
	for key, tbl in pairs(tbl) do
		local text = popup:CreateFontString()
		text:SetSize(400, 10)
		text:SetFontObject(SystemFont_Shadow_Med1)
		if prev then
			text:SetPoint("TOP", prev, "BOTTOM", 0, -2)
		else
			text:SetPoint("TOP", popup.text, "BOTTOM", 0, 0)
		end
		local color = RAID_CLASS_COLORS[tbl.class or "PRIEST"]
		text:SetText(("|cff%.2x%.2x%.2x"):format(color.r*255, color.g*255, color.b*255)..key.."|r"..(tbl.note and " - "..tbl.note or ""))
		prev = text
		size = size + text:GetHeight()
	end

	popup:SetHeight(90 + size)
	popup:Show()
end

local f = CreateFrame("Frame")
local function IterateGroupMembers()
	if InCombatLockdown() and not inCombat then
		inCombat = true
		f:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	local prefix  = IsInRaid() and "raid" or "party"
	local name    = ""
	local class   = ""
	local realm   = GetNormalizedRealmName()

	for i = 1, GetNumGroupMembers() do
		local unit = prefix..i
		name = GetUnitName(unit, true)
		class = UnitClassBase(unit)
		if name and not name:find("-") then
			name = name.."-"..realm
		end
	
		if name then
			if not recentPlayers[name] then
				recentPlayers[name] = {
					class = class
				}
			end
			if BlocklistDB[name] and not groupWarning[name] then
				doWarn = true
				groupWarning[name] = {
					class = class,
					note = BlocklistDB[name].note
				}
			end
		end
	end

	if doWarn then
		Popup(groupWarning)
		doWarn = false
	end

	inCombat = nil
	f:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function f:PLAYER_REGEN_ENABLED()
	IterateGroupMembers()
end

function f:ADDON_LOADED(event, addon)
	if addon == "Blocklist" then
		if not BlocklistDB then
			BlocklistDB = {}
		end
	end
	f:UnregisterEvent("ADDON_LOADED")
end

function f:GROUP_JOINED()
	groupWarning = {}
end

function f:GROUP_ROSTER_UPDATE()
	IterateGroupMembers()
end

function f:PLAYER_ENTERING_WORLD()
	IterateGroupMembers()
end

f:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("GROUP_JOINED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")