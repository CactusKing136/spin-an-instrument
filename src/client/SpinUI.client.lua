--[[
	SpinUI.client.lua
	Client script — belongs in src/client (syncs to StarterPlayer.StarterPlayerScripts)

	Builds a basic spin button + result label, sends spin requests to the
	server, and displays whatever comes back. Intentionally plain/unstyled
	for now — this is about proving the loop works end to end before
	worrying about how it looks.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Matches the confirmed project structure: ReplicatedStorage.Shared.modules.ItemDatabase
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ItemDatabase = require(ReplicatedStorage.Shared.modules.ItemDatabase)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local spinRequest = remotesFolder:WaitForChild("SpinRequest")
local spinResult = remotesFolder:WaitForChild("SpinResult")

-- Build the UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpinUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local spinButton = Instance.new("TextButton")
spinButton.Name = "SpinButton"
spinButton.Size = UDim2.fromOffset(160, 50)
spinButton.Position = UDim2.fromScale(0.5, 0.85)
spinButton.AnchorPoint = Vector2.new(0.5, 0.5)
spinButton.Text = "SPIN"
spinButton.Font = Enum.Font.GothamBold
spinButton.TextSize = 22
spinButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
spinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
spinButton.Parent = screenGui

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.Size = UDim2.fromOffset(320, 60)
resultLabel.Position = UDim2.fromScale(0.5, 0.7)
resultLabel.AnchorPoint = Vector2.new(0.5, 0.5)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = ""
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextSize = 28
resultLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
resultLabel.Parent = screenGui

-- Disable the button briefly after each click so spamming it doesn't
-- feel broken while waiting on the server's response.
local SPIN_COOLDOWN = 0.5
local lastSpinTime = 0

spinButton.MouseButton1Click:Connect(function()
	local now = os.clock()
	if now - lastSpinTime < SPIN_COOLDOWN then
		return
	end
	lastSpinTime = now

	spinButton.Text = "..."
	resultLabel.Text = ""
	spinRequest:FireServer()

	-- Safety net: re-enable the button after the cooldown even if
	-- spinResult never comes back, so it can never get stuck.
	task.delay(SPIN_COOLDOWN, function()
		if spinButton.Text == "..." then
			spinButton.Text = "SPIN"
		end
	end)
end)

spinResult.OnClientEvent:Connect(function(item)
	spinButton.Text = "SPIN"

	local rarityInfo = ItemDatabase.Rarities[item.Rarity]
	resultLabel.TextColor3 = rarityInfo.Color
	resultLabel.Text = string.format("%s — %s!", item.Name, item.Rarity)
end)

print("SpinUI ready.")
