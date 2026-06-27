local Rage = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Connections = {}
local AttackRemote = nil

Rage.Enabled = false
Rage.OrbitAura = false
Rage.AntiAim = false
Rage.AntiAimMode = "Spin"

Rage.HitsPerFrame = 3
Rage.OrbitRadius = 10
Rage.EvadeDistance = 10000000
Rage.TargetMode = "Closest"
Rage.WeaponCycleMode = "Swap"
Rage.WeaponOrder = {"Primary", "Secondary", "Melee"}
Rage.CurrentWeaponIndex = 1
Rage.ReloadEvadeEnabled = true
Rage.FireDelay = 0

Rage.AntiAimSpinSpeed = 10
Rage.AntiAimJitterAngle = 30

local SpinAngle = 0
local IsEvaluating = false
local OrbitActive = false
local OriginalCameraCF = nil

local function FindAttackRemote()
    if AttackRemote then return AttackRemote end
    local ok, result = pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        if remotes then
            return remotes:WaitForChild("Attack", 5)
        end
    end)
    if ok and result then
        AttackRemote = result
        return result
    end
    return nil
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    return humanoid and root and humanoid.Health > 0
end

local function GetBestTarget()
    local best = nil
    local bestScore = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not IsAlive(player) then continue end
        if not player.Character:FindFirstChild("HumanoidRootPart") then continue end

        local root = player.Character.HumanoidRootPart
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then continue end

        local dist = (myRoot.Position - root.Position).Magnitude
        local score = math.huge

        if Rage.TargetMode == "Closest" then
            score = dist
        elseif Rage.TargetMode == "LowestHP" then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            score = hum and hum.Health or math.huge
        elseif Rage.TargetMode == "Crosshair" then
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                score = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
            end
        end

        if score < bestScore and dist < 500 then
            bestScore = score
            best = player
        end
    end

    return best
end

local function GetSpherePosition(center, radius)
    local theta = math.random() * math.pi * 2
    local phi = math.random() * math.pi
    local r = radius
    return center + Vector3.new(
        r * math.sin(phi) * math.cos(theta),
        r * math.sin(phi) * math.sin(theta),
        r * math.cos(phi)
    )
end

local function DetectWeapons()
    local weapons = {Primary = nil, Secondary = nil, Melee = nil}
    local char = LocalPlayer.Character
    if not char then return weapons end

    local tools = {}
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(tools, tool)
        end
    end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(tools, tool)
        end
    end

    for _, tool in ipairs(tools) do
        local name = tool.Name:lower()
        if not weapons.Primary and (name:find("rifle") or name:find("ak") or name:find("m4") or name:find("ar") or name:find("sniper") or name:find("shotgun") or name:find("smg")) then
            weapons.Primary = tool
        elseif not weapons.Secondary and (name:find("pistol") or name:find("deagle") or name:find("glock") or name:find("revolver") or name:find("hand")) then
            weapons.Secondary = tool
        elseif not weapons.Melee and (name:find("knife") or name:find("bat") or name:find("melee") or name:find("sword")) then
            weapons.Melee = tool
        end
    end

    if not weapons.Primary and not weapons.Secondary and not weapons.Melee then
        if #tools >= 3 then
            weapons.Primary = tools[1]
            weapons.Secondary = tools[2]
            weapons.Melee = tools[3]
        elseif #tools == 2 then
            weapons.Primary = tools[1]
            weapons.Secondary = tools[2]
        elseif #tools == 1 then
            weapons.Primary = tools[1]
        end
    end

    return weapons
end

local function EquipWeapon(tool)
    if not tool or not tool.Parent then return false end
    local char = LocalPlayer.Character
    if not char then return false end

    if tool.Parent == char then return true end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid:EquipTool(tool) end)
        task.wait(0.05)
        return tool.Parent == char
    end
    return false
end

local function FireAttack(enemyRoot)
    local remote = FindAttackRemote()
    if remote then
        pcall(function() remote:FireServer(enemyRoot) end)
        return true
    end
    return false
end

local function EvadeFromTarget(enemyRoot)
    if not enemyRoot then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local randomDir = Vector3.new(
        math.random() * 2 - 1,
        math.random() * 2 - 1,
        math.random() * 2 - 1
    ).Unit * Rage.EvadeDistance

    myRoot.CFrame = CFrame.new(randomDir)
end

local function OrbitAndShoot(target)
    if not target or not target.Character then return end
    local enemyRoot = target.Character:FindFirstChild("HumanoidRootPart")
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not enemyRoot or not myRoot then return end

    local savedCFrame = myRoot.CFrame

    local weapons = DetectWeapons()
    local weaponOrder = {}

    for _, slotName in ipairs(Rage.WeaponOrder) do
        if weapons[slotName] then
            table.insert(weaponOrder, weapons[slotName])
        end
    end

    if #weaponOrder == 0 then
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(weaponOrder, tool)
            end
        end
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(weaponOrder, tool)
            end
        end
    end

    if #weaponOrder == 0 then return end

    for weaponIdx, weapon in ipairs(weaponOrder) do
        EquipWeapon(weapon)
        task.wait(0.02)

        for i = 1, Rage.HitsPerFrame do
            if not IsAlive(target) then break end

            local spherePos = GetSpherePosition(enemyRoot.Position, Rage.OrbitRadius)
            myRoot.CFrame = CFrame.new(spherePos, enemyRoot.Position)

            FireAttack(enemyRoot)

            if Rage.FireDelay > 0 then
                task.wait(Rage.FireDelay)
            end
        end

        if not IsAlive(target) then break end

        if Rage.WeaponCycleMode == "Reload" then
            if Rage.ReloadEvadeEnabled then
                for evadeCount = 1, 30 do
                    if not IsAlive(target) then break end
                    EvadeFromTarget(enemyRoot)
                    task.wait()
                end

                local maxWait = 0
                while maxWait < 300 do
                    if not IsAlive(target) then break end
                    EvadeFromTarget(enemyRoot)
                    task.wait(0.1)
                    maxWait = maxWait + 1

                    local equipped = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if equipped and equipped == weapon then
                        local ammo = equipped:FindFirstChild("Ammo") or equipped:FindFirstChild("ClipSize")
                        if ammo and ammo.Value > 0 then
                            break
                        end
                    end
                end
            else
                for _ = 1, 100 do
                    task.wait(0.01)
                end
            end
        elseif Rage.WeaponCycleMode == "Swap" then
            local nextIdx = weaponIdx + 1
            if nextIdx > #weaponOrder then
                nextIdx = 1
            end
            if weaponOrder[nextIdx] then
                EquipWeapon(weaponOrder[nextIdx])
                task.wait(0.05)
            end
        end
    end

    myRoot.CFrame = savedCFrame
end

local function DoAntiAim()
    if not Rage.AntiAimEnabled then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local currentCF = myRoot.CFrame

    if Rage.AntiAimMode == "Spin" then
        SpinAngle = SpinAngle + Rage.AntiAimSpinSpeed
        if SpinAngle > 360 then SpinAngle = SpinAngle - 360 end
        myRoot.CFrame = CFrame.new(currentCF.Position) * CFrame.Angles(0, math.rad(SpinAngle), 0)
    elseif Rage.AntiAimMode == "Jitter" then
        local jitter = math.random(-Rage.AntiAimJitterAngle, Rage.AntiAimJitterAngle)
        myRoot.CFrame = CFrame.new(currentCF.Position) * CFrame.Angles(0, math.rad(jitter), 0)
    elseif Rage.AntiAimMode == "Back" then
        local lookVec = Camera.CFrame.LookVector
        myRoot.CFrame = CFrame.new(currentCF.Position, currentCF.Position - lookVec)
    end
end

function Rage:Init()
    table.insert(Connections, RunService.Heartbeat:Connect(function()
        if Rage.Enabled and Rage.OrbitAura then
            if IsEvaluating then return end
            IsEvaluating = true

            local target = GetBestTarget()
            if target then
                OrbitAndShoot(target)
            end

            IsEvaluating = false
        end

        if Rage.AntiAimEnabled then
            DoAntiAim()
        end
    end))
end

function Rage:Cleanup()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
    IsEvaluating = false
    OrbitActive = false
end

function Rage:BuildUI(Tabs)
    local RageTab = Tabs

    local OrbitBox = RageTab:AddLeftGroupbox("Orbit Aura")

    OrbitBox:AddToggle("Rage_Enabled", {
        Text = "Enable Rage",
        Default = false,
        Callback = function(value)
            Rage.Enabled = value
        end
    })

    OrbitBox:AddToggle("Rage_OrbitAura", {
        Text = "Orbit Aura",
        Default = false,
        Callback = function(value)
            Rage.OrbitAura = value
        end
    })

    OrbitBox:AddSlider("Rage_HitsPerFrame", {
        Text = "Hits Per Frame",
        Default = 3,
        Min = 1,
        Max = 10,
        Rounding = 0,
        Callback = function(value)
            Rage.HitsPerFrame = value
        end
    })

    OrbitBox:AddSlider("Rage_OrbitRadius", {
        Text = "Orbit Radius",
        Default = 10,
        Min = 3,
        Max = 50,
        Rounding = 0,
        Callback = function(value)
            Rage.OrbitRadius = value
        end
    })

    OrbitBox:AddSlider("Rage_EvadeDistance", {
        Text = "Evade Distance",
        Default = 10000000,
        Min = 1000000,
        Max = 100000000,
        Rounding = 0,
        Callback = function(value)
            Rage.EvadeDistance = value
        end
    })

    OrbitBox:AddSlider("Rage_FireDelay", {
        Text = "Fire Delay",
        Default = 0,
        Min = 0,
        Max = 0.1,
        Rounding = 3,
        Callback = function(value)
            Rage.FireDelay = value
        end
    })

    local TargetBox = RageTab:AddRightGroupbox("Targeting")

    TargetBox:AddDropdown("Rage_TargetMode", {
        Text = "Target Mode",
        Values = {"Closest", "Crosshair", "LowestHP"},
        Default = 1,
        Callback = function(value)
            Rage.TargetMode = value
        end
    })

    TargetBox:AddDropdown("Rage_WeaponCycleMode", {
        Text = "Weapon Mode",
        Values = {"Swap", "Reload"},
        Default = 1,
        Callback = function(value)
            Rage.WeaponCycleMode = value
        end
    })

    TargetBox:AddToggle("Rage_ReloadEvade", {
        Text = "Evade During Reload",
        Default = true,
        Callback = function(value)
            Rage.ReloadEvadeEnabled = value
        end
    })

    TargetBox:AddDropdown("Rage_WeaponOrder1", {
        Text = "Slot 1",
        Values = {"Primary", "Secondary", "Melee"},
        Default = 1,
        Callback = function(value)
            Rage.WeaponOrder[1] = value
        end
    })

    TargetBox:AddDropdown("Rage_WeaponOrder2", {
        Text = "Slot 2",
        Values = {"Primary", "Secondary", "Melee"},
        Default = 2,
        Callback = function(value)
            Rage.WeaponOrder[2] = value
        end
    })

    TargetBox:AddDropdown("Rage_WeaponOrder3", {
        Text = "Slot 3",
        Values = {"Primary", "Secondary", "Melee"},
        Default = 3,
        Callback = function(value)
            Rage.WeaponOrder[3] = value
        end
    })

    local AntiAimBox = RageTab:AddLeftGroupbox("Anti-Aim")

    AntiAimBox:AddToggle("Rage_AntiAim", {
        Text = "Anti-Aim",
        Default = false,
        Callback = function(value)
            Rage.AntiAimEnabled = value
        end
    })

    AntiAimBox:AddDropdown("Rage_AntiAimMode", {
        Text = "Mode",
        Values = {"Spin", "Jitter", "Back"},
        Default = 1,
        Callback = function(value)
            Rage.AntiAimMode = value
        end
    })

    AntiAimBox:AddSlider("Rage_SpinSpeed", {
        Text = "Spin Speed",
        Default = 10,
        Min = 1,
        Max = 50,
        Rounding = 0,
        Callback = function(value)
            Rage.AntiAimSpinSpeed = value
        end
    })

    AntiAimBox:AddSlider("Rage_JitterAngle", {
        Text = "Jitter Angle",
        Default = 30,
        Min = 5,
        Max = 180,
        Rounding = 0,
        Callback = function(value)
            Rage.AntiAimJitterAngle = value
        end
    })
end

return Rage
