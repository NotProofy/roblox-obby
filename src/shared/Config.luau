-- All the numbers you might want to tweak live here.
local Config = {}

Config.DataStoreName = "RedLineChallenge_v1"

-- Run
Config.StartPrize = 250000
Config.GoalFitness = 100
Config.DaySeconds = 120 -- one in-game day in real seconds

-- Fitness check-ins: crossing each threshold unlocks the next challenge
Config.CheckIns = { 15, 30, 45, 60, 75, 90 }
Config.ShirtTiers = { "3XL", "2XL", "XL", "L", "M", "S", "XS" } -- index = check-ins reached + 1

-- Energy
Config.MaxEnergy = 100
Config.SleepCooldown = 60

-- Activities: what each one costs and gives
Config.Treadmill = { EnergyPerSec = 1.5, FitnessPerSec = 0.08, StaminaPerSec = 0.12, BeltSpeed = 14 }
Config.Bench = { HoldSeconds = 3, Energy = 12, Strength = 2, Fitness = 0.6 }
Config.Hoop = { Energy = 5, Fitness = 0.3, Stamina = 0.3, MakeChance = 0.45 }
Config.TrackLap = { Energy = 10, Fitness = 1.5, Stamina = 1 }
Config.HealthyFood = { Energy = 25, Cooldown = 20 }
Config.JunkFood = { Energy = 45, FitnessLoss = 2, Cooldown = 10 }

Config.MaxStat = 100 -- cap for Strength and Stamina
Config.WalkSpeed = 16 -- normal walking speed (challenges change it and put it back to this)

-- Challenges, played in this order
Config.Challenges = {
	{ Id = "PushUps", Name = "Push-Up Payday", Desc = "$1,000 for every push-up. Press SPACE in the green zone." },
	{ Id = "CashCarry", Name = "Cash Carry", Desc = "Carry $10k bags for one lap. Drop one and you lose it all." },
	{ Id = "Mile", Name = "Beat the Mile", Desc = "Run 3 laps before time runs out to win $25,000." },
	{ Id = "Hang", Name = "Crane Hang", Desc = "$1,000 per second. Mash SPACE to keep your grip." },
	{ Id = "PullUp", Name = "The Pull-Up", Desc = "One perfect press wins $10,000." },
	{ Id = "Plank", Name = "Plank Hold", Desc = "$1,500 per second. Hold to keep your body in the green." },
}

Config.PushUps = { PerRep = 1000, MaxReps = 150 }
Config.CashCarry = { PerBag = 10000, MaxBags = 10, SpeedLossPerBag = 0.8, MinSpeed = 8, DropChancePerBagPerSec = 0.006 }
Config.Mile = { Reward = 25000, Laps = 3, TimeLimit = 60, BaseSpeed = 16, SpeedPerStamina = 0.08 }
Config.Hang = { PerSecond = 1000, MaxSeconds = 240 }
Config.PullUp = { Reward = 10000 }
-- Plank Hold: holding SPACE/the button lifts the marker, letting go drops it.
-- Form drains while you're outside the green zone; at 0 form the plank is over.
Config.Plank = { PerSecond = 1500, MaxSeconds = 120, FormDrainPerSec = 35, FormRefillPerSec = 10 }

-- Safety nets so nobody gets stuck in a challenge
Config.ChallengeTimeout = 300 -- seconds before a timing challenge is cancelled if the client never answers
Config.CarryChoiceTimeout = 45 -- seconds to pick a number of bags before Cash Carry is cancelled

-- Shop: cosmetics bought with Bank money (your lifetime winnings).
-- Id must never change once players have bought it (it's what gets saved).
Config.Shop = {
	Shirts = {
		{ Id = "ShirtRed", Name = "Red", Price = 25000, Color = Color3.fromRGB(220, 50, 50) },
		{ Id = "ShirtBlue", Name = "Blue", Price = 25000, Color = Color3.fromRGB(50, 110, 230) },
		{ Id = "ShirtGreen", Name = "Green", Price = 50000, Color = Color3.fromRGB(50, 190, 80) },
		{ Id = "ShirtGold", Name = "Gold", Price = 150000, Color = Color3.fromRGB(255, 200, 40) },
		{ Id = "ShirtBlack", Name = "Black", Price = 100000, Color = Color3.fromRGB(30, 30, 35) },
	},
	Trails = {
		{ Id = "TrailWhite", Name = "Speed Lines", Price = 50000, Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 200, 255) } },
		{ Id = "TrailFire", Name = "Fire", Price = 150000, Colors = { Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 60, 20) } },
		{ Id = "TrailCash", Name = "Cash", Price = 250000, Colors = { Color3.fromRGB(120, 255, 120), Color3.fromRGB(20, 140, 50) } },
		{ Id = "TrailRainbow", Name = "Rainbow", Price = 500000, Colors = { Color3.fromRGB(255, 60, 60), Color3.fromRGB(60, 120, 255) } },
	},
	-- Optional: the ID of a plain white Shirt template from the Creator Store, e.g. "rbxassetid://123".
	-- If set, everyone wearing a shop color gets this shirt, tinted. If empty, the player's own
	-- shirt is tinted instead (or their torso is colored if they have no shirt).
	ShirtTemplate = "",
}

-- Global leaderboard board (needs API Services on in Studio, like saving)
Config.Leaderboard = { StoreName = "RedLineBank_v1", RefreshSeconds = 60, Rows = 10 }

-- Sound effects. SWAP THESE for any free sound from the Creator Store:
-- open a sound in the Creator Store, copy the number in its link and write "rbxassetid://NUMBER".
-- The defaults are sounds built into every Roblox client, so they always work but are basic.
Config.Sounds = {
	CheckIn = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.8, Pitch = 1 },
	ChallengeWin = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.8, Pitch = 1.3 },
	ChallengeFail = { Id = "rbxasset://sounds/uuhhh.mp3", Volume = 0.7, Pitch = 1 },
	Coin = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 2 },
	RedLineWarning = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 1, Pitch = 0.5 },
}

-- Map layout (used by the auto map builder and the track)
Config.Map = {
	RedLineRadius = 95,
	TrackRadius = 70,
	TrackCheckpoints = 8,
	CraneHeight = 60,
}

return Config
