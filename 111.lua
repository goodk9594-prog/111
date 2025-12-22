-- Services
local Players,CoreGui,UIS = game:GetService("Players"),game:GetService("CoreGui"),game:GetService("UserInputService")
local P = Players.LocalPlayer

-- Config
local MAX_DIST, FAIL_CD, SCAN = 3000, 6, 0.4
local FRUIT = {
	["Hie Hie Devil Fruit"]=1,["Bomu Bomu Devil Fruit"]=1,
	["Mochi Mochi Devil Fruit"]=1,["Nikyu Nikyu Devil Fruit"]=1,
	["Bari Bari Devil Fruit"]=1,
}

-- State
local S = {pick=false, fruit=false, tip=false}
local busy, bad = false, {}

-- GUI
pcall(function() CoreGui.AutoPickGui:Destroy() end)
local gui = Instance.new("ScreenGui", CoreGui); gui.Name="AutoPickGui"
local frame = Instance.new("Frame", gui)
frame.Size=UDim2.new(0,190,0,260)
frame.Position=UDim2.new(0,20,0,120)
frame.BackgroundColor3=Color3.fromRGB(35,35,35)
frame.BorderSizePixel=0

local function toggle(y,t,k)
	local b=Instance.new("TextButton",frame)
	b.Size=UDim2.new(1,-10,0,26)
	b.Position=UDim2.new(0,5,0,y)
	b.BackgroundColor3=Color3.fromRGB(60,60,60)
	b.TextColor3=Color3.new(1,1,1)
	b.BorderSizePixel=0
	b.Text=t.."关"
	b.MouseButton1Click:Connect(function()
		S[k]=not S[k]
		b.Text=t..(S[k] and "开" or "关")
	end)
end

toggle(10,"自动拾取：","pick")
toggle(40,"拾取果实：","fruit")
toggle(70,"果实提示：","tip")

-- ===== 果实记录框 =====
local list = Instance.new("ScrollingFrame", frame)
list.Position=UDim2.new(0,5,0,110)
list.Size=UDim2.new(1,-10,1,-115)
list.CanvasSize=UDim2.new(0,0,0,0)
list.ScrollBarThickness=6
list.BackgroundColor3=Color3.fromRGB(28,28,28)
list.BorderSizePixel=0

local layout=Instance.new("UIListLayout",list)
layout.Padding=UDim.new(0,4)

local function timeStr()
	local t=os.date("*t")
	return string.format("%02d:%02d:%02d",t.hour,t.min,t.sec)
end

local function addFruit(name)
	local l=Instance.new("TextLabel",list)
	l.Size=UDim2.new(1,-4,0,20)
	l.BackgroundTransparency=1
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.Font=Enum.Font.SourceSansBold
	l.TextSize=13
	l.TextColor3=Color3.fromRGB(255,200,60)
	l.Text=string.format("%s  [%s]",name,timeStr())
	task.wait()
	list.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y)
end

-- Minimize
local mini=Instance.new("TextButton",frame)
mini.Size=UDim2.new(0,22,0,22)
mini.Position=UDim2.new(1,-26,0,4)
mini.Text="—"
mini.BackgroundColor3=Color3.fromRGB(80,80,80)
mini.TextColor3=Color3.new(1,1,1)
mini.BorderSizePixel=0

local icon=Instance.new("TextButton",gui)
icon.Size=UDim2.new(0,44,0,44)
icon.Position=UDim2.new(0,20,0,120)
icon.Text="🍎"
icon.Visible=false
icon.BackgroundColor3=Color3.fromRGB(60,60,60)
icon.TextColor3=Color3.new(1,1,1)
icon.BorderSizePixel=0
Instance.new("UICorner",icon).CornerRadius=UDim.new(1,0)

mini.MouseButton1Click:Connect(function() frame.Visible=false; icon.Visible=true end)
icon.MouseButton1Click:Connect(function() if drag then return end frame.Visible=true; icon.Visible=false end)

-- 📱 Touch drag only
local drag,startPos,startTouch=false
icon.InputBegan:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.Touch then
		drag=true; startPos=icon.Position; startTouch=i.Position
	end
end)
icon.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
UIS.InputChanged:Connect(function(i)
	if drag and i.UserInputType==Enum.UserInputType.Touch then
		local d=i.Position-startTouch
		icon.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
end)

-- Utils
local function HRP()
	return (P.Character or P.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
end

local function getFruit(pp)
	local c=pp.Parent
	while c do if FRUIT[c.Name] then return c end c=c.Parent end
end

-- Fruit highlight
local function mark(m)
	local p=m:FindFirstChildWhichIsA("BasePart",true)
	if not p or p:FindFirstChild("FruitTag") then return end
	local g=Instance.new("BillboardGui",p)
	g.Name="FruitTag"
	g.Size=UDim2.new(0,200,0,36)
	g.StudsOffset=Vector3.new(0,3,0)
	g.AlwaysOnTop=true
	local t=Instance.new("TextLabel",g)
	t.Size=UDim2.fromScale(1,1)
	t.BackgroundTransparency=1
	t.Text=m.Name
	t.TextScaled=true
	t.Font=Enum.Font.SourceSansBold
	t.TextStrokeTransparency=0.2
	t.TextColor3=Color3.fromRGB(255,200,60)
	m.AncestryChanged:Connect(function(_,p) if not p then g:Destroy() end end)
end

-- Auto pick
local function bestPrompt()
	local hrp,best,dist,now=HRP(),nil,math.huge,os.clock()
	for _,pp in ipairs(workspace:GetDescendants()) do
		if pp:IsA("ProximityPrompt") and pp.Enabled and not(bad[pp] and bad[pp]>now) then
			local m=getFruit(pp); if m and not S.fruit then continue end
			local part=pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
			if part:IsA("BasePart") then
				local d=(hrp.Position-part.Position).Magnitude
				if d<=MAX_DIST and d<dist then best,dist=pp,d end
			end
		end
	end
	return best
end

local function pick(pp)
	busy=true
	local part=pp.Parent:IsA("Attachment") and pp.Parent.Parent or pp.Parent
	HRP().CFrame=part.CFrame*CFrame.new(0,0,2)
	task.wait(0.15)
	if fireproximityprompt then fireproximityprompt(pp) end
	task.wait(0.25)
	if pp.Parent then bad[pp]=os.clock()+FAIL_CD end
	busy=false
end

task.spawn(function()
	while task.wait(SCAN) do
		if S.pick and not busy then
			local pp=bestPrompt()
			if pp then pick(pp) end
		end
	end
end)

-- Only fruit spawn detect
workspace.DescendantAdded:Connect(function(o)
	if S.tip and o:IsA("ProximityPrompt") then
		task.wait(0.1)
		local m=getFruit(o)
		if m then
			mark(m)
			addFruit(m.Name)
		end
	end
end)

warn("✅ 果实生成记录已添加时间")
