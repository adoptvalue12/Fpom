-- ============================================================
--  YUNO PLAYER  |  v2.0
--  Loading -> Platform Chooser -> Spotify UI / YouTube UI
--  Profile bar: avatar rect / username / session timer / stats
-- ============================================================

getgenv().YUNO_HUB = getgenv().YUNO_HUB or false
if getgenv().YUNO_HUB then return end
getgenv().YUNO_HUB = true

-- ============================================================
--  SERVICES
-- ============================================================
local fn = cloneref or function(a) return a end
local Players     = fn(game:GetService("Players"))
local TweenSvc    = fn(game:GetService("TweenService"))
local UIS         = fn(game:GetService("UserInputService"))
local CoreGui     = fn(game:GetService("CoreGui"))
local StarterGui  = fn(game:GetService("StarterGui"))
local HttpSvc     = fn(game:GetService("HttpService"))
local SoundSvc    = fn(game:GetService("SoundService"))
local RunSvc      = fn(game:GetService("RunService"))
local WS          = fn(game:GetService("Workspace"))

local LP          = Players.LocalPlayer
local Cam         = WS.CurrentCamera

-- ============================================================
--  EXECUTOR COMPAT
-- ============================================================
local request_ = request or http_request
    or (syn and syn.request)
    or (http and http.request)
    or (fluxus and fluxus.request)
    or (getgenv and getgenv().request)

local clip_ = setclipboard or toclipboard
    or (syn and syn.write_clipboard)
    or (fluxus and fluxus.setclipboard)

local hwid_ = (gethwid and gethwid())
    or (syn and syn.gethwid and syn.gethwid())
    or (fluxus and fluxus.gethwid and fluxus.gethwid())
    or tostring(LP.UserId)

-- ============================================================
--  CONFIG / CONSTANTS
-- ============================================================
local YMP_URL = "https://raw.githubusercontent.com/Dan41/Roblox-Scripts/refs/heads/main/Youtube%20Music%20Player/YoutubeMusicPlayer.lua"
local IP_URL  = "https://api.ipify.org?format=json"
local GEO_URL = "http://ip-api.com/json/"

-- Spotify palette
local SP = {
    BG       = Color3.fromRGB(10, 10, 10),
    SURFACE  = Color3.fromRGB(18, 18, 18),
    CARD     = Color3.fromRGB(24, 24, 24),
    CARD2    = Color3.fromRGB(30, 30, 30),
    ACCENT   = Color3.fromRGB(30, 215, 96),
    WHITE    = Color3.fromRGB(255, 255, 255),
    GREY     = Color3.fromRGB(179, 179, 179),
    MUTED    = Color3.fromRGB(100, 100, 100),
    NAV      = Color3.fromRGB(9, 9, 9),
}
-- YouTube palette
local YT = {
    BG       = Color3.fromRGB(15, 15, 15),
    SURFACE  = Color3.fromRGB(22, 22, 22),
    CARD     = Color3.fromRGB(28, 28, 28),
    TOPBAR   = Color3.fromRGB(15, 15, 15),
    RED      = Color3.fromRGB(255, 0, 0),
    WHITE    = Color3.fromRGB(255, 255, 255),
    GREY     = Color3.fromRGB(170, 170, 170),
    MUTED    = Color3.fromRGB(95, 95, 95),
}

-- Asset IDs — replace with real rbxassetids as needed
local A = {
    SPOTIFY_LOGO  = "rbxassetid://6031075931",
    YOUTUBE_LOGO  = "rbxassetid://6031082508",
    YMP_LOGO      = "rbxassetid://132058030456598",
    PLAY          = "rbxassetid://7743878857",
    PAUSE         = "rbxassetid://7743877799",
    SKIP_NEXT     = "rbxassetid://7743876375",
    SKIP_PREV     = "rbxassetid://7743875893",
    SHUFFLE       = "rbxassetid://7743880065",
    REPEAT_I      = "rbxassetid://7743879471",
    HEART         = "rbxassetid://7743874909",
    HEART_F       = "rbxassetid://7743874283",
    SEARCH        = "rbxassetid://7743881379",
    SETTINGS      = "rbxassetid://7734055498",
    HOME          = "rbxassetid://7734049836",
    LIBRARY       = "rbxassetid://7734048734",
    PREMIUM       = "rbxassetid://7734046732",
    CREATE        = "rbxassetid://7734045622",
    CLOSE         = "rbxassetid://7734043826",
    MORE          = "rbxassetid://7734042734",
    SHARE         = "rbxassetid://7734041528",
    VOLUME        = "rbxassetid://7734040324",
    CAST          = "rbxassetid://7734039128",
    CC            = "rbxassetid://7734037924",
    FULLSCREEN    = "rbxassetid://7734036718",
    LIKE          = "rbxassetid://7734035512",
    DISLIKE       = "rbxassetid://7734034306",
    QUEUE         = "rbxassetid://7734033100",
    LYRICS        = "rbxassetid://7734031894",
    CLOCK         = "rbxassetid://7734030688",
    DEVICES       = "rbxassetid://7734029482",
    BACK_ARROW    = "rbxassetid://7734028276",
    DOWN_ARROW    = "rbxassetid://7734027070",
    LOCK          = "rbxassetid://7734025864",
    SPEED         = "rbxassetid://7734024658",
    QUALITY       = "rbxassetid://7734023452",
    SUBSCRIBE     = "rbxassetid://7734022246",
    BELL          = "rbxassetid://7734021040",
    THUMB_UP      = "rbxassetid://7734019834",
    THUMB_DOWN    = "rbxassetid://7734018628",
    SAVE          = "rbxassetid://7734017422",
    USER          = "rbxassetid://7734016216",
    INFO          = "rbxassetid://7734015010",
    WIFI          = "rbxassetid://7734013804",
    SERVER_I      = "rbxassetid://7734012598",
    LOCATION      = "rbxassetid://7734011392",
    TRANSLATE     = "rbxassetid://7734010186",
    ADD           = "rbxassetid://7734008980",
    DOWNLOAD      = "rbxassetid://7734007774",
    MUSIC_NOTE    = "rbxassetid://7734006568",
    VIDEO_I       = "rbxassetid://7734005362",
}

-- ============================================================
--  TWEEN SHORTHAND
-- ============================================================
local TI = {
    f  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    m  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    s  = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    b  = TweenInfo.new(0.50, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    si = TweenInfo.new(0.60, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}
local function tw(o, i, p) TweenSvc:Create(o,i,p):Play() end

-- ============================================================
--  INSTANCE FACTORY
-- ============================================================
local function N(cls, props, parent)
    local o = Instance.new(cls)
    if props then for k,v in pairs(props) do o[k]=v end end
    if parent then o.Parent = parent end
    return o
end
local function Corner(p, r) return N("UICorner",{CornerRadius=r or UDim.new(0,8)},p) end
local function Stroke(p,c,t,tr) return N("UIStroke",{Color=c,Thickness=t or 1,Transparency=tr or 0},p) end
local function Pad(p,t,b,l,r) return N("UIPadding",{PaddingTop=UDim.new(0,t or 8),PaddingBottom=UDim.new(0,b or 8),PaddingLeft=UDim.new(0,l or 8),PaddingRight=UDim.new(0,r or 8)},p) end
local function List(p,d,a,sp) return N("UIListLayout",{FillDirection=d or Enum.FillDirection.Vertical,HorizontalAlignment=a or Enum.HorizontalAlignment.Left,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,sp or 0)},p) end
local function Grid(p,cs,cp) return N("UIGridLayout",{CellSize=cs or UDim2.new(0,80,0,80),CellPaddingHorizontal=UDim.new(0,cp or 6),CellPaddingVertical=UDim.new(0,cp or 6),SortOrder=Enum.SortOrder.LayoutOrder},p) end
local function Lbl(p, txt, sz, col, font, ts, xa)
    return N("TextLabel",{Size=sz or UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=txt or "",TextColor3=col or Color3.new(1,1,1),Font=font or Enum.Font.GothamBold,TextSize=ts or 14,TextXAlignment=xa or Enum.TextXAlignment.Left,RichText=true,TextTruncate=Enum.TextTruncate.AtEnd},p)
end
local function Img(p, id, sz, pos, ic)
    return N("ImageLabel",{Size=sz or UDim2.new(0,24,0,24),Position=pos or UDim2.new(0,0,0,0),BackgroundTransparency=1,Image=id or "",ScaleType=Enum.ScaleType.Fit,ImageColor3=ic or Color3.new(1,1,1)},p)
end
local function ImgBtn(p, id, sz, ic)
    local b = N("ImageButton",{Size=sz or UDim2.new(0,28,0,28),BackgroundTransparency=1,Image=id or "",ScaleType=Enum.ScaleType.Fit,ImageColor3=ic or Color3.new(1,1,1),AutoButtonColor=false},p)
    b.MouseEnter:Connect(function() tw(b,TI.f,{ImageTransparency=0.35}) end)
    b.MouseLeave:Connect(function() tw(b,TI.f,{ImageTransparency=0}) end)
    return b
end
local function TxtBtn(p, txt, sz, bg, tc, ts, font)
    local b = N("TextButton",{Size=sz or UDim2.new(0,100,0,36),BackgroundColor3=bg or Color3.fromRGB(30,30,30),Text=txt or "",TextColor3=tc or Color3.new(1,1,1),Font=font or Enum.Font.GothamBold,TextSize=ts or 13,AutoButtonColor=false,BorderSizePixel=0},p)
    Corner(b)
    return b
end
local function Scroll(p, sz, pos, pad)
    local s = N("ScrollingFrame",{Size=sz or UDim2.new(1,0,1,0),Position=pos or UDim2.new(0,0,0,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=Color3.fromRGB(80,80,80),CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},p)
    if pad then Pad(s,pad,pad,pad,pad) end
    return s
end

-- ============================================================
--  DRAG
-- ============================================================
local function Drag(handle, target)
    local drag, di, ds, sp = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=target.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i==di and drag then
            local d=i.Position-ds
            target.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
--  SESSION TRACKING
-- ============================================================
local sessionStart = tick()
local sessionStats = { songsPlayed=0, videosPlayed=0, searches=0 }

local function sessionTime()
    local e = math.floor(tick()-sessionStart)
    local h = math.floor(e/3600)
    local m = math.floor((e%3600)/60)
    local s = e%60
    if h > 0 then return string.format("%dh %02dm", h, m)
    else return string.format("%dm %02ds", m, s) end
end

-- ============================================================
--  PLAYER SKIN COLOR (approximate from character)
-- ============================================================
local function getSkinColor()
    local chr = LP.Character or LP.CharacterAdded:Wait()
    if chr then
        local torso = chr:FindFirstChild("UpperTorso") or chr:FindFirstChild("Torso")
        if torso and torso:IsA("BasePart") then
            return torso.Color
        end
        local head = chr:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            return head.Color
        end
    end
    return Color3.fromRGB(255, 200, 150)
end

-- ============================================================
--  NOTIFICATION
-- ============================================================
local notifSG, notifFrame

local function initNotif()
    if notifSG and notifSG.Parent then notifSG:Destroy() end
    notifSG = N("ScreenGui",{Name="YunoNotif",IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},CoreGui)
    notifFrame = N("Frame",{Size=UDim2.new(0,280,1,0),Position=UDim2.new(1,-290,0,0),BackgroundTransparency=1},notifSG)
    List(notifFrame,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Right,6)
    Pad(notifFrame,10,0,0,0)
end

local function notify(title, body, err)
    if not notifFrame then initNotif() end
    local c = N("Frame",{Size=UDim2.new(1,0,0,64),BackgroundColor3=Color3.fromRGB(22,22,22),BorderSizePixel=0,ClipsDescendants=true},notifFrame)
    Corner(c,UDim.new(0,10))
    Stroke(c, err and Color3.fromRGB(255,50,50) or Color3.fromRGB(30,215,96), 1, 0.4)
    local bar = N("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=err and Color3.fromRGB(255,50,50) or Color3.fromRGB(30,215,96),BorderSizePixel=0},c)
    Corner(bar,UDim.new(0,2))
    local inner = N("Frame",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1},c)
    Pad(inner,8,8,4,4)
    Lbl(inner,title,UDim2.new(1,0,0,18),Color3.new(1,1,1),Enum.Font.GothamBold,12)
    Lbl(inner,body, UDim2.new(1,0,0,16),Color3.fromRGB(170,170,170),Enum.Font.Gotham,11,Enum.TextXAlignment.Left)
    tw(c,TI.b,{Size=UDim2.new(1,0,0,64)})
    task.delay(4, function()
        if c and c.Parent then tw(c,TI.m,{BackgroundTransparency=1}) task.wait(0.3) pcall(function() c:Destroy() end) end
    end)
end

-- ============================================================
--  LOADING SCREEN
-- ============================================================
local function showLoading(cb)
    local sg = N("ScreenGui",{Name="YunoLoading",IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},CoreGui)
    local bg = N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0},sg)

    -- Animated background lines
    for i=1,12 do
        local line = N("Frame",{
            Size=UDim2.new(0,1,1,0),
            Position=UDim2.new(0,(i-1)*70+10,0,0),
            BackgroundColor3=Color3.fromRGB(20,20,20),BorderSizePixel=0
        },bg)
        task.spawn(function()
            while line and line.Parent do
                tw(line,TweenInfo.new(2+math.random(),Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundColor3=Color3.fromRGB(35,35,35)})
                task.wait(1.5+math.random())
                tw(line,TweenInfo.new(2+math.random(),Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundColor3=Color3.fromRGB(20,20,20)})
                task.wait(1.5+math.random())
            end
        end)
    end

    -- Center card
    local card = N("Frame",{
        Size=UDim2.new(0,280,0,320),
        Position=UDim2.new(0.5,0,0.5,0),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=Color3.fromRGB(14,14,14),
        BorderSizePixel=0,
    },bg)
    Corner(card,UDim.new(0,20))
    Stroke(card,Color3.fromRGB(40,40,40),1)

    -- Logo box
    local logoBox = N("Frame",{
        Size=UDim2.new(0,72,0,72),
        Position=UDim2.new(0.5,-36,0,32),
        BackgroundColor3=Color3.fromRGB(22,22,22),
        BorderSizePixel=0,
    },card)
    Corner(logoBox,UDim.new(0,16))
    local logoStroke = Stroke(logoBox,Color3.fromRGB(30,215,96),2)
    Img(logoBox,A.YMP_LOGO,UDim2.new(0.68,0,0.68,0),UDim2.new(0.16,0,0.16,0))

    -- Title
    local titleLbl = N("TextLabel",{
        Size=UDim2.new(1,0,0,32),
        Position=UDim2.new(0,0,0,116),
        BackgroundTransparency=1,
        Text="Yuno Player",
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.GothamBold,
        TextSize=22,
        TextXAlignment=Enum.TextXAlignment.Center,
    },card)
    local subLbl = N("TextLabel",{
        Size=UDim2.new(1,0,0,18),
        Position=UDim2.new(0,0,0,150),
        BackgroundTransparency=1,
        Text="Your media. Your rules.",
        TextColor3=Color3.fromRGB(100,100,100),
        Font=Enum.Font.Gotham,
        TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Center,
    },card)

    -- Progress bar
    local barBg = N("Frame",{
        Size=UDim2.new(0,200,0,4),
        Position=UDim2.new(0.5,-100,0,190),
        BackgroundColor3=Color3.fromRGB(30,30,30),
        BorderSizePixel=0,
    },card)
    Corner(barBg,UDim.new(1,0))
    local barFill = N("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=Color3.fromRGB(30,215,96),BorderSizePixel=0},barBg)
    Corner(barFill,UDim.new(1,0))

    local statusLbl = N("TextLabel",{
        Size=UDim2.new(1,0,0,16),
        Position=UDim2.new(0,0,0,206),
        BackgroundTransparency=1,
        Text="Initializing...",
        TextColor3=Color3.fromRGB(80,80,80),
        Font=Enum.Font.Gotham,
        TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Center,
    },card)

    -- Username greeting
    local greetLbl = N("TextLabel",{
        Size=UDim2.new(1,-24,0,20),
        Position=UDim2.new(0,12,0,240),
        BackgroundTransparency=1,
        Text="Welcome, "..LP.DisplayName,
        TextColor3=Color3.fromRGB(60,60,60),
        Font=Enum.Font.Gotham,
        TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Center,
    },card)

    -- Entrance
    card.Size=UDim2.new(0,0,0,0)
    card.BackgroundTransparency=1
    tw(card,TI.b,{Size=UDim2.new(0,280,0,320),BackgroundTransparency=0})

    -- Stroke pulse
    task.spawn(function()
        local up=true
        while card and card.Parent do
            tw(logoStroke,TI.si,{Transparency=up and 0 or 0.6})
            task.wait(0.9); up=not up
        end
    end)

    local steps = {
        {0.15,"Loading services..."},
        {0.35,"Connecting to YMP API..."},
        {0.55,"Building interface..."},
        {0.75,"Preparing your profile..."},
        {0.95,"Almost ready..."},
        {1.0,"Done!"},
    }
    task.spawn(function()
        for _,s in ipairs(steps) do
            if not card or not card.Parent then return end
            tw(barFill,TI.s,{Size=UDim2.new(s[1],0,1,0)})
            statusLbl.Text=s[2]
            task.wait(0.45)
        end
        task.wait(0.3)
        tw(bg,TweenInfo.new(0.4),{BackgroundTransparency=1})
        for _,d in ipairs(bg:GetDescendants()) do
            if d:IsA("GuiObject") then
                pcall(function() tw(d,TweenInfo.new(0.4),{BackgroundTransparency=1,TextTransparency=1,ImageTransparency=1}) end)
            end
        end
        task.wait(0.45)
        pcall(function() sg:Destroy() end)
        if cb then cb() end
    end)
end

-- ============================================================
--  PLATFORM CHOOSER
-- ============================================================
local activeSG = nil

local function destroyActive()
    if activeSG and activeSG.Parent then
        activeSG:Destroy()
        activeSG = nil
    end
end

local function showChooser(onPick)
    destroyActive()
    local sg = N("ScreenGui",{Name="YunoHub",IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},CoreGui)
    activeSG = sg

    local win = N("Frame",{
        Size=UDim2.new(0,380,0,340),
        Position=UDim2.new(0.5,0,0.5,0),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=Color3.fromRGB(12,12,12),
        BorderSizePixel=0,
    },sg)
    Corner(win,UDim.new(0,18))
    Stroke(win,Color3.fromRGB(35,35,35))
    Drag(win,win)

    -- Header
    local hdr = N("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0},win)
    Corner(hdr,UDim.new(0,18))
    N("Frame",{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,1,-26),BackgroundColor3=Color3.fromRGB(8,8,8),BorderSizePixel=0},hdr)
    Img(hdr,A.YMP_LOGO,UDim2.new(0,26,0,26),UDim2.new(0,14,0,13))
    Lbl(hdr,"Yuno Player",UDim2.new(0,180,0,26),Color3.new(1,1,1),Enum.Font.GothamBold,15)
        .Position = UDim2.new(0,48,0,13)
    local closeX = ImgBtn(hdr,A.CLOSE,UDim2.new(0,22,0,22))
    closeX.Position=UDim2.new(1,-34,0,15)
    closeX.MouseButton1Click:Connect(function()
        tw(win,TI.m,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1})
        task.wait(0.3); sg:Destroy()
    end)

    -- Welcome text
    local wt = Lbl(win,"Choose your platform",UDim2.new(1,-32,0,22),Color3.new(1,1,1),Enum.Font.GothamBold,17)
    wt.Position=UDim2.new(0,16,0,64)
    wt.TextXAlignment=Enum.TextXAlignment.Center
    local ws = Lbl(win,"Select how you want to listen today",UDim2.new(1,-32,0,16),Color3.fromRGB(100,100,100),Enum.Font.Gotham,12)
    ws.Position=UDim2.new(0,16,0,90)
    ws.TextXAlignment=Enum.TextXAlignment.Center

    -- Card builder
    local function platformCard(parent, logoId, name, tagline, accent, xpos, onClick)
        local card = N("Frame",{
            Size=UDim2.new(0,158,0,142),
            Position=UDim2.new(0,xpos,0,118),
            BackgroundColor3=Color3.fromRGB(20,20,20),
            BorderSizePixel=0,
        },parent)
        Corner(card,UDim.new(0,14))
        local st = Stroke(card,Color3.fromRGB(38,38,38),1)
        Pad(card,16,16,16,16)

        -- Logo
        local logoFrame = N("Frame",{
            Size=UDim2.new(0,52,0,52),
            Position=UDim2.new(0.5,-26,0,0),
            BackgroundColor3=Color3.fromRGB(10,10,10),
            BorderSizePixel=0,
        },card)
        Corner(logoFrame,UDim.new(0,12))
        Img(logoFrame,logoId,UDim2.new(0.72,0,0.72,0),UDim2.new(0.14,0,0.14,0))

        -- Name
        local nl = Lbl(card,name,UDim2.new(1,0,0,18),Color3.new(1,1,1),Enum.Font.GothamBold,14)
        nl.Position=UDim2.new(0,0,0,60)
        nl.TextXAlignment=Enum.TextXAlignment.Center

        -- Tagline
        local tl = Lbl(card,tagline,UDim2.new(1,0,0,28),Color3.fromRGB(110,110,110),Enum.Font.Gotham,11)
        tl.Position=UDim2.new(0,0,0,80)
        tl.TextXAlignment=Enum.TextXAlignment.Center
        tl.TextWrapped=true

        -- Invisible button
        local btn = N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5,AutoButtonColor=false},card)
        btn.MouseEnter:Connect(function()
            tw(card,TI.f,{BackgroundColor3=Color3.fromRGB(28,28,28)})
            tw(st,TI.f,{Color=accent,Transparency=0})
        end)
        btn.MouseLeave:Connect(function()
            tw(card,TI.f,{BackgroundColor3=Color3.fromRGB(20,20,20)})
            tw(st,TI.f,{Color=Color3.fromRGB(38,38,38)})
        end)
        btn.MouseButton1Click:Connect(function()
            tw(card,TI.f,{BackgroundColor3=accent:Lerp(Color3.new(0,0,0),0.7)})
            task.wait(0.12)
            onClick()
        end)
    end

    platformCard(win, A.SPOTIFY_LOGO, "Music", "Spotify-style interface",
        Color3.fromRGB(30,215,96), 16, function() onPick("spotify") end)
    platformCard(win, A.YOUTUBE_LOGO, "Video", "YouTube-style interface",
        Color3.fromRGB(255,0,0), 186, function() onPick("youtube") end)

    -- Footer info
    local fl = Lbl(win,"You can switch platforms from the Config tab at any time",
        UDim2.new(1,-32,0,28),Color3.fromRGB(55,55,55),Enum.Font.Gotham,10)
    fl.Position=UDim2.new(0,16,0,278)
    fl.TextXAlignment=Enum.TextXAlignment.Center
    fl.TextWrapped=true

    win.Size=UDim2.new(0,0,0,0)
    tw(win,TI.b,{Size=UDim2.new(0,380,0,340)})
end

-- ============================================================
--  PROFILE BAR BUILDER  (shared between both UIs)
-- ============================================================
local function buildProfileBar(parent, accentColor)
    local skinColor = getSkinColor()

    local bar = N("Frame",{
        Size=UDim2.new(1,0,0,54),
        BackgroundColor3=Color3.fromRGB(16,16,16),
        BorderSizePixel=0,
    },parent)
    Stroke(bar,Color3.fromRGB(30,30,30),1)
    Pad(bar,0,0,10,10)

    -- Skin color rect (avatar approximation)
    local skinRect = N("Frame",{
        Size=UDim2.new(0,36,0,36),
        Position=UDim2.new(0,0,0.5,-18),
        BackgroundColor3=skinColor,
        BorderSizePixel=0,
    },bar)
    Corner(skinRect,UDim.new(0,6))
    Stroke(skinRect,accentColor,2,0.3)
    -- Initial letter drawn over the rect
    local initLbl = N("TextLabel",{
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text=LP.Name:sub(1,1):upper(),
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.GothamBold,
        TextSize=16,
        TextXAlignment=Enum.TextXAlignment.Center,
    },skinRect)

    -- Name + display name
    local nameLbl = N("TextLabel",{
        Size=UDim2.new(0,130,0,18),
        Position=UDim2.new(0,44,0,8),
        BackgroundTransparency=1,
        Text=LP.DisplayName,
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.GothamBold,
        TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
    },bar)
    local userLbl = N("TextLabel",{
        Size=UDim2.new(0,130,0,14),
        Position=UDim2.new(0,44,0,26),
        BackgroundTransparency=1,
        Text="@"..LP.Name,
        TextColor3=Color3.fromRGB(90,90,90),
        Font=Enum.Font.Gotham,
        TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,
    },bar)

    -- Session timer (right side)
    local timerLbl = N("TextLabel",{
        Size=UDim2.new(0,90,0,18),
        Position=UDim2.new(1,-100,0,8),
        BackgroundTransparency=1,
        Text=sessionTime(),
        TextColor3=accentColor,
        Font=Enum.Font.GothamBold,
        TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Right,
    },bar)
    local timerSub = N("TextLabel",{
        Size=UDim2.new(0,90,0,14),
        Position=UDim2.new(1,-100,0,26),
        BackgroundTransparency=1,
        Text="session time",
        TextColor3=Color3.fromRGB(65,65,65),
        Font=Enum.Font.Gotham,
        TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Right,
    },bar)

    -- Live update timer
    task.spawn(function()
        while timerLbl and timerLbl.Parent do
            timerLbl.Text = sessionTime()
            task.wait(5)
        end
    end)

    return bar, skinRect, nameLbl
end

-- ============================================================
--  STAT BAR  (songs played / searches / etc)
-- ============================================================
local function buildStatBar(parent, mode)
    local bar = N("Frame",{
        Size=UDim2.new(1,0,0,38),
        BackgroundColor3=Color3.fromRGB(14,14,14),
        BorderSizePixel=0,
    },parent)
    Stroke(bar,Color3.fromRGB(28,28,28),1)
    Pad(bar,0,0,10,10)

    local function statItem(label, getValue, xpct, color)
        local f = N("Frame",{
            Size=UDim2.new(0,80,1,0),
            Position=UDim2.new(xpct,-40,0,0),
            BackgroundTransparency=1,
        },bar)
        local vl = N("TextLabel",{
            Size=UDim2.new(1,0,0,18),
            BackgroundTransparency=1,
            Text=tostring(getValue()),
            TextColor3=color or Color3.new(1,1,1),
            Font=Enum.Font.GothamBold,
            TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Center,
        },f)
        N("TextLabel",{
            Size=UDim2.new(1,0,0,14),
            Position=UDim2.new(0,0,0,18),
            BackgroundTransparency=1,
            Text=label,
            TextColor3=Color3.fromRGB(70,70,70),
            Font=Enum.Font.Gotham,
            TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Center,
        },f)
        -- auto refresh
        task.spawn(function()
            while vl and vl.Parent do
                vl.Text=tostring(getValue())
                task.wait(3)
            end
        end)
        return vl
    end

    if mode=="spotify" then
        statItem("Songs Played", function() return sessionStats.songsPlayed end, 0.18, Color3.fromRGB(30,215,96))
        statItem("Searches",     function() return sessionStats.searches end,    0.50, Color3.fromRGB(180,180,180))
        statItem("Session",      function() return sessionTime() end,            0.82, Color3.fromRGB(30,215,96))
    else
        statItem("Videos Played",function() return sessionStats.videosPlayed end,0.18, Color3.fromRGB(255,50,50))
        statItem("Searches",     function() return sessionStats.searches end,    0.50, Color3.fromRGB(180,180,180))
        statItem("Session",      function() return sessionTime() end,            0.82, Color3.fromRGB(255,50,50))
    end

    return bar
end

-- ============================================================
--  SPOTIFY UI
-- ============================================================
local function buildSpotify(onSwitch)
    destroyActive()
    local sg = N("ScreenGui",{Name="YunoHub",IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},CoreGui)
    activeSG = sg

    -- Main window
    local WIN_W, WIN_H = 400, 620
    local win = N("Frame",{
        Size=UDim2.new(0,WIN_W,0,WIN_H),
        Position=UDim2.new(0.5,0,0.5,0),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=SP.BG,
        BorderSizePixel=0,
        ClipsDescendants=true,
    },sg)
    Corner(win,UDim.new(0,16))
    Drag(win,win)

    -- Top chrome (drag handle)
    local topChrome = N("Frame",{
        Size=UDim2.new(1,0,0,40),
        BackgroundColor3=SP.SURFACE,
        BorderSizePixel=0,
    },win)
    N("Frame",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,1,-20),BackgroundColor3=SP.SURFACE,BorderSizePixel=0},topChrome)
    Img(topChrome,A.SPOTIFY_LOGO,UDim2.new(0,22,0,22),UDim2.new(0,14,0,9),Color3.fromRGB(30,215,96))
    Lbl(topChrome,"Yuno Player",UDim2.new(0,140,0,22),SP.WHITE,Enum.Font.GothamBold,14).Position=UDim2.new(0,44,0,9)
    local closeBtn=ImgBtn(topChrome,A.CLOSE,UDim2.new(0,20,0,20))
    closeBtn.Position=UDim2.new(1,-30,0,10)
    closeBtn.MouseButton1Click:Connect(function()
        tw(win,TI.m,{Size=UDim2.new(0,0,0,0)}); task.wait(0.28); sg:Destroy()
    end)

    -- Profile + stat bars
    local profBar, skinRect = buildProfileBar(win, SP.ACCENT)
    profBar.Position=UDim2.new(0,0,0,40)
    local statBar = buildStatBar(win,"spotify")
    statBar.Position=UDim2.new(0,0,0,94)

    -- Body: tabbed views
    -- Tabs: Home | Search | Library | Config
    local BODY_TOP = 132
    local BODY_H   = WIN_H - BODY_TOP - 52  -- 52 = bottom nav
    local body = N("Frame",{
        Size=UDim2.new(1,0,0,BODY_H),
        Position=UDim2.new(0,0,0,BODY_TOP),
        BackgroundTransparency=1,
        ClipsDescendants=true,
    },win)

    -- Views
    local views = {}
    local function makeView()
        local v = N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},body)
        table.insert(views,v)
        return v
    end

    -- ---- HOME VIEW ----
    local homeView = makeView()
    homeView.Visible=true

    local homeScroll = Scroll(homeView,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),12)
    local homeList = N("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},homeScroll)
    List(homeList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,0)

    -- Good morning greeting
    local hour = tonumber(os.date("%H")) or 12
    local greeting = hour<12 and "Good morning" or (hour<18 and "Good afternoon" or "Good evening")
    local greetF = N("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,LayoutOrder=1},homeList)
    Lbl(greetF,greeting,UDim2.new(1,-24,0,32),SP.WHITE,Enum.Font.GothamBold,18).Position=UDim2.new(0,0,0,4)

    -- Recent playlists grid (2 columns, Spotify style)
    local recentHeader = N("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,LayoutOrder=2},homeList)
    Lbl(recentHeader,"Recent",UDim2.new(1,0,1,0),SP.WHITE,Enum.Font.GothamBold,14)

    local recentGrid = N("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1,
        LayoutOrder=3,
        AutomaticSize=Enum.AutomaticSize.Y,
    },homeList)
    Grid(recentGrid,UDim2.new(0.48,0,0,50),6)

    local playlists = {
        {name="My Playlist",    thumb=SP.CARD2},
        {name="Favorites",      thumb=Color3.fromRGB(30,50,80)},
        {name="Downloaded",     thumb=Color3.fromRGB(50,30,80)},
        {name="Recent",         thumb=Color3.fromRGB(60,40,20)},
        {name="Liked Songs",    thumb=Color3.fromRGB(30,20,80)},
        {name="Local Audio",    thumb=Color3.fromRGB(20,60,40)},
    }
    for i,pl in ipairs(playlists) do
        local cell = N("Frame",{
            BackgroundColor3=pl.thumb,
            BorderSizePixel=0,
            LayoutOrder=i,
        },recentGrid)
        Corner(cell,UDim.new(0,6))
        -- thumb placeholder drawn as colored left square
        local thumb = N("Frame",{Size=UDim2.new(0,50,1,0),BackgroundColor3=pl.thumb:Lerp(Color3.new(0,0,0),0.3),BorderSizePixel=0},cell)
        Img(thumb,A.MUSIC_NOTE,UDim2.new(0.6,0,0.6,0),UDim2.new(0.2,0,0.2,0),Color3.fromRGB(120,120,120))
        Lbl(cell,pl.name,UDim2.new(1,-60,1,0),SP.WHITE,Enum.Font.GothamBold,12).Position=UDim2.new(0,56,0,0)
        local cbtn=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5,AutoButtonColor=false},cell)
        cbtn.MouseEnter:Connect(function() tw(cell,TI.f,{BackgroundColor3=pl.thumb:Lerp(Color3.new(1,1,1),0.08)}) end)
        cbtn.MouseLeave:Connect(function() tw(cell,TI.f,{BackgroundColor3=pl.thumb}) end)
    end

    -- Daily recommendations section
    local recHeader = N("Frame",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,LayoutOrder=4},homeList)
    Pad(recHeader,6,0,0,0)
    Lbl(recHeader,"Recommended for you",UDim2.new(1,0,0,24),SP.WHITE,Enum.Font.GothamBold,15)

    local recScroll = N("ScrollingFrame",{
        Size=UDim2.new(1,0,0,170),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        ScrollBarThickness=0,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.X,
        ScrollingDirection=Enum.ScrollingDirection.X,
        LayoutOrder=5,
    },homeList)
    local recInner = N("Frame",{Size=UDim2.new(0,0,1,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.X},recScroll)
    List(recInner,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Left,10)
    Pad(recInner,0,0,0,10)

    local recColors={
        Color3.fromRGB(40,20,60),
        Color3.fromRGB(20,40,60),
        Color3.fromRGB(60,30,20),
        Color3.fromRGB(20,55,40),
        Color3.fromRGB(55,40,20),
    }
    local recLabels={"Single","Album","EP","Single","Album"}
    local recNames={"Loading...","Loading...","Loading...","Loading...","Loading..."}
    for i=1,5 do
        local card = N("Frame",{
            Size=UDim2.new(0,130,1,-8),
            BackgroundColor3=recColors[i],
            BorderSizePixel=0,
            LayoutOrder=i,
        },recInner)
        Corner(card,UDim.new(0,10))
        Pad(card,8,8,8,8)
        local thumb = N("Frame",{
            Size=UDim2.new(1,0,0,100),
            BackgroundColor3=recColors[i]:Lerp(Color3.new(0,0,0),0.4),
            BorderSizePixel=0,
        },card)
        Corner(thumb,UDim.new(0,8))
        Img(thumb,A.MUSIC_NOTE,UDim2.new(0.45,0,0.45,0),UDim2.new(0.275,0,0.275,0),Color3.fromRGB(90,90,90))
        Lbl(card,recNames[i],UDim2.new(1,0,0,16),SP.WHITE,Enum.Font.GothamBold,12).Position=UDim2.new(0,0,0,108)
        Lbl(card,recLabels[i],UDim2.new(1,0,0,14),SP.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,124)
    end

    -- ---- SEARCH VIEW ----
    local searchView = makeView()
    local srchScroll = Scroll(searchView,UDim2.new(1,0,1,0),nil,10)
    local srchList   = N("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},srchScroll)
    List(srchList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,0)

    -- Search input area
    local srchBox = N("Frame",{
        Size=UDim2.new(1,0,0,42),
        BackgroundColor3=SP.CARD2,
        BorderSizePixel=0,
        LayoutOrder=1,
    },srchList)
    Corner(srchBox,UDim.new(1,0))
    Pad(srchBox,0,0,12,12)
    Img(srchBox,A.SEARCH,UDim2.new(0,18,0,18),UDim2.new(0,0,0.5,-9),SP.MUTED)
    local srchInput = N("TextBox",{
        Size=UDim2.new(1,-36,1,0),
        Position=UDim2.new(0,28,0,0),
        BackgroundTransparency=1,
        Text="",
        PlaceholderText="Search songs, artists...",
        TextColor3=SP.WHITE,
        PlaceholderColor3=SP.MUTED,
        Font=Enum.Font.Gotham,
        TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false,
    },srchBox)

    -- Search result placeholder rows
    local function addSongRow(parent, order, title, artist, duration)
        local row = N("Frame",{
            Size=UDim2.new(1,0,0,56),
            BackgroundTransparency=1,
            BorderSizePixel=0,
            LayoutOrder=order,
        },parent)
        local thumb = N("Frame",{Size=UDim2.new(0,40,0,40),Position=UDim2.new(0,0,0.5,-20),BackgroundColor3=SP.CARD2,BorderSizePixel=0},row)
        Corner(thumb,UDim.new(0,4))
        Img(thumb,A.MUSIC_NOTE,UDim2.new(0.6,0,0.6,0),UDim2.new(0.2,0,0.2,0),SP.MUTED)
        local meta=N("Frame",{Size=UDim2.new(1,-100,0,40),Position=UDim2.new(0,50,0.5,-20),BackgroundTransparency=1},row)
        Lbl(meta,title,UDim2.new(1,0,0,20),SP.WHITE,Enum.Font.GothamBold,13)
        Lbl(meta,artist,UDim2.new(1,0,0,16),SP.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,20)
        Lbl(row,duration,UDim2.new(0,40,1,0),SP.MUTED,Enum.Font.Gotham,12).Position=UDim2.new(1,-46,0,0)
        local hbtn=ImgBtn(row,A.HEART,UDim2.new(0,22,0,22),SP.MUTED)
        hbtn.Position=UDim2.new(1,-68,0.5,-11)
        local moreBtn=ImgBtn(row,A.MORE,UDim2.new(0,20,0,20),SP.MUTED)
        moreBtn.Position=UDim2.new(1,-22,0.5,-10)
        local rbtn=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5,AutoButtonColor=false},row)
        rbtn.MouseEnter:Connect(function() tw(row,TI.f,{BackgroundColor3=SP.CARD}) end)
        rbtn.MouseLeave:Connect(function() tw(row,TI.f,{BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=1}) end)
        rbtn.MouseButton1Click:Connect(function()
            sessionStats.songsPlayed=sessionStats.songsPlayed+1
        end)
        return row
    end

    local placeholderSongs={
        {"Search for a song above","Enter title or YT link","0:00"},
        {"Your results appear here","Use the search bar","0:00"},
        {"Tap a song to play it","Powered by YMP","0:00"},
    }
    for i,s in ipairs(placeholderSongs) do
        addSongRow(srchList,i+1,s[1],s[2],s[3])
    end

    srchInput.FocusLost:Connect(function(enter)
        if enter and srchInput.Text~="" then
            sessionStats.searches=sessionStats.searches+1
        end
    end)

    -- ---- LIBRARY VIEW ----
    local libView = makeView()
    local libScroll = Scroll(libView,UDim2.new(1,0,1,0),nil,10)
    local libList = N("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},libScroll)
    List(libList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,0)

    Lbl(libList,"Your Library",UDim2.new(1,0,0,30),SP.WHITE,Enum.Font.GothamBold,18).LayoutOrder=1

    -- Filter chips
    local chipRow=N("Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,LayoutOrder=2},libList)
    local chipScroll=N("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X},chipRow)
    List(chipScroll,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Left,6)
    Pad(chipScroll,4,4,0,0)
    local chips={"All","Playlists","Albums","Artists","Downloaded"}
    local selectedChip=1
    local chipBtns={}
    for i,ch in ipairs(chips) do
        local cb=N("TextButton",{
            Size=UDim2.new(0,0,0,26),
            AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=i==1 and SP.WHITE or SP.CARD2,
            Text=" "..ch.." ",
            TextColor3=i==1 and SP.BG or SP.WHITE,
            Font=Enum.Font.GothamBold,
            TextSize=12,
            AutoButtonColor=false,
            BorderSizePixel=0,
            LayoutOrder=i,
        },chipScroll)
        Corner(cb,UDim.new(1,0))
        table.insert(chipBtns,cb)
        cb.MouseButton1Click:Connect(function()
            for j,btn2 in ipairs(chipBtns) do
                tw(btn2,TI.f,{BackgroundColor3=j==i and SP.WHITE or SP.CARD2,TextColor3=j==i and SP.BG or SP.WHITE})
            end
            selectedChip=i
        end)
    end

    -- Library list items
    local libItems={
        {name="Liked Songs", count="0 songs", col=Color3.fromRGB(30,20,80)},
        {name="Downloaded",  count="0 songs", col=Color3.fromRGB(20,60,40)},
        {name="My Playlist", count="0 songs", col=Color3.fromRGB(40,20,60)},
        {name="Favorites",   count="0 songs", col=Color3.fromRGB(60,30,20)},
    }
    for i,item in ipairs(libItems) do
        local row=N("Frame",{Size=UDim2.new(1,0,0,62),BackgroundTransparency=1,LayoutOrder=i+2},libList)
        local thumb=N("Frame",{Size=UDim2.new(0,50,0,50),Position=UDim2.new(0,0,0.5,-25),BackgroundColor3=item.col,BorderSizePixel=0},row)
        Corner(thumb,UDim.new(0,8))
        Img(thumb,A.MUSIC_NOTE,UDim2.new(0.6,0,0.6,0),UDim2.new(0.2,0,0.2,0),Color3.fromRGB(120,120,120))
        local meta=N("Frame",{Size=UDim2.new(1,-60,0,50),Position=UDim2.new(0,58,0.5,-25),BackgroundTransparency=1},row)
        Lbl(meta,item.name,UDim2.new(1,0,0,22),SP.WHITE,Enum.Font.GothamBold,14)
        Lbl(meta,"Playlist - "..item.count,UDim2.new(1,0,0,16),SP.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,24)
        local rbtn=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5,AutoButtonColor=false},row)
        rbtn.MouseEnter:Connect(function() tw(row,TI.f,{BackgroundColor3=SP.CARD,BackgroundTransparency=0}) end)
        rbtn.MouseLeave:Connect(function() tw(row,TI.f,{BackgroundTransparency=1}) end)
    end

    -- ---- CONFIG VIEW ----
    local cfgView = makeView()
    local cfgScroll = Scroll(cfgView,UDim2.new(1,0,1,0),nil,12)
    local cfgList = N("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},cfgScroll)
    List(cfgList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,8)

    local function cfgSection(txt, order)
        local f=N("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=order},cfgList)
        Lbl(f,txt,UDim2.new(1,0,1,0),SP.ACCENT,Enum.Font.GothamBold,11)
        return f
    end
    local function cfgRow(title, sub, order)
        local row=N("Frame",{Size=UDim2.new(1,0,0,58),BackgroundColor3=SP.CARD,BorderSizePixel=0,LayoutOrder=order},cfgList)
        Corner(row,UDim.new(0,8))
        Pad(row,0,0,12,12)
        Lbl(row,title,UDim2.new(1,-60,0,20),SP.WHITE,Enum.Font.GothamBold,13)
        local sl=Lbl(row,sub,UDim2.new(1,-60,0,16),SP.MUTED,Enum.Font.Gotham,11)
        sl.Position=UDim2.new(0,0,0,22); sl.TextWrapped=true
        return row
    end

    cfgSection("PROFILE",1)
    local infoRow=cfgRow(LP.DisplayName.." (@"..LP.Name..")",
        "ID: "..LP.UserId.."  |  Age: "..LP.AccountAge.."d  |  HWID: "..tostring(hwid_):sub(1,20).."...",2)

    cfgSection("PLATFORM",3)
    local switchRow=N("Frame",{Size=UDim2.new(1,0,0,66),BackgroundColor3=SP.CARD,BorderSizePixel=0,LayoutOrder=4},cfgList)
    Corner(switchRow,UDim.new(0,8))
    Pad(switchRow,12,12,12,12)
    Lbl(switchRow,"Switch to YouTube",UDim2.new(1,0,0,20),SP.WHITE,Enum.Font.GothamBold,14)
    Lbl(switchRow,"Open the YouTube-style video interface",UDim2.new(1,0,0,14),SP.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,22)
    local ytSwBtn=N("TextButton",{
        Size=UDim2.new(0,160,0,30),
        Position=UDim2.new(0,0,0,36),
        BackgroundColor3=Color3.fromRGB(255,0,0),
        Text="Switch to YouTube",
        TextColor3=Color3.new(1,1,1),
        Font=Enum.Font.GothamBold,
        TextSize=12,
        AutoButtonColor=false,
        BorderSizePixel=0,
    },switchRow)
    Corner(ytSwBtn,UDim.new(0,6))
    ytSwBtn.MouseButton1Click:Connect(function()
        tw(win,TI.m,{Size=UDim2.new(0,0,0,0)}); task.wait(0.28)
        sg:Destroy()
        onSwitch("youtube")
    end)

    cfgSection("SCRIPT INFO",5)
    local infoCard=cfgRow("Yuno Player  v2.0","YouTube Music Player hub with Spotify and YouTube interfaces. Use YMP window for playback.",6)

    -- Server info rows
    cfgSection("SERVER",7)
    local srvData={
        {"Game",tostring(game.Name)},
        {"Game ID",tostring(game.GameId)},
        {"Place ID",tostring(game.PlaceId)},
        {"Job ID",(game.JobId or "N/A"):sub(1,24)},
        {"Players",tostring(#Players:GetPlayers()).."/"..tostring(Players.MaxPlayers)},
    }
    for i,d in ipairs(srvData) do
        local r=cfgRow(d[1],d[2],7+i)
        local cpBtn=N("TextButton",{
            Size=UDim2.new(0,50,0,22),
            Position=UDim2.new(1,-52,0.5,-11),
            BackgroundColor3=SP.CARD2,
            Text="Copy",
            TextColor3=SP.GREY,
            Font=Enum.Font.Gotham,
            TextSize=11,
            AutoButtonColor=false,
            BorderSizePixel=0,
        },r)
        Corner(cpBtn,UDim.new(0,4))
        local captured=d[2]
        cpBtn.MouseButton1Click:Connect(function()
            if clip_ then pcall(clip_,captured) end
            notify("Copied",captured)
        end)
    end

    -- ---- BOTTOM NAV BAR ----
    local navBar = N("Frame",{
        Size=UDim2.new(1,0,0,52),
        Position=UDim2.new(0,0,1,-52),
        BackgroundColor3=SP.NAV,
        BorderSizePixel=0,
    },win)
    -- top line
    N("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.fromRGB(28,28,28),BorderSizePixel=0},navBar)

    local navItems={
        {icon=A.HOME,    label="Home",    view=homeView,  idx=1},
        {icon=A.SEARCH,  label="Search",  view=searchView,idx=2},
        {icon=A.LIBRARY, label="Library", view=libView,   idx=3},
        {icon=A.SETTINGS,label="Config",  view=cfgView,   idx=4},
    }
    local selectedNav=1

    local function setNav(idx)
        selectedNav=idx
        for i,item in ipairs(views) do
            item.Visible=(i==idx)
        end
    end

    for i,nav in ipairs(navItems) do
        local navBtn=N("TextButton",{
            Size=UDim2.new(0.25,0,1,0),
            Position=UDim2.new((i-1)*0.25,0,0,0),
            BackgroundTransparency=1,
            Text="",
            AutoButtonColor=false,
        },navBar)
        local ic=Img(navBtn,nav.icon,UDim2.new(0,22,0,22),
            UDim2.new(0.5,-11,0,6),
            i==1 and SP.ACCENT or SP.MUTED)
        local nl=Lbl(navBtn,nav.label,UDim2.new(1,0,0,14),
            i==1 and SP.ACCENT or SP.MUTED,Enum.Font.Gotham,10)
        nl.Position=UDim2.new(0,0,0,30)
        nl.TextXAlignment=Enum.TextXAlignment.Center
        navBtn.MouseButton1Click:Connect(function()
            for j,ni in ipairs(navItems) do
                local color = j==i and SP.ACCENT or SP.MUTED
                -- find icon and label in navBtn
            end
            -- update colors via stored refs
            setNav(i)
            -- visual update
            for j,nb in ipairs(navBar:GetChildren()) do
                if nb:IsA("TextButton") then
                    local jj=j
                    for _,ch in ipairs(nb:GetChildren()) do
                        if ch:IsA("ImageLabel") then
                            tw(ch,TI.f,{ImageColor3=jj==i and SP.ACCENT or SP.MUTED})
                        elseif ch:IsA("TextLabel") then
                            tw(ch,TI.f,{TextColor3=jj==i and SP.ACCENT or SP.MUTED})
                        end
                    end
                end
            end
        end)
    end

    -- NOW PLAYING BAR (mini player pinned above nav)
    local npBar = N("Frame",{
        Size=UDim2.new(1,-16,0,56),
        Position=UDim2.new(0,8,1,-116),
        BackgroundColor3=Color3.fromRGB(28,28,28),
        BorderSizePixel=0,
    },win)
    Corner(npBar,UDim.new(0,10))
    Pad(npBar,0,0,10,10)

    -- Album art mini
    local npArt=N("Frame",{Size=UDim2.new(0,40,0,40),Position=UDim2.new(0,0,0.5,-20),BackgroundColor3=Color3.fromRGB(40,40,60),BorderSizePixel=0},npBar)
    Corner(npArt,UDim.new(0,6))
    Img(npArt,A.MUSIC_NOTE,UDim2.new(0.6,0,0.6,0),UDim2.new(0.2,0,0.2,0),SP.MUTED)

    local npMeta=N("Frame",{Size=UDim2.new(1,-130,0,40),Position=UDim2.new(0,50,0.5,-20),BackgroundTransparency=1},npBar)
    local npTitle=Lbl(npMeta,"Nothing playing",UDim2.new(1,0,0,20),SP.WHITE,Enum.Font.GothamBold,13)
    Lbl(npMeta,"Select a song",UDim2.new(1,0,0,14),SP.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,22)

    local npHeart=ImgBtn(npBar,A.HEART,UDim2.new(0,24,0,24),SP.MUTED)
    npHeart.Position=UDim2.new(1,-80,0.5,-12)
    local npPlay=ImgBtn(npBar,A.PLAY,UDim2.new(0,28,0,28),SP.WHITE)
    npPlay.Position=UDim2.new(1,-42,0.5,-14)

    -- Progress line under mini player
    local npProgBg=N("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=Color3.fromRGB(50,50,50),BorderSizePixel=0},npBar)
    local npProg=N("Frame",{Size=UDim2.new(0.2,0,1,0),BackgroundColor3=SP.ACCENT,BorderSizePixel=0},npProgBg)

    -- Entrance animation
    win.Size=UDim2.new(0,0,0,0)
    tw(win,TI.b,{Size=UDim2.new(0,WIN_W,0,WIN_H)})

    -- YMP loadstring
    task.spawn(function()
        task.wait(0.6)
        pcall(function()
            loadstring(game:HttpGet(YMP_URL,true))()
        end)
        notify("Music Ready","YouTube Music Player loaded. Use YMP window to play songs.")
    end)
end

-- ============================================================
--  YOUTUBE UI
-- ============================================================
local function buildYouTube(onSwitch)
    destroyActive()
    local sg = N("ScreenGui",{Name="YunoHub",IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},CoreGui)
    activeSG = sg

    local WIN_W, WIN_H = 400, 640
    local win = N("Frame",{
        Size=UDim2.new(0,WIN_W,0,WIN_H),
        Position=UDim2.new(0.5,0,0.5,0),
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundColor3=YT.BG,
        BorderSizePixel=0,
        ClipsDescendants=true,
    },sg)
    Corner(win,UDim.new(0,16))
    Drag(win,win)

    -- TOP BAR (YouTube style)
    local topBar = N("Frame",{
        Size=UDim2.new(1,0,0,48),
        BackgroundColor3=YT.TOPBAR,
        BorderSizePixel=0,
    },win)
    N("Frame",{Size=UDim2.new(1,0,0,24),Position=UDim2.new(0,0,1,-24),BackgroundColor3=YT.TOPBAR,BorderSizePixel=0},topBar)
    -- YT logo (drawn: white rect + red rect)
    local ytIconFrame = N("Frame",{Size=UDim2.new(0,30,0,22),Position=UDim2.new(0,10,0,13),BackgroundTransparency=1},topBar)
    local ytRedBox=N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=YT.RED,BorderSizePixel=0},ytIconFrame)
    Corner(ytRedBox,UDim.new(0,6))
    -- Play triangle drawn as rotated frame
    local ytPlay=N("Frame",{Size=UDim2.new(0,10,0,12),Position=UDim2.new(0.5,-3,0.5,-6),BackgroundColor3=YT.WHITE,BorderSizePixel=0},ytIconFrame)
    Corner(ytPlay,UDim.new(0,2))
    Lbl(topBar,"Yuno Player",UDim2.new(0,120,0,26),YT.WHITE,Enum.Font.GothamBold,15).Position=UDim2.new(0,50,0,11)

    -- Search
    local topSearch = N("Frame",{
        Size=UDim2.new(0,160,0,30),
        Position=UDim2.new(0.5,-80,0,9),
        BackgroundColor3=YT.SURFACE,
        BorderSizePixel=0,
    },topBar)
    Corner(topSearch,UDim.new(1,0))
    Stroke(topSearch,Color3.fromRGB(50,50,50),1)
    local topInput = N("TextBox",{
        Size=UDim2.new(1,-32,1,0),
        Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1,
        Text="",
        PlaceholderText="Search...",
        TextColor3=YT.WHITE,
        PlaceholderColor3=YT.MUTED,
        Font=Enum.Font.Gotham,
        TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false,
    },topSearch)
    local topSearchIcon=ImgBtn(topSearch,A.SEARCH,UDim2.new(0,18,0,18),YT.MUTED)
    topSearchIcon.Position=UDim2.new(1,-22,0.5,-9)
    topInput.FocusLost:Connect(function(e) if e and topInput.Text~="" then sessionStats.searches=sessionStats.searches+1 end end)

    -- Right icons
    local topRight=N("Frame",{Size=UDim2.new(0,60,1,0),Position=UDim2.new(1,-64,0,0),BackgroundTransparency=1},topBar)
    Pad(topRight,0,0,0,6)
    local moreBtn=ImgBtn(topRight,A.MORE,UDim2.new(0,22,0,22),YT.GREY)
    moreBtn.Position=UDim2.new(0,0,0.5,-11)
    local closeBtn=ImgBtn(topRight,A.CLOSE,UDim2.new(0,22,0,22),YT.GREY)
    closeBtn.Position=UDim2.new(0,26,0.5,-11)
    closeBtn.MouseButton1Click:Connect(function()
        tw(win,TI.m,{Size=UDim2.new(0,0,0,0)}); task.wait(0.28); sg:Destroy()
    end)

    -- Profile + stat bars
    local profBar=buildProfileBar(win,YT.RED)
    profBar.Position=UDim2.new(0,0,0,48)
    local statBar=buildStatBar(win,"youtube")
    statBar.Position=UDim2.new(0,0,0,102)

    -- TABS: Home | Watch | Search | Config
    local BODY_TOP=140
    local BODY_H=WIN_H-BODY_TOP-52

    local tabBar=N("Frame",{
        Size=UDim2.new(1,0,0,38),
        Position=UDim2.new(0,0,0,BODY_TOP),
        BackgroundColor3=YT.TOPBAR,
        BorderSizePixel=0,
    },win)
    N("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.fromRGB(35,35,35),BorderSizePixel=0},tabBar)

    local body=N("Frame",{
        Size=UDim2.new(1,0,0,BODY_H-38),
        Position=UDim2.new(0,0,0,BODY_TOP+38),
        BackgroundTransparency=1,
        ClipsDescendants=true,
    },win)

    local ytViews={}
    local function makeYTView()
        local v=N("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false},body)
        table.insert(ytViews,v)
        return v
    end
    local function setYTView(idx)
        for i,v in ipairs(ytViews) do v.Visible=(i==idx) end
    end

    -- Tab bar buttons
    local ytTabs={"Home","Watch","Search","Config"}
    local ytTabBtns={}
    for i,name in ipairs(ytTabs) do
        local tbBtn=N("TextButton",{
            Size=UDim2.new(0.25,0,1,-1),
            Position=UDim2.new((i-1)*0.25,0,0,0),
            BackgroundTransparency=1,
            Text=name,
            TextColor3=i==1 and YT.WHITE or YT.MUTED,
            Font=Enum.Font.GothamBold,
            TextSize=12,
            AutoButtonColor=false,
            BorderSizePixel=0,
        },tabBar)
        -- active underline
        local underline=N("Frame",{
            Size=UDim2.new(0.6,0,0,2),
            Position=UDim2.new(0.2,0,1,-2),
            BackgroundColor3=YT.RED,
            BackgroundTransparency=i==1 and 0 or 1,
            BorderSizePixel=0,
        },tbBtn)
        table.insert(ytTabBtns,{btn=tbBtn,line=underline})
        tbBtn.MouseButton1Click:Connect(function()
            for j,tb in ipairs(ytTabBtns) do
                tw(tb.btn,TI.f,{TextColor3=j==i and YT.WHITE or YT.MUTED})
                tw(tb.line,TI.f,{BackgroundTransparency=j==i and 0 or 1})
            end
            setYTView(i)
        end)
    end

    -- ---- YT HOME VIEW ----
    local ytHome=makeYTView()
    ytHome.Visible=true
    local ytHomeScroll=Scroll(ytHome,UDim2.new(1,0,1,0),nil,0)
    local ytHomeList=N("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},ytHomeScroll)
    List(ytHomeList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,0)
    Pad(ytHomeList,0,10,0,0)

    -- Filter chips (YouTube style)
    local chipScrollYT=N("ScrollingFrame",{
        Size=UDim2.new(1,0,0,40),
        BackgroundColor3=YT.BG,
        BorderSizePixel=0,
        ScrollBarThickness=0,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.X,
        ScrollingDirection=Enum.ScrollingDirection.X,
        LayoutOrder=1,
    },ytHomeList)
    Pad(chipScrollYT,6,6,10,10)
    List(chipScrollYT,Enum.FillDirection.Horizontal,Enum.HorizontalAlignment.Left,8)
    local ytChips={"All","Music","Gaming","News","Live","Tech"}
    local selYTChip=1
    local ytChipBtns={}
    for i,ch in ipairs(ytChips) do
        local cb=N("TextButton",{
            Size=UDim2.new(0,0,1,-12),
            AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=i==1 and YT.WHITE or YT.SURFACE,
            Text=" "..ch.." ",
            TextColor3=i==1 and YT.BG or YT.WHITE,
            Font=Enum.Font.GothamBold,
            TextSize=12,
            AutoButtonColor=false,
            BorderSizePixel=0,
            LayoutOrder=i,
        },chipScrollYT)
        Corner(cb,UDim.new(1,0))
        table.insert(ytChipBtns,cb)
        cb.MouseButton1Click:Connect(function()
            for j,b in ipairs(ytChipBtns) do
                tw(b,TI.f,{BackgroundColor3=j==i and YT.WHITE or YT.SURFACE,TextColor3=j==i and YT.BG or YT.WHITE})
            end
        end)
    end

    -- Video feed cards
    local function videoCard(parent, order, title, channel, views, dur, thumbColor)
        local card=N("Frame",{
            Size=UDim2.new(1,0,0,0),
            BackgroundTransparency=1,
            BorderSizePixel=0,
            LayoutOrder=order,
            AutomaticSize=Enum.AutomaticSize.Y,
        },parent)

        -- Thumbnail
        local thumb=N("Frame",{
            Size=UDim2.new(1,0,0,200),
            BackgroundColor3=thumbColor or YT.SURFACE,
            BorderSizePixel=0,
        },card)
        Img(thumb,A.VIDEO_I,UDim2.new(0,52,0,52),UDim2.new(0.5,-26,0.5,-26),Color3.fromRGB(55,55,55))
        -- Duration badge
        local durBadge=N("Frame",{
            Size=UDim2.new(0,0,0,18),
            Position=UDim2.new(1,-6,1,-24),
            AnchorPoint=Vector2.new(1,0),
            AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=Color3.fromRGB(0,0,0),
            BackgroundTransparency=0.3,
            BorderSizePixel=0,
        },thumb)
        Corner(durBadge,UDim.new(0,3))
        Pad(durBadge,0,0,4,4)
        Lbl(durBadge,dur,UDim2.new(0,0,1,0),YT.WHITE,Enum.Font.GothamBold,11).AutomaticSize=Enum.AutomaticSize.X

        -- Meta row below thumb
        local meta=N("Frame",{
            Size=UDim2.new(1,0,0,70),
            BackgroundTransparency=1,
        },card)
        Pad(meta,8,8,10,10)
        -- Channel avatar
        local chAv=N("Frame",{Size=UDim2.new(0,34,0,34),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(60,60,60),BorderSizePixel=0},meta)
        Corner(chAv,UDim.new(1,0))
        Lbl(chAv,channel:sub(1,1):upper(),UDim2.new(1,0,1,0),YT.WHITE,Enum.Font.GothamBold,14).TextXAlignment=Enum.TextXAlignment.Center
        -- Title + info
        local textArea=N("Frame",{Size=UDim2.new(1,-50,0,60),Position=UDim2.new(0,44,0,0),BackgroundTransparency=1},meta)
        local tl=Lbl(textArea,title,UDim2.new(1,0,0,0),YT.WHITE,Enum.Font.GothamBold,13)
        tl.TextWrapped=true; tl.AutomaticSize=Enum.AutomaticSize.Y
        Lbl(textArea,channel.."  •  "..views.." views",UDim2.new(1,0,0,14),YT.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,32)
        ImgBtn(meta,A.MORE,UDim2.new(0,20,0,20),YT.MUTED).Position=UDim2.new(1,-22,0,2)

        -- Click to count
        local rbtn=N("TextButton",{Size=UDim2.new(1,0,0,200),BackgroundTransparency=1,Text="",ZIndex=5,AutoButtonColor=false},card)
        rbtn.MouseButton1Click:Connect(function()
            sessionStats.videosPlayed=sessionStats.videosPlayed+1
            notify("Now Playing",title)
        end)
        return card
    end

    local feedColors={
        Color3.fromRGB(20,30,50),
        Color3.fromRGB(35,20,20),
        Color3.fromRGB(20,40,30),
        Color3.fromRGB(40,30,20),
        Color3.fromRGB(25,25,45),
    }
    local feedData={
        {"Use search to find videos","YouTube Channel","0 views","0:00"},
        {"Results appear in Watch tab","Creator Studio","0 views","0:00"},
        {"Paste a YT link to play","YMP Integration","0 views","0:00"},
    }
    for i,d in ipairs(feedData) do
        videoCard(ytHomeList,i+1,d[1],d[2],d[3],d[4],feedColors[i])
    end

    -- ---- YT WATCH VIEW ----
    local ytWatch=makeYTView()
    local wtScroll=Scroll(ytWatch,UDim2.new(1,0,1,0),nil,0)
    local wtList=N("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},wtScroll)
    List(wtList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,0)

    -- Video player area
    local videoArea=N("Frame",{
        Size=UDim2.new(1,0,0,215),
        BackgroundColor3=Color3.fromRGB(5,5,5),
        BorderSizePixel=0,
        LayoutOrder=1,
    },wtList)
    Img(videoArea,A.VIDEO_I,UDim2.new(0,54,0,54),UDim2.new(0.5,-27,0.5,-40),Color3.fromRGB(40,40,40))
    Lbl(videoArea,"No video selected",UDim2.new(1,0,0,20),YT.MUTED,Enum.Font.Gotham,13).Position=UDim2.new(0,0,0.5,22)

    -- Video controls overlay (bottom of video)
    local vCtrl=N("Frame",{
        Size=UDim2.new(1,0,0,40),
        Position=UDim2.new(0,0,1,-40),
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.5,
        BorderSizePixel=0,
    },videoArea)
    -- Progress bar
    local vpBg=N("Frame",{Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(80,80,80),BorderSizePixel=0},vCtrl)
    local vpFill=N("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=YT.RED,BorderSizePixel=0},vpBg)
    -- Controls row
    Pad(vCtrl,4,4,8,8)
    local vPlayBtn=ImgBtn(vCtrl,A.PLAY,UDim2.new(0,24,0,24),YT.WHITE)
    vPlayBtn.Position=UDim2.new(0,0,0,8)
    Lbl(vCtrl,"0:00 / 0:00",UDim2.new(0,80,0,24),YT.WHITE,Enum.Font.Gotham,11).Position=UDim2.new(0,30,0,8)
    local vFullBtn=ImgBtn(vCtrl,A.FULLSCREEN,UDim2.new(0,22,0,22),YT.WHITE)
    vFullBtn.Position=UDim2.new(1,-26,0,9)
    local vCCBtn=ImgBtn(vCtrl,A.CC,UDim2.new(0,22,0,22),YT.WHITE)
    vCCBtn.Position=UDim2.new(1,-52,0,9)
    local vCastBtn=ImgBtn(vCtrl,A.CAST,UDim2.new(0,22,0,22),YT.WHITE)
    vCastBtn.Position=UDim2.new(1,-78,0,9)

    -- Video meta section
    local vMeta=N("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundColor3=YT.BG,
        BorderSizePixel=0,
        LayoutOrder=2,
        AutomaticSize=Enum.AutomaticSize.Y,
    },wtList)
    Pad(vMeta,10,10,12,12)
    local vtitle=Lbl(vMeta,"Select a video from the feed",UDim2.new(1,0,0,0),YT.WHITE,Enum.Font.GothamBold,15)
    vtitle.TextWrapped=true; vtitle.AutomaticSize=Enum.AutomaticSize.Y
    Lbl(vMeta,"0 views  •  0 likes",UDim2.new(1,0,0,16),YT.MUTED,Enum.Font.Gotham,12).Position=UDim2.new(0,0,0,38)

    -- Actions row (like, dislike, share, save)
    local actRow=N("Frame",{
        Size=UDim2.new(1,0,0,44),
        Position=UDim2.new(0,0,0,60),
        BackgroundTransparency=1,
    },vMeta)
    vMeta.Size=UDim2.new(1,0,0,112)

    local actItems={
        {A.THUMB_UP,"0","Like"},
        {A.THUMB_DOWN,"","Dislike"},
        {A.SHARE,"Share","Share"},
        {A.DOWNLOAD,"Download","Save"},
        {A.MORE,"More","More"},
    }
    for i,act in ipairs(actItems) do
        local af=N("Frame",{
            Size=UDim2.new(0,60,1,0),
            Position=UDim2.new(0,(i-1)*66,0,0),
            BackgroundColor3=YT.SURFACE,
            BorderSizePixel=0,
        },actRow)
        Corner(af,UDim.new(1,0))
        Pad(af,0,0,8,8)
        local ic=Img(af,act[1],UDim2.new(0,18,0,18),UDim2.new(0,0,0.5,-9),YT.GREY)
        Lbl(af,act[2]=="" and act[3] or act[2],UDim2.new(1,-26,1,0),YT.GREY,Enum.Font.Gotham,11).Position=UDim2.new(0,24,0,0)
        local ab=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5,AutoButtonColor=false},af)
        ab.MouseEnter:Connect(function() tw(af,TI.f,{BackgroundColor3=YT.CARD}) end)
        ab.MouseLeave:Connect(function() tw(af,TI.f,{BackgroundColor3=YT.SURFACE}) end)
    end

    -- Channel row
    local chRow=N("Frame",{
        Size=UDim2.new(1,0,0,52),
        BackgroundColor3=YT.BG,
        BorderSizePixel=0,
        LayoutOrder=3,
    },wtList)
    Stroke(chRow,Color3.fromRGB(30,30,30),1)
    Pad(chRow,0,0,12,12)
    local chAv2=N("Frame",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,0,0.5,-18),BackgroundColor3=Color3.fromRGB(60,60,60),BorderSizePixel=0},chRow)
    Corner(chAv2,UDim.new(1,0))
    Lbl(chAv2,"C",UDim2.new(1,0,1,0),YT.WHITE,Enum.Font.GothamBold,16).TextXAlignment=Enum.TextXAlignment.Center
    local chNameLbl=Lbl(chRow,"Channel Name",UDim2.new(0,130,0,20),YT.WHITE,Enum.Font.GothamBold,13)
    chNameLbl.Position=UDim2.new(0,44,0,8)
    Lbl(chRow,"0 subscribers",UDim2.new(0,100,0,14),YT.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,44,0,28)
    local subBtn=N("TextButton",{
        Size=UDim2.new(0,90,0,32),
        Position=UDim2.new(1,-92,0.5,-16),
        BackgroundColor3=YT.WHITE,
        Text="Subscribe",
        TextColor3=YT.BG,
        Font=Enum.Font.GothamBold,
        TextSize=12,
        AutoButtonColor=false,
        BorderSizePixel=0,
    },chRow)
    Corner(subBtn,UDim.new(1,0))

    -- Comments section
    local commSection=N("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundColor3=YT.BG,
        BorderSizePixel=0,
        LayoutOrder=4,
        AutomaticSize=Enum.AutomaticSize.Y,
    },wtList)
    Pad(commSection,10,10,12,12)
    local commHeader=N("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1},commSection)
    Lbl(commHeader,"Comments",UDim2.new(0,100,1,0),YT.WHITE,Enum.Font.GothamBold,14)
    Lbl(commHeader,"51",UDim2.new(0,30,1,0),YT.MUTED,Enum.Font.Gotham,13).Position=UDim2.new(0,106,0,0)

    -- Sample comment rows
    local sampleComments={
        {"User1","hope you reach good views"},
        {"User2","great video!"},
        {"User3","thanks for the tutorial"},
    }
    for i,c in ipairs(sampleComments) do
        local crow=N("Frame",{
            Size=UDim2.new(1,0,0,52),
            Position=UDim2.new(0,0,0,28+(i-1)*58),
            BackgroundTransparency=1,
        },commSection)
        commSection.Size=UDim2.new(1,0,0,28+#sampleComments*58+10)
        local cav=N("Frame",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(60,60,60),BorderSizePixel=0},crow)
        Corner(cav,UDim.new(1,0))
        Lbl(cav,c[1]:sub(1,1),UDim2.new(1,0,1,0),YT.WHITE,Enum.Font.GothamBold,13).TextXAlignment=Enum.TextXAlignment.Center
        local cmeta=N("Frame",{Size=UDim2.new(1,-40,0,50),Position=UDim2.new(0,38,0,0),BackgroundTransparency=1},crow)
        Lbl(cmeta,c[1],UDim2.new(1,0,0,16),YT.WHITE,Enum.Font.GothamBold,12)
        Lbl(cmeta,c[2],UDim2.new(1,0,0,16),YT.GREY,Enum.Font.Gotham,12).Position=UDim2.new(0,0,0,18)
        local clikesRow=N("Frame",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,36),BackgroundTransparency=1},cmeta)
        ImgBtn(clikesRow,A.THUMB_UP,UDim2.new(0,14,0,14),YT.MUTED).Position=UDim2.new(0,0,0,2)
        Lbl(clikesRow,"0",UDim2.new(0,20,1,0),YT.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,18,0,0)
    end

    -- Settings sheet bottom (YouTube settings sheet style)
    local function showSettingsSheet()
        local sheet=N("Frame",{
            Size=UDim2.new(1,0,0,0),
            Position=UDim2.new(0,0,1,0),
            BackgroundColor3=YT.SURFACE,
            BorderSizePixel=0,
            ZIndex=10,
        },win)
        Corner(sheet,UDim.new(0,16))
        -- handle bar
        local handle=N("Frame",{
            Size=UDim2.new(0,36,0,4),
            Position=UDim2.new(0.5,-18,0,8),
            BackgroundColor3=Color3.fromRGB(80,80,80),
            BorderSizePixel=0,
        },sheet)
        Corner(handle,UDim.new(1,0))
        local shList=N("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},sheet)
        List(shList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,0)
        Pad(shList,20,20,0,0)

        local shItems={
            {A.QUALITY,"Quality","Auto (720p)"},
            {A.SPEED,  "Playback speed","1x"},
            {A.CC,     "Subtitles","Off"},
            {A.LOCK,   "Lock screen",""},
            {A.SETTINGS,"More settings",""},
        }
        for i,si in ipairs(shItems) do
            local row=N("Frame",{
                Size=UDim2.new(1,0,0,52),
                BackgroundTransparency=1,
                BorderSizePixel=0,
                LayoutOrder=i,
            },shList)
            Pad(row,0,0,20,20)
            Img(row,si[1],UDim2.new(0,22,0,22),UDim2.new(0,0,0.5,-11),YT.WHITE)
            Lbl(row,si[2],UDim2.new(1,-80,0,22),YT.WHITE,Enum.Font.GothamBold,14).Position=UDim2.new(0,34,0.5,-11)
            if si[3]~="" then
                Lbl(row,si[3],UDim2.new(0,80,0,22),YT.MUTED,Enum.Font.Gotham,13).Position=UDim2.new(1,-80,0.5,-11)
            end
            N("Frame",{Size=UDim2.new(1,-40,0,1),Position=UDim2.new(0,20,1,-1),BackgroundColor3=Color3.fromRGB(40,40,40),BorderSizePixel=0},row)
            local rb=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=11,AutoButtonColor=false},row)
            rb.MouseEnter:Connect(function() tw(row,TI.f,{BackgroundColor3=YT.CARD,BackgroundTransparency=0}) end)
            rb.MouseLeave:Connect(function() tw(row,TI.f,{BackgroundTransparency=1}) end)
        end
        sheet.Size=UDim2.new(1,0,0,#shItems*52+40)
        tw(sheet,TI.m,{Position=UDim2.new(0,0,1,-(#shItems*52+40))})

        -- tap outside to dismiss
        local overlay=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=9},win)
        overlay.MouseButton1Click:Connect(function()
            tw(sheet,TI.m,{Position=UDim2.new(0,0,1,0)})
            task.wait(0.28); sheet:Destroy(); overlay:Destroy()
        end)
    end

    -- Hook more button to settings sheet
    moreBtn.MouseButton1Click:Connect(showSettingsSheet)

    -- ---- YT SEARCH VIEW ----
    local ytSearch=makeYTView()
    local ysScroll=Scroll(ytSearch,UDim2.new(1,0,1,0),nil,10)
    local ysList=N("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},ysScroll)
    List(ysList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,0)

    local srchBox2=N("Frame",{
        Size=UDim2.new(1,0,0,40),
        BackgroundColor3=YT.SURFACE,
        BorderSizePixel=0,
        LayoutOrder=1,
    },ysList)
    Corner(srchBox2,UDim.new(1,0))
    Pad(srchBox2,0,0,14,14)
    Stroke(srchBox2,Color3.fromRGB(55,55,55),1)
    Img(srchBox2,A.SEARCH,UDim2.new(0,18,0,18),UDim2.new(0,0,0.5,-9),YT.MUTED)
    local srchInput2=N("TextBox",{
        Size=UDim2.new(1,-36,1,0),
        Position=UDim2.new(0,28,0,0),
        BackgroundTransparency=1,
        Text="",
        PlaceholderText="Search YouTube...",
        TextColor3=YT.WHITE,
        PlaceholderColor3=YT.MUTED,
        Font=Enum.Font.Gotham,
        TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false,
    },srchBox2)
    srchInput2.FocusLost:Connect(function(e)
        if e and srchInput2.Text~="" then sessionStats.searches=sessionStats.searches+1 end
    end)

    -- Placeholder results
    for i=1,3 do
        local row=N("Frame",{Size=UDim2.new(1,0,0,90),BackgroundTransparency=1,LayoutOrder=i+1},ysList)
        local thumb=N("Frame",{Size=UDim2.new(0,140,0,78),Position=UDim2.new(0,0,0.5,-39),BackgroundColor3=YT.SURFACE,BorderSizePixel=0},row)
        Corner(thumb,UDim.new(0,6))
        Img(thumb,A.VIDEO_I,UDim2.new(0,36,0,36),UDim2.new(0.5,-18,0.5,-18),Color3.fromRGB(50,50,50))
        local meta=N("Frame",{Size=UDim2.new(1,-150,0,78),Position=UDim2.new(0,148,0.5,-39),BackgroundTransparency=1},row)
        Lbl(meta,"Search result "..i,UDim2.new(1,0,0,20),YT.WHITE,Enum.Font.GothamBold,13)
        Lbl(meta,"Channel  •  0 views",UDim2.new(1,0,0,14),YT.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,22)
        Lbl(meta,"0:00",UDim2.new(1,0,0,14),YT.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,38)
        local rbtn=N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=5,AutoButtonColor=false},row)
        rbtn.MouseEnter:Connect(function() tw(row,TI.f,{BackgroundColor3=YT.SURFACE,BackgroundTransparency=0}) end)
        rbtn.MouseLeave:Connect(function() tw(row,TI.f,{BackgroundTransparency=1}) end)
        rbtn.MouseButton1Click:Connect(function()
            sessionStats.videosPlayed=sessionStats.videosPlayed+1
        end)
    end

    -- ---- YT CONFIG VIEW ----
    local ytCfg=makeYTView()
    local ycScroll=Scroll(ytCfg,UDim2.new(1,0,1,0),nil,12)
    local ycList=N("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y},ycScroll)
    List(ycList,Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,8)

    local function yCfgSec(txt,order)
        local f=N("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,LayoutOrder=order},ycList)
        Lbl(f,txt,UDim2.new(1,0,1,0),YT.RED,Enum.Font.GothamBold,11)
        return f
    end
    local function yCfgRow(title,sub,order)
        local row=N("Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=YT.CARD,BorderSizePixel=0,LayoutOrder=order},ycList)
        Corner(row,UDim.new(0,8))
        Pad(row,0,0,12,12)
        Lbl(row,title,UDim2.new(1,-60,0,20),YT.WHITE,Enum.Font.GothamBold,13)
        local sl=Lbl(row,sub,UDim2.new(1,-60,0,16),YT.MUTED,Enum.Font.Gotham,11)
        sl.Position=UDim2.new(0,0,0,22); sl.TextWrapped=true
        return row
    end

    yCfgSec("PROFILE",1)
    yCfgRow(LP.DisplayName.." (@"..LP.Name..")","ID: "..LP.UserId.."  |  Age: "..LP.AccountAge.."d",2)

    yCfgSec("PLATFORM",3)
    local swRow=N("Frame",{Size=UDim2.new(1,0,0,70),BackgroundColor3=YT.CARD,BorderSizePixel=0,LayoutOrder=4},ycList)
    Corner(swRow,UDim.new(0,8))
    Pad(swRow,12,12,12,12)
    Lbl(swRow,"Switch to Spotify",UDim2.new(1,0,0,20),YT.WHITE,Enum.Font.GothamBold,14)
    Lbl(swRow,"Open the Spotify-style music interface",UDim2.new(1,0,0,14),YT.MUTED,Enum.Font.Gotham,11).Position=UDim2.new(0,0,0,22)
    local spSwBtn=N("TextButton",{
        Size=UDim2.new(0,150,0,30),
        Position=UDim2.new(0,0,0,38),
        BackgroundColor3=Color3.fromRGB(30,215,96),
        Text="Switch to Spotify",
        TextColor3=Color3.new(0,0,0),
        Font=Enum.Font.GothamBold,
        TextSize=12,
        AutoButtonColor=false,
        BorderSizePixel=0,
    },swRow)
    Corner(spSwBtn,UDim.new(0,6))
    spSwBtn.MouseButton1Click:Connect(function()
        tw(win,TI.m,{Size=UDim2.new(0,0,0,0)}); task.wait(0.28)
        sg:Destroy()
        onSwitch("spotify")
    end)

    yCfgSec("SERVER INFO",5)
    local srvData2={
        {"Game",tostring(game.Name)},
        {"Game ID",tostring(game.GameId)},
        {"Place ID",tostring(game.PlaceId)},
        {"Job ID",(game.JobId or "N/A"):sub(1,24)},
        {"Players",tostring(#Players:GetPlayers()).."/"..tostring(Players.MaxPlayers)},
        {"HWID",tostring(hwid_):sub(1,22)},
    }
    for i,d in ipairs(srvData2) do
        local r=yCfgRow(d[1],d[2],5+i)
        local cpBtn=N("TextButton",{
            Size=UDim2.new(0,50,0,22),
            Position=UDim2.new(1,-52,0.5,-11),
            BackgroundColor3=YT.SURFACE,
            Text="Copy",
            TextColor3=YT.GREY,
            Font=Enum.Font.Gotham,
            TextSize=11,
            AutoButtonColor=false,
            BorderSizePixel=0,
        },r)
        Corner(cpBtn,UDim.new(0,4))
        local captured=d[2]
        cpBtn.MouseButton1Click:Connect(function()
            if clip_ then pcall(clip_,captured) end
            notify("Copied",captured)
        end)
    end

    yCfgSec("PLAYERS",12)
    local allPlayers=Players:GetPlayers()
    for i,plr in ipairs(allPlayers) do
        local pr=yCfgRow(plr.DisplayName.." (@"..plr.Name..")",
            "ID: "..plr.UserId.."  |  Age: "..plr.AccountAge.."d",12+i)
        local cpBtn2=N("TextButton",{
            Size=UDim2.new(0,50,0,22),
            Position=UDim2.new(1,-52,0.5,-11),
            BackgroundColor3=YT.SURFACE,
            Text="Copy ID",
            TextColor3=YT.GREY,
            Font=Enum.Font.Gotham,
            TextSize=10,
            AutoButtonColor=false,
            BorderSizePixel=0,
        },pr)
        Corner(cpBtn2,UDim.new(0,4))
        local cid=tostring(plr.UserId)
        cpBtn2.MouseButton1Click:Connect(function()
            if clip_ then pcall(clip_,cid) end
            notify("Copied","User ID: "..cid)
        end)
    end

    -- ---- BOTTOM NAV ----
    local ytNav=N("Frame",{
        Size=UDim2.new(1,0,0,52),
        Position=UDim2.new(0,0,1,-52),
        BackgroundColor3=YT.TOPBAR,
        BorderSizePixel=0,
    },win)
    N("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.fromRGB(35,35,35),BorderSizePixel=0},ytNav)
    local ytNavItems={
        {A.HOME,"Home",1},
        {A.VIDEO_I,"Watch",2},
        {A.SEARCH,"Search",3},
        {A.SETTINGS,"Config",4},
    }
    for i,nav in ipairs(ytNavItems) do
        local nb=N("TextButton",{
            Size=UDim2.new(0.25,0,1,0),
            Position=UDim2.new((i-1)*0.25,0,0,0),
            BackgroundTransparency=1,Text="",AutoButtonColor=false
        },ytNav)
        local nic=Img(nb,nav[1],UDim2.new(0,22,0,22),UDim2.new(0.5,-11,0,6),
            i==1 and YT.WHITE or YT.MUTED)
        local nnl=Lbl(nb,nav[2],UDim2.new(1,0,0,12),i==1 and YT.WHITE or YT.MUTED,Enum.Font.Gotham,10)
        nnl.Position=UDim2.new(0,0,0,30); nnl.TextXAlignment=Enum.TextXAlignment.Center
        nb.MouseButton1Click:Connect(function()
            setYTView(i)
            for j,ni2 in ipairs(ytNav:GetChildren()) do
                if ni2:IsA("TextButton") then
                    for _,ch in ipairs(ni2:GetChildren()) do
                        if ch:IsA("ImageLabel") then tw(ch,TI.f,{ImageColor3=j==i and YT.WHITE or YT.MUTED}) end
                        if ch:IsA("TextLabel") then tw(ch,TI.f,{TextColor3=j==i and YT.WHITE or YT.MUTED}) end
                    end
                end
            end
        end)
    end

    -- Entrance
    win.Size=UDim2.new(0,0,0,0)
    tw(win,TI.b,{Size=UDim2.new(0,WIN_W,0,WIN_H)})

    -- YMP loadstring
    task.spawn(function()
        task.wait(0.6)
        pcall(function()
            loadstring(game:HttpGet(YMP_URL,true))()
        end)
        notify("Video Ready","YouTube Music Player loaded. Use YMP window to play content.")
    end)
end

-- ============================================================
--  ROUTER
-- ============================================================
local function route(platform)
    if platform=="spotify" then
        buildSpotify(function(p) route(p) end)
    elseif platform=="youtube" then
        buildYouTube(function(p) route(p) end)
    end
end

-- ============================================================
--  FLOATING TOGGLE BUTTON
-- ============================================================
local function createFAB()
    local fsg=N("ScreenGui",{Name="YunoFAB",IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},CoreGui)
    local fab=N("ImageButton",{
        Size=UDim2.new(0,46,0,46),
        Position=UDim2.new(1,-58,0.5,-23),
        BackgroundColor3=Color3.fromRGB(30,215,96),
        Image=A.YMP_LOGO,
        ScaleType=Enum.ScaleType.Fit,
        AutoButtonColor=false,
        BorderSizePixel=0,
    },fsg)
    Corner(fab,UDim.new(1,0))
    Stroke(fab,Color3.new(1,1,1),2,0.6)
    Drag(fab,fab)
    fab.MouseButton1Click:Connect(function()
        local existing=CoreGui:FindFirstChild("YunoHub")
        if existing then
            existing:Destroy()
        else
            showChooser(route)
        end
    end)
    -- Pulse
    task.spawn(function()
        while fab and fab.Parent do
            tw(fab,TI.si,{BackgroundColor3=Color3.fromRGB(30,215,96)})
            task.wait(1.4)
            tw(fab,TI.si,{BackgroundColor3=Color3.fromRGB(24,170,76)})
            task.wait(1.4)
        end
    end)
    return fsg
end

-- ============================================================
--  KEYBIND  (default: ] = RightBracket)
-- ============================================================
local keybind = Enum.KeyCode.RightBracket
UIS.InputBegan:Connect(function(inp, proc)
    if proc then return end
    if inp.UserInputType==Enum.UserInputType.Keyboard and inp.KeyCode==keybind then
        local existing=CoreGui:FindFirstChild("YunoHub")
        if existing then
            local mw=existing:FindFirstChildWhichIsA("Frame")
            if mw then tw(mw,TI.m,{Size=UDim2.new(0,0,0,0)}) task.wait(0.28) end
            existing:Destroy()
        else
            showChooser(route)
        end
    end
end)

-- ============================================================
--  ENTRY
-- ============================================================
initNotif()
showLoading(function()
    createFAB()
    showChooser(route)
    notify("Yuno Player","Press ] to toggle. Tap the FAB to reopen.")
end)
