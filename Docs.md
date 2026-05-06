# Scriptora UI Library API Documentation (v9.0)

Scriptora is a high-performance, premium Roblox UI library designed for universal scripts. It features a modern, themed aesthetic with smooth animations and a robust configuration system.

## Table of Contents
1. [Initialization](#initialization)
2. [Window Management](#window-management)
3. [Tab Management](#tab-management)
4. [UI Components](#ui-components)
    - [Toggles](#toggles)
    - [Sliders](#sliders)
    - [Dropdowns (Single/Multi)](#dropdowns)
    - [Color Pickers](#color-pickers)
    - [Keybinds](#keybinds)
    - [Buttons](#buttons)
    - [Sections](#sections)
5. [Utility Functions](#utility-functions)

---

## Initialization
To use the library, load the source via `loadstring`.

```lua
local Scriptora = loadstring(game:HttpGet("https://raw.githubusercontent.com/sskintbgs/scriptora-lib/refs/heads/main/Source.lua"))()
```

## Window Management
Creates the main hub interface.

```lua
local Hub = Scriptora:CreateWindow({
    Name      = "My Script",
    SubTitle  = "Premium Edition",
    Theme     = "Amethyst", -- Themes: Amethyst, Ocean, Emerald, Ruby, Amber, Frost
    Size      = UDim2.new(0, 640, 0, 480),
    ToggleKey = Enum.KeyCode.RightShift,
    CustomPFP = "rbxassetid://0" -- Optional Image ID
})
```

## Tab Management
Tabs categorize your script features.

```lua
local MainTab = Hub:CreateTab({
    Name = "Main",
    Icon = "rbxassetid://10723346658" -- Optional Lucide/Roblox Icon
})
```

## UI Components

### Toggles
A simple On/Off switch.

```lua
MainTab:AddToggle({
    Title = "Aimbot",
    Description = "Automatically locks onto targets", -- Optional
    Default = false,
    Flag = "aim_enabled", -- Flag for Config saving (if implemented)
    Callback = function(Value)
        print("Aimbot is now:", Value)
    end
})
```

### Sliders
Numeric range selector.

```lua
MainTab:AddSlider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Suffix = " studs",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
})
```

### Dropdowns
Supports single or multiple item selection.

**Single Select:**
```lua
MainTab:AddDropdown({
    Title = "Target Bone",
    Options = {"Head", "Torso", "Feet"},
    Default = "Head",
    Callback = function(Value)
        print("Selected:", Value)
    end
})
```

**Multi Select:**
```lua
MainTab:AddDropdown({
    Title = "ESP Options",
    Options = {"Boxes", "Names", "Tracer"},
    MultiSelect = true,
    Default = {"Boxes", "Names"},
    Callback = function(Table)
        for Option, Enabled in pairs(Table) do
            print(Option, "is now", Enabled)
        end
    end
})
```

### Color Pickers
Advanced RGB selector for visuals.

```lua
MainTab:AddColorPicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(170, 100, 255),
    Callback = function(Color)
        print("Color changed to:", Color)
    end
})
```

### Keybinds
Customizable input listeners.

```lua
MainTab:AddKeybind({
    Title = "Panic Key",
    Default = Enum.KeyCode.P,
    Callback = function()
        print("Panic key pressed!")
    end
})
```

### Buttons
Standard clickable elements.

```lua
MainTab:AddButton({
    Title = "Reset Character",
    Callback = function()
        game.Players.LocalPlayer.Character:BreakJoints()
    end
})
```

### Sections
Used to group related elements within a tab.

```lua
MainTab:AddSection("Visual Settings")
```

## Utility Functions

### Notifications
Displays a message on the side of the screen.

```lua
Scriptora:Notify({
    Title   = "Success",
    Content = "Script loaded successfully!",
    Type    = "success", -- Types: success, error, info, warning
    Duration = 5
})
```

### Destroying
Removes the UI completely.

```lua
Hub:Destroy()
```
