local json = require "libraries/dkjson"
local Player = require "player"
local Audio = require "audio"

local Collision = {}

function Collision.loadWalls(world, gameMap)
    local walls = {}
    if gameMap.layers["Walls"] then
        for i, obj in pairs(gameMap.layers["Walls"].objects) do
            if obj.polygon then
                local points = {}
                for _, point in ipairs(obj.polygon) do
                    table.insert(points, point.x)
                    table.insert(points, point.y)
                end
                local collider = world:newPolygonCollider(points)
                if collider then
                    collider:setType('static')
                    collider:setCollisionClass('Wall')
                    table.insert(walls, collider)
                else
                    print("Falha ao criar colisor para objeto", i)  
                end
            elseif obj.width and obj.height then
                local collider = world:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
                collider:setType('static')
                collider:setCollisionClass('Wall')
                table.insert(walls, collider)
            end
        end
    end
    return walls
end

function Collision.loadDiamonds(world, gameMap, layerName, collisionClass)
    local diamonds = {}
    local diamond_layer = gameMap.layers[layerName]

    local counter = 0
    if diamond_layer then
        for y = 1, diamond_layer.height do
            for x = 1, diamond_layer.width do
                local tile = diamond_layer.data[y][x]
                
                if tile and tile ~= 0 then
                    local cx = (x - 1) * gameMap.tilewidth + gameMap.tilewidth / 2
                    local cy = (y - 1) * gameMap.tileheight + gameMap.tileheight / 2
                    
                    local radius = gameMap.tilewidth / 8
                    local collider = world:newCircleCollider(cx, cy, radius)
                    collider:setType("static")
                    collider:setCollisionClass(collisionClass)
                    
                    collider.tile_x = x
                    collider.tile_y = y
                    
                    table.insert(diamonds, collider)
                    counter = counter + 1
                end
            end
        end
    end
    print("Loaded " .. counter .. " " .. layerName)
    return diamonds
end

function Collision.handleDiamondCollision(player, collisionClass, layerName, diamondList, counter, gameMap, clientSocket)
    if player.collider:enter(collisionClass) then
        Audio.playCollectDiamond()

        local collision_data = player.collider:getEnterCollisionData(collisionClass)
        local coin_collider = collision_data.collider

        -- Avisa o servidor que o diamante foi coletado
        local message = {
            action = "collect_diamond",
            collisionClass = collisionClass
        }
        clientSocket:send(json.encode(message) .. "\n")

        -- Cliente remove o diamante do mapa por meio das seguintes ações:
        -- Remove o diamante do mundo
        coin_collider:destroy() 

        -- Remove a tile usando as coordenadas armazenadas
        gameMap:setLayerTile(layerName, coin_collider.tile_x, coin_collider.tile_y, 0)

        -- Remove também da lista de diamantes
        for i, d in ipairs(diamondList) do
            if d == coin_collider then
                table.remove(diamondList, i)
                break
            end
        end

    end
end

-- lembrar de mudar quando eu inserir a nova fase do jogo
function Collision.handleEnemyPlayerCollision(player, clientSocket, world)

    if not player or not player.collider then return end

    if player.collider:enter('Enemy') then
        -- toca o efeito sonoro de colisão
        Audio.playEnemyHit()
        
        -- Avisa o servidor que houve colisão do player com um inimigo
        -- pcall envia requisições de forma segura
        local ok, err = pcall(function()
            clientSocket:send(json.encode({action="enemy_collision"}) .. "\n")
        end)
        if not ok then
            print("falha no envio:", err)
        end

        -- ativa o "travamento" e pausa por um segundo
        isCollisionFreeze = true
        collisionDelay = 1.5

        -- destrói o colisor atual para "retirar" o jogador do jogo
        if player.collider and player.collider.destroy then
            player.collider:destroy()
        end

        -- agenda o respawn depois da pausa
        player.pendingRespawn = true
        
    end

    return player
end

return Collision