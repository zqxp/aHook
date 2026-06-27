local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
local LocalPlayer = Players.LocalPlayer

task.spawn(function()
	local ok, remote = pcall(function()
		return ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AnalyticsPipeline") and ReplicatedStorage.Remotes.AnalyticsPipeline:FindFirstChild("RemoteEvent")
	end)
	if ok and remote and remote.OnClientEvent then
		for _, conn in pairs(getconnections(remote.OnClientEvent)) do
			if conn and conn.Function then
				pcall(hookfunction, conn.Function, newcclosure(function() end))
			end
		end
	end
end)

task.spawn(function()
	for _, conn in pairs(getconnections(LogService.MessageOut)) do
		if conn and conn.Function then
			pcall(hookfunction, conn.Function, newcclosure(function() end))
		end
	end
end)

task.spawn(function()
	for _, conn in ipairs(getconnections(ScriptContext.Error)) do
		pcall(conn.Disable, conn)
	end
	pcall(hookfunction, ScriptContext.Error.Connect, newcclosure(function()
		return nil
	end))
end)

task.spawn(function()
	local old
	old = hookfunction(LocalPlayer.Kick, newcclosure(function(self, ...)
		if self == LocalPlayer then
			return
		end
		return old(self, ...)
	end))
end)
