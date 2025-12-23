--====================================================
-- Services
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
local S = {box=false, fruit=false}
local busy = false
local TPList = {}
local FruitLog = {}

--====================================================
-- Utils
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
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
-- Clean GUI
--====================================================
pcall(function() CoreGui.AutoPickGui:Destroy() end)

--====================================================
-- Main GUI
--====================================================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,300)
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
		S[key] = not S[key]
		b.Text = text .. (S[key] and "开" or "关")
	end)
end

toggle(10,"自动拾取箱子：","box")
toggle(40,"自动拾取果实：","fruit")

--====================================================
-- TP Button
--====================================================
local tpBtn = Instance.new("TextButton",frame)
tpBtn.Size = UDim2.new(1,-10,0,26)
tpBtn.Position = UDim2.new(0,5,0,75)
tpBtn.Text = "坐标传送面板"
tpBtn.BackgroundColor3 = Color3.fromRGB(70,120,180)
tpBtn.TextColor3 = Color3.new(1,1,1)
tpBtn.BorderSizePixel = 0

--====================================================
-- TP Panel（老结构，保证生成按钮）
--====================================================
local tp = Instance.new("Frame", gui)
tp.Size = UDim2.new(0,200,0,260)
tp.BackgroundColor3 = Color3.fromRGB(30,30,30)
tp.BorderSizePixel = 0
tp.Visible = false

local function syncTP()
	tp.Position = frame.Position + UDim2.new(0,frame.Size.X.Offset+6,0,0)
end
frame:GetPropertyChangedSignal("Position"):Connect(syncTP)
syncTP()

tpBtn.MouseButton1Click:Connect(function()
	tp.Visible = not tp.Visible
end)

local saveBtn = Instance.new("TextButton",tp)
saveBtn.Size = UDim2.new(1,-10,0,26)
saveBtn.Position = UDim2.new(0,5,0,5)
saveBtn.Text = "保存当前位置"
saveBtn.BackgroundColor3 = Color3.fromRGB(90,150,210)
saveBtn.TextColor3 = Color3.new(1,1,1)
saveBtn.BorderSizePixel = 0

local list = Instance.new("ScrollingFrame",tp)
list.Position = UDim2.new(0,5,0,36)
list.Size = UDim2.new(1,-10,1,-41)
list.ScrollBarThickness = 6
list.BackgroundColor3 = Color3.fromRGB(25,25,25)
list.BorderSizePixel = 0

local layout = Instance.new("UIListLayout",list)
layout.Padding = UDim.new(0,4)

local function refreshTP()
	list:ClearAllChildren()
	layout.Parent = list

	for i,cf in ipairs(TPList) do
		local row = Instance.new("TextButton",list)
		row.Size = UDim2.new(1,-4,0,28)
		row.Text = "坐标 "..i
		row.BackgroundColor3 = Color3.fromRGB(60,60,60)
		row.TextColor3 = Color3.new(1,1,1)
		row.BorderSizePixel = 0
		row.MouseButton1Click:Connect(function()
			HRP().CFrame = cf
		end)
	end

	task.wait()
	list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

saveBtn.MouseButton1Click:Connect(function()
	table.insert(TPList, HRP().CFrame)
	refreshTP()
end)

--====================================================
-- Fruit Log GUI
--====================================================
local log = Instance.new("ScrollingFrame",frame)
log.Position = UDim2.new(0,5,0,110)
log.Size = UDim2.new(1,-10,1,-115)
log.ScrollBarThickness = 6
log.BackgroundColor3 = Color3.fromRGB(28,28,28)
log.BorderSizePixel = 0

local logLayout = Instance.new("UIListLayout",log)
logLayout.Padding = UDim.new(0,4)

local function addFruit(name)
	local t = workspace:GetServerTimeNow()
	local l = Instance.new("TextLabel",log)
	l.Size = UDim2.new(1,-4,0,22)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Left
	l.Font = Enum.Font.SourceSansBold
	l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(255,200,60)
	l.Text = string.format("%s | %.2f", name, t)

	task.wait()
	log.CanvasSize = UDim2.new(0,0,0,logLayout.AbsoluteContentSize.Y)
end

--====================================================
-- Auto Pick (回退到稳定方案 A)
--====================================================
task.spawn(function()
	while task.wait(SCAN) do
		if busy then continue end

		local hrp = HRP()
		local best, dist = nil, math.huge

		for _,pp in ipairs(workspace:GetDescendants()) do
			if pp:IsA("ProximityPrompt") and pp.Enabled then
				local kind, model = getType(pp)
				if kind == "box" and not S.box then continue end
				if kind == "fruit" and not S.fruit then continue end
				if not kind then continue end

				local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
				if part:IsA("BasePart") then
					local d = (hrp.Position - part.Position).Magnitude
					if d < dist and d <= MAX_DIST then
						best = pp
						dist = d
					end
				end
			end
		end

		if best then
			busy = true
			local kind, model = getType(best)
			if kind == "fruit" then
				addFruit(model.Name)
			end

			local part = best.Parent:IsA("Attachment") and best.Parent.Parent or best.Parent
			HRP().CFrame = part.CFrame * CFrame.new(0,0,2)
			task.wait(0.15)
			if fireproximityprompt then
				fireproximityprompt(best)
			end
			task.wait(0.3)
			busy = false
		end
	end
end)

warn("✅ 已完全回退到稳定方案，三项功能应全部恢复")
