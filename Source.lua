--[[
    Scriptora UI Library
    Executor-only Roblox UI engine — designed for loadstring use.

    Usage flow:
        1) Execute this file once. It registers itself globally.
        2) In any subsequent script:
                local Scriptora = getgenv().Scriptora
                local Window = Scriptora:CreateWindow({...})

    Supports: Synapse X, Script-Ware, KRNL, Fluxus, Solara, Wave,
              Hydrogen, Delta, Arceus X, Codex, Trigon, and most other
              modern executors.
]]

-- // Clean up any prior instance so re-running this script is safe
if getgenv and getgenv().Scriptora then
    pcall(function() getgenv().Scriptora:DestroyAll() end)
end

local Scriptora = {}
Scriptora.__index = Scriptora
Scriptora.Version = "2.0.0"
Scriptora.Flags = {}
Scriptora.Connections = {}
Scriptora.Windows = {}

-- ============================================================
-- // SERVICES
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local TextService      = game:GetService("TextService")
local Stats            = game:GetService("Stats")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ============================================================
-- // EXECUTOR COMPAT LAYER
-- ============================================================
local Executor = {}

Executor.identifyexecutor = (identifyexecutor or (syn and syn.identify) or function() return "Unknown" end)

Executor.protectgui = function(gui)
    -- Try every protected-parent technique, fall back to PlayerGui
    local ok = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
        elseif gethui then
            gui.Parent = gethui()
        elseif get_hidden_gui then
            gui.Parent = get_hidden_gui()
        else
            gui.Parent = CoreGui
        end
    end)
    if not ok or not gui.Parent then
        gui.Parent = LP:WaitForChild("PlayerGui")
    end
end

Executor.writefile = (writefile or function() end)
Executor.readfile  = (readfile  or function() return nil end)
Executor.isfile    = (isfile    or function() return false end)
Executor.makefolder = (makefolder or function() end)
Executor.isfolder   = (isfolder   or function() return false end)
Executor.listfiles  = (listfiles  or function() return {} end)
Executor.delfile    = (delfile    or function() end)

Executor.setclipboard = (setclipboard or (toclipboard) or function() end)
Executor.getcustomasset = (getcustomasset or (getsynasset) or function() return "" end)

-- ============================================================
-- // THEMES
-- ============================================================
Scriptora.Themes = {
    Amethyst = {  -- // default purple+black
        Background    = Color3.fromRGB(14, 10, 20),
        Secondary     = Color3.fromRGB(22, 16, 30),
        Tertiary      = Color3.fromRGB(30, 22, 42),
        Element       = Color3.fromRGB(40, 30, 56),
        ElementHover  = Color3.fromRGB(54, 40, 76),
        Border        = Color3.fromRGB(70, 50, 110),
        Accent        = Color3.fromRGB(170, 100, 255),
        AccentHover   = Color3.fromRGB(195, 130, 255),
        AccentDim     = Color3.fromRGB(120, 70, 200),
        Text          = Color3.fromRGB(240, 235, 250),
        SubText       = Color3.fromRGB(170, 155, 200),
        Disabled      = Color3.fromRGB(90, 80, 110),
        Success       = Color3.fromRGB(100, 220, 140),
        Warning       = Color3.fromRGB(255, 180, 80),
        Error         = Color3.fromRGB(255, 90, 110),
        Info          = Color3.fromRGB(100, 180, 255),
    },
    Dark = {
        Background    = Color3.fromRGB(20, 20, 24),
        Secondary     = Color3.fromRGB(28, 28, 33),
        Tertiary      = Color3.fromRGB(36, 36, 42),
        Element       = Color3.fromRGB(44, 44, 51),
        ElementHover  = Color3.fromRGB(54, 54, 62),
        Border        = Color3.fromRGB(50, 50, 58),
        Accent        = Color3.fromRGB(120, 120, 255),
        AccentHover   = Color3.fromRGB(140, 140, 255),
        AccentDim     = Color3.fromRGB(80, 80, 200),
        Text          = Color3.fromRGB(235, 235, 240),
        SubText       = Color3.fromRGB(160, 160, 170),
        Disabled      = Color3.fromRGB(90, 90, 100),
        Success       = Color3.fromRGB(100, 220, 140),
        Warning       = Color3.fromRGB(255, 180, 80),
        Error         = Color3.fromRGB(255, 90, 110),
        Info          = Color3.fromRGB(100, 180, 255),
    },
    Light = {
        Background    = Color3.fromRGB(245, 245, 248),
        Secondary     = Color3.fromRGB(230, 230, 235),
        Tertiary      = Color3.fromRGB(215, 215, 220),
        Element       = Color3.fromRGB(200, 200, 210),
        ElementHover  = Color3.fromRGB(180, 180, 195),
        Border        = Color3.fromRGB(170, 170, 185),
        Accent        = Color3.fromRGB(100, 70, 200),
        AccentHover   = Color3.fromRGB(120, 90, 220),
        AccentDim     = Color3.fromRGB(80, 50, 160),
        Text          = Color3.fromRGB(20, 20, 30),
        SubText       = Color3.fromRGB(80, 80, 100),
        Disabled      = Color3.fromRGB(150, 150, 160),
        Success       = Color3.fromRGB(40, 150, 80),
        Warning       = Color3.fromRGB(200, 130, 40),
        Error         = Color3.fromRGB(200, 50, 70),
        Info          = Color3.fromRGB(50, 120, 200),
    },
    Midnight = {
        Background    = Color3.fromRGB(13, 17, 23),
        Secondary     = Color3.fromRGB(22, 27, 34),
        Tertiary      = Color3.fromRGB(33, 38, 45),
        Element       = Color3.fromRGB(40, 46, 54),
        ElementHover  = Color3.fromRGB(50, 56, 64),
        Border        = Color3.fromRGB(48, 54, 61),
        Accent        = Color3.fromRGB(88, 166, 255),
        AccentHover   = Color3.fromRGB(108, 186, 255),
        AccentDim     = Color3.fromRGB(60, 130, 220),
        Text          = Color3.fromRGB(230, 237, 243),
        SubText       = Color3.fromRGB(139, 148, 158),
        Disabled      = Color3.fromRGB(80, 90, 100),
        Success       = Color3.fromRGB(100, 220, 140),
        Warning       = Color3.fromRGB(255, 180, 80),
        Error         = Color3.fromRGB(255, 90, 110),
        Info          = Color3.fromRGB(100, 180, 255),
    },
    Rose = {
        Background    = Color3.fromRGB(28, 18, 22),
        Secondary     = Color3.fromRGB(38, 24, 30),
        Tertiary      = Color3.fromRGB(48, 32, 38),
        Element       = Color3.fromRGB(58, 40, 46),
        ElementHover  = Color3.fromRGB(70, 48, 56),
        Border        = Color3.fromRGB(66, 46, 54),
        Accent        = Color3.fromRGB(255, 105, 145),
        AccentHover   = Color3.fromRGB(255, 125, 165),
        AccentDim     = Color3.fromRGB(200, 70, 110),
        Text          = Color3.fromRGB(245, 235, 240),
        SubText       = Color3.fromRGB(180, 150, 165),
        Disabled      = Color3.fromRGB(100, 80, 90),
        Success       = Color3.fromRGB(100, 220, 140),
        Warning       = Color3.fromRGB(255, 180, 80),
        Error         = Color3.fromRGB(255, 90, 110),
        Info          = Color3.fromRGB(100, 180, 255),
    },
    Forest = {
        Background    = Color3.fromRGB(12, 18, 14),
        Secondary     = Color3.fromRGB(18, 28, 22),
        Tertiary      = Color3.fromRGB(24, 38, 30),
        Element       = Color3.fromRGB(34, 52, 42),
        ElementHover  = Color3.fromRGB(44, 66, 54),
        Border        = Color3.fromRGB(54, 80, 64),
        Accent        = Color3.fromRGB(80, 220, 120),
        AccentHover   = Color3.fromRGB(100, 255, 150),
        AccentDim     = Color3.fromRGB(50, 160, 90),
        Text          = Color3.fromRGB(220, 245, 230),
        SubText       = Color3.fromRGB(140, 180, 160),
        Disabled      = Color3.fromRGB(70, 90, 80),
        Success       = Color3.fromRGB(100, 220, 140),
        Warning       = Color3.fromRGB(255, 180, 80),
        Error         = Color3.fromRGB(255, 90, 110),
        Info          = Color3.fromRGB(100, 180, 255),
    },
    Ocean = {
        Background    = Color3.fromRGB(10, 18, 28),
        Secondary     = Color3.fromRGB(16, 26, 40),
        Tertiary      = Color3.fromRGB(22, 36, 54),
        Element       = Color3.fromRGB(30, 48, 70),
        ElementHover  = Color3.fromRGB(40, 60, 86),
        Border        = Color3.fromRGB(40, 70, 100),
        Accent        = Color3.fromRGB(80, 200, 230),
        AccentHover   = Color3.fromRGB(110, 220, 245),
        AccentDim     = Color3.fromRGB(50, 150, 190),
        Text          = Color3.fromRGB(225, 240, 250),
        SubText       = Color3.fromRGB(140, 170, 195),
        Disabled      = Color3.fromRGB(80, 100, 120),
        Success       = Color3.fromRGB(100, 220, 140),
        Warning       = Color3.fromRGB(255, 180, 80),
        Error         = Color3.fromRGB(255, 90, 110),
        Info          = Color3.fromRGB(100, 180, 255),
    },
    Sunset = {
        Background    = Color3.fromRGB(20, 12, 16),
        Secondary     = Color3.fromRGB(32, 18, 24),
        Tertiary      = Color3.fromRGB(45, 25, 32),
        Element       = Color3.fromRGB(60, 35, 45),
        ElementHover  = Color3.fromRGB(75, 45, 55),
        Border        = Color3.fromRGB(90, 50, 60),
        Accent        = Color3.fromRGB(255, 120, 60),
        AccentHover   = Color3.fromRGB(255, 150, 80),
        AccentDim     = Color3.fromRGB(180, 80, 40),
        Text          = Color3.fromRGB(255, 240, 230),
        SubText       = Color3.fromRGB(200, 160, 160),
        Disabled      = Color3.fromRGB(100, 80, 85),
        Success       = Color3.fromRGB(100, 220, 140),
        Warning       = Color3.fromRGB(255, 180, 80),
        Error         = Color3.fromRGB(255, 90, 110),
        Info          = Color3.fromRGB(100, 180, 255),
    },
}

-- ============================================================
-- // HELPERS
-- ============================================================
local function tween(obj, time, props, style, dir)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function create(class, props, children)
    local inst = Instance.new(class)
    if props then
        local p = props.Parent
        for k, v in pairs(props) do
            if k ~= "Parent" then inst[k] = v end
        end
        if p then inst.Parent = p end
    end
    if children then
        for _, c in ipairs(children) do c.Parent = inst end
    end
    return inst
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Color3.fromRGB(50,50,58),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function gradient(parent, colors, rotation)
    local cs
    if typeof(colors) == "ColorSequence" then
        cs = colors
    else
        cs = ColorSequence.new(colors)
    end
    return create("UIGradient", {
        Color = cs,
        Rotation = rotation or 0,
        Parent = parent,
    })
end

local function padding(parent, p, l, r, b)
    return create("UIPadding", {
        PaddingTop    = UDim.new(0, p),
        PaddingBottom = UDim.new(0, b or p),
        PaddingLeft   = UDim.new(0, l or p),
        PaddingRight  = UDim.new(0, r or l or p),
        Parent = parent,
    })
end

local function listLayout(parent, pad, dir, hAlign, vAlign)
    return create("UIListLayout", {
        Padding = UDim.new(0, pad or 6),
        FillDirection = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

local function shadow(parent, transparency)
    return create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",  -- soft drop shadow
        ImageColor3 = Color3.new(0,0,0),
        ImageTransparency = transparency or 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 60, 1, 60),
        Position = UDim2.new(0, -30, 0, -30),
        ZIndex = 0,
        Parent = parent,
    })
end

local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function fetchImage(url)
    if not url or url == "" then return "" end
    if not string.find(url, "http") then return url end
    
    local filename = "Scriptora_Asset_" .. (url:gsub("[^%w]", "_"):sub(-30)) .. ".png"
    if Executor.isfile(filename) then 
        return Executor.getcustomasset(filename) 
    end
    
    local success, content = pcall(function() return game:HttpGet(url) end)
    if success then
        pcall(function() Executor.writefile(filename, content) end)
        return Executor.getcustomasset(filename)
    end
    return ""
end

-- ============================================================
-- // NOTIFICATIONS
-- ============================================================
local notifContainer

local function ensureNotifContainer()
    if notifContainer and notifContainer.Parent then return notifContainer end
    local gui = create("ScreenGui", {
        Name = "ScriptoraNotifications",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 999,
    })
    Executor.protectgui(gui)
    notifContainer = create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 320, 1, -32),
        Parent = gui,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = notifContainer,
    })
    return notifContainer
end

function Scriptora:Notify(opts)
    opts = opts or {}
    local title    = opts.Title or "Notification"
    local content  = opts.Content or ""
    local duration = opts.Duration or 4
    local notifType = string.lower(opts.Type or "info")  -- info|success|warning|error
    local theme = self.CurrentTheme or Scriptora.Themes.Amethyst

    local typeColor = theme.Info
    local icon = "i"
    if notifType == "success" then typeColor, icon = theme.Success, "✓"
    elseif notifType == "warning" then typeColor, icon = theme.Warning, "!"
    elseif notifType == "error" then typeColor, icon = theme.Error, "×"
    elseif notifType == "info" then typeColor, icon = theme.Info, "i"
    end

    local container = ensureNotifContainer()

    local notif = create("Frame", {
        BackgroundColor3 = theme.Secondary,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        Parent = container,
    })
    corner(notif, 8)
    stroke(notif, theme.Border, 1)
    shadow(notif, 0.6)

    -- side accent stripe
    local stripe = create("Frame", {
        BackgroundColor3 = typeColor,
        Size = UDim2.new(0, 3, 1, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Parent = notif,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = stripe })

    local pad = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = notif,
    })
    padding(pad, 12, 8, 12, 12)

    local iconLabel = create("TextLabel", {
        BackgroundColor3 = typeColor,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 0, 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = theme.Text,
        Text = icon,
        BackgroundTransparency = 1,
        Parent = pad,
    })
    corner(iconLabel, 9)

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 0, 0),
        Size = UDim2.new(1, -24, 0, 18),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title,
        Parent = pad,
    })

    local contentLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 0, 22),
        Size = UDim2.new(1, -24, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = theme.SubText,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Text = content,
        Parent = pad,
    })

    local bar = create("Frame", {
        BackgroundColor3 = typeColor,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Parent = notif,
    })

    -- slide in
    notif.Position = UDim2.new(1, 50, 0, 0)
    tween(notif, 0.3, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
    tween(stripe, 0.3, { BackgroundTransparency = 0 })
    tween(iconLabel, 0.3, { BackgroundTransparency = 0 })
    tween(titleLabel, 0.3, { TextTransparency = 0 })
    tween(contentLabel, 0.3, { TextTransparency = 0 })
    tween(bar, 0.3, { BackgroundTransparency = 0 })

    task.spawn(function()
        tween(bar, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
        task.wait(duration)
        tween(notif, 0.25, { BackgroundTransparency = 1, Position = UDim2.new(1, 50, 0, 0) })
        tween(stripe, 0.2, { BackgroundTransparency = 1 })
        tween(iconLabel, 0.2, { BackgroundTransparency = 1, TextTransparency = 1 })
        tween(titleLabel, 0.2, { TextTransparency = 1 })
        tween(contentLabel, 0.2, { TextTransparency = 1 })
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- ============================================================
-- // WINDOW
-- ============================================================
function Scriptora:CreateWindow(opts)
    opts = opts or {}
    local W = setmetatable({}, { __index = Scriptora })

    local windowName = opts.Name or "Scriptora"
    local subTitle   = opts.SubTitle or ""
    local themeName  = opts.Theme or "Amethyst"
    local theme      = Scriptora.Themes[themeName] or Scriptora.Themes.Amethyst
    local toggleKey  = opts.ToggleKey or Enum.KeyCode.RightShift
    local size       = opts.Size or UDim2.new(0, 600, 0, 420)
    local minSize    = opts.MinSize or Vector2.new(440, 320)
    local configFolder = opts.ConfigFolder or "Scriptora"
    local configName   = opts.ConfigName or "default"
    local showWatermark = opts.Watermark ~= false  -- true unless explicitly disabled

    W.CurrentTheme     = theme
    W.CurrentThemeName = themeName
    W.ConfigFolder     = configFolder
    W.ConfigName       = configName
    W.Tabs             = {}
    W.AllElements      = {}
    W.ThemedItems      = {}
    function W:themed(inst, map)
        table.insert(W.ThemedItems, { Inst = inst, Map = map })
        return inst
    end
    W.Visible          = true

    -- // Master ScreenGui
    local gui = create("ScreenGui", {
        Name = "Scriptora_" .. windowName,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
    })
    Executor.protectgui(gui)
    W.GUI = gui

    -- // Loading splash
    local splash = create("Frame", {
        BackgroundColor3 = theme.Background,
        Size = UDim2.new(0, 240, 0, 80),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = gui,
    })
    corner(splash, 12)
    stroke(splash, theme.Border, 1)

    local splashTitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 14),
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = theme.Text,
        Text = windowName,
        TextTransparency = 1,
        Parent = splash,
    })
    local splashSub = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = theme.SubText,
        Text = "Initializing…",
        TextTransparency = 1,
        Parent = splash,
    })
    local splashBar = create("Frame", {
        BackgroundColor3 = theme.Element,
        Position = UDim2.new(0.5, -80, 1, -16),
        Size = UDim2.new(0, 160, 0, 3),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Parent = splash,
    })
    corner(splashBar, 2)
    local splashFill = create("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        Parent = splashBar,
    })
    corner(splashFill, 2)

    tween(splash, 0.3, { BackgroundTransparency = 0 })
    tween(splashTitle, 0.3, { TextTransparency = 0 })
    tween(splashSub, 0.3, { TextTransparency = 0 })
    tween(splashBar, 0.3, { BackgroundTransparency = 0 })
    tween(splashFill, 0.6, { Size = UDim2.new(1, 0, 1, 0) })

    -- // Main Frame (hidden until splash done)
    local main = create("Frame", {
        Name = "Main",
        BackgroundColor3 = theme.Background,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        Parent = gui,
    })
    corner(main, 10)
    W:themed(main, { BackgroundColor3 = "Background" })
    W:themed(stroke(main, theme.Border, 1), { Color = "Border" })
    W.Main = main

    -- ------------------ TOP BAR ------------------
    local topBar = create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = theme.Secondary,
        Size = UDim2.new(1, 0, 0, 40),
        BorderSizePixel = 0,
        Parent = main,
    })
    W:themed(topBar, { BackgroundColor3 = "Secondary" })
    -- gradient overlay for flair
    local tbg = gradient(topBar, ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.Secondary),
        ColorSequenceKeypoint.new(1, theme.Tertiary),
    }), 0)
    W:themed(tbg, { Color = function(t) return ColorSequence.new(t.Secondary, t.Tertiary) end })

    -- Mask the bottom-rounded corners of the topbar
    W:themed(create("Frame", {
        BackgroundColor3 = theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        Parent = topBar,
    }), { BackgroundColor3 = "Secondary" })

    -- // Logo / icon
    local pfpUrl = fetchImage(opts.CustomPFP)
    local logo = create(pfpUrl ~= "" and "ImageLabel" or "Frame", {
        BackgroundColor3 = theme.Accent,
        Position = UDim2.new(0, 12, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Image = pfpUrl ~= "" and pfpUrl or "",
        BorderSizePixel = 0,
        Parent = topBar,
    })
    corner(logo, 6)
    W:themed(logo, { BackgroundColor3 = "Accent" })

    if pfpUrl == "" then
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = theme.Text,
            Text = string.sub(windowName, 1, 1):upper(),
            Parent = logo,
        })
    end

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = windowName,
        Parent = topBar,
    })
    W:themed(titleLabel, { TextColor3 = "Text" })

    if subTitle ~= "" then
        local titleSize = TextService:GetTextSize(windowName, 14, Enum.Font.GothamBold, Vector2.new(1000, 100))
        local subLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 40 + titleSize.X + 8, 0, 0),
            Size = UDim2.new(0, 200, 1, 0),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = subTitle,
            Parent = topBar,
        })
        W:themed(subLabel, { TextColor3 = "SubText" })
    end

    -- // Close + Minimize buttons
    local function topBtn(text, hoverColor, x)
        local b = create("TextButton", {
            BackgroundColor3 = theme.Element,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, x, 0.5, -10),
            Size = UDim2.new(0, 20, 0, 20),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = theme.SubText,
            Text = text,
            AutoButtonColor = false,
            Parent = topBar,
        })
        corner(b, 6)
        b.MouseEnter:Connect(function()
            tween(b, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = hoverColor, TextColor3 = theme.Text })
        end)
        b.MouseLeave:Connect(function()
            tween(b, 0.15, { BackgroundTransparency = 1, TextColor3 = theme.SubText })
        end)
        return b
    end

    local closeBtn = topBtn("×", theme.Error, -28)
    local minBtn   = topBtn("–", theme.Accent, -52)

    closeBtn.MouseButton1Click:Connect(function() W:Destroy() end)
    minBtn.MouseButton1Click:Connect(function() W:Toggle() end)

    makeDraggable(main, topBar)

    -- ------------------ SIDEBAR ------------------
    local sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Secondary,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(0, 150, 1, -76),
        BorderSizePixel = 0,
        Parent = main,
    })
    W:themed(sidebar, { BackgroundColor3 = "Secondary" })

    -- Search bar
    local searchHolder = create("Frame", {
        BackgroundColor3 = theme.Tertiary,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 28),
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    W:themed(searchHolder, { BackgroundColor3 = "Tertiary" })
    W:themed(stroke(searchHolder, theme.Border, 1, 0.5), { Color = "Border" })

    local searchIcon = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0, 14, 1, 0),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = theme.SubText,
        Text = "⌕",
        Parent = searchHolder,
    })

    local searchBox = create("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -32, 1, 0),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.SubText,
        PlaceholderText = "Search…",
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "",
        ClearTextOnFocus = false,
        Parent = searchHolder,
    })
    W:themed(searchBox, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })

    local tabHolder = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 44),
        Size = UDim2.new(1, -16, 1, -52),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    listLayout(tabHolder, 4)

    -- ------------------ BOTTOM PLAYER BAR ------------------
    local playerBar = create("Frame", {
        BackgroundColor3 = theme.Secondary,
        Position = UDim2.new(0, 0, 1, -36),
        Size = UDim2.new(0, 150, 0, 36),
        BorderSizePixel = 0,
        Parent = main,
    })
    W:themed(playerBar, { BackgroundColor3 = "Secondary" })

    local avatar = create("ImageLabel", {
        BackgroundColor3 = theme.Element,
        Position = UDim2.new(0, 8, 0.5, -13),
        Size = UDim2.new(0, 26, 0, 26),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=150&height=150&format=png",
        Parent = playerBar,
    })
    corner(avatar, 13)
    stroke(avatar, theme.Accent, 1.5)
    W:themed(avatar, { BackgroundColor3 = "Element" })

    W:themed(create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 4),
        Size = UDim2.new(1, -46, 0, 14),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = LP.DisplayName,
        Parent = playerBar,
    }), { TextColor3 = "Text" })

    W:themed(create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 18),
        Size = UDim2.new(1, -46, 0, 12),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "@" .. LP.Name,
        Parent = playerBar,
    }), { TextColor3 = "SubText" })

    -- ------------------ CONTENT AREA ------------------
    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 150, 0, 40),
        Size = UDim2.new(1, -150, 1, -40),
        Parent = main,
    })

    -- ------------------ RESIZE HANDLE ------------------
    local resizeHandle = create("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 16, 0, 16),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = main,
    })
    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = theme.SubText,
        Text = "⇲",
        Parent = resizeHandle,
    })

    do
        local resizing = false
        local startMouse, startSize
        resizeHandle.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                startMouse = UserInputService:GetMouseLocation()
                startSize = main.AbsoluteSize
            end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
                local m = UserInputService:GetMouseLocation()
                local dx = m.X - startMouse.X
                local dy = m.Y - startMouse.Y
                local nx = math.max(minSize.X, startSize.X + dx)
                local ny = math.max(minSize.Y, startSize.Y + dy)
                main.Size = UDim2.new(0, nx, 0, ny)
                size = main.Size
            end
        end)
    end

    -- ------------------ WATERMARK ------------------
    local watermark
    if showWatermark then
        watermark = create("Frame", {
            BackgroundColor3 = theme.Secondary,
            Position = UDim2.new(0, 12, 0, 12),
            Size = UDim2.new(0, 220, 0, 28),
            BorderSizePixel = 0,
            Parent = gui,
        })
        corner(watermark, 6)
        stroke(watermark, theme.Border, 1)
        shadow(watermark, 0.7)

        local wmLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = theme.Text,
            Text = "Scriptora • loading…",
            Parent = watermark,
        })

        makeDraggable(watermark, watermark)

        task.spawn(function()
            local lastFrame = tick()
            local fps = 60
            while watermark.Parent do
                local now = tick()
                fps = 1 / (now - lastFrame)
                lastFrame = now
                local ping = 0
                pcall(function()
                    ping = math.floor(Stats.PerformanceStats.Ping:GetValue())
                end)
                wmLabel.Text = string.format("Scriptora • %d FPS • %d ms • %s",
                    math.floor(fps), ping, os.date("%H:%M:%S"))
                task.wait(0.5)
            end
        end)
    end

    -- ------------------ TOGGLE KEY ------------------
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then W:Toggle() end
    end)

    -- ------------------ AFTER SPLASH: REVEAL UI ------------------
    task.spawn(function()
        task.wait(0.7)
        tween(splash, 0.3, { BackgroundTransparency = 1 })
        tween(splashTitle, 0.2, { TextTransparency = 1 })
        tween(splashSub, 0.2, { TextTransparency = 1 })
        tween(splashBar, 0.2, { BackgroundTransparency = 1 })
        tween(splashFill, 0.2, { BackgroundTransparency = 1 })
        task.wait(0.3)
        splash:Destroy()

        tween(main, 0.4, { Size = size, BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
    end)

    -- ============================================================
    -- // TAB CREATION
    -- ============================================================
    function W:CreateTab(tabOpts)
        tabOpts = tabOpts or {}
        local tab = {}
        tab.Name = tabOpts.Name or "Tab"
        tab.Icon = tabOpts.Icon or "•"
        tab.Elements = {}

        local tabBtn = create("TextButton", {
            BackgroundColor3 = theme.Tertiary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "  " .. tab.Icon .. "   " .. tab.Name,
            AutoButtonColor = false,
            Parent = tabHolder,
        })
        corner(tabBtn, 6)

        -- left accent indicator
        local accentBar = create("Frame", {
            BackgroundColor3 = theme.Accent,
            Position = UDim2.new(0, 0, 0.5, -6),
            Size = UDim2.new(0, 0, 0, 12),
            BorderSizePixel = 0,
            Parent = tabBtn,
        })
        corner(accentBar, 2)

        tab.Button = tabBtn

        local page = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Element,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            BorderSizePixel = 0,
            Parent = content,
        })
        padding(page, 14)
        listLayout(page, 8)
        tab.Page = page

        local function selectTab()
            for _, t in ipairs(W.Tabs) do
                t.Page.Visible = false
                tween(t.Button, 0.2, { BackgroundTransparency = 1, TextColor3 = theme.SubText })
                local ab = t.Button:FindFirstChildOfClass("Frame")
                if ab then tween(ab, 0.2, { Size = UDim2.new(0, 0, 0, 12) }) end
            end
            page.Visible = true
            tween(tabBtn, 0.2, { BackgroundTransparency = 0, BackgroundColor3 = theme.Tertiary, TextColor3 = theme.Text })
            tween(accentBar, 0.25, { Size = UDim2.new(0, 3, 0, 16) }, Enum.EasingStyle.Back)

            -- fade in elements
            page.Position = UDim2.new(0, 8, 0, 0)
            tween(page, 0.25, { Position = UDim2.new(0, 0, 0, 0) })
        end

        tabBtn.MouseButton1Click:Connect(selectTab)
        tabBtn.MouseEnter:Connect(function()
            if not page.Visible then
                tween(tabBtn, 0.15, { TextColor3 = theme.Text, BackgroundTransparency = 0.7 })
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if not page.Visible then
                tween(tabBtn, 0.15, { TextColor3 = theme.SubText, BackgroundTransparency = 1 })
            end
        end)

        if #W.Tabs == 0 then selectTab() end
        table.insert(W.Tabs, tab)

        -- ====================================================
        -- // ELEMENT REGISTRATION (for search)
        -- ====================================================
        local function registerElement(frame, searchText, name)
            local entry = {
                Frame = frame,
                Name = string.lower(searchText or name or ""),
                DisplayName = name or "",
                Tab = tab,
            }
            table.insert(W.AllElements, entry)
            return entry
        end

        -- ====================================================
        -- // SECTION
        -- ====================================================
        function tab:AddSection(name)
            local section = {}
            local holder = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                Parent = page,
            })
            local label = W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = string.upper(name),
                Parent = holder,
            }), { TextColor3 = "SubText" })
            -- right divider line
            local line = W:themed(create("Frame", {
                BackgroundColor3 = theme.Border,
                BackgroundTransparency = 0.4,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 1),
                BorderSizePixel = 0,
                ZIndex = 0,
                Parent = holder,
            }), { BackgroundColor3 = "Border" })
            -- push label so the line starts after it
            label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                line.Position = UDim2.new(0, label.AbsoluteSize.X + 8, 0.5, 0)
                line.Size = UDim2.new(1, -(label.AbsoluteSize.X + 8), 0, 1)
            end)
            section.Label = label
            return section
        end

        -- ====================================================
        -- // BUTTON
        -- ====================================================
        function tab:AddButton(opts)
            opts = opts or {}
            local btnTitle = opts.Title or opts.Name or "Button"
            local desc = opts.Description or ""
            local callback = opts.Callback or function() end
            local frame = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, desc ~= "" and 50 or 36),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 6)
            W:themed(stroke(frame, theme.Border, 1), { Color = "Border" })

            local btn = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                AutoButtonColor = false,
                Parent = frame,
            })

            local titleLbl = W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, desc ~= "" and 6 or 0),
                Size = desc ~= "" and UDim2.new(1, -34, 0, 18) or UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = btnTitle,
                Parent = frame,
            }), { TextColor3 = "Text" })

            local descLbl
            if desc ~= "" then
                descLbl = W:themed(create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26),
                    Size = UDim2.new(1, -34, 0, 16),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = theme.SubText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = desc,
                    Parent = frame,
                }), { TextColor3 = "SubText" })
            end

            local arrow = W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -22, 0, 0),
                Size = UDim2.new(0, 12, 1, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = theme.SubText,
                Text = "›",
                Parent = frame,
            }), { TextColor3 = "SubText" })

            W:themed(frame, { BackgroundColor3 = "Secondary" })
            W:themed(titleLbl, { TextColor3 = "Text" })
            if descLbl then W:themed(descLbl, { TextColor3 = "SubText" }) end

            btn.MouseEnter:Connect(function()
                tween(frame, 0.15, { BackgroundColor3 = theme.Tertiary })
                tween(arrow, 0.15, { TextColor3 = theme.Accent, Position = UDim2.new(1, -18, 0, 0) })
            end)
            btn.MouseLeave:Connect(function()
                tween(frame, 0.15, { BackgroundColor3 = theme.Secondary })
                tween(arrow, 0.15, { TextColor3 = theme.SubText, Position = UDim2.new(1, -22, 0, 0) })
            end)
            btn.MouseButton1Click:Connect(function()
                tween(frame, 0.08, { BackgroundColor3 = theme.AccentDim })
                task.wait(0.1)
                tween(frame, 0.15, { BackgroundColor3 = theme.Tertiary })
                task.spawn(callback)
            end)

            registerElement(frame, btnTitle .. " " .. desc, btnTitle)
            return frame
        end

        -- ====================================================
        -- // TOGGLE
        -- ====================================================
        function tab:AddToggle(opts)
            opts = opts or {}
            local title = opts.Title or opts.Name or "Toggle"
            local desc = opts.Description or ""
            local default = opts.Default or false
            local flag = opts.Flag
            local callback = opts.Callback or function() end

            local toggle = { Value = default }
            local frame = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, desc ~= "" and 50 or 36),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 6)
            W:themed(stroke(frame, theme.Border, 1), { Color = "Border" })

            local btn = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                AutoButtonColor = false,
                Parent = frame,
            })

            local titleLbl = W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, desc ~= "" and 6 or 0),
                Size = desc ~= "" and UDim2.new(1, -64, 0, 18) or UDim2.new(1, -64, 1, 0),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            }), { TextColor3 = "Text" })

            local descLbl
            if desc ~= "" then
                descLbl = W:themed(create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26),
                    Size = UDim2.new(1, -64, 0, 16),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = theme.SubText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = desc,
                    Parent = frame,
                }), { TextColor3 = "SubText" })
            end

            local switch = W:themed(create("Frame", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(1, -42, 0.5, -10),
                Size = UDim2.new(0, 32, 0, 18),
                BorderSizePixel = 0,
                Parent = frame,
            }), { BackgroundColor3 = function(t) return toggle.Value and t.Accent or t.Element end })
            corner(switch, 9)

            local knob = create("Frame", {
                BackgroundColor3 = theme.Text,
                Position = UDim2.new(0, 2, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                BorderSizePixel = 0,
                Parent = switch,
            })
            corner(knob, 7)

            local function refresh()
                if toggle.Value then
                    tween(switch, 0.2, { BackgroundColor3 = theme.Accent })
                    tween(knob, 0.25, { Position = UDim2.new(1, -16, 0.5, -7) }, Enum.EasingStyle.Back)
                else
                    tween(switch, 0.2, { BackgroundColor3 = theme.Element })
                    tween(knob, 0.25, { Position = UDim2.new(0, 2, 0.5, -7) }, Enum.EasingStyle.Back)
                end
            end

            function toggle:Set(v, silent)
                toggle.Value = v and true or false
                if flag then Scriptora.Flags[flag] = toggle.Value end
                refresh()
                if not silent then task.spawn(callback, toggle.Value) end
            end

            btn.MouseEnter:Connect(function() tween(frame, 0.15, { BackgroundColor3 = theme.Tertiary }) end)
            btn.MouseLeave:Connect(function() tween(frame, 0.15, { BackgroundColor3 = theme.Secondary }) end)
            btn.MouseButton1Click:Connect(function() toggle:Set(not toggle.Value) end)

            if flag then Scriptora.Flags[flag] = default end
            refresh()
            if default then task.spawn(callback, true) end

            registerElement(frame, title .. " " .. desc, title)
            return toggle
        end

        -- ====================================================
        -- // SLIDER
        -- ====================================================
        function tab:AddSlider(opts)
            opts = opts or {}
            local title = opts.Title or opts.Name or "Slider"
            local min = opts.Min or 0
            local max = opts.Max or 100
            local default = math.clamp(opts.Default or min, min, max)
            local increment = opts.Increment or 1
            local suffix = opts.Suffix or ""
            local flag = opts.Flag
            local callback = opts.Callback or function() end

            local slider = { Value = default }

            local frame = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, 56),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 6)
            W:themed(stroke(frame, theme.Border, 1), { Color = "Border" })

            local titleLbl = W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -24, 0, 18),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            }), { TextColor3 = "Text" })

            local valueLabel = W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -24, 0, 18),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = theme.Accent,
                TextXAlignment = Enum.TextXAlignment.Right,
                Text = tostring(default) .. suffix,
                Parent = frame,
            }), { TextColor3 = "Accent" })

            local track = W:themed(create("Frame", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(0, 12, 1, -16),
                Size = UDim2.new(1, -24, 0, 6),
                BorderSizePixel = 0,
                Parent = frame,
            }), { BackgroundColor3 = "Element" })
            corner(track, 3)

            local fill = W:themed(create("Frame", {
                BackgroundColor3 = theme.Accent,
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BorderSizePixel = 0,
                Parent = track,
            }), { BackgroundColor3 = "Accent" })
            corner(fill, 3)
            -- gradient on fill
            gradient(fill, ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme.AccentDim),
                ColorSequenceKeypoint.new(1, theme.Accent),
            }), 0)

            local knob = create("Frame", {
                BackgroundColor3 = theme.Text,
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 14, 0, 14),
                BorderSizePixel = 0,
                Parent = fill,
            })
            corner(knob, 7)
            stroke(knob, theme.Accent, 2)

            local dragging = false
            local function updateFromMouse()
                local rel = math.clamp((Mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local value = min + (max - min) * rel
                value = math.floor(value / increment + 0.5) * increment
                value = math.clamp(value, min, max)
                slider:Set(value)
            end

            function slider:Set(v, silent)
                v = math.clamp(v, min, max)
                slider.Value = v
                if flag then Scriptora.Flags[flag] = v end
                local pct = (v - min) / (max - min)
                tween(fill, 0.1, { Size = UDim2.new(pct, 0, 1, 0) })
                valueLabel.Text = tostring(v) .. suffix
                if not silent then task.spawn(callback, v) end
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    tween(knob, 0.15, { Size = UDim2.new(0, 18, 0, 18) })
                    updateFromMouse()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        tween(knob, 0.15, { Size = UDim2.new(0, 14, 0, 14) })
                    end
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromMouse()
                end
            end)

            if flag then Scriptora.Flags[flag] = default end

            registerElement(frame, title, title)
            return slider
        end

        -- ====================================================
        -- // DROPDOWN
        -- ====================================================
        function tab:AddDropdown(opts)
            opts = opts or {}
            local title = opts.Title or opts.Name or "Dropdown"
            local options = opts.Options or {}
            local default = opts.Default
            local flag = opts.Flag
            local callback = opts.Callback or function() end
            local multi = opts.MultiSelect or false

            local dropdown = {
                Value = multi and (type(default) == "table" and default or {}) or default,
                Options = options,
                Open = false,
            }

            local frame = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, 50),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 6)
            W:themed(stroke(frame, theme.Border, 1), { Color = "Border" })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -24, 0, 16),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            })

            local selectButton = W:themed(create("TextButton", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(0, 12, 0, 24),
                Size = UDim2.new(1, -24, 0, 22),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "  Select…",
                AutoButtonColor = false,
                Parent = frame,
            }), { BackgroundColor3 = "Element", TextColor3 = function(t) return dropdown.Value and t.Text or t.SubText end })
            corner(selectButton, 4)

            local arrow = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -18, 0, 0),
                Size = UDim2.new(0, 14, 1, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = theme.SubText,
                Text = "▼",
                Parent = selectButton,
            })

            local optionsHolder = create("Frame", {
                BackgroundColor3 = theme.Tertiary,
                Position = UDim2.new(0, 12, 0, 50),
                Size = UDim2.new(1, -24, 0, 0),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = frame,
            })
            corner(optionsHolder, 4)
            W:themed(stroke(optionsHolder, theme.Border, 1, 0.5), { Color = "Border" })

            local optionsList = create("ScrollingFrame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = theme.Element,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                Parent = optionsHolder,
            })
            listLayout(optionsList, 2)
            padding(optionsList, 4)

            local function refreshLabel()
                if multi then
                    if #dropdown.Value == 0 then
                        selectButton.Text = "  Select…"
                        selectButton.TextColor3 = theme.SubText
                    elseif #dropdown.Value == 1 then
                        selectButton.Text = "  " .. tostring(dropdown.Value[1])
                        selectButton.TextColor3 = theme.Text
                    else
                        selectButton.Text = "  " .. #dropdown.Value .. " selected"
                        selectButton.TextColor3 = theme.Text
                    end
                else
                    if dropdown.Value == nil then
                        selectButton.Text = "  Select…"
                        selectButton.TextColor3 = theme.SubText
                    else
                        selectButton.Text = "  " .. tostring(dropdown.Value)
                        selectButton.TextColor3 = theme.Text
                    end
                end
            end

            local optionButtons = {}

            local function refreshButtonStates()
                for opt, b in pairs(optionButtons) do
                    local sel = false
                    if multi then
                        for _, v in ipairs(dropdown.Value) do
                            if v == opt then sel = true break end
                        end
                    else
                        sel = (dropdown.Value == opt)
                    end
                    if sel then
                        tween(b, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = theme.Accent, TextColor3 = theme.Text })
                    else
                        tween(b, 0.15, { BackgroundTransparency = 1, TextColor3 = theme.SubText })
                    end
                end
            end

            local function rebuildOptions()
                for _, c in ipairs(optionsList:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                optionButtons = {}
                for _, opt in ipairs(dropdown.Options) do
                    local optBtn = create("TextButton", {
                        BackgroundColor3 = theme.Element,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 22),
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        TextColor3 = theme.SubText,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = "  " .. tostring(opt),
                        AutoButtonColor = false,
                        Parent = optionsList,
                    })
                    corner(optBtn, 4)
                    optionButtons[opt] = optBtn

                    optBtn.MouseEnter:Connect(function()
                        local isSel = false
                        if multi then
                            for _, v in ipairs(dropdown.Value) do
                                if v == opt then isSel = true break end
                            end
                        else isSel = (dropdown.Value == opt) end
                        if not isSel then
                            tween(optBtn, 0.12, { BackgroundTransparency = 0.4, BackgroundColor3 = theme.Element, TextColor3 = theme.Text })
                        end
                    end)
                    optBtn.MouseLeave:Connect(refreshButtonStates)

                    optBtn.MouseButton1Click:Connect(function()
                        if multi then
                            local idx
                            for i, v in ipairs(dropdown.Value) do
                                if v == opt then idx = i break end
                            end
                            if idx then
                                table.remove(dropdown.Value, idx)
                            else
                                table.insert(dropdown.Value, opt)
                            end
                        else
                            dropdown.Value = opt
                            dropdown:Toggle(false)
                        end
                        if flag then Scriptora.Flags[flag] = dropdown.Value end
                        refreshLabel()
                        refreshButtonStates()
                        task.spawn(callback, dropdown.Value)
                    end)
                end
                refreshButtonStates()
            end

            function dropdown:Toggle(state)
                if state == nil then state = not dropdown.Open end
                dropdown.Open = state
                if state then
                    local h = math.min(#dropdown.Options * 24 + 8, 130)
                    tween(frame, 0.25, { Size = UDim2.new(1, 0, 0, 50 + h + 6) })
                    tween(optionsHolder, 0.25, { Size = UDim2.new(1, -24, 0, h) })
                    tween(arrow, 0.2, { Rotation = 180 })
                else
                    tween(frame, 0.25, { Size = UDim2.new(1, 0, 0, 50) })
                    tween(optionsHolder, 0.25, { Size = UDim2.new(1, -24, 0, 0) })
                    tween(arrow, 0.2, { Rotation = 0 })
                end
            end

            function dropdown:Refresh(newOptions, keepSelection)
                dropdown.Options = newOptions or {}
                if not keepSelection then
                    dropdown.Value = multi and {} or nil
                end
                rebuildOptions()
                refreshLabel()
            end

            function dropdown:Set(value, silent)
                dropdown.Value = value
                if flag then Scriptora.Flags[flag] = value end
                refreshLabel()
                refreshButtonStates()
                if not silent then task.spawn(callback, value) end
            end

            selectButton.MouseButton1Click:Connect(function() dropdown:Toggle() end)

            rebuildOptions()
            refreshLabel()
            if flag then Scriptora.Flags[flag] = dropdown.Value end

            registerElement(frame, title, title)
            return dropdown
        end

        function tab:AddMultiDropdown(opts)
            opts = opts or {}
            opts.MultiSelect = true
            return tab:AddDropdown(opts)
        end

        -- ====================================================
        -- // INPUT
        -- ====================================================
        function tab:AddInput(opts)
            opts = opts or {}
            local title = opts.Title or opts.Name or "Input"
            local placeholder = opts.Placeholder or "Type here…"
            local default = opts.Default or ""
            local flag = opts.Flag
            local callback = opts.Callback or function() end
            local clearOnFocus = opts.ClearOnFocus or false
            local numericOnly = opts.NumericOnly or false

            local input = { Value = default }

            local frame = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, 50),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 6)
            W:themed(stroke(frame, theme.Border, 1), { Color = "Border" })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 6),
                Size = UDim2.new(1, -24, 0, 16),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            })

            local box = W:themed(create("TextBox", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(0, 12, 0, 24),
                Size = UDim2.new(1, -24, 0, 22),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.Text,
                PlaceholderColor3 = theme.SubText,
                PlaceholderText = placeholder,
                Text = default,
                ClearTextOnFocus = clearOnFocus,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            }), { BackgroundColor3 = "Element", TextColor3 = "Text", PlaceholderColor3 = "SubText" })
            corner(box, 4)
            padding(box, 0, 6)
            local boxStroke = stroke(box, theme.Border, 1, 0.5)

            box.Focused:Connect(function()
                tween(boxStroke, 0.15, { Color = theme.Accent, Transparency = 0 })
            end)
            box.FocusLost:Connect(function(enter)
                tween(boxStroke, 0.15, { Color = theme.Border, Transparency = 0.5 })
                if numericOnly then
                    box.Text = box.Text:gsub("[^%-%d%.]", "")
                end
                input.Value = box.Text
                if flag then Scriptora.Flags[flag] = box.Text end
                task.spawn(callback, box.Text, enter)
            end)

            function input:Set(v, silent)
                box.Text = tostring(v)
                input.Value = tostring(v)
                if flag then Scriptora.Flags[flag] = input.Value end
                if not silent then task.spawn(callback, input.Value, false) end
            end

            if flag then Scriptora.Flags[flag] = default end
            registerElement(frame, title, title)
            return input
        end

        -- ====================================================
        -- // KEYBIND
        -- ====================================================
        function tab:AddKeybind(opts)
            opts = opts or {}
            local title = opts.Title or opts.Name or "Keybind"
            local default = opts.Default or Enum.KeyCode.Unknown
            local flag = opts.Flag
            local callback = opts.Callback or function() end
            local mode = opts.Mode or "Press"

            local keybind = { Key = default, Listening = false, Toggled = false }

            local frame = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, 36),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 6)
            W:themed(stroke(frame, theme.Border, 1), { Color = "Border" })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -100, 1, 0),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            })

            local btn = create("TextButton", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(1, -82, 0.5, -10),
                Size = UDim2.new(0, 70, 0, 20),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = theme.Text,
                Text = default.Name,
                AutoButtonColor = false,
                Parent = frame,
            })
            corner(btn, 4)
            stroke(btn, theme.Border, 1, 0.5)

            btn.MouseButton1Click:Connect(function()
                keybind.Listening = true
                btn.Text = "[ … ]"
                btn.TextColor3 = theme.Accent
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if keybind.Listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode == Enum.KeyCode.Escape then
                        keybind.Key = Enum.KeyCode.Unknown
                    else
                        keybind.Key = input.KeyCode
                    end
                    keybind.Listening = false
                    btn.Text = keybind.Key.Name
                    btn.TextColor3 = theme.Text
                    if flag then Scriptora.Flags[flag] = keybind.Key end
                    return
                end
                if not gpe and not keybind.Listening and input.KeyCode == keybind.Key then
                    if mode == "Press" then
                        task.spawn(callback)
                    elseif mode == "Toggle" then
                        keybind.Toggled = not keybind.Toggled
                        task.spawn(callback, keybind.Toggled)
                    elseif mode == "Hold" then
                        task.spawn(callback, true)
                    end
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if mode == "Hold" and input.KeyCode == keybind.Key then
                    task.spawn(callback, false)
                end
            end)

            function keybind:Set(key)
                keybind.Key = key
                btn.Text = key.Name
                if flag then Scriptora.Flags[flag] = key end
            end

            if flag then Scriptora.Flags[flag] = default end
            registerElement(frame, title, title)
            return keybind
        end

        -- ====================================================
        -- // COLOR PICKER
        -- ====================================================
        function tab:AddColorPicker(opts)
            opts = opts or {}
            local title = opts.Title or opts.Name or "Color"
            local default = opts.Default or Color3.fromRGB(255, 255, 255)
            local flag = opts.Flag
            local callback = opts.Callback or function() end

            local picker = { Value = default, Open = false }

            local frame = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, 36),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 6)
            W:themed(stroke(frame, theme.Border, 1), { Color = "Border" })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0),
                Size = UDim2.new(1, -50, 0, 36),
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            })

            local swatch = create("TextButton", {
                BackgroundColor3 = default,
                Position = UDim2.new(1, -32, 0.5, -10),
                Size = UDim2.new(0, 22, 0, 20),
                Text = "",
                AutoButtonColor = false,
                Parent = frame,
            })
            corner(swatch, 4)
            stroke(swatch, theme.Border, 1)

            local pickerFrame = W:themed(create("Frame", {
                BackgroundColor3 = theme.Tertiary,
                Position = UDim2.new(0, 12, 0, 42),
                Size = UDim2.new(1, -24, 0, 100),
                BorderSizePixel = 0,
                Parent = frame,
            }), { BackgroundColor3 = "Tertiary" })
            corner(pickerFrame, 4)

            local satVal = create("ImageLabel", {
                BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                Position = UDim2.new(0, 6, 0, 6),
                Size = UDim2.new(0, 88, 0, 88),
                Image = "rbxassetid://4155801252",
                BorderSizePixel = 0,
                Parent = pickerFrame,
            })
            corner(satVal, 3)

            local hueBar = create("Frame", {
                Position = UDim2.new(0, 100, 0, 6),
                Size = UDim2.new(0, 12, 0, 88),
                BorderSizePixel = 0,
                Parent = pickerFrame,
            })
            corner(hueBar, 3)
            local hueGrad = create("UIGradient", { Parent = hueBar })
            hueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            })
            hueGrad.Rotation = 90

            local rgbLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 120, 0, 6),
                Size = UDim2.new(1, -126, 0, 88),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Text = "",
                Parent = pickerFrame,
            })

            local h, s, v = Color3.toHSV(default)

            local function updateColor()
                local color = Color3.fromHSV(h, s, v)
                picker.Value = color
                swatch.BackgroundColor3 = color
                satVal.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                rgbLabel.Text = string.format("R %d\nG %d\nB %d\nHEX #%02X%02X%02X",
                    color.R*255, color.G*255, color.B*255,
                    color.R*255, color.G*255, color.B*255)
                if flag then Scriptora.Flags[flag] = color end
                task.spawn(callback, color)
            end

            local svDrag, hueDrag = false, false
            satVal.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
            end)
            hueBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = true end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then svDrag, hueDrag = false, false end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    if svDrag then
                        s = math.clamp((Mouse.X - satVal.AbsolutePosition.X) / satVal.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((Mouse.Y - satVal.AbsolutePosition.Y) / satVal.AbsoluteSize.Y, 0, 1)
                        updateColor()
                    elseif hueDrag then
                        h = math.clamp((Mouse.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                        updateColor()
                    end
                end
            end)

            swatch.MouseButton1Click:Connect(function()
                picker.Open = not picker.Open
                if picker.Open then
                    tween(frame, 0.25, { Size = UDim2.new(1, 0, 0, 148) })
                else
                    tween(frame, 0.25, { Size = UDim2.new(1, 0, 0, 36) })
                end
            end)

            function picker:Set(c, silent)
                picker.Value = c
                h, s, v = Color3.toHSV(c)
                updateColor()
            end

            if flag then Scriptora.Flags[flag] = default end
            updateColor()
            registerElement(frame, title, title)
            return picker
        end

        -- ====================================================
        -- // LABEL / PARAGRAPH / DIVIDER
        -- ====================================================
        function tab:AddLabel(text)
            local lbl = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = text or "",
                Parent = page,
            })
            local label = { Frame = lbl }
            function label:Set(t) lbl.Text = t end
            return label
        end

        function tab:AddParagraph(opts)
            opts = opts or {}
            local title = opts.Title or "Paragraph"
            local content = opts.Content or ""

            local frame = W:themed(create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                Parent = page,
            }), { BackgroundColor3 = "Secondary" })
            corner(frame, 6)
            W:themed(stroke(frame, theme.Border, 1), { Color = "Border" })

            local pad = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = frame,
            })
            padding(pad, 10)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = pad,
            })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Text = content,
                Parent = pad,
            })

            registerElement(frame, title .. " " .. content, title)
            return frame
        end

        function tab:AddDivider()
            return create("Frame", {
                BackgroundColor3 = theme.Border,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, 0, 0, 1),
                BorderSizePixel = 0,
                Parent = page,
            })
        end

        return tab
    end

    -- ============================================================
    -- // SEARCH
    -- ============================================================
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(searchBox.Text)
        if query == "" then
            for _, t in ipairs(W.Tabs) do
                for _, c in ipairs(t.Page:GetChildren()) do
                    if c:IsA("Frame") or c:IsA("TextLabel") then
                        c.Visible = true
                    end
                end
            end
            return
        end
        for _, entry in ipairs(W.AllElements) do
            entry.Frame.Visible = string.find(entry.Name, query, 1, true) ~= nil
        end
    end)

    -- ============================================================
    -- // CONFIG SAVE / LOAD
    -- ============================================================
    function W:SaveConfig(name)
        name = name or W.ConfigName
        local data = {}
        for k, v in pairs(Scriptora.Flags) do
            if typeof(v) == "Color3" then
                data[k] = { _t = "Color3", r = v.R, g = v.G, b = v.B }
            elseif typeof(v) == "EnumItem" then
                data[k] = { _t = "EnumItem", e = tostring(v.EnumType), n = v.Name }
            elseif typeof(v) == "table" then
                data[k] = { _t = "table", v = v }
            else
                data[k] = v
            end
        end
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not ok then return false, encoded end

        Executor.makefolder(W.ConfigFolder)
        Executor.writefile(W.ConfigFolder .. "/" .. name .. ".json", encoded)
        return true
    end

    function W:LoadConfig(name)
        name = name or W.ConfigName
        local path = W.ConfigFolder .. "/" .. name .. ".json"
        if not Executor.isfile(path) then return false, "Config does not exist" end
        local raw = Executor.readfile(path)
        local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok then return false, data end
        for k, v in pairs(data) do
            if type(v) == "table" and v._t == "Color3" then
                Scriptora.Flags[k] = Color3.new(v.r, v.g, v.b)
            elseif type(v) == "table" and v._t == "EnumItem" then
                Scriptora.Flags[k] = Enum[v.e:gsub("Enum%.", "")][v.n]
            elseif type(v) == "table" and v._t == "table" then
                Scriptora.Flags[k] = v.v
            else
                Scriptora.Flags[k] = v
            end
        end
        return true
    end

    function W:ListConfigs()
        local folder = W.ConfigFolder
        if not Executor.isfolder(folder) then return {} end
        local files = Executor.listfiles(folder)
        local list = {}
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
        return list
    end

    -- ============================================================
    -- // THEME SWITCH
    -- ============================================================
    function W:SetTheme(themeName)
        local newTheme = Scriptora.Themes[themeName]
        if not newTheme then return end
        W.CurrentTheme = newTheme
        W.CurrentThemeName = themeName

        for _, item in ipairs(W.ThemedItems) do
            if item.Inst.Parent then
                for prop, key in pairs(item.Map) do
                    pcall(function()
                        local val = newTheme[key]
                        if type(key) == "function" then
                            val = key(newTheme)
                        end
                        item.Inst[prop] = val
                    end)
                end
            end
        end

        W:Notify({
            Title = "Theme",
            Content = "Switched to " .. themeName .. ". Reload UI for full refresh.",
            Type = "info",
            Duration = 3,
        })
    end

    -- ============================================================
    -- // WINDOW METHODS
    -- ============================================================
    function W:Toggle()
        W.Visible = not W.Visible
        if W.Visible then
            main.Visible = true
            tween(main, 0.3, { Size = size, BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
        else
            tween(main, 0.25, { Size = UDim2.new(0, size.X.Offset, 0, 0), BackgroundTransparency = 1 })
            task.wait(0.25)
            if not W.Visible then main.Visible = false end
        end
    end

    function W:Destroy()
        tween(main, 0.25, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
        task.wait(0.3)
        gui:Destroy()
        for i, w in ipairs(Scriptora.Windows) do
            if w == W then table.remove(Scriptora.Windows, i) break end
        end
    end

    -- ============================================================
    -- // DIALOG (modal)
    -- ============================================================
    function W:Dialog(opts)
        opts = opts or {}
        local title = opts.Title or "Dialog"
        local content = opts.Content or ""
        local buttons = opts.Buttons or { { Text = "OK", Callback = function() end } }

        local overlay = create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 50,
            Parent = main,
        })
        tween(overlay, 0.2, { BackgroundTransparency = 0.5 })

        local box = create("Frame", {
            BackgroundColor3 = theme.Secondary,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 51,
            Parent = overlay,
        })
        corner(box, 8)
        stroke(box, theme.Border, 1)
        shadow(box, 0.4)

        tween(box, 0.3, { Size = UDim2.new(0, 280, 0, 140), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 12),
            Size = UDim2.new(1, -24, 0, 18),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = title,
            ZIndex = 52,
            Parent = box,
        })
        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 36),
            Size = UDim2.new(1, -24, 0, 60),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = content,
            ZIndex = 52,
            Parent = box,
        })

        local btnHolder = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 1, -36),
            Size = UDim2.new(1, -24, 0, 28),
            ZIndex = 52,
            Parent = box,
        })
        create("UIListLayout", {
            Padding = UDim.new(0, 6),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = btnHolder,
        })

        local function close()
            tween(overlay, 0.2, { BackgroundTransparency = 1 })
            tween(box, 0.2, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
            task.wait(0.25)
            overlay:Destroy()
        end

        for i, b in ipairs(buttons) do
            local btn = create("TextButton", {
                BackgroundColor3 = b.Primary and theme.Accent or theme.Element,
                Size = UDim2.new(0, 80, 1, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = theme.Text,
                Text = b.Text or "OK",
                AutoButtonColor = false,
                ZIndex = 53,
                Parent = btnHolder,
            })
            corner(btn, 5)
            btn.MouseButton1Click:Connect(function()
                if b.Callback then task.spawn(b.Callback) end
                close()
            end)
            btn.MouseEnter:Connect(function()
                tween(btn, 0.15, { BackgroundColor3 = b.Primary and theme.AccentHover or theme.ElementHover })
            end)
            btn.MouseLeave:Connect(function()
                tween(btn, 0.15, { BackgroundColor3 = b.Primary and theme.Accent or theme.Element })
            end)
        end
    end

    table.insert(Scriptora.Windows, W)
    return W
end

-- ============================================================
-- // GLOBAL UTILITIES
-- ============================================================
function Scriptora:GetFlag(flag)
    return Scriptora.Flags[flag]
end

function Scriptora:SetFlag(flag, value)
    Scriptora.Flags[flag] = value
end

function Scriptora:DestroyAll()
    for _, w in ipairs(self.Windows) do
        pcall(function() w:Destroy() end)
    end
    self.Windows = {}
end

function Scriptora:GetExecutor()
    return Executor.identifyexecutor()
end

-- ============================================================
-- // REGISTER GLOBALLY (so Example script can grab it)
-- ============================================================
if getgenv then
    getgenv().Scriptora = Scriptora
end
_G.Scriptora = Scriptora
shared.Scriptora = Scriptora

return Scriptora
