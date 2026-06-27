local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local SkinChanger = {
	Enabled = false,
	CurrentWeapon = nil,
	CurrentSkin = nil,
	Skins = {},
	WeaponSkins = {},
	MaterialOptions = { "Plastic", "Metal", "Neon", "Ice", "Glow" },
	CurrentMaterial = "Plastic",
	CustomColor = Color3.fromRGB(255, 255, 255),
	CustomTransparency = 0,
	ApplyToAll = false,
	AutoApply = false,
	Connections = {},
}

local function GetWeaponModel(weapon)
	if not weapon then return nil end
	local handle = weapon:FindFirstChild("Handle")
	if handle then return handle end
	for _, v in ipairs(weapon:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			return v
		end
	end
	return weapon.PrimaryPart
end

local MaterialMap = {
	Plastic = Enum.Material.Plastic,
	Metal = Enum.Material.Metal,
	Neon = Enum.Material.Neon,
	Ice = Enum.Material.Ice,
	Glow = Enum.Material.ForceField,
}

function SkinChanger:GetWeapon()
	local char = LocalPlayer.Character
	if not char then return nil end
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		self.CurrentWeapon = tool
		return tool
	end
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Tool") then
			self.CurrentWeapon = v
			return v
		end
	end
	return nil
end

function SkinChanger:ApplySkin(weapon, skinData)
	if not weapon then weapon = self:GetWeapon() end
	if not weapon then return end
	local model = GetWeaponModel(weapon)
	if not model then return end

	local color = skinData and skinData.Color or self.CustomColor
	local material = skinData and skinData.Material or self.CurrentMaterial
	local transparency = skinData and skinData.Transparency or self.CustomTransparency

	model.Color = color
	model.Material = MaterialMap[material] or Enum.Material.Plastic
	model.Transparency = transparency
	model.Reflectance = material == "Metal" and 0.5 or 0

	for _, v in ipairs(weapon:GetDescendants()) do
		if v:IsA("BasePart") and v ~= model then
			v.Color = color
			if material == "Neon" or material == "Ice" or material == "Glow" then
				v.Material = MaterialMap[material]
			end
			if self.ApplyToAll then
				v.Transparency = transparency
			end
		end
		if v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = math.min(1, transparency + 0.5)
		end
	end

	self.CurrentSkin = self.CurrentWeapon and self.CurrentWeapon.Name
end

function SkinChanger:SetupWatcher()
	local conn = RunService.RenderStepped:Connect(function()
		if not SkinChanger.Enabled then return end
		local weapon = SkinChanger:GetWeapon()
		if weapon and weapon ~= SkinChanger.CurrentWeapon then
			SkinChanger.CurrentWeapon = weapon
			if SkinChanger.AutoApply then
				SkinChanger:ApplySkin(weapon)
			end
		end
		if weapon and SkinChanger.AutoApply then
			SkinChanger:ApplySkin(weapon)
		end
	end)
	table.insert(SkinChanger.Connections, conn)
end

function SkinChanger:BuildUI(Tab)
	local SG = Tab:AddLeftGroupbox("Skin Changer")
	SG:AddToggle("SkinChanger_Enabled", { Text = "Skin Changer", Default = false })
	Toggles.SkinChanger_Enabled:OnChanged(function() SkinChanger.Enabled = Toggles.SkinChanger_Enabled.Value end)
	SG:AddToggle("SkinChanger_AutoApply", { Text = "Auto Apply", Default = false })
	Toggles.SkinChanger_AutoApply:OnChanged(function() SkinChanger.AutoApply = Toggles.SkinChanger_AutoApply.Value end)
	SG:AddToggle("SkinChanger_ApplyAll", { Text = "Apply To All Parts", Default = false })
	Toggles.SkinChanger_ApplyAll:OnChanged(function() SkinChanger.ApplyToAll = Toggles.SkinChanger_ApplyAll.Value end)
	SG:AddLabel("Color"):AddColorPicker("SkinChanger_Color", { Default = SkinChanger.CustomColor })
	Options.SkinChanger_Color:OnChanged(function() SkinChanger.CustomColor = Options.SkinChanger_Color.Value end)
	SG:AddDropdown("SkinChanger_Material", { Text = "Material", Default = 1, Values = SkinChanger.MaterialOptions })
	Options.SkinChanger_Material:OnChanged(function() SkinChanger.CurrentMaterial = Options.SkinChanger_Material.Value end)
	SG:AddSlider("SkinChanger_Transparency", { Text = "Transparency", Default = 0, Min = 0, Max = 1, Rounding = 2 })
	Options.SkinChanger_Transparency:OnChanged(function() SkinChanger.CustomTransparency = Options.SkinChanger_Transparency.Value end)
	SG:AddButton("Apply Now", function()
		SkinChanger:ApplySkin()
	end)
end

function SkinChanger:Init()
	self:SetupWatcher()
end

function SkinChanger:Cleanup()
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	self.Connections = {}
end

return SkinChanger
