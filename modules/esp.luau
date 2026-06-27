local ESP = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Connections = {}
local PlayerDrawings = {}
local Highlights = {}

ESP.Enabled = false
ESP.ShowBoxes = true
ESP.ShowTracers = false
ESP.ShowNames = false
ESP.ShowSkeleton = false
ESP.ShowViewLine = false
ESP.ShowChams = false
ESP.RainbowColor = false
ESP.MaxDistance = 2000
ESP.TeamCheck = true
ESP.BoxColor = Color3.fromRGB(255, 255, 255)
ESP.TracerColor = Color3.fromRGB(255, 255, 255)
ESP.NameColor = Color3.fromRGB(255, 255, 255)
ESP.SkeletonColor = Color3.fromRGB(255, 255, 255)
ESP.ViewLineColor = Color3.fromRGB(255, 255, 255)
ESP.ChamsFillColor = Color3.fromRGB(255, 0, 0)
ESP.ChamsFillTransparency = 0.5

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    return humanoid and root and humanoid.Health > 0
end

local function IsEnemy(player)
    if not ESP.TeamCheck then return true end
    if not LocalPlayer.Team or not player.Team then return true end
    return LocalPlayer.Team ~= player.Team
end

local function GetRainbowColor()
    return Color3.fromHSV((tick() % 5) / 5, 1, 1)
end

local function CreatePlayerDrawings(player)
    if PlayerDrawings[player] then return end

    local data = {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        ViewLine = Drawing.new("Line"),
        Skeleton = {
            HeadToTorso = Drawing.new("Line"),
            TorsoToLeftArm = Drawing.new("Line"),
            TorsoToRightArm = Drawing.new("Line"),
            TorsoToLeftLeg = Drawing.new("Line"),
            TorsoToRightLeg = Drawing.new("Line"),
            TorsoToLowerTorso = Drawing.new("Line"),
        }
    }

    data.Box.Thickness = 1.5
    data.Box.Color = ESP.BoxColor
    data.Box.Transparency = 1
    data.Box.Filled = false
    data.Box.Visible = false

    data.Tracer.Thickness = 1
    data.Tracer.Color = ESP.TracerColor
    data.Tracer.Transparency = 0.8
    data.Tracer.Visible = false

    data.Name.Size = 14
    data.Name.Center = true
    data.Name.Outline = true
    data.Name.Color = ESP.NameColor
    data.Name.Transparency = 1
    data.Name.Visible = false

    data.ViewLine.Thickness = 1.5
    data.ViewLine.Color = ESP.ViewLineColor
    data.ViewLine.Transparency = 0.8
    data.ViewLine.Visible = false

    for _, line in pairs(data.Skeleton) do
        line.Thickness = 2
        line.Color = ESP.SkeletonColor
        line.Transparency = 0.8
        line.Visible = false
    end

    PlayerDrawings[player] = data
end

local function RemovePlayerDrawings(player)
    local data = PlayerDrawings[player]
    if not data then return end

    pcall(function() data.Box:Remove() end)
    pcall(function() data.Tracer:Remove() end)
    pcall(function() data.Name:Remove() end)
    pcall(function() data.ViewLine:Remove() end)
    for _, line in pairs(data.Skeleton) do
        pcall(function() line:Remove() end)
    end

    PlayerDrawings[player] = nil
end

local function CreateHighlight(player)
    if Highlights[player] then return end
    if not player.Character then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "aHook_Cham"
    highlight.FillColor = ESP.ChamsFillColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = ESP.ChamsFillTransparency
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = player.Character
    highlight.Parent = player.Character
    Highlights[player] = highlight
end

local function RemoveHighlight(player)
    local hl = Highlights[player]
    if hl then
        pcall(function() hl:Destroy() end)
        Highlights[player] = nil
    end
end

local function UpdatePlayerESP(player)
    if not ESP.Enabled then
        RemovePlayerDrawings(player)
        return
    end

    if player == LocalPlayer or not IsAlive(player) or not IsEnemy(player) then
        RemovePlayerDrawings(player)
        RemoveHighlight(player)
        return
    end

    if not player.Character then
        RemovePlayerDrawings(player)
        return
    end

    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        RemovePlayerDrawings(player)
        return
    end

    local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        and (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
        or 0

    if dist > ESP.MaxDistance then
        RemovePlayerDrawings(player)
        return
    end

    CreatePlayerDrawings(player)
    local data = PlayerDrawings[player]

    local hrpPos, onScreen = Camera:WorldToViewportPoint(root.Position)

    if not onScreen then
        data.Box.Visible = false
        data.Tracer.Visible = false
        data.Name.Visible = false
        data.ViewLine.Visible = false
        for _, line in pairs(data.Skeleton) do
            line.Visible = false
        end
        return
    end

    local color = ESP.RainbowColor and GetRainbowColor() or ESP.BoxColor

    local top = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
    local bottom = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
    local size = Vector2.new(math.abs(top.X - bottom.X) * 1.5, math.abs(top.Y - bottom.Y) * 1.5)
    local pos = Vector2.new(hrpPos.X - size.X / 2, hrpPos.Y - size.Y / 2)

    if ESP.ShowBoxes then
        data.Box.Size = size
        data.Box.Position = pos
        data.Box.Color = color
        data.Box.Visible = true
    else
        data.Box.Visible = false
    end

    if ESP.ShowTracers then
        data.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        data.Tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
        data.Tracer.Color = color
        data.Tracer.Visible = true
    else
        data.Tracer.Visible = false
    end

    if ESP.ShowNames then
        data.Name.Position = Vector2.new(hrpPos.X, pos.Y - 16)
        data.Name.Text = player.Name .. " [" .. math.floor(dist) .. "]"
        data.Name.Color = color
        data.Name.Visible = true
    else
        data.Name.Visible = false
    end

    if ESP.ShowViewLine and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
        local headPos = Camera:WorldToViewportPoint(player.Character.Head.Position)
        local lookVec = player.Character.HumanoidRootPart.CFrame.LookVector * 2
        local viewPoint = player.Character.Head.Position + lookVec
        local viewPos = Camera:WorldToViewportPoint(viewPoint)

        data.ViewLine.From = Vector2.new(headPos.X, headPos.Y)
        data.ViewLine.To = Vector2.new(viewPos.X, viewPos.Y)
        data.ViewLine.Color = color
        data.ViewLine.Visible = true
    else
        data.ViewLine.Visible = false
    end

    if ESP.ShowSkeleton and player.Character then
        local head = player.Character:FindFirstChild("Head")
        local torso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso")
        local leftArm = player.Character:FindFirstChild("LeftUpperArm")
        local rightArm = player.Character:FindFirstChild("RightUpperArm")
        local leftLeg = player.Character:FindFirstChild("LeftUpperLeg")
        local rightLeg = player.Character:FindFirstChild("RightUpperLeg")
        local lowerTorso = player.Character:FindFirstChild("LowerTorso")

        if head and torso then
            local headPos = Camera:WorldToViewportPoint(head.Position)
            local torsoPos = Camera:WorldToViewportPoint(torso.Position)

            data.Skeleton.HeadToTorso.From = Vector2.new(headPos.X, headPos.Y)
            data.Skeleton.HeadToTorso.To = Vector2.new(torsoPos.X, torsoPos.Y)
            data.Skeleton.HeadToTorso.Color = color
            data.Skeleton.HeadToTorso.Visible = true

            if leftArm then
                local armPos = Camera:WorldToViewportPoint(leftArm.Position)
                data.Skeleton.TorsoToLeftArm.From = Vector2.new(torsoPos.X, torsoPos.Y)
                data.Skeleton.TorsoToLeftArm.To = Vector2.new(armPos.X, armPos.Y)
                data.Skeleton.TorsoToLeftArm.Color = color
                data.Skeleton.TorsoToLeftArm.Visible = true
            else
                data.Skeleton.TorsoToLeftArm.Visible = false
            end

            if rightArm then
                local armPos = Camera:WorldToViewportPoint(rightArm.Position)
                data.Skeleton.TorsoToRightArm.From = Vector2.new(torsoPos.X, torsoPos.Y)
                data.Skeleton.TorsoToRightArm.To = Vector2.new(armPos.X, armPos.Y)
                data.Skeleton.TorsoToRightArm.Color = color
                data.Skeleton.TorsoToRightArm.Visible = true
            else
                data.Skeleton.TorsoToRightArm.Visible = false
            end

            if leftLeg then
                local legPos = Camera:WorldToViewportPoint(leftLeg.Position)
                data.Skeleton.TorsoToLeftLeg.From = Vector2.new(torsoPos.X, torsoPos.Y)
                data.Skeleton.TorsoToLeftLeg.To = Vector2.new(legPos.X, legPos.Y)
                data.Skeleton.TorsoToLeftLeg.Color = color
                data.Skeleton.TorsoToLeftLeg.Visible = true
            else
                data.Skeleton.TorsoToLeftLeg.Visible = false
            end

            if rightLeg then
                local legPos = Camera:WorldToViewportPoint(rightLeg.Position)
                data.Skeleton.TorsoToRightLeg.From = Vector2.new(torsoPos.X, torsoPos.Y)
                data.Skeleton.TorsoToRightLeg.To = Vector2.new(legPos.X, legPos.Y)
                data.Skeleton.TorsoToRightLeg.Color = color
                data.Skeleton.TorsoToRightLeg.Visible = true
            else
                data.Skeleton.TorsoToRightLeg.Visible = false
            end

            if lowerTorso then
                local ltPos = Camera:WorldToViewportPoint(lowerTorso.Position)
                data.Skeleton.TorsoToLowerTorso.From = Vector2.new(torsoPos.X, torsoPos.Y)
                data.Skeleton.TorsoToLowerTorso.To = Vector2.new(ltPos.X, ltPos.Y)
                data.Skeleton.TorsoToLowerTorso.Color = color
                data.Skeleton.TorsoToLowerTorso.Visible = true
            else
                data.Skeleton.TorsoToLowerTorso.Visible = false
            end
        else
            for _, line in pairs(data.Skeleton) do
                line.Visible = false
            end
        end
    else
        for _, line in pairs(data.Skeleton) do
            line.Visible = false
        end
    end

    if ESP.ShowChams then
        CreateHighlight(player)
    else
        RemoveHighlight(player)
    end
end

local function UpdateAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        UpdatePlayerESP(player)
    end
end

function ESP:Init()
    table.insert(Connections, RunService.RenderStepped:Connect(function()
        if ESP.Enabled then
            UpdateAllPlayers()
        else
            for player, _ in pairs(PlayerDrawings) do
                RemovePlayerDrawings(player)
            end
            for player, _ in pairs(Highlights) do
                RemoveHighlight(player)
            end
        end
    end))

    table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
        RemovePlayerDrawings(player)
        RemoveHighlight(player)
    end))

    table.insert(Connections, Players.PlayerAdded:Connect(function(player)
        table.insert(Connections, player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if ESP.Enabled then
                UpdatePlayerESP(player)
            end
        end))
    end))

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(Connections, player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if ESP.Enabled then
                    UpdatePlayerESP(player)
                end
            end))
        end
    end
end

function ESP:Cleanup()
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}

    for player, _ in pairs(PlayerDrawings) do
        RemovePlayerDrawings(player)
    end
    for player, _ in pairs(Highlights) do
        RemoveHighlight(player)
    end
end

function ESP:BuildUI(Tabs)
    local ESPTab = Tabs

    local ESPBox = ESPTab:AddLeftGroupbox("ESP")

    ESPBox:AddToggle("ESP_Enabled", {
        Text = "Enable ESP",
        Default = false,
        Callback = function(value)
            ESP.Enabled = value
        end
    })

    ESPBox:AddToggle("ESP_Boxes", {
        Text = "Boxes",
        Default = true,
        Callback = function(value)
            ESP.ShowBoxes = value
        end
    })

    ESPBox:AddToggle("ESP_Tracers", {
        Text = "Tracers",
        Default = false,
        Callback = function(value)
            ESP.ShowTracers = value
        end
    })

    ESPBox:AddToggle("ESP_Names", {
        Text = "Names",
        Default = false,
        Callback = function(value)
            ESP.ShowNames = value
        end
    })

    ESPBox:AddToggle("ESP_Skeleton", {
        Text = "Skeleton",
        Default = false,
        Callback = function(value)
            ESP.ShowSkeleton = value
        end
    })

    ESPBox:AddToggle("ESP_ViewLine", {
        Text = "View Line",
        Default = false,
        Callback = function(value)
            ESP.ShowViewLine = value
        end
    })

    ESPBox:AddToggle("ESP_Chams", {
        Text = "Chams",
        Default = false,
        Callback = function(value)
            ESP.ShowChams = value
        end
    })

    ESPBox:AddToggle("ESP_Rainbow", {
        Text = "Rainbow Color",
        Default = false,
        Callback = function(value)
            ESP.RainbowColor = value
        end
    })

    ESPBox:AddSlider("ESP_MaxDist", {
        Text = "Max Distance",
        Default = 2000,
        Min = 100,
        Max = 10000,
        Rounding = 0,
        Callback = function(value)
            ESP.MaxDistance = value
        end
    })

    ESPBox:AddToggle("ESP_TeamCheck", {
        Text = "Team Check",
        Default = true,
        Callback = function(value)
            ESP.TeamCheck = value
        end
    })
end

return ESP
