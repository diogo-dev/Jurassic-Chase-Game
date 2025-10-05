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
        current_screen = screen
    }
    clientSocket:send(json.encode(message) .. "\n")
end

function Buttons.load(clientSocket)

    font = love.graphics.setNewFont(32)

    table.insert(Buttons, new_button(
    "Começar jogo", 
    function() 
        change_screen("running", clientSocket) 
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

  -- largura dos botões
  local button_width = ww * (1/3)

  -- espaçamento entre os botões
  local margin = 16

  -- altura total dos botões + espaçamento
  local total_height =  (BUTTON_HEIGHT + margin) * #Buttons

  local cursor_y = 0

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