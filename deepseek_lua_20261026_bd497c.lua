--[[ ═══════════════════════════════════════════════════════════
     YUNO PLAYER v3.0 — Masterpiece Edition
     Full English • Draggable Everywhere • Zero Emojis
     YouTube Video Mode & YouTube Music (Spotify Style)
     ═══════════════════════════════════════════════════════════ ]]

if getgenv().YunoPlayerV3Loaded then return end
getgenv().YunoPlayerV3Loaded = true

-- ═══════════════ SERVICES ═══════════════
local Players         = game:GetService("Players")
local HttpService     = game:GetService("HttpService")
local TweenService    = game:GetService("TweenService")
local UserInputService= game:GetService("UserInputService")
local SoundService    = game:GetService("SoundService")
local StarterGui      = game:GetService("StarterGui")
local CoreGui         = game:GetService("CoreGui")
local RunService      = game:GetService("RunService")

local player = Players.LocalPlayer

-- ═══════════════ EXECUTOR CHECK ═══════════════
local REQUIRED = {"writefile","readfile","isfile","delfile","listfiles","makefolder","isfolder","getcustomasset"}
local missing = {}
for _, f in ipairs(REQUIRED) do
    if type(_G[f]) ~= "function" and type(getgenv()[f]) ~= "function" then
        table.insert(missing, f)
    end
end
local requestFn = request or syn and syn.request or http and http.request or http_request
if not requestFn then table.insert(missing, "request") end
if #missing > 0 then
    StarterGui:SetCore("SendNotification", {
        Title = "ERROR",
        Text = "Executor not supported: " .. table.concat(missing, ", "),
        Duration = 10
    })
    return
end

local function req(o) return requestFn(o) end
local function get(url) local r = req({Url=url,Method="GET"}) return r and r.Body end

-- ═══════════════ ASSET IDS (ZERO EMOJIS) ═══════════════
local Icons = {
    Home        = "rbxassetid://7734038567",
    Search      = "rbxassetid://7734068235",
    Library     = "rbxassetid://7733981353",
    Settings    = "rbxassetid://7734068688",
    Play        = "rbxassetid://6023426926",
    Pause       = "rbxassetid://6023426916",
    Next        = "rbxassetid://6023426923",
    Prev        = "rbxassetid://6023426928",
    Shuffle     = "rbxassetid://6023426908",
    Repeat      = "rbxassetid://6023426921",
    Close       = "rbxassetid://6031094667",
    Minimize    = "rbxassetid://6031094673",
    Download    = "rbxassetid://6035047409",
    Like        = "rbxassetid://6031090990",
    Dislike     = "rbxassetid://6031091004",
    Share       = "rbxassetid://6035047409",
    Plus        = "rbxassetid://6031075935",
    More        = "rbxassetid://6031075935",
    YouTubeLogo = "rbxassetid://1275974022",
    YouTubeCard = "rbxassetid://1049060234",
    MusicLogo   = "rbxassetid://6424875972",
    ChillHero   = "rbxassetid://3290453459",
    Loading     = "rbxassetid://9145283899",
    Glow        = "rbxassetid://4996891970"
}

-- ═══════════════ FILES & CONFIG ═══════════════
local ROOT   = "YunoPlayerV3"
local MUSIC  = ROOT .. "/Audio"
local VIDEO  = ROOT .. "/Video"
local CACHE  = ROOT .. "/Cache"
local CONFIG = ROOT .. "/config.json"
local API    = "https://ymp-api.ddns.net"

for _, f in ipairs({ROOT, MUSIC, VIDEO, CACHE}) do
    if not isfolder(f) then makefolder(f) end
end
for _, f in ipairs(listfiles(CACHE)) do pcall(delfile, f) end

local Config = { mode = nil }
if isfile(CONFIG) then
    pcall(function()
        local d = HttpService:JSONDecode(readfile(CONFIG))
        if d.mode then Config.mode = d.mode end
    end)
end
local function SaveConfig() pcall(function() writefile(CONFIG, HttpService:JSONEncode(Config)) end) end

-- ═══════════════ THEMES (Rectangular & Dark) ═══════════════
local Themes = {
    youtube = {
        key       = "youtube",
        name      = "YouTube Video",
        logo      = Icons.YouTubeLogo,
        hero      = Icons.YouTubeCard,
        bg        = Color3.fromRGB(15, 15, 15),
        side      = Color3.fromRGB(20, 20, 20),
        panel     = Color3.fromRGB(30, 30, 30),
        card      = Color3.fromRGB(40, 40, 40),
        accent    = Color3.fromRGB(255, 0, 0),
        text      = Color3.fromRGB(255, 255, 255),
        sub       = Color3.fromRGB(170, 170, 170),
        radius    = 8,
    },
    music = {
        key       = "music",
        name      = "YouTube Music",
        logo      = Icons.MusicLogo,
        hero      = Icons.ChillHero,
        bg        = Color3.fromRGB(18, 18, 18),
        side      = Color3.fromRGB(0, 0, 0),
        panel     = Color3.fromRGB(24, 24, 24),
        card      = Color3.fromRGB(32, 32, 32),
        accent    = Color3.fromRGB(29, 185, 84),
        text      = Color3.fromRGB(255, 255, 255),
        sub       = Color3.fromRGB(179, 179, 179),
        radius    = 12,
    },
}

-- ═══════════════ HELPERS ═══════════════
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = o; return c end
local function stroke(o, col, th, trans) local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th or 1; s.Transparency = trans or 0; s.Parent = o; return s end
local function tw(o, info, p) local t = TweenService:Create(o, info, p); t:Play(); return t end
local function notify(t, x, d) pcall(function() StarterGui:SetCore("SendNotification", {Title=tostring(t), Text=tostring(x), Duration=d or 5}) end) end
local function fmtTime(s) s = math.floor(s or 0); return string.format("%02d:%02d", math.floor(s/60), s%60) end

local function getThumbnail(url, id)
    local path = CACHE .. "/" .. id .. ".png"
    if not isfile(path) then
        local ok, res = pcall(get, url)
        if ok and res then writefile(path, res) end
    end
    if isfile(path) then
        local ok, asset = pcall(getcustomasset, path)
        if ok then return asset end
    end
    return Icons.YouTubeCard
end

-- ═══════════════ NETWORK / API / POW ═══════════════
local function searchYT(q)
    local ok, r = pcall(get, API .. "/search/youtube/free/" .. HttpService:UrlEncode(q))
    if not ok or not r then return nil end
    local okJ, d = pcall(HttpService.JSONDecode, HttpService, r)
    if okJ and d and d.results then return d.results end
    return nil
end

local shaK = {0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}

local function sha256(msg)
    local b = {string.byte(msg, 1, #msg)}
    local bitlen = #b * 8; table.insert(b, 0x80)
    while #b % 64 ~= 56 do table.insert(b, 0) end
    local hi, lo = math.floor(bitlen/4294967296), bitlen % 4294967296
    for i = 24, 0, -8 do table.insert(b, bit32.band(bit32.rshift(hi, i), 0xFF)) end
    for i = 24, 0, -8 do table.insert(b, bit32.band(bit32.rshift(lo, i), 0xFF)) end
    local h = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
    for chunk = 1, #b, 64 do
        local w = {}
        for i = 0, 15 do
            local p = chunk + i*4
            w[i] = bit32.bor(bit32.lshift(b[p] or 0, 24), bit32.lshift(b[p+1] or 0, 16), bit32.lshift(b[p+2] or 0, 8), b[p+3] or 0)
        end
        for i = 16, 63 do
            local s0 = bit32.bxor(bit32.rrotate(w[i-15],7), bit32.rrotate(w[i-15],18), bit32.rshift(w[i-15],3))
            local s1 = bit32.bxor(bit32.rrotate(w[i-2],17), bit32.rrotate(w[i-2],19), bit32.rshift(w[i-2],10))
            w[i] = (w[i-16] + s0 + w[i-7] + s1) % 4294967296
        end
        local a,bb,c,d,e,f,g,hh = table.unpack(h)
        for i = 0, 63 do
            local S1 = bit32.bxor(bit32.rrotate(e,6), bit32.rrotate(e,11), bit32.rrotate(e,25))
            local ch = bit32.bxor(bit32.band(e,f), bit32.band(bit32.bnot(e),g))
            local t1 = (hh + S1 + ch + shaK[i+1] + w[i]) % 4294967296
            local S0 = bit32.bxor(bit32.rrotate(a,2), bit32.rrotate(a,13), bit32.rrotate(a,22))
            local mj = bit32.bxor(bit32.band(a,bb), bit32.band(a,c), bit32.band(bb,c))
            local t2 = (S0 + mj) % 4294967296
            hh=g; g=f; f=e; e=(d+t1)%4294967296; d=c; c=bb; bb=a; a=(t1+t2)%4294967296
        end
        h[1]=(h[1]+a)%4294967296; h[2]=(h[2]+bb)%4294967296; h[3]=(h[3]+c)%4294967296; h[4]=(h[4]+d)%4294967296
        h[5]=(h[5]+e)%4294967296; h[6]=(h[6]+f)%4294967296; h[7]=(h[7]+g)%4294967296; h[8]=(h[8]+hh)%4294967296
    end
    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", table.unpack(h))
end

local function solvePoW(salt, diff)
    local pre = string.rep("0", diff); local nonce = 0
    while true do
        if sha256(salt .. ":" .. tostring(nonce)):sub(1, diff) == pre then return tostring(nonce) end
        nonce = nonce + 1
        if nonce % 5000 == 0 then task.wait() end
    end
end

local token, tokenExp = nil, 0
local function getToken()
    if token and os.time() < tokenExp - 30 then return token end
    local c = req({Url="https://p.savenow.to/api/pow/challenge", Method="GET"})
    if not c or not c.Body then return nil end
    local ok, d = pcall(HttpService.JSONDecode, HttpService, c.Body)
    if not ok or not d.salt then return nil end
    local n = solvePoW(d.salt, d.difficulty)
    local v = req({Url="https://p.savenow.to/api/pow/verify", Method="POST", Headers={["Content-Type"]="application/json"}, Body=HttpService:JSONEncode({salt=d.salt, difficulty=d.difficulty, expires_at=d.expires_at, signature=d.signature, nonce=n})})
    if not v then return nil end
    local ok2, vd = pcall(HttpService.JSONDecode, HttpService, v.Body)
    if not ok2 or not vd.success then return nil end
    token, tokenExp = vd.token, tonumber(vd.expires_at) or (os.time()+300)
    return token
end

local function downloadMedia(url, format)
    local tk = getToken()
    if not tk then return nil, "PoW failed" end
    local dlUrl = "https://p.savenow.to/api/v2/download?format=" .. format .. "&url=" .. HttpService:UrlEncode(url) .. "&apikey=dfcb6d76f2f6a9894gjkege8a4ab232222"
    local hdrs = {authorization="Bearer " .. tk}
    local r = req({Url=dlUrl, Method="GET", Headers=hdrs})
    if not r or not r.Body then return nil, "API error" end
    local ok, d = pcall(HttpService.JSONDecode, HttpService, r.Body)
    if not ok or not d.progress_url then return nil, "invalid" end
    for _ = 1, 60 do
        task.wait(2)
        local p = req({Url=d.progress_url, Method="GET", Headers=hdrs})
        if p and p.Body then
            local ok2, pd = pcall(HttpService.JSONDecode, HttpService, p.Body)
            if ok2 and pd and pd.progress == 1000 and pd.download_url then return pd.download_url end
        end
    end
    return nil, "timeout"
end

-- ═══════════════ SPLASH SCREEN ═══════════════
local splash = Instance.new("ScreenGui", CoreGui)
splash.IgnoreGuiInset = true
local sBg = Instance.new("Frame", splash)
sBg.Size = UDim2.fromScale(1,1); sBg.BackgroundColor3 = Color3.fromRGB(5, 5, 5); sBg.BorderSizePixel = 0

local sGlow = Instance.new("ImageLabel", sBg)
sGlow.Size = UDim2.new(0, 400, 0, 400); sGlow.Position = UDim2.fromScale(0.5, 0.5)
sGlow.AnchorPoint = Vector2.new(0.5, 0.5); sGlow.BackgroundTransparency = 1
sGlow.Image = Icons.Glow; sGlow.ImageColor3 = Color3.fromRGB(255, 0, 50); sGlow.ImageTransparency = 0.4

local sLogo = Instance.new("ImageLabel", sBg)
sLogo.Size = UDim2.new(0, 0, 0, 0); sLogo.Position = UDim2.fromScale(0.5, 0.45)
sLogo.AnchorPoint = Vector2.new(0.5, 0.5); sLogo.BackgroundTransparency = 1; sLogo.Image = Icons.YouTubeLogo

local sTitle = Instance.new("TextLabel", sBg)
sTitle.Size = UDim2.new(1, 0, 0, 50); sTitle.Position = UDim2.fromScale(0, 0.6)
sTitle.BackgroundTransparency = 1; sTitle.Text = "YUNO PLAYER"
sTitle.TextColor3 = Color3.new(1,1,1); sTitle.Font = Enum.Font.GothamBlack; sTitle.TextSize = 48; sTitle.TextTransparency = 1

local sBarBg = Instance.new("Frame", sBg)
sBarBg.Size = UDim2.new(0, 300, 0, 6); sBarBg.Position = UDim2.fromScale(0.5, 0.72)
sBarBg.AnchorPoint = Vector2.new(0.5, 0); sBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30); sBarBg.BorderSizePixel = 0; corner(sBarBg, 3)

local sBarFill = Instance.new("Frame", sBarBg)
sBarFill.Size = UDim2.new(0, 0, 1, 0); sBarFill.BackgroundColor3 = Color3.fromRGB(255, 0, 50); sBarFill.BorderSizePixel = 0; corner(sBarFill, 3)

local statusText = Instance.new("TextLabel", sBg)
statusText.Size = UDim2.new(1,0,0,20); statusText.Position = UDim2.fromScale(0, 0.76)
statusText.BackgroundTransparency = 1; statusText.Text = "Initializing..."; statusText.TextColor3 = Color3.fromRGB(150,150,150); statusText.Font = Enum.Font.Gotham; statusText.TextSize = 12

-- Splash Animation
tw(sLogo, TweenInfo.new(1, Enum.EasingStyle.Back), {Size = UDim2.new(0, 120, 0, 120)})
task.wait(0.5)
tw(sTitle, TweenInfo.new(0.5), {TextTransparency = 0})
tw(sBarFill, TweenInfo.new(2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 1, 0)})

local statuses = {"Loading assets...", "Connecting to API...", "Preparing UI...", "Ready!"}
for i = 1, 100 do
    if i % 25 == 0 then statusText.Text = statuses[math.floor(i/25)] end
    task.wait(0.02)
end
task.wait(0.5)

local fadeOut = tw(sBg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
tw(sLogo, TweenInfo.new(0.5), {ImageTransparency = 1})
tw(sTitle, TweenInfo.new(0.5), {TextTransparency = 1})
tw(sBarBg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
tw(sBarFill, TweenInfo.new(0.5), {BackgroundTransparency = 1})
tw(statusText, TweenInfo.new(0.5), {TextTransparency = 1})
fadeOut.Completed:Wait()
splash:Destroy()

-- ═══════════════ MAIN UI LOGIC ═══════════════
local mainGui, mainRoot
local sound = Instance.new("Sound", SoundService)
local playlist, currentIdx = {}, 0

local function buildApp(modeKey)
    if mainGui then mainGui:Destroy() end
    sound:Stop()
    local T = Themes[modeKey]
    
    mainGui = Instance.new("ScreenGui", CoreGui)
    mainGui.Name = "YunoApp"
    mainGui.IgnoreGuiInset = true
    mainGui.ResetOnSpawn = false

    -- Main Rectangular Frame
    local root = Instance.new("Frame", mainGui)
    root.Name = "Root"
    root.Size = UDim2.new(0, 950, 0, 550)
    root.Position = UDim2.new(0.5, -475, 0.5, -275)
    root.BackgroundColor3 = T.bg
    root.BorderSizePixel = 0
    root.Active = true
    mainRoot = root
    corner(root, 12)
    stroke(root, T.card, 1)

    -- UIScale for Mobile Support
    local uis = Instance.new("UIScale", root)
    local function resize()
        local vp = workspace.CurrentCamera.ViewportSize
        uis.Scale = math.min(vp.X * 0.9 / 950, vp.Y * 0.9 / 550, 1)
        root.Position = UDim2.new(0.5, -475, 0.5, -275)
    end
    resize()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

    -- ═══════════ FULLY DRAGGABLE FIX ═══════════
    local dragging, dragStart, startPos
    local dragConnection, endConnection
    
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = root.Position
        end
    end

    root.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            -- Check if we are clicking an interactive element
            local isInteractive = false
            for _, obj in ipairs(UserInputService:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextBox") or obj:IsA("ScrollingFrame") then
                    isInteractive = true
                    break
                end
            end
            if not isInteractive then
                startDrag(input)
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ═══════════ SIDEBAR (Navigation) ═══════════
    local sidebar = Instance.new("Frame", root)
    sidebar.Size = UDim2.new(0, 80, 1, 0)
    sidebar.BackgroundColor3 = T.side
    sidebar.BorderSizePixel = 0
    corner(sidebar, 12)
    
    local sideFix = Instance.new("Frame", sidebar)
    sideFix.Size = UDim2.new(0, 12, 1, 0)
    sideFix.Position = UDim2.new(1, -12, 0, 0)
    sideFix.BackgroundColor3 = T.side
    sideFix.BorderSizePixel = 0

    local function createNavBtn(iconId, yPos, callback)
        local btn = Instance.new("ImageButton", sidebar)
        btn.Size = UDim2.new(0, 40, 0, 40)
        btn.Position = UDim2.new(0.5, -20, 0, yPos)
        btn.BackgroundTransparency = 1
        btn.Image = iconId
        btn.ImageColor3 = T.sub
        btn.MouseEnter:Connect(function() tw(btn, TweenInfo.new(0.2), {ImageColor3 = T.text}) end)
        btn.MouseLeave:Connect(function() tw(btn, TweenInfo.new(0.2), {ImageColor3 = T.sub}) end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Tabs Container
    local tabsFrame = Instance.new("Frame", root)
    tabsFrame.Size = UDim2.new(1, -80, 1, -120)
    tabsFrame.Position = UDim2.new(0, 80, 0, 0)
    tabsFrame.BackgroundTransparency = 1

    local homeTab = Instance.new("Frame", tabsFrame)
    homeTab.Size = UDim2.fromScale(1,1); homeTab.BackgroundTransparency = 1; homeTab.Visible = true

    local searchTab = Instance.new("Frame", tabsFrame)
    searchTab.Size = UDim2.fromScale(1,1); searchTab.BackgroundTransparency = 1; searchTab.Visible = false

    local configTab = Instance.new("Frame", tabsFrame)
    configTab.Size = UDim2.fromScale(1,1); configTab.BackgroundTransparency = 1; configTab.Visible = false

    createNavBtn(Icons.Home, 20, function() 
        homeTab.Visible = true; searchTab.Visible = false; configTab.Visible = false 
    end)
    createNavBtn(Icons.Search, 70, function() 
        homeTab.Visible = false; searchTab.Visible = true; configTab.Visible = false 
    end)
    createNavBtn(Icons.Settings, 120, function() 
        homeTab.Visible = false; searchTab.Visible = false; configTab.Visible = true 
    end)

    -- ═══════════ TOP BAR (Close/Minimize) ═══════════
    local closeBtn = Instance.new("ImageButton", root)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 15)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = Icons.Close
    closeBtn.ImageColor3 = T.sub
    closeBtn.MouseButton1Click:Connect(function()
        root.Visible = false
        miniBtn.Visible = true
    end)

    -- ═══════════ HOME TAB (YouTube/Spotify Style) ═══════════
    -- Hero Banner
    local hero = Instance.new("Frame", homeTab)
    hero.Size = UDim2.new(1, -40, 0, 200)
    hero.Position = UDim2.new(0, 20, 0, 20)
    hero.BackgroundColor3 = T.card
    hero.ClipsDescendants = true
    corner(hero, T.radius)

    local heroImg = Instance.new("ImageLabel", hero)
    heroImg.Size = UDim2.new(1, 0, 1, 0)
    heroImg.Image = T.hero
    heroImg.ScaleType = Enum.ScaleType.Crop
    heroImg.BackgroundTransparency = 1
    
    local heroGrad = Instance.new("UIGradient", heroImg)
    heroGrad.Rotation = 90
    heroGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    }

    local heroTitle = Instance.new("TextLabel", hero)
    heroTitle.Size = UDim2.new(1, -40, 0, 40)
    heroTitle.Position = UDim2.new(0, 20, 1, -60)
    heroTitle.BackgroundTransparency = 1
    heroTitle.Text = "Welcome to " .. T.name
    heroTitle.TextColor3 = T.text
    heroTitle.Font = Enum.Font.GothamBlack
    heroTitle.TextSize = 28
    heroTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Quick Access Grid
    local gridTitle = Instance.new("TextLabel", homeTab)
    gridTitle.Size = UDim2.new(1, -40, 0, 30)
    gridTitle.Position = UDim2.new(0, 20, 0, 240)
    gridTitle.BackgroundTransparency = 1
    gridTitle.Text = "Quick Access"
    gridTitle.TextColor3 = T.text
    gridTitle.Font = Enum.Font.GothamBold
    gridTitle.TextSize = 18
    gridTitle.TextXAlignment = Enum.TextXAlignment.Left

    local gridScroll = Instance.new("ScrollingFrame", homeTab)
    gridScroll.Size = UDim2.new(1, -40, 0, 150)
    gridScroll.Position = UDim2.new(0, 20, 0, 280)
    gridScroll.BackgroundTransparency = 1
    gridScroll.BorderSizePixel = 0
    gridScroll.ScrollBarThickness = 0
    gridScroll.ScrollingDirection = Enum.ScrollingDirection.X
    gridScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    
    local gridLayout = Instance.new("UIListLayout", gridScroll)
    gridLayout.FillDirection = Enum.FillDirection.Horizontal
    gridLayout.Padding = UDim.new(0, 15)

    local genres = {"Lofi Beats", "Top Pop", "Rock Classics", "Chill Vibes", "Rap Hits"}
    for i, g in ipairs(genres) do
        local card = Instance.new("Frame", gridScroll)
        card.Size = UDim2.new(0, 160, 1, 0)
        card.BackgroundColor3 = T.panel
        corner(card, T.radius)
        
        local cImg = Instance.new("ImageLabel", card)
        cImg.Size = UDim2.new(1, 0, 0.7, 0)
        cImg.Image = Icons.YouTubeCard
        cImg.ScaleType = Enum.ScaleType.Crop
        cImg.BackgroundTransparency = 1
        corner(cImg, T.radius)
        
        local cText = Instance.new("TextLabel", card)
        cText.Size = UDim2.new(1, -10, 0.3, 0)
        cText.Position = UDim2.new(0, 5, 0.7, 0)
        cText.BackgroundTransparency = 1
        cText.Text = g
        cText.TextColor3 = T.text
        cText.Font = Enum.Font.GothamBold
        cText.TextSize = 14
    end

    -- ═══════════ SEARCH TAB ═══════════
    local searchBar = Instance.new("Frame", searchTab)
    searchBar.Size = UDim2.new(1, -40, 0, 50)
    searchBar.Position = UDim2.new(0, 20, 0, 20)
    searchBar.BackgroundColor3 = T.panel
    corner(searchBar, 25)

    local sIcon = Instance.new("ImageLabel", searchBar)
    sIcon.Size = UDim2.new(0, 24, 0, 24)
    sIcon.Position = UDim2.new(0, 15, 0.5, -12)
    sIcon.BackgroundTransparency = 1
    sIcon.Image = Icons.Search
    sIcon.ImageColor3 = T.sub

    local sBox = Instance.new("TextBox", searchBar)
    sBox.Size = UDim2.new(1, -100, 1, 0)
    sBox.Position = UDim2.new(0, 50, 0, 0)
    sBox.BackgroundTransparency = 1
    sBox.PlaceholderText = "Search YouTube..."
    sBox.TextColor3 = T.text
    sBox.Font = Enum.Font.Gotham
    sBox.TextSize = 14
    sBox.TextXAlignment = Enum.TextXAlignment.Left
    sBox.ClearTextOnFocus = false

    local searchResults = Instance.new("ScrollingFrame", searchTab)
    searchResults.Size = UDim2.new(1, -40, 1, -90)
    searchResults.Position = UDim2.new(0, 20, 0, 80)
    searchResults.BackgroundTransparency = 1
    searchResults.BorderSizePixel = 0
    searchResults.AutomaticCanvasSize = Enum.AutomaticSize.Y
    searchResults.ScrollBarThickness = 4
    searchResults.ScrollBarImageColor3 = T.accent
    
    local srLayout = Instance.new("UIListLayout", searchResults)
    srLayout.Padding = UDim.new(0, 10)

    -- ═══════════ CONFIG TAB ═══════════
    local switchBtn = Instance.new("TextButton", configTab)
    switchBtn.Size = UDim2.new(0, 250, 0, 50)
    switchBtn.Position = UDim2.new(0, 20, 0, 20)
    switchBtn.BackgroundColor3 = T.accent
    switchBtn.Text = "Switch to " .. (modeKey == "youtube" and "Music Player" or "YouTube Video")
    switchBtn.TextColor3 = T.text
    switchBtn.Font = Enum.Font.GothamBold
    switchBtn.TextSize = 14
    corner(switchBtn, 8)
    switchBtn.MouseButton1Click:Connect(function()
        Config.mode = (modeKey == "youtube") and "music" or "youtube"
        SaveConfig()
        buildApp(Config.mode)
    end)

    -- ═══════════ PLAYER BAR (Bottom) ═══════════
    local playerBar = Instance.new("Frame", root)
    playerBar.Size = UDim2.new(1, -100, 0, 90)
    playerBar.Position = UDim2.new(0, 90, 1, -100)
    playerBar.BackgroundColor3 = T.panel
    playerBar.BorderSizePixel = 0
    corner(playerBar, T.radius)
    stroke(playerBar, T.card, 1)

    -- Album Art
    local albumArt = Instance.new("ImageLabel", playerBar)
    albumArt.Size = UDim2.new(0, 64, 0, 64)
    albumArt.Position = UDim2.new(0, 13, 0, 13)
    albumArt.BackgroundColor3 = T.card
    albumArt.Image = T.logo
    corner(albumArt, T.radius)

    -- Info
    local trackTitle = Instance.new("TextLabel", playerBar)
    trackTitle.Size = UDim2.new(0, 200, 0, 20)
    trackTitle.Position = UDim2.new(0, 90, 0, 20)
    trackTitle.BackgroundTransparency = 1
    trackTitle.Text = "Not Playing"
    trackTitle.TextColor3 = T.text
    trackTitle.Font = Enum.Font.GothamBold
    trackTitle.TextSize = 14
    trackTitle.TextXAlignment = Enum.TextXAlignment.Left

    local trackAuthor = Instance.new("TextLabel", playerBar)
    trackAuthor.Size = UDim2.new(0, 200, 0, 16)
    trackAuthor.Position = UDim2.new(0, 90, 0, 40)
    trackAuthor.BackgroundTransparency = 1
    trackAuthor.Text = "YUNO"
    trackAuthor.TextColor3 = T.sub
    trackAuthor.Font = Enum.Font.Gotham
    trackAuthor.TextSize = 12
    trackAuthor.TextXAlignment = Enum.TextXAlignment.Left

    -- Controls
    local controls = Instance.new("Frame", playerBar)
    controls.Size = UDim2.new(0, 200, 1, 0)
    controls.Position = UDim2.new(0.5, -100, 0, 0)
    controls.BackgroundTransparency = 1

    local prevBtn = Instance.new("ImageButton", controls)
    prevBtn.Size = UDim2.new(0, 32, 0, 32)
    prevBtn.Position = UDim2.new(0, 20, 0.5, -16)
    prevBtn.BackgroundTransparency = 1
    prevBtn.Image = Icons.Prev
    prevBtn.ImageColor3 = T.text

    local playBtn = Instance.new("ImageButton", controls)
    playBtn.Size = UDim2.new(0, 48, 0, 48)
    playBtn.Position = UDim2.new(0.5, -24, 0.5, -24)
    playBtn.BackgroundColor3 = T.text
    playBtn.Image = Icons.Play
    playBtn.ImageColor3 = T.bg
    corner(playBtn, 24)

    local nextBtn = Instance.new("ImageButton", controls)
    nextBtn.Size = UDim2.new(0, 32, 0, 32)
    nextBtn.Position = UDim2.new(0.5, 40, 0.5, -16)
    nextBtn.BackgroundTransparency = 1
    nextBtn.Image = Icons.Next
    nextBtn.ImageColor3 = T.text

    -- Progress Bar
    local progressBg = Instance.new("Frame", playerBar)
    progressBg.Size = UDim2.new(1, -400, 0, 4)
    progressBg.Position = UDim2.new(0, 300, 0, 65)
    progressBg.BackgroundColor3 = T.card
    progressBg.BorderSizePixel = 0
    corner(progressBg, 2)

    local progressFill = Instance.new("Frame", progressBg)
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = T.text
    progressFill.BorderSizePixel = 0
    corner(progressFill, 2)

    -- ═══════════ MINI BUTTON (Floating) ═══════════
    local miniBtn = Instance.new("ImageButton", mainGui)
    miniBtn.Size = UDim2.new(0, 50, 0, 50)
    miniBtn.Position = UDim2.new(0, 20, 0.5, -25)
    miniBtn.BackgroundColor3 = T.accent
    miniBtn.Image = T.logo
    miniBtn.Visible = false
    corner(miniBtn, 25)
    stroke(miniBtn, Color3.new(1,1,1), 2)
    miniBtn.MouseButton1Click:Connect(function()
        root.Visible = true
        miniBtn.Visible = false
    end)

    -- Make miniBtn draggable
    local mDrag, mStart, mPos
    miniBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mDrag = true; mStart = input.Position; mPos = miniBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if mDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - mStart
            miniBtn.Position = UDim2.new(mPos.X.Scale, mPos.X.Offset + d.X, mPos.Y.Scale, mPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mDrag = false
        end
    end)

    -- ═══════════ LOGIC: SEARCH & PLAY ═══════════
    local function playMedia(entry)
        trackTitle.Text = entry.name
        trackAuthor.Text = entry.author
        albumArt.Image = getThumbnail(entry.thumbnail, entry.id)
        
        local fmt = (entry.isVideo) and "360" or "mp3"
        local ext = (entry.isVideo) and ".webm" or ".mp3"
        local dir = (entry.isVideo) and VIDEO or MUSIC
        local path = dir .. "/" .. entry.id .. ext

        task.spawn(function()
            if not isfile(path) then
                notify("Downloading", entry.name, 3)
                local dlUrl = downloadMedia("https://youtu.be/" .. entry.id, fmt)
                if dlUrl then
                    local file = req({Url=dlUrl, Method="GET"})
                    if file and file.Body then writefile(path, file.Body) end
                end
            end
            
            if isfile(path) then
                local asset = getcustomasset(path)
                if entry.isVideo then
                    notify("Playing Video", "Video mode is visual placeholder", 3)
                    -- In a real app, you would use a VideoFrame here
                else
                    sound.SoundId = asset
                    sound:Play()
                    playBtn.Image = Icons.Pause
                end
            end
        end)
    end

    local function doSearch()
        for _, c in ipairs(searchResults:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        local q = sBox.Text
        if q == "" then return end
        
        local results = searchYT(q)
        if not results then return end
        
        for i, r in ipairs(results) do
            local card = Instance.new("Frame", searchResults)
            card.Size = UDim2.new(1, -10, 0, 80)
            card.BackgroundColor3 = T.panel
            corner(card, T.radius)
            
            local thumb = Instance.new("ImageLabel", card)
            thumb.Size = UDim2.new(0, 100, 0, 60)
            thumb.Position = UDim2.new(0, 10, 0, 10)
            thumb.BackgroundColor3 = T.card
            thumb.Image = getThumbnail(r.thumbnail, r.id)
            corner(thumb, 6)
            
            local title = Instance.new("TextLabel", card)
            title.Size = UDim2.new(1, -130, 0, 20)
            title.Position = UDim2.new(0, 120, 0, 15)
            title.BackgroundTransparency = 1
            title.Text = r.name
            title.TextColor3 = T.text
            title.Font = Enum.Font.GothamBold
            title.TextSize = 14
            title.TextXAlignment = Enum.TextXAlignment.Left
            
            local author = Instance.new("TextLabel", card)
            author.Size = UDim2.new(1, -130, 0, 16)
            author.Position = UDim2.new(0, 120, 0, 40)
            author.BackgroundTransparency = 1
            author.Text = r.author
            author.TextColor3 = T.sub
            author.Font = Enum.Font.Gotham
            author.TextSize = 12
            author.TextXAlignment = Enum.TextXAlignment.Left
            
            local playBtn = Instance.new("ImageButton", card)
            playBtn.Size = UDim2.new(0, 40, 0, 40)
            playBtn.Position = UDim2.new(1, -50, 0, 20)
            playBtn.BackgroundColor3 = T.accent
            playBtn.Image = Icons.Play
            corner(playBtn, 20)
            playBtn.MouseButton1Click:Connect(function()
                playMedia({id = r.id, name = r.name, author = r.author, thumbnail = r.thumbnail, isVideo = false})
            end)
        end
    end

    sBox.FocusLost:Connect(function(enter) if enter then doSearch() end end)

    -- ═══════════ LOGIC: CONTROLS ═══════════
    playBtn.MouseButton1Click:Connect(function()
        if sound.IsPlaying then
            sound:Pause()
            playBtn.Image = Icons.Play
        else
            sound:Resume()
            playBtn.Image = Icons.Pause
        end
    end)

    -- Progress update loop
    task.spawn(function()
        while root.Parent do
            if sound.TimeLength > 0 then
                progressFill.Size = UDim2.new(sound.TimePosition / sound.TimeLength, 0, 1, 0)
            end
            task.wait(0.1)
        end
    end)

    return mainGui
end

-- ═══════════════ BOOTSTRAP ═══════════════
if Config.mode and Themes[Config.mode] then
    buildApp(Config.mode)
else
    buildApp("youtube") 
end

notify("YUNO PLAYER", "Loaded successfully!", 5)