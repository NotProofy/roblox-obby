-- Training equipment, food, bed and the day clock.
-- Works on any part with the right CollectionService tag.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Activities = {}

local cooldowns = {} -- [player] = { [key] = time }

local function onCooldown(player, key, seconds)
	cooldowns[player] = cooldowns[player] or {}
	local last = cooldowns[player][key]
	if last and os.clock() - last < seconds then
		PlayerData.Notify(player, "small", "Not yet", "Wait " .. math.ceil(seconds - (os.clock() - last)) .. "s.")
		return true
	end
	cooldowns[player][key] = os.clock()
	return false
end

local function busy(player)
	return player:GetAttribute("InChallenge") ~= nil
end

-- Adds a ProximityPrompt to every part with `tag`, now and in the future
local function promptFor(tag, actionText, holdSeconds, onTriggered)
	local function setup(part)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = actionText
		prompt.ObjectText = part.Name
		prompt.HoldDuration = holdSeconds
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
		prompt.Triggered:Connect(function(player)
			if not busy(player) and PlayerData.Get(player) then
				onTriggered(player, part)
			end
		end)
	end
	for _, part in CollectionService:GetTagged(tag) do
		setup(part)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(setup)
end

local function setupTreadmills()
	local cfg = Config.Treadmill
	local function belt(part)
		-- An anchored part with velocity acts like a conveyor belt.
		-- It pushes backwards, so players face the part's front (-Z) and run.
		part.AssemblyLinearVelocity = -part.CFrame.LookVector * cfg.BeltSpeed
	end
	for _, part in CollectionService:GetTagged("Treadmill") do
		belt(part)
	end
	CollectionService:GetInstanceAddedSignal("Treadmill"):Connect(belt)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local TICK = 0.5
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and not busy(player) and humanoid.MoveDirection.Magnitude > 0.1 then
					params.FilterDescendantsInstances = { character }
					local hit = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), params)
					if hit and CollectionService:HasTag(hit.Instance, "Treadmill") then
						if PlayerData.Spend(player, cfg.EnergyPerSec * TICK) then
							PlayerData.Add(player, "Fitness", cfg.FitnessPerSec * TICK)
							PlayerData.Add(player, "Stamina", cfg.StaminaPerSec * TICK)
						end
					end
				end
			end
		end
	end)
end

function Activities.Start()
	setupTreadmills()

	promptFor("Bench", "Lift", Config.Bench.HoldSeconds, function(player)
		local cfg = Config.Bench
		if PlayerData.Spend(player, cfg.Energy) then
			PlayerData.Add(player, "Strength", cfg.Strength)
			PlayerData.Add(player, "Fitness", cfg.Fitness)
			PlayerData.Notify(player, "small", "Great set!", "+" .. cfg.Strength .. " strength")
		end
	end)

	promptFor("Hoop", "Shoot", 0.3, function(player)
		local cfg = Config.Hoop
		if PlayerData.Spend(player, cfg.Energy) then
			local made = math.random() < cfg.MakeChance
			local bonus = if made then 2 else 1
			PlayerData.Add(player, "Fitness", cfg.Fitness * bonus)
			PlayerData.Add(player, "Stamina", cfg.Stamina * bonus)
			PlayerData.Notify(player, "small", if made then "SWISH!" else "Brick...", if made then "Double reward!" else "Keep shooting.")
		end
	end)

	promptFor("HealthyFood", "Eat", 1, function(player)
		local cfg = Config.HealthyFood
		if not onCooldown(player, "healthy", cfg.Cooldown) then
			PlayerData.Add(player, "Energy", cfg.Energy)
			PlayerData.Notify(player, "small", "Healthy meal", "+" .. cfg.Energy .. " energy")
		end
	end)

	promptFor("JunkFood", "Eat", 0.5, function(player)
		local cfg = Config.JunkFood
		if not onCooldown(player, "junk", cfg.Cooldown) then
			PlayerData.Add(player, "Energy", cfg.Energy)
			PlayerData.Add(player, "Fitness", -cfg.FitnessLoss)
			PlayerData.Notify(player, "small", "Tasty... but", "-" .. cfg.FitnessLoss .. "% fitness")
		end
	end)

	promptFor("Bed", "Sleep", 1.5, function(player)
		if not onCooldown(player, "sleep", Config.SleepCooldown) then
			PlayerData.Add(player, "Energy", Config.MaxEnergy)
			PlayerData.Add(player, "Day", 1)
			PlayerData.Notify(player, "big", "DAY " .. player:GetAttribute("Day"), "Fully rested. Let's work!")
		end
	end)

	-- The day clock: everyone's day goes up over time, and the sky follows
	task.spawn(function()
		local Lighting = game:GetService("Lighting")
		local elapsed = 0
		while true do
			local dt = task.wait(1)
			elapsed += dt
			Lighting.ClockTime = 6 + (elapsed % Config.DaySeconds) / Config.DaySeconds * 18
			if elapsed >= Config.DaySeconds then
				elapsed = 0
				for _, player in Players:GetPlayers() do
					PlayerData.Add(player, "Day", 1)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
end

return Activities
