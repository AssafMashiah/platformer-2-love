local Platform = require("platform")

local Level = {}
Level.__index = Level

Level.TILE_SIZE = 32

function Level.new(levelNumber)
    local self = setmetatable({}, Level)
    self.levelNumber = levelNumber or 1
    self.platforms = {}
    self.width = 1600
    self.height = 900
    self.difficulty = self:calculateDifficulty()
    
    self:generate()
    
    return self
end

function Level:calculateDifficulty()
    local base = 1
    local scale = 0.3
    return base + (self.levelNumber - 1) * scale
end

function Level:generate()
    self.platforms = {}
    
    self:generateGround()
    
    local floatingCount = math.floor(3 + self.difficulty * 2)
    self:generateFloatingPlatforms(floatingCount)
    
    if self.levelNumber >= 2 then
        local movingCount = math.floor((self.difficulty - 1) * 2)
        self:generateMovingPlatforms(movingCount)
    end
end

function Level:generateGround()
    local groundY = self.height - 50
    local groundWidth = self.width - 100
    
    local ground = Platform.new(50, groundY, groundWidth, 50, Platform.TYPES.GROUND)
    table.insert(self.platforms, ground)
    
    for i = 1, math.floor(self.difficulty) do
        local x = 150 + math.random(100, self.width - 300)
        local width = 100 + math.random(50, 150)
        local platform = Platform.new(x, groundY - 80 - (i * 40), width, 30, Platform.TYPES.FLOATING)
        table.insert(self.platforms, platform)
    end
end

function Level:generateFloatingPlatforms(count)
    local minY = 150
    local maxY = self.height - 200
    local margin = 100
    
    local attempts = count * 10
    local placed = 0
    local tries = 0
    
    while placed < count and tries < attempts do
        tries = tries + 1
        
        local width = 80 + math.random(0, math.floor(self.difficulty * 20))
        width = math.max(60, math.min(200, width))
        local height = 30
        
        local x = margin + math.random(0, self.width - margin * 2 - width)
        local y = minY + math.random(0, maxY - minY)
        
        if self:isValidPlacement(x, y, width, height) then
            local platform = Platform.new(x, y, width, height, Platform.TYPES.FLOATING)
            table.insert(self.platforms, platform)
            placed = placed + 1
        end
    end
end

function Level:generateMovingPlatforms(count)
    local minY = 200
    local maxY = self.height - 300
    local margin = 150
    
    local attempts = count * 10
    local placed = 0
    local tries = 0
    
    while placed < count and tries < attempts do
        tries = tries + 1
        
        local width = 100 + math.random(0, math.floor(self.difficulty * 15))
        width = math.max(80, math.min(180, width))
        local height = 30
        local range = 100 + math.floor(self.difficulty * 30)
        local speed = 80 + math.floor(self.difficulty * 20)
        local horizontal = math.random() > 0.3
        
        local baseX = margin + math.random(0, self.width - margin * 2 - width)
        local baseY = minY + math.random(0, maxY - minY)
        
        local x = baseX
        local y = baseY
        
        if horizontal then
            x = baseX - range
            if x < margin then x = margin end
        else
            y = baseY - range
            if y < minY then y = minY end
        end
        
        if self:isValidPlacement(x, y, width, height) then
            local config = {
                moveRange = range,
                moveSpeed = speed,
                horizontal = horizontal
            }
            local platform = Platform.new(baseX, baseY, width, height, Platform.TYPES.MOVING, config)
            table.insert(self.platforms, platform)
            placed = placed + 1
        end
    end
end

function Level:isValidPlacement(x, y, width, height)
    local minGap = 60
    
    for _, platform in ipairs(self.platforms) do
        if x < platform.x + platform.width + minGap and
           x + width + minGap > platform.x and
           y < platform.y + platform.height + minGap and
           y + height + minGap > platform.y then
            return true
        end
    end
    
    return false
end

function Level:update(dt)
    for _, platform in ipairs(self.platforms) do
        platform:update(dt)
    end
end

function Level:draw()
    for _, platform in ipairs(self.platforms) do
        platform:draw()
    end
end

function Level:collidesWith(entity)
    for _, platform in ipairs(self.platforms) do
        if platform:collidesWith(entity) then
            return platform
        end
    end
    return nil
end

function Level:reset()
    self.difficulty = self:calculateDifficulty()
    self:generate()
end

function Level:nextLevel()
    self.levelNumber = self.levelNumber + 1
    self:reset()
end

function Level:getSpawnPoint()
    return 100, self.height - 150
end

function Level:getExitPoint()
    return self.width - 150, self.height - 150
end

return Level
