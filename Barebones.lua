--[[
    Scriptora Barebones Example
    A demonstration of every UI component available in the library.
]]

local Scriptora = loadstring(game:HttpGet("https://raw.githubusercontent.com/sskintbgs/scriptora-lib/refs/heads/main/Source.lua"))()

-- // Create Window
local Hub = Scriptora:CreateWindow({
    Name      = "Scriptora Barebones",
    SubTitle  = "UI Library Showcase",
    Theme     = "Ocean",
    Size      = UDim2.new(0, 600, 0, 450),
    ToggleKey = Enum.KeyCode.RightShift
})

-- // Create Tabs
local BasicTab = Hub:CreateTab({ Name = "Basic Elements", Icon = "rbxassetid://10723346658" })
local AdvancedTab = Hub:CreateTab({ Name = "Advanced", Icon = "rbxassetid://10704987012" })
local SettingsTab = Hub:CreateTab({ Name = "Settings", Icon = "rbxassetid://10723351907" })

-- // BASIC ELEMENTS
BasicTab:AddSection("Standard Inputs")

BasicTab:AddButton({
    Title = "Simple Button",
    Description = "Executes a function when clicked",
    Callback = function()
        Scriptora:Notify({ Title = "Button", Content = "You clicked the button!", Type = "info" })
    end
})

BasicTab:AddToggle({
    Title = "Toggle Switch",
    Description = "An On/Off state manager",
    Default = false,
    Callback = function(v)
        print("Toggle Value:", v)
    end
})

BasicTab:AddSlider({
    Title = "Numeric Slider",
    Description = "Select a value within a range",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 5,
    Suffix = "%",
    Callback = function(v)
        print("Slider Value:", v)
    end
})

-- // ADVANCED ELEMENTS
AdvancedTab:AddSection("Complex Selectors")

AdvancedTab:AddDropdown({
    Title = "Single Select Dropdown",
    Options = {"Option A", "Option B", "Option C", "Option D"},
    Default = "Option A",
    Callback = function(v)
        print("Dropdown Selected:", v)
    end
})

AdvancedTab:AddDropdown({
    Title = "Multi-Select Dropdown",
    Description = "Select multiple items at once",
    Options = {"Red", "Green", "Blue", "Yellow"},
    MultiSelect = true,
    Default = {"Red", "Blue"},
    Callback = function(v)
        print("Multi-Select state changed")
        for color, enabled in pairs(v) do
            if enabled then print(" - " .. color .. " is active") end
        end
    end
})

AdvancedTab:AddSection("Visuals")

AdvancedTab:AddColorPicker({
    Title = "Color Picker",
    Default = Color3.fromRGB(0, 255, 150),
    Callback = function(v)
        print("New Color:", v)
    end
})

AdvancedTab:AddKeybind({
    Title = "Input Keybind",
    Default = Enum.KeyCode.F,
    Callback = function()
        Scriptora:Notify({ Title = "Keybind", Content = "F key was pressed!", Type = "success" })
    end
})

-- // SETTINGS
SettingsTab:AddSection("Configuration")

local themes = {}
for n, _ in pairs(Scriptora.Themes) do table.insert(themes, n) end
SettingsTab:AddDropdown({
    Title = "Change Theme",
    Options = themes,
    Default = "Ocean",
    Callback = function(v)
        Hub:SetTheme(v)
    end
})

SettingsTab:AddButton({
    Title = "Unload UI",
    Callback = function()
        Hub:Destroy()
    end
})

-- // Initial Notification
Scriptora:Notify({
    Title = "Welcome",
    Content = "Barebones showcase loaded successfully.",
    Type = "success"
})
