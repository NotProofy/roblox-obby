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

local lastTouch = {} -- [player] = time
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
	if lastTouch[player] and os.clock() - lastTouch[player] < 2 then
		return
	end
	lastTouch[player] = os.clock()
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end

	if profile.Run.Fitness >= Config.GoalFitness then
		PlayerData.EndRun(player, true)
		sendToSpawn(player)
		return
	end

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
		if wantsToLeave == true then
			PlayerData.EndRun(player, false)
			sendToSpawn(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastTouch[player] = nil
		waitingForAnswer[player] = nil
	end)
end

return RedLine
