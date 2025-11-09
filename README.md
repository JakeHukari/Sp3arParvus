# Sp3arParvus

**A localized fork of [Parvus Hub](https://github.com/AlexR32/Parvus)** - Roblox development toolkit for testing in your own games.

> This is adapted from the original Parvus Hub to run completely offline without GitHub dependencies.

## 🎯 Project Goal

Create a fully local, self-contained version of Parvus Hub that:
- ✅ Runs entirely offline in your own Roblox game
- ✅ Replaces all remote `HttpGet` calls with local file reads
- ✅ Functions without GitHub dependencies
- ✅ Has executor function guards to prevent crashes

## 📦 Two Execution Methods

Choose the method that works best for you:

### 🔹 [Single-File Method](single-file/) **(Recommended)**
**Best for:** Quick execution, easy setup, most users

- ✅ One file contains everything
- ✅ Just load and run
- ✅ Works with Fluxus, Wave, Synapse X
- ❌ Only includes Universal script (no game-specific features)

**[→ Go to single-file/](single-file/)**

### 🔹 [Multi-File Method](multi-file/) **(Advanced)**
**Best for:** Game-specific features, customization, developers

- ✅ Includes all game-specific scripts (AR2, BB, BRM5, etc.)
- ✅ Modular structure - edit individual components
- ✅ Auto-detects your game
- ⚠️ Requires `readfile` support or internet connection

**[→ Go to multi-file/](multi-file/)**

## ⚙️ Executor Requirements

### ❌ Won't Work
- **Solara** - Missing all required functions (0/20 supported)
- **KRNL** - Outdated
- **JJSploit** - Too limited

### ✅ Will Work
- **Fluxus** (Free, recommended) - Get from [WeAreDevs.net](https://wearedevs.net)
- **Wave** (Free, keyless)
- **Synapse X** (Paid, $20)
- **Script-Ware** (Paid, $20)

## 🚀 Quick Start

1. **Get a compatible executor** (Fluxus recommended)
2. **Choose your method:**
   - **Easy:** Use [single-file/](single-file/) - Load `Parvus.lua` and execute
   - **Advanced:** Use [multi-file/](multi-file/) - Run `Loader.lua` with parameters
3. **Press RightShift** to toggle the menu

## 📚 Documentation

- **[single-file/README.md](single-file/README.md)** - Single-file execution guide
- **[multi-file/README.md](multi-file/README.md)** - Multi-file execution guide
- **[docs/CLAUDE.md](docs/CLAUDE.md)** - Architecture & development guide
- **[docs/CHANGELOG.md](docs/CHANGELOG.md)** - Update history

## 🎮 Features

### Universal Features (Both Methods)
- **Aimbot** - Auto-aim with prediction and sensitivity
- **Silent Aim** - Hit registration modification (multiple modes)
- **Trigger Bot** - Auto-shoot when on target
- **ESP** - Player boxes, tracers, head dots, off-screen arrows
- **FOV Circles** - Visual aim indicators
- **Custom Crosshair** - Fully customizable
- **UI System** - Bracket V2 with config save/load
- **Lighting Controls** - Modify game lighting

### Game-Specific Features (Multi-File Only)
- **Apocalypse Rising 2** - Full feature set (ESP, vehicle mods, walkspeed, etc.)
- **Bad Business** - Auto-shoot, weapon mods, anti-kick
- **Blackhawk Rescue Mission 5** - NPC ESP, teleports
- **Steel Titans** - Fly, tank XRay
- **The Wild West** - Animal/tree ESP
- **Those Who Remain** - Item ESP, unlimited ammo
- **RAGDOLL UNIVERSE** - Combat features

## 🛠️ Development

### Repository Structure
```
Sp3arParvus/
├── single-file/          # Single-file execution method
│   ├── Parvus.lua       # Complete merged script
│   └── README.md        # Usage guide
├── multi-file/          # Multi-file execution method
│   ├── Loader.lua       # Entry point
│   ├── Universal.lua    # Fallback script
│   ├── Utilities/       # Core modules
│   ├── Games/           # Game-specific scripts
│   └── README.md        # Usage guide
├── docs/                # Documentation
│   ├── CLAUDE.md        # Architecture guide
│   └── CHANGELOG.md     # Update history
└── README.md            # This file
```

### Making Changes

See [docs/CLAUDE.md](docs/CLAUDE.md) for:
- Code architecture
- Technical patterns
- Development workflow
- Common issues

## 🐛 Troubleshooting

### Script won't load
- **Check your executor** - Solara won't work, use Fluxus
- **Test executor functions:**
  ```lua
  print(Drawing and "✓ Drawing" or "✗ Missing")
  print(hookmetamethod and "✓ Hooks" or "✗ Missing")
  ```

### Features not working
- Some features require specific executor functions
- The script will disable features automatically if functions are missing
- Check console for warnings

### "Already running" message
- Script is already loaded
- Rejoin the game or restart Roblox

## ⚖️ Legal & Usage

- ✅ **Allowed:** Testing in your own Roblox games you're developing
- ⚠️ **Not recommended:** Using in public games or games you don't own
- 📜 Roblox has stated they don't consider it "exploiting" if you're running scripts in **your own game**

This is for educational purposes and development testing in private game instances.

## 🙏 Credits

- **Original Parvus:** [AlexR32/Parvus](https://github.com/AlexR32/Parvus)
- **UI Framework:** Bracket V2 by el3tric
- **Contributors:** See [docs/CHANGELOG.md](docs/CHANGELOG.md)

## 📞 Support

- **Issues:** Check method-specific READMEs first
- **Executor help:** Visit [WeAreDevs.net](https://wearedevs.net)
- **Original Parvus:** [Discord](https://discord.gg/sYqDpbPYb7)

---

**Version:** Sp3arParvus v1.0 (Localized Fork)
**Based on:** Parvus Hub by AlexR32
**Last Updated:** 2025-11-09
