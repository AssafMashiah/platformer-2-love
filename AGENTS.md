# Agent Instructions

## Overview
This repository contains a LÖVE2D platformer game. All agents should maintain documentation consistency and update relevant files when making changes.

## Documentation Standards

### README.md
- User-facing documentation
- Controls, gameplay mechanics, installation instructions
- Update when adding new features that affect user experience (new controls, new enemy types, new weapons)

### SPEC.md
- Technical specification document
- Contains game system details, constants, formulas
- Update when modifying game mechanics, adding enemies, weapons, or changing game balance

## Agent Workflow

### When Starting Work
1. Read SPEC.md to understand current game state
2. Check README.md to understand user-facing features
3. Identify what documentation needs updating based on your task

### When Completing Work
1. Update SPEC.md if you changed game mechanics, added features, or modified constants
2. Update README.md if you added user-facing features (new enemies, weapons, controls)
3. Commit documentation changes along with code changes

### Documentation Update Checklist
- [ ] Did you add/modify enemies? → Update SPEC.md enemy table and README.md enemy table
- [ ] Did you add/modify weapons? → Update SPEC.md weapon table and README.md weapon table
- [ ] Did you change game mechanics (health, scoring, levels)? → Update SPEC.md
- [ ] Did you add new controls? → Update README.md controls section
- [ ] Did you add new gameplay features? → Update README.md gameplay section

## File Locations
- **Game Code**: `*.lua` files in root directory
- **Documentation**: `README.md`, `SPEC.md` in root directory
- **Project Config**: `.kilo/` directory for agent and command definitions
