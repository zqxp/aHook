local Storage = {}

local HttpService = game:GetService("HttpService")

Storage.SaveFolder = "aHookSettings"
Storage.SkinLoadouts = {}
Storage.AutoloadSkin = nil

local function EnsureFolder()
    pcall(function()
        if not isfolder(Storage.SaveFolder) then
            makefolder(Storage.SaveFolder)
        end
    end)
end

function Storage:Init()
    EnsureFolder()
    self:Load()
end

function Storage:Save()
    EnsureFolder()
    local data = {
        SkinLoadouts = self.SkinLoadouts,
        AutoloadSkin = self.AutoloadSkin,
    }
    local json = HttpService:JSONEncode(data)
    pcall(function() writefile(Storage.SaveFolder .. "/skins.json", json) end)
end

function Storage:Load()
    EnsureFolder()
    local ok, content = pcall(function()
        return readfile(Storage.SaveFolder .. "/skins.json")
    end)
    if ok and content and type(content) == "string" and #content > 2 then
        local data = HttpService:JSONDecode(content)
        if data then
            self.SkinLoadouts = data.SkinLoadouts or {}
            self.AutoloadSkin = data.AutoloadSkin or nil
        end
    end
end

function Storage:SaveSkinLoadout(name, data)
    if not name or name == "" then return false, "Empty name" end
    self.SkinLoadouts[name] = data
    self:Save()
    return true
end

function Storage:LoadSkinLoadout(name)
    local data = self.SkinLoadouts[name]
    if data then
        return true, data
    end
    return false, nil
end

function Storage:DeleteSkinLoadout(name)
    self.SkinLoadouts[name] = nil
    self:Save()
end

function Storage:ListSkinLoadouts()
    local list = {}
    for name, _ in pairs(self.SkinLoadouts) do
        table.insert(list, name)
    end
    return list
end

function Storage:SetSkinAutoload(name)
    self.AutoloadSkin = name
    self:Save()
end

function Storage:LoadAutoloadSkin()
    if self.AutoloadSkin then
        local ok, data = self:LoadSkinLoadout(self.AutoloadSkin)
        if ok and data then
            return true, data
        end
    end
    return false, nil
end

Storage:Init()

return Storage
