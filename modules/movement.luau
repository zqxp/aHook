local Movement = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Connections = {}
local FlyBodyVelocity = nil
local FlyBodyGyro = nil
local FlyConnection = nil
local FlyEnabled = false
local FlySpeed = 50

Movement.NoclipEnabled = false
Movement.SpeedEnabled = false
Movement.FlyEnabled = false
Movement.BhopEnabled = false
Movement.InfiniteJumpEnabled = false
Movement.CFrameWalkEnabled = false
Movement.CFrameWalkSpeed = 0.5

Movement.SpeedMultiplier = 16

local NoclipConnection = nil
local SpeedConnection = nil
local CFrameWalkConnection = nil

local function IsAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return hum and root and hum.Health > 0
end

local function SetupNoclip()
    if NoclipConnection then NoclipConnection:Disconnect() end

    NoclipConnection = RunService.Stepped:Connect(function()
        if not Movement.NoclipEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)

    table.insert(Connections, NoclipConnection)
end

local function CleanupNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
end

local function SetupSpeed()
    if SpeedConnection then SpeedConnection:Disconnect() end

    SpeedConnection = RunService.Stepped:Connect(function()
        if not Movement.SpeedEnabled then return end
        if not IsAlive() then return end

        local char = LocalPlayer.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if root and hum then
            root.CFrame = root.CFrame + hum.MoveDirection * Movement.SpeedMultiplier * 0.1
        end
    end)

    table.insert(Connections, SpeedConnection)
end

local function CleanupSpeed()
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end
end

local function SetupFly()
    if not IsAlive() then return end

    local char = LocalPlayer.Character
    local root = char:FindFirstChild("HumanoidRootPart")

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    FlyBodyVelocity.Parent = root

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyBodyGyro.P = 10000
    FlyBodyGyro.D = 500
    FlyBodyGyro.Parent = root

    FlyConnection = RunService.RenderStepped:Connect(function()
        if not FlyEnabled then return end
        if not FlyBodyVelocity or not FlyBodyGyro then return end

        local flyDir = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            flyDir = flyDir + Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            flyDir = flyDir - Camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            flyDir = flyDir - Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            flyDir = flyDir + Camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            flyDir = flyDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            flyDir = flyDir - Vector3.new(0, 1, 0)
        end

        if flyDir.Magnitude > 0 then
            flyDir = flyDir.Unit * FlySpeed
        end

        FlyBodyVelocity.Velocity = flyDir
        FlyBodyGyro.CFrame = Camera.CFrame
    end)

    table.insert(Connections, FlyConnection)
end

local function CleanupFly()
    FlyEnabled = false
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if FlyBodyVelocity then
        pcall(function() FlyBodyVelocity:Destroy() end)
        FlyBodyVelocity = nil
    end
    if FlyBodyGyro then
        pcall(function() FlyBodyGyro:Destroy() end)
        FlyBodyGyro = nil
    end
end

local function SetupCFrameWalk()
    if CFrameWalkConnection then CFrameWalkConnection:Disconnect() end

    CFrameWalkConnection = RunService.RenderStepped:Connect(function()
        if not Movement.CFrameWalkEnabled then return end
        if not IsAlive() then return end

        local char = LocalPlayer.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if root and hum then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                root.CFrame = root.CFrame + moveDir * Movement.CFrameWalkSpeed
            end
        end
    end)

    table.insert(Connections, CFrameWalkConnection)
end

local function CleanupCFrameWalk()
    if CFrameWalkConnection then
        CFrameWalkConnection:Disconnect()
        CFrameWalkConnection = nil
    end
end

function Movement:Init()
    table.insert(Connections, UserInputService.JumpRequest:Connect(function()
        if not Movement.InfiniteJumpEnabled then return end
        if not IsAlive() then return end

        local char = LocalPlayer.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))

    local lastBhopTick = 0
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        if not Movement.BhopEnabled then return end
        if not IsAlive() then return end

        local char = LocalPlayer.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        if hum.FloorMaterial ~= Enum.Material.Air then
            local now = tick()
            if now - lastBhopTick > 0.1 then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                lastBhopTick = now
            end
        end
    end))
end

function Movement:Cleanup()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    CleanupNoclip()
    CleanupSpeed()
    CleanupFly()
    CleanupCFrameWalk()
end

function Movement:BuildUI(Tabs)
    local MovTab = Tabs

    local MovementBox = MovTab:AddLeftGroupbox("Movement")

    MovementBox:AddToggle("Mov_Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(value)
            Movement.NoclipEnabled = value
            if value then
                SetupNoclip()
            else
                CleanupNoclip()
            end
        end
    })

    MovementBox:AddToggle("Mov_Speed", {
        Text = "Speed",
        Default = false,
        Callback = function(value)
            Movement.SpeedEnabled = value
            if value then
                SetupSpeed()
            else
                CleanupSpeed()
            end
        end
    })

    MovementBox:AddSlider("Mov_SpeedMult", {
        Text = "Speed Multiplier",
        Default = 16,
        Min = 16,
        Max = 100,
        Rounding = 0,
        Callback = function(value)
            Movement.SpeedMultiplier = value
        end
    })

    MovementBox:AddToggle("Mov_Fly", {
        Text = "Fly",
        Default = false,
        Callback = function(value)
            Movement.FlyEnabled = value
            FlyEnabled = value
            if value then
                SetupFly()
            else
                CleanupFly()
            end
        end
    })

    MovementBox:AddSlider("Mov_FlySpeed", {
        Text = "Fly Speed",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 0,
        Callback = function(value)
            FlySpeed = value
        end
    })

    MovementBox:AddToggle("Mov_CFrameWalk", {
        Text = "CFrame Walk",
        Default = false,
        Callback = function(value)
            Movement.CFrameWalkEnabled = value
            if value then
                SetupCFrameWalk()
            else
                CleanupCFrameWalk()
            end
        end
    })

    MovementBox:AddSlider("Mov_CFrameSpeed", {
        Text = "CFrame Speed",
        Default = 0.5,
        Min = 0.1,
        Max = 5,
        Rounding = 1,
        Callback = function(value)
            Movement.CFrameWalkSpeed = value
        end
    })

    local JumpBox = MovTab:AddRightGroupbox("Jump")

    JumpBox:AddToggle("Mov_InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(value)
            Movement.InfiniteJumpEnabled = value
        end
    })

    JumpBox:AddToggle("Mov_Bhop", {
        Text = "Bunny Hop",
        Default = false,
        Callback = function(value)
            Movement.BhopEnabled = value
        end
    })
end

return Movement
