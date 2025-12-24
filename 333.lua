--====================================================
-- Solara 稳定初始化（非常关键）
--====================================================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
if not player then return end

-- 等角色 & GUI 完全就绪（Solara 必须）
task.spawn(function()
	player.CharacterAdded:Wait()
	task.wait(1.5)

	local PlayerGui = player:WaitForChild("PlayerGui", 10)
	if not PlayerGui then return end

	--====================================================
	-- Anti AFK（Solara 安全）
	--====================================================
	player.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)

	--====================================================
	-- Config
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

	local State = {boxPick=false, fruitPick=false}
	local Running = true
	local busy, bad = false, {}

	--====================================================
	-- GUI（只用 PlayerGui，Solara 安全）
	--====================================================
	pcall(function()
		PlayerGui.AutoPickGui:Destroy()
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "AutoPickGui"
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui

	local frame = Instance.new("Frame", gui)
	frame.Size = UDim2.fromOffset(240,320)
	frame.Position = UDim2.fromOffset(40,120)
	frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true -- PC 最稳

	--====================================================
	-- 标题
	--====================================================
	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1,0,0,30)
	title.BackgroundColor3 = Color3.fromRGB(25,25,25)
	title.Text = "Auto Pick (Solara)"
	title.TextColor3 = Color3.new(1,1,1)
	title.BorderSizePixel = 0

	--====================================================
	-- 关闭
	--====================================================
	local close = Instance.new("TextButton", frame)
	close.Size = UDim2.fromOffset(26,22)
	close.Position = UDim2.new(1,-30,0,4)
	close.Text = "X"
	close.BackgroundColor3 = Color3.fromRGB(150,60,60)
	close.TextColor3 = Color3.new(1,1,1)

	close.MouseButton1Click:Connect(function()
		Running = false
		gui:Destroy()
	end)

	--====================================================
	-- Toggle
	--====================================================
	local function toggle(y,text,key)
		local b = Instance.new("TextButton", frame)
		b.Size = UDim2.new(1,-20,0,26)
		b.Position = UDim2.fromOffset(10,y)
		b.BackgroundColor3 = Color3.fromRGB(60,60,60)
		b.TextColor3 = Color3.new(1,1,1)
		b.BorderSizePixel = 0
		b.Text = text.."关"

		b.MouseButton1Click:Connect(function()
			State[key] = not State[key]
			b.Text = text..(State[key] and "开" or "关")
		end)
	end

	toggle(40,"自动拾取箱子：","boxPick")
	toggle(70,"自动拾取果实：","fruitPick")

	--====================================================
	-- 果实记录
	--====================================================
	local list = Instance.new("ScrollingFrame", frame)
	list.Position = UDim2.fromOffset(10,110)
	list.Size = UDim2.new(1,-20,1,-120)
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new()

	local layout = Instance.new("UIListLayout", list)
	layout.Padding = UDim.new(0,4)

	local function addFruit(name)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1,-4,0,22)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Left
		label.TextColor3 = Color3.fromRGB(255,200,60)
		label.TextSize = 14
		label.Text = name.." | "..os.date("%X", os.time())
		label.Parent = list

		task.wait()
		list.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
	end

	--====================================================
	-- 自动拾取（原方案 A）
	--====================================================
	local function HRP()
		return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	end

	local function getType(pp)
		local c = pp.Parent
		while c do
			if FRUIT[c.Name] then return "fruit",c end
			if BOX[c.Name] then return "box",c end
			c = c.Parent
		end
	end

	local function bestPrompt()
		local hrp = HRP()
		if not hrp then return end

		local best, dist = nil, math.huge
		local now = os.clock()

		for _,pp in ipairs(workspace:GetDescendants()) do
			if not Running then return end
			if not (pp:IsA("ProximityPrompt") and pp.Enabled) then continue end
			if bad[pp] and bad[pp] > now then continue end

			local kind = getType(pp)
			if kind=="box" and not State.boxPick then continue end
			if kind=="fruit" and not State.fruitPick then continue end
			if not kind then continue end

			local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
			if part:IsA("BasePart") then
				local d = (hrp.Position - part.Position).Magnitude
				if d < dist then
					best, dist = pp, d
				end
			end
		end
		return best
	end

	task.spawn(function()
		while Running do
			task.wait(SCAN)
			if not busy then
				local pp = bestPrompt()
				if pp then
					busy = true
					local part = pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
					if HRP() then
						HRP().CFrame = part.CFrame * CFrame.new(0,0,2)
						task.wait(0.15)
						pcall(function()
							fireproximityprompt(pp)
						end)
					end
					task.wait(0.25)
					if pp.Parent then bad[pp] = os.clock() + FAIL_CD end
					busy = false
				end
			end
		end
	end)

	workspace.DescendantAdded:Connect(function(o)
		if o:IsA("ProximityPrompt") then
			task.wait(0.1)
			local kind, model = getType(o)
			if kind=="fruit" then
				addFruit(model.Name)
			end
		end
	end)

	warn("✅ Solara · PlayerGui 稳定最终版 已加载")
end)
