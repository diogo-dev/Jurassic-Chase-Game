local Player = {}

function Player.load(world, startX, startY, lives)
    local width, height = 30, 50
    local collider = world:newBSGRectangleCollider(startX, startY, width, height, 10)
    collider:setFixedRotation(true)
    collider:setCollisionClass('Player')
    local x, y = collider:getPosition()
    local speed = 150
    local current_lives = lives
    local spriteSheet = love.graphics.newImage('sprites/player-sheet.png')
    local grid = anim8.newGrid(12, 18, spriteSheet:getWidth(), spriteSheet:getHeight())

    local animations = {
        down  = anim8.newAnimation(grid('1-4', 1), 0.2),
        left  = anim8.newAnimation(grid('1-4', 2), 0.2),
        right = anim8.newAnimation(grid('1-4', 3), 0.2),
        up    = anim8.newAnimation(grid('1-4', 4), 0.2)
    }

    local player = {
        width = width,
        height = height,
        collider = collider,
        x = x,
        y = y,
        speed = speed,
        baseSpeed = speed,
        lives = current_lives,
        spriteSheet = spriteSheet,
        grid = grid,
        animations = animations,
        directionSprite = animations.down
    }
    
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
    -- proteção: não opera sem o colisor do player
    if not player or not player.collider then return end

    local isMoving = false

    -- velocity of the collider
    local vx = 0
    local vy = 0

    if love.keyboard.isDown("right") then
        vx = player.speed
        player.directionSprite = player.animations.right
        isMoving = true
    elseif love.keyboard.isDown("left") then
        vx = player.speed * -1
        player.directionSprite = player.animations.left
        isMoving = true
    elseif love.keyboard.isDown("up") then
        vy = player.speed * -1
        player.directionSprite = player.animations.up
        isMoving = true
    elseif love.keyboard.isDown("down") then
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