-- LocalScript
-- 放在 StarterPlayerScripts 或 StarterGui 下

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local enabled = false
local DETECT_RANGE = 300
local DETECT_INTERVAL = 0.5

-- ==================== UI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoPickupUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
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

-- 开关按钮
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleBtn"
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

-- 关闭UI按钮
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
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

-- ==================== 功能逻辑 ====================

local function updateCharacter()
	character = player.Character
	if character then
		humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	end
end

player.CharacterAdded:Connect(function(char)
	character = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

local function getClosestItems()
	local itemsFolder = workspace:FindFirstChild("item")
	if not itemsFolder then return {} end

	local results = {}
	local hrpPos = humanoidRootPart and humanoidRootPart.Position

	if not hrpPos then return {} end

	for _, obj in ipairs(itemsFolder:GetDescendants()) do
		if obj:IsA("MeshPart") then
			local dist = (obj.Position - hrpPos).Magnitude
			if dist <= DETECT_RANGE then
				table.insert(results, {
					part = obj,
					distance = dist
				})
			end
		end
	end

	table.sort(results, function(a, b)
		return a.distance < b.distance
	end)

	return results
end

local function pressE()
	-- 模拟按下并松开 E 键
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
	task.wait(0.08)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function tryPickup(part)
	if not humanoidRootPart or not part or not part.Parent then return end

	-- 瞬移到物品上方一点
	humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 3, 0)

	-- 把长按改成按一下就能触发
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
		or part:FindFirstChildWhichIsA("ProximityPrompt", true)

	if prompt then
		prompt.HoldDuration = 0          -- 关键关键
		prompt.MaxActivationDistance = 20 -- 保证能触发
	end

	task.wait(0.12) -- 等一下让Prompt刷新
	pressE()
end

-- 主循环
task.spawn(function()
	while true do
		if enabled and humanoidRootPart then
			local items = getClosestItems()
			for _, data in ipairs(items) do
				if not enabled then break end
				tryPickup(data.part)
				task.wait(0.15) -- 每个物品之间稍微间隔一下，防止卡顿
			end
		end
		task.wait(DETECT_INTERVAL)
	end
end)

-- 按钮事件
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

print("自动拾取脚本已加载")
