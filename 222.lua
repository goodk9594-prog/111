--====================================================
-- Services & Player
--====================================================
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local P = Players.LocalPlayer

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
local BOX = {Box=true,Chest=true,Barrel=true}

--====================================================
-- State
--====================================================
local S = {boxPick=false, fruitPick=false}
local busy, bad = false, {}
local Running = true

--====================================================
-- GUI 清理
--====================================================
pcall(function() CoreGui.AutoPickGui:Destroy() end)

local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "AutoPickGui"

--====================================================
-- 主 GUI
--====================================================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,300)
frame.Position = UDim2.new(0,20,0,120)
frame.BackgroundColor3 = Color3.fromRGB(35,35,35)
frame.BorderSizePixel = 0

--====================================================
-- 顶栏
--====================================================
local top = Instance.new("Frame", frame)
top.Size = UDim2.new(1,0,0,30)
top.BackgroundColor3 = Color3.fromRGB(25,25,25)

--====================================================
-- 主 GUI 拖动
--====================================================
do
	local dragging, sp, fp
	top.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true
			sp=i.Position
			fp=frame.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
			local d=i.Position-sp
			frame.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
		end
	end)
	top.InputEnded:Connect(function()
		dragging=false
	end)
end

--====================================================
-- 关闭 / 最小化
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

--====================================================
-- 最小化图标（支持手机拖拽）
--====================================================
local icon = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0,44,0,44)
icon.Position = frame.Position
icon.Text = "🍎"
icon.Visible = false
icon.BackgroundColor3 = Color3.fromRGB(60,60,60)
icon.BorderSizePixel = 0

local iconDragging, iconStartPos, iconStartTouch

icon.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		iconDragging = true
		iconStartPos = icon.Position
		iconStartTouch = i.Position
	end
end)

icon.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then
		iconDragging = false
	end
end)

UIS.InputChanged:Connect(function(i)
	if iconDragging and i.UserInputType == Enum.UserInputType.Touch then
		local d = i.Position - iconStartTouch
		icon.Position = UDim2.new(
			iconStartPos.X.Scale, iconStartPos.X.Offset + d.X,
			iconStartPos.Y.Scale, iconStartPos.Y.Offset + d.Y
		)
	end
end)

--====================================================
-- 坐标传送 GUI（右侧）
--====================================================
local tp = Instance.new("Frame", gui)
tp.Size = UDim2.new(0,200,0,240)
tp.Position = UDim2.new(0,260,0,120)
tp.BackgroundColor3 = Color3.fromRGB(30,30,30)
tp.Visible = false

--====================================================
-- 最小化 / 还原逻辑（关键修复）
--====================================================
mini.MouseButton1Click:Connect(function()
	frame.Visible = false
	tp.Visible = false   -- ✅ 一起最小化
	icon.Visible = true
	icon.Position = frame.Position
end)

icon.MouseButton1Click:Connect(function()
	frame.Visible = true
	icon.Visible = false
	-- tp 是否显示由按钮控制，不强制打开
end)

close.MouseButton1Click:Connect(function()
	Running = false
	gui:Destroy()
end)

--====================================================
-- 自动拾取核心（完全保留方案 A，不再贴一遍）
--====================================================
-- ↓↓↓ 这里以下你继续使用你当前“完全能用”的那一整段 ↓↓↓
-- （bestPrompt / pick / 果实监听 / 果实记录 都不需要再改）

warn("✅ 最终稳定版：最小化联动 + 图标可拖拽（手机）")
