local socket = require("socket")
local json = require("libraries/dkjson")

udp = socket.udp()
udp:setsockname('*', 12345)
udp:settimeout(0)

print("Servidor da biblioteca rodando na porta 12345...")

-- Configuração inicial do estado do jogo
local gameState = nil

local function reset_game_state()
    return {
        current_screen = "menu",
        total_diamonds = 113,
        total_pink_diamonds = 7,
        lives_number = 3,
        player_position = {x = 524.8, y = 320},
        player_speed = 120
    }
end

local function diamondCollision(class)
    -- Quando acontecer a colisão com o diamente rosa, aumentar a velocidade do jogador
    local response = {}

    if class == "Diamond" then
        gameState.total_diamonds = gameState.total_diamonds - 1
        response = { action = "diamond_collision", diamonds =  gameState.total_diamonds }
    elseif class == "PinkDiamond" then
        gameState.total_pink_diamonds = gameState.total_pink_diamonds - 1
        local speedBoost = { multiplier = 1.8, duration = 1.5 }
        response = { action = "pink_diamond_collision", pink_diamonds =  gameState.total_pink_diamonds, speedBoost = speedBoost }
    end

    return response
end

local function dinoCollision()
    if gameState.lives_number == 1 then
        gameState.lives_number = gameState.lives_number - 1
        response = { action = "game_over", remaining_lives = gameState.lives_number, current_screen = "game_over" }
    else
        gameState.lives_number = gameState.lives_number - 1
        local player_position = { x = 524.8, y = 320 }
        response = { action = "enemy_collision", remaining_lives = gameState.lives_number, player_position = player_position }
    end

    return response
end

while true do
    local data, ip, port = udp:receivefrom()
    if data then
        print("Comando recebido:", data)
        -- Transforma a string JSON em uma tabela Lua
        data = json.decode(data)
        local response = {}

        if data.action == "getInitialGameState" then
            gameState = reset_game_state()
            response = {action = "initial_game", gameState = gameState}
        elseif data.action == "collect_diamond" then
            response = diamondCollision(data.collisionClass)
        elseif data.action == "change_current_screen" then
            gameState.current_screen = data.current_screen
            response = { action = "change_current_screen", current_screen = gameState.current_screen }
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