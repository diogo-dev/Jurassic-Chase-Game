local json = require "libraries/dkjson"
local HowToPlay = {}

local function change_screen(screen, clientSocket)
    local message = {
        action = "change_current_screen",
        current_screen = screen
    }
    clientSocket:send(json.encode(message) .. "\n")
end

function HowToPlay.load(clientSocket)
    --HowToPlay.backgroundImage = love.graphics.newImage("assets/background.jpg")

    HowToPlay.fontTitle = love.graphics.newFont("assets/fonts/Chicago_Athletic.ttf", 90)
    HowToPlay.fontText = love.graphics.newFont(20)
    HowToPlay.clientSocket = clientSocket

    HowToPlay.button_back= {
        text = "Voltar ao Menu",
        last = false,
        now = false,
    }
end

function HowToPlay.draw()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()

    -- fundo da tela
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, ww, wh)

    -- desenha o título
    local title_text = "Como Jogar"
    love.graphics.setFont(HowToPlay.fontTitle)
    love.graphics.setColor(0.55, 0.27, 0.07, 1)
    local title_width = HowToPlay.fontTitle:getWidth(title_text)
    love.graphics.print(title_text, (ww * 0.5) - (title_width * 0.5), wh * 0.15)

    local title_text = "Como Jogar"
    love.graphics.setFont(HowToPlay.fontTitle)
    love.graphics.setColor(1, 0.8, 0, 1)
    local title_width = HowToPlay.fontTitle:getWidth(title_text)
    love.graphics.print(title_text, (ww * 0.5) - (title_width * 0.51), wh * 0.155)

    -- instruções
    love.graphics.setFont(HowToPlay.fontText)
    love.graphics.setColor(1, 1, 1, 1)

    -- substituir depois por imagem
    local instructions = {
        "-> Use as setas para mover o personagem.",
        "-> Colete todos os diamantes azuis e rosas pelo mapa.",
        "-> Evite colidir com árvores e obstáculos.",
        "-> Você começa com 3 vidas.",
        "-> Você tem um total de 3 minutos para completar cada fase.",
        "-> Fique longe dos dinossauros — eles vão te perseguir!"
    }

    local goals = {
        "1) Coletar todos os diamantes azuis e rosas",
        "2) Completar as duas fases antes do tempo acabar"
    }

    local y = 260
    for _, line in ipairs(instructions) do
        love.graphics.print(line, 240, y)
        y = y + 35
    end

    y = y + 50
    for _, line in ipairs(goals) do
        love.graphics.print(line, 240, y)
        y = y + 35
    end

    -- botão voltar
    local button = HowToPlay.button_back
    local buttonText = button.text
    local buttonW = HowToPlay.fontText:getWidth(buttonText)
    local buttonH = HowToPlay.fontText:getHeight()
    local bx = (ww - buttonW) * 0.5
    local by = wh - 120

    -- detectar mouse
    local mx, my = love.mouse.getPosition()
    local hot = mx > bx - 20 and mx < bx + buttonW + 20 and
                my > by - 10 and my < by + buttonH + 20
    
    -- atualizar estado do clique
    button.last = button.now
    button.now = love.mouse.isDown(1)

    if button.now and not button.last and hot then
        change_screen("menu", HowToPlay.clientSocket)
    end

    if hot then
        love.graphics.setColor(0.2, 0.8, 0.2, 1)
    else
        love.graphics.setColor(0.2, 0.5, 0.2, 1)
    end

    love.graphics.rectangle("fill", bx - 20, by - 10, buttonW + 40, buttonH + 20, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(buttonText, bx, by)
end

return HowToPlay

