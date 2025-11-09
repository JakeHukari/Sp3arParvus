#!/bin/bash

# Build single-file version of Parvus
OUTPUT="Parvus_SingleFile.lua"

echo "--[[" > "$OUTPUT"
echo "    ========================================" >> "$OUTPUT"
echo "    PARVUS HUB - SINGLE FILE VERSION" >> "$OUTPUT"
echo "    ========================================" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "    Merged single-file version for easy execution" >> "$OUTPUT"
echo "    Original: https://github.com/AlexR32/Parvus" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "    REQUIRED FUNCTIONS:" >> "$OUTPUT"
echo "    - Drawing API, hookmetamethod, mousemoverel, etc." >> "$OUTPUT"
echo "    - Will NOT work on limited executors like Solara" >> "$OUTPUT"
echo "    - Use Fluxus, Wave, or Synapse X instead" >> "$OUTPUT"
echo "]]" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Add initialization
cat >> "$OUTPUT" << 'EOF'
repeat task.wait() until game.IsLoaded
repeat task.wait() until game.GameId ~= 0

if Parvus and Parvus.Loaded then
    warn("[Parvus] Already running!")
    return
end

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = PlayerService.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Initialize Parvus global
getgenv().Parvus = {Loaded = false, Utilities = {}}

-- ========================================
-- PHYSICS MODULE
-- ========================================
EOF

# Add Physics module
echo "Parvus.Utilities.Physics = (function()" >> "$OUTPUT"
cat "Utilities/Physics.lua" >> "$OUTPUT"
echo "end)()" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Add Main utilities module
echo "-- ========================================" >> "$OUTPUT"
echo "-- MAIN UTILITIES MODULE" >> "$OUTPUT"
echo "-- ========================================" >> "$OUTPUT"
cat "Utilities/Main.lua" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Add UI module
echo "-- ========================================" >> "$OUTPUT"
echo "-- UI MODULE (Bracket V2)" >> "$OUTPUT"
echo "-- ========================================" >> "$OUTPUT"
echo "Parvus.Utilities.UI = (function()" >> "$OUTPUT"
cat "Utilities/UI.lua" >> "$OUTPUT"
echo "end)()" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Add Drawing module
echo "-- ========================================" >> "$OUTPUT"
echo "-- DRAWING/ESP MODULE" >> "$OUTPUT"
echo "-- ========================================" >> "$OUTPUT"
echo "Parvus.Utilities.Drawing = (function()" >> "$OUTPUT"
cat "Utilities/Drawing.lua" >> "$OUTPUT"
echo "end)()" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Add Universal game script
echo "-- ========================================" >> "$OUTPUT"
echo "-- UNIVERSAL GAME SCRIPT" >> "$OUTPUT"
echo "-- ========================================" >> "$OUTPUT"
cat "Universal.lua" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Add completion
echo "Parvus.Loaded = true" >> "$OUTPUT"
echo 'print("[Parvus] Loaded successfully!")' >> "$OUTPUT"

chmod +x "$OUTPUT"
echo "Build complete: $OUTPUT"
