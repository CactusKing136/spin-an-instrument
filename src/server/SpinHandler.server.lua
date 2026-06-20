--[[
	SpinHandler.server.lua
	Server script — belongs in src/server (syncs to ServerScriptService)

	Listens for spin requests, rolls a random item using ItemDatabase,
	stores it via InventoryManager, and reports both the spin result and
	the updated inventory back to that client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDatabase = require(ReplicatedStorage.Shared.modules.ItemDatabase)
local InventoryManager = require(script.Parent.InventoryManager)
local PlayerDataManager = require(script.Parent.PlayerDataManager)

-- Create the RemoteEvents/RemoteFunctions both sides need, if missing.
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(className, name)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote
end

local spinRequest = getOrCreateRemote("RemoteEvent", "SpinRequest")
local spinResult = getOrCreateRemote("RemoteEvent", "SpinResult")
local inventoryUpdated = getOrCreateRemote("RemoteEvent", "InventoryUpdated")
local requestInventory = getOrCreateRemote("RemoteFunction", "RequestInventory")

-- Basic anti-spam — the real protection is RollRandomItem() only ever
-- running here, server-side, never on the client.
local SPIN_COOLDOWN = 0.5
local lastSpinTime = {}

spinRequest.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if lastSpinTime[player] and now - lastSpinTime[player] < SPIN_COOLDOWN then
		return
	end
	lastSpinTime[player] = now

	local rolledItem = ItemDatabase.RollRandomItem()
	InventoryManager.AddItem(player, rolledItem.Id)

	spinResult:FireClient(player, rolledItem)
	inventoryUpdated:FireClient(player, InventoryManager.GetInventory(player))
end)

-- Lets the client pull the current inventory on demand (e.g. right
-- when the UI first loads in, before any spin has happened yet).
requestInventory.OnServerInvoke = function(player)
	return InventoryManager.GetInventory(player)
end

print("SpinHandler ready.")
