GameState = require("src.states.gamestate")
MenuState = require("src.states.menu")
PlayingState = require("src.states.playing")
GameOverState = require("src.states.gameover")

function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)
    GameState.init()
    GameState.change("menu")
end

function love.update(dt)
    GameState.update(dt)
end

function love.draw()
    GameState.draw()
end

function love.keypressed(key)
    GameState.keypressed(key)
end
