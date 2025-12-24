--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local P = Players.LocalPlayer

--====================================================
-- Anti AFK（稳定）
--====================================================
P.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new(0,0))
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

local BOX = {
	Box=true,
	Chest=true,
	Barrel=true
}

--====================================================
-- State
--====================================================
local S = {boxPick=false, fruitPick=false}
local busy = false
local bad = {}
local Running = true

--====================================================
-- GUI（PlayerGui 稳定版）
--====================================================
pcall(function()
	if P.PlayerGui:FindFirstChild("AutoPickGui") then
		P.PlayerGui.AutoPickGui:Destroy()
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "AutoPickGui"
gui.ResetOnSpawn = false
gui.Parent = P:WaitForChild("PlayerGui")

--====================================================
-- 主窗口
--====================================================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,320)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0
frame.Visible = true

--====================================================
-- 顶栏（拖拽）
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

do
	local dragging, sp, fp
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			sp = i.Position
			fp = frame.Position
		end
	end)

	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - sp
			frame.Position = UDim2.new(fp.X.Scale, fp.X.Offset + d.X, fp.Y.Scale, fp.Y.Offset + d.Y)
		end
	end)

	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
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
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)

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
-- Toggle 按钮
--====================================================
local function toggle(y,text,key)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-10,0,26)
	b.Position = UDim2.new(0,5,0,y)
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.Text = text.."关"

	b.MouseButton1Click:Connect(function()
		S[key] = not S[key]
		b.Text = text .. (S[key] and "开" or "关")
	end)
end

toggle(40,"自动拾取箱子：","boxPick")
toggle(70,"自动拾取果实：","fruitPick")

--====================================================
-- 果实记录（修复版）
--====================================================
local list = Instance.new("ScrollingFrame", frame)
list.Position = UDim2.new(0,5,0,110)
list.Size = UDim2.new(1,-10,1,-115)
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new(0,0,0,0)

local ll = Instance.new("UIListLayout", list)
ll.Padding = UDim.new(0,4)

local function addFruit(name)
	if not name or name == "" then return end
	local t = os.time()

	local l = Instance.new("TextLabel", list)
	l.Size = UDim2.new(1,-6,0,20)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = false
	l.Text = name.." ["..t.."]"

	task.wait()
	list.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y + 4)
end

--====================================================
-- 工具
--====================================================
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

--====================================================
-- 自动拾取（方案 A）
--====================================================
local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then return "fruit", c end
		if BOX[c.Name] then return "box", c end
		c = c.Parent
	end
end

local function bestPrompt()
	local hrp = HRP()
	local best, dist = nil, math.huge
	local now = os.clock()

	for _,pp in ipairs(workspace:GetDescendants()) do
		if not Running then return end
		if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end
		if bad[pp] and bad[pp] > now then continue end

		local kind, model = getType(pp)
		if not kind then continue end
		if kind == "box" and not S.boxPick then continue end
		if kind == "fruit" and not S.fruitPick then continue end

		local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
		if part:IsA("BasePart") then
			local d = (hrp.Position - part.Position).Magnitude
			if d < dist and d <= MAX_DIST then
				best, dist = pp, d
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
			HRP().CFrame = part.CFrame * CFrame.new(0,0,2)

			task.wait(0.15)
			if fireproximityprompt then
				fireproximityprompt(pp)
			end

			task.wait(0.25)
			bad[pp] = os.clock() + FAIL_CD
			busy = false
		end
	end
end)

--====================================================
-- 果实生成监听（稳定）
--====================================================
workspace.DescendantAdded:Connect(function(o)
	if not Running then return end
	if not o:IsA("ProximityPrompt") then return end

	task.wait(0.1)
	local kind, model = getType(o)
	if kind == "fruit" and model and model.Name then
		addFruit(model.Name)
	end
end)

warn("✅ PlayerGui 稳定终极整合版 已加载")
