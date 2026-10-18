-- Plays the sound effects listed in Config.Sounds (only this player hears them).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage.Shared.Config)

local Sounds = {}

local folder = Instance.new("Folder")
folder.Name = "RedLineSounds"
folder.Parent = SoundService

local loaded = {} -- [name] = Sound
for name, info in Config.Sounds do
	if info.Id ~= "" then
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = info.Id
		sound.Volume = info.Volume or 0.7
		sound.PlaybackSpeed = info.Pitch or 1
		sound.Parent = folder
		loaded[name] = sound
	end
end

-- Play a sound by its name in Config.Sounds. Unknown names are ignored.
function Sounds.play(name)
	local sound = name and loaded[name]
	if sound then
		sound.TimePosition = 0
		sound:Play()
	end
end

return Sounds
