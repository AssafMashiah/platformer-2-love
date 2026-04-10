local sound = {}

sound.muted = false
sound.sounds = {}

local function generateTone(frequency, duration, volume, waveType, attack, decay)
    local sampleRate = 44100
    local numSamples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(numSamples, sampleRate, 16, 1)
    
    attack = attack or 0.01
    decay = decay or 0.1
    
    for i = 0, numSamples - 1 do
        local t = i / sampleRate
        local sample = 0
        
        if waveType == "sine" then
            sample = math.sin(2 * math.pi * frequency * t)
        elseif waveType == "square" then
            sample = math.sin(2 * math.pi * frequency * t) > 0 and 1 or -1
        elseif waveType == "sawtooth" then
            sample = 2 * (frequency * t % 1) - 1
        elseif waveType == "noise" then
            sample = love.math.random(-1, 1)
        else
            sample = math.sin(2 * math.pi * frequency * t)
        end
        
        local env = 1
        if t < attack then
            env = t / attack
        elseif t > duration - decay then
            env = (duration - t) / decay
        end
        
        sample = sample * env * volume
        soundData:setSample(i, math.max(-1, math.min(1, sample)))
    end
    
    return soundData
end

local function generateJump()
    local sampleRate = 44100
    local numSamples = math.floor(sampleRate * 0.15)
    local soundData = love.sound.newSoundData(numSamples, sampleRate, 16, 1)
    
    for i = 0, numSamples - 1 do
        local t = i / sampleRate
        local progress = i / numSamples
        local frequency = 200 + (400 * (1 - progress))
        local sample = math.sin(2 * math.pi * frequency * t)
        local env = 1 - progress
        soundData:setSample(i, sample * env * 0.3)
    end
    
    return soundData
end

local function generateShoot()
    local sampleRate = 44100
    local numSamples = math.floor(sampleRate * 0.1)
    local soundData = love.sound.newSoundData(numSamples, sampleRate, 16, 1)
    
    for i = 0, numSamples - 1 do
        local t = i / sampleRate
        local progress = i / numSamples
        local frequency = 800 - (300 * progress)
        local sample = math.sin(2 * math.pi * frequency * t)
        local noise = love.math.random(-1, 1) * 0.2
        sample = sample * 0.8 + noise
        local env = math.exp(-3 * progress)
        soundData:setSample(i, sample * env * 0.4)
    end
    
    return soundData
end

local function generateEnemyDeath()
    local sampleRate = 44100
    local numSamples = math.floor(sampleRate * 0.3)
    local soundData = love.sound.newSoundData(numSamples, sampleRate, 16, 1)
    
    for i = 0, numSamples - 1 do
        local t = i / sampleRate
        local progress = i / numSamples
        local frequency = 600 - (400 * progress)
        local sample = math.sin(2 * math.pi * frequency * t)
        local noise = love.math.random(-1, 1) * 0.3
        sample = sample * 0.7 + noise
        local env = math.exp(-4 * progress)
        soundData:setSample(i, sample * env * 0.5)
    end
    
    return soundData
end

local function generatePlayerDamage()
    local sampleRate = 44100
    local numSamples = math.floor(sampleRate * 0.25)
    local soundData = love.sound.newSoundData(numSamples, sampleRate, 16, 1)
    
    for i = 0, numSamples - 1 do
        local t = i / sampleRate
        local progress = i / numSamples
        local frequency = 150 + (100 * math.sin(20 * progress * math.pi))
        local sample = math.sin(2 * math.pi * frequency * t)
        local env = math.exp(-2 * progress)
        soundData:setSample(i, sample * env * 0.5)
    end
    
    return soundData
end

local function generateLevelComplete()
    local sampleRate = 44100
    local duration = 0.5
    local numSamples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(numSamples, sampleRate, 16, 1)
    
    local notes = {523.25, 659.25, 783.99, 1046.50}
    local noteDuration = duration / #notes
    
    for i = 0, numSamples - 1 do
        local t = i / sampleRate
        local noteIndex = math.floor(t / noteDuration)
        local noteProgress = (t % noteDuration) / noteDuration
        
        if noteIndex < #notes then
            local frequency = notes[noteIndex + 1]
            local sample = math.sin(2 * math.pi * frequency * t)
            local noise = love.math.random(-1, 1) * 0.05
            sample = sample * 0.9 + noise
            local env = 1 - noteProgress * 0.3
            soundData:setSample(i, sample * env * 0.4)
        else
            soundData:setSample(i, 0)
        end
    end
    
    return soundData
end

local function createSources()
    sound.sounds.jump = love.audio.newSource(generateJump(), "static")
    sound.sounds.shoot = love.audio.newSource(generateShoot(), "static")
    sound.sounds.enemyDeath = love.audio.newSource(generateEnemyDeath(), "static")
    sound.sounds.playerDamage = love.audio.newSource(generatePlayerDamage(), "static")
    sound.sounds.levelComplete = love.audio.newSource(generateLevelComplete(), "static")
    
    for _, src in pairs(sound.sounds) do
        src:setVolume(0.5)
    end
end

function sound.init()
    if love.audio then
        createSources()
    end
end

function sound.play(soundName)
    if sound.muted then return end
    
    local src = sound.sounds[soundName]
    if src then
        local newSrc = src:clone()
        newSrc:setVolume(0.5)
        newSrc:play()
    end
end

function sound.jump()
    sound.play("jump")
end

function sound.shoot()
    sound.play("shoot")
end

function sound.enemyDeath()
    sound.play("enemyDeath")
end

function sound.playerDamage()
    sound.play("playerDamage")
end

function sound.levelComplete()
    sound.play("levelComplete")
end

function sound.toggle()
    sound.muted = not sound.muted
    return sound.muted
end

function sound.mute()
    sound.muted = true
end

function sound.unmute()
    sound.muted = false
end

function sound.isMuted()
    return sound.muted
end

function sound.setVolume(vol)
    for _, src in pairs(sound.sounds) do
        src:setVolume(math.max(0, math.min(1, vol)))
    end
end

return sound
