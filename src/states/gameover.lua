local GameOverState = {}

function GameOverState.enter(finalScore)
    GameOverState.score = finalScore or 0
end

function GameOverState.update(dt)
end

function GameOverState.draw()
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.setNewFont(32)
    love.graphics.printf("GAME OVER", 0, 200, 800, "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.printf("Final Score: " .. GameOverState.score, 0, 280, 800, "center")
    love.graphics.printf("Press ENTER to Return to Menu", 0, 340, 800, "center")
end

function GameOverState.keypressed(key)
    if key == "return" then
        GameState.change("menu")
    end
end

return GameOverState