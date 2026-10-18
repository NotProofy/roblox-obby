-- Starts every server system in order.
local MapBuilder = require(script.Parent.MapBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Track = require(script.Parent.Track)
local Activities = require(script.Parent.Activities)
local RedLine = require(script.Parent.RedLine)
local Challenges = require(script.Parent.Challenges)

MapBuilder.Build()
PlayerData.Start()
Track.Start()
Activities.Start()
RedLine.Start()
Challenges.Start()

print("Red Line Challenge server ready")
