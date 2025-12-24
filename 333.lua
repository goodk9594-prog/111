--====================================================
-- Services
--====================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Player = Players.LocalPlayer

--====================================================
-- 等待 PlayerGui（稳定）
--====================================================
local PlayerGui = Player:WaitForChild("PlayerGui", 10)
if not PlayerGui then
	warn("❌ PlayerGui 获取失败，脚本终止")
	return
end

--====================================================
-- Anti AFK（安全版）
--====================================================
Player.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new(0,0))
end)

--====================================================
-- 配置
--====================================================
local MAX_DIST, FAIL_CD, SCAN = 3000, 6, 0.4

local FRUIT = {
	["Hie Hie Devil Fruit"]=true,
	["Bomu Bomu Devil Fruit"]=true,
	["Mochi Mochi Devil Fruit"]=true,
	["Nikyu Nikyu Devil Fruit"]=true,
	["Bari Bari Devil Fruit"]=true,
}
local BOX = {Box=true,Chest=true,Barrel=true}

local State = {box=false, fruit=false}
local Running = true
local busy = false
local bad = {}

--====================================================
-- GUI 创建（绝不碰 CoreGui）
--====================================================
pcall(function()
	PlayerGui:FindFirstChild("AutoPick_PlayerGui"):Destroy()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AutoPick_PlayerGui"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

--====================================================
-- 主窗口
--====================================================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(220, 300)
frame.Position = UDim2.fromOffset(30, 120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

--====================================================
-- 标题
--====================================================
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundColor3 = Color3.fromRGB(25,25,25)
title.Text = "Auto Pick (Stable)"
title.TextColor3 = Color3.new(1,1,1)
title.BorderSizePixel = 0

--====================================================
-- 按钮工具
--====================================================
local function makeToggle(y, text, key)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-10,0,26)
	b.Position = UDim2.new(0,5,0,y)
	b.Text = text.."关"
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.TextColor3 = Color3.new(1,1,1)

	b.MouseButton1Click:Connect(function()
		State[key] = not State[key]
		b.Text = text .. (State[key] and "开" or "关")
	end)
end

makeToggle(40,"自动拾取箱子：","box")
makeToggle(70,"自动拾取果实：","fruit")

--====================================================
-- 果实记录框（修复 Label 问题）
--====================================================
local list = Instance.new("ScrollingFrame", frame)
list.Position = UDim2.new(0,5,0,110)
list.Size = UDim2.new(1,-10,1,-115)
list.CanvasSize = UDim2.new()
list.ScrollBarThickness = 6
list.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0,4)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 4)
end)

local function addFruit(name)
	local t = os.date("%H:%M:%S")
	local l = Instance.new("TextLabel", list)
	l.Size = UDim2.new(1,-4,0,22)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = Color3.new(1,1,1)
	l.Text = name .. " | " .. t
end

--====================================================
-- 工具函数
--====================================================
local function HRP()
	return Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
end

local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit", c end
		if BOX[c.Name] then return "box", c end
		c = c.Parent
	end
end

--====================================================
-- 自动拾取主循环（稳定）
--====================================================
task.spawn(function()
	while Running do
		task.wait(SCAN)
		if busy then continue end

		local hrp = HRP()
		if not hrp then continue end

		for _,pp in ipairs(workspace:GetDescendants()) do
			if not Running then break end
			if not pp:IsA("ProximityPrompt") or not pp.Enabled then continue end

			local kind, model = getType(pp)
			if kind == "box" and not State.box then continue end
			if kind == "fruit" and not State.fruit then continue end
			if not kind then continue end

			local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
			if not part:IsA("BasePart") then continue end

			busy = true
			hrp.CFrame = part.CFrame * CFrame.new(0,0,2)
			task.wait(0.15)
			if fireproximityprompt then fireproximityprompt(pp) end
			task.wait(0.2)
			busy = false
			break
		end
	end
end)

--====================================================
-- 果实生成监听（修复空 Label）
--====================================================
workspace.DescendantAdded:Connect(function(o)
	if not o:IsA("ProximityPrompt") then return end
	task.wait(0.1)
	local kind, model = getType(o)
	if kind == "fruit" and model then
		addFruit(model.Name)
	end
end)

warn("✅ PlayerGui 稳定整合版 已成功加载")
