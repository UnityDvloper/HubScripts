-- Sigma Hub v3.0 | API de loadstring | Hub completo com toggle/slider/dropdown/texto

local Hub = {}
Hub.__index = Hub

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local lp               = Players.LocalPlayer

local COR = {
    ACENTO   = Color3.fromRGB(124, 110, 245),
    FUNDO    = Color3.fromRGB(13,  15,  20),
    FUNDO2   = Color3.fromRGB(8,   10,  14),
    CARD     = Color3.fromRGB(19,  21,  30),
    BORDA    = Color3.fromRGB(30,  33,  48),
    TEXTO    = Color3.fromRGB(192, 196, 220),
    MUTED    = Color3.fromRGB(58,  61,  82),
    VERDE    = Color3.fromRGB(34,  197, 94),
    AMARELO  = Color3.fromRGB(245, 158, 11),
    VERMELHO = Color3.fromRGB(226, 75,  74),
}

Hub._flags       = {}
Hub._elementos   = {}
Hub._abas        = {}
Hub._abaAtiva    = nil
Hub._gui         = nil
Hub._ativosCount = 0
Hub._footerInfo  = nil

local notifHolder

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

local function tw(obj, t, props)
    return TweenService:Create(obj, TweenInfo.new(t), props)
end

-- FIX 1: criarNotifHolder agora retorna o holder para uso interno
local function criarNotifHolder(pai)
    local h = novo("Frame", {
        Name = "NotifHolder",
        Size = UDim2.new(0, 300, 1, -80),
        Position = UDim2.new(1, -310, 0, 10),
        BackgroundTransparency = 1,
        ZIndex = 200,
    }, pai)
    novo("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, h)
    notifHolder = h
end

function Hub.Notificar(titulo, subtitulo, tipo, tempo)
    if not notifHolder then return end
    tipo  = tipo  or "info"
    tempo = tonumber(tempo) or 4

    local cores = {
        info    = {bg=Color3.fromRGB(22,19,58),  brd=COR.ACENTO,   dot=COR.ACENTO},
        success = {bg=Color3.fromRGB(10,32,21),  brd=COR.VERDE,    dot=COR.VERDE},
        warn    = {bg=Color3.fromRGB(42,28,0),   brd=COR.AMARELO,  dot=COR.AMARELO},
        danger  = {bg=Color3.fromRGB(32,10,10),  brd=COR.VERMELHO, dot=COR.VERMELHO},
    }
    local c = cores[tipo] or cores.info

    local notif = novo("Frame", {
        Name = "Notif_"..tick(),
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = c.bg,
        ClipsDescendants = true,
        ZIndex = 200,
        Position = UDim2.new(0, 10, 0, 0),
    }, notifHolder)
    arredondar(notif, 10)
    borda(notif, c.brd)

    novo("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = c.dot,
        BorderSizePixel = 0,
        ZIndex = 201,
    }, notif)

    local iconFr = novo("Frame", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, 12, 0.5, -11),
        BackgroundColor3 = c.bg,
        ZIndex = 201,
    }, notif)
    arredondar(iconFr, 11)
    borda(iconFr, c.dot)

    local icones = {info="i", success="✓", warn="!", danger="✕"}
    novo("TextLabel", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text = icones[tipo] or "i",
        TextColor3 = c.dot,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        ZIndex = 202,
    }, iconFr)

    novo("TextLabel", {
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.new(0, 42, 0, 9),
        BackgroundTransparency = 1,
        Text = tostring(titulo or ""),
        TextColor3 = COR.TEXTO,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 201,
    }, notif)

    if subtitulo and subtitulo ~= "" then
        novo("TextLabel", {
            Size = UDim2.new(1, -80, 0, 16),
            Position = UDim2.new(0, 42, 0, 30),
            BackgroundTransparency = 1,
            Text = tostring(subtitulo),
            TextColor3 = COR.MUTED,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 201,
        }, notif)
    end

    -- FIX 2: xBtn é TextButton (não Frame), logo MouseButton1Click é válido
    local xBtn = novo("TextButton", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -26, 0.5, -10),
        BackgroundColor3 = Color3.fromRGB(30,33,48),
        Text = "X",
        TextColor3 = Color3.fromRGB(100,100,120),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        ZIndex = 202,
    }, notif)
    arredondar(xBtn, 5)

    local barBg = novo("Frame", {
        Size = UDim2.new(1,0,0,2),
        Position = UDim2.new(0,0,1,-2),
        BackgroundColor3 = Color3.fromRGB(30,33,48),
        BorderSizePixel = 0,
        ZIndex = 202,
    }, notif)
    local barFill = novo("Frame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundColor3 = c.dot,
        BorderSizePixel = 0,
        ZIndex = 203,
    }, barBg)

    notif:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.25, true)
    TweenService:Create(barFill, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {Size = UDim2.new(0,0,1,0)}):Play()

    local function fechar()
        if not notif or not notif.Parent then return end
        notif:TweenPosition(UDim2.new(0, 10, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.2, true, function()
            if notif and notif.Parent then notif:Destroy() end
        end)
    end

    xBtn.MouseButton1Click:Connect(fechar)
    task.delay(tempo, fechar)

    return notif
end

function Hub.Iniciar(config)
    config = config or {}
    local titulo  = config.Titulo  or "Sigma Hub"
    local versao  = config.Versao  or "v3.0"
    local keybind = config.Keybind or Enum.KeyCode.RightShift

    local gui = lp:FindFirstChild("PlayerGui")
    if gui and gui:FindFirstChild("SigmaHub") then
        gui.SigmaHub:Destroy()
    end

    local sg = novo("ScreenGui", {
        Name = "SigmaHub",
        ResetOnSpawn = false,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, gui)
    Hub._gui = sg

    local win = novo("Frame", {
        Name = "Janela",
        Size = UDim2.new(0, 340, 0, 460),
        Position = UDim2.new(0.5, -170, 0.5, -230),
        BackgroundColor3 = COR.FUNDO,
        Active = true,
        Draggable = true,
        ClipsDescendants = false,
    }, sg)
    arredondar(win, 12)
    borda(win)
    Hub._win = win

    -- Header
    local header = novo("Frame", {
        Size = UDim2.new(1,0,0,44),
        BackgroundColor3 = COR.FUNDO2,
        ZIndex = 2,
    }, win)
    arredondar(header, 12)
    borda(header)
    novo("Frame", {
        Size = UDim2.new(1,0,0,12),
        Position = UDim2.new(0,0,1,-12),
        BackgroundColor3 = COR.FUNDO2,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, header)

    -- Losango
    local diam = novo("Frame", {
        Size = UDim2.new(0,10,0,10),
        Position = UDim2.new(0,14,0.5,-5),
        BackgroundColor3 = COR.ACENTO,
        Rotation = 45,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, header)
    arredondar(diam, 2)

    novo("TextLabel", {
        Size = UDim2.new(1,-120,1,0),
        Position = UDim2.new(0,30,0,0),
        BackgroundTransparency = 1,
        Text = titulo .. "  " .. versao,
        TextColor3 = COR.TEXTO,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, header)

    local badge = novo("TextLabel", {
        Size = UDim2.new(0,50,0,18),
        Position = UDim2.new(1,-80,0.5,-9),
        BackgroundColor3 = Color3.fromRGB(10,32,21),
        Text = "ATIVO",
        TextColor3 = COR.VERDE,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        ZIndex = 3,
    }, header)
    arredondar(badge, 9)
    borda(badge, Color3.fromRGB(26,74,42))

    -- FIX 2: X é TextButton, nunca Frame
    local xBtnWin = novo("TextButton", {
        Size = UDim2.new(0,24,0,24),
        Position = UDim2.new(1,-32,0.5,-12),
        BackgroundColor3 = Color3.fromRGB(25,28,38),
        Text = "X",
        TextColor3 = Color3.fromRGB(100,105,125),
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        ZIndex = 3,
    }, header)
    arredondar(xBtnWin, 6)
    borda(xBtnWin)

    xBtnWin.MouseEnter:Connect(function()
        tw(xBtnWin, 0.12, {BackgroundColor3=Color3.fromRGB(60,15,15), TextColor3=COR.VERMELHO}):Play()
    end)
    xBtnWin.MouseLeave:Connect(function()
        tw(xBtnWin, 0.12, {BackgroundColor3=Color3.fromRGB(25,28,38), TextColor3=Color3.fromRGB(100,105,125)}):Play()
    end)
    xBtnWin.MouseButton1Click:Connect(function()
        win.Visible = false
        Hub.Notificar("Hub fechado", "Pressione " .. tostring(keybind) .. " para reabrir", "warn", 4)
    end)

    -- Barra de abas
    local tabBar = novo("Frame", {
        Size = UDim2.new(1,0,0,32),
        Position = UDim2.new(0,0,0,44),
        BackgroundColor3 = COR.FUNDO2,
        ZIndex = 2,
    }, win)
    borda(tabBar)
    novo("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, tabBar)

    -- Área de conteúdo
    local contentArea = novo("Frame", {
        Size = UDim2.new(1,0,1,-112),
        Position = UDim2.new(0,0,0,76),
        BackgroundTransparency = 1,
    }, win)

    -- Footer
    local footer = novo("Frame", {
        Size = UDim2.new(1,0,0,36),
        Position = UDim2.new(0,0,1,-36),
        BackgroundColor3 = COR.FUNDO2,
        ZIndex = 2,
    }, win)
    arredondar(footer, 12)
    borda(footer)
    novo("Frame", {
        Size = UDim2.new(1,0,0,12),
        BackgroundColor3 = COR.FUNDO2,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, footer)

    local footerInfo = novo("TextLabel", {
        Size = UDim2.new(1,-80,1,0),
        Position = UDim2.new(0,14,0,0),
        BackgroundTransparency = 1,
        Text = "0 funcoes ativas",
        TextColor3 = COR.MUTED,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    }, footer)
    Hub._footerInfo = footerInfo

    local footerTag = novo("TextLabel", {
        Size = UDim2.new(0,60,0,18),
        Position = UDim2.new(1,-68,0.5,-9),
        BackgroundColor3 = Color3.fromRGB(22,19,58),
        Text = "SIGMA",
        TextColor3 = COR.ACENTO,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        ZIndex = 3,
    }, footer)
    arredondar(footerTag, 9)
    borda(footerTag, Color3.fromRGB(45,40,112))

    Hub._tabBar      = tabBar
    Hub._contentArea = contentArea

    criarNotifHolder(sg)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == keybind then
            win.Visible = not win.Visible
            if win.Visible then
                Hub.Notificar("Hub reaberto", "", "info", 2)
            end
        end
    end)

    Hub.Notificar("Carregado!", titulo .. " " .. versao, "success", 4)
    return Hub
end

function Hub.NovaAba(nome)
    local tabBar      = Hub._tabBar
    local contentArea = Hub._contentArea
    local isFirst     = (#Hub._abas == 0)

    local btn = novo("TextButton", {
        Size = UDim2.new(0,85,1,0),
        BackgroundTransparency = 1,
        Text = nome,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextColor3 = isFirst and COR.ACENTO or COR.MUTED,
        ZIndex = 3,
        LayoutOrder = #Hub._abas + 1,
    }, tabBar)

    local underline = novo("Frame", {
        Size = UDim2.new(1,0,0,2),
        Position = UDim2.new(0,0,1,-2),
        BackgroundColor3 = COR.ACENTO,
        BorderSizePixel = 0,
        Visible = isFirst,
        ZIndex = 4,
    }, btn)

    local page = novo("ScrollingFrame", {
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Color3.fromRGB(45,48,72),
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = isFirst,
    }, contentArea)

    novo("UIListLayout", {
        Padding = UDim.new(0,6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    novo("UIPadding", {
        PaddingTop    = UDim.new(0,8),
        PaddingBottom = UDim.new(0,8),
        PaddingLeft   = UDim.new(0,8),
        PaddingRight  = UDim.new(0,8),
    }, page)

    local abaObj = {btn=btn, page=page, underline=underline, nome=nome}
    table.insert(Hub._abas, abaObj)
    if isFirst then Hub._abaAtiva = abaObj end

    btn.MouseButton1Click:Connect(function()
        for _, a in ipairs(Hub._abas) do
            a.page.Visible    = false
            a.underline.Visible = false
            tw(a.btn, 0.1, {TextColor3=COR.MUTED}):Play()
        end
        page.Visible      = true
        underline.Visible = true
        tw(btn, 0.1, {TextColor3=COR.ACENTO}):Play()
        Hub._abaAtiva = abaObj
    end)

    local Aba   = {}
    local ordem = 0

    local function proxOrdem()
        ordem = ordem + 1
        return ordem
    end

    local function criarCard(altura)
        local card = novo("Frame", {
            Size             = UDim2.new(1,0,0,altura or 50),
            BackgroundColor3 = COR.CARD,
            BorderSizePixel  = 0,
            LayoutOrder      = proxOrdem(),
        }, page)
        arredondar(card, 9)
        borda(card)
        return card
    end

    function Aba.SecaoLabel(texto)
        local lbl = novo("TextLabel", {
            Size               = UDim2.new(1,0,0,20),
            BackgroundTransparency = 1,
            Text               = string.upper(texto),
            TextColor3         = Color3.fromRGB(58,61,82),
            TextSize           = 9,
            Font               = Enum.Font.GothamBold,
            TextXAlignment     = Enum.TextXAlignment.Left,
            LayoutOrder        = proxOrdem(),
        }, page)
        novo("UIPadding", {PaddingLeft=UDim.new(0,4)}, lbl)
        return lbl
    end

    -- ─── TOGGLE ───────────────────────────────────────
    function Aba.CriarToggle(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label    or "Toggle"
        local sub      = opcoes.Sub      or ""
        local padrao   = opcoes.Padrao   or false
        local flag     = opcoes.Flag     or label
        local callback = opcoes.AoMudar

        Hub._flags[flag] = padrao
        if padrao then
            Hub._ativosCount += 1
            Hub._footerInfo.Text = Hub._ativosCount .. " funcoes ativas"
        end

        local card = criarCard(52)
        novo("UIPadding", {
            PaddingLeft  = UDim.new(0,12),
            PaddingRight = UDim.new(0,12),
        }, card)

        novo("TextLabel", {
            Size               = UDim2.new(1,-55,0,18),
            Position           = UDim2.new(0,0,0,9),
            BackgroundTransparency = 1,
            Text               = label,
            TextColor3         = COR.TEXTO,
            TextSize           = 12,
            Font               = Enum.Font.GothamMedium,
            TextXAlignment     = Enum.TextXAlignment.Left,
        }, card)

        if sub ~= "" then
            novo("TextLabel", {
                Size               = UDim2.new(1,-55,0,14),
                Position           = UDim2.new(0,0,0,28),
                BackgroundTransparency = 1,
                Text               = sub,
                TextColor3         = COR.MUTED,
                TextSize           = 10,
                Font               = Enum.Font.Gotham,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, card)
        end

        local pill = novo("Frame", {
            Size             = UDim2.new(0,40,0,22),
            Position         = UDim2.new(1,-40,0.5,-11),
            BackgroundColor3 = padrao and COR.ACENTO or Color3.fromRGB(30,33,48),
        }, card)
        arredondar(pill, 11)
        borda(pill, padrao and Color3.fromRGB(90,78,192) or COR.BORDA)

        local knob = novo("Frame", {
            Size             = UDim2.new(0,16,0,16),
            Position         = padrao and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3 = padrao and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,75,95),
        }, pill)
        arredondar(knob, 8)

        -- FIX 2: hit é TextButton, não Frame
        local hit = novo("TextButton", {
            Size               = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Text               = "",
            ZIndex             = 5,
        }, card)

        local estado = padrao
        hit.MouseButton1Click:Connect(function()
            estado           = not estado
            Hub._flags[flag] = estado
            Hub._ativosCount += estado and 1 or -1
            Hub._footerInfo.Text = Hub._ativosCount .. " funcoes ativas"

            tw(pill, 0.2, {BackgroundColor3 = estado and COR.ACENTO or Color3.fromRGB(30,33,48)}):Play()
            tw(knob, 0.2, {
                Position         = estado and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                BackgroundColor3 = estado and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,75,95),
            }):Play()

            if callback then callback(estado) end
        end)

        local elem = {}
        function elem.Valor() return Hub._flags[flag] end
        function elem.Definir(v)
            estado           = v
            Hub._flags[flag] = v
            tw(pill, 0.2, {BackgroundColor3 = v and COR.ACENTO or Color3.fromRGB(30,33,48)}):Play()
            tw(knob, 0.2, {
                Position         = v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                BackgroundColor3 = v and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,75,95),
            }):Play()
        end
        Hub._elementos[flag] = elem
        return elem
    end

    -- ─── SLIDER ───────────────────────────────────────
    function Aba.CriarSlider(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label    or "Slider"
        local minV     = opcoes.Min      or 0
        local maxV     = opcoes.Max      or 100
        local padrao   = math.clamp(opcoes.Padrao or minV, minV, maxV)
        local sufixo   = opcoes.Sufixo   or ""
        local flag     = opcoes.Flag     or label
        local callback = opcoes.AoMudar

        Hub._flags[flag] = padrao

        local card = criarCard(70)
        novo("UIPadding", {
            PaddingLeft  = UDim.new(0,12),
            PaddingRight = UDim.new(0,12),
            PaddingTop   = UDim.new(0,8),
        }, card)

        local topRow = novo("Frame", {
            Size               = UDim2.new(1,0,0,18),
            BackgroundTransparency = 1,
        }, card)

        novo("TextLabel", {
            Size               = UDim2.new(1,-50,1,0),
            BackgroundTransparency = 1,
            Text               = label,
            TextColor3         = COR.TEXTO,
            TextSize           = 12,
            Font               = Enum.Font.GothamMedium,
            TextXAlignment     = Enum.TextXAlignment.Left,
        }, topRow)

        local valLabel = novo("TextLabel", {
            Size               = UDim2.new(0,50,1,0),
            Position           = UDim2.new(1,-50,0,0),
            BackgroundTransparency = 1,
            Text               = tostring(padrao) .. sufixo,
            TextColor3         = COR.ACENTO,
            TextSize           = 12,
            Font               = Enum.Font.GothamBold,
            TextXAlignment     = Enum.TextXAlignment.Right,
        }, topRow)

        -- FIX 3: trackBtn é TextButton para aceitar MouseButton1Down
        local trackBtn = novo("TextButton", {
            Size             = UDim2.new(1,0,0,18),
            Position         = UDim2.new(0,0,0,24),
            BackgroundColor3 = Color3.fromRGB(30,33,48),
            Text             = "",
            AutoButtonColor  = false,
            ZIndex           = 4,
        }, card)
        arredondar(trackBtn, 4)

        local pct = (padrao - minV) / (maxV - minV)

        local fill = novo("Frame", {
            Size             = UDim2.new(pct,0,1,0),
            BackgroundColor3 = COR.ACENTO,
            BorderSizePixel  = 0,
        }, trackBtn)
        arredondar(fill, 4)

        -- Thumb como Frame (filho do trackBtn, não precisa ser clicável sozinho)
        local thumb = novo("Frame", {
            Size             = UDim2.new(0,18,0,18),
            Position         = UDim2.new(pct,0,0.5,0),
            AnchorPoint      = Vector2.new(0.5,0.5),
            BackgroundColor3 = COR.ACENTO,
            BorderSizePixel  = 0,
            ZIndex           = 5,
        }, trackBtn)
        arredondar(thumb, 9)
        borda(thumb, Color3.fromRGB(90,78,192))

        local rowLabels = novo("Frame", {
            Size               = UDim2.new(1,0,0,14),
            Position           = UDim2.new(0,0,0,46),
            BackgroundTransparency = 1,
        }, card)
        novo("TextLabel", {
            Size               = UDim2.new(0.5,0,1,0),
            BackgroundTransparency = 1,
            Text               = tostring(minV) .. sufixo,
            TextColor3         = COR.MUTED,
            TextSize           = 9,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
        }, rowLabels)
        novo("TextLabel", {
            Size               = UDim2.new(0.5,0,1,0),
            Position           = UDim2.new(0.5,0,0,0),
            BackgroundTransparency = 1,
            Text               = tostring(maxV) .. sufixo,
            TextColor3         = COR.MUTED,
            TextSize           = 9,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Right,
        }, rowLabels)

        local dragging = false

        local function updateSlider(absX)
            local p = math.clamp((absX - trackBtn.AbsolutePosition.X) / trackBtn.AbsoluteSize.X, 0, 1)
            local v = math.round(minV + p * (maxV - minV))
            Hub._flags[flag]  = v
            fill.Size         = UDim2.new(p, 0, 1, 0)
            thumb.Position    = UDim2.new(p, 0, 0.5, 0)
            valLabel.Text     = tostring(v) .. sufixo
            if callback then callback(v) end
        end

        -- FIX 3: MouseButton1Down no TextButton funciona corretamente
        trackBtn.MouseButton1Down:Connect(function()
            dragging = true
            updateSlider(UserInputService:GetMouseLocation().X)
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        -- Suporte touch
        trackBtn.TouchPan:Connect(function(_, totalTranslation, _, state)
            if state == Enum.UserInputState.Change or state == Enum.UserInputState.Begin then
                updateSlider(trackBtn.AbsolutePosition.X + totalTranslation.X + trackBtn.AbsoluteSize.X * ((padrao - minV)/(maxV - minV)))
            end
        end)

        local elem = {}
        function elem.Valor() return Hub._flags[flag] end
        function elem.Definir(v)
            v = math.clamp(v, minV, maxV)
            local p = (v - minV) / (maxV - minV)
            Hub._flags[flag] = v
            fill.Size        = UDim2.new(p, 0, 1, 0)
            thumb.Position   = UDim2.new(p, 0, 0.5, 0)
            valLabel.Text    = tostring(v) .. sufixo
        end
        Hub._elementos[flag] = elem
        return elem
    end

    -- ─── DROPDOWN ─────────────────────────────────────
    function Aba.CriarDropdown(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label    or "Dropdown"
        local sub      = opcoes.Sub      or ""
        local itens    = opcoes.Itens    or {}
        local multi    = opcoes.Multi    or false
        local flag     = opcoes.Flag     or label
        local callback = opcoes.AoMudar

        local selecao  = {}
        Hub._flags[flag] = selecao

        local aberto    = false
        local itensBtns = {}

        local card = criarCard(sub ~= "" and 82 or 68)
        novo("UIPadding", {
            PaddingLeft   = UDim.new(0,10),
            PaddingRight  = UDim.new(0,10),
            PaddingTop    = UDim.new(0,8),
            PaddingBottom = UDim.new(0,8),
        }, card)
        card.ClipsDescendants = false
        card.AutomaticSize    = Enum.AutomaticSize.Y

        local badgeTipo = novo("TextLabel", {
            Size             = UDim2.new(0,52,0,14),
            BackgroundColor3 = Color3.fromRGB(22,19,58),
            Text             = multi and "MULTI" or "UNICO",
            TextColor3       = COR.ACENTO,
            TextSize         = 8,
            Font             = Enum.Font.GothamBold,
        }, card)
        arredondar(badgeTipo, 7)
        borda(badgeTipo, Color3.fromRGB(45,40,112))

        novo("TextLabel", {
            Size               = UDim2.new(1,-62,0,14),
            Position           = UDim2.new(0,60,0,0),
            BackgroundTransparency = 1,
            Text               = label,
            TextColor3         = COR.TEXTO,
            TextSize           = 12,
            Font               = Enum.Font.GothamMedium,
            TextXAlignment     = Enum.TextXAlignment.Left,
        }, card)

        if sub ~= "" then
            novo("TextLabel", {
                Size               = UDim2.new(1,0,0,12),
                Position           = UDim2.new(0,0,0,16),
                BackgroundTransparency = 1,
                Text               = sub,
                TextColor3         = COR.MUTED,
                TextSize           = 9,
                Font               = Enum.Font.Gotham,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, card)
        end

        local topOff = sub ~= "" and 32 or 20

        local head = novo("Frame", {
            Size             = UDim2.new(1,0,0,28),
            Position         = UDim2.new(0,0,0,topOff),
            BackgroundColor3 = COR.FUNDO,
        }, card)
        arredondar(head, 7)
        borda(head)

        local headLbl = novo("TextLabel", {
            Size               = UDim2.new(1,-28,1,0),
            Position           = UDim2.new(0,8,0,0),
            BackgroundTransparency = 1,
            Text               = "Selecione...",
            TextColor3         = Color3.fromRGB(100,104,128),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
        }, head)

        local arrow = novo("TextLabel", {
            Size               = UDim2.new(0,20,1,0),
            Position           = UDim2.new(1,-22,0,0),
            BackgroundTransparency = 1,
            Text               = "v",
            TextColor3         = COR.MUTED,
            TextSize           = 10,
            Font               = Enum.Font.Gotham,
        }, head)

        local lista = novo("Frame", {
            Size             = UDim2.new(1,0,0,0),
            Position         = UDim2.new(0,0,0,topOff+32),
            BackgroundColor3 = COR.FUNDO,
            ClipsDescendants = true,
            Visible          = false,
            ZIndex           = 10,
        }, card)
        arredondar(lista, 7)
        borda(lista)
        novo("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder}, lista)

        local function atualizarLabel()
            local sels = {}
            for k in pairs(selecao) do table.insert(sels, k) end
            if #sels == 0 then
                headLbl.Text      = "Selecione..."
                headLbl.TextColor3 = Color3.fromRGB(100,104,128)
            else
                headLbl.Text      = table.concat(sels, ", ")
                headLbl.TextColor3 = COR.TEXTO
            end
        end

        local function criarItemLista(texto)
            -- FIX 2: cada item é TextButton
            local item = novo("TextButton", {
                Size             = UDim2.new(1,0,0,30),
                BackgroundColor3 = COR.FUNDO,
                Text             = "",
                ZIndex           = 11,
                AutoButtonColor  = false,
            }, lista)

            local check = novo("Frame", {
                Size             = UDim2.new(0,14,0,14),
                Position         = UDim2.new(0,10,0.5,-7),
                BackgroundColor3 = COR.FUNDO2,
                ZIndex           = 12,
            }, item)
            arredondar(check, 3)
            borda(check)

            local checkTxt = novo("TextLabel", {
                Size               = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text               = "",
                TextColor3         = Color3.fromRGB(255,255,255),
                TextSize           = 9,
                Font               = Enum.Font.GothamBold,
                ZIndex             = 13,
            }, check)

            novo("TextLabel", {
                Size               = UDim2.new(1,-32,1,0),
                Position           = UDim2.new(0,30,0,0),
                BackgroundTransparency = 1,
                Text               = texto,
                TextColor3         = Color3.fromRGB(180,184,210),
                TextSize           = 11,
                Font               = Enum.Font.Gotham,
                TextXAlignment     = Enum.TextXAlignment.Left,
                ZIndex             = 12,
            }, item)

            item.MouseEnter:Connect(function()
                tw(item, 0.1, {BackgroundColor3=COR.CARD}):Play()
            end)
            item.MouseLeave:Connect(function()
                tw(item, 0.1, {BackgroundColor3=COR.FUNDO}):Play()
            end)

            local function setCheck(on)
                if on then
                    tw(check, 0.1, {BackgroundColor3=COR.ACENTO}):Play()
                    checkTxt.Text = "+"
                else
                    tw(check, 0.1, {BackgroundColor3=COR.FUNDO2}):Play()
                    checkTxt.Text = ""
                end
            end

            item.MouseButton1Click:Connect(function()
                if multi then
                    if selecao[texto] then
                        selecao[texto] = nil
                        setCheck(false)
                    else
                        selecao[texto] = true
                        setCheck(true)
                    end
                else
                    for k in pairs(selecao) do selecao[k] = nil end
                    for _, ib in ipairs(itensBtns) do ib.setCheck(false) end
                    selecao[texto] = true
                    setCheck(true)
                    aberto = false
                    tw(lista, 0.18, {Size=UDim2.new(1,0,0,0)}):Play()
                    task.delay(0.18, function() if lista and lista.Parent then lista.Visible = false end end)
                    arrow.Text = "v"
                end
                atualizarLabel()
                if callback then
                    local sels = {}
                    for k in pairs(selecao) do table.insert(sels, k) end
                    callback(multi and sels or sels[1])
                end
            end)

            local entry = {setCheck=setCheck, texto=texto}
            table.insert(itensBtns, entry)
            return entry
        end

        for _, it in ipairs(itens) do criarItemLista(it) end

        -- FIX 2: headBtn é TextButton
        local headBtn = novo("TextButton", {
            Size               = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Text               = "",
            ZIndex             = 12,
            AutoButtonColor    = false,
        }, head)

        headBtn.MouseButton1Click:Connect(function()
            aberto = not aberto
            local totalH = #itensBtns * 30
            if aberto then
                lista.Visible = true
                lista.Size    = UDim2.new(1,0,0,0)
                TweenService:Create(lista, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                    Size = UDim2.new(1,0,0,math.min(totalH, 120))
                }):Play()
                arrow.Text = "^"
            else
                TweenService:Create(lista, TweenInfo.new(0.18), {Size=UDim2.new(1,0,0,0)}):Play()
                task.delay(0.18, function() if lista and lista.Parent then lista.Visible = false end end)
                arrow.Text = "v"
            end
        end)

        local elem = {}
        function elem.Selecionar(v)
            if type(v) == "table" then
                for _, k in ipairs(v) do selecao[k] = true end
            else
                selecao[v] = true
            end
            atualizarLabel()
        end
        function elem.AdicionarOpcao(v)
            criarItemLista(v)
        end
        function elem.RemoverOpcao(v)
            for i, ib in ipairs(itensBtns) do
                if ib.texto == v then
                    ib.setCheck(false)
                    -- encontra o frame e destrói
                    for _, child in ipairs(lista:GetChildren()) do
                        if child:IsA("TextButton") then
                            local lbl = child:FindFirstChildWhichIsA("TextLabel")
                            if lbl and lbl.Text == v then
                                child:Destroy()
                                break
                            end
                        end
                    end
                    selecao[v] = nil
                    table.remove(itensBtns, i)
                    atualizarLabel()
                    break
                end
            end
        end
        function elem.Valor()
            local sels = {}
            for k in pairs(selecao) do table.insert(sels, k) end
            return multi and sels or sels[1]
        end
        Hub._elementos[flag] = elem
        return elem
    end

    -- ─── TEXTO ────────────────────────────────────────
    function Aba.CriarTexto(opcoes)
        opcoes = opcoes or {}
        local texto    = opcoes.Texto  or ""
        local titulo   = opcoes.Titulo or nil
        local flag     = opcoes.Flag   or texto

        local card = criarCard(40)
        novo("UIPadding", {
            PaddingLeft  = UDim.new(0,12),
            PaddingRight = UDim.new(0,12),
            PaddingTop   = UDim.new(0,8),
        }, card)
        card.AutomaticSize = Enum.AutomaticSize.Y

        if titulo then
            local badge = novo("TextLabel", {
                Size             = UDim2.new(0,52,0,14),
                BackgroundColor3 = Color3.fromRGB(22,19,58),
                Text             = "TEXTO",
                TextColor3       = COR.ACENTO,
                TextSize         = 8,
                Font             = Enum.Font.GothamBold,
            }, card)
            arredondar(badge, 7)
            borda(badge, Color3.fromRGB(45,40,112))

            novo("TextLabel", {
                Size               = UDim2.new(1,-62,0,14),
                Position           = UDim2.new(0,60,0,0),
                BackgroundTransparency = 1,
                Text               = titulo,
                TextColor3         = COR.TEXTO,
                TextSize           = 11,
                Font               = Enum.Font.GothamMedium,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, card)
        end

        local offset = titulo and 20 or 0
        local txtLbl = novo("TextLabel", {
            Size               = UDim2.new(1,0,0,0),
            Position           = UDim2.new(0,0,0,offset),
            AutomaticSize      = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text               = texto,
            TextColor3         = Color3.fromRGB(160,165,200),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextWrapped        = true,
        }, card)

        local elem = {}
        function elem.Texto()    return txtLbl.Text end
        function elem.Definir(v) txtLbl.Text = tostring(v) end
        function elem.DefinirCor(r,g,b) txtLbl.TextColor3 = Color3.fromRGB(r,g,b) end
        Hub._elementos[flag] = elem
        return elem
    end

    -- ─── BOTÃO ────────────────────────────────────────
    function Aba.CriarBotao(opcoes)
        opcoes = opcoes or {}
        local label    = opcoes.Label    or "Botao"
        local sub      = opcoes.Sub      or ""
        local callback = opcoes.AoClicar
        local tipo     = opcoes.Tipo     or "normal"

        local paleta = {
            normal  = {bg=Color3.fromRGB(22,19,58),  ht=COR.ACENTO,   brd=Color3.fromRGB(45,40,112)},
            perigo  = {bg=Color3.fromRGB(40,12,12),  ht=COR.VERMELHO, brd=Color3.fromRGB(80,25,25)},
            sucesso = {bg=Color3.fromRGB(10,30,18),  ht=COR.VERDE,    brd=Color3.fromRGB(20,60,35)},
        }
        local c = paleta[tipo] or paleta.normal

        local card = criarCard(42)
        novo("UIPadding", {
            PaddingLeft  = UDim.new(0,12),
            PaddingRight = UDim.new(0,12),
        }, card)
        card.BackgroundColor3 = c.bg
        borda(card, c.brd)

        -- FIX 2: btn é TextButton, MouseButton1Click válido
        local btn = novo("TextButton", {
            Size               = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            Text               = "",
            ZIndex             = 5,
            AutoButtonColor    = false,
        }, card)

        novo("TextLabel", {
            Size               = UDim2.new(1,-22,0,18),
            Position           = UDim2.new(0,0,0.5, sub~="" and -12 or -9),
            BackgroundTransparency = 1,
            Text               = label,
            TextColor3         = c.ht,
            TextSize           = 12,
            Font               = Enum.Font.GothamMedium,
            TextXAlignment     = Enum.TextXAlignment.Left,
        }, card)

        if sub ~= "" then
            novo("TextLabel", {
                Size               = UDim2.new(1,-22,0,12),
                Position           = UDim2.new(0,0,0.5,2),
                BackgroundTransparency = 1,
                Text               = sub,
                TextColor3         = Color3.fromRGB(80,85,110),
                TextSize           = 9,
                Font               = Enum.Font.Gotham,
                TextXAlignment     = Enum.TextXAlignment.Left,
            }, card)
        end

        novo("TextLabel", {
            Size               = UDim2.new(0,20,1,0),
            Position           = UDim2.new(1,-22,0,0),
            BackgroundTransparency = 1,
            Text               = ">",
            TextColor3         = c.ht,
            TextSize           = 18,
            Font               = Enum.Font.GothamBold,
        }, card)

        btn.MouseButton1Click:Connect(function()
            tw(card, 0.08, {BackgroundColor3=Color3.fromRGB(35,33,65)}):Play()
            task.delay(0.08, function()
                if card and card.Parent then
                    tw(card, 0.1, {BackgroundColor3=c.bg}):Play()
                end
            end)
            if callback then callback() end
        end)

        local elem = {}
        function elem.DefinirLabel(v)
            for _, child in ipairs(card:GetChildren()) do
                if child:IsA("TextLabel") then child.Text = v; break end
            end
        end
        return elem
    end

    return Aba
end

-- Acesso global
function Hub.Elemento(flag) return Hub._elementos[flag] end
function Hub.Flag(flag)     return Hub._flags[flag] end

-- FIX 1: em vez de "return Hub" (que loadstring() ignora),
-- armazena no _G para que o caller possa recuperar
getgenv().SigmaHub = Hub
