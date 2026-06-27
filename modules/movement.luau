local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Movement = {
	Fly = false,
	Speed = false,
	SpeedAmount = 50,
	NoClip = false,
	InfiniteJump = false,
	BunnyHop = false,
	DoubleTap = false,
	DoubleTapSpeed = 100,
	JumpPower = false,
	JumpPowerAmount = 100,
	CFrameWalk = false,
	CFrameWalkSpeed = 1.5,
	FlySpeed = 50,
	FlyVerticalSpeed = 30,
	Connections = {},
	Flying = false,
	BodyVelocity = nil,
	BodyGyro = nil,
}

function Movement:SetupFly()
	for _, v in ipairs(Movement.Connections) do
		if v.Name == "Fly" then v:Disconnect() end
	end
	if self.BodyVelocity then self.BodyVelocity:Destroy(); self.BodyVelocity = nil end
	if self.BodyGyro then self.BodyGyro:Destroy(); self.BodyGyro = nil end

	if not Movement.Fly then
		self.Flying = false
		return
	end

	local conn = RunService.RenderStepped:Connect(function()
		if not Movement.Fly or not LocalPlayer.Character then
			if self.BodyVelocity then self.BodyVelocity:Destroy(); self.BodyVelocity = nil end
			if self.BodyGyro then self.BodyGyro:Destroy(); self.BodyGyro = nil end
			self.Flying = false
			return
		end
		local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		if not root or not hum then return end

		if not self.BodyVelocity then
			self.BodyVelocity = Instance.new("BodyVelocity")
			self.BodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			self.BodyVelocity.P = 1e5
			self.BodyVelocity.Parent = root
		end
		if not self.BodyGyro then
			self.BodyGyro = Instance.new("BodyGyro")
			self.BodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
			self.BodyGyro.P = 1e5
			self.BodyGyro.Parent = root
		end

		hum.PlatformStand = true
		self.Flying = true

		local moveDir = Vector3.new()
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Workspace.CurrentCamera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Workspace.CurrentCamera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Workspace.CurrentCamera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Workspace.CurrentCamera.CFrame.RightVector end

		local vertical = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vertical = -1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = -1 end

		if moveDir.Magnitude > 0 then
			moveDir = moveDir.Unit * Movement.FlySpeed
		end
		self.BodyVelocity.Velocity = Vector3.new(moveDir.X, vertical * Movement.FlyVerticalSpeed, moveDir.Z)
		self.BodyGyro.CFrame = Workspace.CurrentCamera.CFrame
	end)
	conn.Name = "Fly"
	table.insert(Movement.Connections, conn)
end

function Movement:SetupSpeed()
	local conn = RunService.RenderStepped:Connect(function()
		if not Movement.Speed or not LocalPlayer.Character then return end
		local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum.WalkSpeed = Movement.SpeedAmount
		end
	end)
	table.insert(Movement.Connections, conn)
end

function Movement:SetupNoClip()
	local conn = RunService.Stepped:Connect(function()
		if not Movement.NoClip or not LocalPlayer.Character then return end
		for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end)
	table.insert(Movement.Connections, conn)
end

function Movement:SetupInfiniteJump()
	local conn = game:GetService("UserInputService").JumpRequest:Connect(function()
		if Movement.InfiniteJump and LocalPlayer.Character then
			local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	end)
	table.insert(Movement.Connections, conn)
end

function Movement:SetupBunnyHop()
	local hopping = false
	local conn = RunService.Heartbeat:Connect(function()
		if not Movement.BunnyHop or not LocalPlayer.Character then
			hopping = false
			return
		end
		local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end
		if hum.FloorMaterial ~= Enum.Material.Air and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			if not hopping then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				hopping = true
			end
		elseif hum.FloorMaterial == Enum.Material.Air then
			hopping = false
		end
	end)
	table.insert(Movement.Connections, conn)
end

function Movement:SetupDoubleTap()
	local lastTap = 0
	local tapCount = 0
	local conn = UserInputService.InputBegan:Connect(function(input)
		if not Movement.DoubleTap or not LocalPlayer.Character then return end
		if input.KeyCode == Enum.KeyCode.W then
			local now = tick()
			if now - lastTap < 0.3 then
				tapCount = tapCount + 1
				if tapCount >= 2 then
					local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
					if hum then hum.WalkSpeed = Movement.DoubleTapSpeed end
					task.delay(2, function()
						if hum then hum.WalkSpeed = 16 end
					end)
					tapCount = 0
				end
			else
				tapCount = 1
			end
			lastTap = now
		end
	end)
	table.insert(Movement.Connections, conn)
end

function Movement:SetupJumpPower()
	local conn = RunService.RenderStepped:Connect(function()
		if not Movement.JumpPower or not LocalPlayer.Character then return end
		local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum.JumpPower = Movement.JumpPowerAmount
		end
	end)
	table.insert(Movement.Connections, conn)
end

function Movement:SetupCFrameWalk()
	local conn = RunService.RenderStepped:Connect(function()
		if not Movement.CFrameWalk or not LocalPlayer.Character then return end
		local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hum or not root then return end
		local moveDir = hum.MoveDirection
		if moveDir.Magnitude > 0 then
			local targetPos = root.Position + moveDir * Movement.CFrameWalkSpeed
			root.CFrame = CFrame.new(targetPos, root.Position + moveDir)
		end
	end)
	table.insert(Movement.Connections, conn)
end

function Movement:BuildUI(Tab)
	local MG = Tab:AddLeftGroupbox("Movement")
	MG:AddToggle("Movement_Fly", { Text = "Fly", Default = false })
	Toggles.Movement_Fly:OnChanged(function() Movement.Fly = Toggles.Movement_Fly.Value; Movement:SetupFly() end)
	MG:AddSlider("Movement_FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 500, Rounding = 0 })
	Options.Movement_FlySpeed:OnChanged(function() Movement.FlySpeed = Options.Movement_FlySpeed.Value end)
	MG:AddToggle("Movement_Speed", { Text = "Speed", Default = false })
	Toggles.Movement_Speed:OnChanged(function() Movement.Speed = Toggles.Movement_Speed.Value end)
	MG:AddSlider("Movement_SpeedAmount", { Text = "Speed Amount", Default = 50, Min = 16, Max = 500, Rounding = 0 })
	Options.Movement_SpeedAmount:OnChanged(function() Movement.SpeedAmount = Options.Movement_SpeedAmount.Value end)
	MG:AddToggle("Movement_NoClip", { Text = "No Clip", Default = false })
	Toggles.Movement_NoClip:OnChanged(function() Movement.NoClip = Toggles.Movement_NoClip.Value end)
	MG:AddToggle("Movement_InfiniteJump", { Text = "Infinite Jump", Default = false })
	Toggles.Movement_InfiniteJump:OnChanged(function() Movement.InfiniteJump = Toggles.Movement_InfiniteJump.Value end)
	MG:AddToggle("Movement_BunnyHop", { Text = "Bunny Hop", Default = false })
	Toggles.Movement_BunnyHop:OnChanged(function() Movement.BunnyHop = Toggles.Movement_BunnyHop.Value end)
	MG:AddToggle("Movement_JumpPower", { Text = "Jump Power", Default = false })
	Toggles.Movement_JumpPower:OnChanged(function() Movement.JumpPower = Toggles.Movement_JumpPower.Value end)
	MG:AddSlider("Movement_JumpPowerAmount", { Text = "Jump Power", Default = 100, Min = 50, Max = 500, Rounding = 0 })
	Options.Movement_JumpPowerAmount:OnChanged(function() Movement.JumpPowerAmount = Options.Movement_JumpPowerAmount.Value end)

	local EG = Tab:AddRightGroupbox("Exploits")
	EG:AddToggle("Movement_CFrameWalk", { Text = "CFrame Walk", Default = false })
	Toggles.Movement_CFrameWalk:OnChanged(function() Movement.CFrameWalk = Toggles.Movement_CFrameWalk.Value end)
	EG:AddSlider("Movement_CFrameWalkSpeed", { Text = "CFrame Speed", Default = 1.5, Min = 0.1, Max = 5, Rounding = 1 })
	Options.Movement_CFrameWalkSpeed:OnChanged(function() Movement.CFrameWalkSpeed = Options.Movement_CFrameWalkSpeed.Value end)
	EG:AddToggle("Movement_DoubleTap", { Text = "Double Tap Speed", Default = false })
	Toggles.Movement_DoubleTap:OnChanged(function() Movement.DoubleTap = Toggles.Movement_DoubleTap.Value end)
	EG:AddSlider("Movement_DoubleTapSpeed", { Text = "Tap Speed", Default = 100, Min = 50, Max = 500, Rounding = 0 })
	Options.Movement_DoubleTapSpeed:OnChanged(function() Movement.DoubleTapSpeed = Options.Movement_DoubleTapSpeed.Value end)
end

function Movement:Init()
	self:SetupFly()
	self:SetupSpeed()
	self:SetupNoClip()
	self:SetupInfiniteJump()
	self:SetupBunnyHop()
	self:SetupDoubleTap()
	self:SetupJumpPower()
	self:SetupCFrameWalk()
end

function Movement:Cleanup()
	for _, v in ipairs(self.Connections) do
		pcall(v.Disconnect, v)
	end
	self.Connections = {}
	if self.BodyVelocity then self.BodyVelocity:Destroy(); self.BodyVelocity = nil end
	if self.BodyGyro then self.BodyGyro:Destroy(); self.BodyGyro = nil end
	if LocalPlayer.Character then
		local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			hum.PlatformStand = false
		end
		for _, v in ipairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = true
			end
		end
	end
end

return Movement
