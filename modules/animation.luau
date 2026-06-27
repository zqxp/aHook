local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Animation = {
	Overrides = {},
	Hooks = {}
}

function Animation:GetAnimator()
	local char = LocalPlayer.Character
	if char then
		return char:FindFirstChildWhichIsA("Animator")
	end
	return nil
end

function Animation:OverrideAnimation(id, newId)
	self.Overrides[id] = newId
end

function Animation:RemoveOverride(id)
	self.Overrides[id] = nil
end

function Animation:ClearOverrides()
	self.Overrides = {}
end

function Animation:SetupHook()
	if self.Hooks.Active then
		return
	end

	local animator = self:GetAnimator()
	if not animator then
		local char = LocalPlayer.CharacterAdded:Connect(function()
			task.wait(0.5)
			self:SetupHook()
		end)
		table.insert(self.Hooks, char)
		return
	end

	local conn
	conn = animator.AnimationPlayed:Connect(function(track)
		local anim = track.Animation
		if anim and anim.AnimationId then
			local newId = self.Overrides[anim.AnimationId]
			if newId then
				track:Stop()
				local newAnim = Instance.new("Animation")
				newAnim.AnimationId = newId
				animator:LoadAnimation(newAnim):Play()
			end
		end
	end)
	table.insert(self.Hooks, conn)
	self.Hooks.Active = true
end

function Animation:SetupCharacterWatcher()
	local conn
	conn = LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		self.Hooks.Active = false
		self:SetupHook()
	end)
	table.insert(self.Hooks, conn)
end

function Animation:Cleanup()
	for _, conn in ipairs(self.Hooks) do
		if type(conn) == "function" then
			conn:Disconnect()
		end
	end
	self.Hooks = {}
	self.Hooks.Active = false
end

return Animation
