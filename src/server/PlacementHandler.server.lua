--[[
	PlacementHandler.server.lua
	Server script — belongs in src/server (syncs to ServerScriptService)

	Assigns each player a plot when they join, lets them "arm" an item
	from their inventory, and handles the actual placement when they
	click one of their own empty slots.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemDatabase = require(ReplicatedStorage.Shared.modules.ItemDatabase)
local InventoryManager = require(script.Parent.InventoryManager)
local PlotManager = require(script.Parent.PlotManager)

-- Reuse the same Remotes folder the other systems already created.
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

local selectItemForPlacement = getOrCreateRemote("RemoteEvent", "SelectItemForPlacement")
local inventoryUpdated = getOrCreateRemote("RemoteEvent", "InventoryUpdated")

-- Tracks which item each player currently has "armed" for placement.
local selectedItemId = {}

selectItemForPlacement.OnServerEvent:Connect(function(player, itemId)
	selectedItemId[player] = itemId
end)

-- Removes the first matching itemId from a player's inventory list.
-- Returns true if something was actually removed.
local function removeOneItem(player, itemId)
	local inventory = InventoryManager.GetInventory(player)
	for i, ownedId in inventory do
		if ownedId == itemId then
			table.remove(inventory, i)
			return true
		end
	end
	return false
end

-- Placeholder visual until real instrument models exist — a colored
-- cube (by rarity) with a floating name tag above it.
local function spawnPlacedItemVisual(slotPart, itemData)
	local visual = Instance.new("Part")
	visual.Name = itemData.Id
	visual.Size = Vector3.new(3, 3, 3)
	visual.Anchored = true
	visual.CanCollide = false
	visual.Position = slotPart.Position + Vector3.new(0, 2.5, 0)
	visual.Color = ItemDatabase.Rarities[itemData.Rarity].Color
	visual.Parent = slotPart

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(120, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = visual

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = itemData.Name
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.Parent = billboard
end

local function onSlotClicked(player, slotIndex)
	local itemId = selectedItemId[player]
	if not itemId then
		return -- nothing selected, nothing to place
	end

	if not PlotManager.IsSlotEmpty(player, slotIndex) then
		return -- slot already taken
	end

	local removed = removeOneItem(player, itemId)
	if not removed then
		selectedItemId[player] = nil -- they don't actually have this anymore
		return
	end

	PlotManager.SetSlotItem(player, slotIndex, itemId)

	local slotPart = PlotManager.GetSlotPart(player, slotIndex)
	local itemData = ItemDatabase.GetItemById(itemId)
	spawnPlacedItemVisual(slotPart, itemData)

	inventoryUpdated:FireClient(player, InventoryManager.GetInventory(player))
end

local function onPlayerAdded(player)
	PlotManager.AssignPlot(player, onSlotClicked)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Covers the Studio-specific case where the test player may already be
-- in Players:GetPlayers() before this script finishes connecting up.
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	selectedItemId[player] = nil
	PlotManager.ClearPlayerPlot(player)
end)

print("PlacementHandler ready.")
