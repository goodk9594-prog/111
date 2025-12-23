-- ================== Services ==================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local P = Players.LocalPlayer

-- ================== State ==================
local running = true
local autoFruit = true
local busy = false
local bad = {}

-- ================== Config ==================
local MAX_DIST = 3000
local FAIL_CD = 5

-- ================== Whitelist ==================
local BOX = {Box=true,Chest=true,Barrel=true}
local FRUIT = {
	["Hie Hie Devil Fruit"]=true,
	["Bomu Bomu Devil Fruit"]=true,
	["Mochi Mochi Devil Fruit"]=true,
	["Nikyu Nikyu Devil Fruit"]=true,
	["Bari Bari Devil Fruit"]=true,
}

-- ================== Anti AFK ==================
task.spawn(function()
	while running do
		task.wait(60)
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new(0,0))
		end)
	end
end)

-- ================== Character ==================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

-- ================== GUI ==================
local gui = Instance.new("ScreenGui")
gui.Name = "FruitAutoGui"
gui.ResetOnSpawn = false
gui.Parent = CoreGui
pcall(function() syn.protect_gui(gui) end)

-- 主窗口
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,240,0,280)
frame.Position = UDim2.new(0,30,0,200)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)

-- 关闭按钮（停止脚本）
local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0,22,0,22)
close.Position = UDim2.new(1,-26,0,4)
close.Text = "X"

-- 最小化按钮
local mini = Instance.new("TextButton", frame)
mini.Size = UDim2.new(0,22,0,22)
mini.Position = UDim2.new(1,-52,0,4)
mini.Text = "-"

-- 图标
local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,48,0,48)
icon.Position = UDim2.new(0,20,0,200)
icon.Text = "🍎"
icon.Visible = false

-- ================== 果实记录框 ==================
local list = Instance.new("ScrollingFrame", frame)
list.Position = UDim2.new(0,8,0,40)
list.Size = UDim2.new(1,-16,1,-48)
list.CanvasSize = UDim2.new(0,0,0,0)
list.ScrollBarImageTransparency = 0

local layout = Instance.new("UIListLayout", list)

local function addRecord(name)
	local t = os.date("%H:%M:%S")
	local label = Instance.new("TextLabel", list)
	label.Size = UDim2.new(1,-4,0,20)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Left
	label.TextSize = 14
	label.Text = "["..t.."] "..name
	label.TextColor3 = Color3.fromRGB(255,200,60)
	task.wait()
	list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

-- ================== 防出屏幕展开 ==================
local function safeExpandFromIcon()
	local vp = workspace.CurrentCamera.ViewportSize
	local size = frame.AbsoluteSize
	local pos = icon.AbsolutePosition
	local x,y = pos.X,pos.Y

	if x + size.X > vp.X then x = vp.X - size.X end
	if y + size.Y > vp.Y then y = vp.Y - size.Y end
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end

	frame.Position = UDim2.fromOffset(x,y)
end

-- ================== Buttons ==================
mini.MouseButton1Click:Connect(function()
	frame.Visible = false
	icon.Visible = true
end)

close.MouseButton1Click:Connect(function()
	running = false
	gui:Destroy()
end)

icon.MouseButton1Click:Connect(function()
	safeExpandFromIcon()
	frame.Visible = true
	icon.Visible = false
end)

-- ================== 手机端拖动图标 ==================
local dragging,startPos,startTouch=false
icon.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then
		dragging=true
		startPos=icon.Position
		startTouch=i.Position
	end
end)

icon.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then
		dragging=false
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and i.UserInputType==Enum.UserInputType.Touch then
		local d=i.Position-startTouch
		icon.Position=UDim2.new(
			startPos.X.Scale,startPos.X.Offset+d.X,
			startPos.Y.Scale,startPos.Y.Offset+d.Y
		)
	end
end)

-- ================== Utils ==================
local function kind(p)
	local c=p.Parent
	while c do
		if FRUIT[c.Name] then return "fruit" end
		if BOX[c.Name] then return "box" end
		c=c.Parent
	end
end

local function pick(p)
	if busy or (bad[p] and os.clock()<bad[p]) then return end
	local part=p.Parent:IsA("Attachment") and p.Parent.Parent or p.Parent
	if not part:IsA("BasePart") then return end

	local hrp=HRP()
	if (hrp.Position-part.Position).Magnitude>MAX_DIST then return end

	busy=true
	hrp.CFrame=part.CFrame*CFrame.new(0,0,2)
	task.wait(0.15)
	if fireproximityprompt then fireproximityprompt(p) end
	task.wait(0.25)

	if p.Parent then bad[p]=os.clock()+FAIL_CD end
	busy=false
end

-- ================== 自动拾取 ==================
task.spawn(function()
	while running do
		task.wait(0.4)
		if busy then continue end

		local hrp=HRP()
		local best,dist=nil,math.huge

		for _,v in ipairs(workspace:GetDescendants()) do
			if v:IsA("ProximityPrompt") and v.Enabled then
				local t=kind(v)
				if t=="box" or (t=="fruit" and autoFruit) then
					local p=v.Parent:IsA("Attachment") and v.Parent.Parent or v.Parent
					if p:IsA("BasePart") then
						local d=(hrp.Position-p.Position).Magnitude
						if d<dist then dist,best=d,v end
					end
				end
			end
		end

		if best then pick(best) end
	end
end)

-- ================== 果实生成检测 ==================
workspace.DescendantAdded:Connect(function(o)
	if not running or not o:IsA("ProximityPrompt") then return end
	task.wait(0.1)
	local c=o.Parent
	while c do
		if FRUIT[c.Name] then
			addRecord(c.Name)
			break
		end
		c=c.Parent
	end
end)
