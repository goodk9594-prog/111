--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

--// 设置
local skills = {"E","R","T","Y","G"}
local followDistance = 8
local detectRange = 100
local detectDelay = 0.3

--// 状态
local autoLock = false
local autoFollow = false
local autoSkill = false
local running = true
local currentTarget = nil
local alignPos = nil
local alignOri = nil

--// GUI - 优化布局
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 280, 0, 260)
frame.Position = UDim2.new(0.5, -140, 0.5, -130)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "锁定 + 自动跟随 Boss"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 20
title.Font = Enum.Font.SourceSansBold

-- 关闭按钮
local closeButton = Instance.new("TextButton")
closeButton.Parent = frame
closeButton.Size = UDim2.new(0, 35, 0, 35)
closeButton.Position = UDim2.new(1, -35, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 20

-- 三个开关按钮（垂直排列，加大间距）
local lockButton = Instance.new("TextButton")
lockButton.Parent = frame
lockButton.Size = UDim2.new(0.85, 0, 0, 45)
lockButton.Position = UDim2.new(0.075, 0, 0.22, 0)
lockButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
lockButton.Text = "位置锁定: OFF"
lockButton.TextColor3 = Color3.new(1, 1, 1)
lockButton.TextSize = 16

local followButton = Instance.new("TextButton")
followButton.Parent = frame
followButton.Size = UDim2.new(0.85, 0, 0, 45)
followButton.Position = UDim2.new(0.075, 0, 0.42, 0)
followButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
followButton.Text = "自动跟随Boss: OFF"
followButton.TextColor3 = Color3.new(1, 1, 1)
followButton.TextSize = 16

local skillButton = Instance.new("TextButton")
skillButton.Parent = frame
skillButton.Size = UDim2.new(0.85, 0, 0, 45)
skillButton.Position = UDim2.new(0.075, 0, 0.62, 0)
skillButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
skillButton.Text = "自动技能: OFF"
skillButton.TextColor3 = Color3.new(1, 1, 1)
skillButton.TextSize = 16

--// 找最近敌人
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

-- 按钮功能
lockButton.MouseButton1Click:Connect(function()
    autoLock = not autoLock
    lockButton.Text = autoLock and "位置锁定: ON" or "位置锁定: OFF"
    lockButton.BackgroundColor3 = autoLock and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

followButton.MouseButton1Click:Connect(function()
    autoFollow = not autoFollow
    followButton.Text = autoFollow and "自动跟随Boss: ON" or "自动跟随Boss: OFF"
    followButton.BackgroundColor3 = autoFollow and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

skillButton.MouseButton1Click:Connect(function()
    autoSkill = not autoSkill
    skillButton.Text = autoSkill and "自动技能: ON" or "自动技能: OFF"
    skillButton.BackgroundColor3 = autoSkill and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

closeButton.MouseButton1Click:Connect(function()
    running = false
    if alignPos then alignPos:Destroy() end
    if alignOri then alignOri:Destroy() end
    gui:Destroy()
end)

-- 检测Boss循环
task.spawn(function()
    while running do
        task.wait(detectDelay)
        if autoFollow then
            currentTarget = getClosestEnemy()
        else
            currentTarget = nil
        end
    end
end)

-- 锁定 + 跟随逻辑（加强版）
RunService.Heartbeat:Connect(function()
    if not running then return end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not (autoLock or autoFollow) then
        if alignPos then alignPos:Destroy() alignPos = nil end
        if alignOri then alignOri:Destroy() alignOri = nil end
        return
    end

    -- 创建约束
    if not alignPos then
        local att0 = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
        alignPos = Instance.new("AlignPosition")
        alignPos.Name = "LockPos"
        alignPos.Parent = hrp
        alignPos.Attachment0 = att0
        alignPos.MaxForce = math.huge
        alignPos.Responsiveness = 999
        alignPos.RigidityEnabled = true
    end

    if not alignOri then
        local att0 = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
        alignOri = Instance.new("AlignOrientation")
        alignOri.Name = "LockOri"
        alignOri.Parent = hrp
        alignOri.Attachment0 = att0
        alignOri.MaxTorque = math.huge
        alignOri.Responsiveness = 999
        alignOri.RigidityEnabled = true
    end

    -- 自动跟随Boss优先
    if autoFollow and currentTarget then
        local targetHRP = currentTarget:FindFirstChild("HumanoidRootPart")
        if targetHRP then
            local direction = (hrp.Position - targetHRP.Position).Unit
            local targetPos = targetHRP.Position + direction * followDistance
            alignPos.Position = targetPos
            alignOri.CFrame = CFrame.lookAt(targetPos, targetHRP.Position)
            return
        end
    end

    -- 普通位置锁定
    if autoLock then
        alignPos.Position = hrp.Position
        alignOri.CFrame = hrp.CFrame
    end
end)

-- 自动技能
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

print("✅ 修复版脚本已加载 - 请检查是否显示3个开关")
