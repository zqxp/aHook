local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local SkinChanger = {
	Enabled = false,
	CurrentWeapon = nil,
	CurrentSkin = nil,
	CurrentMaterial = "ForceField",
	CurrentTransparency = 0,
	CurrentPattern = "None",
	ApplyToAll = false,
	MaterialMap = {},
	IconReplacements = {},
	ViewModels = {},
	Connections = {}
}

local MaterialColors = {
	ForceField = Color3.fromRGB(150, 150, 255),
	Neon = Color3.fromRGB(255, 100, 200),
	Foil = Color3.fromRGB(200, 200, 100),
	Metal = Color3.fromRGB(180, 180, 180),
	Glass = Color3.fromRGB(200, 220, 255),
	Ice = Color3.fromRGB(200, 230, 255),
	DiamondPlate = Color3.fromRGB(200, 200, 220),
	Cobblestone = Color3.fromRGB(140, 130, 120),
	Granite = Color3.fromRGB(130, 130, 140),
	Brick = Color3.fromRGB(180, 100, 80),
	Wood = Color3.fromRGB(160, 130, 90),
	WoodPlanks = Color3.fromRGB(170, 140, 100),
	Marble = Color3.fromRGB(200, 195, 190),
	Limestone = Color3.fromRGB(190, 185, 170),
	Concrete = Color3.fromRGB(160, 160, 160),
	Slate = Color3.fromRGB(110, 110, 120),
	Sandstone = Color3.fromRGB(190, 175, 140),
	Plastic = Color3.fromRGB(180, 180, 200),
	SmoothPlastic = Color3.fromRGB(190, 190, 210),
	CorrodedMetal = Color3.fromRGB(140, 120, 100),
	Diamond = Color3.fromRGB(200, 220, 255),
}

function SkinChanger:GetViewModels()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return {}
	end
	local assets = playerGui:FindFirstChild("Assets")
	if not assets then
		return {}
	end
	local viewModels = assets:FindFirstChild("ViewModels")
	if not viewModels then
		return {}
	end

	local result = {}
	for _, child in ipairs(viewModels:GetChildren()) do
		if child:IsA("Model") or child:IsA("Tool") or child:IsA("Part") then
			table.insert(result, child)
		end
	end
	return result
end

function SkinChanger:ApplySkin(weaponName, skinName)
	local weaponData = Data and Data.Weapons[weaponName]
	if not weaponData then
		return
	end

	local skinData = weaponData.Skins[skinName]
	if not skinData then
		return
	end

	self.CurrentWeapon = weaponName
	self.CurrentSkin = skinName

	local viewModels = self:GetViewModels()
	for _, vm in ipairs(viewModels) do
		if vm.Name:lower():find(weaponName:lower()) then
			self:ApplyToViewModel(vm, skinData)
		end
	end

	self:ReplaceIcons(weaponName, skinData.Id)
end

function SkinChanger:ApplyToViewModel(viewModel, skinData)
	local material = Enum.Material[self.CurrentMaterial] or Enum.Material.ForceField

	for _, part in ipairs(viewModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Material = material
			part.Transparency = self.CurrentTransparency
			if MaterialColors[self.CurrentMaterial] then
				part.Color = MaterialColors[self.CurrentMaterial]
			end
		end
	end
end

function SkinChanger:ReplaceIcons(weaponName, skinId)
	for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
		if gui:IsA("ScreenGui") or gui:IsA("SurfaceGui") then
			for _, child in ipairs(gui:GetDescendants()) do
				if child:IsA("ImageLabel") or child:IsA("ImageButton") then
					if child.Name:lower():find(weaponName:lower()) or child.Name:lower():find("icon") then
						if not self.IconReplacements[child] then
							self.IconReplacements[child] = child.Image
						end
						child.Image = "rbxassetid://" .. skinId
					end
				end
			end
		end
	end
end

function SkinChanger:ResetIcons()
	for gui, original in pairs(self.IconReplacements) do
		gui.Image = original
	end
	self.IconReplacements = {}
end

function SkinChanger:BuildUI(Tab)
	local WeaponGroup = Tab:AddLeftGroupbox("Weapons")
	WeaponGroup:AddDropdown("Skin_Weapon", {
		Text = "Select Weapon",
		Default = 1,
		Values = Data and Data:GetWeaponNames() or {},
		Tooltip = "Choose a weapon to customize"
	})

	local SkinGroup = Tab:AddRightGroupbox("Customize")
	SkinGroup:AddDropdown("Skin_Select", {
		Text = "Skin",
		Default = 1,
		Values = {},
		Tooltip = "Choose a skin for this weapon"
	})

	SkinGroup:AddDropdown("Skin_Material", {
		Text = "Material",
		Default = 1,
		Values = Data and Data.Materials or {},
		Tooltip = "Change weapon material"
	})
	Options.Skin_Material:OnChanged(function()
		SkinChanger.CurrentMaterial = Options.Skin_Material.Value
	end)

	SkinGroup:AddSlider("Skin_Transparency", {
		Text = "Transparency",
		Default = 0,
		Min = 0,
		Max = 1,
		Rounding = 2,
		Tooltip = "Weapon transparency"
	})
	Options.Skin_Transparency:OnChanged(function()
		SkinChanger.CurrentTransparency = Options.Skin_Transparency.Value
	end)

	SkinGroup:AddToggle("Skin_ApplyToAll", {
		Text = "Apply to All",
		Default = false,
		Tooltip = "Apply this skin to all weapons"
	})

	SkinGroup:AddButton("Apply Skin", function()
		local weapon = Options.Skin_Weapon.Value
		local skin = Options.Skin_Select.Value
		if weapon and skin then
			SkinChanger:ApplySkin(weapon, skin)
		end
	end)

	SkinGroup:AddButton("Reset to Default", function()
		SkinChanger:ResetIcons()
	end)

	Options.Skin_Weapon:OnChanged(function()
		local weapon = Options.Skin_Weapon.Value
		local data = Data
		local skinNames = data:GetSkinNames(weapon)
		Options.Skin_Select:SetValues(skinNames)
		if #skinNames > 0 then
			Options.Skin_Select:SetValue(skinNames[1])
		end
	end)
end

function SkinChanger:Init()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not SkinChanger.Enabled then
			return
		end
		if SkinChanger.CurrentWeapon and SkinChanger.CurrentSkin then
			SkinChanger:ApplySkin(SkinChanger.CurrentWeapon, SkinChanger.CurrentSkin)
		end
	end)
	table.insert(self.Connections, conn)
end

function SkinChanger:Cleanup()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
	self:ResetIcons()
end

return SkinChanger
