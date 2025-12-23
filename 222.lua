--====================================================
-- Services
--====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local PPS = game:GetService("ProximityPromptService")
local P = Players.LocalPlayer

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

--====================================================
-- ================= 主 GUI =================
--====================================================
pcall(function() CoreGui.MainGui:Destroy() end)
local mainGui = Instance.new("ScreenGui", CoreGui)
mainGui.Name = "MainGui"

local main = Instance.new("Frame", mainGui)
main.Size = UDim2.new(0,220,0,240)
main.Position = UDim2.new(0,20,0,120)
main.BackgroundColor3 = Color3.fromRGB(35,35,35)
main.BorderSizePixel = 0

-- Close main → clear data
local closeMain = Instance.new("TextButton", main)
closeMain.Size = UDim2.new(0,22,0,22)
closeMain.Position = UDim2.new(1,-26,0,4)
closeMain.Text = "X"
closeMain.BackgroundColor3 = Color3.fromRGB(140,60,60)

--====================================================
-- 坐标数据（只在主 GUI 关闭时清空）
--====================================================
local TP_DATA = {}
local TP_ID = 0

--====================================================
-- 坐标子 GUI
--====================================================
local tpGui = Instance.new("ScreenGui", CoreGui)
tpGui.Name = "TPGui"
tpGui.Enabled = false

local tpFrame = Instance.new("Frame", tpGui)
tpFrame.Size = UDim2.new(0,260,0,300)
tpFrame.Position = UDim2.new(0.5,-130,0.5,-150)
tpFrame.BackgroundColor3 = Color3.fromRGB(35,35,35)

local tpTop = Instance.new("Frame", tpFrame)
tpTop.Size = UDim2.new(1,0,0,30)
tpTop.BackgroundColor3 = Color3.fromRGB(25,25,25)

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

local layout = Instance.new("UIListLayout", tpContent)
layout.Padding = UDim.new(0,5)

local saveBtn = Instance.new("TextButton", tpContent)
saveBtn.Size = UDim2.new(1,0,0,32)
saveBtn.Text = "保存当前坐标"
saveBtn.BackgroundColor3 = Color3.fromRGB(70,130,180)

--====================================================
-- Drag
--====================================================
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
drag(tpTop, tpFrame)

--====================================================
-- 坐标保存 & 传送
--====================================================
local function refreshTP()
	for _,c in ipairs(tpContent:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	for i,v in ipairs(TP_DATA) do
		local row = Instance.new("Frame", tpContent)
		row.Size = UDim2.new(1,0,0,30)
		row.BackgroundTransparency = 1

		local tp = Instance.new("TextButton", row)
		tp.Size = UDim2.new(1,-34,1,0)
		tp.Text = v.name
		tp.BackgroundColor3 = Color3.fromRGB(60,60,60)

		local del = Instance.new("TextButton", row)
		del.Size = UDim2.new(0,30,1,0)
		del.Position = UDim2.new(1,-30,0,0)
		del.Text = "X"
		del.BackgroundColor3 = Color3.fromRGB(170,60,60)

		tp.MouseButton1Click:Connect(function()
			HRP().CFrame = v.cf
		end)

		del.MouseButton1Click:Connect(function()
			table.remove(TP_DATA,i)
			refreshTP()
		end)
	end
end

saveBtn.MouseButton1Click:Connect(function()
	TP_ID += 1
	table.insert(TP_DATA,{
		name="坐标 "..TP_ID,
		cf=HRP().CFrame
	})
	refreshTP()
end)

tpClose.MouseButton1Click:Connect(function()
	tpGui.Enabled = false
end)

tpMin.MouseButton1Click:Connect(function()
	tpFrame.Visible = false
end)

--====================================================
-- 主 GUI 坐标按钮
--====================================================
local openTP = Instance.new("TextButton", main)
openTP.Size = UDim2.new(1,-10,0,30)
openTP.Position = UDim2.new(0,5,0,40)
openTP.Text = "坐标传送面板"
openTP.BackgroundColor3 = Color3.fromRGB(70,130,180)

openTP.MouseButton1Click:Connect(function()
	tpGui.Enabled = true
	tpFrame.Visible = true
end)

--====================================================
-- 主 GUI 关闭 → 清空数据
--====================================================
closeMain.MouseButton1Click:Connect(function()
	TP_DATA = {}
	tpGui:Destroy()
	mainGui:Destroy()
end)

warn("✅ 最终增强整合版已加载（Anti-AFK + 子TP GUI）")
