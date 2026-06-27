local httpService = game:GetService('HttpService')
local Storage = {
	Folder = 'aHookSkins',
	Presets = {}
}

function Storage:BuildFolders()
	local paths = {
		self.Folder,
		self.Folder .. '/loadouts',
		self.Folder .. '/presets'
	}
	for i = 1, #paths do
		local str = paths[i]
		if not isfolder(str) then
			makefolder(str)
		end
	end
end

function Storage:SaveSkinLoadout(name, data)
	if not name or name:gsub(' ', '') == '' then
		return false, 'invalid name'
	end
	local fullPath = self.Folder .. '/loadouts/' .. name .. '.json'
	local success, encoded = pcall(httpService.JSONEncode, httpService, data)
	if not success then
		return false, 'encode failed'
	end
	writefile(fullPath, encoded)
	return true
end

function Storage:LoadSkinLoadout(name)
	local file = self.Folder .. '/loadouts/' .. name .. '.json'
	if not isfile(file) then
		return false, 'file not found'
	end
	local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
	if not success then
		return false, 'decode failed'
	end
	return true, decoded
end

function Storage:DeleteSkinLoadout(name)
	local file = self.Folder .. '/loadouts/' .. name .. '.json'
	if isfile(file) then
		delfile(file)
		return true
	end
	return false
end

function Storage:ListSkinLoadouts()
	local list = listfiles(self.Folder .. '/loadouts')
	local out = {}
	for i = 1, #list do
		local file = list[i]
		if file:sub(-5) == '.json' then
			local pos = file:find('.json', 1, true)
			local start = pos
			local char = file:sub(pos, pos)
			while char ~= '/' and char ~= '\\' and char ~= '' do
				pos = pos - 1
				char = file:sub(pos, pos)
			end
			if char == '/' or char == '\\' then
				table.insert(out, file:sub(pos + 1, start - 1))
			end
		end
	end
	return out
end

function Storage:SetSkinAutoload(name)
	writefile(self.Folder .. '/autoload.txt', name)
end

function Storage:GetSkinAutoload()
	if isfile(self.Folder .. '/autoload.txt') then
		return readfile(self.Folder .. '/autoload.txt')
	end
	return nil
end

function Storage:LoadAutoloadSkin()
	local name = self:GetSkinAutoload()
	if name then
		local success, data = self:LoadSkinLoadout(name)
		if success then
			return data
		end
	end
	return nil
end

Storage:BuildFolders()

return Storage
