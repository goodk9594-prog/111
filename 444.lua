--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--// 状态
local autoLock = false
local running = true
local alignPos = nil
local alignOri = nil

--// GUI
local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 240, 0, 160)
frame.Position = UDim2.new(0.5, -120, 0.5, -80)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "角色位置锁定"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 18
title.Font = Enum.Font.SourceSansBold

-- 关闭按钮
local closeButton = Instance.new("TextButton")
closeButton.Parent = frame
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 18

-- 锁定开关按钮
local lockButton = Instance.new("TextButton")
lockButton.Parent = frame
lockButton.Size = UDim2.new(0.8, 0, 0, 50)
lockButton.Position = UDim2.new(0.1, 0, 0.35, 0)
lockButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
lockButton.Text = "位置锁定: OFF"
lockButton.TextColor3 = Color3.new(1, 1, 1)
lockButton.TextSize = 16

--// 按钮功能
lockButton.MouseButton1Click:Connect(function()
    autoLock = not autoLock
    lockButton.Text = autoLock and "位置锁定: ON" or "位置锁定: OFF"
    lockButton.BackgroundColor3 = autoLock and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

closeButton.MouseButton1Click:Connect(function()
    running = false
    if alignPos then alignPos:Destroy() end
    if alignOri then alignOri:Destroy() end
    gui:Destroy()
end)

--// 锁定逻辑（使用 Align 约束，最温和方式）
RunService.Heartbeat:Connect(function()
    if not running then return end

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not autoLock then
        if alignPos then alignPos:Destroy() alignPos = nil end
        if alignOri then alignOri:Destroy() alignOri = nil end
        return
    end

    -- 创建约束（只创建一次）
    if not alignPos then
        local attachment0 = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
        
        alignPos = Instance.new("AlignPosition")
        alignPos.Name = "LockPosition"
        alignPos.Parent = hrp
        alignPos.Attachment0 = attachment0
        alignPos.MaxForce = 999999999
        alignPos.Responsiveness = 200
        alignPos.RigidityEnabled = true
    end

    if not alignOri then
        local attachment0 = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
        
        alignOri = Instance.new("AlignOrientation")
        alignOri.Name = "LockOrientation"
        alignOri.Parent = hrp
        alignOri.Attachment0 = attachment0
        alignOri.MaxTorque = 999999999
        alignOri.Responsiveness = 200
        alignOri.RigidityEnabled = true
    end

    -- 实时锁定当前位置和当前朝向
    alignPos.Position = hrp.Position
    alignOri.CFrame = hrp.CFrame
end)

print("✅ 角色位置锁定脚本已加载 | 使用 Xeno 执行")
