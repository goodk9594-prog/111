--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer

--====================================================
-- Config
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

--====================================================
-- State
--====================================================
local State = {
	boxPick = false,
	fruitPick = false,
	running = true,
}

local busy = false
local bad = {}
local FruitLog = {}
local SavedPos = {}

--====================================================
-- Utils
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

--====================================================
-- Clear old GUI
--====================================================
pcall(function()
	CoreGui:FindFirstChild("AutoPickGui"):Destroy()
end)

--====================================================
-- GUI Root
--====================================================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"
gui.ResetOnSpawn = false

--====================================================
-- Main Frame
--====================================================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,300)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

--====================================================
-- Top Bar
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

--====================================================
-- Drag
--====================================================
do
	local dragging, startPos, startInput
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = frame.Position
			startInput = i.Position
		end
	end)
	top.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - startInput
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

--====================================================
-- Close Button（真正关闭脚本）
--====================================================
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,24,0,22)
close.Position = UDim2.new(1,-28,0,4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(150,60,60)
close.TextColor3 = Color3.new(1,1,1)
close.BorderSizePixel = 0

close.MouseButton1Click:Connect(function()
	State.running = false
	gui:Destroy()
end)

--====================================================
-- Minimize Button
--====================================================
local mini = Instance.new("TextButton", top)
mini.Size = UDim2.new(0,24,0,22)
mini.Position = UDim2.new(1,-56,0,4)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80,80,80)
mini.TextColor3 = Color3.new(1,1,1)
mini.BorderSizePixel = 0

local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Position = frame.Position
icon.Text = "📦"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)
icon.TextColor3 = Color3.new(1,1,1)
icon.BorderSizePixel = 0
Instance.new("UICorner", icon).CornerRadius = UDim.new(1,0)

mini.MouseButton1Click:Connect(function()
	frame.Visible = false
	icon.Visible = true
	icon.Position = frame.Position
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
end)

--====================================================
-- Toggles
--====================================================
local function toggle(y,text,key)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-10,0,26)
	b.Position = UDim2.new(0,5,0,y)
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.TextColor3 = Color3.new(1,1,1)
	b.BorderSizePixel = 0
	b.Text = text.."关"
	b.MouseButton1Click:Connect(function()
		State[key] = not State[key]
		b.Text = text .. (State[key] and "开" or "关")
	end)
end

toggle(40,"自动拾取箱子：","boxPick")
toggle(70,"自动拾取果实：","fruitPick")

--====================================================
-- TP Panel Toggle Button
--====================================================
local tpBtn = Instance.new("TextButton", frame)
tpBtn.Size = UDim2.new(1,-10,0,28)
tpBtn.Position = UDim2.new(0,5,0,110)
tpBtn.Text = "坐标传送"
tpBtn.BackgroundColor3 = Color3.fromRGB(70,130,180)
tpBtn.TextColor3 = Color3.new(1,1,1)
tpBtn.BorderSizePixel = 0

--====================================================
-- TP Panel (Side)
--====================================================
local tp = Instance.new("Frame", gui)
tp.Size = UDim2.new(0,180,0,220)
tp.BackgroundColor3 = Color3.fromRGB(30,30,30)
tp.BorderSizePixel = 0
tp.Visible = false

local function syncTP()
	tp.Position = UDim2.new(
		frame.Position.X.Scale,
		frame.Position.X.Offset + frame.Size.X.Offset + 5,
		frame.Position.Y.Scale,
		frame.Position.Y.Offset
	)
end

frame:GetPropertyChangedSignal("Position"):Connect(syncTP)

tpBtn.MouseButton1Click:Connect(function()
	tp.Visible = not tp.Visible
	syncTP()
end)

-- Save
local save = Instance.new("TextButton", tp)
save.Size = UDim2.new(1,-10,0,28)
save.Position = UDim2.new(0,5,0,5)
save.Text = "保存当前位置"
save.BackgroundColor3 = Color3.fromRGB(80,140,200)
save.TextColor3 = Color3.new(1,1,1)
save.BorderSizePixel = 0

local list = Instance.new("ScrollingFrame", tp)
list.Position = UDim2.new(0,5,0,40)
list.Size = UDim2.new(1,-10,1,-45)
list.ScrollBarThickness = 6
list.BackgroundColor3 = Color3.fromRGB(25,25,25)
list.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0,4)

save.MouseButton1Click:Connect(function()
	local cf = HRP().CFrame
	local id = #SavedPos + 1
	SavedPos[id] = cf

	local row = Instance.new("Frame", list)
	row.Size = UDim2.new(1,-4,0,26)
	row.BackgroundTransparency = 1

	local go = Instance.new("TextButton", row)
	go.Size = UDim2.new(0.7,0,1,0)
	go.Text = "坐标 "..id
	go.BackgroundColor3 = Color3.fromRGB(60,60,60)
	go.TextColor3 = Color3.new(1,1,1)
	go.BorderSizePixel = 0

	local del = Instance.new("TextButton", row)
	del.Size = UDim2.new(0.3,-4,1,0)
	del.Position = UDim2.new(0.7,4,0,0)
	del.Text = "删"
	del.BackgroundColor3 = Color3.fromRGB(150,60,60)
	del.TextColor3 = Color3.new(1,1,1)
	del.BorderSizePixel = 0

	go.MouseButton1Click:Connect(function()
		if SavedPos[id] then
			HRP().CFrame = SavedPos[id]
		end
	end)

	del.MouseButton1Click:Connect(function()
		SavedPos[id] = nil
		row:Destroy()
	end)

	task.wait()
	list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end)

--====================================================
-- 自动拾取（方案 A，保持原样）
--====================================================
local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit" end
		if BOX[c.Name] then return "box" end
		c = c.Parent
	end
end

local function bestPrompt()
	local hrp = HRP()
	local best, dist = nil, math.huge
	for _,pp in ipairs(workspace:GetDescendants()) do
		if not State.running then return end
		if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end

		local kind = getType(pp)
		if kind=="box" and not State.boxPick then continue end
		if kind=="fruit" and not State.fruitPick then continue end
		if not kind then continue end

		local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
		if part:IsA("BasePart") then
			local d = (hrp.Position - part.Position).Magnitude
			if d < dist and d <= MAX_DIST then
				best, dist = pp, d
			end
		end
	end
	return best
end

task.spawn(function()
	while State.running do
		task.wait(SCAN)
		if not busy then
			local pp = bestPrompt()
			if pp then
				busy = true
				local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
				HRP().CFrame = part.CFrame * CFrame.new(0,0,2)
				task.wait(0.15)
				if fireproximityprompt then
					fireproximityprompt(pp)
				end
				task.wait(0.3)
				busy = false
			end
		end
	end
end)

warn("✅ 方案A + 最小化 + 坐标传送 最终整合版已加载")
