local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Combat = {
	SilentAim = false,
	Aimbot = false,
	Triggerbot = false,
	AutoFire = false,
	FireRate = 0.08,
	TargetPart = "Head",
	TeamCheck = true,
	VisibleCheck = true,
	Prediction = 0.165,
	FOVRadius = 200,
	Smoothness = 0.5,
	DrawFOV = false,
	FOVCircle = nil,
	Connections = {},
	AttackRemote = nil,
	HoldingClick = false,
	FireLoop = nil,
}

local function FindAttackRemote()
	if Combat.AttackRemote then return Combat.AttackRemote end
	local ok, remote = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attack")
	end)
	if ok and typeof(remote) == "Instance" and remote:IsA("RemoteEvent") then
		Combat.AttackRemote = remote
		return remote
	end
	for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
		if v:IsA("RemoteEvent") and v.Name:find("ttack") then
			Combat.AttackRemote = v
			return v
		end
	end
	return nil
end

function Combat:GetTarget(player)
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	if Combat.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then return nil end
	local part = char:FindFirstChild(Combat.TargetPart) or char:FindFirstChild("Head")
	return part
end

function Combat:IsVisible(part)
	if not Combat.VisibleCheck then return true end
	if not part then return false end
	local cam = Workspace.CurrentCamera
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {LocalPlayer.Character or {}}
	local ray = Workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
	if ray then
		local model = ray.Instance:FindFirstAncestorWhichIsA("Model")
		if model and model:FindFirstChildWhichIsA("Humanoid") then return true end
		return false
	end
	return true
end

function Combat:GetBestTarget()
	local closest = math.huge
	local bestPlayer, bestPart = nil, nil
	local cam = Workspace.CurrentCamera
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		local part = self:GetTarget(p)
		if not part then continue end
		local sp, os = cam:WorldToViewportPoint(part.Position)
		if not os then continue end
		local mp = UserInputService:GetMouseLocation()
		local pp = Vector2.new(sp.X, sp.Y)
		local d = (mp - pp).Magnitude
		if d < closest and d <= Combat.FOVRadius then
			closest = d
			bestPlayer = p
			bestPart = part
		end
	end
	return bestPlayer, bestPart
end

function Combat:FireAt(part)
	local remote = FindAttackRemote()
	if remote then
		pcall(remote.FireServer, remote, part)
		return
	end
	Mouse1Click()
end

function Combat:SetupSilentAim()
	if Combat.SilentAimHook then return end
	Combat.SilentAimHook = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if Combat.SilentAim and self == Mouse and (key == "Hit" or key == "Target") then
			local _, part = Combat:GetBestTarget()
			if part then
				if not Combat:IsVisible(part) then
					return Combat.SilentAimHook(self, key)
				end
				if key == "Hit" then
					local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
					local vel = root and root.Velocity or Vector3.new()
					return CFrame.new(part.Position + vel * Combat.Prediction)
				end
				return part
			end
		end
		return Combat.SilentAimHook(self, key)
	end))
end

function Combat:FireLoop()
	if Combat.FireLoop then Combat.FireLoop:Disconnect() end
	Combat.FireLoop = RunService.Heartbeat:Connect(function()
		if not Combat.AutoFire or not Combat.HoldingClick then return end
		if not Combat.SilentAim then
			Combat:FireAt(nil)
			return
		end
		local _, part = Combat:GetBestTarget()
		if part and Combat:IsVisible(part) then
			Combat:FireAt(part)
		end
		task.wait(Combat.FireRate)
	end)
end

function Combat:DrawFOVCircle()
	if Combat.FOVCircle then
		Combat.FOVCircle:Remove()
		Combat.FOVCircle = nil
	end
	if not Combat.DrawFOV then return end
	local c = Drawing.new("Circle")
	c.Visible = true
	c.Radius = Combat.FOVRadius
	c.Thickness = 1.5
	c.Color = Color3.fromRGB(255, 255, 255)
	c.Transparency = 0.7
	c.NumSides = 64
	c.Filled = false
	Combat.FOVCircle = c
	local conn = RunService.RenderStepped:Connect(function()
		if Combat.FOVCircle then
			local vp = Workspace.CurrentCamera.ViewportSize
			Combat.FOVCircle.Position = Vector2.new(vp.X / 2, vp.Y / 2)
			Combat.FOVCircle.Visible = Combat.DrawFOV
			Combat.FOVCircle.Radius = Combat.FOVRadius
		end
	end)
	table.insert(Combat.Connections, conn)
end

function Combat:SetupAimbot()
	local conn = RunService.RenderStepped:Connect(function()
		if not Combat.Aimbot then return end
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
		local _, part = Combat:GetBestTarget()
		if part and Combat:IsVisible(part) then
			local cam = Workspace.CurrentCamera
			local current = cam.CFrame
			local target = CFrame.new(current.Position, part.Position)
			cam.CFrame = current:Lerp(target, Combat.Smoothness)
		end
	end)
	table.insert(Combat.Connections, conn)
end

function Combat:SetupTriggerbot()
	local conn = RunService.Heartbeat:Connect(function()
		if not Combat.Triggerbot then return end
		local _, part = Combat:GetBestTarget()
		if part and Combat:IsVisible(part) then
			local sp = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
			local mp = UserInputService:GetMouseLocation()
			local tp = Vector2.new(sp.X, sp.Y)
			if (mp - tp).Magnitude < 15 then
				Combat:FireAt(part)
			end
		end
	end)
	table.insert(Combat.Connections, conn)
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Combat.HoldingClick = true
		if Combat.AutoFire then Combat:FireLoop() end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Combat.HoldingClick = false
		if Combat.FireLoop then
			Combat.FireLoop:Disconnect()
			Combat.FireLoop = nil
		end
	end
end)

function Combat:BuildUI(Tab)
	local SA = Tab:AddLeftGroupbox("Silent Aim")
	SA:AddToggle("SilentAim", { Text = "Silent Aim", Default = false })
	Toggles.SilentAim:OnChanged(function() Combat.SilentAim = Toggles.SilentAim.Value end)
	SA:AddToggle("SilentAim_VisibleCheck", { Text = "Visible Check", Default = true })
	Toggles.SilentAim_VisibleCheck:OnChanged(function() Combat.VisibleCheck = Toggles.SilentAim_VisibleCheck.Value end)
	SA:AddToggle("SilentAim_TeamCheck", { Text = "Team Check", Default = true })
	Toggles.SilentAim_TeamCheck:OnChanged(function() Combat.TeamCheck = Toggles.SilentAim_TeamCheck.Value end)
	SA:AddDropdown("SilentAim_TargetPart", { Text = "Target Part", Default = 1, Values = { "Head", "Torso", "HumanoidRootPart", "Random" } })
	Options.SilentAim_TargetPart:OnChanged(function()
		local v = Options.SilentAim_TargetPart.Value
		Combat.TargetPart = v == "Random" and ({ "Head", "Torso", "HumanoidRootPart" })[math.random(1, 3)] or v
	end)
	SA:AddSlider("SilentAim_Prediction", { Text = "Prediction", Default = 0.165, Min = 0, Max = 0.5, Rounding = 3, Suffix = "s" })
	Options.SilentAim_Prediction:OnChanged(function() Combat.Prediction = Options.SilentAim_Prediction.Value end)
	SA:AddSlider("SilentAim_FOV", { Text = "FOV Radius", Default = 200, Min = 10, Max = 500, Rounding = 0, Suffix = "px" })
	Options.SilentAim_FOV:OnChanged(function() Combat.FOVRadius = Options.SilentAim_FOV.Value end)
	SA:AddLabel("Key"):AddKeyPicker("SilentAim_Key", { Default = "MB2", Mode = "Hold", Text = "Silent Aim Key" })

	local AB = Tab:AddRightGroupbox("Aimbot")
	AB:AddToggle("Aimbot", { Text = "Aimbot", Default = false })
	Toggles.Aimbot:OnChanged(function() Combat.Aimbot = Toggles.Aimbot.Value end)
	AB:AddSlider("Aimbot_Smoothness", { Text = "Smoothness", Default = 0.5, Min = 0.1, Max = 1, Rounding = 2, Suffix = "" })
	Options.Aimbot_Smoothness:OnChanged(function() Combat.Smoothness = Options.Aimbot_Smoothness.Value end)
	AB:AddToggle("Aimbot_DrawFOV", { Text = "Draw FOV Circle", Default = false })
	Toggles.Aimbot_DrawFOV:OnChanged(function() Combat.DrawFOV = Toggles.Aimbot_DrawFOV.Value; Combat:DrawFOVCircle() end)
	AB:AddLabel("Key"):AddKeyPicker("Aimbot_Key", { Default = "MB2", Mode = "Hold", Text = "Aimbot Key" })

	local TB = Tab:AddLeftGroupbox("Triggerbot")
	TB:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false })
	Toggles.Triggerbot:OnChanged(function() Combat.Triggerbot = Toggles.Triggerbot.Value end)
	TB:AddLabel("Key"):AddKeyPicker("Triggerbot_Key", { Default = "C", Mode = "Toggle", Text = "Trigger Key" })

	local AF = Tab:AddRightGroupbox("Auto Fire")
	AF:AddToggle("AutoFire", { Text = "Auto Fire", Default = false })
	Toggles.AutoFire:OnChanged(function() Combat.AutoFire = Toggles.AutoFire.Value end)
	AF:AddSlider("AutoFire_Rate", { Text = "Fire Rate (s)", Default = 0.08, Min = 0.01, Max = 0.5, Rounding = 2, Suffix = "s" })
	Options.AutoFire_Rate:OnChanged(function() Combat.FireRate = Options.AutoFire_Rate.Value end)
end

function Combat:Init()
	self:SetupSilentAim()
	self:SetupAimbot()
	self:SetupTriggerbot()
	self:DrawFOVCircle()
end

function Combat:Cleanup()
	if Combat.SilentAimHook then
		hookmetamethod(game, "__index", Combat.SilentAimHook)
		Combat.SilentAimHook = nil
	end
	if Combat.FOVCircle then
		Combat.FOVCircle:Remove()
		Combat.FOVCircle = nil
	end
	if Combat.FireLoop then
		Combat.FireLoop:Disconnect()
		Combat.FireLoop = nil
	end
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	self.Connections = {}
end

return Combat
