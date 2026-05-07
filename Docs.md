# Scriptora UI Library v3.0.0 Documentation

**Scriptora** is a professional-grade, executor-only Roblox UI engine designed for stability, aesthetics, and ease of use. It is optimized for loadstring deployment and supports almost all modern executors.

---

## 🚀 Getting Started

### Loadstring
```lua
local Scriptora = loadstring(game:HttpGet("https://raw.githubusercontent.com/sskintbgs/scriptora-lib/main/Source.lua"))()
```

### Initialization
```lua
local Window = Scriptora:CreateWindow({
    Name = "My Script",
    SubTitle = "v1.0.0",
    Theme = "Amethyst", -- See Themes section
    Size = UDim2.new(0, 620, 0, 440),
    ToggleKey = Enum.KeyCode.RightShift,
    CustomPFP = "https://example.com/image.png", -- Optional
    Watermark = true
})
```

---

## 🎨 Themes (16 Presets)
Scriptora v3 comes with 16 high-fidelity color palettes:

- `Amethyst` (Default)
- `Dark`, `Light`, `Midnight`
- `Rose`, `Forest`, `Ocean`, `Sunset`
- `Cyberpunk`, `Dracula`, `Nord`, `Monokai`
- `Blood`, `Neon`, `Catppuccin`, `Gold`

**Live Theme Switching:**
```lua
Window:SetTheme("Cyberpunk")
```

---

## 🔑 Key System
Secure your script with a built-in key system supporting multiple methods.

```lua
Scriptora:CreateKeySystem({
    Name = "My Hub",
    Method = "Hardcoded", -- "Hardcoded" | "URL" | "KeyAuth" | "Panda" | "Custom"
    
    -- Hardcoded Method
    Keys = {"secret123"},
    
    -- URL Method (Advanced)
    URL = "https://your-api.com/validate",
    MethodType = "GET", -- "GET" or "POST"
    KeyParam = "key",   -- Parameter name for GET
    Headers = { ["Authorization"] = "Bearer ..." }, -- Optional
    
    -- KeyAuth Method
    AppName = "MyApp",
    OwnerID = "OwnerID",
    AppSecret = "Secret", -- Optional for some setups
    Version = "1.0",
    
    -- PandaAuth Method
    ServiceID = "YourServiceID",

    -- Custom Method
    ValidateFunc = function(key)
        return key == "custom", "Success message"
    end,

    SaveKey = true,
    KeyFolder = "MyScriptData",
    OnValidated = function()
        -- Start your script here
    end
})
```

---

## 📑 Components

### Tabs
```lua
local Tab = Window:CreateTab({
    Name = "Combat",
    Icon = "rbxassetid://10723346658"
})
```

### Sections
```lua
Tab:AddSection("Targeting")
```

### Buttons
```lua
Tab:AddButton({
    Title = "Print Hello",
    Description = "Prints hello to the console",
    Callback = function()
        print("Hello!")
    end
})
```

### Toggles
```lua
Tab:AddToggle({
    Title = "Aimbot",
    Default = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        print("Aimbot is now:", Value)
    end
})
```

### Sliders
```lua
Tab:AddSlider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Suffix = " studs",
    Flag = "WS_Slider",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
})
```

### Dropdowns
```lua
Tab:AddDropdown({
    Title = "Teleport",
    Options = {"Home", "Shop", "Arena"},
    Default = "Home",
    Flag = "TP_Dropdown",
    Callback = function(Selected)
        print("Teleporting to:", Selected)
    end
})

-- Multi-Select Dropdown
Tab:AddMultiDropdown({
    Title = "Selected Parts",
    Options = {"Head", "Torso", "Arms"},
    Default = {"Head"},
    Callback = function(SelectedList)
        -- SelectedList is a table of selected strings
    end
})
```

### Color Pickers
```lua
Tab:AddColorPicker({
    Title = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Color)
        print("New color chosen:", Color)
    end
})
```

### Keybinds
```lua
Tab:AddKeybind({
    Title = "Quick Exit",
    Default = Enum.KeyCode.X,
    Mode = "Press", -- "Press" | "Toggle" | "Hold"
    Callback = function(State)
        print("Keybind triggered!")
    end
})
```

### Inputs
```lua
Tab:AddInput({
    Title = "Custom Tag",
    Placeholder = "Enter name…",
    NumericOnly = false,
    Callback = function(Text, EnterPressed)
        print("Input:", Text)
    end
})
```

### UI Elements (Static)
- `Tab:AddLabel("Static Text")`
- `Tab:AddParagraph({Title = "Info", Content = "Long description here..."})`
- `Tab:AddDivider()`

---

## 🛠️ Utility Methods

### Notifications
```lua
Scriptora:Notify({
    Title = "Success",
    Content = "Operation completed!",
    Type = "success", -- "success" | "warning" | "error" | "info"
    Duration = 5
})
```

### Dialog Modals
```lua
Window:Dialog({
    Title = "Are you sure?",
    Content = "This will reset all your settings.",
    Buttons = {
        { Text = "Cancel", Callback = function() print("Cancelled") end },
        { Text = "Confirm", Primary = true, Callback = function() print("Confirmed") end }
    }
})
```

### Configurations
```lua
Window:SaveConfig("my_config")
Window:LoadConfig("my_config")
local configs = Window:ListConfigs() -- returns table of names
```

### Cleanup
```lua
Window:Destroy() -- Destroys specific window
Scriptora:DestroyAll() -- Destroys all Scriptora windows
```

---

## 🔒 Security & Privacy
- **Protect GUI:** Automatically uses `syn.protect_gui` or equivalent to hide the UI from Roblox detection.
- **Local Assets:** Fetches and caches images locally to avoid redundant HTTP requests.
- **Executor Compatibility:** Standardized file and HTTP methods across all major platforms.
