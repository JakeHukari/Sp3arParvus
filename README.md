# <p align="center">Sp3arParvus</p>

<p align="center">
  <strong>Advanced Developer & Debugging Suite for Lua Games</strong><br>
  <em>Performance-optimized, client-sided tools for environment analysis, bug hunting, and interaction testing.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/JakeHukari/Sp3arParvus?style=for-the-badge&color=fc95af" alt="Stars">
  <img src="https://img.shields.io/github/forks/JakeHukari/Sp3arParvus?style=for-the-badge&color=fc95af" alt="Forks">
  <img src="https://img.shields.io/github/license/JakeHukari/Sp3arParvus?style=for-the-badge&color=fc95af" alt="License">
</p>

## Overview

Sp3arParvus is a comprehensive Lua-based debugging suite designed for Roblox developers. It empowers creators to inspect game environments, test interaction limits, monitor performance, and validate network boundaries in real-time. With a minimal performance footprint, Sp3arParvus provides an intuitive UI to manage game states safely without interrupting development.

### UI Demo

<p align="center">
  <img src=".github\Sp3arParvusUI.png" width="800" alt="Sp3arParvus UI Mockup">
  <br>
</p>

## How to Use

Copy the loader script below:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JakeHukari/Sp3arParvus/refs/heads/main/Sp3arParvus.lua", true))()
```

Execute the script in your testing environment workspace. 

> [!TIP]
> **Safe Mode:** Sp3arParvus includes a built-in `SAFE_MODE` flag at the top of the script. By default, `SAFE_MODE = false`. Set this to `true` to safely disable high-risk input simulation features (like automated clicks or instant position changes) to prevent triggering Roblox's automated anti-cheat systems during routine development testing.

## Features

### Interaction & Input Testing
*   **Camera Tracking Assistant**: Smoothing-based viewport tracking to automatically focus the camera on nearby targets, simulating player focus.
*   **Input Simulation**: Automated click simulation for testing UI interactions, hitboxes, and event triggers without manual repetition.
*   **Target Indicators**: Dynamic Indicators on target parts that turn **Red** when focused by the camera tracking system.
*   **Position-Force**: Instantly move your humanoid in any direction using direction inputs.

### Visuals & Analytics
*   **Gh0st Mode**: Removes obstructive UI elements to provide a cleaner debugging experience.
*   **Player Visualization**: Full humanoidHitbox rendering, playerTags with user info, worldDistance tracking, and playerTeam identification.
    *   **Distance-based Sorting**: Color-coded proximity: **Pink** (Closest), **Red** (≤750 studs), **Yellow** (≤1875 studs), and **Green** (>1875 studs).
    *   **Health HUD**: Numerical health display and real-time health bars on player nametags.
    *   **Equipped Item Viewer**: View the currently equipped items being held by nearby players.
*   **Closest Player Tracker**: Real-time HUD displaying the nearest player's name and worldDistance.
*   **Local Health HUD**: Compact display of your current character health and max health.
*   **worldLighting Modifiers**: Toggle `Fullbright` (maximum brightness, no shadows/fog) or `FullDark` (minimum brightness) to test visibility in extreme lighting conditions.
*   **[Any-Item-ESP](https://github.com/JakeHukari/Any-Item-ESP)**: Create visual markers for any item, folder, or instance group in your workspace to track spawns and replication.

### Developer Utilities
*   **PlayerPage**: Comprehensive player management including whitelisting, blacklisting, and detailed property viewing/spectating for testing moderation and replication.
*   **Item Panel**: Robust item explorer and property editor for backpack and character tools.
*   **World Humanoid Editor**: Edit properties (WalkSpeed, JumpPower, Health, etc.) of any non-local Humanoid or NPC to test AI behavior and limits.
*   **Br3ak3r (Collision Debugger)**: Isolate map geometry, remove physical obstacles, and disable collisions to analyze map structure and walk through walls.
*   **H1ghL1ghter**: Highlight specific parts and instantly retrieve their full workspace paths.
*   **D3v Tool**: Real-time HUD displaying World Time, Local Player Coordinates (LPC), and Mouse Coordinates (LMC).
*   **Waypoint System**: Create and manage custom 3D map markers visible from anywhere in the scene.
*   **Free-cam**: Cinematic, detached camera exploration for map scouting and recording.
*   **Performance Monitor**: Real-time FPS, ping, memory usage, and custom object counts (Broken/Highlighted instances).
*   **Humanoid Editor**: Directly override your LocalPlayer's humanoid properties (WalkSpeed, JumpPower, MaxSlopeAngle) to test movement edge cases.
*   **Anti-AFK**: Built-in mechanism to prevent idle disconnections during long observation sessions.
*   **Scroll-unlocker**: Dynamically unlocks camera zoom limits, useful for surveying large maps.
*   **Q-Teleport**: Quick teleportation to mouse cursor position (Press Ctrl+Q) for rapid map traversal.

## Shortcut Keys

### UI & Configuration
*   **Menu Visibility**: `CapsLock`
*   **Menu Minimize/Maximize**: `Ctrl + -`
*   **Gh0st Mode**: `Ctrl + G`
*   **Rejoin Server**: `Ctrl + R`
*   **Unload Sp3arParvus**: `Ctrl + U`

### Interaction & Testing
*   **Camera Tracking Toggle**: `Ctrl + ~`
*   **Camera Tracking Lock-on**: Hold `Right Mouse Button` (When "Always Active" is OFF)
*   **Mouse Teleport**: `Ctrl + Q` to teleport to mouse position
*   **Teleport to Last Waypoint**: `Ctrl + Y`
*   **Toggle Full-Body Camera Tracking**: `Ctrl + H`
*   **Position-Force**: `Ctrl` + `Up↑`, `Down↓`, `Left←`, `Right→` (Arrow keys)

### Visuals & Analytics
*   **[Any-Item-ESP](https://github.com/JakeHukari/Any-Item-ESP)**: `Ctrl + E`
*   **Fullbright**: `Ctrl + F`
*   **FullDark**: `Ctrl + N`
*   **Free-cam**: `Ctrl + P`

### Waypoints
*   **Create Waypoint**: `Ctrl + Middle Mouse Button`
*   **Delete Waypoint**: `Ctrl + Middle Mouse Button` (On existing waypoint)
*   **Teleport to Last-Created Waypoint**: `Ctrl + Y`
*   **Delete all existing waypoints**: `Ctrl + Shift + Middle Mouse Button`

### Developer Utilities
*   **PlayerPage**: `Ctrl + K`
*   **Item Panel**: `Ctrl + J`
*   **D3v Tool**: `Ctrl + .` (Period)
*   **Br3ak3r**: `Ctrl + Left Click` to **Break** objects, `Ctrl + B` to **Toggle** tool, `Ctrl + Z` to **Undo** last break, `Ctrl + X` to **Clear All** breaks
*   **H1ghL1ghter**: `Ctrl + Shift + Left-Click` to **Highlight** parts, `Ctrl + Shift + Z` to **Undo** last highlight

### Free-cam Controls
*   **Free-cam Toggle**: `Ctrl + P`
*   **Camera Movement**: `W`, `A`, `S`, `D`, `Q` (Down), `E` (Up)
*   **Humanoid Movement**: `U`, `H`, `J`, `K`, `Space` (Jump)
*   **Camera Speed Clutch**: `Left Shift`
*   **Fov Control**: `Mouse Wheel`
*   **Humanoid Crash**: `I`
*   **Reset Humanoid**: `Y`
*   **Camera Speed**: `↑/↓ (Arrow keys)`
*   **Teleport Humanoid to Camera Position**: `Ctrl + T`


## Community & Contributing

Any contributions are welcome! If you have ideas for new features or have found any bugs, please check out our:
- [Contributing Guidelines](.github\CONTRIBUTING.md)
- [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md)
- [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md)
- [Licensed under MIT](LICENSE)

## Disclaimer

**For educational and development purposes only.** Sp3arParvus is strictly intended for game developers, QA testers, and researchers to understand Lua environment interactions, test anti-cheat measures, and debug their own games. Misuse of this tool on games where you lack explicit permission may violate Terms of Service.

---

<p align="center">
  Made by <a href="https://github.com/JakeHukari">Jake Hukari</a><br>
  Special thanks to <a href="https://github.com/AlexR32">@AlexR32</a> (creator of Parvus)
</p>
