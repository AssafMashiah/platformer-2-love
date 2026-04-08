WeaponSystem = {}
WeaponSystem.__index = WeaponSystem

local WEAPON_TYPES = {
    {
        name = "Pew Pew",
        color = {1, 0.2, 0.2},
        size = 4,
        fireRate = 0.15,
        damage = 10,
        projectileSpeed = 600,
        projectileCount = 1
    },
    {
        name = "Triple Shot",
        color = {0.2, 0.8, 1},
        size = 5,
        fireRate = 0.25,
        damage = 8,
        projectileSpeed = 500,
        projectileCount = 3
    },
    {
        name = "Heavy Blaster",
        color = {1, 0.6, 0.1},
        size = 8,
        fireRate = 0.5,
        damage = 35,
        projectileSpeed = 400,
        projectileCount = 1
    },
    {
        name = "Rapid Fire",
        color = {0.4, 1, 0.4},
        size = 3,
        fireRate = 0.05,
        damage = 5,
        projectileSpeed = 700,
        projectileCount = 1
    },
    {
        name = "Scatter Gun",
        color = {1, 0.3, 0.8},
        size = 6,
        fireRate = 0.4,
        damage = 12,
        projectileSpeed = 450,
        projectileCount = 5
    },
    {
        name = "Laser Beam",
        color = {0.6, 0.2, 1},
        size = 3,
        fireRate = 0.1,
        damage = 15,
        projectileSpeed = 900,
        projectileCount = 1
    }
}

function WeaponSystem:new()
    local instance = setmetatable({}, self)
    instance.currentWeapon = instance:generateRandomWeapon()
    instance.lastFireTime = 0
    instance.canFire = true
    instance.projectiles = {}
    instance.pickups = {}
    instance.pickupSpawnTimer = 0
    instance.pickupSpawnInterval = 10
    return instance
end

function WeaponSystem:generateRandomWeapon()
    local weaponData = WEAPON_TYPES[math.random(1, #WEAPON_TYPES)]
    return {
        name = weaponData.name,
        color = {unpack(weaponData.color)},
        size = weaponData.size,
        fireRate = weaponData.fireRate,
        damage = weaponData.damage,
        projectileSpeed = weaponData.projectileSpeed,
        projectileCount = weaponData.projectileCount
    }
end

function WeaponSystem:generatePickup(x, y)
    local weaponData = WEAPON_TYPES[math.random(1, #WEAPON_TYPES)]
    return {
        x = x,
        y = y,
        width = 24,
        height = 24,
        weapon = {
            name = weaponData.name,
            color = {unpack(weaponData.color)},
            size = weaponData.size,
            fireRate = weaponData.fireRate,
            damage = weaponData.damage,
            projectileSpeed = weaponData.projectileSpeed,
            projectileCount = weaponData.projectileCount
        },
        bobOffset = 0,
        bobSpeed = 3
    }
end

function WeaponSystem:spawnPickup(x, y)
    table.insert(self.pickups, self:generatePickup(x, y))
end

function WeaponSystem:update(dt, screenWidth, screenHeight)
    self.pickupSpawnTimer = self.pickupSpawnTimer + dt
    
    if self.pickupSpawnTimer >= self.pickupSpawnInterval then
        self.pickupSpawnTimer = 0
        local x = math.random(50, screenWidth - 50)
        local y = math.random(50, screenHeight - 200)
        self:spawnPickup(x, y)
    end
    
    for i = #self.pickups, 1, -1 do
        local pickup = self.pickups[i]
        pickup.bobOffset = pickup.bobOffset + pickup.bobSpeed * dt
    end
    
    for i = #self.projectiles, 1, -1 do
        local proj = self.projectiles[i]
        proj.x = proj.x + proj.vx * dt
        proj.y = proj.y + proj.vy * dt
        
        if proj.x < -50 or proj.x > screenWidth + 50 or 
           proj.y < -50 or proj.y > screenHeight + 50 then
            table.remove(self.projectiles, i)
        end
    end
end

function WeaponSystem:fire(x, y, directionX, directionY, currentTime)
    if not self.canFire then return {} end
    
    if currentTime - self.lastFireTime < self.currentWeapon.fireRate then
        return {}
    end
    
    self.lastFireTime = currentTime
    local newProjectiles = {}
    
    local count = self.currentWeapon.projectileCount
    local spread = 0.15
    
    for i = 1, count do
        local angle = math.atan2(directionY, directionX)
        
        if count > 1 then
            local offset = (i - (count + 1) / 2) * spread
            angle = angle + offset
        end
        
        local vx = math.cos(angle) * self.currentWeapon.projectileSpeed
        local vy = math.sin(angle) * self.currentWeapon.projectileSpeed
        
        table.insert(newProjectiles, {
            x = x,
            y = y,
            vx = vx,
            vy = vy,
            size = self.currentWeapon.size,
            damage = self.currentWeapon.damage,
            color = self.currentWeapon.color
        })
        
        table.insert(self.projectiles, newProjectiles[#newProjectiles])
    end
    
    return newProjectiles
end

function WeaponSystem:checkPickupCollision(playerX, playerY, playerWidth, playerHeight)
    local collected = nil
    
    for i = #self.pickups, 1, -1 do
        local pickup = self.pickups[i]
        local pickupY = pickup.y + math.sin(pickup.bobOffset) * 5
        
        if playerX < pickup.x + pickup.width and
           playerX + playerWidth > pickup.x and
           playerY < pickupY + pickup.height and
           playerY + playerHeight > pickupY then
            collected = pickup.weapon
            table.remove(self.pickups, i)
            break
        end
    end
    
    if collected then
        self.currentWeapon = collected
    end
    
    return collected
end

function WeaponSystem:getProjectiles()
    return self.projectiles
end

function WeaponSystem:getPickups()
    return self.pickups
end

function WeaponSystem:getCurrentWeapon()
    return self.currentWeapon
end

function WeaponSystem:drawHUD()
    local weapon = self.currentWeapon
    local padding = 10
    local hudX = padding
    local hudY = padding
    local boxWidth = 180
    local boxHeight = 50
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", hudX, hudY, boxWidth, boxHeight, 5, 5)
    
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", hudX, hudY, boxWidth, boxHeight, 5, 5)
    
    love.graphics.setColor(weapon.color[1], weapon.color[2], weapon.color[3])
    love.graphics.circle("fill", hudX + 25, hudY + 25, 12)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print(weapon.name, hudX + 45, hudY + 10)
    
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(10))
    local stats = string.format("DMG: %d  SPD: %d", weapon.damage, math.floor(weapon.projectileSpeed / 10))
    love.graphics.print(stats, hudX + 45, hudY + 28)
    
    love.graphics.setColor(0.5, 0.9, 0.5)
    local cooldownWidth = 100
    local cooldownHeight = 6
    local cooldownX = hudX + 40
    local cooldownY = hudY + boxHeight - 12
    
    love.graphics.rectangle("fill", cooldownX, cooldownY, cooldownWidth, cooldownHeight, 2, 2)
end

function WeaponSystem:drawPickups()
    for _, pickup in ipairs(self.pickups) do
        local y = pickup.y + math.sin(pickup.bobOffset) * 5
        
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", pickup.x + 2, y + 2, pickup.width, pickup.height, 4, 4)
        
        love.graphics.setColor(pickup.weapon.color[1], pickup.weapon.color[2], pickup.weapon.color[3], 0.3)
        love.graphics.rectangle("fill", pickup.x, y, pickup.width, pickup.height, 4, 4)
        
        love.graphics.setColor(pickup.weapon.color[1], pickup.weapon.color[2], pickup.weapon.color[3])
        love.graphics.rectangle("fill", pickup.x, y, pickup.width, pickup.height, 4, 4)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(8))
        love.graphics.printf("?", pickup.x, y + 6, pickup.width, "center")
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf(pickup.weapon.name, pickup.x - 10, y + pickup.height + 5, pickup.width + 20, "center")
    end
end

function WeaponSystem:drawProjectiles()
    for _, proj in ipairs(self.projectiles) do
        love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3])
        love.graphics.circle("fill", proj.x, proj.y, proj.size)
        
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", proj.x, proj.y, proj.size * 0.5)
    end
end

function WeaponSystem:removeProjectile(index)
    if index and self.projectiles[index] then
        table.remove(self.projectiles, index)
    end
end

function WeaponSystem:reset()
    self.projectiles = {}
    self.pickups = {}
    self.pickupSpawnTimer = 0
    self.currentWeapon = self:generateRandomWeapon()
    self.lastFireTime = 0
end

return WeaponSystem
