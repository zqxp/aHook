local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
local LocalPlayer = Players.LocalPlayer

task.spawn(function()
	local ok, mod = pcall(function()
		return require(game:GetService("ReplicatedFirst"):WaitForChild("AnalyticsPipelineController", 5))
	end)
	if ok and type(mod) == "table" then
		for _, name in ipairs({ "reportEvent", "reportCounter", "reportStats" }) do
			if type(mod[name]) == "function" then
				pcall(hookfunction, mod[name], newcclosure(function() task.wait(9e9) end))
			end
		end
	end
end)

task.spawn(function()
	local ok, remote = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AnalyticsPipeline"):WaitForChild("RemoteEvent")
	end)
	if ok and remote and remote.OnClientEvent then
		for _, conn in pairs(getconnections(remote.OnClientEvent)) do
			if conn and conn.Function then
				pcall(function()
					hookfunction(conn.Function, newcclosure(function(...) end))
				end)
			end
		end
	end
end)

task.spawn(function()
	for _, conn in pairs(getconnections(LogService.MessageOut)) do
		if conn and conn.Function then
			pcall(function()
				hookfunction(conn.Function, newcclosure(function(...) end))
			end)
		end
	end
end)

task.spawn(function()
	for _, conn in ipairs(getconnections(ScriptContext.Error)) do
		pcall(function()
			conn:Disable()
		end)
	end
	pcall(function()
		hookfunction(ScriptContext.Error.Connect, newcclosure(function(...)
			return nil
		end))
	end)
end)

task.spawn(function()
	local KickNames = { "Kick", "kick" }
	for _, name in ipairs(KickNames) do
		local fn = LocalPlayer[name]
		if type(fn) == "function" then
			local oldkick
			oldkick = hookfunction(fn, newcclosure(function(self, ...)
				if self == LocalPlayer then
					return
				end
				return oldkick(self, ...)
			end))
		end
	end
end)
