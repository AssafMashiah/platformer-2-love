# Agent Workflow Guide

## Overview
This document defines how agents should work on the Platformer 2 LÖVE game project.

## Working on Code

### 1. Check Existing Code First
Before making changes, read the existing files in:
```
/workspace/rigs/cbfec689-db55-4610-b22a-cde007ab410b/browse/
```

### 2. Making Changes
- Edit files directly in the browse directory
- After editing, commit with a clear message:
```bash
git add <changed-file>
git commit -m "Description of changes"
```

### 3. Pushing to Main
Push from browse branch to main:
```bash
git push origin browse-cbfec689:refs/heads/main
```

## Common Issues

### Lua Syntax
- Lua 5.1 does NOT have `continue` - use `if/else` blocks instead
- Use `for i = #list, 1, -1` for safe reverse iteration
- Use dead-list pattern for removing items during iteration

### LÖVE2D Specific
- Key constant for spacebar is `"space"`, not `" "`
- Use `love.audio.newSource(data, "static")` for sound data
- Camera offset needed for scrolling games

## Game Constants (for reference)
- Screen: 800x600
- Level Width: 4000 (scrolling)
- Player Speed: 250
- Jump Force: 400
- Gravity: 1000

## Commit Message Format
```
<type>: <short description>

<longer description if needed>
```

Types: Fix, Add, Update, Refactor, Docs

## Testing
Test changes locally with:
```bash
cd /workspace/rigs/cbfec689-db55-4610-b22a-cde007ab410b/browse
love .
```
