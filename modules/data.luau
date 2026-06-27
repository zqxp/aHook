local Data = {
	RarityColors = {
		Common = Color3.fromRGB(180, 180, 180),
		Rare = Color3.fromRGB(50, 150, 255),
		Epic = Color3.fromRGB(180, 80, 255),
		Legendary = Color3.fromRGB(255, 180, 50),
	},
	Patterns = {
		"None", "Solid", "Striped", "Camo", "Digital",
		"Zebra", "Tiger", "Snake", "Crystal", "Holographic"
	},
	Weapons = {
		["Falcon"] = {
			DisplayName = "Falcon",
			Type = "Pistol",
			Skins = {
				["Carbon Fiber"] = { Id = 1234567890, Rarity = "Common" },
				["Gold"] = { Id = 1234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 1234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 1234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 1234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 1234567895, Rarity = "Epic" },
				["Neon"] = { Id = 1234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 1234567897, Rarity = "Rare" },
				["Blood"] = { Id = 1234567898, Rarity = "Epic" },
				["Storm"] = { Id = 1234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://1234567800",
				Walk = "rbxassetid://1234567801",
				Run = "rbxassetid://1234567802",
				Shoot = "rbxassetid://1234567803",
				Reload = "rbxassetid://1234567804",
			}
		},
		["Revolver"] = {
			DisplayName = "Revolver",
			Type = "Pistol",
			Skins = {
				["Carbon Fiber"] = { Id = 2234567890, Rarity = "Common" },
				["Gold"] = { Id = 2234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 2234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 2234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 2234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 2234567895, Rarity = "Epic" },
				["Neon"] = { Id = 2234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 2234567897, Rarity = "Rare" },
				["Blood"] = { Id = 2234567898, Rarity = "Epic" },
				["Storm"] = { Id = 2234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://2234567800",
				Walk = "rbxassetid://2234567801",
				Run = "rbxassetid://2234567802",
				Shoot = "rbxassetid://2234567803",
				Reload = "rbxassetid://2234567804",
			}
		},
		["Dagger"] = {
			DisplayName = "Dagger",
			Type = "Melee",
			Skins = {
				["Carbon Fiber"] = { Id = 3234567890, Rarity = "Common" },
				["Gold"] = { Id = 3234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 3234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 3234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 3234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 3234567895, Rarity = "Epic" },
				["Neon"] = { Id = 3234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 3234567897, Rarity = "Rare" },
				["Blood"] = { Id = 3234567898, Rarity = "Epic" },
				["Storm"] = { Id = 3234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://3234567800",
				Walk = "rbxassetid://3234567801",
				Run = "rbxassetid://3234567802",
				Shoot = "rbxassetid://3234567803",
				Reload = "rbxassetid://3234567804",
			}
		},
		["Katana"] = {
			DisplayName = "Katana",
			Type = "Melee",
			Skins = {
				["Carbon Fiber"] = { Id = 4234567890, Rarity = "Common" },
				["Gold"] = { Id = 4234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 4234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 4234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 4234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 4234567895, Rarity = "Epic" },
				["Neon"] = { Id = 4234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 4234567897, Rarity = "Rare" },
				["Blood"] = { Id = 4234567898, Rarity = "Epic" },
				["Storm"] = { Id = 4234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://4234567800",
				Walk = "rbxassetid://4234567801",
				Run = "rbxassetid://4234567802",
				Shoot = "rbxassetid://4234567803",
				Reload = "rbxassetid://4234567804",
			}
		},
		["Scarlet"] = {
			DisplayName = "Scarlet",
			Type = "AR",
			Skins = {
				["Carbon Fiber"] = { Id = 5234567890, Rarity = "Common" },
				["Gold"] = { Id = 5234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 5234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 5234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 5234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 5234567895, Rarity = "Epic" },
				["Neon"] = { Id = 5234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 5234567897, Rarity = "Rare" },
				["Blood"] = { Id = 5234567898, Rarity = "Epic" },
				["Storm"] = { Id = 5234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://5234567800",
				Walk = "rbxassetid://5234567801",
				Run = "rbxassetid://5234567802",
				Shoot = "rbxassetid://5234567803",
				Reload = "rbxassetid://5234567804",
			}
		},
		["Rifle"] = {
			DisplayName = "Rifle",
			Type = "AR",
			Skins = {
				["Carbon Fiber"] = { Id = 6234567890, Rarity = "Common" },
				["Gold"] = { Id = 6234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 6234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 6234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 6234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 6234567895, Rarity = "Epic" },
				["Neon"] = { Id = 6234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 6234567897, Rarity = "Rare" },
				["Blood"] = { Id = 6234567898, Rarity = "Epic" },
				["Storm"] = { Id = 6234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://6234567800",
				Walk = "rbxassetid://6234567801",
				Run = "rbxassetid://6234567802",
				Shoot = "rbxassetid://6234567803",
				Reload = "rbxassetid://6234567804",
			}
		},
		["Shotgun"] = {
			DisplayName = "Shotgun",
			Type = "Shotgun",
			Skins = {
				["Carbon Fiber"] = { Id = 7234567890, Rarity = "Common" },
				["Gold"] = { Id = 7234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 7234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 7234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 7234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 7234567895, Rarity = "Epic" },
				["Neon"] = { Id = 7234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 7234567897, Rarity = "Rare" },
				["Blood"] = { Id = 7234567898, Rarity = "Epic" },
				["Storm"] = { Id = 7234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://7234567800",
				Walk = "rbxassetid://7234567801",
				Run = "rbxassetid://7234567802",
				Shoot = "rbxassetid://7234567803",
				Reload = "rbxassetid://7234567804",
			}
		},
		["SMG"] = {
			DisplayName = "SMG",
			Type = "SMG",
			Skins = {
				["Carbon Fiber"] = { Id = 8234567890, Rarity = "Common" },
				["Gold"] = { Id = 8234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 8234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 8234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 8234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 8234567895, Rarity = "Epic" },
				["Neon"] = { Id = 8234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 8234567897, Rarity = "Rare" },
				["Blood"] = { Id = 8234567898, Rarity = "Epic" },
				["Storm"] = { Id = 8234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://8234567800",
				Walk = "rbxassetid://8234567801",
				Run = "rbxassetid://8234567802",
				Shoot = "rbxassetid://8234567803",
				Reload = "rbxassetid://8234567804",
			}
		},
		["Sniper"] = {
			DisplayName = "Sniper",
			Type = "Sniper",
			Skins = {
				["Carbon Fiber"] = { Id = 9234567890, Rarity = "Common" },
				["Gold"] = { Id = 9234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 9234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 9234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 9234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 9234567895, Rarity = "Epic" },
				["Neon"] = { Id = 9234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 9234567897, Rarity = "Rare" },
				["Blood"] = { Id = 9234567898, Rarity = "Epic" },
				["Storm"] = { Id = 9234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://9234567800",
				Walk = "rbxassetid://9234567801",
				Run = "rbxassetid://9234567802",
				Shoot = "rbxassetid://9234567803",
				Reload = "rbxassetid://9234567804",
			}
		},
		["Burst"] = {
			DisplayName = "Burst",
			Type = "AR",
			Skins = {
				["Carbon Fiber"] = { Id = 10234567890, Rarity = "Common" },
				["Gold"] = { Id = 10234567891, Rarity = "Rare" },
				["Diamond"] = { Id = 10234567892, Rarity = "Epic" },
				["Galaxy"] = { Id = 10234567893, Rarity = "Legendary" },
				["Ice"] = { Id = 10234567894, Rarity = "Rare" },
				["Dragon"] = { Id = 10234567895, Rarity = "Epic" },
				["Neon"] = { Id = 10234567896, Rarity = "Legendary" },
				["Midnight"] = { Id = 10234567897, Rarity = "Rare" },
				["Blood"] = { Id = 10234567898, Rarity = "Epic" },
				["Storm"] = { Id = 10234567899, Rarity = "Legendary" },
			},
			Animations = {
				Idle = "rbxassetid://10234567800",
				Walk = "rbxassetid://10234567801",
				Run = "rbxassetid://10234567802",
				Shoot = "rbxassetid://10234567803",
				Reload = "rbxassetid://10234567804",
			}
		},
	},
	Materials = {
		"ForceField", "Neon", "Foil", "Metal", "Glass", "Ice",
		"DiamondPlate", "Cobblestone", "Granite", "Brick", "Wood",
		"WoodPlanks", "Marble", "Limestone", "Concrete", "Slate",
		"Sandstone", "Plastic", "SmoothPlastic", "CorrodedMetal", "Diamond"
	},
	Skyboxes = {
		"Default", "Night", "Sunset", "Blood", "Storm", "Dark",
		"Neon", "Cloudy"
	}
}

function Data:GetWeaponNames()
	local names = {}
	for key, weapon in pairs(self.Weapons) do
		table.insert(names, key)
	end
	table.sort(names)
	return names
end

function Data:GetSkinNames(weaponName)
	local weapon = self.Weapons[weaponName]
	if not weapon then
		return {}
	end
	local names = {}
	for key in pairs(weapon.Skins) do
		table.insert(names, key)
	end
	table.sort(names)
	return names
end

function Data:GetSkinId(weaponName, skinName)
	local weapon = self.Weapons[weaponName]
	if weapon and weapon.Skins[skinName] then
		return weapon.Skins[skinName].Id
	end
	return nil
end

function Data:GetWeaponAnimations(weaponName)
	local weapon = self.Weapons[weaponName]
	if weapon then
		return weapon.Animations
	end
	return nil
end

function Data:GetWeaponType(weaponName)
	local weapon = self.Weapons[weaponName]
	if weapon then
		return weapon.Type
	end
	return nil
end

return Data
