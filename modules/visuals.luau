local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Visuals = {
	Fullbright = false,
	FullbrightMode = "Lighting",
	AntiSmoke = false,
	ClearSky = false,
	FOVChanger = false,
	FOVAmount = 90,
	AmbientColor = Color3.fromRGB(255, 255, 255),
	FogColor = nil,
	FogEnd = nil,
	NoFog = false,
	Crosshair = false,
	CrosshairColor = Color3.fromRGB(255, 255, 255),
	CrosshairSize = 12,
	CrosshairGap = 4,
	CrosshairThickness = 2,
	Watermark = false,
	WatermarkText = "aHook",
	Connections = {},
	CrosshairDraw = nil,
	WatermarkTextObj = nil,
}

function Visuals:SetupFullbright()
	if Visuals.Fullbright then
		if Visuals.FullbrightMode == "Lighting" then
			Lighting.Ambient = Color3.fromRGB(255, 255, 255)
			Lighting.Brightness = 2
			Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
			Lighting.GlobalShadows = false
			Lighting.ShadowSoftness = 0
		elseif Visuals.FullbrightMode == "Override" then
			Lighting.Ambient = Visuals.AmbientColor
			Lighting.Brightness = 2
			Lighting.OutdoorAmbient = Visuals.AmbientColor
			Lighting.GlobalShadows = false
		end
	else
		Lighting.Ambient = Color3.fromRGB(0, 0, 0)
		Lighting.Brightness = 1
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.GlobalShadows = true
	end
end

function Visuals:SetupFOV()
	local conn = RunService.RenderStepped:Connect(function()
		if not Visuals.FOVChanger then return end
		local cam = Workspace.CurrentCamera
		if cam then
			cam.FieldOfView = Visuals.FOVAmount
		end
	end)
	table.insert(Visuals.Connections, conn)
end

function Visuals:SetupNoFog()
	if Visuals.NoFog then
		Lighting.FogEnd = 1e9
		Lighting.FogStart = 0
	else
		Lighting.FogEnd = Visuals.FogEnd or 100000
		Lighting.FogStart = 0
	end
end

function Visuals:SetupCrosshair()
	if Visuals.CrosshairDraw then
		Visuals.CrosshairDraw:Remove()
		Visuals.CrosshairDraw = nil
	end
	if not Visuals.Crosshair then return end
	local d = Drawing.new("Circle")
	d.Visible = true
	d.Filled = false
	d.Thickness = Visuals.CrosshairThickness
	d.Color = Visuals.CrosshairColor
	d.Radius = Visuals.CrosshairSize
	d.NumSides = 32
	Visuals.CrosshairDraw = d

	local conn = RunService.RenderStepped:Connect(function()
		if not Visuals.Crosshair or not d then
			if d then d.Visible = false end
			return
		end
		local cam = Workspace.CurrentCamera
		local vs = cam and cam.ViewportSize
		if vs then
			d.Position = Vector2.new(vs.X / 2, vs.Y / 2)
			d.Radius = Visuals.CrosshairSize
			d.Thickness = Visuals.CrosshairThickness
			d.Color = Visuals.CrosshairColor
			d.Visible = true
		end
	end)
	table.insert(Visuals.Connections, conn)
end

function Visuals:SetupAntiSmoke()
	if Visuals.AntiSmoke then
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then
				v.Enabled = false
			end
		end
	end
end

function Visuals:BuildUI(Tab)
	local VG = Tab:AddLeftGroupbox("Visuals")
	VG:AddToggle("Visuals_Fullbright", { Text = "Fullbright", Default = false })
	Toggles.Visuals_Fullbright:OnChanged(function() Visuals.Fullbright = Toggles.Visuals_Fullbright.Value; Visuals:SetupFullbright() end)
	VG:AddDropdown("Visuals_FullbrightMode", { Text = "Fullbright Mode", Default = 1, Values = { "Lighting", "Override" } })
	Options.Visuals_FullbrightMode:OnChanged(function() Visuals.FullbrightMode = Options.Visuals_FullbrightMode.Value; Visuals:SetupFullbright() end)
	VG:AddLabel("Ambient Color"):AddColorPicker("Visuals_Ambient", { Default = Visuals.AmbientColor })
	Options.Visuals_Ambient:OnChanged(function() Visuals.AmbientColor = Options.Visuals_Ambient.Value end)
	VG:AddToggle("Visuals_AntiSmoke", { Text = "Anti-Smoke", Default = false })
	Toggles.Visuals_AntiSmoke:OnChanged(function() Visuals.AntiSmoke = Toggles.Visuals_AntiSmoke.Value; Visuals:SetupAntiSmoke() end)
	VG:AddToggle("Visuals_NoFog", { Text = "No Fog", Default = false })
	Toggles.Visuals_NoFog:OnChanged(function() Visuals.NoFog = Toggles.Visuals_NoFog.Value; Visuals:SetupNoFog() end)
	VG:AddToggle("Visuals_FOVChanger", { Text = "FOV Changer", Default = false })
	Toggles.Visuals_FOVChanger:OnChanged(function() Visuals.FOVChanger = Toggles.Visuals_FOVChanger.Value end)
	VG:AddSlider("Visuals_FOVAmount", { Text = "FOV Amount", Default = 90, Min = 30, Max = 120, Rounding = 0, Suffix = " deg" })
	Options.Visuals_FOVAmount:OnChanged(function() Visuals.FOVAmount = Options.Visuals_FOVAmount.Value end)

	local XG = Tab:AddRightGroupbox("Crosshair")
	XG:AddToggle("Visuals_Crosshair", { Text = "Custom Crosshair", Default = false })
	Toggles.Visuals_Crosshair:OnChanged(function() Visuals.Crosshair = Toggles.Visuals_Crosshair.Value; Visuals:SetupCrosshair() end)
	XG:AddLabel("Color"):AddColorPicker("Visuals_CrosshairColor", { Default = Visuals.CrosshairColor })
	Options.Visuals_CrosshairColor:OnChanged(function() Visuals.CrosshairColor = Options.Visuals_CrosshairColor.Value end)
	XG:AddSlider("Visuals_CrosshairSize", { Text = "Size", Default = 12, Min = 2, Max = 50, Rounding = 0 })
	Options.Visuals_CrosshairSize:OnChanged(function() Visuals.CrosshairSize = Options.Visuals_CrosshairSize.Value end)
	XG:AddSlider("Visuals_CrosshairThickness", { Text = "Thickness", Default = 2, Min = 1, Max = 10, Rounding = 0 })
	Options.Visuals_CrosshairThickness:OnChanged(function() Visuals.CrosshairThickness = Options.Visuals_CrosshairThickness.Value end)
end

function Visuals:Init()
	self:SetupFullbright()
	self:SetupFOV()
	self:SetupNoFog()
	self:SetupCrosshair()
end

function Visuals:Cleanup()
	if Visuals.CrosshairDraw then
		Visuals.CrosshairDraw:Remove()
		Visuals.CrosshairDraw = nil
	end
	self:SetupFullbright()
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	self.Connections = {}
end

return Visuals
