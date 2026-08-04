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

local function CurrentActivity()
	local instance, instanceType = GetInstanceInfo()

	if instanceType ~= "none" then
		return instance
	end

	return GetRealZoneText()
end

local function IterateGroupMembers()
	if InCombatLockdown() and not inCombat then
		inCombat = true
		ns:RegisterEvent("PLAYER_REGEN_ENABLED", IterateGroupMembers)
		return
	end

	local prefix = IsInRaid() and "raid" or "party"
	local name
	local class
	local realm = GetNormalizedRealmName()
	if not realm then return end

	for i = 1, GetNumGroupMembers() do
		local unit = prefix..i
		name = GetUnitName(unit, true)
		class = UnitClassBase(unit)
		if name and name ~= "Unknown" then
			if not strfind(name, '-') then
				name = name.."-"..realm
			end

			if not recentPlayers[name] then
				recentPlayers[name] = {
					class = class,
					activity = CurrentActivity(),
				}
			end
			if ns.Blocked()[name] and not groupWarning[name] then
				doWarn = true
				groupWarning[name] = {
					class = class,
					note = ns.Blocked()[name].note
				}
			end
		end
	end

	if doWarn then
		Popup(groupWarning)
		doWarn = false
	end

	inCombat = nil
	ns:UnregisterEvent("PLAYER_REGEN_ENABLED", IterateGroupMembers)
end

function ns:OnLoad()
	BlocklistDB = BlocklistDB or {}

	if BlocklistDB.players == nil then
		local players = {}
		for name, entry in pairs(BlocklistDB) do
			players[name] = entry
		end

		BlocklistDB = { players = players }
	end

	BlocklistDB.minimap = BlocklistDB.minimap or {}

	ns.SetupMinimapButton()
end

ns:RegisterEvent("GROUP_JOINED", function()
	groupWarning = {}
end)

ns:RegisterEvent("GROUP_ROSTER_UPDATE", IterateGroupMembers)
ns:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED", IterateGroupMembers)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", IterateGroupMembers)

local broker = LibStub("LibDataBroker-1.1"):NewDataObject(ADDON_NAME, {
	type = "launcher",
	icon = "Interface\\Icons\\Ability_Rogue_Disguise",
	OnClick = function(_, button)
		if button == "LeftButton" then
			ns.Toggle()
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:AddLine(ADDON_NAME)
		tooltip:AddLine(L["MinimapTooltip"], 1, 1, 1)
	end,
})

local icon = LibStub("LibDBIcon-1.0")

function ns.SetupMinimapButton()
	icon:Register(ADDON_NAME, broker, BlocklistDB.minimap)
end

ns:RegisterSlash("/blocklist", "/bl", function()
	ns.Toggle()
end)
