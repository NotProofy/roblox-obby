-- Loads, saves and changes each player's data.
-- Values the client needs are mirrored onto Player attributes so the HUD can read them.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Format = require(ReplicatedStorage.Shared.Format)

local store = DataStoreService:GetDataStore(Config.DataStoreName)

local PlayerData = {}
local profiles = {} -- [player] = data table (this is what gets saved)
local session = {} -- [player] = { LastTiredNotice = time } (never saved)
local loadFailed = {} -- [player] = true if loading failed, so we never overwrite their save
local pendingSaves = 0 -- how many saves are running right now (used when the server shuts down)

local function newRun()
	return {
		Fitness = 0,
		Strength = 0,
		Stamina = 0,
		Energy = Config.MaxEnergy,
		Prize = Config.StartPrize,
		Day = 1,
		CheckIns = 0, -- how many fitness check-ins reached
		ChallengesDone = 0,
	}
end

local function newProfile()
	return { Bank = 0, Wins = 0, BestDays = 0, Run = newRun() }
end

local function withRetries(fn)
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn("DataStore attempt " .. attempt .. " failed: " .. tostring(result))
		if attempt < 3 then
			task.wait(attempt * 2)
		end
	end
	return false, nil
end

-- Copy values from a saved table into a fresh default table.
-- Only keys the default has, with the same type, are copied. This means old saves
-- get any new fields automatically and a broken value can't crash the game.
local function merge(into, saved)
	for key, default in into do
		local value = saved[key]
		if value ~= nil and type(value) == type(default) then
			if type(default) == "table" then
				merge(default, value)
			else
				into[key] = value
			end
		end
	end
end

-- Copy the data onto attributes + leaderstats so clients can see it
function PlayerData.Sync(player)
	local p = profiles[player]
	if not p then
		return
	end
	local run = p.Run
	player:SetAttribute("Fitness", math.floor(run.Fitness * 10) / 10)
	player:SetAttribute("Strength", math.floor(run.Strength))
	player:SetAttribute("Stamina", math.floor(run.Stamina))
	player:SetAttribute("Energy", math.floor(run.Energy))
	player:SetAttribute("Prize", run.Prize)
	player:SetAttribute("Day", run.Day)
	player:SetAttribute("Bank", p.Bank)
	player:SetAttribute("ShirtTier", Config.ShirtTiers[math.min(run.CheckIns + 1, #Config.ShirtTiers)])
	local ready = run.ChallengesDone < run.CheckIns and run.ChallengesDone < #Config.Challenges
	player:SetAttribute("NextChallenge", if ready then run.ChallengesDone + 1 else 0)

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Bank.Value = p.Bank
		stats.Wins.Value = p.Wins
	end
end

function PlayerData.Get(player)
	return profiles[player]
end

function PlayerData.Notify(player, kind, title, body)
	Remotes.Notify:FireClient(player, kind, title, body or "")
end

local function checkIns(player, run)
	while run.CheckIns < #Config.CheckIns and run.Fitness >= Config.CheckIns[run.CheckIns + 1] do
		run.CheckIns += 1
		local challenge = Config.Challenges[run.CheckIns]
		local tier = Config.ShirtTiers[math.min(run.CheckIns + 1, #Config.ShirtTiers)]
		local body = "New shirt size: " .. tier
		if challenge then
			body ..= "\nChallenge unlocked: " .. challenge.Name
		end
		PlayerData.Notify(player, "big", "CHECK-IN: " .. math.floor(run.Fitness) .. "% FIT!", body)
	end
end

-- Change a stat by `amount`. Handles limits, check-ins and the goal.
function PlayerData.Add(player, stat, amount)
	local p = profiles[player]
	if not p then
		return
	end
	local run = p.Run
	local before = run[stat]
	if stat == "Energy" then
		run.Energy = math.clamp(run.Energy + amount, 0, Config.MaxEnergy)
	elseif stat == "Fitness" then
		run.Fitness = math.clamp(run.Fitness + amount, 0, Config.GoalFitness)
		checkIns(player, run)
		if before < Config.GoalFitness and run.Fitness >= Config.GoalFitness then
			PlayerData.Notify(
				player,
				"big",
				"GOAL REACHED!",
				"The red line is green. Walk out to claim " .. Format.money(run.Prize) .. "!"
			)
		end
	elseif stat == "Strength" or stat == "Stamina" then
		run[stat] = math.clamp(run[stat] + amount, 0, Config.MaxStat)
	else
		run[stat] += amount
	end
	PlayerData.Sync(player)
end

-- Spend energy. Returns false (and tells the player) if they don't have enough.
function PlayerData.Spend(player, energy)
	local p = profiles[player]
	local s = session[player]
	if not p or not s then
		return false
	end
	if p.Run.Energy < energy then
		-- Don't spam the message every tick
		if os.clock() - (s.LastTiredNotice or 0) > 5 then
			s.LastTiredNotice = os.clock()
			PlayerData.Notify(player, "small", "Too tired!", "Eat something or sleep in the bed.")
		end
		return false
	end
	PlayerData.Add(player, "Energy", -energy)
	return true
end

-- End the current run. won = true pays out the prize pool.
function PlayerData.EndRun(player, won)
	local p = profiles[player]
	if not p then
		return
	end
	local run = p.Run
	if won then
		p.Bank += run.Prize
		p.Wins += 1
		if p.BestDays == 0 or run.Day < p.BestDays then
			p.BestDays = run.Day
		end
		PlayerData.Notify(player, "big", "YOU WON " .. Format.money(run.Prize) .. "!", "Finished in " .. run.Day .. " days. A new run begins!")
	else
		PlayerData.Notify(player, "big", "YOU CROSSED THE LINE", "The " .. Format.money(run.Prize) .. " prize pool is gone. Try again!")
	end
	p.Run = newRun()
	PlayerData.Sync(player)
end

local function save(player)
	local p = profiles[player]
	if not p or loadFailed[player] then
		return
	end
	pendingSaves += 1
	withRetries(function()
		store:SetAsync("player_" .. player.UserId, p)
	end)
	pendingSaves -= 1
end

local function onPlayerAdded(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local bank = Instance.new("IntValue")
	bank.Name = "Bank"
	bank.Parent = stats
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = stats
	stats.Parent = player

	local ok, saved = withRetries(function()
		return store:GetAsync("player_" .. player.UserId)
	end)
	local profile = newProfile()
	if ok and type(saved) == "table" then
		merge(profile, saved)
	end
	if not player.Parent then
		return -- left while loading
	end
	if not ok then
		-- Loading failed (DataStores down, or API access off in Studio). Let them play,
		-- but never save, or we'd overwrite their real data with this empty profile.
		loadFailed[player] = true
		PlayerData.Notify(player, "small", "Saving is off", "Your data couldn't load, so this visit won't save.")
	end
	session[player] = {}
	profiles[player] = profile
	PlayerData.Sync(player)
end

function PlayerData.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
		session[player] = nil
		loadFailed[player] = nil
	end)
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			task.spawn(save, player)
		end
		-- Wait until every save has finished (Roblox allows up to 30 seconds here)
		local started = os.clock()
		repeat
			task.wait(0.5)
		until pendingSaves <= 0 or os.clock() - started > 25
	end)
	-- Autosave every 2 minutes
	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in Players:GetPlayers() do
				task.spawn(save, player)
			end
		end
	end)
end

return PlayerData
