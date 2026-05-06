# <p align="center">Sp3arParvus</p>

<p align="center">
  <strong>Universal Expansion Script for Roblox games.</strong><br>
  <em>Performance-optimized client-sided tools for combat & development.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/JakeHukari/Sp3arParvus?style=for-the-badge&color=00c8ff" alt="Stars">
  <img src="https://img.shields.io/github/forks/JakeHukari/Sp3arParvus?style=for-the-badge&color=00c8ff" alt="Forks">
  <img src="https://img.shields.io/github/license/JakeHukari/Sp3arParvus?style=for-the-badge&color=00c8ff" alt="License">
</p>


## Overview

Sp3arParvus is a lua client designed to enhance your in-game senses with universal player tracking, bullet prediction, and various utility tools. Sp3arParvus provides an easy to use interface with minimal performance impact.

### UI Demo

<p align="center">
  <img src=".github\Sp3arParvusUI.png" width="800" alt="Sp3arParvus UI Mockup">
  <br>
</p>


## How to use

Copy the loadstring below:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/JakeHukari/Sp3arParvus/refs/heads/main/Sp3arParvus.lua", true))()
```

Paste the loadstring into an executor [e.g. [Solara](https://getsolara.dev/), Wave, Delta] or use any other method of executing scripts in your workspace

Upon execution, the Sp3arParvus client will immediately begin enhancing the user.

## Features

### Combat & Accuracy
*   **Silent Aim**: Hit your targets without snapping your camera.
*   **TriggerBot**: Automatic firing when a target is detected.
*   **Physics Prediction**: Advanced velocity and gravity correction for projectiles (3155 velocity default).
*   **Target Indicators**: Dynamic head and root dots that turn **Red** when locked-on by the aimbot.

### Visuals & ESP
*   **Gh0st Mode**: Turns off all UI elements while still allowing functions like aimbot and br3ak3r.
*   **Player ESP**: Full hitbox, nametag, distance tracking, and team tracking.
    *   **Distance-based Coloring**: Color-coded proximity: **Pink** (Closest), **Red** (≤2000 studs), **Yellow** (≤4000 studs), and **Green** (>4000 studs).
    *   **Health HUD**: Numerical health display and real-time health bars on player nametags.
    *   **Equipped Item**: View the currently equipped items being held by nearby players.
*   **Player Panel**: View the Top 10 closest players with names, distances, and 2D direction arrows.
*   **Fullbright**: Sets the workspace lighting to maximum brightness & removes shadows, fog, and other ambient lighting effects.
*   **FullDark**: Sets the workspace lighting to minimum brightness.
*   **[Any-Item-ESP](https://github.com/JakeHukari/Any-Item-ESP)**: Create ESP tracking for any item, folder, or group of items in your workspace.

### Developer Utilities
*   **World Humanoid Editor**: Edit properties (WalkSpeed, JumpPower, Health, etc.) of any non-local Humanoid or NPC in the game.
*   **Br3ak3r (Wallbreak)**: Remove annoying obstacles, analyze map structure, or walk through walls.
*   **H1ghL1ghter**: Highlight parts and get full workspace path nametags.
*   **D3v Tool**: Real-time HUD displaying World Time, Local Player Coordinates (LPC), and Mouse Coordinates (LMC).
*   **Waypoint System**: Create and manage custom map markers, visible from anywhere.
*   **Free-cam**: Cinematic exploration for creators or tactical scouting.
*   **Performance Monitor**: Real-time FPS, ping, memory usage, and object counts (Broken/Highlighted).
*   **Humanoid Editor**: Edit LocalPlayer humanoid properties like walkspeed, jump power, max-slope-angle, health, etc.

## Shortcut Keys

### UI & Configuration
*   **Menu Visibility**: `CapsLock`
*   **Menu Minimize/Maximize**: `Ctrl + -`
*   **Gh0st Mode**: `Ctrl + G`
*   **Rejoin Server**: `Ctrl + R`
*   **Unload Sp3arParvus**: `Ctrl + U`

### Combat & Accuracy
*   **Aimbot Lock-on**: Hold `Right Mouse Button` (When "Always Active" is OFF)

### Visuals & ESP
*   **[Any-Item-ESP](https://github.com/JakeHukari/Any-Item-ESP)**: `Ctrl + E`
*   **Fullbright**: `Ctrl + F`
*   **FullDark**: `Ctrl + N`
*   **Free-cam**: `Ctrl + P`
*   **Waypoints**: `Ctrl + Middle Mouse Button` to **Create**, `Ctrl + Middle Mouse Button` (On existing waypoint) to **Delete**

### Developer Utilities
*   **D3v Tool**: `Ctrl + .` (Period)
*   **Br3ak3r**: `Ctrl + Left Click` to **Br3ak** objects, `Ctrl + B` to **Toggle** tool, `Ctrl + Z` to **Undo** last break, `Ctrl + X` to **Clear All** breaks
*   **H1ghL1ghter**: `Ctrl + Shift + Left-Click` to **Highlight** parts, `Ctrl + Shift + Z` to **Undo** last highlight


## Community & Contributing

Any contributions are welcome! If you have ideas for new features or have found any bugs, please check out our:
- [Contributing Guidelines](.github\CONTRIBUTING.md)
- [Bug Report Template](.github/ISSUE_TEMPLATE/bug_report.md)
- [Feature Request Template](.github/ISSUE_TEMPLATE/feature_request.md)
- [Licensed under MIT](LICENSE)


## Disclaimer

**For educational and development purposes only.** Sp3arParvus is intended for game developers and researchers to understand Lua environment interactions.

---

<p align="center">
  Made by <a href="https://github.com/JakeHukari">Jake Hukari</a><br>
  Special thanks to <a href="https://github.com/AlexR32">@AlexR32</a> (creator of Parvus)
</p>
