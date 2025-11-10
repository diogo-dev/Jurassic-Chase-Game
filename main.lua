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
local Winner = require "winner"

-- importando bibliotecas para rede
local socket = require "socket"
local json = require "libraries/dkjson"
local udp

-- variáveis globais do jogo
isPaused = false
isTransitioning = false
isCollisionFreeze = false
collisionDelay = 0    
isGameOver = false
tileSize = 32

fade = {
    alpha = 0,        
    direction = nil,  
    speed = 1.5,      
    onComplete = nil  
}

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
    Winner.load(udp)
end

function love.update(dt)
    updateFade(dt)

    if isPaused then return end

    if isTransitioning then return end

    -- Recebendo dados do servidor
    local data = udp:receive()
    if data then
        local response, pos, err = json.decode(data)

        if not response then
            print("Erro ao decodificar JSON:", err or "resposta nula")
            print("Conteúdo recebido:", data)
            return 
        end

        handleServerResponse(response)

        if isTransitioning then return end
    end

    if not world or not game_map or not player then
        return
    end

    -- verificar se o jogo está em estado de "congelamento" por colisão
    if updateCollisionFreeze(gameState, dt) then
        return 
    end

    -- Atualizar quando o speedBoostTimer do player
    updatePlayerSpeedBoost(player, dt)

    -- Atualizando o timer do jogo
    updateGameTimer(gameState, dt)

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

    if isTransitioning then
        return
    end

    if gameState and gameState.current_screen == "menu" then
        Menu.draw()
    elseif gameState and gameState.current_screen == "how_to_play" then
        HowToPlay.draw()
    elseif gameState and gameState.current_screen == "game_over" then
        GameOver.draw()
    elseif gameState and gameState.current_screen == "winner" then
        Winner.draw()
    else
        drawGame(game_map, player, world, gameState)
        drawHUD(gameState, 50)
    end

    if isPaused then
        pausedGameDraw()
    end

    drawFade()
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

function updatePlayerSpeedBoost(player, dt)
    if player and player.speedBoostTimer then
        player.speedBoostTimer = player.speedBoostTimer - dt
        if player.speedBoostTimer <= 0 then
            player.speed = player.baseSpeed or player.speed
            player.speedBoostTimer = nil
            player.speedBoostMultiplier = nil
        end
    end
end

function updateGameTimer(gameState, dt)
    if gameState and gameState.current_screen == "running" and not isPaused then
        if gameState.timer > 0 then
            gameState.timer = gameState.timer - dt
        else
            gameState.timer = 0
            -- O tempo acabou: jogador perde
            gameState.current_screen = "game_over"
        end
    end
end

function updateCollisionFreeze(gameState, dt)

    if isCollisionFreeze then
        collisionDelay = collisionDelay - dt
        if collisionDelay <= 0 then
            isCollisionFreeze = false
        else
            return true -- ainda em pausa, interrompe o update
        end
    end

    if not isCollisionFreeze and player and player.pendingRespawn then
        player.pendingRespawn = false

        if gameState and gameState.player_position then
            local px = gameState.player_position.x * tileSize
            local py = gameState.player_position.y * tileSize
            local current_lives = gameState.lives_number

            player = Player.load(world, px, py, current_lives)
        end
    elseif not isCollisionFreeze and isGameOver then
        isGameOver = false
        gameState.current_screen = "game_over"
    end

    return false -- não está congelado, pode continuar o update
end

function loadGame(map, posX, posY)
    -- carregando o mapa
    game_map = sti(map)
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
    mapWidth = game_map.width * game_map.tilewidth
    mapHeight = game_map.height * game_map.tileheight

    -- definindo a posição inicial do jogador
    local startX = tileSize * posX
    local startY = tileSize * posY
    
    -- carregando o jogador principal
    player = Player.load(world, startX, startY, 3)
    player.pendingRespawn = false

    -- carregando os inimigos (dinossauros)
    Enemies.load(world)

    -- Carregando colisões
    walls = Collision.loadWalls(world, game_map)
    diamonds = Collision.loadDiamonds(world, game_map, "Diamonds", "Diamond")
    pink_diamonds = Collision.loadDiamonds(world, game_map, "PinkDiamonds", "PinkDiamond")

    print("Jogo iniciado com sucesso")

    isTransitioning = false
end

function handleServerResponse(response)
    for k, v in pairs(response) do
            print(k, v)
    end

    -- Condicionais para tratar as respostas do servidor
    if response.action == "initial_game" then
        cleanup_map()
        gameState = response.gameState
        loadGame(
            gameState.maps[gameState.current_map_index],
            gameState.player_position.x,
            gameState.player_position.y
        )
    elseif response.action == "blue_diamond_collision" then
        gameState.total_blue_diamonds = response.blue_diamonds
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
    elseif response.action == "next_map" then
        startFade("out", function()
            gameState = response.gameState
            cleanup_map()
            loadGame(
                gameState.maps[gameState.current_map_index],
                gameState.player_position.x,
                gameState.player_position.y
            )
            startFade("in")
        end)
    elseif response.action == "change_current_screen" then
        gameState.current_screen = response.current_screen
        if response.prev_screen == "game_over" or response.prev_screen == "winner" then
            -- resetar flags e solicitar o gameState inicial
            isCollisionFreeze = false
            collisionDelay = 0    
            isGameOver = false

            udp:send(json.encode({ action = "getInitialGameState" }) .. "\n")
        end
    elseif response.action == "winner" then
        startFade("out", function()
            gameState.current_screen = response.current_screen
            startFade("in")
        end)
    elseif response.action == "enemy_collision" then
        gameState.lives_number = response.remaining_lives
        gameState.player_position = response.player_position
    elseif response.action == "game_over" then
        gameState.lives_number = response.remaining_lives
        isCollisionFreeze = true
        collisionDelay = 1.5
        isGameOver = true
    else
        print("Ação desconhecida ou aguardando dados do servidor...")
    end
end

function cleanup_map()
    isTransitioning  = true

    -- limpar as referencias dos colisores
    if player then
        if player.collider then
            player.collider = nil
        end
        player = nil
    end

    if Enemies and Enemies.cleanup then
        Enemies.cleanup()
    end

    if diamonds then
        diamonds = {}
    end
    
    if pink_diamonds then
        pink_diamonds = {}
    end
    
    if walls then
        walls = {}
    end
    
    if world then
        world:destroy()
        world = nil
    end
    
    if game_map then
        game_map = nil
    end

end

function updateFade(dt)
    if fade.direction == "out" then
        fade.alpha = fade.alpha + dt * fade.speed
        if fade.alpha >= 1 then
            fade.alpha = 1
            fade.direction = nil
            if fade.onComplete then
                fade.onComplete()
                fade.onComplete = nil
            end
        end
    elseif fade.direction == "in" then
        fade.alpha = fade.alpha - dt * fade.speed
        if fade.alpha <= 0 then
            fade.alpha = 0
            fade.direction = nil
        end
    end
end

function drawFade()
    if fade.alpha > 0 then
        love.graphics.setColor(0, 0, 0, fade.alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function startFade(direction, onComplete)
    fade.direction = direction
    fade.onComplete = onComplete
end
