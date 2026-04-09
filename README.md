# Platformer - Survive the Onslaught

A LÖVE2D side-scrolling platformer shooter. Fight enemies, collect weapons, reach the flag!

## Play Online

The game is automatically deployed to GitHub Pages:

**https://assafmashiah.github.io/platformer-2-love**

No installation needed - play directly in your browser.

## Play Locally

### Prerequisites
- [LÖVE2D](https://love2d.org/) version 11.0+

### Run
```bash
git clone https://github.com/AssafMashiah/platformer-2-love.git
cd platformer-2-love
love .
```

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrow Keys | Move |
| W / Up / Space | Jump (double jump!) |
| Space | Shoot |
| P / Escape | Pause |
| Enter | Menu select |

## Gameplay

### Objective
Side-scroll through levels, defeat enemies, collect weapons, and reach the flag at the end of each level.

### Weapons (6 types)
| Weapon | Color | Description |
|--------|-------|-------------|
| Pew Pew | Red | Fast single shot |
| Triple Shot | Cyan | Three projectiles |
| Heavy Blaster | Orange | Slow but powerful |
| Rapid Fire | Green | Very fast weak shots |
| Scatter Gun | Pink | Five-way spread |
| Laser Beam | Purple | Piercing shots |

### Enemies (5 types)
| Enemy | Behavior |
|-------|----------|
| Slime | Patrols and jumps |
| Bat | Flies and chases |
| Turret | Stationary shooter |
| Chaser | Aggressive charge |
| Ghost | Phases through walls |

## Web Deployment

The `.github/workflows/web.yml` workflow automatically:
1. Builds the `.love` file
2. Converts to web using [love.js](https://github.com/Davidobot/love.js)
3. Deploys to GitHub Pages

### Setup GitHub Pages
1. Go to repo **Settings → Pages**
2. Set **Source** to "GitHub Actions"
3. Push to main - the workflow deploys automatically

### Build Web Version Locally
```bash
npm install -g love.js
zip game.love *.lua conf.lua
love.js game.love web-build -t "Platformer" -c
cp web/index.html web-build/index.html
cd web-build && python3 -m http.server 8000
# Open http://localhost:8000
```

### Quick Play (no build)
Upload `game.love` to [love2d.org/play](https://love2d.org/play):
```bash
zip game.love *.lua conf.lua
```

## File Structure
```
├── main.lua       # Game loop, camera, states
├── enemy.lua      # Enemy system (5 types)
├── weapon.lua     # Weapon system (6 types)
├── projectile.lua # Projectile physics
├── hud.lua        # UI and menus
├── sound.lua      # Procedural SFX
├── conf.lua       # LÖVE config
├── save.lua       # Save/load system
├── web/
│   └── index.html # Web launcher
├── .github/
│   └── workflows/
│       └── web.yml
├── SPEC.md        # Technical spec
├── AGENTS.md      # Agent workflow
└── README.md
```
