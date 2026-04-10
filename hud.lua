HUD = {}
HUD.__index = HUD

function HUD:new()
    local instance = setmetatable({}, self)
    instance.health = 100
    instance.maxHealth = 100
    instance.score = 0
    instance.level = 1
    instance.currentWeapon = nil
    instance.lastFireTime = 0
    instance.fireRate = 0
    instance.screenWidth = 800
    instance.screenHeight = 600
    instance.damageFlashTimer = 0
    instance.scorePopups = {}
    instance.menuSelection = 1
    instance.menuOptions = {"Start Game", "Controls", "Quit"}
    instance.showControls = false
    instance.gameOver = false
    instance.gameOverTimer = 0
    instance.paused = false
    instance.weaponSystem = nil
    instance.charSelection = 1
    instance.characters = require("characters")
    return instance
end

function HUD:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function HUD:setHealth(health, maxHealth)
    self.health = math.max(0, health)
    self.maxHealth = maxHealth or self.maxHealth
end

function HUD:getHealth()
    return self.health
end

function HUD:addScore(points, x, y)
    self.score = self.score + points
    if x and y then
        table.insert(self.scorePopups, {
            text = "+" .. points,
            x = x,
            y = y,
            lifetime = 1.0,
            vy = -60
        })
    end
end

function HUD:getScore()
    return self.score
end

function HUD:setLevel(level)
    self.level = level
end

function HUD:getLevel()
    return self.level
end

function HUD:setWeapon(weapon)
    self.currentWeapon = weapon
    if weapon then
        self.fireRate = weapon.fireRate or 0.15
    end
end

function HUD:getWeapon()
    return self.currentWeapon
end

function HUD:setWeaponSystem(ws)
    self.weaponSystem = ws
end

function HUD:updateFireTime(time)
    self.lastFireTime = time
end

function HUD:takeDamage(amount)
    self.health = math.max(0, self.health - amount)
    self.damageFlashTimer = 0.2
    return self.health <= 0
end

function HUD:update(dt)
    if self.damageFlashTimer > 0 then
        self.damageFlashTimer = self.damageFlashTimer - dt
    end
    
    for i = #self.scorePopups, 1, -1 do
        local popup = self.scorePopups[i]
        popup.lifetime = popup.lifetime - dt
        popup.y = popup.y + popup.vy * dt
        if popup.lifetime <= 0 then
            table.remove(self.scorePopups, i)
        end
    end
    
    if self.gameOver then
        self.gameOverTimer = self.gameOverTimer + dt
    end
end

function HUD:draw()
    if self.damageFlashTimer > 0 then
        love.graphics.setColor(1, 0, 0, self.damageFlashTimer * 2)
        love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    end
    
    self:drawHealth()
    self:drawScore()
    self:drawWeaponInfo()
    self:drawLevel()
    self:drawScorePopups()
end

function HUD:drawHealth()
    local heartSize = 20
    local heartSpacing = 26
    local startX = 15
    local startY = 15
    local maxHearts = math.ceil(self.maxHealth / 25)
    local filledHearts = math.ceil(self.health / 25)
    
    for i = 1, maxHearts, 1 do
        local x = startX + (i - 1) * heartSpacing
        local y = startY
        
        if i <= filledHearts then
            self:drawHeart(x, y, heartSize, 1.0)
        else
            self:drawHeart(x, y, heartSize, 0.3)
        end
    end
    
    local healthBarWidth = 150
    local healthBarHeight = 8
    local healthBarX = startX
    local healthBarY = startY + heartSize + 8
    local healthPercent = self.health / self.maxHealth
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth, healthBarHeight, 4, 4)
    
    local healthColor = {0.2, 0.9, 0.3}
    if healthPercent < 0.5 then
        healthColor = {1, 0.8, 0.2}
    end
    if healthPercent < 0.25 then
        healthColor = {1, 0.2, 0.2}
    end
    
    love.graphics.setColor(healthColor[1], healthColor[2], healthColor[3])
    love.graphics.rectangle("fill", healthBarX, healthBarY, healthBarWidth * healthPercent, healthBarHeight, 4, 4)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.print(math.floor(self.health) .. "/" .. self.maxHealth, healthBarX + 5, healthBarY - 1)
end

function HUD:drawHeart(x, y, size, alpha)
    local halfSize = size / 2
    
    love.graphics.setColor(0.8 * alpha, 0.2 * alpha, 0.2 * alpha, alpha)
    love.graphics.setLineWidth(2)
    
    local points = {}
    for i = 0, 10 do
        local t = i / 10 * math.pi * 2
        local px = x + halfSize + halfSize * 0.7 * math.cos(t) - (halfSize * 0.3) * math.cos(2 * t)
        local py = y + halfSize + halfSize * 0.7 * math.sin(t) - (halfSize * 0.3) * math.sin(2 * t)
        table.insert(points, px)
        table.insert(points, py)
    end
    love.graphics.polygon("fill", unpack(points))
    
    love.graphics.setColor(1 * alpha, 0.5 * alpha, 0.5 * alpha, alpha * 0.5)
    local highlightX = x + halfSize * 0.6
    local highlightY = y + halfSize * 0.5
    love.graphics.circle("fill", highlightX, highlightY, halfSize * 0.2)
end

function HUD:drawScore()
    local scoreText = "SCORE: " .. self.score
    local padding = 15
    local boxWidth = 150
    local boxHeight = 30
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", self.screenWidth - boxWidth - padding, padding, boxWidth, boxHeight, 5, 5)
    
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", self.screenWidth - boxWidth - padding, padding, boxWidth, boxHeight, 5, 5)
    
    love.graphics.setColor(1, 1, 0.3)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(scoreText, self.screenWidth - boxWidth - padding, padding + 7, boxWidth, "center")
end

function HUD:drawLevel()
    local padding = 15
    local boxWidth = 120
    local boxHeight = 30
    local y = padding + 35
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", self.screenWidth - boxWidth - padding, y, boxWidth, boxHeight, 5, 5)
    
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", self.screenWidth - boxWidth - padding, y, boxWidth, boxHeight, 5, 5)
    
    love.graphics.setColor(0.5, 0.8, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("LEVEL " .. self.level, self.screenWidth - boxWidth - padding, y + 8, boxWidth, "center")
end

function HUD:drawWeaponInfo()
    if not self.currentWeapon then return end
    
    local weapon = self.currentWeapon
    local padding = 10
    local hudX = padding
    local hudY = self.screenHeight - 90
    local boxWidth = 200
    local boxHeight = 70
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", hudX, hudY, boxWidth, boxHeight, 5, 5)
    
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", hudX, hudY, boxWidth, boxHeight, 5, 5)
    
    local wc = weapon.color or {1, 1, 1}
    love.graphics.setColor(wc[1], wc[2], wc[3])
    love.graphics.circle("fill", hudX + 25, hudY + 35, 15)
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.circle("fill", hudX + 22, hudY + 32, 5)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print(weapon.name, hudX + 48, hudY + 10)
    
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(10))
    local stats = string.format("DMG: %d  |  SPD: %d", weapon.damage, math.floor(weapon.projectileSpeed / 10))
    love.graphics.print(stats, hudX + 48, hudY + 28)
    
    local cooldownWidth = 140
    local cooldownHeight = 8
    local cooldownX = hudX + 50
    local cooldownY = hudY + boxHeight - 14
    
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", cooldownX, cooldownY, cooldownWidth, cooldownHeight, 3, 3)
    
    local validCooldown = self.fireRate and self.fireRate > 0
    local cooldownProgress = validCooldown and math.min(1, (love.timer.getTime() - self.lastFireTime) / self.fireRate) or 1
    
    local readyColor = {0.3, 1, 0.3}
    if cooldownProgress < 1 then
        readyColor = {0.5 + cooldownProgress * 0.5, 0.7, 0.5}
    end
    
    love.graphics.setColor(readyColor[1], readyColor[2], readyColor[3])
    love.graphics.rectangle("fill", cooldownX, cooldownY, cooldownWidth * cooldownProgress, cooldownHeight, 3, 3)
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setFont(love.graphics.newFont(8))
    if validCooldown and cooldownProgress >= 1 then
        love.graphics.print("READY", cooldownX + cooldownWidth / 2 - 15, cooldownY - 2)
    elseif validCooldown then
        love.graphics.print("RELOADING", cooldownX + cooldownWidth / 2 - 25, cooldownY - 2)
    end
    
    self:drawInventorySlots()
end

function HUD:drawInventorySlots()
    if not self.weaponSystem then return end
    
    local inventory = self.weaponSystem:getInventory()
    local currentSlot = self.weaponSystem:getCurrentSlot()
    local maxSlots = self.weaponSystem:getMaxInventory()
    
    local slotSize = 36
    local slotPadding = 4
    local startX = 220
    local startY = self.screenHeight - 90
    
    local totalWidth = maxSlots * slotSize + (maxSlots - 1) * slotPadding
    local bgX = startX - 4
    local bgY = startY - 4
    local bgW = totalWidth + 8
    local bgH = slotSize + 24
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", bgX, bgY, bgW, bgH, 5, 5)
    
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("line", bgX, bgY, bgW, bgH, 5, 5)
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setFont(love.graphics.newFont(8))
    love.graphics.print("[Q] Swap  [1-4] Select", startX, bgY + 2)
    
    for i = 1, maxSlots do
        local x = startX + (i - 1) * (slotSize + slotPadding)
        local y = startY + 12
        
        if i == currentSlot then
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.rectangle("fill", x - 1, y - 1, slotSize + 2, slotSize + 2, 4, 4)
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.rectangle("line", x - 1, y - 1, slotSize + 2, slotSize + 2, 4, 4)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
            love.graphics.rectangle("fill", x, y, slotSize, slotSize, 3, 3)
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.rectangle("line", x, y, slotSize, slotSize, 3, 3)
        end
        
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.setFont(love.graphics.newFont(8))
        love.graphics.print(tostring(i), x + 2, y + 1)
        
        if inventory[i] then
            local w = inventory[i]
            local wc = w.color or {1, 1, 1}
            love.graphics.setColor(wc[1], wc[2], wc[3], 0.8)
            love.graphics.circle("fill", x + slotSize / 2, y + slotSize / 2, 8)
            
            love.graphics.setColor(1, 1, 1, 0.4)
            love.graphics.circle("fill", x + slotSize / 2 - 2, y + slotSize / 2 - 2, 3)
            
            love.graphics.setColor(1, 1, 1, 0.7)
            love.graphics.setFont(love.graphics.newFont(7))
            love.graphics.printf(w.name, x, y + slotSize - 8, slotSize, "center")
        end
    end
end

function HUD:drawScorePopups()
    for _, popup in ipairs(self.scorePopups) do
        local alpha = popup.lifetime
        love.graphics.setColor(1, 1, 0.2, alpha)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(popup.text, popup.x, popup.y)
    end
end

function HUD:drawMenu()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    
    for x = 0, self.screenWidth, 40 do
        love.graphics.setColor(0.1, 0.1, 0.15)
        love.graphics.line(x, 0, x, self.screenHeight)
    end
    for y = 0, self.screenHeight, 40 do
        love.graphics.setColor(0.1, 0.1, 0.15)
        love.graphics.line(0, y, self.screenWidth, y)
    end
    
    local centerX = self.screenWidth / 2
    local centerY = self.screenHeight / 2
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", centerX - 200, centerY - 180, 400, 360, 10, 10)
    
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", centerX - 200, centerY - 180, 400, 360, 10, 10)
    
    if self.showControls then
        self:drawControlsScreen(centerX, centerY)
    else
        love.graphics.setColor(0.3, 0.7, 1)
        love.graphics.setFont(love.graphics.newFont(36))
        love.graphics.printf("PLATFORMER", centerX - 200, centerY - 150, 400, "center")
        
        love.graphics.setColor(0.5, 0.9, 0.5)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf("Survive the onslaught!", centerX - 200, centerY - 100, 400, "center")
        
        for i, option in ipairs(self.menuOptions) do
            local y = centerY + (i - 1) * 50 - 30
            
            if i == self.menuSelection then
                love.graphics.setColor(0, 0.8, 1, 0.3)
                love.graphics.rectangle("fill", centerX - 100, y - 5, 200, 35, 5, 5)
                
                love.graphics.setColor(0, 1, 0.5)
                love.graphics.setFont(love.graphics.newFont(20))
                love.graphics.printf("> " .. option .. " <", centerX - 200, y, 400, "center")
            else
                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.setFont(love.graphics.newFont(18))
                love.graphics.printf(option, centerX - 200, y, 400, "center")
            end
        end
        
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf("Use UP/DOWN or W/S to select", centerX - 200, centerY + 130, 400, "center")
    end
end

function HUD:drawControlsScreen(centerX, centerY)
    love.graphics.setColor(0.5, 0.8, 1)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf("CONTROLS", centerX - 200, centerY - 150, 400, "center")
    
    local controls = {
        {"MOVE", "WASD or Arrow Keys"},
        {"SHOOT", "SPACE"},
        {"SWAP WEAPON", "Q"},
        {"SELECT SLOT", "1-4"},
        {"PAUSE", "P or ESC"},
        {"MENU", "ESC"}
    }
    
    for i, ctrl in ipairs(controls) do
        local y = centerY - 60 + (i - 1) * 40
        
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        love.graphics.rectangle("fill", centerX - 150, y - 5, 300, 30, 5, 5)
        
        love.graphics.setColor(1, 1, 0.3)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf(ctrl[1], centerX - 200, y, 120, "right")
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(ctrl[2], centerX - 80, y, 280, "left")
    end
    
    local backY = centerY + 110
    if self.menuSelection == 1 then
        love.graphics.setColor(0, 1, 0.5)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
    end
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("< Back", centerX - 200, backY, 400, "center")
end

function HUD:drawGameOver()
    love.graphics.setBackgroundColor(0.1, 0.02, 0.02)
    
    local centerX = self.screenWidth / 2
    local centerY = self.screenHeight / 2
    
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", centerX - 250, centerY - 180, 500, 360, 10, 10)
    
    love.graphics.setColor(1, 0.2, 0.2, 0.5)
    love.graphics.rectangle("line", centerX - 250, centerY - 180, 500, 360, 10, 10)
    
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("GAME OVER", centerX - 250, centerY - 140, 500, "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Final Score: " .. self.score, centerX - 250, centerY - 50, 500, "center")
    
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("Level Reached: " .. self.level, centerX - 250, centerY - 10, 500, "center")
    
    if self.gameOverTimer > 1 then
        local pulse = 0.5 + 0.5 * math.sin(self.gameOverTimer * 4)
        
        if self.menuSelection == 1 then
            love.graphics.setColor(0, pulse, pulse)
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
        end
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf("> Play Again <", centerX - 250, centerY + 50, 500, "center")
        
        if self.menuSelection == 2 then
            love.graphics.setColor(0, pulse, pulse)
        else
            love.graphics.setColor(0.4, 0.4, 0.4)
        end
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf("> Main Menu <", centerX - 250, centerY + 90, 500, "center")
    end
end

function HUD:handleMenuKey(key)
    if self.showControls then
        if key == "escape" or key == "backspace" then
            self.showControls = false
            self.menuSelection = 2
        end
        return "controls"
    end
    
    if key == "up" or key == "w" then
        self.menuSelection = self.menuSelection - 1
        if self.menuSelection < 1 then
            self.menuSelection = #self.menuOptions
        end
    elseif key == "down" or key == "s" then
        self.menuSelection = self.menuSelection + 1
        if self.menuSelection > #self.menuOptions then
            self.menuSelection = 1
        end
    elseif key == "return" or key == "space" then
        if self.menuSelection == 1 then
            return "charselect"
        elseif self.menuSelection == 2 then
            self.showControls = true
            return "controls"
        elseif self.menuSelection == 3 then
            return "quit"
        end
    elseif key == "escape" then
        return "quit"
    end
    
    return "menu"
end

function HUD:handleGameOverKey(key)
    if key == "up" or key == "w" then
        self.menuSelection = math.max(1, self.menuSelection - 1)
    elseif key == "down" or key == "s" then
        self.menuSelection = math.min(2, self.menuSelection + 1)
    elseif key == "return" or key == "space" then
        if self.gameOverTimer > 1 then
            if self.menuSelection == 1 then
                return "restart"
            else
                return "menu"
            end
        end
    elseif key == "escape" then
        return "menu"
    end
    
    return "gameover"
end

function HUD:startGameOver()
    self.gameOver = true
    self.gameOverTimer = 0
    self.menuSelection = 1
end

function HUD:isGameOver()
    return self.gameOver
end

function HUD:isPaused()
    return self.paused
end

function HUD:isMenu()
    return self.showControls or (not self.gameOver and self.score == 0)
end

function HUD:togglePause()
    self.paused = not self.paused
end

function HUD:drawPause()
    local centerX = self.screenWidth / 2
    local centerY = self.screenHeight / 2
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", centerX - 150, centerY - 80, 300, 160, 10, 10)
    
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", centerX - 150, centerY - 80, 300, 160, 10, 10)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("PAUSED", centerX - 150, centerY - 50, 300, "center")
    
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("Press P or ESC to resume", centerX - 150, centerY + 20, 300, "center")
end

function HUD:drawCharacterSelect()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)

    for x = 0, self.screenWidth, 40 do
        love.graphics.setColor(0.1, 0.1, 0.15)
        love.graphics.line(x, 0, x, self.screenHeight)
    end
    for y = 0, self.screenHeight, 40 do
        love.graphics.setColor(0.1, 0.1, 0.15)
        love.graphics.line(0, y, self.screenWidth, y)
    end

    local centerX = self.screenWidth / 2
    local chars = self.characters.list
    local count = #chars
    local cols = 3
    local rows = 2
    local cardW = 180
    local cardH = 170
    local gapX = 20
    local gapY = 20
    local totalW = cols * cardW + (cols - 1) * gapX
    local totalH = rows * cardH + (rows - 1) * gapY
    local startX = centerX - totalW / 2
    local startY = 120

    love.graphics.setColor(0.3, 0.7, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("CHOOSE YOUR CHARACTER", 0, 30, self.screenWidth, "center")

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf("Use LEFT/RIGHT or A/D to browse. ENTER or SPACE to confirm. ESC to go back.", 0, 70, self.screenWidth, "center")

    for i, char in ipairs(chars) do
        local col = ((i - 1) % cols)
        local row = math.floor((i - 1) / cols)
        local cx = startX + col * (cardW + gapX)
        local cy = startY + row * (cardH + gapY)
        local isSelected = (i == self.charSelection)

        if isSelected then
            love.graphics.setColor(char.color[1] * 0.3, char.color[2] * 0.3, char.color[3] * 0.3, 0.5)
            love.graphics.rectangle("fill", cx - 3, cy - 3, cardW + 6, cardH + 6, 10, 10)
            love.graphics.setColor(char.color[1], char.color[2], char.color[3], 0.9)
            love.graphics.rectangle("line", cx - 3, cy - 3, cardW + 6, cardH + 6, 10, 10)
        end

        love.graphics.setColor(0.08, 0.08, 0.15, 0.85)
        love.graphics.rectangle("fill", cx, cy, cardW, cardH, 8, 8)

        if not isSelected then
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.rectangle("line", cx, cy, cardW, cardH, 8, 8)
        end

        local previewCx = cx + cardW / 2
        local previewCy = cy + 45
        local pw = char.width or 32
        local ph = char.height or 32

        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.ellipse("fill", previewCx + 2, previewCy + ph / 2 + 4, pw / 2 + 3, 6)

        love.graphics.setColor(char.color[1], char.color[2], char.color[3])
        love.graphics.rectangle("fill", previewCx - pw / 2, previewCy - ph / 2, pw, ph, 4, 4)

        love.graphics.setColor(char.color[1] * 1.3, char.color[2] * 1.3, char.color[3] * 1.3, 0.6)
        love.graphics.rectangle("fill", previewCx - pw / 2 + 2, previewCy - ph / 2 + 2, pw - 4, ph / 3, 3, 3)

        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", previewCx - 5, previewCy - ph / 6, 3)
        love.graphics.circle("fill", previewCx + 5, previewCy - ph / 6, 3)
        love.graphics.setColor(0.1, 0.1, 0.2)
        love.graphics.circle("fill", previewCx - 4, previewCy - ph / 6, 1.5)
        love.graphics.circle("fill", previewCx + 6, previewCy - ph / 6, 1.5)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.printf(char.name, cx, cy + 75, cardW, "center")

        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.printf(char.description, cx + 5, cy + 95, cardW - 10, "center")

        local barX = cx + 10
        local barW = cardW - 20
        local barH = 6
        local statsY = cy + 115

        local speedPct = char.speed / 400
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, statsY, barW, barH, 3, 3)
        love.graphics.setColor(0.3, 0.8, 1)
        love.graphics.rectangle("fill", barX, statsY, barW * speedPct, barH, 3, 3)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.setFont(love.graphics.newFont(8))
        love.graphics.print("SPD", barX, statsY - 9)

        local jumpPct = char.jumpForce / 800
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, statsY + 16, barW, barH, 3, 3)
        love.graphics.setColor(0.3, 1, 0.4)
        love.graphics.rectangle("fill", barX, statsY + 16, barW * jumpPct, barH, 3, 3)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("JMP", barX, statsY + 7)

        local gripPct = char.grip
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, statsY + 32, barW, barH, 3, 3)
        love.graphics.setColor(1, 0.8, 0.3)
        love.graphics.rectangle("fill", barX, statsY + 32, barW * gripPct, barH, 3, 3)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("GRP", barX, statsY + 23)
    end
end

function HUD:handleCharacterSelectKey(key)
    local count = self.characters:count()

    if key == "left" or key == "a" then
        self.charSelection = self.charSelection - 1
        if self.charSelection < 1 then
            self.charSelection = count
        end
    elseif key == "right" or key == "d" then
        self.charSelection = self.charSelection + 1
        if self.charSelection > count then
            self.charSelection = 1
        end
    elseif key == "up" or key == "w" then
        self.charSelection = self.charSelection - 3
        if self.charSelection < 1 then
            self.charSelection = self.charSelection + count
        end
    elseif key == "down" or key == "s" then
        self.charSelection = self.charSelection + 3
        if self.charSelection > count then
            self.charSelection = self.charSelection - count
        end
    elseif key == "return" or key == "space" then
        return "confirm"
    elseif key == "escape" then
        return "back"
    end

    return "charselect"
end

function HUD:getSelectedCharacter()
    return self.charSelection
end

function HUD:reset()
    self.health = 100
    self.maxHealth = 100
    self.score = 0
    self.level = 1
    self.lastFireTime = 0
    self.damageFlashTimer = 0
    self.scorePopups = {}
    self.menuSelection = 1
    self.showControls = false
    self.gameOver = false
    self.gameOverTimer = 0
    self.paused = false
    self.charSelection = 1
end

return HUD
