-- One place that creates (server) or finds (client) every RemoteEvent.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"Notify", -- server -> client: (kind, title, body)
	"ConfirmLeave", -- server -> client: (prizeAmount)
	"LeaveAnswer", -- client -> server: (wantsToLeave: boolean)
	"StartChallenge", -- client -> server
	"ChallengeBegin", -- server -> client: (challengeId, params)
	"ChallengeResult", -- client -> server: (value)
	"CarryChoice", -- client -> server: (bags: number)
}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local Remotes = {}
for _, name in NAMES do
	Remotes[name] = folder:WaitForChild(name)
end
return Remotes
