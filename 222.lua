--====================================================
-- Services
--====================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local PPS = game:GetService("ProximityPromptService")
local P = Players.LocalPlayer
local PlayerGui = P:WaitForChild("PlayerGui")

--====================================================
-- Anti AFK
--====================================================
P.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
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
	local d, sp, tp
	handle.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			d=true sp=i.Position tp=target.Position
		end
	end)
	handle.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			d=false
		end
	end)
	handle.InputChanged:Connect(function(i)
		if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
			local v=i.Position-sp
			target.Position=UDim2.new(tp.X.Scale,tp.X.Offset+v.X,tp.Y.Scale,tp.Y.Offset+v.Y)
		end
	end)
end

--====================================================
-- 清理旧 GUI
--====================================================
pcall(function() PlayerGui.MainGui:Destroy() end)
pcall(function() PlayerGui.TPGui:Destroy() end)

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
local mainGui = Instance.new("ScreenGui", PlayerGui)
mainGui.Name = "MainGui"
mainGui.ResetOnSpawn = false

local main = Instance.new("Frame", mainGui)
main.Size = UDim2.new(0,230,0,320)
main.Position = UDim2.new(0,20,0,120)
main.BackgroundColor3 = Color3.fromRGB(35,35,35)

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
	b.MouseButton1Click:Connect(function()
		S[key]=not S[key]
		b.Text=text..(S[key] and "开" or "关")
	end)
end

toggle(40,"自动拾取箱子：","boxPick")
toggle(70,"拾取果实：","fruitPick")

--====================================================
-- 打开 TP 面板按钮（缺失项修复）
--====================================================
local openTP = Instance.new("TextButton", main)
openTP.Size = UDim2.new(1,-10,0,28)
openTP.Position = UDim2.new(0,5,0,105)
openTP.Text = "坐标传送面板"
openTP.BackgroundColor3 = Color3.fromRGB(70,130,180)

--====================================================
-- 果实记录列表（缺失项修复）
--====================================================
local list = Instance.new("ScrollingFrame", main)
list.Position = UDim2.new(0,5,0,145)
list.Size = UDim2.new(1,-10,1,-150)
list.ScrollBarThickness = 6
list.BackgroundColor3 = Color3.fromRGB(28,28,28)

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0,4)

local function nowTime()
	local t=os.date("*t")
	return string.format("%02d:%02d:%02d",t.hour,t.min,t.sec)
end

local function addFruitLog(name)
	local l=Instance.new("TextLabel",list)
	l.Size=UDim2.new(1,-4,0,20)
	l.BackgroundTransparency=1
	l.TextXAlignment=Left
	l.Font=Enum.Font.SourceSansBold
	l.TextSize=13
	l.TextColor3=Color3.fromRGB(255,200,60)
	l.Text=string.format("%s [%s]",name,nowTime())
	task.wait()
	list.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

--====================================================
-- TP 子 GUI（完整）
--====================================================
local tpGui = Instance.new("ScreenGui", PlayerGui)
tpGui.Name = "TPGui"
tpGui.Enabled = false
tpGui.ResetOnSpawn = false

local tpFrame = Instance.new("Frame", tpGui)
tpFrame.Size = UDim2.new(0,260,0,300)
tpFrame.Position = UDim2.new(0.5,-130,0.5,-150)
tpFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)

local tpTop = Instance.new("Frame", tpFrame)
tpTop.Size = UDim2.new(1,0,0,30)
tpTop.BackgroundColor3 = Color3.fromRGB(25,25,25)
drag(tpTop,tpFrame)

local tpMin = Instance.new("TextButton", tpTop)
tpMin.Size = UDim2.new(0,30,0,22)
tpMin.Position = UDim2.new(1,-64,0,4)
tpMin.Text = "-"

local tpClose = Instance.new("TextButton", tpTop)
tpClose.Size = UDim2.new(0,30,0,22)
tpClose.Position = UDim2.new(1,-34,0,4)
tpClose.Text = "X"

local tpContent = Instance.new("Frame", tpFrame)
tpContent.Position = UDim2.new(0,5,0,35)
tpContent.Size = UDim2.new(1,-10,1,-40)
tpContent.BackgroundTransparency = 1

local tpLayout = Instance.new("UIListLayout", tpContent)
tpLayout.Padding = UDim.new(0,5)

local saveBtn = Instance.new("TextButton", tpContent)
saveBtn.Size = UDim2.new(1,0,0,32)
saveBtn.Text = "保存当前坐标"
saveBtn.BackgroundColor3 = Color3.fromRGB(70,130,180)

local TP_DATA, TP_ID = {}, 0

local function refreshTP()
	for _,c in ipairs(tpContent:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for i,v in ipairs(TP_DATA) do
		local row=Instance.new("Frame",tpContent)
		row.Size=UDim2.new(1,0,0,30)
		row.BackgroundTransparency=1
		local tp=Instance.new("TextButton",row)
		tp.Size=UDim2.new(1,-34,1,0)
		tp.Text=v.name
		tp.BackgroundColor3=Color3.fromRGB(60,60,60)
		local del=Instance.new("TextButton",row)
		del.Size=UDim2.new(0,30,1,0)
		del.Position=UDim2.new(1,-30,0,0)
		del.Text="X"
		del.BackgroundColor3=Color3.fromRGB(170,60,60)
		tp.MouseButton1Click:Connect(function()
			HRP().CFrame=v.cf
		end)
		
