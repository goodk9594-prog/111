--====================================================
-- 基础等待（防止一注入就报错）
--====================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local P = Players.LocalPlayer
if not P then return end
if not P.Character then P.CharacterAdded:Wait() end

local PlayerGui = P:WaitForChild("PlayerGui", 10)
if not PlayerGui then return end

--====================================================
-- Anti AFK（安全版）
--====================================================
pcall(function()
	P.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new(0,0))
	end)
end)

--====================================================
-- Config（方案 A）
--====================================================
local MAX_DIST, FAIL_CD, SCAN = 3000, 6, 0.4

local FRUIT = {
	["Hie Hie Devil Fruit"]=true,
	["Bomu Bomu Devil Fruit"]=true,
	["Mochi Mochi Devil Fruit"]=true,
	["Nikyu Nikyu Devil Fruit"]=true,
	["Bari Bari Devil Fruit"]=true,
}
local BOX = { Box=true, Chest=true, Barrel=true }

--====================================================
-- State
--====================================================
local S = { boxPick=false, fruitPick=false }
local bad = {}
local Running = true
local busy = false

--====================================================
-- GUI 清理 & 创建
--====================================================
pcall(function()
	if PlayerGui:FindFirstChild("AutoPickGui") then
		PlayerGui.AutoPickGui:Destroy()
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AutoPickGui"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

--====================================================
-- 主窗口
--====================================================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,330)
frame.Position = UDim2.new(0,40,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

--====================================================
-- 顶栏（拖拽）
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1,-70,1,0)
title.Position = UDim2.new(0,6,0,0)
title.BackgroundTransparency = 1
title.Text = "AutoPick 稳定版"
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Left
title.TextScaled = true

-- 拖拽（鼠标 + 触屏）
do
	local dragging, sp, fp
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			sp = i.Position
			fp = frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
		or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - sp
			frame.Position = UDim2.new(fp.X.Scale, fp.X.Offset + d.X, fp.Y.Scale, fp.Y.Offset + d.Y)
		end
	end)
	top.InputEnded:Connect(function() dragging = false end)
end

--====================================================
-- 最小化 / 关闭
--====================================================
local mini = Instance.new("TextButton", top)
mini.Size = UDim2.new(0,24,0,22)
mini.Position = UDim2.new(1,-56,0,4)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80,80,80)
mini.TextColor3 = Color3.new(1,1,1)

local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,24,0,22)
close.Position = UDim2.new(1,-28,0,4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(150,60,60)
close.TextColor3 = Color3.new(1,1,1)

-- 最小化图标
local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)
icon.TextColor3 = Color3.new(1,1,1)

mini.MouseButton1Click:Connect(function()
	icon.Position = frame.Position
	frame.Visible = false
	icon.Visible = true
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
end)

-- 图标拖拽（鼠标 + 触屏）
do
	local dragging, sp, fp
	icon.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			sp = i.Position
			fp = icon.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
		or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - sp
			icon.Position = UDim2.new(fp.X.Scale, fp.X.Offset + d.X, fp.Y.Scale, fp.Y.Offset + d.Y)
		end
	end)
	icon.InputEnded:Connect(function() dragging = false end)
end

close.MouseButton1Click:Connect(function()
	Running = false
	gui:Destroy()
end)

--====================================================
-- Toggle 按钮
--====================================================
local function toggle(y, text, key)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-10,0,26)
	b.Position = UDim2.new(0,5,0,y)
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.TextColor3 = Color3.new(1,1,1)
	b.Text = text.."关"
	b.MouseButton1Click:Connect(function()
		S[key] = not S[key]
		b.Text = text .. (S[key] and "开" or "关")
	end)
end

toggle(40, "自动拾取箱子：", "boxPick")
toggle(70, "自动拾取果实：", "fruitPick")

--====================================================
-- 果实记录（稳定版）
--====================================================
local list = Instance.new("ScrollingFrame", frame)
list.Position = UDim2.new(0,5,0,110)
list.Size = UDim2.new(1,-10,1,-115)
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new()

local ll = Instance.new("UIListLayout", list)
ll.Padding = UDim.new(0,4)

local function addFruit(name)
	if type(name) ~= "string" then return end
	local t = os.time()
	local label = Instance.new("TextLabel", list)
	label.Size = UDim2.new(1,-4,0,20)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Left
	label.TextColor3 = Color3.fromRGB(255,200,60)
	label.Font = Enum.Font.SourceSansBold
	label.TextSize = 13
	label.Text = name .. " [" .. t .. "]"
	task.wait()
	list.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y)
end

--====================================================
-- 自动拾取（方案 A，延迟启动）
--====================================================
local function HRP()
	local c = P.Character
	if not c then return end
	return c:FindFirstChild("HumanoidRootPart")
end

local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit", c end
		if BOX[c.Name] then return "box", c end
		c = c.Parent
	end
end

task.delay(1, function()
	task.spawn(function()
		while Running do
			task.wait(SCAN)
			if busy then continue end
			local hrp = HRP()
			if not hrp then continue end

			local best, dist = nil, math.huge
			local now = os.clock()

			for _,pp in ipairs(workspace:GetDescendants()) do
				if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end
				if bad[pp] and bad[pp] > now then continue end

				local kind, model = getType(pp)
				if kind=="box" and not S.boxPick then continue end
				if kind=="fruit" and not S.fruitPick then continue end
				if not kind then continue end

				local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
				if part:IsA("BasePart") then
					local d = (hrp.Position - part.Position).Magnitude
					if d < dist and d <= MAX_DIST then
						best, dist = pp, d
					end
				end
			end

			if best then
				busy = true
				local part = best.Parent:IsA("Attachment") and best.Parent.Parent or best.Parent
				hrp.CFrame = part.CFrame * CFrame.new(0,0,2)
				task.wait(0.15)
				pcall(function()
					if fireproximityprompt then fireproximityprompt(best) end
				end)
				task.wait(0.25)
				bad[best] = os.clock() + FAIL_CD
				busy = false
			end
		end
	end)
end)

--====================================================
-- 果实生成监听（修复 Label 问题）
--====================================================
workspace.DescendantAdded:Connect(function(o)
	if not Running then return end
	if not o:IsA("ProximityPrompt") then return end
	task.delay(0.2, function()
		local kind, model = getType(o)
		if kind=="fruit" and model and model.Name then
			addFruit(model.Name)
		end
	end)
end)

warn("✅ PlayerGui 终极稳定整合版 已加载")
