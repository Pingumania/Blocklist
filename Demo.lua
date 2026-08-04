local ADDON_NAME, ns = ...

local blocked = {
	["Trackmania-Blackhand"] = { class = "HUNTER", note = "Ninja looted the trinket" },
	["Polymania-Blackhand"] = { class = "MAGE", note = "" },
	["Stabmania-Blackhand"] = { class = "ROGUE", note = "Left the key at the last boss" },
	["Schockmania-Blackhand"] = { class = "SHAMAN", note = "Kept pulling extra packs" },
}

local recent = {
	["Trackmania-Blackhand"] = { class = "HUNTER", activity = "Ara-Kara, City of Echoes" },
	["Heilmania-Blackhand"] = { class = "PRIEST", activity = "Liberation of Undermine" },
	["Panzermania-Blackhand"] = { class = "WARRIOR", activity = "The Dawnbreaker" },
	["Weihmania-Blackhand"] = { class = "PALADIN", activity = "Dornogal" },
	["Klauenmania-Blackhand"] = { class = "DRUID", activity = "Grim Batol" },
	["Daemonmania-Blackhand"] = { class = "WARLOCK", activity = "Isle of Dorn" },
	["Windmania-Blackhand"] = { class = "MONK", activity = "Cinderbrew Meadery" },
	["Frostmania-Blackhand"] = { class = "DEATHKNIGHT", activity = "Operation: Floodgate" },
}

local Blocked = ns.Blocked
local Recent = ns.Recent
local showing

--[[ ns.ToggleDemo()
Fills the window with made up players, so the layout can be checked without a group. Only in
development builds, and it never touches the saved blocklist.
--]]
function ns.ToggleDemo()
	showing = not showing

	if showing then
		ns.Blocked = function() return blocked end
		ns.Recent = function() return recent end
	else
		ns.Blocked = Blocked
		ns.Recent = Recent
	end

	ns.Show()
	ns.Refresh()

	print(("%s: demo data %s"):format(ADDON_NAME, showing and "on" or "off"))
end

ns:RegisterSlash("/bldemo", function()
	ns.ToggleDemo()
end)
