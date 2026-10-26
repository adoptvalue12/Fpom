--[[ ═══════════════════════════════════════════════════════════
     YUNO PLAYER v2.0 — Ultimate Edition
     Dual Mode: YouTube Music + Music Player
     Draggable everywhere • Playlist sidebar • Premium splash
     ═══════════════════════════════════════════════════════════ ]]

if getgenv().YunoPlayerLoaded then return end
getgenv().YunoPlayerLoaded = true

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
        Title = "❌ YUNO PLAYER",
        Text = "Executor non supporté: " .. table.concat(missing, ", "),
        Duration = 10
    })
    getgenv().YunoPlayerLoaded = false
    return
end

local function req(o) return requestFn(o) end
local function get(url) local r = req({Url=url,Method="GET"}) return r and r.Body end

-- ═══════════════ FILES ═══════════════
local API    = "https://ymp-api.ddns.net"
local ROOT   = "YunoPlayer"
local MUSIC  = ROOT .. "/Musics"
local VIDEO  = ROOT .. "/Videos"
local CACHE  = ROOT .. "/Cache"
local CONFIG = ROOT .. "/config.json"

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

local function SaveConfig()
    pcall(function() writefile(CONFIG, HttpService:JSONEncode(Config)) end)
end

-- ═══════════════ THEMES ═══════════════
local Themes = {
    youtube = {
        key       = "youtube",
        name      = "YouTube Music",
        logo      = "rbxassetid://1275974022",
        hero      = "rbxassetid://131351281584870",
        videoCard = "rbxassetid://1049060234",
        bg        = Color3.fromRGB(8, 8, 10),
        side      = Color3.fromRGB(14, 14, 16),
        panel     = Color3.fromRGB(20, 20, 22),
        card      = Color3.fromRGB(28, 28, 32),
        cardHi    = Color3.fromRGB(38, 38, 44),
        accent    = Color3.fromRGB(255, 0, 50),
        accent2   = Color3.fromRGB(255, 80, 100),
        text      = Color3.fromRGB(255, 255, 255),
        sub       = Color3.fromRGB(160, 160, 170),
        radius    = 10,
    },
    music = {
        key       = "music",
        name      = "Music Player",
        logo      = "rbxassetid://6424875972",
        hero      = "rbxassetid://3290453459",
        videoCard = "rbxassetid://3290453459",
        bg        = Color3.fromRGB(12, 12, 12),
        side      = Color3.fromRGB(0, 0, 0),
        panel     = Color3.fromRGB(18, 18, 18),
        card      = Color3.fromRGB(28, 28, 28),
        cardHi    = Color3.fromRGB(38, 38, 38),
        accent    = Color3.fromRGB(29, 185, 84),
        accent2   = Color3.fromRGB(30, 215, 96),
        text      = Color3.fromRGB(255, 255, 255),
        sub       = Color3.fromRGB(170, 170, 170),
        radius    = 14,
    },
}

-- ═══════════════ HELPERS ═══════════════
local function corner(o, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = o; return c
end
local function stroke(o, col, th, trans)
    local s = Instance.new("UIStroke")
    s.Color = col; s.Thickness = th or 1; s.Transparency = trans or 0; s.Parent = o; return s
end
local function tw(o, info, p) local t = TweenService:Create(o, info, p); t:Play(); return t end
local function notify(t, x, d)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(t), Text = tostring(x), Duration = d or 5
        })
    end)
end
local function fmtTime(s)
    s = math.floor(s or 0)
    return string.format("%02d:%02d", math.floor(s/60), s%60)
end
local function addGlow(parent, color, size)
    local glow = Instance.new("ImageLabel")
    glow.Size = UDim2.new(1, size or 40, 1, size or 40)
    glow.Position = UDim2.fromScale(0.5, 0.5)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://4996891970"
    glow.ImageColor3 = color
    glow.ImageTransparency = 0.65
    glow.ZIndex = 0
    glow.Parent = parent
    return glow
end

-- ═══════════════ NETWORK / API ═══════════════
local function searchYT(q)
    local ok, r = pcall(function()
        return get(API .. "/search/youtube/free/" .. HttpService:UrlEncode(q))
    end)
    if not ok or not r then return nil, "error" end
    local low = string.lower(r)
    if string.find(low, "no results") then return nil, "empty" end
    if string.find(low, "too many") then return nil, "rate" end
    local okJ, d = pcall(HttpService.JSONDecode, HttpService, r)
    if okJ and d and d.results then return d.results end
    return nil, "error"
end

-- ═══════════════ SHA256 + PoW ═══════════════
local shaK = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
}

local function sha256(msg)
    local b = {string.byte(msg, 1, #msg)}
    local bitlen = #b * 8
    table.insert(b, 0x80)
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
        h[1]=(h[1]+a)%4294967296; h[2]=(h[2]+bb)%4294967296
        h[3]=(h[3]+c)%4294967296; h[4]=(h[4]+d)%4294967296
        h[5]=(h[5]+e)%4294967296; h[6]=(h[6]+f)%4294967296
        h[7]=(h[7]+g)%4294967296; h[8]=(h[8]+hh)%4294967296
    end
    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", table.unpack(h))
end

local function solvePoW(salt, diff)
    local pre = string.rep("0", diff)
    local nonce = 0
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
    local v = req({
        Url="https://p.savenow.to/api/pow/verify", Method="POST",
        Headers={["Content-Type"]="application/json"},
        Body=HttpService:JSONEncode({
            salt=d.salt, difficulty=d.difficulty,
            expires_at=d.expires_at, signature=d.signature, nonce=n
        })
    })
    if not v then return nil end
    local ok2, vd = pcall(HttpService.JSONDecode, HttpService, v.Body)
    if not ok2 or not vd.success then return nil end
    token, tokenExp = vd.token, tonumber(vd.expires_at) or (os.time()+300)
    return token
end

local function downloadMedia(url, format)
    local tk = getToken()
    if not tk then return nil, "PoW failed" end
    local dlUrl = "https://p.savenow.to/api/v2/download?format=" .. format
        .. "&url=" .. HttpService:UrlEncode(url)
        .. "&apikey=dfcb6d76f2f6a9894gjkege8a4ab232222"
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

-- ═══════════════════════════════════════════════
--           PREMIUM SPLASH SCREEN
-- ═══════════════════════════════════════════════
local splash = Instance.new("ScreenGui")
splash.Name = "YunoSplash"
splash.IgnoreGuiInset = true
splash.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() splash.Parent = CoreGui end)
if not splash.Parent then splash.Parent = player:WaitForChild("PlayerGui") end

-- Animated rotating gradient background
local sbg = Instance.new("Frame")
sbg.Size = UDim2.fromScale(1, 1)
sbg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sbg.BorderSizePixel = 0
sbg.Parent = splash

local bgGrad = Instance.new("UIGradient")
bgGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 0, 20)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(20, 0, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 20, 20)),
}
bgGrad.Rotation = 0
bgGrad.Parent = sbg

-- Rotate bg continuously
task.spawn(function()
    while splash.Parent do
        for r = 0, 360, 6 do
            if not splash.Parent then break end
            bgGrad.Rotation = r
            task.wait(0.05)
        end
    end
end)

-- Ambient glow behind logo
local ambientGlow = Instance.new("ImageLabel")
ambientGlow.Size = UDim2.new(0, 420, 0, 420)
ambientGlow.Position = UDim2.fromScale(0.5, 0.4)
ambientGlow.AnchorPoint = Vector2.new(0.5, 0.5)
ambientGlow.BackgroundTransparency = 1
ambientGlow.Image = "rbxassetid://4996891970"
ambientGlow.ImageColor3 = Color3.fromRGB(255, 30, 80)
ambientGlow.ImageTransparency = 0.3
ambientGlow.Parent = splash

task.spawn(function()
    while splash.Parent do
        tw(ambientGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { ImageTransparency = 0.6, Size = UDim2.new(0, 380, 0, 380) })
        task.wait(1.2)
        if not splash.Parent then break end
        tw(ambientGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { ImageTransparency = 0.3, Size = UDim2.new(0, 420, 0, 420) })
        task.wait(1.2)
    end
end)

-- Logo
local sLogo = Instance.new("ImageLabel")
sLogo.Size = UDim2.new(0, 0, 0, 0)
sLogo.Position = UDim2.fromScale(0.5, 0.4)
sLogo.AnchorPoint = Vector2.new(0.5, 0.5)
sLogo.BackgroundTransparency = 1
sLogo.Image = "rbxassetid://1275974022"
sLogo.Parent = splash

-- YUNO PLAYER text with gradient
local sTitle = Instance.new("TextLabel")
sTitle.Size = UDim2.new(1, 0, 0, 52)
sTitle.Position = UDim2.fromScale(0, 0.58)
sTitle.BackgroundTransparency = 1
sTitle.Text = "YUNO PLAYER"
sTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
sTitle.Font = Enum.Font.GothamBlack
sTitle.TextSize = 52
sTitle.TextTransparency = 1
sTitle.Parent = splash

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 100)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 100)),
}
titleGrad.Parent = sTitle

-- Subtitle
local sSub = Instance.new("TextLabel")
sSub.Size = UDim2.new(1, 0, 0, 22)
sSub.Position = UDim2.fromScale(0, 0.665)
sSub.BackgroundTransparency = 1
sSub.Text = "PREMIUM MUSIC & VIDEO STREAMER"
sSub.TextColor3 = Color3.fromRGB(160, 160, 180)
sSub.Font = Enum.Font.GothamBold
sSub.TextSize = 13
sSub.TextTransparency = 1
sSub.Parent = splash

-- Progress bar container
local sPb = Instance.new("Frame")
sPb.Size = UDim2.new(0, 320, 0, 6)
sPb.Position = UDim2.fromScale(0.5, 0.75)
sPb.AnchorPoint = Vector2.new(0.5, 0)
sPb.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
sPb.BorderSizePixel = 0
sPb.ClipsDescendants = true
sPb.Parent = splash
corner(sPb, 3)

-- Progress fill
local sFill = Instance.new("Frame")
sFill.Size = UDim2.new(0, 0, 1, 0)
sFill.BackgroundColor3 = Color3.fromRGB(255, 50, 100)
sFill.BorderSizePixel = 0
sFill.Parent = sPb
corner(sFill, 3)

-- Shimmer effect on fill
local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 100)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 100)),
}
fillGrad.Transparency = NumberSequence.new{
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.5, 0.3),
    NumberSequenceKeypoint.new(1, 0),
}
fillGrad.Parent = sFill

task.spawn(function()
    while splash.Parent do
        for i = -1, 1, 0.05 do
            if not splash.Parent then break end
            fillGrad.Offset = Vector2.new(i, 0)
            task.wait(0.03)
        end
    end
end)

-- Percentage text
local sPercent = Instance.new("TextLabel")
sPercent.Size = UDim2.new(0, 60, 0, 20)
sPercent.Position = UDim2.new(0.5, 170, 0.75, -8)
sPercent.BackgroundTransparency = 1
sPercent.Text = "0%"
sPercent.TextColor3 = Color3.fromRGB(200, 200, 210)
sPercent.Font = Enum.Font.GothamBold
sPercent.TextSize = 13
sPercent.TextXAlignment = Enum.TextXAlignment.Left
sPercent.TextTransparency = 1
sPercent.Parent = splash

-- Loading status text
local sStatus = Instance.new("TextLabel")
sStatus.Size = UDim2.new(1, 0, 0, 18)
sStatus.Position = UDim2.fromScale(0, 0.80)
sStatus.BackgroundTransparency = 1
sStatus.Text = "Initialisation..."
sStatus.TextColor3 = Color3.fromRGB(120, 120, 130)
sStatus.Font = Enum.Font.Gotham
sStatus.TextSize = 11
sStatus.TextTransparency = 1
sStatus.Parent = splash

-- Version text
local sVersion = Instance.new("TextLabel")
sVersion.Size = UDim2.new(1, 0, 0, 16)
sVersion.Position = UDim2.new(0, 0, 1, -30)
sVersion.BackgroundTransparency = 1
sVersion.Text = "v2.0 • by YUNO"
sVersion.TextColor3 = Color3.fromRGB(80, 80, 90)
sVersion.Font = Enum.Font.Gotham
sVersion.TextSize = 10
sVersion.TextTransparency = 1
sVersion.Parent = splash

-- ═══════ Splash Animation Sequence ═══════
tw(sLogo, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 140, 0, 140)
})
task.wait(0.4)

tw(sTitle, TweenInfo.new(0.6), { TextTransparency = 0 })
task.wait(0.3)

tw(sSub, TweenInfo.new(0.5), { TextTransparency = 0 })
tw(sPercent, TweenInfo.new(0.4), { TextTransparency = 0 })
tw(sStatus, TweenInfo.new(0.4), { TextTransparency = 0 })
tw(sVersion, TweenInfo.new(0.4), { TextTransparency = 0 })

-- Logo subtle pulse during loading
task.spawn(function()
    while splash.Parent do
        tw(sLogo, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Size = UDim2.new(0, 155, 0, 155) })
        task.wait(0.8)
        if not splash.Parent then break end
        tw(sLogo, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Size = UDim2.new(0, 140, 0, 140) })
        task.wait(0.8)
    end
end)

-- Loading progress simulation
local statuses = {
    "Initialisation...",
    "Chargement des modules...",
    "Connexion à l'API...",
    "Préparation de l'interface...",
    "Finalisation...",
    "Prêt !"
}

for i = 1, 100 do
    if not splash.Parent then break end
    sFill.Size = UDim2.new(i / 100, 0, 1, 0)
    sPercent.Text = i .. "%"
    if i % 20 == 0 then
        sStatus.Text = statuses[math.min(math.floor(i/20) + 1, #statuses)]
    end
    task.wait(0.025)
end

task.wait(0.3)

-- Fade out everything
for _, obj in ipairs(splash:GetDescendants()) do
    if obj:IsA("GuiObject") then
        pcall(function()
            if obj:IsA("ImageLabel") then
                tw(obj, TweenInfo.new(0.5), { ImageTransparency = 1 })
            elseif obj:IsA("TextLabel") then
                tw(obj, TweenInfo.new(0.5), { TextTransparency = 1 })
            end
            if obj.BackgroundTransparency ~= nil and obj.BackgroundTransparency < 1 then
                tw(obj, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
            end
        end)
    end
end
task.wait(0.6)
splash:Destroy()

-- ═══════════════════════════════════════════════
--              MODE SELECT SCREEN
-- ═══════════════════════════════════════════════
local modeChosen = nil

local function showModeSelect()
    local ms = Instance.new("ScreenGui")
    ms.Name = "YunoModeSelect"
    ms.IgnoreGuiInset = true
    ms.ResetOnSpawn = false
    pcall(function() ms.Parent = CoreGui end)
    if not ms.Parent then ms.Parent = player:WaitForChild("PlayerGui") end

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(6, 6, 8)
    bg.BorderSizePixel = 0
    bg.Parent = ms

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 5, 15)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(5, 5, 8)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 15, 15)),
    }
    bgGrad.Rotation = 60
    bgGrad.Parent = bg

    -- Header
    local hdr = Instance.new("TextLabel")
    hdr.Size = UDim2.new(1, 0, 0, 58)
    hdr.Position = UDim2.new(0, 0, 0.10, 0)
    hdr.BackgroundTransparency = 1
    hdr.Text = "CHOISIS TON MODE"
    hdr.TextColor3 = Color3.fromRGB(255, 255, 255)
    hdr.Font = Enum.Font.GothamBlack
    hdr.TextSize = 42
    hdr.TextTransparency = 1
    hdr.Parent = bg

    local hdrGrad = Instance.new("UIGradient")
    hdrGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255)),
    }
    hdrGrad.Parent = hdr

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 24)
    sub.Position = UDim2.new(0, 0, 0.10, 66)
    sub.BackgroundTransparency = 1
    sub.Text = "Tu peux changer à tout moment depuis Config"
    sub.TextColor3 = Color3.fromRGB(140, 140, 155)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 14
    sub.TextTransparency = 1
    sub.Parent = bg

    local function buildCard(theme, xoff)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 300, 0, 370)
        card.Position = UDim2.new(0.5, xoff, 0.55, 0)
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.BackgroundColor3 = theme.panel
        card.BorderSizePixel = 0
        card.Parent = bg
        corner(card, 18)
        stroke(card, theme.accent, 2, 0.4)

        -- Glow behind
        local glow = Instance.new("ImageLabel")
        glow.Size = UDim2.new(1, 80, 1, 80)
        glow.Position = UDim2.fromScale(0.5, 0.5)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://4996891970"
        glow.ImageColor3 = theme.accent
        glow.ImageTransparency = 0.7
        glow.ZIndex = 0
        glow.Parent = card

        -- Logo container with glow
        local logoBox = Instance.new("Frame")
        logoBox.Size = UDim2.new(0, 160, 0, 160)
        logoBox.Position = UDim2.new(0.5, 0, 0, 30)
        logoBox.AnchorPoint = Vector2.new(0.5, 0)
        logoBox.BackgroundTransparency = 1
        logoBox.Parent = card

        local logoGlow = Instance.new("ImageLabel")
        logoGlow.Size = UDim2.new(1, 40, 1, 40)
        logoGlow.Position = UDim2.fromScale(0.5, 0.5)
        logoGlow.AnchorPoint = Vector2.new(0.5, 0.5)
        logoGlow.BackgroundTransparency = 1
        logoGlow.Image = "rbxassetid://4996891970"
        logoGlow.ImageColor3 = theme.accent
        logoGlow.ImageTransparency = 0.4
        logoGlow.Parent = logoBox

        local logo = Instance.new("ImageLabel")
        logo.Size = UDim2.fromScale(1, 1)
        logo.BackgroundTransparency = 1
        logo.Image = theme.logo
        logo.Parent = logoBox

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(1, -20, 0, 36)
        nm.Position = UDim2.new(0, 10, 0, 220)
        nm.BackgroundTransparency = 1
        nm.Text = theme.name
        nm.TextColor3 = Color3.fromRGB(255, 255, 255)
        nm.Font = Enum.Font.GothamBlack
        nm.TextSize = 26
        nm.Parent = card

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -30, 0, 30)
        desc.Position = UDim2.new(0, 15, 0, 260)
        desc.BackgroundTransparency = 1
        desc.Text = theme.key == "youtube"
            and "Vidéos HD • Playlists • Style sombre"
            or  "Musique • Chill vibes • Style Spotify"
        desc.TextColor3 = theme.sub
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 12
        desc.TextWrapped = true
        desc.Parent = card

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -40, 0, 46)
        btn.Position = UDim2.new(0, 20, 1, -60)
        btn.BackgroundColor3 = theme.accent
        btn.Text = "COMMENCER"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.AutoButtonColor = false
        btn.Parent = card
        corner(btn, 10)

        -- Button hover
        btn.MouseEnter:Connect(function()
            tw(btn, TweenInfo.new(0.2), { BackgroundColor3 = theme.accent2 })
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, TweenInfo.new(0.2), { BackgroundColor3 = theme.accent })
        end)

        -- Card hover
        card.MouseEnter:Connect(function()
            tw(card, TweenInfo.new(0.25), {
                Size = UDim2.new(0, 312, 0, 382),
                BackgroundColor3 = theme.cardHi
            })
            tw(glow, TweenInfo.new(0.25), { ImageTransparency = 0.5 })
            tw(logoGlow, TweenInfo.new(0.25), { ImageTransparency = 0.2 })
        end)
        card.MouseLeave:Connect(function()
            tw(card, TweenInfo.new(0.25), {
                Size = UDim2.new(0, 300, 0, 370),
                BackgroundColor3 = theme.panel
            })
            tw(glow, TweenInfo.new(0.25), { ImageTransparency = 0.7 })
            tw(logoGlow, TweenInfo.new(0.25), { ImageTransparency = 0.4 })
        end)

        return btn, card
    end

    local ytBtn = buildCard(Themes.youtube, -175)
    local spBtn = buildCard(Themes.music, 175)

    tw(hdr, TweenInfo.new(0.5), { TextTransparency = 0 })
    tw(sub, TweenInfo.new(0.6), { TextTransparency = 0 })

    local function pick(mode)
        if modeChosen then return end
        modeChosen = mode
        Config.mode = mode
        SaveConfig()
        local out = tw(bg, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
        for _, c in ipairs(bg:GetDescendants()) do
            if c:IsA("GuiObject") and c ~= bg then
                if c:IsA("ImageLabel") then
                    tw(c, TweenInfo.new(0.4), { ImageTransparency = 1 })
                elseif c:IsA("TextLabel") or c:IsA("TextButton") then
                    tw(c, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
                end
            end
        end
        out.Completed:Wait()
        ms:Destroy()
    end

    ytBtn.MouseButton1Click:Connect(function() pick("youtube") end)
    spBtn.MouseButton1Click:Connect(function() pick("music") end)

    return ms
end

-- ═══════════════════════════════════════════════
--                   MAIN APP
-- ═══════════════════════════════════════════════
local mainGui, mainRoot
local sound = Instance.new("Sound")
sound.Volume = 1
sound.Parent = SoundService

local playlist, currentIdx, currentType = {}, 0, nil
local isPlaying, isDownloading = false, false
local videoFrameRef, thumbRef, titleRef, authorRef
local progressFillRef, timeRef, playBtnRef, progressBgRef
local searchResultsRef, statusRef
local homeContentRef, configContentRef, searchContentRef
local playlistSidebarRef, playlistItemsRef
local tabsRef = {}
local currentTab = "home"

local function clearApp()
    if mainGui then mainGui:Destroy() end
    sound:Stop()
    sound.SoundId = ""
    playlist = {}
    currentIdx = 0
    currentType = nil
    isPlaying = false
end

-- Interactive check for drag-everywhere
local function isInteractiveTarget(input)
    local objs = UserInputService:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
    for _, obj in ipairs(objs) do
        if obj:IsDescendantOf(mainRoot) then
            if obj:IsA("TextButton") or obj:IsA("ImageButton") 
               or obj:IsA("TextBox") or obj:IsA("ScrollingFrame") then
                return true
            end
        end
    end
    return false
end

-- ═══════════════ APP BUILDER ═══════════════
local function buildApp(mode)
    clearApp()
    local T = Themes[mode]
    if not T then return end

    mainGui = Instance.new("ScreenGui")
    mainGui.Name = "YunoPlayer"
    mainGui.IgnoreGuiInset = true
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() mainGui.Parent = CoreGui end)
    if not mainGui.Parent then mainGui.Parent = player:WaitForChild("PlayerGui") end

    -- Root frame
    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.new(0, 1000, 0, 650)
    root.Position = UDim2.new(0.5, -500, 0.5, -325)
    root.BackgroundColor3 = T.bg
    root.BorderSizePixel = 0
    root.Active = true
    root.Parent = mainGui
    mainRoot = root
    corner(root, 16)
    stroke(root, T.accent, 2, 0.5)

    -- Subtle inner glow border
    local innerBorder = Instance.new("Frame")
    innerBorder.Size = UDim2.new(1, -4, 1, -4)
    innerBorder.Position = UDim2.new(0, 2, 0, 2)
    innerBorder.BackgroundTransparency = 1
    innerBorder.BorderSizePixel = 0
    innerBorder.Parent = root
    corner(innerBorder, 14)
    local ibStroke = Instance.new("UIStroke")
    ibStroke.Color = T.accent
    ibStroke.Thickness = 1
    ibStroke.Transparency = 0.85
    ibStroke.Parent = innerBorder

    -- UIScale
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = root

    local function resize()
        local vp = workspace.CurrentCamera.ViewportSize
        uiScale.Scale = math.min(vp.X * 0.85 / 1000, vp.Y * 0.85 / 650, 1)
        root.Position = UDim2.new(0.5, -500, 0.5, -325)
    end
    resize()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)

    -- ═══════════ FULLY DRAGGABLE ═══════════
    local dragging, dragStart, startPos
    root.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 
           and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if isInteractiveTarget(input) then return end
        dragging = true
        dragStart = input.Position
        startPos = root.Position
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement 
                          or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            local vp = workspace.CurrentCamera.ViewportSize
            local newX = startPos.X.Offset + d.X
            local newY = startPos.Y.Offset + d.Y
            newX = math.clamp(newX, -1000, vp.X - 200)
            newY = math.clamp(newY, -100, vp.Y - 100)
            root.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ═══════════ SIDEBAR ═══════════
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 210, 1, 0)
    sidebar.BackgroundColor3 = T.side
    sidebar.BorderSizePixel = 0
    sidebar.Parent = root
    corner(sidebar, 16)
    -- Right square corners
    local sideFix = Instance.new("Frame")
    sideFix.Size = UDim2.new(0, 16, 1, 0)
    sideFix.Position = UDim2.new(1, -16, 0, 0)
    sideFix.BackgroundColor3 = T.side
    sideFix.BorderSizePixel = 0
    sideFix.ZIndex = 1
    sideFix.Parent = sidebar

    -- Logo with glow
    local logoBox = Instance.new("Frame")
    logoBox.Size = UDim2.new(0, 48, 0, 48)
    logoBox.Position = UDim2.new(0, 20, 0, 22)
    logoBox.BackgroundTransparency = 1
    logoBox.Parent = sidebar

    local logoGlow = Instance.new("ImageLabel")
    logoGlow.Size = UDim2.new(1, 20, 1, 20)
    logoGlow.Position = UDim2.fromScale(0.5, 0.5)
    logoGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    logoGlow.BackgroundTransparency = 1
    logoGlow.Image = "rbxassetid://4996891970"
    logoGlow.ImageColor3 = T.accent
    logoGlow.ImageTransparency = 0.55
    logoGlow.Parent = logoBox

    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.fromScale(1, 1)
    logo.BackgroundTransparency = 1
    logo.Image = T.logo
    logo.Parent = logoBox

    local brand = Instance.new("TextLabel")
    brand.Size = UDim2.new(1, -85, 0, 22)
    brand.Position = UDim2.new(0, 76, 0, 26)
    brand.BackgroundTransparency = 1
    brand.Text = "YUNO"
    brand.TextColor3 = T.text
    brand.Font = Enum.Font.GothamBlack
    brand.TextSize = 20
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.Parent = sidebar

    local brandSub = Instance.new("TextLabel")
    brandSub.Size = UDim2.new(1, -85, 0, 14)
    brandSub.Position = UDim2.new(0, 76, 0, 48)
    brandSub.BackgroundTransparency = 1
    brandSub.Text = T.name
    brandSub.TextColor3 = T.accent
    brandSub.Font = Enum.Font.GothamBold
    brandSub.TextSize = 10
    brandSub.TextXAlignment = Enum.TextXAlignment.Left
    brandSub.Parent = sidebar

    -- Nav tabs
    local tabDefs = {
        {id = "home",    icon = "⌂", label = "Accueil"},
        {id = "search",  icon = "⌕", label = "Recherche"},
        {id = "library", icon = "♪", label = "Bibliothèque"},
        {id = "config",  icon = "⚙", label = "Config"},
    }

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -24, 0, 260)
    tabContainer.Position = UDim2.new(0, 12, 0, 100)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabContainer

    local function switchTab(tabId)
        currentTab = tabId
        for k, v in pairs(tabsRef) do
            if k == tabId then
                tw(v.btn, TweenInfo.new(0.2), { BackgroundColor3 = T.accent })
                v.btn.BackgroundTransparency = 0
                v.icon.TextColor3 = Color3.fromRGB(255,255,255)
            else
                tw(v.btn, TweenInfo.new(0.2), { BackgroundColor3 = T.card })
                v.btn.BackgroundTransparency = 0.4
                v.icon.TextColor3 = T.sub
            end
        end
        homeContentRef.Visible = (tabId == "home")
        searchContentRef.Visible = (tabId == "search")
        configContentRef.Visible = (tabId == "config")
        if playlistSidebarRef then playlistSidebarRef.Visible = (tabId ~= "config") end
    end

    for _, tab in ipairs(tabDefs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 50)
        btn.BackgroundColor3 = T.card
        btn.BackgroundTransparency = 0.4
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = tabContainer
        corner(btn, T.radius)

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 34, 0, 34)
        icon.Position = UDim2.new(0, 8, 0, 8)
        icon.BackgroundTransparency = 1
        icon.Text = tab.icon
        icon.TextColor3 = T.sub
        icon.TextSize = 22
        icon.Font = Enum.Font.GothamBold
        icon.Parent = btn

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -58, 1, 0)
        lbl.Position = UDim2.new(0, 50, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = tab.label
        lbl.TextColor3 = T.text
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        btn.MouseEnter:Connect(function()
            if tab.id ~= currentTab then
                tw(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.2 })
            end
        end)
        btn.MouseLeave:Connect(function()
            if tab.id ~= currentTab then
                tw(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.4 })
            end
        end)
        btn.MouseButton1Click:Connect(function()
            switchTab(tab.id)
        end)

        tabsRef[tab.id] = { btn = btn, icon = icon, label = lbl }
    end

    -- ═══════════ CLOSE + MINI ═══════════
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 34, 0, 34)
    closeBtn.Position = UDim2.new(1, -44, 0, 12)
    closeBtn.BackgroundColor3 = T.card
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = T.text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.ZIndex = 2
    closeBtn.Parent = root
    corner(closeBtn, 8)

    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn, TweenInfo.new(0.15), { BackgroundColor3 = T.accent })
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, TweenInfo.new(0.15), { BackgroundColor3 = T.card })
    end)

    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 56, 0, 56)
    miniBtn.Position = UDim2.new(0, 20, 0, 20)
    miniBtn.BackgroundColor3 = T.accent
    miniBtn.Text = "♪"
    miniBtn.TextColor3 = Color3.fromRGB(255,255,255)
    miniBtn.Font = Enum.Font.GothamBlack
    miniBtn.TextSize = 26
    miniBtn.Visible = false
    miniBtn.Parent = mainGui
    corner(miniBtn, 28)
    stroke(miniBtn, Color3.fromRGB(255,255,255), 2, 0.3)
    local miniGlow = addGlow(miniBtn, T.accent, 30)

    closeBtn.MouseButton1Click:Connect(function()
        root.Visible = false
        miniBtn.Visible = true
    end)
    miniBtn.MouseButton1Click:Connect(function()
        root.Visible = true
        miniBtn.Visible = false
    end)

    -- Mini button drag
    local miniDrag, miniStart, miniPos
    miniBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
           or input.UserInputType == Enum.UserInputType.Touch then
            miniDrag = true
            miniStart = input.Position
            miniPos = miniBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if miniDrag and (input.UserInputType == Enum.UserInputType.MouseMovement 
                         or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - miniStart
            miniBtn.Position = UDim2.new(miniPos.X.Scale, miniPos.X.Offset + d.X, miniPos.Y.Scale, miniPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 
           or input.UserInputType == Enum.UserInputType.Touch then
            miniDrag = false
        end
    end)

    -- ═══════════ MAIN CONTENT ═══════════
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -470, 1, -120)
    content.Position = UDim2.new(0, 210, 0, 0)
    content.BackgroundTransparency = 1
    content.Parent = root

    -- ═══════════ PLAYLIST SIDEBAR ═══════════
    playlistSidebarRef = Instance.new("Frame")
    playlistSidebarRef.Size = UDim2.new(0, 250, 1, -120)
    playlistSidebarRef.Position = UDim2.new(1, -260, 0, 0)
    playlistSidebarRef.BackgroundColor3 = T.panel
    playlistSidebarRef.BorderSizePixel = 0
    playlistSidebarRef.Parent = root
    corner(playlistSidebarRef, 12)

    local plTitle = Instance.new("TextLabel")
    plTitle.Size = UDim2.new(1, -30, 0, 30)
    plTitle.Position = UDim2.new(0, 15, 0, 12)
    plTitle.BackgroundTransparency = 1
    plTitle.Text = "▶  File d'attente"
    plTitle.TextColor3 = T.text
    plTitle.Font = Enum.Font.GothamBlack
    plTitle.TextSize = 14
    plTitle.TextXAlignment = Enum.TextXAlignment.Left
    plTitle.Parent = playlistSidebarRef

    local plEmpty = Instance.new("TextLabel")
    plEmpty.Size = UDim2.new(1, -30, 0, 40)
    plEmpty.Position = UDim2.new(0, 15, 0, 60)
    plEmpty.BackgroundTransparency = 1
    plEmpty.Text = "Aucune piste\nRecherche pour commencer 🎵"
    plEmpty.TextColor3 = T.sub
    plEmpty.Font = Enum.Font.Gotham
    plEmpty.TextSize = 11
    plEmpty.TextWrapped = true
    plEmpty.Parent = playlistSidebarRef

    playlistItemsRef = Instance.new("ScrollingFrame")
    playlistItemsRef.Size = UDim2.new(1, -20, 1, -55)
    playlistItemsRef.Position = UDim2.new(0, 10, 0, 50)
    playlistItemsRef.BackgroundTransparency = 1
    playlistItemsRef.BorderSizePixel = 0
    playlistItemsRef.ScrollBarThickness = 3
    playlistItemsRef.ScrollBarImageColor3 = T.accent
    playlistItemsRef.CanvasSize = UDim2.new(0, 0, 0, 0)
    playlistItemsRef.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playlistItemsRef.Parent = playlistSidebarRef

    local plLayout = Instance.new("UIListLayout")
    plLayout.Padding = UDim.new(0, 6)
    plLayout.Parent = playlistItemsRef

    -- ═══════════ PLAYER BAR ═══════════
    local playerBar = Instance.new("Frame")
    playerBar.Size = UDim2.new(1, -30, 0, 108)
    playerBar.Position = UDim2.new(0, 15, 1, -118)
    playerBar.BackgroundColor3 = T.panel
    playerBar.BorderSizePixel = 0
    playerBar.Parent = root
    corner(playerBar, 14)
    stroke(playerBar, T.card, 1, 0.5)

    -- Album art with glow
    local albumBox = Instance.new("Frame")
    albumBox.Size = UDim2.new(0, 72, 0, 72)
    albumBox.Position = UDim2.new(0, 18, 0, 18)
    albumBox.BackgroundTransparency = 1
    albumBox.Parent = playerBar

    local albumGlow = Instance.new("ImageLabel")
    albumGlow.Size = UDim2.new(1, 20, 1, 20)
    albumGlow.Position = UDim2.fromScale(0.5, 0.5)
    albumGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    albumGlow.BackgroundTransparency = 1
    albumGlow.Image = "rbxassetid://4996891970"
    albumGlow.ImageColor3 = T.accent
    albumGlow.ImageTransparency = 0.7
    albumGlow.Parent = albumBox

    thumbRef = Instance.new("ImageLabel")
    thumbRef.Size = UDim2.fromScale(1, 1)
    thumbRef.BackgroundColor3 = T.card
    thumbRef.Image = T.logo
    thumbRef.Parent = albumBox
    corner(thumbRef, T.radius)
    stroke(thumbRef, T.card, 1)

    titleRef = Instance.new("TextLabel")
    titleRef.Size = UDim2.new(0, 240, 0, 20)
    titleRef.Position = UDim2.new(0, 104, 0, 22)
    titleRef.BackgroundTransparency = 1
    titleRef.Text = "Aucune piste"
    titleRef.TextColor3 = T.text
    titleRef.Font = Enum.Font.GothamBold
    titleRef.TextSize = 13
    titleRef.TextTruncate = Enum.TextTruncate.AtEnd
    titleRef.TextXAlignment = Enum.TextXAlignment.Left
    titleRef.Parent = playerBar

    authorRef = Instance.new("TextLabel")
    authorRef.Size = UDim2.new(0, 240, 0, 16)
    authorRef.Position = UDim2.new(0, 104, 0, 46)
    authorRef.BackgroundTransparency = 1
    authorRef.Text = "Prêt à jouer"
    authorRef.TextColor3 = T.sub
    authorRef.Font = Enum.Font.Gotham
    authorRef.TextSize = 11
    authorRef.TextTruncate = Enum.TextTruncate.AtEnd
    authorRef.TextXAlignment = Enum.TextXAlignment.Left
    authorRef.Parent = playerBar

    -- Controls
    local ctrlFrame = Instance.new("Frame")
    ctrlFrame.Size = UDim2.new(0, 320, 0, 44)
    ctrlFrame.Position = UDim2.new(0.5, -160, 0, 14)
    ctrlFrame.BackgroundTransparency = 1
    ctrlFrame.Parent = playerBar

    local prevBtn = Instance.new("TextButton")
    prevBtn.Size = UDim2.new(0, 34, 0, 34)
    prevBtn.Position = UDim2.new(0, 78, 0, 5)
    prevBtn.BackgroundTransparency = 1
    prevBtn.Text = "⏮"
    prevBtn.TextColor3 = T.text
    prevBtn.Font = Enum.Font.GothamBold
    prevBtn.TextSize = 20
    prevBtn.Parent = ctrlFrame

    playBtnRef = Instance.new("TextButton")
    playBtnRef.Size = UDim2.new(0, 44, 0, 44)
    playBtnRef.Position = UDim2.new(0.5, -22, 0, 0)
    playBtnRef.BackgroundColor3 = T.accent
    playBtnRef.Text = "▶"
    playBtnRef.TextColor3 = Color3.fromRGB(255,255,255)
    playBtnRef.Font = Enum.Font.GothamBold
    playBtnRef.TextSize = 18
    playBtnRef.AutoButtonColor = false
    playBtnRef.Parent = ctrlFrame
    corner(playBtnRef, 22)

    local nextBtn = Instance.new("TextButton")
    nextBtn.Size = UDim2.new(0, 34, 0, 34)
    nextBtn.Position = UDim2.new(0, 208, 0, 5)
    nextBtn.BackgroundTransparency = 1
    nextBtn.Text = "⏭"
    nextBtn.TextColor3 = T.text
    nextBtn.Font = Enum.Font.GothamBold
    nextBtn.TextSize = 20
    nextBtn.Parent = ctrlFrame

    -- Progress bar with click seek
    progressBgRef = Instance.new("Frame")
    progressBgRef.Size = UDim2.new(0, 320, 0, 5)
    progressBgRef.Position = UDim2.new(0.5, -160, 0, 72)
    progressBgRef.BackgroundColor3 = T.card
    progressBgRef.BorderSizePixel = 0
    progressBgRef.ClipsDescendants = true
    progressBgRef.Parent = playerBar
    corner(progressBgRef, 3)

    progressFillRef = Instance.new("Frame")
    progressFillRef.Size = UDim2.new(0, 0, 1, 0)
    progressFillRef.BackgroundColor3 = T.accent
    progressFillRef.BorderSizePixel = 0
    progressFillRef.Parent = progressBgRef
    corner(progressFillRef, 3)

    local fillGradPlayer = Instance.new("UIGradient")
    fillGradPlayer.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.accent),
        ColorSequenceKeypoint.new(1, T.accent2),
    }
    fillGradPlayer.Parent = progressFillRef

    -- Seek on click
    progressBgRef.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local media = (currentType == "video") and videoFrameRef or sound
            if not media or not media.TimeLength or media.TimeLength <= 0 then return end
            local pct = math.clamp((input.Position.X - progressBgRef.AbsolutePosition.X) / progressBgRef.AbsoluteSize.X, 0, 1)
            media.TimePosition = pct * media.TimeLength
        end
    end)

    timeRef = Instance.new("TextLabel")
    timeRef.Size = UDim2.new(0, 320, 0, 14)
    timeRef.Position = UDim2.new(0.5, -160, 0, 82)
    timeRef.BackgroundTransparency = 1
    timeRef.Text = "00:00 / 00:00"
    timeRef.TextColor3 = T.sub
    timeRef.Font = Enum.Font.Gotham
    timeRef.TextSize = 10
    timeRef.TextXAlignment = Enum.TextXAlignment.Center
    timeRef.Parent = playerBar

    -- Volume
    local volIcon = Instance.new("TextLabel")
    volIcon.Size = UDim2.new(0, 24, 0, 24)
    volIcon.Position = UDim2.new(1, -90, 0, 42)
    volIcon.BackgroundTransparency = 1
    volIcon.Text = "🔊"
    volIcon.TextSize = 16
    volIcon.Parent = playerBar

    local volBar = Instance.new("Frame")
    volBar.Size = UDim2.new(0, 60, 0, 4)
    volBar.Position = UDim2.new(1, -62, 0, 52)
    volBar.BackgroundColor3 = T.card
    volBar.BorderSizePixel = 0
    volBar.Parent = playerBar
    corner(volBar, 2)

    local volFill = Instance.new("Frame")
    volFill.Size = UDim2.new(1, 0, 1, 0)
    volFill.BackgroundColor3 = T.accent
    volFill.BorderSizePixel = 0
    volFill.Parent = volBar
    corner(volFill, 2)

    -- ═══════════ HOME TAB ═══════════
    homeContentRef = Instance.new("Frame")
    homeContentRef.Size = UDim2.fromScale(1, 1)
    homeContentRef.BackgroundTransparency = 1
    homeContentRef.Parent = content
    homeContentRef.Visible = true

    -- Hero banner
    local hero = Instance.new("Frame")
    hero.Size = UDim2.new(1, -20, 0, 200)
    hero.Position = UDim2.new(0, 10, 0, 12)
    hero.BackgroundColor3 = T.card
    hero.BorderSizePixel = 0
    hero.ClipsDescendants = true
    hero.Parent = homeContentRef
    corner(hero, T.radius)

    local heroGrad = Instance.new("UIGradient")
    heroGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, T.accent),
        ColorSequenceKeypoint.new(1, T.bg)
    }
    heroGrad.Rotation = 30
    heroGrad.Parent = hero

    local heroImg = Instance.new("ImageLabel")
    heroImg.Size = UDim2.new(0, 280, 1, 0)
    heroImg.Position = UDim2.new(1, -280, 0, 0)
    heroImg.BackgroundTransparency = 1
    heroImg.Image = T.hero
    heroImg.ScaleType = Enum.ScaleType.Crop
    heroImg.ImageTransparency = 0.1
    heroImg.Parent = hero

    -- Gradient fade overlay
    local heroFade = Instance.new("Frame")
    heroFade.Size = UDim2.new(1, 0, 1, 0)
    heroFade.BackgroundColor3 = T.card
    heroFade.BorderSizePixel = 0
    heroFade.BackgroundTransparency = 0
    heroFade.Parent = hero
    corner(heroFade, T.radius)
    local heroFadeGrad = Instance.new("UIGradient")
    heroFadeGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.55, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    }
    heroFadeGrad.Parent = heroFade

    local heroContent = Instance.new("Frame")
    heroContent.Size = UDim2.new(1, 0, 1, 0)
    heroContent.BackgroundTransparency = 1
    heroContent.Parent = hero

    local heroTag = Instance.new("TextLabel")
    heroTag.Size = UDim2.new(0, 100, 0, 22)
    heroTag.Position = UDim2.new(0, 24, 0, 26)
    heroTag.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    heroTag.BackgroundTransparency = 0.5
    heroTag.Text = "PREMIUM"
    heroTag.TextColor3 = Color3.fromRGB(255,255,255)
    heroTag.Font = Enum.Font.GothamBold
    heroTag.TextSize = 10
    heroTag.Parent = heroContent
    corner(heroTag, 11)

    local heroTitle = Instance.new("TextLabel")
    heroTitle.Size = UDim2.new(0, 500, 0, 34)
    heroTitle.Position = UDim2.new(0, 24, 0, 58)
    heroTitle.BackgroundTransparency = 1
    heroTitle.Text = "Bienvenue sur YUNO 👋"
    heroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    heroTitle.Font = Enum.Font.GothamBlack
    heroTitle.TextSize = 24
    heroTitle.TextXAlignment = Enum.TextXAlignment.Left
    heroTitle.Parent = heroContent

    local heroSub = Instance.new("TextLabel")
    heroSub.Size = UDim2.new(0, 480, 0, 40)
    heroSub.Position = UDim2.new(0, 24, 0, 100)
    heroSub.BackgroundTransparency = 1
    heroSub.Text = "Mode " .. T.name .. " • Découvre, écoute et savoure"
    heroSub.TextColor3 = Color3.fromRGB(230, 230, 230)
    heroSub.Font = Enum.Font.Gotham
    heroSub.TextSize = 13
    heroSub.TextWrapped = true
    heroSub.TextXAlignment = Enum.TextXAlignment.Left
    heroSub.Parent = heroContent

    local heroCta = Instance.new("TextButton")
    heroCta.Size = UDim2.new(0, 160, 0, 40)
    heroCta.Position = UDim2.new(0, 24, 1, -56)
    heroCta.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    heroCta.Text = "▶  Chercher"
    heroCta.TextColor3 = T.accent
    heroCta.Font = Enum.Font.GothamBold
    heroCta.TextSize = 14
    heroCta.AutoButtonColor = false
    heroCta.Parent = heroContent
    corner(heroCta, 10)

    heroCta.MouseEnter:Connect(function()
        tw(heroCta, TweenInfo.new(0.15), { Size = UDim2.new(0, 170, 0, 44), Position = UDim2.new(0, 24, 1, -58) })
    end)
    heroCta.MouseLeave:Connect(function()
        tw(heroCta, TweenInfo.new(0.15), { Size = UDim2.new(0, 160, 0, 40), Position = UDim2.new(0, 24, 1, -56) })
    end)
    heroCta.MouseButton1Click:Connect(function()
        switchTab("search")
    end)

    -- Quick access label
    local quickTitle = Instance.new("TextLabel")
    quickTitle.Size = UDim2.new(1, -20, 0, 24)
    quickTitle.Position = UDim2.new(0, 10, 0, 222)
    quickTitle.BackgroundTransparency = 1
    quickTitle.Text = "Découvre"
    quickTitle.TextColor3 = T.text
    quickTitle.Font = Enum.Font.GothamBlack
    quickTitle.TextSize = 16
    quickTitle.TextXAlignment = Enum.TextXAlignment.Left
    quickTitle.Parent = homeContentRef

    -- Genre cards scroll
    local quickScroll = Instance.new("ScrollingFrame")
    quickScroll.Size = UDim2.new(1, -20, 0, 145)
    quickScroll.Position = UDim2.new(0, 10, 0, 252)
    quickScroll.BackgroundTransparency = 1
    quickScroll.BorderSizePixel = 0
    quickScroll.ScrollBarThickness = 3
    quickScroll.ScrollBarImageColor3 = T.accent
    quickScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    quickScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    quickScroll.ScrollingDirection = Enum.ScrollingDirection.X
    quickScroll.Parent = homeContentRef

    local quickLayout = Instance.new("UIListLayout")
    quickLayout.FillDirection = Enum.FillDirection.Horizontal
    quickLayout.Padding = UDim.new(0, 10)
    quickLayout.Parent = quickScroll

    local genres = {
        {name = "Lo-fi",   color = T.accent,  icon = "🎧"},
        {name = "Pop",     color = T.accent2, icon = "🎤"},
        {name = "Rock",    color = T.accent,  icon = "🎸"},
        {name = "Chill",   color = T.accent2, icon = "🌙"},
        {name = "Rap",     color = T.accent,  icon = "🎙️"},
        {name = "EDM",     color = T.accent2, icon = "🎹"},
    }

    for _, g in ipairs(genres) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 145, 0, 135)
        card.BackgroundColor3 = g.color
        card.BorderSizePixel = 0
        card.Parent = quickScroll
        corner(card, T.radius)

        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, g.color),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(g.color.R * 0.3, g.color.G * 0.3, g.color.B * 0.3))
        }
        grad.Rotation = 45
        grad.Parent = card

        local iconL = Instance.new("TextLabel")
        iconL.Size = UDim2.new(0, 40, 0, 40)
        iconL.Position = UDim2.new(1, -50, 0, 12)
        iconL.BackgroundTransparency = 1
        iconL.Text = g.icon
        iconL.TextSize = 32
        iconL.Parent = card

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 30)
        lbl.Position = UDim2.new(0, 12, 1, -42)
        lbl.BackgroundTransparency = 1
        lbl.Text = g.name
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Font = Enum.Font.GothamBlack
        lbl.TextSize = 18
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = card

        card.MouseEnter:Connect(function()
            tw(card, TweenInfo.new(0.18), { Size = UDim2.new(0, 155, 0, 145) })
        end)
        card.MouseLeave:Connect(function()
            tw(card, TweenInfo.new(0.18), { Size = UDim2.new(0, 145, 0, 135) })
        end)
        card.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                switchTab("search")
                if searchResultsRef and searchResultsRef.box then
                    searchResultsRef.box.Text = g.name .. " music"
                    if searchResultsRef.doSearch then
                        searchResultsRef.doSearch(g.name .. " music")
                    end
                end
            end
        end)
    end

    -- ═══════════ SEARCH TAB ═══════════
    searchContentRef = Instance.new("Frame")
    searchContentRef.Size = UDim2.fromScale(1, 1)
    searchContentRef.BackgroundTransparency = 1
    searchContentRef.Parent = content
    searchContentRef.Visible = false

    local searchBar = Instance.new("Frame")
    searchBar.Size = UDim2.new(1, -20, 0, 48)
    searchBar.Position = UDim2.new(0, 10, 0, 12)
    searchBar.BackgroundColor3 = T.card
    searchBar.BorderSizePixel = 0
    searchBar.Parent = searchContentRef
    corner(searchBar, T.radius)
    stroke(searchBar, T.accent, 1, 0.7)

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 44, 1, 0)
    searchIcon.Position = UDim2.new(0, 6, 0, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "⌕"
    searchIcon.TextColor3 = T.sub
    searchIcon.TextSize = 20
    searchIcon.Parent = searchBar

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -160, 1, 0)
    searchBox.Position = UDim2.new(0, 46, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Rechercher une musique ou vidéo..."
    searchBox.PlaceholderColor3 = T.sub
    searchBox.Text = ""
    searchBox.TextColor3 = T.text
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchBar

    local searchBtn = Instance.new("TextButton")
    searchBtn.Size = UDim2.new(0, 96, 1, -10)
    searchBtn.Position = UDim2.new(1, -101, 0, 5)
    searchBtn.BackgroundColor3 = T.accent
    searchBtn.Text = "Chercher"
    searchBtn.TextColor3 = Color3.fromRGB(255,255,255)
    searchBtn.Font = Enum.Font.GothamBold
    searchBtn.TextSize = 12
    searchBtn.AutoButtonColor = false
    searchBtn.Parent = searchBar
    corner(searchBtn, 6)

    searchBtn.MouseEnter:Connect(function()
        tw(searchBtn, TweenInfo.new(0.15), { BackgroundColor3 = T.accent2 })
    end)
    searchBtn.MouseLeave:Connect(function()
        tw(searchBtn, TweenInfo.new(0.15), { BackgroundColor3 = T.accent })
    end)

    local resultsFrame = Instance.new("ScrollingFrame")
    resultsFrame.Size = UDim2.new(1, -20, 1, -85)
    resultsFrame.Position = UDim2.new(0, 10, 0, 72)
    resultsFrame.BackgroundTransparency = 1
    resultsFrame.BorderSizePixel = 0
    resultsFrame.ScrollBarThickness = 4
    resultsFrame.ScrollBarImageColor3 = T.accent
    resultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    resultsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    resultsFrame.Parent = searchContentRef

    local resultsLayout = Instance.new("UIListLayout")
    resultsLayout.Padding = UDim.new(0, 8)
    resultsLayout.Parent = resultsFrame

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 1, -25)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = T.sub
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = searchContentRef

    statusRef = status

    -- ═══════════ CONFIG TAB ═══════════
    configContentRef = Instance.new("Frame")
    configContentRef.Size = UDim2.fromScale(1, 1)
    configContentRef.BackgroundTransparency = 1
    configContentRef.Parent = content
    configContentRef.Visible = false

    local cfgTitle = Instance.new("TextLabel")
    cfgTitle.Size = UDim2.new(1, -20, 0, 30)
    cfgTitle.Position = UDim2.new(0, 10, 0, 12)
    cfgTitle.BackgroundTransparency = 1
    cfgTitle.Text = "⚙  Configuration"
    cfgTitle.TextColor3 = T.text
    cfgTitle.Font = Enum.Font.GothamBlack
    cfgTitle.TextSize = 20
    cfgTitle.TextXAlignment = Enum.TextXAlignment.Left
    cfgTitle.Parent = configContentRef

    -- Switch mode card
    local switchCard = Instance.new("Frame")
    switchCard.Size = UDim2.new(1, -20, 0, 150)
    switchCard.Position = UDim2.new(0, 10, 0, 60)
    switchCard.BackgroundColor3 = T.card
    switchCard.BorderSizePixel = 0
    switchCard.Parent = configContentRef
    corner(switchCard, T.radius)
    stroke(switchCard, T.accent, 1, 0.7)

    local scIconBox = Instance.new("Frame")
    scIconBox.Size = UDim2.new(0, 64, 0, 64)
    scIconBox.Position = UDim2.new(0, 22, 0, 22)
    scIconBox.BackgroundTransparency = 1
    scIconBox.Parent = switchCard

    local scIconGlow = Instance.new("ImageLabel")
    scIconGlow.Size = UDim2.new(1, 20, 1, 20)
    scIconGlow.Position = UDim2.fromScale(0.5, 0.5)
    scIconGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    scIconGlow.BackgroundTransparency = 1
    scIconGlow.Image = "rbxassetid://4996891970"
    scIconGlow.ImageColor3 = T.accent
    scIconGlow.ImageTransparency = 0.55
    scIconGlow.Parent = scIconBox

    local scIcon = Instance.new("ImageLabel")
    scIcon.Size = UDim2.fromScale(1, 1)
    scIcon.BackgroundTransparency = 1
    scIcon.Image = T.logo
    scIcon.Parent = scIconBox

    local scTitle = Instance.new("TextLabel")
    scTitle.Size = UDim2.new(1, -140, 0, 22)
    scTitle.Position = UDim2.new(0, 106, 0, 24)
    scTitle.BackgroundTransparency = 1
    scTitle.Text = "Mode actuel : " .. T.name
    scTitle.TextColor3 = T.text
    scTitle.Font = Enum.Font.GothamBlack
    scTitle.TextSize = 15
    scTitle.TextXAlignment = Enum.TextXAlignment.Left
    scTitle.Parent = switchCard

    local scDesc = Instance.new("TextLabel")
    scDesc.Size = UDim2.new(1, -140, 0, 40)
    scDesc.Position = UDim2.new(0, 106, 0, 50)
    scDesc.BackgroundTransparency = 1
    scDesc.Text = "Change d'interface à tout moment.\nTa playlist reste conservée."
    scDesc.TextColor3 = T.sub
    scDesc.Font = Enum.Font.Gotham
    scDesc.TextSize = 11
    scDesc.TextWrapped = true
    scDesc.TextXAlignment = Enum.TextXAlignment.Left
    scDesc.TextYAlignment = Enum.TextYAlignment.Top
    scDesc.Parent = switchCard

    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(1, -44, 0, 42)
    switchBtn.Position = UDim2.new(0, 22, 1, -56)
    switchBtn.BackgroundColor3 = T.accent
    switchBtn.Text = "🔄  Changer de mode"
    switchBtn.TextColor3 = Color3.fromRGB(255,255,255)
    switchBtn.Font = Enum.Font.GothamBold
    switchBtn.TextSize = 13
    switchBtn.AutoButtonColor = false
    switchBtn.Parent = switchCard
    corner(switchBtn, 8)

    switchBtn.MouseEnter:Connect(function()
        tw(switchBtn, TweenInfo.new(0.15), { BackgroundColor3 = T.accent2 })
    end)
    switchBtn.MouseLeave:Connect(function()
        tw(switchBtn, TweenInfo.new(0.15), { BackgroundColor3 = T.accent })
    end)

    -- Info card
    local infoCard = Instance.new("Frame")
    infoCard.Size = UDim2.new(1, -20, 0, 110)
    infoCard.Position = UDim2.new(0, 10, 0, 230)
    infoCard.BackgroundColor3 = T.card
    infoCard.BorderSizePixel = 0
    infoCard.Parent = configContentRef
    corner(infoCard, T.radius)

    local infoTitle = Instance.new("TextLabel")
    infoTitle.Size = UDim2.new(1, -40, 0, 24)
    infoTitle.Position = UDim2.new(0, 20, 0, 16)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "ℹ  À propos"
    infoTitle.TextColor3 = T.text
    infoTitle.Font = Enum.Font.GothamBlack
    infoTitle.TextSize = 14
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    infoTitle.Parent = infoCard

    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -40, 0, 60)
    infoText.Position = UDim2.new(0, 20, 0, 44)
    infoText.BackgroundTransparency = 1
    infoText.Text = "YUNO PLAYER • v2.0\nRecherche & lecture YouTube / Vidéos • Basé sur YMP V8.5\nDéveloppé avec ❤ pour la communauté"
    infoText.TextColor3 = T.sub
    infoText.Font = Enum.Font.Gotham
    infoText.TextSize = 11
    infoText.TextWrapped = true
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.Parent = infoCard

    switchBtn.MouseButton1Click:Connect(function()
        local target = (mode == "youtube") and "music" or "youtube"
        Config.mode = target
        SaveConfig()
        notify("🔄 Changement", "Passage en " .. Themes[target].name, 3)
        task.wait(0.2)
        buildApp(target)
    end)

    -- ═══════════ PLAYER LOGIC ═══════════
    local function updateProgress()
        local media = (currentType == "video") and videoFrameRef or sound
        if not media then return end
        local len = media.TimeLength or 0
        local pos = media.TimePosition or 0
        if len > 0 then
            progressFillRef.Size = UDim2.new(pos / len, 0, 1, 0)
        end
        timeRef.Text = fmtTime(pos) .. " / " .. fmtTime(len)
    end

    task.spawn(function()
        while mainGui and mainGui.Parent do
            task.wait(0.2)
            updateProgress()
        end
    end)

    -- Playlist render
    local function renderPlaylist()
        for _, c in ipairs(playlistItemsRef:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        plEmpty.Visible = (#playlist == 0)
        for i, entry in ipairs(playlist) do
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, -6, 0, 48)
            item.BackgroundColor3 = (i == currentIdx) and T.cardHi or T.card
            item.BorderSizePixel = 0
            item.Parent = playlistItemsRef
            corner(item, T.radius)

            if i == currentIdx then
                stroke(item, T.accent, 1, 0)
            end

            local tImg = Instance.new("ImageLabel")
            tImg.Size = UDim2.new(0, 40, 0, 40)
            tImg.Position = UDim2.new(0, 4, 0, 4)
            tImg.BackgroundColor3 = T.panel
            tImg.Image = entry.thumb or ""
            tImg.ScaleType = Enum.ScaleType.Crop
            tImg.Parent = item
            corner(tImg, 6)

            local tName = Instance.new("TextLabel")
            tName.Size = UDim2.new(1, -54, 0, 16)
            tName.Position = UDim2.new(0, 50, 0, 6)
            tName.BackgroundTransparency = 1
            tName.Text = entry.name or ""
            tName.TextColor3 = T.text
            tName.Font = Enum.Font.GothamBold
            tName.TextSize = 10
            tName.TextTruncate = Enum.TextTruncate.AtEnd
            tName.TextXAlignment = Enum.TextXAlignment.Left
            tName.Parent = item

            local tAuthor = Instance.new("TextLabel")
            tAuthor.Size = UDim2.new(1, -54, 0, 12)
            tAuthor.Position = UDim2.new(0, 50, 0, 26)
            tAuthor.BackgroundTransparency = 1
            tAuthor.Text = (entry.type == "video" and "🎬 " or "🎵 ") .. (entry.author or "")
            tAuthor.TextColor3 = T.sub
            tAuthor.Font = Enum.Font.Gotham
            tAuthor.TextSize = 9
            tAuthor.TextTruncate = Enum.TextTruncate.AtEnd
            tAuthor.TextXAlignment = Enum.TextXAlignment.Left
            tAuthor.Parent = item

            item.MouseButton1Click:Connect(function()
                currentIdx = i
                renderPlaylist()
                playEntry(entry)
            end)
        end
    end

    local function playEntry(entry)
        if isDownloading then
            notify("⏳", "Téléchargement en cours...", 4)
            return
        end
        isDownloading = true
        sound:Stop()
        if videoFrameRef then
            videoFrameRef.Visible = false
            videoFrameRef.Video = ""
        end
        thumbRef.Image = T.logo
        titleRef.Text = entry.name or "Chargement..."
        authorRef.Text = entry.author or ""
        if statusRef then statusRef.Text = "Préparation..." end

        local ytUrl = "https://youtu.be/" .. entry.id
        task.spawn(function()
            local fmt = (entry.type == "video") and "360" or "mp3"
            local ext = (entry.type == "video") and ".webm" or ".mp3"
            local dir = (entry.type == "video") and VIDEO or MUSIC
            local path = dir .. "/" .. entry.id .. ext

            if not isfile(path) then
                if statusRef then statusRef.Text = "⏳ Téléchargement (30-60s)..." end
                local dlUrl, err = downloadMedia(ytUrl, fmt)
                if not dlUrl then
                    notify("❌ Erreur", err or "Échoué", 5)
                    if statusRef then statusRef.Text = "❌ " .. (err or "Erreur") end
                    isDownloading = false
                    return
                end
                if statusRef then statusRef.Text = "💾 Récupération..." end
                local fr = req({Url=dlUrl, Method="GET"})
                if not fr or not fr.Body then
                    notify("❌ Erreur", "Fichier introuvable", 5)
                    isDownloading = false
                    return
                end
                writefile(path, fr.Body)
            end

            if statusRef then statusRef.Text = "▶ Lecture..." end
            local ok, asset = pcall(getcustomasset, path)
            if not ok then
                notify("❌ Erreur", "getcustomasset échoué", 5)
                isDownloading = false
                return
            end

            if entry.type == "video" then
                if not videoFrameRef then
                    videoFrameRef = Instance.new("VideoFrame")
                    videoFrameRef.Size = UDim2.new(0, 240, 0, 135)
                    videoFrameRef.Position = UDim2.new(0.5, -120, 0.5, -80)
                    videoFrameRef.BackgroundColor3 = T.card
                    videoFrameRef.ZIndex = 10
                    videoFrameRef.Parent = homeContentRef
                    corner(videoFrameRef, T.radius)
                    stroke(videoFrameRef, T.accent, 2)
                end
                videoFrameRef.Video = asset
                videoFrameRef.Volume = 1
                videoFrameRef.Visible = true
                videoFrameRef:Play()
                currentType = "video"
            else
                sound.SoundId = asset
                sound:Play()
                currentType = "audio"
            end

            isPlaying = true
            playBtnRef.Text = "⏸"
            isDownloading = false
            if statusRef then statusRef.Text = "✅ " .. (entry.name or "") end
            notify("🎵 " .. T.name, entry.name or "", 4)
        end)
    end

    local function playAtIndex(i)
        if #playlist == 0 then return end
        if i < 1 then i = #playlist end
        if i > #playlist then i = 1 end
        currentIdx = i
        renderPlaylist()
        playEntry(playlist[i])
    end

    playBtnRef.MouseButton1Click:Connect(function()
        if currentType == "video" and videoFrameRef then
            if videoFrameRef.IsPlaying then
                videoFrameRef:Pause(); playBtnRef.Text = "▶"; isPlaying = false
            else
                videoFrameRef:Play(); playBtnRef.Text = "⏸"; isPlaying = true
            end
        else
            if sound.IsPlaying then
                sound:Pause(); playBtnRef.Text = "▶"; isPlaying = false
            else
                if sound.SoundId ~= "" then
                    sound:Resume(); playBtnRef.Text = "⏸"; isPlaying = true
                else
                    playAtIndex(currentIdx)
                end
            end
        end
    end)

    nextBtn.MouseButton1Click:Connect(function() playAtIndex(currentIdx + 1) end)
    prevBtn.MouseButton1Click:Connect(function() playAtIndex(currentIdx - 1) end)
    sound.Ended:Connect(function() playAtIndex(currentIdx + 1) end)

    -- Search handler
    local function doSearch(query)
        if query == "" then return end
        for _, c in ipairs(resultsFrame:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        status.Text = "🔍 Recherche..."
        searchBtn.Active = false

        local results, err = searchYT(query)
        if not results then
            status.Text = (err == "rate") and "⏳ Trop de requêtes" or "❌ Aucun résultat"
            searchBtn.Active = true
            return
        end

        for i, r in ipairs(results) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -4, 0, 74)
            card.BackgroundColor3 = T.card
            card.BorderSizePixel = 0
            card.LayoutOrder = i
            card.Parent = resultsFrame
            corner(card, T.radius)

            card.MouseEnter:Connect(function()
                tw(card, TweenInfo.new(0.15), { BackgroundColor3 = T.cardHi })
            end)
            card.MouseLeave:Connect(function()
                tw(card, TweenInfo.new(0.15), { BackgroundColor3 = T.card })
            end)

            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(0, 108, 0, 62)
            img.Position = UDim2.new(0, 6, 0, 6)
            img.BackgroundColor3 = T.panel
            img.Image = r.thumbnail or ""
            img.ScaleType = Enum.ScaleType.Crop
            img.Parent = card
            corner(img, T.radius)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -290, 0, 18)
            nm.Position = UDim2.new(0, 122, 0, 10)
            nm.BackgroundTransparency = 1
            nm.Text = r.name or "?"
            nm.TextColor3 = T.text
            nm.Font = Enum.Font.GothamBold
            nm.TextSize = 12
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.Parent = card

            local au = Instance.new("TextLabel")
            au.Size = UDim2.new(1, -290, 0, 14)
            au.Position = UDim2.new(0, 122, 0, 32)
            au.BackgroundTransparency = 1
            au.Text = r.author or ""
            au.TextColor3 = T.sub
            au.Font = Enum.Font.Gotham
            au.TextSize = 10
            au.TextTruncate = Enum.TextTruncate.AtEnd
            au.TextXAlignment = Enum.TextXAlignment.Left
            au.Parent = card

            local du = Instance.new("TextLabel")
            du.Size = UDim2.new(0, 60, 0, 14)
            du.Position = UDim2.new(0, 122, 0, 50)
            du.BackgroundTransparency = 1
            du.Text = "⏱ " .. (r.duration or "?")
            du.TextColor3 = T.sub
            du.Font = Enum.Font.Gotham
            du.TextSize = 10
            du.TextXAlignment = Enum.TextXAlignment.Left
            du.Parent = card

            local playA = Instance.new("TextButton")
            playA.Size = UDim2.new(0, 48, 0, 32)
            playA.Position = UDim2.new(1, -110, 0, 21)
            playA.BackgroundColor3 = T.accent
            playA.Text = "🎵"
            playA.TextColor3 = Color3.fromRGB(255,255,255)
            playA.Font = Enum.Font.GothamBold
            playA.TextSize = 12
            playA.AutoButtonColor = false
            playA.Parent = card
            corner(playA, 6)

            local playV = Instance.new("TextButton")
            playV.Size = UDim2.new(0, 48, 0, 32)
            playV.Position = UDim2.new(1, -56, 0, 21)
            playV.BackgroundColor3 = T.accent2
            playV.Text = "🎬"
            playV.TextColor3 = Color3.fromRGB(255,255,255)
            playV.Font = Enum.Font.GothamBold
            playV.TextSize = 12
            playV.AutoButtonColor = false
            playV.Parent = card
            corner(playV, 6)

            playA.MouseEnter:Connect(function() tw(playA, TweenInfo.new(0.1), { Size = UDim2.new(0, 52, 0, 36) }) end)
            playA.MouseLeave:Connect(function() tw(playA, TweenInfo.new(0.1), { Size = UDim2.new(0, 48, 0, 32) }) end)

            playA.MouseButton1Click:Connect(function()
                table.insert(playlist, {
                    id = r.id, name = r.name, author = r.author,
                    thumb = r.thumbnail, type = "audio"
                })
                renderPlaylist()
                playAtIndex(#playlist)
            end)
            playV.MouseButton1Click:Connect(function()
                table.insert(playlist, {
                    id = r.id, name = r.name, author = r.author,
                    thumb = r.thumbnail, type = "video"
                })
                renderPlaylist()
                playAtIndex(#playlist)
            end)
        end

        status.Text = "✅ " .. #results .. " résultats"
        searchBtn.Active = true
    end

    searchResultsRef = { box = searchBox, doSearch = doSearch }

    searchBtn.MouseButton1Click:Connect(function() doSearch(searchBox.Text) end)
    searchBox.FocusLost:Connect(function(enter) if enter then doSearch(searchBox.Text) end end)

    -- ═══════════ INIT ═══════════
    switchTab("home")
    renderPlaylist()
    return mainGui
end

-- ═══════════════════════════════════════════════
--                   BOOTSTRAP
-- ═══════════════════════════════════════════════
if Config.mode and Themes[Config.mode] then
    buildApp(Config.mode)
else
    local ms = showModeSelect()
    task.spawn(function()
        while not modeChosen do task.wait(0.1) end
        task.wait(0.5)
        buildApp(modeChosen)
    end)
end

notify("🎵 YUNO PLAYER v2.0", "Bienvenue !", 5)
print("[YUNO PLAYER] Loaded — Mode: " .. tostring(Config.mode or "pending"))