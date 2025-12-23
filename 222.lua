--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local P = Players.LocalPlayer

--====================================================
-- Anti AFK（关闭脚本时会断开）
--====================================================
local antiAfkConn
antiAfkConn = P.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

--====================================================
-- Config（方案 A 原始配置）
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
local S = {boxPick=false, fruitPick=false}
local busy, bad = false, {}
local FruitLog = {}      -- 果实记录（服务器时间）
local SavedTP = {}       -- 坐标保存
local scriptAlive = true -- 关闭脚本用

--====================================================
-- Utils
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

-- 服务器时间戳
local function serverTime()
	local t = workspace:GetServerTimeNow()
	local total = math.floor(t)
	local min = math.floor(total / 60)
	local sec = total % 60
	return string.format("%d:%02d", min, sec), t
end

--====================================================
-- 清理旧 GUI
--====================================================
pcall(function() CoreGui.AutoPickGui:Destroy() end)

--====================================================
-- GUI（主）
--====================================================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,300)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

--====================================================
-- 顶栏
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

-- 最小化
local mini = Instance.new("TextButton", top)
mini.Size = UDim2.new(0,22,0,22)
mini.Position = UDim2.new(1,-54,0,4)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80,80,80)
mini.TextColor3 = Color3.new(1,1,1)
mini.BorderSizePixel = 0

-- 关闭（彻底停止脚本）
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,22,0,22)
close.Position = UDim2.new(1,-26,0,4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(150,60,60)
close.TextColor3 = Color3.new(1,1,1)
close.BorderSizePixel = 0

--====================================================
-- 拖动（手机）
--====================================================
do
	local dragging, sp, fp
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			dragging=true
			sp=i.Position
			fp=frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType==Enum.UserInputType.Touch then
			local d=i.Position-sp
			frame.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
			tpFrame.Position=frame.Position+UDim2.new(0,230,0,0)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)
end

--====================================================
-- Toggle
--====================================================
local function toggle(y,text,key)
	local b=Instance.new("TextButton",frame)
	b.Size=UDim2.new(1,-10,0,26)
	b.Position=UDim2.new(0,5,0,y)
	b.BackgroundColor3=Color3.fromRGB(60,60,60)
	b.TextColor3=Color3.new(1,1,1)
	b.BorderSizePixel=0
	b.Text=text.."关"
	b.MouseButton1Click:Connect(function()
		S[key]=not S[key]
		b.Text=text..(S[key] and "开" or "关")
	end)
end

toggle(40,"自动拾取箱子：","boxPick")
toggle(70,"自动拾取果实：","fruitPick")

--====================================================
-- 坐标传送面板（跟随主 GUI）
--====================================================
local tpBtn = Instance.new("TextButton", frame)
tpBtn.Size = UDim2.new(1,-10,0,26)
tpBtn.Position = UDim2.new(0,5,0,110)
tpBtn.Text = "坐标保存 / 传送"
tpBtn.BackgroundColor3 = Color3.fromRGB(70,130,180)
tpBtn.BorderSizePixel = 0

tpFrame = Instance.new("Frame", gui)
tpFrame.Size = UDim2.new(0,200,0,260)
tpFrame.Position = frame.Position + UDim2.new(0,230,0,0)
tpFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
tpFrame.Visible = false
tpFrame.BorderSizePixel = 0

local saveBtn = Instance.new("TextButton", tpFrame)
saveBtn.Size = UDim2.new(1,-10,0,26)
saveBtn.Position = UDim2.new(0,5,0,5)
saveBtn.Text = "保存当前位置"
saveBtn.BackgroundColor3 = Color3.fromRGB(80,140,200)
saveBtn.BorderSizePixel = 0

local tpList = Instance.new("ScrollingFrame", tpFrame)
tpList.Position = UDim2.new(0,5,0,40)
tpList.Size = UDim2.new(1,-10,1,-45)
tpList.ScrollBarThickness = 6
tpList.CanvasSize = UDim2.new(0,0,0,0)
tpList.BorderSizePixel = 0

local tpLayout = Instance.new("UIListLayout", tpList)
tpLayout.Padding = UDim.new(0,4)

tpBtn.MouseButton1Click:Connect(function()
	tpFrame.Visible = not tpFrame.Visible
	tpFrame.Position = frame.Position + UDim2.new(0,230,0,0)
end)

saveBtn.MouseButton1Click:Connect(function()
	local cf = HRP().CFrame
	local index = #SavedTP + 1
	SavedTP[index] = cf

	local row = Instance.new("Frame", tpList)
	row.Size = UDim2.new(1,0,0,26)
	row.BackgroundTransparency = 1

	local go = Instance.new("TextButton", row)
	go.Size = UDim2.new(0.7,0,1,0)
	go.Text = "坐标 "..index
	go.BackgroundColor3 = Color3.fromRGB(60,60,60)
	go.BorderSizePixel = 0
	go.MouseButton1Click:Connect(function()
		HRP().CFrame = cf
	end)

	local del = Instance.new("TextButton", row)
	del.Size = UDim2.new(0.28,0,1,0)
	del.Position = UDim2.new(0.72,0,0,0)
	del.Text = "删"
	del.BackgroundColor3 = Color3.fromRGB(140,60,60)
	del.BorderSizePixel = 0
	del.MouseButton1Click:Connect(function()
		row:Destroy()
	end)

	row.Parent = tpList
	task.wait()
	tpList.CanvasSize = UDim2.new(0,0,0,tpLayout.AbsoluteContentSize.Y)
end)

--====================================================
-- 果实记录（服务器时间）
--====================================================
local log = Instance.new("TextLabel", frame)
log.Size = UDim2.new(1,-10,0,20)
log.Position = UDim2.new(0,5,0,150)
log.Text = "果实生成记录（服务器时间）"
log.TextColor3 = Color3.fromRGB(255,200,60)
log.BackgroundTransparency = 1
log.TextXAlignment = Left

local list = Instance.new("ScrollingFrame", frame)
list.Position = UDim2.new(0,5,0,175)
list.Size = UDim2.new(1,-10,1,-180)
list.ScrollBarThickness = 6
list.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0,4)

local function addFruit(name)
	local timeStr, ts = serverTime()
	table.insert(FruitLog,{name=name,time=timeStr,ts=ts})

	local l=Instance.new("TextLabel",list)
	l.Size=UDim2.new(1,-4,0,20)
	l.BackgroundTransparency=1
	l.TextXAlignment=Left
	l.Font=Enum.Font.SourceSansBold
	l.TextSize=13
	l.TextColor3=Color3.fromRGB(255,200,60)
	l.Text=string.format("%s [S %s]",name,timeStr)

	task.wait()
	list.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

--====================================================
-- 方案 A：自动拾取核心（未改）
--====================================================
local function getType(pp)
	local c=pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit",c end
		if BOX[c.Name] then return "box",c end
		c=c.Parent
	end
end

local function bestPrompt()
	local hrp,best,dist,now=HRP(),nil,math.huge,os.clock()
	for _,pp in ipairs(workspace:GetDescendants()) do
		if not scriptAlive then return end
		if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end
		if bad[pp] and bad[pp]>now then continue end

		local kind=getType(pp)
		if kind=="box" and not S.boxPick then continue end
		if kind=="fruit" and not S.fruitPick then continue end
		if not kind then continue end

		local part=pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
		if part:IsA("BasePart") then
			local d=(hrp.Position-part.Position).Magnitude
			if d<=MAX_DIST and d<dist then best,dist=pp,d end
		end
	end
	return best
end

local function pick(pp)
	busy=true
	local part=pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
	HRP().CFrame=part.CFrame*CFrame.new(0,0,2)
	task.wait(0.15)
	if fireproximityprompt then fireproximityprompt(pp) end
	task.wait(0.25)
	if pp.Parent then bad[pp]=os.clock()+FAIL_CD end
	busy=false
end

task.spawn(function()
	while scriptAlive do
		task.wait(SCAN)
		if not busy then
			local pp=bestPrompt()
			if pp then pick(pp) end
		end
	end
end)

-- 果实生成监听
workspace.DescendantAdded:Connect(function(o)
	if o:IsA("ProximityPrompt") then
		task.wait(0.1)
		local kind,model=getType(o)
		if kind=="fruit" then
			addFruit(model.Name)
		end
	end
end)

--====================================================
-- 最小化 & 关闭
--====================================================
local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Position = frame.Position
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)
icon.BorderSizePixel = 0
Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0)

mini.MouseButton1Click:Connect(function()
	frame.Visible=false
	tpFrame.Visible=false
	icon.Visible=true
	icon.Position=frame.Position
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible=true
	icon.Visible=false
end)

close.MouseButton1Click:Connect(function()
	scriptAlive=false
	if antiAfkConn then antiAfkConn:Disconnect() end
	gui:Destroy()
end)

warn("✅ 方案A · 最终整合版 已加载")
