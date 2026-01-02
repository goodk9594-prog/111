--====================================================
-- Old A Bizarre Day - Stable Script
-- PC & Mobile Compatible
--====================================================

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

--====================================================
-- Config
--====================================================
local KILL_RANGE = 25
local KillAura = false
local AutoPick = false

-- 物品白名单
local PICK_WHITELIST = {
	["Requiem Arrow"] = true,
	["Vampire Mask"] = true,
	["Shadow Camera"] = true,
	["Holy Corpse"] = true,
	["Nostalgic Relic"] = true,
	["Monochromatic Sphere"] = true,
	["Ender Pearl"] = true,
	["Galaxy Portal"] = true,
}

--====================================================
-- Character Utils
--====================================================
local function Char()
	return LP.Character or LP.CharacterAdded:Wait()
end

local function HRP()
	return Char():WaitForChild("HumanoidRootPart")
end

--====================================================
-- GUI Cleanup
--====================================================
pcall(function()
	CoreGui.OABD_GUI:Destroy()
end)

--====================================================
-- GUI Base
--====================================================
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "OABD_GUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 240, 0, 260)
frame.Position = UDim2.new(0, 30, 0, 120)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0

--====================================================
-- Top Bar (Drag)
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(20,20,20)

local dragging, dragStart, startPos

top.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = frame.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
	or i.UserInputType == Enum.UserInputType.Touch) then
		local delta = i.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UIS.InputEnded:Connect(function()
	dragging = false
end)

--====================================================
-- Minimize & Close
--====================================================
local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,24,0,20)
close.Position = UDim2.new(1,-28,0,5)
close.Text = "X"
close.BackgroundColor3 = Color3.fromRGB(140,60,60)

local mini = Instance.new("TextButton", top)
mini.Size = UDim2.new(0,24,0,20)
mini.Position = UDim2.new(1,-56,0,5)
mini.Text = "-"
mini.BackgroundColor3 = Color3.fromRGB(80,80,80)

local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Text = "⚔️"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)

mini.MouseButton1Click:Connect(function()
	frame.Visible = false
	icon.Visible = true
	icon.Position = frame.Position
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
end)

close.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

-- icon drag
icon.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = i.Position
		startPos = icon.Position
	end
end)

UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
	or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart
		icon.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + d.X,
			startPos.Y.Scale,
			startPos.Y.Offset + d.Y
		)
	end
end)

--====================================================
-- Buttons
--====================================================
local function Button(y, text, callback)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1,-10,0,28)
	b.Position = UDim2.new(0,5,0,y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(50,50,50)
	b.MouseButton1Click:Connect(callback)
	return b
end

local auraBtn = Button(40, "Kill Aura：关", function()
	KillAura = not KillAura
	auraBtn.Text = "Kill Aura："..(KillAura and "开" or "关")
end)

local pickBtn = Button(75, "自动拾取：关", function()
	AutoPick = not AutoPick
	pickBtn.Text = "自动拾取："..(AutoPick and "开" or "关")
end)

--====================================================
-- Kill Aura Range Slider
--====================================================
local sliderFrame = Instance.new("Frame", frame)
sliderFrame.Size = UDim2.new(1,-10,0,40)
sliderFrame.Position = UDim2.new(0,5,0,115)
sliderFrame.BackgroundColor3 = Color3.fromRGB(45,45,45)

local sliderText = Instance.new("TextLabel", sliderFrame)
sliderText.Size = UDim2.new(1,0,0,18)
sliderText.BackgroundTransparency = 1
sliderText.TextColor3 = Color3.new(1,1,1)
sliderText.Text = "范围："..KILL_RANGE

local bar = Instance.new("Frame", sliderFrame)
bar.Position = UDim2.new(0,5,0,24)
bar.Size = UDim2.new(1,-10,0,8)
bar.BackgroundColor3 = Color3.fromRGB(70,70,70)

local fill = Instance.new("Frame", bar)
fill.BackgroundColor3 = Color3.fromRGB(120,120,255)
fill.Size = UDim2.new(KILL_RANGE/100,0,1,0)

local draggingSlider = false
local MIN, MAX = 5, 100

local function updateSlider(x)
	local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
	KILL_RANGE = math.floor(MIN + (MAX - MIN) * p)
	fill.Size = UDim2.new(p,0,1,0)
	sliderText.Text = "范围："..KILL_RANGE
end

bar.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1
	or i.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
		updateSlider(i.Position.X)
	end
end)

UIS.InputChanged:Connect(function(i)
	if draggingSlider and (i.UserInputType == Enum.UserInputType.MouseMovement
	or i.UserInputType == Enum.UserInputType.Touch) then
		updateSlider(i.Position.X)
	end
end)

UIS.InputEnded:Connect(function()
	draggingSlider = false
end)

--====================================================
-- Kill Aura Logic
--====================================================
RunService.Heartbeat:Connect(function()
	if not KillAura then return end
	if not Char():FindFirstChild("HumanoidRootPart") then return end

	for _,m in ipairs(workspace:GetChildren()) do
		local hum = m:FindFirstChildOfClass("Humanoid")
		local hrp = m:FindFirstChild("HumanoidRootPart")
		if hum and hrp and m ~= Char() and hum.Health > 0 then
			if (HRP().Position - hrp.Position).Magnitude <= KILL_RANGE then
				hum.Health = 0
			end
		end
	end
  end
