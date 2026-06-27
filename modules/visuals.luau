local Visuals = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Connections = {}
local FOVCircle = nil
local CrosshairCircle = nil

Visuals.FullbrightEnabled = false
Visuals.NoFogEnabled = false
Visuals.AntiSmokeEnabled = false
Visuals.FOVChangerEnabled = false
Visuals.FOVValue = 70
Visuals.CrosshairEnabled = false
Visuals.CrosshairSize = 4
Visuals.CrosshairGap = 2
Visuals.CrosshairColor = Color3.fromRGB(255, 255, 255)

local SavedLighting = {}
local AntiSmokeConnection = nil

local function SaveLighting()
    SavedLighting.Brightness = Lighting.Brightness
    SavedLighting.Ambient = Lighting.Ambient
    SavedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
    SavedLighting.FogEnd = Lighting.FogEnd
    SavedLighting.FogStart = Lighting.FogStart
    SavedLighting.FogColor = Lighting.FogColor
    SavedLighting.GlobalShadows = Lighting.GlobalShadows
end

local function RestoreLighting()
    Lighting.Brightness = SavedLighting.Brightness or 1
    Lighting.Ambient = SavedLighting.Ambient or Color3.fromRGB(0, 0, 0)
    Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient or Color3.fromRGB(0, 0, 0)
    Lighting.FogEnd = SavedLighting.FogEnd or 100000
    Lighting.FogStart = SavedLighting.FogStart or 0
    Lighting.FogColor = SavedLighting.FogColor or Color3.fromRGB(0, 0, 0)
    Lighting.GlobalShadows = SavedLighting.GlobalShadows ~= false
end

local function SetupFOVCircle()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1.5
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.7
    FOVCircle.Visible = false
end

local function UpdateFOVCircle()
    if not FOVCircle then return end
    if Visuals.FOVChangerEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
        FOVCircle.Radius = Visuals.FOVValue
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
end

local function SetupCrosshair()
    CrosshairCircle = Drawing.new("Circle")
    CrosshairCircle.Thickness = 1.5
    CrosshairCircle.Color = Visuals.CrosshairColor
    CrosshairCircle.Filled = false
    CrosshairCircle.Radius = Visuals.CrosshairSize
    CrosshairCircle.Transparency = 0.8
    CrosshairCircle.Visible = false
end

local function UpdateCrosshair()
    if not CrosshairCircle then return end
    if Visuals.CrosshairEnabled then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        CrosshairCircle.Position = screenCenter
        CrosshairCircle.Radius = Visuals.CrosshairSize
        CrosshairCircle.Color = Visuals.CrosshairColor
        CrosshairCircle.Visible = true
    else
        CrosshairCircle.Visible = false
    end
end

local function SetupAntiSmoke()
    if AntiSmokeConnection then AntiSmokeConnection:Disconnect() end

    AntiSmokeConnection = Workspace.DescendantAdded:Connect(function(descendant)
        if not Visuals.AntiSmokeEnabled then return end

        if descendant:IsA("ParticleEmitter") then
            pcall(function() descendant.Enabled = false end)
        elseif descendant:IsA("Smoke") then
            pcall(function() descendant.Enabled = false end)
        elseif descendant:IsA("Fire") then
            pcall(function() descendant.Enabled = false end)
        end
    end)

    table.insert(Connections, AntiSmokeConnection)
end

local function CleanupAntiSmoke()
    if AntiSmokeConnection then
        AntiSmokeConnection:Disconnect()
        AntiSmokeConnection = nil
    end
end

function Visuals:Init()
    SaveLighting()

    table.insert(Connections, RunService.RenderStepped:Connect(function()
        Camera = Workspace.CurrentCamera

        UpdateFOVCircle()
        UpdateCrosshair()

        if Visuals.FullbrightEnabled then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.GlobalShadows = false
        end

        if Visuals.NoFogEnabled then
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
        end

        if Visuals.FOVChangerEnabled then
            Camera.FieldOfView = Visuals.FOVValue
        end
    end))

    SetupFOVCircle()
    SetupCrosshair()
end

function Visuals:Cleanup()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}

    if FOVCircle then
        pcall(function() FOVCircle:Remove() end)
        FOVCircle = nil
    end
    if CrosshairCircle then
        pcall(function() CrosshairCircle:Remove() end)
        CrosshairCircle = nil
    end

    CleanupAntiSmoke()
    RestoreLighting()
    Camera.FieldOfView = 70
end

function Visuals:BuildUI(Tabs)
    local VisTab = Tabs

    local LightingBox = VisTab:AddLeftGroupbox("Lighting")

    LightingBox:AddToggle("Vis_Fullbright", {
        Text = "Fullbright",
        Default = false,
        Callback = function(value)
            Visuals.FullbrightEnabled = value
            if not value then
                pcall(function()
                    Lighting.Brightness = SavedLighting.Brightness or 1
                    Lighting.Ambient = SavedLighting.Ambient or Color3.fromRGB(0, 0, 0)
                    Lighting.OutdoorAmbient = SavedLighting.OutdoorAmbient or Color3.fromRGB(0, 0, 0)
                    Lighting.GlobalShadows = SavedLighting.GlobalShadows ~= false
                end)
            end
        end
    })

    LightingBox:AddToggle("Vis_NoFog", {
        Text = "No Fog",
        Default = false,
        Callback = function(value)
            Visuals.NoFogEnabled = value
            if not value then
                pcall(function()
                    Lighting.FogEnd = SavedLighting.FogEnd or 100000
                    Lighting.FogStart = SavedLighting.FogStart or 0
                end)
            end
        end
    })

    LightingBox:AddToggle("Vis_AntiSmoke", {
        Text = "Anti-Smoke",
        Default = false,
        Callback = function(value)
            Visuals.AntiSmokeEnabled = value
            if value then
                SetupAntiSmoke()
                for _, desc in ipairs(Workspace:GetDescendants()) do
                    if desc:IsA("ParticleEmitter") or desc:IsA("Smoke") or desc:IsA("Fire") then
                        pcall(function() desc.Enabled = false end)
                    end
                end
            else
                CleanupAntiSmoke()
                for _, desc in ipairs(Workspace:GetDescendants()) do
                    if desc:IsA("ParticleEmitter") or desc:IsA("Smoke") or desc:IsA("Fire") then
                        pcall(function() desc.Enabled = true end)
                    end
                end
            end
        end
    })

    local AimAssistBox = VisTab:AddRightGroupbox("Aim Assist")

    AimAssistBox:AddToggle("Vis_FOVChanger", {
        Text = "FOV Changer",
        Default = false,
        Callback = function(value)
            Visuals.FOVChangerEnabled = value
            if not value then
                Camera.FieldOfView = 70
            end
        end
    })

    AimAssistBox:AddSlider("Vis_FOVValue", {
        Text = "FOV Value",
        Default = 70,
        Min = 30,
        Max = 120,
        Rounding = 0,
        Callback = function(value)
            Visuals.FOVValue = value
        end
    })

    AimAssistBox:AddToggle("Vis_Crosshair", {
        Text = "Crosshair",
        Default = false,
        Callback = function(value)
            Visuals.CrosshairEnabled = value
        end
    })

    AimAssistBox:AddSlider("Vis_CrosshairSize", {
        Text = "Crosshair Size",
        Default = 4,
        Min = 1,
        Max = 20,
        Rounding = 0,
        Callback = function(value)
            Visuals.CrosshairSize = value
        end
    })
end

return Visuals
