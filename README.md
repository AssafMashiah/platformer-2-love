# Platformer

A 2D platformer game built with LÖVE2D.

## Requirements

- [LÖVE2D](https://love2d.org/) version 11.0 or later

## Running the Game

### Linux/macOS
```bash
love .
```

### Windows
Double-click the `love.exe` or drag the project folder onto the LÖVE2D application.

## Controls

- **Arrow Keys** / **WASD** - Movement
- **Space** - Jump / Shoot
- **Enter** - Start game / Confirm
- **Escape** - Pause / Return to menu

## Game States

- **Menu** - Start screen
- **Playing** - Main gameplay
- **Game Over** - End screen with score

## Project Structure

```
.
├── conf.lua          -- Game configuration
├── main.lua          -- Entry point and game loop
├── src/
│   └── states/
│       ├── gamestate.lua   -- State machine
│       ├── menu.lua       -- Menu state
│       ├── playing.lua    -- Playing state
│       └── gameover.lua   -- Game over state
└── README.md
```