local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local ESP = {
	Enabled = false,
	Boxes = true,
	BoxStyle = "Full", -- Full, Corner, 3D
	BoxOutline = true,
	Tracers = false,
	TracerOrigin = "Bottom",
	HealthBar = true,
	HealthStyle = "Bar",
	Skeleton = false,
	Names = true,
	Distance = true,
	TeamCheck = true,
	ShowTeam = false,
	Chams = false,
	ChamsFillColor = Color3.fromRGB(255, 0, 0),
	ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
	ChamsFillTransparency = 0.5,
	Color = Color3.fromRGB(240, 80, 80),
	MaxDistance = 5000,
	TextSize = 14,
	Rainbow = false,
	RainbowSpeed = 1,
	RainbowParts = "All",
	Connections = {},
	Highlights = {},
	PlayerData = {},
}

local function GetCamera()
	return Workspace.CurrentCamera
end

function ESP:GetData(player)
	if not self.PlayerData[player] then
		self.PlayerData[player] = {
			Box = Drawing.new("Square"),
			BoxBg = Drawing.new("Square"),
			Tracer = Drawing.new("Line"),
			HealthBg = Drawing.new("Square"),
			HealthFill = Drawing.new("Square"),
			NameLbl = Drawing.new("Text"),
			DistLbl = Drawing.new("Text"),
			HealthText = Drawing.new("Text"),
			CornerLines = {},
			SkelParts = {},
		}
		for _, v in pairs(self.PlayerData[player]) do
			if typeof(v) == "Drawing" then
				v.Visible = false
				v.ZIndex = 10
			end
		end
		local corners = {}
		for i = 1, 8 do
			local line = Drawing.new("Line")
			line.Visible = false
			line.ZIndex = 10
			corners[i] = line
		end
		self.PlayerData[player].CornerLines = corners
	end
	return self.PlayerData[player]
end

function ESP:Clear(player)
	local d = self.PlayerData[player]
	if d then
		for _, v in pairs(d) do
			if typeof(v) == "Drawing" then pcall(v.Remove, v) end
		end
		for _, v in pairs(d.CornerLines) do pcall(v.Remove, v) end
		for _, v in pairs(d.SkelParts) do pcall(v.Destroy, v) end
		self.PlayerData[player] = nil
	end
	local hl = self.Highlights[player]
	if hl then
		hl:Destroy()
		self.Highlights[player] = nil
	end
end

function ESP:IsAlive(player)
	local char = player.Character
	if not char then return false end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	return hum and hum.Health > 0
end

function ESP:IsEnemy(player)
	if player == LocalPlayer then return false end
	if ESP.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
		return ESP.ShowTeam
	end
	return true
end

function ESP:GetRainbowColor()
	if not ESP.Rainbow then return ESP.Color end
	return Color3.fromHSV(tick() * ESP.RainbowSpeed / 10 % 1, 1, 1)
end

function ESP:GetBoundingBox(char)
	local cam = GetCamera()
	if not cam then return nil end
	local vs = cam.ViewportSize
	local xMin, yMin = vs.X, vs.Y
	local xMax, yMax = 0, 0
	local onScreen = false

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			local cf = part.CFrame
			local size = part.Size
			local corners = {
				cf:PointToWorldSpace(Vector3.new(-size.X/2, -size.Y/2, -size.Z/2)),
				cf:PointToWorldSpace(Vector3.new(size.X/2, -size.Y/2, -size.Z/2)),
				cf:PointToWorldSpace(Vector3.new(-size.X/2, -size.Y/2, size.Z/2)),
				cf:PointToWorldSpace(Vector3.new(size.X/2, -size.Y/2, size.Z/2)),
				cf:PointToWorldSpace(Vector3.new(-size.X/2, size.Y/2, -size.Z/2)),
				cf:PointToWorldSpace(Vector3.new(size.X/2, size.Y/2, -size.Z/2)),
				cf:PointToWorldSpace(Vector3.new(-size.X/2, size.Y/2, size.Z/2)),
				cf:PointToWorldSpace(Vector3.new(size.X/2, size.Y/2, size.Z/2)),
			}
			for _, c in ipairs(corners) do
				local sp, vis = cam:WorldToViewportPoint(c)
				if vis then
					onScreen = true
					if sp.X < xMin then xMin = sp.X end
					if sp.X > xMax then xMax = sp.X end
					if sp.Y < yMin then yMin = sp.Y end
					if sp.Y > yMax then yMax = sp.Y end
				end
			end
		end
	end
	for _, child in ipairs(char:GetDescendants()) do
		if child:IsA("BasePart") and child.Parent ~= char then
			local sp, vis = cam:WorldToViewportPoint(child.Position)
			if vis then
				onScreen = true
				if sp.X < xMin then xMin = sp.X end
				if sp.X > xMax then xMax = sp.X end
				if sp.Y < yMin then yMin = sp.Y end
				if sp.Y > yMax then yMax = sp.Y end
			end
		end
	end
	if not onScreen then return nil end
	return xMin, yMin, xMax, yMax, bw, bh
end

function ESP:DrawCornerBox(d, x, y, w, h, color)
	local cl = d.CornerLines
	local len = math.min(w, h) * 0.2
	local t = 1.5

	-- Top-left
	cl[1].From = Vector2.new(x, y); cl[1].To = Vector2.new(x + len, y)
	cl[2].From = Vector2.new(x, y); cl[2].To = Vector2.new(x, y + len)
	-- Top-right
	cl[3].From = Vector2.new(x + w, y); cl[3].To = Vector2.new(x + w - len, y)
	cl[4].From = Vector2.new(x + w, y); cl[4].To = Vector2.new(x + w, y + len)
	-- Bottom-left
	cl[5].From = Vector2.new(x, y + h); cl[5].To = Vector2.new(x + len, y + h)
	cl[6].From = Vector2.new(x, y + h); cl[6].To = Vector2.new(x, y + h - len)
	-- Bottom-right
	cl[7].From = Vector2.new(x + w, y + h); cl[7].To = Vector2.new(x + w - len, y + h)
	cl[8].From = Vector2.new(x + w, y + h); cl[8].To = Vector2.new(x + w, y + h - len)

	for i = 1, 8 do
		cl[i].Visible = true
		cl[i].Color = color
		cl[i].Thickness = t
	end
	for i = 9, #cl do cl[i].Visible = false end
end

function ESP:UpdateSkeleton(player, char)
	local d = self:GetData(player)
	if not ESP.Skeleton then
		for _, v in pairs(d.SkelParts) do pcall(v.Destroy, v) end
		d.SkelParts = {}
		return
	end
	local skel = d.SkelParts
	local active = {}
	local bones = {
		{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
		{ "UpperTorso", "LeftUpperArm" }, { "UpperTorso", "RightUpperArm" },
		{ "LowerTorso", "LeftUpperLeg" }, { "LowerTorso", "RightUpperLeg" },
		{ "LeftUpperArm", "LeftLowerArm" }, { "RightUpperArm", "RightLowerArm" },
		{ "LeftUpperLeg", "LeftLowerLeg" }, { "RightUpperLeg", "RightLowerLeg" },
	}
	local color = self:GetRainbowColor()
	for _, pair in ipairs(bones) do
		local p1 = char:FindFirstChild(pair[1])
		local p2 = char:FindFirstChild(pair[2])
		if p1 and p2 then
			local key = pair[1] .. "_" .. pair[2]
			active[key] = true
			local adj = skel[key]
			if not adj then
				adj = Instance.new("CylinderHandleAdornment")
				adj.Radius = 0.12
				adj.AlwaysOnTop = true
				adj.ZIndex = 20
				adj.Transparency = 0.3
				adj.Parent = char
				skel[key] = adj
			end
			adj.Color3 = color
			adj.Visible = true
			local mid = (p1.Position + p2.Position) / 2
			local dist = (p1.Position - p2.Position).Magnitude
			adj.Height = dist
			adj.CFrame = CFrame.lookAt(mid, p2.Position) * CFrame.new(0, 0, -dist / 2)
		end
	end
	for key, v in pairs(skel) do
		if not active[key] then v.Visible = false end
	end
end

function ESP:Update()
	local cam = GetCamera()
	if not cam then return end
	local vs = cam.ViewportSize

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then
			self:Clear(player)
			continue
		end
		if not self:IsEnemy(player) or not self:IsAlive(player) then
			self:Clear(player)
			continue
		end

		local char = player.Character
		if not char then self:Clear(player); continue end

		local xMin, yMin, xMax, yMax = self:GetBoundingBox(char)
		if not xMin then self:Clear(player); continue end
		local bw = xMax - xMin
		local bh = yMax - yMin
		if bw < 5 or bh < 5 then self:Clear(player); continue end

		local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		local dist = root and math.floor((cam.CFrame.Position - root.Position).Magnitude) or 0
		if dist > ESP.MaxDistance then self:Clear(player); continue end

		local color = self:GetRainbowColor()
		local d = self:GetData(player)

		self:UpdateSkeleton(player, char)

		if ESP.Boxes then
			if ESP.BoxStyle == "Corner" then
				d.Box.Visible = false
				d.BoxBg.Visible = false
				self:DrawCornerBox(d, xMin, yMin, bw, bh, color)
			else
				for _, cl in ipairs(d.CornerLines) do cl.Visible = false end
				d.Box.Visible = true
				d.Box.Size = Vector2.new(bw, bh)
				d.Box.Position = Vector2.new(xMin, yMin)
				d.Box.Color = color
				d.Box.Thickness = 1.5
				d.Box.Filled = false

				if ESP.BoxOutline then
					d.BoxBg.Visible = true
					d.BoxBg.Size = Vector2.new(bw + 4, bh + 4)
					d.BoxBg.Position = Vector2.new(xMin - 2, yMin - 2)
					d.BoxBg.Color = Color3.fromRGB(10, 10, 10)
					d.BoxBg.Thickness = 0
					d.BoxBg.Filled = true
					d.BoxBg.Transparency = 0.65
				else
					d.BoxBg.Visible = false
				end
			end
		else
			d.Box.Visible = false
			d.BoxBg.Visible = false
			for _, cl in ipairs(d.CornerLines) do cl.Visible = false end
		end

		if ESP.Tracers then
			d.Tracer.Visible = true
			local origin = vs.X / 2
			if ESP.TracerOrigin == "Bottom" then
				d.Tracer.From = Vector2.new(origin, vs.Y)
			elseif ESP.TracerOrigin == "Top" then
				d.Tracer.From = Vector2.new(origin, 0)
			elseif ESP.TracerOrigin == "Mouse" then
				d.Tracer.From = game:GetService("UserInputService"):GetMouseLocation()
			else
				d.Tracer.From = Vector2.new(origin, vs.Y / 2)
			end
			d.Tracer.To = Vector2.new(xMin + bw / 2, yMax)
			d.Tracer.Color = color
			d.Tracer.Thickness = 1.5
		else
			d.Tracer.Visible = false
		end

		if ESP.HealthBar then
			local hum = char:FindFirstChildWhichIsA("Humanoid")
			if hum then
				local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
				local hc = Color3.fromRGB(math.floor(255 * (1 - hp)), math.floor(255 * hp), 0)
				d.HealthBg.Visible = true
				d.HealthBg.Size = Vector2.new(4, bh)
				d.HealthBg.Position = Vector2.new(xMin - 8, yMin)
				d.HealthBg.Color = Color3.fromRGB(15, 15, 15)
				d.HealthBg.Filled = true
				d.HealthFill.Visible = true
				d.HealthFill.Size = Vector2.new(4, bh * hp)
				d.HealthFill.Position = Vector2.new(xMin - 8, yMin + bh * (1 - hp))
				d.HealthFill.Color = hc
				d.HealthFill.Filled = true

				if ESP.HealthStyle == "Text" or ESP.HealthStyle == "Both" then
					d.HealthText.Visible = true
					d.HealthText.Position = Vector2.new(xMin - 12, yMin + bh / 2)
					d.HealthText.Text = math.floor(hum.Health) .. "HP"
					d.HealthText.Color = hc
					d.HealthText.Size = 11
					d.HealthText.Center = false
				else
					d.HealthText.Visible = false
				end
			end
		else
			d.HealthBg.Visible = false
			d.HealthFill.Visible = false
			d.HealthText.Visible = false
		end

		if ESP.Names then
			d.NameLbl.Visible = true
			d.NameLbl.Position = Vector2.new(xMin + bw / 2, yMin - 16)
			d.NameLbl.Text = player.Name
			d.NameLbl.Color = color
			d.NameLbl.Size = ESP.TextSize
			d.NameLbl.Center = true
			d.NameLbl.Outline = true
		else
			d.NameLbl.Visible = false
		end

		if ESP.Distance then
			d.DistLbl.Visible = true
			d.DistLbl.Position = Vector2.new(xMin + bw / 2, yMax + 2)
			d.DistLbl.Text = tostring(dist) .. "m"
			d.DistLbl.Color = Color3.fromRGB(200, 200, 200)
			d.DistLbl.Size = ESP.TextSize - 2
			d.DistLbl.Center = true
			d.DistLbl.Outline = true
		else
			d.DistLbl.Visible = false
		end

		if ESP.Chams then
			local hl = self.Highlights[player]
			if not hl and char then
				hl = Instance.new("Highlight")
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Parent = char
				self.Highlights[player] = hl
			end
			if hl and char then
				hl.Parent = char
				hl.FillColor = ESP.ChamsFillColor
				hl.OutlineColor = ESP.ChamsOutlineColor
				hl.FillTransparency = ESP.ChamsFillTransparency
				hl.OutlineTransparency = 0
				hl.Enabled = true
			end
		else
			local hl = self.Highlights[player]
			if hl then
				hl:Destroy()
				self.Highlights[player] = nil
			end
		end
	end
end

function ESP:BuildUI(tab)
	local g = tab:AddLeftGroupbox("ESP")
	g:AddToggle("ESP_Master", { Text = "ESP", Default = false })
	Toggles.ESP_Master:OnChanged(function() ESP.Enabled = Toggles.ESP_Master.Value end)
	g:AddToggle("ESP_Boxes", { Text = "Boxes", Default = true })
	Toggles.ESP_Boxes:OnChanged(function() ESP.Boxes = Toggles.ESP_Boxes.Value end)
	g:AddDropdown("ESP_BoxStyle", { Text = "Box Style", Default = 1, Values = { "Full", "Corner" } })
	Options.ESP_BoxStyle:OnChanged(function() ESP.BoxStyle = Options.ESP_BoxStyle.Value end)
	g:AddToggle("ESP_BoxOutline", { Text = "Box Background", Default = true })
	Toggles.ESP_BoxOutline:OnChanged(function() ESP.BoxOutline = Toggles.ESP_BoxOutline.Value end)
	g:AddToggle("ESP_Tracers", { Text = "Tracers", Default = false })
	Toggles.ESP_Tracers:OnChanged(function() ESP.Tracers = Toggles.ESP_Tracers.Value end)
	g:AddDropdown("ESP_TracerOrigin", { Text = "Tracer Origin", Default = 1, Values = { "Bottom", "Top", "Mouse", "Center" } })
	Options.ESP_TracerOrigin:OnChanged(function() ESP.TracerOrigin = Options.ESP_TracerOrigin.Value end)
	g:AddToggle("ESP_HealthBar", { Text = "Health Bar", Default = true })
	Toggles.ESP_HealthBar:OnChanged(function() ESP.HealthBar = Toggles.ESP_HealthBar.Value end)
	g:AddDropdown("ESP_HealthStyle", { Text = "Health Style", Default = 1, Values = { "Bar", "Text", "Both" } })
	Options.ESP_HealthStyle:OnChanged(function() ESP.HealthStyle = Options.ESP_HealthStyle.Value end)
	g:AddToggle("ESP_Skeleton", { Text = "Skeleton", Default = false })
	Toggles.ESP_Skeleton:OnChanged(function() ESP.Skeleton = Toggles.ESP_Skeleton.Value end)
	g:AddToggle("ESP_Names", { Text = "Names", Default = true })
	Toggles.ESP_Names:OnChanged(function() ESP.Names = Toggles.ESP_Names.Value end)
	g:AddToggle("ESP_Distance", { Text = "Distance", Default = true })
	Toggles.ESP_Distance:OnChanged(function() ESP.Distance = Toggles.ESP_Distance.Value end)
	g:AddToggle("ESP_TeamCheck", { Text = "Team Check", Default = true })
	Toggles.ESP_TeamCheck:OnChanged(function() ESP.TeamCheck = Toggles.ESP_TeamCheck.Value end)
	g:AddToggle("ESP_ShowTeam", { Text = "Show Team", Default = false })
	Toggles.ESP_ShowTeam:OnChanged(function() ESP.ShowTeam = Toggles.ESP_ShowTeam.Value end)
	g:AddSlider("ESP_TextSize", { Text = "Text Size", Default = 14, Min = 10, Max = 24, Rounding = 0 })
	Options.ESP_TextSize:OnChanged(function() ESP.TextSize = Options.ESP_TextSize.Value end)
	g:AddSlider("ESP_MaxDistance", { Text = "Max Distance", Default = 5000, Min = 100, Max = 10000, Rounding = 0, Suffix = " studs" })
	Options.ESP_MaxDistance:OnChanged(function() ESP.MaxDistance = Options.ESP_MaxDistance.Value end)
	g:AddLabel("Color"):AddColorPicker("ESP_Color", { Default = ESP.Color })
	Options.ESP_Color:OnChanged(function() ESP.Color = Options.ESP_Color.Value end)
	g:AddToggle("ESP_Rainbow", { Text = "Rainbow Mode", Default = false })
	Toggles.ESP_Rainbow:OnChanged(function() ESP.Rainbow = Toggles.ESP_Rainbow.Value end)
	g:AddSlider("ESP_RainbowSpeed", { Text = "Rainbow Speed", Default = 1, Min = 0.1, Max = 5, Rounding = 1 })
	Options.ESP_RainbowSpeed:OnChanged(function() ESP.RainbowSpeed = Options.ESP_RainbowSpeed.Value end)

	local ChamsGroup = tab:AddRightGroupbox("Chams")
	ChamsGroup:AddToggle("ESP_Chams", { Text = "Chams", Default = false })
	Toggles.ESP_Chams:OnChanged(function() ESP.Chams = Toggles.ESP_Chams.Value end)
	ChamsGroup:AddLabel("Fill Color"):AddColorPicker("ESP_ChamsFill", { Default = ESP.ChamsFillColor })
	Options.ESP_ChamsFill:OnChanged(function() ESP.ChamsFillColor = Options.ESP_ChamsFill.Value end)
	ChamsGroup:AddLabel("Outline Color"):AddColorPicker("ESP_ChamsOutline", { Default = ESP.ChamsOutlineColor })
	Options.ESP_ChamsOutline:OnChanged(function() ESP.ChamsOutlineColor = Options.ESP_ChamsOutline.Value end)
	ChamsGroup:AddSlider("ESP_ChamsTransparency", { Text = "Fill Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 2 })
	Options.ESP_ChamsTransparency:OnChanged(function() ESP.ChamsFillTransparency = Options.ESP_ChamsTransparency.Value end)
end

function ESP:Init()
	local conn = RunService.RenderStepped:Connect(function()
		if not ESP.Enabled then
			for p, d in pairs(ESP.PlayerData) do
				for _, v in pairs(d) do
					if typeof(v) == "Drawing" then v.Visible = false end
				end
				for _, v in pairs(d.CornerLines) do v.Visible = false end
				for _, v in pairs(d.SkelParts) do v.Visible = false end
			end
			for _, hl in pairs(ESP.Highlights) do hl.Enabled = false end
			return
		end
		ESP:Update()
	end)
	table.insert(self.Connections, conn)
end

function ESP:Cleanup()
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	self.Connections = {}
	for p, d in pairs(self.PlayerData) do
		for _, v in pairs(d) do
			if typeof(v) == "Drawing" then pcall(v.Remove, v) end
		end
		for _, v in pairs(d.CornerLines) do pcall(v.Remove, v) end
		for _, v in pairs(d.SkelParts) do pcall(v.Destroy, v) end
	end
	self.PlayerData = {}
	for _, hl in pairs(self.Highlights) do hl:Destroy() end
	self.Highlights = {}
end

return ESP
