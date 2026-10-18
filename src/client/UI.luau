-- Small helpers for building UI in code (no Studio GUI editing needed).
local UI = {}

UI.Colors = {
	Panel = Color3.fromRGB(20, 22, 30),
	Text = Color3.fromRGB(255, 255, 255),
	Dim = Color3.fromRGB(170, 175, 190),
	Red = Color3.fromRGB(235, 45, 45),
	Green = Color3.fromRGB(60, 200, 90),
	Gold = Color3.fromRGB(255, 205, 50),
	Blue = Color3.fromRGB(70, 150, 255),
}

function UI.new(className, props, children)
	local inst = Instance.new(className)
	for key, value in props or {} do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function UI.corner(radius)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

function UI.panel(props)
	props.BackgroundColor3 = props.BackgroundColor3 or UI.Colors.Panel
	props.BackgroundTransparency = props.BackgroundTransparency or 0.15
	props.BorderSizePixel = 0
	return UI.new("Frame", props, { UI.corner(12) })
end

function UI.text(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.FredokaOne
	props.TextColor3 = props.TextColor3 or UI.Colors.Text
	props.TextScaled = if props.TextScaled == nil then true else props.TextScaled
	return UI.new("TextLabel", props)
end

function UI.button(props)
	props.Font = props.Font or Enum.Font.FredokaOne
	props.TextColor3 = props.TextColor3 or UI.Colors.Text
	props.TextScaled = true
	props.AutoButtonColor = true
	props.BorderSizePixel = 0
	return UI.new("TextButton", props, { UI.corner(10), UI.new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
	}) })
end

-- A labelled progress bar. Returns the frame and a setter(fraction, text).
function UI.bar(parent, position, size, color, labelText)
	local back = UI.panel({ Parent = parent, Position = position, Size = size, BackgroundColor3 = Color3.fromRGB(45, 48, 60), BackgroundTransparency = 0 })
	local fill = UI.new("Frame", { Parent = back, Size = UDim2.fromScale(0, 1), BackgroundColor3 = color, BorderSizePixel = 0 }, { UI.corner(12) })
	local label = UI.text({ Parent = back, Size = UDim2.new(1, -12, 1, -6), Position = UDim2.fromOffset(6, 3), Text = labelText, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
	return back, function(fraction, text)
		fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		label.Text = text
	end
end

return UI
