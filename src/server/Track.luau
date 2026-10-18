-- Tracks laps around the running track. A lap = pass every checkpoint in order
-- (either direction) and come back to checkpoint 1.
-- Normal laps give fitness. Challenges can take over with Track.SetLapHandler.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Track = {}

local state = {} -- [player] = { forward, backward, handler }
local checkpointCount = 0

local function getState(player)
	if not state[player] then
		state[player] = { forward = 0, backward = 0, handler = nil }
	end
	return state[player]
end

local function defaultLap(player)
	local lap = Config.TrackLap
	if PlayerData.Spend(player, lap.Energy) then
		PlayerData.Add(player, "Fitness", lap.Fitness)
		PlayerData.Add(player, "Stamina", lap.Stamina)
		PlayerData.Notify(player, "small", "Lap complete!", "+" .. lap.Fitness .. "% fitness")
	end
end

-- progress counts checkpoints hit in a row; returns new progress and whether a lap finished
local function advance(progress, order, expectedFn)
	if order == expectedFn(progress) then
		progress += 1
		local lapDone = progress > 1 and (progress - 1) % checkpointCount == 0
		return progress, lapDone
	elseif order == 1 then
		return 1, false -- restart counting from the start line
	end
	return progress, false
end

local function onCheckpoint(player, order)
	local s = getState(player)
	local lap = false
	local done
	s.forward, done = advance(s.forward, order, function(p)
		return p % checkpointCount + 1
	end)
	lap = lap or done
	s.backward, done = advance(s.backward, order, function(p)
		if p == 0 then
			return 1
		end
		return (checkpointCount - (p % checkpointCount)) % checkpointCount + 1
	end)
	lap = lap or done
	if lap then
		s.forward, s.backward = 1, 1
		if s.handler then
			s.handler(player)
		else
			defaultLap(player)
		end
	end
end

-- Reset lap progress as if the player is standing on the start line
-- (used when a challenge teleports them there)
function Track.Reset(player)
	local s = getState(player)
	s.forward, s.backward = 1, 1
end

-- handler(player) is called on each lap instead of the normal reward. Pass nil to restore.
function Track.SetLapHandler(player, handler)
	getState(player).handler = handler
end

function Track.GetStartCFrame()
	for _, cp in CollectionService:GetTagged("TrackCP") do
		if cp:GetAttribute("Order") == 1 then
			return cp.CFrame
		end
	end
	return CFrame.new(Config.Map.TrackRadius, 3, 0)
end

local function hook(cp)
	checkpointCount = math.max(checkpointCount, cp:GetAttribute("Order") or 0)
	local recent = {}
	cp.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or (recent[player] and os.clock() - recent[player] < 1) then
			return
		end
		recent[player] = os.clock()
		onCheckpoint(player, cp:GetAttribute("Order"))
	end)
end

function Track.Start()
	for _, cp in CollectionService:GetTagged("TrackCP") do
		hook(cp)
	end
	CollectionService:GetInstanceAddedSignal("TrackCP"):Connect(hook)
	Players.PlayerRemoving:Connect(function(player)
		state[player] = nil
	end)
end

return Track
