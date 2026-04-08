# Platformer - Survive the Onslaught

A LÖVE2D platformer shooter game where you fight waves of enemies across multiple platforms.

## Controls

### Movement
- **WASD** or **Arrow Keys** - Move character
- **W** or **Up Arrow** or **Space** - Jump (also shoots when in air)

### Combat
- **Space** - Shoot in the direction you're facing
- Walk over weapon pickups to change weapons

### Game Management
- **P** or **Escape** - Pause/Resume game
- **Enter** - Select menu option
- **Escape** (in menu) - Quit game

## Gameplay

### Objective
Survive as long as possible while defeating enemies and accumulating points. Your score increases with each enemy defeated.

### Levels
- Levels increase every 500 points
- Higher levels spawn more enemies at a faster rate
- Enemy difficulty scales with level

### Weapons
Collect weapon pickups to change your weapon. Available weapons include:

| Weapon | Color | Description |
|--------|-------|-------------|
| Pew Pew | Red | Fast single shot |
| Triple Shot | Cyan | Three projectiles at once |
| Heavy Blaster | Orange | Slow but powerful |
| Rapid Fire | Green | Very fast weak shots |
| Scatter Gun | Pink | Five projectiles spread out |
| Laser Beam | Purple | Fast piercing shots |

### Enemies
| Enemy | Color | Behavior |
|-------|-------|----------|
| Slime | Green | Patrols and hops |
| Bat | Purple | Flies and chases |
| Turret | Orange | Stationary, shoots at you |
| Chaser | Red | Chases aggressively, can charge |
| Ghost | Blue | Phases through platforms, flickers |

### Health
- Start with 100 health displayed as hearts
- Taking damage flashes the screen red
- Brief invulnerability after being hit
- Game over when health reaches zero

## Running the Game

### Prerequisites
- LÖVE2D (version 11.0 or higher)

### Installation
```bash
# Clone or download the repository
cd platformer

# Run with LÖVE
love .
```

### File Structure
```
platformer/
├── main.lua       # Main game logic and integration
├── enemy.lua      # Enemy system with 5 enemy types
├── weapon.lua     # Weapon system with 6 weapon types
├── projectile.lua # Enhanced projectile system
├── hud.lua        # Heads-up display and menus
├── sound.lua      # Procedural sound effects
├── conf.lua       # LÖVE2D configuration
├── SPEC.md        # Technical specification
└── README.md      # This file
```

## Contributing

## Browser Support

LÖVE2D games cannot run natively in a web browser. However, there are options for browser deployment:

### Option 1: Upload to LÖVE2D Play (Simplest)

1. Create a `.love` file from your game files
2. Upload it to [https://love2d.org/play](https://love2d.org/play)
3. Share the generated URL with others

**Creating a .love file:**
```bash
zip game.zip *.lua && mv game.zip game.love
```

### Option 2: WebLove (WebAssembly Port)

WebLove is a WebAssembly port of LÖVE2D that runs in browsers. This requires more complex setup but allows self-hosted deployment.

For more information, visit the [WebLove project](https://github.com/TannerGilbert/LÖVE-WASM).

## Contributing

See [AGENTS.md](AGENTS.md) for agent workflow and documentation standards. All contributors should maintain SPEC.md and README.md when modifying game systems.

## Tips
- Stay mobile! Enemies will chase you
- Platform height matters - use it to your advantage
- Different weapons suit different situations
- Watch your cooldown bar before engaging tough enemies
- Ghosts can attack from unexpected angles since they phase through platforms
