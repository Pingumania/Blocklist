
local ADDON_NAME, ns = ...

local L = ns.L
local AceGUI = LibStub("AceGUI-3.0")
local configFrame, popup, blockFrame
local wContainer, wEvent, wGroup
local BL = {}

local C1_WIDTH = 0.35
local C2_WIDTH = 0.59
local C3_WIDTH = 0.06

-- ns.recentPlayers["Trackmania-Blackhand"] = { class = "HUNTER" }
-- ns.recentPlayers["Polymania-Blackhand"] = { class = "MAGE" }
-- ns.recentPlayers["Stabmania-Blackhand"] = { class = "ROGUE" }
-- ns.recentPlayers["Schockmania-Blackhand"] = { class = "SHAMAN" }

local function OnClickHide()
	popup.add = nil
	popup.key = nil
	popup.tbl = nil
	popup:Hide()
	blockFrame:Hide()
	popup.editBox:SetText("")
end

local function OnclickConfirm()
	local note = popup.editBox:GetText()
	if popup.add then
		BlocklistDB[popup.key] = {
			class = popup.tbl.class,
			note = note
		}
	else
		BlocklistDB[popup.key] = nil
	end
	BL.SelectGroup(wContainer, wEvent, wGroup)
	popup.add = nil
	popup.key = nil
	popup.tbl = nil
	popup:Hide()
	blockFrame:Hide()
	popup.editBox:SetText("")
end

do
	popup = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	popup:SetSize(450, 100)
	popup:SetBackdrop({bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark"})
	popup:SetPoint("CENTER", UIParent, "CENTER")
	popup:SetFrameStrata("TOOLTIP")
	popup:Hide()

	local border = CreateFrame("Frame", nil, popup, "DialogBorderDarkTemplate")
	border:SetPoint("TOPLEFT", popup, "TOPLEFT", -5, 5)
	border:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", 5, -5)
	popup.border = border

	local editBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
	editBox:SetSize(400, 60)
	editBox:SetPoint("CENTER", popup, "CENTER", 0, 0)
	editBox:SetScript("OnEscapePressed", OnClickHide)
	editBox:SetScript("OnEnterPressed", OnclickConfirm)
	popup.editBox = editBox

	local text = popup:CreateFontString()
	text:SetFontObject(GameFontNormal)
	text:SetSize(600, 40)
	text:SetPoint("TOP", popup, "TOP", 0, 0)
	popup.text = text

	local confirm = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	confirm:SetSize(96, 22)
	confirm:SetPoint("BOTTOM", popup, "BOTTOM", 0, 8)
	confirm:SetScript("OnClick", OnclickConfirm)
	confirm:SetText(L["Okay"])

	local cancel = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
	cancel:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -3, -3)
	cancel:SetScript("OnClick", OnClickHide)

	blockFrame = CreateFrame("Frame")
	blockFrame:SetFrameStrata("TOOLTIP")
	blockFrame:SetFrameLevel(popup:GetFrameLevel() - 1)
	blockFrame:SetScript("OnEnter", function() end)
	blockFrame:Hide()
end

local function Popup(key, tbl)
	popup.key = key
	popup.tbl = tbl
	blockFrame:SetAllPoints(configFrame.frame)
	blockFrame:Show()
	popup:Show()
end

local function PopupAdd(key, tbl)
	popup.add = true
	popup.editBox:Show()
	local color = RAID_CLASS_COLORS[tbl.class or "PRIEST"]
	popup.text:SetText(L["EnterNote"]..("|cff%.2x%.2x%.2x"):format(color.r*255, color.g*255, color.b*255)..key.."|r.")
	Popup(key, tbl)
end

local function PopupDel(key, tbl)
	popup.add = false
	popup.editBox:Hide()
	local color = RAID_CLASS_COLORS[tbl.class or "PRIEST"]
	popup.text:SetText(L["ConfirmDelete"]..("|cff%.2x%.2x%.2x"):format(color.r*255, color.g*255, color.b*255)..key.."|r?")
	Popup(key, tbl)
end

local function DrawGroup1(container)
	local c1 = AceGUI:Create("Label")
	c1:SetText(L["Name"])
	c1:SetRelativeWidth(C1_WIDTH)
	container:AddChild(c1)

	local c2 = AceGUI:Create("Label")
	c2:SetText(L["Note"])
	c2:SetRelativeWidth(C2_WIDTH)
	container:AddChild(c2)
	
	local heading = AceGUI:Create("Heading")
	heading:SetFullWidth(true)
	container:AddChild(heading)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	scroll:SetLayout("Flow")
	container:AddChild(scroll)

	local list = {}
	local i = 1
	for key, tbl in pairs(BlocklistDB) do
		list[i] = {}
		local color = RAID_CLASS_COLORS[tbl.class or "PRIEST"]

		list[i].name = AceGUI:Create("Label")
		list[i].name:SetText(key)
		list[i].name:SetRelativeWidth(C1_WIDTH)
		list[i].name:SetColor(color.r, color.g, color.b)

		list[i].note = AceGUI:Create("Label")
		list[i].note:SetText(tbl.note or L["NoNote"])
		list[i].note:SetRelativeWidth(C2_WIDTH)
		list[i].note:SetColor(color.r, color.g, color.b)

		list[i].button = AceGUI:Create("Button")
		list[i].button:SetText(L["Remove"])
		list[i].button:SetRelativeWidth(C3_WIDTH)
		list[i].button:SetCallback("OnClick", function(self)
			PopupDel(key, tbl)
		end)

		scroll:AddChild(list[i].name)
		scroll:AddChild(list[i].note)
		scroll:AddChild(list[i].button)

		i = i + 1
	end
end

local function DrawGroup2(container)
	local c1 = AceGUI:Create("Label")
	c1:SetText(L["Name"])
	c1:SetRelativeWidth(C1_WIDTH)
	container:AddChild(c1)

	local c2 = AceGUI:Create("Label")
	c2:SetText(L["AlreadyBlocked"])
	c2:SetRelativeWidth(C2_WIDTH)
	container:AddChild(c2)

	local heading = AceGUI:Create("Heading")
	heading:SetFullWidth(true)
	container:AddChild(heading)
	
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	scroll:SetLayout("Flow")
	container:AddChild(scroll)

	local list = {}
	local i = 1
	for key, tbl in pairs(ns.recentPlayers) do
		list[i] = {}
		local color = RAID_CLASS_COLORS[tbl.class or "PRIEST"]

		list[i].name = AceGUI:Create("Label")
		list[i].name:SetText(key)
		list[i].name:SetRelativeWidth(C1_WIDTH)
		list[i].name:SetColor(color.r, color.g, color.b)

		list[i].note = AceGUI:Create("Label")
		list[i].note:SetRelativeWidth(C2_WIDTH)
		list[i].note:SetColor(color.r, color.g, color.b)
		
		list[i].button = AceGUI:Create("Button")
		list[i].button:SetText(L["Add"])
		list[i].button:SetRelativeWidth(C3_WIDTH)
		list[i].button:SetCallback("OnClick", function(self)
			PopupAdd(key, tbl)
		end)
		
		if BlocklistDB[key] then
			list[i].note:SetText((L["Yes"]))
			list[i].button:SetDisabled(true)
		end

		scroll:AddChild(list[i].name)
		scroll:AddChild(list[i].note)
		scroll:AddChild(list[i].button)

		i = i + 1
	end
end

function BL.SelectGroup(container, event, group)
	wContainer = container
	wEvent = event
	wGroup = group
	container:ReleaseChildren()
	if group == "tab1" then
		DrawGroup1(container)
	elseif group == "tab2" then
		DrawGroup2(container)
	end
end

local function OpenConfig()
	local frame = AceGUI:Create("Frame")
	frame:SetTitle(ADDON_NAME)
	frame:SetStatusText("@project-version@")
	frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		configFrame = nil
	end)
	frame:SetLayout("Fill")
	configFrame = frame

	local tab =  AceGUI:Create("TabGroup")
	tab:SetLayout("Flow")
	tab:SetTabs({{text=L["BlockedPlayers"], value="tab1"}, {text=L["RecentPlayers"], value="tab2"}})
	tab:SetCallback("OnGroupSelected", BL.SelectGroup)
	tab:SelectTab("tab1")

	frame:AddChild(tab)
end

local function SlashHandler(cmd)
	if not configFrame then
		OpenConfig()
	end
end

SLASH_BLOCKLIST1 = "/blocklist"
SlashCmdList["BLOCKLIST"] = function(cmd) SlashHandler(cmd) end