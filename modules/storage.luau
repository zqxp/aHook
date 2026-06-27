local HttpService = game:GetService("HttpService")

local Storage = {
	SaveFolder = "aHookSettings",
	SkinLoadouts = {},
	AutoloadSkin = nil,
}

function Storage:GetPath()
	return self.SaveFolder
end

function Storage:Load()
	local ok, data = pcall(function()
		return readfile(self.SaveFolder .. "/skins.json")
	end)
	if ok and data then
		local decoded = HttpService:JSONDecode(data)
		if type(decoded) == "table" then
			self.SkinLoadouts = decoded
		end
	end
end

function Storage:Save()
	local ok, err = pcall(function()
		writefile(self.SaveFolder .. "/skins.json", HttpService:JSONEncode(self.SkinLoadouts))
	end)
	return ok, err
end

function Storage:SaveSkinLoadout(name, data)
	self.SkinLoadouts[name] = data
	return self:Save()
end

function Storage:LoadSkinLoadout(name)
	local data = self.SkinLoadouts[name]
	if data then
		return true, data
	end
	return false, nil
end

function Storage:ListSkinLoadouts()
	local list = {}
	for name in pairs(self.SkinLoadouts) do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

function Storage:DeleteSkinLoadout(name)
	self.SkinLoadouts[name] = nil
	self:Save()
end

function Storage:SetSkinAutoload(name)
	self.AutoloadSkin = name
	local ok, err = pcall(function()
		writefile(self.SaveFolder .. "/autoload.txt", name)
	end)
	return ok, err
end

function Storage:LoadAutoloadSkin()
	if self.AutoloadSkin then
		return self:LoadSkinLoadout(self.AutoloadSkin)
	end
	local ok, name = pcall(function()
		return readfile(self.SaveFolder .. "/autoload.txt")
	end)
	if ok and name and name ~= "" then
		self.AutoloadSkin = name
		return self:LoadSkinLoadout(name)
	end
	return false, nil
end

Storage:Load()

return Storage
