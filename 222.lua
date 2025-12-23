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
-- Anti AFK
--====================================================
P.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

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
-- ScreenGui
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
-- 关闭按钮
--====================================================
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,28,0,22)
close.Position = UDim2.new(1,-32,0,4)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(150,60,60)
close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

--====================================================
-- 状态
--====================================================
local State = {box=false, fruit=false}
local saveId = 0

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
-- 坐标传送面板
--====================================================
local openTP = Instance.new("TextButton", frame)
openTP.Size = UDim2.new(1,-10,0,28)
openTP.Position = UDim2.new(0,5,0,105)
openTP.Text = "坐标传送面板"
openTP.BackgroundColor3 = Color3.fromRGB(70,130,180)

local tp = Instance.new("Frame", frame)
tp.Size = UDim2.new(1,-10,0,180)
tp.Position = UDim2.new(0,5,0,140)
tp.BackgroundColor3 = Color3.fromRGB(30,30,30)
tp.Visible = false

local save = Instance.new("TextButton", tp)
save.Size = UDim2.new(1,0,0,28)
save.Text = "保存当前位置"
save.BackgroundColor3 = Color3.fromRGB(80,140,200)

local tpLayout = Instance.new("UIListLayout", tp)
tpLayout.Padding = UDim.new(0,4)

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

--====================================================
-- 自动拾取配置
--====================================================
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
	Barrel=true,
}

--====================================================
-- Prompt 缓存
--====================================================
local PromptCache = {}

local function addPrompt(pp)
	if pp:IsA("ProximityPrompt") then
		PromptCache[pp] = true
	end
end

local function removePrompt(pp)
	PromptCache[pp] = nil
end

for _,obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("ProximityPrompt") then
		addPrompt(obj)
	end
end

workspace.DescendantAdded:Connect(addPrompt)
workspace.DescendantRemoving:Connect(removePrompt)

--====================================================
-- Prompt 类型判断（修复版）
--====================================================
local function getType(pp)
	local c = pp.Parent
	while c do
		if FRUIT[c.Name] then
			return "fruit", c
		end
		if BOX[c.Name] then
			return "box", c
		end
		if pp.ActionText then
			local t = string.lower(pp.ActionText)
			if t:find("pick") or t:find("fruit") then
				return "fruit", c
			end
			if t:find("open") then
				return "box", c
			end
		end
		c = c.Parent
	end
end

--====================================================
-- 自动拾取主循环（已修复）
--====================================================
local busy = false
local MAX_DIST = 3000
local SCAN = 0.35

task.spawn(function()
	while true do
		task.wait(busy and 0.1 or SCAN)
		if busy then continue end

		local hrp = HRP()
		local best, bestDist

		for pp,_ in pairs(PromptCache) do
			if not pp.Parent or not pp.Enabled then
				PromptCache[pp] = nil
				continue
			end

			local kind, model = getType(pp)
			if not kind then continue end
			if kind == "fruit" and not State.fruit then continue end
			if kind == "box" and not State.box then continue end

			local part =
				pp.Parent:IsA("Attachment") and pp.Parent.Parent
				or pp.Parent:IsA("BasePart") and pp.Parent
				or pp:FindFirstAncestorWhichIsA("BasePart")

			if part then
				local d = (hrp.Position - part.Position).Magnitude
				if d <= MAX_DIST and (not bestDist or d < bestDist) then
					best = {pp = pp, part = part}
					bestDist = d
				end
			end
		end

		if best then
			busy = true
			pcall(function()
				HRP().CFrame = best.part.CFrame * CFrame.new(0,0,2)
				task.wait(0.1)
				best.pp.HoldDuration = 0
				if fireproximityprompt then
					fireproximityprompt(best.pp, 0)
				end
			end)
			task.delay(0.35, function()
				busy = false
			end)
		end
	end
end)

warn("✅ 自动拾取 · 坐标 · GUI · 全部已稳定运行")
