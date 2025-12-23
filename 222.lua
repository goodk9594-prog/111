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
local MAX_DIST = 3000
local SCAN = 0.4
local FAIL_CD = 6

-- 方案 A：你给的 ID
local FRUIT = {
	["Hie Hie Devil Fruit"]=true,
	["Bomu Bomu Devil Fruit"]=true,
	["Mochi Mochi Devil Fruit"]=true,
	["Nikyu Nikyu Devil Fruit"]=true,
	["Bari Bari Devil Fruit"]=true,
}
local BOX = { Box=true, Chest=true, Barrel=true }

--====================================================
-- State
--====================================================
local State = {
	box = false,
	fruit = false,
	running = true,
}

local busy = false
local bad = {}
local FruitLog = {}
local TPList = {}

--====================================================
-- Utils
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

local function serverTime()
	return os.time()
end

--====================================================
-- Clean old GUI
--====================================================
pcall(function()
	CoreGui.AutoPickGui:Destroy()
end)

--====================================================
-- Main GUI
--====================================================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,300)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

--====================================================
-- Buttons
--====================================================
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

close.MouseButton1Click:Connect(function()
	State.running = false
	gui:Destroy()
end)

--====================================================
-- 坐标传送面板（独立）
--====================================================
local tpBtn = Instance.new("TextButton",frame)
tpBtn.Size = UDim2.new(1,-10,0,26)
tpBtn.Position = UDim2.new(0,5,0,75)
tpBtn.Text = "坐标传送面板"
tpBtn.BackgroundColor3 = Color3.fromRGB(70,120,180)
tpBtn.BorderSizePixel = 0
tpBtn.TextColor3 = Color3.new(1,1,1)

local tpFrame = Instance.new("Frame",gui)
tpFrame.Size = UDim2.new(0,200,0,260)
tpFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
tpFrame.BorderSizePixel = 0
tpFrame.Visible = false

local function syncTPPos()
	tpFrame.Position = frame.Position + UDim2.new(0, frame.Size.X.Offset + 6, 0, 0)
end
frame:GetPropertyChangedSignal("Position"):Connect(syncTPPos)
syncTPPos()

tpBtn.MouseButton1Click:Connect(function()
	tpFrame.Visible = not tpFrame.Visible
end)

local saveBtn = Instance.new("TextButton",tpFrame)
saveBtn.Size = UDim2.new(1,-10,0,26)
saveBtn.Position = UDim2.new(0,5,0,5)
saveBtn.Text = "保存当前位置"
saveBtn.BackgroundColor3 = Color3.fromRGB(90,150,210)
saveBtn.BorderSizePixel = 0
saveBtn.TextColor3 = Color3.new(1,1,1)

local tpList = Instance.new("ScrollingFrame",tpFrame)
tpList.Position = UDim2.new(0,5,0,36)
tpList.Size = UDim2.new(1,-10,1,-41)
tpList.ScrollBarThickness = 6
tpList.CanvasSize = UDim2.new(0,0,0,0)
tpList.BackgroundColor3 = Color3.fromRGB(25,25,25)
tpList.BorderSizePixel = 0

local tpLayout = Instance.new("UIListLayout",tpList)
tpLayout.Padding = UDim.new(0,4)

local function refreshTP()
	tpList:ClearAllChildren()
	tpLayout.Parent = tpList
	for i,v in ipairs(TPList) do
		local row = Instance.new("TextButton",tpList)
		row.Size = UDim2.new(1,-4,0,24)
		row.Text = "坐标 "..i
		row.BackgroundColor3 = Color3.fromRGB(60,60,60)
		row.TextColor3 = Color3.new(1,1,1)
		row.BorderSizePixel = 0
		row.MouseButton1Click:Connect(function()
			HRP().CFrame = v
		end)

		local del = Instance.new("TextButton",row)
		del.Size = UDim2.new(0,24,1,0)
		del.Position = UDim2.new(1,-24,0,0)
		del.Text = "×"
		del.BackgroundColor3 = Color3.fromRGB(140,60,60)
		del.TextColor3 = Color3.new(1,1,1)
		del.BorderSizePixel = 0
		del.MouseButton1Click:Connect(function()
			table.remove(TPList,i)
			refreshTP()
		end)
	end
	task.wait()
	tpList.CanvasSize = UDim2.new(0,0,0,tpLayout.AbsoluteContentSize.Y)
end

saveBtn.MouseButton1Click:Connect(function()
	table.insert(TPList, HRP().CFrame)
	refreshTP()
end)

--====================================================
-- 果实生成记录表（滑轮）
--====================================================
local fruitList = Instance.new("ScrollingFrame",frame)
fruitList.Position = UDim2.new(0,5,0,110)
fruitList.Size = UDim2.new(1,-10,1,-115)
fruitList.CanvasSize = UDim2.new(0,0,0,0)
fruitList.ScrollBarThickness = 6
fruitList.BackgroundColor3 = Color3.fromRGB(28,28,28)
fruitList.BorderSizePixel = 0

local fruitLayout = Instance.new("UIListLayout",fruitList)
fruitLayout.Padding = UDim.new(0,4)

local function addFruitLog(name)
	local t = serverTime()
	local l = Instance.new("TextLabel",fruitList)
	l.Size = UDim2.new(1,-4,0,20)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Left
	l.Font = Enum.Font.SourceSansBold
	l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(255,200,60)
	l.Text = name.." | "..t
	task.wait()
	fruitList.CanvasSize = UDim2.new(0,0,0,fruitLayout.AbsoluteContentSize.Y)
end

--====================================================
-- Type Detect
--====================================================
local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit",c end
		if BOX[c.Name] then return "box",c end
		c = c.Parent
	end
end

--====================================================
-- Auto Pick Loop
--====================================================
task.spawn(function()
	while State.running do
		task.wait(SCAN)
		if busy then continue end

		local hrp = HRP()
		local best,dist=nil,math.huge
		for _,pp in ipairs(workspace:GetDescendants()) do
			if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end
			if bad[pp] and bad[pp]>os.clock() then continue end

			local kind = getType(pp)
			if kind=="box" and not State.box then continue end
			if kind=="fruit" and not State.fruit then continue end
			if not kind then continue end

			local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
			if part:IsA("BasePart") then
				local d = (hrp.Position-part.Position).Magnitude
				if d<dist and d<=MAX_DIST then
					best,dist=pp,d
				end
			end
		end

		if best then
			busy=true
			local part = best.Parent:IsA("Attachment") and best.Parent.Parent or best.Parent
			pcall(function()
				HRP().CFrame = part.CFrame * CFrame.new(0,0,2)
				task.wait(0.15)
				if fireproximityprompt then fireproximityprompt(best) end
			end)
			bad[best]=os.clock()+FAIL_CD
			busy=false
		end
	end
end)

--====================================================
-- Fruit Spawn Detect
--====================================================
workspace.DescendantAdded:Connect(function(o)
	if not State.running then return end
	if o:IsA("ProximityPrompt") then
		task.wait(0.1)
		local kind,model=getType(o)
		if kind=="fruit" and model then
			addFruitLog(model.Name)
		end
	end
end)
