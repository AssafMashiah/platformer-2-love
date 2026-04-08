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
    maxHealth = 100
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
    
    createPlatforms()
    enemySystem:reset()
    weaponSystem:reset()
    projectileSystem:reset()
    hud:reset()
    
    gameTime = 0
    levelScoreThreshold = 500
end

function love.load()
    love.window.setMode(screenWidth, screenHeight)
    love.window.setTitle("Platformer - Survive the Onslaught")
    love.graphics.setBackgroundColor(0.05, 0.05, 0.12)
    math.randomseed(os.time())
    
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
        return
    end
    
    gameTime = gameTime + dt
    
    local dx, dy = 0, 0
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = dx - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = dx + 1
    end
    
    player.velocityX = dx * player.speed
    
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space")) and player.grounded then
        player.velocityY = -player.jumpForce
        player.grounded = false
        sound.jump()
    end
    
    player.velocityY = player.velocityY + 1000 * dt
    if player.velocityY > 600 then
        player.velocityY = 600
    end
    
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            player.facingX, player.facingY = dx / len, dy / len
        end
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
            end
        end
    end
    
    weaponSystem:update(dt, screenWidth, screenHeight)
    projectileSystem:update(dt)
    
    enemySystem:update(dt, player, platforms)
    
    local collectedWeapon = weaponSystem:checkPickupCollision(player.x, player.y, player.width, player.height)
    if collectedWeapon then
        hud:setWeapon(collectedWeapon)
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
            
            if isDead then
                currentState = GameState.GAME_OVER
                hud:startGameOver()
            end
        end
    end
    
    local scoreFromPlayerProj = projectileSystem:checkPlayerProjectilesVsEnemies(enemySystem:getEnemies())
    if scoreFromPlayerProj > 0 then
        local enemies = enemySystem:getEnemies()
        for _, enemy in ipairs(enemies) do
            if not enemy.alive then
                hud:addScore(enemy.scoreValue, enemy.x, enemy.y)
            end
        end
        sound.enemyDeath()
    end
    
    enemySystem:checkProjectileHit(projectileSystem:getProjectiles())
    
    local level = math.floor(hud:getScore() / levelScoreThreshold) + 1
    hud:setLevel(level)
    enemySystem:setDifficulty(math.min(level, 5))
    
    if level > hud:getLevel() then
        sound.levelComplete()
        for i = 1, 3 do
            local x = math.random(50, screenWidth - 50)
            local y = math.random(50, screenHeight - 200)
            weaponSystem:spawnPickup(x, y)
        end
    end
    
    hud:update(dt)
end

function love.draw()
    if currentState == GameState.MENU then
        drawMenu()
        return
    end
    
    love.graphics.setBackgroundColor(0.05, 0.05, 0.12)
    drawBackground()
    drawPlatforms()
    
    weaponSystem:drawPickups()
    enemySystem:draw()
    projectileSystem:draw()
    drawPlayer()
    
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
    love.graphics.circle("fill", player.x + player.width / 2 - 5 + eyeOffsetX + 1, 
                         player.y + player.height / 3 + eyeOffsetY, 2)
    love.graphics.circle("fill", player.x + player.width / 2 + 5 + eyeOffsetX + 1, 
                         player.y + player.height / 3 + eyeOffsetY, 2)
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
        if key == "space" then
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
            end
        end
    end
end

function love.keyreleased(key)
    
end
