local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Combat = {
	SilentAim = { Enabled = false, OldRaycast = nil, OldIndex = nil },
	Aimbot = { Enabled = false },
	Triggerbot = { Enabled = false, Delay = 0 },
	TargetPart = "Head",
	TeamCheck = true,
	VisibleCheck = true,
	Prediction = 0.165,
	FOVRadius = 200,
	Smoothness = 10,
	Connections = {}
}

local function IsTeamCheck(player)
	if not Combat.TeamCheck then
		return false
	end
	if LocalPlayer.Team and player.Team == LocalPlayer.Team then
		return true
	end
	return false
end

local function IsVisible(part)
	if not Combat.VisibleCheck then
		return true
	end
	if not part then
		return false
	end
	local origin = Workspace.CurrentCamera.CFrame.Position
	local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
	local raycastResult = Workspace:Raycast(origin, direction)
	if raycastResult and raycastResult.Instance then
		local hitPlayer = raycastResult.Instance:FindFirstAncestorWhichIsA("Model")
		if hitPlayer and hitPlayer:FindFirstChild("Humanoid") then
			return true
		end
		return false
	end
	return true
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
	local part = char:FindFirstChild(Combat.TargetPart)
	if not part then
		part = char:FindFirstChild("Head")
	end
	return part
end

local function GetClosestPlayerToMouse()
	local closestDist = Combat.FOVRadius
	local closestPlayer = nil
	local closestPart = nil

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			if IsTeamCheck(player) then
				continue
			end
			local part = GetTargetPart(player)
			if not part then
				continue
			end
			if not IsVisible(part) then
				continue
			end
			local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
			if not onScreen then
				continue
			end
			local mousePos = Vector2.new(Mouse.X, Mouse.Y)
			local partPos = Vector2.new(screenPos.X, screenPos.Y)
			local dist = (mousePos - partPos).Magnitude
			if dist < closestDist then
				closestDist = dist
				closestPlayer = player
				closestPart = part
			end
		end
	end

	return closestPlayer, closestPart, closestDist
end

function Combat:SetupSilentAim()
	local oldRaycast
	oldRaycast = hookfunction(Workspace.Raycast, newcclosure(function(self, origin, direction, raycastParams)
		if not Combat.SilentAim.Enabled then
			return oldRaycast(self, origin, direction, raycastParams)
		end
		local targetPlayer, targetPart = GetClosestPlayerToMouse()
		if targetPlayer and targetPart then
			local prediction = Combat.Prediction
			local vel = targetPlayer.Character:FindFirstChildWhichIsA("HumanoidRootPart")
			if vel then
				local newOrigin = origin
				local newDirection = (targetPart.Position + (vel.Velocity * prediction) - origin)
				return oldRaycast(self, newOrigin, newDirection.Unit * direction.Magnitude, raycastParams)
			end
		end
		return oldRaycast(self, origin, direction, raycastParams)
	end))
	Combat.SilentAim.OldRaycast = oldRaycast

	local oldIndex
	oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
		if Combat.SilentAim.Enabled and self == Mouse and (key == "Hit" or key == "Target") then
			local targetPlayer, targetPart = GetClosestPlayerToMouse()
			if targetPlayer and targetPart then
				if key == "Hit" then
					return CFrame.new(targetPart.Position)
				elseif key == "Target" then
					return targetPart
				end
			end
		end
		return oldIndex(self, key)
	end))
	Combat.SilentAim.OldIndex = oldIndex
end

function Combat:SetupAimbot()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not Combat.Aimbot.Enabled then
			return
		end
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			return
		end
		local targetPlayer, targetPart = GetClosestPlayerToMouse()
		if targetPlayer and targetPart then
			local screenPos = Workspace.CurrentCamera:WorldToViewportPoint(targetPart.Position)
			local mousePos = Vector2.new(Mouse.X, Mouse.Y)
			local targetPos = Vector2.new(screenPos.X, screenPos.Y)
			local delta = targetPos - mousePos
			local smooth = Combat.Smoothness
			mousemoverel(delta.X / smooth, delta.Y / smooth)
		end
	end)
	table.insert(Combat.Connections, conn)
end

function Combat:SetupTriggerbot()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not Combat.Triggerbot.Enabled then
			return
		end
		local targetPlayer, targetPart = GetClosestPlayerToMouse()
		if targetPlayer and targetPart then
			local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(targetPart.Position)
			if onScreen then
				local mousePos = Vector2.new(Mouse.X, Mouse.Y)
				local targetPos = Vector2.new(screenPos.X, screenPos.Y)
				if (mousePos - targetPos).Magnitude < 10 then
					task.wait(Combat.Triggerbot.Delay / 1000)
					Mouse1Click()
				end
			end
		end
	end)
	table.insert(Combat.Connections, conn)
end

function Combat:BuildUI(Tab)
	local SilentAimGroup = Tab:AddLeftGroupbox("Silent Aim")
	SilentAimGroup:AddToggle("SilentAim", {
		Text = "Silent Aim",
		Default = false,
		Tooltip = "Redirects bullets to target without moving mouse"
	})
	Toggles.SilentAim:OnChanged(function()
		Combat.SilentAim.Enabled = Toggles.SilentAim.Value
	end)

	SilentAimGroup:AddToggle("SilentAim_VisibleCheck", {
		Text = "Visible Check",
		Default = true,
		Tooltip = "Only targets players you can see"
	})
	Toggles.SilentAim_VisibleCheck:OnChanged(function()
		Combat.VisibleCheck = Toggles.SilentAim_VisibleCheck.Value
	end)

	SilentAimGroup:AddToggle("SilentAim_TeamCheck", {
		Text = "Team Check",
		Default = true,
		Tooltip = "Ignores teammates"
	})
	Toggles.SilentAim_TeamCheck:OnChanged(function()
		Combat.TeamCheck = Toggles.SilentAim_TeamCheck.Value
	end)

	SilentAimGroup:AddDropdown("SilentAim_TargetPart", {
		Text = "Target Part",
		Default = 1,
		Values = { "Head", "Torso", "HumanoidRootPart", "Random" },
		Tooltip = "Which body part to aim at"
	})
	Options.SilentAim_TargetPart:OnChanged(function()
		Combat.TargetPart = Options.SilentAim_TargetPart.Value
	end)

	SilentAimGroup:AddSlider("SilentAim_Prediction", {
		Text = "Prediction",
		Default = 0.165,
		Min = 0,
		Max = 0.5,
		Rounding = 3,
		Suffix = "s",
		Tooltip = "How far ahead to predict target movement"
	})
	Options.SilentAim_Prediction:OnChanged(function()
		Combat.Prediction = Options.SilentAim_Prediction.Value
	end)

	SilentAimGroup:AddSlider("SilentAim_FOV", {
		Text = "FOV Radius",
		Default = 200,
		Min = 10,
		Max = 500,
		Rounding = 0,
		Suffix = "px",
		Tooltip = "Maximum distance from crosshair to lock on"
	})
	Options.SilentAim_FOV:OnChanged(function()
		Combat.FOVRadius = Options.SilentAim_FOV.Value
	end)

	SilentAimGroup:AddLabel("Aim Key"):AddKeyPicker("SilentAim_Key", {
		Default = "MB2",
		Mode = "Hold",
		Text = "Silent Aim Key",
		NoUI = false
	})

	local TriggerGroup = Tab:AddRightGroupbox("Triggerbot")
	TriggerGroup:AddToggle("Triggerbot", {
		Text = "Triggerbot",
		Default = false,
		Tooltip = "Auto-fires when crosshair is on target"
	})
	Toggles.Triggerbot:OnChanged(function()
		Combat.Triggerbot.Enabled = Toggles.Triggerbot.Value
	end)

	TriggerGroup:AddSlider("Triggerbot_Delay", {
		Text = "Trigger Delay",
		Default = 0,
		Min = 0,
		Max = 500,
		Rounding = 0,
		Suffix = "ms",
		Tooltip = "Delay before firing"
	})
	Options.Triggerbot_Delay:OnChanged(function()
		Combat.Triggerbot.Delay = Options.Triggerbot_Delay.Value
	end)

	TriggerGroup:AddLabel("Trigger Key"):AddKeyPicker("Triggerbot_Key", {
		Default = "C",
		Mode = "Toggle",
		Text = "Trigger Key",
	})

	TriggerGroup:AddDivider()

	local AimbotGroup = TriggerGroup:AddDependencyBox()
	AimbotGroup:AddLabel("Aimbot")
	AimbotGroup:AddToggle("Aimbot", {
		Text = "Aimbot (Mouse)",
		Default = false,
		Tooltip = "Physically moves your mouse toward target"
	})
	Toggles.Aimbot:OnChanged(function()
		Combat.Aimbot.Enabled = Toggles.Aimbot.Value
	end)

	AimbotGroup:AddSlider("Aimbot_Smoothness", {
		Text = "Smoothness",
		Default = 10,
		Min = 1,
		Max = 50,
		Rounding = 0,
		Tooltip = "Higher = smoother but slower aim"
	})
	Options.Aimbot_Smoothness:OnChanged(function()
		Combat.Smoothness = Options.Aimbot_Smoothness.Value
	end)

	AimbotGroup:AddDropdown("Aimbot_Part", {
		Text = "Aimbot Part",
		Default = 1,
		Values = { "Head", "Torso", "HumanoidRootPart" },
	})
	Options.Aimbot_Part:OnChanged(function()
		Combat.AimbotPart = Options.Aimbot_Part.Value
	end)

	AimbotGroup:AddToggle("Aimbot_DrawFOV", {
		Text = "Draw FOV Circle",
		Default = false,
		Tooltip = "Shows the FOV radius on screen"
	})

	AimbotGroup:AddLabel("Aimbot Key"):AddKeyPicker("Aimbot_Key", {
		Default = "MB2",
		Mode = "Hold",
		Text = "Aimbot Key",
	})
	AimbotGroup:SetupDependencies({
		{ Toggles.Aimbot, true }
	})
end

function Combat:Init()
	self:SetupSilentAim()
	self:SetupAimbot()
	self:SetupTriggerbot()
	local part = Combat.TargetPart
end

function Combat:Cleanup()
	if self.SilentAim.OldRaycast then
		hookfunction(Workspace.Raycast, self.SilentAim.OldRaycast)
	end
	if self.SilentAim.OldIndex then
		hookmetamethod(game, "__index", self.SilentAim.OldIndex)
	end
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
end

return Combat
