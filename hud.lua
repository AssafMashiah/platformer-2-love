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
    instance.menuTime = 0
    instance.gameOverHighScore = false
    instance.kills = 0
    instance.totalKills = 0
    instance.fonts = {}
    instance:loadFonts()
    return instance
end

function HUD:loadFonts()
    self.fonts = {
        [8] = love.graphics.newFont(8),
        [10] = love.graphics.newFont(10),
        [12] = love.graphics.newFont(12),
        [14] = love.graphics.newFont(14),
        [16] = love.graphics.newFont(16),
        [18] = love.graphics.newFont(18),
        [20] = love.graphics.newFont(20),
        [24] = love.graphics.newFont(24),
        [28] = love.graphics.newFont(28),
        [32] = love.graphics.newFont(32),
        [36] = love.graphics.newFont(36),
        [48] = love.graphics.newFont(48),
    }
end

function HUD:setFont(size)
    local font = self.fonts[size] or self.fonts[14]
    if font then
        love.graphics.setFont(font)
    end
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
            lifetime = 1.2,
            vy = -70,
            scale = 1.5
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

function HUD:updateFireTime(time)
    self.lastFireTime = time
end

function HUD:takeDamage(amount)
    self.health = math.max(0, self.health - amount)
    self.damageFlashTimer = 0.25
    return self.health <= 0
end

function HUD:addKill()
    self.kills = self.kills + 1
    self.totalKills = self.totalKills + 1
end

function HUD:update(dt)
    self.menuTime = self.menuTime + dt

    if self.damageFlashTimer > 0 then
        self.damageFlashTimer = self.damageFlashTimer - dt
    end

    for i = #self.scorePopups, 1, -1 do
        local popup = self.scorePopups[i]
        popup.lifetime = popup.lifetime - dt
        popup.y = popup.y + popup.vy * dt
        popup.scale = math.max(1, popup.scale - dt * 2)
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
        local flashAlpha = self.damageFlashTimer / 0.25
        love.graphics.setColor(1, 0, 0, flashAlpha * 0.3)
        love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)
    end

    self:drawHealth()
    self:drawScore()
    self:drawWeaponInfo()
    self:drawLevel()
    self:drawScorePopups()
end

function HUD:drawHeart(x, y, size, alpha, pulse)
    local s = size / 2
    if pulse then
        s = s * (1 + math.sin(self.menuTime * 3) * 0.05)
    end

    love.graphics.setColor(0.9 * alpha, 0.15 * alpha, 0.15 * alpha, alpha)
    love.graphics.circle("fill", x - s * 0.3, y - s * 0.2, s * 0.55)
    love.graphics.circle("fill", x + s * 0.3, y - s * 0.2, s * 0.55)

    local points = {
        x - s * 0.85, y - s * 0.05,
        x - s * 0.3, y - s * 0.7,
        x, y - s * 0.35,
        x + s * 0.3, y - s * 0.7,
        x + s * 0.85, y - s * 0.05,
        x, y + s * 0.85
    }
    love.graphics.polygon("fill", points)

    love.graphics.setColor(1 * alpha, 0.5 * alpha, 0.5 * alpha, alpha * 0.4)
    love.graphics.circle("fill", x - s * 0.3, y - s * 0.3, s * 0.18)
end

function HUD:drawHealth()
    local heartSize = 18
    local heartSpacing = 24
    local startX = 15
    local startY = 15
    local healthPerHeart = 25
    local maxHearts = math.ceil(self.maxHealth / healthPerHeart)
    local filledHearts = math.ceil(self.health / healthPerHeart)
    local partialHeart = (self.health % healthPerHeart) / healthPerHeart

    local bgPad = 8
    local bgW = maxHearts * heartSpacing + bgPad * 2
    local bgH = heartSize + 28
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", startX - bgPad, startY - bgPad, bgW, bgH, 6, 6)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("line", startX - bgPad, startY - bgPad, bgW, bgH, 6, 6)

    for i = 1, maxHearts do
        local hx = startX + (i - 1) * heartSpacing + heartSize / 2
        local hy = startY + heartSize / 2

        if i <= filledHearts then
            local isLastFilled = (i == filledHearts and self.health < self.maxHealth)
            self:drawHeart(hx, hy, heartSize, 1.0, isLastFilled and self.health / self.maxHealth < 0.3)
        elseif i == filledHearts + 1 and partialHeart > 0 then
            self:drawHeart(hx, hy, heartSize, partialHeart * 0.7, false)
        else
            self:drawHeart(hx, hy, heartSize, 0.25, false)
        end
    end

    local barW = maxHearts * heartSpacing
    local barH = 6
    local barX = startX
    local barY = startY + heartSize + 6
    local pct = self.health / self.maxHealth

    love.graphics.setColor(0.15, 0.15, 0.15, 0.8)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 3, 3)

    local r, g, b = 0.2, 0.85, 0.3
    if pct < 0.5 then r, g, b = 1, 0.75, 0.15 end
    if pct < 0.25 then r, g, b = 1, 0.2, 0.2 end

    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", barX, barY, barW * pct, barH, 3, 3)

    love.graphics.setColor(r, g, b, 0.4)
    love.graphics.rectangle("fill", barX, barY - 1, barW * pct, barH * 0.4, 3, 3)

    love.graphics.setColor(1, 1, 1, 0.9)
    self:setFont(10)
    love.graphics.print(math.floor(self.health) .. "/" .. self.maxHealth, barX + 4, barY - 1)
end

function HUD:drawScore()
    local padding = 15
    local boxW = 160
    local boxH = 32

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", self.screenWidth - boxW - padding, padding, boxW, boxH, 6, 6)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("line", self.screenWidth - boxW - padding, padding, boxW, boxH, 6, 6)

    love.graphics.setColor(1, 1, 0.3)
    self:setFont(16)
    love.graphics.printf("SCORE: " .. self.score, self.screenWidth - boxW - padding, padding + 8, boxW, "center")
end

function HUD:drawLevel()
    local padding = 15
    local boxW = 130
    local boxH = 28
    local y = padding + 40

    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", self.screenWidth - boxW - padding, y, boxW, boxH, 6, 6)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("line", self.screenWidth - boxW - padding, y, boxW, boxH, 6, 6)

    love.graphics.setColor(0.5, 0.8, 1)
    self:setFont(14)
    love.graphics.printf("LEVEL " .. self.level, self.screenWidth - boxW - padding, y + 6, boxW, "center")
end

function HUD:drawWeaponInfo()
    if not self.currentWeapon then return end

    local weapon = self.currentWeapon
    local padding = 10
    local hudX = padding
    local hudY = self.screenHeight - 95
    local boxW = 210
    local boxH = 80

    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", hudX, hudY, boxW, boxH, 6, 6)
    love.graphics.setColor(1, 1, 1, 0.15)
    love.graphics.rectangle("line", hudX, hudY, boxW, boxH, 6, 6)

    love.graphics.setColor(weapon.color[1], weapon.color[2], weapon.color[3])
    love.graphics.circle("fill", hudX + 28, hudY + 38, 16)

    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.circle("fill", hudX + 24, hudY + 34, 6)

    love.graphics.setColor(1, 1, 1)
    self:setFont(14)
    love.graphics.print(weapon.name, hudX + 52, hudY + 10)

    love.graphics.setColor(0.7, 0.7, 0.7)
    self:setFont(10)
    local stats = string.format("DMG: %d  |  SPD: %d", weapon.damage, math.floor(weapon.projectileSpeed / 10))
    love.graphics.print(stats, hudX + 52, hudY + 30)

    local currentTime = love.timer.getTime()
    local cooldownProgress = math.min(1, (currentTime - self.lastFireTime) / self.fireRate)

    local cdW = 145
    local cdH = 8
    local cdX = hudX + 52
    local cdY = hudY + boxH - 16

    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", cdX, cdY, cdW, cdH, 4, 4)

    if cooldownProgress >= 1 then
        local pulse = 0.85 + 0.15 * math.sin(self.menuTime * 5)
        love.graphics.setColor(0.2 * pulse, 0.9 * pulse, 0.3 * pulse)
    else
        love.graphics.setColor(0.5 + cooldownProgress * 0.5, 0.6, 0.4)
    end
    love.graphics.rectangle("fill", cdX, cdY, cdW * cooldownProgress, cdH, 4, 4)

    love.graphics.setColor(1, 1, 1, 0.75)
    self:setFont(8)
    if cooldownProgress >= 1 then
        love.graphics.print("READY", cdX + cdW / 2 - 14, cdY - 1)
    else
        love.graphics.print("RELOADING...", cdX + cdW / 2 - 28, cdY - 1)
    end
end

function HUD:drawScorePopups()
    for _, popup in ipairs(self.scorePopups) do
        local alpha = math.min(1, popup.lifetime * 2)
        local scale = popup.scale or 1
        love.graphics.setColor(1, 1, 0.2, alpha)
        self:setFont(math.floor(14 * scale))
        love.graphics.print(popup.text, popup.x, popup.y)
    end
end

function HUD:drawMenu()
    love.graphics.setBackgroundColor(0.04, 0.04, 0.09)

    for x = 0, self.screenWidth, 40 do
        love.graphics.setColor(0.08, 0.08, 0.13)
        love.graphics.line(x, 0, x, self.screenHeight)
    end
    for y = 0, self.screenHeight, 40 do
        love.graphics.setColor(0.08, 0.08, 0.13)
        love.graphics.line(0, y, self.screenWidth, y)
    end

    local starCount = 60
    for i = 1, starCount do
        local sx = (i * 137.5) % self.screenWidth
        local sy = (i * 73.7) % self.screenHeight
        local sz = ((i * 17) % 3) + 1
        local twinkle = 0.3 + 0.7 * math.abs(math.sin(self.menuTime * 1.5 + i * 0.7))
        love.graphics.setColor(1, 1, 1, twinkle * 0.5)
        love.graphics.circle("fill", sx, sy, sz)
    end

    local centerX = self.screenWidth / 2
    local centerY = self.screenHeight / 2

    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", centerX - 210, centerY - 190, 420, 380, 12, 12)
    love.graphics.setColor(0.2, 0.5, 0.9, 0.4)
    love.graphics.rectangle("line", centerX - 210, centerY - 190, 420, 380, 12, 12)

    if self.showControls then
        self:drawControlsScreen(centerX, centerY)
    else
        local titleBob = math.sin(self.menuTime * 2) * 4
        love.graphics.setColor(0.3, 0.7, 1)
        self:setFont(36)
        love.graphics.printf("PLATFORMER", centerX - 210, centerY - 155 + titleBob, 420, "center")

        love.graphics.setColor(0.5, 0.9, 0.5)
        self:setFont(14)
        love.graphics.printf("Survive the onslaught!", centerX - 210, centerY - 105 + titleBob, 420, "center")

        for i, option in ipairs(self.menuOptions) do
            local y = centerY + (i - 1) * 55 - 30

            if i == self.menuSelection then
                local slideX = math.sin(self.menuTime * 6) * 3
                love.graphics.setColor(0, 0.6, 1, 0.2)
                love.graphics.rectangle("fill", centerX - 110 + slideX, y - 5, 220, 38, 6, 6)
                love.graphics.setColor(0, 0.8, 1, 0.4)
                love.graphics.rectangle("line", centerX - 110 + slideX, y - 5, 220, 38, 6, 6)

                love.graphics.setColor(0, 1, 0.6)
                self:setFont(20)
                love.graphics.printf("> " .. option .. " <", centerX - 210, y + 2, 420, "center")
            else
                love.graphics.setColor(0.55, 0.55, 0.55)
                self:setFont(18)
                love.graphics.printf(option, centerX - 210, y + 4, 420, "center")
            end
        end

        love.graphics.setColor(0.35, 0.35, 0.35)
        self:setFont(10)
        love.graphics.printf("Use UP/DOWN or W/S to select, ENTER/SPACE to confirm", centerX - 210, centerY + 140, 420, "center")
    end
end

function HUD:drawControlsScreen(centerX, centerY)
    love.graphics.setColor(0.5, 0.8, 1)
    self:setFont(28)
    love.graphics.printf("CONTROLS", centerX - 210, centerY - 155, 420, "center")

    local controls = {
        {"MOVE", "WASD or Arrow Keys"},
        {"SHOOT", "SPACE"},
        {"PAUSE", "P or ESC"},
    }

    for i, ctrl in ipairs(controls) do
        local y = centerY - 70 + (i - 1) * 50

        love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
        love.graphics.rectangle("fill", centerX - 160, y - 5, 320, 35, 6, 6)
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.rectangle("line", centerX - 160, y - 5, 320, 35, 6, 6)

        love.graphics.setColor(1, 1, 0.3)
        self:setFont(14)
        love.graphics.printf(ctrl[1], centerX - 210, y + 3, 130, "right")

        love.graphics.setColor(1, 1, 1)
        self:setFont(12)
        love.graphics.printf(ctrl[2], centerX - 70, y + 4, 280, "left")
    end

    local backY = centerY + 120
    if self.menuSelection == 1 then
        love.graphics.setColor(0, 1, 0.5)
    else
        love.graphics.setColor(0.45, 0.45, 0.45)
    end
    self:setFont(16)
    love.graphics.printf("< Back", centerX - 210, backY, 420, "center")
end

function HUD:drawGameOver()
    love.graphics.setBackgroundColor(0.08, 0.02, 0.02)

    local centerX = self.screenWidth / 2
    local centerY = self.screenHeight / 2

    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", centerX - 260, centerY - 195, 520, 390, 12, 12)
    love.graphics.setColor(1, 0.15, 0.15, 0.45)
    love.graphics.rectangle("line", centerX - 260, centerY - 195, 520, 390, 12, 12)

    local shakeX = 0
    local shakeY = 0
    if self.gameOverTimer < 0.5 then
        shakeX = (math.random() - 0.5) * 6 * (1 - self.gameOverTimer * 2)
        shakeY = (math.random() - 0.5) * 6 * (1 - self.gameOverTimer * 2)
    end

    love.graphics.setColor(1, 0.15, 0.15)
    self:setFont(48)
    love.graphics.printf("GAME OVER", centerX - 260 + shakeX, centerY - 155 + shakeY, 520, "center")

    love.graphics.setColor(1, 1, 1)
    self:setFont(24)
    love.graphics.printf("Final Score: " .. self.score, centerX - 260, centerY - 65, 520, "center")

    love.graphics.setColor(0.7, 0.7, 0.7)
    self:setFont(16)
    love.graphics.printf("Level Reached: " .. self.level, centerX - 260, centerY - 25, 520, "center")

    if self.totalKills > 0 then
        love.graphics.printf("Enemies Defeated: " .. self.totalKills, centerX - 260, centerY + 5, 520, "center")
    end

    if self.gameOverTimer > 1.0 then
        local pulse = 0.5 + 0.5 * math.sin(self.gameOverTimer * 4)

        local optY = centerY + 55
        if self.menuSelection == 1 then
            love.graphics.setColor(0, pulse, pulse)
            love.graphics.rectangle("fill", centerX - 120, optY - 5, 240, 32, 6, 6)
        else
            love.graphics.setColor(0.35, 0.35, 0.35)
        end
        self:setFont(20)
        love.graphics.printf("Play Again", centerX - 260, optY, 520, "center")

        optY = centerY + 95
        if self.menuSelection == 2 then
            love.graphics.setColor(0, pulse, pulse)
            love.graphics.rectangle("fill", centerX - 120, optY - 5, 240, 32, 6, 6)
        else
            love.graphics.setColor(0.35, 0.35, 0.35)
        end
        self:setFont(20)
        love.graphics.printf("Main Menu", centerX - 260, optY, 520, "center")
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
            return "start"
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
    love.graphics.rectangle("fill", centerX - 155, centerY - 85, 310, 170, 10, 10)
    love.graphics.setColor(1, 1, 1, 0.25)
    love.graphics.rectangle("line", centerX - 155, centerY - 85, 310, 170, 10, 10)

    love.graphics.setColor(1, 1, 1)
    self:setFont(32)
    love.graphics.printf("PAUSED", centerX - 155, centerY - 55, 310, "center")

    love.graphics.setColor(0.6, 0.6, 0.6)
    self:setFont(14)
    love.graphics.printf("Press P or ESC to resume", centerX - 155, centerY + 15, 310, "center")

    love.graphics.setColor(0.4, 0.4, 0.4)
    self:setFont(10)
    love.graphics.printf("Score: " .. self.score .. "  |  Level: " .. self.level, centerX - 155, centerY + 50, 310, "center")
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
    self.kills = 0
end

return HUD
