local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local ESP = {
	Enabled = false,
	BoxESP = false,
	Tracers = false,
	HealthBar = false,
	Skeleton = false,
	ShowName = false,
	ShowDistance = false,
	TeamCheck = true,
	ESPColor = Color3.fromRGB(255, 100, 100),
	HealthColor = Color3.fromRGB(0, 255, 0),
	Connections = {},
	Drawings = {},
	Skeletons = {},
}

local BONE_CONNECTIONS = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"},
	{"UpperTorso", "RightUpperArm"},
	{"LowerTorso", "LeftUpperLeg"},
	{"LowerTorso", "RightUpperLeg"},
	{"LeftUpperArm", "LeftLowerArm"},
	{"RightUpperArm", "RightLowerArm"},
	{"LeftUpperLeg", "LeftLowerLeg"},
	{"RightUpperLeg", "RightLowerLeg"},
}

local ALIASES = {
	Head = "Head",
	UpperTorso = "UpperTorso",
	LowerTorso = "LowerTorso",
	LeftUpperArm = "LeftUpperArm",
	RightUpperArm = "RightUpperArm",
	LeftLowerArm = "LeftLowerArm",
	RightLowerArm = "RightLowerArm",
	LeftUpperLeg = "LeftUpperLeg",
	RightUpperLeg = "RightUpperLeg",
	LeftLowerLeg = "LeftLowerLeg",
	RightLowerLeg = "RightLowerLeg",
}

local function IsTeammate(player)
	return ESP.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team
end

local function IsAlive(player)
	local char = player.Character
	if not char then return false end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	return hum and hum.Health > 0
end

function ESP:ClearPlayer(player)
	if self.Drawings[player] then
		for _, d in pairs(self.Drawings[player]) do
			pcall(d.Remove, d)
		end
		self.Drawings[player] = nil
	end
	if self.Skeletons[player] then
		for _, d in pairs(self.Skeletons[player]) do
			pcall(d.Destroy, d)
		end
		self.Skeletons[player] = nil
	end
end

function ESP:GetDrawings(player)
	if not self.Drawings[player] then
		local d = {}
		d.Box = Drawing.new("Square")
		d.Tracer = Drawing.new("Line")
		d.HealthBg = Drawing.new("Square")
		d.HealthFill = Drawing.new("Square")
		d.Name = Drawing.new("Text")
		d.Distance = Drawing.new("Text")
		for _, v in pairs(d) do
			v.Visible = false
			v.ZIndex = 10
		end
		self.Drawings[player] = d
	end
	return self.Drawings[player]
end

function ESP:UpdateSkeleton(player)
	local char = player.Character
	if not char then
		self:ClearPlayer(player)
		return
	end

	if not self.Skeletons[player] then
		self.Skeletons[player] = {}
	end
	local skel = self.Skeletons[player]
	local active = {}

	for _, pair in ipairs(BONE_CONNECTIONS) do
		local p1 = char:FindFirstChild(pair[1])
		local p2 = char:FindFirstChild(pair[2])
		if p1 and p2 then
			local key = pair[1] .. "_" .. pair[2]
			active[key] = true
			local adorn = skel[key]
			if not adorn then
				adorn = Instance.new("CylinderHandleAdornment")
				adorn.Radius = 0.12
				adorn.Height = 1
				adorn.AlwaysOnTop = true
				adorn.ZIndex = 20
				adorn.Color3 = ESP.ESPColor
				adorn.Transparency = 0.3
				adorn.Visible = ESP.Skeleton
				adorn.Parent = char
				skel[key] = adorn
			end
			adorn.Color3 = ESP.ESPColor
			adorn.Visible = ESP.Skeleton
			local mid = (p1.Position + p2.Position) / 2
			local dist = (p1.Position - p2.Position).Magnitude
			adorn.Height = dist
			adorn.CFrame = CFrame.lookAt(mid, p2.Position) * CFrame.new(0, 0, -dist / 2)
		end
	end

	for key, adorn in pairs(skel) do
		if not active[key] then
			adorn.Visible = false
		end
	end
end

function ESP:Update()
	camera = Workspace.CurrentCamera
	if not camera then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then
			if self.Skeletons[player] then
				for _, d in pairs(self.Skeletons[player]) do
					pcall(d.Destroy, d)
				end
				self.Skeletons[player] = nil
			end
			continue
		end

		if IsTeammate(player) or not IsAlive(player) then
			self:ClearPlayer(player)
			continue
		end

		local char = player.Character
		local root = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")
		if not root or not head then
			self:ClearPlayer(player)
			continue
		end

		local rootPos = root.Position
		local headPos = head.Position
		local rootScr, rootVis = camera:WorldToViewportPoint(rootPos)
		local headScr, headVis = camera:WorldToViewportPoint(headPos)

		if not rootVis and not headVis then
			self:ClearPlayer(player)
			continue
		end

		-- Skeleton
		if ESP.Skeleton then
			self:UpdateSkeleton(player)
		elseif self.Skeletons[player] then
			for _, d in pairs(self.Skeletons[player]) do
				pcall(d.Destroy, d)
			end
			self.Skeletons[player] = nil
		end

		-- 2D ESP
		local d = self:GetDrawings(player)
		local boxH = math.abs(rootScr.Y - headScr.Y)
		local boxW = boxH * 0.55
		local boxPos = Vector2.new(rootScr.X - boxW / 2, headScr.Y)
		local dist = math.floor((camera.CFrame.Position - rootPos).Magnitude)

		if ESP.BoxESP then
			d.Box.Visible = true
			d.Box.Size = Vector2.new(boxW, boxH)
			d.Box.Position = boxPos
			d.Box.Color = ESP.ESPColor
			d.Box.Thickness = 1.5
			d.Box.Filled = false
			d.Box.Transparency = 1
		else
			d.Box.Visible = false
		end

		if ESP.Tracers then
			d.Tracer.Visible = true
			d.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
			d.Tracer.To = Vector2.new(rootScr.X, rootScr.Y)
			d.Tracer.Color = ESP.ESPColor
			d.Tracer.Thickness = 1.5
		else
			d.Tracer.Visible = false
		end

		if ESP.HealthBar then
			local hp = math.clamp(char.Humanoid.Health / char.Humanoid.MaxHealth, 0, 1)
			local hColor = Color3.fromRGB(math.floor(255 * (1 - hp)), math.floor(255 * hp), 0)

			d.HealthBg.Visible = true
			d.HealthBg.Size = Vector2.new(4, boxH)
			d.HealthBg.Position = Vector2.new(boxPos.X - 6, headScr.Y)
			d.HealthBg.Color = Color3.fromRGB(20, 20, 20)
			d.HealthBg.Filled = true
			d.HealthBg.Transparency = 1

			d.HealthFill.Visible = true
			d.HealthFill.Size = Vector2.new(4, boxH * hp)
			d.HealthFill.Position = Vector2.new(boxPos.X - 6, headScr.Y + boxH * (1 - hp))
			d.HealthFill.Color = hColor
			d.HealthFill.Filled = true
			d.HealthFill.Transparency = 1
		else
			d.HealthBg.Visible = false
			d.HealthFill.Visible = false
		end

		if ESP.ShowName then
			d.Name.Visible = true
			d.Name.Position = Vector2.new(boxPos.X + boxW / 2, headScr.Y - 16)
			d.Name.Text = player.Name
			d.Name.Color = ESP.ESPColor
			d.Name.Size = 14
			d.Name.Center = true
			d.Name.Outline = true
		else
			d.Name.Visible = false
		end

		if ESP.ShowDistance then
			d.Distance.Visible = true
			d.Distance.Position = Vector2.new(boxPos.X + boxW / 2, headScr.Y + boxH + 2)
			d.Distance.Text = tostring(dist) .. "m"
			d.Distance.Color = Color3.fromRGB(200, 200, 200)
			d.Distance.Size = 12
			d.Distance.Center = true
			d.Distance.Outline = true
		else
			d.Distance.Visible = false
		end
	end
end

function ESP:BuildUI(Tab)
	local g = Tab:AddLeftGroupbox("ESP")
	g:AddToggle("ESP_Enabled", { Text = "Enable ESP", Default = false })
	Toggles.ESP_Enabled:OnChanged(function()
		ESP.Enabled = Toggles.ESP_Enabled.Value
	end)

	g:AddToggle("ESP_Skeleton", { Text = "Skeleton", Default = false, Tooltip = "3D bone skeleton" })
	Toggles.ESP_Skeleton:OnChanged(function()
		ESP.Skeleton = Toggles.ESP_Skeleton.Value
	end)

	g:AddToggle("ESP_Box", { Text = "Box", Default = false })
	Toggles.ESP_Box:OnChanged(function()
		ESP.BoxESP = Toggles.ESP_Box.Value
	end)

	g:AddToggle("ESP_Tracers", { Text = "Tracers", Default = false })
	Toggles.ESP_Tracers:OnChanged(function()
		ESP.Tracers = Toggles.ESP_Tracers.Value
	end)

	g:AddToggle("ESP_HealthBar", { Text = "Health Bar", Default = false })
	Toggles.ESP_HealthBar:OnChanged(function()
		ESP.HealthBar = Toggles.ESP_HealthBar.Value
	end)

	g:AddToggle("ESP_Name", { Text = "Name", Default = false })
	Toggles.ESP_Name:OnChanged(function()
		ESP.ShowName = Toggles.ESP_Name.Value
	end)

	g:AddToggle("ESP_Distance", { Text = "Distance", Default = false })
	Toggles.ESP_Distance:OnChanged(function()
		ESP.ShowDistance = Toggles.ESP_Distance.Value
	end)

	g:AddToggle("ESP_TeamCheck", { Text = "Team Check", Default = true })
	Toggles.ESP_TeamCheck:OnChanged(function()
		ESP.TeamCheck = Toggles.ESP_TeamCheck.Value
	end)

	g:AddLabel("Color"):AddColorPicker("ESP_Color", {
		Default = Color3.fromRGB(255, 100, 100),
	})
	Options.ESP_Color:OnChanged(function()
		ESP.ESPColor = Options.ESP_Color.Value
	end)
end

function ESP:Init()
	local conn = RunService.RenderStepped:Connect(function()
		if ESP.Enabled then
			ESP:Update()
		else
			for p, d in pairs(ESP.Drawings) do
				for _, v in pairs(d) do
					v.Visible = false
				end
			end
			for p, skel in pairs(ESP.Skeletons) do
				for _, v in pairs(skel) do
					v.Visible = false
				end
			end
		end
	end)
	table.insert(self.Connections, conn)
end

function ESP:Cleanup()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
	for p, d in pairs(self.Drawings) do
		for _, v in pairs(d) do
			pcall(v.Remove, v)
		end
	end
	self.Drawings = {}
	for p, skel in pairs(self.Skeletons) do
		for _, v in pairs(skel) do
			pcall(v.Destroy, v)
		end
	end
	self.Skeletons = {}
end

return ESP
