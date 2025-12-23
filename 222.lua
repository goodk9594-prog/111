--====================================================
-- Services / Player
--====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer

--====================================================
-- Config
--====================================================
local MAX_DIST, SCAN = 3000, 0.4

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
local State = {box=false, fruit=false, running=true}
local TPList = {}
local busy = false
local FruitLog = {}

--====================================================
-- Utils
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

--====================================================
-- Clean GUI
--====================================================
pcall(function() CoreGui.AutoPickGui:Destroy() end)

--====================================================
-- Main GUI
--====================================================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,230,0,310)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

--====================================================
-- Toggles
--====================================================
local function toggle(y,text,key)
	local b = Instance.new("TextButton",frame)
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

toggle(10,"自动拾取箱子：","box")
toggle(40,"自动拾取果实：","fruit")

--====================================================
-- Close / Minimize
--====================================================
local close = Instance.new("TextButton",frame)
close.Size = UDim2.new(0,22,0,22)
close.Position = UDim2.new(1,-26,0,4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(150,60,60)
close.TextColor3 = Color3.new(1,1,1)
close.BorderSizePixel = 0

local mini = Instance.new("TextButton",frame)
mini.Size = UDim2.new(0,22,0,22)
mini.Position = UDim2.new(1,-52,0,4)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80,80,80)
mini.TextColor3 = Color3.new(1,1,1)
mini.BorderSizePixel = 0

local icon = Instance.new("TextButton",gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Position = frame.Position
icon.Text = "📍"
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

close.MouseButton1Click:Connect(function()
	State.running = false
	gui:Destroy()
end)

--====================================================
-- TP Panel (FIXED)
--====================================================
local tpBtn = Instance.new("TextButton",frame)
tpBtn.Size = UDim2.new(1,-10,0,26)
tpBtn.Position = UDim2.new(0,5,0,75)
tpBtn.Text = "坐标传送面板"
tpBtn.BackgroundColor3 = Color3.fromRGB(70,120,180)
tpBtn.TextColor3 = Color3.new(1,1,1)
tpBtn.BorderSizePixel = 0

local tpFrame = Instance.new("Frame",gui)
tpFrame.Size = UDim2.new(0,200,0,260)
tpFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
tpFrame.BorderSizePixel = 0
tpFrame.Visible = false

local function syncTP()
	tpFrame.Position = frame.Position + UDim2.new(0,frame.Size.X.Offset+6,0,0)
end
frame:GetPropertyChangedSignal("Position"):Connect(syncTP)
syncTP()

tpBtn.MouseButton1Click:Connect(function()
	tpFrame.Visible = not tpFrame.Visible
end)

-- Save Button
local saveBtn = Instance.new("TextButton",tpFrame)
saveBtn.Size = UDim2.new(1,-10,0,26)
saveBtn.Position = UDim2.new(0,5,0,5)
saveBtn.Text = "保存当前位置"
saveBtn.BackgroundColor3 = Color3.fromRGB(90,150,210)
saveBtn.TextColor3 = Color3.new(1,1,1)
saveBtn.BorderSizePixel = 0

-- List
local list = Instance.new("ScrollingFrame",tpFrame)
list.Position = UDim2.new(0,5,0,36)
list.Size = UDim2.new(1,-10,1,-41)
list.CanvasSize = UDim2.new(0,0,0,0)
list.ScrollBarThickness = 6
list.BackgroundColor3 = Color3.fromRGB(25,25,25)
list.BorderSizePixel = 0
list.AutomaticCanvasSize = Enum.AutomaticSize.None

local layout = Instance.new("UIListLayout",list)
layout.Padding = UDim.new(0,4)

local function refreshTP()
	list:ClearAllChildren()
	layout.Parent = list

	for i,cf in ipairs(TPList) do
		local row = Instance.new("Frame",list)
		row.Size = UDim2.new(1,-4,0,30)
		row.BackgroundColor3 = Color3.fromRGB(60,60,60)
		row.BorderSizePixel = 0

		local tp = Instance.new("TextButton",row)
		tp.Size = UDim2.new(1,-30,1,0)
		tp.Text = "坐标 "..i
		tp.BackgroundTransparency = 1
		tp.TextColor3 = Color3.new(1,1,1)
		tp.MouseButton1Click:Connect(function()
			HRP().CFrame = cf
		end)

		local del = Instance.new("TextButton",row)
		del.Size = UDim2.new(0,26,1,0)
		del.Position = UDim2.new(1,-26,0,0)
		del.Text = "×"
		del.BackgroundColor3 = Color3.fromRGB(150,60,60)
		del.TextColor3 = Color3.new(1,1,1)
		del.BorderSizePixel = 0
		del.MouseButton1Click:Connect(function()
			table.remove(TPList,i)
			refreshTP()
		end)
	end

	task.wait()
	list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 4)
end

saveBtn.MouseButton1Click:Connect(function()
	table.insert(TPList,HRP().CFrame)
	refreshTP()
end)

--====================================================
-- Fruit spawn log (example)
--====================================================
workspace.DescendantAdded:Connect(function(o)
	if not o:IsA("ProximityPrompt") then return end
	task.wait(0.1)

	local c=o.Parent
	while c do
		if FRUIT[c.Name] then
			local t = workspace:GetServerTimeNow()
			warn("🍎 果实生成:",c.Name,"ServerTime:",t)
			break
		end
		c=c.Parent
	end
end)

warn("✅ 坐标按钮显示 + 果实时间示例 修复完成")
