--====================================================
-- Services
--====================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer

--====================================================
-- Config
--====================================================
local SCAN_INTERVAL = 0.4
local MAX_DIST = 3000

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
	Barrel = true,
}

--====================================================
-- State
--====================================================
local Running = true
local AutoBox = false
local AutoFruit = false
local Busy = false

--====================================================
-- Character
--====================================================
local function HRP()
	return (player.Character or player.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

--====================================================
-- GUI (PlayerGui)
--====================================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoPickStable"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0,240,0,340)
main.Position = UDim2.new(0,40,0,120)
main.BackgroundColor3 = Color3.fromRGB(35,35,35)
main.BorderSizePixel = 0

-- Title
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Auto Pick Stable"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(25,25,25)

-- Close
local close = Instance.new("TextButton", title)
close.Size = UDim2.new(0,30,1,0)
close.Position = UDim2.new(1,-30,0,0)
close.Text = "X"

close.MouseButton1Click:Connect(function()
	Running = false
	gui:Destroy()
end)

--====================================================
-- Toggle Buttons
--====================================================
local function makeToggle(y, text, callback)
	local b = Instance.new("TextButton", main)
	b.Size = UDim2.new(1,-20,0,28)
	b.Position = UDim2.new(0,10,0,y)
	b.BackgroundColor3 = Color3.fromRGB(60,60,60)
	b.Text = text .. "：关"

	local on = false
	b.MouseButton1Click:Connect(function()
		on = not on
		b.Text = text .. (on and "：开" or "：关")
		callback(on)
	end)
end

makeToggle(40, "自动拾取箱子", function(v) AutoBox = v end)
makeToggle(75, "自动拾取果实", function(v) AutoFruit = v end)

--====================================================
-- 坐标传送面板
--====================================================
local tpBtn = Instance.new("TextButton", main)
tpBtn.Size = UDim2.new(1,-20,0,28)
tpBtn.Position = UDim2.new(0,10,0,115)
tpBtn.Text = "坐标传送面板"

local tp = Instance.new("Frame", gui)
tp.Size = UDim2.new(0,200,0,260)
tp.BackgroundColor3 = Color3.fromRGB(30,30,30)
tp.Visible = false

local tpList = Instance.new("UIListLayout", tp)
tpList.Padding = UDim.new(0,4)

local save = Instance.new("TextButton", tp)
save.Size = UDim2.new(1,0,0,28)
save.Text = "保存当前位置"

tpBtn.MouseButton1Click:Connect(function()
	tp.Visible = not tp.Visible
	tp.Position = UDim2.new(
		0, main.AbsolutePosition.X + main.AbsoluteSize.X + 10,
		0, main.AbsolutePosition.Y
	)
end)

save.MouseButton1Click:Connect(function()
	local cf = HRP().CFrame

	local row = Instance.new("Frame", tp)
	row.Size = UDim2.new(1,0,0,26)

	local go = Instance.new("TextButton", row)
	go.Size = UDim2.new(0.7,0,1,0)
	go.Text = "传送"
	go.MouseButton1Click:Connect(function()
		HRP().CFrame = cf
	end)

	local del = Instance.new("TextButton", row)
	del.Size = UDim2.new(0.3,0,1,0)
	del.Position = UDim2.new(0.7,0,0,0)
	del.Text = "删除"
	del.MouseButton1Click:Connect(function()
		row:Destroy()
	end)
end)

--====================================================
-- 果实生成记录
--====================================================
local record = Instance.new("ScrollingFrame", main)
record.Position = UDim2.new(0,10,0,155)
record.Size = UDim2.new(1,-20,1,-165)
record.ScrollBarThickness = 6

local rl = Instance.new("UIListLayout", record)
rl.Padding = UDim.new(0,4)

local function addFruit(name)
	local label = Instance.new("TextLabel", record)
	label.Size = UDim2.new(1,-4,0,20)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = name .. " | " .. os.time()

	record.CanvasSize = UDim2.new(0,0,0,rl.AbsoluteContentSize.Y)
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

task.spawn(function()
	while Running do
		task.wait(SCAN_INTERVAL)
		if Busy then continue end

		local hrp = HRP()
		local best, dist = nil, math.huge

		for _, pp in ipairs(workspace:GetDescendants()) do
			if not pp:IsA("ProximityPrompt") or not pp.Enabled then continue end
			local kind, model = getType(pp)
			if kind == "box" and not AutoBox then continue end
			if kind == "fruit" and not AutoFruit then continue end
			if not kind then continue end

			local part = model:FindFirstChildWhichIsA("BasePart")
			if part then
				local d = (hrp.Position - part.Position).Magnitude
				if d < dist and d <= MAX_DIST then
					best, dist = pp, d
				end
			end
		end

		if best then
			Busy = true
			local model = best.Parent
			local part = model:FindFirstChildWhichIsA("BasePart")
			if part then
				hrp.CFrame = part.CFrame * CFrame.new(0,0,2)
				task.wait(0.15)
				if fireproximityprompt then
					fireproximityprompt(best)
				end
			end
			task.wait(0.3)
			Busy = false
		end
	end
end)

--====================================================
-- 果实生成监听
--====================================================
workspace.DescendantAdded:Connect(function(o)
	if o:IsA("ProximityPrompt") then
		task.wait(0.1)
		local kind, model = getType(o)
		if kind == "fruit" then
			addFruit(model.Name)
		end
	end
end)

warn("✅ PlayerGui 稳定整合版 已加载")
