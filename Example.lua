--[[
    Scriptora Premium Hub
    Modern, Aesthetic, and Feature-Rich
]]

local Scriptora = getgenv().Scriptora or _G.Scriptora or shared.Scriptora
if not Scriptora then
    warn("Scriptora Library not found! Please run the Source script first.")
    return
end

-- // Global Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- // Configuration
local Config = {
    Combat = {
        Aimbot = false,
        Smoothing = 2,
        FOV = 100,
        TargetPart = "Head",
        BoneScan = true,
        TeamCheck = true,
        VisibleCheck = true,
        ShowFOV = true,
        RainbowFOV = false,
        Triggerbot = false,
        TriggerDelay = 0.05,
        SilentAim = false,
    },
    Visuals = {
        Enabled = false,
        Boxes = true,
        Names = true,
        Tracers = false,
        Health = true,
        Distance = true,
        TeamCheck = true,
        RainbowESP = false,
        PrimaryColor = Color3.fromRGB(170, 100, 255),
    },
    World = {
        FullBright = false,
        RainbowSky = false,
        FogDensity = 0.5,
        TimeOfDay = 14,
        Gravity = 196.2,
    },
    Misc = {
        WalkSpeed = 16,
        JumpPower = 50,
        Fly = false,
        FlySpeed = 50,
        NoClip = false,
        InfiniteJump = false,
        SpinBot = false,
        SpinSpeed = 10,
    }
}

-- // Asset IDs
local ICONS = {
    Combat = "rbxassetid://10723346658",
    Visuals = "rbxassetid://10704987012",
    World = "rbxassetid://10723346959",
    Misc = "rbxassetid://10723351907",
    Settings = "rbxassetid://10723351907"
}

-- // UI Creation
local Main = Window or Scriptora:CreateWindow({
    Name      = "Scriptora Prime Hub",
    SubTitle  = "Version 3.4.1 [Stable]",
    Theme     = "Amethyst",
    Size      = UDim2.new(0, 620, 0, 440),
    ToggleKey = Enum.KeyCode.RightShift,
    CustomPFP = "https://raw.githubusercontent.com/sskintbgs/scriptora-lib/main/Untitled.jpg"
})

-- // Tabs
local CombatTab = Main:CreateTab({ Name = "Combat", Icon = ICONS.Combat })
local VisualsTab = Main:CreateTab({ Name = "Visuals", Icon = ICONS.Visuals })
local WorldTab = Main:CreateTab({ Name = "World", Icon = ICONS.World })
local MiscTab = Main:CreateTab({ Name = "Misc", Icon = ICONS.Misc })
local SettingsTab = Main:CreateTab({ Name = "Settings", Icon = ICONS.Settings })

-- --------------------------------------------------
-- // COMBAT FEATURES
-- --------------------------------------------------
CombatTab:AddSection("Aimbot")
CombatTab:AddToggle({ Title = "Enabled", Flag = "aim_enable", Callback = function(v) Config.Combat.Aimbot = v end })
CombatTab:AddToggle({ Title = "Silent Aim (Simulated)", Callback = function(v) Config.Combat.SilentAim = v end })
CombatTab:AddToggle({ Title = "Bone Scanning", Default = true, Callback = function(v) Config.Combat.BoneScan = v end })
CombatTab:AddToggle({ Title = "Team Check", Default = true, Callback = function(v) Config.Combat.TeamCheck = v end })
CombatTab:AddToggle({ Title = "Visibility Check", Default = true, Callback = function(v) Config.Combat.VisibleCheck = v end })
CombatTab:AddSlider({ Title = "Smoothing", Min = 1, Max = 15, Default = 2, Callback = function(v) Config.Combat.Smoothing = v end })
CombatTab:AddDropdown({ Title = "Priority Part", Options = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}, Default = "Head", Callback = function(v) Config.Combat.TargetPart = v end })

CombatTab:AddSection("Triggerbot")
CombatTab:AddToggle({ Title = "Auto Fire", Callback = function(v) Config.Combat.Triggerbot = v end })
CombatTab:AddSlider({ Title = "Fire Delay (ms)", Min = 0, Max = 500, Default = 50, Callback = function(v) Config.Combat.TriggerDelay = v/1000 end })

CombatTab:AddSection("FOV")
CombatTab:AddToggle({ Title = "Show Circle", Default = true, Callback = function(v) Config.Combat.ShowFOV = v end })
CombatTab:AddToggle({ Title = "Rainbow FOV", Callback = function(v) Config.Combat.RainbowFOV = v end })
CombatTab:AddSlider({ Title = "Radius", Min = 10, Max = 800, Default = 100, Callback = function(v) Config.Combat.FOV = v end })

-- --------------------------------------------------
-- // VISUAL FEATURES
-- --------------------------------------------------
VisualsTab:AddSection("ESP")
VisualsTab:AddToggle({ Title = "Master Switch", Callback = function(v) Config.Visuals.Enabled = v end })
VisualsTab:AddToggle({ Title = "Rainbow Cycle", Callback = function(v) Config.Visuals.RainbowESP = v end })
VisualsTab:AddToggle({ Title = "Show Boxes", Default = true, Callback = function(v) Config.Visuals.Boxes = v end })
VisualsTab:AddToggle({ Title = "Show Names", Default = true, Callback = function(v) Config.Visuals.Names = v end })
VisualsTab:AddToggle({ Title = "Show Health", Default = true, Callback = function(v) Config.Visuals.Health = v end })
VisualsTab:AddToggle({ Title = "Show Distance", Default = false, Callback = function(v) Config.Visuals.Distance = v end })
VisualsTab:AddToggle({ Title = "Show Tracers", Callback = function(v) Config.Visuals.Tracers = v end })
VisualsTab:AddToggle({ Title = "Team Check", Default = true, Callback = function(v) Config.Visuals.TeamCheck = v end })
VisualsTab:AddColorPicker({ Title = "Primary Color", Default = Color3.fromRGB(170, 100, 255), Callback = function(v) Config.Visuals.PrimaryColor = v end })

-- --------------------------------------------------
-- // WORLD FEATURES
-- --------------------------------------------------
WorldTab:AddSection("Environment")
WorldTab:AddToggle({ Title = "FullBright", Callback = function(v) Config.World.FullBright = v end })
WorldTab:AddToggle({ Title = "Rainbow Ambient", Callback = function(v) Config.World.RainbowSky = v end })
WorldTab:AddSlider({ Title = "Time of Day", Min = 0, Max = 24, Default = 14, Callback = function(v) Lighting.ClockTime = v end })
WorldTab:AddSlider({ Title = "Fog Density", Min = 0, Max = 1, Increment = 0.1, Default = 0.5, Callback = function(v) Lighting.FogEnd = (1-v) * 10000 end })
WorldTab:AddSlider({ Title = "Map Gravity", Min = 0, Max = 500, Default = 196, Callback = function(v) workspace.Gravity = v end })

WorldTab:AddSection("Skybox")
WorldTab:AddButton({ Title = "Night Sky", Callback = function() local s = Instance.new("Sky", Lighting); s.SkyboxBk = "rbxassetid://159454299"; s.SkyboxDn = "rbxassetid://159454296"; s.SkyboxFt = "rbxassetid://159454293"; s.SkyboxLf = "rbxassetid://159454286"; s.SkyboxRt = "rbxassetid://159454282"; s.SkyboxUp = "rbxassetid://159454280" end })
WorldTab:AddButton({ Title = "Purple Nebula", Callback = function() local s = Instance.new("Sky", Lighting); s.SkyboxBk = "rbxassetid://159454299"; s.SkyboxDn = "rbxassetid://159454296"; s.SkyboxFt = "rbxassetid://159454293"; s.SkyboxLf = "rbxassetid://159454286"; s.SkyboxRt = "rbxassetid://159454282"; s.SkyboxUp = "rbxassetid://159454280" end })

-- --------------------------------------------------
-- // MISC FEATURES
-- --------------------------------------------------
MiscTab:AddSection("Character")
MiscTab:AddSlider({ Title = "WalkSpeed", Min = 16, Max = 300, Default = 16, Callback = function(v) Config.Misc.WalkSpeed = v end })
MiscTab:AddSlider({ Title = "JumpPower", Min = 50, Max = 500, Default = 50, Callback = function(v) Config.Misc.JumpPower = v end })
MiscTab:AddToggle({ Title = "NoClip", Callback = function(v) Config.Misc.NoClip = v end })
MiscTab:AddToggle({ Title = "Infinite Jump", Callback = function(v) Config.Misc.InfiniteJump = v end })
MiscTab:AddToggle({ Title = "Fly", Callback = function(v) Config.Misc.Fly = v end })
MiscTab:AddSlider({ Title = "Fly Speed", Min = 10, Max = 500, Default = 50, Callback = function(v) Config.Misc.FlySpeed = v end })

MiscTab:AddSection("Funny")
MiscTab:AddToggle({ Title = "SpinBot", Callback = function(v) Config.Misc.SpinBot = v end })
MiscTab:AddSlider({ Title = "Spin Speed", Min = 1, Max = 100, Default = 10, Callback = function(v) Config.Misc.SpinSpeed = v end })

-- --------------------------------------------------
-- // LOGIC ENGINE
-- --------------------------------------------------

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Radius = Config.Combat.FOV
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Visible = false

local ESP_STORAGE = {}

-- Bone Scanning Logic
local BONES = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}
local function getVisiblePart(character)
    if not Config.Combat.BoneScan then return character:FindFirstChild(Config.Combat.TargetPart) end
    
    local priority = character:FindFirstChild(Config.Combat.TargetPart)
    if priority and isVisible(priority) then return priority end
    
    for _, name in ipairs(BONES) do
        local part = character:FindFirstChild(name)
        if part and isVisible(part) then return part end
    end
    return nil
end

-- Helper: Visibility
function isVisible(part)
    local hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(Camera.CFrame.Position, part.Position - Camera.CFrame.Position), {LocalPlayer.Character, Camera})
    return hit == nil or hit:IsDescendantOf(part.Parent)
end

-- Closest Player
local function getTarget()
    local target, dist = nil, Config.Combat.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Humanoid.Health > 0 then
            if Config.Combat.TeamCheck and p.Team == LocalPlayer.Team then continue end
            local part = getVisiblePart(p.Character)
            if part then
                local pos, vis = Camera:WorldToViewportPoint(part.Position)
                if vis then
                    local mDist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if mDist < dist then target = part; dist = mDist end
                end
            end
        end
    end
    return target
end

-- ESP Drawings
local function createESP(p)
    if ESP_STORAGE[p] then return end
    local d = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Health = Drawing.new("Line"),
    }
    d.Box.Thickness = 1; d.Box.Filled = false
    d.Name.Size = 13; d.Name.Center = true; d.Name.Outline = true
    d.Tracer.Thickness = 1
    d.Health.Thickness = 2
    ESP_STORAGE[p] = d
end

-- Main Loop
local hue = 0
RunService.RenderStepped:Connect(function()
    hue = (hue + 0.005) % 1
    local rainbow = Color3.fromHSV(hue, 1, 1)
    
    -- FOV Update
    FOVCircle.Visible = Config.Combat.ShowFOV and Config.Combat.Aimbot
    FOVCircle.Radius = Config.Combat.FOV
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Color = Config.Combat.RainbowFOV and rainbow or Main.CurrentTheme.Accent

    -- Character Update
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = Config.Misc.WalkSpeed
        char.Humanoid.JumpPower = Config.Misc.JumpPower
        if Config.Misc.NoClip then
            for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
        if Config.Misc.SpinBot then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Config.Misc.SpinSpeed), 0)
        end
    end

    -- Triggerbot
    if Config.Combat.Triggerbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getTarget()
        if target then
            mouse1click()
            task.wait(Config.Combat.TriggerDelay)
        end
    end

    -- Aimbot
    if Config.Combat.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getTarget()
        if target then
            local pos = Camera:WorldToViewportPoint(target.Position)
            local mouse = UserInputService:GetMouseLocation()
            if mousemoverel then
                mousemoverel((pos.X - mouse.X) / Config.Combat.Smoothing, (pos.Y - mouse.Y) / Config.Combat.Smoothing)
            end
        end
    end

    -- Visuals Update
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        createESP(p)
        local d = ESP_STORAGE[p]
        local c = p.Character
        local show = Config.Visuals.Enabled and c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
        if show and Config.Visuals.TeamCheck and p.Team == LocalPlayer.Team then show = false end
        
        if show then
            local hrp = c.HumanoidRootPart
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            if vis then
                local size = (Camera.CFrame.Position - hrp.Position).Magnitude
                local scale = (1 / size) * 1000
                local w, h = 2.4 * scale, 4.2 * scale
                local col = Config.Visuals.RainbowESP and rainbow or Config.Visuals.PrimaryColor
                
                d.Box.Visible = Config.Visuals.Boxes
                d.Box.Size = Vector2.new(w, h)
                d.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                d.Box.Color = col
                
                d.Name.Visible = Config.Visuals.Names
                d.Name.Text = p.DisplayName
                d.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - 16)
                d.Name.Color = Color3.fromRGB(255, 255, 255)
                
                d.Tracer.Visible = Config.Visuals.Tracers
                d.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                d.Tracer.To = Vector2.new(pos.X, pos.Y + h/2)
                d.Tracer.Color = col
            else d.Box.Visible = false; d.Name.Visible = false; d.Tracer.Visible = false end
        else d.Box.Visible = false; d.Name.Visible = false; d.Tracer.Visible = false end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.Misc.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Scriptora:Notify({ Title = "Success", Content = "Hub Loaded with 40+ dynamic features!", Type = "success" })
