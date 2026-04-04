--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

--// 设置
local skills = {"E","R","T","Y","G"}
local followDistance = 6
local detectRange = 80
local detectDelay = 0.4

--// 状态
local autoFight = false
local autoSkill = false
local running = true
local currentTarget = nil
local lockedPosition = nil  -- 新增：锁定角色位置

--// GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0,220,0,170)
frame.Position = UDim2.new(0.5,-110,0.5,-85)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1,0,0,30)
title.Text = "Auto Boss Fight"
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
fightButton.Size = UDim2.new(0.8,0,0,40)
fightButton.Position = UDim2.new(0.1,0,0.3,0)
fightButton.Text = "Auto Fight: OFF"
fightButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
fightButton.TextColor3 = Color3.new(1,1,1)

-- Auto Skill
local skillButton = Instance.new("TextButton")
skillButton.Parent = frame
skillButton.Size = UDim2.new(0.8,0,0,40)
skillButton.Position = UDim2.new(0.1,0,0.6,0)
skillButton.Text = "Auto Skill: OFF"
skillButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
skillButton.TextColor3 = Color3.new(1,1,1)

--// 找敌人（保持不变）
local function getClosestEnemy()
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local parts = workspace:GetPartBoundsInRadius(hrp.Position, detectRange)

    local closest = nil
    local shortest = detectRange

    for _, part in pairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model \~= char then
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
end

-- 按钮
fightButton.MouseButton1Click:Connect(function()
    autoFight = not autoFight
    fightButton.Text = autoFight and "Auto Fight: ON" or "Auto Fight: OFF"
end)

skillButton.MouseButton1Click:Connect(function()
    autoSkill = not autoSkill
    skillButton.Text = autoSkill and "Auto Skill: ON" or "Auto Skill: OFF"
end)

-- 关闭脚本
closeButton.MouseButton1Click:Connect(function()
    running = false
    gui:Destroy()
end)

-- 检测Boss（修改：仅在新目标时重置锁定位置）
task.spawn(function()
    while running do
        task.wait(detectDelay)

        if autoFight then
            local newTarget = getClosestEnemy()
            if newTarget \~= currentTarget then
                currentTarget = newTarget
                lockedPosition = nil  -- 新 Boss 时重置锁定位置
            end
        else
            currentTarget = nil
            lockedPosition = nil
        end
    end
end)

-- 锁定Boss并追踪（核心修改：位置锁定 + 始终面向）
RunService.RenderStepped:Connect(function()
    if not running then return end
    if not autoFight then return end
    if not currentTarget then return end

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetHRP = currentTarget:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    -- 如果还未锁定位置，第一次计算 Boss 旁边的固定坐标
    if lockedPosition == nil then
        local direction = (hrp.Position - targetHRP.Position).Unit
        if direction.Magnitude < 0.01 then
            direction = Vector3.new(0, 0, 1)  -- 防止零向量
        end
        lockedPosition = targetHRP.Position + direction * followDistance
    end

    -- 锁定位置 + 始终面向 Boss（位置不再变化）
    hrp.CFrame = CFrame.lookAt(lockedPosition, targetHRP.Position)
end)

-- 自动技能（保持不变）
task.spawn(function()
    while running do
        task.wait(0.5)

        if autoSkill then
            for _, key in pairs(skills) do
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end
    end
end)
