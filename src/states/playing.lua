local PlayingState = {}

function PlayingState.enter()
    self.score = 0
    self.level = 1
    self.health = 3
end

function PlayingState.update(dt)
end

function PlayingState.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.print("Score: " .. self.score, 10, 10)
    love.graphics.print("Level: " .. self.level, 10, 30)
    love.graphics.print("Health: " .. self.health, 10, 50)
    love.graphics.print("Playing... Press ESC for Menu", 400, 300, 800, "center")
end

function PlayingState.keypressed(key)
    if key == "escape" then
        GameState.change("menu")
    elseif key == "g" then
        GameState.change("gameover", self.score)
    end
end

return PlayingState