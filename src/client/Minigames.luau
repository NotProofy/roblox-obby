-- Timing minigames for Push-Ups, Crane Hang, Pull-Up and Plank Hold.
-- Each one calls done(result) at most once when it ends. If the server ends the
-- challenge first (it destroys the "Minigame" frame), the game stops and sends nothing.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Format = require(game:GetService("ReplicatedStorage").Shared.Format)
local UI = require(script.Parent.UI)

local Minigames = {}

-- Shared frame: title, a bar area, a counter and a big TAP button (for phones)
local function makeFrame(gui, title, hint)
	local frame = UI.panel({ Parent = gui, Name = "Minigame", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.fromOffset(460, 230) })
	UI.text({ Parent = frame, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 34), Text = title, TextColor3 = UI.Colors.Gold })
	UI.text({ Parent = frame, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 20), Text = hint, TextColor3 = UI.Colors.Dim })
	local track = UI.panel({ Parent = frame, Position = UDim2.new(0, 20, 0, 72), Size = UDim2.new(1, -40, 0, 34), BackgroundColor3 = Color3.fromRGB(50, 52, 64), BackgroundTransparency = 0 })
	local counter = UI.text({ Parent = frame, Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 0, 40), Text = "" })
	local tap = UI.button({ Parent = frame, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 160), Size = UDim2.fromOffset(200, 56), Text = "TAP / SPACE", BackgroundColor3 = UI.Colors.Blue })
	return frame, track, counter, tap
end

-- Calls onPress when SPACE, click on the button, or a screen tap happens
local function listenPresses(tap, onPress)
	local connections = {}
	table.insert(connections, tap.Activated:Connect(onPress))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if UserInputService:GetFocusedTextBox() then
			return -- typing in chat, not playing
		end
		if input.KeyCode == Enum.KeyCode.Space or (not processed and input.UserInputType == Enum.UserInputType.MouseButton1) then
			onPress()
		end
	end))
	return function()
		for _, c in connections do
			c:Disconnect()
		end
	end
end

-- Runs stop() once, when the minigame frame is destroyed for any reason
local function onClosed(frame, stop)
	frame.Destroying:Connect(stop)
end

-- A green zone and a sliding marker. Returns helpers to move the zone and read the marker.
local function zoneAndMarker(track)
	local zone = UI.new("Frame", { Parent = track, BackgroundColor3 = UI.Colors.Green, BorderSizePixel = 0, Size = UDim2.fromScale(0.2, 1) }, { UI.corner(8) })
	local marker = UI.new("Frame", { Parent = track, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 6, 1, 0), ZIndex = 3 })
	local state = { zoneStart = 0.4, zoneWidth = 0.2, pos = 0, dir = 1 }
	function state.setZone(width)
		state.zoneWidth = width
		state.zoneStart = math.random() * (1 - width)
		zone.Position = UDim2.fromScale(state.zoneStart, 0)
		zone.Size = UDim2.fromScale(width, 1)
	end
	function state.step(dt, speed)
		state.pos += state.dir * speed * dt
		if state.pos > 1 then
			state.pos, state.dir = 1, -1
		elseif state.pos < 0 then
			state.pos, state.dir = 0, 1
		end
		marker.Position = UDim2.fromScale(state.pos, 0)
	end
	function state.setPos(pos)
		state.pos = math.clamp(pos, 0, 1)
		marker.Position = UDim2.fromScale(state.pos, 0)
	end
	function state.moveZone(start)
		state.zoneStart = math.clamp(start, 0, 1 - state.zoneWidth)
		zone.Position = UDim2.fromScale(state.zoneStart, 0)
	end
	function state.inZone()
		return state.pos >= state.zoneStart and state.pos <= state.zoneStart + state.zoneWidth
	end
	return state
end

function Minigames.PushUps(gui, params, done)
	local strength = params.Strength or 0
	local perRep = params.PerRep or 1000
	local frame, track, counter, tap = makeFrame(gui, "PUSH-UP PAYDAY", "Press when the marker is in the GREEN zone. Miss once and it's over.")
	local zm = zoneAndMarker(track)
	local reps, lastPress, finished, missed = 0, 0, false, false
	local function zoneWidth()
		return math.max(0.05, 0.28 - reps * 0.007 + strength * 0.001)
	end
	zm.setZone(zoneWidth())
	counter.Text = "0 reps  ·  $0"

	local stopInput
	local heartbeat
	local function stop()
		if finished then
			return
		end
		finished = true
		stopInput()
		heartbeat:Disconnect()
	end
	local function finish()
		if finished then
			return
		end
		stop()
		frame:Destroy()
		done(reps)
	end
	stopInput = listenPresses(tap, function()
		if missed or os.clock() - lastPress < 0.4 then
			return
		end
		lastPress = os.clock()
		if zm.inZone() then
			reps += 1
			counter.Text = reps .. " reps  ·  " .. Format.money(reps * perRep)
			zm.setZone(zoneWidth())
		else
			missed = true -- no more reps after a miss
			counter.Text = "MISSED! " .. reps .. " reps"
			counter.TextColor3 = UI.Colors.Red
			task.delay(1, finish)
		end
	end)
	heartbeat = RunService.Heartbeat:Connect(function(dt)
		zm.step(dt, 0.7 + reps * 0.035)
	end)
	onClosed(frame, stop)
end

function Minigames.Hang(gui, params, done)
	local strength = params.Strength or 0
	local perSecond = params.PerSecond or 1000
	local frame, track, counter, tap = makeFrame(gui, "CRANE HANG", "Mash to keep your GRIP up. " .. Format.money(perSecond) .. " every second!")
	local fill = UI.new("Frame", { Parent = track, BackgroundColor3 = UI.Colors.Gold, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, { UI.corner(8) })
	local grip, elapsed, finished = 100, 0, false
	local baseDrain = math.max(8, 26 - strength * 0.16)

	local stopInput = listenPresses(tap, function()
		grip = math.min(100, grip + 6)
	end)
	local heartbeat
	heartbeat = RunService.Heartbeat:Connect(function(dt)
		if finished then
			return
		end
		elapsed += dt
		grip -= (baseDrain + elapsed * 0.25) * dt
		fill.Size = UDim2.fromScale(math.max(grip, 0) / 100, 1)
		fill.BackgroundColor3 = if grip < 30 then UI.Colors.Red else UI.Colors.Gold
		counter.Text = math.floor(elapsed) .. "s  ·  " .. Format.money(math.floor(elapsed) * perSecond)
		if grip <= 0 then
			finished = true
			heartbeat:Disconnect()
			stopInput()
			counter.Text = "YOU LET GO at " .. math.floor(elapsed) .. "s"
			task.delay(1, function()
				if frame.Parent then
					frame:Destroy()
					done(math.floor(elapsed))
				end
			end)
		end
	end)
	onClosed(frame, function()
		finished = true
		heartbeat:Disconnect()
		stopInput()
	end)
end

function Minigames.PullUp(gui, params, done)
	local strength = params.Strength or 0
	local frame, track, counter, tap = makeFrame(gui, "THE PULL-UP", "One try. Press when the marker hits GREEN.")
	local zm = zoneAndMarker(track)
	zm.setZone(math.min(0.25, 0.05 + strength * 0.0015))
	counter.Text = "Get ready..."
	local startedAt = os.clock()
	local finished = false
	local stopInput
	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		zm.step(dt, 1.3)
	end)
	stopInput = listenPresses(tap, function()
		if finished or os.clock() - startedAt < 1.2 then
			return
		end
		finished = true
		local success = zm.inZone()
		heartbeat:Disconnect()
		stopInput()
		counter.Text = if success then "PULL-UP!" else "Not quite..."
		counter.TextColor3 = if success then UI.Colors.Green else UI.Colors.Red
		task.delay(1, function()
			if frame.Parent then
				frame:Destroy()
				done(success)
			end
		end)
	end)
	onClosed(frame, function()
		finished = true
		heartbeat:Disconnect()
		stopInput()
	end)
end

function Minigames.Plank(gui, params, done)
	local strength = params.Strength or 0
	local perSecond = params.PerSecond or 1500
	local maxSeconds = params.MaxSeconds or 120
	local drain = params.FormDrainPerSec or 35
	local refill = params.FormRefillPerSec or 10
	local frame, track, counter, tap = makeFrame(gui, "PLANK HOLD", "HOLD to lift, let go to drop. Keep the marker in the GREEN!")
	tap.Text = "HOLD / SPACE"
	local zm = zoneAndMarker(track)
	zm.setZone(math.min(0.35, 0.18 + strength * 0.0015))
	zm.moveZone(0.5 - zm.zoneWidth / 2)
	zm.setPos(0.5)
	-- The "form" meter sits under the bar
	local formBack = UI.panel({ Parent = frame, Position = UDim2.new(0, 20, 0, 108), Size = UDim2.new(1, -40, 0, 8), BackgroundColor3 = Color3.fromRGB(50, 52, 64), BackgroundTransparency = 0 })
	local formFill = UI.new("Frame", { Parent = formBack, BackgroundColor3 = UI.Colors.Green, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) })

	local holding, velocity, form, elapsed, finished = false, 0, 100, 0, false
	local connections = {
		tap.MouseButton1Down:Connect(function()
			holding = true
		end),
		tap.MouseButton1Up:Connect(function()
			holding = false
		end),
		UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.Space and not UserInputService:GetFocusedTextBox() then
				holding = true
			end
		end),
		UserInputService.InputEnded:Connect(function(input)
			-- Also let go if the finger/mouse is released somewhere off the button
			local inputType = input.UserInputType
			if input.KeyCode == Enum.KeyCode.Space or inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
				holding = false
			end
		end),
	}
	local heartbeat
	local function stop()
		finished = true
		for _, c in connections do
			c:Disconnect()
		end
		if heartbeat then
			heartbeat:Disconnect()
		end
	end
	heartbeat = RunService.Heartbeat:Connect(function(dt)
		if finished then
			return
		end
		elapsed += dt
		-- Holding pushes the marker up, gravity pulls it down, and a wobble makes it harder over time
		local wobble = math.sin(elapsed * 2.3) * (0.4 + elapsed * 0.01)
		velocity += ((if holding then 1.6 else -1.6) + wobble) * dt
		velocity *= 0.97
		zm.setPos(zm.pos + velocity * dt)
		if zm.pos <= 0 or zm.pos >= 1 then
			velocity = 0
		end
		-- The green zone slowly drifts
		zm.moveZone(0.5 - zm.zoneWidth / 2 + math.sin(elapsed * 0.7) * 0.25)

		form = math.clamp(form + (if zm.inZone() then refill else -drain) * dt, 0, 100)
		formFill.Size = UDim2.fromScale(form / 100, 1)
		formFill.BackgroundColor3 = if form < 30 then UI.Colors.Red else UI.Colors.Green
		local seconds = math.floor(elapsed)
		counter.Text = seconds .. "s  ·  " .. Format.money(seconds * perSecond)
		if form <= 0 or elapsed >= maxSeconds then
			stop()
			counter.Text = if form <= 0 then "YOU DROPPED at " .. seconds .. "s" else "MAX TIME! " .. seconds .. "s"
			task.delay(1, function()
				if frame.Parent then
					frame:Destroy()
					done(seconds)
				end
			end)
		end
	end)
	onClosed(frame, stop)
end

return Minigames
