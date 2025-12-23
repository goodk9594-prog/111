-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local P = Players.LocalPlayer

-- ===== Global Run Switch =====
local RUNNING = true

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
local FruitLog = {}

-- ===== GUI =====
pcall(function() CoreGui.AutoPickGui:Destroy() end)
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,200,0,270)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

-- ===== Minimize Icon =====
local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)
icon.TextColor3 = Color3.new(1,1,1)
icon.BorderSizePixel = 0
Instance.new("UICorner",icon).CornerRadius = UDim.new(1,0)

-- 初始位置
icon.Position = UDim2.new(0,20,0,120)
frame.Position = icon.Position + UDim2.new(0,0,0,50)

-- ===== Toggle Buttons =====
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

-- ===== Close / Minimize / Kill =====
local close=Instance.new("TextButton",frame)
close.Size=UDim2.new(0,22,0,22)
close.Position=UDim2.new(1,-26,0,4)
close.Text="X"
close.BackgroundColor3=Color3.fromRGB(140,60,60)
close.TextColor3=Color3.new(1,1,1)
close.BorderSizePixel=0

-- 短按：最小化 ｜ 长按1秒：彻底关闭
local pressTime
close.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
		pressTime = os.clock()
	end
end)

close.InputEnded:Connect(function(i)
	if not pressTime then return end
	local held = os.clock() - pressTime
	pressTime = nil

	if held > 1 then
		-- 🔴 完全关闭脚本
		RUNNING = false
		gui:Destroy()
	else
		-- 🟡 最小化
		icon.Position = frame.Position
		frame.Visible = false
		icon.Visible = true
	end
end)

-- 图标展开（跟随位置）
icon.MouseButton1Click:Connect(function()
	frame.Position = icon.Position + UDim2.new(0,0,0,50)
	frame.Visible = true
	icon.Visible = false
end)

-- ===== Touch Drag Icon =====
local dragging,startPos,startTouch=false
icon.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then
		dragging=true
		startPos=icon.Position
		startTouch=i.Position
	end
end)
icon.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then dragging=false end
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

-- ===== Utils =====
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

-- ===== Main Loop =====
task.spawn(function()
	while RUNNING do
		task.wait(SCAN)
		if busy then continue end

		local hrp=HRP()
		local best,dist=nil,math.huge

		for _,pp in ipairs(workspace:GetDescendants()) do
			if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end
			if bad[pp] and bad[pp]>os.clock() then continue end

			local t,_=getType(pp)
			if t=="box" and not S.boxPick then continue end
			if t=="fruit" and not S.fruitPick then continue end
			if not t then continue end

			local part=pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
			if part:IsA("BasePart") then
				local d=(hrp.Position-part.Position).Magnitude
				if d<=MAX_DIST and d<dist then dist,best=d,pp end
			end
		end

		if best then
			busy=true
			local part=best.Parent:IsA("Attachment") and best.Parent.Parent or best.Parent
			hrp.CFrame=part.CFrame*CFrame.new(0,0,2)
			task.wait(0.15)
			if fireproximityprompt then fireproximityprompt(best) end
			task.wait(0.25)
			if best.Parent then bad[best]=os.clock()+FAIL_CD end
			busy=false
		end
	end
end)

-- ===== Anti AFK =====
task.spawn(function()
	while RUNNING do
		task.wait(60)
		pcall(function()
			VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
			task.wait(0.1)
			VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
		end)
	end
end)
