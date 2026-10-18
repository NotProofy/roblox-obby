-- Global leaderboard: the richest Banks across every server.
-- Each refresh writes the Bank of everyone in this server to an OrderedDataStore,
-- then reads the top rows and shows them on every part tagged "Leaderboard".
local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local Leaderboard = {}

local cfg = Config.Leaderboard
local okStore, store = pcall(function()
	return DataStoreService:GetOrderedDataStore(cfg.StoreName)
end)
local lastWritten = {} -- [userId] = Bank value we last wrote (skip writing if unchanged)
local names = {} -- [userId] = name (cache, looking names up is slow)
local boards = {} -- list of { rows = { TextLabel } }

local function nameFor(userId)
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and name then
		names[userId] = name
		return name
	end
	return "Player " .. userId
end

-- Build the sign on one tagged part. Text faces the part's Front.
local function buildBoard(part)
	if not part:IsA("BasePart") then
		warn("Tag 'Leaderboard' must be on a part")
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "LeaderboardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part

	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	background.BorderSizePixel = 0
	background.Parent = gui

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0.005, 0)
	list.Parent = background

	local rowHeight = 1 / (cfg.Rows + 2)
	local function line(order, text, color)
		local label = Instance.new("TextLabel")
		label.LayoutOrder = order
		label.Size = UDim2.fromScale(1, rowHeight)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = color
		label.Text = text
		label.Parent = background
		return label
	end
	line(0, "TOP BANKS", Color3.fromRGB(255, 205, 50))
	local rows = {}
	for i = 1, cfg.Rows do
		rows[i] = line(i, "", Color3.new(1, 1, 1))
	end
	local status = line(cfg.Rows + 1, "Loading...", Color3.fromRGB(170, 175, 190))
	table.insert(boards, { rows = rows, status = status })
end

local function writeScores()
	for _, player in Players:GetPlayers() do
		-- Only trust players whose data loaded properly (otherwise Bank could be a fake 0)
		local bank = player:GetAttribute("Bank")
		if player:GetAttribute("DataLoaded") == true and type(bank) == "number" and lastWritten[player.UserId] ~= bank then
			local ok, err = pcall(function()
				store:SetAsync("player_" .. player.UserId, math.floor(bank))
			end)
			if ok then
				lastWritten[player.UserId] = bank
			else
				warn("Leaderboard write failed: " .. tostring(err))
			end
		end
	end
end

local function refresh()
	if not okStore then
		for _, board in boards do
			board.status.Text = "Leaderboard offline"
		end
		return
	end
	writeScores()
	local ok, entries = pcall(function()
		return store:GetSortedAsync(false, cfg.Rows):GetCurrentPage()
	end)
	for _, board in boards do
		board.status.Text = if ok then "Updates every " .. cfg.RefreshSeconds .. "s" else "Leaderboard offline (try later)"
	end
	if not ok then
		warn("Leaderboard read failed: " .. tostring(entries))
		return
	end
	for i = 1, cfg.Rows do
		local entry = entries[i]
		local text = ""
		if entry then
			local userId = tonumber(string.match(entry.key, "%d+$"))
			local name = if userId then nameFor(userId) else "?"
			text = i .. ". " .. name .. "  " .. Format.money(entry.value)
		end
		for _, board in boards do
			board.rows[i].Text = text
		end
	end
end

function Leaderboard.Start()
	for _, part in CollectionService:GetTagged("Leaderboard") do
		buildBoard(part)
	end
	CollectionService:GetInstanceAddedSignal("Leaderboard"):Connect(buildBoard)

	-- Write a leaving player's final Bank so the board stays up to date
	Players.PlayerRemoving:Connect(function(player)
		local bank = player:GetAttribute("Bank")
		if okStore and player:GetAttribute("DataLoaded") == true and type(bank) == "number" and lastWritten[player.UserId] ~= bank then
			pcall(function()
				store:SetAsync("player_" .. player.UserId, math.floor(bank))
			end)
		end
		lastWritten[player.UserId] = nil
	end)

	task.spawn(function()
		task.wait(5) -- give the first players time to load
		while true do
			refresh()
			task.wait(cfg.RefreshSeconds)
		end
	end)
end

return Leaderboard
