local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Rage = {
	Enabled = false,
	AutoShoot = false,
	RageMode = "Aim", -- Aim, Teleport, TPShoot
	TargetPart = "Head",
	HitChance = 75,
	MaxDistance = 1000,
	TeamCheck = true,
	VisibleCheck = false,
	AutoWall = false,
	WallPenetration = 0,
	Prediction = 0.175,
	HitboxPriority = "LowestHP",
	TargetSwitching = "Crosshair",
	AntiAim = false,
	AntiAimType = "Jitter",
	AntiAimPitch = false,
	AntiAimYaw = "Spin",
	AntiAimFakeDesync = false,
	FakeLag = false,
	FakeLagAmount = 3,
	FakeLagTick = 0,
	HitSound = false,
	HitSoundID = "rbxassetid://0",
	Connections = {},
	AttackRemote = nil,
	LastTarget = nil,
	Resolver = false,
	BodyPartMultipliers = {
		Head = 3.0,
		Torso = 1.5,
		HumanoidRootPart = 1.0,
	},
}

local function FindAttackRemote()
	if Rage.AttackRemote then return Rage.AttackRemote end
	local ok, remote = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attack")
	end)
	if ok and typeof(remote) == "Instance" and remote:IsA("RemoteEvent") then
		Rage.AttackRemote = remote
		return remote
	end
	for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
		if v:IsA("RemoteEvent") and v.Name:find("ttack") then
			Rage.AttackRemote = v
			return v
		end
	end
	return nil
end

function Rage:GetPart(player)
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	if Rage.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then return nil end
	if Rage.TargetPart == "Random" then
		local parts = { "Head", "Torso", "HumanoidRootPart" }
		return char:FindFirstChild(parts[math.random(1, #parts)])
	end
	return char:FindFirstChild(Rage.TargetPart) or char:FindFirstChild("Head")
end

function Rage:IsVisible(part)
	if not Rage.VisibleCheck then return true end
	if not part then return false end
	local cam = Workspace.CurrentCamera
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { LocalPlayer.Character or {} }
	local ray = Workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
	if ray then
		local m = ray.Instance:FindFirstAncestorWhichIsA("Model")
		if m and m:FindFirstChildWhichIsA("Humanoid") then return true end
		if Rage.AutoWall then
			local remain = ray.Distance
			local dir = (part.Position - cam.CFrame.Position).Unit
			local hit = ray.Instance
			if hit and hit:IsA("BasePart") then
				local pen = Rage.WallPenetration
				if hit.Transparency > 0.5 then pen = pen + 0.5 end
				if hit.Material == Enum.Material.Glass then pen = pen + 0.3 end
				return pen > 0.3
			end
		end
		return false
	end
	return true
end

function Rage:GetBodyPartMultiplier(partName)
	return Rage.BodyPartMultipliers[partName] or 1.0
end

function Rage:SelectTarget()
	local candidates = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p == LocalPlayer then continue end
		local part = self:GetPart(p)
		if not part then continue end
		local char = p.Character
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if not hum then continue end
		local dist = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and
			(LocalPlayer.Character.PrimaryPart.Position - part.Position).Magnitude or math.huge
		if dist > Rage.MaxDistance then continue end
		if not self:IsVisible(part) and not Rage.AutoWall then continue end
		local sp, os = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
		if not os then continue end
		table.insert(candidates, { player = p, part = part, distance = dist, health = hum.Health, screenDist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(sp.X, sp.Y)).Magnitude })
	end
	if #candidates == 0 then return nil, nil end
	if Rage.HitboxPriority == "LowestHP" then
		table.sort(candidates, function(a, b) return a.health < b.health end)
	elseif Rage.HitboxPriority == "Closest" then
		table.sort(candidates, function(a, b) return a.distance < b.distance end)
	elseif Rage.HitboxPriority == "Crosshair" then
		table.sort(candidates, function(a, b) return a.screenDist < b.screenDist end)
	end
	local picked = candidates[1]
	local chance = math.random(1, 100)
	local hc = Rage.HitChance
	local mult = self:GetBodyPartMultiplier(picked.part.Name)
	hc = hc * (mult / 1.5)
	if chance > hc then return nil, nil end
	return picked.player, picked.part
end

function Rage:TeleportToTarget(targetPart)
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local targetPos = targetPart.Position + Vector3.new(0, 3, 0)
	local lookAt = CFrame.lookAt(targetPos, targetPart.Position)
	root.CFrame = lookAt
end

function Rage:FireAt(part)
	local remote = FindAttackRemote()
	if remote then
		pcall(remote.FireServer, remote, part)
		return
	end
	Mouse1Click()
end

function Rage:DoAntiAim()
	if not Rage.AntiAim then return end
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local yaw = 0
	if Rage.AntiAimYaw == "Spin" then
		yaw = (tick() * 15) % 360
	elseif Rage.AntiAimYaw == "Jitter" then
		yaw = math.random(-60, 60)
	elseif Rage.AntiAimYaw == "Back" then
		yaw = 180
	elseif Rage.AntiAimYaw == "Left" then
		yaw = 90
	elseif Rage.AntiAimYaw == "Right" then
		yaw = -90
	elseif Rage.AntiAimYaw == "Desync" then
		yaw = 0
	end
	local pitch = 0
	if Rage.AntiAimPitch then
		pitch = math.random(-80, 80)
	end
	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(math.rad(pitch), math.rad(yaw), 0)
end

function Rage:DoFakeLag()
	if not Rage.FakeLag then return end
	Rage.FakeLagTick = Rage.FakeLagTick + 1
	if Rage.FakeLagTick >= Rage.FakeLagAmount then
		Rage.FakeLagTick = 0
		return
	end
	task.wait(0.1)
end

function Rage:SetupRagebot()
	local lastFire = 0
	local conn = RunService.Heartbeat:Connect(function()
		if not Rage.Enabled then
			Rage.LastTarget = nil
			return
		end
		Rage:DoFakeLag()
		Rage:DoAntiAim()
		local player, part = Rage:SelectTarget()
		if not player or not part then
			Rage.LastTarget = nil
			return
		end
		Rage.LastTarget = player
		if Rage.RageMode == "Teleport" or Rage.RageMode == "TPShoot" then
			Rage:TeleportToTarget(part)
		end
		if Rage.AutoShoot and (Rage.RageMode == "Aim" or Rage.RageMode == "TPShoot") then
			local now = tick()
			if now - lastFire >= 0.05 then
				Rage:FireAt(part)
				lastFire = now
			end
		end
	end)
	table.insert(Rage.Connections, conn)
end

function Rage:SetupHitSound()
	if Rage.HitSoundConn then Rage.HitSoundConn:Disconnect() end
	Rage.HitSoundConn = (LocalPlayer.Character or game:GetService("Players").LocalPlayer.CharacterAdded:Wait()):WaitForChild("Humanoid").HealthChanged:Connect(function(hp)
		if not Rage.HitSound or not Rage.LastTarget then return end
		local char = Rage.LastTarget.Character
		if not char then return end
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if hum and hum.Health < hp then
			local s = Instance.new("Sound")
			s.SoundId = Rage.HitSoundID
			s.Volume = 1
			s.Parent = Workspace.CurrentCamera
			s:Play()
			game:GetService("Debris"):AddItem(s, 1)
		end
	end)
end

function Rage:BuildUI(Tab)
	local RG = Tab:AddLeftGroupbox("Ragebot")
	RG:AddToggle("Ragebot", { Text = "Ragebot", Default = false })
	Toggles.Ragebot:OnChanged(function() Rage.Enabled = Toggles.Ragebot.Value end)
	RG:AddDropdown("Ragebot_Mode", { Text = "Rage Mode", Default = 1, Values = { "Aim", "Teleport", "TPShoot" } })
	Options.Ragebot_Mode:OnChanged(function() Rage.RageMode = Options.Ragebot_Mode.Value end)
	RG:AddToggle("Ragebot_AutoShoot", { Text = "Auto Shoot", Default = true })
	Toggles.Ragebot_AutoShoot:OnChanged(function() Rage.AutoShoot = Toggles.Ragebot_AutoShoot.Value end)
	RG:AddDropdown("Ragebot_Hitbox", { Text = "Hitbox Priority", Default = 1, Values = { "Head", "Torso", "HumanoidRootPart", "Random" } })
	Options.Ragebot_Hitbox:OnChanged(function()
		local v = Options.Ragebot_Hitbox.Value
		Rage.TargetPart = v == "Random" and ({ "Head", "Torso", "HumanoidRootPart" })[math.random(1, 3)] or v
	end)
	RG:AddSlider("Ragebot_HitChance", { Text = "Min Hit Chance", Default = 75, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
	Options.Ragebot_HitChance:OnChanged(function() Rage.HitChance = Options.Ragebot_HitChance.Value end)
	RG:AddSlider("Ragebot_MaxDistance", { Text = "Max Distance", Default = 1000, Min = 50, Max = 5000, Rounding = 0, Suffix = " studs" })
	Options.Ragebot_MaxDistance:OnChanged(function() Rage.MaxDistance = Options.Ragebot_MaxDistance.Value end)
	RG:AddSlider("Ragebot_Prediction", { Text = "Prediction", Default = 0.175, Min = 0, Max = 0.5, Rounding = 3, Suffix = "s" })
	Options.Ragebot_Prediction:OnChanged(function() Rage.Prediction = Options.Ragebot_Prediction.Value end)
	RG:AddDropdown("Ragebot_Priority", { Text = "Target Selection", Default = 1, Values = { "LowestHP", "Closest", "Crosshair" } })
	Options.Ragebot_Priority:OnChanged(function() Rage.HitboxPriority = Options.Ragebot_Priority.Value end)
	RG:AddLabel("Key"):AddKeyPicker("Ragebot_Key", { Default = "Q", Mode = "Toggle", Text = "Rage Key" })

	local AG = Tab:AddRightGroupbox("Anti-Aim")
	AG:AddToggle("Ragebot_AntiAim", { Text = "Anti-Aim", Default = false })
	Toggles.Ragebot_AntiAim:OnChanged(function() Rage.AntiAim = Toggles.Ragebot_AntiAim.Value end)
	AG:AddDropdown("Ragebot_AntiAimYaw", { Text = "Yaw", Default = 1, Values = { "Spin", "Jitter", "Back", "Left", "Right", "Desync" } })
	Options.Ragebot_AntiAimYaw:OnChanged(function() Rage.AntiAimYaw = Options.Ragebot_AntiAimYaw.Value end)
	AG:AddToggle("Ragebot_AntiAimPitch", { Text = "Pitch", Default = false })
	Toggles.Ragebot_AntiAimPitch:OnChanged(function() Rage.AntiAimPitch = Toggles.Ragebot_AntiAimPitch.Value end)
	AG:AddDivider()

	local Misc = Tab:AddLeftGroupbox("Misc")
	Misc:AddToggle("Ragebot_TeamCheck", { Text = "Team Check", Default = true })
	Toggles.Ragebot_TeamCheck:OnChanged(function() Rage.TeamCheck = Toggles.Ragebot_TeamCheck.Value end)
	Misc:AddToggle("Ragebot_AutoWall", { Text = "Auto Wallbang", Default = false })
	Toggles.Ragebot_AutoWall:OnChanged(function() Rage.AutoWall = Toggles.Ragebot_AutoWall.Value end)
	Misc:AddSlider("Ragebot_WallPen", { Text = "Wall Penetration", Default = 0, Min = 0, Max = 100, Rounding = 0, Suffix = "%" })
	Options.Ragebot_WallPen:OnChanged(function() Rage.WallPenetration = Options.Ragebot_WallPen.Value / 100 end)
	Misc:AddToggle("Ragebot_VisibleCheck", { Text = "Visible Check", Default = false })
	Toggles.Ragebot_VisibleCheck:OnChanged(function() Rage.VisibleCheck = Toggles.Ragebot_VisibleCheck.Value end)

	local Evade = Tab:AddRightGroupbox("Evasion")
	Evade:AddToggle("Ragebot_FakeLag", { Text = "Fake Lag", Default = false })
	Toggles.Ragebot_FakeLag:OnChanged(function() Rage.FakeLag = Toggles.Ragebot_FakeLag.Value end)
	Evade:AddSlider("Ragebot_FakeLagAmount", { Text = "Lag Amount", Default = 3, Min = 1, Max = 10, Rounding = 0 })
	Options.Ragebot_FakeLagAmount:OnChanged(function() Rage.FakeLagAmount = Options.Ragebot_FakeLagAmount.Value end)
	Evade:AddToggle("Ragebot_HitSound", { Text = "Hit Sound", Default = false })
	Toggles.Ragebot_HitSound:OnChanged(function() Rage.HitSound = Toggles.Ragebot_HitSound.Value end)
	Evade:AddInput("Ragebot_HitSoundID", { Text = "Sound ID", Default = "rbxassetid://0" })
	Options.Ragebot_HitSoundID:OnChanged(function() Rage.HitSoundID = Options.Ragebot_HitSoundID.Value end)
end

function Rage:Init()
	self:SetupRagebot()
	self:SetupHitSound()
end

function Rage:Cleanup()
	if Rage.HitSoundConn then Rage.HitSoundConn:Disconnect() end
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	self.Connections = {}
end

return Rage
