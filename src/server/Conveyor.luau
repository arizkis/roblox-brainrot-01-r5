-- Conveyor: spawns brainrots at the arch every 4 s (2 s during Belt Rush), rides them down
-- the belt at a steady speed and despawns them at the far end. The server tier band is the
-- highest rebirth count online; each rebirth shifts the spawn odds one step richer.
-- Buying is handled by Carry through the injected buy handler (avoids a require cycle).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local CharacterFactory = require(script.Parent.CharacterFactory)
local GameState = require(script.Parent.GameState)

local Conveyor = {}

local lane = nil -- world conveyor handle, set by Init
local beltFolder: Folder? = nil
local riding: { { Model: Model, Offset: number } } = {}
local buyHandler: ((Player, Model) -> ())? = nil

local RIDE_SPEED = 8 -- studs per second
local MAX_ON_BELT = 14
local BASE_ODDS = { 55, 27, 12, 4.5, 1.2, 0.25, 0.05 } -- Common..Divine at band 0

Conveyor.BeltRush = false

function Conveyor.Init(world)
	lane = world.Conveyor
	beltFolder = Instance.new("Folder")
	beltFolder.Name = "BeltCharacters"
	beltFolder.Parent = world.Root
end

function Conveyor.SetBuyHandler(handler: (Player, Model) -> ())
	buyHandler = handler
end

function Conveyor.SetBeltRush(active: boolean)
	Conveyor.BeltRush = active
end

-- One server band = highest rebirth count online, capped at 6 shifts.
function Conveyor.CurrentTierBand(): number
	local band = 0
	for _, player in Players:GetPlayers() do
		band = math.max(band, GameState.GetRebirths(player))
	end
	return math.min(band, 6)
end

-- Odds for the current band: each shift moves the whole distribution one tier richer.
local function tierWeights(band: number): { number }
	local weights = {}
	local total = 0
	for i = 1, #GameConfig.Tiers do
		local idx = i + band
		local w = if idx <= #BASE_ODDS then BASE_ODDS[idx] else BASE_ODDS[#BASE_ODDS] * 0.5 ^ (idx - #BASE_ODDS)
		weights[i] = w
		total += w
	end
	for i, w in weights do
		weights[i] = w / total
	end
	return weights
end

local function pickTier(band: number)
	local weights = tierWeights(band)
	local roll = math.random()
	for i, w in weights do
		roll -= w
		if roll <= 0 then
			return GameConfig.Tiers[i]
		end
	end
	return GameConfig.Tiers[#GameConfig.Tiers]
end

function Conveyor.SpawnBrainrotOnBelt(): Model?
	if not lane or #riding >= MAX_ON_BELT then
		return nil
	end
	local tier = pickTier(Conveyor.CurrentTierBand())
	local recipes = GameConfig.CastByTier[tier.name]
	local recipe = recipes[math.random(1, #recipes)]
	local mutation = GameConfig.RollMutation(tier.name)

	local model = CharacterFactory.BuildCharacter(recipe, mutation)
	model:SetAttribute("CharacterId", HttpService:GenerateGUID(false))
	model:SetAttribute("Price", tier.buyPrice)
	model:SetAttribute("Stolen", false)
	model:SetAttribute("BeltCharacter", true)
	model.Parent = beltFolder
	model:PivotTo(CFrame.new(lane.Start + Vector3.new(0, 0.55, 0)))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ObjectText = recipe.name
	prompt.ActionText = string.format("$%d", tier.buyPrice)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		if buyHandler then
			buyHandler(player, model)
		end
	end)

	table.insert(riding, { Model = model, Offset = 0 })
	return model
end

-- Take a character off the belt (bought). Returns its ride entry, or nil when it is already gone.
function Conveyor.RemoveBeltCharacter(model: Model)
	for i, entry in ipairs(riding) do
		if entry.Model == model then
			table.remove(riding, i)
			local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("BuyPrompt")
			if prompt then
				prompt.Enabled = false
			end
			return entry
		end
	end
	return nil
end

function Conveyor.StartConveyor()
	-- Ride the belt; despawn at the far end.
	RunService.Heartbeat:Connect(function(dt)
		for i = #riding, 1, -1 do
			local entry = riding[i]
			entry.Offset += RIDE_SPEED * dt
			if entry.Offset >= lane.Length then
				entry.Model:Destroy()
				table.remove(riding, i)
			else
				entry.Model:PivotTo(CFrame.new(lane.Start + lane.Direction * entry.Offset + Vector3.new(0, 0.55, 0)))
			end
		end
	end)

	-- Spawn loop: 4 s normally, 2 s during Belt Rush.
	task.spawn(function()
		while true do
			local interval = if Conveyor.BeltRush then 2 else GameConfig.Economy.ConveyorSpawnInterval
			task.wait(interval)
			Conveyor.SpawnBrainrotOnBelt()
		end
	end)
end

return Conveyor
