--[[
    Scriptora UI Library — Full Example Script
    Updated to use the latest Scriptora engine features.
]]

-- // Load the UI Library
-- Replace the URL with your actual source URL if using loadstring
local Scriptora = _G.Scriptora or shared.Scriptora or getgenv().Scriptora 
if not Scriptora then
    -- Fallback for local testing or if not pre-loaded
    Scriptora = loadstring(game:HttpGet("https://raw.githubusercontent.com/sskintbgs/scriptora-lib/refs/heads/main/Source.lua"))()
end

-- // Create the main window
local Window = Scriptora:CreateWindow({
    Name      = "Scriptora Prime",
    SubTitle  = "Premium Edition",
    Theme     = "Amethyst",      -- Amethyst | Dark | Light | Midnight | Rose | Forest | Ocean | Sunset
    Size      = UDim2.new(0, 620, 0, 440),
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "ScriptoraConfigs",
    ConfigName   = "Default",
    -- Support for GitHub PFP!
    CustomPFP = "https://raw.githubusercontent.com/sskintbgs/scriptora-lib/main/Untitled.jpg",
})

-- // Initial Notification
Scriptora:Notify({
    Title    = "Script Loaded",
    Content  = "Welcome back, " .. game.Players.LocalPlayer.DisplayName .. "!",
    Type     = "success",
    Duration = 5,
})

-- ============================================================
-- // HOME TAB
-- ============================================================
local Home = Window:CreateTab({ Name = "Main", Icon = "🏠" })

Home:AddSection("Information")

Home:AddParagraph({
    Title   = "Scriptora v2.0",
    Content = "The most advanced executor-only UI library. Optimized for performance and aesthetics.",
})

Home:AddLabel("Status: Active")
Home:AddLabel("Executor: " .. Scriptora:GetExecutor())

Home:AddSection("Main Features")

Home:AddToggle({
    Title       = "Kill Aura",
    Description = "Automatically attacks nearby enemies",
    Default     = false,
    Flag        = "kill_aura",
    Callback = function(v)
        print("Kill Aura:", v)
    end,
})

Home:AddSlider({
    Title     = "Aura Range",
    Min       = 5,
    Max       = 50,
    Default   = 15,
    Suffix    = " studs",
    Flag      = "aura_range",
})

Home:AddButton({
    Title       = "Teleport to Safezone",
    Description = "Instantly moves you to the map spawn",
    Callback = function()
        Window:Dialog({
            Title = "Teleport",
            Content = "Are you sure you want to teleport? This might be visible to other players.",
            Buttons = {
                { Text = "Cancel" },
                { 
                    Text = "Teleport", 
                    Primary = true, 
                    Callback = function()
                        print("Teleporting...")
                        local lp = game.Players.LocalPlayer
                        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                            lp.Character.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
                        end
                    end 
                }
            }
        })
    end,
})

-- ============================================================
-- // VISUALS TAB
-- ============================================================
local Visuals = Window:CreateTab({ Name = "Visuals", Icon = "👁" })

Visuals:AddSection("ESP Settings")

Visuals:AddToggle({
    Title   = "Enable ESP",
    Default = false,
    Flag    = "esp_master",
})

Visuals:AddColorPicker({
    Title   = "Box Color",
    Default = Color3.fromRGB(170, 100, 255),
    Flag    = "esp_box_color",
})

Visuals:AddDropdown({
    Title   = "ESP Type",
    Options = { "Boxes", "Corners", "Tracers", "Skeleton", "Head Dots" },
    Default = "Boxes",
    Flag    = "esp_type",
})

Visuals:AddSection("World")

Visuals:AddSlider({
    Title   = "Field of View",
    Min     = 70,
    Max     = 120,
    Default = 90,
    Flag    = "world_fov",
    Callback = function(v)
        workspace.CurrentCamera.FieldOfView = v
    end,
})

Visuals:AddToggle({
    Title   = "Fullbright",
    Default = false,
    Flag    = "world_fullbright",
    Callback = function(v)
        game:GetService("Lighting").Brightness = v and 2 or 1
        game:GetService("Lighting").ClockTime = v and 12 or 14
    end,
})

-- ============================================================
-- // SETTINGS TAB
-- ============================================================
local Settings = Window:CreateTab({ Name = "Misc", Icon = "⚙" })

Settings:AddSection("UI Customization")

Settings:AddDropdown({
    Title    = "Theme",
    Options  = { "Amethyst", "Dark", "Light", "Midnight", "Rose", "Forest", "Ocean", "Sunset" },
    Default  = "Amethyst",
    Callback = function(theme)
        Window:SetTheme(theme)
    end,
})

Settings:AddKeybind({
    Title    = "Toggle Menu",
    Default  = Enum.KeyCode.RightShift,
    Mode     = "Press",
    Callback = function()
        Window:Toggle()
    end,
})

Settings:AddSection("Configuration")

local configInput = Settings:AddInput({
    Title       = "Config File Name",
    Placeholder = "my_config",
    Default     = "Default",
})

Settings:AddButton({
    Title    = "Save Current Config",
    Callback = function()
        local name = configInput.Value
        local success = Window:SaveConfig(name)
        if success then
            Scriptora:Notify({ Title = "Config", Content = "Saved " .. name, Type = "success" })
        end
    end,
})

Settings:AddButton({
    Title    = "Load Selected Config",
    Callback = function()
        local name = configInput.Value
        local success = Window:LoadConfig(name)
        if success then
            Scriptora:Notify({ Title = "Config", Content = "Loaded " .. name, Type = "success" })
        else
            Scriptora:Notify({ Title = "Error", Content = "Config not found", Type = "error" })
        end
    end,
})

Settings:AddDivider()

Settings:AddButton({
    Title    = "Destroy UI",
    Callback = function()
        Window:Destroy()
    end,
})

-- // Background logic example
task.spawn(function()
    while task.wait(1) do
        if Scriptora:GetFlag("kill_aura") then
            -- Logic would go here
        end
    end
end)
