-- Sigma Hub v3.0 | API de loadstring | Hub completo com toggle/slider/dropdown/texto

local Hub = {}
Hub.__index = Hub

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local lp               = Players.LocalPlayer

local COR = {
    ACENTO   = Color3.fromRGB(124, 110, 245),
    FUNDO    = Color3.fromRGB(13,  15,  20),
    FUNDO2   = Color3.fromRGB(8,   10,  14),
    CARD     = Color3.fromRGB(19,  21,  30),
    BORDA    = Color3.fromRGB(30,  33,  48),
    TEXTO    = Color3.fromRGB(220, 224, 240),
    MUTED    = Color3.fromRGB(120, 124, 150),
    VERDE    = Color3.fromRGB(34,  197, 94),
    AMARELO  = Color3.fromRGB(245, 158, 11),
    VERMELHO = Color3.fromRGB(226, 75,  74),
}

Hub._flags        = {}
Hub._elementos    = {}
Hub._abas         = {}
Hub._abaAtiva     = nil
Hub._gui          = nil
Hub._ativosCount  = 0
Hub._onCloseCb    = nil

-- ════════════════════════════════════════════════
--   UTILITÁRIOS
-- ════════════════════════════════════════════════
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

local function tween(obj, info, props)
    return TweenService:Create(obj, info, props)
end

-- "Enum.KeyCode.RightShift" → "RightShift"
local function nomeKeybind(kc)
    local s = tostring(kc)
    return s:match("%.(%w+)$") or s
end

-- ════════════════════════════════════════════════
--   NOTIFICAÇÃO  (legibilidade + texto longo)
-- ════════════════════════════════════════════════
local notifHolder

local function criarNotifHolder(pai)
    notifHolder = novo("Frame", {
        Name = "NotifHolder",
        Size = UDim2.new(0, 280, 1, -20),
        Position = UDim2.new(1, -290, 0, 10),
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

    local cores = {
        info    = {bg=Color3.fromRGB(28,24,68),  brd=COR.ACENTO,   dot=COR.ACENTO},
        success = {bg=Color3.fromRGB(12,38,24),  brd=COR.VERDE,    dot=COR.VERDE},
        warn    = {bg=Color3.fromRGB(52,34,0),   brd=COR.AMARELO,  dot=COR.AMARELO},
        danger  = {bg=Color3.fromRGB(42,12,12),  brd=COR.VERMELHO, dot=COR.VERMELHO},
    }
    local c = cores[tipo] or cores.info

    local temSub      = subtitulo ~= ""
    local alturaBase  = temSub and 70 or 52

    local notif = novo("Frame", {
        Name             = "Notif_"..tick(),
        Size             = UDim2.new(1, 0, 0, alturaBase),
        BackgroundColor3 = c.bg,
        AutomaticSize    = Enum.AutomaticSize.Y,   -- cresce se texto for longo
        ClipsDescendants = false,
        ZIndex           = 200,
    }, notifHolder)
    arredondar(notif, 10)
    borda(notif, c.brd, 1.5)

    -- Barra lateral
    novo("Frame", {Size=UDim2.new(0,3,1,0), BackgroundColor3=c.dot, BorderSizePixel=0, ZIndex=201}, notif)

    -- Ícone
    local iconFr = novo("Frame", {
        Size             = UDim2.new(0,22,0,22),
        Position         = UDim2.new(0,12,0,14),
        BackgroundColor3 = c.bg,
        ZIndex           = 201,
    }, notif)
    arredondar(iconFr, 11)
    borda(iconFr, c.dot, 1.5)
    local icones = {info="●", success="✓", warn="!", danger="✕"}
    novo("TextLabel", {
        Size               = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text               = icones[tipo] or "●",
        TextColor3         = c.dot,
        TextSize           = 11,
        Font               = Enum.Font.GothamBold,
        ZIndex             = 202,
    }, iconFr)

    -- Título — branco puro p/ max contraste
    novo("TextLabel", {
        Size               = UDim2.new(1,-68,0,0),
        Position           = UDim2.new(0,42,0,10),
        AutomaticSize      = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text               = titulo,
        TextColor3         = Color3.fromRGB(240, 242, 255),
        TextSize           = 13,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextWrapped        = true,
        ZIndex             = 202,
    }, notif)

    -- Subtítulo
    if temSub then
        novo("TextLabel", {
            Size               = UDim2.new(1,-68,0,0),
            Position           = UDim2.new(0,42,0,30),
            AutomaticSize      = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text               = subtitulo,
            TextColor3         = Color3.fromRGB(190, 195, 225),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextWrapped        = true,
            ZIndex             = 202,
        }, notif)
    end

    -- Botão X
    local xBtn = novo("TextButton", {
        Size             = UDim2.new(0,18,0,18),
        Position         = UDim2.new(1,-24,0,8),
        BackgroundColor3 = Color3.fromRGB(40,43,62),
        Text             = "✕",
        TextColor3       = Color3.fromRGB(170,173,200),
        TextSize         = 10,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 203,
    }, notif)
    arredondar(xBtn, 5)

    -- Barra de progresso
    local barBg = novo("Frame", {
        Size             = UDim2.new(1,0,0,2),
        Position         = UDim2.new(0,0,1,-2),
        BackgroundColor3 = Color3.fromRGB(40,43,62),
        BorderSizePixel  = 0,
        ZIndex           = 202,
    }, notif)
    local barFill = novo("Frame", {
        Size             = UDim2.new(1,0,1,0),
        BackgroundColor3 = c.dot,
        BorderSizePixel  = 0,
        ZIndex           = 203,
    }, barBg)

    notif.Position = UDim2.new(0,10,0,0)
    notif:TweenPosition(UDim2.new(0,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true)
    tween(barFill, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,1,0)}):Play()

    local function fechar()
        notif:TweenPosition(UDim2.new(0,10,0,0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.2, true, function()
            notif:Destroy()
        end)
    end

    xBtn.MouseButton1Click:Connect(fechar)
    xBtn.TouchTap:Connect(fechar)
    task.delay(tempo, fechar)
    return notif
end

-- ════════════════════════════════════════════════
--   OnClose
-- ════════════════════════════════════════════════
function Hub.OnClose(cb)
    Hub._onCloseCb = cb
end

local function executarFechamento()
    if Hub._onCloseCb then pcall(Hub._onCloseCb) end
    if Hub._gui then
        Hub._gui:Destroy()
        Hub._gui = nil
    end
end

-- ════════════════════════════════════════════════
--   DRAG UNIFICADO (mouse + touch)
-- ════════════════════════════════════════════════
local function adicionarDrag(janela, alca)
    local dragging  = false
    local dragStart = nil
    local startPos  = nil

    local function onBegin(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = janela.Position
        end
    end
    local function onMove(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        janela.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
    local function onEnd(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    alca.InputBegan:Connect(onBegin)
    UserInputService.InputChanged:Connect(onMove)
    UserInputService.InputEnded:Connect(onEnd)
end

-- ════════════════════════════════════════════════
--   JANELA PRINCIPAL
-- ════════════════════════════════════════════════
function Hub.Iniciar(config)
    config = config or {}
    local titulo  = config.Titulo  or "Sigma Hub"
    local versao  = config.Versao  or "v3.0"
    local keybind = config.Keybind or Enum.KeyCode.RightShift
    local nomeKb  = nomeKeybind(keybind)

    if lp.PlayerGui:FindFirstChild("SigmaHub") then
        lp.PlayerGui.SigmaHub:Destroy()
    end

    local sg = novo("ScreenGui", {
        Name           = "SigmaHub",
        ResetOnSpawn   = false,
        DisplayOrder   = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, lp.PlayerGui)
    Hub._gui = sg

    local win = novo("Frame", {
        Name             = "Janela",
        Size             = UDim2.new(0,340,0,460),
        Position         = UDim2.new(0.5,-170,0.5,-230),
        BackgroundColor3 = COR.FUNDO,
        Active           = true,
        Draggable        = false,   -- drag manual p/ suporte touch
        ClipsDescendants = false,
    }, sg)
    arredondar(win, 12)
    borda(win)

    -- Header
    local header = novo("Frame", {
        Size             = UDim2.new(1,0,0,44),
        BackgroundColor3 = COR.FUNDO2,
        Active           = true,
        ZIndex           = 2,
    }, win)
    arredondar(header, 12)
    borda(header)
    novo("Frame", {Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,1,-12), BackgroundColor3=COR.FUNDO2, BorderSizePixel=0, ZIndex=2}, header)

    adicionarDrag(win, header)

    local diamond = novo("Frame", {
        Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,14,0.5,-5),
        BackgroundColor3=COR.ACENTO, Rotation=45, BorderSizePixel=0, ZIndex=3,
    }, header)
    arredondar(diamond, 2)

    novo("TextLabel", {
        Size=UDim2.new(1,-130,1,0), Position=UDim2.new(0,30,0,0),
        BackgroundTransparency=1, Text=titulo.."  "..versao,
        TextColor3=COR.TEXTO, TextSize=13, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
    }, header)

    local statusBadge = novo("TextLabel", {
        Size=UDim2.new(0,50,0,18), Position=UDim2.new(1,-112,0.5,-9),
        BackgroundColor3=Color3.fromRGB(10,32,21), Text="ATIVO",
        TextColor3=COR.VERDE, TextSize=9, Font=Enum.Font.GothamBold, ZIndex=3,
    }, header)
    arredondar(statusBadge, 9)
    borda(statusBadge, Color3.fromRGB(26,74,42))

    -- Botão minimizar (esconde; reabrir pelo keybind)
    local minBtn = novo("TextButton", {
        Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-62,0.5,-12),
        BackgroundColor3=Color3.fromRGB(25,28,38),
        Text="–", TextColor3=Color3.fromRGB(160,165,195),
        TextSize=16, Font=Enum.Font.GothamBold, ZIndex=3,
    }, header)
    arredondar(minBtn, 6)
    borda(minBtn)
    local function minimizar()
        win.Visible = false
        -- FIX: mostra "RightShift" e não "Enum.KeyCode.RightShift"
        Hub.Notificar("Hub minimizado", "Pressione "..nomeKb.." para reabrir", "warn", 4)
    end
    minBtn.MouseButton1Click:Connect(minimizar)
    minBtn.TouchTap:Connect(minimizar)

    -- Botão fechar completo (dispara OnClose e destrói tudo)
    local xBtn = novo("TextButton", {
        Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-32,0.5,-12),
        BackgroundColor3=Color3.fromRGB(35,14,14),
        Text="✕", TextColor3=Color3.fromRGB(200,90,90),
        TextSize=11, Font=Enum.Font.GothamBold, ZIndex=3,
    }, header)
    arredondar(xBtn, 6)
    borda(xBtn, Color3.fromRGB(80,25,25))
    xBtn.MouseEnter:Connect(function()
        tween(xBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(60,15,15), TextColor3=COR.VERMELHO}):Play()
    end)
    xBtn.MouseLeave:Connect(function()
        tween(xBtn, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(35,14,14), TextColor3=Color3.fromRGB(200,90,90)}):Play()
    end)
    xBtn.MouseButton1Click:Connect(executarFechamento)
    xBtn.TouchTap:Connect(executarFechamento)

    -- Barra de abas
    local tabBar = novo("Frame", {
        Size=UDim2.new(1,0,0,32), Position=UDim2.new(0,0,0,44),
        BackgroundColor3=COR.FUNDO2, ZIndex=2,
    }, win)
    borda(tabBar)
    novo("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder}, tabBar)

    local contentArea = novo("Frame", {
        Size=UDim2.new(1,0,1,-112), Position=UDim2.new(0,0,0,76),
        BackgroundTransparency=1,
    }, win)

    -- Footer
    local footer = novo("Frame", {
        Size=UDim2.new(1,0,0,36), Position=UDim2.new(1,0,1,-36),
        AnchorPoint=Vector2.new(1,1), BackgroundColor3=COR.FUNDO2, ZIndex=2,
    }, win)
    arredondar(footer, 12)
    borda(footer)
    novo("Frame", {Size=UDim2.new(1,0,0,12), BackgroundColor3=COR.FUNDO2, BorderSizePixel=0, ZIndex=2}, footer)

    local footerInfo = novo("TextLabel", {
        Size=UDim2.new(1,-80,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text="0 funções ativas",
        TextColor3=COR.MUTED, TextSize=10, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3,
    }, footer)
    Hub._footerInfo = footerInfo

    local footerTag = novo("TextLabel", {
        Size=UDim2.new(0,60,0,18), Position=UDim2.new(1,-68,0.5,-9),
        BackgroundColor3=Color3.fromRGB(22,19,58), Text="SIGMA",
        TextColor3=COR.ACENTO, TextSize=9, Font=Enum.Font.GothamBold, ZIndex=3,
    }, footer)
    arredondar(footerTag, 9)
    borda(footerTag, Color3.fromRGB(45,40,112))

    Hub._tabBar      = tabBar
    Hub._contentArea = contentArea

    criarNotifHolder(sg)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == keybind and Hub._gui then
            win.Visible = not win.Visible
            if win.Visible then Hub.Notificar("Hub reaberto", "", "info", 2) end
        end
    end)

    Hub.Notificar("Hub iniciado!", titulo.." "..versao.." carregado", "success", 4)
    return Hub
end

-- ════════════════════════════════════════════════
--   ABAS
-- ════════════════════════════════════════════════
function Hub.NovaAba(nome)
    local tabBar      = Hub._tabBar
    local contentArea = Hub._contentArea
    local isFirst     = (#Hub._abas == 0)

    local btn = novo("TextButton", {
        Size=UDim2.new(0,85,1,0), BackgroundTransparency=1,
        Text=nome, TextSize=11, Font=Enum.Font.GothamMedium,
        TextColor3=isFirst and COR.ACENTO or COR.MUTED,
        ZIndex=3, LayoutOrder=#Hub._abas+1,
    }, tabBar)

    local underline = novo("Frame", {
        Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=COR.ACENTO, BorderSizePixel=0, Visible=isFirst, ZIndex=4,
    }, btn)

    local page = novo("ScrollingFrame", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=3,
        ScrollBarImageColor3=Color3.fromRGB(45,48,72),
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=isFirst, ScrollingEnabled=true,
    }, contentArea)

    novo("UIListLayout", {
        Padding=UDim.new(0,6),
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        SortOrder=Enum.SortOrder.LayoutOrder,
    }, page)
    novo("UIPadding", {
        PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8),
        PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8),
    }, page)

    local abaObj = {btn=btn, page=page, underline=underline, nome=nome}
    table.insert(Hub._abas, abaObj)
    if isFirst then Hub._abaAtiva = abaObj end

    local function selecionarAba()
        for _, a in ipairs(Hub._abas) do
            a.page.Visible=false; a.underline.Visible=false
            tween(a.btn, TweenInfo.new(0.1), {TextColor3=COR.MUTED}):Play()
        end
        page.Visible=true; underline.Visible=true
        tween(btn, TweenInfo.new(0.1), {TextColor3=COR.ACENTO}):Play()
        Hub._abaAtiva = abaObj
    end
    btn.MouseButton1Click:Connect(selecionarAba)
    btn.TouchTap:Connect(selecionarAba)

    local Aba   = {}
    Aba._page   = page
    Aba._nome   = nome
    Aba._ordem  = 0

    local function proximaOrdem()
        Aba._ordem = Aba._ordem + 1
        return Aba._ordem
    end

    local function criarCard(altura)
        local card = novo("Frame", {
            Size=UDim2.new(1,0,0,altura or 50),
            BackgroundColor3=COR.CARD, BorderSizePixel=0,
            LayoutOrder=proximaOrdem(),
        }, page)
        arredondar(card, 9)
        borda(card)
        return card
    end

    function Aba.SecaoLabel(texto)
        local lbl = novo("TextLabel", {
            Size=UDim2.new(1,0,0,20), BackgroundTransparency=1,
            Text=string.upper(texto), TextColor3=Color3.fromRGB(120,124,155),
            TextSize=9, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Left,
            LayoutOrder=proximaOrdem(),
        }, page)
        novo("UIPadding", {PaddingLeft=UDim.new(0,4)}, lbl)
        return lbl
    end

    -- TOGGLE
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

        local card = criarCard(52)
        novo("UIPadding", {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)}, card)

        novo("TextLabel", {
            Size=UDim2.new(1,-55,0,18), Position=UDim2.new(0,0,0,9),
            BackgroundTransparency=1, Text=label, TextColor3=COR.TEXTO,
            TextSize=12, Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,
        }, card)

        if sub ~= "" then
            novo("TextLabel", {
                Size=UDim2.new(1,-55,0,14), Position=UDim2.new(0,0,0,28),
                BackgroundTransparency=1, Text=sub, TextColor3=COR.MUTED,
                TextSize=10, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, card)
        end

        local pill = novo("Frame", {
            Size=UDim2.new(0,40,0,22), Position=UDim2.new(1,-40,0.5,-11),
            BackgroundColor3=padrao and COR.ACENTO or Color3.fromRGB(30,33,48),
        }, card)
        arredondar(pill, 11)
        borda(pill, padrao and Color3.fromRGB(90,78,192) or COR.BORDA)

        local knob = novo("Frame", {
            Size=UDim2.new(0,16,0,16),
            Position=padrao and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3=padrao and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,75,95),
        }, pill)
        arredondar(knob, 8)

        local hit = novo("TextButton", {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5,
        }, card)

        local estado = padrao
        local function alternar()
            estado = not estado
            Hub._flags[flag] = estado
            Hub._ativosCount = Hub._ativosCount + (estado and 1 or -1)
            Hub._footerInfo.Text = Hub._ativosCount.." funções ativas"
            tween(pill, TweenInfo.new(0.2), {BackgroundColor3=estado and COR.ACENTO or Color3.fromRGB(30,33,48)}):Play()
            tween(knob, TweenInfo.new(0.2), {
                Position=estado and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                BackgroundColor3=estado and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,75,95),
            }):Play()
            if callback then callback(estado) end
        end
        hit.MouseButton1Click:Connect(alternar)
        hit.TouchTap:Connect(alternar)

        local elem = {}
        function elem.Valor() return Hub._flags[flag] end
        function elem.Definir(v)
            estado=v; Hub._flags[flag]=v
            tween(pill, TweenInfo.new(0.2), {BackgroundColor3=v and COR.ACENTO or Color3.fromRGB(30,33,48)}):Play()
            tween(knob, TweenInfo.new(0.2), {
                Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                BackgroundColor3=v and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,75,95),
            }):Play()
        end
        Hub._elementos[flag] = elem
        return elem
    end

    -- SLIDER (touch completo)
    function Aba.CriarSlider(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label    or "Slider"
        local min      = opcoes.Min      or 0
        local max      = opcoes.Max      or 100
        local padrao   = opcoes.Padrao   or min
        local sufixo   = opcoes.Sufixo   or ""
        local flag     = opcoes.Flag     or label
        local callback = opcoes.AoMudar

        Hub._flags[flag] = padrao

        local card = criarCard(70)
        novo("UIPadding", {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12), PaddingTop=UDim.new(0,8)}, card)

        local topRow = novo("Frame", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1}, card)
        novo("TextLabel", {
            Size=UDim2.new(1,-50,1,0), BackgroundTransparency=1,
            Text=label, TextColor3=COR.TEXTO, TextSize=12,
            Font=Enum.Font.GothamMedium, TextXAlignment=Enum.TextXAlignment.Left,
        }, topRow)
        local valLabel = novo("TextLabel", {
            Size=UDim2.new(0,50,1,0), Position=UDim2.new(1,-50,0,0),
            BackgroundTransparency=1, Text=tostring(padrao)..sufixo,
            TextColor3=COR.ACENTO, TextSize=12, Font=Enum.Font.GothamBold,
            TextXAlignment=Enum.TextXAlignment.Right,
        }, topRow)

        local track = novo("Frame", {
            Size=UDim2.new(1,0,0,4), Position=UDim2.new(0,0,0,26),
            BackgroundColor3=Color3.fromRGB(30,33,48),
        }, card)
        arredondar(track, 4)

        local pct  = (padrao-min)/(max-min)
        local fill = novo("Frame", {Size=UDim2.new(pct,0,1,0), BackgroundColor3=COR.ACENTO}, track)
        arredondar(fill, 4)

        local thumbBtn = novo("TextButton", {
            Size=UDim2.new(0,26,0,26),
            Position=UDim2.new(pct,0,0.5,0),
            AnchorPoint=Vector2.new(0.5,0.5),
            BackgroundColor3=COR.ACENTO, Text="", ZIndex=5,
        }, track)
        arredondar(thumbBtn, 13)
        borda(thumbBtn, Color3.fromRGB(90,78,192))

        -- Hit area larga para toque no trilho
        local trackHit = novo("TextButton", {
            Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0.5,-15),
            BackgroundTransparency=1, Text="", ZIndex=4,
        }, track)

        local rowMin = novo("Frame", {Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,0,34), BackgroundTransparency=1}, card)
        novo("TextLabel", {Size=UDim2.new(0.5,0,1,0), BackgroundTransparency=1, Text=tostring(min)..sufixo, TextColor3=COR.MUTED, TextSize=9, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left}, rowMin)
        novo("TextLabel", {Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundTransparency=1, Text=tostring(max)..sufixo, TextColor3=COR.MUTED, TextSize=9, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Right}, rowMin)

        local dragging = false

        local function updateSlider(absX)
            local p = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local v = math.round(min + p*(max-min))
            Hub._flags[flag]  = v
            fill.Size         = UDim2.new(p,0,1,0)
            thumbBtn.Position = UDim2.new(p,0,0.5,0)
            valLabel.Text     = tostring(v)..sufixo
            if callback then callback(v) end
        end

        -- Mouse
        thumbBtn.MouseButton1Down:Connect(function() dragging=true end)
        trackHit.MouseButton1Down:Connect(function()
            dragging=true
            updateSlider(UserInputService:GetMouseLocation().X)
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                updateSlider(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
        end)

        -- Touch arrastar
        thumbBtn.TouchPan:Connect(function(_, _, _, state)
            if state==Enum.UserInputState.Begin then dragging=true
            elseif state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then dragging=false end
        end)
        trackHit.TouchTap:Connect(function(positions)
            if positions and positions[1] then updateSlider(positions[1].X) end
        end)
        UserInputService.TouchMoved:Connect(function(touch, gpe)
            if dragging and not gpe then updateSlider(touch.Position.X) end
        end)
        UserInputService.TouchEnded:Connect(function() dragging=false end)

        local elem = {}
        function elem.Valor() return Hub._flags[flag] end
        function elem.Definir(v)
            v=math.clamp(v,min,max)
            local p=((v-min)/(max-min))
            Hub._flags[flag]=v
            fill.Size=UDim2.new(p,0,1,0)
            thumbBtn.Position=UDim2.new(p,0,0.5,0)
            valLabel.Text=tostring(v)..sufixo
        end
        Hub._elementos[flag] = elem
        return elem
    end

    -- DROPDOWN
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

        local card = criarCard(54)
        novo("UIPadding", {PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8)}, card)
        card.ClipsDescendants = false
        card.AutomaticSize    = Enum.AutomaticSize.Y

        local badgeTipo = novo("TextLabel", {
            Size=UDim2.new(0,55,0,14), BackgroundColor3=Color3.fromRGB(22,19,58),
            Text=multi and "MULTI" or "ÚNICO", TextColor3=COR.ACENTO,
            TextSize=8, Font=Enum.Font.GothamBold,
        }, card)
        arredondar(badgeTipo, 7)
        borda(badgeTipo, Color3.fromRGB(45,40,112))

        novo("TextLabel", {
            Size=UDim2.new(1,-65,0,14), Position=UDim2.new(0,62,0,0),
            BackgroundTransparency=1, Text=label, TextColor3=COR.TEXTO,
            TextSize=12, Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,
        }, card)

        if sub ~= "" then
            novo("TextLabel", {
                Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,16),
                BackgroundTransparency=1, Text=sub, TextColor3=COR.MUTED,
                TextSize=9, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
            }, card)
        end

        local topOffset = sub ~= "" and 32 or 20

        local head = novo("Frame", {
            Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,topOffset),
            BackgroundColor3=COR.FUNDO,
        }, card)
        arredondar(head, 7); borda(head)

        local headLbl = novo("TextLabel", {
            Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,8,0,0),
            BackgroundTransparency=1, Text="Selecione...",
            TextColor3=Color3.fromRGB(140,144,168), TextSize=11, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,
        }, head)

        local arrow = novo("TextLabel", {
            Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-22,0,0),
            BackgroundTransparency=1, Text="▾", TextColor3=COR.MUTED,
            TextSize=10, Font=Enum.Font.Gotham,
        }, head)

        local lista = novo("Frame", {
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,topOffset+32),
            BackgroundColor3=COR.FUNDO, ClipsDescendants=true, Visible=false, ZIndex=10,
        }, card)
        arredondar(lista, 7); borda(lista)
        novo("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder}, lista)

        local function atualizarLabel()
            local sels={}
            for k in pairs(selecao) do table.insert(sels,k) end
            if #sels==0 then
                headLbl.Text="Selecione..."; headLbl.TextColor3=Color3.fromRGB(140,144,168)
            elseif #sels==1 then
                headLbl.Text=sels[1]; headLbl.TextColor3=COR.TEXTO
            else
                headLbl.Text=table.concat(sels,", "); headLbl.TextColor3=COR.TEXTO
            end
        end

        local function criarItemLista(texto)
            local item = novo("TextButton", {
                Size=UDim2.new(1,0,0,32), BackgroundColor3=COR.FUNDO, Text="", ZIndex=11,
            }, lista)

            local check = novo("Frame", {
                Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,10,0.5,-7),
                BackgroundColor3=COR.FUNDO2, ZIndex=12,
            }, item)
            arredondar(check,3); borda(check)

            local checkTxt = novo("TextLabel", {
                Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="",
                TextColor3=Color3.fromRGB(255,255,255), TextSize=9,
                Font=Enum.Font.GothamBold, ZIndex=13,
            }, check)

            novo("TextLabel", {
                Name="ItemLabel", Size=UDim2.new(1,-32,1,0), Position=UDim2.new(0,30,0,0),
                BackgroundTransparency=1, Text=texto,
                TextColor3=Color3.fromRGB(200,204,228), TextSize=11, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
            }, item)

            item.MouseEnter:Connect(function() tween(item,TweenInfo.new(0.1),{BackgroundColor3=COR.CARD}):Play() end)
            item.MouseLeave:Connect(function() tween(item,TweenInfo.new(0.1),{BackgroundColor3=COR.FUNDO}):Play() end)

            local function setCheck(on)
                tween(check,TweenInfo.new(0.1),{BackgroundColor3=on and COR.ACENTO or COR.FUNDO2}):Play()
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
                    tween(lista,TweenInfo.new(0.18),{Size=UDim2.new(1,0,0,0)}):Play()
                    task.delay(0.18,function() lista.Visible=false end)
                    arrow.Text="▾"
                end
                atualizarLabel()
                if callback then
                    local sels={}
                    for k in pairs(selecao) do table.insert(sels,k) end
                    callback(multi and sels or sels[1])
                end
            end
            item.MouseButton1Click:Connect(onSelect)
            item.TouchTap:Connect(onSelect)

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
            local totalH=#itensBtns*32
            if aberto then
                lista.Visible=true; lista.Size=UDim2.new(1,0,0,0)
                tween(lista,TweenInfo.new(0.2,Enum.EasingStyle.Quart),{Size=UDim2.new(1,0,0,math.min(totalH,128))}):Play()
                arrow.Text="▴"
            else
                tween(lista,TweenInfo.new(0.18),{Size=UDim2.new(1,0,0,0)}):Play()
                task.delay(0.18,function() lista.Visible=false end)
                arrow.Text="▾"
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
            if aberto then lista.Size=UDim2.new(1,0,0,math.min(#itensBtns*32,128)) end
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

    -- TEXTO
    function Aba.CriarTexto(opcoes)
        opcoes=opcoes or {}
        local texto  = opcoes.Texto  or ""
        local titulo = opcoes.Titulo or nil
        local flag   = opcoes.Flag   or texto

        local card=criarCard(titulo and 52 or 36)
        novo("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,8)},card)
        card.AutomaticSize=Enum.AutomaticSize.Y

        if titulo then
            local badge=novo("TextLabel",{
                Size=UDim2.new(0,55,0,14), BackgroundColor3=Color3.fromRGB(22,19,58),
                Text="TEXTO", TextColor3=COR.ACENTO, TextSize=8, Font=Enum.Font.GothamBold,
            },card)
            arredondar(badge,7); borda(badge,Color3.fromRGB(45,40,112))
            novo("TextLabel",{
                Size=UDim2.new(1,-65,0,14), Position=UDim2.new(0,62,0,0),
                BackgroundTransparency=1, Text=titulo, TextColor3=COR.TEXTO,
                TextSize=11, Font=Enum.Font.GothamMedium,
                TextXAlignment=Enum.TextXAlignment.Left,
            },card)
        end

        local offset=titulo and 20 or 0
        local txtLbl=novo("TextLabel",{
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,offset),
            AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
            Text=texto, TextColor3=Color3.fromRGB(190,195,225),
            TextSize=11, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true,
        },card)

        local elem={}
        function elem.Texto() return txtLbl.Text end
        function elem.Definir(v) txtLbl.Text=tostring(v) end
        function elem.DefinirCor(r,g,b) txtLbl.TextColor3=Color3.fromRGB(r,g,b) end
        Hub._elementos[flag]=elem
        return elem
    end

    -- BOTÃO
    function Aba.CriarBotao(opcoes)
        opcoes=opcoes or {}
        local label    = opcoes.Label    or "Botão"
        local sub      = opcoes.Sub      or ""
        local callback = opcoes.AoClicar
        local tipo     = opcoes.Tipo     or "normal"

        local cores={
            normal ={bg=Color3.fromRGB(22,19,58), ht=COR.ACENTO,   brd=Color3.fromRGB(45,40,112)},
            perigo ={bg=Color3.fromRGB(40,12,12), ht=COR.VERMELHO, brd=Color3.fromRGB(80,25,25)},
            sucesso={bg=Color3.fromRGB(10,30,18), ht=COR.VERDE,    brd=Color3.fromRGB(20,60,35)},
        }
        local c=cores[tipo] or cores.normal

        local card=criarCard(42)
        novo("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)},card)
        card.BackgroundColor3=c.bg; borda(card,c.brd)

        local btn=novo("TextButton",{
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=5,
        },card)

        local mainLbl=novo("TextLabel",{
            Size=UDim2.new(1,-24,0,18),
            Position=UDim2.new(0,0,0.5,sub~="" and -12 or -9),
            BackgroundTransparency=1, Text=label, TextColor3=c.ht,
            TextSize=12, Font=Enum.Font.GothamMedium,
            TextXAlignment=Enum.TextXAlignment.Left,
        },card)

        if sub~="" then
            novo("TextLabel",{
                Size=UDim2.new(1,-24,0,12), Position=UDim2.new(0,0,0.5,2),
                BackgroundTransparency=1, Text=sub,
                TextColor3=Color3.fromRGB(120,125,150), TextSize=9, Font=Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,
            },card)
        end

        novo("TextLabel",{
            Size=UDim2.new(0,20,1,0), Position=UDim2.new(1,-22,0,0),
            BackgroundTransparency=1, Text="›", TextColor3=c.ht,
            TextSize=18, Font=Enum.Font.GothamBold,
        },card)

        local function onClick()
            tween(card,TweenInfo.new(0.08),{BackgroundColor3=Color3.fromRGB(35,33,65)}):Play()
            task.delay(0.08,function() tween(card,TweenInfo.new(0.1),{BackgroundColor3=c.bg}):Play() end)
            if callback then callback() end
        end
        btn.MouseButton1Click:Connect(onClick)
        btn.TouchTap:Connect(onClick)

        local elem={}
        function elem.DefinirLabel(v) mainLbl.Text=v end
        return elem
    end

    return Aba
end

-- ════════════════════════════════════════════════
--   ACESSO GLOBAL
-- ════════════════════════════════════════════════
function Hub.Elemento(flag) return Hub._elementos[flag] end
function Hub.Flag(flag)     return Hub._flags[flag] end

return Hub
