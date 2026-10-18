-- The cosmetics shop: shirt colors and character trails, bought with Bank money.
-- Items are listed in Config.Shop. What a player owns and wears is saved in PlayerData.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Format = require(ReplicatedStorage.Shared.Format)
local PlayerData = require(script.Parent.PlayerData)

local Shop = {}

local CATEGORIES = { "Shirts", "Trails" }

-- Find an item by Id. Returns the item and its category.
local function findItem(id)
	for _, category in CATEGORIES do
		for _, item in Config.Shop[category] do
			if item.Id == id then
				return item, category
			end
		end
	end
	return nil, nil
end

-- The player's own colors, saved the first time we change them, so "take off" can undo it
local originalColors = {} -- [character] = { [instance] = { [propertyName] = value } }

-- Remember a property's first value, and return that original value
local function original(character, inst, propertyName)
	originalColors[character] = originalColors[character] or {}
	local saved = originalColors[character]
	saved[inst] = saved[inst] or {}
	if saved[inst][propertyName] == nil then
		saved[inst][propertyName] = inst[propertyName]
	end
	return saved[inst][propertyName]
end

local function applyShirt(player, character)
	local item = findItem(player:GetAttribute("EquippedShirts") or "")
	local color = item and item.Color

	-- Optional shop shirt template: give everyone with a shop color the same plain shirt
	local shirt = character:FindFirstChildOfClass("Shirt")
	if color and Config.Shop.ShirtTemplate ~= "" then
		if not shirt then
			shirt = Instance.new("Shirt")
			shirt.Parent = character
		end
		original(character, shirt, "ShirtTemplate")
		shirt.ShirtTemplate = Config.Shop.ShirtTemplate
	end

	if shirt then
		local before = original(character, shirt, "Color3") -- remember it before changing it
		shirt.Color3 = color or before
		if not color and Config.Shop.ShirtTemplate ~= "" then
			shirt.ShirtTemplate = original(character, shirt, "ShirtTemplate")
		end
	else
		-- No shirt at all: color the torso so the color still shows
		for _, name in { "UpperTorso", "LowerTorso", "Torso" } do
			local bodyPart = character:FindFirstChild(name)
			if bodyPart and bodyPart:IsA("BasePart") then
				local before = original(character, bodyPart, "Color")
				bodyPart.Color = color or before
			end
		end
	end
end

local function applyTrail(player, character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local old = root:FindFirstChild("ShopTrail")
	if old then
		old:Destroy()
	end
	for _, name in { "ShopTrailTop", "ShopTrailBottom" } do
		local attachment = root:FindFirstChild(name)
		if attachment then
			attachment:Destroy()
		end
	end

	local item = findItem(player:GetAttribute("EquippedTrails") or "")
	if not item then
		return
	end
	local top = Instance.new("Attachment")
	top.Name = "ShopTrailTop"
	top.Position = Vector3.new(0, 0.8, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "ShopTrailBottom"
	bottom.Position = Vector3.new(0, -0.8, 0)
	bottom.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = "ShopTrail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = ColorSequence.new(item.Colors[1], item.Colors[2] or item.Colors[1])
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Lifetime = 0.5
	trail.LightEmission = 0.4
	trail.Parent = root
end

local function applyAll(player)
	local character = player.Character
	if character and character.Parent then
		pcall(applyShirt, player, character)
		pcall(applyTrail, player, character)
	end
end

local function onBuy(player, id)
	if type(id) ~= "string" then
		return
	end
	local profile = PlayerData.Get(player)
	local item, category = findItem(id)
	if not profile or not item then
		return
	end
	if profile.Owned[id] then
		return -- already owned (the client shows EQUIP instead)
	end
	if not PlayerData.SpendBank(player, item.Price) then
		PlayerData.Notify(player, "small", "Not enough money", "You need " .. Format.money(item.Price) .. " in your Bank.")
		return
	end
	profile.Owned[id] = true
	profile.Equipped[category] = id -- wear it straight away
	PlayerData.Sync(player)
	applyAll(player)
	PlayerData.Notify(player, "small", "Bought " .. item.Name .. "!", "-" .. Format.money(item.Price) .. " from your Bank", "Coin")
end

local function onEquip(player, category, id)
	local profile = PlayerData.Get(player)
	if not profile or type(category) ~= "string" or type(id) ~= "string" or not table.find(CATEGORIES, category) then
		return
	end
	if id ~= "" then
		local item, itemCategory = findItem(id)
		if not item or itemCategory ~= category or not profile.Owned[id] then
			return
		end
	end
	profile.Equipped[category] = id
	PlayerData.Sync(player)
	applyAll(player)
end

function Shop.Start()
	Remotes.ShopBuy.OnServerEvent:Connect(onBuy)
	Remotes.ShopEquip.OnServerEvent:Connect(onEquip)

	local function setup(player)
		player.CharacterAppearanceLoaded:Connect(function(character)
			applyAll(player)
			character.Destroying:Connect(function()
				originalColors[character] = nil
			end)
		end)
		if player:HasAppearanceLoaded() then
			applyAll(player)
		end
	end
	-- Wait for each player's data, since that says what they're wearing
	PlayerData.Loaded:Connect(function(player)
		local profile = PlayerData.Get(player)
		-- Drop anything that isn't in the shop any more
		for _, category in CATEGORIES do
			local item, itemCategory = findItem(profile.Equipped[category])
			if not item or itemCategory ~= category or not profile.Owned[item.Id] then
				profile.Equipped[category] = ""
			end
		end
		PlayerData.Sync(player)
		setup(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		if player.Character then
			originalColors[player.Character] = nil
		end
	end)
end

return Shop
