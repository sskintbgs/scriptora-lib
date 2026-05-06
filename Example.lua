--[[
    Scriptora Universal Hub (v9.0)
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
        BoxStyle = "Corners", -- "None", "Full", "Corners"
        BoxFill = false, Names = true, Distance = true, Health = true, HealthText = false,
        Tracers = false, Skeletons = false, HeadCircles = false, Chams = false, LookLines = false,
        Compass = false, OutlineThickness = 1, TextSize = 13, TextFont = 2
    },
    Colors = {
        PlayerColor = Color3.fromRGB(170, 100, 255),
        NPCColor = Color3.fromRGB(255, 255, 0),
        TargetColor = Color3.fromRGB(255, 0, 0), -- New Target Highlight
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
        SpinBot = false, SpinSpeed = 25, AntiAFK = true, ChatSpam = false, SpamText = "Scriptora Universal on top!",
        CamFOV = 70, Hitbox = false, HitboxSize = 2, HitboxParts = {"Head"}, HitboxTeamCheck = true,
    }
}
local ORIGINAL_SIZES = {}

-- // Data Storage
local FOVCircle = Drawing.new("Circle")
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

-- // ESP Class
local function createEntity(ent)
    if ESP_REGISTRY[ent] then return end
    
    local d = {
        Box = Drawing.new("Square"),
        BoxFill = Drawing.new("Square"),
        Corners = {
            Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"),
            Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line")
        },
        Skeleton = {},
        Name = Drawing.new("Text"),
        HealthT = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        HealthBar = Drawing.new("Line"),
        HealthBack = Drawing.new("Line"),
        HeadC = Drawing.new("Circle"),
        LookL = Drawing.new("Line"),
        Arrow = Drawing.new("Triangle"),
    }
    
    -- Setup Defaults
    d.Box.Thickness = 1; d.Box.Outline = true
    d.BoxFill.Thickness = 0; d.BoxFill.Filled = true; d.BoxFill.Transparency = 0.4
    for _, l in ipairs(d.Corners) do l.Thickness = 1.5; l.Outline = true end
    for i=1, 15 do table.insert(d.Skeleton, Drawing.new("Line")) end
    for _, l in ipairs(d.Skeleton) do l.Thickness = 1.5; l.Outline = true end
    d.Name.Center = true; d.Name.Outline = true
    d.HealthT.Outline = true
    d.Tracer.Thickness = 1; d.Tracer.Outline = true
    d.HealthBar.Thickness = 2; d.HealthBar.Outline = true
    d.HealthBack.Thickness = 3; d.HealthBack.Color = Color3.new(0,0,0); d.HealthBack.Transparency = 0.5
    d.HeadC.Thickness = 1; d.HeadC.Outline = true
    d.LookL.Thickness = 1; d.LookL.Outline = true
    d.Arrow.Filled = true; d.Arrow.Thickness = 0
    
    ESP_REGISTRY[ent] = d
end

local function removeEntity(ent)
    local d = ESP_REGISTRY[ent]
    if d then
        for _, obj in pairs(d) do
            if type(obj) == "table" then for _, l in pairs(obj) do l:Remove() end
            elseif obj.Remove then obj:Remove() end
        end
        ESP_REGISTRY[ent] = nil
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
        for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) then table.insert(candidates, v) end end
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
local Hub = Scriptora:CreateWindow({
    Name      = "Scriptora Universal v9.0",
    SubTitle  = "The Infinite Universal",
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
CombatTab:AddDropdown({ Title = "Target Parts", Options = ALL_BONES, MultiSelect = true, Default = {"Head"}, Callback = function(v) Config.Misc.HitboxParts = {} for part, enabled in pairs(v) do if enabled then table.insert(Config.Misc.HitboxParts, part) end end end })

CombatTab:AddSection("Triggerbot")
CombatTab:AddToggle({ Title = "Triggerbot Enabled", Callback = function(v) Config.Triggerbot.Enabled = v end })
CombatTab:AddSlider({ Title = "Trigger Delay (ms)", Min = 0, Max = 500, Default = 0, Callback = function(v) Config.Triggerbot.Delay = v/1000 end })

CombatTab:AddSection("FOV Circle")
CombatTab:AddToggle({ Title = "Show FOV", Default = true, Callback = function(v) Config.Combat.ShowFOV = v end })
CombatTab:AddSlider({ Title = "Radius", Min = 10, Max = 1000, Default = 100, Callback = function(v) Config.Combat.FOV = v end })

-- // VISUALS
VisualsTab:AddSection("Main")
VisualsTab:AddToggle({ Title = "Enabled", Callback = function(v) Config.Visuals.Enabled = v end })
VisualsTab:AddToggle({ Title = "Team Check", Default = true, Callback = function(v) Config.Visuals.TeamCheck = v end })
VisualsTab:AddToggle({ Title = "NPC Support", Callback = function(v) Config.Visuals.NPCSupport = v end })

VisualsTab:AddSection("Box Styles")
VisualsTab:AddDropdown({ Title = "Style", Options = {"None", "Full", "Corners"}, Default = "Corners", Callback = function(v) Config.Visuals.BoxStyle = v end })
VisualsTab:AddToggle({ Title = "Box Filling", Callback = function(v) Config.Visuals.BoxFill = v end })

VisualsTab:AddSection("Advanced Visuals")
VisualsTab:AddToggle({ Title = "Skeletons", Callback = function(v) Config.Visuals.Skeletons = v end })
VisualsTab:AddToggle({ Title = "Chams", Callback = function(v) Config.Visuals.Chams = v end })
VisualsTab:AddToggle({ Title = "Head Circles", Callback = function(v) Config.Visuals.HeadCircles = v end })
VisualsTab:AddToggle({ Title = "Look Lines", Callback = function(v) Config.Visuals.LookLines = v end })
VisualsTab:AddToggle({ Title = "Compass", Callback = function(v) Config.Visuals.Compass = v end })

VisualsTab:AddSection("Information")
VisualsTab:AddToggle({ Title = "Names", Default = true, Callback = function(v) Config.Visuals.Names = v end })
VisualsTab:AddToggle({ Title = "Health Bars", Default = true, Callback = function(v) Config.Visuals.Health = v end })
VisualsTab:AddToggle({ Title = "Health %", Callback = function(v) Config.Visuals.HealthText = v end })
VisualsTab:AddToggle({ Title = "Distance Labels", Default = true, Callback = function(v) Config.Visuals.Distance = v end })
VisualsTab:AddToggle({ Title = "Snaplines", Callback = function(v) Config.Visuals.Tracers = v end })

VisualsTab:AddSection("Style Settings")
VisualsTab:AddSlider({ Title = "Text Size", Min = 10, Max = 25, Default = 13, Callback = function(v) Config.Visuals.TextSize = v end })
VisualsTab:AddSlider({ Title = "Outline Boldness", Min = 1, Max = 5, Default = 1, Callback = function(v) Config.Visuals.OutlineThickness = v end })

-- // COLORS
ColorsTab:AddSection("ESP Colors")
ColorsTab:AddColorPicker({ Title = "Players", Default = Config.Colors.PlayerColor, Callback = function(v) Config.Colors.PlayerColor = v end })
ColorsTab:AddColorPicker({ Title = "NPCs", Default = Config.Colors.NPCColor, Callback = function(v) Config.Colors.NPCColor = v end })
ColorsTab:AddColorPicker({ Title = "Current Target", Default = Config.Colors.TargetColor, Callback = function(v) Config.Colors.TargetColor = v end })
ColorsTab:AddColorPicker({ Title = "Box Fill", Default = Config.Colors.FillColor, Callback = function(v) Config.Colors.FillColor = v end })
ColorsTab:AddColorPicker({ Title = "Chams Glow", Default = Config.Colors.ChamsColor, Callback = function(v) Config.Colors.ChamsColor = v end })
ColorsTab:AddColorPicker({ Title = "Compass Color", Default = Config.Colors.CompassColor, Callback = function(v) Config.Colors.CompassColor = v end })
ColorsTab:AddSection("Indicator Colors")
ColorsTab:AddToggle({ Title = "Rainbow Visuals", Callback = function(v) Config.Visuals.RainbowESP = v end })
ColorsTab:AddColorPicker({ Title = "FOV Circle", Default = Config.Colors.FOVColor, Callback = function(v) Config.Colors.FOVColor = v end })

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
    Hub:Destroy(); FOVCircle:Remove(); for _, d in pairs(ESP_REGISTRY) do for _, obj in pairs(d) do if type(obj) == "table" then for _, l in pairs(obj) do l:Remove() end else obj:Remove() end end end
    for _, c in pairs(CONNECTIONS) do c:Disconnect() end 
end })

-- // RENDERER
local function renderESP(char)
    createEntity(char); local d = ESP_REGISTRY[char]; local hum = char:FindFirstChild("Humanoid"); local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not (hum and hrp and hum.Health > 0 and char.Parent) then
        for _, obj in pairs(d) do if type(obj) == "table" then for _, l in pairs(obj) do l.Visible = false end else obj.Visible = false end end
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
            d.Arrow.Visible = false
            local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
            local scale = (1 / dist) * 1000; local w, h = 2.4 * scale, 4.2 * scale
            local x, y = pos.X - w/2, pos.Y - h/2
            
            d.Box.Visible = Config.Visuals.BoxStyle == "Full"; d.Box.Size = Vector2.new(w, h); d.Box.Position = Vector2.new(x, y); d.Box.Color = col
            d.BoxFill.Visible = Config.Visuals.BoxFill; d.BoxFill.Size = Vector2.new(w, h); d.BoxFill.Position = Vector2.new(x, y); d.BoxFill.Color = Config.Colors.FillColor
            
            if Config.Visuals.BoxStyle == "Corners" then
                local cl = w/4; local c = d.Corners
                c[1].From = Vector2.new(x, y); c[1].To = Vector2.new(x + cl, y)
                c[2].From = Vector2.new(x, y); c[2].To = Vector2.new(x, y + cl)
                c[3].From = Vector2.new(x + w, y); c[3].To = Vector2.new(x + w - cl, y)
                c[4].From = Vector2.new(x + w, y); c[4].To = Vector2.new(x, y + cl) -- Fixed typo
                c[4].To = Vector2.new(x + w, y + cl)
                c[5].From = Vector2.new(x, y + h); c[5].To = Vector2.new(x + cl, y + h)
                c[6].From = Vector2.new(x, y + h); c[6].To = Vector2.new(x, y + h - cl)
                c[7].From = Vector2.new(x + w, y + h); c[7].To = Vector2.new(x + w - cl, y + h)
                c[8].From = Vector2.new(x + w, y + h); c[8].To = Vector2.new(x + w, y + h - cl)
                for _, l in ipairs(c) do l.Visible = true; l.Color = col; l.Thickness = Config.Visuals.OutlineThickness + 0.5 end
            else for _, l in ipairs(d.Corners) do l.Visible = false end end

            d.Name.Visible = Config.Visuals.Names; d.Name.Text = (p and p.DisplayName or char.Name)
            if Config.Visuals.Distance then d.Name.Text = d.Name.Text .. " [" .. math.floor(dist) .. "m]" end
            d.Name.Position = Vector2.new(pos.X, y - 16); d.Name.Color = Color3.new(1,1,1); d.Name.Size = Config.Visuals.TextSize
            
            local hSize = (h * (hum.Health/hum.MaxHealth))
            d.HealthBack.Visible = Config.Visuals.Health; d.HealthBack.From = Vector2.new(x - 6, y + h); d.HealthBack.To = Vector2.new(x - 6, y)
            d.HealthBar.Visible = Config.Visuals.Health; d.HealthBar.From = Vector2.new(x - 6, y + h); d.HealthBar.To = Vector2.new(x - 6, y + h - hSize); d.HealthBar.Color = Color3.new(1-hum.Health/hum.MaxHealth, hum.Health/hum.MaxHealth, 0)
            d.HealthT.Visible = Config.Visuals.HealthText; d.HealthT.Text = math.floor(hum.Health).."%"; d.HealthT.Position = Vector2.new(x - 30, y + h - hSize - 7); d.HealthT.Color = d.HealthBar.Color; d.HealthT.Size = Config.Visuals.TextSize - 1

            d.Tracer.Visible = Config.Visuals.Tracers; d.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); d.Tracer.To = Vector2.new(pos.X, y + h); d.Tracer.Color = col
            
            local head = char:FindFirstChild("Head")
            if Config.Visuals.HeadCircles and head then
                local hpos, hv = Camera:WorldToViewportPoint(head.Position)
                d.HeadC.Visible = hv; d.HeadC.Position = Vector2.new(hpos.X, hpos.Y); d.HeadC.Radius = (scale * 0.45); d.HeadC.Color = col
            else d.HeadC.Visible = false end

            if Config.Visuals.LookLines and head then
                local hpos, hv = Camera:WorldToViewportPoint(head.Position)
                local lookPos, lv = Camera:WorldToViewportPoint(head.Position + head.CFrame.LookVector * 10)
                d.LookL.Visible = hv and lv; d.LookL.From = Vector2.new(hpos.X, hpos.Y); d.LookL.To = Vector2.new(lookPos.X, lookPos.Y); d.LookL.Color = col
            else d.LookL.Visible = false end

            if Config.Visuals.Skeletons then
                local j = {} for _, n in ipairs(ALL_BONES) do local v = char:FindFirstChild(n); if v then local p, o = Camera:WorldToViewportPoint(v.Position); if o then j[n] = Vector2.new(p.X, p.Y) end end end
                local pairs = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}}
                for i, p in ipairs(pairs) do local l = d.Skeleton[i]; if j[p[1]] and j[p[2]] then l.From = j[p[1]]; l.To = j[p[2]]; l.Visible = true; l.Color = col else l.Visible = false end end
            else for _, l in ipairs(d.Skeleton) do l.Visible = false end end

            if Config.Visuals.Chams then
                local h = char:FindFirstChild("ScriptoraHighlight") or Instance.new("Highlight", char)
                h.Name = "ScriptoraHighlight"; h.FillColor = Config.Colors.ChamsColor; h.OutlineColor = Color3.new(1,1,1); h.FillTransparency = 0.5
            elseif char:FindFirstChild("ScriptoraHighlight") then char.ScriptoraHighlight:Destroy() end
        else
            -- Compass
            if Config.Visuals.Compass then
                local screenCenter = Camera.ViewportSize / 2
                local dir = (hrp.Position - Camera.CFrame.Position).Unit
                local angle = math.atan2(dir.Z, dir.X) + math.rad(90)
                local camAngle = math.atan2(Camera.CFrame.LookVector.Z, Camera.CFrame.LookVector.X) + math.rad(90)
                local finalAngle = angle - camAngle
                local arrowPos = screenCenter + Vector2.new(math.cos(finalAngle), math.sin(finalAngle)) * 180
                local p1 = arrowPos + Vector2.new(math.cos(finalAngle), math.sin(finalAngle)) * 15
                local p2 = arrowPos + Vector2.new(math.cos(finalAngle + math.rad(140)), math.sin(finalAngle + math.rad(140))) * 15
                local p3 = arrowPos + Vector2.new(math.cos(finalAngle - math.rad(140)), math.sin(finalAngle - math.rad(140))) * 15
                d.Arrow.Visible = true; d.Arrow.PointA = p1; d.Arrow.PointB = p2; d.Arrow.PointC = p3; d.Arrow.Color = Config.Colors.CompassColor
            else d.Arrow.Visible = false end
            for _, obj in pairs(d) do if obj ~= d.Arrow then if type(obj) == "table" then for _, l in pairs(obj) do l.Visible = false end else obj.Visible = false end end end
        end
    else
        for _, obj in pairs(d) do if type(obj) == "table" then for _, l in pairs(obj) do l.Visible = false end else obj.Visible = false end end
        if char:FindFirstChild("ScriptoraHighlight") then char.ScriptoraHighlight:Destroy() end
    end
end

-- // MAIN
CONNECTIONS.Heartbeat = RunService.Heartbeat:Connect(function()
    FOVCircle.Visible = Config.Combat.ShowFOV and Config.Combat.Aimbot
    FOVCircle.Radius = Config.Combat.FOV; FOVCircle.Position = UserInputService:GetMouseLocation(); FOVCircle.Color = Config.Colors.FOVColor

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
                if Config.Combat.Smoothing > 0 then moveX = moveX/Config.Combat.Smoothing; moveY = moveY/Config.Combat.Smoothing end
                mousemoverel(moveX, moveY)
            elseif Config.Combat.Mode == "Camera (1st Person)" then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
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
                -- Revert sizes if teammate or feature off
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
        for _, v in ipairs(workspace:GetDescendants()) do 
            if v:IsA("Model") and v:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(v) then 
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
    
    -- Fast Registry Cleanup
    for ent, _ in pairs(ESP_REGISTRY) do if not ent or not ent.Parent then removeEntity(ent) end end
end)

CONNECTIONS.Jump = UserInputService.JumpRequest:Connect(function() if Config.Misc.InfiniteJump and LocalPlayer.Character then LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
Scriptora:Notify({ Title = "Scriptora Universal v9.0", Content = "Infinite Universal Hub Loaded.", Type = "success" })
