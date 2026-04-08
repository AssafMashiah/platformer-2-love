# Character Selection System Specification

## Overview
Introduce playable characters that users can choose from the main menu before starting a game. Each character has unique attributes affecting gameplay.

## Character Flow
1. User selects "Start Game" from main menu
2. Character selection screen appears
3. User browses characters and selects one
4. Game starts with selected character's stats

## Characters

### 1. Turbo (Default)
- **Color**: Blue (#2E86AB)
- **Speed**: 250
- **Jump Force**: 400
- **Grip**: 1.0 (no slide)
- **Description**: "Balanced all-rounder"

### 2. Speedy
- **Color**: Green (#2ECC71)
- **Speed**: 350
- **Jump Force**: 350
- **Grip**: 0.8 (slight slide)
- **Description**: "Fast but slippery"

### 3. Jumpy
- **Color**: Yellow (#F1C40F)
- **Speed**: 180
- **Jump Force**: 550
- **Grip**: 1.0 (no slide)
- **Description**: "Leaps for days"

### 4. Ice King
- **Color**: Cyan (#00D4FF)
- **Speed**: 200
- **Jump Force**: 380
- **Grip**: 0.4 (significant slide)
- **Description**: "Slides on release"

### 5. Tank
- **Color**: Red (#E74C3C)
- **Speed**: 150
- **Jump Force**: 300
- **Grip**: 1.0 (no slide)
- **Description**: "Slow but steady"

## Grip Mechanics
- Grip value affects how quickly velocity decays when keys are released
- Grip of 1.0 = instant stop (velocity *= 0)
- Grip of 0.4 = slides for ~0.5 seconds after release
- Formula: `velocityX *= (1 - grip * dt * 10)`

## UI Components

### Character Selection Screen
- Display character roster in horizontal layout
- Show character preview with their color
- Display stats: Speed, Jump, Grip
- Arrow keys to navigate, Enter/Space to select, Escape to go back
- Visual indicator for selected character (glow/border)

### State Transition
- `GameState.CHAR_SELECT` added to enum
- Main menu flow: MENU -> CHAR_SELECT -> PLAYING

## Implementation Files
- `characters.lua`: Character definitions and data
- `hud.lua`: Character selection UI and navigation
- `main.lua`: Apply character stats to player, handle state transitions
