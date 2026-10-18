-- The red line around the compound.
-- Before the goal: touching it asks "leave and lose the prize pool?"
-- After the goal: touching it wins the prize pool.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)

local RedLine = {}

local lastTouch = {} -- [player] = time (stops one step firing dozens of touches)
local waitingForAnswer = {} -- [player] = true

local function sendToSpawn(player)
	local character = player.Character
	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if character and spawn then
		character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
	end
end

local function pushInside(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
		local inward = if flat.Magnitude > 0 then -flat.Unit else Vector3.zAxis
		character:PivotTo(CFrame.new(root.Position + inward * 12, root.Position + inward * 20))
	end
end

local function onTouched(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or player:GetAttribute("InChallenge") then
		return
	end
	-- A short wait between touches. It must be short, or a player could walk
	-- straight through the line while it is ignoring them.
	if lastTouch[player] and os.clock() - lastTouch[player] < 0.3 then
		return
	end
	lastTouch[player] = os.clock()
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if profile.Run.Fitness >= Config.GoalFitness then
		waitingForAnswer[player] = nil
		PlayerData.EndRun(player, true)
		sendToSpawn(player)
		return
	end

	-- Always push them back in. Only ask the question once until they answer.
	pushInside(player)
	if not waitingForAnswer[player] then
		waitingForAnswer[player] = true
		Remotes.ConfirmLeave:FireClient(player, profile.Run.Prize)
	end
end

function RedLine.Start()
	local function hook(part)
		part.Touched:Connect(onTouched)
	end
	for _, part in CollectionService:GetTagged("RedLine") do
		hook(part)
	end
	CollectionService:GetInstanceAddedSignal("RedLine"):Connect(hook)

	Remotes.LeaveAnswer.OnServerEvent:Connect(function(player, wantsToLeave)
		if not waitingForAnswer[player] then
			return
		end
		waitingForAnswer[player] = nil
		local profile = PlayerData.Get(player)
		-- Can't leave in the middle of a challenge (the run would reset under it)
		if wantsToLeave ~= true or not profile or player:GetAttribute("InChallenge") then
			return
		end
		-- If they reached the goal while the question was open, that's a win, not a loss
		PlayerData.EndRun(player, profile.Run.Fitness >= Config.GoalFitness)
		sendToSpawn(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastTouch[player] = nil
		waitingForAnswer[player] = nil
	end)
end

return RedLine
