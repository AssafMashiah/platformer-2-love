Player = {}
Player.__index = Player

Player.WIDTH = 32
Player.HEIGHT = 32
Player.SPEED = 250
Player.JUMP_FORCE = 400
Player.GRAVITY = 1000
Player.MAX_FALL_SPEED = 600

function Player:new()
    local instance = setmetatable({}, self)
    instance.x = 400
    instance.y = 400
    instance.width = Player.WIDTH
    instance.height = Player.HEIGHT
    instance.speed = Player.SPEED
    instance.jumpForce = Player.JUMP_FORCE
    instance.velocityX = 0
    instance.velocityY = 0
    instance.grounded = false
    instance.facingX = 1
    instance.facingY = 0
    instance.invulnerable = false
    instance.invulnerableTimer = 0
    instance.invulnerableDuration = 1.5
    
    instance.maxHealth = 3
    instance.currentHealth = 3
    instance.healthPerHeart = 34
    
    instance.maxLives = 3
    instance.lives = 3
    
    instance.respawnX = 400
    instance.respawnY = 400
    instance.screenWidth = 800
    instance.screenHeight = 600
    
    instance.eyeOffsetX = 0
    instance.eyeOffsetY = 0
    
    return instance
end

function Player:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function Player:setRespawnPoint(x, y)
    self.respawnX = x
    self.respawnY = y
end

function Player:update(dt)
    local dx = 0
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = dx - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = dx + 1
    end
    
    self.velocityX = dx * self.speed
    
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown(" ")) and self.grounded then
        self.velocityY = -self.jumpForce
        self.grounded = false
    end
    
    self.velocityY = self.velocityY + Player.GRAVITY * dt
    if self.velocityY > Player.MAX_FALL_SPEED then
        self.velocityY = Player.MAX_FALL_SPEED
    end
    
    if dx ~= 0 then
        local len = math.sqrt(dx * dx)
        if len > 0 then
            self.facingX = dx / len
        end
    end
    
    self.x = self.x + self.velocityX * dt
    self.y = self.y + self.velocityY * dt
    
    self.x = math.max(0, math.min(self.screenWidth - self.width, self.x))
    
    if self.y > self.screenHeight then
        self:loseLife()
        return false
    end
    
    return true
end

function Player:checkPlatformCollision(platforms)
    self.grounded = false
    
    for _, platform in ipairs(platforms) do
        local platformBounds = platform.getBounds and platform:getBounds() or {
            left = platform.x,
            right = platform.x + platform.width,
            top = platform.y,
            bottom = platform.y + platform.height
        }
        
        local prevBottom = self.y + self.height - self.velocityY * dt
        local currBottom = self.y + self.height
        
        if self.x + self.width > platformBounds.left and self.x < platformBounds.right then
            if prevBottom <= platformBounds.top and currBottom >= platformBounds.top then
                self.y = platformBounds.top - self.height
                self.velocityY = 0
                self.grounded = true
            end
        end
    end
    
    return self.grounded
end

function Player:takeDamage(amount)
    if self.invulnerable then
        return false
    end
    
    self.currentHealth = self.currentHealth - amount
    self.invulnerable = true
    self.invulnerableTimer = self.invulnerableDuration
    
    if self.currentHealth <= 0 then
        self:loseLife()
        return true
    end
    
    return false
end

function Player:loseLife()
    self.lives = self.lives - 1
    
    if self.lives > 0 then
        self.x = self.respawnX
        self.y = self.respawnY
        self.velocityX = 0
        self.velocityY = 0
        self.currentHealth = self.maxHealth
        self.invulnerable = true
        self.invulnerableTimer = self.invulnerableDuration * 2
    end
end

function Player:isAlive()
    return self.lives > 0
end

function Player:isDead()
    return self.lives <= 0
end

function Player:updateInvulnerability(dt)
    if self.invulnerable then
        self.invulnerableTimer = self.invulnerableTimer - dt
        if self.invulnerableTimer <= 0 then
            self.invulnerable = false
        end
    end
end

function Player:getHealth()
    return self.currentHealth
end

function Player:getMaxHealth()
    return self.maxHealth
end

function Player:getLives()
    return self.lives
end

function Player:getMaxLives()
    return self.maxLives
end

function Player:getPosition()
    return self.x, self.y
end

function Player:getCenter()
    return self.x + self.width / 2, self.y + self.height / 2
end

function Player:getBounds()
    return {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        left = self.x,
        right = self.x + self.width,
        top = self.y,
        bottom = self.y + self.height
    }
end

function Player:draw()
    if self.invulnerable and math.floor(love.timer.getTime() * 10) % 2 == 0 then
        return
    end
    
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.ellipse("fill", self.x + self.width / 2 + 2, 
                           self.y + self.height + 2, 
                           self.width / 2 + 2, 6)
    
    love.graphics.setColor(0.2, 0.5, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)
    
    love.graphics.setColor(0.4, 0.7, 1)
    love.graphics.rectangle("fill", self.x + 2, self.y + 2, self.width - 4, self.height / 3, 3, 3)
    
    local eyeOffsetX = self.facingX * 4
    local eyeOffsetY = self.facingY * 2
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", self.x + self.width / 2 - 5 + eyeOffsetX, 
                         self.y + self.height / 3 + eyeOffsetY, 4)
    love.graphics.circle("fill", self.x + self.width / 2 + 5 + eyeOffsetX, 
                         self.y + self.height / 3 + eyeOffsetY, 4)
    
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.circle("fill", self.x + self.width / 2 - 5 + eyeOffsetX + 1, 
                         self.y + self.height / 3 + eyeOffsetY, 2)
    love.graphics.circle("fill", self.x + self.width / 2 + 5 + eyeOffsetX + 1, 
                         self.y + self.height / 3 + eyeOffsetY, 2)
end

function Player:reset()
    self.x = self.respawnX
    self.y = self.respawnY
    self.velocityX = 0
    self.velocityY = 0
    self.grounded = false
    self.facingX = 1
    self.facingY = 0
    self.invulnerable = false
    self.invulnerableTimer = 0
    self.currentHealth = self.maxHealth
    self.lives = self.maxLives
end

function Player:resetPosition()
    self.x = self.respawnX
    self.y = self.respawnY
    self.velocityX = 0
    self.velocityY = 0
    self.grounded = false
end

return Player
