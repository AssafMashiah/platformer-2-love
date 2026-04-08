ProjectileSystem = {}
ProjectileSystem.__index = ProjectileSystem

local PROJECTILE_PRESETS = {
    player_bullet = {
        color = {1, 0.2, 0.2},
        glowColor = {1, 0.5, 0.3},
        size = 5,
        shape = "circle",
        hasTrail = true,
        trailLength = 5
    },
    player_laser = {
        color = {0.2, 0.8, 1},
        glowColor = {0.5, 1, 1},
        size = 3,
        shape = "line",
        hasTrail = true,
        trailLength = 8
    },
    player_heavy = {
        color = {1, 0.6, 0.1},
        glowColor = {1, 0.8, 0.3},
        size = 8,
        shape = "circle",
        hasTrail = true,
        trailLength = 6
    },
    enemy_bullet = {
        color = {0.8, 0.2, 0.8},
        glowColor = {1, 0.5, 1},
        size = 6,
        shape = "circle",
        hasTrail = true,
        trailLength = 4
    },
    enemy_laser = {
        color = {0.6, 0.2, 1},
        glowColor = {0.8, 0.5, 1},
        size = 4,
        shape = "line",
        hasTrail = true,
        trailLength = 10
    },
    slime_projectile = {
        color = {0.2, 0.8, 0.3},
        glowColor = {0.5, 1, 0.5},
        size = 7,
        shape = "circle",
        hasTrail = true,
        trailLength = 3
    },
    bat_projectile = {
        color = {0.6, 0.2, 0.8},
        glowColor = {0.8, 0.5, 1},
        size = 5,
        shape = "circle",
        hasTrail = true,
        trailLength = 5
    },
    turret_projectile = {
        color = {0.8, 0.4, 0.1},
        glowColor = {1, 0.6, 0.2},
        size = 6,
        shape = "circle",
        hasTrail = true,
        trailLength = 6
    }
}

function ProjectileSystem:new()
    local instance = setmetatable({}, self)
    instance.projectiles = {}
    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.graphicsCache = {}
    return instance
end

function ProjectileSystem:createProjectile(config)
    local preset = PROJECTILE_PRESETS[config.preset] or PROJECTILE_PRESETS.player_bullet
    
    local projectile = {
        x = config.x or 0,
        y = config.y or 0,
        vx = config.vx or 0,
        vy = config.vy or 0,
        size = config.size or preset.size,
        damage = config.damage or 10,
        owner = config.owner or "player",
        isPlayerOwned = config.owner == "player",
        color = config.color or {unpack(preset.color)},
        glowColor = config.glowColor or {unpack(preset.glowColor)},
        shape = preset.shape,
        hasTrail = preset.hasTrail,
        trailLength = preset.trailLength or 5,
        trail = {},
        lifetime = config.lifetime or 5,
        maxLifetime = config.lifetime or 5,
        rotation = math.atan2(config.vy or 0, config.vx or 0),
        piercing = config.piercing or false,
        hitsRemaining = config.piercing and (config.maxHits or 3) or 1
    }
    
    return projectile
end

function ProjectileSystem:fire(config)
    local preset = PROJECTILE_PRESETS[config.preset] or PROJECTILE_PRESETS.player_bullet
    local count = config.count or 1
    local spread = config.spread or 0.15
    local baseAngle = math.atan2(config.dirY or 0, config.dirX or 1)
    
    for i = 1, count do
        local angle = baseAngle
        
        if count > 1 then
            angle = baseAngle + (i - (count + 1) / 2) * spread
        end
        
        local speed = config.speed or 600
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        local projectile = self:createProjectile({
            x = config.x,
            y = config.y,
            vx = vx,
            vy = vy,
            damage = config.damage,
            owner = config.owner,
            preset = config.preset,
            size = config.size,
            color = config.color,
            glowColor = config.glowColor,
            lifetime = config.lifetime,
            piercing = config.piercing,
            maxHits = config.maxHits
        })
        
        table.insert(self.projectiles, projectile)
    end
end

function ProjectileSystem:fireAtPoint(config)
    local dx = config.targetX - config.x
    local dy = config.targetY - config.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    if dist > 0 then
        config.dirX = dx / dist
        config.dirY = dy / dist
    else
        config.dirX = 1
        config.dirY = 0
    end
    
    return self:fire(config)
end

function ProjectileSystem:update(dt)
    local deadProjectiles = {}
    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        
        proj.x = proj.x + proj.vx * dt
        proj.y = proj.y + proj.vy * dt
        proj.lifetime = proj.lifetime - dt
        
        if proj.hasTrail then
            table.insert(proj.trail, 1, {x = proj.x, y = proj.y, alpha = 1})
            
            while #proj.trail > proj.trailLength do
                table.remove(proj.trail)
            end
            
            for j, point in ipairs(proj.trail) do
                point.alpha = 1 - (j - 1) / proj.trailLength
            end
        end
        
        if proj.lifetime <= 0 or 
           proj.x < -50 or proj.x > self.screenWidth + 50 or 
           proj.y < -50 or proj.y > self.screenHeight + 50 or
           proj.hitsRemaining <= 0 then
            table.insert(deadProjectiles, i)
        end
    end
    
    for _, idx in ipairs(deadProjectiles) do
        table.remove(self.projectiles, idx)
    end
end

function ProjectileSystem:checkCollisionWithRect(targetX, targetY, targetWidth, targetHeight, owner)
    local hitProjectiles = {}
    
    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        
        if proj.owner ~= owner then
            if self:rectsCollide(proj.x - proj.size, proj.y - proj.size,
                                proj.size * 2, proj.size * 2,
                                targetX, targetY, targetWidth, targetHeight) then
                table.insert(hitProjectiles, {
                    projectile = proj,
                    index = i,
                    damage = proj.damage
                })
                
                proj.hitsRemaining = proj.hitsRemaining - 1
            end
        end
    end
    
    return hitProjectiles
end

function ProjectileSystem:checkCollisionWithEntity(entity, owner)
    if not entity or not entity.x or not entity.y then
        return nil
    end
    
    local width = entity.width or (entity.size and entity.size * 2) or 32
    local height = entity.height or (entity.size and entity.size * 2) or 32
    
    return self:checkCollisionWithRect(entity.x, entity.y, width, height, owner)
end

function ProjectileSystem:checkPlayerProjectilesVsEnemies(enemies)
    local enemiesHit = {}
    local totalScore = 0
    
    for _, proj in ipairs(self.projectiles) do
        if proj.isPlayerOwned then
            for _, enemy in ipairs(enemies) do
                if enemy.alive then
                    local enemyWidth = enemy.width or (enemy.size and enemy.size * 2) or 32
                    local enemyHeight = enemy.height or (enemy.size and enemy.size * 2) or 32
                    
                    if self:rectsCollide(proj.x - proj.size, proj.y - proj.size,
                                        proj.size * 2, proj.size * 2,
                                        enemy.x, enemy.y, enemyWidth, enemyHeight) then
                        
                        if not enemiesHit[enemy] then
                            enemiesHit[enemy] = 0
                        end
                        enemiesHit[enemy] = enemiesHit[enemy] + proj.damage
                        
                        if not proj.piercing then
                            proj.hitsRemaining = 0
                        end
                    end
                end
            end
        end
    end
    
    for enemy, damage in pairs(enemiesHit) do
        enemy.health = (enemy.health or 100) - damage
        if enemy.health <= 0 then
            enemy.alive = false
            totalScore = totalScore + (enemy.scoreValue or 100)
        end
    end
    
    return totalScore
end

function ProjectileSystem:checkEnemyProjectilesVsPlayer(player)
    local damageTaken = 0
    
    for _, proj in ipairs(self.projectiles) do
        if not proj.isPlayerOwned then
            if self:rectsCollide(proj.x - proj.size, proj.y - proj.size,
                                proj.size * 2, proj.size * 2,
                                player.x, player.y, player.width or 32, player.height or 32) then
                damageTaken = damageTaken + proj.damage
                proj.hitsRemaining = 0
            end
        end
    end
    
    return damageTaken
end

function ProjectileSystem:removeProjectile(index)
    if index and self.projectiles[index] then
        table.remove(self.projectiles, index)
    end
end

function ProjectileSystem:removeProjectilesByOwner(owner)
    for i = #self.projectiles, 1, -1 do
        if self.projectiles[i].owner == owner then
            table.remove(self.projectiles, i)
        end
    end
end

function ProjectileSystem:clearPlayerProjectiles()
    for i = #self.projectiles, 1, -1 do
        if self.projectiles[i].isPlayerOwned then
            table.remove(self.projectiles, i)
        end
    end
end

function ProjectileSystem:clearEnemyProjectiles()
    for i = #self.projectiles, 1, -1 do
        if not self.projectiles[i].isPlayerOwned then
            table.remove(self.projectiles, i)
        end
    end
end

function ProjectileSystem:rectsCollide(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

function ProjectileSystem:getProjectiles()
    return self.projectiles
end

function ProjectileSystem:getPlayerProjectiles()
    local playerProjectiles = {}
    for _, proj in ipairs(self.projectiles) do
        if proj.isPlayerOwned then
            table.insert(playerProjectiles, proj)
        end
    end
    return playerProjectiles
end

function ProjectileSystem:getEnemyProjectiles()
    local enemyProjectiles = {}
    for _, proj in ipairs(self.projectiles) do
        if not proj.isPlayerOwned then
            table.insert(enemyProjectiles, proj)
        end
    end
    return enemyProjectiles
end

function ProjectileSystem:getProjectileCount()
    return #self.projectiles
end

function ProjectileSystem:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function ProjectileSystem:setLevelBounds(start, levelEnd)
    self.levelStart = start
    self.levelEnd = levelEnd
end

function ProjectileSystem:setCameraX(camX)
    self.cameraX = camX
end

function ProjectileSystem:draw()
    local camX = self.cameraX or 0
    for _, proj in ipairs(self.projectiles) do
        local screenX = proj.x - camX
        if screenX >= -100 and screenX <= self.screenWidth + 100 then
            self:drawProjectile(proj, screenX)
        end
    end
end

function ProjectileSystem:drawProjectile(proj, screenX)
    local camX = self.cameraX or 0
    screenX = screenX or (proj.x - camX)
    if proj.hasTrail then
        for i, point in ipairs(proj.trail) do
            local trailSize = proj.size * (1 - (i - 1) / proj.trailLength) * 0.7
            
            love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3], point.alpha * 0.4)
            love.graphics.circle("fill", point.x - camX, point.y, trailSize)
        end
    end
    
    love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3], 0.3)
    love.graphics.circle("fill", screenX, proj.y, proj.size * 2)
    
    love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3], 0.6)
    love.graphics.circle("fill", screenX, proj.y, proj.size * 1.3)
    
    love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3])
    if proj.shape == "line" then
        local length = proj.size * 3
        local endX = screenX - math.cos(proj.rotation) * length
        local endY = proj.y - math.sin(proj.rotation) * length
        love.graphics.setLineWidth(proj.size * 0.6)
        love.graphics.line(screenX, proj.y, endX, endY)
    else
        love.graphics.circle("fill", screenX, proj.y, proj.size)
    end
    
    love.graphics.setColor(1, 1, 1, 0.8)
    if proj.shape == "line" then
        local length = proj.size * 1.5
        local endX = screenX - math.cos(proj.rotation) * length
        local endY = proj.y - math.sin(proj.rotation) * length
        love.graphics.setLineWidth(proj.size * 0.3)
        love.graphics.line(screenX, proj.y, endX, endY)
    else
        love.graphics.circle("fill", screenX, proj.y, proj.size * 0.4)
    end
    
    love.graphics.setColor(proj.glowColor[1], proj.glowColor[2], proj.glowColor[3], 0.2)
    love.graphics.circle("fill", screenX, proj.y, proj.size * 2.5)
end

function ProjectileSystem:reset()
    self.projectiles = {}
end

return ProjectileSystem
