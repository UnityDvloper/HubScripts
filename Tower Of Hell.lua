local Hub = loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USER/sigma-hub/main/hub.lua"))()

-- Inicia o hub
Hub.Iniciar({
    Titulo  = "Meu Hub",
    Versao  = "v1.0",
    Keybind = Enum.KeyCode.RightShift,
})

-- ── ABA PROTEÇÃO ──
local TabProtecao = Hub.NovaAba("Proteção")

TabProtecao.SecaoLabel("Personagem")

local toggleMorte = TabProtecao.CriarToggle({
    Label  = "Anti-death",
    Sub    = "Bloqueia vida zerada",
    Padrao = true,
    Flag   = "anti-death",
    AoMudar = function(v)
        Hub.Notificar("Anti-death "..(v and "ativado" or "desativado"), "", v and "success" or "warn", 3)
    end,
})

TabProtecao.CriarToggle({
    Label  = "Anti-kick",
    Sub    = "Intercepta expulsões",
    Padrao = true,
    Flag   = "anti-kick",
})

TabProtecao.SecaoLabel("Configurações")

local sliderTempo = TabProtecao.CriarSlider({
    Label  = "Tempo da notificação",
    Min    = 1,
    Max    = 10,
    Padrao = 4,
    Sufixo = "s",
    Flag   = "notif-tempo",
    AoMudar = function(v) print("Novo tempo:", v) end,
})

TabProtecao.CriarTexto({
    Titulo = "Status",
    Texto  = "Anti-death e Anti-kick ativos por padrão",
    Flag   = "txt-status",
})

-- Alterar texto dinamicamente:
Hub.Elemento("txt-status").Definir("Proteção máxima ativada!")

-- ── ABA PLAYER ──
local TabPlayer = Hub.NovaAba("Player")

TabPlayer.SecaoLabel("Movimento")

local toggleSpeed = TabPlayer.CriarToggle({
    Label  = "Speed hack",
    Sub    = "Velocidade extra",
    Flag   = "speed",
})

TabPlayer.CriarSlider({
    Label  = "WalkSpeed",
    Min    = 16,
    Max    = 200,
    Padrao = 32,
    Flag   = "walk-speed",
    AoMudar = function(v)
        if Hub.Flag("speed") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end,
})

TabPlayer.SecaoLabel("Teleporte")

local ddTeleporte = TabPlayer.CriarDropdown({
    Label = "Destino",
    Sub   = "Selecione onde teleportar",
    Itens = {"Spawn", "Centro", "Base inimiga"},
    Multi = false,
    Flag  = "tp-destino",
    AoMudar = function(v)
        Hub.Notificar("Destino selecionado", v, "info", 2)
    end,
})

-- Adicionar opção dinamicamente:
ddTeleporte.AdicionarOpcao("Torre norte")
-- Remover opção:
ddTeleporte.RemoverOpcao("Centro")

-- ── ABA VISUAL ──
local TabVisual = Hub.NovaAba("Visual")

TabVisual.CriarToggle({Label="ESP jogadores", Flag="esp"})
TabVisual.CriarToggle({Label="Fullbright", Flag="fullbright"})

local ddEspCores = TabVisual.CriarDropdown({
    Label = "Cores do ESP",
    Itens = {"Vermelho", "Verde", "Azul", "Roxo"},
    Multi = true,
    Flag  = "esp-cores",
})

TabVisual.CriarSlider({
    Label  = "Tamanho do ESP",
    Min    = 10,
    Max    = 100,
    Padrao = 50,
    Flag   = "esp-size",
})

-- ── ABA MISC ──
local TabMisc = Hub.NovaAba("Misc")

TabMisc.CriarToggle({Label="Auto rejoin", Flag="auto-rejoin"})

TabMisc.CriarBotao({
    Label = "Desativar tudo",
    Sub   = "Reseta todas as funções",
    Tipo  = "perigo",
    AoClicar = function()
        Hub.Notificar("Todas as funções desativadas", "", "danger", 3)
    end,
})

TabMisc.CriarBotao({
    Label = "Restaurar vida",
    Tipo  = "sucesso",
    AoClicar = function()
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
        Hub.Notificar("Vida restaurada!", "HP = "..tostring(hum and hum.MaxHealth or 0), "success", 3)
    end,
})

TabMisc.CriarTexto({
    Titulo = "Sobre",
    Texto  = "Sigma Hub v3.0 • Suporte: toggle, slider, dropdown, texto",
    Flag   = "txt-sobre",
})
