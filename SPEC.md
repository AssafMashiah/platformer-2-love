# Platformer - Survive the Onslaught Specification

## Overview
A LÖVE2D platformer shooter game where players fight waves of enemies across multiple platforms, collecting weapons and scoring points.

## Game Systems

### Player
- **Size**: 30x40 pixels
- **Speed**: 300 pixels/second horizontal
- **Jump Velocity**: 600 pixels/second
- **Gravity**: 1800 pixels/second²
- **Starting Health**: 100 HP
- **Invulnerability**: 1.5 seconds after taking damage

### Weapons (6 types)

| ID | Name | Color (RGB) | Fire Rate | Projectile Count | Damage | Behavior |
|----|------|-------------|-----------|------------------|--------|----------|
| 1 | Pew Pew | (255, 50, 50) | 0.25 | 1 | 25 | Fast single shot |
| 2 | Triple Shot | (0, 255, 255) | 0.5 | 3 | 15 | Spread pattern |
| 3 | Heavy Blaster | (255, 165, 0) | 1.0 | 1 | 75 | Slow, powerful |
| 4 | Rapid Fire | (50, 255, 50) | 0.1 | 1 | 10 | Very fast weak shots |
| 5 | Scatter Gun | (255, 100, 200) | 0.6 | 5 | 12 | Wide spread |
| 6 | Laser Beam | (180, 0, 255) | 0.3 | 1 | 30 | Piercing (passes through enemies) |

### Enemies (5 types)

| Type | Color (RGB) | Size | HP | Damage | Behavior |
|------|-------------|------|-----|--------|----------|
| Slime | (50, 255, 50) | 30x20 | 50 | 15 | Patrols, hops toward player |
| Bat | (180, 100, 255) | 30x20 | 30 | 10 | Flies, chases player horizontally |
| Turret | (255, 150, 0) | 30x30 | 80 | 20 | Stationary, shoots at player |
| Chaser | (255, 50, 50) | 30x35 | 70 | 25 | Aggressive chase, charges when close |
| Ghost | (100, 150, 255) | 30x35 | 40 | 15 | Phases through platforms, flickers |

### Spawning System
- **Base spawn interval**: 2.0 seconds
- **Minimum spawn interval**: 0.3 seconds
- **Difficulty scaling**: Every 500 points increases level
- **Spawn rate formula**: `max(0.3, 2.0 - level * 0.15)`
- **Max concurrent enemies**: 15

### Level Progression
- Level increases every 500 points
- Higher levels spawn more enemies
- Enemy health scales: `baseHP * (1 + level * 0.1)`

## Game States
1. **Menu** - Title screen with Start/Quit options
2. **Playing** - Active gameplay
3. **Paused** - Game paused, can resume
4. **Game Over** - Display final score, option to restart

## Controls
| Key | Action |
|-----|--------|
| A/D or Left/Right | Move left/right |
| W/Up/Space | Jump |
| Space | Shoot (in air while moving) |
| P/Escape | Pause game |
| Enter | Menu selection |
| Escape (in menu) | Quit game |

## File Structure
```
platformer/
├── main.lua       # Main game loop, state management, integration
├── enemy.lua      # Enemy classes, spawning, AI behaviors
├── weapon.lua     # Weapon definitions and stats
├── projectile.lua # Projectile physics and rendering
├── hud.lua        # HUD, menus, health display
├── sound.lua      # Procedural sound effects
├── conf.lua       # LÖVE2D configuration
└── README.md      # User-facing documentation
```

## Technical Notes
- Window size: 800x600 pixels
- FPS limit: 60
- Uses LÖVE2D 11.0+ API
- Procedural audio generation (no external files)
