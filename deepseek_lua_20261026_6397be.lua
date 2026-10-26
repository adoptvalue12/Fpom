-- =======================================================
-- YUNO PLAYER HUB - By Yuno
-- Script complet : Loading Screen + YouTube UI + Spotify UI
-- Draggable, Sans Emoji, Utilisation d'Asset IDs
-- =======================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Sécurité anti-double exécution
if getgenv().YunoPlayerHubLoaded then return end
getgenv().YunoPlayerHubLoaded = true

-- Dictionnaire des icônes (Assets)
local Assets = {
    YouTubeLogo = "rbxassetid://1275974022",
    SpotifyLogo = "rbxassetid://6154762067", -- Icône Spotify
    Play = "rbxassetid://6023563408",
    Pause = "rbxassetid://6023563423",
    Next = "rbxassetid://6023563450",
    Prev = "rbxassetid://6023563448",
    Search = "rbxassetid://3926305904",
    Home = "rbxassetid://6023563434",
    Library = "rbxassetid://6031075938",
    Like = "rbxassetid://6031090990",
    Share = "rbxassetid://6031094678",
    Volume = "rbxassetid://6031094678",
    Close = "rbxassetid://6031094678"
}

-- =======================================================
-- FONCTIONS UTILES
-- =======================================================

local function Create(className, properties, children)
    local inst = Instance.new(className)
    for prop, val in pairs(properties) do
        inst[prop] = val
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    return inst
end

-- Fonction pour rendre les frames déplaçables
local function MakeDraggable(frame, dragArea)
    dragArea = dragArea or frame
    local dragging, dragInput, dragStart, startPos
    
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- =======================================================
-- UI PRINCIPALE (ScreenGui)
-- =======================================================
local ScreenGui = Create("ScreenGui", {
    Name = "YunoPlayerHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
ScreenGui.Parent = CoreGui

-- =======================================================
-- ÉCRAN DE CHARGEMENT (Yuno Player Loading)
-- =======================================================
local LoadingFrame = Create("Frame", {
    Name = "LoadingScreen",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(10, 10, 10),
    ZIndex = 100,
    Parent = ScreenGui
})

local LoadingText = Create("TextLabel", {
    Name = "LoadingText",
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0.4, 0),
    BackgroundTransparency = 1,
    Text = "YUNO PLAYER LOADING",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBlack,
    TextSize = 40,
    ZIndex = 101,
    Parent = LoadingFrame
})

local LoadingSubtext = Create("TextLabel", {
    Name = "Subtext",
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 0.4, 50),
    BackgroundTransparency = 1,
    Text = "Initializing modules...",
    TextColor3 = Color3.fromRGB(150, 150, 150),
    Font = Enum.Font.Gotham,
    TextSize = 18,
    ZIndex = 101,
    Parent = LoadingFrame
})

-- Barre de chargement
local BarBackground = Create("Frame", {
    Name = "BarBG",
    Size = UDim2.new(0, 400, 0, 6),
    Position = UDim2.new(0.5, -200, 0.55, 0),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    ZIndex = 101,
    Parent = LoadingFrame
})
Create("UICorner", {CornerRadius = UDim.new(1, 0)}, {Parent = BarBackground})

local BarFill = Create("Frame", {
    Name = "BarFill",
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(255, 0, 0), -- Rouge YouTube
    BorderSizePixel = 0,
    ZIndex = 102,
    Parent = BarBackground
})
Create("UICorner", {CornerRadius = UDim.new(1, 0)}, {Parent = BarFill})

-- Animation de chargement
task.spawn(function()
    TweenService:Create(LoadingText, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 45, TextTransparency = 0.2}):Play()
    task.wait(0.5)
    TweenService:Create(LoadingText, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 40, TextTransparency = 0}):Play()
    
    TweenService:Create(BarFill, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    
    task.wait(3.2)
    
    TweenService:Create(LoadingText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(LoadingSubtext, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(BarBackground, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(BarFill, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    
    task.wait(0.5)
    LoadingFrame:Destroy()
end)

-- =======================================================
-- BOUTON FLOTTANT (Pour ouvrir/fermer le Hub)
-- =======================================================
local FloatingBtn = Create("TextButton", {
    Name = "FloatingBtn",
    Size = UDim2.new(0, 120, 0, 40),
    Position = UDim2.new(0, 20, 0.5, -20),
    BackgroundColor3 = Color3.fromRGB(20, 20, 20),
    Text = "YUNO HUB",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 50,
    Parent = ScreenGui
})
Create("UICorner", {CornerRadius = UDim.new(0, 20)}, {Parent = FloatingBtn})
Create("UIStroke", {Color = Color3.fromRGB(255, 0, 0), Thickness = 2}, {Parent = FloatingBtn})
MakeDraggable(FloatingBtn)

-- =======================================================
-- INTERFACE YOUTUBE (Vidéo)
-- =======================================================
local YouTubeUI = Create("Frame", {
    Name = "YouTubeUI",
    Size = UDim2.new(0, 420, 0, 340),
    Position = UDim2.new(0.5, -210, 0.5, -170),
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    Visible = false,
    ZIndex = 10,
    Parent = ScreenGui
})
Create("UICorner", {CornerRadius = UDim.new(0, 12)}, {Parent = YouTubeUI})
Create("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1.5}, {Parent = YouTubeUI})

-- Header YouTube
local YTHeader = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    Parent = YouTubeUI
})
MakeDraggable(YouTubeUI, YTHeader)

Create("ImageLabel", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(0, 10, 0, 5),
    BackgroundTransparency = 1,
    Image = Assets.YouTubeLogo,
    Parent = YTHeader
})

Create("TextLabel", {
    Size = UDim2.new(0, 100, 1, 0),
    Position = UDim2.new(0, 45, 0, 0),
    BackgroundTransparency = 1,
    Text = "YouTube",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = YTHeader
})

local YTClose = Create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -40, 0, 5),
    BackgroundTransparency = 1,
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Parent = YTHeader
})

-- Vidéo Player Zone (Fake)
local YTVideoFrame = Create("Frame", {
    Size = UDim2.new(1, -20, 0, 180),
    Position = UDim2.new(0, 10, 0, 45),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    ClipsDescendants = true,
    Parent = YouTubeUI
})
Create("UICorner", {CornerRadius = UDim.new(0, 8)}, {Parent = YTVideoFrame})

-- Image de fond pour simuler la vidéo (Basé sur ta capture)
Create("ImageLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Image = "rbxassetid://1275974022", -- Remplacer par l'ID de ta miniature si besoin
    ScaleType = Enum.ScaleType.Crop,
    ImageTransparency = 0.5,
    Parent = YTVideoFrame
})

-- Barre de contrôle vidéo
local YTControls = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 1, -40),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.5,
    Parent = YTVideoFrame
})

Create("ImageButton", {
    Size = UDim2.new(0, 25, 0, 25),
    Position = UDim2.new(0.5, -12.5, 0, 7),
    BackgroundTransparency = 1,
    Image = Assets.Play,
    Parent = YTControls
})

-- Titre et infos
Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 25),
    Position = UDim2.new(0, 10, 0, 235),
    BackgroundTransparency = 1,
    Text = "How to Vibecode Without Limits for Free",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = YouTubeUI
})

Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 10, 0, 260),
    BackgroundTransparency = 1,
    Text = "@Nessiell  611 vues  il y a 1 jour",
    TextColor3 = Color3.fromRGB(170, 170, 170),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = YouTubeUI
})

-- Boutons d'actions (Like, Share, Commentaires)
local ActionRow = Create("Frame", {
    Size = UDim2.new(1, -20, 0, 35),
    Position = UDim2.new(0, 10, 0, 290),
    BackgroundTransparency = 1,
    Parent = YouTubeUI
})

local function CreateActionBtn(pos, icon, text)
    local btn = Create("TextButton", {
        Size = UDim2.new(0, 90, 1, 0),
        Position = UDim2.new(0, pos, 0, 0),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        Text = "",
        Parent = ActionRow
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 15)}, {Parent = btn})
    Create("ImageLabel", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 10, 0.5, -8),
        BackgroundTransparency = 1,
        Image = icon,
        Parent = btn
    })
    Create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn
    })
end

CreateActionBtn(0, Assets.Like, "J'aime")
CreateActionBtn(100, Assets.Share, "Partager")
CreateActionBtn(200, Assets.Search, "Commentaires (51)")


-- =======================================================
-- INTERFACE YOUTUBE MUSIC (Style Spotify)
-- =======================================================
local SpotifyUI = Create("Frame", {
    Name = "SpotifyUI",
    Size = UDim2.new(0, 350, 0, 550),
    Position = UDim2.new(0.5, 220, 0.5, -275), -- Placé à droite par défaut
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    Visible = false,
    ZIndex = 10,
    Parent = ScreenGui
})
Create("UICorner", {CornerRadius = UDim.new(0, 12)}, {Parent = SpotifyUI})
Create("UIStroke", {Color = Color3.fromRGB(40, 40, 40), Thickness = 1.5}, {Parent = SpotifyUI})

-- Header Spotify
local SPHeader = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundTransparency = 1,
    Parent = SpotifyUI
})
MakeDraggable(SpotifyUI, SPHeader)

Create("ImageLabel", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1,
    Image = Assets.SpotifyLogo,
    Parent = SPHeader
})

-- Boutons Home, Search, Library
local NavBar = Create("Frame", {
    Size = UDim2.new(0, 150, 0, 30),
    Position = UDim2.new(1, -160, 0, 10),
    BackgroundTransparency = 1,
    Parent = SPHeader
})

local function CreateNavBtn(pos, icon)
    Create("ImageButton", {
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, pos, 0, 0),
        BackgroundTransparency = 1,
        Image = icon,
        Parent = NavBar
    })
end
CreateNavBtn(0, Assets.Home)
CreateNavBtn(50, Assets.Search)
CreateNavBtn(100, Assets.Library)

-- Titre "Tout"
Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 55),
    BackgroundTransparency = 1,
    Text = "Tout",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = SpotifyUI
})

-- Playlists (Scrolling Frame)
local SPList = Create("ScrollingFrame", {
    Size = UDim2.new(1, -20, 0, 330),
    Position = UDim2.new(0, 10, 0, 90),
    BackgroundTransparency = 1,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
    CanvasSize = UDim2.new(0, 0, 0, 400),
    Parent = SpotifyUI
})
Create("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, {Parent = SPList})

-- Fonction pour ajouter des cartes de playlist (Style Spotify)
local function AddPlaylistCard(title, subtitle, imageId, order)
    local card = Create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Color3.fromRGB(24, 24, 24),
        BackgroundTransparency = 0.2,
        LayoutOrder = order,
        Parent = SPList
    })
    Create("UICorner", {CornerRadius = UDim.new(0, 6)}, {Parent = card})
    
    Create("ImageLabel", {
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Image = imageId,
        Parent = card
    })
    
    Create("TextLabel", {
        Size = UDim2.new(1, -65, 0, 20),
        Position = UDim2.new(0, 60, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })
    
    Create("TextLabel", {
        Size = UDim2.new(1, -65, 0, 15),
        Position = UDim2.new(0, 60, 0, 30),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = Color3.fromRGB(170, 170, 170),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })
end

-- Ajout des playlists basées sur tes captures
AddPlaylistCard("Loverboy", "Playlist", "rbxassetid://6031075938", 1) -- Remplacer IDs par tes images
AddPlaylistCard("Meant To Be", "Playlist", "rbxassetid://6031075938", 2)
AddPlaylistCard("Fav song 2025", "Playlist", "rbxassetid://6031075938", 3)
AddPlaylistCard("Relaxation pour chat", "Playlist", "rbxassetid://6031075938", 4)

-- Player en bas (Style Spotify)
local SPPlayer = Create("Frame", {
    Size = UDim2.new(1, -20, 0, 80),
    Position = UDim2.new(0, 10, 1, -90),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    Parent = SpotifyUI
})
Create("UICorner", {CornerRadius = UDim.new(0, 8)}, {Parent = SPPlayer})

-- Infos chanson
Create("ImageLabel", {
    Size = UDim2.new(0, 50, 0, 50),
    Position = UDim2.new(0, 5, 0, 5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6031075938", -- Cover
    Parent = SPPlayer
})

Create("TextLabel", {
    Size = UDim2.new(1, -70, 0, 20),
    Position = UDim2.new(0, 60, 0, 10),
    BackgroundTransparency = 1,
    Text = "Sweet Boy",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = SPPlayer
})

Create("TextLabel", {
    Size = UDim2.new(1, -70, 0, 15),
    Position = UDim2.new(0, 60, 0, 30),
    BackgroundTransparency = 1,
    Text = "Malcolm Todd",
    TextColor3 = Color3.fromRGB(170, 170, 170),
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = SPPlayer
})

-- Contrôles Spotify
local SPControls = Create("Frame", {
    Size = UDim2.new(1, 0, 0, 25),
    Position = UDim2.new(0, 0, 0, 55),
    BackgroundTransparency = 1,
    Parent = SPPlayer
})

local function CreateSPControl(pos, icon, size)
    Create("ImageButton", {
        Size = UDim2.new(0, size, 0, size),
        Position = UDim2.new(0.5, pos, 0, 0),
        BackgroundTransparency = 1,
        Image = icon,
        Parent = SPControls
    })
end

CreateSPControl(-40, Assets.Prev, 20)
CreateSPControl(-10, Assets.Play, 25)
CreateSPControl(20, Assets.Next, 20)

-- =======================================================
-- LOGIQUE DES BOUTONS
-- =======================================================

-- Ouvrir / Fermer le Hub
local isHubOpen = false
FloatingBtn.MouseButton1Click:Connect(function()
    isHubOpen = not isHubOpen
    
    if isHubOpen then
        YouTubeUI.Visible = true
        SpotifyUI.Visible = true
        TweenService:Create(FloatingBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
    else
        YouTubeUI.Visible = false
        SpotifyUI.Visible = false
        TweenService:Create(FloatingBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
    end
end)

-- Fermer les fenêtres individuellement
YTClose.MouseButton1Click:Connect(function()
    YouTubeUI.Visible = false
end)

-- =======================================================
-- AJOUT D'UN SON DE TEST (Pour que le bouton Play marche)
-- =======================================================
local TestSound = Instance.new("Sound")
TestSound.SoundId = "rbxassetid://1845755853" -- ID d'une musique libre de droits dans Roblox
TestSound.Volume = 0.5
TestSound.Looped = true
TestSound.Parent = game.Workspace

local isPlaying = false

-- Connecter le bouton Play de Spotify
local spPlayBtn = SPControls:GetChildren()[2] -- Le bouton Play
spPlayBtn.MouseButton1Click:Connect(function()
    if isPlaying then
        TestSound:Pause()
        spPlayBtn.Image = Assets.Play
        isPlaying = false
    else
        TestSound:Play()
        spPlayBtn.Image = Assets.Pause
        isPlaying = true
    end
end)

-- Connecter le bouton Play de YouTube
local ytPlayBtn = YTControls:GetChildren()[1]
ytPlayBtn.MouseButton1Click:Connect(function()
    if isPlaying then
        TestSound:Pause()
        ytPlayBtn.Image = Assets.Play
        isPlaying = false
    else
        TestSound:Play()
        ytPlayBtn.Image = Assets.Pause
        isPlaying = true
    end
end)

print("Yuno Player Hub chargé avec succès !")