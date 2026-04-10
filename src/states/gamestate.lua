local GameState = {}
GameState.current = nil

function GameState.init()
end

function GameState.change(stateName, ...)
    if stateName == "menu" then
        GameState.current = MenuState
    elseif stateName == "playing" then
        GameState.current = PlayingState
    elseif stateName == "gameover" then
        GameState.current = GameOverState
    end

    if GameState.current and GameState.current.enter then
        GameState.current.enter(...)
    end
end

function GameState.update(dt)
    if GameState.current and GameState.current.update then
        GameState.current.update(dt)
    end
end

function GameState.draw()
    if GameState.current and GameState.current.draw then
        GameState.current.draw()
    end
end

function GameState.keypressed(key)
    if GameState.current and GameState.current.keypressed then
        GameState.current.keypressed(key)
    end
end

return GameState
