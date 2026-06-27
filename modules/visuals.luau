local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = game:GetService("Players").LocalPlayer

local Visuals = {
	AntiSmoke = false,
	AntiKatana = false,
	CharTransparency = 0,
	Skybox = "Default",
	Fullbright = false,
	Connections = {},
}

function Visuals:SetupAntiSmoke()
	local conn
	conn = Workspace.DescendantAdded:Connect(function(descendant)
		if not Visuals.AntiSmoke then
			return
		end
		if descendant:IsA("Part") or descendant:IsA("UnionOperation") then
			task.wait(0.1)
			if descendant.Transparency < 0.5 then
				descendant.Transparency = 1
			end
		end
	end)
	table.insert(Visuals.Connections, conn)

	local cleanupConn = Workspace.DescendantRemoving:Connect(function() end)
	table.insert(Visuals.Connections, cleanupConn)
end

function Visuals:ApplyAntiSmoke()
	if not Visuals.AntiSmoke then
		return
	end
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Part") or descendant:IsA("UnionOperation") then
			if descendant.Transparency < 0.5 and descendant.Name:lower():find("smoke") then
				descendant.Transparency = 1
			end
		end
	end
end

function Visuals:ApplyCharTransparency()
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local trans = Visuals.CharTransparency
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = trans
		end
	end
end

function Visuals:ApplySkybox()
	local skyboxMap = {
		Default = nil,
		Night = { 165038004, 165038010, 165038019, 165038024, 165038033, 165038043 },
		Sunset = { 165038060, 165038068, 165038076, 165038089, 165038099, 165038109 },
		Blood = { 165038115, 165038123, 165038135, 165038148, 165038158, 165038166 },
		Storm = { 165038175, 165038186, 165038196, 165038204, 165038213, 165038222 },
		Dark = { 165038229, 165038237, 165038247, 165038254, 165038262, 165038270 },
		Neon = { 165038280, 165038290, 165038299, 165038308, 165038318, 165038327 },
		Cloudy = { 165038336, 165038345, 165038354, 165038362, 165038370, 165038378 },
	}

	-- Remove existing sky
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") then
			child:Destroy()
		end
	end

	local ids = skyboxMap[Visuals.Skybox]
	if ids then
		local sky = Instance.new("Sky")
		sky.SkyboxBk = "rbxassetid://" .. ids[1]
		sky.SkyboxDn = "rbxassetid://" .. ids[2]
		sky.SkyboxFt = "rbxassetid://" .. ids[3]
		sky.SkyboxLf = "rbxassetid://" .. ids[4]
		sky.SkyboxRt = "rbxassetid://" .. ids[5]
		sky.SkyboxUp = "rbxassetid://" .. ids[6]
		sky.Parent = Lighting
	end
end

function Visuals:ApplyFullbright()
	if Visuals.Fullbright then
		Lighting.Brightness = 2
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
	else
		Lighting.Brightness = 1
		Lighting.GlobalShadows = true
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.Ambient = Color3.fromRGB(128, 128, 128)
	end
end

function Visuals:BuildUI(Tab)
	local WorldGroup = Tab:AddRightGroupbox("World")
	WorldGroup:AddToggle("Visuals_AntiSmoke", {
		Text = "Anti-Smoke",
		Default = false,
		Tooltip = "Removes smoke effects"
	})
	Toggles.Visuals_AntiSmoke:OnChanged(function()
		Visuals.AntiSmoke = Toggles.Visuals_AntiSmoke.Value
		Visuals:ApplyAntiSmoke()
	end)

	WorldGroup:AddToggle("Visuals_AntiKatana", {
		Text = "Anti-Katana",
		Default = false,
		Tooltip = "Remove katana block visual"
	})

	WorldGroup:AddSlider("Visuals_CharTransparency", {
		Text = "Character Transparency",
		Default = 0,
		Min = 0,
		Max = 1,
		Rounding = 2,
		Tooltip = "Make your character see-through"
	})
	Options.Visuals_CharTransparency:OnChanged(function()
		Visuals.CharTransparency = Options.Visuals_CharTransparency.Value
		Visuals:ApplyCharTransparency()
	end)

	WorldGroup:AddToggle("Visuals_Fullbright", {
		Text = "Fullbright",
		Default = false,
		Tooltip = "Maximum brightness"
	})
	Toggles.Visuals_Fullbright:OnChanged(function()
		Visuals.Fullbright = Toggles.Visuals_Fullbright.Value
		Visuals:ApplyFullbright()
	end)

	WorldGroup:AddDropdown("Visuals_Skybox", {
		Text = "Skybox",
		Default = 1,
		Values = { "Default", "Night", "Sunset", "Blood", "Storm", "Dark", "Neon", "Cloudy" },
		Tooltip = "Change the sky"
	})
	Options.Visuals_Skybox:OnChanged(function()
		Visuals.Skybox = Options.Visuals_Skybox.Value
		Visuals:ApplySkybox()
	end)
end

function Visuals:Init()
	self:SetupAntiSmoke()
end

function Visuals:Cleanup()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
end

return Visuals
