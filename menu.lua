local json = require "libraries/dkjson"

BUTTON_HEIGHT = 64

function new_button(text, function_to_call)
  return {
    text = text,
    action = function_to_call,
    now = false,
    last = false
  } 
end

local Buttons = {}
local font = nil

local function change_screen(screen, clientSocket)
    -- informar ao servidor a mudança de tela
    local message = {
        action = "change_current_screen",
        prev_screen = "menu",
        current_screen = screen
    }
    clientSocket:send(json.encode(message) .. "\n")
end

function Buttons.load(clientSocket)
    font = love.graphics.setNewFont(23)
    title_font = love.graphics.newFont("assets/fonts/Chicago_Athletic.ttf", 70)
    backgroundImage = love.graphics.newImage("assets/background.png")

    table.insert(Buttons, new_button(
    "Começar jogo", 
    function() 
        startFade("out", function ()
          change_screen("running", clientSocket) 
          startFade("in")
        end)
    end))

    table.insert(Buttons, new_button(
    "Como Jogar", 
    function() 
        change_screen("how_to_play", clientSocket) 
    end))

    table.insert(Buttons, new_button(
    "Sair", 
    function() 
        love.event.quit()
    end))

end


function Buttons.draw()
  -- dimensões da janela
  local ww = love.graphics.getWidth()
  local wh = love.graphics.getHeight()
  
  -- desenha o fundo
  if backgroundImage then
    local x = (ww - backgroundImage:getWidth()) / 2
    local y = (wh - backgroundImage:getHeight()) / 2
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.draw(backgroundImage, x, y + 130)
  end

  -- desenha o título
  local title_text = "Jurassic Chase"
  love.graphics.setFont(title_font)
  love.graphics.setColor(0.55, 0.27, 0.07, 1)
  local title_width = title_font:getWidth(title_text)
  love.graphics.print(title_text, (ww * 0.5) - (title_width * 0.5), wh * 0.15)

  -- desenha o título
  local title_text = "Jurassic Chase"
  love.graphics.setFont(title_font)
  love.graphics.setColor(1, 0.8, 0, 1)
  local title_width = title_font:getWidth(title_text)
  love.graphics.print(title_text, (ww * 0.5) - (title_width * 0.51), wh * 0.155)


  -- largura dos botões
  local button_width = ww * (1/3)

  -- espaçamento entre os botões
  local margin = 16

  -- altura total dos botões + espaçamento
  local total_height =  (BUTTON_HEIGHT + margin) * #Buttons

  local cursor_y = 50

  -- desenhando os botões
  for i, button in ipairs(Buttons) do
    button.last = button.now

    local bx = (ww * 0.5) - (button_width * 0.5)
    local by = (wh * 0.5) - (total_height * 0.5) + cursor_y

    local color = {0, 0.4, 0.1, 0.7}

    local mx, my = love.mouse.getPosition()

    local hot = mx > bx and mx < bx + button_width and
                my > by and my < by + BUTTON_HEIGHT

    if hot then
        color = {0, 0.8, 0.2, 1}
    end

    button.now = love.mouse.isDown(1)

    if button.now and not button.last and hot then
      button.action()
    end

    love.graphics.setColor(unpack(color))
    love.graphics.rectangle(
      "fill",
      bx,
      by,
      button_width,
      BUTTON_HEIGHT
    )

    -- printando o texto do botão
    local text_width = font:getWidth(button.text)
    local text_height = font:getHeight(button.text)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.print(
      button.text,
      font,
      (ww * 0.5) - (text_width * 0.5),
      by + text_height * 0.5
    )

    cursor_y = cursor_y + (BUTTON_HEIGHT + margin)
  end

end

return Buttons