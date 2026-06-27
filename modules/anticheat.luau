local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
local LocalPlayer = Players.LocalPlayer

task.spawn(function()
	local hooked = 0
	for _, v in pairs(getgc(true)) do
		if typeof(v) == "function" then
			local ok, src = pcall(function()
				return debug.info(v, "s")
			end)
			if ok and type(src) == "string" and string.find(src, "AnalyticsPipelineController") then
				hooked = hooked + 1
				hookfunction(v, newcclosure(function(...)
					return wait(9e9)
				end))
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
