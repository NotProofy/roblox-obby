-- The HUD, popups, red-line warning and challenge screens.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Format = require(ReplicatedStorage.Shared.Format)
local UI = require(script.Parent.UI)
local Minigames = require(script.Parent.Minigames)

local player = Players.LocalPlayer
local gui = UI.new("ScreenGui", { Name = "RedLineHUD", ResetOnSpawn = false, IgnoreGuiInset = false, Parent = player:WaitForChild("PlayerGui") })
local money = Format.money

-- Shrink the whole HUD on small screens (phones) so it doesn't cover the controls
local uiScale = UI.new("UIScale", { Parent = gui })
local function rescale()
	local camera = workspace.CurrentCamera
	if camera then
		local size = camera.ViewportSize
		uiScale.Scale = math.clamp(math.min(size.X / 1100, size.Y / 700), 0.55, 1)
	end
end
rescale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(rescale)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

---------------------------------------------------------------------------
-- Stats panel (top left) and prize pool (top center)
---------------------------------------------------------------------------
-- Left side, below Roblox's chat window
local stats = UI.panel({ Parent = gui, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.55, 0), Size = UDim2.fromOffset(260, 196) })
local dayLabel = UI.text({ Parent = stats, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 26), Text = "DAY 1", TextXAlignment = Enum.TextXAlignment.Left })
local shirtLabel = UI.text({ Parent = stats, Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 0, 18), Text = "", TextColor3 = UI.Colors.Dim, TextXAlignment = Enum.TextXAlignment.Left })
local _, setFitness = UI.bar(stats, UDim2.fromOffset(12, 58), UDim2.new(1, -24, 0, 28), UI.Colors.Green, "Fitness")
local _, setEnergy = UI.bar(stats, UDim2.fromOffset(12, 92), UDim2.new(1, -24, 0, 28), UI.Colors.Gold, "Energy")
local _, setStrength = UI.bar(stats, UDim2.fromOffset(12, 126), UDim2.new(1, -24, 0, 26), UI.Colors.Blue, "Strength")
local _, setStamina = UI.bar(stats, UDim2.fromOffset(12, 158), UDim2.new(1, -24, 0, 26), Color3.fromRGB(180, 90, 255), "Stamina")

local prizePanel = UI.panel({ Parent = gui, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(300, 84) })
UI.text({ Parent = prizePanel, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 18), Text = "PRIZE POOL", TextColor3 = UI.Colors.Dim })
local prizeLabel = UI.text({ Parent = prizePanel, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 38), Text = "$0", TextColor3 = UI.Colors.Gold })
local bankLabel = UI.text({ Parent = prizePanel, Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 0, 16), Text = "", TextColor3 = UI.Colors.Dim })

-- The red line turns green for you once you reach the goal
local function colorRedLine(reached)
	for _, part in CollectionService:GetTagged("RedLineVisual") do
		part.Color = if reached then UI.Colors.Green else Color3.fromRGB(255, 30, 30)
	end
end

local lastPrize = nil
local function refresh()
	local fitness = player:GetAttribute("Fitness") or 0
	dayLabel.Text = "DAY " .. (player:GetAttribute("Day") or 1)
	shirtLabel.Text = "Shirt size: " .. (player:GetAttribute("ShirtTier") or "3XL")
	setFitness(fitness / Config.GoalFitness, "Fitness " .. fitness .. "%")
	setEnergy((player:GetAttribute("Energy") or 0) / Config.MaxEnergy, "Energy " .. (player:GetAttribute("Energy") or 0))
	setStrength((player:GetAttribute("Strength") or 0) / Config.MaxStat, "Strength " .. (player:GetAttribute("Strength") or 0))
	setStamina((player:GetAttribute("Stamina") or 0) / Config.MaxStat, "Stamina " .. (player:GetAttribute("Stamina") or 0))
	local prize = player:GetAttribute("Prize") or 0
	prizeLabel.Text = money(prize)
	bankLabel.Text = "Bank: " .. money(player:GetAttribute("Bank"))
	if lastPrize and prize > lastPrize then
		prizeLabel.TextColor3 = UI.Colors.Green
		task.delay(1.5, function()
			prizeLabel.TextColor3 = UI.Colors.Gold
		end)
	end
	lastPrize = prize
	colorRedLine(fitness >= Config.GoalFitness)
end
player.AttributeChanged:Connect(refresh)
refresh()
-- Parts can stream in later, so color new red line parts too
CollectionService:GetInstanceAddedSignal("RedLineVisual"):Connect(function()
	colorRedLine((player:GetAttribute("Fitness") or 0) >= Config.GoalFitness)
end)

---------------------------------------------------------------------------
-- Notifications: small toasts (right side) and big banners (center)
---------------------------------------------------------------------------
-- Toasts sit above the bottom-right corner so they never cover the phone jump button
local toasts = UI.new("Frame", { Parent = gui, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 0.7, 0), Size = UDim2.fromOffset(280, 300) }, {
	UI.new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local toastOrder = 0

local function toast(title, body)
	toastOrder += 1
	local t = UI.panel({ Parent = toasts, Size = UDim2.new(1, 0, 0, 54), LayoutOrder = toastOrder })
	UI.text({ Parent = t, Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 24), Text = title, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Gold })
	UI.text({ Parent = t, Position = UDim2.fromOffset(10, 28), Size = UDim2.new(1, -20, 0, 20), Text = body, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UI.Colors.Dim })
	task.delay(3, function()
		t:Destroy()
	end)
end

local banner = UI.panel({ Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.35), Size = UDim2.fromOffset(520, 150), Visible = false, BackgroundColor3 = Color3.fromRGB(15, 15, 20) })
local bannerTitle = UI.text({ Parent = banner, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 56), Text = "", TextColor3 = UI.Colors.Gold })
local bannerBody = UI.text({ Parent = banner, Position = UDim2.fromOffset(16, 72), Size = UDim2.new(1, -32, 0, 66), Text = "", TextWrapped = true })
local bannerToken = 0

local function bigBanner(title, body)
	bannerToken += 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerBody.Text = body
	banner.Size = UDim2.fromOffset(420, 120)
	banner.Visible = true
	TweenService:Create(banner, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(520, 150) }):Play()
	task.delay(4, function()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

Remotes.Notify.OnClientEvent:Connect(function(kind, title, body)
	if kind == "big" then
		bigBanner(title, body)
	else
		toast(title, body)
	end
end)

---------------------------------------------------------------------------
-- Red line warning
---------------------------------------------------------------------------
local confirm = UI.panel({ Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(420, 200), Visible = false, BackgroundColor3 = Color3.fromRGB(60, 10, 10) })
UI.text({ Parent = confirm, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 40), Text = "THE RED LINE", TextColor3 = UI.Colors.Red })
local confirmBody = UI.text({ Parent = confirm, Position = UDim2.fromOffset(16, 56), Size = UDim2.new(1, -32, 0, 54), Text = "", TextWrapped = true })
local stayButton = UI.button({ Parent = confirm, Position = UDim2.new(0, 16, 1, -66), Size = UDim2.new(0.5, -24, 0, 50), Text = "STAY", BackgroundColor3 = UI.Colors.Green })
local leaveButton = UI.button({ Parent = confirm, Position = UDim2.new(0.5, 8, 1, -66), Size = UDim2.new(0.5, -24, 0, 50), Text = "LEAVE", BackgroundColor3 = UI.Colors.Red })

Remotes.ConfirmLeave.OnClientEvent:Connect(function(prize)
	confirmBody.Text = "If you leave now you lose the " .. money(prize) .. " prize pool and start over."
	confirm.Visible = true
end)
stayButton.Activated:Connect(function()
	confirm.Visible = false
	Remotes.LeaveAnswer:FireServer(false)
end)
leaveButton.Activated:Connect(function()
	confirm.Visible = false
	Remotes.LeaveAnswer:FireServer(true)
end)

---------------------------------------------------------------------------
-- Challenge button (bottom center)
---------------------------------------------------------------------------
local challengePanel = UI.panel({ Parent = gui, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(440, 110), Visible = false, BackgroundColor3 = Color3.fromRGB(40, 30, 5) })
local challengeName = UI.text({ Parent = challengePanel, Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 30), Text = "", TextColor3 = UI.Colors.Gold })
local challengeDesc = UI.text({ Parent = challengePanel, Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 0, 18), Text = "", TextColor3 = UI.Colors.Dim })
local startButton = UI.button({ Parent = challengePanel, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 60), Size = UDim2.fromOffset(220, 42), Text = "START CHALLENGE", BackgroundColor3 = UI.Colors.Green })

local function refreshChallenge()
	local index = player:GetAttribute("NextChallenge") or 0
	local busy = player:GetAttribute("InChallenge") ~= nil
	if busy and confirm.Visible then
		-- A challenge started while the red line question was open: answer "stay"
		confirm.Visible = false
		Remotes.LeaveAnswer:FireServer(false)
	end
	local challenge = Config.Challenges[index]
	challengePanel.Visible = challenge ~= nil and not busy
	if challenge then
		challengeName.Text = "CHALLENGE " .. index .. ": " .. challenge.Name
		challengeDesc.Text = challenge.Desc
	end
end
player:GetAttributeChangedSignal("NextChallenge"):Connect(refreshChallenge)
player:GetAttributeChangedSignal("InChallenge"):Connect(refreshChallenge)
refreshChallenge()

startButton.Activated:Connect(function()
	challengePanel.Visible = false
	Remotes.StartChallenge:FireServer()
end)

---------------------------------------------------------------------------
-- Challenge screens
---------------------------------------------------------------------------
local active -- UI for the current track challenge, destroyed on "End"

local function carryChooser(params)
	local maxBags = params.MaxBags or 10
	local bags = 1
	local frame = UI.panel({ Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(420, 220) })
	UI.text({ Parent = frame, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 0, 34), Text = "CASH CARRY", TextColor3 = UI.Colors.Gold })
	UI.text({ Parent = frame, Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 0, 36), Text = "More bags = more money, slower legs and a higher chance to drop. Drop one and you lose it all.", TextWrapped = true, TextColor3 = UI.Colors.Dim })
	local amount = UI.text({ Parent = frame, Position = UDim2.fromOffset(80, 92), Size = UDim2.new(1, -160, 0, 44), Text = "" })
	local minus = UI.button({ Parent = frame, Position = UDim2.fromOffset(20, 92), Size = UDim2.fromOffset(50, 44), Text = "-", BackgroundColor3 = UI.Colors.Blue })
	local plus = UI.button({ Parent = frame, Position = UDim2.new(1, -70, 0, 92), Size = UDim2.fromOffset(50, 44), Text = "+", BackgroundColor3 = UI.Colors.Blue })
	local go = UI.button({ Parent = frame, Position = UDim2.new(0.5, -110, 0, 152), Size = UDim2.fromOffset(200, 50), Text = "PICK UP & GO", BackgroundColor3 = UI.Colors.Green })
	local cancel = UI.button({ Parent = frame, Position = UDim2.new(0.5, 100, 0, 152), Size = UDim2.fromOffset(100, 50), Text = "CANCEL", BackgroundColor3 = UI.Colors.Red })
	local function show()
		amount.Text = bags .. " bag" .. (if bags == 1 then "" else "s") .. " = " .. money(bags * Config.CashCarry.PerBag)
	end
	show()
	minus.Activated:Connect(function()
		bags = math.max(1, bags - 1)
		show()
	end)
	plus.Activated:Connect(function()
		bags = math.min(maxBags, bags + 1)
		show()
	end)
	go.Activated:Connect(function()
		frame:Destroy()
		Remotes.CarryChoice:FireServer(bags)
	end)
	cancel.Activated:Connect(function()
		frame:Destroy()
		Remotes.CarryChoice:FireServer(0) -- 0 bags = cancel, the challenge stays unlocked
	end)
	return frame
end

local function mileTimer(params)
	local frame = UI.panel({ Parent = gui, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.fromOffset(240, 60) })
	local label = UI.text({ Parent = frame, Size = UDim2.fromScale(1, 1), Text = "" })
	local endsAt = os.clock() + (params.TimeLimit or 60)
	task.spawn(function()
		while frame.Parent do
			local left = math.max(0, endsAt - os.clock())
			label.Text = string.format("%.1fs  ·  %d laps", left, params.Laps or 3)
			label.TextColor3 = if left < 10 then UI.Colors.Red else UI.Colors.Text
			task.wait(0.1)
		end
	end)
	return frame
end

Remotes.ChallengeBegin.OnClientEvent:Connect(function(id, params)
	params = params or {}
	if id == "End" then
		if active then
			active:Destroy()
			active = nil
		end
		local leftover = gui:FindFirstChild("Minigame")
		if leftover then
			leftover:Destroy()
		end
		return
	end
	if id == "PushUps" or id == "Hang" or id == "PullUp" then
		Minigames[id](gui, params, function(result)
			Remotes.ChallengeResult:FireServer(result)
		end)
	elseif id == "CashCarry" then
		active = carryChooser(params)
	elseif id == "Mile" then
		active = mileTimer(params)
	end
end)
