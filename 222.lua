--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")

local P = Players.LocalPlayer
local PlayerGui
repeat
	task.wait()
	PlayerGui = P:FindFirstChildOfClass("PlayerGui")
until PlayerGui

--====================================================
-- Anti AFK（稳定）
--====================================================
P.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

--====================================================
-- Mobile Prompt Fix（长按 → 立即）
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

--====================================================
-- 清理旧 GUI
--====================================================
pcall(function()
	PlayerGui:FindFirstChild("StableGui"):Destroy()
end)

--====================================================
-- 唯一 ScreenGui（手机最稳）
--====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "StableGui"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

--====================================================
-- 主窗口
--====================================================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,260,0,360)
frame.Position = UDim2.new(0,30,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)

local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

--====================================================
-- 拖动
--====================================================
do
	local dragging, sp, fp
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			sp = i.Position
			fp = frame.Position
		end
	end)
	top.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - sp
			frame.Position = UDim2.new(fp.X.Scale, fp.X.Offset + d.X, fp.Y.Scale, fp.Y.Offset + d.Y)
		end
	end)
end

--====================================================
-- 关闭按钮（清数据）
--====================================================
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,28,0,22)
close.Position = UDim2.new(1,-32,0,4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(150,60,60)

--====================================================
-- 状态
--====================================================
local State = {box=false, fruit=false}
local saveId = 0
local FruitLog = {}

--====================================================
-- Toggle
--====================================================
local function toggle(y,text,key)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-10,0,26)
	b.Position = UDim2.new(0,5,0,y)
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.TextColor3 = Color3.new(1,1,1)
	b.Text = text.."关"
	b.MouseButton1Click:Connect(function()
		State[key] = not State[key]
		b.Text = text .. (State[key] and "开" or "关")
	end)
end

toggle(40,"自动拾取箱子：","box")
toggle(70,"自动拾取果实：","fruit")

--====================================================
-- TP 面板按钮
--====================================================
local openTP = Instance.new("TextButton", frame)
openTP.Size = UDim2.new(1,-10,0,28)
openTP.Position = UDim2.new(0,5,0,105)
openTP.Text = "坐标传送面板"
openTP.BackgroundColor3 = Color3.fromRGB(70,130,180)
--====================================================
-- 果实生成记录（GUI）
--====================================================
local logTitle = Instance.new("TextLabel", frame)
logTitle.Size = UDim2.new(1,-10,0,22)
logTitle.Position = UDim2.new(0,5,0,180)
logTitle.Text = "果实生成记录"
logTitle.TextColor3 = Color3.fromRGB(255,200,60)
logTitle.BackgroundTransparency = 1
logTitle.TextXAlignment = Left

local logList = Instance.new("ScrollingFrame", frame)
logList.Position = UDim2.new(0,5,0,205)
logList.Size = UDim2.new(1,-10,0,130)
logList.CanvasSize = UDim2.new(0,0,0,0)
logList.ScrollBarThickness = 6
logList.BackgroundColor3 = Color3.fromRGB(28,28,28)
logList.BorderSizePixel = 0

local logLayout = Instance.new("UIListLayout", logList)
logLayout.Padding = UDim.new(0,4)

--====================================================
-- TP 子窗口（Frame）
--====================================================
local tp = Instance.new("Frame", frame)
tp.Size = UDim2.new(1,-10,0,180)
tp.Position = UDim2.new(0,5,0,140)
tp.BackgroundColor3 = Color3.fromRGB(30,30,30)
tp.Visible = false

local save = Instance.new("TextButton", tp)
save.Size = UDim2.new(1,0,0,28)
save.Text = "保存当前位置"
save.BackgroundColor3 = Color3.fromRGB(80,140,200)

local layout = Instance.new("UIListLayout", tp)
layout.Padding = UDim.new(0,4)

openTP.MouseButton1Click:Connect(function()
	tp.Visible = not tp.Visible
	logTitle.Visible = not tp.Visible
	logList.Visible = not tp.Visible
end)


save.MouseButton1Click:Connect(function()
	saveId += 1
	local cf = HRP().CFrame
	local btn = Instance.new("TextButton", tp)
	btn.Size = UDim2.new(1,0,0,26)
	btn.Text = "坐标 "..saveId
	btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	btn.MouseButton1Click:Connect(function()
		HRP().CFrame = cf
	end)
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

--====================================================
-- 自动拾取（长按 Prompt 修复版）
--====================================================
local FRUIT = {
	["Hie Hie Devil Fruit"]=true,
	["Bomu Bomu Devil Fruit"]=true,
	["Mochi Mochi Devil Fruit"]=true,
	["Nikyu Nikyu Devil Fruit"]=true,
	["Bari Bari Devil Fruit"]=true,
}
local BOX = {Box=true,Chest=true,Barrel=true}

local busy = false
local MAX_DIST = 3000
local SCAN = 0.4

local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit", c end
		if BOX[c.Name] then return "box", c end
		c = c.Parent
	end
end
--====================================================
-- 果实记录工具函数
--====================================================
local function nowTime()
	local t = os.date("*t")
	return string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
end

local function addFruitLog(name)
	local time = nowTime()
	table.insert(FruitLog, {name=name, time=time})

	local l = Instance.new("TextLabel", logList)
	l.Size = UDim2.new(1,-4,0,20)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Left
	l.Font = Enum.Font.SourceSansBold
	l.TextSize = 13
	l.TextColor3 = Color3.fromRGB(255,200,60)
	l.Text = string.format("%s  [%s]", name, time)

	task.wait()
	logList.CanvasSize = UDim2.new(0,0,0,logLayout.AbsoluteContentSize.Y)
end

task.spawn(function()
	while true do
		task.wait(SCAN)
		if busy then continue end

		local hrp = HRP()
		local best, dist = nil, math.huge

		for _,pp in ipairs(workspace:GetDescendants()) do
			if pp:IsA("ProximityPrompt") and pp.Enabled then
				if pp.HoldDuration > 0 then
					pp.HoldDuration = 0
				end

				local kind, model = getType(pp)
				if kind == "fruit" and not State.fruit then continue end
				if kind == "box" and not State.box then continue end
				if not kind then continue end

				local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
				if part:IsA("BasePart") then
					local d = (hrp.Position - part.Position).Magnitude
					if d < dist and d <= MAX_DIST then
						best = pp
						dist = d
					end
				end
			end
		end

		if best then
			busy = true
			local part = best.Parent:IsA("Attachment") and best.Parent.Parent or best.Parent
			HRP().CFrame = part.CFrame * CFrame.new(0,0,2)
			task.wait(0.15)
			if fireproximityprompt then
				fireproximityprompt(best, 0)
			end
			task.wait(0.3)
			busy = false
		end
	end
end)
--====================================================
-- 果实生成监听（始终开启）
--====================================================
workspace.DescendantAdded:Connect(function(obj)
	if not obj:IsA("ProximityPrompt") then return end

	task.wait(0.1) -- 等模型完整

	local c = obj.Parent
	while c do
		if FRUIT and FRUIT[c.Name] then
			addFruitLog(c.Name)
			break
		end
		c = c.Parent
	end
end)

warn("✅ 手机稳定 · 最终整合版 已加载")
