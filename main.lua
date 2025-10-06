-- importando as bibliotecas
anim8 = require "libraries/anim8"
sti = require "libraries/sti"
wf = require "libraries/windfield"

-- importando módulos
local Player = require "player"
local Collision = require "collision"
local Menu = require "menu"

-- importando bibliotecas para rede
local socket = require "socket"
local json = require "libraries/dkjson"
local udp

local menus = { 'Play', 'How To Play', 'Quit' }

function love.load()
    -- configurando a rede
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername("127.0.0.1", 12345)

    local initialRequest = {action = "getInitialGameState"}
    udp:send(json.encode(initialRequest) .. "\n")

    -- carregando o menu inicial
    Menu.load(udp)

    -- carregando o mapa
    game_map = sti('maps/testeMap.lua')
    world = wf.newWorld(0, 0)
    
    -- filtro para pixel art (mudança de scala não afeta a qualidade das sprites)
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- classes de colisão
    world:addCollisionClass('Player')
    world:addCollisionClass('Diamond')
    world:addCollisionClass('PinkDiamond')
    world:addCollisionClass('Wall')

    -- declarando uma variável do tamanho de cada bloco para o posicionamento inicial dos personagens
    tileSize = 64
    mapWidth = game_map.width * game_map.tilewidth
    mapHeight = game_map.height * game_map.tileheight

    -- Menu Options
    -- use a big font for the menu
    local font = love.graphics.setNewFont(30)

    -- get the height of the font to help calculate vertical positions of menu items
    font_height = font:getHeight()

    -- definindo a posição inicial do jogador
    local startX = tileSize * 8.2 
    local startY = tileSize * 5
    
    -- carregando o jogador principal
    player = Player.load(world, startX, startY)

    -- Carregando colisões
    walls = Collision.loadWalls(world, game_map)
    diamonds = Collision.loadDiamonds(world, game_map, "Diamonds", "Diamond")
    pink_diamonds = Collision.loadDiamonds(world, game_map, "PinkDiamonds", "PinkDiamond")

    gameState = nil
end

function love.update(dt)

    -- Recebendo dados do servidor
    local data = udp:receive()
    if data then
        local response = json.decode(data)
        for k, v in pairs(response) do
            print(k, v)
        end

        if response.action == "initial_game" then
            gameState = response.gameState
        elseif response.action == "diamond_collision" then
            gameState.total_diamonds = response.diamonds
        elseif response.action == "pink_diamond_collision" then
            gameState.total_pink_diamonds = response.pink_diamonds
        elseif response.action == "change_current_screen" then
            gameState.current_screen = response.current_screen
        else
            print("Aguardando dados do servidor...")
        end
    end

    -- Atualizando o movimento do jogador
    Player.updateMovement(player)
    -- Mantendo o jogador dentro dos limites da tela
    Player.playerWindowLimits(player, mapWidth, mapHeight)
    -- Atualizado o mundo físico do jogo
    world:update(dt)
    -- Sincronizando a posição do jogador com o seu colisor
    player.x, player.y = player.collider:getPosition()
    -- Atualizando a animação do sprite do jogador
    player.directionSprite:update(dt)   
    -- Atualizando o mapa 
    game_map:update(dt) 

    -- Colisão do jogador com os diamantes
    Collision.handleDiamondCollision(player, "Diamond", "Diamonds", diamonds, "totalDiamonds", game_map, udp)
    Collision.handleDiamondCollision(player, "PinkDiamond", "PinkDiamonds", pink_diamonds, "totalPinkDiamonds", game_map, udp)   
end

function love.draw()

    if gameState and gameState.current_screen == "menu" then
        Menu.draw()
    elseif gameState and gameState.current_screen == "how_to_play" then
        love.graphics.print("Instruções de como jogar", mapWidth * 0.5, mapHeight * 0.5)
    else
        drawGame(game_map, player, world, gameState)
    end

end


function drawGame(game_map, player, world, gameState)
    -- Desenhando o mapa (now inside the testeMap.lua)
    game_map:draw()

    -- Desenhando o jogador
    -- Parâmetros: imagem, posição x, posição y, rotação, escala x, escala y, offset x, offset y
    player.directionSprite:draw(player.spriteSheet, player.x, player.y, nil, 3.2, 3.2, 6, 9)

    -- Desenhando os colisores para melhor visualização
    --world:draw()
    
    font = love.graphics.setNewFont(20)
    if gameState then
        love.graphics.setColor(1, 1, 1, 1) 
        love.graphics.print("Diamantes: " .. gameState.total_diamonds, 10, 10)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Pink Diamantes: " .. gameState.total_pink_diamonds, 10, 30)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Números de vidas: " .. gameState.lives_number, 10, 50)
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("Aguardando estado do jogo do servidor...", 10, 10)
    end
end

