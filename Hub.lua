-- ════════════════════════════════════════════════════════════════
--   Sigma Hub v4.0  |  loadstring-ready
--   Correções: OnClose funcional, cleanup de conexões/loops,
--   X real no header, elementos melhorados, drag touch/mouse
-- ════════════════════════════════════════════════════════════════

local Hub = {}
Hub.__index = Hub

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local lp               = Players.LocalPlayer

-- ════════════ PALETA ════════════
local COR = {
    ACENTO   = Color3.fromRGB(124, 110, 245),
    ACENTO2  = Color3.fromRGB(167, 139, 250),
    FUNDO    = Color3.fromRGB(11,  12,  18),
    FUNDO2   = Color3.fromRGB(7,   8,   13),
    CARD     = Color3.fromRGB(16,  18,  28),
    CARD2    = Color3.fromRGB(20,  22,  35),
    BORDA    = Color3.fromRGB(32,  35,  55),
    BORDA2   = Color3.fromRGB(45,  48,  75),
    TEXTO    = Color3.fromRGB(225, 228, 245),
    MUTED    = Color3.fromRGB(100, 105, 140),
    VERDE    = Color3.fromRGB(52,  211, 153),
    AMARELO  = Color3.fromRGB(251, 191,  36),
    VERMELHO = Color3.fromRGB(248,  82,  83),
}

-- ════════════ ESTADO INTERNO ════════════
Hub._flags       = {}
Hub._elementos   = {}
Hub._abas        = {}
Hub._abaAtiva    = nil
Hub._gui         = nil
Hub._ativosCount = 0
Hub._footerInfo  = nil

-- Lista de conexões RBXScriptConnection e callbacks a disparar no OnClose
Hub._conexoes    = {}   -- {conn: RBXScriptConnection}  → Disconnect() ao fechar
Hub._onCloseCbs  = {}   -- lista de funções a chamar ao fechar

-- ════════════════════════════════════════
--   UTILITÁRIOS
-- ════════════════════════════════════════
local function novo(cls, props, pai)
    local obj = Instance.new(cls)
    for k, v in pairs(props or {}) do obj[k] = v end
    if pai then obj.Parent = pai end
    return obj
end

local function arredondar(frame, raio)
    return novo("UICorner", {CornerRadius = UDim.new(0, raio or 8)}, frame)
end

local function borda(frame, cor, esp)
    return novo("UIStroke", {Color = cor or COR.BORDA, Thickness = esp or 1}, frame)
end

local function tw(obj, info, props)
    return TweenService:Create(obj, info, props)
end

local function twFast(obj, props)
    return tw(obj, TweenInfo.new(0.15, Enum.EasingStyle.Quart), props)
end

local function nomeKeybind(kc)
    local s = tostring(kc)
    return s:match("%.(%w+)$") or s
end

-- Registra uma conexão para ser desconectada automaticamente ao fechar
local function regConn(conn)
    table.insert(Hub._conexoes, conn)
    return conn
end

-- ════════════════════════════════════════
--   OnClose  — registra callbacks
-- ════════════════════════════════════════
--[[
    Uso:
        Hub.OnClose(function()
            loop:Disconnect()      -- para um RunService loop
            connection:Disconnect()
        end)
    Pode ser chamado várias vezes; todos são executados ao fechar.
]]
function Hub.OnClose(cb)
    if type(cb) == "function" then
        table.insert(Hub._onCloseCbs, cb)
    end
end

-- Executa todos os OnClose callbacks + desconecta conexões internas + destrói a GUI
local function executarFechamento()
    -- Callbacks do usuário primeiro
    for _, cb in ipairs(Hub._onCloseCbs) do
        pcall(cb)
    end
    -- Desconecta conexões internas registradas com regConn
    for _, conn in ipairs(Hub._conexoes) do
        pcall(function() conn:Disconnect() end)
    end
    Hub._conexoes   = {}
    Hub._onCloseCbs = {}

    if Hub._gui then
        Hub._gui:Destroy()
        Hub._gui = nil
    end
end

-- ════════════════════════════════════════
--   DRAG (mouse + touch)
-- ════════════════════════════════════════
local function adicionarDrag(janela, alca)
    local dragging  = false
    local dragStart = nil
    local startPos  = nil

    regConn(alca.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = janela.Position
        end
    end))

    regConn(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        janela.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end))

    regConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- ════════════════════════════════════════
--   NOTIFICAÇÕES
-- ════════════════════════════════════════
local notifHolder

local function criarNotifHolder(pai)
    notifHolder = novo("Frame", {
        Name = "NotifHolder",
        Size = UDim2.new(0, 290, 1, -24),
        Position = UDim2.new(1, -302, 0, 12),
        BackgroundTransparency = 1,
        ZIndex = 200,
    }, pai)
    novo("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, notifHolder)
end

function Hub.Notificar(titulo, subtitulo, tipo, tempo)
    if not notifHolder then return end
    tipo      = tipo  or "info"
    tempo     = tempo or 4
    titulo    = tostring(titulo    or "")
    subtitulo = tostring(subtitulo or "")

    local temas = {
        info    = {bg=Color3.fromRGB(18,16,48),  brd=COR.ACENTO,   dot=COR.ACENTO,   ico="ℹ"},
        success = {bg=Color3.fromRGB(8, 30,20),  brd=COR.VERDE,    dot=COR.VERDE,    ico="✓"},
        warn    = {bg=Color3.fromRGB(40,26,4),   brd=COR.AMARELO,  dot=COR.AMARELO,  ico="!"},
        danger  = {bg=Color3.fromRGB(35,10,10),  brd=COR.VERMELHO, dot=COR.VERMELHO, ico="✕"},
    }
    local c = temas[tipo] or temas.info
    local temSub = subtitulo ~= ""

    local notif = novo("Frame", {
        Size             = UDim2.new(1, 0, 0, temSub and 68 or 50),
        BackgroundColor3 = c.bg,
        AutomaticSize    = Enum.AutomaticSize.Y,
        ClipsDescendants = false,
        ZIndex           = 200,
    }, notifHolder)
    arredondar(notif, 10)
    borda(notif, c.brd, 1.5)

    -- Faixa lateral
    novo("Frame", {
        Size=UDim2.new(0,3,1,0), BackgroundColor3=c.dot,
        BorderSizePixel=0, ZIndex=201,
    }, notif)

    -- Ícone
    local iconFr = novo("Frame", {
        Size=UDim2.new(0,24,0,24), Position=UDim2.new(0,12,0,13),
        BackgroundColor3=c.bg, ZIndex=201,
    }, notif)
    arredondar(iconFr, 12)
    borda(iconFr, c.dot, 1.5)
    novo("TextLabel", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=c.ico, TextColor3=c.dot, TextSize=11,
        Font=Enum.Font.GothamBold, ZIndex=202,
    }, iconFr)

    -- Título
    novo("TextLabel", {
        Size=UDim2.new(1,-70,0,0), Position=UDim2.new(0,44,0,11),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, Text=titulo,
        TextColor3=Color3.fromRGB(235,238,255), TextSize=12,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=202,
    }, notif)

    if temSub then
        novo("TextLabel", {
            Size=UDim2.new(1,-70,0,0), Position=UDim2.new(0,44,0,28),
            AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Text=subtitulo,
            TextColor3=Color3.fromRGB(180,185,215), TextSize=10,
            Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true, ZIndex=202,
        }, notif)
    end

    -- Botão X
    local xNotif = novo("TextButton", {
        Size=UDim2.new(0,18,0,18), Position=UDim2.new(1,-24,0,8),
        BackgroundColor3=Color3.fromRGB(35,38,58),
        Text="✕", TextColor3=Color3.fromRGB(160,165,195),
        TextSize=9, Font=Enum.Font.GothamBold, ZIndex=203,
    }, notif)
    arredondar(xNotif, 5)

    -- Progress bar
    local barBg = novo("Frame", {
        Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=Color3.fromRGB(35,38,58), BorderSizePixel=0, ZIndex=202,
    }, notif)
    local barFill = novo("Frame", {
        Size=UDim2.new(1,0,1,0), BackgroundColor3=c.dot,
        BorderSizePixel=0, ZIndex=203,
    }, barBg)

    -- Animação entrada
    notif.Position = UDim2.new(0,12,0,0)
    notif:TweenPosition(UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.25,true)
    tw(barFill, TweenInfo.new(tempo,Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,1,0)}):Play()

    local function fecharNotif()
        notif:TweenPosition(UDim2.new(0,12,0,0),Enum.EasingDirection.In,Enum.EasingStyle.Quart,0.2,true,function()
            notif:Destroy()
        end)
    end
    xNotif.MouseButton1Click:Connect(fecharNotif)
    xNotif.TouchTap:Connect(fecharNotif)
    task.delay(tempo, fecharNotif)
    return notif
end

-- ════════════════════════════════════════
--   JANELA PRINCIPAL
-- ════════════════════════════════════════
function Hub.Iniciar(config)
    config = config or {}
    local titulo  = config.Titulo  or "Sigma Hub"
    local versao  = config.Versao  or "v4.0"
    local keybind = config.Keybind or Enum.KeyCode.RightShift
    local nomeKb  = nomeKeybind(keybind)

    -- Destrói instância anterior se existir
    local old = lp.PlayerGui:FindFirstChild("SigmaHub")
    if old then old:Destroy() end

    local sg = novo("ScreenGui", {
        Name="SigmaHub", ResetOnSpawn=false,
        DisplayOrder=100, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    }, lp.PlayerGui)
    Hub._gui = sg

    -- Janela
    local win = novo("Frame", {
        Name="Janela",
        Size=UDim2.new(0,345,0,475),
        Position=UDim2.new(0.5,-172,0.5,-237),
        BackgroundColor3=COR.FUNDO,
        Active=true, Draggable=false,
        ClipsDescendants=false,
    }, sg)
    arredondar(win, 14)
    borda(win, COR.BORDA, 1)

    -- Glow sutil
    local shadow = novo("ImageLabel", {
        Size=UDim2.new(1,40,1,40), Position=UDim2.new(0,-20,0,-20),
        BackgroundTransparency=1,
        Image="rbxassetid://5028857084",
        ImageColor3=Color3.fromRGB(30,25,80),
        ImageTransparency=0.6,
        ZIndex=0,
    }, win)

    -- ── HEADER ──
    local header = novo("Frame", {
        Size=UDim2.new(1,0,0,46),
        BackgroundColor3=COR.FUNDO2, ZIndex=2,
    }, win)
    arredondar(header, 14)
    borda(header, COR.BORDA)
    -- cobre o arredondamento inferior do header
    novo("Frame", {
        Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14),
        BackgroundColor3=COR.FUNDO2, BorderSizePixel=0, ZIndex=2,
    }, header)

    adicionarDrag(win, header)

    -- Diamante decorativo
    local diamond = novo("Frame", {
        Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,16,0.5,-5),
        BackgroundColor3=COR.ACENTO, Rotation=45, BorderSizePixel=0, ZIndex=3,
    }, header)
    arredondar(diamond, 2)
    -- Brilho no diamante
    local diamondGlow = novo("Frame", {
        Size=UDim2.new(0,5,0,5), Position=UDim2.new(0,18,0.5,-8),
        BackgroundColor3=Color3.fromRGB(200,190,255), Rotation=45,
        BorderSizePixel=0, ZIndex=4, BackgroundTransparency=0.5,
    }, header)
    arredondar(diamondGlow, 1)

    novo("TextLabel", {
        Size=UDim2.new(1,-140,1,0), Position=UDim2.new(0,32,0,0),
        BackgroundTransparency=1,
        Text=titulo.."  "..versao,
        TextColor3=COR.TEXTO, TextSize=13, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
    }, header)

    -- Badge ATIVO
    local statusBadge = novo("Frame", {
        Size=UDim2.new(0,52,0,20), Position=UDim2.new(1,-118,0.5,-10),
        BackgroundColor3=Color3.fromRGB(8,28,18), ZIndex=3,
    }, header)
    arredondar(statusBadge, 10)
    borda(statusBadge, Color3.fromRGB(20,70,40))
    local dotVerde = novo("Frame", {
        Size=UDim2.new(0,6,0,6), Position=UDim2.new(0,6,0.5,-3),
        BackgroundColor3=COR.VERDE, ZIndex=4,
    }, statusBadge)
    arredondar(dotVerde, 3)
    novo("TextLabel", {
        Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text="ATIVO",
        TextColor3=COR.VERDE, TextSize=9, Font=Enum.Font.GothamBold, ZIndex=4,
    }, statusBadge)

    -- Botão minimizar  "–"
    local minBtn = novo("TextButton", {
        Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-62,0.5,-13),
        BackgroundColor3=Color3.fromRGB(22,24,38),
        Text="–", TextColor3=Color3.fromRGB(150,155,190),
        TextSize=16, Font=Enum.Font.GothamBold, ZIndex=3,
    }, header)
    arredondar(minBtn, 7)
    borda(minBtn)

    minBtn.MouseEnter:Connect(function()
        twFast(minBtn, {BackgroundColor3=Color3.fromRGB(30,33,50)}):Play()
    end)
    minBtn.MouseLeave:Connect(function()
        twFast(minBtn, {BackgroundColor3=Color3.fromRGB(22,24,38)}):Play()
    end)

    local function minimizar()
        win.Visible = false
        Hub.Notificar("Hub minimizado", "Pressione "..nomeKb.." para reabrir", "warn", 4)
    end
    minBtn.MouseButton1Click:Connect(minimizar)
    minBtn.TouchTap:Connect(minimizar)

    -- ── BOTÃO FECHAR  "✕"  (dispara OnClose + destrói tudo) ──
    local closeBtn = novo("TextButton", {
        Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-30,0.5,-13),
        BackgroundColor3=Color3.fromRGB(38,14,14),
        Text="✕", TextColor3=Color3.fromRGB(220,85,85),
        TextSize=11, Font=Enum.Font.GothamBold, ZIndex=3,
    }, header)
    arredondar(closeBtn, 7)
    borda(closeBtn, Color3.fromRGB(80,22,22))

    closeBtn.MouseEnter:Connect(function()
        twFast(closeBtn, {BackgroundColor3=Color3.fromRGB(65,12,12), TextColor3=COR.VERMELHO}):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        twFast(closeBtn, {BackgroundColor3=Color3.fromRGB(38,14,14), TextColor3=Color3.fromRGB(220,85,85)}):Play()
    end)
    closeBtn.MouseButton1Click:Connect(executarFechamento)
    closeBtn.TouchTap:Connect(executarFechamento)

    -- ── TAB BAR ──
    local tabBar = novo("Frame", {
        Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,46),
        BackgroundColor3=COR.FUNDO2, ZIndex=2,
    }, win)
    borda(tabBar, COR.BORDA)
    novo("UIListLayout", {
        FillDirection=Enum.FillDirection.Horizontal,
        SortOrder=Enum.SortOrder.LayoutOrder,
    }, tabBar)

    -- ── ÁREA DE CONTEÚDO ──
    local contentArea = novo("Frame", {
        Size=UDim2.new(1,0,1,-118), Position=UDim2.new(0,0,0,80),
        BackgroundTransparency=1,
    }, win)

    -- ── FOOTER ──
    local footer = novo("Frame", {
        Size=UDim2.new(1,0,0,38),
        Position=UDim2.new(0,0,1,-38),
        BackgroundColor3=COR.FUNDO2, ZIndex=2,
    }, win)
    arredondar(footer, 14)
    borda(footer, COR.BORDA)
    novo("Frame", {
        Size=UDim2.new(1,0,0,14), BackgroundColor3=COR.FUNDO2,
        BorderSizePixel=0, ZIndex=2,
    }, footer)

    Hub._footerInfo = novo("TextLabel", {
        Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text="0 funções ativas",
        TextColor3=COR.MUTED, TextSize=10, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
    }, footer)

    local footerTag = novo("Frame", {
        Size=UDim2.new(0,62,0,20), Position=UDim2.new(1,-70,0.5,-10),
        BackgroundColor3=Color3.fromRGB(20,17,55), ZIndex=3,
    }, footer)
    arredondar(footerTag, 10)
    borda(footerTag, Color3.fromRGB(42,38,110))
    novo("TextLabel", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text="SIGMA", TextColor3=COR.ACENTO2,
        TextSize=9, Font=Enum.Font.GothamBold, ZIndex=4,
    }, footerTag)

    Hub._tabBar      = tabBar
    Hub._contentArea = contentArea

    criarNotifHolder(sg)

    -- Keybind para mostrar/ocultar
    regConn(UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == keybind and Hub._gui then
            win.Visible = not win.Visible
            if win.Visible then
                Hub.Notificar("Hub reaberto", "", "info", 2)
            end
        end
    end))

    Hub.Notificar("Hub iniciado!", titulo.." "..versao.." carregado", "success", 4)
    return Hub
end

-- ════════════════════════════════════════
--   ABAS
-- ════════════════════════════════════════
function Hub.NovaAba(nome)
    local tabBar      = Hub._tabBar
    local contentArea = Hub._contentArea
    local isFirst     = (#Hub._abas == 0)

    -- Botão da aba
    local btn = novo("TextButton", {
        Size=UDim2.new(0,85,1,0),
        BackgroundTransparency=1,
        Text=nome, TextSize=11,
        Font=Enum.Font.GothamMedium,
        TextColor3=isFirst and COR.ACENTO or COR.MUTED,
        ZIndex=3, LayoutOrder=#Hub._abas+1,
    }, tabBar)

    local underline = novo("Frame", {
        Size=UDim2.new(0.75,0,0,2),
        Position=UDim2.new(0.125,0,1,-2),
        BackgroundColor3=COR.ACENTO, BorderSizePixel=0,
        Visible=isFirst, ZIndex=4,
    }, btn)
    arredondar(underline, 2)

    -- Página (ScrollingFrame)
    local page = novo("ScrollingFrame", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3,
        ScrollBarImageColor3=Color3.fromRGB(50,54,80),
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=isFirst, ScrollingEnabled=true,
    }, contentArea)

    novo("UIListLayout", {
        Padding=UDim.new(0,7),
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        SortOrder=Enum.SortOrder.LayoutOrder,
    }, page)
    novo("UIPadding", {
        PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10),
        PaddingLeft=UDim.new(0,9), PaddingRight=UDim.new(0,9),
    }, page)

    local abaObj = {btn=btn, page=page, underline=underline, nome=nome}
    table.insert(Hub._abas, abaObj)
    if isFirst then Hub._abaAtiva = abaObj end

    local function selecionarAba()
        for _, a in ipairs(Hub._abas) do
            a.page.Visible=false; a.underline.Visible=false
            twFast(a.btn, {TextColor3=COR.MUTED}):Play()
        end
        page.Visible=true; underline.Visible=true
        twFast(btn, {TextColor3=COR.ACENTO}):Play()
        Hub._abaAtiva = abaObj
    end
    btn.MouseButton1Click:Connect(selecionarAba)
    btn.TouchTap:Connect(selecionarAba)

    -- ──────────────────────────────────────
    local Aba  = {}
    Aba._page  = page
    Aba._nome  = nome
    Aba._ordem = 0

    local function proxOrdem()
        Aba._ordem = Aba._ordem + 1
        return Aba._ordem
    end

    local function criarCard(altura, autoY)
        local card = novo("Frame", {
            Size=UDim2.new(1,0,0,altura or 52),
            BackgroundColor3=COR.CARD, BorderSizePixel=0,
            LayoutOrder=proxOrdem(),
            AutomaticSize=autoY and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        }, page)
        arredondar(card, 10)
        borda(card, COR.BORDA)
        return card
    end

    -- ── SEÇÃO LABEL ──
    function Aba.SecaoLabel(texto)
        local fr = novo("Frame", {
            Size=UDim2.new(1,0,0,22), BackgroundTransparency=1,
            LayoutOrder=proxOrdem(),
        }, page)
        -- Linha decorativa
        local linha = novo("Frame", {
            Size=UDim2.new(0,3,0,14), Position=UDim2.new(0,0,0.5,-7),
            BackgroundColor3=COR.ACENTO, BorderSizePixel=0,
        }, fr)
        arredondar(linha, 2)
        novo("TextLabel", {
            Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,8,0,0),
            BackgroundTransparency=1,
            Text=string.upper(texto),
            TextColor3=Color3.fromRGB(110,115,155),
            TextSize=9, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,
        }, fr)
        return fr
    end

    -- ════════════════════════════════════════
    --   TOGGLE  (melhorado)
    -- ════════════════════════════════════════
    function Aba.CriarToggle(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label    or "Toggle"
        local sub      = opcoes.Sub      or ""
        local padrao   = opcoes.Padrao   or false
        local flag     = opcoes.Flag     or label
        local callback = opcoes.AoMudar

        Hub._flags[flag] = padrao
        if padrao then
            Hub._ativosCount = Hub._ativosCount + 1
            Hub._footerInfo.Text = Hub._ativosCount.." funções ativas"
        end

        local altCard = sub ~= "" and 58 or 46
        local card = criarCard(altCard)
        novo("UIPadding", {
            PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
            PaddingTop=UDim.new(0,10),
        }, card)

        novo("TextLabel", {
            Size=UDim2.new(1,-58,0,18), Position=UDim2.new(0,0,0,0),
            BackgroundTransparency=1, Text=label, TextColor3=COR.TEXTO,
            TextSize=12, Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,
        }, card)

        if sub ~= "" then
            novo("TextLabel", {
                Size=UDim2.new(1,-58,0,13), Position=UDim2.new(0,0,0,20),
                BackgroundTransparency=1, Text=sub, TextColor3=COR.MUTED,
                TextSize=10, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, card)
        end

        -- Pill
        local pill = novo("Frame", {
            Size=UDim2.new(0,42,0,24),
            Position=UDim2.new(1,-42,0,0),
            BackgroundColor3=padrao and COR.ACENTO or Color3.fromRGB(28,30,46),
        }, card)
        arredondar(pill, 12)
        borda(pill, padrao and Color3.fromRGB(88,76,195) or COR.BORDA)

        -- Brilho interno quando ativo
        local pillGlow = novo("Frame", {
            Size=UDim2.new(0,18,0,8), Position=UDim2.new(0,4,0,3),
            BackgroundColor3=Color3.fromRGB(200,195,255),
            BackgroundTransparency=padrao and 0.65 or 1,
        }, pill)
        arredondar(pillGlow, 4)

        local knob = novo("Frame", {
            Size=UDim2.new(0,18,0,18),
            Position=padrao and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
            BackgroundColor3=padrao and Color3.fromRGB(255,255,255) or Color3.fromRGB(65,68,95),
        }, pill)
        arredondar(knob, 9)

        -- Hit area cobrindo o card todo
        local hit = novo("TextButton", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5,
        }, card)

        local estado = padrao
        local function alternar()
            estado = not estado
            Hub._flags[flag] = estado
            Hub._ativosCount = Hub._ativosCount + (estado and 1 or -1)
            Hub._footerInfo.Text = Hub._ativosCount.." funções ativas"

            local info = TweenInfo.new(0.22, Enum.EasingStyle.Quart)
            tw(pill, info, {
                BackgroundColor3 = estado and COR.ACENTO or Color3.fromRGB(28,30,46),
            }):Play()
            tw(knob, info, {
                Position = estado and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
                BackgroundColor3 = estado and Color3.fromRGB(255,255,255) or Color3.fromRGB(65,68,95),
            }):Play()
            tw(pillGlow, info, {
                BackgroundTransparency = estado and 0.65 or 1,
            }):Play()
            tw(card, TweenInfo.new(0.18), {
                BackgroundColor3 = estado and Color3.fromRGB(20,18,36) or COR.CARD,
            }):Play()

            if callback then callback(estado) end
        end
        hit.MouseButton1Click:Connect(alternar)
        hit.TouchTap:Connect(alternar)

        local elem = {}
        function elem.Valor()  return Hub._flags[flag] end
        function elem.Definir(v)
            if estado ~= v then alternar() end
        end
        Hub._elementos[flag] = elem
        return elem
    end

    -- ════════════════════════════════════════
    --   SLIDER  (melhorado, touch completo)
    -- ════════════════════════════════════════
    function Aba.CriarSlider(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label    or "Slider"
        local min      = opcoes.Min      or 0
        local max      = opcoes.Max      or 100
        local padrao   = math.clamp(opcoes.Padrao or min, min, max)
        local sufixo   = opcoes.Sufixo   or ""
        local passo    = opcoes.Passo    or 1
        local flag     = opcoes.Flag     or label
        local callback = opcoes.AoMudar

        Hub._flags[flag] = padrao

        local card = criarCard(76)
        novo("UIPadding", {
            PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
            PaddingTop=UDim.new(0,10),
        }, card)

        -- Linha topo: label + valor
        local topRow = novo("Frame", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1}, card)

        novo("TextLabel", {
            Size=UDim2.new(1,-62,1,0), BackgroundTransparency=1,
            Text=label, TextColor3=COR.TEXTO, TextSize=12,
            Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left,
        }, topRow)

        local valBox = novo("Frame", {
            Size=UDim2.new(0,56,0,20), Position=UDim2.new(1,-56,0,-1),
            BackgroundColor3=Color3.fromRGB(22,19,55), ZIndex=2,
        }, topRow)
        arredondar(valBox, 6)
        borda(valBox, Color3.fromRGB(42,38,108))

        local valLabel = novo("TextLabel", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text=tostring(padrao)..sufixo,
            TextColor3=COR.ACENTO2, TextSize=11, Font=Enum.Font.GothamBold, ZIndex=3,
        }, valBox)

        -- Trilho
        local trackBg = novo("Frame", {
            Size=UDim2.new(1,0,0,6), Position=UDim2.new(0,0,0,28),
            BackgroundColor3=Color3.fromRGB(24,26,42),
        }, card)
        arredondar(trackBg, 6)
        borda(trackBg, COR.BORDA)

        local pct = (padrao-min)/(max-min)
        local fill = novo("Frame", {
            Size=UDim2.new(pct,0,1,0),
            BackgroundColor3=COR.ACENTO,
        }, trackBg)
        arredondar(fill, 6)

        -- Gradiente no fill
        novo("UIGradient", {
            Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(100,80,240)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(160,130,255)),
            },
        }, fill)

        -- Thumb
        local thumb = novo("Frame", {
            Size=UDim2.new(0,18,0,18),
            Position=UDim2.new(pct,0,0.5,0),
            AnchorPoint=Vector2.new(0.5,0.5),
            BackgroundColor3=Color3.fromRGB(255,255,255), ZIndex=5,
        }, trackBg)
        arredondar(thumb, 9)
        borda(thumb, COR.ACENTO, 2)

        -- Ponto central do thumb
        local thumbDot = novo("Frame", {
            Size=UDim2.new(0,6,0,6),
            Position=UDim2.new(0.5,0,0.5,0),
            AnchorPoint=Vector2.new(0.5,0.5),
            BackgroundColor3=COR.ACENTO, ZIndex=6,
        }, thumb)
        arredondar(thumbDot, 3)

        -- Hit area mais larga para toque fácil
        local trackHit = novo("TextButton", {
            Size=UDim2.new(1,0,0,36), Position=UDim2.new(0,0,0.5,-18),
            BackgroundTransparency=1, Text="", ZIndex=4,
        }, trackBg)

        -- Min/max labels
        local rowMinMax = novo("Frame", {
            Size=UDim2.new(1,0,0,13), Position=UDim2.new(0,0,0,44),
            BackgroundTransparency=1,
        }, card)
        novo("TextLabel", {
            Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1,
            Text=tostring(min)..sufixo, TextColor3=COR.MUTED,
            TextSize=9, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left,
        }, rowMinMax)
        novo("TextLabel", {
            Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0),
            BackgroundTransparency=1,
            Text=tostring(max)..sufixo, TextColor3=COR.MUTED,
            TextSize=9, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Right,
        }, rowMinMax)

        local dragging = false

        local function updateSlider(absX)
            local p = math.clamp((absX - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
            -- Snap ao passo
            local range   = max - min
            local pasos   = range / passo
            local snapP   = math.round(p * pasos) / pasos
            local v       = math.clamp(min + snapP * range, min, max)
            Hub._flags[flag] = v
            fill.Size         = UDim2.new(snapP, 0, 1, 0)
            thumb.Position    = UDim2.new(snapP, 0, 0.5, 0)
            valLabel.Text     = tostring(v)..sufixo
            if callback then callback(v) end
        end

        -- Mouse
        local thumbBtn = novo("TextButton", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=6,
        }, thumb)
        thumbBtn.MouseButton1Down:Connect(function()
            dragging=true
            twFast(thumb, {Size=UDim2.new(0,22,0,22)}):Play()
        end)
        trackHit.MouseButton1Down:Connect(function()
            dragging=true
            updateSlider(UserInputService:GetMouseLocation().X)
        end)
        regConn(UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                updateSlider(input.Position.X)
            end
        end))
        regConn(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=false
                twFast(thumb, {Size=UDim2.new(0,18,0,18)}):Play()
            end
        end))

        -- Touch
        thumbBtn.TouchPan:Connect(function(_, _, _, state)
            if state==Enum.UserInputState.Begin then
                dragging=true
                twFast(thumb, {Size=UDim2.new(0,22,0,22)}):Play()
            elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then
                dragging=false
                twFast(thumb, {Size=UDim2.new(0,18,0,18)}):Play()
            end
        end)
        trackHit.TouchTap:Connect(function(positions)
            if positions and positions[1] then updateSlider(positions[1].X) end
        end)
        regConn(UserInputService.TouchMoved:Connect(function(touch, gpe)
            if dragging and not gpe then updateSlider(touch.Position.X) end
        end))
        regConn(UserInputService.TouchEnded:Connect(function()
            if dragging then
                dragging=false
                twFast(thumb, {Size=UDim2.new(0,18,0,18)}):Play()
            end
        end))

        local elem = {}
        function elem.Valor() return Hub._flags[flag] end
        function elem.Definir(v)
            v = math.clamp(v, min, max)
            local p = (v-min)/(max-min)
            Hub._flags[flag] = v
            fill.Size       = UDim2.new(p,0,1,0)
            thumb.Position  = UDim2.new(p,0,0.5,0)
            valLabel.Text   = tostring(v)..sufixo
        end
        Hub._elementos[flag] = elem
        return elem
    end

    -- ════════════════════════════════════════
    --   DROPDOWN  (melhorado)
    -- ════════════════════════════════════════
    function Aba.CriarDropdown(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label    or "Dropdown"
        local sub      = opcoes.Sub      or ""
        local itens    = opcoes.Itens    or {}
        local multi    = opcoes.Multi    or false
        local flag     = opcoes.Flag     or label
        local callback = opcoes.AoMudar

        local selecao    = {}
        Hub._flags[flag] = selecao
        local aberto     = false
        local itensBtns  = {}

        local card = criarCard(56, true)
        card.ClipsDescendants = false
        novo("UIPadding", {
            PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12),
            PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10),
        }, card)

        -- Badge tipo
        local badgeTipo = novo("Frame", {
            Size=UDim2.new(0,50,0,16),
            BackgroundColor3=Color3.fromRGB(20,17,52), ZIndex=2,
        }, card)
        arredondar(badgeTipo, 8)
        borda(badgeTipo, Color3.fromRGB(40,36,108))
        novo("TextLabel", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text=multi and "MULTI" or "ÚNICO",
            TextColor3=COR.ACENTO, TextSize=8, Font=Enum.Font.GothamBold, ZIndex=3,
        }, badgeTipo)

        novo("TextLabel", {
            Size=UDim2.new(1,-62,0,16), Position=UDim2.new(0,58,0,0),
            BackgroundTransparency=1, Text=label, TextColor3=COR.TEXTO,
            TextSize=12, Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
        }, card)

        local topOffset = 20
        if sub ~= "" then
            topOffset = 34
            novo("TextLabel", {
                Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,18),
                BackgroundTransparency=1, Text=sub, TextColor3=COR.MUTED,
                TextSize=10, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, card)
        end

        -- Head (botão de abrir)
        local head = novo("Frame", {
            Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,topOffset),
            BackgroundColor3=Color3.fromRGB(10,11,18), ZIndex=2,
        }, card)
        arredondar(head, 8)
        borda(head, COR.BORDA2)

        local headLbl = novo("TextLabel", {
            Size=UDim2.new(1,-30,1,0), Position=UDim2.new(0,10,0,0),
            BackgroundTransparency=1, Text="Selecione...",
            TextColor3=Color3.fromRGB(120,124,160), TextSize=11, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
        }, head)

        local arrow = novo("TextLabel", {
            Size=UDim2.new(0,24,1,0), Position=UDim2.new(1,-26,0,0),
            BackgroundTransparency=1, Text="▾",
            TextColor3=COR.MUTED, TextSize=12, Font=Enum.Font.Gotham, ZIndex=3,
        }, head)

        -- Lista dropdown
        local lista = novo("Frame", {
            Size=UDim2.new(1,0,0,0),
            Position=UDim2.new(0,0,0,topOffset+34),
            BackgroundColor3=Color3.fromRGB(10,11,18),
            ClipsDescendants=true, Visible=false, ZIndex=10,
        }, card)
        arredondar(lista, 8)
        borda(lista, COR.BORDA2)
        novo("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder}, lista)

        local function atualizarLabel()
            local sels={}
            for k in pairs(selecao) do table.insert(sels,k) end
            if #sels==0 then
                headLbl.Text="Selecione..."
                headLbl.TextColor3=Color3.fromRGB(120,124,160)
            else
                headLbl.Text=table.concat(sels,", ")
                headLbl.TextColor3=COR.TEXTO
            end
        end

        local function criarItemLista(texto)
            local item = novo("Frame", {
                Size=UDim2.new(1,0,0,34),
                BackgroundColor3=Color3.fromRGB(10,11,18), ZIndex=11,
            }, lista)

            -- Indicador selecionado
            local checkBg = novo("Frame", {
                Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,10,0.5,-8),
                BackgroundColor3=Color3.fromRGB(18,19,32), ZIndex=12,
            }, item)
            arredondar(checkBg, 4)
            borda(checkBg, COR.BORDA)

            local checkTxt = novo("TextLabel", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="",
                TextColor3=Color3.fromRGB(255,255,255), TextSize=9,
                Font=Enum.Font.GothamBold, ZIndex=13,
            }, checkBg)

            novo("TextLabel", {
                Size=UDim2.new(1,-36,1,0), Position=UDim2.new(0,32,0,0),
                BackgroundTransparency=1, Text=texto,
                TextColor3=Color3.fromRGB(195,200,230), TextSize=11, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
            }, item)

            local hitItem = novo("TextButton", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=13,
            }, item)

            hitItem.MouseEnter:Connect(function()
                twFast(item, {BackgroundColor3=Color3.fromRGB(18,20,34)}):Play()
            end)
            hitItem.MouseLeave:Connect(function()
                twFast(item, {BackgroundColor3=Color3.fromRGB(10,11,18)}):Play()
            end)

            local function setCheck(on)
                tw(checkBg, TweenInfo.new(0.15), {
                    BackgroundColor3=on and COR.ACENTO or Color3.fromRGB(18,19,32),
                }):Play()
                checkTxt.Text = on and "✓" or ""
            end

            local function onSelect()
                if multi then
                    if selecao[texto] then selecao[texto]=nil; setCheck(false)
                    else selecao[texto]=true; setCheck(true) end
                else
                    for k in pairs(selecao) do selecao[k]=nil end
                    for _,ib in ipairs(itensBtns) do ib.setCheck(false) end
                    selecao[texto]=true; setCheck(true)
                    aberto=false
                    tw(lista,TweenInfo.new(0.2,Enum.EasingStyle.Quart),{Size=UDim2.new(1,0,0,0)}):Play()
                    task.delay(0.2,function() lista.Visible=false end)
                    tw(arrow, TweenInfo.new(0.2), {Rotation=0}):Play()
                    arrow.Text="▾"
                end
                atualizarLabel()
                if callback then
                    local sels={}
                    for k in pairs(selecao) do table.insert(sels,k) end
                    callback(multi and sels or sels[1])
                end
            end
            hitItem.MouseButton1Click:Connect(onSelect)
            hitItem.TouchTap:Connect(onSelect)

            local entry={frame=item, setCheck=setCheck, texto=texto}
            table.insert(itensBtns, entry)
            return entry
        end

        for _,it in ipairs(itens) do criarItemLista(it) end

        local headBtn = novo("TextButton", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=11,
        }, head)

        local function toggleDropdown()
            aberto=not aberto
            local totalH = #itensBtns * 34
            if aberto then
                lista.Visible=true; lista.Size=UDim2.new(1,0,0,0)
                tw(lista, TweenInfo.new(0.22,Enum.EasingStyle.Quart),
                    {Size=UDim2.new(1,0,0,math.min(totalH,136))}):Play()
                tw(arrow, TweenInfo.new(0.2), {Rotation=180}):Play()
            else
                tw(lista, TweenInfo.new(0.18), {Size=UDim2.new(1,0,0,0)}):Play()
                tw(arrow, TweenInfo.new(0.2), {Rotation=0}):Play()
                task.delay(0.18, function() lista.Visible=false end)
            end
        end
        headBtn.MouseButton1Click:Connect(toggleDropdown)
        headBtn.TouchTap:Connect(toggleDropdown)

        local elem={}
        function elem.Selecionar(v)
            if type(v)=="table" then for _,k in ipairs(v) do selecao[k]=true end
            else selecao[v]=true end
            atualizarLabel()
            for _,ib in ipairs(itensBtns) do ib.setCheck(selecao[ib.texto]~=nil) end
        end
        function elem.AdicionarOpcao(v)
            criarItemLista(v)
            if aberto then
                lista.Size=UDim2.new(1,0,0,math.min(#itensBtns*34,136))
            end
        end
        function elem.RemoverOpcao(v)
            for i,ib in ipairs(itensBtns) do
                if ib.texto==v then
                    ib.frame:Destroy(); table.remove(itensBtns,i)
                    selecao[v]=nil; atualizarLabel(); break
                end
            end
        end
        function elem.Valor()
            local sels={}
            for k in pairs(selecao) do table.insert(sels,k) end
            return multi and sels or sels[1]
        end
        Hub._elementos[flag]=elem
        return elem
    end

    -- ════════════════════════════════════════
    --   INPUT DE TEXTO  (novo elemento)
    -- ════════════════════════════════════════
    function Aba.CriarInput(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label       or "Input"
        local placeholder = opcoes.Placeholder or "Digite aqui..."
        local padrao   = opcoes.Padrao      or ""
        local flag     = opcoes.Flag        or label
        local callback = opcoes.AoMudar

        Hub._flags[flag] = padrao

        local card = criarCard(62)
        novo("UIPadding", {
            PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
            PaddingTop=UDim.new(0,10),
        }, card)

        novo("TextLabel", {
            Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
            Text=label, TextColor3=COR.TEXTO, TextSize=11,
            Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left,
        }, card)

        local inputBox = novo("Frame", {
            Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,20),
            BackgroundColor3=Color3.fromRGB(10,11,18),
        }, card)
        arredondar(inputBox, 7)
        borda(inputBox, COR.BORDA)

        local tb = novo("TextBox", {
            Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,8,0,0),
            BackgroundTransparency=1,
            Text=padrao, PlaceholderText=placeholder,
            TextColor3=COR.TEXTO, PlaceholderColor3=COR.MUTED,
            TextSize=11, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,
            ClearTextOnFocus=false, ZIndex=2,
        }, inputBox)

        tb.Focused:Connect(function()
            twFast(inputBox, {BackgroundColor3=Color3.fromRGB(14,12,35)}):Play()
            borda(inputBox, COR.ACENTO)
        end)
        tb.FocusLost:Connect(function()
            twFast(inputBox, {BackgroundColor3=Color3.fromRGB(10,11,18)}):Play()
            borda(inputBox, COR.BORDA)
            Hub._flags[flag] = tb.Text
            if callback then callback(tb.Text) end
        end)

        local elem={}
        function elem.Valor()    return Hub._flags[flag] end
        function elem.Definir(v) tb.Text=tostring(v); Hub._flags[flag]=v end
        Hub._elementos[flag]=elem
        return elem
    end

    -- ════════════════════════════════════════
    --   TEXTO / LABEL informativo
    -- ════════════════════════════════════════
    function Aba.CriarTexto(opcoes)
        opcoes=opcoes or {}
        local texto  = opcoes.Texto  or ""
        local titulo = opcoes.Titulo or nil
        local flag   = opcoes.Flag   or texto

        local card = criarCard(36, true)
        novo("UIPadding", {
            PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
            PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8),
        }, card)

        if titulo then
            local badge=novo("Frame", {
                Size=UDim2.new(0,48,0,15),
                BackgroundColor3=Color3.fromRGB(20,17,52), ZIndex=2,
            }, card)
            arredondar(badge,7); borda(badge,Color3.fromRGB(40,36,108))
            novo("TextLabel", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                Text="INFO", TextColor3=COR.ACENTO, TextSize=8, Font=Enum.Font.GothamBold, ZIndex=3,
            }, badge)
            novo("TextLabel", {
                Size=UDim2.new(1,-56,0,15), Position=UDim2.new(0,54,0,0),
                BackgroundTransparency=1, Text=titulo, TextColor3=COR.TEXTO,
                TextSize=11, Font=Enum.Font.GothamMedium,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2,
            }, card)
        end

        local offset = titulo and 18 or 0
        local txtLbl = novo("TextLabel", {
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,offset),
            AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
            Text=texto, TextColor3=Color3.fromRGB(185,190,220),
            TextSize=11, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        }, card)

        local elem={}
        function elem.Texto()    return txtLbl.Text end
        function elem.Definir(v) txtLbl.Text=tostring(v) end
        function elem.DefinirCor(r,g,b) txtLbl.TextColor3=Color3.fromRGB(r,g,b) end
        Hub._elementos[flag]=elem
        return elem
    end

    -- ════════════════════════════════════════
    --   BOTÃO  (melhorado)
    -- ════════════════════════════════════════
    function Aba.CriarBotao(opcoes)
        opcoes=opcoes or {}
        local label    = opcoes.Label    or "Botão"
        local sub      = opcoes.Sub      or ""
        local callback = opcoes.AoClicar
        local tipo     = opcoes.Tipo     or "normal"

        local temas={
            normal ={bg=Color3.fromRGB(20,17,55),  ht=COR.ACENTO2,   brd=Color3.fromRGB(44,40,115)},
            perigo ={bg=Color3.fromRGB(38,10,10),  ht=COR.VERMELHO,  brd=Color3.fromRGB(78,20,20)},
            sucesso={bg=Color3.fromRGB(8,28,16),   ht=COR.VERDE,     brd=Color3.fromRGB(18,58,32)},
        }
        local c=temas[tipo] or temas.normal

        local altCard = sub ~= "" and 52 or 42
        local card=criarCard(altCard)
        novo("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)},card)
        card.BackgroundColor3=c.bg
        borda(card,c.brd)

        -- Ícone / chevron
        novo("TextLabel",{
            Size=UDim2.new(0,22,1,0), Position=UDim2.new(1,-22,0,0),
            BackgroundTransparency=1, Text="›",
            TextColor3=c.ht, TextSize=20, Font=Enum.Font.GothamBold,
        },card)

        local mainLbl=novo("TextLabel",{
            Size=UDim2.new(1,-28,0,18),
            Position=UDim2.new(0,0,0.5,sub~="" and -11 or -9),
            BackgroundTransparency=1, Text=label, TextColor3=c.ht,
            TextSize=12, Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,
        },card)

        if sub~="" then
            novo("TextLabel",{
                Size=UDim2.new(1,-28,0,12),
                Position=UDim2.new(0,0,0.5,2),
                BackgroundTransparency=1, Text=sub,
                TextColor3=Color3.fromRGB(110,115,150), TextSize=9, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
            },card)
        end

        local btn=novo("TextButton",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5,
        },card)

        btn.MouseEnter:Connect(function()
            twFast(card, {BackgroundColor3=Color3.fromRGB(
                c.bg.R*255+8, c.bg.G*255+6, c.bg.B*255+18
            )}):Play()
        end)
        btn.MouseLeave:Connect(function()
            twFast(card, {BackgroundColor3=c.bg}):Play()
        end)

        local function onClick()
            tw(card,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(32,28,75)}):Play()
            task.delay(0.08,function() twFast(card,{BackgroundColor3=c.bg}):Play() end)
            if callback then callback() end
        end
        btn.MouseButton1Click:Connect(onClick)
        btn.TouchTap:Connect(onClick)

        local elem={}
        function elem.DefinirLabel(v) mainLbl.Text=v end
        return elem
    end

    -- ════════════════════════════════════════
    --   KEYBIND  (novo elemento)
    -- ════════════════════════════════════════
    function Aba.CriarKeybind(opcoes)
        opcoes=opcoes or {}
        local label    = opcoes.Label    or "Keybind"
        local padrao   = opcoes.Padrao   or Enum.KeyCode.E
        local flag     = opcoes.Flag     or label
        local callback = opcoes.AoPressionar

        Hub._flags[flag] = padrao
        local esperando = false
        local teclaAtual = padrao

        local card=criarCard(46)
        novo("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,10)},card)

        novo("TextLabel",{
            Size=UDim2.new(1,-90,0,20), BackgroundTransparency=1,
            Text=label, TextColor3=COR.TEXTO, TextSize=12,
            Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left,
        },card)

        local keyBox=novo("Frame",{
            Size=UDim2.new(0,80,0,26), Position=UDim2.new(1,-80,0,-3),
            BackgroundColor3=Color3.fromRGB(18,16,45), ZIndex=2,
        },card)
        arredondar(keyBox,7)
        borda(keyBox,Color3.fromRGB(40,36,100))

        local keyLbl=novo("TextLabel",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text=nomeKeybind(padrao), TextColor3=COR.ACENTO2,
            TextSize=10, Font=Enum.Font.GothamBold, ZIndex=3,
        },keyBox)

        local hitKey=novo("TextButton",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5,
        },card)

        hitKey.MouseButton1Click:Connect(function()
            esperando=not esperando
            if esperando then
                keyLbl.Text="..."
                twFast(keyBox,{BackgroundColor3=Color3.fromRGB(28,24,65)}):Play()
            else
                keyLbl.Text=nomeKeybind(teclaAtual)
                twFast(keyBox,{BackgroundColor3=Color3.fromRGB(18,16,45)}):Play()
            end
        end)

        regConn(UserInputService.InputBegan:Connect(function(input, gpe)
            if not esperando or gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                teclaAtual=input.KeyCode
                Hub._flags[flag]=teclaAtual
                keyLbl.Text=nomeKeybind(teclaAtual)
                esperando=false
                twFast(keyBox,{BackgroundColor3=Color3.fromRGB(18,16,45)}):Play()
                if callback then callback(teclaAtual) end
            end
        end))

        -- Escuta global pela tecla definida
        regConn(UserInputService.InputBegan:Connect(function(input,gpe)
            if not gpe and input.KeyCode==teclaAtual and callback then
                callback(teclaAtual)
            end
        end))

        local elem={}
        function elem.Valor() return Hub._flags[flag] end
        Hub._elementos[flag]=elem
        return elem
    end

    return Aba
end

-- ════════════════════════════════════════
--   ACESSO GLOBAL
-- ════════════════════════════════════════
function Hub.Elemento(flag) return Hub._elementos[flag] end
function Hub.Flag(flag)     return Hub._flags[flag] end

return Hub
