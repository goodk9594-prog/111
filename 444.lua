--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

--// 设置
local skills = {"E","R","T","Y","G"}
local followDistance = 6
local detectRange = 80
local detectDelay = 0.8
local interactRange = 12

--// 状态
local autoFight = false
local autoSkill = false
local autoInteract = false
local running = true
local currentTarget = nil

--// GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0,230,0,210)
frame.Position = UDim2.new(0.5,-115,0.5,-105)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1,0,0,30)
title.Text = "Auto Boss Farm"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundTransparency = 1

-- 关闭按钮
local closeButton = Instance.new("TextButton")
closeButton.Parent = frame
closeButton.Size = UDim2.new(0,30,0,30)
closeButton.Position = UDim2.new(1,-30,0,0)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(170,0,0)
closeButton.TextColor3 = Color3.new(1,1,1)

-- Auto Fight
local fightButton = Instance.new("TextButton")
fightButton.Parent = frame
fightButton.Size = UDim2.new(0.8,0,0,35)
fightButton.Position = UDim2.new(0.1,0,0.25,0)
fightButton.Text = "Auto Fight: OFF"
fightButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
fightButton.TextColor3 = Color3.new(1,1,1)

-- Auto Skill
local skillButton = Instance.new("TextButton")
skillButton.Parent = frame
skillButton.Size = UDim2.new(0.8,0,0,35)
skillButton.Position = UDim2.new(0.1,0,0.45,0)
skillButton.Text = "Auto Skill: OFF"
skillButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
skillButton.TextColor3 = Color3.new(1,1,1)

-- Auto Interact
local interactButton = Instance.new("TextButton")
interactButton.Parent = frame
interactButton.Size = UDim2.new(0.8,0,0,35)
interactButton.Position = UDim2.new(0.1,0,0.65,0)
interactButton.Text = "Auto Interact: OFF"
interactButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
interactButton.TextColor3 = Color3.new(1,1,1)

--// 按钮
fightButton.MouseButton1Click:Connect(function()
autoFight = not autoFight
fightButton.Text = autoFight and "Auto Fight: ON" or "Auto Fight: OFF"
end)

skillButton.MouseButton1Click:Connect(function()
autoSkill = not autoSkill
skillButton.Text = autoSkill and "Auto Skill: ON" or "Auto Skill: OFF"
end)

interactButton.MouseButton1Click:Connect(function()
autoInteract = not autoInteract
interactButton.Text = autoInteract and "Auto Interact: ON" or "Auto Interact: OFF"
end)

closeButton.MouseButton1Click:Connect(function()
running = false
gui:Destroy()
end)

--// 找Boss
local function getClosestEnemy()

```
local char = player.Character
if not char then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end

local parts = workspace:GetPartBoundsInRadius(hrp.Position, detectRange)

local closest
local shortest = detectRange

for _,part in pairs(parts) do

    local model = part:FindFirstAncestorOfClass("Model")

    if model and model ~= char then

        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local enemyHRP = model:FindFirstChild("HumanoidRootPart")

        if humanoid and enemyHRP and humanoid.Health > 0 then

            local dist = (enemyHRP.Position - hrp.Position).Magnitude

            if dist < shortest then
                shortest = dist
                closest = model
            end

        end

    end

end

return closest
```

end

--// Boss检测
task.spawn(function()

```
while running do
    task.wait(detectDelay)

    if autoFight then
        currentTarget = getClosestEnemy()
    else
        currentTarget = nil
    end

end
```

end)

--// 锁Boss
RunService.RenderStepped:Connect(function()

```
if not running then return end
if not autoFight then return end
if not currentTarget then return end

local char = player.Character
if not char then return end

local humanoid = char:FindFirstChildOfClass("Humanoid")
local hrp = char:FindFirstChild("HumanoidRootPart")

if not humanoid or not hrp then return end

local targetHRP = currentTarget:FindFirstChild("HumanoidRootPart")
if not targetHRP then return end

humanoid.WalkSpeed = 0
humanoid.JumpPower = 0

local direction = (hrp.Position - targetHRP.Position).Unit
local lockPos = targetHRP.Position + direction * followDistance

hrp.CFrame = CFrame.new(lockPos, targetHRP.Position)
```

end)

--// 自动技能
task.spawn(function()

```
while running do
    task.wait(0.5)

    if autoSkill then

        for _,key in pairs(skills) do

            VirtualInputManager:SendKeyEvent(true,key,false,game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false,key,false,game)

        end

    end

end
```

end)

--// 自动E交互
task.spawn(function()

```
while running do
    task.wait(0.4)

    if autoInteract then

        local char = player.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        for _,v in pairs(workspace:GetDescendants()) do

            if v:IsA("ProximityPrompt") then

                local part = v.Parent

                if part and part:IsA("BasePart") then

                    local dist = (part.Position - hrp.Position).Magnitude

                    if dist <= interactRange then

                        v.HoldDuration = 0
                        fireproximityprompt(v)

                    end

                end

            end

        end

    end

end
```

end)
