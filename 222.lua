--========================
-- Services / Player
--========================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer

--========================
-- Config
--========================
local MAX_DIST = 3000
local SCAN = 0.4
local FAIL_CD = 6

-- 你给的 ID（方案 A 核心）
local FRUIT = {
	["Hie Hie Devil Fruit"]=true,
	["Bomu Bomu Devil Fruit"]=true,
	["Mochi Mochi Devil Fruit"]=true,
	["Nikyu Nikyu Devil Fruit"]=true,
	["Bari Bari Devil Fruit"]=true,
}

local BOX = {
	Box=true,
	Chest=true,
	Barrel=true,
}

--========================
-- State
--========================
local State = {
	box = false,
	fruit = false,
	running = true,
}

local busy = false
local bad = {}
local FruitLog = {}

--========================
-- Utils
--========================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

local function serverTime()
	return os.time() -- 服务器 Unix 时间戳
end

--========================
-- GUI Clean
--========================
pcall(function()
	CoreGui.AutoPickGui:Destroy()
end)

--========================
-- GUI Main
--========================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoPickGui"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,210,0,280)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

--========================
-- Buttons
--========================
local function toggle(y,text,key)
	local b = Instance.new("TextButton",frame)
	b.Size = UDim2.new(1,-10,0,26)
	b.Position = UDim2.new(0,5,0,y)
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.BorderSizePixel = 0
	b.TextColor3 = Color3.new(1,1,1)
	b.Text = text.."关"

	b.MouseButton1Click:Connect(function()
		State[key] = not State[key]
		b.Text = text .. (State[key] and "开" or "关")
	end)
end

toggle(10,"自动拾取箱子：","box")
toggle(40,"自动拾取果实：","fruit")

--========================
-- Close / Minimize
--========================
local close = Instance.new("TextButton",frame)
close.Size = UDim2.new(0,22,0,22)
close.Position = UDim2.new(1,-26,0,4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(140,60,60)
close.TextColor3 = Color3.new(1,1,1)
close.BorderSizePixel = 0

local mini = Instance.new("TextButton",frame)
mini.Size = UDim2.new(0,22,0,22)
mini.Position = UDim2.new(1,-52,0,4)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80,80,80)
mini.TextColor3 = Color3.new(1,1,1)
mini.BorderSizePixel = 0

--========================
-- Minimized Icon
--========================
local icon = Instance.new("TextButton",gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Position = frame.Position
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)
icon.TextColor3 = Color3.new(1,1,1)
icon.BorderSizePixel = 0
Instance.new("UICorner",icon).CornerRadius = UDim.new(1,0)

mini.MouseButton1Click:Connect(function()
	frame.Visible = false
	icon.Visible = true
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
end)

-- 关闭 = 停止脚本
close.MouseButton1Click:Connect(function()
	State.running = false
	gui:Destroy()
end)

--========================
-- Fruit Log UI
--========================
local list = Instance.new("ScrollingFrame",frame)
list.Position = UDim2.new(0,5,0,80)
list.Size = UDim2.new(1,-10,1,-85)
list.CanvasSize = UDim2.new(0,0,0,0)
list.ScrollBarThickness = 6
list.BackgroundColor3 = Color3.fromRGB(28,28,28)
list.BorderSizePixel = 0

local layout = Instance.new("UIListLayout",list)
layout.Padding = UDim.new(0,4)

local function addFruit(name)
	local time = tostring(serverTime())
	table.insert(FruitLog,{name=name,time=time})

	local l = Instance.new("TextLabel",list)
	l.Size = UDim2.new(1,-4,0,20)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Font = Enum.Font.SourceSansBold
	l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(255,200,60)
	l.Text = name.." | "..time

	task.wait()
	list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

--========================
-- Type Detect（方案 A）
--========================
local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then
			return "fruit", c
		end
		if BOX[c.Name] then
			return "box", c
		end
		c = c.Parent
	end
end

--========================
-- Best Prompt
--========================
local function bestPrompt()
	local hrp = HRP()
	local best, dist = nil, math.huge
	local now = os.clock()

	for _,pp in ipairs(workspace:GetDescendants()) do
		if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end
		if bad[pp] and bad[pp] > now then continue end

		local kind = getType(pp)
		if kind == "box" and not State.box then continue end
		if kind == "fruit" and not State.fruit then continue end
		if not kind then continue end

		local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
		if part:IsA("BasePart") then
			local d = (hrp.Position - part.Position).Magnitude
			if d <= MAX_DIST and d < dist then
				best, dist = pp, d
			end
		end
	end
	return best
end

--========================
-- Pick
--========================
local function pick(pp)
	busy = true
	local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent

	pcall(function()
		HRP().CFrame = part.CFrame * CFrame.new(0,0,2)
		task.wait(0.15)
		if fireproximityprompt then
			fireproximityprompt(pp)
		end
	end)

	task.wait(0.25)
	if pp.Parent then
		bad[pp] = os.clock() + FAIL_CD
	end
	busy = false
end

--========================
-- Auto Pick Loop（修复版）
--========================
task.spawn(function()
	while State.running and task.wait(SCAN) do
		if not busy then
			local pp = bestPrompt()
			if pp then
				pick(pp)
			end
		end
	end
end)

--========================
-- Fruit Spawn Detect
--========================
workspace.DescendantAdded:Connect(function(o)
	if not State.running then return end
	if o:IsA("ProximityPrompt") then
		task.wait(0.1)
		local kind, model = getType(o)
		if kind == "fruit" and model then
			addFruit(model.Name)
		end
	end
end)
