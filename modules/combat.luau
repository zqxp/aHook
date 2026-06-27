local Combat = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Connections = {}
local SilentAimHook = nil
local OriginalCFrame = nil

Combat.Enabled = false
Combat.SilentAimEnabled = false
Combat.AimbotEnabled = false
Combat.TriggerbotEnabled = false
Combat.AutoFireEnabled = false

Combat.AimPart = "Head"
Combat.FOV = 100
Combat.Smoothness = 0.5
Combat.Prediction = 0.165
Combat.PredictionEnabled = false
Combat.PredictionStrengthX = 0.1
Combat.PredictionStrengthY = 0.1
Combat.StickyAim = false
Combat.TeamCheck = true
Combat.WallCheck = true

Combat.LockedTarget = nil
Combat.FOVCircle = nil

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.IgnoreWater = true

local function GetAttackRemote()
    local ok, remote = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 5)
            and ReplicatedStorage.Remotes:WaitForChild("Attack", 5)
    end)
    if ok and remote then return remote end
    return nil
end

local function IsLobbyVisible()
    local ok, result = pcall(function()
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if not gui then return false end
        local mainGui = gui:FindFirstChild("MainGui")
        if not mainGui then return false end
        local frame = mainGui:FindFirstChild("MainFrame")
        if not frame then return false end
        local lobby = frame:FindFirstChild("Lobby")
        if not lobby then return false end
        local currency = lobby:FindFirstChild("Currency")
        if not currency then return false end
        return currency.Visible
    end)
    return ok and result or false
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    return humanoid and root and humanoid.Health > 0
end

local function IsVisible(targetPart)
    if not Combat.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    RaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(origin, direction, RaycastParams)
    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestToMouse()
    local closest = nil
    local shortestDist = Combat.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            if Combat.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                continue
            end

            local aimPart = player.Character:FindFirstChild(Combat.AimPart)
            if not aimPart then continue end

            local predictedPos = aimPart.Position
            if Combat.PredictionEnabled then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local vel = hrp.Velocity
                    predictedPos = predictedPos + Vector3.new(
                        vel.X * Combat.PredictionStrengthX * Combat.Prediction,
                        vel.Y * Combat.PredictionStrengthY * Combat.Prediction,
                        0
                    )
                end
            end

            local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
            if not onScreen then continue end

            local mousePos = UserInputService:GetMouseLocation()
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

            if dist < shortestDist then
                if IsVisible(aimPart) then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end

    return closest
end

local function GetClosestToCrosshair()
    local closest = nil
    local shortestDist = Combat.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            if Combat.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                continue
            end

            local aimPart = player.Character:FindFirstChild(Combat.AimPart)
            if not aimPart then continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
            if not onScreen then continue end

            local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

            if dist < shortestDist then
                if IsVisible(aimPart) then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end

    return closest
end

local function AimAtTarget(target)
    if not target or not target.Character then return end

    local aimPart = target.Character:FindFirstChild(Combat.AimPart)
    if not aimPart then return end

    local predictedPos = aimPart.Position
    if Combat.PredictionEnabled then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.Velocity
            predictedPos = predictedPos + Vector3.new(
                vel.X * Combat.PredictionStrengthX * Combat.Prediction,
                vel.Y * Combat.PredictionStrengthY * Combat.Prediction,
                0
            )
        end
    end

    local targetCF = CFrame.new(Camera.CFrame.Position, predictedPos)
    Camera.CFrame = Camera.CFrame:Lerp(targetCF, Combat.Smoothness)
end

local function MoveMouseToTarget(target)
    if not target or not target.Character then return end

    local aimPart = target.Character:FindFirstChild(Combat.AimPart)
    if not aimPart then return end

    local predictedPos = aimPart.Position
    if Combat.PredictionEnabled then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.Velocity
            predictedPos = predictedPos + Vector3.new(
                vel.X * Combat.PredictionStrengthX * Combat.Prediction,
                vel.Y * Combat.PredictionStrengthY * Combat.Prediction,
                0
            )
        end
    end

    local screenPos = Camera:WorldToViewportPoint(predictedPos)
    local mousePos = UserInputService:GetMouseLocation()
    local move = Vector2.new(screenPos.X - mousePos.X, screenPos.Y - mousePos.Y)

    if Combat.Smoothness > 0 then
        move = move / (Combat.Smoothness + 1)
    end

    pcall(function() mousemoverel(move.X, move.Y) end)
end

local function SetupFOVCircle()
    Combat.FOVCircle = Drawing.new("Circle")
    Combat.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    Combat.FOVCircle.Thickness = 1
    Combat.FOVCircle.Transparency = 0.8
    Combat.FOVCircle.Filled = false
    Combat.FOVCircle.Visible = false
end

local function UpdateFOVCircle()
    if not Combat.FOVCircle then return end
    if Combat.AimbotEnabled or Combat.SilentAimEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        Combat.FOVCircle.Position = mousePos
        Combat.FOVCircle.Radius = Combat.FOV
        Combat.FOVCircle.Visible = true
    else
        Combat.FOVCircle.Visible = false
    end
end

function Combat:Init()
    SetupFOVCircle()

    table.insert(Connections, RunService.RenderStepped:Connect(function()
        UpdateFOVCircle()

        if Combat.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if not IsLobbyVisible() then
                local target = Combat.LockedTarget or GetClosestToCrosshair()
                if target then
                    Combat.LockedTarget = target
                    AimAtTarget(target)
                end
            end
        end

        if Combat.SilentAimEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            if not IsLobbyVisible() then
                local target = GetClosestToMouse()
                if target and target.Character and target.Character:FindFirstChild(Combat.AimPart) then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character[Combat.AimPart].Position)
                end
            end
        end

        if Combat.TriggerbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            if not IsLobbyVisible() then
                local target = GetClosestToCrosshair()
                if target and target.Character then
                    local head = target.Character:FindFirstChild("Head")
                    if head then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local mousePos = UserInputService:GetMouseLocation()
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if dist < 30 then
                                pcall(function() mouse1click() end)
                            end
                        end
                    end
                end
            end
        end

        if Combat.AutoFireEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            if not IsLobbyVisible() then
                pcall(function() mouse1click() end)
            end
        end
    end))

    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Combat.LockedTarget = nil
        end
    end))
end

function Combat:Cleanup()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    if Combat.FOVCircle then
        pcall(function() Combat.FOVCircle:Remove() end)
        Combat.FOVCircle = nil
    end
end

function Combat:BuildUI(Tabs)
    local CombatTab = Tabs

    local AimbotBox = CombatTab:AddLeftGroupbox("Aimbot")

    AimbotBox:AddToggle("Combat_Aimbot", {
        Text = "Enable Aimbot",
        Default = false,
        Callback = function(value)
            Combat.AimbotEnabled = value
        end
    })

    AimbotBox:AddSlider("Combat_FOV", {
        Text = "FOV Size",
        Default = 100,
        Min = 10,
        Max = 500,
        Rounding = 0,
        Callback = function(value)
            Combat.FOV = value
        end
    })

    AimbotBox:AddSlider("Combat_Smoothness", {
        Text = "Smoothness",
        Default = 0.5,
        Min = 0,
        Max = 5,
        Rounding = 1,
        Callback = function(value)
            Combat.Smoothness = value
        end
    })

    AimbotBox:AddDropdown("Combat_AimPart", {
        Text = "Aim Part",
        Values = {"Head", "HumanoidRootPart", "UpperTorso"},
        Default = 1,
        Callback = function(value)
            Combat.AimPart = value
        end
    })

    AimbotBox:AddToggle("Combat_Prediction", {
        Text = "Prediction",
        Default = false,
        Callback = function(value)
            Combat.PredictionEnabled = value
        end
    })

    AimbotBox:AddSlider("Combat_PredX", {
        Text = "Pred Strength X",
        Default = 0.1,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            Combat.PredictionStrengthX = value
        end
    })

    AimbotBox:AddSlider("Combat_PredY", {
        Text = "Pred Strength Y",
        Default = 0.1,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            Combat.PredictionStrengthY = value
        end
    })

    AimbotBox:AddToggle("Combat_StickyAim", {
        Text = "Sticky Aim",
        Default = false,
        Callback = function(value)
            Combat.StickyAim = value
        end
    })

    AimbotBox:AddToggle("Combat_TeamCheck", {
        Text = "Team Check",
        Default = true,
        Callback = function(value)
            Combat.TeamCheck = value
        end
    })

    AimbotBox:AddToggle("Combat_WallCheck", {
        Text = "Wall Check",
        Default = true,
        Callback = function(value)
            Combat.WallCheck = value
        end
    })

    local SilentAimBox = CombatTab:AddRightGroupbox("Silent Aim")

    SilentAimBox:AddToggle("Combat_SilentAim", {
        Text = "Silent Aim",
        Default = false,
        Callback = function(value)
            Combat.SilentAimEnabled = value
        end
    })

    SilentAimBox:AddToggle("Combat_Triggerbot", {
        Text = "Triggerbot",
        Default = false,
        Callback = function(value)
            Combat.TriggerbotEnabled = value
        end
    })

    SilentAimBox:AddToggle("Combat_AutoFire", {
        Text = "Auto Fire",
        Default = false,
        Callback = function(value)
            Combat.AutoFireEnabled = value
        end
    })
end

return Combat
