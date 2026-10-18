-- The five micro-challenges that add money to the prize pool.
-- Timing games (push-ups, hang, pull-up) run on the client; the server checks the
-- result is possible for the time that passed. Track challenges run on the server.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)
local Track = require(script.Parent.Track)

local Challenges = {}

local active = {} -- [player] = { id, startedAt, bags, cleanup = {} }

local function spot(tag)
	return CollectionService:GetTagged(tag)[1]
end

local function getRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

local function finish(player, reward, title, body)
	local a = active[player]
	if not a then
		return
	end
	active[player] = nil
	for _, fn in a.cleanup do
		pcall(fn)
	end
	player:SetAttribute("InChallenge", nil)
	Track.SetLapHandler(player, nil)

	local profile = PlayerData.Get(player)
	if profile then
		profile.Run.ChallengesDone += 1
		if reward > 0 then
			PlayerData.Add(player, "Prize", reward)
		else
			PlayerData.Sync(player)
		end
	end
	Remotes.ChallengeBegin:FireClient(player, "End")
	PlayerData.Notify(player, "big", title, body .. "\nPrize pool: $" .. player:GetAttribute("Prize"))
end

-- Freeze the player at a spot for the client-side timing games
local function freezeAt(player, a, part, offset)
	local root, humanoid = getRoot(player)
	if not root or not part then
		return false
	end
	player.Character:PivotTo(part.CFrame + offset)
	root.Anchored = true
	table.insert(a.cleanup, function()
		root.Anchored = false
	end)
	if humanoid then
		humanoid.WalkSpeed = 0
		table.insert(a.cleanup, function()
			humanoid.WalkSpeed = 16
		end)
	end
	return true
end

local function attachBags(player, a, count)
	local root = getRoot(player)
	if not root then
		return
	end
	for i = 1, count do
		local bag = Instance.new("Part")
		bag.Name = "MoneyBag"
		bag.Size = Vector3.new(1.2, 1.2, 1.2)
		bag.Color = Color3.fromRGB(40, 150, 60)
		bag.Material = Enum.Material.Fabric
		bag.CanCollide = false
		bag.Massless = true
		local side = if i % 2 == 0 then 1 else -1
		bag.CFrame = root.CFrame * CFrame.new(side * 1.6, -0.5 + math.floor((i - 1) / 2) * 0.9 - 1, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = bag
		weld.Parent = bag
		bag.Parent = player.Character
		table.insert(a.cleanup, function()
			bag:Destroy()
		end)
	end
end

local starters = {}

starters.PushUps = function(player, a)
	if not freezeAt(player, a, spot("PushUpSpot"), Vector3.new(0, 3, 0)) then
		return false
	end
	Remotes.ChallengeBegin:FireClient(player, "PushUps", { Strength = player:GetAttribute("Strength") })
	return true
end

starters.Hang = function(player, a)
	if not freezeAt(player, a, spot("CraneSpot"), Vector3.new(0, 3.5, 0)) then
		return false
	end
	Remotes.ChallengeBegin:FireClient(player, "Hang", { Strength = player:GetAttribute("Strength") })
	return true
end

starters.PullUp = function(player, a)
	if not freezeAt(player, a, spot("CraneSpot"), Vector3.new(0, 3.5, 0)) then
		return false
	end
	Remotes.ChallengeBegin:FireClient(player, "PullUp", { Strength = player:GetAttribute("Strength") })
	return true
end

local function goToTrackStart(player)
	local root = getRoot(player)
	if not root then
		return false
	end
	player.Character:PivotTo(Track.GetStartCFrame() - Vector3.new(0, 1, 0))
	Track.Reset(player)
	return true
end

starters.CashCarry = function(player, a)
	-- First ask the client how many bags; the run starts in CarryChoice
	a.waitingForBags = true
	Remotes.ChallengeBegin:FireClient(player, "CashCarry", { MaxBags = Config.CashCarry.MaxBags, Strength = player:GetAttribute("Strength") })
	return true
end

local function startCarry(player, a, bags)
	local cfg = Config.CashCarry
	local root, humanoid = getRoot(player)
	if not root or not humanoid or not goToTrackStart(player) then
		finish(player, 0, "Challenge cancelled", "Something went wrong.")
		return
	end
	a.bags = bags
	humanoid.WalkSpeed = math.max(cfg.MinSpeed, 16 - bags * cfg.SpeedLossPerBag)
	table.insert(a.cleanup, function()
		humanoid.WalkSpeed = 16
	end)
	attachBags(player, a, bags)
	PlayerData.Notify(player, "small", "Carry $" .. bags * cfg.PerBag, "Run one lap. Don't drop anything!")

	Track.SetLapHandler(player, function()
		finish(player, bags * cfg.PerBag, "YOU MADE IT!", "+$" .. bags * cfg.PerBag .. " added to the prize pool")
	end)

	-- Every second there's a chance to drop a bag. More bags = more risk, strength helps.
	local strength = player:GetAttribute("Strength") or 0
	local chance = bags * cfg.DropChancePerBagPerSec * (1 - strength / 150)
	task.spawn(function()
		local started = os.clock()
		while active[player] == a do
			task.wait(1)
			if active[player] ~= a then
				break
			end
			if humanoid.Health <= 0 or os.clock() - started > 150 then
				finish(player, 0, "Challenge over", "You didn't finish the lap.")
			elseif math.random() < chance then
				finish(player, 0, "YOU DROPPED A BAG!", "All $" .. bags * cfg.PerBag .. " is lost.")
			end
		end
	end)
end

starters.Mile = function(player, a)
	local cfg = Config.Mile
	local _, humanoid = getRoot(player)
	if not humanoid or not goToTrackStart(player) then
		return false
	end
	local stamina = player:GetAttribute("Stamina") or 0
	humanoid.WalkSpeed = cfg.BaseSpeed + stamina * cfg.SpeedPerStamina
	table.insert(a.cleanup, function()
		humanoid.WalkSpeed = 16
	end)
	local laps = 0
	local started = os.clock()
	Remotes.ChallengeBegin:FireClient(player, "Mile", { TimeLimit = cfg.TimeLimit, Laps = cfg.Laps })
	Track.SetLapHandler(player, function()
		laps += 1
		if laps >= cfg.Laps then
			finish(player, cfg.Reward, "UNDER THE TIME!", "+$" .. cfg.Reward .. " added to the prize pool")
		else
			PlayerData.Notify(player, "small", "Lap " .. laps .. "/" .. cfg.Laps, math.floor(os.clock() - started) .. "s so far")
		end
	end)
	task.delay(cfg.TimeLimit, function()
		if active[player] == a then
			finish(player, 0, "TOO SLOW!", "Train your stamina on the treadmill.")
		end
	end)
	return true
end

-- Results from the client timing games
local function onResult(player, value)
	local a = active[player]
	if not a then
		return
	end
	local elapsed = os.clock() - a.startedAt
	if a.id == "PushUps" and type(value) == "number" then
		local cfg = Config.PushUps
		local reps = math.clamp(math.floor(value), 0, math.min(cfg.MaxReps, math.floor(elapsed / 0.35)))
		finish(player, reps * cfg.PerRep, reps .. " PUSH-UPS!", "+$" .. reps * cfg.PerRep .. " added to the prize pool")
	elseif a.id == "Hang" and type(value) == "number" then
		local cfg = Config.Hang
		local seconds = math.clamp(math.floor(value), 0, math.min(cfg.MaxSeconds, math.floor(elapsed + 1)))
		finish(player, seconds * cfg.PerSecond, "HUNG FOR " .. seconds .. "s!", "+$" .. seconds * cfg.PerSecond .. " added to the prize pool")
	elseif a.id == "PullUp" then
		if value == true and elapsed > 1 then
			finish(player, Config.PullUp.Reward, "PULL-UP!", "+$" .. Config.PullUp.Reward .. " added to the prize pool")
		else
			finish(player, 0, "So close...", "No pull-up this time.")
		end
	end
end

function Challenges.Start()
	Remotes.StartChallenge.OnServerEvent:Connect(function(player)
		local index = player:GetAttribute("NextChallenge") or 0
		if index == 0 or active[player] then
			return
		end
		local challenge = Config.Challenges[index]
		local a = { id = challenge.Id, startedAt = os.clock(), cleanup = {} }
		active[player] = a
		player:SetAttribute("InChallenge", challenge.Id)
		local ok = starters[challenge.Id](player, a)
		if not ok then
			active[player] = nil
			player:SetAttribute("InChallenge", nil)
			for _, fn in a.cleanup do
				pcall(fn)
			end
			PlayerData.Notify(player, "small", "Can't start", "Try again in a moment.")
		end
	end)

	Remotes.CarryChoice.OnServerEvent:Connect(function(player, bags)
		local a = active[player]
		if not a or a.id ~= "CashCarry" or not a.waitingForBags or type(bags) ~= "number" then
			return
		end
		a.waitingForBags = false
		bags = math.clamp(math.floor(bags), 1, Config.CashCarry.MaxBags)
		startCarry(player, a, bags)
	end)

	Remotes.ChallengeResult.OnServerEvent:Connect(onResult)

	local function cancelOnDeath(player)
		player.CharacterAdded:Connect(function()
			if active[player] then
				finish(player, 0, "Challenge over", "You respawned.")
			end
		end)
	end
	Players.PlayerAdded:Connect(cancelOnDeath)
	for _, player in Players:GetPlayers() do
		cancelOnDeath(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		active[player] = nil
	end)
end

return Challenges
