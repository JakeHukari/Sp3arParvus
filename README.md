# Sp3arParvus - Single File Edition
## loadstring(game:HttpGet("https://raw.githubusercontent.com/JakeHukari/Sp3arParvus/refs/heads/main/Sp3arParvus.lua",true))()
**A fully localized, offline-ready fork of [Parvus Hub](https://github.com/AlexR32/Parvus)** - Complete Roblox development toolkit with game-specific features, optimized for stability and ease of use.

> 🎯 This version combines everything into a single file with comprehensive error handling, making it the most reliable way to run Parvus Hub.

---

## 📋 Table of Contents

- [What's This?](#-whats-this)
- [Recent Fixes](#-recent-fixes-latest-update)
- [Requirements](#-requirements)
- [Features](#combat-features)
- [Game-Specific Support](#-game-specific-support)
- [Controls](#-controls)
- [Troubleshooting](#-troubleshooting
- [Technical Details](#-technical-details)
- [Credits](#-credits)

---

## 🎯 What's This?

Sp3arParvus is a **single-file, self-contained** version of Parvus Hub that:
- ✅ Runs entirely offline in your own Roblox game
- ✅ No GitHub dependencies or remote loading
- ✅ Everything merged into one file - just load and execute
- ✅ Full game detection and game-specific features
- ✅ Comprehensive error handling to prevent crashes
- ✅ Works with Fluxus, Wave, Synapse X, and other major executors

---

## 🆕 Recent Fixes (Latest Update)

This version includes **critical stability fixes** that resolve tens of thousands of error messages:

### Fixed Issues:
1. **✅ AR2 (Apocalypse Rising 2) GetTeam Function**
   - Implemented proper squad/team detection system
   - Fixed ESP not working for AR2 players
   - Added error handling for squad data retrieval

2. **✅ Bad Business Module Loading**
   - Added safety checks for `getupvalue` function
   - Graceful fallback if Tortoiseshell module unavailable
   - Protected all character/team lookups

3. **✅ Blackhawk Rescue Mission 5**
   - Added 30-second timeout for module loading
   - Protected `getmodules()` calls
   - No more infinite loops on module load failure

4. **✅ ESP Rendering Protection**
   - Wrapped all ESP updates in error handlers
   - One player's error won't affect others
   - Automatic ESP hiding on error to prevent visual glitches

5. **✅ All Game-Specific Functions**
   - Added `pcall` protection to GetHealth, GetTeam, GetWeapon
   - Safe fallback values when data unavailable
   - Prevents cascading errors in rendering loops

---

## ✅ Requirements

### Required Executor Functions
Your executor **MUST** have these functions for full functionality:

**Essential (Script won't work without these):**
- ✅ `Drawing` API (for ESP/visuals)
- ✅ `game` and game services access
- ✅ `task.wait()` and task library

**Highly Recommended (Most features need these):**
- ✅ `hookmetamethod` (for silent aim)
- ✅ `getnamecallmethod` (for hooks)
- ✅ `checkcaller` (for security)

**Optional (Enhanced features):**
- ⭐ `mousemoverel` (for aimbot)
- ⭐ `mouse1press`/`mouse1release` (for triggerbot)
- ⭐ `setclipboard` (for copy functions)
- ⭐ `getupvalue` (for Bad Business)
- ⭐ `getmodules` (for Blackhawk Rescue Mission 5)
- ⭐ `sethiddenproperty` (for terrain decoration)
- ⭐ `isrbxactive` (for window focus detection)

---

### Combat Features

#### **Aimbot**
- Auto-aim with prediction and sensitivity control
- Customizable FOV (Field of View) circle
- Distance check and team check
- Visibility check (only aim at visible targets)
- Body part selection (head, torso, limbs, etc.)
- Priority system (closest, random, or specific body part)
- Keybind toggle support

#### **Silent Aim**
- Hit registration modification without moving camera
- Multiple hook modes:
  - FindPartOnRayWithIgnoreList
  - FindPartOnRayWithWhitelist
  - Raycast
  - Mouse.Target and Mouse.Hit
  - WorldToViewportPoint/WorldToScreenPoint
  - And more...
- Hit chance percentage
- Prediction support
- Customizable FOV circle

#### **Triggerbot**
- Auto-shoot when aiming at target
- Configurable click delay
- Hold mouse button mode
- FOV-based targeting
- Team and visibility checks

### Visual Features

#### **ESP (Extra Sensory Perception)**
- **Player Boxes** - Corner brackets around players
  - Filled or outline mode
  - Adjustable thickness and transparency
  - Corner size customization
  - Healthbar display
- **Head Dots** - Circles on player heads
  - Autoscale with distance
  - Adjustable radius and sides
  - Filled or outline
- **Tracers** - Lines to players
  - From bottom or mouse position
  - Thickness and transparency control
- **Offscreen Arrows** - Indicators for players outside view
  - Adjustable size and distance from center
  - Filled or outline
- **Player Info Text**
  - Name, health, distance, weapon
  - Autoscale with distance
  - Outline for readability

#### **FOV Circles**
- Visual indicators for aimbot, silent aim, and triggerbot
- Customizable colors with transparency
- Filled or outline mode
- Adjustable thickness and sides
- Independent settings for each feature

#### **Custom Crosshair**
- Fully customizable size, gap, and color
- Always centered on screen
- Works independently of game crosshair

### UI Features

#### **Bracket V2 Interface**
- Clean, modern design
- Tabbed organization
- Smooth animations
- Color customization
- Multiple background options (30+ patterns)
- Background tile settings (offset/scale)
- Blur gameplay option
- Watermark with FPS and ping
- Keybind list display

#### **Script Control (NEW in v1.0.0)**
- **Reload Script** - Completely refresh the script
  - Cleans up all UI elements and ESP objects
  - Reloads fresh copy from GitHub
  - Fixes any broken state without rejoining game
  - Preserves executor environment
- **Shutdown Script** - Gracefully unload everything
  - Removes all UI and ESP
  - Restores broken parts from Br3ak3r
  - Cleans up all resources and global state
  - Complete teardown with no residue
- **Version Display** - Always see current version in UI

#### **Config System**
- Auto-save settings
- Multiple config slots
- Import/export configs
- Per-game configs
- Auto-load on startup

### Lighting Control

Modify game lighting in real-time:
- Ambient color
- Brightness
- Clock time (day/night)
- Color shift (top/bottom)
- Fog settings
- Global shadows toggle
- Terrain decoration toggle
- And more...

---

## 🎯 Game-Specific Support

### Universal (All Games)
Works in **any** Roblox game with standard character models:
- Full ESP system
- Aimbot, Silent Aim, Triggerbot
- All visual features
- Custom crosshair

### Apocalypse Rising 2 ⭐ **FIXED**
- Custom health tracking (including health bonuses)
- Squad/team detection system
- Weapon detection from equipped items
- All combat features
- Full ESP support

### Bad Business ⭐ **FIXED**
- Team detection using Tortoiseshell API
- Character tracking system
- Weapon from backpack
- Team color ESP
- FFA (Free For All) detection
- All combat features with safe fallbacks

### Blackhawk Rescue Mission 5 ⭐ **FIXED**
- Skirmish team detection
- NPC vs Player ESP
- Round interface integration
- Team-based targeting
- Proximity prompt detection

### RAGDOLL UNIVERSE
- Custom character detection
- Team value checking
- Body part color ESP
- Tool detection

### Steel Titans
- Tank character detection
- Tank health system
- Vehicle-based ESP
- Tank XRay support

### The Wild West
- Standard character support
- All universal features
- Custom weapon detection

### Those Who Remain
- Custom health tracking
- Item ESP
- Unlimited ammo support
- Custom weapon system

---

## ⌨️ Controls

### Default Keybinds
- **RightShift** - Toggle menu
- **MouseButton2** (Right Click) - Aimbot/Triggerbot toggle (when enabled)

### Customizable
All keybinds can be changed in the UI. Click on any keybind button and press your desired key.

### Menu Navigation
- **Mouse** - Navigate menu
- **Left Click** - Select/Toggle options
- **Drag** - Move menu (drag from title bar)
- **Scroll** - Scroll through sections

---

## 🐛 Troubleshooting

### Script Already Running
**Error:** "Script already running!" or "Parvus already loaded"
**Solution:** Rejoin the game or restart Roblox

### Executor Functions Missing
**Error:** "attempt to call a nil value" or features not working
**Solution:**
1. Check executor compatibility (see Requirements section)
2. Use Fluxus if your current executor doesn't work
3. The script will automatically disable features that require missing functions

### ESP Not Visible
**Symptoms:** Can't see boxes, tracers, or other ESP elements
**Solutions:**
1. Test Drawing API:
   ```lua
   print(Drawing and "✓ Drawing works" or "✗ Drawing missing")
   ```
2. If Drawing is missing, your executor doesn't support it
3. Try toggling ESP on/off
4. Check if distance limit is too low

### Features Disabled
**Symptoms:** Some features grayed out or not working
**Cause:** Your executor is missing required functions for those features
**Solution:**
- Use a better executor (Fluxus recommended)
- The script automatically detects and disables unsupported features
- Check console for warnings about missing functions

### AR2 Features Not Working
**Fixed in latest version!** If you still have issues:
1. Make sure you're using the latest version of Sp3arParvus.lua
2. Check console for "[Parvus]" messages
3. Verify you're in Apocalypse Rising 2 (game ID 358276974 or 3495983524)

### Bad Business Errors
**Fixed in latest version!** If you still have issues:
1. Ensure your executor supports `getupvalue`
2. The script will automatically fall back to basic features if getupvalue is unavailable
3. Check console for "[Parvus]" messages

### FPS Drops
**Symptoms:** Game becomes laggy when script is running
**Solutions:**
1. Disable unused ESP features
2. Increase distance limits (render fewer objects)
3. Disable filled shapes (use outline only)
4. Disable blur gameplay
5. Reduce FOV circle NumSides

### Aimbot Not Smooth
**Symptoms:** Aimbot is jittery or too fast
**Solutions:**
1. Increase sensitivity (higher = slower movement)
2. Check if prediction is enabled (disable if not needed)
3. Reduce FOV radius
4. Enable distance check with appropriate limit

---

## 🔧 Technical Details

### Architecture

**Single-File Structure:**
```
Sp3arParvus.lua (7,400+ lines)
├── Physics Module (Trajectory calculation)
├── Main Utilities (Core functions)
├── UI Module (Bracket V2)
├── Drawing Library (ESP system)
├── Game Detection
├── Game-Specific Modules
│   ├── Bad Business
│   ├── Apocalypse Rising 2
│   ├── Blackhawk Rescue Mission 5
│   ├── RAGDOLL UNIVERSE
│   ├── Steel Titans
│   └── Others
└── Universal Game Script
```

### Error Handling

The script includes multiple layers of error protection:

1. **Function Guards**
   - Checks for executor function availability
   - Automatic feature disabling if functions missing
   - No crashes from nil function calls

2. **Game-Specific Pcall Wrapping**
   - All GetHealth, GetTeam, GetWeapon functions wrapped
   - Safe fallback values (100 HP, enemy team, "Hands")
   - Module loading with timeout protection

3. **Rendering Loop Protection**
   - Each ESP object updated independently
   - One error doesn't affect other players
   - Automatic ESP hiding on error

4. **Module Loading Safety**
   - Timeout protection (30 seconds for BRM5)
   - Graceful degradation if modules unavailable
   - Console warnings for failed loads

### Performance Optimization

- Cached math functions (sin, cos, etc.)
- Cached service lookups
- Efficient Drawing API usage
- Minimal garbage collection
- Frame-independent updates

### Memory Management

- Weak table metatables for ESP objects
- Automatic cleanup on player removal
- Drawing object pooling
- Connection management

---

## 💾 Configuration

### Config Locations
Configs are saved in your executor's workspace folder:
- `[Executor]/workspace/Bracket/Parvus_[GameId].txt`

### Auto-Loading
Enable "Open On Load" in Options to automatically open UI on script load.

### Saving Configs
1. Click "Config" section in Options tab
2. Enter config name
3. Click "Save Config"
4. Your settings are now saved!

### Loading Configs
1. Click dropdown in Config section
2. Select your config
3. Click "Load Config"
4. Settings applied!

---

## ⚖️ Legal & Usage

### Allowed Usage
- ✅ Testing in **your own** Roblox games during development
- ✅ Private game instances you own
- ✅ Educational purposes and learning
- ✅ Testing game security (your own games)

### Not Recommended
- ⚠️ Using in public games or games you don't own
- ⚠️ Commercial use without permission
- ⚠️ Ruining other players' experience

### Disclaimer
- This tool is for educational and development testing purposes
- Roblox has stated they don't consider it "exploiting" if you're running scripts in **your own game**
- Use responsibly and ethically
- The developers are not responsible for misuse

---

## 🙏 Credits

### Original Authors
- **AlexR32** - Original Parvus Hub
  - GitHub: [AlexR32/Parvus](https://github.com/AlexR32/Parvus)
  - Discord: sYqDpbPYb7

### Special Thanks
- **el3tric** - Bracket V2 UI Framework
- **Jan** @ v3rmillion.net - Background patterns
- **CornCatCornDog** @ v3rmillion.net - Offscreen arrows
- **mickeyrbx** @ v3rmillion.net - CalculateBox function
- **Kiriot22** @ v3rmillion.net - Anti-plugin crash
- **piqey** (John Kushmer) - lua-polynomials (trajectory math)

### Contributors
- All testers and bug reporters
- Community feedback and suggestions
- Open source contributors

---
## 📝 Version Information

**Current Version:** Sp3arParvus v1.0.0
**Based on:** Parvus Hub by AlexR32
**Last Updated:** 2025-11-09
**Script Size:** ~8,140 lines
**File Size:** ~320 KB

**Version Format:** MAJOR.MINOR.PATCH (e.g., 1.0.0)
- Each update increments the PATCH version by 1 (e.g., 1.0.0 → 1.0.1)
- Version is displayed in UI title, console logs, and all documentation

### Changelog

**v1.0.0 (2025-11-09) - Comprehensive Audit & Fixes**
  - 🔧 **CRITICAL FIX:** Resolved all scoping issues causing "attempt to call a nil value" errors
    - Moved all Misc feature variables and functions outside Window scope
    - Fixed Window variable declaration (removed incorrect `local` scope)
    - All functions now properly accessible throughout script lifecycle
  - ✨ **NEW: Reload Feature** - Completely refresh the script without rejoining
    - Cleans up all UI, ESP, and resources
    - Preserves executor environment
    - Accessible from Miscellaneous → Script Control
  - ✨ **NEW: Shutdown Feature** - Gracefully unload script and restore modified parts
    - Removes all UI elements and ESP objects
    - Restores broken parts from Br3ak3r
    - Cleans up global state completely
  - 📌 **Versioning System** - Track updates across all instances
    - Version constant at script top (SP3ARPARVUS_VERSION)
    - Displayed in Window title: "Sp3arParvus v1.0.0"
    - Shown in console logs and Script Control section
    - Documentation synchronized with script version
  - ✅ Fixed AR2 missing GetTeam function (squad detection)
  - ✅ Fixed Bad Business getupvalue crashes
  - ✅ Fixed Blackhawk Rescue Mission infinite loop
  - ✅ Added comprehensive error handling to ESP system
  - ✅ Protected all game-specific functions with pcall
  - ✅ Added timeout protection to module loading
  - ✅ Improved stability across all supported games
  - 📚 Enhanced code organization with clear section markers

---

## 🎯 Quick Reference Card

**Load Script:** Load file or paste code → Execute
**Open Menu:** RightShift
**Aimbot:** Combat → Aimbot → Enable → Hold Right Click
**Silent Aim:** Combat → Silent Aim → Enable
**ESP:** Visuals → ESP → Enable features
**Save Settings:** Options → Config → Save
**Change Keybinds:** Click any keybind button → Press new key
**Reload Script:** Miscellaneous → Script Control → Reload Script
**Shutdown Script:** Miscellaneous → Script Control → Shutdown Script
**Check Version:** Miscellaneous → Script Control (shows version)
**Fix Errors:** Update to latest version, try Reload Script feature

---

**Made with ❤️ by the Parvus community**
**For educational and development purposes only**
