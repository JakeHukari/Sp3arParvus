# Parvus Hub - Single File Execution

## 📦 What's This?

This is the **easiest way** to run Parvus. Everything is merged into one file - just load and execute.

## 📁 File

- **`Parvus.lua`** - Complete merged script (7,330 lines)
  - All utilities included (Physics, UI, Drawing, Main)
  - Universal game script
  - All executor function guards in place

## ✅ Requirements

### Executor Compatibility

| Executor | Status | Notes |
|----------|--------|-------|
| **Fluxus** | ✅ Recommended | Free, full support, get from WeAreDevs.net |
| **Wave** | ✅ Works | Free, keyless |
| **Synapse X** | ✅ Works | Paid ($20), best stability |
| **Script-Ware** | ✅ Works | Paid ($20) |
| **Solara** | ❌ Won't Work | Missing 20/20 required functions |
| **KRNL** | ⚠️ Outdated | May work but unsupported |

### Required Functions

Your executor MUST have:
- `Drawing` API (for ESP)
- `hookmetamethod` (for silent aim)
- `getnamecallmethod` (for hooks)
- `checkcaller` (for security)

Optional but recommended:
- `mousemoverel` (aimbot)
- `mouse1press`/`mouse1release` (trigger)
- `setclipboard` (copy functions)

## 🚀 How to Use

### Method 1: Load File (Easiest)
1. Open your executor (Fluxus, Wave, etc.)
2. Attach to Roblox
3. Click "Load File" or "Open"
4. Select `Parvus.lua`
5. Click "Execute"

### Method 2: Copy & Paste
1. Open `Parvus.lua` in any text editor
2. Select all (Ctrl+A) and copy (Ctrl+C)
3. Paste into your executor
4. Click "Execute"

## 🎮 Features

- **Aimbot** - Auto-aim with prediction
- **Silent Aim** - Hit registration modification
- **Trigger Bot** - Auto-shoot on target
- **ESP** - Player boxes, tracers, head dots, arrows
- **FOV Circles** - Visual aim indicators
- **Custom UI** - Full menu system (Bracket V2)
- **Config System** - Save/load your settings

## ⌨️ Controls

- **RightShift** - Toggle menu (default)
- Configure keybinds in the UI

## 🐛 Troubleshooting

### "Script already running!"
The script is already loaded. Rejoin the game or restart Roblox.

### "attempt to call a nil value"
Your executor doesn't support required functions. Get Fluxus from WeAreDevs.net.

### ESP not visible
Test if Drawing API works:
```lua
print(Drawing and "✓ Drawing works" or "✗ Drawing missing")
```

### Features disabled
The script will warn you about missing functions and disable those features automatically.

## 📝 Notes

- Only includes the **Universal** script (works in any game)
- Game-specific scripts (AR2, Bad Business, etc.) not included
- If you need game-specific features, use the [multi-file method](../multi-file/)
- All safety guards in place - won't crash if functions are missing

## 🔗 Need the Multi-File Version?

See [`multi-file/`](../multi-file/) for the original structure with game-specific scripts.

---

**Version:** Single-File v1.0
**Last Updated:** 2025-11-09
