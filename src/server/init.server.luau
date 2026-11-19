-- Brainrot Bazaar server entrypoint: build the world, start the core loop
-- (conveyor spawns, income tick, carry/delivery), and bind every player to a session.

local Players = game:GetService("Players")
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerSessions = require(script.Parent.PlayerSessions)
local Economy = require(script.Parent.Economy)
local Conveyor = require(script.Parent.Conveyor)
local Carry = require(script.Parent.Carry)

local world = WorldBuilder.BuildWorld()

PlayerSessions.Init(world)
Economy.Init(world)
Conveyor.Init(world)
Carry.Init(world)

Conveyor.SetBuyHandler(Carry.BuyBeltCharacter)
Conveyor.StartConveyor()
Economy.StartIncomeLoop()

for _, player in Players:GetPlayers() do
	PlayerSessions.BindPlayer(player)
end

print(string.format(
	"[BrainrotBazaar] ready: %d booths, conveyor %.0f studs, core loop running (spawns 4s, income 1s)",
	#world.Booths,
	world.Conveyor.Length
))
