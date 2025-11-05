-- importando as bibliotecas
anim8 = require "libraries/anim8"
sti = require "libraries/sti"
wf = require "libraries/windfield"

-- importando módulos
local Player = require "player"
local Enemies = require "enemies"
local Collision = require "collision"
local Menu = require "menu"
local HowToPlay = require "how_to_play"
local GameOver = require "game_over"

-- importando bibliotecas para rede
local socket = require "socket"
local json = require "libraries/dkjson"
local udp

local isPaused = false

function love.load()
    -- configurando a janela do jogo
    local hudHeight = 50
    love.window.setMode(544, 576 + hudHeight)
    heartImage = love.graphics.newImage("assets/heart.png")
    clockImage = love.graphics.newImage("assets/clock.png")

    gameState = nil

    -- configurando a rede
    udp = socket.udp()
    udp:settimeout(0)
    udp:setpeername("127.0.0.1", 12345)

    local initialRequest = {action = "getInitialGameState"}
    udp:send(json.encode(initialRequest) .. "\n")

    -- carregando as possíveis telas do jogo
    Menu.load(udp)
    HowToPlay.load(udp)
    GameOver.load(udp)

    -- carregando o mapa
    game_map = sti('maps/fase1.lua')
    world = wf.newWorld(0, 0)
    
    -- filtro para pixel art (mudança de scala não afeta a qualidade das sprites)
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- classes de colisão
    world:addCollisionClass('Player')
    world:addCollisionClass('Enemy')
    world:addCollisionClass('Diamond', {ignores = {'Enemy'}})
    world:addCollisionClass('PinkDiamond', {ignores = {'Enemy'}})
    world:addCollisionClass('Wall')

    -- declarando uma variável do tamanho de cada bloco para o posicionamento inicial dos personagens
    tileSize = 32
    mapWidth = game_map.width * game_map.tilewidth
    mapHeight = game_map.height * game_map.tileheight

    -- Menu Options
    -- use a big font for the menu
    local font = love.graphics.setNewFont(30)

    -- obeter a altura da fonte para ajudar a calcular as posições verticais dos botões do menus
    font_height = font:getHeight()

    -- definindo a posição inicial do jogador
    local startX = tileSize * 8.2 
    local startY = tileSize * 5
    
    -- carregando o jogador principal
    player = Player.load(world, startX, startY, 3)

    -- carregando os inimigos (dinossauros)
    Enemies.load(world)

    -- Carregando colisões
    walls = Collision.loadWalls(world, game_map)
    diamonds = Collision.loadDiamonds(world, game_map, "Diamonds", "Diamond")
    pink_diamonds = Collision.loadDiamonds(world, game_map, "PinkDiamonds", "PinkDiamond")
end

function love.update(dt)
    -- Caso o jogo esteja pausado, não atualiza nada (trava o jogo)
    if isPaused then
        return
    end

    -- Recebendo dados do servidor
    local data = udp:receive()
    if data then
        local response, pos, err = json.decode(data)

        if not response then
            print("Erro ao decodificar JSON:", err or "resposta nula")
            print("Conteúdo recebido:", data)
            return -- ignora este pacote
        end

        for k, v in pairs(response) do
            print(k, v)
        end

        -- Condicionais para tratar as respostas do servidor
        if response.action == "initial_game" then
            gameState = response.gameState
        elseif response.action == "diamond_collision" then
            gameState.total_diamonds = response.diamonds
        elseif response.action == "pink_diamond_collision" then
            gameState.total_pink_diamonds = response.pink_diamonds
            -- aumentar a velocidade do jogador por 1,5 segundos
            if response.speedBoost and player then
                player.baseSpeed = player.baseSpeed or player.speed
                local mult = response.speedBoost.multiplier or 1.0
                player.speed = player.baseSpeed * mult
                player.speedBoostTimer = response.speedBoost.duration or 0
                player.speedBoostMultiplier = mult
            end
        elseif response.action == "change_current_screen" then
            if response.prev_screen == "game_over" and response.current_screen == "running" then
                gameState = response.gameState
            else
                gameState.current_screen = response.current_screen
            end
        elseif response.action == "enemy_collision" then
            gameState.lives_number = response.remaining_lives
            gameState.player_position = response.player_position
        elseif response.action == "game_over" then
            gameState.lives_number = response.remaining_lives
            gameState.current_screen = response.current_screen
        else
            print("Aguardando dados do servidor...")
        end
    end

    -- Atualizar quando o speedBoostTimer do player existir
    if player and player.speedBoostTimer then
        player.speedBoostTimer = player.speedBoostTimer - dt
        if player.speedBoostTimer <= 0 then
            player.speed = player.baseSpeed or player.speed
            player.speedBoostTimer = nil
            player.speedBoostMultiplier = nil
        end
    end

    -- Atualiza o timer do jogo
    if gameState and gameState.current_screen == "running" and not isPaused then
        if gameState.timer > 0 then
            gameState.timer = gameState.timer - dt
        else
            gameState.timer = 0
            -- O tempo acabou: jogador perde
            gameState.current_screen = "game_over"
        end
    end

    -- Atualizando o movimento do jogador 
    Player.updateMovement(player)
    -- Mantendo o jogador dentro dos limites da tela
    Player.playerWindowLimits(player, mapWidth, mapHeight)
    -- Atualizando os inimingos
    Enemies.update(dt)
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
    -- Colisão do jogador com os inimigos
    player = Collision.handleEnemyPlayerCollision(player, udp, world)
end

function love.draw()

    if gameState and gameState.current_screen == "menu" then
        Menu.draw()
    elseif gameState and gameState.current_screen == "how_to_play" then
        HowToPlay.draw()
    elseif gameState and gameState.current_screen == "game_over" then
        GameOver.draw()
    else
        drawGame(game_map, player, world, gameState)
        drawHUD(gameState, 50)
    end

    if isPaused then
        pausedGameDraw()
    end

end


function drawGame(game_map, player, world, gameState)
    -- Desenhando o mapa (now inside the testeMap.lua)
    game_map:draw()
    --drawHUD(gameState)

    -- Desenhando o jogador
    -- Parâmetros: imagem, posição x, posição y, rotação, escala x, escala y, offset x, offset y
    player.directionSprite:draw(player.spriteSheet, player.x, player.y, nil, player.scale, player.scale, player.frameW / 2, player.frameH / 2)

    -- Desenhar os inimigos
    Enemies.draw()

    -- Desenhando os colisores para melhor visualização
    --world:draw()
end

function love.keypressed(key)
    if key == "e" and gameState.current_screen == "running" then
        isPaused = not isPaused
    end

    -- Adicionar música de fundo depois
    -- if gameState.isPaused then
    --     backgroundMusic:pause()
    -- else
    --     backgroundMusic:play()
    -- end
end

function pausedGameDraw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    love.graphics.setColor(0.7, 0.4, 0.1, 1) -- marrom
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("JOGO PAUSADO", 0, love.graphics.getHeight()/2 - 40, love.graphics.getWidth(), "center")

    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Pressione E para continuar", 0, love.graphics.getHeight()/2 + 20, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 1, 1, 1)
end

function drawHUD(gameState, hudHeight)

    -- área do HUD
    love.graphics.setColor(0, 0, 0, 0.6) 
    love.graphics.rectangle("fill", 0, mapHeight, mapWidth, hudHeight)
    love.graphics.setColor(1, 1, 1)

    local margin = 20
    local y = mapHeight + 15

    -- Dimensões desejadas
    local desiredWidth = 26
    local desiredHeight = 24
    local scaleX = desiredWidth / heartImage:getWidth()
    local scaleY = desiredHeight / heartImage:getHeight()

    -- Desenha corações (vidas)
    local lifeCount = gameState.lives_number or 3
    local heartSpacing = 40
    for i = 1, lifeCount do
        love.graphics.draw(heartImage, margin + (i - 1) * heartSpacing, y, 0, scaleX, scaleY)
    end

    -- Relógio
    local desiredClockSize = 26
    local scaleClock = desiredClockSize / clockImage:getWidth()
    love.graphics.draw(clockImage, 150, y, 0, scaleClock, scaleClock)

    -- Tempo formatado
    local remainingTime = math.max(0, gameState.timer)
    local minutes = math.floor(remainingTime / 60)
    local seconds = math.floor(remainingTime % 60)
    local timeText = string.format("%02d:%02d", minutes, seconds)

    love.graphics.setFont(love.graphics.newFont(25))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(timeText, 185, y - 2)
end


