local Player = {}

function Player.load(world, startX, startY)
    local player = {}
    player.width = 30
    player.height = 50
    player.collider = world:newBSGRectangleCollider(startX, startY, player.width, player.height, 10)
    player.collider:setFixedRotation(true)
    player.collider:setCollisionClass('Player')
    player.x, player.y = player.collider:getPosition()
    player.speed = 200
    player.lives = 3
    player.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

    player.animations = {}
    player.animations.down = anim8.newAnimation(player.grid('1-4', 1), 0.2)
    player.animations.left = anim8.newAnimation(player.grid('1-4', 2), 0.2)
    player.animations.right = anim8.newAnimation(player.grid('1-4', 3), 0.2)
    player.animations.up = anim8.newAnimation(player.grid('1-4', 4), 0.2)
    -- definindo a direção inicial do sprite (personagem olhando para baixo)
    player.directionSprite = player.animations.down
    
    return player
end

function Player.playerWindowLimits(player, mapWidth, mapHeight)
    local px, py = player.collider:getPosition()
    local halfWidth = player.width / 2
    local halfHeight = player.height / 2

    -- verificação horizontal
    if px - halfWidth < 0 then
        player.collider:setX(halfWidth)
    elseif px + halfWidth > mapWidth then
        player.collider:setX(mapWidth - halfWidth)
    end

    -- verificação vertical
    if py - halfHeight < 0 then
        player.collider:setY(halfHeight)
    elseif py + halfHeight > mapHeight then
        player.collider:setY(mapHeight - halfHeight)
    end
end

function Player.updateMovement(player)
    local isMoving = false

    -- velocity of the collider
    local vx = 0
    local vy = 0

    if love.keyboard.isDown("right") then
        vx = player.speed
        player.directionSprite = player.animations.right
        isMoving = true
    end

    if love.keyboard.isDown("left") then
        vx = player.speed * -1
        player.directionSprite = player.animations.left
        isMoving = true
    end

    if love.keyboard.isDown("up") then
        vy = player.speed * -1
        player.directionSprite = player.animations.up
        isMoving = true
    end

    if love.keyboard.isDown("down") then
        vy = player.speed
        player.directionSprite = player.animations.down
        isMoving = true
    end

    -- Aplicando a velocidade ao collider do jogador
    player.collider:setLinearVelocity(vx, vy)

    -- Se o jogador não estiver se movendo, definir o frame para o frame parado (frame 2)
    if (not (isMoving)) then
        player.directionSprite:gotoFrame(2)
    end
end

return Player



-- fazendo o carregamento do dinossauro 1
    -- dino1 = {}
    -- dino1.x = 200
    -- dino1.y = 200
    -- dino1.speed = 5
    -- dino1.spriteSheet = love.graphics.newImage('../sprites/dino/Dino1.png')
    -- dino1.grid = anim8.newGrid(24, 24, dino1.spriteSheet:getWidth(), dino1.spriteSheet:getHeight())

    -- dino1.animations = {}
    -- dino1.animations.move = anim8.newAnimation(dino1.grid('4-10', 1), 0.08)
    -- dino1.directionSprite = dino1.animations.move