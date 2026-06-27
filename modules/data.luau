local Data = {}

Data.Weapons = {
    Primary = {
        "AK-47", "M4A1", "AR", "Rifle", "Sniper", "Shotgun", "SMG",
        "FAMAS", "SCAR", "Galil", "Aug", "SG556", "P90", "MP5",
        "AWP", "Scout", "SSG08", "Nova", "XM1014", "MAG-7",
    },
    Secondary = {
        "Pistol", "Deagle", "Glock", "USP", "P250", "Five-SeveN",
        "Tec-9", "CZ75", "Revolver", "Desert Eagle", "Dual Berettas",
    },
    Melee = {
        "Knife", "Bat", "Sword", "Machete", "Axe", "Crowbar",
    }
}

Data.RemoteNames = {
    Attack = "Attack",
    Analytics = "AnalyticsPipeline",
    Equip = "Equip",
    Reload = "Reload",
}

Data.Maps = {}

Data.PlayerStats = {}

function Data.Encode(tbl)
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONEncode(tbl)
    end)
    return ok and result or nil
end

function Data.Decode(str)
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(str)
    end)
    return ok and result or nil
end

function Data.GetWeaponID(name)
    return Data.Weapons[name] or nil
end

function Data.GetSkinID(name)
    return Data.Skins and Data.Skins[name] or nil
end

return Data
