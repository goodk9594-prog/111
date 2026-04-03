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
local alignPos = nil
local alignOri = nil

--// GUI （完全没改）
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

--// 找敌人 （完全没改）
local function getClosestEnemy()
    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local parts = workspace:GetPartBoundsInRadius(hrp.Position, detectRange)

    local closest = nil
    local shortest = detectRange

    for _,part in pairs(parts) do
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

-- 按钮 （完全没改）
fightButton.MouseButton1Click:Connect(function()
    autoFight = not autoFight
    fightButton.Text = autoFight and "Auto Fight: ON" or "Auto Fight: OFF"
end)

skillButton.MouseButton1Click:Connect(function()
    autoSkill = not autoSkill
    skillButton.Text = autoSkill and "Auto Skill: ON" or "Auto Skill: OFF"
end)

-- 关闭脚本 （完全没改）
closeButton.MouseButton1Click:Connect(function()
    running = false
    if alignPos then alignPos:Destroy() end
    if alignOri then alignOri:Destroy() end
    gui:Destroy()
end)

-- 检测Boss （完全没改）
task.spawn(function()
    while running do
        task.wait(detectDelay)
        if autoFight then
            currentTarget = getClosestEnemy()
        else
            currentTarget = nil
        end
    end
end)

-- 温和位置锁定（使用 AlignPosition + AlignOrientation，检测风险最低）
RunService.Heartbeat:Connect(function()
    if not running then return end
    if not autoFight then 
        if alignPos then alignPos:Destroy() alignPos = nil end
        if alignOri then alignOri:Destroy() alignOri = nil end
        return 
    end

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- 创建/更新约束（只在需要时创建）
    if not alignPos then
        alignPos = Instance.new("AlignPosition")
        alignPos.MaxForce = 999999999
        alignPos.Responsiveness = 200
        alignPos.Parent = hrp
        alignPos.Attachment0 = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
    end

    if not alignOri then
        alignOri = Instance.new("AlignOrientation")
        alignOri.MaxTorque = 999999999
        alignOri.Responsiveness = 200
        alignOri.Parent = hrp
        alignOri.Attachment0 = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
    end

    -- 锁定当前位置和当前朝向
    alignPos.Position = hrp.Position
    alignOri.CFrame = hrp.CFrame
end)

-- 自动技能 （完全没改）
task.spawn(function()
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
end)
