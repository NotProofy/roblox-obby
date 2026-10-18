-- The shop window: buy and wear shirt colors and trails with Bank money.
-- The server checks every purchase; this window only shows what's for sale.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Format = require(ReplicatedStorage.Shared.Format)
local UI = require(script.Parent.UI)

local ShopUI = {}

local player = Players.LocalPlayer

local TABS = {
	{ Category = "Shirts", Title = "SHIRTS" },
	{ Category = "Trails", Title = "TRAILS" },
}

local function ownedSet()
	local set = {}
	for id in string.gmatch(player:GetAttribute("Owned") or "", "[^,]+") do
		set[id] = true
	end
	return set
end

-- Builds the window (hidden) and returns a function to open/close it
function ShopUI.create(gui)
	local window = UI.panel({ Parent = gui, Name = "Shop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(460, 400), Visible = false, ZIndex = 5 })
	UI.text({ Parent = window, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -90, 0, 34), Text = "SHOP", TextColor3 = UI.Colors.Gold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local bankLabel = UI.text({ Parent = window, Position = UDim2.fromOffset(16, 44), Size = UDim2.new(1, -32, 0, 20), Text = "", TextColor3 = UI.Colors.Dim, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 })
	local close = UI.button({ Parent = window, Position = UDim2.new(1, -56, 0, 10), Size = UDim2.fromOffset(44, 40), Text = "X", BackgroundColor3 = UI.Colors.Red, ZIndex = 5 })

	local tabButtons = {}
	for i, tab in TABS do
		tabButtons[tab.Category] = UI.button({ Parent = window, Position = UDim2.new((i - 1) / #TABS, if i == 1 then 16 else 4, 0, 72), Size = UDim2.new(1 / #TABS, -20, 0, 36), Text = tab.Title, BackgroundColor3 = UI.Colors.Blue, ZIndex = 5 })
	end

	local list = UI.new("ScrollingFrame", {
		Parent = window,
		Position = UDim2.fromOffset(16, 118),
		Size = UDim2.new(1, -32, 1, -130),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 5,
	}, {
		UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local currentTab = "Shirts"

	local function render()
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for category, button in tabButtons do
			button.BackgroundColor3 = if category == currentTab then UI.Colors.Green else UI.Colors.Blue
		end
		bankLabel.Text = "Your Bank: " .. Format.money(player:GetAttribute("Bank"))

		local owned = ownedSet()
		local equipped = player:GetAttribute("Equipped" .. currentTab) or ""
		local bank = player:GetAttribute("Bank") or 0
		for i, item in Config.Shop[currentTab] do
			local row = UI.panel({ Parent = list, LayoutOrder = i, Size = UDim2.new(1, -8, 0, 52), BackgroundColor3 = Color3.fromRGB(40, 42, 54), ZIndex = 5 })
			local swatchColor = item.Color or item.Colors[1]
			local swatch = UI.panel({ Parent = row, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = swatchColor, BackgroundTransparency = 0, ZIndex = 6 })
			if item.Colors and item.Colors[2] then
				UI.new("UIGradient", { Parent = swatch, Color = ColorSequence.new(item.Colors[1], item.Colors[2]) })
				swatch.BackgroundColor3 = Color3.new(1, 1, 1)
			end
			UI.text({ Parent = row, Position = UDim2.fromOffset(54, 6), Size = UDim2.new(1, -200, 0, 24), Text = item.Name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
			UI.text({ Parent = row, Position = UDim2.fromOffset(54, 30), Size = UDim2.new(1, -200, 0, 16), Text = Format.money(item.Price), TextColor3 = UI.Colors.Gold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })

			local text, color, action
			if equipped == item.Id then
				text, color = "TAKE OFF", UI.Colors.Dim
				action = function()
					Remotes.ShopEquip:FireServer(currentTab, "")
				end
			elseif owned[item.Id] then
				text, color = "WEAR", UI.Colors.Blue
				action = function()
					Remotes.ShopEquip:FireServer(currentTab, item.Id)
				end
			else
				text = "BUY"
				color = if bank >= item.Price then UI.Colors.Green else Color3.fromRGB(90, 90, 100)
				action = function()
					Remotes.ShopBuy:FireServer(item.Id)
				end
			end
			local button = UI.button({ Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 38), Text = text, BackgroundColor3 = color, ZIndex = 6 })
			button.Activated:Connect(action)
		end
	end

	for category, button in tabButtons do
		button.Activated:Connect(function()
			currentTab = category
			render()
		end)
	end
	close.Activated:Connect(function()
		window.Visible = false
	end)
	for _, name in { "Owned", "EquippedShirts", "EquippedTrails", "Bank" } do
		player:GetAttributeChangedSignal(name):Connect(function()
			if window.Visible then
				render()
			end
		end)
	end

	-- Open or close the window. open = nil toggles.
	return function(open)
		if open == nil then
			open = not window.Visible
		end
		window.Visible = open
		if open then
			render()
		end
	end
end

return ShopUI
