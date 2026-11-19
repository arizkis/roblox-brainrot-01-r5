-- Brainrot Bazaar server entrypoint: build the world, then announce readiness.
-- The game loops (conveyor, income, tsunami, locks, rebirth) land on top of this foundation.

local WorldBuilder = require(script.Parent.WorldBuilder)
local CharacterFactory = require(script.Parent.CharacterFactory)
local GameState = require(script.Parent.GameState)

local world = WorldBuilder.BuildWorld()

print(string.format(
	"[BrainrotBazaar] ready: %d booths, %d pads each, conveyor %.0f studs — factory and state home loaded",
	#world.Booths,
	#world.Booths[1].Pads,
	world.Conveyor.Length
))
