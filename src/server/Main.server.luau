-- Starts every server system in order.
local MapBuilder = require(script.Parent.MapBuilder)
local PlayerData = require(script.Parent.PlayerData)
local Track = require(script.Parent.Track)
local Activities = require(script.Parent.Activities)
local RedLine = require(script.Parent.RedLine)
local Challenges = require(script.Parent.Challenges)
local Shop = require(script.Parent.Shop)
local Leaderboard = require(script.Parent.Leaderboard)

MapBuilder.Build()
Shop.Start() -- before PlayerData, so it hears every "player data loaded" signal
PlayerData.Start()
Track.Start()
Activities.Start()
RedLine.Start()
Challenges.Start()
Leaderboard.Start()

print("Red Line Challenge server ready")
