local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
 
local Window = Rayfield:CreateWindow({
   Name = "Universal Farm",
   LoadingTitle = "Universal Farm System",
   LoadingSubtitle = "by RoBH",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false 
})
 
local Settings = {
    AutoFarm = false,
    OneHit = false,
    AutoClick = false,
    Distance = 5,
    Position = "Behind",
    TargetName = nil,
    TargetType = "Mob"
}
 
local function GetLatestLists()
    local mobs = {}
    local players = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Parent and v.Parent:IsA("Model") then
            local name = v.Parent.Name
            if game.Players:GetPlayerFromCharacter(v.Parent) then
                if v.Parent ~= game.Players.LocalPlayer.Character and not table.find(players, name) then
                    table.insert(players, name)
                end
            else
                if not table.find(mobs, name) then
                    table.insert(mobs, name)
                end
            end
        end
    end
    table.sort(mobs)
    return mobs, players
end
 
local FarmTab = Window:CreateTab("Farm Settings", 4483362458)
local mList, pList = GetLatestLists()
 
local MobDropdown
local PlayerDropdown
 
MobDropdown = FarmTab:CreateDropdown({
   Name = "Select Mob",
   Options = mList,
   CurrentOption = "",
   Callback = function(Option) 
       if Option[1] and Option[1] ~= "" then
           Settings.TargetName = Option[1]
           Settings.TargetType = "Mob"
           PlayerDropdown:Set({""})
       end
   end,
})
 
PlayerDropdown = FarmTab:CreateDropdown({
   Name = "Select Player",
   Options = pList,
   CurrentOption = "",
   Callback = function(Option) 
       if Option[1] and Option[1] ~= "" then
           Settings.TargetName = Option[1]
           Settings.TargetType = "Player"
           MobDropdown:Set({""})
       end
   end,
})
 
FarmTab:CreateButton({
   Name = "Refresh Lists",
   Callback = function()
       local m, p = GetLatestLists()
       MobDropdown:Refresh(m)
       PlayerDropdown:Refresh(p)
   end,
})
 
FarmTab:CreateSection("Combat")
FarmTab:CreateToggle({
   Name = "Auto Click Screen",
   CurrentValue = false,
   Callback = function(Value) Settings.AutoClick = Value end,
})
FarmTab:CreateToggle({
   Name = "One Hit Kill",
   CurrentValue = false,
   Callback = function(Value) Settings.OneHit = Value end,
})
 
FarmTab:CreateSection("Movement")
FarmTab:CreateDropdown({
   Name = "Farm Position",
   Options = {"Behind", "Above", "Under"},
   CurrentOption = "Behind",
   Callback = function(Option) 
       if Option[1] then Settings.Position = Option[1] end 
   end,
})
FarmTab:CreateSlider({
   Name = "Distance Offset",
   Range = {0, 25},
   Increment = 1,
   CurrentValue = 5,
   Callback = function(Value) Settings.Distance = Value end,
})
FarmTab:CreateToggle({
   Name = "START AUTO FARM",
   CurrentValue = false,
   Callback = function(Value) Settings.AutoFarm = Value end,
})
 
FarmTab:CreateSection("UI Management")
FarmTab:CreateButton({
   Name = "Destroy UI",
   Callback = function() Rayfield:Destroy() end,
})
 
local CurrentTarget = nil
 
game:GetService("RunService").Heartbeat:Connect(function()
    if Settings.AutoFarm and Settings.TargetName and Settings.TargetName ~= "" then
        local char = game.Players.LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
 
        if not CurrentTarget or not CurrentTarget.Parent or not CurrentTarget.Parent:FindFirstChild("Humanoid") or CurrentTarget.Parent.Humanoid.Health <= 0 then
            CurrentTarget = nil
            if Settings.TargetType == "Mob" then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v.Name == Settings.TargetName and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        CurrentTarget = v:FindFirstChild("HumanoidRootPart")
                        break
                    end
                end
            else
                local p = game.Players:FindFirstChild(Settings.TargetName)
                if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.Humanoid.Health > 0 then
                    CurrentTarget = p.Character.HumanoidRootPart
                end
            end
        end
 
        if CurrentTarget then
            local speed = (Settings.Position == "Behind") and 0.4 or 0.1
            local targetCF = CurrentTarget.CFrame
            local finalCF
 
            if Settings.Position == "Behind" then
                finalCF = targetCF * CFrame.new(0, 0, Settings.Distance)
            elseif Settings.Position == "Above" then
                finalCF = targetCF * CFrame.new(0, Settings.Distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            elseif Settings.Position == "Under" then
                finalCF = targetCF * CFrame.new(0, -Settings.Distance, 0) * CFrame.Angles(math.rad(90), 0, 0)
            end
 
            myRoot.Velocity = Vector3.new(0,0,0)
            myRoot.CFrame = myRoot.CFrame:Lerp(finalCF, (speed == 0.1) and 1 or 0.5)
        end
    end
end)
 
task.spawn(function()
    while task.wait(0.1) do
        if Settings.AutoClick then
            game:GetService("VirtualUser"):CaptureController()
            game:GetService("VirtualUser"):ClickButton1(Vector2.new(9999, 9999))
        end
    end
end)
 
task.spawn(function()
    while task.wait(0.5) do
        if Settings.OneHit then
            pcall(function()
                sethiddenproperty(game.Players.LocalPlayer, "SimulationRadius", 112412400000)
                for _, d in pairs(workspace:GetDescendants()) do
                    if d:IsA("Humanoid") and d.Health > 0 and d.Health < d.MaxHealth then
                        if not game.Players:GetPlayerFromCharacter(d.Parent) then
                            d.Health = 0
                        end
                    end
                end
            end)
        end
    end
end)
 
Tags: Script
Add Comment
Please, Sign In to add comment
create new paste  /  syntax languages  /  archive  /  faq  /  tools  /  night mode  /  api  /  scraping api  /  news  /  pro
privacy statement  /  cookies policy  /  terms of service /  security disclosure  /  dmca  /  report abuse  /  contact

We use cookies for various purposes including analytics. By continuing to use Pastebin, you agree to our use of cookies as described in the Cookies Policy.  OK, I Understand
