-- LocalScript（更稳健版）
-- 放在 StarterPlayerScripts

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local character, humanoidRootPart

local enabled = false
local DETECT_RANGE = 300
local DETECT_INTERVAL = 0.5

-- 安全获取角色
local function updateCharacter()
	character = player.Character
	if character then
		humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	else
		humanoidRootPart = nil
	end
end

updateCharacter()
player.CharacterAdded:Connect(function(char)
	character = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart", 5)
end)

player.CharacterRemoving:Connect(function()
	humanoidRootPart = nil
end)

-- ==================== UI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoPickupUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 140)
mainFrame.Position = UDim2.new(0.5, -110, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
title.BorderSizePixel = 0
title.Text = "自动拾取"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = title

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.85, 0, 0, 36)
toggleBtn.Position = UDim2.new(0.075, 0, 0.32, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "开启自动拾取"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextSize = 14
toggleBtn.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.85, 0, 0, 32)
closeBtn.Position = UDim2.new(0.075, 0, 0.65, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "关闭UI"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 14
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- ==================== 核心逻辑 ====================

local function getClosestItems()
	local itemsFolder = workspace:FindFirstChild("item")
	if not itemsFolder then return {} end
	if not humanoidRootPart then return {} end

	local results = {}
	local hrpPos = humanoidRootPart.Position

	for _, obj in ipairs(itemsFolder:GetDescendants()) do
		if obj:IsA("MeshPart") and obj.Parent then
			local success, dist = pcall(function()
				return (obj.Position - hrpPos).Magnitude
			end)
			if success and dist <= DETECT_RANGE then
				table.insert(results, {part = obj, distance = dist})
			end
		end
	end

	table.sort(results, function(a, b)
		return a.distance < b.distance
	end)

	return results
end

local function pressE()
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.08)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
	end)
end

local function tryPickup(part)
	if not humanoidRootPart or not part or not part.Parent then return end

	local success = pcall(function()
		humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	end)
	if not success then return end

	-- 修改长按为瞬间触发
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
	end

	if prompt then
		pcall(function()
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 25
		end)
	end

	task.wait(0.15)
	pressE()
end

-- 主循环
task.spawn(function()
	while true do
		if enabled and humanoidRootPart and humanoidRootPart.Parent then
			local items = getClosestItems()
			for _, data in ipairs(items) do
				if not enabled then break end
				tryPickup(data.part)
				task.wait(0.18)
			end
		end
		task.wait(DETECT_INTERVAL)
	end
end)

-- 按钮
toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	if enabled then
		toggleBtn.Text = "关闭自动拾取"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 70)
	else
		toggleBtn.Text = "开启自动拾取"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

print("✅ 自动拾取脚本已加载（稳健版）")
