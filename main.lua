function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2)
    
    Package = {}
    Package.path = "?.lua;" .. Package.path
    
    Platform = require("platform")
    Level = require("level")
    
    currentLevel = Level.new(1)
    
    player = {
        x = 100,
        y = 500,
        width = 28,
        height = 44,
        vx = 0,
        vy = 0,
        speed = 200,
        jumpForce = -400,
        onGround = false,
        color = {0.9, 0.6, 0.3}
    }
    
    gravity = 800
    jumpPressed = false
    
    score = 0
    levelDisplay = 1
end

function love.update(dt)
    currentLevel:update(dt)
    
    player.vx = 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        player.vx = -player.speed
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        player.vx = player.speed
    end
    
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space")) and player.onGround and not jumpPressed then
        player.vy = player.jumpForce
        player.onGround = false
        jumpPressed = true
    end
    
    if not (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space")) then
        jumpPressed = false
    end
    
    player.vy = player.vy + gravity * dt
    player.vy = math.min(player.vy, 600)
    
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
    
    player.x = math.max(0, math.min(currentLevel.width - player.width, player.x))
    
    player.onGround = false
    
    local entityBounds = {
        x = player.x,
        y = player.y,
        width = player.width,
        height = player.height
    }
    
    for _, platform in ipairs(currentLevel.platforms) do
        local bounds = platform:getBounds()
        
        if entityBounds.x < bounds.right and
           entityBounds.x + entityBounds.width > bounds.left and
           entityBounds.y < bounds.bottom and
           entityBounds.y + entityBounds.height > bounds.top then
            
            local overlapLeft = (entityBounds.x + entityBounds.width) - bounds.left
            local overlapRight = bounds.right - entityBounds.x
            local overlapTop = (entityBounds.y + entityBounds.height) - bounds.top
            local overlapBottom = bounds.bottom - entityBounds.y
            
            local minOverlapX = math.min(overlapLeft, overlapRight)
            local minOverlapY = math.min(overlapTop, overlapBottom)
            
            if minOverlapY < minOverlapX then
                if overlapTop < overlapBottom then
                    player.y = bounds.top - player.height
                    if player.vy > 0 then
                        player.vy = 0
                        player.onGround = true
                        
                        if platform.type == Platform.TYPES.MOVING then
                            local platformDeltaX = platform.x - platform.prevX
                            local platformDeltaY = platform.y - platform.prevY
                            if platformDeltaX then
                                player.x = player.x + platformDeltaX
                            end
                            if platformDeltaY then
                                player.y = player.y + platformDeltaY
                            end
                        end
                    end
                else
                    player.y = bounds.bottom
                    if player.vy < 0 then
                        player.vy = 0
                    end
                end
            else
                if overlapLeft < overlapRight then
                    player.x = bounds.left - player.width
                else
                    player.x = bounds.right
                end
            end
        end
    end
    
    if player.y > currentLevel.height then
        player.x, player.y = currentLevel:getSpawnPoint()
        player.vy = 0
    end
    
    if player.x > currentLevel.width - 50 then
        score = score + 100 * currentLevel.levelNumber
        levelDisplay = currentLevel.levelNumber + 1
        currentLevel:nextLevel()
        player.x, player.y = currentLevel:getSpawnPoint()
        player.vy = 0
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level: " .. levelDisplay, 10, 10)
    love.graphics.print("Score: " .. score, 10, 30)
    love.graphics.print("Platforms: " .. #currentLevel.platforms, 10, 50)
    
    love.graphics.print("WASD/Arrows: Move | Space/W/Up: Jump", 10, currentLevel.height - 25)
    love.graphics.print("Reach right side to advance level", 10, currentLevel.height - 10)
    
    currentLevel:draw()
    
    love.graphics.setColor(player.color[1], player.color[2], player.color[3])
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    
    love.graphics.setColor(0.2, 0.8, 0.2)
    love.graphics.rectangle("fill", currentLevel:getExitPoint(), currentLevel.height - 100, 40, 50)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
