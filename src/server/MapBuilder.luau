-- Builds a simple playable compound out of plain parts if the place doesn't have one.
-- To use your own map: build a Model called "Compound" in Workspace and tag your parts
-- the same way (Treadmill, Bench, Hoop, HealthyFood, JunkFood, Bed, RedLine, TrackCP,
-- PushUpSpot, CraneSpot, Leaderboard). This builder then does nothing.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

local compound

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		if key ~= "Tag" and key ~= "Parent" then
			p[key] = value
		end
	end
	if props.Tag then
		CollectionService:AddTag(p, props.Tag)
	end
	p.Parent = props.Parent or compound
	return p
end

local function label(adornee, text, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 40)
	gui.StudsOffset = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 80
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Parent = gui
	gui.Parent = adornee
end

local function ring(radius, segments, build)
	for i = 0, segments - 1 do
		local angle = (i / segments) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
		build(i, pos, CFrame.lookAt(pos, pos + tangent), radius * math.pi * 2 / segments)
	end
end

function MapBuilder.Build()
	if workspace:FindFirstChild("Compound") then
		return
	end
	compound = Instance.new("Model")
	compound.Name = "Compound"
	compound.Parent = workspace

	local map = Config.Map

	-- Ground and floor
	part({ Name = "Ground", Size = Vector3.new(600, 2, 600), Position = Vector3.new(0, -1, 0), Color = Color3.fromRGB(86, 160, 72), Material = Enum.Material.Grass })
	local floor = part({ Name = "Floor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, map.RedLineRadius * 2, map.RedLineRadius * 2), CFrame = CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 200, 195), Material = Enum.Material.Concrete })
	floor.CanCollide = true

	-- Running track and its checkpoints
	ring(map.TrackRadius, 48, function(_, pos, cf, length)
		part({ Name = "Track", Size = Vector3.new(10, 0.3, length + 0.5), CFrame = cf + Vector3.new(0, 0.45, 0), Color = Color3.fromRGB(176, 82, 52), Material = Enum.Material.Slate })
	end)
	ring(map.TrackRadius, map.TrackCheckpoints, function(i, pos, cf)
		local cp = part({ Name = "TrackCP" .. (i + 1), Size = Vector3.new(12, 10, 2), CFrame = cf + Vector3.new(0, 5, 0), Transparency = 1, CanCollide = false, Tag = "TrackCP" })
		cp:SetAttribute("Order", i + 1)
		if i == 0 then
			part({ Name = "StartLine", Size = Vector3.new(10, 0.35, 1), CFrame = cf + Vector3.new(0, 0.5, 0), Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon })
			label(cp, "START / FINISH")
		end
	end)

	-- The red line (visual ring + tall invisible trigger)
	ring(map.RedLineRadius, 64, function(_, pos, cf, length)
		part({ Name = "RedLineVisual", Size = Vector3.new(2, 0.3, length + 0.3), CFrame = cf + Vector3.new(0, 0.45, 0), Color = Color3.fromRGB(255, 30, 30), Material = Enum.Material.Neon, CanCollide = false, Tag = "RedLineVisual" })
		part({ Name = "RedLine", Size = Vector3.new(4, 40, length + 0.3), CFrame = cf + Vector3.new(0, 20, 0), Transparency = 1, CanCollide = false, Tag = "RedLine" })
	end)

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.6, 20)
	spawn.Color = Color3.fromRGB(80, 80, 90)
	spawn.Duration = 0
	spawn.Parent = compound

	-- Treadmills
	for i = 0, 2 do
		local x = -40 + i * 7
		part({ Name = "TreadmillBase", Size = Vector3.new(5, 1, 10), Position = Vector3.new(x, 0.9, -20), Color = Color3.fromRGB(40, 40, 45) })
		part({ Name = "Treadmill", Size = Vector3.new(3.6, 0.3, 9), Position = Vector3.new(x, 1.55, -20), Color = Color3.fromRGB(20, 20, 20), Material = Enum.Material.Fabric, Tag = "Treadmill" })
		part({ Name = "Console", Size = Vector3.new(4, 4, 0.6), Position = Vector3.new(x, 3.5, -25), Color = Color3.fromRGB(60, 60, 70) })
	end
	label(compound:FindFirstChild("Console"), "TREADMILLS")

	-- Weight bench
	local bench = part({ Name = "Bench", Size = Vector3.new(3, 2, 7), Position = Vector3.new(-33, 1.4, 8), Color = Color3.fromRGB(30, 30, 120), Tag = "Bench" })
	part({ Name = "Barbell", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 0.4, 0.4), Position = Vector3.new(-33, 4.5, 6), Color = Color3.fromRGB(180, 180, 180), Material = Enum.Material.Metal })
	for _, side in { -1, 1 } do
		part({ Name = "Plate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2.4, 2.4), Position = Vector3.new(-33 + side * 3.3, 4.5, 6), Color = Color3.fromRGB(20, 20, 20) })
	end
	label(bench, "WEIGHT BENCH")

	-- Basketball hoop
	local hoop = part({ Name = "Hoop", Size = Vector3.new(1, 12, 1), Position = Vector3.new(35, 6, -25), Color = Color3.fromRGB(90, 90, 90), Material = Enum.Material.Metal, Tag = "Hoop" })
	part({ Name = "Backboard", Size = Vector3.new(7, 4.5, 0.4), Position = Vector3.new(35, 12, -24), Color = Color3.new(1, 1, 1) })
	part({ Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2.6, 2.6), CFrame = CFrame.new(35, 10.5, -22.4) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 100, 0), CanCollide = false })
	part({ Name = "Court", Size = Vector3.new(20, 0.3, 18), Position = Vector3.new(35, 0.5, -18), Color = Color3.fromRGB(200, 140, 70), Material = Enum.Material.WoodPlanks })
	label(hoop, "BASKETBALL")

	-- Kitchen
	part({ Name = "Counter", Size = Vector3.new(14, 3, 4), Position = Vector3.new(35, 1.7, 15), Color = Color3.fromRGB(230, 230, 230), Material = Enum.Material.Marble })
	local healthy = part({ Name = "HealthyFood", Size = Vector3.new(2.5, 1.2, 2.5), Position = Vector3.new(31, 3.8, 15), Color = Color3.fromRGB(60, 200, 80), Tag = "HealthyFood" })
	label(healthy, "HEALTHY MEAL", Color3.fromRGB(120, 255, 120))
	local junk = part({ Name = "JunkFood", Size = Vector3.new(2.5, 1.2, 2.5), Position = Vector3.new(39, 3.8, 15), Color = Color3.fromRGB(240, 140, 30), Tag = "JunkFood" })
	label(junk, "JUNK FOOD", Color3.fromRGB(255, 170, 60))

	-- Bed
	local bed = part({ Name = "Bed", Size = Vector3.new(6, 1.6, 9), Position = Vector3.new(0, 1.2, 45), Color = Color3.fromRGB(70, 110, 200), Material = Enum.Material.Fabric, Tag = "Bed" })
	part({ Name = "Pillow", Size = Vector3.new(4, 0.8, 1.6), Position = Vector3.new(0, 2.3, 49), Color = Color3.new(1, 1, 1), Material = Enum.Material.Fabric })
	label(bed, "BED (sleep)")

	-- Push-up mat
	local mat = part({ Name = "PushUpSpot", Size = Vector3.new(4, 0.3, 8), Position = Vector3.new(-12, 0.55, 8), Color = Color3.fromRGB(150, 40, 160), Material = Enum.Material.Fabric, Tag = "PushUpSpot" })
	label(mat, "PUSH-UP MAT")

	-- Crane with a hanging bar
	local cx, cz, h = 0, -50, map.CraneHeight
	part({ Name = "CraneTower", Size = Vector3.new(4, h + 10, 4), Position = Vector3.new(cx - 10, (h + 10) / 2, cz), Color = Color3.fromRGB(240, 190, 20), Material = Enum.Material.DiamondPlate })
	part({ Name = "CraneArm", Size = Vector3.new(16, 2, 2), Position = Vector3.new(cx - 2, h + 9, cz), Color = Color3.fromRGB(240, 190, 20), Material = Enum.Material.DiamondPlate })
	part({ Name = "Cable", Size = Vector3.new(0.3, 3, 0.3), Position = Vector3.new(cx, h + 6.5, cz), Color = Color3.fromRGB(30, 30, 30) })
	part({ Name = "HangBar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 0.5, 0.5), Position = Vector3.new(cx, h + 5, cz), Color = Color3.fromRGB(200, 200, 200), Material = Enum.Material.Metal })
	part({ Name = "CraneSpot", Size = Vector3.new(10, 1, 10), Position = Vector3.new(cx, h - 0.5, cz), Color = Color3.fromRGB(60, 60, 60), Material = Enum.Material.DiamondPlate, Tag = "CraneSpot", Transparency = 0.2 })
	label(compound:FindFirstChild("CraneTower"), "THE CRANE")

	-- Global leaderboard sign near the spawn, facing it
	local boardPos = Vector3.new(16, 7, 30)
	local facing = Vector3.new(0, 7, 20)
	part({ Name = "Leaderboard", Size = Vector3.new(10, 12, 0.5), CFrame = CFrame.lookAt(boardPos, facing), Color = Color3.fromRGB(20, 22, 30), Tag = "Leaderboard" })
	part({ Name = "LeaderboardPost", Size = Vector3.new(0.6, 1, 0.6), Position = Vector3.new(16, 0.5, 30), Color = Color3.fromRGB(60, 60, 70) })
end

return MapBuilder
