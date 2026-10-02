local ADDON_NAME, ns = ...

local L = ns.L

local function ClassColored(name, entry)
	local color = RAID_CLASS_COLORS[entry and entry.class or "PRIEST"]
	return ("|cff%.2x%.2x%.2x%s|r"):format(color.r * 255, color.g * 255, color.b * 255, name)
end

StaticPopupDialogs["BLOCKLIST_ADD"] = {
	text = L["EnterNote"],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = 128,
	editBoxWidth = 350,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(dialog, data)
		ns.Blocked()[data.name] = {
			class = data.entry and data.entry.class,
			note = dialog:GetEditBox():GetText(),
		}
		ns.Refresh()
	end,
	EditBoxOnEnterPressed = function(editBox, data)
		local dialog = editBox:GetParent()
		StaticPopupDialogs["BLOCKLIST_ADD"].OnAccept(dialog, data)
		dialog:Hide()
	end,
	EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
}

StaticPopupDialogs["BLOCKLIST_REMOVE"] = {
	text = L["ConfirmDelete"],
	button1 = ACCEPT,
	button2 = CANCEL,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	showAlert = true,
	OnAccept = function(_, data)
		ns.Blocked()[data.name] = nil
		ns.Refresh()
	end,
}

--[[ ns.ConfirmAdd(_name_, _entry_)
Asks for a note, then puts _name_ on the blocklist.
--]]
function ns.ConfirmAdd(name, entry)
	local dialog = StaticPopup_Show("BLOCKLIST_ADD", ClassColored(name, entry), nil, { name = name, entry = entry })
	if dialog then
		dialog:GetEditBox():SetText(entry and entry.note or "")
	end
end

--[[ ns.ConfirmRemove(_name_, _entry_)
Asks for confirmation, then takes _name_ off the blocklist.
--]]
function ns.ConfirmRemove(name, entry)
	StaticPopup_Show("BLOCKLIST_REMOVE", ClassColored(name, entry), nil, { name = name, entry = entry })
end

local MIN_WIDTH = 420
local MIN_HEIGHT = 300
local ROW_HEIGHT = 28
local ICON_SIZE = 18
local ACTION_SIZE = 20
local RESIZE_SIZE = 12
local NAME_WIDTH = 170
local MEDIA = [[Interface\AddOns\Blocklist\Media\]]
local CHECKMARK = ("|T%scommon-icon-checkmark-small:14:14|t"):format(MEDIA)

-- the list sits this far inside the frame's inset, and each row this far inside the list, so the
-- column headers add both to line up with what is under them
local LIST_INSET = 0
local LIST_INSET_TOP = 1
local ROW_INSET = 8
local COLUMN_GAP = 8

local HEADER_HEIGHT = ROW_HEIGHT
local TAB_BLOCKED = 1
local TAB_RECENT = 2

local frame
local selectedTab = TAB_BLOCKED

--[[ ns.Blocked()
The players on the blocklist, keyed by name.
--]]
function ns.Blocked()
	return BlocklistDB.players
end

--[[ ns.Recent()
The players seen in a group this session, keyed by name.
--]]
function ns.Recent()
	return ns.recentPlayers
end

local function ClassColor(entry)
	return RAID_CLASS_COLORS[entry.class or "PRIEST"]
end

local function SortedEntries(source)
	local names = {}
	for name in pairs(source) do
		table.insert(names, name)
	end

	table.sort(names)
	return names
end

local function Refresh()
	if not (frame and frame:IsShown()) then return end

	local source = selectedTab == TAB_BLOCKED and ns.Blocked() or ns.Recent()
	local provider = CreateDataProvider()
	local shown = 0

	for _, name in ipairs(SortedEntries(source)) do
		shown = shown + 1
		provider:Insert({ name = name, entry = source[name], index = shown })
	end

	frame.ScrollBox:SetDataProvider(provider)

	frame.Empty:SetText(selectedTab == TAB_BLOCKED and L["NoBlockedPlayers"] or L["NoRecentPlayers"])
	frame.Empty:SetShown(shown == 0)
	frame.NoteHeader:SetText(selectedTab == TAB_BLOCKED and L["Note"] or L["Activity"])
end

ns.Refresh = Refresh

local function InitRow(row, data)
	if not row.Name then
		row:SetHeight(ROW_HEIGHT)

		row.Stripe = row:CreateTexture(nil, "BACKGROUND")
		row.Stripe:SetAllPoints()
		row.Stripe:SetColorTexture(1, 1, 1, 0.03)

		row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
		row.Highlight:SetAllPoints()
		row.Highlight:SetColorTexture(1, 1, 1, 0.08)

		row:SetScript("OnEnter", function(self)
			self.Stripe:Hide()

			local blocked = selectedTab == TAB_RECENT and ns.Blocked()[self.name]
			if not blocked then return end

			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(ClassColored(self.name, blocked))
			GameTooltip:AddLine(blocked.note ~= "" and blocked.note or "-", 1, 1, 1, true)
			GameTooltip:Show()
		end)

		row:SetScript("OnLeave", function(self)
			self.Stripe:SetShown(self.striped)
			GameTooltip_Hide()
		end)

		row.Icon = row:CreateTexture(nil, "ARTWORK")
		row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
		row.Icon:SetPoint("LEFT", ROW_INSET, 0)

		row.Name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		row.Name:SetPoint("LEFT", row.Icon, "RIGHT", COLUMN_GAP, 0)
		row.Name:SetJustifyH("LEFT")
		row.Name:SetWidth(NAME_WIDTH)
		row.Name:SetWordWrap(false)

		row.Action = CreateFrame("Button", nil, row)
		row.Action:SetSize(ACTION_SIZE, ACTION_SIZE)
		row.Action:SetPoint("RIGHT", -8, 0)
		row.Action:SetScript("OnClick", function(self)
			if selectedTab == TAB_BLOCKED then
				ns.ConfirmRemove(self.name, self.entry)
			else
				ns.ConfirmAdd(self.name, self.entry)
			end
		end)
		row.Action:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltip)
			GameTooltip:Show()
		end)
		row.Action:SetScript("OnLeave", GameTooltip_Hide)

		row.Action.Icon = row.Action:CreateTexture(nil, "ARTWORK")
		row.Action.Icon:SetAllPoints()

		row.Edit = CreateFrame("Button", nil, row)
		row.Edit:SetSize(ACTION_SIZE, ACTION_SIZE)
		row.Edit:SetPoint("RIGHT", row.Action, "LEFT", -COLUMN_GAP / 2, 0)
		row.Edit:SetScript("OnClick", function(self)
			ns.ConfirmAdd(self.name, self.entry)
		end)
		row.Edit:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["EditNote"])
			GameTooltip:Show()
		end)
		row.Edit:SetScript("OnLeave", GameTooltip_Hide)

		row.Edit.Icon = row.Edit:CreateTexture(nil, "ARTWORK")
		row.Edit.Icon:SetAllPoints()
		row.Edit.Icon:SetTexture(MEDIA .. "common-icon-speak", nil, nil, "TRILINEAR")

		row.Status = row:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		row.Status:SetPoint("RIGHT", row.Action, "LEFT", -COLUMN_GAP, 0)
		row.Status:SetJustifyH("RIGHT")

		row.Note = row:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		row.Note:SetJustifyH("LEFT")
		row.Note:SetWordWrap(false)
	end

	local color = ClassColor(data.entry)

	row.striped = data.index % 2 == 0
	row.Stripe:SetShown(row.striped and not row:IsMouseOver())

	row.Icon:SetTexture(MEDIA .. GetClassAtlas(strlower(data.entry.class or "PRIEST")), nil, nil, "TRILINEAR")

	row.Name:SetText(data.name)
	row.Name:SetTextColor(color.r, color.g, color.b)

	row.name = data.name

	row.Action.name = data.name
	row.Action.entry = data.entry

	row.Edit.name = data.name
	row.Edit.entry = data.entry

	row.Note:ClearAllPoints()
	row.Note:SetPoint("LEFT", row.Name, "RIGHT", COLUMN_GAP, 0)

	if selectedTab == TAB_BLOCKED then
		row.Note:SetText(data.entry.note ~= "" and data.entry.note or "-")
		row.Note:SetPoint("RIGHT", row.Edit, "LEFT", -COLUMN_GAP, 0)
		row.Status:SetText("")
		row.Action.Icon:SetTexture(MEDIA .. "common-icon-redx", nil, nil, "TRILINEAR")
		row.Action.tooltip = L["Remove"]
		row.Action:Show()
		row.Edit:Show()
	else
		local blocked = ns.Blocked()[data.name]
		row.Note:SetText(data.entry.activity or "")
		row.Note:SetPoint("RIGHT", row.Status, "LEFT", -COLUMN_GAP, 0)
		row.Status:SetText(blocked and CHECKMARK or "")
		row.Action.Icon:SetTexture(MEDIA .. "communities-icon-addgroupplus", nil, nil, "TRILINEAR")
		row.Action.tooltip = L["Add"]
		row.Action:SetShown(not blocked)
		row.Edit:Hide()
	end
end

local function SelectTab(tab)
	selectedTab = tab
	PanelTemplates_SetTab(frame, tab)
	Refresh()
end

local function CreateFrames()
	frame = CreateFrame("Frame", "BlocklistFrame", UIParent, "ButtonFrameTemplate")
	frame:SetSize(600, 340)
	frame:SetPoint("CENTER")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetScript("OnShow", Refresh)
	frame:Hide()

	ButtonFrameTemplate_HidePortrait(frame)
	ButtonFrameTemplate_HideButtonBar(frame)
	ButtonFrameTemplate_HideAttic(frame)
	frame.TitleContainer.TitleText:SetText(ADDON_NAME)

	table.insert(UISpecialFrames, "BlocklistFrame")

	frame:SetResizable(true)
	frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT)

	local resize = CreateFrame("Button", nil, frame, "PanelResizeButtonTemplate")
	resize:SetSize(RESIZE_SIZE, RESIZE_SIZE)
	resize:SetPoint("BOTTOMRIGHT", -4, 4)
	resize:Init(frame, MIN_WIDTH, MIN_HEIGHT)
	resize:SetScript("OnEnter", nil)
	resize:SetScript("OnLeave", nil)

	local header = CreateFrame("Frame", nil, frame)
	header:SetHeight(HEADER_HEIGHT)
	frame.Header = header

	local headerBackground = header:CreateTexture(nil, "BACKGROUND")
	headerBackground:SetAllPoints()
	headerBackground:SetColorTexture(1, 1, 1, 0.03)

	local nameHeader = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	nameHeader:SetPoint("LEFT", ROW_INSET, 0)
	nameHeader:SetWidth(ICON_SIZE + COLUMN_GAP + NAME_WIDTH)
	nameHeader:SetJustifyH("LEFT")
	nameHeader:SetText(L["Name"])

	local noteHeader = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	noteHeader:SetPoint("LEFT", nameHeader, "RIGHT", COLUMN_GAP, 0)
	noteHeader:SetPoint("RIGHT", header, "RIGHT", -(ROW_INSET + ACTION_SIZE + COLUMN_GAP), 0)
	noteHeader:SetJustifyH("LEFT")
	frame.NoteHeader = noteHeader

	local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")
	frame.ScrollBox = scrollBox

	local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

	local listTop = -(LIST_INSET_TOP + HEADER_HEIGHT)

	local withBar = {
		CreateAnchor("TOPLEFT", frame.Inset, "TOPLEFT", LIST_INSET, listTop),
		CreateAnchor("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -(LIST_INSET + 16), LIST_INSET),
	}

	local withoutBar = {
		CreateAnchor("TOPLEFT", frame.Inset, "TOPLEFT", LIST_INSET, listTop),
		CreateAnchor("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -LIST_INSET, LIST_INSET),
	}

	header:SetPoint("BOTTOMLEFT", scrollBox, "TOPLEFT")
	header:SetPoint("BOTTOMRIGHT", scrollBox, "TOPRIGHT")

	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 0)

	ScrollUtil.AddManagedScrollBarVisibilityBehavior(scrollBox, scrollBar, withBar, withoutBar)

	local view = CreateScrollBoxListLinearView()
	view:SetElementExtent(ROW_HEIGHT)
	view:SetElementInitializer("Button", InitRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

	local empty = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableLarge")
	empty:SetPoint("CENTER", scrollBox)
	empty:Hide()
	frame.Empty = empty

	local blocked = CreateFrame("Button", "BlocklistFrameTab1", frame, "PanelTabButtonTemplate")
	blocked:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 20, 2)
	blocked:SetText(L["BlockedPlayers"])
	blocked:SetScript("OnClick", function()
		SelectTab(TAB_BLOCKED)
	end)

	local recent = CreateFrame("Button", "BlocklistFrameTab2", frame, "PanelTabButtonTemplate")
	recent:SetPoint("LEFT", blocked, "RIGHT", -16, 0)
	recent:SetText(L["RecentPlayers"])
	recent:SetScript("OnClick", function()
		SelectTab(TAB_RECENT)
	end)

	frame.numTabs = 2
	PanelTemplates_SetNumTabs(frame, 2)
	PanelTemplates_SetTab(frame, TAB_BLOCKED)

	return frame
end

--[[ ns.Show()
Opens the blocklist window.
--]]
function ns.Show()
	if not frame then
		CreateFrames()
	end

	frame:Show()
end

--[[ ns.Toggle()
Shows the blocklist window, or hides it when it is already open.
--]]
function ns.Toggle()
	if not frame then
		CreateFrames()
	end

	frame:SetShown(not frame:IsShown())
end
