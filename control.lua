require "defines"
require "utils"

remote.addinterface("sspl",
{
	clean = function()
		glob.sspl = {	splitSets = {},
						splitSetsToRemove = {},
						version = utils.currentVersion
				   }
	end
})

game.oninit(function() OnInit() end)
game.onload(function() OnLoad() end)
game.onevent(defines.events.ontick, function(event) OnTick(event) end)
game.onevent(defines.events.onbuiltentity, function(event) OnBuiltEntity(event) end)
game.onevent(defines.events.onentitydied, function(event) OnEntityDied(event) end)
game.onevent(defines.events.onpreplayermineditem, function(event) OnPrePlayerMinedItem(event) end)


function OnInit()
	--game.player.print("SmartSplitters: OnInit")
	if glob.sspl == nil then
		glob.sspl = {	splitSets = {},
						splitSetsToRemove = {},
						version = utils.currentVersion
				   }
	else
		local total = 0
		for _, set in pairs(glob.sspl.splitSets) do
			total = total + #set.splitters
		end
		
		--game.player.print("Loaded " .. #glob.sspl.splitSets .. " splitter sets containing " .. total .. " splitters.")
	end
	if not glob.sspl.version then
		game.player.print("Migrating SmartSplitters from unversioned to version " .. utils.currentVersion)
		utils.migrations.versionless()
		game.player.print("Migration successful.")
	end
	if glob.sspl.version ~= utils.currentVersion then
		game.player.print("Migrating SmartSplitters from version " .. glob.sspl.version .. " to version " .. utils.currentVersion .. ".")
		utils.migrations[glob.sspl.version]()
		game.player.print("Migration successful.")
	end
	
	
end

function OnLoad()
	--game.player.print("SmartSplitters: OnLoad")
	-- Call OnInit to ensure glob.teles exists.
	OnInit()
end

function OnTick(_Event)
	--game.player.print("SmartSplitters: OnTick")
	-- Check if there's any sets with invalid splitters and remove those from the splitter lists.
	-- Then check if there's any sets with zero splitters and remove those from the global set table.
	if game.tick % 60 == 0 then
		local toRemove = {}
		for setID, set in pairs(glob.sspl.splitSets) do
			splitterToRemove = {}
			for splitterID, splitter in pairs(set.splitters) do
				if not splitter.valid then
					table.insert(splitterToRemove, splitterID)
				end
			end
			for _, splitterID in pairs(splitterToRemove) do
				table.remove(set.splitters, splitterID)
			end
			if #set.splitters < 1 then
				table.insert(toRemove, setID)
			end
		end
		for _, setID in pairs(toRemove) do
			table.remove(glob.sspl.splitSets)
		end
	end
	
	-- Check for new filters 6 times per second.
	if game.tick % 10 == 0 then
		for _, set in pairs(glob.sspl.splitSets) do
			RecalculateSet(set)
		end
	end
	
	for _, set in pairs(glob.sspl.splitSets) do
		for _, splitter in pairs(set.splitters) do
			if splitter.valid then
				local scanArea = GetScanArea(splitter.direction, splitter.position)
			
				local scan = {	left = game.findentitiesfiltered{	name = "item-on-ground",
										  				 			area = scanArea.left
																},
								right = game.findentitiesfiltered{	name = "item-on-ground",
											  					 	area = scanArea.right
																 }
				 			 }
				
				for sideName, side in pairs(scan) do
					for _, item in pairs(side) do
						local targetSplitterSet = nil
						if set.filteredItems[item.stack.name] then
							targetSplitterSet = set.filteredItems[item.stack.name]
						else
							targetSplitterSet = set.nonfilteringSplitters
						end
						
						if not set.itemCounts[item.stack.name] then
							set.itemCounts[item.stack.name] = 0
						else
							set.itemCounts[item.stack.name] = set.itemCounts[item.stack.name] + 1
						end
						
						local moved = false
						local tries = 0
						while not moved and tries < #targetSplitterSet do
							local targetSplitter = targetSplitterSet[((set.itemCounts[item.stack.name] + tries) % #targetSplitterSet) + 1]
							
							moved = MoveStack(item, targetSplitter, sideName)
							tries = tries + 1
						end
					end
				end
			end
		end
	end
end

local directionToOffset = {[0] = {x = -1, y =  0},
						   [2] = {x =  0, y = -1},
						   [4] = {x =  1, y =  0},
						   [6] = {x =  0, y =  1}}
						   
function OnBuiltEntity(_Event)
	local _Entity = _Event.createdentity
	if IsSmartSplitter(_Entity) then
		--game.player.print("Built smartsplitter")
		local _Position = _Entity.position
		local _Direction = _Entity.direction
		
		-- Check if there's a splitter to the left.
		local scanPosl = {x = _Position.x + directionToOffset[_Direction].x, y = _Position.y + directionToOffset[_Direction].y}
		local scanAreal = {{scanPosl.x - 0.25, scanPosl.y - 0.25}, {scanPosl.x + 0.25, scanPosl.y + 0.25}}
		local scanl = game.findentitiesfiltered{name = "smartsplitter", area = scanAreal}
		
		-- Check if there's a splitter to the right.
		local scanPosr = {x = _Position.x - directionToOffset[_Direction].x, y = _Position.y - directionToOffset[_Direction].y}
		local scanArear = {{scanPosr.x - 0.25, scanPosr.y - 0.25}, {scanPosr.x + 0.25, scanPosr.y + 0.25}}
		local scanr = game.findentitiesfiltered{name = "smartsplitter", area = scanArear}
		
		
		local lset = nil
		local rset = nil
		
		local lsetID = nil
		if #scanl == 1 and scanl[1].direction == _Direction then
			lsetID = GetAppropriateSetID(scanl[1])
		end
		local rsetID = nil
		if #scanr == 1 and scanr[1].direction == _Direction then
			rsetID = GetAppropriateSetID(scanr[1])
		end
		
		local set = CreateNewSet()
		if lsetID and rsetID then
			-- Add all splitters from the left set into the new set.
			for _, v in pairs(glob.sspl.splitSets[lsetID].splitters) do
				table.insert(set.splitters, v)
			end
			glob.sspl.splitSets[lsetID].splitters = {}
			-- Add the current splitter.
			table.insert(set.splitters, _Entity)
			-- Add all splitters from the right set.
			for _, v in pairs(glob.sspl.splitSets[rsetID].splitters) do
				table.insert(set.splitters, v)
			end
			glob.sspl.splitSets[rsetID].splitters = {}
			-- Remove left and right set.
			-- Remove the higher ID first, as the other ID won't be correct otherwise.
			if lsetID > rsetID then
				--game.player.print("Removing left set.")
				RemoveSetByID(lsetID)
				--game.player.print("Removing right set.")
				RemoveSetByID(rsetID)
			else
				--game.player.print("Removing right set.")
				RemoveSetByID(rsetID)
				--game.player.print("Removing left set.")
				RemoveSetByID(lsetID)
			end
			AddSet(set)
			--game.player.print("Merged sets.")
		elseif lsetID then
			--game.player.print("Added to left set.")
			set = glob.sspl.splitSets[lsetID]
			-- Add the current splitter to the end of the set.
			table.insert(set.splitters, _Entity)
		elseif rsetID then
			--game.player.print("Added to right set.")
			set = glob.sspl.splitSets[rsetID]
			-- Add the current splitter to the start of the set.
			table.insert(set.splitters, 1, _Entity)
		else
			--game.player.print("Created new set.")
			-- Add the splitter to the new set.
			table.insert(set.splitters, _Entity)
			AddSet(set)
		end
		
		RecalculateSet(set)
	end
end

function OnEntityDied(_Event)
	if IsSmartSplitter(_Event.entity) then
		RemoveSmartSplitter(_Event.entity)
	end
end

function OnPrePlayerMinedItem(_Event)
	if IsSmartSplitter(_Event.entity) then
		RemoveSmartSplitter(_Event.entity)
	end
end

function IsSmartSplitter(_Entity)
	return (_Entity.name == "smartsplitter")
end

function CreateNewSet()
	return {	splitters = {},
				filteredItems = {},
				itemCounts = {},
				filteringSplitters = {},
				nonfilteringSplitters = {}
		   }
end

function RemoveSmartSplitter(_Splitter)
	--game.player.print("RemoveSmartSplitter on splitter at [" .. _Splitter.position.x .. ", " .. _Splitter.position.y .. "]")
	local setID, splitterI = GetAppropriateSetID(_Splitter)
	
	if setID then
		local set = glob.sspl.splitSets[setID]
		-- If the splitter is at the edge.
		if splitterI == 1 or splitterI == #set.splitters then
			table.remove(set.splitters, splitterI)
			RecalculateSet(set)
		else
			--game.player.print("Splitting set into 2.")
			-- Splitter is somewhere in the middle, split the set.
			leftSet = CreateNewSet()
			rightSet = CreateNewSet()
			
			for i = 1, splitterI - 1 do
				table.insert(leftSet.splitters, set.splitters[i])
			end
			for i = splitterI + 1, #set.splitters do
				table.insert(rightSet.splitters, set.splitters[i])
			end
			set.splitters = {}
			
			--game.player.print("Removing old set.")
			RemoveSetByID(setID)
			
			AddSet(leftSet)
			RecalculateSet(leftSet)
			
			AddSet(rightSet)
			RecalculateSet(rightSet)
		end
	end
end

function AddSet(_Set)
	table.insert(glob.sspl.splitSets, _Set)
	--game.player.print("Added set")
	--game.player.print(#glob.sspl.splitSets .. " sets")
end

function RemoveSet(_Set)
	-- Not yet tested
	local id = 0
	for i, set in pairs(glob.sspl.splitSets) do
		if set == _Set then
			id = i
			break;
		end
	end
	if id ~= 0 then
		if #glob.sspl.splitSets[id].splitters > 0 then
			game.player.print("Removing split set with nonzero splitters.")
		end
		table.remove(glob.sspl.splitSets, id)
	else
		--game.player.print("Tried to remove nonexistent set.")
	end
	--game.player.print("Removed set " .. id)
	--game.player.print(#glob.sspl.splitSets .. " sets")
end

function RemoveSetByID(_ID)
	if #glob.sspl.splitSets[_ID].splitters > 0 then
		game.player.print("Removing split set with nonzero splitters.")
	end
	table.remove(glob.sspl.splitSets, _ID)
	--game.player.print("Removed set " .. _ID)
	--game.player.print(#glob.sspl.splitSets .. " sets")
end

function RecalculateSet(_Set)
	_Set.nonfilteringSplitters = {}
	_Set.filteredItems = {}
	_Set.filteringSplitters = {}
	
	if #_Set.splitters < 1 then
		--game.player.print("Empty set, removing.")
		RemoveSet(_Set)
	end
	
	for splitterID, splitter in pairs(_Set.splitters) do
		if splitter.valid then
			-- Fill item filter table.
			for i = 1, 5 do
				local itemName = splitter.getfilter(i)
				if itemName then
					table.insert(_Set.filteringSplitters, splitterID, splitter)
					if _Set.filteredItems[itemName] then
						table.insert(_Set.filteredItems[itemName], splitter)
					else
						_Set.filteredItems[itemName] = {[1] = splitter}
					end
				end
			end
			if not _Set.filteringSplitters[splitterID] then
				table.insert(_Set.nonfilteringSplitters, splitter)
			end
		end
	end
end

function GetAppropriateSetID(_Entity)
	for setID, set in pairs(glob.sspl.splitSets) do
		for splitterI, splitter in pairs(set.splitters) do
			if splitter.equals(_Entity) then
				return setID, splitterI
			end
		end
	end
	game.player.print("ERROR: No set ID found for smartsplitter at [" .. _Entity.position.x .. ", " .. _Entity.position.y .. "]")
	--game.player.print("This should not happen, so please tell the mod author (ThaPear) what you were doing when this happened.")
	--game.player.print("This means: Were you merging 2 rows of splitters, building it left/right/above/below other splitters, in what direction were those splitters?")
	return nil, nil
end

function GetScanArea(_Direction, _Position)
	local offL = 0.5
	local offH = 0.3
	if _Direction == 0 then
		return {left  = {{_Position.x + -offH, _Position.y        }, {_Position.x       , _Position.y + offL}},
				right = {{_Position.x        , _Position.y        }, {_Position.x + offH, _Position.y + offL}}
			   }
	elseif _Direction == 2 then
		return {left  = {{_Position.x + -offL, _Position.y + -offH}, {_Position.x       , _Position.y       }},
				right = {{_Position.x + -offL, _Position.y        }, {_Position.x       , _Position.y + offH}}
			   }
	elseif _Direction == 4 then
		return {left  = {{_Position.x        , _Position.y + -offL}, {_Position.x + offH, _Position.y       }},
				right = {{_Position.x + -offH, _Position.y + -offL}, {_Position.x       , _Position.y       }}
			   }
	else
		return {left  = {{_Position.x        , _Position.y        }, {_Position.x + offL, _Position.y + offH}},
				right = {{_Position.x        , _Position.y + -offH}, {_Position.x + offL, _Position.y       }}
			   }
	end
end

local VV = 0.55
local HH = 0.23
local targetOff = {[0] = {left = {x = -HH, y = -VV}, right = {x =  HH, y = -VV}},
				   [2] = {left = {x =  VV, y = -HH}, right = {x =  VV, y =  HH}},
				   [4] = {left = {x =  HH, y =  VV}, right = {x = -HH, y =  VV}},
				   [6] = {left = {x = -VV, y =  HH}, right = {x = -VV, y = -HH}}
						 }

function MoveStack(_Item, _Splitter, _Side)
	local newPos = {x = _Splitter.position.x + targetOff[_Splitter.direction][_Side].x,
					y = _Splitter.position.y + targetOff[_Splitter.direction][_Side].y}

	if _Splitter.energy < 1 then
		return false
	end


	-- Check if the target location is empty.
	local possiblePos = game.findnoncollidingposition("item-on-ground", newPos, 0.01, 0.01)
	if possiblePos then
		game.createentity{position=possiblePos, name="item-on-ground", stack={name=_Item.stack.name, count=_Item.stack.count}}
		_Item.destroy()

		return true
	end
	return false
end
