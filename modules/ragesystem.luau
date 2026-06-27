local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Rage = {
	Enabled = false,
	AutoShoot = false,
	InstantLock = false,
	HitboxPriority = "Head",
	HitChance = 75,
	MaxDistance = 1000,
	ResolverMode = "Off",
	AutoWallbang = false,
	SkipVisibleCheck = false,
	AntiAim = false,
	AntiAimType = "Desync",
	Fakelag = false,
	FakelagAmount = 5,
	TargetPart = "Head",
	Connections = {},
	FakelagHooks = {}
}

local function IsTeamCheck(player)
	if LocalPlayer.Team and player.Team == LocalPlayer.Team then
		return true
	end
	return false
end

local function GetTargetPart(player)
	local char = player.Character
	if not char then
		return nil
	end
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local part = char:FindFirstChild(Rage.TargetPart)
	if not part then
		part = char:FindFirstChild("Head")
	end
	return part
end

local function ResolveTarget(player)
	if Rage.ResolverMode == "Off" then
		return GetTargetPart(player)
	end
	local char = player.Character
	if not char then
		return nil
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return GetTargetPart(player)
	end
	if Rage.ResolverMode == "Experimental" then
		local resolvedCF = root.CFrame * CFrame.Angles(0, math.rad(180), 0)
		return root
	elseif Rage.ResolverMode == "Full" then
		local vel = root.Velocity
		local lookDir = root.CFrame.LookVector
		local prediction = root.CFrame * CFrame.new(0, 0, -vel.Magnitude * 0.05)
		return root
	end
	return GetTargetPart(player)
end

local function IsVisible(origin, targetPos)
	local direction = (targetPos - origin)
	local mag = direction.Magnitude
	local raycastResult = Workspace:Raycast(origin, direction.Unit * mag)
	if raycastResult and raycastResult.Instance then
		local hitPlayer = raycastResult.Instance:FindFirstAncestorWhichIsA("Model")
		if hitPlayer and hitPlayer:FindFirstChildWhichIsA("Humanoid") then
			return true, raycastResult
		end
		return false, raycastResult
	end
	return true, nil
end

local function GetWallbangTarget(origin, targetPos)
	local direction = (targetPos - origin)
	local mag = direction.Magnitude
	local penetrateCount = 0
	local maxPenetrate = 3
	local hitPlayer = nil

	for i = 1, maxPenetrate do
		local raycastResult = Workspace:Raycast(origin, direction.Unit * mag)
		if not raycastResult then
			break
		end
		local model = raycastResult.Instance:FindFirstAncestorWhichIsA("Model")
		if model and model:FindFirstChildWhichIsA("Humanoid") then
			hitPlayer = model
			break
		end
		penetrateCount = penetrateCount + 1
		local material = raycastResult.Instance.Material
		if material == Enum.Material.Water or material == Enum.Material.Air then
			break
		end
		origin = raycastResult.Position + (direction.Unit * 0.5)
		mag = mag - (raycastResult.Position - origin).Magnitude
	end

	return hitPlayer
end

local function CalculateHitChance(part)
	local chance = math.random(1, 100)
	local hitChance = Rage.HitChance
	if part.Name == "Head" then
		hitChance = hitChance - 10
	elseif part.Name == "Torso" then
		hitChance = hitChance + 5
	else
		hitChance = hitChance + 15
	end
	return chance <= hitChance
end

local function FindBestTarget()
	local bestTarget = nil
	local bestPart = nil
	local bestScore = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then
			continue
		end
		if not player.Character then
			continue
		end
		if IsTeamCheck(player) then
			continue
		end

		local part
		if Rage.ResolverMode ~= "Off" then
			part = ResolveTarget(player)
		else
			part = GetTargetPart(player)
		end
		if not part then
			continue
		end

		local dist = (LocalPlayer.Character.PrimaryPart.Position - part.Position).Magnitude
		if dist > Rage.MaxDistance then
			continue
		end

		local camera = Workspace.CurrentCamera
		local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
		if not onScreen then
			continue
		end

		local mousePos = Vector2.new(Mouse.X, Mouse.Y)
		local partPos = Vector2.new(screenPos.X, screenPos.Y)
		local screenDist = (mousePos - partPos).Magnitude

		if screenDist < bestScore then
			bestScore = screenDist
			bestTarget = player
			bestPart = part
		end
	end

	if bestTarget and not Rage.SkipVisibleCheck then
		local camera = Workspace.CurrentCamera
		local origin = camera.CFrame.Position
		local visible, _ = IsVisible(origin, bestPart.Position)
		if not visible then
			if Rage.AutoWallbang then
				local wallbangTarget = GetWallbangTarget(origin, bestPart.Position)
				if wallbangTarget == bestTarget then
					return bestTarget, bestPart
				end
				return nil, nil
			end
			return nil, nil
		end
	end

	if bestTarget and not CalculateHitChance(bestPart) then
		return nil, nil
	end

	return bestTarget, bestPart
end

local function DoAntiAim()
	if not Rage.AntiAim then
		return
	end
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if Rage.AntiAimType == "Desync" then
		local cf = root.CFrame
		root.CFrame = cf * CFrame.Angles(0, math.rad(90), 0)
	elseif Rage.AntiAimType == "Spin" then
		local time = tick()
		local angle = (time * 10) % 360
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(angle), 0)
	elseif Rage.AntiAimType == "Jitter" then
		local angle = math.random(-45, 45)
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(angle), 0)
	end
end

function Rage:SetupRagebot()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not Rage.Enabled then
			return
		end

		local target, part = FindBestTarget()
		if target and part then
			if Rage.AutoShoot then
				Mouse1Click()
			end
		end

		DoAntiAim()
	end)
	table.insert(Rage.Connections, conn)
end

function Rage:SetupFakelag()
	if Rage.Fakelag then
		local mt = getrawmetatable(game)
		if mt then
			local oldNamecall = mt.__namecall
			Rage.FakelagHooks.Namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
				local method = getnamecallmethod()
				if method == "NetworkClient" or method == "Send" then
					if Rage.Fakelag and math.random(1, Rage.FakelagAmount) ~= 1 then
						return
					end
				end
				return oldNamecall(self, ...)
			end))
		end
	end
end

function Rage:BuildUI(Tab)
	local RageGroup = Tab:AddLeftGroupbox("Ragebot")
	RageGroup:AddToggle("Ragebot", {
		Text = "Ragebot",
		Default = false,
		Tooltip = "Auto-acquire and shoot targets instantly"
	})
	Toggles.Ragebot:OnChanged(function()
		Rage.Enabled = Toggles.Ragebot.Value
	end)

	RageGroup:AddToggle("Ragebot_AutoShoot", {
		Text = "Auto Shoot",
		Default = false,
		Tooltip = "Automatically fires when target acquired"
	})
	Toggles.Ragebot_AutoShoot:OnChanged(function()
		Rage.AutoShoot = Toggles.Ragebot_AutoShoot.Value
	end)

	RageGroup:AddToggle("Ragebot_InstantLock", {
		Text = "Instant Lock",
		Default = true,
		Tooltip = "Zero delay lock-on"
	})
	Toggles.Ragebot_InstantLock:OnChanged(function()
		Rage.InstantLock = Toggles.Ragebot_InstantLock.Value
	end)

	RageGroup:AddDropdown("Ragebot_Hitbox", {
		Text = "Hitbox Priority",
		Default = 1,
		Values = { "Head", "Chest", "Random" },
		Tooltip = "Which hitbox to prioritize"
	})
	Options.Ragebot_Hitbox:OnChanged(function()
		local v = Options.Ragebot_Hitbox.Value
		local map = { Head = "Head", Chest = "Torso", Random = "Head" }
		Rage.TargetPart = map[v]
	end)

	RageGroup:AddSlider("Ragebot_HitChance", {
		Text = "Minimum Hit Chance",
		Default = 75,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Suffix = "%",
		Tooltip = "Minimum probability to shoot"
	})
	Options.Ragebot_HitChance:OnChanged(function()
		Rage.HitChance = Options.Ragebot_HitChance.Value
	end)

	RageGroup:AddSlider("Ragebot_MaxDistance", {
		Text = "Max Distance",
		Default = 1000,
		Min = 50,
		Max = 5000,
		Rounding = 0,
		Suffix = " studs",
		Tooltip = "Maximum engage distance"
	})
	Options.Ragebot_MaxDistance:OnChanged(function()
		Rage.MaxDistance = Options.Ragebot_MaxDistance.Value
	end)

	RageGroup:AddLabel("Rage Key"):AddKeyPicker("Ragebot_Key", {
		Default = "Q",
		Mode = "Toggle",
		Text = "Rage Key",
	})

	local ResolverGroup = Tab:AddRightGroupbox("Resolver")
	ResolverGroup:AddDropdown("Ragebot_Resolver", {
		Text = "Resolver Mode",
		Default = 1,
		Values = { "Off", "Experimental", "Full" },
		Tooltip = "Predict desync angles for HvH"
	})
	Options.Ragebot_Resolver:OnChanged(function()
		local v = Options.Ragebot_Resolver.Value
		local map = { Off = "Off", Experimental = "Experimental", Full = "Full" }
		Rage.ResolverMode = map[v]
	end)

	ResolverGroup:AddToggle("Ragebot_AutoWallbang", {
		Text = "Auto Wallbang",
		Default = false,
		Tooltip = "Penetrate walls to hit targets"
	})
	Toggles.Ragebot_AutoWallbang:OnChanged(function()
		Rage.AutoWallbang = Toggles.Ragebot_AutoWallbang.Value
	end)

	ResolverGroup:AddToggle("Ragebot_SkipVisible", {
		Text = "Skip Visible Check",
		Default = false,
		Tooltip = "Ignore line of sight checks"
	})
	Toggles.Ragebot_SkipVisible:OnChanged(function()
		Rage.SkipVisibleCheck = Toggles.Ragebot_SkipVisible.Value
	end)

	ResolverGroup:AddDivider()

	ResolverGroup:AddLabel("Anti-Aim  ‍🌀")
	ResolverGroup:AddToggle("Ragebot_AntiAim", {
		Text = "Anti-Aim",
		Default = false,
		Tooltip = "Modify character rotation to miss shots"
	})
	Toggles.Ragebot_AntiAim:OnChanged(function()
		Rage.AntiAim = Toggles.Ragebot_AntiAim.Value
	end)

	ResolverGroup:AddDropdown("Ragebot_AntiAimType", {
		Text = "Anti-Aim Type",
		Default = 1,
		Values = { "Desync", "Spin", "Jitter" },
	})
	Options.Ragebot_AntiAimType:OnChanged(function()
		Rage.AntiAimType = Options.Ragebot_AntiAimType.Value
	end)

	ResolverGroup:AddToggle("Ragebot_Fakelag", {
		Text = "Fakelag",
		Default = false,
		Tooltip = "Choke packets for harder hits"
	})
	Toggles.Ragebot_Fakelag:OnChanged(function()
		Rage.Fakelag = Toggles.Ragebot_Fakelag.Value
		Rage:SetupFakelag()
	end)

	ResolverGroup:AddSlider("Ragebot_FakelagAmount", {
		Text = "Fakelag Amount",
		Default = 5,
		Min = 1,
		Max = 15,
		Rounding = 0,
		Tooltip = "How many packets to choke"
	})
	Options.Ragebot_FakelagAmount:OnChanged(function()
		Rage.FakelagAmount = Options.Ragebot_FakelagAmount.Value
	end)
end

function Rage:Init()
	self:SetupRagebot()
	self:SetupFakelag()
end

function Rage:Cleanup()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
	for _, hook in pairs(self.FakelagHooks) do
		if type(hook) == "function" then
		end
	end
end

return Rage
