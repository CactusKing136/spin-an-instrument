--[[
	InventoryManager.lua
	Server-only ModuleScript — belongs in src/server (syncs to ServerScriptService)

	IMPORTANT: keep this file named exactly "InventoryManager.lua" — no
	".server" suffix. It's require()'d, not run on its own.

	Tracks what each player has spun, in memory, while they're connected.
	PlayerDataManager now owns the full lifecycle — loading this in when
	a player joins, and saving + clearing it when they leave — so this
	module no longer clears itself on PlayerRemoving.
]]

local InventoryManager = {}

local inventories = {}

local function ensureInventory(player)
	if not inventories[player] then
		inventories[player] = {}
	end
	return inventories[player]
end

function InventoryManager.AddItem(player, itemId)
	local inventory = ensureInventory(player)
	table.insert(inventory, itemId)
end

function InventoryManager.GetInventory(player)
	return ensureInventory(player)
end

-- Called by PlayerDataManager right after loading a player's save.
function InventoryManager.SetInventory(player, itemIds)
	inventories[player] = itemIds
end

-- Called by PlayerDataManager right after saving, once it's safe to
-- forget this player's data.
function InventoryManager.ClearInventory(player)
	inventories[player] = nil
end

return InventoryManager
