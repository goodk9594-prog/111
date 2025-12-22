-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer

-- Config
local MAX_DIST, FAIL_CD, SCAN = 3000, 6, 0.4

local FRUIT = {
	["Hie Hie Devil Fruit"]=true,
	["Bomu Bomu Devil Fruit"]=true,
	["Mochi Mochi Devil Fruit"]=true,
	["Nikyu Nikyu Devil Fruit"]=true,
	["Bari Bari Devil Fruit"]=true,
}
local BOX = {Box=true,Chest=true,Barrel=true}

-- State
local S = {boxPick=false, fruitPick=false}
local busy, bad = false, {}
local FruitLog = {} -- 🔒 不随重生清空的果实记录

-- GUI
pcall(function() CoreGui.AutoPickGui:Destroy() end)
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,200,0,270)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

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

toggle(10,"自动拾取箱子：","boxPick")
toggle(40,"拾取果实：","fruitPick")

local close=Instance.new("TextButton",frame)
close.Size=UDim2.new(0,22,0,22)
close.Position=UDim2.new(1,-26,0,4)
close.Text="X"
close.BackgroundColor3=Color3.fromRGB(120,60,60)
close.TextColor3=Color3.new(1,1,1)
close.BorderSizePixel=0
close.MouseButton1Click:Connect(function() gui.Enabled=false end)

-- List
local list=Instance.new("ScrollingFrame",frame)
list.Position=UDim2.new(0,5,0,80)
list.Size=UDim2.new(1,-10,1,-85)
list.CanvasSize=UDim2.new(0,0,0,0)
list.ScrollBarThickness=6
list.BackgroundColor3=Color3.fromRGB(28,28,28)
list.BorderSizePixel=0

local layout=Instance.new("UIListLayout",list)
layout.Padding=UDim.new(0,4)

local function nowTime()
	local t=os.date("*t")
	return string.format("%02d:%02d:%02d",t.hour,t.min,t.sec)
end

local function renderLog(name,time)
	local l=Instance.new("TextLabel",list)
	l.Size=UDim2.new(1,-4,0,20)
	l.BackgroundTransparency=1
	l.TextXAlignment=Left
	l.Font=Enum.Font.SourceSansBold
	l.TextSize=13
	l.TextColor3=Color3.fromRGB(255,200,60)
	l.Text=string.format("%s [%s]",name,time)
end

-- 恢复历史记录（重生不清空）
for _,v in ipairs(FruitLog) do
	renderLog(v.name,v.time)
end

local function addFruit(name)
	local time=nowTime()
	table.insert(FruitLog,{name=name,time=time})
	renderLog(name,time)
	task.wait()
	list.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

-- Minimize icon
local icon=Instance.new("TextButton",gui)
icon.Size=UDim2.new(0,44,0,44)
icon.Position=UDim2.new(0,20,0,120)
icon.Text="🍎"
icon.Visible=false
icon.BackgroundColor3=Color3.fromRGB(60,60,60)
icon.TextColor3=Color3.new(1,1,1)
icon.BorderSizePixel=0
Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0)

frame:GetPropertyChangedSignal("Visible"):Connect(function()
	icon.Visible = not frame.Visible
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible=true
end)

-- 📱 Touch drag only
local dragging,startPos,startTouch=false
icon.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then
		dragging=true; startPos=icon.Position; startTouch=i.Position
	end
end)
icon.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
UIS.InputChanged:Connect(function(i)
	if dragging and i.UserInputType==Enum.UserInputType.Touch then
		local d=i.Position-startTouch
		icon.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
end)

-- Utils
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

local function getType(pp)
	local c=pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit",c end
		if BOX[c.Name] then return "box",c end
		c=c.Parent
	end
end

local function markFruit(m)
	local p=m:FindFirstChildWhichIsA("BasePart",true)
	if not p or p:FindFirstChild("FruitTag") then return end
	local g=Instance.new("BillboardGui",p)
	g.Name="FruitTag"
	g.Size=UDim2.new(0,200,0,36)
	g.StudsOffset=Vector3.new(0,3,0)
	g.AlwaysOnTop=true
	local t=Instance.new("TextLabel",g)
	t.Size=UDim2.fromScale(1,1)
	t.BackgroundTransparency=1
	t.Text=m.Name
	t.TextScaled=true
	t.Font=Enum.Font.SourceSansBold
	t.TextStrokeTransparency=0.2
	t.TextColor3=Color3.fromRGB(255,200,60)
	m.AncestryChanged:Connect(function(_,p) if not p then g:Destroy() end end)
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

-- 果实生成检测（永久开启）
workspace.DescendantAdded:Connect(function(o)
	if o:IsA("ProximityPrompt") then
		task.wait(0.1)
		local kind,model=getType(o)
		if kind=="fruit" then
			markFruit(model)
			addFruit(model.Name)
		end
	end
end)
