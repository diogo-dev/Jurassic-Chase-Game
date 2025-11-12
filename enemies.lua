local Enemies = {}
Enemies.list = {}

-- Direções possíveis (vetores normalizados)
local directions = {
    {x = 1, y = 0},   -- direita
    {x = -1, y = 0},  -- esquerda
    {x = 0, y = 1},   -- baixo
    {x = 0, y = -1}   -- cima
}

-- Configurações
local DIRECTION_CHECK_DISTANCE = 64
local DECISION_INTERVAL_RANDOM = 0.6
local DECISION_INTERVAL_CHASE = 0.5
local ENEMY_SPEED = 125
local CHASE_SPEED = 145
local currentMap = 1

local function isDirectionFree(enemy, direction, world)
    local ex, ey = enemy.collider:getPosition()
    local checkDist = DIRECTION_CHECK_DISTANCE
    
    -- Ponto final do raycast
    local endX = ex + direction.x * checkDist
    local endY = ey + direction.y * checkDist
    
    -- Verifica se há colisores na área de destino
    local colliders = world:queryCircleArea(endX, endY, 10, {'Wall', 'Walls'})
    
    return #colliders == 0
end

local function getAvailableDirections(enemy, world)
    local available = {}
    
    for i, dir in ipairs(directions) do
        if isDirectionFree(enemy, dir, world) then
            table.insert(available, {index = i, vector = dir})
        end
    end
    
    return available
end

local function pickSmartDirection(enemy, world, bounds)
    local available = getAvailableDirections(enemy, world)
    
    if #available == 0 then
        -- Se não há direções livres, para temporariamente
        enemy.dir = {x = 0, y = 0}
        enemy.stuck = true
        return
    end
    
    -- Remove a direção oposta à atual para evitar "vai e volta"
    local currentDir = enemy.dir
    local filtered = {}
    
    for _, dirInfo in ipairs(available) do
        local isOpposite = (dirInfo.vector.x == -currentDir.x and dirInfo.vector.y == -currentDir.y)
        -- Só remove a oposta se houver outras opções
        if not isOpposite or #available == 1 then
            -- Verifica bounds do mapa
            if bounds then
                local ex, ey = enemy.collider:getPosition()
                local nextX = ex + dirInfo.vector.x * 10
                local nextY = ey + dirInfo.vector.y * 10
                if nextX >= bounds.left and nextX <= bounds.right and 
                   nextY >= bounds.top and nextY <= bounds.bottom then
                    table.insert(filtered, dirInfo)
                end
            else
                table.insert(filtered, dirInfo)
            end
        end
    end
    
    -- Se filtrou tudo, usa as direções disponíveis originais
    if #filtered == 0 then
        filtered = available
    end
    
    if #filtered > 0 then
        local chosen = filtered[love.math.random(1, #filtered)]
        enemy.dirIndex = chosen.index
        enemy.dir = chosen.vector
        enemy.stuck = false
    end
end

local function getDirectionTowardsPlayer(enemy, playerPos, world)
    local ex, ey = enemy.collider:getPosition()
    local px, py = playerPos.x, playerPos.y
    
    -- Calcula diferenças
    local dx = px - ex
    local dy = py - ey
    
    -- Obtém direções disponíveis
    local available = getAvailableDirections(enemy, world)
    
    if #available == 0 then
        return {x = 0, y = 0}
    end
    
    -- Pontuação para cada direção baseada em quão perto leva do player
    local scored = {}
    for _, dirInfo in ipairs(available) do
        local dir = dirInfo.vector
        -- Produto escalar: quanto maior, mais alinhado com a direção do player
        local score = (dir.x * dx + dir.y * dy)
        table.insert(scored, {dirInfo = dirInfo, score = score})
    end
    
    -- Ordena por pontuação (maior = melhor)
    table.sort(scored, function(a, b) return a.score > b.score end)
    
    -- Sempre escolhe a melhor direção (mais próxima do player)
    local chosen = scored[1].dirInfo
    
    return chosen.vector, chosen.index
end

-- Movimentação de perseguição
local function pickChaseDirection(enemy, playerPos, world, bounds)
    if not playerPos then
        -- Se não tem player, comporta-se aleatoriamente
        pickSmartDirection(enemy, world, bounds)
        return
    end
    
    local newDir, newIndex = getDirectionTowardsPlayer(enemy, playerPos, world)
    
    if newDir and (newDir.x ~= 0 or newDir.y ~= 0) then
        enemy.dir = newDir
        if newIndex then
            enemy.dirIndex = newIndex
        end
        enemy.stuck = false
    else
        enemy.dir = {x = 0, y = 0}
        enemy.stuck = true
    end
end

function Enemies.load(world, mapNumber)
    local tileSize = 32
    local width, height = 25, 28

    currentMap = mapNumber   

    -- posições iniciais nas "pontas" do mapa (calculadas a partir do game_map)
    local mapW, mapH = 17, 18 
    if game_map then
        mapW, mapH = game_map.width, game_map.height
    end

    -- opcional: usar margem de 1 tile para evitar spawn parcialmente fora do mapa
    local margin = 1
    local leftX  = math.max(1, 1 + margin)
    local rightX = math.max(1, mapW - margin)
    local topY   = math.max(1, 1 + margin)
    local botY   = math.max(1, mapH - margin)

    local startPositions = {
        { x = leftX,  y = topY    }, -- canto superior-esquerdo
        { x = rightX, y = topY    }, -- canto superior-direito
        { x = leftX,  y = botY    }, -- canto inferior-esquerdo
        { x = rightX, y = botY    }  -- canto inferior-direito
    }

    local dinos = {}

    for i, pos in ipairs(startPositions) do
        local frameW, frameH = 32, 32
        local scale = 1

        local spawnX = (pos.x - 1) * tileSize + tileSize / 2
        local spawnY = (pos.y - 1) * tileSize + tileSize / 2
        local collider = world:newBSGRectangleCollider(spawnX, spawnY, width, height, 2)
        collider:setFixedRotation(true)
        collider:setCollisionClass('Enemy')

        local spritePath = 'sprites/dino/Dino' .. i .. '.png'
        local spriteSheet = love.graphics.newImage(spritePath)
        local grid = anim8.newGrid(frameW, frameH, spriteSheet:getWidth(), spriteSheet:getHeight())
        local moveAnim = anim8.newAnimation(grid('1-6', 1), 0.08)

        local dirIndex = math.random(#directions)

        -- definindo compotamentos padrão
        local speed = ENEMY_SPEED
        local decisionInterval = DECISION_INTERVAL_RANDOM

        -- na fase 2, dois inimigos serão bem rápidos
        if currentMap == 2 then
            if i <= 2 then
                speed = CHASE_SPEED
                decisionInterval = DECISION_INTERVAL_CHASE
            end
        else
            print("Inimigo " .. i .. " configurado como ALEATÓRIO (fase 1)")
        end

        dinos[i] = {
            collider = collider,
            x = collider:getX(),
            y = collider:getY(),
            width = width,
            height = height,
            speed = speed,
            spriteSheet = spriteSheet,
            grid = grid,
            directionSprite = moveAnim,
            timer = decisionInterval,
            decisionInterval = decisionInterval,
            dirIndex = dirIndex,
            dir = directions[dirIndex],
            frameW = frameW,
            frameH = frameH,
            scale = scale,
            stuck = false,
            stuckTimer = 0,
            world = world,
        }
    end

    Enemies.list = dinos

    -- debug: imprime conteúdo legível
    for i, d in ipairs(dinos) do
        print(string.format("Dino %d: collider=%s, pos=(%.1f,%.1f)", 
            i, tostring(d.collider), d.x, d.y))
    end
    print(#dinos, "dinos carregados")
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

function Enemies.update(dt)
    local tileSize = 32

    if not Enemies.list then return end
    if not game_map then return end -- espera game_map global estar carregado

    local mapW = game_map.width
    local mapH = game_map.height
    local mapPixelW = mapW * tileSize
    local mapPixelH = mapH * tileSize

    for _, e in ipairs(Enemies.list) do
        e.timer = e.timer - dt
        
        if e.timer <= 0 then
            local halfSpriteW = (e.frameW * e.scale) / 2
            local halfSpriteH = (e.frameH * e.scale) / 2
            local halfColliderW = e.width / 2
            local halfColliderH = e.height / 2
            local halfW = math.max(halfSpriteW, halfColliderW)
            local halfH = math.max(halfSpriteH, halfColliderH)
            local left = halfW
            local right = mapPixelW - halfW
            local top = halfH
            local bottom = mapPixelH - halfH
            
            local bounds = {left = left, right = right, top = top, bottom = bottom}
            pickSmartDirection(e, e.world, bounds)
            e.timer = e.decisionInterval
        end

        if e.stuck then
            e.stuckTimer = e.stuckTimer + dt
            if e.stuckTimer > 0.15 then
                e.stuckTimer = 0
                local halfW = e.width / 2
                local halfH = e.height / 2
                local left = halfW
                local right = mapPixelW - halfW
                local top = halfH
                local bottom = mapPixelH - halfH
                local bounds = {left = left, right = right, top = top, bottom = bottom}
                
                pickSmartDirection(e, e.world, bounds)
            end
        end

        local ex, ey = e.collider:getPosition()
        local halfSpriteW = (e.frameW * e.scale) / 2
        local halfSpriteH = (e.frameH * e.scale) / 2
        local halfColliderW = e.width / 2
        local halfColliderH = e.height / 2
        local halfW = math.max(halfSpriteW, halfColliderW)
        local halfH = math.max(halfSpriteH, halfColliderH)
        local left = halfW
        local right = mapPixelW - halfW
        local top = halfH
        local bottom = mapPixelH - halfH

        -- Prever próxima posição
        local nextX = ex + e.dir.x * e.speed * dt
        local nextY = ey + e.dir.y * e.speed * dt

        -- Verificar limites do mapa
        if nextX < left or nextX > right or nextY < top or nextY > bottom then
            e.collider:setLinearVelocity(0, 0)
            e.stuck = true
            local bounds = {left = left, right = right, top = top, bottom = bottom}
            
            pickSmartDirection(e, e.world, bounds)
            e.timer = e.decisionInterval
        else
            e.collider:setLinearVelocity(e.dir.x * e.speed, e.dir.y * e.speed)

            if e.collider:enter('Wall') then
                e.collider:setLinearVelocity(0, 0)
                e.stuck = true
                
                local curTileX = math.floor(ex / tileSize)
                local curTileY = math.floor(ey / tileSize)
                local centerX = curTileX * tileSize + tileSize / 2
                local centerY = curTileY * tileSize + tileSize / 2
                
                centerX = clamp(centerX, left, right)
                centerY = clamp(centerY, top, bottom)
                e.collider:setPosition(centerX, centerY)
                
                local bounds = {left = left, right = right, top = top, bottom = bottom}
                pickSmartDirection(e, e.world, bounds)
                e.timer = e.decisionInterval
            else
                e.x, e.y = e.collider:getPosition()
                e.stuck = false
            end
        end
        e.directionSprite:update(dt)
    end
end

function Enemies.draw()
    if not Enemies.list then return end
    for _, e in ipairs(Enemies.list) do
        local ex, ey = e.collider:getPosition()
        local drawX = ex - (e.frameW * e.scale) / 2
        local drawY = ey - (e.frameH * e.scale) / 2
        e.directionSprite:draw(e.spriteSheet, drawX, drawY, 0, e.scale, e.scale)
    end
end

function Enemies.cleanup()
    -- Limpar referências aos colisores
    for i, enemy in ipairs(Enemies.list) do
        if enemy.collider then
            enemy.collider = nil
        end
    end
    
    Enemies.list = {}
    
    print("Inimigos limpos")
end

return Enemies
