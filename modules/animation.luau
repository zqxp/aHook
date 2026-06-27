local Animation = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Connections = {}
local OriginalAnims = {}

Animation.NoAnimationEnabled = false
Animation.DisableArmsEnabled = false
Animation.NoWeaponSwayEnabled = false
Animation.NoBobEnabled = false

local function GetHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function CancelAnimations()
    local hum = GetHumanoid()
    if not hum then return end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if Animation.NoAnimationEnabled then
            track:Stop(0)
        end
    end
end

local function SetupNoAnimation()
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        if not Animation.NoAnimationEnabled then return end
        CancelAnimations()
    end))
end

local function SetupCharacterAdded()
    table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(1)
        if Animation.NoAnimationEnabled then
            CancelAnimations()
        end
    end))
end

function Animation:Init()
    SetupNoAnimation()
    SetupCharacterAdded()
end

function Animation:Cleanup()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
end

function Animation:BuildUI(Tabs)
    local AnimTab = Tabs

    local AnimBox = AnimTab:AddLeftGroupbox("Animation")

    AnimBox:AddToggle("Anim_NoAnimation", {
        Text = "No Animation",
        Default = false,
        Callback = function(value)
            Animation.NoAnimationEnabled = value
        end
    })

    AnimBox:AddToggle("Anim_DisableArms", {
        Text = "Disable Arms",
        Default = false,
        Callback = function(value)
            Animation.DisableArmsEnabled = value
        end
    })

    AnimBox:AddToggle("Anim_NoSway", {
        Text = "No Weapon Sway",
        Default = false,
        Callback = function(value)
            Animation.NoWeaponSwayEnabled = value
        end
    })

    AnimBox:AddToggle("Anim_NoBob", {
        Text = "No Weapon Bob",
        Default = false,
        Callback = function(value)
            Animation.NoBobEnabled = value
        end
    })
end

return Animation
