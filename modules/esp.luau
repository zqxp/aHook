local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local ESP = {
	Enabled = false,
	BoxESP = false,
	Tracers = false,
	HealthBar = false,
	ShowName = false,
	ShowDistance = false,
	Chams = false,
	TeamCheck = true,
	ESPColor = Color3.fromRGB(255, 255, 255),
	ChamsColor = Color3.fromRGB(214, 141, 168),
	Connections = {},
	Drawings = {},
}

local function IsTeamCheck(player)
	if not ESP.TeamCheck then
		return false
	end
	if LocalPlayer.Team and player.Team == LocalPlayer.Team then
		return true
	end
	return false
end

function ESP:CreateDrawing(type)
	local drawing = Drawing.new(type)
	drawing.Visible = false
	table.insert(self.Drawings, drawing)
	return drawing
end

function ESP:ClearPlayerDrawings(player)
	if self.Drawings[player] then
		for _, d in pairs(self.Drawings[player]) do
			d:Remove()
		end
		self.Drawings[player] = nil
	end
end

function ESP:GetOrCreateDrawings(player)
	if not self.Drawings[player] then
		self.Drawings[player] = {
			Box = Drawing.new("Square"),
			BoxFill = Drawing.new("Square"),
			Tracer = Drawing.new("Line"),
			Name = Drawing.new("Text"),
			Distance = Drawing.new("Text"),
			HealthBg = Drawing.new("Square"),
			HealthFill = Drawing.new("Square"),
		}
		for _, d in pairs(self.Drawings[player]) do
			d.Visible = false
			d.ZIndex = 5
		end
	end
	return self.Drawings[player]
end

function ESP:Update()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then
			continue
		end
		if IsTeamCheck(player) then
			self:ClearPlayerDrawings(player)
			continue
		end

		local char = player.Character
		if not char then
			self:ClearPlayerDrawings(player)
			continue
		end
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not root then
			self:ClearPlayerDrawings(player)
			continue
		end

		local drawings = self:GetOrCreateDrawings(player)
		local head = char:FindFirstChild("Head")
		local rootPos = root.Position
		local headPos = head and head.Position or (rootPos + Vector3.new(0, 3, 0))
		local rootScreen, rootVis = camera:WorldToViewportPoint(rootPos)
		local headScreen, headVis = camera:WorldToViewportPoint(headPos)

		if not rootVis and not headVis then
			for _, d in pairs(drawings) do
				d.Visible = false
			end
			continue
		end

		local boxHeight = math.abs(rootScreen.Y - headScreen.Y)
		local boxWidth = boxHeight * 0.6
		local boxPos = Vector2.new(rootScreen.X - boxWidth / 2, headScreen.Y)
		local dist = math.floor((camera.CFrame.Position - rootPos).Magnitude)

		if ESP.BoxESP then
			drawings.Box.Visible = true
			drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
			drawings.Box.Position = boxPos
			drawings.Box.Color = ESP.ESPColor
			drawings.Box.Thickness = 1.5
			drawings.Box.Filled = false
			drawings.Box.Transparency = 1

			drawings.BoxFill.Visible = true
			drawings.BoxFill.Size = Vector2.new(boxWidth, boxHeight)
			drawings.BoxFill.Position = boxPos
			drawings.BoxFill.Color = Color3.fromRGB(0, 0, 0)
			drawings.BoxFill.Thickness = 0
			drawings.BoxFill.Filled = true
			drawings.BoxFill.Transparency = 0.7
		else
			drawings.Box.Visible = false
			drawings.BoxFill.Visible = false
		end

		if ESP.HealthBar then
			local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
			local healthColor = Color3.fromRGB(
				math.floor(255 * (1 - healthPercent)),
				math.floor(255 * healthPercent),
				0
			)
			drawings.HealthFill.Visible = true
			drawings.HealthFill.Size = Vector2.new(4, boxHeight * healthPercent)
			drawings.HealthFill.Position = Vector2.new(boxPos.X - 6, headScreen.Y + boxHeight * (1 - healthPercent))
			drawings.HealthFill.Color = healthColor
			drawings.HealthFill.Filled = true
			drawings.HealthFill.Transparency = 1

			drawings.HealthBg.Visible = true
			drawings.HealthBg.Size = Vector2.new(4, boxHeight)
			drawings.HealthBg.Position = Vector2.new(boxPos.X - 6, headScreen.Y)
			drawings.HealthBg.Color = Color3.fromRGB(30, 30, 30)
			drawings.HealthBg.Filled = true
			drawings.HealthBg.Transparency = 1
		else
			drawings.HealthFill.Visible = false
			drawings.HealthBg.Visible = false
		end

		if ESP.Tracers then
			drawings.Tracer.Visible = true
			drawings.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
			drawings.Tracer.To = Vector2.new(rootScreen.X, rootScreen.Y)
			drawings.Tracer.Color = ESP.ESPColor
			drawings.Tracer.Thickness = 1.5
		else
			drawings.Tracer.Visible = false
		end

		if ESP.ShowName then
			drawings.Name.Visible = true
			drawings.Name.Position = Vector2.new(boxPos.X + boxWidth / 2, headScreen.Y - 16)
			drawings.Name.Text = player.Name
			drawings.Name.Color = ESP.ESPColor
			drawings.Name.Size = 14
			drawings.Name.Center = true
			drawings.Name.Outline = true
		else
			drawings.Name.Visible = false
		end

		if ESP.ShowDistance then
			drawings.Distance.Visible = true
			drawings.Distance.Position = Vector2.new(boxPos.X + boxWidth / 2, headScreen.Y - 2)
			drawings.Distance.Text = tostring(dist) .. " studs"
			drawings.Distance.Color = ESP.ESPColor
			drawings.Distance.Size = 12
			drawings.Distance.Center = true
			drawings.Distance.Outline = true
		else
			drawings.Distance.Visible = false
		end
	end
end

function ESP:SetupChams()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not ESP.Chams then
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player == LocalPlayer then
				continue
			end
			if IsTeamCheck(player) then
				continue
			end
			local char = player.Character
			if not char then
				continue
			end
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = ESP.ChamsColor
				end
			end
		end
	end)
	table.insert(ESP.Connections, conn)
end

function ESP:BuildUI(Tab)
	local ESPGroup = Tab:AddLeftGroupbox("ESP")
	ESPGroup:AddToggle("ESP_Box", {
		Text = "Box ESP",
		Default = false,
		Tooltip = "Draws a box around players"
	})
	Toggles.ESP_Box:OnChanged(function()
		ESP.BoxESP = Toggles.ESP_Box.Value
	end)

	ESPGroup:AddToggle("ESP_Tracers", {
		Text = "Tracers",
		Default = false,
		Tooltip = "Draws line from screen bottom to player"
	})
	Toggles.ESP_Tracers:OnChanged(function()
		ESP.Tracers = Toggles.ESP_Tracers.Value
	end)

	ESPGroup:AddToggle("ESP_HealthBar", {
		Text = "Health Bar",
		Default = false,
		Tooltip = "Shows colored health bar"
	})
	Toggles.ESP_HealthBar:OnChanged(function()
		ESP.HealthBar = Toggles.ESP_HealthBar.Value
	end)

	ESPGroup:AddToggle("ESP_Name", {
		Text = "Name",
		Default = false
	})
	Toggles.ESP_Name:OnChanged(function()
		ESP.ShowName = Toggles.ESP_Name.Value
	end)

	ESPGroup:AddToggle("ESP_Distance", {
		Text = "Distance",
		Default = false
	})
	Toggles.ESP_Distance:OnChanged(function()
		ESP.ShowDistance = Toggles.ESP_Distance.Value
	end)

	ESPGroup:AddToggle("ESP_TeamCheck", {
		Text = "Team Check",
		Default = true,
		Tooltip = "Ignores teammates"
	})
	Toggles.ESP_TeamCheck:OnChanged(function()
		ESP.TeamCheck = Toggles.ESP_TeamCheck.Value
	end)

	ESPGroup:AddToggle("ESP_Chams", {
		Text = "Chams",
		Default = false,
		Tooltip = "Highlights players with solid color"
	})
	Toggles.ESP_Chams:OnChanged(function()
		ESP.Chams = Toggles.ESP_Chams.Value
	end)

	ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESP_Color", {
		Default = Color3.fromRGB(255, 255, 255),
		Title = "ESP Color"
	})
	Options.ESP_Color:OnChanged(function()
		ESP.ESPColor = Options.ESP_Color.Value
	end)

	ESPGroup:AddLabel("Chams Color"):AddColorPicker("ESP_ChamsColor", {
		Default = Color3.fromRGB(214, 141, 168),
		Title = "Chams Color"
	})
	Options.ESP_ChamsColor:OnChanged(function()
		ESP.ChamsColor = Options.ESP_ChamsColor.Value
	end)

	ESPGroup:AddToggle("ESP_Enabled", {
		Text = "Enable ESP",
		Default = false,
		Tooltip = "Master toggle for all ESP features"
	})
	Toggles.ESP_Enabled:OnChanged(function()
		ESP.Enabled = Toggles.ESP_Enabled.Value
	end)
end

function ESP:Init()
	self:SetupChams()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if ESP.Enabled then
			ESP:Update()
		else
			for player, drawings in pairs(ESP.Drawings) do
				for _, d in pairs(drawings) do
					d.Visible = false
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
	for _, d in pairs(self.Drawings) do
		if type(d) == "table" then
			for _, drawing in pairs(d) do
				drawing:Remove()
			end
		end
	end
	self.Drawings = {}
end

return ESP
