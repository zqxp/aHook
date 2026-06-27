local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Animation = {
	NoAnimation = false,
	AnimSpeed = 0,
	AntiAnimation = false,
	CustomIdle = false,
	CustomWalk = false,
	DisableArms = false,
	NoWeaponSway = false,
	NoBob = false,
	Hooked = false,
	Connections = {},
	OldAnimate = nil,
}

function Animation:SetupHook()
	if Animation.Hooked then return end
	if not LocalPlayer.Character then
		LocalPlayer.CharacterAdded:Connect(function() Animation:SetupHook() end)
		return
	end
	local char = LocalPlayer.Character
	local animate = char:FindFirstChild("Animate")
	if not animate then
		local waitChar = LocalPlayer.CharacterAdded:Wait()
		animate = waitChar:FindFirstChild("Animate")
	end
	if animate and animate:IsA("LocalScript") then
		Animation.Hooked = true
		Animation.OldAnimate = animate
	end
end

function Animation:SetupCharacterWatcher()
	local conn = RunService.Heartbeat:Connect(function()
		if not Animation.NoAnimation or not LocalPlayer.Character then return end
		local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			local states = {
				Enum.HumanoidStateType.Running,
				Enum.HumanoidStateType.Climbing,
				Enum.HumanoidStateType.Swimming,
				Enum.HumanoidStateType.Freefall,
				Enum.HumanoidStateType.Jumping,
			}
			for _, state in ipairs(states) do
				if humanoid:GetState() == state then
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					break
				end
			end
		end
	end)
	table.insert(Animation.Connections, conn)
end

function Animation:BuildUI(Tab)
	local AG = Tab:AddLeftGroupbox("Animation")
	AG:AddToggle("Animation_NoAnimation", { Text = "No Animation", Default = false })
	Toggles.Animation_NoAnimation:OnChanged(function() Animation.NoAnimation = Toggles.Animation_NoAnimation.Value end)
	AG:AddToggle("Animation_AntiAnimation", { Text = "Anti-Animations", Default = false })
	Toggles.Animation_AntiAnimation:OnChanged(function() Animation.AntiAnimation = Toggles.Animation_AntiAnimation.Value end)
	AG:AddToggle("Animation_DisableArms", { Text = "Disable Arms", Default = false })
	Toggles.Animation_DisableArms:OnChanged(function() Animation.DisableArms = Toggles.Animation_DisableArms.Value end)
	AG:AddToggle("Animation_NoSway", { Text = "No Weapon Sway", Default = false })
	Toggles.Animation_NoSway:OnChanged(function() Animation.NoWeaponSway = Toggles.Animation_NoSway.Value end)
	AG:AddToggle("Animation_NoBob", { Text = "No Weapon Bob", Default = false })
	Toggles.Animation_NoBob:OnChanged(function() Animation.NoBob = Toggles.Animation_NoBob.Value end)
end

function Animation:Init()
	self:SetupHook()
	self:SetupCharacterWatcher()
end

function Animation:Cleanup()
	for _, c in ipairs(self.Connections) do c:Disconnect() end
	self.Connections = {}
end

return Animation
