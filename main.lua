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
    jumpForce = 600,
    velocityX = 0,
    velocityY = 0,
    grounded = false,
    facingX = 1,
    facingY = 0,
    invulnerable = false,
    invulnerableTimer = 0,
    maxHealth = 100,
    jumpsRemaining = 2,
    maxJumps = 2
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

local levelWidth = 4000
local camera = {x = 0, y = 0, width = screenWidth}
local flag = {x = levelWidth - 100, y = 0, reached = false}

local function createPlatforms()
    platforms = {}
    table.insert(platforms, {x = 0, y = 560, width = levelWidth, height = 40})
    
    local platformCount = math.floor(levelWidth / 200)
    for i = 1, platformCount do
        local x = 100 + (i - 1) * 200 + math.random(-80, 80)
        local y = 200 + math.random(0, 280)
        local width = 80 + math.random(0, 120)
        local height = 20
        if x > 0 and x + width < levelWidth then
            table.insert(platforms, {x = x, y = y, width = width, height = height})
        end
    end
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
    
    camera.x = 0
    camera.y = 0
    flag.reached = false
    
    createPlatforms()
    enemySystem:reset()
    weaponSystem:fullReset()
    weaponSystem:spawnLevelPickups(platforms, levelWidth, screenHeight)
    projectileSystem:reset()
    hud:reset()
    
    gameTime = 0
    levelScoreThreshold = 500
end

local function generateNewLevel()
    player.x = 400
    player.y = 400
    player.velocityX = 0
    player.velocityY = 0
    player.grounded = false
    player.facingX = 1
    
    camera.x = 0
    flag.reached = false
    
    createPlatforms()
    enemySystem:reset()
    weaponSystem:reset()
    weaponSystem:spawnLevelPickups(platforms, levelWidth, screenHeight)
    projectileSystem:reset()
end

function love.load()
    love.window.setMode(screenWidth, screenHeight)
    love.window.setTitle("Platformer - Survive the Onslaught")
    love.graphics.setBackgroundColor(0.05, 0.05, 0.12)
    math.randomseed(os.time())
    
    enemySystem = EnemySystem:new()
    enemySystem:setScreenSize(screenWidth, screenHeight)
    enemySystem:setLevelBounds(0, levelWidth)
    
    weaponSystem = WeaponSystem:new()
    projectileSystem = ProjectileSystem:new()
    projectileSystem:setScreenSize(screenWidth, screenHeight)
    projectileSystem:setLevelBounds(0, levelWidth)
    
    hud = HUD:new()
    hud:setScreenSize(screenWidth, screenHeight)
    hud:setWeaponSystem(weaponSystem)
    
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
    
    local levelEnd = levelWidth - player.width
    player.x = math.max(0, math.min(levelEnd, player.x))
    
    local targetCamX = player.x - screenWidth / 2 + player.width / 2
    camera.x = camera.x + (targetCamX - camera.x) * 5 * dt
    camera.x = math.max(0, math.min(levelWidth - screenWidth, camera.x))
    
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
                player.jumpsRemaining = player.maxJumps
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
    
    if not flag.reached then
        if player.x + player.width > flag.x and player.x < flag.x + 30 then
            flag.reached = true
            hud:addScore(1000, flag.x, flag.y)
            sound.levelComplete()
            generateNewLevel()
        end
    end
    
    local level = math.floor(hud:getScore() / levelScoreThreshold) + 1
    hud:setLevel(level)
    enemySystem:setDifficulty(math.min(level, 5))
    
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
    
    weaponSystem:setCameraX(camera.x)
    enemySystem:setCameraX(camera.x)
    projectileSystem:setCameraX(camera.x)
    weaponSystem:drawPickups()
    enemySystem:draw()
    projectileSystem:draw()
    drawPlayer()
    drawFlag()
    
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
    local parallax1 = camera.x * 0.3
    local parallax2 = camera.x * 0.5
    
    for x = -40, screenWidth + 40, 40 do
        love.graphics.setColor(0.08, 0.08, 0.12)
        love.graphics.line(x, 0, x - parallax1 % 40, screenHeight)
    end
    for y = 0, screenHeight, 40 do
        love.graphics.setColor(0.08, 0.08, 0.12)
        love.graphics.line(0, y, screenWidth, y)
    end
    
    local starCount = 50
    for i = 1, starCount do
        local x = (i * 137.5 + parallax2) % (screenWidth + 200) - 100
        local y = (i * 73.7) % screenHeight
        local size = ((i * 17) % 3) + 1
        local twinkle = 0.3 + 0.7 * math.abs(math.sin(love.timer.getTime() * 2 + i))
        love.graphics.setColor(1, 1, 1, twinkle * 0.6)
        love.graphics.circle("fill", x, y, size)
    end
end

function drawPlatforms()
    for _, platform in ipairs(platforms) do
        if platform.x + platform.width > camera.x and platform.x < camera.x + screenWidth then
            local offsetX = platform.x - camera.x
            love.graphics.setColor(0.15, 0.15, 0.2)
            love.graphics.rectangle("fill", offsetX, platform.y, platform.width, platform.height, 3, 3)
            
            love.graphics.setColor(0.25, 0.25, 0.35)
            love.graphics.rectangle("fill", offsetX, platform.y, platform.width, 4, 3, 3)
            
            love.graphics.setColor(0.1, 0.1, 0.15)
            love.graphics.rectangle("line", offsetX, platform.y, platform.width, platform.height, 3, 3)
        end
    end
end

function drawPlayer()
    if player.invulnerable and math.floor(love.timer.getTime() * 10) % 2 == 0 then
        return
    end
    
    local offsetX = player.x - camera.x
    
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse("fill", offsetX + player.width / 2 + 2, 
                           player.y + player.height + 2, 
                           player.width / 2 + 2, 6)
    
    love.graphics.setColor(0.2, 0.5, 0.9)
    love.graphics.rectangle("fill", offsetX, player.y, player.width, player.height, 4, 4)
    
    love.graphics.setColor(0.4, 0.7, 1)
    love.graphics.rectangle("fill", offsetX + 2, player.y + 2, player.width - 4, player.height / 3, 3, 3)
    
    local eyeOffsetX = player.facingX * 4
    local eyeOffsetY = player.facingY * 2
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", offsetX + player.width / 2 - 5 + eyeOffsetX, 
                         player.y + player.height / 3 + eyeOffsetY, 4)
    love.graphics.circle("fill", offsetX + player.width / 2 + 5 + eyeOffsetX, 
                         player.y + player.height / 3 + eyeOffsetY, 4)
    
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.circle("fill", offsetX + player.width / 2 - 5 + eyeOffsetX + 1, 
                         player.y + player.height / 3 + eyeOffsetY, 2)
    love.graphics.circle("fill", offsetX + player.width / 2 + 5 + eyeOffsetX + 1, 
                         player.y + player.height / 3 + eyeOffsetY, 2)
end

function drawFlag()
    if flag.reached then
        return
    end
    
    local screenX = flag.x - camera.x
    if screenX < -50 or screenX > screenWidth + 50 then
        return
    end
    
    local flagY = 200
    local poleHeight = flagY + 200
    local flagWidth = 60
    local flagHeight = 40
    local time = love.timer.getTime()
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(6)
    love.graphics.line(screenX, flagY, screenX, flagY + poleHeight)
    
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.circle("fill", screenX, flagY, 8)
    
    local wave1 = math.sin(time * 4) * 5
    local wave2 = math.sin(time * 4 + 1) * 3
    local wave3 = math.sin(time * 4 + 2) * 4
    
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.polygon("fill",
        screenX + 5, flagY + 10,
        screenX + 5 + flagWidth + wave1, flagY + 10 + wave2,
        screenX + 5 + flagWidth + wave3, flagY + 10 + flagHeight / 2,
        screenX + 5 + flagWidth + wave2, flagY + 10 + flagHeight,
        screenX + 5, flagY + 10 + flagHeight
    )
    
    love.graphics.setColor(1, 1, 0.2)
    love.graphics.circle("fill", screenX + 30 + wave1, flagY + 30 + wave2, 8)
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
        if key == "q" then
            weaponSystem:swapToNext()
            hud:setWeapon(weaponSystem:getCurrentWeapon())
        elseif key == "1" then
            weaponSystem:swapToSlot(1)
            hud:setWeapon(weaponSystem:getCurrentWeapon())
        elseif key == "2" then
            weaponSystem:swapToSlot(2)
            hud:setWeapon(weaponSystem:getCurrentWeapon())
        elseif key == "3" then
            weaponSystem:swapToSlot(3)
            hud:setWeapon(weaponSystem:getCurrentWeapon())
        elseif key == "4" then
            weaponSystem:swapToSlot(4)
            hud:setWeapon(weaponSystem:getCurrentWeapon())
        elseif key == "space" then
            if player.jumpsRemaining > 0 then
                player.velocityY = -player.jumpForce
                player.jumpsRemaining = player.jumpsRemaining - 1
                player.grounded = false
                sound.jump()
            end
            
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
        elseif key == "w" or key == "up" then
            if player.jumpsRemaining > 0 then
                player.velocityY = -player.jumpForce
                player.jumpsRemaining = player.jumpsRemaining - 1
                player.grounded = false
                sound.jump()
            end
        end
    end
end

function love.keyreleased(key)
    
end
