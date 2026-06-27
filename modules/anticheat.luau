local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
local LocalPlayer = Players.LocalPlayer

local AntiCheat = {
	Enabled = true,
	HookedAnalytics = false,
	HookedLogs = false,
	HookedKick = false,
	HookedErrors = false,
	DetectionAttempts = 0,
	BypassMethods = {},
}

function AntiCheat:Setup()
	task.spawn(function()
		local remote = pcall(function()
			local r = ReplicatedStorage:FindFirstChild("Remotes")
			if r then
				local ap = r:FindFirstChild("AnalyticsPipeline")
				if ap then
					return ap:FindFirstChild("RemoteEvent")
				end
			end
		end)
		if type(remote) == "userdata" and remote.OnClientEvent then
			for _, conn in pairs(getconnections(remote.OnClientEvent)) do
				if conn and conn.Function then
					pcall(hookfunction, conn.Function, newcclosure(function() end))
					AntiCheat.HookedAnalytics = true
				end
			end
		end
	end)

	task.spawn(function()
		for _, conn in pairs(getconnections(LogService.MessageOut)) do
			if conn and conn.Function then
				pcall(hookfunction, conn.Function, newcclosure(function() end))
				AntiCheat.HookedLogs = true
			end
		end
	end)

	task.spawn(function()
		for _, conn in ipairs(getconnections(ScriptContext.Error)) do
			pcall(conn.Disable, conn)
		end
		pcall(hookfunction, ScriptContext.Error.Connect, newcclosure(function() return nil end))
		AntiCheat.HookedErrors = true
	end)

	task.spawn(function()
		local oldKick
		oldKick = hookfunction(LocalPlayer.Kick, newcclosure(function(self, ...)
			if self == LocalPlayer then
				AntiCheat.DetectionAttempts = AntiCheat.DetectionAttempts + 1
				local args = { ... }
				warn("aHook: Blocked kick:", unpack(args))
				return
			end
			return oldKick(self, ...)
		end))
		AntiCheat.HookedKick = true
	end)

	task.spawn(function()
		if not hookmetamethod then return end
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if AntiCheat.Enabled and method == "FireServer" and typeof(self) == "Instance" then
				if self.Name == "AnalyticsPipeline" or self.Name == "Telemetry" or self.Name == "ReportAbuse" then
					return
				end
			end
			return oldNamecall(self, ...)
		end))
	end)

	task.spawn(function()
		local mt = getrawmetatable(game)
		if not mt then return end
		local old = mt.__index
		mt.__index = newcclosure(function(self, key)
			if AntiCheat.Enabled and type(key) == "string" and key == "ReportAbuseScript" then
				return nil
			end
			return old(self, key)
		end)
	end)
end

function AntiCheat:BuildUI(Tab)
	local AG = Tab:AddRightGroupbox("Anti-Cheat Bypass")
	AG:AddToggle("AntiCheat_Enabled", { Text = "Enable Bypass", Default = true })
	Toggles.AntiCheat_Enabled:OnChanged(function() AntiCheat.Enabled = Toggles.AntiCheat_Enabled.Value end)
	AG:AddLabel("Analytics: " .. (AntiCheat.HookedAnalytics and "Bypassed" or "Not Found"))
	AG:AddLabel("Kick Hook: " .. (AntiCheat.HookedKick and "Active" or "Not Active"))
	AG:AddLabel("Log Hook: " .. (AntiCheat.HookedLogs and "Active" or "Not Active"))
	AG:AddLabel("Detections: " .. tostring(AntiCheat.DetectionAttempts))
end

function AntiCheat:Init()
	self:Setup()
end

function AntiCheat:Cleanup()
	AntiCheat.Enabled = false
end

return AntiCheat
