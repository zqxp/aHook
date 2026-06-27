local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Movement = {
	Flight = false,
	NoClip = false,
	SpeedMultiplier = 1,
	FlySpeed = 50,
	JumpPower = 50,
	Connections = {},
	BodyVelocity = nil,
	Align = nil,
	OriginalWalkSpeed = 16,
	OriginalJumpPower = 50,
}

function Movement:SetupFlight()
	if Movement.BodyVelocity then
		Movement.BodyVelocity:Destroy()
		Movement.BodyVelocity = nil
	end

	local char = LocalPlayer.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	Movement.OriginalWalkSpeed = humanoid.WalkSpeed
	Movement.OriginalJumpPower = humanoid.JumpPower

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(4000, 4000, 4000)
	bv.P = 1250
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = root
	Movement.BodyVelocity = bv
end

function Movement:UpdateFlight()
	if not Movement.Flight or not Movement.BodyVelocity then
		return
	end

	local char = LocalPlayer.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local camera = Workspace.CurrentCamera
	local moveVec = Vector3.new(0, 0, 0)
	local speed = Movement.FlySpeed

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveVec = moveVec + camera.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveVec = moveVec - camera.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveVec = moveVec - camera.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveVec = moveVec + camera.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		moveVec = moveVec + Vector3.new(0, 1, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		moveVec = moveVec + Vector3.new(0, -1, 0)
	end

	if moveVec.Magnitude > 0 then
		moveVec = moveVec.Unit * speed
	end

	Movement.BodyVelocity.Velocity = moveVec
end

function Movement:SetupNoClip()
	local conn
	conn = RunService.Stepped:Connect(function()
		if not Movement.NoClip then
			return
		end
		local char = LocalPlayer.Character
		if not char then
			return
		end
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
	table.insert(Movement.Connections, conn)
end

function Movement:ApplySpeed()
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = Movement.OriginalWalkSpeed * Movement.SpeedMultiplier
end

function Movement:ApplyJumpPower()
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end
	humanoid.JumpPower = Movement.JumpPower
end

function Movement:BuildUI(Tab)
	local MoveGroup = Tab:AddLeftGroupbox("Movement  ‍🏃")
	MoveGroup:AddToggle("Movement_Flight", {
		Text = "Flight",
		Default = false,
		Tooltip = "Enable flight mode (WASD + Space/Shift)"
	})
	Toggles.Movement_Flight:OnChanged(function()
		Movement.Flight = Toggles.Movement_Flight.Value
		if Movement.Flight then
			Movement:SetupFlight()
		elseif Movement.BodyVelocity then
			Movement.BodyVelocity:Destroy()
			Movement.BodyVelocity = nil
			local char = LocalPlayer.Character
			if char then
				local humanoid = char:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = Movement.OriginalWalkSpeed
					humanoid.JumpPower = Movement.OriginalJumpPower
				end
			end
		end
	end)

	MoveGroup:AddSlider("Movement_FlySpeed", {
		Text = "Fly Speed",
		Default = 50,
		Min = 10,
		Max = 200,
		Rounding = 0,
		Suffix = " studs/s",
		Tooltip = "Flight movement speed"
	})
	Options.Movement_FlySpeed:OnChanged(function()
		Movement.FlySpeed = Options.Movement_FlySpeed.Value
	end)

	MoveGroup:AddToggle("Movement_NoClip", {
		Text = "NoClip",
		Default = false,
		Tooltip = "Walk through walls"
	})
	Toggles.Movement_NoClip:OnChanged(function()
		Movement.NoClip = Toggles.Movement_NoClip.Value
	end)

	MoveGroup:AddSlider("Movement_Speed", {
		Text = "Speed Multiplier",
		Default = 1,
		Min = 1,
		Max = 5,
		Rounding = 1,
		Suffix = "x",
		Tooltip = "Multiply walk speed"
	})
	Options.Movement_Speed:OnChanged(function()
		Movement.SpeedMultiplier = Options.Movement_Speed.Value
		Movement:ApplySpeed()
	end)

	MoveGroup:AddSlider("Movement_JumpPower", {
		Text = "Jump Power",
		Default = 50,
		Min = 50,
		Max = 200,
		Rounding = 0,
		Tooltip = "Jump height"
	})
	Options.Movement_JumpPower:OnChanged(function()
		Movement.JumpPower = Options.Movement_JumpPower.Value
		Movement:ApplyJumpPower()
	end)
end

function Movement:Init()
	self:SetupNoClip()

	local flightConn
	flightConn = RunService.RenderStepped:Connect(function()
		self:UpdateFlight()
	end)
	table.insert(self.Connections, flightConn)

	local charConn
	charConn = LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		if Movement.Flight then
			self:SetupFlight()
		end
		self:ApplySpeed()
		self:ApplyJumpPower()
	end)
	table.insert(self.Connections, charConn)
end

function Movement:Cleanup()
	for _, conn in ipairs(self.Connections) do
		conn:Disconnect()
	end
	self.Connections = {}
	if Movement.BodyVelocity then
		Movement.BodyVelocity:Destroy()
		Movement.BodyVelocity = nil
	end
end

return Movement
