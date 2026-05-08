--[[
    Scriptora Universal Hub (v9.0) - PATCHED v2
    "The Infinite Universal" — 100+ Features
]]

local Scriptora = getgenv().Scriptora or _G.Scriptora or shared.Scriptora
if not Scriptora then
    Scriptora = loadstring(game:HttpGet("https://raw.githubusercontent.com/sskintbgs/scriptora-lib/refs/heads/main/Source.lua"))()
end

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- // Configuration
local Config = {
    Combat = {
        Aimbot = false, Smoothing = 0, FOV = 100, TargetPart = "Head", TeamCheck = true, VisibleCheck = true,
        ShowFOV = true, RainbowFOV = false, NPCSupport = false, BoneScanning = true,
        Method = "Closest to Crosshair", Mode = "Mouse (3rd Person)", 
    },
    Triggerbot = {
        Enabled = false, Delay = 0, TeamCheck = true, NPCSupport = false
    },
    Visuals = {
        Enabled = false, RainbowESP = false, TeamCheck = true, NPCSupport = false,
        BoxStyle = "Corners",
        BoxFill = false, Names = true, Distance = true, Health = true, HealthText = false,
        Tracers = false, Skeletons = false, HeadCircles = false, Chams = false, LookLines = false,
        Compass = false, OutlineThickness = 1, TextSize = 13, TextFont = 2
    },
    Colors = {
        PlayerColor = Color3.fromRGB(170, 100, 255),
        NPCColor = Color3.fromRGB(255, 255, 0),
        TargetColor = Color3.fromRGB(255, 0, 0),
        FillColor = Color3.fromRGB(170, 100, 255),
        ChamsColor = Color3.fromRGB(255, 0, 255),
        FOVColor = Color3.fromRGB(255, 255, 255),
        CompassColor = Color3.fromRGB(255, 255, 255)
    },
    World = {
        FullBright = false, RainbowSky = false, FogDensity = 0.5, TimeOfDay = 14, Gravity = 196,
    },
    Misc = {
        WalkSpeed = 16, JumpPower = 50, Fly = false, FlySpeed = 50, NoClip = false, InfiniteJump = false,
        SpinBot = false, SpinSpeed = 25, AntiAFK = true, ChatSpam = false, SpamText = "Scriptora Universal on top",
        CamFOV = 70, Hitbox = false, HitboxSize = 2, HitboxParts = {"Head"}, HitboxTeamCheck = true,
    }
}
local ORIGINAL_SIZES = {}
local CAPABILITIES = {
    Triangle = false,
    Square = false,
    Circle = false,
    Line = false,
    Text = false,
    Thickness = true,
    Outline = true
}

-- Safe Capability Checker
local function checkCapabilities()
    if type(Drawing) ~= "table" and type(Drawing) ~= "userdata" then return end
    if type(Drawing.new) ~= "function" then return end

    local types = {"Triangle", "Square", "Circle", "Line", "Text"}
    for _, t in ipairs(types) do
        local ok, obj = pcall(function() return Drawing.new(t) end)
        if ok and obj and (typeof(obj) == "userdata" or typeof(obj) == "table") then
            CAPABILITIES[t] = true
            
            if t == "Line" or t == "Square" then
                local tOk = pcall(function() obj.Thickness = 1 end)
                if not tOk then CAPABILITIES.Thickness = false end
                
                local oOk = pcall(function() obj.Outline = true end)
                if not oOk then CAPABILITIES.Outline = false end
            end

            if type(obj.Remove) == "function" then pcall(function() obj:Remove() end)
            elseif type(obj.Destroy) == "function" then pcall(function() obj:Destroy() end) end
        end
    end
end
checkCapabilities()

local function SafeDrawing(t)
    if not CAPABILITIES[t] then return nil end
    local ok, obj = pcall(function() return Drawing.new(t) end)
    if ok and obj and (typeof(obj) == "userdata" or typeof(obj) == "table") then
        return obj
    end
    return nil
end

local FOVCircle = SafeDrawing("Circle")
local ESP_REGISTRY = {}
local CONNECTIONS = {}
local ALL_BONES = {
    "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", 
    "LeftUpperArm", "LeftLowerArm", "LeftHand", 
    "RightUpperArm", "RightLowerArm", "RightHand", 
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", 
    "RightUpperLeg", "RightLowerLeg", "RightFoot"
}
local AimbotTarget = nil
local NPC_LIST = {}

-- Background NPC Scanner
task.spawn(function()
    while task.wait(2) do
        if Config.Visuals.NPCSupport or Config.Combat.NPCSupport or Config.Triggerbot.NPCSupport then
            local list = {}
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) then
                    table.insert(list, v)
                end
            end
            NPC_LIST = list
        else
            NPC_LIST = {}
        end
    end
end)

local function SafeRemove(item)
    if not item then return end
    if type(item) == "table" or type(item) == "userdata" then
        pcall(function()
            if item.Remove then item:Remove()
            elseif item.Destroy then item:Destroy() end
        end)
    end
end

-- // ESP Class
local function createEntity(ent)
    if ESP_REGISTRY[ent] then return end
    
    local d = {
        Box = SafeDrawing("Square"),
        BoxFill = SafeDrawing("Square"),
        Corners = {
            SafeDrawing("Line"), SafeDrawing("Line"), SafeDrawing("Line"), SafeDrawing("Line"),
            SafeDrawing("Line"), SafeDrawing("Line"), SafeDrawing("Line"), SafeDrawing("Line")
        },
        Skeleton = {},
        Name = SafeDrawing("Text"),
        HealthT = SafeDrawing("Text"),
        Tracer = SafeDrawing("Line"),
        HealthBar = SafeDrawing("Line"),
        HealthBack = SafeDrawing("Line"),
        HeadC = SafeDrawing("Circle"),
        LookL = SafeDrawing("Line"),
        Arrow = SafeDrawing("Triangle"),
    }
    
    for i=1, 15 do table.insert(d.Skeleton, SafeDrawing("Line")) end
    
    if d.Box then 
        if CAPABILITIES.Thickness then pcall(function() d.Box.Thickness = 1 end) end
        if CAPABILITIES.Outline then pcall(function() d.Box.Outline = true end) end
    end
    if d.BoxFill then 
        if CAPABILITIES.Thickness then pcall(function() d.BoxFill.Thickness = 0 end) end
        pcall(function() d.BoxFill.Filled = true; d.BoxFill.Transparency = 0.4 end) 
    end
    for _, l in ipairs(d.Corners) do 
        if l then 
            if CAPABILITIES.Thickness then pcall(function() l.Thickness = 1.5 end) end
            if CAPABILITIES.Outline then pcall(function() l.Outline = true end) end
        end 
    end
    for _, l in ipairs(d.Skeleton) do 
        if l then 
            if CAPABILITIES.Thickness then pcall(function() l.Thickness = 1.5 end) end
            if CAPABILITIES.Outline then pcall(function() l.Outline = true end) end
        end 
    end
    if d.Name then 
        pcall(function() d.Name.Center = true end)
        if CAPABILITIES.Outline then pcall(function() d.Name.Outline = true end) end
    end
    if d.HealthT then 
        if CAPABILITIES.Outline then pcall(function() d.HealthT.Outline = true end) end
    end
    if d.Tracer then 
        if CAPABILITIES.Thickness then pcall(function() d.Tracer.Thickness = 1 end) end
        if CAPABILITIES.Outline then pcall(function() d.Tracer.Outline = true end) end
    end
    if d.HealthBar then 
        if CAPABILITIES.Thickness then pcall(function() d.HealthBar.Thickness = 2 end) end
        if CAPABILITIES.Outline then pcall(function() d.HealthBar.Outline = true end) end
    end
    if d.HealthBack then 
        if CAPABILITIES.Thickness then pcall(function() d.HealthBack.Thickness = 3 end) end
        pcall(function() d.HealthBack.Color = Color3.new(0,0,0); d.HealthBack.Transparency = 0.5 end)
    end
    if d.HeadC then 
        if CAPABILITIES.Thickness then pcall(function() d.HeadC.Thickness = 1 end) end
        if CAPABILITIES.Outline then pcall(function() d.HeadC.Outline = true end) end
    end
    if d.LookL then 
        if CAPABILITIES.Thickness then pcall(function() d.LookL.Thickness = 1 end) end
        if CAPABILITIES.Outline then pcall(function() d.LookL.Outline = true end) end
    end
    if d.Arrow then 
        pcall(function() d.Arrow.Filled = true end)
        if CAPABILITIES.Thickness then pcall(function() d.Arrow.Thickness = 0 end) end
    end
    
    ESP_REGISTRY[ent] = d
end

local function removeEntity(ent)
    local d = ESP_REGISTRY[ent]
    if d then
        for key, obj in pairs(d) do
            if key == "Corners" or key == "Skeleton" then 
                for _, l in pairs(obj) do SafeRemove(l) end
            else
                SafeRemove(obj)
            end
        end
        ESP_REGISTRY[ent] = nil
    end
    if ent and ent:FindFirstChild("ScriptoraHighlight") then
        pcall(function() ent.ScriptoraHighlight:Destroy() end)
    end
end

-- // Utility
local function isVisible(part)
    local hit = workspace:FindPartOnRayWithIgnoreList(Ray.new(Camera.CFrame.Position, part.Position - Camera.CFrame.Position), {LocalPlayer.Character, Camera})
    return hit == nil or hit:IsDescendantOf(part.Parent)
end

local function getBestPart(char)
    local main = char:FindFirstChild(Config.Combat.TargetPart)
    if not Config.Combat.BoneScanning then return main end
    if main and isVisible(main) then return main end
    for _, b in ipairs(ALL_BONES) do
        local p = char:FindFirstChild(b)
        if p and isVisible(p) then return p end
    end
    return main
end

local function getTarget()
    local target, bestVal = nil, math.huge
    local candidates = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer and p.Character then table.insert(candidates, p.Character) end end
    if Config.Combat.NPCSupport then
        for _, v in ipairs(NPC_LIST) do if v.Parent then table.insert(candidates, v) end end
    end

    for _, char in ipairs(candidates) do
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            local p = Players:GetPlayerFromCharacter(char)
            if p and Config.Combat.TeamCheck and p.Team == LocalPlayer.Team then continue end
            local part = getBestPart(char)
            if part then
                local pos, vis = Camera:WorldToViewportPoint(part.Position)
                if vis then
                    local mouse = UserInputService:GetMouseLocation()
                    local screenDist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if screenDist <= Config.Combat.FOV then
                        local worldDist = (Camera.CFrame.Position - part.Position).Magnitude
                        local val = (Config.Combat.Method == "Closest to Crosshair" and screenDist) or (Config.Combat.Method == "Closest to Player" and worldDist) or (screenDist + worldDist/10)
                        if val < bestVal then bestVal = val; target = part end
                    end
                end
            end
        end
    end
    return target
end

-- // UI Creation
Scriptora:CreateKeySystem({
    Name = "Scriptora Universal",
    Method = "Hardcoded",
    Keys = {"123"},
    SaveKey = true,
    KeyFolder = "Scriptora",
    OnValidated = function()
        local Hub = Scriptora:CreateWindow({
            Name      = "Scriptora Universal",
            SubTitle  = "The best Utility",
            Theme     = "Amethyst",
            Size      = UDim2.new(0, 660, 0, 500),
            ToggleKey = Enum.KeyCode.RightShift,
            CustomPFP = "https://raw.githubusercontent.com/sskintbgs/scriptora-lib/main/Untitled.jpg"
        })

        local CombatTab = Hub:CreateTab({ Name = "Combat", Icon = "rbxassetid://10723346658" })
        local VisualsTab = Hub:CreateTab({ Name = "Visuals", Icon = "rbxassetid://10704987012" })
        local ColorsTab = Hub:CreateTab({ Name = "Colors", Icon = "rbxassetid://10723351907" })
        local PlayersTab = Hub:CreateTab({ Name = "Players", Icon = "rbxassetid://10723350200" })
        local MiscTab = Hub:CreateTab({ Name = "Misc", Icon = "rbxassetid://10723351907" })
        local SettingsTab = Hub:CreateTab({ Name = "Settings", Icon = "rbxassetid://10723351907" })

        -- // COMBAT
        CombatTab:AddSection("Targeting Engine")
        CombatTab:AddToggle({ Title = "Enabled", Callback = function(v) Config.Combat.Aimbot = v end })
        CombatTab:AddToggle({ Title = "Team Check", Default = true, Callback = function(v) Config.Combat.TeamCheck = v end })
        CombatTab:AddToggle({ Title = "NPC Support", Callback = function(v) Config.Combat.NPCSupport = v end })
        CombatTab:AddToggle({ Title = "Bone Scanning", Default = true, Callback = function(v) Config.Combat.BoneScanning = v end })
        CombatTab:AddSlider({ Title = "Smoothing", Min = 0, Max = 15, Default = 0, Callback = function(v) Config.Combat.Smoothing = v end })
        CombatTab:AddDropdown({ Title = "Method", Options = {"Closest to Crosshair", "Closest to Player", "Smart"}, Default = "Closest to Crosshair", Callback = function(v) Config.Combat.Method = v end })
        CombatTab:AddDropdown({ Title = "Input Mode", Options = {"Mouse (3rd Person)", "Camera (1st Person)"}, Default = "Mouse (3rd Person)", Callback = function(v) Config.Combat.Mode = v end })
        CombatTab:AddDropdown({ Title = "Primary Bone", Options = ALL_BONES, Default = "Head", Callback = function(v) Config.Combat.TargetPart = v end })

        CombatTab:AddSection("Hitbox Expander")
        CombatTab:AddToggle({ Title = "Enabled", Callback = function(v) Config.Misc.Hitbox = v end })
        CombatTab:AddToggle({ Title = "Team Check", Default = true, Callback = function(v) Config.Misc.HitboxTeamCheck = v end })
        CombatTab:AddSlider({ Title = "Hitbox Size", Min = 2, Max = 200, Default = 2, Callback = function(v) Config.Misc.HitboxSize = v end })
        CombatTab:AddDropdown({ Title = "Target Parts", Options = ALL_BONES, MultiSelect = true, Default = {"Head"}, Callback = function(v) Config.Misc.HitboxParts = v end })

        CombatTab:AddSection("Triggerbot")
        CombatTab:AddToggle({ Title = "Triggerbot Enabled", Callback = function(v) Config.Triggerbot.Enabled = v end })
        CombatTab:AddSlider({ Title = "Trigger Delay (ms)", Min = 0, Max = 500, Default = 0, Callback = function(v) Config.Triggerbot.Delay = v/1000 end })

        if CAPABILITIES.Circle then
            CombatTab:AddSection("FOV Circle")
            CombatTab:AddToggle({ Title = "Show FOV", Default = true, Callback = function(v) Config.Combat.ShowFOV = v end })
            CombatTab:AddSlider({ Title = "Radius", Min = 10, Max = 1000, Default = 100, Callback = function(v) Config.Combat.FOV = v end })
        end

        -- // VISUALS
        VisualsTab:AddSection("Main")
        VisualsTab:AddToggle({ Title = "Enabled", Callback = function(v) Config.Visuals.Enabled = v end })
        VisualsTab:AddToggle({ Title = "Team Check", Default = true, Callback = function(v) Config.Visuals.TeamCheck = v end })
        VisualsTab:AddToggle({ Title = "NPC Support", Callback = function(v) Config.Visuals.NPCSupport = v end })

        if CAPABILITIES.Square or CAPABILITIES.Line then
            VisualsTab:AddSection("Box Styles")
            local styles = {"None"}
            if CAPABILITIES.Square then table.insert(styles, "Full") end
            if CAPABILITIES.Line then table.insert(styles, "Corners") end
            VisualsTab:AddDropdown({ Title = "Style", Options = styles, Default = CAPABILITIES.Line and "Corners" or (CAPABILITIES.Square and "Full" or "None"), Callback = function(v) Config.Visuals.BoxStyle = v end })
            if CAPABILITIES.Square then
                VisualsTab:AddToggle({ Title = "Box Filling", Callback = function(v) Config.Visuals.BoxFill = v end })
            end
        end

        if CAPABILITIES.Line or CAPABILITIES.Circle or CAPABILITIES.Triangle then
            VisualsTab:AddSection("Advanced Visuals")
            if CAPABILITIES.Line then
                VisualsTab:AddToggle({ Title = "Skeletons", Callback = function(v) Config.Visuals.Skeletons = v end })
            end
            VisualsTab:AddToggle({ Title = "Chams", Callback = function(v) Config.Visuals.Chams = v end })
            if CAPABILITIES.Circle then
                VisualsTab:AddToggle({ Title = "Head Circles", Callback = function(v) Config.Visuals.HeadCircles = v end })
            end
            if CAPABILITIES.Line then
                VisualsTab:AddToggle({ Title = "Look Lines", Callback = function(v) Config.Visuals.LookLines = v end })
            end
            if CAPABILITIES.Triangle then
                VisualsTab:AddToggle({ Title = "Compass", Default = false, Callback = function(v) Config.Visuals.Compass = v end })
            end
        else
            VisualsTab:AddSection("Advanced Visuals")
            VisualsTab:AddToggle({ Title = "Chams", Callback = function(v) Config.Visuals.Chams = v end })
        end

        if CAPABILITIES.Text or CAPABILITIES.Line then
            VisualsTab:AddSection("Information")
            if CAPABILITIES.Text then
                VisualsTab:AddToggle({ Title = "Names", Default = true, Callback = function(v) Config.Visuals.Names = v end })
            end
            if CAPABILITIES.Line then
                VisualsTab:AddToggle({ Title = "Health Bars", Default = true, Callback = function(v) Config.Visuals.Health = v end })
            end
            if CAPABILITIES.Text then
                VisualsTab:AddToggle({ Title = "Health %", Callback = function(v) Config.Visuals.HealthText = v end })
                VisualsTab:AddToggle({ Title = "Distance Labels", Default = true, Callback = function(v) Config.Visuals.Distance = v end })
            end
            if CAPABILITIES.Line then
                VisualsTab:AddToggle({ Title = "Snaplines", Callback = function(v) Config.Visuals.Tracers = v end })
            end
        end

        if CAPABILITIES.Text or CAPABILITIES.Thickness then
            VisualsTab:AddSection("Style Settings")
            if CAPABILITIES.Text then
                VisualsTab:AddSlider({ Title = "Text Size", Min = 10, Max = 25, Default = 13, Callback = function(v) Config.Visuals.TextSize = v end })
            end
            if CAPABILITIES.Thickness then
                VisualsTab:AddSlider({ Title = "Outline Boldness", Min = 1, Max = 5, Default = 1, Callback = function(v) Config.Visuals.OutlineThickness = v end })
            end
        end

        -- // COLORS
        ColorsTab:AddSection("ESP Colors")
        ColorsTab:AddColorPicker({ Title = "Players", Default = Config.Colors.PlayerColor, Callback = function(v) Config.Colors.PlayerColor = v end })
        ColorsTab:AddColorPicker({ Title = "NPCs", Default = Config.Colors.NPCColor, Callback = function(v) Config.Colors.NPCColor = v end })
        ColorsTab:AddColorPicker({ Title = "Current Target", Default = Config.Colors.TargetColor, Callback = function(v) Config.Colors.TargetColor = v end })
        ColorsTab:AddColorPicker({ Title = "Box Fill", Default = Config.Colors.FillColor, Callback = function(v) Config.Colors.FillColor = v end })
        ColorsTab:AddColorPicker({ Title = "Chams Glow", Default = Config.Colors.ChamsColor, Callback = function(v) Config.Colors.ChamsColor = v end })
        if CAPABILITIES.Triangle then ColorsTab:AddColorPicker({ Title = "Compass Color", Default = Config.Colors.CompassColor, Callback = function(v) Config.Colors.CompassColor = v end }) end
        ColorsTab:AddSection("Indicator Colors")
        ColorsTab:AddToggle({ Title = "Rainbow Visuals", Callback = function(v) Config.Visuals.RainbowESP = v end })
        if CAPABILITIES.Circle then ColorsTab:AddColorPicker({ Title = "FOV Circle", Default = Config.Colors.FOVColor, Callback = function(v) Config.Colors.FOVColor = v end }) end

        -- // MISC
        MiscTab:AddSection("Humanoid Control")
        MiscTab:AddSlider({ Title = "WalkSpeed", Min = 16, Max = 500, Default = 16, Callback = function(v) Config.Misc.WalkSpeed = v end })
        MiscTab:AddSlider({ Title = "JumpPower", Min = 50, Max = 500, Default = 50, Callback = function(v) Config.Misc.JumpPower = v end })
        MiscTab:AddToggle({ Title = "NoClip", Callback = function(v) Config.Misc.NoClip = v end })
        MiscTab:AddToggle({ Title = "Infinite Jump", Callback = function(v) Config.Misc.InfiniteJump = v end })

        MiscTab:AddSection("Movement Tools")
        MiscTab:AddToggle({ Title = "Fly Enabled", Callback = function(v) Config.Misc.Fly = v end })
        MiscTab:AddSlider({ Title = "Fly Speed", Min = 10, Max = 500, Default = 50, Callback = function(v) Config.Misc.FlySpeed = v end })
        MiscTab:AddToggle({ Title = "SpinBot", Callback = function(v) Config.Misc.SpinBot = v end })
        MiscTab:AddSlider({ Title = "Spin Speed", Min = 1, Max = 100, Default = 25, Callback = function(v) Config.Misc.SpinSpeed = v end })

        MiscTab:AddSection("Utility")
        MiscTab:AddToggle({ Title = "Chat Spammer", Callback = function(v) Config.Misc.ChatSpam = v end })
        MiscTab:AddSlider({ Title = "Camera FOV", Min = 70, Max = 120, Default = 70, Callback = function(v) Config.Misc.CamFOV = v; Camera.FieldOfView = v end })
        MiscTab:AddSlider({ Title = "Time of Day", Min = 0, Max = 24, Default = 14, Callback = function(v) Lighting.TimeOfDay = v end })

        -- // PLAYERS
        PlayersTab:AddSection("Target Selection")
        local SelectedPlayer = nil
        local PlayerDropdown = PlayersTab:AddDropdown({ Title = "Select Target", Options = {}, Callback = function(v) SelectedPlayer = Players:FindFirstChild(v) end })
        PlayersTab:AddButton({ Title = "Teleport To", Callback = function() if SelectedPlayer and LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = SelectedPlayer.Character.HumanoidRootPart.CFrame end end })
        PlayersTab:AddButton({ Title = "Spectate", Callback = function() if SelectedPlayer then Camera.CameraSubject = SelectedPlayer.Character.Humanoid end end })
        PlayersTab:AddButton({ Title = "Reset Camera", Callback = function() Camera.CameraSubject = LocalPlayer.Character.Humanoid end })

        local function updateList()
            local n = {}
            for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(n, p.Name) end end
            PlayerDropdown:Refresh(n, true)
        end
        Players.PlayerAdded:Connect(updateList); Players.PlayerRemoving:Connect(updateList); updateList()

        -- // SETTINGS
        SettingsTab:AddSection("System")
        local themes = {}
        for n, _ in pairs(Scriptora.Themes) do table.insert(themes, n) end
        SettingsTab:AddDropdown({ Title = "UI Theme", Options = themes, Default = "Amethyst", Callback = function(v) Hub:SetTheme(v) end })
        SettingsTab:AddKeybind({ Title = "Toggle UI", Default = Enum.KeyCode.RightShift, Callback = function() Hub:Toggle() end })
        SettingsTab:AddButton({ Title = "Unload Script", Callback = function() 
            Hub:Destroy(); SafeRemove(FOVCircle)
            for ent, _ in pairs(ESP_REGISTRY) do removeEntity(ent) end
            for _, p in ipairs(Players:GetPlayers()) do if p.Character then removeEntity(p.Character) end end
            for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("Model") and v:FindFirstChild("Humanoid") then removeEntity(v) end end
            for _, c in pairs(CONNECTIONS) do c:Disconnect() end 
        end })

        -- // RENDERER
        local function hideElements(d, exemptKey)
            for key, obj in pairs(d) do
                if key == exemptKey then continue end
                if key == "Corners" or key == "Skeleton" then
                    for _, l in pairs(obj) do 
                        if l and (type(l) == "table" or type(l) == "userdata") then pcall(function() l.Visible = false end) end 
                    end
                elseif obj and (type(obj) == "table" or type(obj) == "userdata") then
                    pcall(function() obj.Visible = false end)
                end
            end
        end

        local function renderESP(char)
            createEntity(char); local d = ESP_REGISTRY[char]; local hum = char:FindFirstChild("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart")
            
            if not (hum and hrp and hum.Health > 0 and char.Parent) then
                hideElements(d)
                if char:FindFirstChild("ScriptoraHighlight") then char.ScriptoraHighlight:Destroy() end
                return
            end

            local p = Players:GetPlayerFromCharacter(char)
            local show = Config.Visuals.Enabled
            if p then if Config.Visuals.TeamCheck and p.Team == LocalPlayer.Team then show = false end
            elseif not Config.Visuals.NPCSupport then show = false end
            
            if show then
                local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
                local isTarget = (AimbotTarget and AimbotTarget.Parent == char)
                local col = Config.Visuals.RainbowESP and Color3.fromHSV((tick()*0.5)%1, 1, 1) or (isTarget and Config.Colors.TargetColor or (p and Config.Colors.PlayerColor or Config.Colors.NPCColor))
                
                if vis then
                    if d.Arrow then pcall(function() d.Arrow.Visible = false end) end
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    local scale = (1 / dist) * 1000; local w, h = 2.4 * scale, 4.2 * scale
                    local x, y = pos.X - w/2, pos.Y - h/2
                    
                    if d.Box then pcall(function() d.Box.Visible = Config.Visuals.BoxStyle == "Full"; d.Box.Size = Vector2.new(w, h); d.Box.Position = Vector2.new(x, y); d.Box.Color = col end) end
                    if d.BoxFill then pcall(function() d.BoxFill.Visible = Config.Visuals.BoxFill; d.BoxFill.Size = Vector2.new(w, h); d.BoxFill.Position = Vector2.new(x, y); d.BoxFill.Color = Config.Visuals.RainbowESP and col or Config.Colors.FillColor end) end
                    
                    if Config.Visuals.BoxStyle == "Corners" and d.Corners and d.Corners[1] then
                        local cl = w/4; local c = d.Corners
                        pcall(function() c[1].From = Vector2.new(x, y); c[1].To = Vector2.new(x + cl, y) end)
                        pcall(function() c[2].From = Vector2.new(x, y); c[2].To = Vector2.new(x, y + cl) end)
                        pcall(function() c[3].From = Vector2.new(x + w, y); c[3].To = Vector2.new(x + w - cl, y) end)
                        pcall(function() c[4].From = Vector2.new(x + w, y); c[4].To = Vector2.new(x + w, y + cl) end)
                        pcall(function() c[5].From = Vector2.new(x, y + h); c[5].To = Vector2.new(x + cl, y + h) end)
                        pcall(function() c[6].From = Vector2.new(x, y + h); c[6].To = Vector2.new(x, y + h - cl) end)
                        pcall(function() c[7].From = Vector2.new(x + w, y + h); c[7].To = Vector2.new(x + w - cl, y + h) end)
                        pcall(function() c[8].From = Vector2.new(x + w, y + h); c[8].To = Vector2.new(x + w, y + h - cl) end)
                        for _, l in ipairs(c) do if l then pcall(function() l.Visible = true; l.Color = col; if CAPABILITIES.Thickness then l.Thickness = Config.Visuals.OutlineThickness + 0.5 end end) end end
                    else 
                        if d.Corners then for _, l in ipairs(d.Corners) do if l then pcall(function() l.Visible = false end) end end end 
                    end

                    if d.Name then
                        pcall(function()
                            d.Name.Visible = Config.Visuals.Names; d.Name.Text = (p and p.DisplayName or char.Name)
                            if Config.Visuals.Distance then d.Name.Text = d.Name.Text .. " [" .. math.floor(dist) .. "m]" end
                            d.Name.Position = Vector2.new(pos.X, y - 16); d.Name.Color = Color3.new(1,1,1); d.Name.Size = Config.Visuals.TextSize
                        end)
                    end
                    
                    local hSize = (h * (hum.Health/hum.MaxHealth))
                    if d.HealthBack then pcall(function() d.HealthBack.Visible = Config.Visuals.Health; d.HealthBack.From = Vector2.new(x - 6, y + h); d.HealthBack.To = Vector2.new(x - 6, y) end) end
                    if d.HealthBar then pcall(function() d.HealthBar.Visible = Config.Visuals.Health; d.HealthBar.From = Vector2.new(x - 6, y + h); d.HealthBar.To = Vector2.new(x - 6, y + h - hSize); d.HealthBar.Color = Color3.new(1-hum.Health/hum.MaxHealth, hum.Health/hum.MaxHealth, 0) end) end
                    if d.HealthT then pcall(function() d.HealthT.Visible = Config.Visuals.HealthText; d.HealthT.Text = math.floor(hum.Health).."%"; d.HealthT.Position = Vector2.new(x - 30, y + h - hSize - 7); d.HealthT.Color = d.HealthBar and d.HealthBar.Color or Color3.new(0,1,0); d.HealthT.Size = Config.Visuals.TextSize - 1 end) end

                    if d.Tracer then pcall(function() d.Tracer.Visible = Config.Visuals.Tracers; d.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); d.Tracer.To = Vector2.new(pos.X, y + h); d.Tracer.Color = col end) end
                    
                    local head = char:FindFirstChild("Head")
                    if Config.Visuals.HeadCircles and head and d.HeadC then
                        local hpos, hv = Camera:WorldToViewportPoint(head.Position)
                        pcall(function() d.HeadC.Visible = hv; d.HeadC.Position = Vector2.new(hpos.X, hpos.Y); d.HeadC.Radius = (scale * 0.45); d.HeadC.Color = col end)
                    elseif d.HeadC then pcall(function() d.HeadC.Visible = false end) end

                    if Config.Visuals.LookLines and head and d.LookL then
                        local hpos, hv = Camera:WorldToViewportPoint(head.Position)
                        local lookPos, lv = Camera:WorldToViewportPoint(head.Position + head.CFrame.LookVector * 10)
                        pcall(function() d.LookL.Visible = hv and lv; d.LookL.From = Vector2.new(hpos.X, hpos.Y); d.LookL.To = Vector2.new(lookPos.X, lookPos.Y); d.LookL.Color = col end)
                    elseif d.LookL then pcall(function() d.LookL.Visible = false end) end

                    if Config.Visuals.Skeletons and d.Skeleton and #d.Skeleton > 0 then
                        local j = {} for _, n in ipairs(ALL_BONES) do local v = char:FindFirstChild(n); if v then local p, o = Camera:WorldToViewportPoint(v.Position); if o then j[n] = Vector2.new(p.X, p.Y) end end end
                        local pairs = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
                        for i, pair in ipairs(pairs) do local l = d.Skeleton[i]; if l then if j[pair[1]] and j[pair[2]] then pcall(function() l.From = j[pair[1]]; l.To = j[pair[2]]; l.Visible = true; l.Color = col end) else pcall(function() l.Visible = false end) end end end
                    elseif d.Skeleton then for _, l in ipairs(d.Skeleton) do if l then pcall(function() l.Visible = false end) end end end

                    if Config.Visuals.Chams then
                        local h_obj = char:FindFirstChild("ScriptoraHighlight") or Instance.new("Highlight", char)
                        h_obj.Name = "ScriptoraHighlight"
                        h_obj.FillColor = Config.Visuals.RainbowESP and col or Config.Colors.ChamsColor
                        h_obj.OutlineColor = Color3.new(1,1,1); h_obj.FillTransparency = 0.5
                    elseif char:FindFirstChild("ScriptoraHighlight") then char.ScriptoraHighlight:Destroy() end
                else
                    if Config.Visuals.Compass and d.Arrow then
                        local screenCenter = Camera.ViewportSize / 2
                        local dir = (hrp.Position - Camera.CFrame.Position).Unit
                        local angle = math.atan2(dir.Z, dir.X) + math.rad(90)
                        local camAngle = math.atan2(Camera.CFrame.LookVector.Z, Camera.CFrame.LookVector.X) + math.rad(90)
                        local finalAngle = angle - camAngle
                        local arrowPos = screenCenter + Vector2.new(math.cos(finalAngle), math.sin(finalAngle)) * 180
                        local p1 = arrowPos + Vector2.new(math.cos(finalAngle), math.sin(finalAngle)) * 15
                        local p2 = arrowPos + Vector2.new(math.cos(finalAngle + math.rad(140)), math.sin(finalAngle + math.rad(140))) * 15
                        local p3 = arrowPos + Vector2.new(math.cos(finalAngle - math.rad(140)), math.sin(finalAngle - math.rad(140))) * 15
                        pcall(function() d.Arrow.Visible = true; d.Arrow.PointA = p1; d.Arrow.PointB = p2; d.Arrow.PointC = p3; d.Arrow.Color = Config.Colors.CompassColor end)
                    elseif d.Arrow then pcall(function() d.Arrow.Visible = false end) end
                    hideElements(d, "Arrow")
                end
            else
                hideElements(d)
                if char:FindFirstChild("ScriptoraHighlight") then char.ScriptoraHighlight:Destroy() end
            end
        end

        -- // MAIN
        CONNECTIONS.Heartbeat = RunService.Heartbeat:Connect(function()
            if FOVCircle then
                pcall(function()
                    FOVCircle.Visible = Config.Combat.ShowFOV and Config.Combat.Aimbot
                    FOVCircle.Radius = Config.Combat.FOV; FOVCircle.Position = UserInputService:GetMouseLocation(); FOVCircle.Color = Config.Colors.FOVColor
                end)
            end

            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = Config.Misc.WalkSpeed; char.Humanoid.JumpPower = Config.Misc.JumpPower
                if Config.Misc.NoClip then for _, v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end end
                if Config.Misc.Fly then 
                    local vel = Vector3.new(0,0,0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then vel = vel + Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then vel = vel - Vector3.new(0,1,0) end
                    char.HumanoidRootPart.Velocity = vel * Config.Misc.FlySpeed; char.HumanoidRootPart.Anchored = (vel.Magnitude == 0)
                else char.HumanoidRootPart.Anchored = false end
                if Config.Misc.SpinBot then char.Humanoid.AutoRotate = false; char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Config.Misc.SpinSpeed), 0) else char.Humanoid.AutoRotate = true end
            end

            if Config.Combat.Aimbot and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                local t = getTarget()
                AimbotTarget = t
                if t then
                    if Config.Combat.Mode == "Mouse (3rd Person)" and mousemoverel then
                        local pos = Camera:WorldToViewportPoint(t.Position); local m = UserInputService:GetMouseLocation()
                        local moveX, moveY = (pos.X - m.X), (pos.Y - m.Y)
                        local smooth = Config.Combat.Smoothing + 1
                        mousemoverel(moveX / smooth, moveY / smooth)
                    elseif Config.Combat.Mode == "Camera (1st Person)" then
                        local targetCF = CFrame.new(Camera.CFrame.Position, t.Position)
                        if Config.Combat.Smoothing > 0 then
                            Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / (Config.Combat.Smoothing + 1))
                        else
                            Camera.CFrame = targetCF
                        end
                    end
                end
            else
                AimbotTarget = nil
            end

            if Config.Triggerbot.Enabled then
                local t = getTarget()
                if t and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    task.wait(Config.Triggerbot.Delay); if mouse1click then mouse1click() end
                end
            end

            for _, p in ipairs(Players:GetPlayers()) do 
                if p ~= LocalPlayer and p.Character then 
                    renderESP(p.Character)
                    local isTeammate = (Config.Misc.HitboxTeamCheck and p.Team == LocalPlayer.Team)
                    if Config.Misc.Hitbox and not isTeammate then
                        for _, partName in ipairs(Config.Misc.HitboxParts) do
                            local part = p.Character:FindFirstChild(partName)
                            if part and part:IsA("BasePart") then
                                if not ORIGINAL_SIZES[part] then ORIGINAL_SIZES[part] = part.Size end
                                part.Size = Vector3.new(Config.Misc.HitboxSize, Config.Misc.HitboxSize, Config.Misc.HitboxSize)
                                part.Transparency = 0.5
                                part.CanCollide = false
                            end
                        end
                    else
                        for _, v in ipairs(p.Character:GetChildren()) do
                            if v:IsA("BasePart") and ORIGINAL_SIZES[v] then
                                v.Size = ORIGINAL_SIZES[v]
                                v.Transparency = 0
                                ORIGINAL_SIZES[v] = nil
                            end
                        end
                    end
                end 
            end
            
            if Config.Visuals.NPCSupport then 
                for _, v in ipairs(NPC_LIST) do 
                    if v.Parent then
                        renderESP(v)
                        if Config.Misc.Hitbox then
                            for _, partName in ipairs(Config.Misc.HitboxParts) do
                                local part = v:FindFirstChild(partName)
                                if part and part:IsA("BasePart") then
                                    if not ORIGINAL_SIZES[part] then ORIGINAL_SIZES[part] = part.Size end
                                    part.Size = Vector3.new(Config.Misc.HitboxSize, Config.Misc.HitboxSize, Config.Misc.HitboxSize)
                                    part.Transparency = 0.5
                                    part.CanCollide = false
                                end
                            end
                        else
                            for _, b in ipairs(v:GetChildren()) do
                                if b:IsA("BasePart") and ORIGINAL_SIZES[b] then
                                    b.Size = ORIGINAL_SIZES[b]
                                    b.Transparency = 0
                                    ORIGINAL_SIZES[b] = nil
                                end
                            end
                        end
                    end 
                end 
            end

            if Config.Misc.ChatSpam and tick() % 3 < 0.1 then
                local say = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                if say then say.SayMessageRequest:FireServer(Config.Misc.SpamText, "All") end
            end
            
            for ent, _ in pairs(ESP_REGISTRY) do 
                if not ent or not ent.Parent then 
                    removeEntity(ent) 
                elseif not Players:GetPlayerFromCharacter(ent) and not Config.Visuals.NPCSupport then
                    removeEntity(ent)
                end 
            end
        end)

        CONNECTIONS.Jump = UserInputService.JumpRequest:Connect(function() if Config.Misc.InfiniteJump and LocalPlayer.Character then LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
        
        local MissingCapStr = ""
        for k, v in pairs(CAPABILITIES) do if not v then MissingCapStr = MissingCapStr .. k .. ", " end end
        if MissingCapStr ~= "" then
            Scriptora:Notify({ Title = "Compatibility Mode", Content = "Disabled features lacking support: " .. MissingCapStr:sub(1, -3), Type = "warning", Duration = 8 })
        end
        Scriptora:Notify({ Title = "Scriptora Universal", Content = "The best utility", Type = "success" })
    end
})