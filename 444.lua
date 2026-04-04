local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local followDistance = 6
local detectRange = 80
local detectDelay = 0.4

local autoFight = false
local running = true
local currentTarget = nil
local lockedPosition = nil

local gui = Instance.new("ScreenGui")
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0, 220, 0, 120)
frame.Position = UDim2.new(0.5, -110, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Boss Lock"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1

local toggleButton = Instance.new("TextButton")
toggleButton.Parent = frame
toggleButton.Size = UDim2.new(0.8, 0, 0, 50)
toggleButton.Position = UDim2.new(0.1, 0, 0.4, 0)
toggleButton.Text = "Lock: OFF"
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextSize = 18

local closeButton = Instance.new("TextButton")
closeButton.Parent = frame
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
closeButton.TextColor3 = Color3.new(1, 1, 1)

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

toggleButton.MouseButton1Click:Connect(function()
    autoFight = not autoFight
    toggleButton.Text = autoFight and "Lock: ON" or "Lock: OFF"
    toggleButton.BackgroundColor3 = autoFight and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)

closeButton.MouseButton1Click:Connect(function()
    running = false
    gui:Destroy()
end)

task.spawn(function()
    while running do
        task.wait(detectDelay)

        if autoFight then
            local newTarget = getClosestEnemy()
            if newTarget \~= currentTarget then
                currentTarget = newTarget
                lockedPosition = nil
            end
        else
            currentTarget = nil
            lockedPosition = nil
        end
    end
end)

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

    if lockedPosition == nil then
        local direction = (hrp.Position - targetHRP.Position).Unit
        if direction.Magnitude < 0.01 then
            direction = Vector3.new(0, 0, 1)
        end
        lockedPosition = targetHRP.Position + direction * followDistance
    end

    hrp.CFrame = CFrame.lookAt(lockedPosition, targetHRP.Position)
end)
