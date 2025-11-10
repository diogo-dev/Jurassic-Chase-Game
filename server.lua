local socket = require("socket")
local json = require("libraries/dkjson")

udp = socket.udp()
udp:setsockname('*', 12345)
udp:settimeout(0)

print("Servidor da biblioteca rodando na porta 12345...")

-- Configuração inicial do estado do jogo
local gameState = nil

local mapConfig = {
    fase1 = {
        blue = 168,
        pink = 8,
        posX = 8.2,
        posY = 5
    },
    fase2 = {
        blue = 174,
        pink = 11,
        posX = 8.3,
        posY = 8.3
    }
}

local function load_game_state()
    return {
        current_screen = "menu",
        load_next_map = false,
        total_blue_diamonds = mapConfig.fase1.blue,
        total_pink_diamonds = mapConfig.fase1.pink,
        lives_number = 3,
        player_position = { 
            x = mapConfig.fase1.posX, 
            y = mapConfig.fase1.posY 
        },
        is_paused = false,
        player_speed = 120,
        timer = 180,
        maps = {"maps/fase1.lua", "maps/fase2.lua"},
        current_map_index = 1
    }
end

local function update_game_state(params)
    for key, value in pairs(params) do
        if gameState[key] ~= nil then
            gameState[key] = value
        else
            print("Aviso: '" .. key .. "' não é um atributo válido no gameState")
        end
    end 
end

local function diamondCollision(class)
    local response = {}

    if class == "Diamond" then
        gameState.total_blue_diamonds = gameState.total_blue_diamonds - 1
        response = { 
            action = "blue_diamond_collision", 
            blue_diamonds =  gameState.total_blue_diamonds, 
        }
    elseif class == "PinkDiamond" then
        gameState.total_pink_diamonds = gameState.total_pink_diamonds - 1
        local speedBoost = { multiplier = 1.8, duration = 0.8 }
        response = { 
            action = "pink_diamond_collision", 
            pink_diamonds =  gameState.total_pink_diamonds, 
            speedBoost = speedBoost,
        }
    end

    if gameState.total_blue_diamonds + gameState.total_pink_diamonds <= 0 then
        if gameState.current_map_index == 1 then
            update_game_state({
                load_next_map = true,
                total_blue_diamonds = mapConfig.fase2.blue,
                total_pink_diamonds = mapConfig.fase2.pink,
                timer = 180,
                current_map_index = gameState.current_map_index + 1,
                player_position = {
                    x = mapConfig.fase2.posX,
                    y = mapConfig.fase2.posY
                }
            })
            response = { action = "next_map", gameState = gameState }
        else
            response = { action = "winner", current_screen = "winner"}
        end
        
    else
        gameState.load_next_map = false
    end

    return response
end

local function dinoCollision()
    if gameState.lives_number == 1 then
        gameState.lives_number = gameState.lives_number - 1
        response = { 
            action = "game_over", 
            remaining_lives = gameState.lives_number, 
            current_screen = "game_over" 
        }
    else
        gameState.lives_number = gameState.lives_number - 1

        local posX, posY
        if gameState.current_map_index == 1 then
            posX = mapConfig.fase1.posX
            posY = mapConfig.fase1.posY
        else
            posX = mapConfig.fase2.posX
            posY = mapConfig.fase2.posY
        end

        local player_position = { x = posX, y = posY }
        response = { 
            action = "enemy_collision", 
            remaining_lives = gameState.lives_number, 
            player_position = player_position 
        }
    end

    return response
end

local function changeCurrentScreen(data)

    local prev_screen = data.prev_screen or gameState.current_screen
    local new_screen = data.current_screen

    gameState.current_screen = new_screen
    return { 
        action = "change_current_screen", 
        current_screen = new_screen,
        prev_screen = prev_screen
    }

end

while true do
    local data, ip, port = udp:receivefrom()
    if data then
        print(string.format("Recebido de %s:%d: %s", ip, port, data))
        print("Comando recebido:", data)
        -- Transforma a string JSON em uma tabela Lua
        data = json.decode(data)
        local response = {}

        if data.action == "getInitialGameState" then
            gameState = load_game_state()
            response = {action = "initial_game", gameState = gameState}
        elseif data.action == "collect_diamond" then
            response = diamondCollision(data.collisionClass)
        elseif data.action == "change_current_screen" then
            response = changeCurrentScreen(data)
        elseif data.action == "enemy_collision" then
            response = dinoCollision()
        else
            response = { action = "unknownCommand", message = "Comando desconhecido." }
        end

        -- Codifica a tabela lua em JSON
        local responseJSON = json.encode(response, { indent = false })
        udp:sendto(responseJSON, ip, port)
    end
    socket.sleep(0.01)
end