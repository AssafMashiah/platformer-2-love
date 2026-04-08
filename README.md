# Platformer - Survive the Onslaught

A 2D platformer game built with LÖVE (Love2D).

## Controls

| Key | Action |
|-----|--------|
| **A / Left Arrow** | Move left |
| **D / Right Arrow** | Move right |
| **W / Up Arrow / Space** | Jump |
| **Space** (in-game) | Fire weapon |
| **P / Escape** | Pause game |
| **Enter** | Confirm selection (menu) |

## Gameplay

### Objective
Survive waves of enemies across multiple levels. Each level increases difficulty with more enemies and faster spawn rates.

### Scoring
- Defeat enemies to earn points
- Each enemy type has a different point value
- Score thresholds (500 points each) advance you to the next level

### Health
- You start with 100 health
- Enemy contact deals damage based on enemy type
- Taking damage grants brief invulnerability (0.5 seconds)
- Health does not regenerate

### Weapons
Collect weapon pickups scattered across platforms. Each weapon has different stats:

| Weapon | Damage | Fire Rate | Projectile Speed |
|--------|--------|-----------|------------------|
| Pistol | 20 | 0.5s | 400 |
| Machine Gun | 15 | 0.1s | 500 |
| Shotgun | 12×3 | 0.7s | 350 |
| Sniper | 50 | 1.2s | 800 |
| Laser Beam | 25 | 0.3s | 600 |
| Rocket Launcher | 80 | 1.5s | 250 |

### Enemy Types

| Enemy | Behavior | Health | Damage | Points |
|-------|----------|--------|--------|--------|
| **Slime** | Patrols platforms, jumps between them | 30 | 10 | 100 |
| **Bat** | Flies and chases the player | 20 | 8 | 150 |
| **Turret** | Stationary, shoots projectiles | 50 | 15 | 200 |
| **Chaser** | Aggressive, charges at player | 40 | 20 | 250 |
| **Ghost** | Phases through platforms, flickers | 25 | 12 | 175 |

## Game States

- **Menu**: Press Enter to start, Escape to quit
- **Playing**: Main gameplay
- **Paused**: Press P or Escape to resume
- **Game Over**: Shows final score, restart or return to menu

## Installation

Requires LÖVE (Love2D) to run.

```bash
# Clone the repository
git clone <repository-url>
cd platformer-2-love

# Run with LÖVE
love .
```

Or create a game archive:
```bash
zip -r platformer.love *.lua
love platformer.love
```

## Project Structure

```
.
├── main.lua          # Main game loop, player, platforms
├── enemy.lua         # Enemy system with 5 enemy types
├── weapon.lua        # Weapon pickups and stats
├── projectile.lua    # Projectile system with trails
├── hud.lua           # UI, menus, health, score
└── sound.lua         # Sound effects
```

## Technical Details

- **Resolution**: 800×600
- **Physics**: Custom gravity-based platformer physics
- **Rendering**: LÖVE2D canvas-based graphics
- **Collision**: AABB rectangle collision detection
