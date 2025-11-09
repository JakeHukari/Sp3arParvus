# Parvus Hub - Multi-File Execution

## 📦 What's This?

This is the **original structure** with separate modules and game-specific scripts. Use this if you want game-specific features or need to modify individual components.

## 📁 File Structure

```
multi-file/
├── Loader.lua          # Main entry point - RUN THIS
├── Universal.lua       # Fallback script for unsupported games
├── Utilities/          # Core modules
│   ├── Main.lua       # Utility functions
│   ├── UI.lua         # GUI framework (Bracket V2)
│   ├── Drawing.lua    # ESP rendering
│   ├── Physics.lua    # Ballistics/prediction
│   ├── ArrowCursor.png # Custom cursor asset
│   └── Loadstring     # Auto-reload template
└── Games/             # Game-specific scripts
    ├── AR2.lua        # Apocalypse Rising 2
    ├── BB.lua         # Bad Business
    ├── BRM5.lua       # Blackhawk Rescue Mission 5
    ├── RU.lua         # RAGDOLL UNIVERSE
    ├── ST.lua         # Steel Titans
    ├── TWR.lua        # Those Who Remain
    └── TWW.lua        # The Wild West
```

## ✅ Requirements

### Executor Compatibility

| Executor | Status | Method |
|----------|--------|--------|
| **Fluxus** | ✅ Recommended | Use `loadfile` or remote loading |
| **Wave** | ✅ Works | Use `loadfile` or remote loading |
| **Synapse X** | ✅ Works | Full support both methods |
| **Script-Ware** | ✅ Works | Full support both methods |
| **Solara** | ❌ Won't Work | Missing `readfile`, `loadstring`, hooks |

### Required Functions

- `loadstring` - Execute Lua code dynamically
- `readfile` - Load local files (for local mode)
- All functions from single-file method

## 🚀 How to Use

### Method 1: Local File Loading (Recommended)

**Setup:**
1. Place the entire `multi-file/` folder in your executor's workspace
2. Make sure the folder structure is intact

**Execution:**
```lua
loadfile("multi-file/Loader.lua")("main", 5, true)
```

**Parameters:**
- `"main"` - Branch name (not used in local mode)
- `5` - Notification duration (seconds)
- `true` - **Local mode** (use `readfile` instead of HTTP)

### Method 2: Remote Loading (Internet Required)

**Execution:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/Parvus/main/Loader.lua"))("main", 5, false)
```

**Parameters:**
- `"main"` - GitHub branch
- `5` - Notification duration
- `false` - **Remote mode** (download from GitHub)

### Method 3: Paste Loader Only

1. Open `Loader.lua`
2. Change line 24 to:
   ```lua
   local Branch, NotificationTime, IsLocal = "main", 5, false
   ```
3. Copy entire file and execute

## 🎮 Supported Games

The loader auto-detects your game and loads the appropriate script:

| Game | Features |
|------|----------|
| **Apocalypse Rising 2** | Full suite (ESP, aimbot, vehicle mods, walkspeed, etc.) |
| **Bad Business** | Combat, auto-shoot, weapon mods |
| **Blackhawk Rescue Mission 5** | NPC ESP, teleports, vehicle mods |
| **Steel Titans** | Fly, XRay for tank modules |
| **The Wild West** | Animal/tree ESP, legendary tracking |
| **RAGDOLL UNIVERSE** | Basic combat features |
| **Those Who Remain** | Item ESP, unlimited ammo |
| **Any Other Game** | Universal script (aimbot, ESP, silent aim) |

## 🔧 Configuration

### File Paths (Local Mode)

The loader expects files in:
```
Parvus/
├── Utilities/Main.lua
├── Utilities/UI.lua
├── Utilities/Drawing.lua
├── Utilities/Physics.lua
├── Utilities/ArrowCursor.png
├── Utilities/Loadstring
├── Games/AR2.lua
├── Games/BB.lua
└── ...etc
```

Make sure your executor can read from the `Parvus/` folder using `readfile()`.

### Remote Mode

Uses GitHub URLs:
```
https://raw.githubusercontent.com/AlexR32/Parvus/main/<FilePath>
```

## 🐛 Troubleshooting

### "readfile function not available"
Your executor doesn't support local file loading. Use remote mode or single-file version.

### "loadstring function not available"
Your executor is too limited. Get Fluxus from WeAreDevs.net.

### "attempt to index nil (Parvus.Utilities)"
Utilities failed to load. Check:
1. File paths are correct
2. All files are present
3. You're in local mode with `readfile` support OR remote mode with internet

### Game not detected
Check console output. If your game isn't listed, it will use Universal script automatically.

## 📝 Notes

- **Local mode** requires `readfile` function
- **Remote mode** requires internet connection
- Game-specific scripts may break after game updates
- Check [`docs/CHANGELOG.md`](../docs/CHANGELOG.md) for update history

## 🔗 Want Something Simpler?

See [`single-file/`](../single-file/) for a merged version with easier execution.

---

**Version:** Multi-File Original
**Last Updated:** 2025-11-09
