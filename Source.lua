--[[
    Scriptora UI Library v3.0.0
    Executor-only Roblox UI engine — designed for loadstring use.

    Usage flow:
        1) Execute this file once. It registers itself globally.
        2) In any subsequent script:
                local Scriptora = getgenv().Scriptora
                local Window = Scriptora:CreateWindow({...})

    Key System Usage:
        Scriptora:CreateKeySystem({
            Name = "My Script",
            Method = "Hardcoded",              -- "Hardcoded" | "URL" | "Custom"
            Keys = {"key1", "key2"},            -- for Hardcoded
            -- URL = "https://keyauth.win/...", -- for URL-based (KeyAuth etc.)
            -- ValidateFunc = function(key) ... end, -- for Custom
            SaveKey = true,
            KeyFolder = "Scriptora",
            OnValidated = function()
                -- create your window here
            end,
        })

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
Scriptora.Version = "3.0.0"
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

Executor.writefile   = (writefile or function() end)
Executor.readfile    = (readfile  or function() return nil end)
Executor.isfile      = (isfile    or function() return false end)
Executor.makefolder  = (makefolder or function() end)
Executor.isfolder    = (isfolder   or function() return false end)
Executor.listfiles   = (listfiles  or function() return {} end)
Executor.delfile     = (delfile    or function() end)
Executor.request     = (request or http_request or (syn and syn.request) or function() return { StatusCode = 0, Body = "" } end)

Executor.setclipboard   = (setclipboard or (toclipboard) or function() end)
Executor.getcustomasset = (getcustomasset or (getsynasset) or function() return "" end)

-- ============================================================
-- // THEMES  (16 total)
-- ============================================================
Scriptora.Themes = {
    -- ── SIGNATURE ──
    Amethyst = {
        Background    = Color3.fromRGB(12, 8, 18),
        Secondary     = Color3.fromRGB(20, 14, 28),
        Tertiary      = Color3.fromRGB(28, 20, 40),
        Element       = Color3.fromRGB(38, 28, 54),
        ElementHover  = Color3.fromRGB(52, 38, 74),
        Border        = Color3.fromRGB(58, 42, 88),
        Accent        = Color3.fromRGB(168, 96, 255),
        AccentHover   = Color3.fromRGB(192, 128, 255),
        AccentDim     = Color3.fromRGB(118, 68, 198),
        AccentGlow    = Color3.fromRGB(168, 96, 255),
        Text          = Color3.fromRGB(242, 238, 252),
        SubText       = Color3.fromRGB(160, 148, 192),
        Disabled      = Color3.fromRGB(88, 78, 108),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
    },

    -- ── DARK / NEUTRAL ──
    Dark = {
        Background    = Color3.fromRGB(16, 16, 20),
        Secondary     = Color3.fromRGB(24, 24, 30),
        Tertiary      = Color3.fromRGB(32, 32, 40),
        Element       = Color3.fromRGB(42, 42, 50),
        ElementHover  = Color3.fromRGB(54, 54, 64),
        Border        = Color3.fromRGB(46, 46, 56),
        Accent        = Color3.fromRGB(108, 118, 255),
        AccentHover   = Color3.fromRGB(132, 140, 255),
        AccentDim     = Color3.fromRGB(78, 86, 198),
        AccentGlow    = Color3.fromRGB(108, 118, 255),
        Text          = Color3.fromRGB(238, 238, 244),
        SubText       = Color3.fromRGB(148, 148, 166),
        Disabled      = Color3.fromRGB(86, 86, 98),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
    },

    -- ── LIGHT ──
    Light = {
        Background    = Color3.fromRGB(248, 248, 252),
        Secondary     = Color3.fromRGB(236, 236, 242),
        Tertiary      = Color3.fromRGB(222, 222, 230),
        Element       = Color3.fromRGB(208, 208, 218),
        ElementHover  = Color3.fromRGB(190, 190, 204),
        Border        = Color3.fromRGB(180, 180, 198),
        Accent        = Color3.fromRGB(96, 64, 198),
        AccentHover   = Color3.fromRGB(118, 86, 218),
        AccentDim     = Color3.fromRGB(76, 46, 158),
        AccentGlow    = Color3.fromRGB(96, 64, 198),
        Text          = Color3.fromRGB(18, 18, 28),
        SubText       = Color3.fromRGB(76, 76, 98),
        Disabled      = Color3.fromRGB(148, 148, 162),
        Success       = Color3.fromRGB(32, 148, 76),
        Warning       = Color3.fromRGB(198, 128, 36),
        Error         = Color3.fromRGB(198, 46, 66),
        Info          = Color3.fromRGB(46, 118, 198),
    },

    -- ── MIDNIGHT (GitHub-dark) ──
    Midnight = {
        Background    = Color3.fromRGB(10, 14, 20),
        Secondary     = Color3.fromRGB(18, 24, 32),
        Tertiary      = Color3.fromRGB(28, 34, 44),
        Element       = Color3.fromRGB(38, 44, 56),
        ElementHover  = Color3.fromRGB(48, 56, 68),
        Border        = Color3.fromRGB(42, 50, 62),
        Accent        = Color3.fromRGB(82, 162, 255),
        AccentHover   = Color3.fromRGB(108, 182, 255),
        AccentDim     = Color3.fromRGB(56, 128, 218),
        AccentGlow    = Color3.fromRGB(82, 162, 255),
        Text          = Color3.fromRGB(232, 238, 246),
        SubText       = Color3.fromRGB(132, 142, 158),
        Disabled      = Color3.fromRGB(76, 86, 98),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
    },

    -- ── ROSE ──
    Rose = {
        Background    = Color3.fromRGB(22, 14, 18),
        Secondary     = Color3.fromRGB(34, 22, 28),
        Tertiary      = Color3.fromRGB(46, 30, 38),
        Element       = Color3.fromRGB(58, 38, 48),
        ElementHover  = Color3.fromRGB(72, 48, 58),
        Border        = Color3.fromRGB(68, 44, 56),
        Accent        = Color3.fromRGB(255, 98, 142),
        AccentHover   = Color3.fromRGB(255, 128, 164),
        AccentDim     = Color3.fromRGB(198, 68, 108),
        AccentGlow    = Color3.fromRGB(255, 98, 142),
        Text          = Color3.fromRGB(248, 238, 242),
        SubText       = Color3.fromRGB(178, 148, 162),
        Disabled      = Color3.fromRGB(98, 78, 88),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
    },

    -- ── FOREST ──
    Forest = {
        Background    = Color3.fromRGB(10, 16, 12),
        Secondary     = Color3.fromRGB(16, 26, 20),
        Tertiary      = Color3.fromRGB(22, 36, 28),
        Element       = Color3.fromRGB(32, 50, 40),
        ElementHover  = Color3.fromRGB(42, 64, 52),
        Border        = Color3.fromRGB(48, 72, 58),
        Accent        = Color3.fromRGB(72, 218, 112),
        AccentHover   = Color3.fromRGB(96, 242, 142),
        AccentDim     = Color3.fromRGB(48, 162, 86),
        AccentGlow    = Color3.fromRGB(72, 218, 112),
        Text          = Color3.fromRGB(222, 248, 232),
        SubText       = Color3.fromRGB(132, 178, 152),
        Disabled      = Color3.fromRGB(68, 88, 78),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
    },

    -- ── OCEAN ──
    Ocean = {
        Background    = Color3.fromRGB(8, 16, 26),
        Secondary     = Color3.fromRGB(14, 24, 38),
        Tertiary      = Color3.fromRGB(20, 34, 52),
        Element       = Color3.fromRGB(28, 46, 68),
        ElementHover  = Color3.fromRGB(38, 58, 84),
        Border        = Color3.fromRGB(36, 64, 96),
        Accent        = Color3.fromRGB(72, 196, 228),
        AccentHover   = Color3.fromRGB(102, 218, 246),
        AccentDim     = Color3.fromRGB(46, 148, 186),
        AccentGlow    = Color3.fromRGB(72, 196, 228),
        Text          = Color3.fromRGB(228, 242, 252),
        SubText       = Color3.fromRGB(132, 168, 192),
        Disabled      = Color3.fromRGB(76, 96, 118),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
    },

    -- ── SUNSET ──
    Sunset = {
        Background    = Color3.fromRGB(18, 10, 14),
        Secondary     = Color3.fromRGB(30, 16, 22),
        Tertiary      = Color3.fromRGB(44, 24, 32),
        Element       = Color3.fromRGB(58, 34, 42),
        ElementHover  = Color3.fromRGB(74, 44, 54),
        Border        = Color3.fromRGB(88, 48, 58),
        Accent        = Color3.fromRGB(255, 114, 56),
        AccentHover   = Color3.fromRGB(255, 144, 82),
        AccentDim     = Color3.fromRGB(178, 76, 38),
        AccentGlow    = Color3.fromRGB(255, 114, 56),
        Text          = Color3.fromRGB(255, 242, 232),
        SubText       = Color3.fromRGB(198, 158, 156),
        Disabled      = Color3.fromRGB(98, 78, 82),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
    },

    -- ── CYBERPUNK ──
    Cyberpunk = {
        Background    = Color3.fromRGB(8, 6, 16),
        Secondary     = Color3.fromRGB(14, 10, 28),
        Tertiary      = Color3.fromRGB(22, 16, 42),
        Element       = Color3.fromRGB(32, 22, 56),
        ElementHover  = Color3.fromRGB(44, 30, 72),
        Border        = Color3.fromRGB(62, 28, 98),
        Accent        = Color3.fromRGB(255, 42, 192),
        AccentHover   = Color3.fromRGB(255, 82, 212),
        AccentDim     = Color3.fromRGB(186, 28, 142),
        AccentGlow    = Color3.fromRGB(255, 42, 192),
        Text          = Color3.fromRGB(248, 232, 255),
        SubText       = Color3.fromRGB(168, 128, 198),
        Disabled      = Color3.fromRGB(88, 62, 108),
        Success       = Color3.fromRGB(42, 255, 168),
        Warning       = Color3.fromRGB(255, 222, 42),
        Error         = Color3.fromRGB(255, 42, 72),
        Info          = Color3.fromRGB(42, 198, 255),
    },

    -- ── DRACULA ──
    Dracula = {
        Background    = Color3.fromRGB(24, 24, 36),
        Secondary     = Color3.fromRGB(34, 34, 52),
        Tertiary      = Color3.fromRGB(44, 44, 66),
        Element       = Color3.fromRGB(56, 56, 82),
        ElementHover  = Color3.fromRGB(68, 68, 98),
        Border        = Color3.fromRGB(62, 62, 92),
        Accent        = Color3.fromRGB(188, 148, 255),
        AccentHover   = Color3.fromRGB(208, 172, 255),
        AccentDim     = Color3.fromRGB(148, 112, 218),
        AccentGlow    = Color3.fromRGB(188, 148, 255),
        Text          = Color3.fromRGB(248, 248, 242),
        SubText       = Color3.fromRGB(152, 152, 178),
        Disabled      = Color3.fromRGB(92, 92, 112),
        Success       = Color3.fromRGB(80, 250, 123),
        Warning       = Color3.fromRGB(241, 250, 140),
        Error         = Color3.fromRGB(255, 85, 85),
        Info          = Color3.fromRGB(139, 233, 253),
    },

    -- ── NORD ──
    Nord = {
        Background    = Color3.fromRGB(36, 40, 52),
        Secondary     = Color3.fromRGB(42, 48, 62),
        Tertiary      = Color3.fromRGB(52, 58, 74),
        Element       = Color3.fromRGB(62, 70, 88),
        ElementHover  = Color3.fromRGB(72, 82, 102),
        Border        = Color3.fromRGB(68, 76, 96),
        Accent        = Color3.fromRGB(136, 192, 208),
        AccentHover   = Color3.fromRGB(162, 210, 224),
        AccentDim     = Color3.fromRGB(102, 162, 182),
        AccentGlow    = Color3.fromRGB(136, 192, 208),
        Text          = Color3.fromRGB(236, 239, 244),
        SubText       = Color3.fromRGB(168, 178, 198),
        Disabled      = Color3.fromRGB(98, 108, 128),
        Success       = Color3.fromRGB(163, 190, 140),
        Warning       = Color3.fromRGB(235, 203, 139),
        Error         = Color3.fromRGB(191, 97, 106),
        Info          = Color3.fromRGB(129, 161, 193),
    },

    -- ── MONOKAI ──
    Monokai = {
        Background    = Color3.fromRGB(32, 32, 28),
        Secondary     = Color3.fromRGB(42, 42, 36),
        Tertiary      = Color3.fromRGB(54, 54, 48),
        Element       = Color3.fromRGB(66, 66, 58),
        ElementHover  = Color3.fromRGB(78, 78, 70),
        Border        = Color3.fromRGB(72, 72, 64),
        Accent        = Color3.fromRGB(166, 226, 46),
        AccentHover   = Color3.fromRGB(186, 238, 76),
        AccentDim     = Color3.fromRGB(128, 182, 28),
        AccentGlow    = Color3.fromRGB(166, 226, 46),
        Text          = Color3.fromRGB(248, 248, 242),
        SubText       = Color3.fromRGB(168, 168, 152),
        Disabled      = Color3.fromRGB(98, 98, 88),
        Success       = Color3.fromRGB(166, 226, 46),
        Warning       = Color3.fromRGB(253, 151, 31),
        Error         = Color3.fromRGB(249, 38, 114),
        Info          = Color3.fromRGB(102, 217, 239),
    },

    -- ── BLOOD ──
    Blood = {
        Background    = Color3.fromRGB(14, 8, 8),
        Secondary     = Color3.fromRGB(24, 12, 12),
        Tertiary      = Color3.fromRGB(36, 16, 16),
        Element       = Color3.fromRGB(50, 22, 22),
        ElementHover  = Color3.fromRGB(66, 28, 28),
        Border        = Color3.fromRGB(72, 26, 26),
        Accent        = Color3.fromRGB(218, 36, 52),
        AccentHover   = Color3.fromRGB(238, 62, 78),
        AccentDim     = Color3.fromRGB(168, 24, 38),
        AccentGlow    = Color3.fromRGB(218, 36, 52),
        Text          = Color3.fromRGB(252, 238, 238),
        SubText       = Color3.fromRGB(188, 148, 148),
        Disabled      = Color3.fromRGB(98, 72, 72),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
    },

    -- ── NEON ──
    Neon = {
        Background    = Color3.fromRGB(6, 6, 12),
        Secondary     = Color3.fromRGB(10, 10, 22),
        Tertiary      = Color3.fromRGB(16, 16, 34),
        Element       = Color3.fromRGB(22, 22, 48),
        ElementHover  = Color3.fromRGB(30, 30, 64),
        Border        = Color3.fromRGB(42, 42, 86),
        Accent        = Color3.fromRGB(42, 255, 198),
        AccentHover   = Color3.fromRGB(82, 255, 218),
        AccentDim     = Color3.fromRGB(28, 186, 148),
        AccentGlow    = Color3.fromRGB(42, 255, 198),
        Text          = Color3.fromRGB(232, 255, 248),
        SubText       = Color3.fromRGB(128, 188, 172),
        Disabled      = Color3.fromRGB(62, 88, 78),
        Success       = Color3.fromRGB(42, 255, 168),
        Warning       = Color3.fromRGB(255, 222, 42),
        Error         = Color3.fromRGB(255, 42, 96),
        Info          = Color3.fromRGB(42, 168, 255),
    },

    -- ── CATPPUCCIN (Mocha) ──
    Catppuccin = {
        Background    = Color3.fromRGB(30, 30, 46),
        Secondary     = Color3.fromRGB(36, 36, 54),
        Tertiary      = Color3.fromRGB(45, 45, 66),
        Element       = Color3.fromRGB(56, 56, 80),
        ElementHover  = Color3.fromRGB(68, 68, 96),
        Border        = Color3.fromRGB(62, 62, 88),
        Accent        = Color3.fromRGB(203, 166, 247),
        AccentHover   = Color3.fromRGB(218, 188, 252),
        AccentDim     = Color3.fromRGB(162, 128, 212),
        AccentGlow    = Color3.fromRGB(203, 166, 247),
        Text          = Color3.fromRGB(205, 214, 244),
        SubText       = Color3.fromRGB(147, 153, 178),
        Disabled      = Color3.fromRGB(88, 91, 112),
        Success       = Color3.fromRGB(166, 227, 161),
        Warning       = Color3.fromRGB(249, 226, 175),
        Error         = Color3.fromRGB(243, 139, 168),
        Info          = Color3.fromRGB(137, 220, 235),
    },

    -- ── GOLD ──
    Gold = {
        Background    = Color3.fromRGB(16, 14, 10),
        Secondary     = Color3.fromRGB(26, 22, 16),
        Tertiary      = Color3.fromRGB(38, 32, 22),
        Element       = Color3.fromRGB(52, 44, 30),
        ElementHover  = Color3.fromRGB(66, 56, 38),
        Border        = Color3.fromRGB(78, 64, 38),
        Accent        = Color3.fromRGB(255, 198, 56),
        AccentHover   = Color3.fromRGB(255, 216, 96),
        AccentDim     = Color3.fromRGB(198, 152, 36),
        AccentGlow    = Color3.fromRGB(255, 198, 56),
        Text          = Color3.fromRGB(255, 248, 232),
        SubText       = Color3.fromRGB(198, 178, 142),
        Disabled      = Color3.fromRGB(108, 96, 72),
        Success       = Color3.fromRGB(86, 222, 132),
        Warning       = Color3.fromRGB(255, 186, 72),
        Error         = Color3.fromRGB(255, 82, 106),
        Info          = Color3.fromRGB(96, 176, 255),
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
        Color = color or Color3.fromRGB(50, 50, 58),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function gradient(parent, colors, rotation)
    local cs = typeof(colors) == "ColorSequence" and colors or ColorSequence.new(colors)
    return create("UIGradient", {
        Color = cs,
        Rotation = rotation or 0,
        Parent = parent,
    })
end

local function padding(parent, top, left, right, bottom)
    return create("UIPadding", {
        PaddingTop    = UDim.new(0, top),
        PaddingBottom = UDim.new(0, bottom or top),
        PaddingLeft   = UDim.new(0, left or top),
        PaddingRight  = UDim.new(0, right or left or top),
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
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
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
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
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

-- Ripple effect helper
local function addRipple(button, theme)
    button.ClipsDescendants = true
    button.MouseButton1Click:Connect(function()
        local mx = Mouse.X - button.AbsolutePosition.X
        local my = Mouse.Y - button.AbsolutePosition.Y
        local maxDist = math.max(
            math.sqrt(mx^2 + my^2),
            math.sqrt((button.AbsoluteSize.X - mx)^2 + my^2),
            math.sqrt(mx^2 + (button.AbsoluteSize.Y - my)^2),
            math.sqrt((button.AbsoluteSize.X - mx)^2 + (button.AbsoluteSize.Y - my)^2)
        )
        local ripple = create("Frame", {
            BackgroundColor3 = theme.AccentGlow or theme.Accent,
            BackgroundTransparency = 0.7,
            Position = UDim2.new(0, mx, 0, my),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 0, 0, 0),
            Parent = button,
        })
        corner(ripple, 999)
        local sz = maxDist * 2
        tween(ripple, 0.4, { Size = UDim2.new(0, sz, 0, sz), BackgroundTransparency = 1 })
        task.delay(0.45, function() ripple:Destroy() end)
    end)
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
        Size = UDim2.new(0, 330, 1, -32),
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
    local notifType = string.lower(opts.Type or "info")
    local theme = self.CurrentTheme or Scriptora.Themes.Amethyst

    local typeColor = theme.Info
    local icon = "ℹ"
    if notifType == "success" then typeColor, icon = theme.Success, "✓"
    elseif notifType == "warning" then typeColor, icon = theme.Warning, "⚠"
    elseif notifType == "error" then typeColor, icon = theme.Error, "✕"
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
    corner(notif, 10)
    stroke(notif, theme.Border, 1, 0.3)
    shadow(notif, 0.55)

    -- accent stripe
    local stripe = create("Frame", {
        BackgroundColor3 = typeColor,
        Size = UDim2.new(0, 3, 1, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Parent = notif,
    })
    corner(stripe, 2)

    -- inner padded area
    local pad = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = notif,
    })
    padding(pad, 12, 8, 12, 12)

    -- icon badge
    local iconBg = create("Frame", {
        BackgroundColor3 = typeColor,
        BackgroundTransparency = 0.85,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 0, 0, 0),
        Parent = pad,
    })
    corner(iconBg, 6)

    local iconLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = typeColor,
        Text = icon,
        TextTransparency = 1,
        Parent = iconBg,
    })

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 1),
        Size = UDim2.new(1, -28, 0, 18),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = theme.Text,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = title,
        Parent = pad,
    })

    local contentLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 28, 0, 22),
        Size = UDim2.new(1, -28, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = theme.SubText,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Text = content,
        Parent = pad,
    })

    -- progress bar
    local bar = create("Frame", {
        BackgroundColor3 = typeColor,
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BorderSizePixel = 0,
        Parent = notif,
    })

    -- animate in
    notif.Position = UDim2.new(1, 60, 0, 0)
    tween(notif, 0.35, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
    tween(stripe, 0.3, { BackgroundTransparency = 0 })
    tween(iconLabel, 0.3, { TextTransparency = 0 })
    tween(titleLabel, 0.3, { TextTransparency = 0 })
    tween(contentLabel, 0.3, { TextTransparency = 0 })
    tween(bar, 0.3, { BackgroundTransparency = 0.4 })

    task.spawn(function()
        tween(bar, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)
        task.wait(duration)
        tween(notif, 0.3, { BackgroundTransparency = 1, Position = UDim2.new(1, 60, 0, 0) })
        tween(stripe, 0.2, { BackgroundTransparency = 1 })
        tween(iconLabel, 0.2, { TextTransparency = 1 })
        tween(titleLabel, 0.2, { TextTransparency = 1 })
        tween(contentLabel, 0.2, { TextTransparency = 1 })
        task.wait(0.35)
        notif:Destroy()
    end)
end

-- ============================================================
-- // KEY SYSTEM
-- ============================================================
function Scriptora:CreateKeySystem(opts)
    opts = opts or {}
    local name        = opts.Name or "Scriptora"
    local method      = opts.Method or "Hardcoded" -- "Hardcoded" | "URL" | "Custom"
    local keys        = opts.Keys or {}
    local url         = opts.URL or ""
    local validateFunc = opts.ValidateFunc -- function(key) -> boolean, message
    local saveKey     = opts.SaveKey ~= false
    local keyFolder   = opts.KeyFolder or "Scriptora"
    local keyFile     = opts.KeyFile or "key.txt"
    local onValidated = opts.OnValidated or function() end
    local onFailed    = opts.OnFailed or function() end
    local themeName   = opts.Theme or "Amethyst"
    local theme       = Scriptora.Themes[themeName] or Scriptora.Themes.Amethyst
    local getKeyLink  = opts.GetKeyLink or ""
    local discord     = opts.Discord or ""
    local maxAttempts = opts.MaxAttempts or 5

    local attempts = 0
    local savedKey = ""

    -- Try to load saved key
    if saveKey then
        pcall(function()
            if not Executor.isfolder(keyFolder) then Executor.makefolder(keyFolder) end
            local path = keyFolder .. "/" .. keyFile
            if Executor.isfile(path) then
                savedKey = Executor.readfile(path)
            end
        end)
    end

    -- Validation logic
    local function validate(key)
        if method == "Hardcoded" then
            for _, k in ipairs(keys) do
                if k == key then return true, "Key validated!" end
            end
            return false, "Invalid key."
        elseif method == "URL" then
            local ok, result = pcall(function()
                local requestUrl = url
                if opts.MethodType ~= "POST" then
                    requestUrl = url .. (url:find("?") and "&" or "?") .. (opts.KeyParam or "key") .. "=" .. HttpService:UrlEncode(key)
                end
                
                local resp = Executor.request({
                    Url = requestUrl,
                    Method = opts.MethodType or "GET",
                    Headers = opts.Headers or { ["Content-Type"] = "application/json" },
                    Body = opts.MethodType == "POST" and HttpService:JSONEncode(opts.Body or { key = key }) or nil
                })
                
                if resp.StatusCode == 200 then
                    local body = resp.Body
                    -- support JSON responses
                    local success_parse, data = pcall(HttpService.JSONDecode, HttpService, body)
                    if success_parse and data then
                        if data.success or data.valid or data.status == "success" or data.message == "valid" then
                            return true
                        end
                    end
                    -- raw text check
                    body = body:lower():gsub("%s+", "")
                    if body == "true" or body == "valid" or body == "success" or body == "1" then
                        return true
                    end
                end
                return false
            end)
            if ok and result then
                return true, "Key validated!"
            end
            return false, "Invalid key or server error."
        elseif method == "KeyAuth" then
            local ok, result = pcall(function()
                -- KeyAuth requires Init first
                local initUrl = string.format("https://keyauth.win/api/1.1/?name=%s&ownerid=%s&type=init&ver=%s", 
                    opts.AppName, opts.OwnerID, opts.Version or "1.0")
                local initResp = Executor.request({ Url = initUrl, Method = "GET" })
                local initData = HttpService:JSONDecode(initResp.Body)
                
                if initData.success then
                    local sessionid = initData.sessionid
                    local logUrl = string.format("https://keyauth.win/api/1.1/?name=%s&ownerid=%s&type=license&key=%s&ver=%s&sessionid=%s",
                        opts.AppName, opts.OwnerID, key, opts.Version or "1.0", sessionid)
                    local logResp = Executor.request({ Url = logUrl, Method = "GET" })
                    local logData = HttpService:JSONDecode(logResp.Body)
                    
                    if logData.success then return true end
                end
                return false
            end)
            if ok and result then return true, "KeyAuth validated!" end
            return false, "Invalid KeyAuth license."
        elseif method == "Panda" then
            local ok, result = pcall(function()
                local serviceID = opts.ServiceID
                local pandaUrl = string.format("https://api.pandadevelopment.net/v1/sdk/test/proxy?service=%s&key=%s", serviceID, key)
                local resp = Executor.request({ Url = pandaUrl, Method = "GET" })
                return resp.Body:find("success") or resp.Body:find("valid")
            end)
            if ok and result then return true, "PandaAuth validated!" end
            return false, "Invalid PandaAuth key."
        elseif method == "Custom" and validateFunc then
            return validateFunc(key)
        end
        return false, "Unknown validation method."
    end

    -- Check saved key first
    if savedKey ~= "" then
        local valid, _ = validate(savedKey)
        if valid then
            task.spawn(onValidated)
            return
        end
    end

    -- Build the key UI
    local gui = create("ScreenGui", {
        Name = "Scriptora_KeySystem",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 200,
    })
    Executor.protectgui(gui)

    -- dark overlay
    local overlay = create("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.3,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = gui,
    })

    -- main card
    local card = create("Frame", {
        BackgroundColor3 = theme.Background,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = gui,
    })
    corner(card, 12)
    stroke(card, theme.Border, 1)
    shadow(card, 0.35)

    tween(card, 0.4, { Size = UDim2.new(0, 360, 0, 300), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)

    -- top accent bar
    local accentTop = create("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(1, 0, 0, 3),
        BorderSizePixel = 0,
        Parent = card,
    })
    gradient(accentTop, ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.AccentDim),
        ColorSequenceKeypoint.new(0.5, theme.Accent),
        ColorSequenceKeypoint.new(1, theme.AccentDim),
    }), 0)
    corner(accentTop, 12)

    -- logo area
    local logoBg = create("Frame", {
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.88,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 24),
        Size = UDim2.new(0, 52, 0, 52),
        Parent = card,
    })
    corner(logoBg, 14)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = theme.Accent,
        Text = "🔑",
        Parent = logoBg,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 84),
        Size = UDim2.new(1, -40, 0, 22),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = theme.Text,
        Text = name,
        Parent = card,
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 108),
        Size = UDim2.new(1, -40, 0, 16),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = theme.SubText,
        Text = "Enter your license key to continue",
        Parent = card,
    })

    -- key input
    local inputBg = create("Frame", {
        BackgroundColor3 = theme.Element,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 140),
        Size = UDim2.new(1, -48, 0, 38),
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(inputBg, 8)
    local inputStroke = stroke(inputBg, theme.Border, 1, 0.3)

    local keyInput = create("TextBox", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.Disabled,
        PlaceholderText = "XXXX-XXXX-XXXX-XXXX",
        Text = "",
        ClearTextOnFocus = false,
        Parent = inputBg,
    })

    keyInput.Focused:Connect(function()
        tween(inputStroke, 0.2, { Color = theme.Accent, Transparency = 0 })
        tween(inputBg, 0.2, { BackgroundColor3 = theme.Tertiary })
    end)
    keyInput.FocusLost:Connect(function()
        tween(inputStroke, 0.2, { Color = theme.Border, Transparency = 0.3 })
        tween(inputBg, 0.2, { BackgroundColor3 = theme.Element })
    end)

    -- status label
    local statusLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 184),
        Size = UDim2.new(1, -48, 0, 14),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = theme.SubText,
        Text = "",
        Parent = card,
    })

    -- validate button
    local validateBtn = create("TextButton", {
        BackgroundColor3 = theme.Accent,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 206),
        Size = UDim2.new(1, -48, 0, 36),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = theme.Text,
        Text = "Validate Key",
        AutoButtonColor = false,
        Parent = card,
    })
    corner(validateBtn, 8)
    gradient(validateBtn, ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.Accent),
        ColorSequenceKeypoint.new(1, theme.AccentDim),
    }), 45)
    addRipple(validateBtn, theme)

    validateBtn.MouseEnter:Connect(function()
        tween(validateBtn, 0.2, { BackgroundColor3 = theme.AccentHover })
    end)
    validateBtn.MouseLeave:Connect(function()
        tween(validateBtn, 0.2, { BackgroundColor3 = theme.Accent })
    end)

    -- bottom links row
    local linksRow = create("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 254),
        Size = UDim2.new(1, -48, 0, 22),
        Parent = card,
    })
    listLayout(linksRow, 12, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center)

    if getKeyLink ~= "" then
        local getBtn = create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 70, 1, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = theme.Accent,
            Text = "Get Key",
            AutoButtonColor = false,
            Parent = linksRow,
        })
        getBtn.MouseButton1Click:Connect(function()
            Executor.setclipboard(getKeyLink)
            statusLabel.Text = "Link copied to clipboard!"
            statusLabel.TextColor3 = theme.Info
        end)
    end

    if discord ~= "" then
        local dcBtn = create("TextButton", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 70, 1, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = theme.Accent,
            Text = "Discord",
            AutoButtonColor = false,
            Parent = linksRow,
        })
        dcBtn.MouseButton1Click:Connect(function()
            Executor.setclipboard(discord)
            statusLabel.Text = "Discord link copied!"
            statusLabel.TextColor3 = theme.Info
        end)
    end

    local pasteBtn = create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 70, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = theme.SubText,
        Text = "Paste",
        AutoButtonColor = false,
        Parent = linksRow,
    })
    -- (paste from clipboard isn't reliable in all executors, but text can be pasted natively)

    -- validation logic
    validateBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if key == "" then
            statusLabel.Text = "Please enter a key."
            statusLabel.TextColor3 = theme.Warning
            return
        end

        attempts = attempts + 1
        if attempts > maxAttempts then
            statusLabel.Text = "Too many attempts. Restart the script."
            statusLabel.TextColor3 = theme.Error
            validateBtn.Active = false
            validateBtn.BackgroundColor3 = theme.Disabled
            return
        end

        statusLabel.Text = "Validating…"
        statusLabel.TextColor3 = theme.SubText
        validateBtn.Text = "Validating…"
        validateBtn.Active = false

        task.spawn(function()
            local valid, msg = validate(key)
            if valid then
                statusLabel.Text = msg or "Key validated!"
                statusLabel.TextColor3 = theme.Success
                validateBtn.Text = "✓ Success"
                validateBtn.BackgroundColor3 = theme.Success

                -- save key
                if saveKey then
                    pcall(function()
                        if not Executor.isfolder(keyFolder) then Executor.makefolder(keyFolder) end
                        Executor.writefile(keyFolder .. "/" .. keyFile, key)
                    end)
                end

                task.wait(0.6)
                tween(card, 0.3, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
                tween(overlay, 0.3, { BackgroundTransparency = 1 })
                task.wait(0.35)
                gui:Destroy()
                task.spawn(onValidated)
            else
                statusLabel.Text = msg or "Invalid key."
                statusLabel.TextColor3 = theme.Error
                validateBtn.Text = "Validate Key"
                validateBtn.Active = true
                validateBtn.BackgroundColor3 = theme.Accent

                -- shake the input
                local orig = inputBg.Position
                for i = 1, 3 do
                    tween(inputBg, 0.04, { Position = orig + UDim2.new(0, 6, 0, 0) })
                    task.wait(0.04)
                    tween(inputBg, 0.04, { Position = orig + UDim2.new(0, -6, 0, 0) })
                    task.wait(0.04)
                end
                tween(inputBg, 0.04, { Position = orig })

                task.spawn(onFailed, key)
            end
        end)
    end)

    return gui
end

-- ============================================================
-- // WINDOW
-- ============================================================
function Scriptora:CreateWindow(opts)
    opts = opts or {}
    local W = setmetatable({}, { __index = Scriptora })

    local windowName   = opts.Name or "Scriptora"
    local subTitle     = opts.SubTitle or ""
    local themeName    = opts.Theme or "Amethyst"
    local theme        = Scriptora.Themes[themeName] or Scriptora.Themes.Amethyst
    local toggleKey    = opts.ToggleKey or Enum.KeyCode.RightShift
    local size         = opts.Size or UDim2.new(0, 620, 0, 440)
    local minSize      = opts.MinSize or Vector2.new(440, 320)
    local configFolder = opts.ConfigFolder or "Scriptora"
    local configName   = opts.ConfigName or "default"
    local showWatermark = opts.Watermark ~= false

    W.CurrentTheme     = theme
    W.CurrentThemeName = themeName
    W.ConfigFolder     = configFolder
    W.ConfigName       = configName
    W.Tabs             = {}
    W.AllElements      = {}
    W.ThemedItems      = {}
    W.Visible          = true

    function W:themed(inst, map)
        table.insert(W.ThemedItems, { Inst = inst, Map = map })
        return inst
    end

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
        Size = UDim2.new(0, 260, 0, 90),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = gui,
    })
    corner(splash, 12)
    stroke(splash, theme.Border, 1, 0.3)
    shadow(splash, 0.45)

    -- accent top line on splash
    local splashAccent = create("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Parent = splash,
    })
    gradient(splashAccent, ColorSequence.new(theme.AccentDim, theme.Accent), 0)
    corner(splashAccent, 12)

    local splashTitle = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 16),
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = theme.Text,
        Text = windowName,
        TextTransparency = 1,
        Parent = splash,
    })
    local splashSub = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 42),
        Size = UDim2.new(1, 0, 0, 14),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = theme.SubText,
        Text = "Initializing…",
        TextTransparency = 1,
        Parent = splash,
    })
    local splashBar = create("Frame", {
        BackgroundColor3 = theme.Element,
        Position = UDim2.new(0.5, -90, 1, -18),
        Size = UDim2.new(0, 180, 0, 3),
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
    gradient(splashFill, ColorSequence.new(theme.AccentDim, theme.Accent), 0)

    tween(splash, 0.3, { BackgroundTransparency = 0 })
    tween(splashAccent, 0.3, { BackgroundTransparency = 0 })
    tween(splashTitle, 0.3, { TextTransparency = 0 })
    tween(splashSub, 0.3, { TextTransparency = 0 })
    tween(splashBar, 0.3, { BackgroundTransparency = 0 })
    tween(splashFill, 0.65, { Size = UDim2.new(1, 0, 1, 0) })

    -- // Main Frame
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
    W:themed(stroke(main, theme.Border, 1, 0.2), { Color = "Border" })
    shadow(main, 0.4)
    W.Main = main

    -- ── TOP BAR ──
    local topBar = create("Frame", {
        Name = "TopBar",
        BackgroundColor3 = theme.Secondary,
        Size = UDim2.new(1, 0, 0, 42),
        BorderSizePixel = 0,
        Parent = main,
    })
    W:themed(topBar, { BackgroundColor3 = "Secondary" })

    -- top accent line
    local topAccent = create("Frame", {
        BackgroundColor3 = theme.Accent,
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
        Parent = topBar,
    })
    gradient(topAccent, ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.AccentDim),
        ColorSequenceKeypoint.new(0.5, theme.Accent),
        ColorSequenceKeypoint.new(1, theme.AccentDim),
    }), 0)

    -- bottom fill to mask corners
    W:themed(create("Frame", {
        BackgroundColor3 = theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -10),
        Size = UDim2.new(1, 0, 0, 10),
        Parent = topBar,
    }), { BackgroundColor3 = "Secondary" })

    -- logo/icon
    local pfpUrl = fetchImage(opts.CustomPFP)
    local logoClass = pfpUrl ~= "" and "ImageLabel" or "Frame"
    local logo = create(logoClass, {
        BackgroundColor3 = theme.Accent,
        BackgroundTransparency = 0.85,
        Position = UDim2.new(0, 12, 0.5, -11),
        Size = UDim2.new(0, 26, 0, 26),
        BorderSizePixel = 0,
        Parent = topBar,
    })
    if pfpUrl ~= "" and logoClass == "ImageLabel" then logo.Image = pfpUrl end
    corner(logo, 7)

    if pfpUrl == "" then
        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = theme.Accent,
            Text = string.sub(windowName, 1, 1):upper(),
            Parent = logo,
        })
    end

    local titleLabel = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 44, 0, 2),
        Size = UDim2.new(0, 200, 1, -2),
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
        W:themed(create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 44 + titleSize.X + 8, 0, 2),
            Size = UDim2.new(0, 200, 1, -2),
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = subTitle,
            Parent = topBar,
        }), { TextColor3 = "SubText" })
    end

    -- Close + Minimize
    local function topBtn(text, hoverColor, x)
        local b = create("TextButton", {
            BackgroundColor3 = theme.Element,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, x, 0.5, -10),
            Size = UDim2.new(0, 22, 0, 22),
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
    local minBtn   = topBtn("–", theme.Accent, -54)

    closeBtn.MouseButton1Click:Connect(function() W:Destroy() end)
    minBtn.MouseButton1Click:Connect(function() W:Toggle() end)

    makeDraggable(main, topBar)

    -- ── SIDEBAR ──
    local sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = theme.Secondary,
        Position = UDim2.new(0, 0, 0, 42),
        Size = UDim2.new(0, 155, 1, -78),
        BorderSizePixel = 0,
        Parent = main,
    })
    W:themed(sidebar, { BackgroundColor3 = "Secondary" })

    -- divider line between sidebar and content
    W:themed(create("Frame", {
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BorderSizePixel = 0,
        Parent = sidebar,
    }), { BackgroundColor3 = "Border" })

    -- search bar
    local searchHolder = create("Frame", {
        BackgroundColor3 = theme.Tertiary,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 0, 30),
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    W:themed(searchHolder, { BackgroundColor3 = "Tertiary" })
    corner(searchHolder, 6)
    local searchStroke = stroke(searchHolder, theme.Border, 1, 0.5)

    create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 9, 0, 0),
        Size = UDim2.new(0, 14, 1, 0),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = theme.Disabled,
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
        PlaceholderColor3 = theme.Disabled,
        PlaceholderText = "Search…",
        Text = "",
        ClearTextOnFocus = false,
        Parent = searchHolder,
    })
    W:themed(searchBox, { TextColor3 = "Text", PlaceholderColor3 = "Disabled" })

    searchBox.Focused:Connect(function()
        tween(searchStroke, 0.15, { Color = theme.Accent, Transparency = 0 })
    end)
    searchBox.FocusLost:Connect(function()
        tween(searchStroke, 0.15, { Color = theme.Border, Transparency = 0.5 })
    end)

    local tabHolder = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 46),
        Size = UDim2.new(1, -16, 1, -54),
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        BorderSizePixel = 0,
        Parent = sidebar,
    })
    listLayout(tabHolder, 3)

    -- ── BOTTOM PLAYER BAR ──
    local playerBar = create("Frame", {
        BackgroundColor3 = theme.Secondary,
        Position = UDim2.new(0, 0, 1, -36),
        Size = UDim2.new(0, 155, 0, 36),
        BorderSizePixel = 0,
        Parent = main,
    })
    W:themed(playerBar, { BackgroundColor3 = "Secondary" })

    -- divider above player bar
    W:themed(create("Frame", {
        BackgroundColor3 = theme.Border,
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -16, 0, 1),
        BorderSizePixel = 0,
        Parent = playerBar,
    }), { BackgroundColor3 = "Border" })

    local avatar = create("ImageLabel", {
        BackgroundColor3 = theme.Element,
        Position = UDim2.new(0, 8, 0.5, -12),
        Size = UDim2.new(0, 24, 0, 24),
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=150&height=150&format=png",
        Parent = playerBar,
    })
    corner(avatar, 12)
    stroke(avatar, theme.Accent, 1.5, 0.3)

    W:themed(create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 5),
        Size = UDim2.new(1, -44, 0, 13),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = LP.DisplayName,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = playerBar,
    }), { TextColor3 = "Text" })

    W:themed(create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 18),
        Size = UDim2.new(1, -44, 0, 12),
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = theme.SubText,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "@" .. LP.Name,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = playerBar,
    }), { TextColor3 = "SubText" })

    -- ── CONTENT AREA ──
    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 155, 0, 42),
        Size = UDim2.new(1, -155, 1, -42),
        Parent = main,
    })

    -- ── RESIZE HANDLE ──
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
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = theme.Disabled,
        Text = "⇲",
        Parent = resizeHandle,
    })

    do
        local resizing, startMouse, startSize = false, nil, nil
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
                local nx = math.max(minSize.X, startSize.X + m.X - startMouse.X)
                local ny = math.max(minSize.Y, startSize.Y + m.Y - startMouse.Y)
                main.Size = UDim2.new(0, nx, 0, ny)
                size = main.Size
            end
        end)
    end

    -- ── WATERMARK ──
    if showWatermark then
        local watermark = create("Frame", {
            BackgroundColor3 = theme.Background,
            Position = UDim2.new(0, 12, 0, 12),
            Size = UDim2.new(0, 230, 0, 28),
            BorderSizePixel = 0,
            Parent = gui,
        })
        corner(watermark, 6)
        stroke(watermark, theme.Border, 1, 0.3)
        shadow(watermark, 0.65)

        -- tiny accent dot
        local dot = create("Frame", {
            BackgroundColor3 = theme.Accent,
            Position = UDim2.new(0, 8, 0.5, -3),
            Size = UDim2.new(0, 6, 0, 6),
            BorderSizePixel = 0,
            Parent = watermark,
        })
        corner(dot, 3)

        local wmLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 20, 0, 0),
            Size = UDim2.new(1, -24, 1, 0),
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Scriptora • loading…",
            Parent = watermark,
        })

        makeDraggable(watermark, watermark)

        task.spawn(function()
            local lastFrame = tick()
            while watermark and watermark.Parent do
                local now = tick()
                local fps = math.floor(1 / math.max(now - lastFrame, 0.001))
                lastFrame = now
                local ping = 0
                pcall(function() ping = math.floor(Stats.PerformanceStats.Ping:GetValue()) end)
                wmLabel.Text = string.format("Scriptora  •  %d FPS  •  %d ms  •  %s",
                    fps, ping, os.date("%H:%M:%S"))
                task.wait(0.5)
            end
        end)
    end

    -- ── TOGGLE KEY ──
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then W:Toggle() end
    end)

    -- ── SPLASH -> REVEAL ──
    task.spawn(function()
        task.wait(0.75)
        tween(splash, 0.25, { BackgroundTransparency = 1 })
        tween(splashAccent, 0.2, { BackgroundTransparency = 1 })
        tween(splashTitle, 0.2, { TextTransparency = 1 })
        tween(splashSub, 0.2, { TextTransparency = 1 })
        tween(splashBar, 0.2, { BackgroundTransparency = 1 })
        tween(splashFill, 0.2, { BackgroundTransparency = 1 })
        task.wait(0.3)
        splash:Destroy()
        tween(main, 0.45, { Size = size, BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
    end)

    -- ============================================================
    -- // TAB CREATION
    -- ============================================================
    function W:CreateTab(tabOpts)
        tabOpts = tabOpts or {}
        local tab = {}
        tab.Name = tabOpts.Name or "Tab"
        tab.Icon = tabOpts.Icon or ""
        tab.Elements = {}

        local page = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
            ScrollBarThickness = 2,
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

        local tabBtn = create("TextButton", {
            BackgroundColor3 = theme.Tertiary,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 34),
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "          " .. tab.Name,
            AutoButtonColor = false,
            Parent = tabHolder,
        })
        corner(tabBtn, 7)

        if tab.Icon ~= "" then
            create("ImageLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                Image = tab.Icon,
                ImageColor3 = theme.SubText,
                Parent = tabBtn,
            })
        end

        -- left accent indicator
        local accentBar = create("Frame", {
            BackgroundColor3 = theme.Accent,
            Position = UDim2.new(0, 0, 0.5, -7),
            Size = UDim2.new(0, 0, 0, 14),
            BorderSizePixel = 0,
            Parent = tabBtn,
        })
        corner(accentBar, 2)

        tab.Button = tabBtn

        local function selectTab()
            for _, t in ipairs(W.Tabs) do
                t.Page.Visible = false
                tween(t.Button, 0.2, { BackgroundTransparency = 1, TextColor3 = W.CurrentTheme.SubText })
                local ab = t.Button:FindFirstChildOfClass("Frame")
                if ab then tween(ab, 0.2, { Size = UDim2.new(0, 0, 0, 14) }) end
            end
            page.Visible = true
            tween(tabBtn, 0.2, { BackgroundTransparency = 0.15, BackgroundColor3 = W.CurrentTheme.Tertiary, TextColor3 = W.CurrentTheme.Text })
            tween(accentBar, 0.25, { Size = UDim2.new(0, 3, 0, 18) }, Enum.EasingStyle.Back)
            page.CanvasPosition = Vector2.new(0, 0)
        end

        tabBtn.MouseButton1Click:Connect(selectTab)
        tabBtn.MouseEnter:Connect(function()
            if not page.Visible then
                tween(tabBtn, 0.15, { TextColor3 = W.CurrentTheme.Text, BackgroundTransparency = 0.5 })
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if not page.Visible then
                tween(tabBtn, 0.15, { TextColor3 = W.CurrentTheme.SubText, BackgroundTransparency = 1 })
            end
        end)

        if #W.Tabs == 0 then selectTab() end
        table.insert(W.Tabs, tab)

        -- element registration for search
        local function registerElement(frame, searchText, name)
            table.insert(W.AllElements, {
                Frame = frame,
                Name = string.lower(searchText or name or ""),
                DisplayName = name or "",
                Tab = tab,
            })
        end

        -- ====================================================
        -- // SECTION
        -- ====================================================
        function tab:AddSection(name)
            local holder = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 24),
                Parent = page,
            })
            local label = W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = string.upper(name),
                Parent = holder,
            }), { TextColor3 = "SubText" })

            local line = W:themed(create("Frame", {
                BackgroundColor3 = theme.Border,
                BackgroundTransparency = 0.5,
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 0, 1),
                BorderSizePixel = 0,
                ZIndex = 0,
                Parent = holder,
            }), { BackgroundColor3 = "Border" })

            label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                line.Position = UDim2.new(0, label.AbsoluteSize.X + 10, 0.5, 0)
                line.Size = UDim2.new(1, -(label.AbsoluteSize.X + 10), 0, 1)
            end)

            return { Label = label }
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
                Size = UDim2.new(1, 0, 0, desc ~= "" and 52 or 38),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 8)
            W:themed(stroke(frame, theme.Border, 1, 0.4), { Color = "Border" })

            local btn = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                AutoButtonColor = false,
                Parent = frame,
            })
            addRipple(btn, theme)

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, desc ~= "" and 7 or 0),
                Size = desc ~= "" and UDim2.new(1, -36, 0, 18) or UDim2.new(1, -36, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = btnTitle,
                Parent = frame,
            }), { TextColor3 = "Text" })

            if desc ~= "" then
                W:themed(create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0, 27),
                    Size = UDim2.new(1, -36, 0, 16),
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
                Position = UDim2.new(1, -24, 0, 0),
                Size = UDim2.new(0, 14, 1, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = theme.Disabled,
                Text = "›",
                Parent = frame,
            }), { TextColor3 = "Disabled" })

            btn.MouseEnter:Connect(function()
                tween(frame, 0.15, { BackgroundColor3 = theme.Tertiary })
                tween(arrow, 0.15, { TextColor3 = theme.Accent, Position = UDim2.new(1, -20, 0, 0) })
            end)
            btn.MouseLeave:Connect(function()
                tween(frame, 0.15, { BackgroundColor3 = theme.Secondary })
                tween(arrow, 0.15, { TextColor3 = theme.Disabled, Position = UDim2.new(1, -24, 0, 0) })
            end)
            btn.MouseButton1Click:Connect(function()
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
                Size = UDim2.new(1, 0, 0, desc ~= "" and 52 or 38),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 8)
            W:themed(stroke(frame, theme.Border, 1, 0.4), { Color = "Border" })

            local btn = create("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Text = "",
                AutoButtonColor = false,
                Parent = frame,
            })

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, desc ~= "" and 7 or 0),
                Size = desc ~= "" and UDim2.new(1, -66, 0, 18) or UDim2.new(1, -66, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            }), { TextColor3 = "Text" })

            if desc ~= "" then
                W:themed(create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 14, 0, 27),
                    Size = UDim2.new(1, -66, 0, 16),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = theme.SubText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = desc,
                    Parent = frame,
                }), { TextColor3 = "SubText" })
            end

            -- switch track
            local switch = create("Frame", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(1, -46, 0.5, -10),
                Size = UDim2.new(0, 34, 0, 18),
                BorderSizePixel = 0,
                Parent = frame,
            })
            corner(switch, 9)

            -- knob
            local knob = create("Frame", {
                BackgroundColor3 = theme.Text,
                Position = UDim2.new(0, 2, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                BorderSizePixel = 0,
                Parent = switch,
            })
            corner(knob, 7)

            -- glow behind knob when active
            local knobGlow = create("Frame", {
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 20, 0, 20),
                Parent = knob,
            })
            corner(knobGlow, 10)

            local function refresh()
                if toggle.Value then
                    tween(switch, 0.2, { BackgroundColor3 = theme.Accent })
                    tween(knob, 0.25, { Position = UDim2.new(1, -16, 0.5, -7), BackgroundColor3 = theme.Text }, Enum.EasingStyle.Back)
                    tween(knobGlow, 0.2, { BackgroundTransparency = 0.75 })
                else
                    tween(switch, 0.2, { BackgroundColor3 = theme.Element })
                    tween(knob, 0.25, { Position = UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = theme.SubText }, Enum.EasingStyle.Back)
                    tween(knobGlow, 0.2, { BackgroundTransparency = 1 })
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
                Size = UDim2.new(1, 0, 0, 58),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 8)
            W:themed(stroke(frame, theme.Border, 1, 0.4), { Color = "Border" })

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 8),
                Size = UDim2.new(1, -28, 0, 16),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            }), { TextColor3 = "Text" })

            -- value badge
            local valueBg = create("Frame", {
                BackgroundColor3 = theme.Accent,
                BackgroundTransparency = 0.85,
                Position = UDim2.new(1, -64, 0, 6),
                Size = UDim2.new(0, 50, 0, 20),
                BorderSizePixel = 0,
                Parent = frame,
            })
            corner(valueBg, 5)

            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = theme.Accent,
                Text = tostring(default) .. suffix,
                Parent = valueBg,
            })

            local track = W:themed(create("Frame", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(0, 14, 1, -18),
                Size = UDim2.new(1, -28, 0, 6),
                BorderSizePixel = 0,
                Parent = frame,
            }), { BackgroundColor3 = "Element" })
            corner(track, 3)

            local fill = create("Frame", {
                BackgroundColor3 = theme.Accent,
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BorderSizePixel = 0,
                Parent = track,
            })
            corner(fill, 3)
            gradient(fill, ColorSequence.new(theme.AccentDim, theme.Accent), 0)

            local knob = create("Frame", {
                BackgroundColor3 = theme.Text,
                Position = UDim2.new(1, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.new(0, 14, 0, 14),
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = fill,
            })
            corner(knob, 7)
            stroke(knob, theme.Accent, 2, 0.2)

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
                tween(fill, 0.08, { Size = UDim2.new(pct, 0, 1, 0) })
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
                    if dragging then tween(knob, 0.15, { Size = UDim2.new(0, 14, 0, 14) }) end
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
                Size = UDim2.new(1, 0, 0, 52),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 8)
            W:themed(stroke(frame, theme.Border, 1, 0.4), { Color = "Border" })

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 7),
                Size = UDim2.new(1, -28, 0, 16),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            }), { TextColor3 = "Text" })

            local selectButton = create("TextButton", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(0, 14, 0, 26),
                Size = UDim2.new(1, -28, 0, 22),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "  Select…",
                AutoButtonColor = false,
                Parent = frame,
            })
            corner(selectButton, 5)
            addRipple(selectButton, theme)

            local arrow = create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -18, 0, 0),
                Size = UDim2.new(0, 14, 1, 0),
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = theme.Disabled,
                Text = "▼",
                Parent = selectButton,
            })

            local optionsHolder = create("Frame", {
                BackgroundColor3 = theme.Tertiary,
                Position = UDim2.new(0, 14, 0, 52),
                Size = UDim2.new(1, -28, 0, 0),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = frame,
            })
            corner(optionsHolder, 5)
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

            local optionButtons = {}

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

            local function refreshButtonStates()
                for opt, b in pairs(optionButtons) do
                    local sel = false
                    if multi then
                        for _, v in ipairs(dropdown.Value) do if v == opt then sel = true break end end
                    else
                        sel = (dropdown.Value == opt)
                    end
                    if sel then
                        tween(b, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = W.CurrentTheme.Accent, TextColor3 = W.CurrentTheme.Text })
                    else
                        tween(b, 0.15, { BackgroundTransparency = 1, TextColor3 = W.CurrentTheme.SubText })
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
                        Size = UDim2.new(1, 0, 0, 24),
                        Font = Enum.Font.Gotham,
                        TextSize = 12,
                        TextColor3 = theme.SubText,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Text = "  " .. tostring(opt),
                        AutoButtonColor = false,
                        Parent = optionsList,
                    })
                    corner(optBtn, 5)
                    optionButtons[opt] = optBtn

                    optBtn.MouseEnter:Connect(function()
                        local isSel = false
                        if multi then
                            for _, v in ipairs(dropdown.Value) do if v == opt then isSel = true break end end
                        else isSel = (dropdown.Value == opt) end
                        if not isSel then
                            tween(optBtn, 0.12, { BackgroundTransparency = 0.4, BackgroundColor3 = W.CurrentTheme.Element, TextColor3 = W.CurrentTheme.Text })
                        end
                    end)
                    optBtn.MouseLeave:Connect(refreshButtonStates)

                    optBtn.MouseButton1Click:Connect(function()
                        if multi then
                            local idx
                            for i, v in ipairs(dropdown.Value) do if v == opt then idx = i break end end
                            if idx then table.remove(dropdown.Value, idx) else table.insert(dropdown.Value, opt) end
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
                    local h = math.min(#dropdown.Options * 26 + 8, 140)
                    tween(frame, 0.25, { Size = UDim2.new(1, 0, 0, 52 + h + 6) })
                    tween(optionsHolder, 0.25, { Size = UDim2.new(1, -28, 0, h) })
                    tween(arrow, 0.2, { Rotation = 180 })
                else
                    tween(frame, 0.25, { Size = UDim2.new(1, 0, 0, 52) })
                    tween(optionsHolder, 0.25, { Size = UDim2.new(1, -28, 0, 0) })
                    tween(arrow, 0.2, { Rotation = 0 })
                end
            end

            function dropdown:Refresh(newOptions, keepSelection)
                dropdown.Options = newOptions or {}
                if not keepSelection then dropdown.Value = multi and {} or nil end
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
                Size = UDim2.new(1, 0, 0, 52),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 8)
            W:themed(stroke(frame, theme.Border, 1, 0.4), { Color = "Border" })

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 7),
                Size = UDim2.new(1, -28, 0, 16),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            }), { TextColor3 = "Text" })

            local box = create("TextBox", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(0, 14, 0, 26),
                Size = UDim2.new(1, -28, 0, 22),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.Text,
                PlaceholderColor3 = theme.Disabled,
                PlaceholderText = placeholder,
                Text = default,
                ClearTextOnFocus = clearOnFocus,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = frame,
            })
            corner(box, 5)
            padding(box, 0, 8)
            local boxStroke = stroke(box, theme.Border, 1, 0.5)

            box.Focused:Connect(function()
                tween(boxStroke, 0.15, { Color = theme.Accent, Transparency = 0 })
            end)
            box.FocusLost:Connect(function(enter)
                tween(boxStroke, 0.15, { Color = theme.Border, Transparency = 0.5 })
                if numericOnly then box.Text = box.Text:gsub("[^%-%d%.]", "") end
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
                Size = UDim2.new(1, 0, 0, 38),
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 8)
            W:themed(stroke(frame, theme.Border, 1, 0.4), { Color = "Border" })

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -100, 1, 0),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            }), { TextColor3 = "Text" })

            local btn = create("TextButton", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(1, -84, 0.5, -11),
                Size = UDim2.new(0, 72, 0, 22),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = theme.SubText,
                Text = default.Name,
                AutoButtonColor = false,
                Parent = frame,
            })
            corner(btn, 5)
            stroke(btn, theme.Border, 1, 0.5)
            addRipple(btn, theme)

            btn.MouseButton1Click:Connect(function()
                keybind.Listening = true
                btn.Text = "…"
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
                    btn.TextColor3 = theme.SubText
                    if flag then Scriptora.Flags[flag] = keybind.Key end
                    return
                end
                if not gpe and not keybind.Listening and input.KeyCode == keybind.Key then
                    if mode == "Press" then task.spawn(callback)
                    elseif mode == "Toggle" then keybind.Toggled = not keybind.Toggled; task.spawn(callback, keybind.Toggled)
                    elseif mode == "Hold" then task.spawn(callback, true) end
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if mode == "Hold" and input.KeyCode == keybind.Key then task.spawn(callback, false) end
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
        -- // COLOR PICKER (Enhanced)
        -- ====================================================
        function tab:AddColorPicker(opts)
            opts = opts or {}
            local title = opts.Title or opts.Name or "Color"
            local default = opts.Default or Color3.fromRGB(168, 96, 255)
            local flag = opts.Flag
            local callback = opts.Callback or function() end

            local picker = { Value = default, Open = false }

            local frame = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, 38),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = page,
            })
            W:themed(frame, { BackgroundColor3 = "Secondary" })
            corner(frame, 8)
            W:themed(stroke(frame, theme.Border, 1, 0.4), { Color = "Border" })

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -50, 0, 38),
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = title,
                Parent = frame,
            }), { TextColor3 = "Text" })

            -- swatch button
            local swatchOuter = create("Frame", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(1, -38, 0.5, -12),
                Size = UDim2.new(0, 28, 0, 24),
                BorderSizePixel = 0,
                Parent = frame,
            })
            corner(swatchOuter, 6)

            local swatch = create("TextButton", {
                BackgroundColor3 = default,
                Position = UDim2.new(0, 3, 0, 3),
                Size = UDim2.new(1, -6, 1, -6),
                Text = "",
                AutoButtonColor = false,
                Parent = swatchOuter,
            })
            corner(swatch, 4)

            -- expanded picker area
            local pickerFrame = create("Frame", {
                BackgroundColor3 = theme.Tertiary,
                Position = UDim2.new(0, 10, 0, 42),
                Size = UDim2.new(1, -20, 0, 170),
                BorderSizePixel = 0,
                Parent = frame,
            })
            corner(pickerFrame, 8)
            stroke(pickerFrame, theme.Border, 1, 0.4)

            -- SV canvas (saturation/value)
            local svCanvas = create("ImageLabel", {
                BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                Position = UDim2.new(0, 8, 0, 8),
                Size = UDim2.new(0, 120, 0, 100),
                Image = "rbxassetid://4155801252",
                BorderSizePixel = 0,
                Parent = pickerFrame,
            })
            corner(svCanvas, 6)

            -- SV cursor
            local svCursor = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 14, 0, 14),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                ZIndex = 3,
                Parent = svCanvas,
            })
            local svRing = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                Parent = svCursor,
            })
            corner(svRing, 7)
            stroke(svRing, Color3.fromRGB(255, 255, 255), 2)
            -- dark inner ring for contrast
            local svRingInner = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                Parent = svCursor,
            })
            corner(svRingInner, 6)
            stroke(svRingInner, Color3.fromRGB(0, 0, 0), 1, 0.5)

            -- Hue bar (vertical)
            local hueBar = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 136, 0, 8),
                Size = UDim2.new(0, 16, 0, 100),
                BorderSizePixel = 0,
                Parent = pickerFrame,
            })
            local hueBg = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Size = UDim2.new(1, 0, 1, 0),
                BorderSizePixel = 0,
                Parent = hueBar,
            })
            corner(hueBg, 4)
            local hueGrad = create("UIGradient", { Parent = hueBg })
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

            -- hue cursor
            local hueCursor = create("Frame", {
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(1, 4, 0, 6),
                BorderSizePixel = 0,
                ZIndex = 3,
                Parent = hueBar,
            })
            corner(hueCursor, 3)
            stroke(hueCursor, Color3.fromRGB(0, 0, 0), 1, 0.4)

            -- color preview + info on right
            local rightCol = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 160, 0, 8),
                Size = UDim2.new(1, -168, 0, 100),
                Parent = pickerFrame,
            })
            listLayout(rightCol, 4)

            -- preview swatch (large)
            local preview = create("Frame", {
                BackgroundColor3 = default,
                Size = UDim2.new(1, 0, 0, 28),
                BorderSizePixel = 0,
                Parent = rightCol,
            })
            corner(preview, 6)
            stroke(preview, theme.Border, 1, 0.4)

            -- hex input
            local function makeColorInput(label, val)
                local c = create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    Parent = rightCol,
                })
                create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 18, 1, 0),
                    Font = Enum.Font.GothamBold,
                    TextSize = 9,
                    TextColor3 = theme.SubText,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = label,
                    Parent = c,
                })
                local b = create("TextBox", {
                    BackgroundColor3 = theme.Element,
                    Position = UDim2.new(0, 20, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 10,
                    TextColor3 = theme.Text,
                    Text = val,
                    ClearTextOnFocus = false,
                    Parent = c,
                })
                corner(b, 3)
                padding(b, 0, 4)
                return b
            end

            local hexInput = makeColorInput("H", "#" .. default:ToHex():upper())
            local rInput = makeColorInput("R", tostring(math.floor(default.R * 255)))
            local gInput = makeColorInput("G", tostring(math.floor(default.G * 255)))
            local bInput = makeColorInput("B", tostring(math.floor(default.B * 255)))

            -- preset colors row
            local presetRow = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 116),
                Size = UDim2.new(1, -16, 0, 22),
                Parent = pickerFrame,
            })
            listLayout(presetRow, 4, Enum.FillDirection.Horizontal)

            local presets = {
                Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 180, 180),
                Color3.fromRGB(255, 82, 82), Color3.fromRGB(255, 150, 50),
                Color3.fromRGB(255, 220, 50), Color3.fromRGB(80, 220, 100),
                Color3.fromRGB(50, 180, 255), Color3.fromRGB(168, 96, 255),
                Color3.fromRGB(255, 100, 180), Color3.fromRGB(0, 0, 0),
            }

            local h, s, v = Color3.toHSV(default)
            local updating = false

            local function updateColor(fromInputs)
                if updating then return end
                updating = true
                local color = Color3.fromHSV(h, s, v)
                picker.Value = color
                swatch.BackgroundColor3 = color
                preview.BackgroundColor3 = color
                svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

                -- position cursors
                svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                hueCursor.Position = UDim2.new(0.5, 0, h, 0)

                if not fromInputs then
                    rInput.Text = math.floor(color.R * 255)
                    gInput.Text = math.floor(color.G * 255)
                    bInput.Text = math.floor(color.B * 255)
                    hexInput.Text = "#" .. color:ToHex():upper()
                end

                if flag then Scriptora.Flags[flag] = color end
                task.spawn(callback, color)
                updating = false
            end

            -- preset buttons
            for _, pc in ipairs(presets) do
                local pb = create("TextButton", {
                    BackgroundColor3 = pc,
                    Size = UDim2.new(0, 18, 0, 18),
                    Text = "",
                    AutoButtonColor = false,
                    Parent = presetRow,
                })
                corner(pb, 4)
                stroke(pb, theme.Border, 1, 0.5)
                pb.MouseButton1Click:Connect(function()
                    h, s, v = Color3.toHSV(pc)
                    updateColor()
                end)
            end

            -- copy hex button
            local copyBtn = create("TextButton", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(0, 8, 0, 144),
                Size = UDim2.new(0.5, -12, 0, 20),
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = theme.SubText,
                Text = "Copy HEX",
                AutoButtonColor = false,
                Parent = pickerFrame,
            })
            corner(copyBtn, 4)
            copyBtn.MouseButton1Click:Connect(function()
                Executor.setclipboard("#" .. picker.Value:ToHex():upper())
                copyBtn.Text = "Copied!"
                task.delay(1, function() copyBtn.Text = "Copy HEX" end)
            end)

            -- close button
            local closeBtn = create("TextButton", {
                BackgroundColor3 = theme.Element,
                Position = UDim2.new(0.5, 4, 0, 144),
                Size = UDim2.new(0.5, -12, 0, 20),
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = theme.SubText,
                Text = "Close",
                AutoButtonColor = false,
                Parent = pickerFrame,
            })
            corner(closeBtn, 4)

            -- input callbacks
            local function onRGBChange()
                local r = math.clamp(tonumber(rInput.Text) or 0, 0, 255)
                local g = math.clamp(tonumber(gInput.Text) or 0, 0, 255)
                local b2 = math.clamp(tonumber(bInput.Text) or 0, 0, 255)
                local c = Color3.fromRGB(r, g, b2)
                h, s, v = Color3.toHSV(c)
                updateColor(true)
                hexInput.Text = "#" .. c:ToHex():upper()
            end

            local function onHexChange()
                local hex = hexInput.Text:gsub("#", "")
                if #hex == 6 then
                    local ok, c = pcall(Color3.fromHex, hex)
                    if ok then
                        h, s, v = Color3.toHSV(c)
                        updateColor(true)
                        rInput.Text = math.floor(c.R * 255)
                        gInput.Text = math.floor(c.G * 255)
                        bInput.Text = math.floor(c.B * 255)
                    end
                end
            end

            rInput.FocusLost:Connect(onRGBChange)
            gInput.FocusLost:Connect(onRGBChange)
            bInput.FocusLost:Connect(onRGBChange)
            hexInput.FocusLost:Connect(onHexChange)

            -- SV and hue dragging
            local svDrag, hueDrag = false, false
            svCanvas.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    svDrag = true
                end
            end)
            hueBar.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    hueDrag = true
                end
            end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    svDrag, hueDrag = false, false
                end
            end)
            UserInputService.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
                    if svDrag then
                        s = math.clamp((Mouse.X - svCanvas.AbsolutePosition.X) / svCanvas.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((Mouse.Y - svCanvas.AbsolutePosition.Y) / svCanvas.AbsoluteSize.Y, 0, 1)
                        updateColor()
                    elseif hueDrag then
                        h = math.clamp((Mouse.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                        updateColor()
                    end
                end
            end)

            local function togglePicker(state)
                picker.Open = state
                if picker.Open then
                    tween(frame, 0.3, { Size = UDim2.new(1, 0, 0, 38 + 178) })
                else
                    tween(frame, 0.3, { Size = UDim2.new(1, 0, 0, 38) })
                end
            end

            swatch.MouseButton1Click:Connect(function() togglePicker(not picker.Open) end)
            closeBtn.MouseButton1Click:Connect(function() togglePicker(false) end)

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
            local lbl = W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = text or "",
                Parent = page,
            }), { TextColor3 = "SubText" })
            local label = { Frame = lbl }
            function label:Set(t) lbl.Text = t end
            return label
        end

        function tab:AddParagraph(opts)
            opts = opts or {}
            local ptitle = opts.Title or "Paragraph"
            local pcontent = opts.Content or ""

            local pframe = create("Frame", {
                BackgroundColor3 = theme.Secondary,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                Parent = page,
            })
            W:themed(pframe, { BackgroundColor3 = "Secondary" })
            corner(pframe, 8)
            W:themed(stroke(pframe, theme.Border, 1, 0.4), { Color = "Border" })

            local ppad = create("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Parent = pframe,
            })
            padding(ppad, 12)

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = ptitle,
                Parent = ppad,
            }), { TextColor3 = "Text" })

            W:themed(create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = theme.SubText,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Text = pcontent,
                Parent = ppad,
            }), { TextColor3 = "SubText" })

            registerElement(pframe, ptitle .. " " .. pcontent, ptitle)
            return pframe
        end

        function tab:AddDivider()
            return W:themed(create("Frame", {
                BackgroundColor3 = theme.Border,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, 0, 0, 1),
                BorderSizePixel = 0,
                Parent = page,
            }), { BackgroundColor3 = "Border" })
        end

        return tab
    end

    -- ============================================================
    -- // SEARCH
    -- ============================================================
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(searchBox.Text)
        if query == "" then
            for _, entry in ipairs(W.AllElements) do
                entry.Frame.Visible = true
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
        for k, val in pairs(Scriptora.Flags) do
            if typeof(val) == "Color3" then
                data[k] = { _t = "Color3", r = val.R, g = val.G, b = val.B }
            elseif typeof(val) == "EnumItem" then
                data[k] = { _t = "EnumItem", e = tostring(val.EnumType), n = val.Name }
            elseif typeof(val) == "table" then
                data[k] = { _t = "table", v = val }
            else
                data[k] = val
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
        for k, val in pairs(data) do
            if type(val) == "table" and val._t == "Color3" then
                Scriptora.Flags[k] = Color3.new(val.r, val.g, val.b)
            elseif type(val) == "table" and val._t == "EnumItem" then
                Scriptora.Flags[k] = Enum[val.e:gsub("Enum%.", "")][val.n]
            elseif type(val) == "table" and val._t == "table" then
                Scriptora.Flags[k] = val.v
            else
                Scriptora.Flags[k] = val
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
            local n = f:match("([^/\\]+)%.json$")
            if n then table.insert(list, n) end
        end
        return list
    end

    -- ============================================================
    -- // THEME SWITCH
    -- ============================================================
    function W:SetTheme(tName)
        local newTheme = Scriptora.Themes[tName]
        if not newTheme then return end
        W.CurrentTheme = newTheme
        W.CurrentThemeName = tName
        theme = newTheme

        for _, item in ipairs(W.ThemedItems) do
            if item.Inst and item.Inst.Parent then
                for prop, key in pairs(item.Map) do
                    pcall(function()
                        local val
                        if type(key) == "function" then
                            val = key(newTheme)
                        else
                            val = newTheme[key]
                        end
                        if val ~= nil then item.Inst[prop] = val end
                    end)
                end
            end
        end

        W:Notify({
            Title = "Theme",
            Content = "Switched to " .. tName,
            Type = "info",
            Duration = 2.5,
        })
    end

    -- ============================================================
    -- // WINDOW METHODS
    -- ============================================================
    function W:Toggle()
        W.Visible = not W.Visible
        if W.Visible then
            main.Visible = true
            tween(main, 0.35, { Size = size, BackgroundTransparency = 0 }, Enum.EasingStyle.Back)
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
        local dtitle = opts.Title or "Dialog"
        local dcontent = opts.Content or ""
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
        corner(box, 10)
        stroke(box, theme.Border, 1)
        shadow(box, 0.35)

        tween(box, 0.3, { Size = UDim2.new(0, 300, 0, 150), BackgroundTransparency = 0 }, Enum.EasingStyle.Back)

        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 14),
            Size = UDim2.new(1, -32, 0, 18),
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = dtitle,
            ZIndex = 52,
            Parent = box,
        })
        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 0, 38),
            Size = UDim2.new(1, -32, 0, 68),
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = dcontent,
            ZIndex = 52,
            Parent = box,
        })

        local btnHolder = create("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 16, 1, -40),
            Size = UDim2.new(1, -32, 0, 30),
            ZIndex = 52,
            Parent = box,
        })
        listLayout(btnHolder, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right)

        local function close()
            tween(overlay, 0.2, { BackgroundTransparency = 1 })
            tween(box, 0.2, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
            task.wait(0.25)
            overlay:Destroy()
        end

        for _, b in ipairs(buttons) do
            local dbtn = create("TextButton", {
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
            corner(dbtn, 6)
            addRipple(dbtn, theme)
            dbtn.MouseButton1Click:Connect(function()
                if b.Callback then task.spawn(b.Callback) end
                close()
            end)
            dbtn.MouseEnter:Connect(function()
                tween(dbtn, 0.15, { BackgroundColor3 = b.Primary and theme.AccentHover or theme.ElementHover })
            end)
            dbtn.MouseLeave:Connect(function()
                tween(dbtn, 0.15, { BackgroundColor3 = b.Primary and theme.Accent or theme.Element })
            end)
        end
    end

    table.insert(Scriptora.Windows, W)
    return W
end

function Scriptora:DestroyAll()
    for _, w in ipairs(Scriptora.Windows) do
        pcall(function() w:Destroy() end)
    end
    table.clear(Scriptora.Windows)
end

getgenv().Scriptora = Scriptora
return Scriptora
