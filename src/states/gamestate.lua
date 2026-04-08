local GameState = {}
GameState.current = nil

function GameState.init()
end

function GameState.change(stateName, ...)
    if stateName == "menu" then
        self.current = MenuState
    elseif stateName == "playing" then
        self.current = PlayingState
    elseif stateName == "gameover" then
        self.current = GameOverState
    end

    if self.current and self.current.enter then
        self.current.enter(...)
    end
end

function GameState.update(dt)
    if self.current and self.current.update then
        self.current.update(dt)
    end
end

function GameState.draw()
    if self.current and self.current.draw then
        self.current.draw()
    end
end

function GameState.keypressed(key)
    if self.current and self.current.keypressed then
        self.current.keypressed(key)
    end
end

return GameState
