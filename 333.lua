--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local P = Players.LocalPlayer
local PlayerGui = P:WaitForChild("PlayerGui")

--====================================================
-- Anti AFK（稳定）
--====================================================
P.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

--====================================================
-- Config
--====================================================
local MAX_DIST, FAIL_CD, SCAN = 3000, 6, 0.4

local FRUIT = {
	["Hie Hie Devil Fruit"] = true,
	["Bomu Bomu Devil Fruit"] = true,
	["Mochi Mochi Devil Fruit"] = true,
	["Nikyu Nikyu Devil Fruit"] = true,
	["Bari Bari Devil Fruit"] = true,
}

local BOX = {
	Box = true,
	Chest = true,
	Barrel = true
}

--====================================================
-- State
--====================================================
local S = { boxPick = false, fruitPick = false }
local busy = false
local bad = {}
local Running = true

--====================================================
-- GUI 创建（PlayerGui 稳定）
--====================================================
pcall(function()
	local old = PlayerGui:FindFirstChild("AutoPickGui")
	if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AutoPickGui"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

--====================================================
-- 主窗口
--====================================================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 320)
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0

--====================================================
-- 顶栏（拖拽：PC + 手机）
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1, 0, 0, 30)
top.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

do
	local dragging, startPos, startFrame
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1
		or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = i.Position
			startFrame = frame.Position
		end
	end)

	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
		or i.UserInputType == Enum.UserInputType.Touch) then
			local delta = i.Position - startPos
			frame.Position = UDim2.new(
				startFrame.X.Scale, startFrame.X.Offset + delta.X,
				startFrame.Y.Scale, startFrame.Y.Offset + delta.Y
			)
		end
	end)

	UIS.InputEnded:Connect(function()
		dragging = false
	end)
end

--====================================================
-- 最小化 / 关闭
--====================================================
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0, 26, 0, 22)
close.Position = UDim2.new(1, -30, 0, 4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(150, 60, 60)

local mini = Instance.new("TextButton", top)
mini.Size = UDim2.new(0, 26, 0, 22)
mini.Position = UDim2.new(1, -60, 0, 4)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0, 44, 0, 44)
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

mini.MouseButton1Click:Connect(function()
	icon.Position = frame.Position
	frame.Visible = false
	icon.Visible = true
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
end)

close.MouseButton1Click:Connect(function()
	Running = false
	gui:Destroy()
end)

--====================================================
-- Toggle
--====================================================
local function toggle(y, text, key)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1, -10, 0, 26)
	b.Position = UDim2.new(0, 5, 0, y)
	b.Text = text .. "关"
	b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

	b.MouseButton1Click:Connect(function()
		S[key] = not S[key]
		b.Text = text .. (S[key] and "开" or "关")
	end)
end

toggle(40, "自动拾取箱子：", "boxPick")
toggle(70, "自动拾取果实：", "fruitPick")

--====================================================
-- 工具
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

--====================================================
-- 果实记录
--====================================================
local list = Instance.new("ScrollingFrame", frame)
list.Position = UDim2.new(0, 5, 0, 110)
list.Size = UDim2.new(1, -10, 1, -115)
list.ScrollBarThickness = 6

local ll = Instance.new("UIListLayout", list)
ll.Padding = UDim.new(0, 4)

local function addFruit(name)
	if not name or name == "" then return end
	local label = Instance.new("TextLabel", list)
	label.Size = UDim2.new(1, -4, 0, 20)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = string.format("%s [%s]", name, os.date("%H:%M:%S"))
	list.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 24)
end

--====================================================
-- 类型识别
--====================================================
local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit", c end
		if BOX[c.Name] then return "box", c end
		c = c.Parent
	end
end

--====================================================
-- 自动拾取
--====================================================
local function bestPrompt()
	local hrp = HRP()
	local best, dist = nil, math.huge
	local now = os.clock()

	for _, pp in ipairs(workspace:GetDescendants()) do
		if not Running then break end
		if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end
		if bad[pp] and bad[pp] > now then continue end

		local kind = getType(pp)
		if kind == "box" and not S.boxPick then continue end
		if kind == "fruit" and not S.fruitPick then continue end
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

	return best
end

task.spawn(function()
	while Running do
		task.wait(SCAN)
		if busy then continue end

		local pp = bestPrompt()
		if pp then
			busy = true
			local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
			HRP().CFrame = part.CFrame * CFrame.new(0, 0, 2)
			task.wait(0.15)
			if fireproximityprompt then
				fireproximityprompt(pp)
			end
			bad[pp] = os.clock() + FAIL_CD
			busy = false
		end
	end
end)

--====================================================
-- 果实生成监听（稳定延迟）
--====================================================
workspace.DescendantAdded:Connect(function(o)
	if not Running then return end
	if o:IsA("ProximityPrompt") then
		task.delay(0.3, function()
			local kind, model = getType(o)
			if kind == "fruit" and model and FRUIT[model.Name] then
				addFruit(model.Name)
			end
		end)
	end
end)

warn("✅ PlayerGui 稳定终极整合版 已加载")
