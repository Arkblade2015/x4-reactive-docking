-- ffi setup 
local ffi = require("ffi") 
local C = ffi.C 
 
local Lib = require("extensions.sn_mod_support_apis.lua_library") 
local map_menu = {}
local dock_menu = {}
local do_menu = {}

local config = {
	subordinatedockingoptions = {
		[1] = { id = "docked",			text = ReadText(1001, 8630),	icon = "",	displayremoveoption = false },
		[2] = { id = "launched",		text = ReadText(1001, 8629),	icon = "",	displayremoveoption = false },
		[3] = { id = "reactive",		text = ReadText(181114415, 1),	icon = "",	displayremoveoption = false }
	},
	mapRowHeight = Helper.standardTextHeight
}

local function init()
	DebugError("Reactive Docking UI Init")

	map_menu = Lib.Get_Egosoft_Menu("MapMenu")
	map_menu.registerCallback("rd_addReactiveDockingMapMenu", do_menu.addReactiveDockingMapMenu)
	
	dock_menu = Lib.Get_Egosoft_Menu("DockedMenu")
	dock_menu.registerCallback("rd_addReactiveDockingDockMenu", do_menu.addReactiveDockingDockMenu)
end 

local function setReactiveDocking(inputobject, i, reactive)
	local pilotentityid = GetControlEntity(inputobject)
	local reactiveList = GetNPCBlackboard(pilotentityid, "$DockingReactive")
	if reactiveList == nil then
		reactiveList = {}
	end
	reactiveList[i] = reactive
	SetNPCBlackboard(pilotentityid, "$DockingReactive", reactiveList)
end

local function getReactiveDocking(inputobject, i)
	local pilotentityid = GetControlEntity(inputobject)
	local reactiveList = GetNPCBlackboard(pilotentityid, "$DockingReactive")
	if reactiveList == nil or reactiveList[i] == nil then
		return false
	else 
		return reactiveList[i] == 1
	end
end

local function getDockingStartingOrder(inputobject, i)
	local docked = C.ShouldSubordinateGroupDockAtCommander(inputobject, i)
	local reactive = getReactiveDocking(inputobject, i)
	if not docked and reactive then
		return "reactive"
	elseif not docked then
		return "launched"
	else
		return "docked"
	end
end

local function setDockingOptions(inputobject, i, newdockingoption)
	local docked = true
	local reactive = false
	if newdockingoption == "reactive" then
		docked = false
		reactive = true
	elseif newdockingoption == "launched" then
		docked = false
	end
	C.SetSubordinateGroupDockAtCommander(inputobject, i, docked)
	setReactiveDocking(inputobject, i, reactive)
end
 
function do_menu.addReactiveDockingMapMenu(row, inputobject, i, mode)
	local menu = map_menu

	-- Just create the vanilla button if its not a ship or a carrier
	if mode ~= "ship" or GetComponentData(inputobject, "shiptype") == "carrier" then
		row[3]:setColSpan(11):createButton({ active = active, mouseOverText = mouseovertext, height = config.mapRowHeight }):setText(function () return C.ShouldSubordinateGroupDockAtCommander(inputobject, i) and ReadText(1001, 8630) or ReadText(1001, 8629) end, { halign = "center" })
		row[3].handlers.onClick = function () return C.SetSubordinateGroupDockAtCommander(inputobject, i, not C.ShouldSubordinateGroupDockAtCommander(inputobject, i)) end
	-- Otherwise create a dropdown with the extra option
	else
		row[3]:setColSpan(11):createDropDown(config.subordinatedockingoptions, { active = active, mouseOverText = mouseovertext, height = config.mapRowHeight, startOption = function () getDockingStartingOrder(inputobject, i) end })
		row[3].handlers.onDropDownActivated = function () menu.noupdate = true end
		row[3].handlers.onDropDownConfirmed = function (_, newdockingoption) setDockingOptions(inputobject, i, newdockingoption); menu.noupdate = false end
	end
	return true
end


function do_menu.addReactiveDockingDockMenu(row, inputobject, i)
	local menu = dock_menu

	local shiptype = GetComponentData(menu.currentplayership, "shiptype")
	local iscarrier = shiptype == "carrier"
	-- Just create the vanilla button if its a carrier
	if iscarrier then
		row[7]:setColSpan(5):createButton({ active = active, mouseOverText = mouseovertext }):setText(function () return C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i) and ReadText(1001, 8630) or ReadText(1001, 8629) end, { halign = "center" })
		row[7].handlers.onClick = function () return C.SetSubordinateGroupDockAtCommander(menu.currentplayership, i, not C.ShouldSubordinateGroupDockAtCommander(menu.currentplayership, i)) end
	-- Otherwise create a dropdown with the extra option
	else
		row[7]:setColSpan(5):createDropDown(config.subordinatedockingoptions, { active = active, mouseOverText = mouseovertext, startOption = function () getDockingStartingOrder(menu.currentplayership, i) end })
		row[7].handlers.onDropDownConfirmed = function (_, newdockingoption) setDockingOptions(menu.currentplayership, i, newdockingoption) end
	end
	return true
end 

init()