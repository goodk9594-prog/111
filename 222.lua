--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")

local P = Players.LocalPlayer
local PlayerGui = P:WaitForChild("PlayerGui")

--====================================================
-- Anti AFK（最原始稳定写法）
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

--====================================================
-- 清理旧 GUI（简单粗暴）
--====================================================
pcall(function()
	PlayerGui:FindFirstChild("StableGui"):Destroy()
end)

--====================================================
-- 唯一 ScreenGui（关键）
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
-- 拖动（直接写，不封装）
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
-- 关闭按钮（关闭即清数据）
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
local Saved = {}
local saveId = 0

--====================================================
-- Toggle Buttons
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
-- TP 子窗口（Frame，不是 ScreenGui）
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

local list = Instance.new("UIListLayout", tp)
list.Padding = UDim.new(0,4)

openTP.MouseButton1Click:Connect(function()
	tp.Visible = not tp.Visible
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
	Saved = {}
end)

--====================================================
-- 自动拾取 & 果实检测（逻辑不依赖 GUI）
--====================================================
local FRUIT = {
	["Hie Hie Devil Fruit"]=true,
	["Bomu Bomu Devil Fruit"]=true,
	["Mochi Mochi Devil Fruit"]=true,
	["Nikyu Nikyu Devil Fruit"]=true,
	["Bari Bari Devil Fruit"]=true,
}
local BOX = {Box=true,Chest=true,Barrel=true}

workspace.DescendantAdded:Connect(function(o)
	if o:IsA("ProximityPrompt") then
		local c = o.Parent
		while c do
			if FRUIT[c.Name] and State.fruit then
				fireproximityprompt(o)
				break
			end
			if BOX[c.Name] and State.box then
				fireproximityprompt(o)
				break
			end
			c = c.Parent
		end
	end
end)

warn("✅ 手机稳定版 GUI 已加载")
