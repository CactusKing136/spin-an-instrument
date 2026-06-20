--[[
	ItemDatabase.lua
	Shared module — belongs in src/shared (syncs to ReplicatedStorage)

	Single source of truth for every instrument: its rarity, drop weight,
	and how much money it generates per second once placed on a plot.

	Both the server (spin rolls, income calculation) and the client
	(UI display, rarity colors) require() this same module.
]]

local ItemDatabase = {}

-- Rarity metadata — used for UI coloring and the spin-reveal effect.
ItemDatabase.Rarities = {
	Common    = { Color = Color3.fromRGB(190, 190, 190) },
	Uncommon  = { Color = Color3.fromRGB(85, 200, 85) },
	Rare      = { Color = Color3.fromRGB(60, 140, 230) },
	Epic      = { Color = Color3.fromRGB(170, 80, 220) },
	Legendary = { Color = Color3.fromRGB(240, 180, 40) },
	Mythic    = { Color = Color3.fromRGB(230, 60, 60) },
}

-- Every instrument in the game.
-- `Weight` controls drop odds — bigger number = more common.
-- `MoneyPerSecond` is the income generated once placed on a plot.
ItemDatabase.Items = {
	{ Id = "tambourine",  Name = "Tambourine",  Rarity = "Common",    Weight = 500, MoneyPerSecond = 1 },
	{ Id = "kazoo",       Name = "Kazoo",       Rarity = "Common",    Weight = 450, MoneyPerSecond = 1.5 },
	{ Id = "recorder",    Name = "Recorder",    Rarity = "Uncommon",  Weight = 250, MoneyPerSecond = 4 },
	{ Id = "ukulele",     Name = "Ukulele",     Rarity = "Uncommon",  Weight = 200, MoneyPerSecond = 5 },
	{ Id = "violin",      Name = "Violin",      Rarity = "Rare",      Weight = 80,  MoneyPerSecond = 15 },
	{ Id = "guitar",      Name = "Guitar",      Rarity = "Rare",      Weight = 60,  MoneyPerSecond = 20 },
	{ Id = "saxophone",   Name = "Saxophone",   Rarity = "Epic",      Weight = 20,  MoneyPerSecond = 60 },
	{ Id = "cello",       Name = "Cello",       Rarity = "Epic",      Weight = 15,  MoneyPerSecond = 75 },
	{ Id = "grand_piano", Name = "Grand Piano", Rarity = "Legendary", Weight = 4,   MoneyPerSecond = 250 },
	{ Id = "pipe_organ",  Name = "Pipe Organ",  Rarity = "Legendary", Weight = 2,   MoneyPerSecond = 400 },
	{ Id = "golden_harp", Name = "Golden Harp", Rarity = "Mythic",    Weight = 0.3, MoneyPerSecond = 2000 },
}

-- Quick lookup table so other scripts don't loop through the whole
-- array every time they need one item by its Id.
local itemsById = {}
for _, item in ItemDatabase.Items do
	itemsById[item.Id] = item
end

function ItemDatabase.GetItemById(id)
	return itemsById[id]
end

-- Pre-calculate the total weight once at module load, since it never
-- changes at runtime — no point re-summing it on every single spin.
local totalWeight = 0
for _, item in ItemDatabase.Items do
	totalWeight += item.Weight
end

-- Rolls a single random item, weighted by rarity.
-- This should be the ONLY place spin logic ever calls into — keeping
-- the math here means the spin handler, any "test roll" tooling, and
-- future systems (like a luck boost) all agree on the same odds.
function ItemDatabase.RollRandomItem()
	local roll = math.random() * totalWeight
	local cumulative = 0

	for _, item in ItemDatabase.Items do
		cumulative += item.Weight
		if roll <= cumulative then
			return item
		end
	end

	-- Fallback — should be unreachable unless totalWeight is 0.
	return ItemDatabase.Items[1]
end

return ItemDatabase
