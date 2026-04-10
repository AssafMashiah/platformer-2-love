local PlayingState = {}

function PlayingState.enter()
    PlayingState.score = 0
    PlayingState.level = 1
    PlayingState.health = 3
end

function PlayingState.update(dt)
end

function PlayingState.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.print("Score: " .. PlayingState.score, 10, 10)
    love.graphics.print("Level: " .. PlayingState.level, 10, 30)
    love.graphics.print("Health: " .. PlayingState.health, 10, 50)
    love.graphics.printf("Playing... Press ESC for Menu", 0, 300, 800, "center")
end

function PlayingState.keypressed(key)
    if key == "escape" then
        GameState.change("menu")
    elseif key == "g" then
        GameState.change("gameover", PlayingState.score)
    end
end

return PlayingState