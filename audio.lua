local Audio = {}
local sounds = {}

function Audio.load()
    sounds.music = love.audio.newSource("assets/sounds/fase1.flac", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.5)
    
    sounds.music2 = love.audio.newSource("assets/sounds/fase2.wav", "stream")
    sounds.music2:setLooping(true)
    sounds.music2:setVolume(0.5)

    sounds.enemyHiy = love.audio.newSource("assets/sounds/loser.wav", "static")
    sounds.enemyHiy:setVolume(0.8)
    sounds.initiateGame = love.audio.newSource("assets/sounds/enter.wav", "static")
    sounds.initiateGame:setVolume(1)
    sounds.collectDiamond = love.audio.newSource("assets/sounds/coin.wav", "static")
    sounds.collectDiamond:setVolume(0.3)
end

-- Toca a música de fundo (somente se não estiver tocando)
function Audio.playMusic()
    if not sounds.music:isPlaying() then
        sounds.music:play()
    end
end

-- Para a música de fundo
function Audio.stopMusic()
    if sounds.music:isPlaying() then
        sounds.music:stop()
    end
end

-- Pausa e retoma a música sem reiniciar
function Audio.pauseMusic()
    if sounds.music:isPlaying() then
        sounds.music:pause()
    end
end

function Audio.resumeMusic()
    if sounds.music:tell() > 0 and not sounds.music:isPlaying() then
        sounds.music:play()
    end
end

function Audio.playMusic2()
    if not sounds.music2:isPlaying() then
        sounds.music2:play()
    end
end

-- Para a música de fundo
function Audio.stopMusic2()
    if sounds.music2:isPlaying() then
        sounds.music2:stop()
    end
end

-- Pausa e retoma a música sem reiniciar
function Audio.pauseMusic2()
    if sounds.music2:isPlaying() then
        sounds.music2:pause()
    end
end

function Audio.resumeMusic2()
    if sounds.music2:tell() > 0 and not sounds.music2:isPlaying() then
        sounds.music2:play()
    end
end

function Audio.playEnemyHit()
    sounds.enemyHiy:play()
end

function Audio.playInitiateGame()
    sounds.initiateGame:stop()
    sounds.initiateGame:play()
end

function Audio.playCollectDiamond()
    sounds.collectDiamond:stop()
    sounds.collectDiamond:play()
end

return Audio