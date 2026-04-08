# Platformer 2 - Technical Specification

## Game Overview
A LÖVE2D side-scrolling platformer where players fight waves of enemies, collect weapons, and reach the flag at the end of each level.

## Game Systems

### Player
- Movement: WASD or Arrow keys
- Jump: W, Up Arrow, or Space
- Shoot: Space (in direction facing)
- Health: 100 HP starting

### Level System
- Level width: 4000 pixels (scrolling)
- Camera follows player horizontally with lerp (smooth follow)
- Flag at end of level triggers new level generation
- Difficulty increases each level

### Enemies (5 types)
| Type | Behavior | Damage | Health |
|------|----------|--------|--------|
| Slime | Patrol + Jump | 10 | 30 |
| Bat | Chase + Hover | 8 | 20 |
| Turret | Stationary Shoot | 15 | 50 |
| Chaser | Chase + Charge | 20 | 40 |
| Ghost | Phase Through | 12 | 25 |

### Weapons (6 types)
| Name | Color | Fire Rate | Damage |
|------|-------|-----------|--------|
| Pew Pew | Red | Fast | 10 |
| Triple Shot | Cyan | Medium | 8 |
| Heavy Blaster | Orange | Slow | 25 |
| Rapid Fire | Green | Very Fast | 5 |
| Scatter Gun | Pink | Medium | 6 |
| Laser Beam | Purple | Fast | 12 (piercing) |

### Physics Constants
- Player Speed: 250
- Jump Force: 400
- Gravity: 1000
- Max Fall Speed: 600

## File Structure
```
main.lua       - Game loop, states, camera
enemy.lua      - Enemy system with 5 types
weapon.lua     - Weapon system with 6 types
projectile.lua - Projectile physics and rendering
hud.lua        - UI (health, score, weapons)
sound.lua      - Procedurally generated SFX
conf.lua       - LÖVE2D configuration
```

## Controls
| Key | Action |
|-----|--------|
| WASD / Arrows | Move |
| W / Up / Space | Jump |
| Space | Shoot |
| P / Escape | Pause |
| Enter | Menu select |
| Escape (menu) | Quit |

## Version History
- v1.0 - Base platformer with enemies and weapons
- Side-scroller mode with camera follow
- Procedural level generation with flag goal
