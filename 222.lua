--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer

--====================================================
-- Config（完全保留方案 A）
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
local FruitLog = {}
local SavedPos = {}
local Running = true

--====================================================
-- GUI 清理
--====================================================
pcall(function() CoreGui.AutoPickGui:Destroy() end)

local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"

--====================================================
-- 主窗口
--====================================================
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

--====================================================
-- 拖动
--====================================================
do
	local dragging, sp, fp
	top.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true
			sp=i.Position
			fp=frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
			local d=i.Position-sp
			frame.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
		end
	end)
	top.InputEnded:Connect(function() dragging=false end)
end

--====================================================
-- 最小化 / 关闭
--====================================================
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,26,0,22)
close.Position = UDim2.new(1,-30,0,4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(150,60,60)

local mini = Instance.new("TextButton", top)
mini.Size = UDim2.new(0,26,0,22)
mini.Position = UDim2.new(1,-60,0,4)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80,80,80)

local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Position = frame.Position
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)

mini.MouseButton1Click:Connect(function()
	frame.Visible=false
	icon.Visible=true
	icon.Position=frame.Position
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible=true
	icon.Visible=false
end)

close.MouseButton1Click:Connect(function()
	Running=false
	gui:Destroy()
end)

--====================================================
-- Toggle
--====================================================
local function toggle(y,text,key)
	local b=Instance.new("TextButton",frame)
	b.Size=UDim2.new(1,-10,0,26)
	b.Position=UDim2.new(0,5,0,y)
	b.Text=text.."关"
	b.BackgroundColor3=Color3.fromRGB(60,60,60)
	b.MouseButton1Click:Connect(function()
		S[key]=not S[key]
		b.Text=text..(S[key] and "开" or "关")
	end)
end

toggle(40,"自动拾取箱子：","boxPick")
toggle(70,"自动拾取果实：","fruitPick")

--====================================================
-- 坐标面板（右侧展开）
--====================================================
local tpBtn = Instance.new("TextButton", frame)
tpBtn.Size = UDim2.new(1,-10,0,28)
tpBtn.Position = UDim2.new(0,5,0,110)
tpBtn.Text = "坐标传送面板"

local tp = Instance.new("Frame", gui)
tp.Size = UDim2.new(0,200,0,240)
tp.Position = UDim2.new(0,250,0,120)
tp.BackgroundColor3 = Color3.fromRGB(30,30,30)
tp.Visible = false

local layout = Instance.new("UIListLayout", tp)
layout.Padding = UDim.new(0,4)

local saveBtn = Instance.new("TextButton", tp)
saveBtn.Size = UDim2.new(1,0,0,28)
saveBtn.Text = "保存当前位置"

tpBtn.MouseButton1Click:Connect(function()
	tp.Visible = not tp.Visible
	tp.Position = UDim2.new(0,frame.AbsolutePosition.X+frame.AbsoluteSize.X+10,0,frame.AbsolutePosition.Y)
end)

local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

saveBtn.MouseButton1Click:Connect(function()
	local cf = HRP().CFrame
	local item = Instance.new("Frame", tp)
	item.Size = UDim2.new(1,0,0,26)

	local go = Instance.new("TextButton", item)
	go.Size = UDim2.new(0.7,0,1,0)
	go.Text = "传送"
	go.MouseButton1Click:Connect(function()
		HRP().CFrame = cf
	end)

	local del = Instance.new("TextButton", item)
	del.Size = UDim2.new(0.3,0,1,0)
	del.Position = UDim2.new(0.7,0,0,0)
	del.Text = "删除"
	del.MouseButton1Click:Connect(function()
		item:Destroy()
	end)
end)

--====================================================
-- 果实记录（服务器时间戳）
--====================================================
local list = Instance.new("ScrollingFrame", frame)
list.Position = UDim2.new(0,5,0,150)
list.Size = UDim2.new(1,-10,1,-155)
list.ScrollBarThickness = 6

local ll = Instance.new("UIListLayout", list)
ll.Padding = UDim.new(0,4)

local function addFruit(name)
	local t = os.time()
	local l = Instance.new("TextLabel", list)
	l.Size = UDim2.new(1,-4,0,20)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Left
	l.Text = name.." ["..t.."]"
	list.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y)
end

--====================================================
-- 自动拾取（原封不动方案 A）
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
		if not Running then return end
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

task.spawn(function()
	while Running do
		task.wait(SCAN)
		if not busy then
			local pp=bestPrompt()
			if pp then
				busy=true
				local part=pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
				HRP().CFrame=part.CFrame*CFrame.new(0,0,2)
				task.wait(0.15)
				if fireproximityprompt then fireproximityprompt(pp) end
				task.wait(0.25)
				if pp.Parent then bad[pp]=os.clock()+FAIL_CD end
				busy=false
			end
		end
	end
end)

workspace.DescendantAdded:Connect(function(o)
	if not Running then return end
	if o:IsA("ProximityPrompt") then
		task.wait(0.1)
		local kind,model=getType(o)
		if kind=="fruit" then
			addFruit(model.Name)
		end
	end
end)

warn("✅ 方案A · 终极稳定整合版 已加载")
