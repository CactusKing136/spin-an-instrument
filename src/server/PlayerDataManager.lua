--[[
	PlayerDataManager.lua
	Server-only ModuleScript — belongs in src/server (syncs to ServerScriptService)

	Loads and saves each player's data using DataStoreService, so
	progress (currently just the inventory) survives between sessions.

	Owns the full lifecycle: load on join, save + clear on leave, a
	periodic autosave, and a save-on-shutdown safety net.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local InventoryManager = require(script.Parent.InventoryManager)

local PlayerDataManager = {}

local playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")

local function getDefaultData()
	return {
		Inventory = {},
	}
end

local function loadPlayerData(player)
	local success, savedData = pcall(function()
		return playerDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if not success then
		warn("Failed to load data for " .. player.Name .. " — starting with defaults.")
	end

	local data = (success and savedData) or getDefaultData()
	InventoryManager.SetInventory(player, data.Inventory or {})
end

local function savePlayerData(player)
	local data = {
		Inventory = InventoryManager.GetInventory(player),
	}

	local success, err = pcall(function()
		playerDataStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

Players.PlayerAdded:Connect(loadPlayerData)

-- Covers the Studio-specific case where the test player may already be
-- in Players:GetPlayers() before this script finishes connecting
-- PlayerAdded — without this, your own test sessions would never load.
for _, player in Players:GetPlayers() do
	loadPlayerData(player)
end

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	InventoryManager.ClearInventory(player)
end)

-- Periodic autosave — a safety net in case the server crashes rather
-- than shutting down cleanly. Five minutes is gentle enough to stay
-- well within DataStore's request limits even with several players.
local AUTOSAVE_INTERVAL = 300 -- seconds

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for _, player in Players:GetPlayers() do
			savePlayerData(player)
		end
	end
end)

-- Catches server shutdowns (e.g. during a game update) so the very
-- latest data isn't lost.
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		savePlayerData(player)
	end
end)

return PlayerDataManager
