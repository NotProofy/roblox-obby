-- All the numbers you might want to tweak live here.
local Config = {}

Config.DataStoreName = "RedLineChallenge_v1"

-- Run
Config.StartPrize = 250000
Config.GoalFitness = 100
Config.DaySeconds = 120 -- one in-game day in real seconds

-- Fitness check-ins: crossing each threshold unlocks the next challenge
Config.CheckIns = { 15, 30, 45, 60, 75 }
Config.ShirtTiers = { "3XL", "2XL", "XL", "L", "M", "S" } -- index = check-ins reached + 1

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
}

Config.PushUps = { PerRep = 1000, MaxReps = 150 }
Config.CashCarry = { PerBag = 10000, MaxBags = 10, SpeedLossPerBag = 0.8, MinSpeed = 8, DropChancePerBagPerSec = 0.006 }
Config.Mile = { Reward = 25000, Laps = 3, TimeLimit = 60, BaseSpeed = 16, SpeedPerStamina = 0.08 }
Config.Hang = { PerSecond = 1000, MaxSeconds = 240 }
Config.PullUp = { Reward = 10000 }

-- Safety nets so nobody gets stuck in a challenge
Config.ChallengeTimeout = 300 -- seconds before a timing challenge is cancelled if the client never answers
Config.CarryChoiceTimeout = 45 -- seconds to pick a number of bags before Cash Carry is cancelled

-- Map layout (used by the auto map builder and the track)
Config.Map = {
	RedLineRadius = 95,
	TrackRadius = 70,
	TrackCheckpoints = 8,
	CraneHeight = 60,
}

return Config
