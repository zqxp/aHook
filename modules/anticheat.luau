local AntiCheat = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")

local LocalPlayer = Players.LocalPlayer

local Connections = {}
local Hooks = {}
local Enabled = false

local BlockedRemotes = {
    "AnalyticsPipeline",
    "ReportAbuseScript",
    "GameAnalytics",
    "Telemetry",
}

local function HookKick()
    local mt = getrawmetatable and getrawmetatable(game) or nil
    if not mt then return end

    local oldNamecall = mt.__namecall
    local oldIndex = mt.__index

    Hooks.Namecall = hookmetamethod and hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or ""
        local args = {...}

        if Enabled then
            if method == "FireServer" then
                for _, blocked in ipairs(BlockedRemotes) do
                    if self.Name and self.Name:find(blocked) then
                        return nil
                    end
                end
            end

            if method == "Kick" and self == LocalPlayer then
                return nil
            end
        end

        return oldNamecall(self, ...)
    end)) or nil

    Hooks.Index = hookmetamethod and hookmetamethod(game, "__index", newcclosure(function(self, key)
        if Enabled and self == LocalPlayer and key == "Kick" then
            return newcclosure(function() return nil end)
        end
        return oldIndex(self, key)
    end)) or nil
end

local function HookAnalytics()
    local ok, remote = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local analytics = remotes:FindFirstChild("AnalyticsPipeline")
            if analytics then
                return analytics:FindFirstChild("RemoteEvent")
            end
        end
    end)

    if ok and remote and typeof(remote) == "Instance" then
        Hooks.Analytics = remote
        pcall(function()
            remote.OnClientEvent:Connect(function() end)
        end)
    end
end

local function BlockLogSpam()
    Hooks.LogService = LogService.MessageOut:Connect(function(message, messageType)
        if Enabled and message:find("analytics") or message:find("telemetry") then
            return
        end
    end)

    table.insert(Connections, Hooks.LogService)
end

function AntiCheat:Init()
    Enabled = true

    pcall(HookKick)
    pcall(HookAnalytics)
    pcall(BlockLogSpam)

    if getconnections then
        for _, conn in ipairs(getconnections(LogService.MessageOut) or {}) do
            pcall(function() conn:Disable() end)
        end
    end
end

function AntiCheat:Cleanup()
    Enabled = false
    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
end

function AntiCheat:BuildUI(Tabs)
    local ACBox = Tabs:AddLeftGroupbox("Anti-Cheat")

    ACBox:AddLabel("Status: Active")

    ACBox:AddToggle("AC_Enabled", {
        Text = "AC Bypass",
        Default = true,
        Callback = function(value)
            Enabled = value
        end
    })
end

return AntiCheat
