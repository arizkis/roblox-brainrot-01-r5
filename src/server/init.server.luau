-- Brainrot Bazaar server entrypoint: build the world, start every system, bind players.
-- Core loop: conveyor spawns, income tick, carry/delivery.
-- Tension: tsunami cycle, rotating events, steal/lock, raccoon thieves.
-- Progression: rebirth, upgrades, contracts, collection index.

local Players = game:GetService("Players")
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerSessions = require(script.Parent.PlayerSessions)
local Quests = require(script.Parent.Quests)
local Economy = require(script.Parent.Economy)
local Conveyor = require(script.Parent.Conveyor)
local Carry = require(script.Parent.Carry)
local Tsunami = require(script.Parent.Tsunami)
local EventDirector = require(script.Parent.EventDirector)
local StealLock = require(script.Parent.StealLock)
local RaccoonThieves = require(script.Parent.RaccoonThieves)
local Rebirth = require(script.Parent.Rebirth)
local Upgrades = require(script.Parent.Upgrades)

local world = WorldBuilder.BuildWorld()

PlayerSessions.Init(world)
Economy.Init(world)
Conveyor.Init(world)
Carry.Init(world)
Tsunami.Init(world)
StealLock.Init(world)
RaccoonThieves.Init(world)
Rebirth.Init(world)
Quests.Init()

-- Cross-system handlers (injected to keep the require graph acyclic).
Conveyor.SetBuyHandler(Carry.BuyBeltCharacter)
Tsunami.SetDropHandler(Carry.DropCarried)
Quests.SetPayHandler(Economy.AddCash)

-- Client request surface (rail buttons, shop, book, contracts).
local Remotes = require(script.Parent.Remotes)
local IndexBook = require(script.Parent.IndexBook)
Remotes.RequestLock.OnServerEvent:Connect(function(player)
	StealLock.RequestLock(player)
end)
Remotes.RequestRebirth.OnServerEvent:Connect(function(player)
	Rebirth.RequestRebirth(player)
end)
Remotes.BuyUpgrade.OnServerEvent:Connect(function(player, trackId)
	if type(trackId) == "string" then
		Upgrades.BuyUpgrade(player, trackId)
	end
end)
Remotes.GetIndex.OnServerInvoke = function(player)
	return IndexBook.FoundSet(player)
end
Remotes.GetQuests.OnServerInvoke = function(player)
	return Quests.ActiveQuests(player)
end
Remotes.GetUpgrades.OnServerInvoke = function(player)
	return Upgrades.UpgradeState(player)
end

Conveyor.StartConveyor()
Economy.StartIncomeLoop()
Tsunami.StartTsunamiCycle()
EventDirector.StartEventDirector()
RaccoonThieves.StartRaccoonCycle()

for _, player in Players:GetPlayers() do
	PlayerSessions.BindPlayer(player)
	Quests.AssignQuests(player)
end

print(string.format(
	"[BrainrotBazaar] ready: %d booths, conveyor %.0f studs, %d upgrade tracks — all systems running",
	#world.Booths,
	world.Conveyor.Length,
	#Upgrades.Tracks
))
