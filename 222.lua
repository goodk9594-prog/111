--====================================================
-- 等待环境稳定（非常关键）
--====================================================
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local PPS = game:GetService("ProximityPromptService")

local P = Players.LocalPlayer
local PlayerGui = P:WaitForChild("PlayerGui", 10)
if not PlayerGui then return end

task.wait(0.5) -- 再等一帧，防止 GUI 被吞

--====================================================
-- Anti AFK
--====================================================
P.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

--====================================================
-- Mobile Prompt Fix
--====================================================
if UIS.TouchEnabled then
	PPS.PromptShown:Connect(function(p)
		p.HoldDuration = 0
	end)
end

--====================================================
-- Utils
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

local function drag(handle, target)
	local dragging, startPos, startGui
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = i.Position
			startGui = target.Position
		end
	end)
	handle.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startPos
			target.Position = UDim2.new(
				startGui.X.Scale, startGui.X.Offset + d.X,
				startGui.Y.Scale, startGui.Y.Offset + d.Y
			)
		end
	end)
end

--====================================================
-- 清理旧 GUI
--====================================================
for _,g in ipairs(PlayerGui:GetChildren()) do
	if g.Name == "MainGui" or g.Name == "TPGui" then
		g:Destroy()
	end
end

--====================================================
-- ScreenGui 创建函数（强制显示核心）
--====================================================
local function newGui(name)
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.Enabled = true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = PlayerGui
	return g
end

--====================================================
-- 自动拾取配置（原始）
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

local S = {boxPick=false, fruitPick=false}
local busy, bad = false, {}

--====================================================
-- 主 GUI
--====================================================
local mainGui = newGui("MainGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0,240,0,340)
main.Position = UDim2.new(0,20,0,120)
main.BackgroundColor3 = Color3.fromRGB(35,35,35)
main.BorderSizePixel = 0
main.Parent = mainGui

local top = Instance.new("Frame", main)
top.Size = UDim2.new(1,0,0,28)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)
drag(top, main)

local closeMain = Instance.new("TextButton", top)
closeMain.Size = UDim2.new(0,24,0,22)
closeMain.Position = UDim2.new(1,-28,0,3)
closeMain.Text = "X"
closeMain.BackgroundColor3 = Color3.fromRGB(140,60,60)

--====================================================
-- Toggle
--====================================================
local function toggle(y,text,key)
	local b=Instance.new("TextButton",main)
	b.Size=UDim2.new(1,-10,0,26)
	b.Position=UDim2.new(0,5,0,y)
	b.BackgroundColor3=Color3.fromRGB(60,60,60)
	b.TextColor3=Color3.new(1,1,1)
	b.Text=text.."关"
	b.BorderSizePixel=0
	b.MouseButton1Click:Connect(function()
		S[key]=not S[key]
		b.Text=text..(S[key] and "开" or "关")
	end)
end

toggle(40,"自动拾取箱子：","boxPick")
toggle(70,"拾取果实：","fruitPick")

--====================================================
-- 果实记录框
--====================================================
local list = Instance.new("ScrollingFrame", main)
list.Position = UDim2.new(0,5,0,140)
list.Size = UDim2.new(1,-10,1,-145)
list.ScrollBarThickness = 6
list.BackgroundColor3 = Color3.fromRGB(28,28,28)
list.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0,4)

local function nowTime()
	local t = os.date("*t")
	return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

local function addFruitLog(name)
	local l = Instance.new("TextLabel", list)
	l.Size = UDim2.new(1,-4,0,20)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Left
	l.Font = Enum.Font.SourceSansBold
	l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(255,200,60)
	l.Text = string.format("%s [%s]", name, nowTime())
	task.wait()
	list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

--====================================================
-- TP 子 GUI（最小化 / 关闭 / 保存）
--====================================================
local tpGui = newGui("TPGui")
tpGui.Enabled = false

local tpFrame = Instance.new("Frame", tpGui)
tpFrame.Size = UDim2.new(0,260,0,300)
tpFrame.Position = UDim2.new(0.5,-130,0.5,-150)
tpFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)

local tpTop = Instance.new("Frame", tpFrame)
tpTop.Size = UDim2.new(1,0,0,30)
tpTop.BackgroundColor3 = Color3.fromRGB(25,25,25)
drag(tpTop, tpFrame)

local tpMin = Instance.new("TextButton", tpTop)
tpMin.Size = UDim2.new(0,30,0,22)
tpMin.Position = UDim2.new(1,-64,0,4)
tpMin.Text = "-"

local tpClose = Instance.new("TextButton", tpTop)
tpClose.Size = UDim2.new(0,30,0,22)
tpClose.Position = UDim2.new(1,-34,0,4)
tpClose.Text = "X"

local openTP = Instance.new("TextButton", main)
openTP.Size = UDim2.new(1,-10,0,28)
openTP.Position = UDim2.new(0,5,0,105)
openTP.Text = "坐标传送面板"
openTP.BackgroundColor3 = Color3.fromRGB(70,130,180)

openTP.MouseButton1Click:Connect(function()
	tpGui.Enabled = true
	tpFrame.Visible = true
end)

tpClose.MouseButton1Click:Connect(function()
	tpGui.Enabled = false
end)

tpMin.MouseButton1Click:Connect(function()
	tpFrame.Visible = false
end)

closeMain.MouseButton1Click:Connect(function()
	mainGui:Destroy()
	tpGui:Destroy()
end)

--====================================================
-- 自动拾取 + 果实检测（原逻辑）
--====================================================
local function getType(pp)
	local c=pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit",c end
		if BOX[c.Name] then return "box",c end
		c=c.Parent
	end
end

local funct
