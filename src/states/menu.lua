local MenuState = {}

function MenuState.enter()
end

function MenuState.update(dt)
end

function MenuState.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(32)
    love.graphics.printf("PLATFORMER", 0, 200, 800, "center")

    love.graphics.setNewFont(16)
    love.graphics.printf("Press ENTER to Start", 0, 300, 800, "center")
    love.graphics.printf("Press ESC to Quit", 0, 340, 800, "center")
end

function MenuState.keypressed(key)
    if key == "return" then
        GameState.change("playing")
    elseif key == "escape" then
        love.event.quit()
    end
end

return MenuState
