-- ============================================================
--   YUNO PLAYER  |  Hub Script  |  Roblox Executor
--   Modes: YouTube Music (Spotify-style) / YouTube Video
--   Utility: IP Lookup, Server Info, Player Tools, Config
-- ============================================================

getgenv().YUNO_HUB = getgenv().YUNO_HUB or false
if getgenv().YUNO_HUB then return end
getgenv().YUNO_HUB = true

-- ============================================================
--  SERVICES
-- ============================================================
local fn = cloneref or function(a) return a end

local Players        = fn(game:GetService("Players"))
local TweenService   = fn(game:GetService("TweenService"))
local UserInput      = fn(game:GetService("UserInputService"))
local RunService     = fn(game:GetService("RunService"))
local CoreGui        = fn(game:GetService("CoreGui"))
local StarterGui     = fn(game:GetService("StarterGui"))
local HttpService    = fn(game:GetService("HttpService"))
local SoundService   = fn(game:GetService("SoundService"))
local Workspace      = fn(game:GetService("Workspace"))
local TextService    = fn(game:GetService("TextService"))

local LP             = Players.LocalPlayer
local Camera         = Workspace.CurrentCamera

-- ============================================================
--  EXECUTOR COMPAT
-- ============================================================
local request_ = request or http_request or syn and syn.request
    or http and http.request or fluxus and fluxus.request
    or getgenv and getgenv().request

local setclipboard_ = setclipboard or toclipboard
    or syn and syn.write_clipboard
    or fluxus and fluxus.setclipboard

local gethwid_ = (gethwid and gethwid())
    or (syn and syn.gethwid and syn.gethwid())
    or (fluxus and fluxus.gethwid and fluxus.gethwid())

-- ============================================================
--  CONSTANTS / CONFIG
-- ============================================================
local CONFIG = {
    HUB_NAME        = "Yuno Player",
    VERSION         = "1.0",
    YMP_SCRIPT_URL  = "https://raw.githubusercontent.com/Dan41/Roblox-Scripts/refs/heads/main/Youtube%20Music%20Player/YoutubeMusicPlayer.lua",
    IP_API_URL      = "https://api.ipify.org?format=json",
    GEO_API_URL     = "http://ip-api.com/json/",
    ACCENT_RED      = Color3.fromRGB(255, 30, 30),
    ACCENT_GREEN    = Color3.fromRGB(30, 215, 96),   -- Spotify green
    BG_DARK         = Color3.fromRGB(10, 10, 10),
    BG_MID          = Color3.fromRGB(18, 18, 18),
    BG_CARD         = Color3.fromRGB(24, 24, 24),
    BG_SURFACE      = Color3.fromRGB(32, 32, 32),
    TEXT_PRIMARY    = Color3.fromRGB(255, 255, 255),
    TEXT_SECONDARY  = Color3.fromRGB(180, 180, 180),
    TEXT_MUTED      = Color3.fromRGB(110, 110, 110),
    CORNER_SM       = UDim.new(0, 4),
    CORNER_MD       = UDim.new(0, 8),
    CORNER_LG       = UDim.new(0, 16),
    CORNER_FULL     = UDim.new(1, 0),
}

-- Asset IDs used for drawn icons (all rbxassetid)
local ICONS = {
    LOGO            = "rbxassetid://132058030456598",   -- YMP logo (reuse)
    YOUTUBE         = "rbxassetid://83758613781843",    -- YT icon
    PLAY            = "rbxassetid://7743878857",
    PAUSE           = "rbxassetid://7743877799",
    SKIP_NEXT       = "rbxassetid://7743876375",
    SKIP_PREV       = "rbxassetid://7743875893",
    SHUFFLE         = "rbxassetid://7743880065",
    REPEAT_ICO      = "rbxassetid://7743879471",
    HEART           = "rbxassetid://7743874909",
    HEART_FILL      = "rbxassetid://7743874283",
    SEARCH          = "rbxassetid://7743881379",
    SETTINGS        = "rbxassetid://7734055498",
    MUSIC_NOTE      = "rbxassetid://7734049836",
    VIDEO_ICO       = "rbxassetid://7734048734",
    GLOBE           = "rbxassetid://7734046732",
    COPY            = "rbxassetid://7734045622",
    CLOSE_X         = "rbxassetid://7734043826",
    USER            = "rbxassetid://7734042734",
    SERVER          = "rbxassetid://7734041528",
    VOLUME          = "rbxassetid://7734040324",
    ARROW_UP        = "rbxassetid://7734039128",
    ARROW_DOWN      = "rbxassetid://7734037924",
    STAR            = "rbxassetid://7734036718",
    INFO            = "rbxassetid://7734035512",
    WIFI            = "rbxassetid://7734034306",
    LOCATION        = "rbxassetid://7734033100",
}

-- ============================================================
--  TWEEN HELPERS
-- ============================================================
local TI = {
    fast   = TweenInfo.new(0.12, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    mid    = TweenInfo.new(0.25, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    slow   = TweenInfo.new(0.45, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    bounce = TweenInfo.new(0.55, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    spring = TweenInfo.new(0.35, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut),
    pop    = TweenInfo.new(0.22, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
}

local function tween(obj, info, props)
    return TweenService:Create(obj, info, props)
end

local function tweenPlay(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- ============================================================
--  INSTANCE BUILDER
-- ============================================================
local function new(class, props, parent)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(parent, radius)
    return new("UICorner", { CornerRadius = radius or CONFIG.CORNER_MD }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return new("UIStroke", {
        Color         = color or CONFIG.TEXT_MUTED,
        Thickness     = thickness or 1,
        Transparency  = transparency or 0,
    }, parent)
end

local function padding(parent, t, b, l, r)
    return new("UIPadding", {
        PaddingTop    = UDim.new(0, t or 8),
        PaddingBottom = UDim.new(0, b or 8),
        PaddingLeft   = UDim.new(0, l or 8),
        PaddingRight  = UDim.new(0, r or 8),
    }, parent)
end

local function listLayout(parent, dir, align, spacing)
    return new("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, spacing or 0),
    }, parent)
end

local function gridLayout(parent, cellSize, cellPad)
    return new("UIGridLayout", {
        CellSize            = cellSize or UDim2.new(0, 80, 0, 80),
        CellPaddingHorizontal = UDim.new(0, cellPad or 8),
        CellPaddingVertical   = UDim.new(0, cellPad or 8),
        SortOrder           = Enum.SortOrder.LayoutOrder,
    }, parent)
end

local function label(parent, text, size, color, font, props)
    local inst = new("TextLabel", {
        Size                = size or UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text                = text or "",
        TextColor3          = color or CONFIG.TEXT_PRIMARY,
        Font                = font or Enum.Font.GothamBold,
        TextScaled          = false,
        TextSize            = 14,
        TextXAlignment      = Enum.TextXAlignment.Left,
        RichText            = true,
    }, parent)
    if props then
        for k, v in pairs(props) do inst[k] = v end
    end
    return inst
end

local function imageLabel(parent, assetId, size, pos, props)
    local inst = new("ImageLabel", {
        Size                   = size or UDim2.new(0, 24, 0, 24),
        Position               = pos or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Image                  = assetId or "",
        ScaleType              = Enum.ScaleType.Fit,
    }, parent)
    if props then
        for k, v in pairs(props) do inst[k] = v end
    end
    return inst
end

local function btn(parent, text, size, pos, bgColor, textColor, props)
    local b = new("TextButton", {
        Size                   = size or UDim2.new(0, 120, 0, 36),
        Position               = pos or UDim2.new(0, 0, 0, 0),
        BackgroundColor3       = bgColor or CONFIG.ACCENT_RED,
        Text                   = text or "",
        TextColor3             = textColor or CONFIG.TEXT_PRIMARY,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 13,
        AutoButtonColor        = false,
        BorderSizePixel        = 0,
    }, parent)
    if props then
        for k, v in pairs(props) do b[k] = v end
    end
    corner(b, CONFIG.CORNER_MD)

    b.MouseEnter:Connect(function()
        tweenPlay(b, TI.fast, { BackgroundColor3 = bgColor and bgColor:Lerp(Color3.new(1,1,1), 0.12) or Color3.fromRGB(220, 20, 20) })
    end)
    b.MouseLeave:Connect(function()
        tweenPlay(b, TI.fast, { BackgroundColor3 = bgColor or CONFIG.ACCENT_RED })
    end)

    return b
end

local function iconBtn(parent, assetId, size, bgColor, props)
    local b = new("ImageButton", {
        Size                   = size or UDim2.new(0, 36, 0, 36),
        BackgroundColor3       = bgColor or Color3.fromRGB(0,0,0),
        BackgroundTransparency = bgColor and 0 or 1,
        Image                  = assetId or "",
        ScaleType              = Enum.ScaleType.Fit,
        AutoButtonColor        = false,
        BorderSizePixel        = 0,
    }, parent)
    if props then
        for k, v in pairs(props) do b[k] = v end
    end
    b.MouseEnter:Connect(function()
        tweenPlay(b, TI.fast, { ImageTransparency = 0.25 })
    end)
    b.MouseLeave:Connect(function()
        tweenPlay(b, TI.fast, { ImageTransparency = 0 })
    end)
    return b
end

-- ============================================================
--  DRAG LOGIC
-- ============================================================
local function makeDraggable(handle, target)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging   = true
            dragStart  = inp.Position
            startPos   = target.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)
    UserInput.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local delta = inp.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
--  NOTIFICATION SYSTEM
-- ============================================================
local notifContainer = nil

local function initNotifContainer()
    local existing = CoreGui:FindFirstChild("YunoNotif")
    if existing then existing:Destroy() end
    local sg = new("ScreenGui", { Name = "YunoNotif", IgnoreGuiInset = true, ResetOnSpawn = false }, CoreGui)
    notifContainer = new("Frame", {
        Size                   = UDim2.new(0, 300, 1, 0),
        Position               = UDim2.new(1, -310, 0, 0),
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(1, 0),
    }, sg)
    listLayout(notifContainer, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, 6)
    padding(notifContainer, 12, 12, 0, 0)
end

local function notify(title, text, duration, isError)
    if not notifContainer then initNotifContainer() end
    local card = new("Frame", {
        Size                   = UDim2.new(1, 0, 0, 0),
        BackgroundColor3       = CONFIG.BG_CARD,
        AutomaticSize          = Enum.AutomaticSize.Y,
        ClipsDescendants       = true,
        BorderSizePixel        = 0,
    }, notifContainer)
    corner(card, CONFIG.CORNER_MD)
    stroke(card, isError and CONFIG.ACCENT_RED or CONFIG.ACCENT_GREEN, 1, 0.3)
    padding(card, 10, 10, 12, 12)

    local accentBar = new("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = isError and CONFIG.ACCENT_RED or CONFIG.ACCENT_GREEN,
        BorderSizePixel  = 0,
    }, card)
    corner(accentBar, UDim.new(0, 2))

    local inner = new("Frame", {
        Size                   = UDim2.new(1, -10, 0, 0),
        Position               = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize          = Enum.AutomaticSize.Y,
    }, card)
    listLayout(inner, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 2)

    label(inner, title, UDim2.new(1, 0, 0, 18), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 13 })
    label(inner, text, UDim2.new(1, 0, 0, 0), CONFIG.TEXT_SECONDARY, Enum.Font.Gotham, {
        TextSize     = 12,
        TextWrapped  = true,
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    card.Size = UDim2.new(1, 0, 0, 0)
    tweenPlay(card, TI.bounce, { Size = UDim2.new(1, 0, 0, 70) })

    task.delay(duration or 4, function()
        if card and card.Parent then
            tweenPlay(card, TI.mid, { BackgroundTransparency = 1 })
            task.wait(0.28)
            if card and card.Parent then card:Destroy() end
        end
    end)
end

-- ============================================================
--  LOADING SCREEN
-- ============================================================
local loadingGui = nil

local function showLoading(onDone)
    local existing = CoreGui:FindFirstChild("YunoLoading")
    if existing then existing:Destroy() end

    local sg = new("ScreenGui", {
        Name            = "YunoLoading",
        IgnoreGuiInset  = true,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)
    loadingGui = sg

    -- Full-screen backdrop
    local backdrop = new("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
        ZIndex           = 1,
    }, sg)

    -- Subtle grid pattern drawn via many small frames (decorative)
    local gridDeco = new("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex                 = 1,
    }, backdrop)
    for row = 0, 8 do
        for col = 0, 12 do
            new("Frame", {
                Size             = UDim2.new(0, 1, 0, 1),
                Position         = UDim2.new(0, col * 80, 0, row * 90),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderSizePixel  = 0,
                ZIndex           = 1,
            }, gridDeco)
        end
    end

    -- Center container
    local center = new("Frame", {
        Size                   = UDim2.new(0, 320, 0, 340),
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex                 = 2,
    }, backdrop)
    listLayout(center, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, 14)
    padding(center, 0, 0, 0, 0)

    -- Logo frame
    local logoFrame = new("Frame", {
        Size                   = UDim2.new(0, 80, 0, 80),
        BackgroundColor3       = CONFIG.BG_SURFACE,
        BorderSizePixel        = 0,
        ZIndex                 = 3,
        LayoutOrder            = 1,
    }, center)
    corner(logoFrame, CONFIG.CORNER_LG)
    stroke(logoFrame, CONFIG.ACCENT_RED, 2, 0)
    imageLabel(logoFrame, ICONS.LOGO,
        UDim2.new(0.7, 0, 0.7, 0),
        UDim2.new(0.15, 0, 0.15, 0),
        { ZIndex = 4, AnchorPoint = Vector2.new(0, 0) }
    )

    -- Hub name
    local hubTitle = label(center, CONFIG.HUB_NAME,
        UDim2.new(1, 0, 0, 40), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
            TextSize            = 28,
            TextXAlignment      = Enum.TextXAlignment.Center,
            ZIndex              = 3,
            LayoutOrder         = 2,
        })

    -- Tagline
    label(center, "Your media. Your rules.",
        UDim2.new(1, 0, 0, 20), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            TextSize        = 13,
            TextXAlignment  = Enum.TextXAlignment.Center,
            ZIndex          = 3,
            LayoutOrder     = 3,
        })

    -- Progress bar background
    local barBg = new("Frame", {
        Size             = UDim2.new(0, 200, 0, 4),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        LayoutOrder      = 4,
    }, center)
    corner(barBg, CONFIG.CORNER_FULL)

    local barFill = new("Frame", {
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CONFIG.ACCENT_RED,
        BorderSizePixel  = 0,
        ZIndex           = 4,
    }, barBg)
    corner(barFill, CONFIG.CORNER_FULL)

    -- Status text
    local statusLabel = label(center, "Initializing...",
        UDim2.new(1, 0, 0, 18), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            TextSize        = 12,
            TextXAlignment  = Enum.TextXAlignment.Center,
            ZIndex          = 3,
            LayoutOrder     = 5,
        })

    -- Pulse the logo stroke
    task.spawn(function()
        local up = true
        while loadingGui and loadingGui.Parent do
            local targetAlpha = up and 0 or 0.5
            tweenPlay(logoFrame:FindFirstChildWhichIsA("UIStroke"), TI.spring, { Transparency = targetAlpha })
            task.wait(0.8)
            up = not up
        end
    end)

    -- Animate bar
    local steps = {
        { pct = 0.2,  text = "Loading modules..." },
        { pct = 0.45, text = "Connecting to services..." },
        { pct = 0.7,  text = "Building interface..." },
        { pct = 0.9,  text = "Almost ready..." },
        { pct = 1.0,  text = "Done!" },
    }

    task.spawn(function()
        for _, step in ipairs(steps) do
            if not loadingGui or not loadingGui.Parent then return end
            tweenPlay(barFill, TI.slow, { Size = UDim2.new(step.pct, 0, 1, 0) })
            statusLabel.Text = step.text
            task.wait(0.55)
        end

        task.wait(0.3)

        -- Fade out
        tweenPlay(backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        for _, d in ipairs(backdrop:GetDescendants()) do
            if d:IsA("GuiObject") then
                tweenPlay(d, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1, ImageTransparency = 1 })
            end
        end

        task.wait(0.45)
        if sg and sg.Parent then sg:Destroy() end
        loadingGui = nil

        if onDone then onDone() end
    end)
end

-- ============================================================
--  HUB ROOT GUI
-- ============================================================
local hubGui    = nil
local hubMain   = nil
local currentMode = nil  -- "music" | "video" | "config" | "utility"

local function destroyHub()
    if hubGui and hubGui.Parent then
        hubGui:Destroy()
        hubGui = nil
    end
end

-- ============================================================
--  MODE SELECTOR SCREEN  (shown after loading)
-- ============================================================
local function buildModeSelector(onSelect)
    local existing = CoreGui:FindFirstChild("YunoHub")
    if existing then existing:Destroy() end

    local sg = new("ScreenGui", {
        Name            = "YunoHub",
        IgnoreGuiInset  = true,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)
    hubGui = sg

    -- Main window
    local win = new("Frame", {
        Size             = UDim2.new(0, 560, 0, 400),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CONFIG.BG_MID,
        BorderSizePixel  = 0,
    }, sg)
    corner(win, CONFIG.CORNER_LG)
    stroke(win, CONFIG.BG_SURFACE, 1, 0)

    -- Titlebar
    local titlebar = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, win)
    corner(titlebar, CONFIG.CORNER_LG)
    -- clip bottom corners of titlebar by covering bottom area
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 20),
        Position         = UDim2.new(0, 0, 1, -20),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, titlebar)

    makeDraggable(titlebar, win)

    imageLabel(titlebar, ICONS.LOGO, UDim2.new(0, 28, 0, 28), UDim2.new(0, 12, 0, 10))

    label(titlebar, CONFIG.HUB_NAME, UDim2.new(0, 160, 0, 28),
        CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
            Position    = UDim2.new(0, 48, 0, 10),
            TextSize    = 15,
        })

    label(titlebar, "v" .. CONFIG.VERSION,
        UDim2.new(0, 40, 0, 28), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position  = UDim2.new(0, 206, 0, 10),
            TextSize  = 11,
        })

    local closeBtn = iconBtn(titlebar, ICONS.CLOSE_X,
        UDim2.new(0, 28, 0, 28), nil,
        { Position = UDim2.new(1, -36, 0.5, -14), AnchorPoint = Vector2.new(0, 0) })
    closeBtn.MouseButton1Click:Connect(function()
        tweenPlay(win, TI.mid, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
        task.wait(0.3)
        sg:Destroy()
    end)

    -- Body
    local body = new("Frame", {
        Size             = UDim2.new(1, 0, 1, -48),
        Position         = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
    }, win)
    padding(body, 20, 20, 20, 20)

    label(body, "Choose your mode", UDim2.new(1, 0, 0, 26),
        CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 17 })

    label(body, "Select how you want to use Yuno Player today",
        UDim2.new(1, 0, 0, 18), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            TextSize = 12,
            Position = UDim2.new(0, 0, 0, 28),
        })

    -- Mode cards
    local function modeCard(parent, icon, title, desc, col, pos)
        local card = new("Frame", {
            Size             = UDim2.new(0, 238, 0, 130),
            Position         = pos,
            BackgroundColor3 = CONFIG.BG_CARD,
            BorderSizePixel  = 0,
        }, parent)
        corner(card, CONFIG.CORNER_MD)
        stroke(card, CONFIG.BG_SURFACE, 1, 0)
        padding(card, 16, 16, 16, 16)

        local topRow = new("Frame", {
            Size                   = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
        }, card)

        local iconFrame = new("Frame", {
            Size             = UDim2.new(0, 32, 0, 32),
            BackgroundColor3 = col,
            BorderSizePixel  = 0,
        }, topRow)
        corner(iconFrame, UDim.new(0, 8))
        imageLabel(iconFrame, icon, UDim2.new(0.65, 0, 0.65, 0), UDim2.new(0.175, 0, 0.175, 0))

        label(topRow, title, UDim2.new(1, -44, 0, 32),
            CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
                Position  = UDim2.new(0, 44, 0, 0),
                TextSize  = 14,
            })

        label(card, desc, UDim2.new(1, 0, 0, 0),
            CONFIG.TEXT_SECONDARY, Enum.Font.Gotham, {
                Position      = UDim2.new(0, 0, 0, 48),
                TextSize      = 12,
                TextWrapped   = true,
                AutomaticSize = Enum.AutomaticSize.Y,
            })

        -- hover / click highlight
        local clickBtn = new("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 5,
        }, card)
        corner(clickBtn, CONFIG.CORNER_MD)

        clickBtn.MouseEnter:Connect(function()
            tweenPlay(card, TI.fast, { BackgroundColor3 = CONFIG.BG_SURFACE })
            tweenPlay(card:FindFirstChildWhichIsA("UIStroke"), TI.fast, { Color = col, Transparency = 0 })
        end)
        clickBtn.MouseLeave:Connect(function()
            tweenPlay(card, TI.fast, { BackgroundColor3 = CONFIG.BG_CARD })
            tweenPlay(card:FindFirstChildWhichIsA("UIStroke"), TI.fast, { Color = CONFIG.BG_SURFACE, Transparency = 0 })
        end)

        return clickBtn
    end

    local musicCard = modeCard(body, ICONS.MUSIC_NOTE, "Music Player",
        "Spotify-style interface for YouTube Music", CONFIG.ACCENT_GREEN,
        UDim2.new(0, 0, 0, 60))

    local videoCard = modeCard(body, ICONS.VIDEO_ICO, "Video Player",
        "YouTube-style interface for watching videos", CONFIG.ACCENT_RED,
        UDim2.new(0, 250, 0, 60))

    local utilCard = modeCard(body, ICONS.GLOBE, "Utility Tools",
        "IP info, server tools, player utilities", Color3.fromRGB(80, 120, 220),
        UDim2.new(0, 0, 0, 205))

    local configCard = modeCard(body, ICONS.SETTINGS, "Settings",
        "Configure Yuno Player behavior and UI", Color3.fromRGB(150, 100, 220),
        UDim2.new(0, 250, 0, 205))

    -- Entrance animation
    win.Size = UDim2.new(0, 0, 0, 0)
    win.BackgroundTransparency = 1
    tweenPlay(win, TI.bounce, {
        Size                   = UDim2.new(0, 560, 0, 400),
        BackgroundTransparency = 0,
    })

    musicCard.MouseButton1Click:Connect(function() onSelect("music") end)
    videoCard.MouseButton1Click:Connect(function() onSelect("video") end)
    utilCard.MouseButton1Click:Connect(function() onSelect("utility") end)
    configCard.MouseButton1Click:Connect(function() onSelect("config") end)
end

-- ============================================================
--  SPOTIFY-STYLE MUSIC UI
-- ============================================================
local function buildSpotifyUI(onBack)
    local existing = CoreGui:FindFirstChild("YunoHub")
    if existing then existing:Destroy() end

    local sg = new("ScreenGui", {
        Name            = "YunoHub",
        IgnoreGuiInset  = true,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)
    hubGui = sg

    -- Main window 680 x 480
    local win = new("Frame", {
        Size             = UDim2.new(0, 700, 0, 500),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, sg)
    corner(win, CONFIG.CORNER_LG)
    makeDraggable(win, win)

    -- LEFT SIDEBAR  (Spotify dark sidebar)
    local sidebar = new("Frame", {
        Size             = UDim2.new(0, 200, 1, 0),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, win)
    padding(sidebar, 16, 16, 12, 12)

    local sideList = new("Frame", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        AutomaticSize          = Enum.AutomaticSize.Y,
    }, sidebar)
    listLayout(sideList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 2)

    -- Logo row
    local logoRow = new("Frame", {
        Size                   = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        LayoutOrder            = 1,
    }, sideList)
    imageLabel(logoRow, ICONS.LOGO, UDim2.new(0, 30, 0, 30), UDim2.new(0, 0, 0.5, -15))
    label(logoRow, "Yuno Player", UDim2.new(1, -40, 0, 30),
        CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
            Position  = UDim2.new(0, 40, 0.5, -15),
            TextSize  = 14,
        })

    -- Divider
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        BorderSizePixel  = 0,
        LayoutOrder      = 2,
    }, sideList)

    local sideNavItems = {
        { icon = ICONS.MUSIC_NOTE,  label = "Music",      id = "music"    },
        { icon = ICONS.HEART,       label = "Favorites",  id = "favs"     },
        { icon = ICONS.STAR,        label = "Playlist",   id = "playlist" },
        { icon = ICONS.SEARCH,      label = "Search",     id = "search"   },
        { icon = ICONS.SETTINGS,    label = "Settings",   id = "settings" },
    }

    local sideSelected = "music"
    local sideButtons  = {}

    local function sideNavItem(parent, data, order)
        local row = new("TextButton", {
            Size             = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = data.id == sideSelected and CONFIG.BG_SURFACE or Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = data.id == sideSelected and 0 or 1,
            Text             = "",
            BorderSizePixel  = 0,
            AutoButtonColor  = false,
            LayoutOrder      = order,
        }, parent)
        corner(row, UDim.new(0, 6))
        imageLabel(row, data.icon, UDim2.new(0, 18, 0, 18), UDim2.new(0, 8, 0.5, -9),
            { ImageColor3 = data.id == sideSelected and CONFIG.ACCENT_GREEN or CONFIG.TEXT_MUTED })
        label(row, data.label, UDim2.new(1, -36, 1, 0),
            data.id == sideSelected and CONFIG.TEXT_PRIMARY or CONFIG.TEXT_MUTED,
            Enum.Font.Gotham, { Position = UDim2.new(0, 36, 0, 0), TextSize = 13 })

        sideButtons[data.id] = { btn = row }

        row.MouseEnter:Connect(function()
            if sideSelected ~= data.id then
                tweenPlay(row, TI.fast, { BackgroundTransparency = 0.8 })
            end
        end)
        row.MouseLeave:Connect(function()
            if sideSelected ~= data.id then
                tweenPlay(row, TI.fast, { BackgroundTransparency = 1 })
            end
        end)
        return row
    end

    for i, item in ipairs(sideNavItems) do
        sideNavItem(sideList, item, i + 2)
    end

    -- Back to hub
    local backBtn = new("TextButton", {
        Size             = UDim2.new(1, 0, 0, 34),
        Position         = UDim2.new(0, 0, 1, -50),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Text             = "< Back to Hub",
        TextColor3       = CONFIG.TEXT_MUTED,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Left,
        AutoButtonColor  = false,
    }, sidebar)
    backBtn.MouseButton1Click:Connect(function()
        sg:Destroy()
        onBack()
    end)

    -- MAIN CONTENT AREA
    local mainArea = new("Frame", {
        Size             = UDim2.new(1, -200, 1, -80),
        Position         = UDim2.new(0, 200, 0, 0),
        BackgroundColor3 = CONFIG.BG_MID,
        BorderSizePixel  = 0,
    }, win)

    -- Top search bar
    local searchBar = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = CONFIG.BG_MID,
        BorderSizePixel  = 0,
    }, mainArea)
    padding(searchBar, 10, 10, 14, 14)

    local searchBox = new("Frame", {
        Size             = UDim2.new(1, -40, 0, 32),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        BorderSizePixel  = 0,
    }, searchBar)
    corner(searchBox, CONFIG.CORNER_FULL)
    imageLabel(searchBox, ICONS.SEARCH, UDim2.new(0, 16, 0, 16), UDim2.new(0, 8, 0.5, -8),
        { ImageColor3 = CONFIG.TEXT_MUTED })

    local searchInput = new("TextBox", {
        Size             = UDim2.new(1, -40, 1, 0),
        Position         = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        Text             = "",
        PlaceholderText  = "Search songs, artists, playlists...",
        TextColor3       = CONFIG.TEXT_PRIMARY,
        PlaceholderColor3 = CONFIG.TEXT_MUTED,
        Font             = Enum.Font.Gotham,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, searchBox)

    -- Scrollable song list
    local songScroll = new("ScrollingFrame", {
        Size             = UDim2.new(1, 0, 1, -52),
        Position         = UDim2.new(0, 0, 0, 52),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CONFIG.TEXT_MUTED,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, mainArea)
    padding(songScroll, 0, 0, 14, 14)
    local songList = new("Frame", {
        Size                   = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize          = Enum.AutomaticSize.Y,
    }, songScroll)
    listLayout(songList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 2)

    -- Populate placeholder song rows
    local function addSongRow(parent, idx, title, artist, duration, order)
        local row = new("Frame", {
            Size             = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
        }, parent)
        corner(row, UDim.new(0, 4))

        -- Index number
        label(row, tostring(idx), UDim2.new(0, 20, 1, 0),
            CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
                Position        = UDim2.new(0, 0, 0, 0),
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Center,
            })

        -- Thumbnail placeholder (drawn as colored square)
        local thumb = new("Frame", {
            Size             = UDim2.new(0, 36, 0, 36),
            Position         = UDim2.new(0, 28, 0.5, -18),
            BackgroundColor3 = CONFIG.BG_SURFACE,
            BorderSizePixel  = 0,
        }, row)
        corner(thumb, UDim.new(0, 4))
        imageLabel(thumb, ICONS.MUSIC_NOTE, UDim2.new(0.6, 0, 0.6, 0),
            UDim2.new(0.2, 0, 0.2, 0), { ImageColor3 = CONFIG.TEXT_MUTED })

        -- Title + artist
        local textBlock = new("Frame", {
            Size                   = UDim2.new(1, -140, 0, 36),
            Position               = UDim2.new(0, 72, 0.5, -18),
            BackgroundTransparency = 1,
        }, row)
        label(textBlock, title, UDim2.new(1, 0, 0, 20),
            CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 13 })
        label(textBlock, artist, UDim2.new(1, 0, 0, 16),
            CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
                Position = UDim2.new(0, 0, 0, 20),
                TextSize = 11,
            })

        -- Duration
        label(row, duration, UDim2.new(0, 40, 1, 0),
            CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
                Position        = UDim2.new(1, -50, 0, 0),
                TextSize        = 12,
                TextXAlignment  = Enum.TextXAlignment.Center,
            })

        -- Heart button
        local heartBtn = iconBtn(row, ICONS.HEART, UDim2.new(0, 22, 0, 22), nil,
            { Position = UDim2.new(1, -26, 0.5, -11), ImageColor3 = CONFIG.TEXT_MUTED })

        -- Row hover
        local rowBtn = new("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 5,
        }, row)
        rowBtn.MouseEnter:Connect(function()
            tweenPlay(row, TI.fast, { BackgroundTransparency = 0.85, BackgroundColor3 = CONFIG.BG_SURFACE })
        end)
        rowBtn.MouseLeave:Connect(function()
            tweenPlay(row, TI.fast, { BackgroundTransparency = 1 })
        end)

        return row, rowBtn
    end

    -- Demo rows (replaced by actual search results when YMP loads)
    local demoSongs = {
        { "Use the search bar to find songs", "Enter a YouTube link or title", "0:00" },
        { "Open search in the sidebar", "Then type a query above", "0:00" },
        { "Your playlist will appear here", "Add songs via the + button", "0:00" },
    }
    for i, s in ipairs(demoSongs) do
        addSongRow(songList, i, s[1], s[2], s[3], i)
    end

    -- BOTTOM PLAYER BAR  (Spotify-style)
    local playerBar = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 80),
        Position         = UDim2.new(0, 0, 1, -80),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, win)
    -- top separator line
    new("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        BorderSizePixel  = 0,
    }, playerBar)

    -- Track info (left third)
    local trackInfo = new("Frame", {
        Size                   = UDim2.new(0.3, 0, 1, 0),
        BackgroundTransparency = 1,
    }, playerBar)
    padding(trackInfo, 10, 10, 12, 0)

    local albumArt = new("Frame", {
        Size             = UDim2.new(0, 48, 0, 48),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        BorderSizePixel  = 0,
    }, trackInfo)
    corner(albumArt, UDim.new(0, 4))
    imageLabel(albumArt, ICONS.MUSIC_NOTE, UDim2.new(0.6, 0, 0.6, 0),
        UDim2.new(0.2, 0, 0.2, 0), { ImageColor3 = CONFIG.TEXT_MUTED })

    local trackMeta = new("Frame", {
        Size                   = UDim2.new(1, -60, 0, 48),
        Position               = UDim2.new(0, 56, 0.5, -24),
        BackgroundTransparency = 1,
    }, trackInfo)
    label(trackMeta, "Nothing playing", UDim2.new(1, 0, 0, 24),
        CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd })
    label(trackMeta, "Select a song", UDim2.new(1, 0, 0, 18),
        CONFIG.TEXT_MUTED, Enum.Font.Gotham, { Position = UDim2.new(0, 0, 0, 24), TextSize = 11 })

    -- Controls (center third)
    local controls = new("Frame", {
        Size                   = UDim2.new(0.4, 0, 1, 0),
        Position               = UDim2.new(0.3, 0, 0, 0),
        BackgroundTransparency = 1,
    }, playerBar)

    -- Progress bar row
    local progRow = new("Frame", {
        Size                   = UDim2.new(0.85, 0, 0, 4),
        Position               = UDim2.new(0.075, 0, 0, 56),
        BackgroundColor3       = CONFIG.BG_SURFACE,
        BorderSizePixel        = 0,
    }, controls)
    corner(progRow, CONFIG.CORNER_FULL)
    local progFill = new("Frame", {
        Size             = UDim2.new(0.3, 0, 1, 0),
        BackgroundColor3 = CONFIG.ACCENT_GREEN,
        BorderSizePixel  = 0,
    }, progRow)
    corner(progFill, CONFIG.CORNER_FULL)
    local progDot = new("Frame", {
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(0.3, -6, 0.5, -6),
        BackgroundColor3 = CONFIG.TEXT_PRIMARY,
        BorderSizePixel  = 0,
    }, progRow)
    corner(progDot, CONFIG.CORNER_FULL)

    label(controls, "0:00", UDim2.new(0, 30, 0, 14),
        CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position  = UDim2.new(0, 0, 0, 52),
            TextSize  = 10,
            TextXAlignment = Enum.TextXAlignment.Center,
        })
    label(controls, "0:00", UDim2.new(0, 30, 0, 14),
        CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position  = UDim2.new(1, -30, 0, 52),
            TextSize  = 10,
            TextXAlignment = Enum.TextXAlignment.Center,
        })

    -- Control buttons row
    local btnRow = new("Frame", {
        Size                   = UDim2.new(1, 0, 0, 36),
        Position               = UDim2.new(0, 0, 0, 10),
        BackgroundTransparency = 1,
    }, controls)

    local shuffleBtn = iconBtn(btnRow, ICONS.SHUFFLE, UDim2.new(0, 26, 0, 26), nil,
        { Position = UDim2.new(0, 6, 0.5, -13), ImageColor3 = CONFIG.TEXT_MUTED })
    local prevBtn = iconBtn(btnRow, ICONS.SKIP_PREV, UDim2.new(0, 30, 0, 30), nil,
        { Position = UDim2.new(0, 44, 0.5, -15), ImageColor3 = CONFIG.TEXT_PRIMARY })
    local playBtnFrame = new("Frame", {
        Size             = UDim2.new(0, 34, 0, 34),
        Position         = UDim2.new(0.5, -17, 0.5, -17),
        BackgroundColor3 = CONFIG.TEXT_PRIMARY,
        BorderSizePixel  = 0,
    }, btnRow)
    corner(playBtnFrame, CONFIG.CORNER_FULL)
    local playBtnIcon = imageLabel(playBtnFrame, ICONS.PLAY,
        UDim2.new(0.6, 0, 0.6, 0), UDim2.new(0.2, 0, 0.2, 0),
        { ImageColor3 = CONFIG.BG_DARK })
    local playClickable = new("TextButton", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        ZIndex                 = 5,
    }, playBtnFrame)
    local nextBtn = iconBtn(btnRow, ICONS.SKIP_NEXT, UDim2.new(0, 30, 0, 30), nil,
        { Position = UDim2.new(1, -74, 0.5, -15), ImageColor3 = CONFIG.TEXT_PRIMARY })
    local repeatBtn = iconBtn(btnRow, ICONS.REPEAT_ICO, UDim2.new(0, 26, 0, 26), nil,
        { Position = UDim2.new(1, -32, 0.5, -13), ImageColor3 = CONFIG.TEXT_MUTED })

    -- Volume (right third)
    local volArea = new("Frame", {
        Size                   = UDim2.new(0.3, 0, 1, 0),
        Position               = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1,
    }, playerBar)
    padding(volArea, 0, 0, 0, 16)
    imageLabel(volArea, ICONS.VOLUME, UDim2.new(0, 18, 0, 18),
        UDim2.new(1, -80, 0.5, -9), { ImageColor3 = CONFIG.TEXT_MUTED })
    local volBarBg = new("Frame", {
        Size             = UDim2.new(0, 60, 0, 4),
        Position         = UDim2.new(1, -62, 0.5, -2),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        BorderSizePixel  = 0,
    }, volArea)
    corner(volBarBg, CONFIG.CORNER_FULL)
    local volFill = new("Frame", {
        Size             = UDim2.new(0.7, 0, 1, 0),
        BackgroundColor3 = CONFIG.TEXT_PRIMARY,
        BorderSizePixel  = 0,
    }, volBarBg)
    corner(volFill, CONFIG.CORNER_FULL)

    -- Entrance
    win.Size = UDim2.new(0, 0, 0, 0)
    tweenPlay(win, TI.bounce, { Size = UDim2.new(0, 700, 0, 500) })

    -- Now launch YMP in background
    task.spawn(function()
        task.wait(0.5)
        pcall(function()
            loadstring(game:HttpGet(CONFIG.YMP_SCRIPT_URL, true))()
        end)
        notify("Music Player", "YouTube Music Player loaded in background. Use the YMP window to search and play.", 5, false)
    end)
end

-- ============================================================
--  YOUTUBE-STYLE VIDEO UI
-- ============================================================
local function buildYouTubeUI(onBack)
    local existing = CoreGui:FindFirstChild("YunoHub")
    if existing then existing:Destroy() end

    local sg = new("ScreenGui", {
        Name            = "YunoHub",
        IgnoreGuiInset  = true,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)
    hubGui = sg

    local win = new("Frame", {
        Size             = UDim2.new(0, 740, 0, 520),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CONFIG.BG_MID,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, sg)
    corner(win, CONFIG.CORNER_LG)
    makeDraggable(win, win)

    -- TOPBAR (YouTube-style, dark with red accent)
    local topbar = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, win)
    -- Flatten bottom corners
    new("Frame", {
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, topbar)

    -- Logo area
    local logoGroup = new("Frame", {
        Size                   = UDim2.new(0, 120, 1, 0),
        BackgroundTransparency = 1,
    }, topbar)
    padding(logoGroup, 0, 0, 12, 0)
    imageLabel(logoGroup, ICONS.YOUTUBE, UDim2.new(0, 26, 0, 26), UDim2.new(0, 0, 0.5, -13),
        { ImageColor3 = CONFIG.ACCENT_RED })
    label(logoGroup, "Yuno", UDim2.new(0, 50, 1, 0),
        CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
            Position  = UDim2.new(0, 34, 0, 0),
            TextSize  = 15,
        })

    -- Search bar (center)
    local searchWrap = new("Frame", {
        Size             = UDim2.new(0, 360, 0, 34),
        Position         = UDim2.new(0.5, -180, 0.5, -17),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        BorderSizePixel  = 0,
    }, topbar)
    corner(searchWrap, CONFIG.CORNER_FULL)
    stroke(searchWrap, CONFIG.BG_CARD, 1, 0)

    local ytSearchInput = new("TextBox", {
        Size             = UDim2.new(1, -40, 1, 0),
        Position         = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text             = "",
        PlaceholderText  = "Search YouTube...",
        TextColor3       = CONFIG.TEXT_PRIMARY,
        PlaceholderColor3 = CONFIG.TEXT_MUTED,
        Font             = Enum.Font.Gotham,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, searchWrap)

    local searchSubmit = iconBtn(searchWrap, ICONS.SEARCH, UDim2.new(0, 30, 0, 30), nil,
        { Position = UDim2.new(1, -34, 0.5, -15), ImageColor3 = CONFIG.TEXT_MUTED })

    -- Right controls
    local rightCtrl = new("Frame", {
        Size                   = UDim2.new(0, 80, 1, 0),
        Position               = UDim2.new(1, -90, 0, 0),
        BackgroundTransparency = 1,
    }, topbar)
    local closeBtn2 = iconBtn(rightCtrl, ICONS.CLOSE_X, UDim2.new(0, 26, 0, 26), nil,
        { Position = UDim2.new(1, -34, 0.5, -13), ImageColor3 = CONFIG.TEXT_MUTED })
    closeBtn2.MouseButton1Click:Connect(function()
        tweenPlay(win, TI.mid, { Size = UDim2.new(0, 0, 0, 0) })
        task.wait(0.3)
        sg:Destroy()
        onBack()
    end)

    -- BODY: left video pane + right sidebar
    local body = new("Frame", {
        Size             = UDim2.new(1, 0, 1, -52),
        Position         = UDim2.new(0, 0, 0, 52),
        BackgroundTransparency = 1,
    }, win)

    -- Video pane (left 480px)
    local videoPane = new("Frame", {
        Size             = UDim2.new(0, 480, 1, 0),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, body)
    padding(videoPane, 12, 12, 12, 12)

    -- Video placeholder
    local videoPlaceholder = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 264),
        BackgroundColor3 = Color3.fromRGB(8, 8, 8),
        BorderSizePixel  = 0,
    }, videoPane)
    corner(videoPlaceholder, CONFIG.CORNER_MD)

    imageLabel(videoPlaceholder, ICONS.VIDEO_ICO, UDim2.new(0, 54, 0, 54),
        UDim2.new(0.5, -27, 0.5, -40), { ImageColor3 = CONFIG.BG_SURFACE })
    label(videoPlaceholder, "Video plays here",
        UDim2.new(1, 0, 0, 24), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position        = UDim2.new(0, 0, 0.5, 20),
            TextSize        = 13,
            TextXAlignment  = Enum.TextXAlignment.Center,
        })

    -- Video controls bar
    local vctrlBar = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 42),
        Position         = UDim2.new(0, 0, 0, 280),
        BackgroundColor3 = CONFIG.BG_CARD,
        BorderSizePixel  = 0,
    }, videoPane)
    corner(vctrlBar, CONFIG.CORNER_MD)
    padding(vctrlBar, 0, 0, 10, 10)

    -- Progress bar
    local vProgBg = new("Frame", {
        Size             = UDim2.new(1, -120, 0, 4),
        Position         = UDim2.new(0, 0, 0.5, -2),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        BorderSizePixel  = 0,
    }, vctrlBar)
    corner(vProgBg, CONFIG.CORNER_FULL)
    local vProgFill = new("Frame", {
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = CONFIG.ACCENT_RED,
        BorderSizePixel  = 0,
    }, vProgBg)
    corner(vProgFill, CONFIG.CORNER_FULL)

    label(vctrlBar, "0:00", UDim2.new(0, 40, 1, 0),
        CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position  = UDim2.new(1, -85, 0, 0),
            TextSize  = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
        })
    label(vctrlBar, "/  0:00", UDim2.new(0, 50, 1, 0),
        CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position  = UDim2.new(1, -46, 0, 0),
            TextSize  = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
        })

    local vPlayBtn = iconBtn(vctrlBar, ICONS.PLAY, UDim2.new(0, 28, 0, 28), nil,
        { Position = UDim2.new(0, -8, 0.5, -14), ImageColor3 = CONFIG.TEXT_PRIMARY })

    -- Video meta
    label(videoPane, "Select a video from the list",
        UDim2.new(1, 0, 0, 22), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
            Position = UDim2.new(0, 0, 0, 330),
            TextSize = 14,
        })
    label(videoPane, "Paste a YouTube URL in the search bar or pick a result",
        UDim2.new(1, 0, 0, 18), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position = UDim2.new(0, 0, 0, 354),
            TextSize = 12,
            TextWrapped = true,
        })

    -- Tab bar for video info
    local tabBar = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 34),
        Position         = UDim2.new(0, 0, 0, 382),
        BackgroundTransparency = 1,
    }, videoPane)
    local tabNames = { "Description", "Comments", "Related" }
    local selectedTab = 1
    for i, name in ipairs(tabNames) do
        local t = new("TextButton", {
            Size             = UDim2.new(0, 100, 1, 0),
            Position         = UDim2.new(0, (i-1)*106, 0, 0),
            BackgroundColor3 = i == 1 and CONFIG.ACCENT_RED or Color3.fromRGB(0,0,0),
            BackgroundTransparency = i == 1 and 0 or 1,
            Text             = name,
            TextColor3       = i == 1 and CONFIG.TEXT_PRIMARY or CONFIG.TEXT_MUTED,
            Font             = Enum.Font.GothamBold,
            TextSize         = 12,
            AutoButtonColor  = false,
            BorderSizePixel  = 0,
        }, tabBar)
        corner(t, UDim.new(0, 6))
        t.MouseButton1Click:Connect(function()
            selectedTab = i
        end)
    end

    -- RIGHT SIDEBAR (results/queue)
    local sidebar2 = new("Frame", {
        Size             = UDim2.new(1, -480, 1, 0),
        Position         = UDim2.new(0, 480, 0, 0),
        BackgroundColor3 = CONFIG.BG_MID,
        BorderSizePixel  = 0,
    }, body)
    padding(sidebar2, 8, 8, 8, 8)

    label(sidebar2, "Up Next",
        UDim2.new(1, 0, 0, 22), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 13 })

    local queueScroll = new("ScrollingFrame", {
        Size             = UDim2.new(1, 0, 1, -30),
        Position         = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CONFIG.TEXT_MUTED,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, sidebar2)

    local queueList = new("Frame", {
        Size                   = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize          = Enum.AutomaticSize.Y,
    }, queueScroll)
    listLayout(queueList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 4)

    -- Placeholder queue items
    for i = 1, 5 do
        local item = new("Frame", {
            Size             = UDim2.new(1, 0, 0, 64),
            BackgroundColor3 = COLOR or CONFIG.BG_CARD,
            BorderSizePixel  = 0,
            LayoutOrder      = i,
        }, queueList)
        corner(item, UDim.new(0, 4))
        local thumb = new("Frame", {
            Size             = UDim2.new(0, 90, 0, 52),
            Position         = UDim2.new(0, 4, 0.5, -26),
            BackgroundColor3 = CONFIG.BG_SURFACE,
            BorderSizePixel  = 0,
        }, item)
        corner(thumb, UDim.new(0, 4))
        imageLabel(thumb, ICONS.VIDEO_ICO, UDim2.new(0.5, 0, 0.5, 0),
            UDim2.new(0.25, 0, 0.25, 0), { ImageColor3 = CONFIG.TEXT_MUTED })

        local meta = new("Frame", {
            Size                   = UDim2.new(1, -104, 0, 52),
            Position               = UDim2.new(0, 100, 0.5, -26),
            BackgroundTransparency = 1,
        }, item)
        label(meta, "Video " .. i, UDim2.new(1, 0, 0, 20),
            CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
                TextSize        = 12,
                TextTruncate    = Enum.TextTruncate.AtEnd,
            })
        label(meta, "Search to populate queue", UDim2.new(1, 0, 0, 16),
            CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
                Position  = UDim2.new(0, 0, 0, 20),
                TextSize  = 10,
            })
    end

    -- Entrance
    win.Size = UDim2.new(0, 0, 0, 0)
    tweenPlay(win, TI.bounce, { Size = UDim2.new(0, 740, 0, 520) })

    -- Load YMP in background
    task.spawn(function()
        task.wait(0.5)
        pcall(function()
            loadstring(game:HttpGet(CONFIG.YMP_SCRIPT_URL, true))()
        end)
        notify("Video Player", "YouTube Music Player loaded. Use the YMP video tab to play content.", 5, false)
    end)
end

-- ============================================================
--  UTILITY UI  (IP lookup, server info, player tools)
-- ============================================================
local function buildUtilityUI(onBack)
    local existing = CoreGui:FindFirstChild("YunoHub")
    if existing then existing:Destroy() end

    local sg = new("ScreenGui", {
        Name            = "YunoHub",
        IgnoreGuiInset  = true,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)
    hubGui = sg

    local win = new("Frame", {
        Size             = UDim2.new(0, 680, 0, 500),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CONFIG.BG_MID,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, sg)
    corner(win, CONFIG.CORNER_LG)
    makeDraggable(win, win)

    -- Titlebar
    local tb = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, win)
    new("Frame", {
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, tb)
    imageLabel(tb, ICONS.GLOBE, UDim2.new(0, 22, 0, 22), UDim2.new(0, 12, 0.5, -11),
        { ImageColor3 = Color3.fromRGB(80, 120, 220) })
    label(tb, "Utility Tools", UDim2.new(0, 160, 1, 0),
        CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
            Position  = UDim2.new(0, 42, 0, 0),
            TextSize  = 15,
        })
    local closeBtn3 = iconBtn(tb, ICONS.CLOSE_X, UDim2.new(0, 26, 0, 26), nil,
        { Position = UDim2.new(1, -36, 0.5, -13), ImageColor3 = CONFIG.TEXT_MUTED })
    closeBtn3.MouseButton1Click:Connect(function()
        sg:Destroy()
        onBack()
    end)

    -- Tab bar
    local tabs = { "IP Lookup", "Server Info", "Players", "Clipboard" }
    local tabFrames = {}
    local selectedUtilTab = 1

    local tabBar2 = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 38),
        Position         = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, win)
    padding(tabBar2, 0, 0, 12, 12)

    local tabContent = new("Frame", {
        Size             = UDim2.new(1, 0, 1, -86),
        Position         = UDim2.new(0, 0, 0, 86),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, win)

    local function switchUtilTab(idx)
        selectedUtilTab = idx
        for i, f in ipairs(tabFrames) do
            f.Visible = (i == idx)
        end
    end

    for i, name in ipairs(tabs) do
        local isActive = (i == 1)
        local tabBtn = new("TextButton", {
            Size             = UDim2.new(0, 110, 1, -6),
            Position         = UDim2.new(0, (i-1)*116, 0, 3),
            BackgroundColor3 = isActive and Color3.fromRGB(80, 120, 220) or CONFIG.BG_SURFACE,
            Text             = name,
            TextColor3       = isActive and CONFIG.TEXT_PRIMARY or CONFIG.TEXT_MUTED,
            Font             = Enum.Font.GothamBold,
            TextSize         = 12,
            AutoButtonColor  = false,
            BorderSizePixel  = 0,
        }, tabBar2)
        corner(tabBtn, UDim.new(0, 6))
        tabBtn.MouseButton1Click:Connect(function()
            -- Reset all
            for _, child in ipairs(tabBar2:GetChildren()) do
                if child:IsA("TextButton") then
                    tweenPlay(child, TI.fast, {
                        BackgroundColor3 = CONFIG.BG_SURFACE,
                        TextColor3       = CONFIG.TEXT_MUTED,
                    })
                end
            end
            tweenPlay(tabBtn, TI.fast, {
                BackgroundColor3 = Color3.fromRGB(80, 120, 220),
                TextColor3       = CONFIG.TEXT_PRIMARY,
            })
            switchUtilTab(i)
        end)
    end

    -- Helper: info card
    local function infoCard(parent, ico, title, value, order)
        local card = new("Frame", {
            Size             = UDim2.new(1, -24, 0, 56),
            BackgroundColor3 = CONFIG.BG_CARD,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
        }, parent)
        corner(card, CONFIG.CORNER_MD)
        padding(card, 0, 0, 12, 12)

        local iconBox = new("Frame", {
            Size             = UDim2.new(0, 36, 0, 36),
            Position         = UDim2.new(0, 0, 0.5, -18),
            BackgroundColor3 = CONFIG.BG_SURFACE,
            BorderSizePixel  = 0,
        }, card)
        corner(iconBox, UDim.new(0, 8))
        imageLabel(iconBox, ico, UDim2.new(0.6, 0, 0.6, 0), UDim2.new(0.2, 0, 0.2, 0),
            { ImageColor3 = Color3.fromRGB(80, 120, 220) })

        local textArea = new("Frame", {
            Size                   = UDim2.new(1, -56, 0, 36),
            Position               = UDim2.new(0, 48, 0.5, -18),
            BackgroundTransparency = 1,
        }, card)
        label(textArea, title, UDim2.new(1, 0, 0, 16),
            CONFIG.TEXT_MUTED, Enum.Font.Gotham, { TextSize = 11 })
        local valLabel = label(textArea, value, UDim2.new(1, 0, 0, 18),
            CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
                Position  = UDim2.new(0, 0, 0, 16),
                TextSize  = 13,
            })

        -- Copy button
        local cpyBtn = new("TextButton", {
            Size             = UDim2.new(0, 60, 0, 26),
            Position         = UDim2.new(1, -62, 0.5, -13),
            BackgroundColor3 = CONFIG.BG_SURFACE,
            Text             = "Copy",
            TextColor3       = CONFIG.TEXT_SECONDARY,
            Font             = Enum.Font.Gotham,
            TextSize         = 11,
            AutoButtonColor  = false,
            BorderSizePixel  = 0,
        }, card)
        corner(cpyBtn, UDim.new(0, 6))
        cpyBtn.MouseButton1Click:Connect(function()
            if setclipboard_ then
                pcall(setclipboard_, valLabel.Text)
                notify("Copied", valLabel.Text, 2)
            end
        end)

        return valLabel
    end

    -- ---- TAB 1: IP LOOKUP ----
    do
        local t = new("ScrollingFrame", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = CONFIG.TEXT_MUTED,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = true,
        }, tabContent)
        padding(t, 12, 12, 12, 12)
        local tList = new("Frame", {
            Size                   = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize          = Enum.AutomaticSize.Y,
        }, t)
        listLayout(tList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, 8)

        table.insert(tabFrames, t)

        label(tList, "Your Network Information",
            UDim2.new(1, -24, 0, 24), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
                TextSize    = 15,
                LayoutOrder = 0,
            })

        -- Placeholder labels updated after fetch
        local ipVal   = infoCard(tList, ICONS.WIFI,    "Public IP Address",  "Fetching...", 1)
        local ispVal  = infoCard(tList, ICONS.GLOBE,   "ISP / Organization",  "Fetching...", 2)
        local cityVal = infoCard(tList, ICONS.LOCATION, "City",               "Fetching...", 3)
        local regVal  = infoCard(tList, ICONS.LOCATION, "Region",             "Fetching...", 4)
        local cntVal  = infoCard(tList, ICONS.GLOBE,   "Country",            "Fetching...", 5)
        local tzVal   = infoCard(tList, ICONS.GLOBE,   "Timezone",           "Fetching...", 6)
        local latVal  = infoCard(tList, ICONS.LOCATION, "Latitude",           "Fetching...", 7)
        local lonVal  = infoCard(tList, ICONS.LOCATION, "Longitude",          "Fetching...", 8)

        local refreshBtn = btn(tList, "Refresh", UDim2.new(0, 120, 0, 36), nil,
            Color3.fromRGB(80, 120, 220), CONFIG.TEXT_PRIMARY, { LayoutOrder = 9 })

        local function fetchIP()
            ipVal.Text  = "Fetching..."
            ispVal.Text = "..."

            task.spawn(function()
                -- Public IP
                local ok, res = pcall(game.HttpGet, game, CONFIG.IP_API_URL)
                if ok and res then
                    local ok2, data = pcall(HttpService.JSONDecode, HttpService, res)
                    if ok2 and data and data.ip then
                        ipVal.Text = data.ip

                        -- Geo info
                        local ok3, geo = pcall(game.HttpGet, game, CONFIG.GEO_API_URL .. data.ip)
                        if ok3 and geo then
                            local ok4, gdata = pcall(HttpService.JSONDecode, HttpService, geo)
                            if ok4 and gdata then
                                ispVal.Text  = gdata.isp or gdata.org or "N/A"
                                cityVal.Text = gdata.city or "N/A"
                                regVal.Text  = gdata.regionName or "N/A"
                                cntVal.Text  = gdata.country or "N/A"
                                tzVal.Text   = gdata.timezone or "N/A"
                                latVal.Text  = tostring(gdata.lat or "N/A")
                                lonVal.Text  = tostring(gdata.lon or "N/A")
                            end
                        end
                    end
                else
                    ipVal.Text = "Failed to fetch"
                end
            end)
        end

        refreshBtn.MouseButton1Click:Connect(fetchIP)
        fetchIP()
    end

    -- ---- TAB 2: SERVER INFO ----
    do
        local t = new("ScrollingFrame", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = CONFIG.TEXT_MUTED,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = false,
        }, tabContent)
        padding(t, 12, 12, 12, 12)
        local tList = new("Frame", {
            Size                   = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize          = Enum.AutomaticSize.Y,
        }, t)
        listLayout(tList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, 8)
        table.insert(tabFrames, t)

        label(tList, "Server Information",
            UDim2.new(1, -24, 0, 24), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
                TextSize    = 15,
                LayoutOrder = 0,
            })

        infoCard(tList, ICONS.SERVER, "Game", game.Name, 1)
        infoCard(tList, ICONS.SERVER, "Game ID", tostring(game.GameId), 2)
        infoCard(tList, ICONS.SERVER, "Place ID", tostring(game.PlaceId), 3)
        infoCard(tList, ICONS.SERVER, "Place Version", tostring(game.PlaceVersion), 4)
        infoCard(tList, ICONS.SERVER, "Job ID", game.JobId or "N/A", 5)
        infoCard(tList, ICONS.USER,   "Player Count",
            tostring(#Players:GetPlayers()) .. " / " .. tostring(Players.MaxPlayers), 6)
        infoCard(tList, ICONS.USER,   "Your Username", LP.Name, 7)
        infoCard(tList, ICONS.USER,   "Your User ID", tostring(LP.UserId), 8)
        infoCard(tList, ICONS.USER,   "Your Display Name", LP.DisplayName, 9)
        infoCard(tList, ICONS.GLOBE,  "Locale", LP.LocaleId or "N/A", 10)
        infoCard(tList, ICONS.INFO,   "Account Age (days)", tostring(LP.AccountAge), 11)
        infoCard(tList, ICONS.INFO,   "HWID", tostring(gethwid_ or LP.UserId), 12)
    end

    -- ---- TAB 3: PLAYERS ----
    do
        local t = new("ScrollingFrame", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = CONFIG.TEXT_MUTED,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = false,
        }, tabContent)
        padding(t, 12, 12, 12, 12)
        local tList = new("Frame", {
            Size                   = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize          = Enum.AutomaticSize.Y,
        }, t)
        listLayout(tList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, 6)
        table.insert(tabFrames, t)

        label(tList, "Players in Server",
            UDim2.new(1, -24, 0, 24), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
                TextSize    = 15,
                LayoutOrder = 0,
            })

        local function buildPlayerList()
            -- Clear existing player rows
            for _, child in ipairs(tList:GetChildren()) do
                if child:IsA("Frame") or (child:IsA("TextButton") and child.Name == "prow") then
                    child:Destroy()
                end
            end

            local allPlayers = Players:GetPlayers()
            for idx, plr in ipairs(allPlayers) do
                local row = new("Frame", {
                    Size             = UDim2.new(1, -24, 0, 52),
                    BackgroundColor3 = CONFIG.BG_CARD,
                    BorderSizePixel  = 0,
                    LayoutOrder      = idx,
                }, tList)
                corner(row, CONFIG.CORNER_MD)
                padding(row, 0, 0, 10, 10)

                -- Avatar thumb placeholder
                local av = new("Frame", {
                    Size             = UDim2.new(0, 36, 0, 36),
                    Position         = UDim2.new(0, 0, 0.5, -18),
                    BackgroundColor3 = CONFIG.BG_SURFACE,
                    BorderSizePixel  = 0,
                }, row)
                corner(av, CONFIG.CORNER_FULL)
                imageLabel(av, ICONS.USER, UDim2.new(0.65, 0, 0.65, 0),
                    UDim2.new(0.175, 0, 0.175, 0), { ImageColor3 = CONFIG.TEXT_MUTED })

                local meta = new("Frame", {
                    Size                   = UDim2.new(1, -56, 0, 36),
                    Position               = UDim2.new(0, 48, 0.5, -18),
                    BackgroundTransparency = 1,
                }, row)
                label(meta, plr.DisplayName ~= plr.Name and
                    plr.DisplayName .. "  <font color='#888888'>" .. plr.Name .. "</font>" or plr.Name,
                    UDim2.new(1, 0, 0, 20), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
                        TextSize = 13, RichText = true
                    })
                label(meta, "ID: " .. tostring(plr.UserId) .. "  |  Age: " .. plr.AccountAge .. "d",
                    UDim2.new(1, 0, 0, 16), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
                        Position = UDim2.new(0, 0, 0, 20),
                        TextSize = 11,
                    })

                -- Copy ID btn
                local cpyIdBtn = new("TextButton", {
                    Size             = UDim2.new(0, 60, 0, 26),
                    Position         = UDim2.new(1, -62, 0.5, -13),
                    BackgroundColor3 = CONFIG.BG_SURFACE,
                    Text             = "Copy ID",
                    TextColor3       = CONFIG.TEXT_SECONDARY,
                    Font             = Enum.Font.Gotham,
                    TextSize         = 11,
                    AutoButtonColor  = false,
                    BorderSizePixel  = 0,
                }, row)
                corner(cpyIdBtn, UDim.new(0, 6))
                local capturedId = tostring(plr.UserId)
                cpyIdBtn.MouseButton1Click:Connect(function()
                    if setclipboard_ then
                        pcall(setclipboard_, capturedId)
                        notify("Copied", "User ID: " .. capturedId, 2)
                    end
                end)
            end
        end

        buildPlayerList()

        local refreshPBtn = btn(tList, "Refresh", UDim2.new(0, 110, 0, 34), nil,
            Color3.fromRGB(80, 120, 220), CONFIG.TEXT_PRIMARY,
            { LayoutOrder = 999 })
        refreshPBtn.MouseButton1Click:Connect(buildPlayerList)
    end

    -- ---- TAB 4: CLIPBOARD TOOLS ----
    do
        local t = new("ScrollingFrame", {
            Size             = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = CONFIG.TEXT_MUTED,
            CanvasSize       = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible          = false,
        }, tabContent)
        padding(t, 12, 12, 12, 12)
        local tList = new("Frame", {
            Size                   = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize          = Enum.AutomaticSize.Y,
        }, t)
        listLayout(tList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center, 8)
        table.insert(tabFrames, t)

        label(tList, "Quick Copy Utilities",
            UDim2.new(1, -24, 0, 24), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
                TextSize    = 15,
                LayoutOrder = 0,
            })

        local quickCopies = {
            { ICONS.USER,   "Your Username",        LP.Name },
            { ICONS.USER,   "Your User ID",         tostring(LP.UserId) },
            { ICONS.USER,   "Your Display Name",    LP.DisplayName },
            { ICONS.SERVER, "Game ID",              tostring(game.GameId) },
            { ICONS.SERVER, "Place ID",             tostring(game.PlaceId) },
            { ICONS.SERVER, "Job ID",               game.JobId or "N/A" },
            { ICONS.INFO,   "HWID",                 tostring(gethwid_ or LP.UserId) },
        }

        for i, entry in ipairs(quickCopies) do
            infoCard(tList, entry[1], entry[2], entry[3], i)
        end

        -- Custom text copy box
        local sep = new("Frame", {
            Size             = UDim2.new(1, -24, 0, 1),
            BackgroundColor3 = CONFIG.BG_SURFACE,
            BorderSizePixel  = 0,
            LayoutOrder      = 100,
        }, tList)

        label(tList, "Custom text to copy",
            UDim2.new(1, -24, 0, 20), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
                TextSize    = 12,
                LayoutOrder = 101,
            })

        local customBox = new("TextBox", {
            Size             = UDim2.new(1, -24, 0, 36),
            BackgroundColor3 = CONFIG.BG_CARD,
            Text             = "",
            PlaceholderText  = "Type anything here...",
            TextColor3       = CONFIG.TEXT_PRIMARY,
            PlaceholderColor3 = CONFIG.TEXT_MUTED,
            Font             = Enum.Font.Gotham,
            TextSize         = 13,
            TextXAlignment   = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            BorderSizePixel  = 0,
            LayoutOrder      = 102,
        }, tList)
        corner(customBox, CONFIG.CORNER_MD)
        padding(customBox, 0, 0, 10, 10)

        local copyCustomBtn = btn(tList, "Copy to Clipboard", UDim2.new(0, 160, 0, 34), nil,
            Color3.fromRGB(80, 120, 220), CONFIG.TEXT_PRIMARY, { LayoutOrder = 103 })
        copyCustomBtn.MouseButton1Click:Connect(function()
            if customBox.Text ~= "" and setclipboard_ then
                pcall(setclipboard_, customBox.Text)
                notify("Copied", customBox.Text:sub(1, 60), 2)
            end
        end)
    end

    -- Initial tab visibility
    for i, f in ipairs(tabFrames) do
        f.Visible = (i == 1)
    end

    -- Entrance
    win.Size = UDim2.new(0, 0, 0, 0)
    tweenPlay(win, TI.bounce, { Size = UDim2.new(0, 680, 0, 500) })
end

-- ============================================================
--  CONFIG / SETTINGS UI
-- ============================================================
local savedConfig = {
    defaultMode     = "selector",   -- "music" | "video" | "selector"
    showOnStart     = true,
    notifDuration   = 4,
    spotifyTheme    = true,
    autoLoadYMP     = true,
    keybind         = "RightBracket",
}

local function buildConfigUI(onBack)
    local existing = CoreGui:FindFirstChild("YunoHub")
    if existing then existing:Destroy() end

    local sg = new("ScreenGui", {
        Name            = "YunoHub",
        IgnoreGuiInset  = true,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)
    hubGui = sg

    local win = new("Frame", {
        Size             = UDim2.new(0, 520, 0, 480),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = CONFIG.BG_MID,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    }, sg)
    corner(win, CONFIG.CORNER_LG)
    makeDraggable(win, win)

    local tb = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, win)
    new("Frame", {
        Size             = UDim2.new(1, 0, 0.5, 0),
        Position         = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = CONFIG.BG_DARK,
        BorderSizePixel  = 0,
    }, tb)
    imageLabel(tb, ICONS.SETTINGS, UDim2.new(0, 22, 0, 22), UDim2.new(0, 12, 0.5, -11),
        { ImageColor3 = Color3.fromRGB(150, 100, 220) })
    label(tb, "Settings", UDim2.new(0, 160, 1, 0),
        CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, {
            Position  = UDim2.new(0, 42, 0, 0),
            TextSize  = 15,
        })
    local closeBtn4 = iconBtn(tb, ICONS.CLOSE_X, UDim2.new(0, 26, 0, 26), nil,
        { Position = UDim2.new(1, -36, 0.5, -13), ImageColor3 = CONFIG.TEXT_MUTED })
    closeBtn4.MouseButton1Click:Connect(function()
        sg:Destroy()
        onBack()
    end)

    local scroll = new("ScrollingFrame", {
        Size             = UDim2.new(1, 0, 1, -48),
        Position         = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CONFIG.TEXT_MUTED,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, win)
    padding(scroll, 14, 14, 16, 16)

    local sList = new("Frame", {
        Size                   = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize          = Enum.AutomaticSize.Y,
    }, scroll)
    listLayout(sList, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left, 10)

    -- Section header
    local function sectionHeader(parent, text, order)
        local f = new("Frame", {
            Size                   = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            LayoutOrder            = order,
        }, parent)
        label(f, text, UDim2.new(1, 0, 1, 0),
            Color3.fromRGB(150, 100, 220), Enum.Font.GothamBold, { TextSize = 12 })
        return f
    end

    -- Toggle row
    local function toggleRow(parent, title, desc, key, order)
        local row = new("Frame", {
            Size             = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = CONFIG.BG_CARD,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
        }, parent)
        corner(row, CONFIG.CORNER_MD)
        padding(row, 0, 0, 12, 12)

        local textArea = new("Frame", {
            Size                   = UDim2.new(1, -62, 0, 40),
            Position               = UDim2.new(0, 0, 0.5, -20),
            BackgroundTransparency = 1,
        }, row)
        label(textArea, title, UDim2.new(1, 0, 0, 22),
            CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 13 })
        label(textArea, desc, UDim2.new(1, 0, 0, 16),
            CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
                Position  = UDim2.new(0, 0, 0, 22),
                TextSize  = 11,
                TextWrapped = true,
            })

        -- Toggle pill
        local isOn = savedConfig[key] == true
        local pill = new("Frame", {
            Size             = UDim2.new(0, 44, 0, 24),
            Position         = UDim2.new(1, -44, 0.5, -12),
            BackgroundColor3 = isOn and Color3.fromRGB(150, 100, 220) or CONFIG.BG_SURFACE,
            BorderSizePixel  = 0,
        }, row)
        corner(pill, CONFIG.CORNER_FULL)

        local dot = new("Frame", {
            Size             = UDim2.new(0, 18, 0, 18),
            Position         = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = CONFIG.TEXT_PRIMARY,
            BorderSizePixel  = 0,
        }, pill)
        corner(dot, CONFIG.CORNER_FULL)

        local pillBtn = new("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 5,
        }, pill)
        pillBtn.MouseButton1Click:Connect(function()
            isOn = not isOn
            savedConfig[key] = isOn
            tweenPlay(pill, TI.fast, {
                BackgroundColor3 = isOn and Color3.fromRGB(150, 100, 220) or CONFIG.BG_SURFACE
            })
            tweenPlay(dot, TI.fast, {
                Position = isOn and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            })
        end)

        return row
    end

    -- Dropdown row
    local function dropdownRow(parent, title, desc, key, options, order)
        local row = new("Frame", {
            Size             = UDim2.new(1, 0, 0, 56),
            BackgroundColor3 = CONFIG.BG_CARD,
            BorderSizePixel  = 0,
            LayoutOrder      = order,
        }, parent)
        corner(row, CONFIG.CORNER_MD)
        padding(row, 0, 0, 12, 12)

        label(row, title, UDim2.new(1, -150, 0, 22),
            CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 13 })
        label(row, desc, UDim2.new(1, -150, 0, 16),
            CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
                Position  = UDim2.new(0, 0, 0, 22),
                TextSize  = 11,
            })

        local ddFrame = new("Frame", {
            Size             = UDim2.new(0, 130, 0, 32),
            Position         = UDim2.new(1, -132, 0.5, -16),
            BackgroundColor3 = CONFIG.BG_SURFACE,
            BorderSizePixel  = 0,
            ClipsDescendants = true,
        }, row)
        corner(ddFrame, UDim.new(0, 6))

        local currentIdx = 1
        for i, opt in ipairs(options) do
            if opt == savedConfig[key] then currentIdx = i break end
        end

        local ddLabel = label(ddFrame, options[currentIdx] or options[1],
            UDim2.new(1, -24, 1, 0), CONFIG.TEXT_PRIMARY, Enum.Font.Gotham, {
                TextSize = 12,
                Position = UDim2.new(0, 8, 0, 0),
            })

        imageLabel(ddFrame, ICONS.ARROW_DOWN, UDim2.new(0, 14, 0, 14),
            UDim2.new(1, -18, 0.5, -7), { ImageColor3 = CONFIG.TEXT_MUTED })

        local ddBtn = new("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            ZIndex                 = 5,
        }, ddFrame)
        ddBtn.MouseButton1Click:Connect(function()
            currentIdx = currentIdx % #options + 1
            ddLabel.Text = options[currentIdx]
            savedConfig[key] = options[currentIdx]
        end)
    end

    -- Build settings
    sectionHeader(sList, "STARTUP", 1)
    toggleRow(sList, "Show on start", "Open Yuno Player when script runs", "showOnStart", 2)
    dropdownRow(sList, "Default mode", "Which UI opens by default",
        "defaultMode", { "selector", "music", "video" }, 3)

    sectionHeader(sList, "INTERFACE", 10)
    toggleRow(sList, "Spotify theme for music", "Use green Spotify palette in music player", "spotifyTheme", 11)

    sectionHeader(sList, "BEHAVIOR", 20)
    toggleRow(sList, "Auto-load YMP", "Load YouTube Music Player in the background automatically", "autoLoadYMP", 21)
    dropdownRow(sList, "Notification duration", "How long notifications stay on screen",
        "notifDuration", { "2", "4", "6", "8" }, 22)

    sectionHeader(sList, "KEYBIND", 30)
    local kbRow = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = CONFIG.BG_CARD,
        BorderSizePixel  = 0,
        LayoutOrder      = 31,
    }, sList)
    corner(kbRow, CONFIG.CORNER_MD)
    padding(kbRow, 0, 0, 12, 12)
    label(kbRow, "Toggle keybind", UDim2.new(1, -160, 0, 22),
        CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 13 })
    label(kbRow, "Press to open/close Yuno Player", UDim2.new(1, -160, 0, 16),
        CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position  = UDim2.new(0, 0, 0, 22),
            TextSize  = 11,
        })
    local kbDisplay = new("TextButton", {
        Size             = UDim2.new(0, 130, 0, 30),
        Position         = UDim2.new(1, -132, 0.5, -15),
        BackgroundColor3 = CONFIG.BG_SURFACE,
        Text             = savedConfig.keybind,
        TextColor3       = COLOR3 or CONFIG.TEXT_PRIMARY,
        Font             = Enum.Font.GothamBold,
        TextSize         = 12,
        AutoButtonColor  = false,
        BorderSizePixel  = 0,
    }, kbRow)
    corner(kbDisplay, UDim.new(0, 6))
    local listening = false
    kbDisplay.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        kbDisplay.Text = "Press a key..."
        kbDisplay.TextColor3 = Color3.fromRGB(150, 100, 220)
        local conn
        conn = UserInput.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                local keyName = inp.KeyCode.Name
                savedConfig.keybind = keyName
                kbDisplay.Text = keyName
                kbDisplay.TextColor3 = CONFIG.TEXT_PRIMARY
                listening = false
                conn:Disconnect()
            end
        end)
    end)

    sectionHeader(sList, "ABOUT", 40)
    local aboutCard = new("Frame", {
        Size             = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = CONFIG.BG_CARD,
        BorderSizePixel  = 0,
        LayoutOrder      = 41,
    }, sList)
    corner(aboutCard, CONFIG.CORNER_MD)
    padding(aboutCard, 12, 12, 12, 12)
    label(aboutCard, "Yuno Player  v" .. CONFIG.VERSION,
        UDim2.new(1, 0, 0, 22), CONFIG.TEXT_PRIMARY, Enum.Font.GothamBold, { TextSize = 14 })
    label(aboutCard, "Hub for YouTube Music Player. YouTube-style video UI, Spotify-style music UI, utilities, and config.",
        UDim2.new(1, 0, 0, 0), CONFIG.TEXT_MUTED, Enum.Font.Gotham, {
            Position      = UDim2.new(0, 0, 0, 24),
            TextSize      = 11,
            TextWrapped   = true,
            AutomaticSize = Enum.AutomaticSize.Y,
        })

    -- Entrance
    win.Size = UDim2.new(0, 0, 0, 0)
    tweenPlay(win, TI.bounce, { Size = UDim2.new(0, 520, 0, 480) })
end

-- ============================================================
--  NAVIGATION ROUTER
-- ============================================================
local function goToMode(mode)
    currentMode = mode

    if mode == "music" then
        buildSpotifyUI(function()
            buildModeSelector(goToMode)
        end)
    elseif mode == "video" then
        buildYouTubeUI(function()
            buildModeSelector(goToMode)
        end)
    elseif mode == "utility" then
        buildUtilityUI(function()
            buildModeSelector(goToMode)
        end)
    elseif mode == "config" then
        buildConfigUI(function()
            buildModeSelector(goToMode)
        end)
    end
end

-- ============================================================
--  TOGGLE KEYBIND
-- ============================================================
local hubVisible = true
UserInput.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = inp.KeyCode.Name
        if keyName == savedConfig.keybind then
            local existing = CoreGui:FindFirstChild("YunoHub")
            if existing then
                hubVisible = not hubVisible
                local mainWin = existing:FindFirstChildWhichIsA("Frame")
                if mainWin then
                    tweenPlay(mainWin, TI.mid, {
                        BackgroundTransparency = hubVisible and 0 or 1,
                        Size = hubVisible
                            and UDim2.new(mainWin.Size.X.Scale, mainWin.Size.X.Offset,
                                         mainWin.Size.Y.Scale, mainWin.Size.Y.Offset)
                            or UDim2.new(0, 0, 0, 0)
                    })
                end
            end
        end
    end
end)

-- ============================================================
--  MINI FLOATING BUTTON  (always visible after hub closes)
-- ============================================================
local function createFloatingBtn()
    local fsg = new("ScreenGui", {
        Name            = "YunoFloat",
        IgnoreGuiInset  = true,
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)

    local fab = new("ImageButton", {
        Size             = UDim2.new(0, 44, 0, 44),
        Position         = UDim2.new(1, -60, 0.5, -22),
        BackgroundColor3 = CONFIG.ACCENT_RED,
        Image            = ICONS.LOGO,
        ScaleType        = Enum.ScaleType.Fit,
        AutoButtonColor  = false,
        BorderSizePixel  = 0,
    }, fsg)
    corner(fab, CONFIG.CORNER_FULL)
    stroke(fab, CONFIG.TEXT_PRIMARY, 2, 0.4)

    makeDraggable(fab, fab)

    -- Pulse animation
    task.spawn(function()
        while fab and fab.Parent do
            tweenPlay(fab, TI.spring, { BackgroundColor3 = Color3.fromRGB(220, 20, 20) })
            task.wait(1.2)
            tweenPlay(fab, TI.spring, { BackgroundColor3 = CONFIG.ACCENT_RED })
            task.wait(1.2)
        end
    end)

    fab.MouseButton1Click:Connect(function()
        local existing = CoreGui:FindFirstChild("YunoHub")
        if existing then
            existing:Destroy()
            buildModeSelector(goToMode)
        else
            buildModeSelector(goToMode)
        end
    end)

    return fsg
end

-- ============================================================
--  ENTRY POINT
-- ============================================================
initNotifContainer()

showLoading(function()
    -- Floating button persists
    createFloatingBtn()

    -- Default mode routing
    if savedConfig.defaultMode == "music" then
        buildSpotifyUI(function() buildModeSelector(goToMode) end)
    elseif savedConfig.defaultMode == "video" then
        buildYouTubeUI(function() buildModeSelector(goToMode) end)
    else
        buildModeSelector(goToMode)
    end

    notify("Yuno Player", "Hub loaded. Press ] to toggle. Use the floating button to reopen.", 5, false)
end)
