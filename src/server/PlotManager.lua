--[[
	PlotManager.lua
	Server-only ModuleScript — belongs in src/server (syncs to ServerScriptService)

	Builds each player's personal plot — a grid of slots they can place
	instruments on — and tracks which slot holds what. Plot layout is
	rebuilt fresh each session for now; saving it is a follow-up step,
	same as we did with inventory.
]]

local Workspace = game:GetService("Workspace")

local PlotManager = {}

local GRID_SIZE = 4          -- 4x4 = 16 slots per plot
local SLOT_SPACING = 6       -- studs between slot centers
local PLOT_SPACING = 40      -- studs between each player's plot origin
local SLOT_SIZE = Vector3.new(5, 1, 5)

local plotsFolder = Workspace:FindFirstChild("Plots")
if not plotsFolder then
	plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = Workspace
end

-- slotData[player][slotIndex] = itemId, or nil if that slot is empty.
local slotData = {}
local nextPlotIndex = 0

-- onSlotClicked(player, slotIndex) fires whenever one of this player's
-- own slots is clicked. PlacementHandler passes this in, so the actual
-- placement logic lives there — this module only owns layout and data.
function PlotManager.AssignPlot(player, onSlotClicked)
	local plotIndex = nextPlotIndex
	nextPlotIndex += 1

	local originX = plotIndex * PLOT_SPACING

	local plotFolder = Instance.new("Folder")
	plotFolder.Name = player.Name .. "_Plot"
	plotFolder.Parent = plotsFolder

	slotData[player] = {}

	local slotIndex = 0
	for row = 0, GRID_SIZE - 1 do
		for col = 0, GRID_SIZE - 1 do
			slotIndex += 1

			-- Give this iteration its OWN local copy of the index to
			-- capture. Without this, every closure below would share
			-- the single outer `slotIndex` and all report whatever it
			-- ends up at once the loop finishes (16, every time).
			local thisSlotIndex = slotIndex

			local slotPart = Instance.new("Part")
			slotPart.Name = "Slot_" .. thisSlotIndex
			slotPart.Size = SLOT_SIZE
			slotPart.Position = Vector3.new(
				originX + col * SLOT_SPACING,
				1,
				row * SLOT_SPACING
			)
			slotPart.Anchored = true
			slotPart.BrickColor = BrickColor.new("Medium stone grey")
			slotPart:SetAttribute("SlotIndex", thisSlotIndex)
			slotPart.Parent = plotFolder

			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 20
			clickDetector.Parent = slotPart

			clickDetector.MouseClick:Connect(function(clickingPlayer)
				if clickingPlayer == player then
					onSlotClicked(player, thisSlotIndex)
				end
			end)

			slotData[player][thisSlotIndex] = nil
		end
	end

	return plotFolder
end

function PlotManager.GetSlotPart(player, slotIndex)
	local plotFolder = plotsFolder:FindFirstChild(player.Name .. "_Plot")
	return plotFolder and plotFolder:FindFirstChild("Slot_" .. slotIndex)
end

function PlotManager.IsSlotEmpty(player, slotIndex)
	return slotData[player] ~= nil and slotData[player][slotIndex] == nil
end

function PlotManager.SetSlotItem(player, slotIndex, itemId)
	if slotData[player] then
		slotData[player][slotIndex] = itemId
	end
end

function PlotManager.ClearPlayerPlot(player)
	local plotFolder = plotsFolder:FindFirstChild(player.Name .. "_Plot")
	if plotFolder then
		plotFolder:Destroy()
	end
	slotData[player] = nil
end

return PlotManager
