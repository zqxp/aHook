local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Data = {
	Weapons = {},
	Skins = {},
	Contracts = {},
	Maps = {},
	PlayerStats = {},
	RemoteNames = {
		Attack = "Remotes.Attack",
		Telemetry = "Remotes.Telemetry",
		Analytics = "Remotes.AnalyticsPipeline.RemoteEvent",
		Kill = "Remotes.Kill",
		Damage = "Remotes.Damage",
		Health = "Remotes.Health",
	},
	WeaponList = {
		"Revolver", "Shotgun", "Rifle", "SMG", "Sniper",
		"Knife", "Bat", "Hammer", "Sword", "Katana",
	},
}

function Data:GetWeaponID(name)
	return self.Weapons[name]
end

function Data:GetSkinID(weapon, skin)
	local ws = self.Skins[weapon]
	if ws then
		return ws[skin]
	end
	return nil
end

function Data:Encode(str)
	if not str then return "" end
	return HttpService:JSONEncode(str)
end

function Data:Decode(str)
	if not str or type(str) ~= "string" then return nil end
	local ok, result = pcall(HttpService.JSONDecode, HttpService, str)
	if ok then return result end
	return nil
end

return Data
