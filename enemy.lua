EnemySystem = {}
EnemySystem.__index = EnemySystem

local ENEMY_TYPES = {
    {
        name = "Slime",
        color = {0.2, 0.8, 0.3},
        size = 20,
        speed = 60,
        health = 30,
        damage = 10,
        behavior = "patrol",
        jumpHeight = 150,
        patrolRange = 100,
        scoreValue = 100
    },
    {
        name = "Bat",
        color = {0.6, 0.2, 0.8},
        size = 15,
        speed = 120,
        health = 20,
        damage = 8,
        behavior = "chase",
        chaseRange = 200,
        hoverAmplitude = 20,
        hoverSpeed = 4,
        scoreValue = 150
    },
    {
        name = "Turret",
        color = {0.8, 0.4, 0.1},
        size = 25,
        speed = 0,
        health = 50,
        damage = 15,
        behavior = "shoot",
        fireRate = 1.5,
        projectileSpeed = 300,
        detectionRange = 250,
        scoreValue = 200
    },
    {
        name = "Chaser",
        color = {1, 0.2, 0.2},
        size = 22,
        speed = 100,
        health = 40,
        damage = 20,
        behavior = "chase",
        chaseRange = 300,
        chargeSpeed = 180,
        chargeCooldown = 3,
        scoreValue = 250
    },
    {
        name = "Ghost",
        color = {0.5, 0.7, 1.0},
        size = 18,
        speed = 50,
        health = 25,
        damage = 12,
        behavior = "patrol",
        patrolRange = 150,
        phaseThrough = true,
        flickerRate = 5,
        scoreValue = 175
    }
}

function EnemySystem:new()
    local instance = setmetatable({}, self)
    instance.enemies = {}
    instance.projectiles = {}
    instance.spawnTimer = 0
    instance.spawnInterval = 5
    instance.maxEnemies = 8
    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.difficulty = 1
    instance.levelStart = 0
    instance.levelEnd = 4000
    instance.cameraX = 0
    return instance
end

function EnemySystem:setLevelBounds(start, levelEnd)
    self.levelStart = start
    self.levelEnd = levelEnd
end

function EnemySystem:setCameraX(camX)
    self.cameraX = camX
end

function EnemySystem:generateEnemy(x, y, forceType)
    local enemyData = forceType and ENEMY_TYPES[forceType] or ENEMY_TYPES[math.random(1, #ENEMY_TYPES)]
    
    local enemy = {
        x = x,
        y = y,
        width = enemyData.size * 2,
        height = enemyData.size * 2,
        name = enemyData.name,
        color = {unpack(enemyData.color)},
        size = enemyData.size,
        speed = enemyData.speed * (0.8 + self.difficulty * 0.2),
        health = enemyData.health * (0.8 + self.difficulty * 0.2),
        maxHealth = enemyData.health * (0.8 + self.difficulty * 0.2),
        damage = enemyData.damage * (0.8 + self.difficulty * 0.2),
        behavior = enemyData.behavior,
        scoreValue = enemyData.scoreValue,
        
        startX = x,
        startY = y,
        direction = math.random() > 0.5 and 1 or -1,
        
        patrolRange = enemyData.patrolRange or 100,
        chaseRange = enemyData.chaseRange or 200,
        detectionRange = enemyData.detectionRange or 250,
        hoverAmplitude = enemyData.hoverAmplitude or 20,
        hoverSpeed = enemyData.hoverSpeed or 4,
        hoverOffset = math.random() * math.pi * 2,
        fireRate = enemyData.fireRate or 2,
        lastFireTime = 0,
        projectileSpeed = enemyData.projectileSpeed or 300,
        jumpHeight = enemyData.jumpHeight or 150,
        chargeCooldown = enemyData.chargeCooldown or 3,
        chargeTimer = 0,
        isCharging = false,
        phaseThrough = enemyData.phaseThrough or false,
        flickerRate = enemyData.flickerRate or 5,
        flickerTimer = 0,
        isVisible = true,
        
        velocityX = 0,
        velocityY = 0,
        grounded = false,
        alive = true
    }
    
    return enemy
end

function EnemySystem:spawnEnemy(x, y, forceType)
    if #self.enemies >= self.maxEnemies then
        return nil
    end
    
    local enemy = self:generateEnemy(x, y, forceType)
    table.insert(self.enemies, enemy)
    return enemy
end

function EnemySystem:spawnRandomEnemy()
    local edge = math.random(1, 4)
    local x, y
    local padding = 50
    
    if edge == 1 then
        x = math.random(padding, self.screenWidth - padding)
        y = padding
    elseif edge == 2 then
        x = self.screenWidth - padding
        y = math.random(padding, self.screenHeight - padding)
    elseif edge == 3 then
        x = math.random(padding, self.screenWidth - padding)
        y = self.screenHeight - padding
    else
        x = padding
        y = math.random(padding, self.screenHeight - padding)
    end
    
    local typeIndex = math.random(1, #ENEMY_TYPES)
    return self:spawnEnemy(x, y, typeIndex)
end

function EnemySystem:update(dt, player, platforms)
    self.spawnTimer = self.spawnTimer + dt
    
    if self.spawnTimer >= self.spawnInterval and #self.enemies < self.maxEnemies then
        self.spawnTimer = 0
        self:spawnRandomEnemy()
    end
    
    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        
        if not enemy.alive then
            table.remove(self.enemies, i)
            continue
        end
        
        if enemy.phaseThrough then
            enemy.flickerTimer = enemy.flickerTimer + dt * enemy.flickerRate
            if enemy.flickerTimer >= 1 then
                enemy.flickerTimer = 0
                enemy.isVisible = not enemy.isVisible
            end
        end
        
        local playerDistX = player.x - enemy.x
        local playerDistY = player.y - enemy.y
        local playerDist = math.sqrt(playerDistX * playerDistX + playerDistY * playerDistY)
        
        if enemy.behavior == "patrol" then
            self:updatePatrol(enemy, dt)
        elseif enemy.behavior == "chase" then
            self:updateChase(enemy, dt, player, playerDist)
        elseif enemy.behavior == "shoot" then
            self:updateShooter(enemy, dt, player, playerDist)
        end
        
        if not enemy.phaseThrough then
            self:applyGravity(enemy, dt, platforms)
        end
        
        enemy.x = enemy.x + enemy.velocityX * dt
        enemy.y = enemy.y + enemy.velocityY * dt
        
        enemy.x = math.max(0, math.min(self.screenWidth - enemy.width, enemy.x))
    end
    
    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        proj.x = proj.x + proj.vx * dt
        proj.y = proj.y + proj.vy * dt
        proj.lifetime = proj.lifetime - dt
        
        if proj.lifetime <= 0 or 
           proj.x < -50 or proj.x > self.screenWidth + 50 or 
           proj.y < -50 or proj.y > self.screenHeight + 50 then
            table.remove(self.projectiles, i)
        end
    end
end

function EnemySystem:updatePatrol(enemy, dt)
    enemy.velocityX = enemy.direction * enemy.speed
    
    if enemy.x <= enemy.startX - enemy.patrolRange then
        enemy.direction = 1
    elseif enemy.x >= enemy.startX + enemy.patrolRange then
        enemy.direction = -1
    end
    
    if enemy.hoverAmplitude > 0 then
        enemy.hoverOffset = enemy.hoverOffset + enemy.hoverSpeed * dt
        enemy.velocityY = math.cos(enemy.hoverOffset) * enemy.hoverSpeed * 10
    end
end

function EnemySystem:updateChase(enemy, dt, player, playerDist)
    if playerDist < enemy.chaseRange and playerDist > 0 then
        local dirX = (player.x - enemy.x) / playerDist
        local dirY = (player.y - enemy.y) / playerDist
        
        if enemy.isCharging then
            enemy.velocityX = dirX * enemy.chargeSpeed
            enemy.velocityY = dirY * enemy.chargeSpeed
            enemy.chargeTimer = enemy.chargeTimer - dt
            
            if enemy.chargeTimer <= 0 then
                enemy.isCharging = false
                enemy.chargeTimer = enemy.chargeCooldown
            end
        else
            enemy.velocityX = dirX * enemy.speed
            enemy.velocityY = dirY * enemy.speed * 0.5
            enemy.chargeTimer = enemy.chargeTimer - dt
            
            if enemy.chargeTimer <= 0 and playerDist < 150 then
                enemy.isCharging = true
            end
        end
    else
        enemy.velocityX = enemy.direction * enemy.speed * 0.5
        if enemy.x <= enemy.startX - enemy.patrolRange then
            enemy.direction = 1
        elseif enemy.x >= enemy.startX + enemy.patrolRange then
            enemy.direction = -1
        end
    end
end

function EnemySystem:updateShooter(enemy, dt, player, playerDist)
    enemy.velocityX = 0
    enemy.velocityY = 0
    
    local currentTime = love.timer.getTime()
    
    if playerDist < enemy.detectionRange then
        if currentTime - enemy.lastFireTime >= enemy.fireRate then
            enemy.lastFireTime = currentTime
            self:fireAtPlayer(enemy, player)
        end
    end
end

function EnemySystem:fireAtPlayer(enemy, player)
    local dx = player.x - enemy.x
    local dy = player.y - enemy.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist > 0 then
        local vx = (dx / dist) * enemy.projectileSpeed
        local vy = (dy / dist) * enemy.projectileSpeed
        
        table.insert(self.projectiles, {
            x = enemy.x + enemy.width / 2,
            y = enemy.y + enemy.height / 2,
            vx = vx,
            vy = vy,
            size = 6,
            damage = enemy.damage,
            color = {unpack(enemy.color)},
            lifetime = 5
        })
    end
end

function EnemySystem:applyGravity(enemy, dt, platforms)
    enemy.velocityY = enemy.velocityY + 500 * dt
    
    if enemy.velocityY > 400 then
        enemy.velocityY = 400
    end
    
    enemy.grounded = false
    
    for _, platform in ipairs(platforms) do
        local bounds = platform.getBounds and platform:getBounds() or {
            left = platform.x,
            right = (platform.x or 0) + (platform.width or 0),
            top = platform.y,
            bottom = (platform.y or 0) + (platform.height or 0)
        }
        
        local prevBottom = enemy.y + enemy.height - enemy.velocityY * dt
        local currBottom = enemy.y + enemy.height
        
        if enemy.x + enemy.width > bounds.left and enemy.x < bounds.right then
            if prevBottom <= bounds.top and currBottom >= bounds.top and enemy.velocityY >= 0 then
                enemy.y = bounds.top - enemy.height
                enemy.velocityY = 0
                enemy.grounded = true
                
                if enemy.behavior == "patrol" or enemy.jumpHeight > 0 then
                    enemy.velocityY = -enemy.jumpHeight * (0.8 + math.random() * 0.4)
                    enemy.grounded = false
                end
            end
        end
    end
end

function EnemySystem:checkPlayerCollision(player)
    local damageTaken = 0
    
    for _, enemy in ipairs(self.enemies) do
        if not enemy.alive then continue end
        if enemy.phaseThrough and not enemy.isVisible then continue end
        
        if self:rectsCollide(player.x, player.y, player.width, player.height,
                             enemy.x, enemy.y, enemy.width, enemy.height) then
            damageTaken = damageTaken + enemy.damage
        end
    end
    
    return damageTaken
end

function EnemySystem:checkProjectileCollision(player)
    local damageTaken = 0
    
    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        
        if self:rectsCollide(player.x, player.y, player.width, player.height,
                            proj.x - proj.size, proj.y - proj.size, 
                            proj.size * 2, proj.size * 2) then
            damageTaken = damageTaken + proj.damage
            table.remove(self.projectiles, i)
        end
    end
    
    return damageTaken
end

function EnemySystem:checkProjectileHit(projectiles)
    local enemiesHit = {}
    
    for _, proj in ipairs(projectiles) do
        for _, enemy in ipairs(self.enemies) do
            if not enemy.alive then continue end
            
            if self:rectsCollide(proj.x - proj.size, proj.y - proj.size, 
                                proj.size * 2, proj.size * 2,
                                enemy.x, enemy.y, enemy.width, enemy.height) then
                if not enemiesHit[enemy] then
                    enemiesHit[enemy] = 0
                end
                enemiesHit[enemy] = enemiesHit[enemy] + proj.damage
            end
        end
    end
    
    local totalScore = 0
    for enemy, damage in pairs(enemiesHit) do
        enemy.health = enemy.health - damage
        if enemy.health <= 0 then
            enemy.alive = false
            totalScore = totalScore + enemy.scoreValue
        end
    end
    
    return totalScore
end

function EnemySystem:rectsCollide(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

function EnemySystem:getEnemies()
    return self.enemies
end

function EnemySystem:getProjectiles()
    return self.projectiles
end

function EnemySystem:getEnemyCount()
    return #self.enemies
end

function EnemySystem:setDifficulty(level)
    self.difficulty = level
    self.maxEnemies = 8 + level * 2
    self.spawnInterval = math.max(2, 5 - level * 0.5)
end

function EnemySystem:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function EnemySystem:draw()
    for _, enemy in ipairs(self.enemies) do
        if not enemy.alive then continue end
        if enemy.phaseThrough and not enemy.isVisible then continue end
        
        local screenX = enemy.x - self.cameraX
        if screenX + enemy.width < -50 or screenX > self.screenWidth + 50 then
            continue
        end
        
        local alpha = enemy.phaseThrough and 0.7 or 1.0
        
        love.graphics.setColor(0, 0, 0, alpha * 0.4)
        love.graphics.ellipse("fill", screenX + enemy.width / 2 + 3, 
                               enemy.y + enemy.height + 5, 
                               enemy.width / 2, 5)
        
        love.graphics.setColor(enemy.color[1] * 0.5, enemy.color[2] * 0.5, enemy.color[3] * 0.5, alpha)
        love.graphics.ellipse("fill", screenX + enemy.width / 2, 
                              enemy.y + enemy.height, 
                              enemy.width / 2 + 4, 8)
        
        love.graphics.setColor(enemy.color[1], enemy.color[2], enemy.color[3], alpha)
        love.graphics.ellipse("fill", screenX + enemy.width / 2, 
                              enemy.y + enemy.height / 2 + 5, 
                              enemy.width / 2, enemy.height / 2)
        
        love.graphics.setColor(math.min(1, enemy.color[1] + 0.2), 
                               math.min(1, enemy.color[2] + 0.2), 
                               math.min(1, enemy.color[3] + 0.2), alpha)
        love.graphics.ellipse("fill", screenX + enemy.width / 2, 
                              enemy.y + enemy.height / 2 - 5, 
                              enemy.width / 3, enemy.height / 3)
        
        if enemy.behavior == "shoot" then
            love.graphics.setColor(1, 0.3, 0.3, alpha)
            love.graphics.circle("fill", screenX + enemy.width / 2, 
                                 enemy.y + enemy.height / 3, 4)
        end
        
        if enemy.isCharging then
            love.graphics.setColor(1, 1, 0, 0.3)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", screenX + enemy.width / 2, 
                                enemy.y + enemy.height / 2, 
                                enemy.width, love.timer.getTime() * 10 % math.pi * 2)
        end
        
        if enemy.health < enemy.maxHealth then
            local barWidth = enemy.width
            local barHeight = 4
            local barX = screenX
            local barY = enemy.y - 10
            local healthPercent = enemy.health / enemy.maxHealth
            
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
            love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 2, 2)
            
            love.graphics.setColor(1, 0.3, 0.3, 1)
            love.graphics.rectangle("fill", barX, barY, barWidth * healthPercent, barHeight, 2, 2)
        end
    end
    
    for _, proj in ipairs(self.projectiles) do
        local projScreenX = proj.x - self.cameraX
        love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3])
        love.graphics.circle("fill", projScreenX, proj.y, proj.size)
        
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("fill", projScreenX, proj.y, proj.size * 0.4)
        
        love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3], 0.3)
        love.graphics.circle("fill", projScreenX, proj.y, proj.size * 1.5)
    end
end

function EnemySystem:reset()
    self.enemies = {}
    self.projectiles = {}
    self.spawnTimer = 0
    self.difficulty = 1
end

return EnemySystem
