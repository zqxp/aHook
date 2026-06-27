local SkinChanger = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local Connections = {}
local WatcherConnection = nil

SkinChanger.Enabled = false
SkinChanger.CurrentWeapon = nil
SkinChanger.CurrentSkin = nil
SkinChanger.Material = "Plastic"
SkinChanger.Color = Color3.fromRGB(255, 0, 0)
SkinChanger.Transparency = 0
SkinChanger.ApplyToAllParts = false

local MaterialMap = {
    Plastic = Enum.Material.Plastic,
    Metal = Enum.Material.Metal,
    Neon = Enum.Material.Neon,
    Ice = Enum.Material.Ice,
    Glow = Enum.Material.ForceField,
}

local function GetWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool end
    return nil
end

local function ApplySkin()
    if not SkinChanger.Enabled then return end

    local weapon = GetWeapon()
    if not weapon then return end

    local mat = MaterialMap[SkinChanger.Material] or Enum.Material.Plastic

    local parts = weapon:GetDescendants()
    if not SkinChanger.ApplyToAllParts then
        parts = weapon:GetChildren()
    end

    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Color = SkinChanger.Color
                part.Material = mat
                part.Transparency = SkinChanger.Transparency
            end)
        end
    end
end

function SkinChanger:Init()
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        if not SkinChanger.Enabled then return end
        local weapon = GetWeapon()
        if weapon and weapon ~= SkinChanger.CurrentWeapon then
            SkinChanger.CurrentWeapon = weapon
            SkinChanger.CurrentSkin = weapon.Name
            task.defer(ApplySkin)
        end
    end))
end

function SkinChanger:Cleanup()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
end

function SkinChanger:ApplySkin(weaponName, skinName)
    SkinChanger.CurrentWeapon = nil
    SkinChanger.CurrentSkin = skinName
    local weapon = GetWeapon()
    if weapon and weapon.Name == weaponName then
        SkinChanger.CurrentWeapon = weapon
        ApplySkin()
    end
end

function SkinChanger:BuildUI(Tabs)
    local SkinTab = Tabs

    local SkinBox = SkinTab:AddLeftGroupbox("Skin Changer")

    SkinBox:AddToggle("Skin_Enabled", {
        Text = "Enable Skin Changer",
        Default = false,
        Callback = function(value)
            SkinChanger.Enabled = value
            if value then
                ApplySkin()
            end
        end
    })

    SkinBox:AddDropdown("Skin_Material", {
        Text = "Material",
        Values = {"Plastic", "Metal", "Neon", "Ice", "Glow"},
        Default = 1,
        Callback = function(value)
            SkinChanger.Material = value
            ApplySkin()
        end
    })

    SkinBox:AddSlider("Skin_Transparency", {
        Text = "Transparency",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            SkinChanger.Transparency = value
            ApplySkin()
        end
    })

    SkinBox:AddToggle("Skin_ApplyAll", {
        Text = "Apply to All Parts",
        Default = false,
        Callback = function(value)
            SkinChanger.ApplyToAllParts = value
            ApplySkin()
        end
    })

    SkinBox:AddButton("Apply Now", function()
        ApplySkin()
    end)
end

return SkinChanger
