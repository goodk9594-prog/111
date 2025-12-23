--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")

local P = Players.LocalPlayer

--====================================================
-- Anti AFK（稳定）
--====================================================
P.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

--====================================================
-- Mobile Prompt Fix（手机长按 → 秒触发）
--====================================================
if UIS.TouchEnabled then
	PPS.PromptShown:Connect(function(p)
		p.HoldDuration = 0
	end)
end

--====================================================
-- Config（原脚本）
--====================================================
local MAX_DIST, FAIL_CD, SCAN = 3000, 6, 0.4

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

--====================================================
-- State（原脚本）
--====================================================
local S = {boxPick=false, fruitPick=false}
local busy, bad = false, {}
local FruitLog = {}

--====================================================
-- Utils
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

--====================================================
-- GUI（安全创建）
--====================================================
pcall(function() CoreGui.AutoPickGui:Destroy() end)

local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,320)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

-- 顶栏
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

-- 拖动
do
	local dragging, sp, fp
	top.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true sp=i.Position fp=frame.Position
		end
	end)
	top.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
			local d=i.Position-sp
			frame.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
		end
	end)
end

-- 关闭 / 最小化
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,22,0,22)
close.Position = UDim2.new(1,-26,0,4)
close.Text="X"
close.BackgroundColor3=Color3.fromRGB(120,60,60)
close.TextColor3=Color3.new(1,1,1)

local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Position = frame.Position
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)
icon.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0)

close.MouseButton1Click:Connect(function()
	frame.Visible=false
	icon.Visible=true
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible=true
	icon.Visible=false
end)

-- Toggles
local function toggle(y,text,key)
	local b=Instance.new("TextButton",frame)
	b.Size=UDim2.new(1,-10,0,26)
	b.Position=UDim2.new(0,5,0,y)
	b.BackgroundColor3=Color3.fromRGB(60,60,60)
	b.TextColor3=Color3.new(1,1,1)
	b.Text=text.."关"
	b.MouseButton1Click:Connect(function()
		S[key]=not S[key]
		b.Text=text..(S[key] and "开" or "关")
	end)
end

toggle(40,"自动拾取箱子：","boxPick")
toggle(70,"拾取果实：","fruitPick")

--====================================================
-- 果实日志
--====================================================
local list=Instance.new("ScrollingFrame",frame)
list.Position=UDim2.new(0,5,0,110)
list.Size=UDim2.new(1,-10,1,-115)
list.ScrollBarThickness=6
list.BackgroundColor3=Color3.fromRGB(28,28,28)
list.BorderSizePixel=0

local layout=Instance.new("UIListLayout",list)
layout.Padding=UDim.new(0,4)

local function nowTime()
	local t=os.date("*t")
	return string.format("%02d:%02d:%02d",t.hour,t.min,t.sec)
end

local function addFruit(name)
	local time=nowTime()
	table.insert(FruitLog,{name=name,time=time})
	local l=Instance.new("TextLabel",list)
	l.Size=UDim2.new(1,-4,0,20)
	l.BackgroundTransparency=1
	l.TextXAlignment=Left
	l.Font=Enum.Font.SourceSansBold
	l.TextSize=13
	l.TextColor3=Color3.fromRGB(255,200,60)
	l.Text=string.format("%s [%s]",name,time)
	task.wait()
	list.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

--====================================================
-- ===== 原版自动拾取逻辑（未改）=====
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
	while task.wait(SCAN) do
		if not busy then
			local pp=bestPrompt()
			if pp then pick(pp) end
		end
	end
end)

-- 果实生成监听（原逻辑）
workspace.DescendantAdded:Connect(function(o)
	if o:IsA("ProximityPrompt") then
		task.wait(0.1)
		local kind,model=getType(o)
		if kind=="fruit" then
			addFruit(model.Name)
		end
	end
end)

warn("✅ 方案A · 最终稳定整合版 已加载")
