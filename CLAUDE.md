# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Sp3arParvus** is a localized fork of Parvus Hub, a Roblox Lua development toolkit originally designed to load game-specific modules from GitHub. This version has been modified to run entirely offline without external HTTP requests for use in your own Roblox game development.

### Project Goal
Convert the remote-loaded Parvus Hub into a self-contained local build that:
- Replaces all remote `HttpGet` calls with local file reads (`readfile`)
- Functions independently without GitHub dependencies
- Removes or stubs executor-specific functions that cause errors
- Runs cleanly in your private Roblox game instance for testing and development

## Architecture

### Core Components

**Loader.lua** - Main entry point
- Initializes the global `Parvus` table with game mappings
- Implements `GetFile()` to support both local (`readfile`) and remote (`HttpGet`) loading
- Uses `LoadScript()` to execute Lua files dynamically via `loadstring`
- Handles game detection via `GameId` matching
- Manages auto-reload on teleport via `queue_on_teleport`
- Loads utilities and game-specific scripts based on the detected game

**Universal.lua** - Universal game script
- Provides a fallback combat system for games without specific implementations
- Implements aimbot, silent aim, and trigger bot systems
- Uses metatable hooking (`__index`, `__namecall`) to intercept Roblox API calls
- Includes FOV circles, ESP rendering (boxes, tracers, head dots, arrows)
- Creates UI windows with combat and visuals configuration tabs

### Utilities System (Utilities/)

**Main.lua** - Core utility functions
- FPS counter implementation (`SetupFPS`)
- Movement direction calculations from WASD inputs (`MovementToDirection`)
- Visual effects system (beams with `MakeBeam`)
- Thread loop management (`NewThreadLoop` for continuous update loops)
- Server utilities (rejoin, server hop)
- Discord integration for community features
- Lighting manipulation system (`SetupLighting`)
- Reusable UI section builders (settings, ESP sections)

**UI.lua** - Custom UI framework ("Bracket V2")
- Complete GUI library for creating windows, tabs, and sections
- UI Elements: toggles, sliders, dropdowns, color pickers, keybinds, textboxes, buttons, labels, dividers
- Draggable windows with position saving
- Configuration system (save/load settings to JSON)
- Watermark and keybind list overlays
- Custom notification/toast system
- Flag-based state management for all UI elements

**Drawing.lua** - ESP rendering system
- Wrapper around Roblox Drawing API for on-screen visuals
- Player ESP (2D boxes, tracers, head dots, off-screen arrows)
- Chams/highlights for 3D object visualization
- Object/loot ESP for world items
- FOV circles for aimbot visualization
- Custom cursor and crosshair rendering
- Automatic cleanup and update loops

**Physics.lua** - Prediction and ballistics
- Projectile trajectory calculation with gravity
- Velocity prediction for moving targets
- Bullet drop compensation
- Hit detection algorithms for aim-assist features

### Game-Specific Scripts (Games/)

Each file in the `Games/` folder implements game-specific features by interfacing with that game's internal framework:

**AR2.lua** - Apocalypse Rising 2 (most feature-complete)
- Comprehensive ESP (players, zombies, corpses, containers, loot, vehicles, map elements)
- Silent aim with prediction and wallbang capabilities
- Movement modifications (walkspeed, jump height, fly mode, noclip)
- Vehicle modifications (speed adjustments)
- Weapon mods (no recoil, instant reload, unlock firemodes)
- Uses deep framework integration via `require(ReplicatedFirst.Framework)`

**BB.lua** - Bad Business
- Combat features with ballistic prediction
- Auto-shoot system with target tracking
- Weapon customization interface
- Anti-kick protection

**BRM5.lua** - Blackhawk Rescue Mission 5
- NPC and intel ESP systems
- Teleport functionality
- Vehicle mods (A-10 flight controls, speed adjustment)
- Environment modifications

**RU.lua** - RAGDOLL UNIVERSE
**ST.lua** - Steel Titans (fly mode, XRay for tank module visibility)
**TWR.lua** - Those Who Remain (item ESP, unlimited ammo)
**TWW.lua** - The Wild West (animal/tree ESP, legendary item tracking)

## Key Technical Patterns

### Executor Function Dependencies

The scripts rely on Roblox executor/script environment functions:
- `getupvalue`, `setupvalue` - Access function upvalues
- `hookfunction`, `hookmetamethod` - Hook Roblox API functions
- `setthreadidentity` - Set script identity level
- `getconnections` - Access signal connections
- `gethiddenproperty`, `sethiddenproperty` - Access hidden Instance properties
- `readfile` - Read local files (for local loading mode)
- `checkcaller` - Detect if caller is your script
- `mousemoverel`, `mouse1press`, `mouse1release` - Input simulation
- `isrbxactive` - Check if Roblox window is focused
- `queue_on_teleport` - Persist script across teleports

### Metatable Hooking Pattern

Used extensively for silent aim (intercepts raycast and mouse operations):
```lua
local OldIndex = hookmetamethod(game, "__index", function(Self, Index)
    if checkcaller() then return OldIndex(Self, Index) end
    -- Custom logic to intercept and modify return values
    if SilentAim and Self == Mouse then
        if Index == "Target" then return SilentAim[3] end
        if Index == "Hit" then return SilentAim[3].CFrame end
    end
    return OldIndex(Self, Index)
end)
```

### Game Framework Access

Game-specific scripts (especially AR2) integrate with the game's internal module structure:
```lua
local Framework = require(ReplicatedFirst:WaitForChild("Framework"))
Framework:WaitForLoaded()
-- Access internal libraries
local Bullets = Framework.Libraries.Bullets
local Network = Framework.Libraries.Network
```

This pattern uses `getupvalue` to extract internal functions from the game's modules.

### Local vs Remote Loading

The loader supports both modes via the `IsLocal` parameter (passed as varargs `...`):
```lua
local Branch, NotificationTime, IsLocal = ...

local function GetFile(File)
    return IsLocal and readfile("Parvus/" .. File)
    or game:HttpGet(("%s%s"):format(Parvus.Source, File))
end
```

For local mode, files should be in a `Parvus/` directory accessible to `readfile`.

## Development Workflow

### Running the Script

To run locally in your Roblox game:
1. Ensure all files are available via `readfile("Parvus/...")`
2. Execute the loader with local mode enabled:
   ```lua
   loadstring(readfile("Parvus/Loader.lua"))("main", 5, true)
   -- Parameters: Branch, NotificationTime, IsLocal
   ```
3. The UI will appear with game-specific features based on `game.GameId`

### Making Modifications

**UI changes:**
- Framework changes: Edit `Utilities/UI.lua`
- Game-specific UI: Edit the relevant game script in `Games/`

**Adding ESP for new object types:**
- Use the drawing system in `Utilities/Drawing.lua`
- Reference existing ESP implementations in game scripts

**Adding support for a new game:**
1. Add entry to `Parvus.Games` table in `Loader.lua`
2. Create new file in `Games/` directory
3. Follow the pattern of existing scripts (UI setup, ESP, features)

**Utility functions:**
- Add reusable functions to `Utilities/Main.lua`
- Physics/ballistics: `Utilities/Physics.lua`

### Common Issues

**Nil errors for executor functions:**
- Stub missing functions with empty implementations or use `pcall` guards
- Check if functions exist before calling: `if hookfunction then ... end`

**Game updates breaking scripts:**
- Game-specific scripts that hook internal modules may break when games update
- AR2.lua is particularly sensitive due to deep framework integration
- Check CHANGELOG.md for historical fixes to similar issues

**Missing dependencies:**
- Ensure all utility modules load before game scripts
- Check load order in `Loader.lua` (lines 64-67)

## File Organization

```
/
├── Loader.lua              # Entry point, game detection, module loader
├── Universal.lua           # Fallback script for unsupported games
├── CHANGELOG.md            # Detailed update history (useful for debugging)
├── README.md               # Project context and objectives
├── Utilities/
│   ├── Main.lua           # Core utilities (server hop, lighting, FPS, etc.)
│   ├── UI.lua             # GUI framework (Bracket V2)
│   ├── Drawing.lua        # ESP rendering system
│   ├── Physics.lua        # Ballistics and trajectory calculations
│   ├── ArrowCursor.png    # Custom cursor asset (loaded via GetFile)
│   └── Loadstring         # Auto-reload template script (for teleports)
└── Games/                 # Game-specific implementations
    ├── AR2.lua           # Apocalypse Rising 2 (most complex)
    ├── BB.lua            # Bad Business
    ├── BRM5.lua          # Blackhawk Rescue Mission 5
    ├── RU.lua            # RAGDOLL UNIVERSE
    ├── ST.lua            # Steel Titans
    ├── TWR.lua           # Those Who Remain
    └── TWW.lua           # The Wild West
```

## Configuration System

The UI framework includes a robust config system:
- Configs saved as JSON via `HttpService:JSONEncode`
- Auto-load system: `Window:AutoLoadConfig("Parvus")`
- All UI elements use flags (e.g., `"Aimbot/Enabled"`, `"ESP/Player/Box/Enabled"`)
- Access values via `Window.Flags["FlagName"]`
- Configs may become corrupted if flag names change between versions

## Important Notes

- **Local mode is preferred**: Set `IsLocal = true` to avoid HTTP dependencies
- **Executor dependency**: Most functionality requires executor functions not available in standard Roblox Studio
- **Game-specific fragility**: Game updates frequently break game-specific scripts (see CHANGELOG.md)
- **Branch parameter**: Originally for remote loading from different GitHub branches; less relevant for local mode
- **Identity level**: Some scripts use `setthreadidentity(2)` to access higher-level Roblox APIs
