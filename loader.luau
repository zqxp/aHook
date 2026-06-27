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
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local BaseRepo = "https://cdn.jsdelivr.net/gh/zqxp/aHook@main/"
local ModuleFolder = BaseRepo .. "modules/"

local LoadingScreen = Instance.new("ScreenGui")
LoadingScreen.Name = "aHook_Load"
LoadingScreen.ZIndexBehavior = Enum.ZIndexBehavior.Global
LoadingScreen.ResetOnSpawn = false
LoadingScreen.Parent = CoreGui

local LoadingFrame = Instance.new("Frame")
LoadingFrame.Size = UDim2.new(0, 340, 0, 120)
LoadingFrame.Position = UDim2.new(0.5, -170, 0.5, -60)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
LoadingFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
LoadingFrame.BorderMode = Enum.BorderMode.Inset
LoadingFrame.Parent = LoadingScreen

local LoadingCorner = Instance.new("UICorner")
LoadingCorner.CornerRadius = UDim.new(0, 6)
LoadingCorner.Parent = LoadingFrame

local LoadingStroke = Instance.new("UIStroke")
LoadingStroke.Color = Color3.fromRGB(50, 50, 50)
LoadingStroke.Thickness = 1
LoadingStroke.Parent = LoadingFrame

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Size = UDim2.new(1, 0, 0, 28)
LoadingTitle.Position = UDim2.new(0, 0, 0, 12)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "AHOOK"
LoadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadingTitle.TextSize = 22
LoadingTitle.Font = Enum.Font.Code
LoadingTitle.TextStrokeTransparency = 0.8
LoadingTitle.Parent = LoadingFrame

local LoadingSubtitle = Instance.new("TextLabel")
LoadingSubtitle.Size = UDim2.new(1, 0, 0, 14)
LoadingSubtitle.Position = UDim2.new(0, 0, 0, 40)
LoadingSubtitle.BackgroundTransparency = 1
LoadingSubtitle.Text = "RIVALS INTERNAL"
LoadingSubtitle.TextColor3 = Color3.fromRGB(120, 120, 120)
LoadingSubtitle.TextSize = 11
LoadingSubtitle.Font = Enum.Font.Code
LoadingSubtitle.Parent = LoadingFrame

local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Size = UDim2.new(1, 0, 0, 16)
LoadingStatus.Position = UDim2.new(0, 0, 0, 62)
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Text = "Initializing..."
LoadingStatus.TextColor3 = Color3.fromRGB(160, 160, 160)
LoadingStatus.TextSize = 12
LoadingStatus.Font = Enum.Font.Code
LoadingStatus.Parent = LoadingFrame

local LoadingBar = Instance.new("Frame")
LoadingBar.Size = UDim2.new(0.85, 0, 0, 4)
LoadingBar.Position = UDim2.new(0.075, 0, 0, 88)
LoadingBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LoadingBar.BorderSizePixel = 0
LoadingBar.Parent = LoadingFrame

local LoadingBarCorner = Instance.new("UICorner")
LoadingBarCorner.CornerRadius = UDim.new(0, 2)
LoadingBarCorner.Parent = LoadingBar

local LoadingBarFill = Instance.new("Frame")
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LoadingBarFill.BorderSizePixel = 0
LoadingBarFill.Parent = LoadingBar

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 2)
FillCorner.Parent = LoadingBarFill

local function UpdateLoading(text, percent)
	LoadingStatus.Text = text
	local tween = TweenService:Create(LoadingBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(percent, 0, 1, 0)
	})
	tween:Play()
end

local function FetchModule(url, isLarge)
	local methods = {
		function() return HttpService:GetAsync(url) end,
		function() return game:HttpGet(url) end,
	}
	local retries = isLarge and 4 or 3
	local waitTime = isLarge and 0.8 or 0.4
	for i = 1, retries do
		for _, method in ipairs(methods) do
			local ok, result = pcall(method)
			if ok and type(result) == "string" and #result > 10 then
				return result:gsub("^\239\187\191", ""):gsub("\254\255", ""):gsub("\255\254", "")
			end
		end
		task.wait(waitTime)
	end
	return nil
end

local function TryLoadString(src)
	local fn, err = loadstring(src)
	if not fn then return nil, err end
	local ok, result = pcall(fn)
	if not ok then return nil, result end
	return result
end

local function LoadModule(name)
	local src = FetchModule(ModuleFolder .. name .. ".luau")
	if not src then return nil end
	local mod, err = TryLoadString(src)
	if not mod then warn("aHook: " .. name .. " error: " .. tostring(err)) end
	return mod
end

local function RunLoader()
	UpdateLoading("Loading UI Library...", 0.1)
	local libSrc = FetchModule(BaseRepo .. "library.luau", true)
	if not libSrc then
		local a = FetchModule(BaseRepo .. "library_a.luau")
		if a then
			local b = FetchModule(BaseRepo .. "library_b.luau")
			if b then
				local c = FetchModule(BaseRepo .. "library_c.luau")
				if c then libSrc = a .. b .. c end
			end
		end
	end
	if not libSrc then
		LoadingStatus.Text = "Failed to load UI library"
		task.wait(4)
		LoadingScreen:Destroy()
		return
	end

	local Library, ThemeManager, SaveManager
	do
		local lib, err = TryLoadString(libSrc)
		if not lib then
			LoadingStatus.Text = "Library error: " .. tostring(err):gsub("^.-: ", "")
			task.wait(4)
			LoadingScreen:Destroy()
			return
		end
		Library = lib
	end
	task.wait(0.1)

	Library.FontColor = Color3.fromRGB(220, 220, 220)
	Library.MainColor = Color3.fromRGB(18, 18, 18)
	Library.BackgroundColor = Color3.fromRGB(24, 24, 24)
	Library.AccentColor = Color3.fromRGB(200, 200, 200)
	Library.OutlineColor = Color3.fromRGB(40, 40, 40)
	Library.RiskColor = Color3.fromRGB(255, 60, 60)

	UpdateLoading("Loading Addons...", 0.15)
	local addonSrc = FetchModule(BaseRepo .. "addons.luau")
	if addonSrc then
		local fn, cerr = loadstring(addonSrc)
		if fn then
			local ok, tm, sm = pcall(fn)
			if ok then ThemeManager, SaveManager = tm, sm end
		end
	end
	task.wait(0.1)

	UpdateLoading("Creating Interface...", 0.2)
	local Window = Library:CreateWindow({
		Title = "ahook",
		Center = true,
		AutoShow = false,
	})
	local Tabs = {
		Combat = Window:AddTab("Combat"),
		Rage = Window:AddTab("Rage"),
		Visuals = Window:AddTab("Visuals"),
		Skins = Window:AddTab("Skins"),
		Movement = Window:AddTab("Movement"),
		Config = Window:AddTab("Config"),
	}

	UpdateLoading("Loading Data...", 0.3)
	local Data = LoadModule("data")
	getgenv().Data = Data

	UpdateLoading("Loading Storage...", 0.35)
	local Storage = LoadModule("storage")
	getgenv().Storage = Storage

	UpdateLoading("Loading AntiCheat...", 0.4)
	local AntiCheat = LoadModule("anticheat")

	UpdateLoading("Loading Combat...", 0.45)
	local Combat = LoadModule("combat")

	UpdateLoading("Loading Rage System...", 0.5)
	local RageSystem = LoadModule("ragesystem")

	UpdateLoading("Loading ESP...", 0.55)
	local ESP = LoadModule("esp")

	UpdateLoading("Loading Visuals...", 0.6)
	local Visuals = LoadModule("visuals")

	UpdateLoading("Loading Movement...", 0.65)
	local Movement = LoadModule("movement")

	UpdateLoading("Loading Skin Changer...", 0.7)
	local SkinChanger = LoadModule("skinchanger")

	UpdateLoading("Loading Animation...", 0.75)
	local Animation = LoadModule("animation")

	UpdateLoading("Building UI...", 0.8)
	if Combat and Combat.BuildUI then Combat:BuildUI(Tabs.Combat) end
	if RageSystem and RageSystem.BuildUI then RageSystem:BuildUI(Tabs.Rage) end
	if ESP and ESP.BuildUI then ESP:BuildUI(Tabs.Visuals) end
	if Visuals and Visuals.BuildUI then Visuals:BuildUI(Tabs.Visuals) end
	if Movement and Movement.BuildUI then Movement:BuildUI(Tabs.Movement) end
	if SkinChanger and SkinChanger.BuildUI then SkinChanger:BuildUI(Tabs.Skins) end
	if AntiCheat and AntiCheat.BuildUI then AntiCheat:BuildUI(Tabs.Rage) end

	local ConfigLeft = Tabs.Config:AddLeftGroupbox("Themes")
	local ConfigRight = Tabs.Config:AddRightGroupbox("Configuration")

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

	local SkinLoadoutGroup = Tabs.Config:AddRightGroupbox("Skin Loadouts")
	SkinLoadoutGroup:AddDropdown("SkinLoadout_List", {
		Text = "Loadout",
		Values = Storage and Storage:ListSkinLoadouts() or {},
		AllowNull = true
	})
	SkinLoadoutGroup:AddInput("SkinLoadout_Name", { Text = "Name" })
	SkinLoadoutGroup:AddButton("Save", function()
		if not Storage then return end
		local name = Options and Options.SkinLoadout_Name and Options.SkinLoadout_Name.Value
		if not name or name == '' then return end
		local data = {
			weapon = SkinChanger and SkinChanger.CurrentWeapon,
			skin = SkinChanger and SkinChanger.CurrentSkin,
			material = Options and Options.SkinChanger_Material and Options.SkinChanger_Material.Value,
			transparency = Options and Options.SkinChanger_Transparency and Options.SkinChanger_Transparency.Value or 0,
		}
		local ok, err = Storage:SaveSkinLoadout(name, data)
		if ok then
			Library:Notify("Saved: " .. name)
			if Options and Options.SkinLoadout_List then
				Options.SkinLoadout_List:SetValues(Storage:ListSkinLoadouts())
			end
		end
	end)
	SkinLoadoutGroup:AddButton("Load", function()
		if not Storage then return end
		local name = Options and Options.SkinLoadout_List and Options.SkinLoadout_List.Value
		if not name then return end
		local ok, data = Storage:LoadSkinLoadout(name)
		if ok and data then
			if SkinChanger and data.weapon and data.skin then
				SkinChanger:ApplySkin(data.weapon, data.skin)
			end
			if data.material and Options and Options.SkinChanger_Material then
				Options.SkinChanger_Material:SetValue(data.material)
			end
			if data.transparency and Options and Options.SkinChanger_Transparency then
				Options.SkinChanger_Transparency:SetValue(data.transparency)
			end
			Library:Notify("Loaded: " .. name)
		end
	end)
	SkinLoadoutGroup:AddButton("Delete", function()
		if not Storage then return end
		local name = Options and Options.SkinLoadout_List and Options.SkinLoadout_List.Value
		if not name then return end
		Storage:DeleteSkinLoadout(name)
		if Options and Options.SkinLoadout_List then
			Options.SkinLoadout_List:SetValues(Storage:ListSkinLoadouts())
		end
		Library:Notify("Deleted: " .. name)
	end)
	SkinLoadoutGroup:AddButton("Autoload", function()
		if not Storage then return end
		local name = Options and Options.SkinLoadout_List and Options.SkinLoadout_List.Value
		if not name then return end
		Storage:SetSkinAutoload(name)
		Library:Notify("Autoload: " .. name)
	end)

	local MenuGroup = Tabs.Config:AddLeftGroupbox("Menu")
	MenuGroup:AddButton("Unload", function() Library:Unload() end)
	local MenuKey = MenuGroup:AddLabel("Toggle"):AddKeyPicker("MenuKeybind", {
		Default = "LeftShift",
		NoUI = true,
	})
	Library.ToggleKeybind = MenuKey

	UpdateLoading("Initializing Modules...", 0.85)
	if AntiCheat and AntiCheat.Init then AntiCheat:Init() end
	if Combat and Combat.Init then Combat:Init() end
	if RageSystem and RageSystem.Init then RageSystem:Init() end
	if ESP and ESP.Init then ESP:Init() end
	if Visuals and Visuals.Init then Visuals:Init() end
	if Movement and Movement.Init then Movement:Init() end
	if SkinChanger and SkinChanger.Init then SkinChanger:Init() end
	if Animation and Animation.Init then Animation:Init() end

	Library:SetWatermarkVisibility(false)
	Library:OnUnload(function()
		if AntiCheat and AntiCheat.Cleanup then AntiCheat:Cleanup() end
		if Combat and Combat.Cleanup then Combat:Cleanup() end
		if RageSystem and RageSystem.Cleanup then RageSystem:Cleanup() end
		if ESP and ESP.Cleanup then ESP:Cleanup() end
		if Visuals and Visuals.Cleanup then Visuals:Cleanup() end
		if Movement and Movement.Cleanup then Movement:Cleanup() end
		if SkinChanger and SkinChanger.Cleanup then SkinChanger:Cleanup() end
		if Animation and Animation.Cleanup then Animation:Cleanup() end
	end)

	UpdateLoading("Loading Configs...", 0.9)
	if ThemeManager then pcall(ThemeManager.Load, ThemeManager) end
	if SaveManager then pcall(SaveManager.LoadAutoloadConfig, SaveManager) end
	if Storage then
		local ok, data = Storage:LoadAutoloadSkin()
		if ok and data and SkinChanger then
			if data.weapon and data.skin then
				SkinChanger:ApplySkin(data.weapon, data.skin)
			end
		end
	end
	task.wait(0.2)

	UpdateLoading("Ready", 1.0)
	task.wait(0.4)

	local fadeOut = TweenService:Create(LoadingScreen, TweenInfo.new(0.3), {Enabled = false})
	fadeOut:Play()
	task.wait(0.3)
	LoadingScreen:Destroy()

	StarterGui:SetCore("SendNotification", {
		Title = "ahook",
		Text = "Loaded. Press LeftShift for menu.",
		Duration = 4
	})
end

local ok, err = pcall(RunLoader)
if not ok then
	if LoadingScreen then LoadingScreen:Destroy() end
	StarterGui:SetCore("SendNotification", {
		Title = "ahook",
		Text = "Error: " .. tostring(err),
		Duration = 8
	})
end
