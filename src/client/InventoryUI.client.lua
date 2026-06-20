--[[
	InventoryUI.client.lua
	Client script — belongs in src/client (syncs to StarterPlayer.StarterPlayerScripts)

	Shows a simple scrolling list of everything the player has spun so
	far, grouped by item with a count (e.g. "Guitar x3"). Updates
	automatically whenever the server reports a change.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemDatabase = require(sharedFolder.modules.ItemDatabase)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local inventoryUpdated = remotesFolder:WaitForChild("InventoryUpdated")
local requestInventory = remotesFolder:WaitForChild("RequestInventory")

-- Reuse the same ScreenGui SpinUI created, if it's already there, so
-- everything lives under one GUI container instead of several.
local screenGui = playerGui:FindFirstChild("SpinUI")
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpinUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
end

local inventoryFrame = Instance.new("Frame")
inventoryFrame.Name = "InventoryFrame"
inventoryFrame.Size = UDim2.fromOffset(220, 320)
inventoryFrame.Position = UDim2.fromOffset(20, 20)
inventoryFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
inventoryFrame.BackgroundTransparency = 0.2
inventoryFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Inventory"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = inventoryFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemList"
scrollFrame.Size = UDim2.new(1, 0, 1, -30)
scrollFrame.Position = UDim2.fromOffset(0, 30)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = inventoryFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

local function refreshInventory(itemIds)
	for _, child in scrollFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Count duplicates so they show as "x3" instead of one row per copy.
	local counts = {}
	local order = {}
	for _, itemId in itemIds do
		if not counts[itemId] then
			counts[itemId] = 0
			table.insert(order, itemId)
		end
		counts[itemId] += 1
	end

	for i, itemId in order do
		local itemData = ItemDatabase.GetItemById(itemId)
		if itemData then
			local row = Instance.new("TextLabel")
			row.Size = UDim2.new(1, -10, 0, 24)
			row.Position = UDim2.fromOffset(5, 0)
			row.BackgroundTransparency = 1
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.Font = Enum.Font.Gotham
			row.TextSize = 16
			row.LayoutOrder = i
			row.TextColor3 = ItemDatabase.Rarities[itemData.Rarity].Color
			row.Text = string.format("%s x%d", itemData.Name, counts[itemId])
			row.Parent = scrollFrame
		end
	end
end

inventoryUpdated.OnClientEvent:Connect(refreshInventory)

-- Pull whatever's already there the moment this loads in.
local initialInventory = requestInventory:InvokeServer()
refreshInventory(initialInventory)
