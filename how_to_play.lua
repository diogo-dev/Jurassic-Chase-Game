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
    HowToPlay.backgroundImage = love.graphics.newImage("assets/instructions.png")

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

    -- desenha o fundo
  if HowToPlay.backgroundImage then
    love.graphics.setColor(1, 1, 1, 1)
    local iw, ih = HowToPlay.backgroundImage:getDimensions()
    local x = (ww - iw) / 2
    local y = (wh - ih) / 2
    love.graphics.draw(HowToPlay.backgroundImage, x, y)
  end

    -- botão voltar
    love.graphics.setFont(HowToPlay.fontText)
    local button = HowToPlay.button_back
    local buttonText = button.text
    local buttonW = HowToPlay.fontText:getWidth(buttonText)
    local buttonH = HowToPlay.fontText:getHeight()
    local bx = (ww - buttonW) * 0.5
    local by = wh - 80

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
        love.graphics.setColor(0.2, 0.3, 0.2, 1)
    else
        love.graphics.setColor(0.2, 0.5, 0.2, 1)
    end

    love.graphics.rectangle("fill", bx - 20, by - 10, buttonW + 40, buttonH + 20, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(buttonText, bx, by)
end

return HowToPlay

