if not game:IsLoaded() then
	game.Loaded:Wait()
end

if game.GameId ~= 6035872082 then
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local BaseRepo = "https://cdn.jsdelivr.net/gh/zqxp/aHook@main/"
local ModuleFolder = BaseRepo .. "modules/"

local LoadingScreen = Instance.new("ScreenGui")
LoadingScreen.Name = "aHook_Loading"
LoadingScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
LoadingScreen.ResetOnSpawn = false
LoadingScreen.Parent = CoreGui

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.new(0, 300, 0, 100)
LoadingFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
LoadingFrame.BorderColor3 = Color3.fromRGB(50, 50, 50)
LoadingFrame.BorderMode = Enum.BorderMode.Inset
LoadingFrame.Parent = LoadingScreen

local VERSION = "v3"
local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Size = UDim2.new(1, 0, 0, 30)
LoadingTitle.Position = UDim2.new(0, 0, 0, 10)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "aHook " .. VERSION
LoadingTitle.TextColor3 = Color3.fromRGB(214, 141, 168)
LoadingTitle.TextSize = 20
LoadingTitle.Font = Enum.Font.Code
LoadingTitle.TextStrokeTransparency = 0
LoadingTitle.Parent = LoadingFrame

local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Size = UDim2.new(1, 0, 0, 20)
LoadingStatus.Position = UDim2.new(0, 0, 0, 45)
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Text = "Loading..."
LoadingStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
LoadingStatus.TextSize = 14
LoadingStatus.Font = Enum.Font.Code
LoadingStatus.Parent = LoadingFrame

local LoadingBar = Instance.new("Frame")
LoadingBar.Size = UDim2.new(0.8, 0, 0, 6)
LoadingBar.Position = UDim2.new(0.1, 0, 0, 75)
LoadingBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LoadingBar.BorderColor3 = Color3.fromRGB(50, 50, 50)
LoadingBar.BorderMode = Enum.BorderMode.Inset
LoadingBar.Parent = LoadingFrame

local LoadingBarFill = Instance.new("Frame")
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Color3.fromRGB(214, 141, 168)
LoadingBarFill.BorderSizePixel = 0
LoadingBarFill.Parent = LoadingBar

local function UpdateLoading(text, percent)
	LoadingStatus.Text = text
	local tween = TweenService:Create(LoadingBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(percent, 0, 1, 0)
	})
	tween:Play()
end

local HttpService = game:GetService("HttpService")

local function Sanitize(str)
	-- Aggressively strip ALL BOM variants anywhere in the string
	str = str:gsub("\239\187\191", "")  -- UTF-8 BOM
	str = str:gsub("\254\255", "")      -- UTF-16 BE BOM
	str = str:gsub("\255\254", "")      -- UTF-16 LE BOM
	return str
end

local function FetchModule(url, isLarge)
	local methods = {
		function() return game:HttpGet(url) end,
		function() return HttpService:GetAsync(url) end,
	}
	if isLarge then
		methods = {
			function() return HttpService:GetAsync(url) end,
			function() return game:HttpGet(url) end,
		}
	end
	local retries = 3
	local waitTime = isLarge and 1.0 or 0.5
	for i = 1, retries do
		for _, method in ipairs(methods) do
			local result
			local ok = pcall(function()
				result = method()
			end)
			if ok and result and #result > 0 then
				return Sanitize(result)
			end
		end
		task.wait(waitTime)
	end
	return nil, "all retries exhausted"
end

local function TryLoadString(src, name)
	local fn, compileErr = loadstring(src)
	if not fn then
		return nil, "compile error: " .. tostring(compileErr)
	end
	local ok, result = pcall(fn)
	if not ok then
		return nil, "runtime error: " .. tostring(result)
	end
	return result
end

local function LoadModule(name)
	local url = ModuleFolder .. name .. ".luau"
	local src, fetchErr = FetchModule(url)
	if not src then
		warn("aHook: Failed to load module: " .. name .. " (" .. tostring(fetchErr) .. ")")
		return nil
	end
	local mod, loadErr = TryLoadString(src, name)
	if not mod then
		warn("aHook: Failed to init module: " .. name .. " (" .. tostring(loadErr) .. ")")
	end
	return mod
end

local function RunLoader()
	-- Diagnostics: test GitHub reachability
	local testOk, testResult = pcall(function()
		return game:HttpGet(BaseRepo .. "loader.luau")
	end)
	if not testOk or not testResult or #testResult < 10 then
		LoadingStatus.Text = "Failed: cannot reach GitHub (" .. tostring(testResult) .. ")"
		task.wait(4)
		LoadingScreen:Destroy()
		return
	end

	-- Step 1: UI Library (fetch first, before AC hooks)
	UpdateLoading("Loading UI Library...", 0.15)
	local libSrc, libErr

	-- Try single file first
	libSrc = FetchModule(BaseRepo .. "library.luau", true)

	-- Fallback: try split parts
	if not libSrc then
		UpdateLoading("Loading UI Library (part 1/3)...", 0.12)
		local a = FetchModule(BaseRepo .. "library_a.luau")
		if a then
			UpdateLoading("Loading UI Library (part 2/3)...", 0.14)
			local b = FetchModule(BaseRepo .. "library_b.luau")
			if b then
				UpdateLoading("Loading UI Library (part 3/3)...", 0.14)
				local c = FetchModule(BaseRepo .. "library_c.luau")
				if c then
					libSrc = a .. b .. c
				end
			end
		end
		if not libSrc then
			libErr = "split fetch failed"
		end
	end
	local Library, ThemeManager, SaveManager
	if libSrc then
		-- Show first 20 bytes for debugging
		local hexDump = libSrc:sub(1, 20):gsub(".", function(c) return string.format("%02X ", string.byte(c)) end)
		LoadingStatus.Text = "Debug: " .. hexDump
		task.wait(2)
		local lib, loadErr = TryLoadString(libSrc, "library")
		if lib then
			Library = lib
		else
			libErr = loadErr .. " [hex: " .. hexDump .. "]"
		end
	else
		libErr = libErr or "fetch returned nil"
	end
	if not Library then
		LoadingStatus.Text = "Failed: " .. tostring(libErr)
		task.wait(6)
		LoadingScreen:Destroy()
		return
	end
	task.wait(0.3)

	-- Step 2: AC Bypass
	UpdateLoading("Bypassing Anti-Cheat...", 0.05)
	local acSrc = FetchModule(ModuleFolder .. "anticheat.luau")
	if acSrc then
		pcall(loadstring(acSrc))
	end
	task.wait(0.3)

	-- Step 3: Addons
	UpdateLoading("Loading Addons...", 0.25)
	local addonSrc = FetchModule(BaseRepo .. "addons.luau")
	if addonSrc then
		local success, addons = pcall(loadstring, addonSrc)
		if success and addons then
			ThemeManager, SaveManager = addons[1], addons[2]
		end
	end
	task.wait(0.3)

	-- Step 4: Create window
	local Window = Library:CreateWindow({
		Title = "aHook",
		Center = true,
		AutoShow = true,
		TabPadding = 8,
		MenuFadeTime = 0.2
	})

	-- Create tabs with emojis
	local Tabs = {
		Combat = Window:AddTab("⚔️ Combat"),
		Rage = Window:AddTab("💥 Rage"),
		Visuals = Window:AddTab("👁️ Visuals"),
		Skins = Window:AddTab("🎨 Skins"),
		Movement = Window:AddTab("🌊 Movement"),
		Config = Window:AddTab("⚙️ Config"),
	}

	-- Step 5: Load modules
	UpdateLoading("Loading Data...", 0.35)
	local Data = LoadModule("data")
	getgenv().Data = Data
	task.wait(0.3)

	UpdateLoading("Loading Storage...", 0.40)
	local Storage = LoadModule("storage")
	getgenv().Storage = Storage
	task.wait(0.2)

	UpdateLoading("Loading Combat...", 0.45)
	local Combat = LoadModule("combat")
	task.wait(0.3)

	UpdateLoading("Loading Rage System...", 0.50)
	local RageSystem = LoadModule("ragesystem")
	task.wait(0.2)

	UpdateLoading("Loading ESP...", 0.60)
	local ESP = LoadModule("esp")
	task.wait(0.3)

	UpdateLoading("Loading Visuals...", 0.65)
	local Visuals = LoadModule("visuals")
	task.wait(0.2)

	UpdateLoading("Loading Movement...", 0.70)
	local Movement = LoadModule("movement")
	task.wait(0.2)

	UpdateLoading("Loading Skin Changer...", 0.78)
	local SkinChanger = LoadModule("skinchanger")
	task.wait(0.3)

	UpdateLoading("Loading Animation...", 0.85)
	local Animation = LoadModule("animation")
	task.wait(0.2)

	-- Step 6: Build UI
	UpdateLoading("Building UI...", 0.95)
	if Combat and Combat.BuildUI then
		Combat:BuildUI(Tabs.Combat)
	end
	if RageSystem and RageSystem.BuildUI then
		RageSystem:BuildUI(Tabs.Rage)
	end
	if ESP and ESP.BuildUI then
		ESP:BuildUI(Tabs.Visuals)
	end
	if Visuals and Visuals.BuildUI then
		Visuals:BuildUI(Tabs.Visuals)
	end
	if Movement and Movement.BuildUI then
		Movement:BuildUI(Tabs.Movement)
	end
	if SkinChanger and SkinChanger.BuildUI then
		SkinChanger:BuildUI(Tabs.Skins)
	end

	-- Step 7: Config tab
	local ConfigLeft = Tabs.Config:AddLeftGroupbox("🎨 Themes")
	local ConfigRight = Tabs.Config:AddRightGroupbox("⚙️ Configuration")

	if ThemeManager then
		ThemeManager:SetLibrary(Library)
		ThemeManager:ApplyToGroupbox(ConfigLeft)
	end

	if SaveManager then
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
		SaveManager:SetFolder('aHookSettings')
		SaveManager:BuildConfigSection(Tabs.Config)
	end

	-- Skin Loadouts UI
	local SkinLoadoutGroup = Tabs.Config:AddRightGroupbox("🎨 Skin Loadouts")
	SkinLoadoutGroup:AddDropdown("SkinLoadout_List", {
		Text = "Loadout Preset",
		Values = Storage and Storage:ListSkinLoadouts() or {},
		AllowNull = true
	})

	SkinLoadoutGroup:AddInput("SkinLoadout_Name", {
		Text = "Loadout Name"
	})

	SkinLoadoutGroup:AddButton("Save Loadout", function()
		if not Storage then
			return
		end
		local name = Options.SkinLoadout_Name and Options.SkinLoadout_Name.Value
		if not name or name == '' then
			return
		end
		local loadoutData = {
			weapon = SkinChanger and SkinChanger.CurrentWeapon or nil,
			skin = SkinChanger and SkinChanger.CurrentSkin or nil,
			material = Options.Skin_Material and Options.Skin_Material.Value or nil,
			transparency = Options.Skin_Transparency and Options.Skin_Transparency.Value or 0,
		}
		local success, err = Storage:SaveSkinLoadout(name, loadoutData)
		if success then
			Library:Notify("Saved loadout: " .. name)
			if Options.SkinLoadout_List then
				Options.SkinLoadout_List:SetValues(Storage:ListSkinLoadouts())
			end
		else
			Library:Notify("Failed to save: " .. tostring(err))
		end
	end)

	SkinLoadoutGroup:AddButton("Load Loadout", function()
		if not Storage then
			return
		end
		local name = Options.SkinLoadout_List and Options.SkinLoadout_List.Value
		if not name then
			return
		end
		local success, data = Storage:LoadSkinLoadout(name)
		if success and data then
			if SkinChanger and data.weapon and data.skin then
				SkinChanger:ApplySkin(data.weapon, data.skin)
			end
			if data.material and Options.Skin_Material then
				Options.Skin_Material:SetValue(data.material)
			end
			if data.transparency and Options.Skin_Transparency then
				Options.Skin_Transparency:SetValue(data.transparency)
			end
			Library:Notify("Loaded loadout: " .. name)
		end
	end)

	SkinLoadoutGroup:AddButton("Delete Loadout", function()
		if not Storage then
			return
		end
		local name = Options.SkinLoadout_List and Options.SkinLoadout_List.Value
		if not name then
			return
		end
		Storage:DeleteSkinLoadout(name)
		if Options.SkinLoadout_List then
			Options.SkinLoadout_List:SetValues(Storage:ListSkinLoadouts())
		end
		Library:Notify("Deleted loadout: " .. name)
	end)

	SkinLoadoutGroup:AddButton("Set as Autoload", function()
		if not Storage then
			return
		end
		local name = Options.SkinLoadout_List and Options.SkinLoadout_List.Value
		if not name then
			return
		end
		Storage:SetSkinAutoload(name)
		Library:Notify("Set autoload: " .. name)
	end)

	-- Menu keybind
	local MenuGroup = Tabs.Config:AddLeftGroupbox("Menu")
	MenuGroup:AddButton("Unload", function() Library:Unload() end)
	MenuGroup:AddLabel("Menu Key"):AddKeyPicker("MenuKeybind", {
		Default = "End",
		NoUI = true,
		Text = "Menu Key"
	})
	Library.ToggleKeybind = Options.MenuKeybind

	-- Step 8: Init modules
	if Combat and Combat.Init then
		Combat:Init()
	end
	if RageSystem and RageSystem.Init then
		RageSystem:Init()
	end
	if ESP and ESP.Init then
		ESP:Init()
	end
	if Visuals and Visuals.Init then
		Visuals:Init()
	end
	if Movement and Movement.Init then
		Movement:Init()
	end
	if SkinChanger and SkinChanger.Init then
		SkinChanger:Init()
	end
	if Animation and Animation.SetupHook then
		Animation:SetupHook()
		Animation:SetupCharacterWatcher()
	end

	-- Watermark
	Library:SetWatermarkVisibility(true)
	local frameTimer = tick()
	local frameCounter = 0
	local fps = 60
	local watermarkConn = RunService.RenderStepped:Connect(function()
		frameCounter = frameCounter + 1
		if (tick() - frameTimer) >= 1 then
			fps = frameCounter
			frameTimer = tick()
			frameCounter = 0
		end
		Library:SetWatermark(("aHook | %d fps | %d ms"):format(
			math.floor(fps),
			math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
		))
	end)

	-- Step 9: Load autoload configs
	UpdateLoading("Loading Configs...", 0.97)
	task.wait(0.3)

	if ThemeManager then
		pcall(function()
			ThemeManager:Load()
		end)
	end

	if SaveManager then
		pcall(function()
			SaveManager:LoadAutoloadConfig()
		end)
	end

	if Storage then
		pcall(function()
			local loadoutData = Storage:LoadAutoloadSkin()
			if loadoutData and SkinChanger then
				if loadoutData.weapon and loadoutData.skin then
					SkinChanger:ApplySkin(loadoutData.weapon, loadoutData.skin)
				end
			end
		end)
	end

	-- Step 10: Ready
	UpdateLoading("Ready!", 1.0)
	task.wait(0.5)

	-- Clean up loading screen
	local fadeOut = TweenService:Create(LoadingScreen, TweenInfo.new(0.3), { Enabled = false })
	fadeOut:Play()
	task.wait(0.3)
	LoadingScreen:Destroy()

	-- Notify
	StarterGui:SetCore("SendNotification", {
		Title = "aHook",
		Text = "Loaded successfully!",
		Duration = 3
	})

	-- Unload cleanup
	Library:OnUnload(function()
		watermarkConn:Disconnect()
		if Combat and Combat.Cleanup then Combat:Cleanup() end
		if RageSystem and RageSystem.Cleanup then RageSystem:Cleanup() end
		if ESP and ESP.Cleanup then ESP:Cleanup() end
		if Visuals and Visuals.Cleanup then Visuals:Cleanup() end
		if Movement and Movement.Cleanup then Movement:Cleanup() end
		if SkinChanger and SkinChanger.Cleanup then SkinChanger:Cleanup() end
		if Animation and Animation.Cleanup then Animation:Cleanup() end
	end)
end

local success, err = pcall(RunLoader)
if not success then
	if LoadingScreen then
		LoadingScreen:Destroy()
	end
	StarterGui:SetCore("SendNotification", {
		Title = "aHook",
		Text = "Error loading: " .. tostring(err),
		Duration = 8
	})
	warn("aHook Error: " .. tostring(err))
end
