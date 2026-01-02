--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer

--====================================================
-- Anti AFK
--====================================================
local VirtualUser = game:GetService("VirtualUser")

P.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new(0,0))
end)

--====================================================
-- Config（方案 A）
--====================================================
local MAX_DIST, FAIL_CD, SCAN = 3000, 6, 0.4

local FRUIT = {
	["Requiem Arrow"] = true,
	["Vampire Mask"] = true,
	["Shadow Camera"] = true,
	["Holy Corpse"] = true,
	["Nostalgic Relic"] = true,
	["Monochromatic Sphere"] = true,
	["Ender Pearl"] = true,
	["Galaxy Portal"] = true,
}
local BOX = {Box=true,Chest=true,Barrel=true}

--====================================================
-- State
--====================================================
local S = {boxPick=false, fruitPick=false}
local busy, bad = false, {}
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
frame.Size = UDim2.new(0,220,0,320)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

--====================================================
-- 顶栏（拖拽）
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

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
	frame.Visible = false
	icon.Visible = true
	icon.Position = frame.Position
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
end)

close.MouseButton1Click:Connect(function()
	Running = false
	gui:Destroy()
end)

-- icon 手机拖拽
do
	local dragging, sp, fp
	icon.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			sp = i.Position
			fp = icon.Position
		end
	end)
	icon.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - sp
			icon.Position = UDim2.new(fp.X.Scale, fp.X.Offset+d.X, fp.Y.Scale, fp.Y.Offset+d.Y)
		end
	end)
end

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
-- 坐标传送面板
--====================================================
local tpBtn = Instance.new("TextButton", frame)
tpBtn.Size = UDim2.new(1,-10,0,28)
tpBtn.Position = UDim2.new(0,5,0,110)
tpBtn.Text = "坐标传送面板"

local tp = Instance.new("Frame", gui)
tp.Size = UDim2.new(0,200,0,240)
tp.BackgroundColor3 = Color3.fromRGB(30,30,30)
tp.Visible = false

local tpList = Instance.new("UIListLayout", tp)
tpList.Padding = UDim.new(0,4)

local saveBtn = Instance.new("TextButton", tp)
saveBtn.Size = UDim2.new(1,0,0,28)
saveBtn.Text = "保存当前位置"

tpBtn.MouseButton1Click:Connect(function()
	tp.Visible = not tp.Visible
	tp.Position = UDim2.new(
		0, frame.AbsolutePosition.X + frame.AbsoluteSize.X + 10,
		0, frame.AbsolutePosition.Y
	)
end)

--====================================================
-- 工具
--====================================================
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
-- 果实记录
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
-- 自动拾取（方案 A 原逻辑）
--====================================================
local function getType(pp)
	local c=pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit",c end
		if BOX[c.Name] then return	return LP.Character or LP.CharacterAdded:Wait()
end

local function HRP()
	return Char():WaitForChild("HumanoidRootPart")
end

--====================================================
-- GUI Cleanup
--====================================================
pcall(function()
	CoreGui.OABD_GUI:Destroy()
end)

--====================================================
-- GUI Base
--====================================================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "OABD_GUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 260)
frame.Position = UDim2.new(0, 30, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0

--====================================================
-- Top Bar (Drag)
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(20,20,20)

local dragging, dragStart, startPos

top.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = frame.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
	or i.UserInputType == Enum.UserInputType.Touch) then
		local delta = i.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function()
	dragging = false
end)

--====================================================
-- Minimize & Close
--====================================================
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,24,0,20)
close.Position = UDim2.new(1,-28,0,5)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(140,60,60)

local mini = Instance.new("TextButton", top)
mini.Size = UDim2.new(0,24,0,20)
mini.Position = UDim2.new(1,-56,0,5)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80,80,80)

local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Text = "⚔️"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)

mini.MouseButton1Click:Connect(function()
	frame.Visible = false
	icon.Visible = true
	icon.Position = frame.Position
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- icon drag
icon.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = icon.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
	or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart
		icon.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + d.X,
			startPos.Y.Scale,
			startPos.Y.Offset + d.Y
		)
	end
end)

--====================================================
-- Buttons
--====================================================
local function Button(y, text, callback)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-10,0,28)
	b.Position = UDim2.new(0,5,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.MouseButton1Click:Connect(callback)
	return b
end

local auraBtn = Button(40, "Kill Aura：关", function()
	KillAura = not KillAura
	auraBtn.Text = "Kill Aura："..(KillAura and "开" or "关")
end)

local pickBtn = Button(75, "自动拾取：关", function()
	AutoPick = not AutoPick
	pickBtn.Text = "自动拾取："..(AutoPick and "开" or "关")
end)

--====================================================
-- Kill Aura Range Slider
--====================================================
local sliderFrame = Instance.new("Frame", frame)
sliderFrame.Size = UDim2.new(1,-10,0,40)
sliderFrame.Position = UDim2.new(0,5,0,115)
sliderFrame.BackgroundColor3 = Color3.fromRGB(45,45,45)

local sliderText = Instance.new("TextLabel", sliderFrame)
sliderText.Size = UDim2.new(1,0,0,18)
sliderText.BackgroundTransparency = 1
sliderText.TextColor3 = Color3.new(1,1,1)
sliderText.Text = "范围："..KILL_RANGE

local bar = Instance.new("Frame", sliderFrame)
bar.Position = UDim2.new(0,5,0,24)
bar.Size = UDim2.new(1,-10,0,8)
bar.BackgroundColor3 = Color3.fromRGB(70,70,70)

local fill = Instance.new("Frame", bar)
fill.BackgroundColor3 = Color3.fromRGB(120,120,255)
fill.Size = UDim2.new(KILL_RANGE/100,0,1,0)

local draggingSlider = false
local MIN, MAX = 5, 100

local function updateSlider(x)
	local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
	KILL_RANGE = math.floor(MIN + (MAX - MIN) * p)
	fill.Size = UDim2.new(p,0,1,0)
	sliderText.Text = "范围："..KILL_RANGE
end

bar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
		updateSlider(i.Position.X)
	end
end)

UIS.InputChanged:Connect(function(i)
	if draggingSlider and (i.UserInputType == Enum.UserInputType.MouseMovement
	or i.UserInputType == Enum.UserInputType.Touch) then
		updateSlider(i.Position.X)
	end
end)

UIS.InputEnded:Connect(function()
	draggingSlider = false
end)

--====================================================
-- Kill Aura Logic
--====================================================
RunService.Heartbeat:Connect(function()
	if not KillAura then return end
	if not Char():FindFirstChild("HumanoidRootPart") then return end

	for _,m in ipairs(workspace:GetChildren()) do
		local hum = m:FindFirstChildOfClass("Humanoid")
		local hrp = m:FindFirstChild("HumanoidRootPart")
		if hum and hrp and m ~= Char() and hum.Health > 0 then
			if (HRP().Position - hrp.Position).Magnitude <= KILL_RANGE then
				hum.Health = 0
			end
		end
	end
  end
