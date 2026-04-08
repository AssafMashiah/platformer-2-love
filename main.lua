local WeaponSystem = require("weapon")

local player = {
    x = 400,
    y = 300,
    width = 32,
    height = 32,
    speed = 200,
    facingX = 1,
    facingY = 0
}

local weaponSystem
local screenWidth = 800
local screenHeight = 600

function love.load()
    love.window.setMode(screenWidth, screenHeight)
    love.window.setTitle("Platformer - Weapon Demo")
    math.randomseed(os.time())
    weaponSystem = WeaponSystem:new()
end

function love.update(dt)
    local dx, dy = 0, 0
    
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        dx = dx - 1
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        dx = dx + 1
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        dy = dy - 1
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        dy = dy + 1
    end
    
    if dx ~= 0 or dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len
        player.facingX, player.facingY = dx, dy
    end
    
    player.x = player.x + dx * player.speed * dt
    player.y = player.y + dy * player.speed * dt
    
    player.x = math.max(0, math.min(screenWidth - player.width, player.x))
    player.y = math.max(0, math.min(screenHeight - player.height, player.y))
    
    weaponSystem:update(dt, screenWidth, screenHeight)
    weaponSystem:checkPickupCollision(player.x, player.y, player.width, player.height)
    
    if love.keyboard.isDown("space") then
        local centerX = player.x + player.width / 2
        local centerY = player.y + player.height / 2
        weaponSystem:fire(centerX, centerY, player.facingX, player.facingY, love.timer.getTime())
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    
    for x = 0, screenWidth, 40 do
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, 40 do
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.line(0, y, screenWidth, y)
    end
    
    weaponSystem:drawPickups()
    weaponSystem:drawProjectiles()
    
    love.graphics.setColor(0.3, 0.7, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height, 4, 4)
    
    local centerX = player.x + player.width / 2
    local centerY = player.y + player.height / 2
    love.graphics.setColor(1, 1, 0.5)
    love.graphics.circle("fill", centerX + player.facingX * 20, centerY + player.facingY * 20, 6)
    
    weaponSystem:drawHUD()
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("WASD/Arrows: Move  |  Space: Shoot  |  Walk over boxes to change weapons", 10, screenHeight - 25)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
