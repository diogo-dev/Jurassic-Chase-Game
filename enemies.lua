-- ...existing code...
local Enemies = {}
local directions = {
    {x = 1, y = 0},   -- direita
    {x = -1, y = 0},  -- esquerda
    {x = 0, y = 1},   -- baixo
    {x = 0, y = -1}   -- cima
}

local function pixelToTile(px, py, tileSize)
    local tx = math.floor(px / tileSize) + 1
    local ty = math.floor(py / tileSize) + 1
    return tx, ty
end

local function tileToPixelCenter(tx, ty, tileSize)
    local px = (tx - 1) * tileSize + tileSize / 2
    local py = (ty - 1) * tileSize + tileSize / 2
    return px, py
end

function Enemies.load(world)
    local tileSize = 64
    local speed = 200
    local width, height = 45, 50

    local minChange, maxChange = 2.5, 5.0

    -- posições iniciais nas "pontas" do mapa (calculadas a partir do game_map)
    local mapW, mapH = 16, 12 -- valores padrão caso game_map não esteja carregado
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
        local frameW, frameH = 24, 24
        local scale = 3

        local spawnX = (pos.x - 1) * tileSize + tileSize / 2
        local spawnY = (pos.y - 1) * tileSize + tileSize / 2
        local collider = world:newBSGRectangleCollider(spawnX, spawnY, width, height, 10)
        collider:setFixedRotation(true)
        collider:setCollisionClass('Enemy')

        local spritePath = 'sprites/dino/Dino' .. i .. '.png'
        local spriteSheet = love.graphics.newImage(spritePath)
        local grid = anim8.newGrid(frameW, frameH, spriteSheet:getWidth(), spriteSheet:getHeight())
        local moveAnim = anim8.newAnimation(grid('4-10', 1), 0.08)

        local dirIndex = math.random(#directions)

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
            timer = math.random() * (maxChange - minChange) + minChange,
            minChange = minChange,
            maxChange = maxChange,
            targetTile = nil,
            dirIndex = dirIndex,
            dir = directions[dirIndex],
            frameW = frameW,
            frameH = frameH,
            scale = scale
        }
    end

    Enemies.list = dinos

    -- debug: imprime conteúdo legível
    for i, d in ipairs(dinos) do
        print("dino", i, "collider:", tostring(d.collider), "x,y:", d.x, d.y, "sprite:", tostring(d.spriteSheet))
    end
    print(#dinos, "dinos carregados")
end

local function clamp(v, a, b)
    if v < a then return a end
    if v > b then return b end
    return v
end

local function pickNewDirection(e, bounds)
    -- escolhe uma direção aleatória diferente da atual e que não imediatamente saia do mapa (se bounds fornecido)
    local tries = 0
    local newIndex = e.dirIndex
    while tries < 20 do
        newIndex = math.random(#directions)
        if newIndex ~= e.dirIndex then
            local cand = directions[newIndex]
            if bounds then
                local nextX = e.x + cand.x * 1 -- unidade pequena para teste
                local nextY = e.y + cand.y * 1
                if nextX >= bounds.left and nextX <= bounds.right and nextY >= bounds.top and nextY <= bounds.bottom then
                    break
                end
            else
                break
            end
        end
        tries = tries + 1
    end
    e.dirIndex = newIndex
    e.dir = directions[e.dirIndex]
end

function Enemies.update(dt)
    local tileSize = 64

    if not Enemies.list then return end
    if not game_map then return end -- espera game_map global estar carregado

    local mapW = game_map.width
    local mapH = game_map.height
    local mapPixelW = mapW * tileSize
    local mapPixelH = mapH * tileSize

    for _, e in ipairs(Enemies.list) do
        -- decrementa timer e troca de direção se expirar
        e.timer = e.timer - dt
        if e.timer <= 0 then
            -- calcula bounds em pixels para evitar escolher direção que saia do mapa
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

            pickNewDirection(e, {left = left, right = right, top = top, bottom = bottom})
            -- reset timer (aleatório dentro do intervalo guardado)
            e.timer = math.random() * (e.maxChange - e.minChange) + e.minChange
        end

        -- obtenha posição atual
        local ex, ey = e.collider:getPosition()

        -- calcule as metades visíveis (considera sprite escalada e colisor)
        local halfSpriteW = (e.frameW * e.scale) / 2
        local halfSpriteH = (e.frameH * e.scale) / 2
        local halfColliderW = e.width / 2
        local halfColliderH = e.height / 2
        local halfW = math.max(halfSpriteW, halfColliderW)
        local halfH = math.max(halfSpriteH, halfColliderH)

        -- bounds em pixels para o centro do colisor
        local left = halfW
        local right = mapPixelW - halfW
        local top = halfH
        local bottom = mapPixelH - halfH

        -- prever próxima posição simples
        local nextX = ex + e.dir.x * e.speed * dt
        local nextY = ey + e.dir.y * e.speed * dt

        -- se a próxima posição ultrapassar os limites em pixels, trocar de direção
        if nextX < left or nextX > right or nextY < top or nextY > bottom then
            e.collider:setLinearVelocity(0, 0)
            e.x, e.y = e.collider:getPosition()
            pickNewDirection(e, {left = left, right = right, top = top, bottom = bottom})
            -- reset timer para evitar troca imediata novamente
            e.timer = math.random() * (e.maxChange - e.minChange) + e.minChange
        else
            -- tenta mover: aplica velocidade na direção cardinal
            e.collider:setLinearVelocity(e.dir.x * e.speed, e.dir.y * e.speed)

            -- se entrou em colisão com parede ou outro inimigo, volta para o centro do tile atual e troca direção
            if e.collider:enter('Wall') or e.collider:enter('Walls') or e.collider:enter('Enemy') then
                e.collider:setLinearVelocity(0, 0)
                -- snap para centro do tile atual para evitar ficar preso
                local curTx, curTy = pixelToTile(ex, ey, tileSize)
                local cx, cy = tileToPixelCenter(curTx, curTy, tileSize)
                -- garanta que o centro stay dentro dos bounds
                cx = clamp(cx, left, right)
                cy = clamp(cy, top, bottom)
                e.collider:setPosition(cx, cy)
                e.x, e.y = cx, cy
                pickNewDirection(e, {left = left, right = right, top = top, bottom = bottom})
                -- reset timer para evitar troca imediata
                e.timer = math.random() * (e.maxChange - e.minChange) + e.minChange
            else
                -- atualizar posição cache
                e.x, e.y = e.collider:getPosition()
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

return Enemies
