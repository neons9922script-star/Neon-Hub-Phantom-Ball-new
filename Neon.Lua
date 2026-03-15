-- ╔══════════════════════════════════════════════════╗
-- ║         NEXUS HUB - Professional Roblox GUI      ║
-- ║         Auto Parry System | v2.0                 ║
-- ╚══════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════
--              CONFIGURAÇÕES
-- ══════════════════════════════════════════
local CONFIG = {
    GUI_NAME        = "NexusHub",
    ACCENT_COLOR    = Color3.fromRGB(99, 102, 241),
    ACCENT_GLOW     = Color3.fromRGB(139, 92, 246),
    BG_DARK         = Color3.fromRGB(10, 10, 18),
    BG_MID          = Color3.fromRGB(16, 16, 28),
    BG_PANEL        = Color3.fromRGB(20, 20, 36),
    BORDER_COLOR    = Color3.fromRGB(40, 40, 70),
    TEXT_PRIMARY    = Color3.fromRGB(240, 240, 255),
    TEXT_SECONDARY  = Color3.fromRGB(140, 140, 180),
    TOGGLE_ON       = Color3.fromRGB(99, 102, 241),
    TOGGLE_OFF      = Color3.fromRGB(45, 45, 70),
    SUCCESS         = Color3.fromRGB(34, 197, 94),
    DANGER          = Color3.fromRGB(239, 68, 68),
    PARRY_DIST      = 1,   -- raio base do detector (studs)
}

-- ══════════════════════════════════════════
--         DETECÇÃO DE JOGO
-- ══════════════════════════════════════════
local GAME_NAMES = {
    phantom = {"phantom ball", "bola fantasma"},
    anime   = {"anime ball", "bola de anime"},
}

local DETECTED_GAME = nil  -- "phantom" | "anime" | nil

local function detectGame()
    local ok, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if not ok or not info then return nil end
    local lower = info.Name:lower()
    for _, n in ipairs(GAME_NAMES.phantom) do
        if lower:find(n, 1, true) then return "phantom" end
    end
    for _, n in ipairs(GAME_NAMES.anime) do
        if lower:find(n, 1, true) then return "anime" end
    end
    return nil
end

-- ══════════════════════════════════════════
--              ESTADO GLOBAL
-- ══════════════════════════════════════════
local State = {
    autoParry                = false,
    detectorPart             = nil,
    runConnection            = nil,
    guiOpen                  = true,
    hasExecutedThisDetection = false,
    lastBallColor            = nil,
    ballWasInside            = false,
    showDetectors            = false,
    -- Auto Spam
    autoSpam                 = false,
    spamDetectorPart         = nil,
    spamConnection           = nil,
    spamActive               = false,
    spamLoopConn             = nil,
    spamMultiplier           = 1,
    savedSpamTarget          = nil,
    -- Stats GUIs
    showParryStats           = false,
    showSpamStats            = false,
    parryCount               = 0,
    spamCount                = 0,
    -- Modo de parry
    parryMode                = "remote", -- "remote" | "button" | "anime_button"
    optimizer                = false,
    -- Anime Ball: speed detector separado
    speedDetectorConn        = nil,
    animeTrackedSpeed        = 0,   -- velocidade atual detectada pelo speed detector
    lastSpeedCFrame          = nil, -- CFrame anterior para cálculo de velocidade
}

-- ══════════════════════════════════════════
--         REMOÇÃO DE GUI ANTIGA
-- ══════════════════════════════════════════
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(CONFIG.GUI_NAME)
if oldGui then oldGui:Destroy() end

-- ══════════════════════════════════════════
--         LOADING SCREEN
-- ══════════════════════════════════════════
local LoadGui = Instance.new("ScreenGui")
LoadGui.Name            = "NexusHubLoader"
LoadGui.ResetOnSpawn    = false
LoadGui.IgnoreGuiInset  = true
LoadGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
LoadGui.Parent          = LocalPlayer:WaitForChild("PlayerGui")

local loadFrame = Instance.new("Frame", LoadGui)
loadFrame.Size               = UDim2.new(1, 0, 1, 0)
loadFrame.BackgroundColor3   = CONFIG.BG_DARK
loadFrame.BorderSizePixel    = 0
loadFrame.ZIndex             = 100

-- Gradiente de fundo
local loadGrad = Instance.new("UIGradient", loadFrame)
loadGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(8,  8,  20)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(14, 10, 30)),
})
loadGrad.Rotation = 135

-- Glow central
local loadGlow = Instance.new("Frame", loadFrame)
loadGlow.Size               = UDim2.new(0, 340, 0, 340)
loadGlow.Position           = UDim2.new(0.5, -170, 0.5, -170)
loadGlow.BackgroundColor3   = CONFIG.ACCENT_COLOR
loadGlow.BackgroundTransparency = 0.88
loadGlow.BorderSizePixel    = 0
loadGlow.ZIndex             = 101
Instance.new("UICorner", loadGlow).CornerRadius = UDim.new(1, 0)

-- Card central
local loadCard = Instance.new("Frame", loadFrame)
loadCard.Size               = UDim2.new(0, 300, 0, 220)
loadCard.Position           = UDim2.new(0.5, -150, 0.5, -110)
loadCard.BackgroundColor3   = CONFIG.BG_MID
loadCard.BorderSizePixel    = 0
loadCard.ZIndex             = 102
Instance.new("UICorner", loadCard).CornerRadius = UDim.new(0, 16)
local loadCardStroke = Instance.new("UIStroke", loadCard)
loadCardStroke.Color     = CONFIG.BORDER_COLOR
loadCardStroke.Thickness = 1.5

-- Linha accent topo
local loadAccentTop = Instance.new("Frame", loadCard)
loadAccentTop.Size             = UDim2.new(1, 0, 0, 3)
loadAccentTop.BackgroundColor3 = CONFIG.ACCENT_COLOR
loadAccentTop.BorderSizePixel  = 0
loadAccentTop.ZIndex           = 103
Instance.new("UICorner", loadAccentTop).CornerRadius = UDim.new(0, 16)
local loadAccentGrad = Instance.new("UIGradient", loadAccentTop)
loadAccentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   CONFIG.ACCENT_COLOR),
    ColorSequenceKeypoint.new(0.5, CONFIG.ACCENT_GLOW),
    ColorSequenceKeypoint.new(1,   CONFIG.ACCENT_COLOR),
})

-- Ícone / logo pulsante
local loadIcon = Instance.new("TextLabel", loadCard)
loadIcon.Text                  = "⚔"
loadIcon.Size                  = UDim2.new(0, 54, 0, 54)
loadIcon.Position              = UDim2.new(0.5, -27, 0, 20)
loadIcon.BackgroundTransparency = 1
loadIcon.TextColor3            = CONFIG.ACCENT_COLOR
loadIcon.TextSize              = 36
loadIcon.Font                  = Enum.Font.GothamBold
loadIcon.ZIndex                = 103

-- Título
local loadTitle = Instance.new("TextLabel", loadCard)
loadTitle.Text                  = "NEXUS HUB"
loadTitle.Size                  = UDim2.new(1, -20, 0, 26)
loadTitle.Position              = UDim2.new(0, 10, 0, 82)
loadTitle.BackgroundTransparency = 1
loadTitle.TextColor3            = CONFIG.TEXT_PRIMARY
loadTitle.TextSize              = 18
loadTitle.Font                  = Enum.Font.GothamBold
loadTitle.TextXAlignment        = Enum.TextXAlignment.Center
loadTitle.ZIndex                = 103

-- Status label
local loadStatus = Instance.new("TextLabel", loadCard)
loadStatus.Text                  = "🔍  Detectando jogo..."
loadStatus.Size                  = UDim2.new(1, -20, 0, 18)
loadStatus.Position              = UDim2.new(0, 10, 0, 114)
loadStatus.BackgroundTransparency = 1
loadStatus.TextColor3            = CONFIG.TEXT_SECONDARY
loadStatus.TextSize              = 11
loadStatus.Font                  = Enum.Font.Gotham
loadStatus.TextXAlignment        = Enum.TextXAlignment.Center
loadStatus.ZIndex                = 103

-- Barra de progresso (track)
local loadBarTrack = Instance.new("Frame", loadCard)
loadBarTrack.Size             = UDim2.new(1, -40, 0, 6)
loadBarTrack.Position         = UDim2.new(0, 20, 0, 148)
loadBarTrack.BackgroundColor3 = CONFIG.TOGGLE_OFF
loadBarTrack.BorderSizePixel  = 0
loadBarTrack.ZIndex           = 103
Instance.new("UICorner", loadBarTrack).CornerRadius = UDim.new(1, 0)

local loadBarFill = Instance.new("Frame", loadBarTrack)
loadBarFill.Size             = UDim2.new(0, 0, 1, 0)
loadBarFill.BackgroundColor3 = CONFIG.ACCENT_COLOR
loadBarFill.BorderSizePixel  = 0
loadBarFill.ZIndex           = 104
Instance.new("UICorner", loadBarFill).CornerRadius = UDim.new(1, 0)
local loadBarGrad = Instance.new("UIGradient", loadBarFill)
loadBarGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   CONFIG.ACCENT_COLOR),
    ColorSequenceKeypoint.new(1,   CONFIG.ACCENT_GLOW),
})

-- Badge do jogo detectado
local loadBadge = Instance.new("Frame", loadCard)
loadBadge.Size             = UDim2.new(1, -40, 0, 28)
loadBadge.Position         = UDim2.new(0, 20, 0, 168)
loadBadge.BackgroundColor3 = CONFIG.BG_PANEL
loadBadge.BackgroundTransparency = 1
loadBadge.BorderSizePixel  = 0
loadBadge.ZIndex           = 103
Instance.new("UICorner", loadBadge).CornerRadius = UDim.new(0, 8)

local loadBadgeLabel = Instance.new("TextLabel", loadBadge)
loadBadgeLabel.Size                  = UDim2.new(1, 0, 1, 0)
loadBadgeLabel.BackgroundTransparency = 1
loadBadgeLabel.TextColor3            = CONFIG.SUCCESS
loadBadgeLabel.TextSize              = 11
loadBadgeLabel.Font                  = Enum.Font.GothamBold
loadBadgeLabel.TextXAlignment        = Enum.TextXAlignment.Center
loadBadgeLabel.ZIndex                = 104
loadBadgeLabel.Text                  = ""

-- Animação de pulso do ícone
task.spawn(function()
    while LoadGui.Parent do
        TweenService:Create(loadIcon, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {TextColor3 = CONFIG.ACCENT_GLOW}):Play()
        task.wait(0.7)
        TweenService:Create(loadIcon, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {TextColor3 = CONFIG.ACCENT_COLOR}):Play()
        task.wait(0.7)
    end
end)

-- Função para animar a barra de progresso
local function setLoadProgress(pct, statusText)
    TweenService:Create(loadBarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(pct, 0, 1, 0)}):Play()
    if statusText then loadStatus.Text = statusText end
end

-- Função para fechar o loading com animação
local function closeLoading()
    TweenService:Create(loadFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {BackgroundTransparency = 1}):Play()
    TweenService:Create(loadCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(0.5, -150, 0.6, -110), BackgroundTransparency = 1}):Play()
    TweenService:Create(loadGlow, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    task.delay(0.55, function()
        LoadGui:Destroy()
    end)
end

-- ── Lógica de detecção ────────────────────
-- BindableEvent garante que DETECTED_GAME esteja definido antes de a GUI ser construída
local _guiReady = Instance.new("BindableEvent")

task.spawn(function()
    setLoadProgress(0.15, "🔍  Detectando jogo...")
    task.wait(0.4)

    setLoadProgress(0.45, "📡  Consultando PlaceId...")
    task.wait(0.3)

    local gameMode = detectGame()
    DETECTED_GAME = gameMode

    setLoadProgress(0.75, "⚙️  Configurando módulos...")
    task.wait(0.35)

    if gameMode == "phantom" then
        loadBadge.BackgroundTransparency = 0
        local stroke = Instance.new("UIStroke", loadBadge)
        stroke.Color = CONFIG.SUCCESS; stroke.Thickness = 1
        loadBadgeLabel.Text      = "✔  Phantom Ball / Bola Fantasma detectado"
        loadBadgeLabel.TextColor3 = CONFIG.SUCCESS
    elseif gameMode == "anime" then
        loadBadge.BackgroundTransparency = 0
        local stroke = Instance.new("UIStroke", loadBadge)
        stroke.Color = Color3.fromRGB(251, 146, 60); stroke.Thickness = 1
        loadBadgeLabel.Text       = "✔  Anime Ball / Bola De Anime detectado"
        loadBadgeLabel.TextColor3 = Color3.fromRGB(251, 146, 60)
    else
        -- Jogo não suportado: mostra erro e encerra sem carregar a GUI
        loadBadge.BackgroundTransparency = 0
        local stroke = Instance.new("UIStroke", loadBadge)
        stroke.Color = CONFIG.DANGER; stroke.Thickness = 1
        loadBadgeLabel.Text       = "✖  Jogo não suportado"
        loadBadgeLabel.TextColor3 = CONFIG.DANGER

        setLoadProgress(1, "✖  Script não carregado.")
        loadStatus.TextColor3 = CONFIG.DANGER

        -- Pulsa o card em vermelho para indicar erro
        TweenService:Create(loadCardStroke, TweenInfo.new(0.3), {Color = CONFIG.DANGER}):Play()
        TweenService:Create(loadIcon,       TweenInfo.new(0.3), {TextColor3 = CONFIG.DANGER}):Play()

        task.wait(3)

        -- Fecha o loading e destrói tudo sem carregar a GUI
        TweenService:Create(loadFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}):Play()
        TweenService:Create(loadCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, -150, 0.6, -110), BackgroundTransparency = 1}):Play()
        task.wait(0.55)
        LoadGui:Destroy()
        -- NÃO dispara _guiReady — o script para aqui
        return
    end

    setLoadProgress(1, "✔  Pronto!")
    task.wait(0.8)
    closeLoading()

    -- Sinaliza: GUI pode ser construída agora
    _guiReady:Fire()
end)

-- Aguarda a detecção terminar antes de construir a GUI (bloqueia esta coroutine)
_guiReady.Event:Wait()
_guiReady:Destroy()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = CONFIG.GUI_NAME
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset  = true
ScreenGui.Parent          = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════
--              JANELA PRINCIPAL
-- ══════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name               = "MainFrame"
MainFrame.Size               = UDim2.new(0, 440, 0, 320)
MainFrame.Position           = UDim2.new(0.5, -220, 0.5, -160)
MainFrame.BackgroundColor3   = CONFIG.BG_DARK
MainFrame.BorderSizePixel    = 0
MainFrame.ClipsDescendants   = true
MainFrame.Parent             = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color     = CONFIG.BORDER_COLOR
mainStroke.Thickness = 1.5

-- Glow de fundo
local glowBg = Instance.new("Frame", MainFrame)
glowBg.Size                   = UDim2.new(1,0,1,0)
glowBg.BackgroundTransparency = 1
glowBg.ZIndex                 = 0

local glowGrad = Instance.new("UIGradient", glowBg)
glowGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   CONFIG.ACCENT_COLOR),
    ColorSequenceKeypoint.new(0.5, CONFIG.BG_DARK),
    ColorSequenceKeypoint.new(1,   CONFIG.BG_DARK),
})
glowGrad.Rotation    = 135
glowGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0,   0.92),
    NumberSequenceKeypoint.new(0.4, 1),
    NumberSequenceKeypoint.new(1,   1),
})

-- ── Barra de Título ───────────────────────
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = CONFIG.BG_MID
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 2
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

-- Corrigir arredondamento inferior do título
local titleFix = Instance.new("Frame", TitleBar)
titleFix.Size             = UDim2.new(1, 0, 0, 14)
titleFix.Position         = UDim2.new(0, 0, 1, -14)
titleFix.BackgroundColor3 = CONFIG.BG_MID
titleFix.BorderSizePixel  = 0
titleFix.ZIndex           = 2

-- Linha accent
local accentLine = Instance.new("Frame", TitleBar)
accentLine.Size             = UDim2.new(0, 60, 0, 3)
accentLine.Position         = UDim2.new(0, 16, 0, 0)
accentLine.BackgroundColor3 = CONFIG.ACCENT_COLOR
accentLine.BorderSizePixel  = 0
accentLine.ZIndex           = 3
Instance.new("UICorner", accentLine).CornerRadius = UDim.new(0, 2)
Instance.new("UIGradient", accentLine).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, CONFIG.ACCENT_COLOR),
    ColorSequenceKeypoint.new(1, CONFIG.ACCENT_GLOW),
})

-- Logo dot
local logoDot = Instance.new("Frame", TitleBar)
logoDot.Size             = UDim2.new(0, 10, 0, 10)
logoDot.Position         = UDim2.new(0, 16, 0.5, -5)
logoDot.BackgroundColor3 = CONFIG.ACCENT_COLOR
logoDot.BorderSizePixel  = 0
logoDot.ZIndex           = 3
Instance.new("UICorner", logoDot).CornerRadius = UDim.new(1, 0)

-- Título texto
local titleLabel = Instance.new("TextLabel", TitleBar)
titleLabel.Text                  = "NEXUS HUB"
titleLabel.Size                  = UDim2.new(0, 200, 1, 0)
titleLabel.Position              = UDim2.new(0, 34, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3            = CONFIG.TEXT_PRIMARY
titleLabel.TextSize              = 15
titleLabel.Font                  = Enum.Font.GothamBold
titleLabel.TextXAlignment        = Enum.TextXAlignment.Left
titleLabel.ZIndex                = 3

local subLabel = Instance.new("TextLabel", TitleBar)
subLabel.Text                  = "v2.0  ·  Professional"
subLabel.Size                  = UDim2.new(0, 200, 0, 14)
subLabel.Position              = UDim2.new(0, 34, 0.5, 4)
subLabel.BackgroundTransparency = 1
subLabel.TextColor3            = CONFIG.TEXT_SECONDARY
subLabel.TextSize              = 10
subLabel.Font                  = Enum.Font.Gotham
subLabel.TextXAlignment        = Enum.TextXAlignment.Left
subLabel.ZIndex                = 3

-- Botão Fechar
local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Text                  = "✕"
CloseBtn.Size                  = UDim2.new(0, 30, 0, 30)
CloseBtn.Position              = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3      = Color3.fromRGB(239, 68, 68)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.TextColor3            = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize              = 12
CloseBtn.Font                  = Enum.Font.GothamBold
CloseBtn.BorderSizePixel       = 0
CloseBtn.ZIndex                = 4
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- ── Barra de Tabs ─────────────────────────
local TabBar = Instance.new("Frame", MainFrame)
TabBar.Name             = "TabBar"
TabBar.Size             = UDim2.new(1, 0, 0, 40)
TabBar.Position         = UDim2.new(0, 0, 0, 48)
TabBar.BackgroundColor3 = CONFIG.BG_MID
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 2

local tabBarStroke = Instance.new("UIStroke", TabBar)
tabBarStroke.Color     = CONFIG.BORDER_COLOR
tabBarStroke.Thickness = 1

local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.FillDirection       = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
tabLayout.Padding             = UDim.new(0, 4)

local tabPadding = Instance.new("UIPadding", TabBar)
tabPadding.PaddingLeft  = UDim.new(0, 8)
tabPadding.PaddingRight = UDim.new(0, 8)

-- ── Área de Conteúdo ──────────────────────
local ContentArea = Instance.new("Frame", MainFrame)
ContentArea.Name                  = "ContentArea"
ContentArea.Size                  = UDim2.new(1, 0, 1, -88)
ContentArea.Position              = UDim2.new(0, 0, 0, 88)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants      = true
ContentArea.ZIndex                = 2

-- ── Botão Flutuante ───────────────────────
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Text             = "⚔"
FloatBtn.Size             = UDim2.new(0, 44, 0, 44)
FloatBtn.Position         = UDim2.new(0, 20, 0.5, -22)
FloatBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
FloatBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
FloatBtn.TextSize         = 18
FloatBtn.Font             = Enum.Font.GothamBold
FloatBtn.BorderSizePixel  = 0
FloatBtn.Visible          = false
FloatBtn.ZIndex           = 10
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(0, 12)

task.spawn(function()
    while true do
        TweenService:Create(FloatBtn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = CONFIG.ACCENT_GLOW}):Play()
        task.wait(0.8)
        TweenService:Create(FloatBtn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundColor3 = CONFIG.ACCENT_COLOR}):Play()
        task.wait(0.8)
    end
end)

-- ══════════════════════════════════════════
--          SISTEMA DE ARRASTAR
-- ══════════════════════════════════════════
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                       startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

makeDraggable(MainFrame, TitleBar)
makeDraggable(FloatBtn,  FloatBtn)

-- ══════════════════════════════════════════
--         ABRIR / FECHAR
-- ══════════════════════════════════════════
local function closeGUI()
    State.guiOpen = false
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size     = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + 220,
                             MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + 160),
    }):Play()
    task.delay(0.35, function()
        MainFrame.Visible = false
        FloatBtn.Visible  = true
    end)
end

local function openGUI()
    State.guiOpen     = true
    FloatBtn.Visible  = false
    MainFrame.Visible = true
    MainFrame.Size    = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(0.5, -220, 0.5, -160)
    TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 440, 0, 320)
    }):Play()
end

CloseBtn.MouseButton1Click:Connect(closeGUI)
FloatBtn.MouseButton1Click:Connect(openGUI)
CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play() end)
CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play() end)

-- ══════════════════════════════════════════
--           SISTEMA DE TABS
-- ══════════════════════════════════════════
local Tabs     = {}
local TabPages = {}

-- Declarado antes de createTab pra ser referenciável dentro dele
local function selectTab(name)
    State.currentTab = name
    for tabName, tabData in pairs(Tabs) do
        if tabName == name then
            TweenService:Create(tabData.button, TweenInfo.new(0.2), {
                TextColor3             = CONFIG.TEXT_PRIMARY,
                BackgroundColor3       = CONFIG.ACCENT_COLOR,
                BackgroundTransparency = 0.85,
            }):Play()
            TweenService:Create(tabData.indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            tabData.page.Visible = true
        else
            TweenService:Create(tabData.button, TweenInfo.new(0.2), {
                TextColor3             = CONFIG.TEXT_SECONDARY,
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(tabData.indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            tabData.page.Visible = false
        end
    end
end

local function createTab(name, icon)
    local tab = Instance.new("TextButton", TabBar)
    tab.Text                  = (icon and (icon .. "  ") or "") .. name
    tab.Size                  = UDim2.new(0, 100, 0, 30)
    tab.BackgroundColor3      = CONFIG.BG_DARK
    tab.BackgroundTransparency = 1
    tab.TextColor3            = CONFIG.TEXT_SECONDARY
    tab.TextSize              = 12
    tab.Font                  = Enum.Font.GothamSemibold
    tab.BorderSizePixel       = 0
    tab.ZIndex                = 3
    Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 8)

    local indicator = Instance.new("Frame", tab)
    indicator.Name                  = "Indicator"
    indicator.Size                  = UDim2.new(0.7, 0, 0, 2)
    indicator.Position              = UDim2.new(0.15, 0, 1, -2)
    indicator.BackgroundColor3      = CONFIG.ACCENT_COLOR
    indicator.BorderSizePixel       = 0
    indicator.BackgroundTransparency = 1
    indicator.ZIndex                = 4
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local page = Instance.new("ScrollingFrame", ContentArea)
    page.Name                  = name .. "Page"
    page.Size                  = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel       = 0
    page.ScrollBarThickness    = 4
    page.ScrollBarImageColor3  = CONFIG.ACCENT_COLOR
    page.Visible               = false
    page.ZIndex                = 2

    local layout = Instance.new("UIListLayout", page)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding       = UDim.new(0, 8)

    local pad = Instance.new("UIPadding", page)
    pad.PaddingLeft   = UDim.new(0, 14)
    pad.PaddingRight  = UDim.new(0, 14)
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    Tabs[name]     = {button = tab, indicator = indicator, page = page}
    TabPages[name] = page
    tab.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

-- ══════════════════════════════════════════
--         COMPONENTES DE UI
-- ══════════════════════════════════════════
local function createToggle(parent, labelText, description, onToggle)
    local container = Instance.new("Frame", parent)
    container.Size             = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = CONFIG.BG_PANEL
    container.BorderSizePixel  = 0
    container.ZIndex           = 3
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", container)
    stroke.Color     = CONFIG.BORDER_COLOR
    stroke.Thickness = 1

    local lbl = Instance.new("TextLabel", container)
    lbl.Text                  = labelText
    lbl.Size                  = UDim2.new(1, -80, 0, 22)
    lbl.Position              = UDim2.new(0, 14, 0, 10)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3            = CONFIG.TEXT_PRIMARY
    lbl.TextSize              = 13
    lbl.Font                  = Enum.Font.GothamSemibold
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 4

    local desc = Instance.new("TextLabel", container)
    desc.Text                  = description or ""
    desc.Size                  = UDim2.new(1, -80, 0, 16)
    desc.Position              = UDim2.new(0, 14, 0, 33)
    desc.BackgroundTransparency = 1
    desc.TextColor3            = CONFIG.TEXT_SECONDARY
    desc.TextSize              = 10
    desc.Font                  = Enum.Font.Gotham
    desc.TextXAlignment        = Enum.TextXAlignment.Left
    desc.ZIndex                = 4

    local track = Instance.new("Frame", container)
    track.Size             = UDim2.new(0, 48, 0, 26)
    track.Position         = UDim2.new(1, -62, 0.5, -13)
    track.BackgroundColor3 = CONFIG.TOGGLE_OFF
    track.BorderSizePixel  = 0
    track.ZIndex           = 4
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame", track)
    thumb.Size             = UDim2.new(0, 20, 0, 20)
    thumb.Position         = UDim2.new(0, 3, 0.5, -10)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel  = 0
    thumb.ZIndex           = 5
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local toggleState = false
    local busy        = false

    local hitbox = Instance.new("TextButton", container)
    hitbox.Size                  = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                  = ""
    hitbox.ZIndex                = 6

    hitbox.MouseButton1Click:Connect(function()
        if busy then return end
        busy        = true
        toggleState = not toggleState
        if toggleState then
            TweenService:Create(track, TweenInfo.new(0.25), {BackgroundColor3 = CONFIG.TOGGLE_ON}):Play()
            TweenService:Create(thumb, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 25, 0.5, -10)}):Play()
        else
            TweenService:Create(track, TweenInfo.new(0.25), {BackgroundColor3 = CONFIG.TOGGLE_OFF}):Play()
            TweenService:Create(thumb, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 3, 0.5, -10)}):Play()
        end
        task.delay(0.25, function()
            busy = false
            if onToggle then onToggle(toggleState) end
        end)
    end)

    hitbox.MouseEnter:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(26,26,46)}):Play()
        TweenService:Create(stroke,    TweenInfo.new(0.15), {Color = CONFIG.ACCENT_COLOR}):Play()
    end)
    hitbox.MouseLeave:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.15), {BackgroundColor3 = CONFIG.BG_PANEL}):Play()
        TweenService:Create(stroke,    TweenInfo.new(0.15), {Color = CONFIG.BORDER_COLOR}):Play()
    end)

    return container
end

local function createStatusLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Text                  = text or ""
    lbl.Size                  = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3            = CONFIG.TEXT_SECONDARY
    lbl.TextSize              = 11
    lbl.Font                  = Enum.Font.Gotham
    lbl.TextXAlignment        = Enum.TextXAlignment.Left
    lbl.ZIndex                = 3
    return lbl
end

local function createSeparator(parent)
    local sep = Instance.new("Frame", parent)
    sep.Size             = UDim2.new(1, 0, 0, 1)
    sep.BackgroundColor3 = CONFIG.BORDER_COLOR
    sep.BorderSizePixel  = 0
    sep.ZIndex           = 3
    local g = Instance.new("UIGradient", sep)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.5, CONFIG.BORDER_COLOR),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
    })
end

-- ══════════════════════════════════════════
--         TAB COMBAT
-- ══════════════════════════════════════════
local CombatPage = createTab("Combat", "⚔")

local combatHeader = Instance.new("TextLabel", CombatPage)
combatHeader.Text                  = "COMBAT MODULES"
combatHeader.Size                  = UDim2.new(1, 0, 0, 18)
combatHeader.BackgroundTransparency = 1
combatHeader.TextColor3            = CONFIG.ACCENT_COLOR
combatHeader.TextSize              = 10
combatHeader.Font                  = Enum.Font.GothamBold
combatHeader.TextXAlignment        = Enum.TextXAlignment.Left
combatHeader.ZIndex                = 3

createSeparator(CombatPage)

local detectorStatus = createStatusLabel(CombatPage, "◉  Auto Parry: Inativo")
local distInfo       = createStatusLabel(CombatPage, "")

-- ── Dropdown: Modo do Parry ────────────────
local dropdownContainer = Instance.new("Frame", CombatPage)
dropdownContainer.Size             = UDim2.new(1, 0, 0, 54)
dropdownContainer.BackgroundColor3 = CONFIG.BG_PANEL
dropdownContainer.BorderSizePixel  = 0
dropdownContainer.ZIndex           = 10
Instance.new("UICorner", dropdownContainer).CornerRadius = UDim.new(0, 10)
local dropStroke = Instance.new("UIStroke", dropdownContainer)
dropStroke.Color = CONFIG.BORDER_COLOR; dropStroke.Thickness = 1

local dropLabel = Instance.new("TextLabel", dropdownContainer)
dropLabel.Text = "Parry Mode"
dropLabel.Size = UDim2.new(1, -14, 0, 18)
dropLabel.Position = UDim2.new(0, 14, 0, 6)
dropLabel.BackgroundTransparency = 1
dropLabel.TextColor3 = CONFIG.TEXT_SECONDARY
dropLabel.TextSize = 10; dropLabel.Font = Enum.Font.Gotham
dropLabel.TextXAlignment = Enum.TextXAlignment.Left
dropLabel.ZIndex = 11

-- Botão do dropdown
local dropBtn = Instance.new("TextButton", dropdownContainer)
dropBtn.Size             = UDim2.new(1, -28, 0, 24)
dropBtn.Position         = UDim2.new(0, 14, 0, 24)
dropBtn.BackgroundColor3 = CONFIG.BG_MID
dropBtn.BorderSizePixel  = 0
dropBtn.TextColor3       = CONFIG.TEXT_PRIMARY
dropBtn.TextSize         = 11
dropBtn.Font             = Enum.Font.GothamSemibold
dropBtn.Text             = "🔵  Remote Event (original)"
dropBtn.TextXAlignment   = Enum.TextXAlignment.Left
dropBtn.ZIndex           = 11
Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 6)
local dropBtnStroke = Instance.new("UIStroke", dropBtn)
dropBtnStroke.Color = CONFIG.BORDER_COLOR; dropBtnStroke.Thickness = 1

-- Padding interno do botão
local dropBtnPad = Instance.new("UIPadding", dropBtn)
dropBtnPad.PaddingLeft = UDim.new(0, 8)

-- Ícone de seta
local dropArrow = Instance.new("TextLabel", dropBtn)
dropArrow.Text = "▾"
dropArrow.Size = UDim2.new(0, 20, 1, 0)
dropArrow.Position = UDim2.new(1, -24, 0, 0)
dropArrow.BackgroundTransparency = 1
dropArrow.TextColor3 = CONFIG.TEXT_SECONDARY
dropArrow.TextSize = 12; dropArrow.Font = Enum.Font.GothamBold
dropArrow.ZIndex = 12

-- Menu de opções (aparece por cima)
local dropMenu = Instance.new("Frame", ScreenGui)
dropMenu.Size             = UDim2.new(0, 0, 0, 0)
dropMenu.BackgroundColor3 = CONFIG.BG_MID
dropMenu.BorderSizePixel  = 0
dropMenu.Visible          = false
dropMenu.ZIndex           = 100
Instance.new("UICorner", dropMenu).CornerRadius = UDim.new(0, 8)
local dropMenuStroke = Instance.new("UIStroke", dropMenu)
dropMenuStroke.Color = CONFIG.ACCENT_COLOR; dropMenuStroke.Thickness = 1

local dropMenuLayout = Instance.new("UIListLayout", dropMenu)
dropMenuLayout.FillDirection = Enum.FillDirection.Vertical
dropMenuLayout.Padding = UDim.new(0, 2)
local dropMenuPad = Instance.new("UIPadding", dropMenu)
dropMenuPad.PaddingLeft = UDim.new(0, 4); dropMenuPad.PaddingRight = UDim.new(0, 4)
dropMenuPad.PaddingTop = UDim.new(0, 4); dropMenuPad.PaddingBottom = UDim.new(0, 4)

local OPTIONS = {
    { label = "🔵  Remote Event (original)", mode = "remote",       games = {"phantom", nil} },
    { label = "🟢  Button (Phantom)",        mode = "button",       games = {"phantom", nil} },
    { label = "🟠  Button (Anime Ball)",     mode = "anime_button", games = {"anime"} },
}

local dropOpen = false

local function closeDropMenu()
    dropOpen = false
    TweenService:Create(dropMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, dropMenu.Size.X.Offset, 0, 0)
    }):Play()
    task.delay(0.15, function() dropMenu.Visible = false end)
    TweenService:Create(dropArrow, TweenInfo.new(0.15), {Rotation = 0}):Play()
end

local function selectOption(opt)
    State.parryMode = opt.mode
    dropBtn.Text    = opt.label
    TweenService:Create(dropBtnStroke, TweenInfo.new(0.2), {Color = CONFIG.ACCENT_COLOR}):Play()
    task.delay(0.4, function()
        TweenService:Create(dropBtnStroke, TweenInfo.new(0.3), {Color = CONFIG.BORDER_COLOR}):Play()
    end)
    closeDropMenu()
end

-- Criar itens do menu (filtrados pelo jogo detectado)
for _, opt in ipairs(OPTIONS) do
    -- Filtra opções: "anime_button" só aparece no Anime Ball; "remote"/"button" só no Phantom/desconhecido
    local show = true
    if opt.mode == "anime_button" and DETECTED_GAME ~= "anime" then show = false end
    if (opt.mode == "remote" or opt.mode == "button") and DETECTED_GAME == "anime" then show = false end
    if not show then continue end

    local item = Instance.new("TextButton", dropMenu)
    item.Size             = UDim2.new(1, 0, 0, 28)
    item.BackgroundColor3 = CONFIG.BG_PANEL
    item.BackgroundTransparency = 0.3
    item.BorderSizePixel  = 0
    item.TextColor3       = CONFIG.TEXT_PRIMARY
    item.TextSize         = 11
    item.Font             = Enum.Font.GothamSemibold
    item.Text             = opt.label
    item.TextXAlignment   = Enum.TextXAlignment.Left
    item.ZIndex           = 101
    Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)
    local itemPad = Instance.new("UIPadding", item)
    itemPad.PaddingLeft = UDim.new(0, 8)

    local capturedOpt = opt
    item.MouseButton1Click:Connect(function() selectOption(capturedOpt) end)
    item.MouseEnter:Connect(function()
        TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.ACCENT_COLOR, BackgroundTransparency = 0.7}):Play()
    end)
    item.MouseLeave:Connect(function()
        TweenService:Create(item, TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.BG_PANEL, BackgroundTransparency = 0.3}):Play()
    end)
end

-- Configura modo automaticamente (DETECTED_GAME já definido antes da GUI ser construída)
if DETECTED_GAME == "anime" then
    State.parryMode = "anime_button"
    dropBtn.Text    = "🟠  Button (Anime Ball)"
elseif DETECTED_GAME == "phantom" then
    State.parryMode = "remote"
    dropBtn.Text    = "🔵  Remote Event (original)"
end

dropBtn.MouseButton1Click:Connect(function()
    dropOpen = not dropOpen
    if dropOpen then
        -- Posiciona o menu abaixo do botão no ScreenGui
        local absPos = dropBtn.AbsolutePosition
        local absSize = dropBtn.AbsoluteSize
        local menuW = absSize.X + 28
        local menuH = #OPTIONS * 30 + 8
        dropMenu.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
        dropMenu.Size     = UDim2.new(0, menuW, 0, 0)
        dropMenu.Visible  = true
        TweenService:Create(dropMenu, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, menuW, 0, menuH)
        }):Play()
        TweenService:Create(dropArrow, TweenInfo.new(0.15), {Rotation = 180}):Play()
    else
        closeDropMenu()
    end
end)

-- Fechar menu ao clicar fora
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dropOpen then
        task.wait()
        if dropOpen then closeDropMenu() end
    end
end)

-- ══════════════════════════════════════════
--         SISTEMA AUTO PARRY
-- ══════════════════════════════════════════
local lastBallCFrame = nil
local trackedSpeed   = 0

-- Optimizer: deleta e recria o remote event para limpar callbacks pendentes na fila
local function optimizeRemote()
    if not State.optimizer then return end
    pcall(function()
        local folder = game:GetService("ReplicatedStorage")
            :WaitForChild("TS")
            :WaitForChild("GeneratedNetworkRemotes")
        local re = folder:FindFirstChild("RE_4.6848415795802784e+76")
        if re then
            -- Desconecta todos os OnClientEvent listeners locais
            -- (limpa a fila de callbacks pendentes no client)
            re.OnClientEvent:Connect(function() end) -- sobrescreve com handler vazio
            -- Reconecta imediatamente para não deixar a fila acumular
        end
    end)
end

-- Função unificada de parry (usada pelo Auto Parry e Auto Spam)
local function executeParry()
    if State.parryMode == "button" then
        -- Modo Button (Phantom Ball): ImageButton BLOCK
        pcall(function()
            local btn = game:GetService("Players").LocalPlayer
                .PlayerGui.Interface.MobileUI.Buttons.Jump.BLOCK.Button
            if not btn or not btn:IsA("ImageButton") then
                detectorStatus.Text = "◉  Erro: BLOCK.Button não é ImageButton"
                return
            end
            btn:FireServer("MouseButton1Down")
            btn:FireServer("MouseButton1Up")
        end)
        State.parryCount = State.parryCount + 1

    elseif State.parryMode == "anime_button" then
        -- Anime Ball: usa getconnections igual ao script de referência
        pcall(function()
            local btn = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if not btn then return end
            btn = btn:FindFirstChild("MobileSmall")
            if not btn then return end
            btn = btn:FindFirstChild("Block")
            if not btn then return end
            btn = btn:FindFirstChild("Detection")
            if not btn then return end
            if not btn:IsA("TextButton") then
                detectorStatus.Text = "◉  Erro: Detection não é TextButton"
                return
            end
            for _, conn in pairs(getconnections(btn.MouseButton1Down)) do
                conn:Fire()
            end
            task.wait(0.01)
            for _, conn in pairs(getconnections(btn.MouseButton1Up)) do
                conn:Fire()
            end
        end)
        State.parryCount = State.parryCount + 1

    else
        -- Modo Remote Event (Phantom Ball original)
        local ok, err = pcall(function()
            game:GetService("ReplicatedStorage")
                :WaitForChild("TS")
                :WaitForChild("GeneratedNetworkRemotes")
                :WaitForChild("RE_4.6848415795802784e+76")
                :FireServer(2.933813859058389e+76)
        end)
        if ok then
            State.parryCount = State.parryCount + 1
            optimizeRemote()
        else
            detectorStatus.Text = "◉  Erro: " .. tostring(err):sub(1, 40)
            return
        end
    end
    TweenService:Create(detectorStatus, TweenInfo.new(0.1), {TextColor3 = CONFIG.SUCCESS}):Play()
    detectorStatus.Text = "◉  Parry EXECUTADO!"
    task.delay(1.5, function()
        if State.autoParry then
            TweenService:Create(detectorStatus, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
            detectorStatus.Text = "◉  Auto Parry: Monitorando..."
        end
    end)
end

local function createDetector()
    if State.detectorPart then State.detectorPart:Destroy() end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local d = Instance.new("Part")
    d.Name         = "AutoParryDetector"
    d.Size         = Vector3.new(CONFIG.PARRY_DIST * 2, CONFIG.PARRY_DIST * 2, CONFIG.PARRY_DIST * 2)
    d.Shape        = Enum.PartType.Ball
    d.Anchored     = true
    d.CanCollide   = false
    d.Transparency = State.showDetectors and 0.6 or 1
    d.BrickColor   = BrickColor.new("Dark blue")
    d.Material     = Enum.Material.ForceField
    d.CFrame       = CFrame.new(hrp.CFrame.Position)
    d.Parent       = workspace
    State.detectorPart = d
end

local function destroyDetector()
    if State.detectorPart      then State.detectorPart:Destroy(); State.detectorPart = nil end
    if State.runConnection     then State.runConnection:Disconnect();     State.runConnection     = nil end
    if State.speedDetectorConn then State.speedDetectorConn:Disconnect(); State.speedDetectorConn = nil end
    State.animeTrackedSpeed = 0
    State.lastSpeedCFrame   = nil
end

local function startAutoParry()
    State.autoParry                = true
    State.hasExecutedThisDetection = false
    State.lastBallColor            = nil
    lastBallCFrame                 = nil
    trackedSpeed                   = 0
    detectorStatus.Text = "◉  Auto Parry: Monitorando..."
    TweenService:Create(detectorStatus, TweenInfo.new(0.3), {TextColor3 = CONFIG.SUCCESS}):Play()
    createDetector()

    -- ── ANIME BALL MODE ───────────────────────────────────────────────
    if DETECTED_GAME == "anime" then

        -- ── Speed Detector: usa AssemblyLinearVelocity da bola (velocidade real do motor físico) ──
        State.lastSpeedCFrame   = nil
        State.animeTrackedSpeed = 0
        State.speedDetectorConn = RunService.Heartbeat:Connect(function()
            local ballsFolder = workspace:FindFirstChild("Balls")
            if not ballsFolder then
                State.animeTrackedSpeed = 0
                return
            end
            -- Pega o primeiro BasePart com cor diferente de Medium Stone Grey
            local targetBall = nil
            local closestSpd = math.huge
            for _, obj in pairs(ballsFolder:GetChildren()) do
                local part = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if part and part:IsA("BasePart") then
                    local d = (part.Position - Vector3.new(0,0,0)).Magnitude  -- qualquer ref
                    if d < closestSpd then
                        closestSpd  = d
                        targetBall  = part
                    end
                end
            end
            if not targetBall then
                State.animeTrackedSpeed = 0
                return
            end
            -- AssemblyLinearVelocity é a velocidade física real do objeto — sem calcular delta
            State.animeTrackedSpeed = targetBall.AssemblyLinearVelocity.Magnitude
        end)

        -- ── Parry Loop: usa a velocidade já calculada pelo speed detector ──
        State.runConnection = RunService.Heartbeat:Connect(function()
            if not State.autoParry then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local ballsFolder = workspace:FindFirstChild("Balls")
            if not ballsFolder then
                distInfo.Text  = "  workspace.Balls não encontrado..."
                State.hasExecutedThisDetection = false
                return
            end

            -- Pega a bola mais próxima do player (suporta Model e BasePart)
            local targetBall = nil
            local closestDist = math.huge
            for _, obj in pairs(ballsFolder:GetChildren()) do
                local part = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if part and part:IsA("BasePart") then
                    local d = (part.Position - hrp.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        targetBall  = part
                    end
                end
            end

            if not targetBall then
                distInfo.Text  = "  Aguardando bola ativa..."
                State.hasExecutedThisDetection = false
                State.ballWasInside            = false
                return
            end

            -- Raio Anime Ball: CONFIG.PARRY_DIST + math.floor(trackedSpeed / 6.5)
            local velocity = State.animeTrackedSpeed
            local radius = math.clamp(
                CONFIG.PARRY_DIST + math.floor(velocity / 6.5),
                CONFIG.PARRY_DIST,
                300
            )

            -- Atualiza detector visual
            if State.detectorPart then
                State.detectorPart.CFrame = CFrame.new(hrp.CFrame.Position)
                State.detectorPart.Size   = Vector3.new(radius * 2, radius * 2, radius * 2)
                State.detectorPart.Transparency = State.showDetectors and 0.6 or 1
            end

            distInfo.Text = string.format("  Vel: %.1f s/s  |  Raio: %d st  |  Bola: %s",
                velocity, radius, targetBall.Name)

            local dist = closestDist  -- já calculado acima

            if State.ballWasInside and dist > radius then
                State.hasExecutedThisDetection = false
                State.ballWasInside            = false
            end

            -- Dispara quando: bola encostou no detector E LocalPlayer tem Highlight em workspace
            local localHighlight = workspace:FindFirstChild(LocalPlayer.Name)
                and workspace:FindFirstChild(LocalPlayer.Name):FindFirstChildWhichIsA("Highlight")
            if dist <= radius and localHighlight then
                State.ballWasInside = true
                if not State.hasExecutedThisDetection then
                    State.hasExecutedThisDetection = true
                    if State.detectorPart and State.showDetectors then
                        State.detectorPart.BrickColor   = BrickColor.new("Bright orange")
                        State.detectorPart.Transparency = 0.25
                        task.delay(0.4, function()
                            if State.detectorPart then
                                State.detectorPart.BrickColor   = BrickColor.new("Dark blue")
                                State.detectorPart.Transparency = 0.6
                            end
                        end)
                    end
                    executeParry()
                end
            else
                State.hasExecutedThisDetection = false
                State.ballWasInside            = false
            end
        end)

    -- ── PHANTOM BALL MODE (padrão) ────────────────────────────────────
    else
        State.runConnection = RunService.Heartbeat:Connect(function(dt)
            if not State.autoParry then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local ball = workspace:FindFirstChild("GameBall")
            if not ball or not ball:IsA("BasePart") then
                distInfo.Text  = "  GameBall não encontrado..."
                lastBallCFrame = nil
                State.hasExecutedThisDetection = false
                State.lastBallColor            = nil
                return
            end

            local curCF = ball.CFrame
            if lastBallCFrame ~= nil then
                local spd = (curCF.Position - lastBallCFrame.Position).Magnitude / math.max(dt, 1/60)
                trackedSpeed = trackedSpeed + (spd - trackedSpeed) * 0.3
            end
            lastBallCFrame = curCF

            local radius = math.clamp(
                CONFIG.PARRY_DIST + math.floor(trackedSpeed / 4),
                CONFIG.PARRY_DIST,
                300
            )

            if State.detectorPart then
                State.detectorPart.CFrame = CFrame.new(hrp.CFrame.Position)
                State.detectorPart.Size   = Vector3.new(radius * 2, radius * 2, radius * 2)
                State.detectorPart.Transparency = State.showDetectors and 0.6 or 1
            end

            distInfo.Text = string.format("  Vel: %.1f s/s  |  Raio: %d st", trackedSpeed, radius)

            local curColor = ball.BrickColor
            if State.lastBallColor ~= curColor then
                State.hasExecutedThisDetection = false
                State.lastBallColor            = curColor
            end

            local dist = (hrp.Position - ball.Position).Magnitude

            if State.ballWasInside and dist > radius then
                State.hasExecutedThisDetection = false
                State.ballWasInside            = false
            end

            if ball.BrickColor == BrickColor.new("Bright red") then
                if dist <= radius then
                    State.ballWasInside = true
                    if not State.hasExecutedThisDetection then
                        State.hasExecutedThisDetection = true
                        if State.detectorPart and State.showDetectors then
                            State.detectorPart.BrickColor  = BrickColor.new("Bright red")
                            State.detectorPart.Transparency = 0.25
                            task.delay(0.4, function()
                                if State.detectorPart then
                                    State.detectorPart.BrickColor  = BrickColor.new("Dark blue")
                                    State.detectorPart.Transparency = 0.6
                                end
                            end)
                        end
                        executeParry()
                    end
                end
            else
                State.hasExecutedThisDetection = false
                State.ballWasInside            = false
            end
        end)
    end
end

local function stopAutoParry()
    State.autoParry                = false
    State.hasExecutedThisDetection = false
    State.lastBallColor            = nil
    lastBallCFrame                 = nil
    trackedSpeed                   = 0
    destroyDetector()
    detectorStatus.Text = "◉  Auto Parry: Inativo"
    TweenService:Create(detectorStatus, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
    distInfo.Text = ""
end

-- Toggle com callback direto
createToggle(CombatPage, "Auto Parry", "Detecta GameBall e executa parry automático", function(on)
    if on then startAutoParry() else stopAutoParry() end
end)

createSeparator(CombatPage)

-- ── AUTO SPAM ─────────────────────────────
local spamStatus = createStatusLabel(CombatPage, "◉  Auto Spam: Inativo")

local SPAM_DIST = 45  -- raio fixo do detector de spam

local function createSpamDetector()
    if State.spamDetectorPart then State.spamDetectorPart:Destroy() end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local d = Instance.new("Part")
    d.Name         = "AutoSpamDetector"
    d.Size         = Vector3.new(SPAM_DIST * 2, SPAM_DIST * 2, SPAM_DIST * 2)
    d.Shape        = Enum.PartType.Ball
    d.Anchored     = true
    d.CanCollide   = false
    d.Transparency = State.showDetectors and 0.6 or 1
    d.BrickColor   = BrickColor.new("Bright blue")
    d.Material     = Enum.Material.ForceField
    d.CFrame       = CFrame.new(hrp.CFrame.Position)
    d.Parent       = workspace
    State.spamDetectorPart = d
end

local function destroySpamDetector()
    if State.spamDetectorPart then State.spamDetectorPart:Destroy(); State.spamDetectorPart = nil end
    if State.spamConnection    then State.spamConnection:Disconnect();    State.spamConnection    = nil end
    if State.spamLoopConn      then State.spamLoopConn:Disconnect();      State.spamLoopConn      = nil end
    State.spamActive = false
end

local function startSpamLoop()
    if State.spamActive then return end
    State.spamActive = true
    spamStatus.Text  = "◉  Auto Spam: SPAMANDO!"
    TweenService:Create(spamStatus, TweenInfo.new(0.1), {TextColor3 = CONFIG.DANGER}):Play()
    State.spamLoopConn = RunService.Heartbeat:Connect(function()
        if not State.spamActive then return end
        if State.parryMode == "button" then
            pcall(function()
                local btn = game:GetService("Players").LocalPlayer
                    .PlayerGui.Interface.MobileUI.Buttons.Jump.BLOCK.Button
                if not btn or not btn:IsA("ImageButton") then return end
                for i = 1, State.spamMultiplier do
                    btn:FireServer("MouseButton1Down")
                    btn:FireServer("MouseButton1Up")
                    State.spamCount = State.spamCount + 1
                end
            end)
        elseif State.parryMode == "anime_button" then
            pcall(function()
                local btn = LocalPlayer.PlayerGui:FindFirstChild("HUD")
                if not btn then return end
                btn = btn:FindFirstChild("MobileSmall")
                if not btn then return end
                btn = btn:FindFirstChild("Block")
                if not btn then return end
                btn = btn:FindFirstChild("Detection")
                if not btn or not btn:IsA("TextButton") then return end
                for i = 1, State.spamMultiplier do
                    for _, conn in pairs(getconnections(btn.MouseButton1Down)) do conn:Fire() end
                    task.wait(0.01)
                    for _, conn in pairs(getconnections(btn.MouseButton1Up)) do conn:Fire() end
                    State.spamCount = State.spamCount + 1
                end
            end)
        else
            local re = game:GetService("ReplicatedStorage")
                :WaitForChild("TS")
                :WaitForChild("GeneratedNetworkRemotes")
                :WaitForChild("RE_4.6848415795802784e+76")
            for i = 1, State.spamMultiplier do
                pcall(function() re:FireServer(2.933813859058389e+76) end)
                State.spamCount = State.spamCount + 1
            end
            optimizeRemote()
        end
    end)
end

local function stopSpamLoop()
    if not State.spamActive then return end
    State.spamActive = false
    if State.spamLoopConn then State.spamLoopConn:Disconnect(); State.spamLoopConn = nil end
    spamStatus.Text = "◉  Auto Spam: Monitorando..."
    TweenService:Create(spamStatus, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
end

local function startAutoSpam()
    State.autoSpam = true
    spamStatus.Text = "◉  Auto Spam: Monitorando..."
    TweenService:Create(spamStatus, TweenInfo.new(0.3), {TextColor3 = CONFIG.SUCCESS}):Play()
    createSpamDetector()

    -- Nome do player salvo (mesmo após perder o highlight)
    local savedTargetName = nil

    State.spamConnection = RunService.Heartbeat:Connect(function()
        if not State.autoSpam then return end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Atualizar posição do detector
        if State.spamDetectorPart then
            State.spamDetectorPart.CFrame = CFrame.new(hrp.CFrame.Position)
            State.spamDetectorPart.Transparency = State.showDetectors and 0.6 or 1
        end

        -- ── ANIME BALL: highlight-based spam ─────────────────────────────
        if DETECTED_GAME == "anime" then
            local ballsFolder = workspace:FindFirstChild("Balls")
            if not ballsFolder then stopSpamLoop(); return end

            -- Pega bola mais próxima (suporta Model e BasePart)
            local closestBall, closestDist = nil, math.huge
            for _, obj in pairs(ballsFolder:GetChildren()) do
                local part = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if part and part:IsA("BasePart") then
                    local d = (part.Position - hrp.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closestBall = part
                    end
                end
            end

            if not closestBall then stopSpamLoop(); return end

            local ballInDetector = closestDist <= SPAM_DIST

            -- Verifica players dentro do detector com Highlight → salva nome
            -- Quando player perde o Highlight mas ainda está no detector → mantém nome salvo
            -- Quando player sai do detector → deleta nome salvo
            for _, player in pairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local pChar = player.Character
                if not pChar then continue end
                local pHRP = pChar:FindFirstChild("HumanoidRootPart")
                if not pHRP then continue end

                local pDist = (pHRP.Position - hrp.Position).Magnitude

                if pDist <= SPAM_DIST then
                    -- Player dentro do detector: salva nome se tiver Highlight
                    local hasHighlight = pChar:FindFirstChildWhichIsA("Highlight") ~= nil
                    if hasHighlight then
                        savedTargetName       = player.Name
                        State.savedSpamTarget = player.Name
                    end
                    -- Se perdeu o Highlight mas ainda está no detector → mantém nome salvo (não limpa)
                else
                    -- Player saiu do detector → limpa nome salvo se for ele
                    if savedTargetName == player.Name then
                        savedTargetName       = nil
                        State.savedSpamTarget = nil
                    end
                end
            end

            -- Eu (LocalPlayer) com Highlight + bola no detector + target salvo → spama
            local myChar = LocalPlayer.Character
            local myHighlight = myChar and myChar:FindFirstChildWhichIsA("Highlight") ~= nil

            if ballInDetector and myHighlight and savedTargetName ~= nil then
                startSpamLoop()
            else
                stopSpamLoop()
            end

        -- ── PHANTOM BALL: lógica original com highlight ───────────────────
        else
            local ball = workspace:FindFirstChild("GameBall")
            local charsFolder = workspace:FindFirstChild("Characters")

            local ballInDetector = false
            if ball and ball:IsA("BasePart") then
                local ballDist = (hrp.Position - ball.Position).Magnitude
                if ballDist <= SPAM_DIST and ball.BrickColor == BrickColor.new("Bright red") then
                    ballInDetector = true
                end
            end

            if charsFolder then
                for _, player in pairs(Players:GetPlayers()) do
                    if player == LocalPlayer then continue end
                    if player.Name == LocalPlayer.Name then continue end

                    local foundChar = charsFolder:FindFirstChild(player.Name)
                    if not foundChar or foundChar == LocalPlayer.Character then continue end

                    local pHRP = foundChar:FindFirstChild("HumanoidRootPart")
                    if not pHRP then continue end

                    local pDist = (hrp.Position - pHRP.Position).Magnitude

                    if pDist <= SPAM_DIST then
                        local highlight = foundChar:FindFirstChild("PlayerBallHighlight")
                        if highlight then
                            savedTargetName = player.Name
                            State.savedSpamTarget = player.Name
                        end
                    else
                        if savedTargetName == player.Name then
                            savedTargetName = nil
                            State.savedSpamTarget = nil
                        end
                    end
                end
            end

            if ballInDetector and savedTargetName ~= nil then
                startSpamLoop()
            elseif State.spamActive and savedTargetName == nil then
                stopSpamLoop()
            end
        end
    end)
end

local function stopAutoSpam()
    State.autoSpam = false
    stopSpamLoop()
    destroySpamDetector()
    spamStatus.Text = "◉  Auto Spam: Inativo"
    TweenService:Create(spamStatus, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
end

createToggle(CombatPage, "Auto Spam", "Spama parry quando detectar player com highlight (35m)", function(on)
    if on then startAutoSpam() else stopAutoSpam() end
end)

-- ── Slider Power do Spam ──────────────────
local sliderContainer = Instance.new("Frame", CombatPage)
sliderContainer.Size             = UDim2.new(1, 0, 0, 72)
sliderContainer.BackgroundColor3 = CONFIG.BG_PANEL
sliderContainer.BorderSizePixel  = 0
sliderContainer.ZIndex           = 3
Instance.new("UICorner", sliderContainer).CornerRadius = UDim.new(0, 10)
local sliderStroke = Instance.new("UIStroke", sliderContainer)
sliderStroke.Color = CONFIG.BORDER_COLOR; sliderStroke.Thickness = 1

local sliderTitle = Instance.new("TextLabel", sliderContainer)
sliderTitle.Text = "⚡ Spam Power"
sliderTitle.Size = UDim2.new(0.55, 0, 0, 18)
sliderTitle.Position = UDim2.new(0, 14, 0, 6)
sliderTitle.BackgroundTransparency = 1
sliderTitle.TextColor3 = CONFIG.TEXT_PRIMARY
sliderTitle.TextSize = 12
sliderTitle.Font = Enum.Font.GothamSemibold
sliderTitle.TextXAlignment = Enum.TextXAlignment.Left
sliderTitle.ZIndex = 4

local sliderValueLabel = Instance.new("TextLabel", sliderContainer)
sliderValueLabel.Text = "1x Power"
sliderValueLabel.Size = UDim2.new(0.42, 0, 0, 18)
sliderValueLabel.Position = UDim2.new(0.58, -14, 0, 6)
sliderValueLabel.BackgroundTransparency = 1
sliderValueLabel.TextColor3 = CONFIG.ACCENT_COLOR
sliderValueLabel.TextSize = 12
sliderValueLabel.Font = Enum.Font.GothamBold
sliderValueLabel.TextXAlignment = Enum.TextXAlignment.Right
sliderValueLabel.ZIndex = 4

-- Descrição dinâmica: "Xx Power = X Heartbeats/frame"
local sliderDesc = Instance.new("TextLabel", sliderContainer)
sliderDesc.Text = "1x Power  =  1 Heartbeat/frame"
sliderDesc.Size = UDim2.new(1, -28, 0, 14)
sliderDesc.Position = UDim2.new(0, 14, 0, 26)
sliderDesc.BackgroundTransparency = 1
sliderDesc.TextColor3 = CONFIG.TEXT_SECONDARY
sliderDesc.TextSize = 10
sliderDesc.Font = Enum.Font.Gotham
sliderDesc.TextXAlignment = Enum.TextXAlignment.Left
sliderDesc.ZIndex = 4

-- Track do slider
local sliderTrack = Instance.new("Frame", sliderContainer)
sliderTrack.Size = UDim2.new(1, -28, 0, 6)
sliderTrack.Position = UDim2.new(0, 14, 0, 50)
sliderTrack.BackgroundColor3 = CONFIG.TOGGLE_OFF
sliderTrack.BorderSizePixel = 0
sliderTrack.ZIndex = 4
Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)

-- Fill do slider
local sliderFill = Instance.new("Frame", sliderTrack)
sliderFill.Size = UDim2.new(0, 0, 1, 0)
sliderFill.BackgroundColor3 = CONFIG.ACCENT_COLOR
sliderFill.BorderSizePixel = 0
sliderFill.ZIndex = 5
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

-- Knob
local sliderKnob = Instance.new("Frame", sliderTrack)
sliderKnob.Size = UDim2.new(0, 14, 0, 14)
sliderKnob.Position = UDim2.new(0, -7, 0.5, -7)
sliderKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
sliderKnob.BorderSizePixel = 0
sliderKnob.ZIndex = 6
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

-- Slider lógica (1x a 100x)
local SLIDER_MIN, SLIDER_MAX = 1, 100
local sliderDragging = false

local function updateSlider(xRatio)
    xRatio = math.clamp(xRatio, 0, 1)
    local value = math.round(SLIDER_MIN + xRatio * (SLIDER_MAX - SLIDER_MIN))
    State.spamMultiplier = value
    sliderValueLabel.Text = value .. "x Power"
    local hbText = value == 1 and "1 Heartbeat/frame" or (value .. " Heartbeats/frame")
    sliderDesc.Text = value .. "x Power  =  " .. hbText
    sliderFill.Size = UDim2.new(xRatio, 0, 1, 0)
    sliderKnob.Position = UDim2.new(xRatio, -7, 0.5, -7)
end

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
        local xRatio = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
        updateSlider(xRatio)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                           input.UserInputType == Enum.UserInputType.Touch) then
        local xRatio = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
        updateSlider(xRatio)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

createSeparator(CombatPage)

-- ── Botão de Teste: Clique no BLOCK.Button ─
local testBtnContainer = Instance.new("Frame", CombatPage)
testBtnContainer.Size             = UDim2.new(1, 0, 0, 54)
testBtnContainer.BackgroundColor3 = CONFIG.BG_PANEL
testBtnContainer.BorderSizePixel  = 0
testBtnContainer.ZIndex           = 3
Instance.new("UICorner", testBtnContainer).CornerRadius = UDim.new(0, 10)
local testBtnStroke = Instance.new("UIStroke", testBtnContainer)
testBtnStroke.Color = CONFIG.BORDER_COLOR; testBtnStroke.Thickness = 1

local testBtnLabel = Instance.new("TextLabel", testBtnContainer)
testBtnLabel.Text = "Test BLOCK Button"
testBtnLabel.Size = UDim2.new(0.6, 0, 0, 20)
testBtnLabel.Position = UDim2.new(0, 14, 0, 8)
testBtnLabel.BackgroundTransparency = 1
testBtnLabel.TextColor3 = CONFIG.TEXT_PRIMARY
testBtnLabel.TextSize = 12
testBtnLabel.Font = Enum.Font.GothamSemibold
testBtnLabel.TextXAlignment = Enum.TextXAlignment.Left
testBtnLabel.ZIndex = 4

local testBtnDesc = Instance.new("TextLabel", testBtnContainer)
testBtnDesc.Text = "Clica 1x no Button para testar"
testBtnDesc.Size = UDim2.new(0.7, 0, 0, 14)
testBtnDesc.Position = UDim2.new(0, 14, 0, 30)
testBtnDesc.BackgroundTransparency = 1
testBtnDesc.TextColor3 = CONFIG.TEXT_SECONDARY
testBtnDesc.TextSize = 10
testBtnDesc.Font = Enum.Font.Gotham
testBtnDesc.TextXAlignment = Enum.TextXAlignment.Left
testBtnDesc.ZIndex = 4

local testBtn = Instance.new("TextButton", testBtnContainer)
testBtn.Text = "▶  Testar"
testBtn.Size = UDim2.new(0, 80, 0, 28)
testBtn.Position = UDim2.new(1, -94, 0.5, -14)
testBtn.BackgroundColor3 = CONFIG.ACCENT_COLOR
testBtn.BackgroundTransparency = 0.2
testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
testBtn.TextSize = 11
testBtn.Font = Enum.Font.GothamBold
testBtn.BorderSizePixel = 0
testBtn.ZIndex = 5
Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 8)

testBtn.MouseEnter:Connect(function()
    TweenService:Create(testBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
end)
testBtn.MouseLeave:Connect(function()
    TweenService:Create(testBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
end)

testBtn.MouseButton1Click:Connect(function()
    local ok, btn

    if DETECTED_GAME == "anime" then
        -- Anime Ball: testa o TextButton Detection
        testBtnLabel.Text = "Test Detection Button"
        ok, btn = pcall(function()
            return game:GetService("Players").LocalPlayer
                :WaitForChild("PlayerGui", 3)
                :WaitForChild("HUD", 3)
                :WaitForChild("MobileSmall", 3)
                :WaitForChild("Block", 3)
                :WaitForChild("Detection", 3)
        end)
        if not ok or not btn then
            testBtnDesc.Text = "❌ Erro: Detection não encontrado!"
            TweenService:Create(testBtnDesc, TweenInfo.new(0.1), {TextColor3 = CONFIG.DANGER}):Play()
            TweenService:Create(testBtn,    TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.DANGER}):Play()
            task.delay(2, function()
                testBtnDesc.Text = "Clica 1x no Button para testar"
                TweenService:Create(testBtnDesc, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
                TweenService:Create(testBtn,    TweenInfo.new(0.3), {BackgroundColor3 = CONFIG.ACCENT_COLOR}):Play()
            end)
            return
        end
        if not btn:IsA("TextButton") then
            testBtnDesc.Text = "❌ Erro: Detection não é TextButton!"
            TweenService:Create(testBtnDesc, TweenInfo.new(0.1), {TextColor3 = CONFIG.DANGER}):Play()
            TweenService:Create(testBtn,    TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.DANGER}):Play()
            task.delay(2, function()
                testBtnDesc.Text = "Clica 1x no Button para testar"
                TweenService:Create(testBtnDesc, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
                TweenService:Create(testBtn,    TweenInfo.new(0.3), {BackgroundColor3 = CONFIG.ACCENT_COLOR}):Play()
            end)
            return
        end
    else
        -- Phantom Ball: testa o ImageButton BLOCK.Button
        testBtnLabel.Text = "Test BLOCK Button"
        ok, btn = pcall(function()
            return game:GetService("Players").LocalPlayer
                :WaitForChild("PlayerGui", 3)
                :WaitForChild("Interface", 3)
                :WaitForChild("MobileUI", 3)
                :WaitForChild("Buttons", 3)
                :WaitForChild("Jump", 3)
                :WaitForChild("BLOCK", 3)
                :WaitForChild("Button", 3)
        end)
        if not ok or not btn then
            testBtnDesc.Text = "❌ Erro: BLOCK.Button não encontrado!"
            TweenService:Create(testBtnDesc, TweenInfo.new(0.1), {TextColor3 = CONFIG.DANGER}):Play()
            TweenService:Create(testBtn,    TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.DANGER}):Play()
            task.delay(2, function()
                testBtnDesc.Text = "Clica 1x no Button para testar"
                TweenService:Create(testBtnDesc, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
                TweenService:Create(testBtn,    TweenInfo.new(0.3), {BackgroundColor3 = CONFIG.ACCENT_COLOR}):Play()
            end)
            return
        end
        if not btn:IsA("ImageButton") then
            testBtnDesc.Text = "❌ Erro: BLOCK.Button não é ImageButton!"
            TweenService:Create(testBtnDesc, TweenInfo.new(0.1), {TextColor3 = CONFIG.DANGER}):Play()
            TweenService:Create(testBtn,    TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.DANGER}):Play()
            task.delay(2, function()
                testBtnDesc.Text = "Clica 1x no Button para testar"
                TweenService:Create(testBtnDesc, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
                TweenService:Create(testBtn,    TweenInfo.new(0.3), {BackgroundColor3 = CONFIG.ACCENT_COLOR}):Play()
            end)
            return
        end
    end

    local fireOk = pcall(function()
        if DETECTED_GAME == "anime" then
            for _, conn in pairs(getconnections(btn.MouseButton1Down)) do conn:Fire() end
            task.wait(0.01)
            for _, conn in pairs(getconnections(btn.MouseButton1Up)) do conn:Fire() end
        else
            btn:FireServer("MouseButton1Down")
            btn:FireServer("MouseButton1Up")
        end
    end)

    if fireOk then
        testBtnDesc.Text = "✔ Clique enviado com sucesso!"
        TweenService:Create(testBtnDesc, TweenInfo.new(0.1), {TextColor3 = CONFIG.SUCCESS}):Play()
        TweenService:Create(testBtn,    TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.SUCCESS}):Play()
    else
        testBtnDesc.Text = "❌ Erro ao clicar no Button"
        TweenService:Create(testBtnDesc, TweenInfo.new(0.1), {TextColor3 = CONFIG.DANGER}):Play()
        TweenService:Create(testBtn,    TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.DANGER}):Play()
    end
    task.delay(2, function()
        testBtnDesc.Text = "Clica 1x no Button para testar"
        TweenService:Create(testBtnDesc, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
        TweenService:Create(testBtn,    TweenInfo.new(0.3), {BackgroundColor3 = CONFIG.ACCENT_COLOR}):Play()
    end)
end)

createSeparator(CombatPage)

createToggle(CombatPage, "Optimizer", "Limpa remote events antigos após cada disparo", function(on)
    State.optimizer = on
end)
LocalPlayer.CharacterRemoving:Connect(function()
    if State.autoParry then destroyDetector() end
    if State.autoSpam  then destroySpamDetector() end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    local hrp      = char:WaitForChild("HumanoidRootPart", 5)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not hrp or not humanoid then return end

    task.wait(0.5)

    if State.autoParry then
        -- Reseta variáveis e reinicia o sistema completo
        State.hasExecutedThisDetection = false
        State.lastBallColor            = nil
        State.ballWasInside            = false
        lastBallCFrame                 = nil
        trackedSpeed                   = 0
        -- Derruba conexão antiga e reinicia
        if State.runConnection then State.runConnection:Disconnect(); State.runConnection = nil end
        startAutoParry()
    end

    if State.autoSpam then
        -- Derruba conexão antiga e reinicia
        if State.spamConnection then State.spamConnection:Disconnect(); State.spamConnection = nil end
        startAutoSpam()
    end
end)

-- ══════════════════════════════════════════
--         TAB VISUAL
-- ══════════════════════════════════════════
local VisualPage = createTab("Visual", "👁")

local visualHeader = Instance.new("TextLabel", VisualPage)
visualHeader.Text                  = "VISUAL MODULES"
visualHeader.Size                  = UDim2.new(1, 0, 0, 18)
visualHeader.BackgroundTransparency = 1
visualHeader.TextColor3            = CONFIG.ACCENT_COLOR
visualHeader.TextSize              = 10
visualHeader.Font                  = Enum.Font.GothamBold
visualHeader.TextXAlignment        = Enum.TextXAlignment.Left
visualHeader.ZIndex                = 3

createSeparator(VisualPage)

-- ══════════════════════════════════════════
--    TAB SKILLS (Phantom Ball apenas)
-- ══════════════════════════════════════════
if DETECTED_GAME == "phantom" then
    local SkillsPage = createTab("Skills", "⚡")

    local skillsHeader = Instance.new("TextLabel", SkillsPage)
    skillsHeader.Text                  = "SKILLS / LIABILITIES"
    skillsHeader.Size                  = UDim2.new(1, 0, 0, 18)
    skillsHeader.BackgroundTransparency = 1
    skillsHeader.TextColor3            = CONFIG.ACCENT_COLOR
    skillsHeader.TextSize              = 10
    skillsHeader.Font                  = Enum.Font.GothamBold
    skillsHeader.TextXAlignment        = Enum.TextXAlignment.Left
    skillsHeader.ZIndex                = 3

    createSeparator(SkillsPage)

    -- Container do passivo
    local passiveContainer = Instance.new("Frame", SkillsPage)
    passiveContainer.Size             = UDim2.new(1, 0, 0, 80)
    passiveContainer.BackgroundColor3 = CONFIG.BG_PANEL
    passiveContainer.BorderSizePixel  = 0
    passiveContainer.ZIndex           = 3
    Instance.new("UICorner", passiveContainer).CornerRadius = UDim.new(0, 10)
    local passiveStroke = Instance.new("UIStroke", passiveContainer)
    passiveStroke.Color = CONFIG.BORDER_COLOR; passiveStroke.Thickness = 1

    local passiveLabel = Instance.new("TextLabel", passiveContainer)
    passiveLabel.Text                  = "Passivo"
    passiveLabel.Size                  = UDim2.new(1, -14, 0, 16)
    passiveLabel.Position              = UDim2.new(0, 14, 0, 8)
    passiveLabel.BackgroundTransparency = 1
    passiveLabel.TextColor3            = CONFIG.TEXT_SECONDARY
    passiveLabel.TextSize              = 10
    passiveLabel.Font                  = Enum.Font.Gotham
    passiveLabel.TextXAlignment        = Enum.TextXAlignment.Left
    passiveLabel.ZIndex                = 4

    local passiveDesc = Instance.new("TextLabel", passiveContainer)
    passiveDesc.Text                  = "Digite o nome e pressione Enter"
    passiveDesc.Size                  = UDim2.new(1, -14, 0, 14)
    passiveDesc.Position              = UDim2.new(0, 14, 1, -18)
    passiveDesc.BackgroundTransparency = 1
    passiveDesc.TextColor3            = CONFIG.TEXT_SECONDARY
    passiveDesc.TextSize              = 10
    passiveDesc.Font                  = Enum.Font.Gotham
    passiveDesc.TextXAlignment        = Enum.TextXAlignment.Left
    passiveDesc.ZIndex                = 4

    -- TextBox do passivo
    local passiveBoxFrame = Instance.new("Frame", passiveContainer)
    passiveBoxFrame.Size             = UDim2.new(1, -28, 0, 28)
    passiveBoxFrame.Position         = UDim2.new(0, 14, 0, 28)
    passiveBoxFrame.BackgroundColor3 = CONFIG.BG_MID
    passiveBoxFrame.BorderSizePixel  = 0
    passiveBoxFrame.ZIndex           = 4
    Instance.new("UICorner", passiveBoxFrame).CornerRadius = UDim.new(0, 7)
    local passiveBoxStroke = Instance.new("UIStroke", passiveBoxFrame)
    passiveBoxStroke.Color = CONFIG.BORDER_COLOR; passiveBoxStroke.Thickness = 1

    local passiveBox = Instance.new("TextBox", passiveBoxFrame)
    passiveBox.Size                  = UDim2.new(1, -16, 1, 0)
    passiveBox.Position              = UDim2.new(0, 8, 0, 0)
    passiveBox.BackgroundTransparency = 1
    passiveBox.TextColor3            = CONFIG.TEXT_PRIMARY
    passiveBox.TextSize              = 12
    passiveBox.Font                  = Enum.Font.GothamSemibold
    passiveBox.PlaceholderText       = "Ex: Reflexos, Força..."
    passiveBox.PlaceholderColor3     = CONFIG.TEXT_SECONDARY
    passiveBox.Text                  = ""
    passiveBox.ClearTextOnFocus      = false
    passiveBox.ZIndex                = 5
    local passiveBoxPad = Instance.new("UIPadding", passiveBox)
    passiveBoxPad.PaddingLeft = UDim.new(0, 2)

    -- Hover/focus no frame
    passiveBox.Focused:Connect(function()
        TweenService:Create(passiveBoxStroke, TweenInfo.new(0.15), {Color = CONFIG.ACCENT_COLOR}):Play()
    end)
    passiveBox.FocusLost:Connect(function(enterPressed)
        TweenService:Create(passiveBoxStroke, TweenInfo.new(0.15), {Color = CONFIG.BORDER_COLOR}):Play()
        if not enterPressed or passiveBox.Text == "" then return end

        local passiveName = passiveBox.Text

        local ok = pcall(function()
            local args = { passiveName, 1 }
            game:GetService("ReplicatedStorage")
                :WaitForChild("TS")
                :WaitForChild("GeneratedNetworkRemotes")
                :WaitForChild("RE_5.456556666731276e+76")
                :FireServer(unpack(args))
        end)

        if ok then
            passiveDesc.Text = "✔  \"" .. passiveName .. "\" equipado!"
            TweenService:Create(passiveDesc, TweenInfo.new(0.1), {TextColor3 = CONFIG.SUCCESS}):Play()
            TweenService:Create(passiveBoxStroke, TweenInfo.new(0.1), {Color = CONFIG.SUCCESS}):Play()
        else
            passiveDesc.Text = "❌  Erro ao equipar passivo"
            TweenService:Create(passiveDesc, TweenInfo.new(0.1), {TextColor3 = CONFIG.DANGER}):Play()
            TweenService:Create(passiveBoxStroke, TweenInfo.new(0.1), {Color = CONFIG.DANGER}):Play()
        end

        task.delay(2.5, function()
            passiveDesc.Text = "Digite o nome e pressione Enter"
            TweenService:Create(passiveDesc, TweenInfo.new(0.3), {TextColor3 = CONFIG.TEXT_SECONDARY}):Play()
            TweenService:Create(passiveBoxStroke, TweenInfo.new(0.3), {Color = CONFIG.BORDER_COLOR}):Play()
        end)
    end)

    createSeparator(SkillsPage)

    -- ── Slider Parry Distance ──────────────────
    local pdContainer = Instance.new("Frame", SkillsPage)
    pdContainer.Size             = UDim2.new(1, 0, 0, 72)
    pdContainer.BackgroundColor3 = CONFIG.BG_PANEL
    pdContainer.BorderSizePixel  = 0
    pdContainer.ZIndex           = 3
    Instance.new("UICorner", pdContainer).CornerRadius = UDim.new(0, 10)
    local pdStroke = Instance.new("UIStroke", pdContainer)
    pdStroke.Color = CONFIG.BORDER_COLOR; pdStroke.Thickness = 1

    local pdTitle = Instance.new("TextLabel", pdContainer)
    pdTitle.Text = "Parry Distance"
    pdTitle.Size = UDim2.new(0.55, 0, 0, 18)
    pdTitle.Position = UDim2.new(0, 14, 0, 6)
    pdTitle.BackgroundTransparency = 1
    pdTitle.TextColor3 = CONFIG.TEXT_PRIMARY
    pdTitle.TextSize = 12; pdTitle.Font = Enum.Font.GothamSemibold
    pdTitle.TextXAlignment = Enum.TextXAlignment.Left
    pdTitle.ZIndex = 4

    local pdValueLabel = Instance.new("TextLabel", pdContainer)
    pdValueLabel.Text = "1 st"
    pdValueLabel.Size = UDim2.new(0.42, 0, 0, 18)
    pdValueLabel.Position = UDim2.new(0.58, -14, 0, 6)
    pdValueLabel.BackgroundTransparency = 1
    pdValueLabel.TextColor3 = CONFIG.ACCENT_COLOR
    pdValueLabel.TextSize = 12; pdValueLabel.Font = Enum.Font.GothamBold
    pdValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    pdValueLabel.ZIndex = 4

    local pdDesc = Instance.new("TextLabel", pdContainer)
    pdDesc.Text = "Raio base do detector de parry"
    pdDesc.Size = UDim2.new(1, -28, 0, 14)
    pdDesc.Position = UDim2.new(0, 14, 0, 26)
    pdDesc.BackgroundTransparency = 1
    pdDesc.TextColor3 = CONFIG.TEXT_SECONDARY
    pdDesc.TextSize = 10; pdDesc.Font = Enum.Font.Gotham
    pdDesc.TextXAlignment = Enum.TextXAlignment.Left
    pdDesc.ZIndex = 4

    local pdTrack = Instance.new("Frame", pdContainer)
    pdTrack.Size = UDim2.new(1, -28, 0, 6)
    pdTrack.Position = UDim2.new(0, 14, 0, 50)
    pdTrack.BackgroundColor3 = CONFIG.TOGGLE_OFF
    pdTrack.BorderSizePixel = 0; pdTrack.ZIndex = 4
    Instance.new("UICorner", pdTrack).CornerRadius = UDim.new(1, 0)

    local pdFill = Instance.new("Frame", pdTrack)
    pdFill.Size = UDim2.new(0, 0, 1, 0)
    pdFill.BackgroundColor3 = CONFIG.ACCENT_COLOR
    pdFill.BorderSizePixel = 0; pdFill.ZIndex = 5
    Instance.new("UICorner", pdFill).CornerRadius = UDim.new(1, 0)

    local pdKnob = Instance.new("Frame", pdTrack)
    pdKnob.Size = UDim2.new(0, 14, 0, 14)
    pdKnob.Position = UDim2.new(0, -7, 0.5, -7)
    pdKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pdKnob.BorderSizePixel = 0; pdKnob.ZIndex = 6
    Instance.new("UICorner", pdKnob).CornerRadius = UDim.new(1, 0)

    -- Range: 1 a 50 studs
    local PD_MIN, PD_MAX = 1, 50
    local pdDragging = false

    local function updatePdSlider(xRatio)
        xRatio = math.clamp(xRatio, 0, 1)
        local value = math.round(PD_MIN + xRatio * (PD_MAX - PD_MIN))
        CONFIG.PARRY_DIST = value
        pdValueLabel.Text = value .. " st"
        pdFill.Size = UDim2.new(xRatio, 0, 1, 0)
        pdKnob.Position = UDim2.new(xRatio, -7, 0.5, -7)
    end

    pdTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            pdDragging = true
            updatePdSlider((input.Position.X - pdTrack.AbsolutePosition.X) / pdTrack.AbsoluteSize.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if pdDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                           input.UserInputType == Enum.UserInputType.Touch) then
            updatePdSlider((input.Position.X - pdTrack.AbsolutePosition.X) / pdTrack.AbsoluteSize.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            pdDragging = false
        end
    end)
end

createToggle(VisualPage, "Show Detectors", "Exibe as esferas dos detectores no mundo", function(on)
    State.showDetectors = on
    if State.detectorPart     then State.detectorPart.Transparency     = on and 0.6 or 1 end
    if State.spamDetectorPart then State.spamDetectorPart.Transparency = on and 0.6 or 1 end
end)

createSeparator(VisualPage)

-- No Anime Ball, a página Visual mostra só os stats panels
if DETECTED_GAME == "anime" then
    local animeVisualInfo = Instance.new("TextLabel", VisualPage)
    animeVisualInfo.Text                  = "ANIME BALL  ·  Stats Panels"
    animeVisualInfo.Size                  = UDim2.new(1, 0, 0, 18)
    animeVisualInfo.BackgroundTransparency = 1
    animeVisualInfo.TextColor3            = Color3.fromRGB(251, 146, 60)
    animeVisualInfo.TextSize              = 10
    animeVisualInfo.Font                  = Enum.Font.GothamBold
    animeVisualInfo.TextXAlignment        = Enum.TextXAlignment.Left
    animeVisualInfo.ZIndex                = 3
    createSeparator(VisualPage)
end

-- ══════════════════════════════════════════
--     GUI FLUTUANTE - AUTO PARRY STATS
-- ══════════════════════════════════════════
local ParryStatsGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ParryStatsGui.Name           = "ParryStatsGui"
ParryStatsGui.ResetOnSpawn   = false
ParryStatsGui.IgnoreGuiInset = true
ParryStatsGui.Enabled        = false

local ParryStatsFrame = Instance.new("Frame", ParryStatsGui)
ParryStatsFrame.Size             = UDim2.new(0, 210, 0, 140)
ParryStatsFrame.Position         = UDim2.new(0, 80, 0.5, -160)
ParryStatsFrame.BackgroundColor3 = CONFIG.BG_DARK
ParryStatsFrame.BorderSizePixel  = 0
Instance.new("UICorner", ParryStatsFrame).CornerRadius = UDim.new(0, 12)
local psStroke = Instance.new("UIStroke", ParryStatsFrame)
psStroke.Color = CONFIG.ACCENT_COLOR; psStroke.Thickness = 1.5

local psHeader = Instance.new("Frame", ParryStatsFrame)
psHeader.Size             = UDim2.new(1, 0, 0, 34)
psHeader.BackgroundColor3 = CONFIG.BG_MID
psHeader.BorderSizePixel  = 0
Instance.new("UICorner", psHeader).CornerRadius = UDim.new(0, 12)
local psHeaderFix = Instance.new("Frame", psHeader)
psHeaderFix.Size = UDim2.new(1,0,0,12); psHeaderFix.Position = UDim2.new(0,0,1,-12)
psHeaderFix.BackgroundColor3 = CONFIG.BG_MID; psHeaderFix.BorderSizePixel = 0

local psTitle = Instance.new("TextLabel", psHeader)
psTitle.Text = "⚔  AUTO PARRY STATS"
psTitle.Size = UDim2.new(1,-10,1,0); psTitle.Position = UDim2.new(0,10,0,0)
psTitle.BackgroundTransparency = 1; psTitle.TextColor3 = CONFIG.ACCENT_COLOR
psTitle.TextSize = 11; psTitle.Font = Enum.Font.GothamBold
psTitle.TextXAlignment = Enum.TextXAlignment.Left

local psAccent = Instance.new("Frame", psHeader)
psAccent.Size = UDim2.new(0.45,0,0,2); psAccent.Position = UDim2.new(0,10,1,-2)
psAccent.BackgroundColor3 = CONFIG.ACCENT_COLOR; psAccent.BorderSizePixel = 0
Instance.new("UICorner", psAccent).CornerRadius = UDim.new(1,0)

-- Glow no fundo da parry stats frame
local psGlow = Instance.new("Frame", ParryStatsFrame)
psGlow.Size = UDim2.new(1,0,1,0); psGlow.BackgroundTransparency = 1; psGlow.ZIndex = 0
local psGlowGrad = Instance.new("UIGradient", psGlow)
psGlowGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, CONFIG.ACCENT_COLOR), ColorSequenceKeypoint.new(1, CONFIG.BG_DARK)})
psGlowGrad.Rotation = 135
psGlowGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.92), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1)})

local function makeStat(parent, yPos, label)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1,-20,0,18); f.Position = UDim2.new(0,10,0,yPos)
    f.BackgroundTransparency = 1
    local k = Instance.new("TextLabel", f)
    k.Size = UDim2.new(0.55,0,1,0); k.BackgroundTransparency = 1
    k.TextColor3 = CONFIG.TEXT_SECONDARY; k.TextSize = 10; k.Font = Enum.Font.Gotham
    k.TextXAlignment = Enum.TextXAlignment.Left; k.Text = label
    local v = Instance.new("TextLabel", f)
    v.Name = "Value"
    v.Size = UDim2.new(0.45,0,1,0); v.Position = UDim2.new(0.55,0,0,0)
    v.BackgroundTransparency = 1
    v.TextColor3 = CONFIG.TEXT_PRIMARY; v.TextSize = 10; v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Right; v.Text = "—"
    return v
end

local psStatStatus = makeStat(ParryStatsFrame, 42,  "Status")
local psStatRadius = makeStat(ParryStatsFrame, 63,  "Raio Atual")
local psStatVel    = makeStat(ParryStatsFrame, 84,  "Vel. Bola")
local psStatCount  = makeStat(ParryStatsFrame, 105, "Total Parrys")

makeDraggable(ParryStatsFrame, psHeader)

-- ══════════════════════════════════════════
--     GUI FLUTUANTE - AUTO SPAM STATS
-- ══════════════════════════════════════════
local SpamStatsGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
SpamStatsGui.Name           = "SpamStatsGui"
SpamStatsGui.ResetOnSpawn   = false
SpamStatsGui.IgnoreGuiInset = true
SpamStatsGui.Enabled        = false

local SpamStatsFrame = Instance.new("Frame", SpamStatsGui)
SpamStatsFrame.Size             = UDim2.new(0, 210, 0, 140)
SpamStatsFrame.Position         = UDim2.new(0, 80, 0.5, -10)
SpamStatsFrame.BackgroundColor3 = CONFIG.BG_DARK
SpamStatsFrame.BorderSizePixel  = 0
Instance.new("UICorner", SpamStatsFrame).CornerRadius = UDim.new(0, 12)
local ssStroke = Instance.new("UIStroke", SpamStatsFrame)
ssStroke.Color = CONFIG.DANGER; ssStroke.Thickness = 1.5

local ssHeader = Instance.new("Frame", SpamStatsFrame)
ssHeader.Size             = UDim2.new(1, 0, 0, 34)
ssHeader.BackgroundColor3 = CONFIG.BG_MID
ssHeader.BorderSizePixel  = 0
Instance.new("UICorner", ssHeader).CornerRadius = UDim.new(0, 12)
local ssHeaderFix = Instance.new("Frame", ssHeader)
ssHeaderFix.Size = UDim2.new(1,0,0,12); ssHeaderFix.Position = UDim2.new(0,0,1,-12)
ssHeaderFix.BackgroundColor3 = CONFIG.BG_MID; ssHeaderFix.BorderSizePixel = 0

local ssTitle = Instance.new("TextLabel", ssHeader)
ssTitle.Text = "⚡  AUTO SPAM STATS"
ssTitle.Size = UDim2.new(1,-10,1,0); ssTitle.Position = UDim2.new(0,10,0,0)
ssTitle.BackgroundTransparency = 1; ssTitle.TextColor3 = CONFIG.DANGER
ssTitle.TextSize = 11; ssTitle.Font = Enum.Font.GothamBold
ssTitle.TextXAlignment = Enum.TextXAlignment.Left

local ssAccent = Instance.new("Frame", ssHeader)
ssAccent.Size = UDim2.new(0.45,0,0,2); ssAccent.Position = UDim2.new(0,10,1,-2)
ssAccent.BackgroundColor3 = CONFIG.DANGER; ssAccent.BorderSizePixel = 0
Instance.new("UICorner", ssAccent).CornerRadius = UDim.new(1,0)

local ssGlow = Instance.new("Frame", SpamStatsFrame)
ssGlow.Size = UDim2.new(1,0,1,0); ssGlow.BackgroundTransparency = 1; ssGlow.ZIndex = 0
local ssGlowGrad = Instance.new("UIGradient", ssGlow)
ssGlowGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, CONFIG.DANGER), ColorSequenceKeypoint.new(1, CONFIG.BG_DARK)})
ssGlowGrad.Rotation = 135
ssGlowGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.92), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 1)})

local ssStatStatus = makeStat(SpamStatsFrame, 42,  "Status")
local ssStatTarget = makeStat(SpamStatsFrame, 63,  "Target")
local ssStatMult   = makeStat(SpamStatsFrame, 84,  "Multiplier")
local ssStatCount  = makeStat(SpamStatsFrame, 105, "Total Fires")

makeDraggable(SpamStatsFrame, ssHeader)

-- ── Loop de atualização dos stats ─────────
RunService.RenderStepped:Connect(function()
    if State.showParryStats then
        if State.autoParry then
            local curRadius
            if DETECTED_GAME == "anime" then
                curRadius = math.clamp(CONFIG.PARRY_DIST + math.floor(State.animeTrackedSpeed / 6.5), CONFIG.PARRY_DIST, 300)
            else
                curRadius = math.clamp(CONFIG.PARRY_DIST + math.floor(trackedSpeed / 5), CONFIG.PARRY_DIST, 300)
            end
            psStatStatus.Text = State.hasExecutedThisDetection and "🔴 Executado" or "🟢 Monitorando"
            psStatRadius.Text = string.format("%.1f st", curRadius)
            psStatVel.Text    = DETECTED_GAME == "anime"
                and string.format("%.1f s/s", State.animeTrackedSpeed)
                or  string.format("%.1f s/s", trackedSpeed)
        else
            psStatStatus.Text = "⚫ Inativo"
            psStatRadius.Text = "—"
            psStatVel.Text    = "—"
        end
        psStatCount.Text = tostring(State.parryCount)
    end

    if State.showSpamStats then
        ssStatStatus.Text = State.spamActive and "🔴 Spamando" or (State.autoSpam and "🟡 Aguardando" or "⚫ Inativo")
        ssStatMult.Text   = "x" .. tostring(State.spamMultiplier)
        ssStatCount.Text  = tostring(State.spamCount)
        ssStatTarget.Text = State.savedSpamTarget or "Nenhum"
    end
end)

-- Toggles na tab Visual
createToggle(VisualPage, "Show Parry Stats", "Exibe painel de stats do Auto Parry", function(on)
    State.showParryStats  = on
    ParryStatsGui.Enabled = on
end)

createToggle(VisualPage, "Show Spam Stats", "Exibe painel de stats do Auto Spam", function(on)
    State.showSpamStats  = on
    SpamStatsGui.Enabled = on
end)

-- Anime Ball: ativa automaticamente os dois stats panels ao carregar
if DETECTED_GAME == "anime" then
    State.showParryStats  = true
    State.showSpamStats   = true
    ParryStatsGui.Enabled = true
    SpamStatsGui.Enabled  = true
end

-- ══════════════════════════════════════════
--         EFEITOS VISUAIS
-- ══════════════════════════════════════════

-- Partículas
local particleContainer = Instance.new("Frame", MainFrame)
particleContainer.Size                   = UDim2.new(1, 0, 1, 0)
particleContainer.BackgroundTransparency = 1
particleContainer.ZIndex                 = 0
particleContainer.ClipsDescendants       = true

local function spawnParticle()
    local dot = Instance.new("Frame", particleContainer)
    dot.Size             = UDim2.new(0, math.random(2,5), 0, math.random(2,5))
    dot.Position         = UDim2.new(math.random(), 0, 1, 0)
    dot.BackgroundColor3 = (math.random() > 0.5) and CONFIG.ACCENT_COLOR or CONFIG.ACCENT_GLOW
    dot.BackgroundTransparency = 0.5
    dot.BorderSizePixel  = 0
    dot.ZIndex           = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local dur = math.random(3, 7)
    TweenService:Create(dot, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
        Position = UDim2.new(dot.Position.X.Scale, 0, -0.1, 0),
        BackgroundTransparency = 1,
    }):Play()
    task.delay(dur, function() if dot.Parent then dot:Destroy() end end)
end

task.spawn(function()
    while true do
        task.wait(math.random() * 0.8 + 0.2)
        if MainFrame.Visible then spawnParticle() end
    end
end)

-- Scan line
local scanLine = Instance.new("Frame", MainFrame)
scanLine.Size                  = UDim2.new(1, 0, 0, 2)
scanLine.Position              = UDim2.new(0, 0, 0, 0)
scanLine.BackgroundColor3      = CONFIG.ACCENT_COLOR
scanLine.BackgroundTransparency = 0.85
scanLine.BorderSizePixel       = 0
scanLine.ZIndex                = 1

local scanGrad = Instance.new("UIGradient", scanLine)
scanGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.5, CONFIG.ACCENT_COLOR),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,0,0)),
})

task.spawn(function()
    while true do
        TweenService:Create(scanLine, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {Position = UDim2.new(0,0,1,0)}):Play()
        task.wait(2.5)
        scanLine.Position = UDim2.new(0,0,0,0)
        task.wait(0.1)
    end
end)

-- ══════════════════════════════════════════
--         INICIALIZAÇÃO
-- ══════════════════════════════════════════
selectTab("Combat")

MainFrame.Size = UDim2.new(0, 0, 0, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 440, 0, 320)
}):Play()

print("[NexusHub] ✓ Carregado com sucesso!")
