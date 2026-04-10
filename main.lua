local EnemySystem = require("enemy")
local WeaponSystem = require("weapon")
local ProjectileSystem = require("projectile")
local HUD = require("hud")
local sound = require("sound")

GameState = {
    MENU = "menu",
    PLAYING = "playing",
    PAUSED = "paused",
    GAME_OVER = "gameover"
}

local player = {
    x = 400,
    y = 400,
    width = 32,
    height = 32,
    speed = 250,
    jumpForce = 400,
    velocityX = 0,
    velocityY = 0,
    grounded = false,
    facingX = 1,
    facingY = 0,
    invulnerable = false,
    invulnerableTimer = 0,
    maxHealth = 100,
    canDoubleJump = false,
    hasDoubleJumped = false
}

local platforms = {}
local enemySystem
local weaponSystem
local projectileSystem
local hud

local screenWidth = 800
local screenHeight = 600
local currentState = GameState.MENU
local levelScoreThreshold = 500
local gameTime = 0
local currentLevel = 1
local enemiesDefeated = 0

local screenShake = {x = 0, y = 0, intensity = 0, duration = 0}
local particles = {}
local fonts = {}

local function addScreenShake(intensity, duration)
    screenShake.intensity = intensity
    screenShake.duration = duration
end

local function spawnParticles(x, y, count, color, speed, lifetime)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = speed * (0.3 + math.random() * 0.7)
        table.insert(particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            lifetime = lifetime * (0.5 + math.random() * 0.5),
            maxLifetime = lifetime,
            color = {color[1], color[2], color[3]},
            size = 2 + math.random() * 3,
            gravity = 200
        })
    end
end

local function createPlatforms()
    platforms = {
        {x = 0, y = 560, width = 800, height = 40},
        {x = 100, y = 450, width = 150, height = 20},
        {x = 350, y = 400, width = 100, height = 20},
        {x = 550, y = 350, width = 150, height = 20},
        {x = 200, y = 300, width = 120, height = 20},
        {x = 450, y = 250, width = 100, height = 20},
        {x = 50, y = 200, width = 100, height = 20},
        {x = 650, y = 180, width = 120, height = 20},
        {x = 300, y = 150, width = 200, height = 20}
    }
end

local function resetGame()
    player.x = 400
    player.y = 400
    player.velocityX = 0
    player.velocityY = 0
    player.grounded = false
    player.facingX = 1
    player.facingY = 0
    player.invulnerable = false
    player.invulnerableTimer = 0
    player.hasDoubleJumped = false
    
    createPlatforms()
    enemySystem:reset()
    weaponSystem:reset()
    projectileSystem:reset()
    hud:reset()
    
    gameTime = 0
    currentLevel = 1
    enemiesDefeated = 0
    levelScoreThreshold = 500
    particles = {}
    screenShake = {x = 0, y = 0, intensity = 0, duration = 0}
end

function love.load()
    love.window.setMode(screenWidth, screenHeight)
    love.window.setTitle("Platformer - Survive the Onslaught")
    love.graphics.setBackgroundColor(0.05, 0.05, 0.12)
    math.randomseed(os.time())
    
    fonts.small = love.graphics.newFont(10)
    fonts.medium = love.graphics.newFont(14)
    fonts.large = love.graphics.newFont(20)
    fonts.title = love.graphics.newFont(36)
    fonts.huge = love.graphics.newFont(48)
    
    enemySystem = EnemySystem:new()
    enemySystem:setScreenSize(screenWidth, screenHeight)
    
    weaponSystem = WeaponSystem:new()
    projectileSystem = ProjectileSystem:new()
    projectileSystem:setScreenSize(screenWidth, screenHeight)
    
    hud = HUD:new()
    hud:setScreenSize(screenWidth, screenHeight)
    
    sound.init()
    
    createPlatforms()
end

function love.update(dt)
    if currentState == GameState.MENU then
        hud:update(dt)
        return
    end
    
    if currentState == GameState.PAUSED then
        return
    end
    
    if currentState == GameState.GAME_OVER then
        hud:update(dt)
        updateParticles(dt)
        return
    end
    
    gameTime = gameTime + dt
    
    updatePlayerMovement(dt)
    updatePlayerPhysics(dt)
    
    weaponSystem:update(dt, screenWidth, screenHeight)
    projectileSystem:update(dt)
    
    enemySystem:update(dt, player, platforms)
    
    local collectedWeapon = weaponSystem:checkPickupCollision(player.x, player.y, player.width, player.height)
    if collectedWeapon then
        hud:setWeapon(collectedWeapon)
        spawnParticles(player.x + player.width / 2, player.y + player.height / 2,
            12, collectedWeapon.color, 150, 0.5)
    end
    
    if player.invulnerable then
        player.invulnerableTimer = player.invulnerableTimer - dt
        if player.invulnerableTimer <= 0 then
            player.invulnerable = false
        end
    end
    
    if not player.invulnerable then
        local damageFromEnemies = enemySystem:checkPlayerCollision(player)
        local damageFromProjectiles = enemySystem:checkProjectileCollision(player)
        local totalDamage = damageFromEnemies + damageFromProjectiles
        
        if totalDamage > 0 then
            local isDead = hud:takeDamage(totalDamage)
            player.invulnerable = true
            player.invulnerableTimer = 0.5
            sound.playerDamage()
            addScreenShake(5, 0.2)
            spawnParticles(player.x + player.width / 2, player.y + player.height / 2,
                8, {1, 0.3, 0.3}, 200, 0.4)
            
            if isDead then
                currentState = GameState.GAME_OVER
                hud:startGameOver()
                addScreenShake(10, 0.5)
                spawnParticles(player.x + player.width / 2, player.y + player.height / 2,
                    30, {1, 0.2, 0.2}, 300, 1.0)
            end
        end
    end
    
    local prevAliveCount = 0
    local enemies = enemySystem:getEnemies()
    for _, e in ipairs(enemies) do
        if e.alive then prevAliveCount = prevAliveCount + 1 end
    end
    
    local scoreFromPlayerProj = projectileSystem:checkPlayerProjectilesVsEnemies(enemies)
    
    local newDeadCount = 0
    for _, e in ipairs(enemies) do
        if not e.alive then
            newDeadCount = newDeadCount + 1
            spawnParticles(e.x + e.width / 2, e.y + e.height / 2,
                15, e.color, 200, 0.6)
        end
    end
    
    local killedCount = newDeadCount - (#enemies - prevAliveCount)
    if killedCount > 0 then
        for _, e in ipairs(enemies) do
            if not e.alive then
                hud:addScore(e.scoreValue, e.x, e.y)
            end
        end
        enemiesDefeated = enemiesDefeated + killedCount
        sound.enemyDeath()
    end
    
    enemySystem:checkProjectileHit(projectileSystem:getProjectiles())
    
    local newLevel = math.floor(hud:getScore() / levelScoreThreshold) + 1
    if newLevel > currentLevel then
        currentLevel = newLevel
        hud:setLevel(currentLevel)
        enemySystem:setDifficulty(math.min(currentLevel, 5))
        sound.levelComplete()
        addScreenShake(3, 0.3)
        
        for i = 1, 3 do
            local px = math.random(50, screenWidth - 50)
            local py = math.random(50, screenHeight - 200)
            weaponSystem:spawnPickup(px, py)
        end
        
        spawnParticles(screenWidth / 2, screenHeight / 2,
            25, {0.3, 0.8, 1}, 250, 0.8)
    end
    
    updateScreenShake(dt)
    updateParticles(dt)
    
    hud:update(dt)
end

function updatePlayerMovement(dt)
    local dx = 0
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = dx - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = dx + 1
    end
    
    player.velocityX = dx * player.speed
    
    if dx ~= 0 then
        player.facingX = dx > 0 and 1 or -1
        player.facingY = 0
    end
end

function updatePlayerPhysics(dt)
    player.velocityY = player.velocityY + 1000 * dt
    if player.velocityY > 600 then
        player.velocityY = 600
    end
    
    player.x = player.x + player.velocityX * dt
    player.y = player.y + player.velocityY * dt
    
    player.x = math.max(0, math.min(screenWidth - player.width, player.x))
    
    if player.y > screenHeight then
        player.y = 100
        player.velocityY = 0
    end
    
    player.grounded = false
    for _, platform in ipairs(platforms) do
        local prevBottom = player.y + player.height - player.velocityY * dt
        local currBottom = player.y + player.height
        
        if player.x + player.width > platform.x and player.x < platform.x + platform.width then
            if prevBottom <= platform.y and currBottom >= platform.y then
                player.y = platform.y - player.height
                player.velocityY = 0
                player.grounded = true
                player.hasDoubleJumped = false
            end
        end
    end
end

function updateScreenShake(dt)
    if screenShake.duration > 0 then
        screenShake.duration = screenShake.duration - dt
        screenShake.x = (math.random() - 0.5) * screenShake.intensity * 2
        screenShake.y = (math.random() - 0.5) * screenShake.intensity * 2
        screenShake.intensity = screenShake.intensity * 0.9
    else
        screenShake.x = 0
        screenShake.y = 0
    end
end

function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + p.gravity * dt
        p.lifetime = p.lifetime - dt
        p.size = p.size * 0.98
        
        if p.lifetime <= 0 then
            table.remove(particles, i)
        end
    end
end

function drawParticles()
    for _, p in ipairs(particles) do
        local alpha = p.lifetime / p.maxLifetime
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, math.max(0.5, p.size))
    end
end

function love.draw()
    if currentState == GameState.MENU then
        drawMenu()
        return
    end
    
    love.graphics.push()
    love.graphics.translate(screenShake.x, screenShake.y)
    
    love.graphics.setBackgroundColor(0.05, 0.05, 0.12)
    drawBackground()
    drawPlatforms()
    
    weaponSystem:drawPickups()
    enemySystem:draw()
    projectileSystem:draw()
    drawPlayer()
    drawParticles()
    
    love.graphics.pop()
    
    if currentState == GameState.PAUSED then
        hud:drawPause()
    end
    
    if currentState == GameState.GAME_OVER then
        hud:draw()
        hud:drawGameOver()
        return
    end
    
    hud:draw()
end

function drawMenu()
    hud:drawMenu()
end

function drawBackground()
    for x = 0, screenWidth, 40 do
        love.graphics.setColor(0.08, 0.08, 0.12)
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, 40 do
        love.graphics.setColor(0.08, 0.08, 0.12)
        love.graphics.line(0, y, screenWidth, y)
    end
    
    local starCount = 50
    for i = 1, starCount do
        local x = (i * 137.5) % screenWidth
        local y = (i * 73.7) % screenHeight
        local size = ((i * 17) % 3) + 1
        local twinkle = 0.3 + 0.7 * math.abs(math.sin(love.timer.getTime() * 2 + i))
        love.graphics.setColor(1, 1, 1, twinkle * 0.6)
        love.graphics.circle("fill", x, y, size)
    end
end

function drawPlatforms()
    for _, platform in ipairs(platforms) do
        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.rectangle("fill", platform.x, platform.y, platform.width, platform.height, 3, 3)
        
        love.graphics.setColor(0.25, 0.25, 0.35)
        love.graphics.rectangle("fill", platform.x, platform.y, platform.width, 4, 3, 3)
        
        love.graphics.setColor(0.1, 0.1, 0.15)
        love.graphics.rectangle("line", platform.x, platform.y, platform.width, platform.height, 3, 3)
    end
end

function drawPlayer()
    if player.invulnerable and math.floor(love.timer.getTime() * 10) % 2 == 0 then
        return
    end
    
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse("fill", player.x + player.width / 2 + 2, 
                           player.y + player.height + 2, 
                           player.width / 2 + 2, 6)
    
    love.graphics.setColor(0.2, 0.5, 0.9)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height, 4, 4)
    
    love.graphics.setColor(0.4, 0.7, 1)
    love.graphics.rectangle("fill", player.x + 2, player.y + 2, player.width - 4, player.height / 3, 3, 3)
    
    local eyeOffsetX = player.facingX * 4
    local eyeOffsetY = player.facingY * 2
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", player.x + player.width / 2 - 5 + eyeOffsetX, 
                         player.y + player.height / 3 + eyeOffsetY, 4)
    love.graphics.circle("fill", player.x + player.width / 2 + 5 + eyeOffsetX, 
                         player.y + player.height / 3 + eyeOffsetY, 4)
    
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.circle("fill", player.x + player.width / 2 - 5 + eyeOffsetX + player.facingX, 
                         player.y + player.height / 3 + eyeOffsetY, 2)
    love.graphics.circle("fill", player.x + player.width / 2 + 5 + eyeOffsetX + player.facingX, 
                         player.y + player.height / 3 + eyeOffsetY, 2)
    
    local weapon = weaponSystem:getCurrentWeapon()
    if weapon then
        local gunX = player.x + player.width / 2 + player.facingX * 18
        local gunY = player.y + player.height / 2 + 4
        love.graphics.setColor(weapon.color[1] * 0.8, weapon.color[2] * 0.8, weapon.color[3] * 0.8)
        love.graphics.rectangle("fill", gunX - 4, gunY - 3, 10, 6, 2, 2)
    end
end

function love.keypressed(key)
    if currentState == GameState.MENU then
        local result = hud:handleMenuKey(key)
        if result == "start" then
            resetGame()
            currentState = GameState.PLAYING
            hud:setWeapon(weaponSystem:getCurrentWeapon())
        elseif result == "quit" then
            love.event.quit()
        end
        return
    end
    
    if currentState == GameState.GAME_OVER then
        local result = hud:handleGameOverKey(key)
        if result == "restart" then
            resetGame()
            currentState = GameState.PLAYING
            hud:setWeapon(weaponSystem:getCurrentWeapon())
        elseif result == "menu" then
            currentState = GameState.MENU
            hud:reset()
        end
        return
    end
    
    if key == "escape" or key == "p" then
        if currentState == GameState.PLAYING then
            currentState = GameState.PAUSED
            hud:togglePause()
        elseif currentState == GameState.PAUSED then
            currentState = GameState.PLAYING
            hud:togglePause()
        end
        return
    end
    
    if currentState == GameState.PLAYING then
        if key == "w" or key == "up" then
            if player.grounded then
                player.velocityY = -player.jumpForce
                player.grounded = false
                sound.jump()
                spawnParticles(player.x + player.width / 2, player.y + player.height,
                    6, {0.5, 0.5, 0.7}, 100, 0.3)
            elseif not player.hasDoubleJumped then
                player.velocityY = -player.jumpForce * 0.8
                player.hasDoubleJumped = true
                sound.jump()
                spawnParticles(player.x + player.width / 2, player.y + player.height,
                    8, {0.3, 0.6, 1}, 120, 0.4)
            end
        end
        
        if key == "space" or key == "z" or key == "f" then
            local centerX = player.x + player.width / 2
            local centerY = player.y + player.height / 2
            
            local weapon = weaponSystem:getCurrentWeapon()
            if weapon then
                projectileSystem:fire({
                    x = centerX,
                    y = centerY,
                    dirX = player.facingX,
                    dirY = player.facingY,
                    speed = weapon.projectileSpeed,
                    damage = weapon.damage,
                    count = weapon.projectileCount,
                    spread = 0.15,
                    owner = "player",
                    preset = weapon.name == "Laser Beam" and "player_laser" or "player_bullet",
                    size = weapon.size,
                    color = weapon.color
                })
                sound.shoot()
                hud:updateFireTime(love.timer.getTime())
                
                spawnParticles(centerX + player.facingX * 15, centerY,
                    3, weapon.color, 80, 0.2)
            end
        end
        
        if key == "m" then
            local muted = sound.toggle()
        end
    end
end

function love.keyreleased(key)
    
end
