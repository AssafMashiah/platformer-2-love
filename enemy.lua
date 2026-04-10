EnemySystem = {}
EnemySystem.__index = EnemySystem

local GRAVITY = 1000
local TERMINAL_VELOCITY = 600

local ENEMY_TYPES = {
    {
        name = "Slime",
        color = {0.2, 0.8, 0.3},
        size = 20,
        speed = 60,
        health = 30,
        damage = 10,
        behavior = "patrol",
        hasGravity = true,
        hasCollision = true,
        jumpForce = 350,
        patrolRange = 150,
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
        hasGravity = false,
        hasCollision = false,
        chaseRange = 250,
        hoverAmplitude = 30,
        hoverSpeed = 3,
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
        hasGravity = true,
        hasCollision = true,
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
        hasGravity = true,
        hasCollision = true,
        chaseRange = 300,
        chargeSpeed = 180,
        chargeCooldown = 3,
        jumpForce = 350,
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
        hasGravity = false,
        hasCollision = false,
        phaseThrough = true,
        flickerRate = 5,
        patrolRange = 150,
        scoreValue = 175
    }
}

function EnemySystem:new()
    local instance = setmetatable({}, self)
    instance.enemies = {}
    instance.projectiles = {}
    instance.spawnTimer = 0
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

    local diff = 0.8 + self.difficulty * 0.2
    local enemy = {
        x = x,
        y = y,
        width = enemyData.size * 2,
        height = enemyData.size * 2,
        name = enemyData.name,
        color = {unpack(enemyData.color)},
        size = enemyData.size,
        speed = enemyData.speed * diff,
        health = enemyData.health * diff,
        maxHealth = enemyData.health * diff,
        damage = enemyData.damage * diff,
        behavior = enemyData.behavior,
        scoreValue = enemyData.scoreValue,

        hasGravity = enemyData.hasGravity or false,
        hasCollision = enemyData.hasCollision or false,

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
        jumpForce = enemyData.jumpForce or 0,
        chargeCooldown = enemyData.chargeCooldown or 3,
        chargeSpeed = enemyData.chargeSpeed or 0,
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

function EnemySystem:spawnLevelEnemies(platforms)
    self.enemies = {}
    self.projectiles = {}
    self.spawnTimer = 0

    local count = math.min(3 + math.floor(self.difficulty), self.maxEnemies)

    for i = 1, count do
        local typeIndex = math.random(1, #ENEMY_TYPES)
        local enemyData = ENEMY_TYPES[typeIndex]

        local platform = platforms[math.random(1, #platforms)]
        local x = platform.x + math.random(0, math.max(0, platform.width - enemyData.size * 2))
        local y = platform.y - enemyData.size * 2

        if not enemyData.hasGravity then
            x = math.random(self.levelStart + 50, self.levelEnd - 150)
            y = math.random(50, self.screenHeight - 150)
        end

        self:spawnEnemy(x, y, typeIndex)
    end
end

function EnemySystem:update(dt, player, platforms)
    for i = #self.enemies, 1, -1 do
        if not self.enemies[i].alive then
            table.remove(self.enemies, i)
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if enemy.phaseThrough and enemy.flickerRate then
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
            self:updatePatrol(enemy, dt, platforms, player, playerDist)
        elseif enemy.behavior == "chase" then
            self:updateChase(enemy, dt, player, playerDist)
        elseif enemy.behavior == "shoot" then
            self:updateShooter(enemy, dt, player, playerDist)
        end

        if enemy.hasGravity then
            enemy.velocityY = enemy.velocityY + GRAVITY * dt
            if enemy.velocityY > TERMINAL_VELOCITY then
                enemy.velocityY = TERMINAL_VELOCITY
            end
        end

        local prevY = enemy.y

        enemy.x = enemy.x + enemy.velocityX * dt
        enemy.y = enemy.y + enemy.velocityY * dt

        enemy.grounded = false
        if enemy.hasCollision then
            self:resolveCollisions(enemy, prevY, platforms)
        end

        if enemy.x < self.levelStart then
            enemy.x = self.levelStart
            enemy.direction = 1
        elseif enemy.x + enemy.width > self.levelEnd then
            enemy.x = self.levelEnd - enemy.width
            enemy.direction = -1
        end

        if not enemy.hasGravity then
            if enemy.y < 0 then
                enemy.y = 0
                enemy.velocityY = math.abs(enemy.velocityY)
            elseif enemy.y + enemy.height > self.screenHeight then
                enemy.y = self.screenHeight - enemy.height
                enemy.velocityY = -math.abs(enemy.velocityY)
            end
        end

        if enemy.hasGravity and enemy.y > self.screenHeight + 200 then
            enemy.y = 0
            enemy.velocityY = 0
        end
    end

    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        proj.x = proj.x + proj.vx * dt
        proj.y = proj.y + proj.vy * dt
        proj.lifetime = proj.lifetime - dt

        if proj.lifetime <= 0 or
           proj.x < self.levelStart - 50 or proj.x > self.levelEnd + 50 or
           proj.y < -50 or proj.y > self.screenHeight + 50 then
            table.remove(self.projectiles, i)
        end
    end
end

function EnemySystem:resolveCollisions(enemy, prevY, platforms)
    local prevBottom = prevY + enemy.height
    local currBottom = enemy.y + enemy.height

    for _, platform in ipairs(platforms) do
        if enemy.x + enemy.width > platform.x and enemy.x < platform.x + platform.width then
            if prevBottom <= platform.y + 4 and currBottom >= platform.y then
                enemy.y = platform.y - enemy.height
                enemy.velocityY = 0
                enemy.grounded = true
            end
        end
    end
end

function EnemySystem:checkGroundAhead(enemy, platforms)
    local checkX
    if enemy.direction > 0 then
        checkX = enemy.x + enemy.width + 5
    else
        checkX = enemy.x - 5
    end
    local checkY = enemy.y + enemy.height + 10

    for _, platform in ipairs(platforms) do
        if checkX >= platform.x and checkX <= platform.x + platform.width and
           checkY >= platform.y and checkY <= platform.y + 15 then
            return true
        end
    end
    return false
end

function EnemySystem:updatePatrol(enemy, dt, platforms, player, playerDist)
    enemy.velocityX = enemy.direction * enemy.speed

    if enemy.x <= enemy.startX - enemy.patrolRange then
        enemy.direction = 1
    elseif enemy.x >= enemy.startX + enemy.patrolRange then
        enemy.direction = -1
    end

    if enemy.hasGravity then
        if enemy.grounded and enemy.jumpForce > 0 then
            if not self:checkGroundAhead(enemy, platforms) then
                enemy.velocityY = -enemy.jumpForce
                enemy.grounded = false
            end
        end
    else
        if enemy.hoverAmplitude > 0 then
            enemy.hoverOffset = enemy.hoverOffset + enemy.hoverSpeed * dt
            enemy.velocityY = math.cos(enemy.hoverOffset) * enemy.hoverAmplitude
        end

        if enemy.phaseThrough and playerDist < 250 and playerDist > 0 then
            local dx = player.x - enemy.x
            local dy = player.y - enemy.y
            enemy.velocityX = enemy.velocityX + (dx / playerDist) * enemy.speed * 0.3
            enemy.velocityY = enemy.velocityY + (dy / playerDist) * enemy.speed * 0.2
        end
    end
end

function EnemySystem:updateChase(enemy, dt, player, playerDist)
    if playerDist < enemy.chaseRange and playerDist > 0 then
        local dirX = (player.x - enemy.x) / playerDist

        if enemy.hasGravity then
            if enemy.isCharging and enemy.chargeSpeed > 0 then
                enemy.velocityX = dirX * enemy.chargeSpeed
                enemy.chargeTimer = enemy.chargeTimer - dt
                if enemy.chargeTimer <= 0 then
                    enemy.isCharging = false
                    enemy.chargeTimer = enemy.chargeCooldown
                end
            else
                enemy.velocityX = dirX * enemy.speed
                if enemy.chargeSpeed and enemy.chargeSpeed > 0 then
                    enemy.chargeTimer = enemy.chargeTimer - dt
                    if enemy.chargeTimer <= 0 and playerDist < 150 then
                        enemy.isCharging = true
                    end
                end
                if enemy.grounded and player.y < enemy.y - 30 and enemy.jumpForce > 0 then
                    enemy.velocityY = -enemy.jumpForce
                    enemy.grounded = false
                end
            end
            enemy.direction = dirX > 0 and 1 or -1
        else
            local dirY = (player.y - enemy.y) / playerDist
            enemy.velocityX = dirX * enemy.speed
            enemy.velocityY = dirY * enemy.speed

            if enemy.hoverAmplitude > 0 then
                enemy.hoverOffset = enemy.hoverOffset + enemy.hoverSpeed * dt
                enemy.velocityY = enemy.velocityY + math.cos(enemy.hoverOffset) * enemy.hoverAmplitude
            end
        end
    else
        enemy.velocityX = enemy.direction * enemy.speed * 0.5
        if enemy.x <= enemy.startX - (enemy.patrolRange or 100) then
            enemy.direction = 1
        elseif enemy.x >= enemy.startX + (enemy.patrolRange or 100) then
            enemy.direction = -1
        end

        if not enemy.hasGravity and enemy.hoverAmplitude then
            enemy.hoverOffset = enemy.hoverOffset + enemy.hoverSpeed * dt
            enemy.velocityY = math.cos(enemy.hoverOffset) * enemy.hoverAmplitude
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

function EnemySystem:checkPlayerCollision(player)
    local damageTaken = 0

    for _, enemy in ipairs(self.enemies) do
        if enemy.alive then
            if not enemy.phaseThrough or enemy.isVisible then
                if self:rectsCollide(player.x, player.y, player.width, player.height,
                                     enemy.x, enemy.y, enemy.width, enemy.height) then
                    damageTaken = damageTaken + enemy.damage
                end
            end
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
            if enemy.alive then
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
end

function EnemySystem:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function EnemySystem:draw()
    for _, enemy in ipairs(self.enemies) do
        if enemy.alive then
            if not enemy.phaseThrough or enemy.isVisible then
                local screenX = enemy.x - self.cameraX
                if screenX + enemy.width >= -50 and screenX <= self.screenWidth + 50 then
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
            end
        end
    end

    for _, proj in ipairs(self.projectiles) do
        local projScreenX = proj.x - self.cameraX
        if projScreenX >= -50 and projScreenX <= self.screenWidth + 50 then
            love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3])
            love.graphics.circle("fill", projScreenX, proj.y, proj.size)

            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.circle("fill", projScreenX, proj.y, proj.size * 0.4)

            love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3], 0.3)
            love.graphics.circle("fill", projScreenX, proj.y, proj.size * 1.5)
        end
    end
end

function EnemySystem:reset()
    self.enemies = {}
    self.projectiles = {}
    self.spawnTimer = 0
    self.difficulty = 1
end

return EnemySystem
