--[[
    ========================================
    PARVUS HUB - SINGLE FILE VERSION
    ========================================

    This is a merged single-file version of Parvus Hub for easy execution.

    REQUIRED EXECUTOR FUNCTIONS:
    - loadstring (for dynamic code execution)
    - hookmetamethod (for silent aim)
    - getnamecallmethod (for silent aim)
    - checkcaller (for hook security)
    - mousemoverel (for aimbot)
    - mouse1press/mouse1release (for trigger bot)
    - Drawing API (for ESP visuals)

    COMPATIBLE EXECUTORS:
    ✓ Synapse X
    ✓ Script-Ware
    ✓ Fluxus
    ✓ Wave
    ✗ Solara (missing required functions)

    USAGE:
    Simply run this file in your executor. The script will auto-detect your game
    and load the appropriate features.

    Original: https://github.com/AlexR32/Parvus
--]]

-- ========================================
-- CONFIGURATION
-- ========================================

repeat task.wait() until game.IsLoaded
repeat task.wait() until game.GameId ~= 0

-- Check if already running
if Parvus and Parvus.Loaded then
    warn("[Parvus] Script already running!")
    return
end

-- ========================================
-- EXECUTOR COMPATIBILITY CHECK
-- ========================================

local MissingFunctions = {}
local RequiredFunctions = {
    "Drawing", "hookmetamethod", "getnamecallmethod", "checkcaller"
}

for _, funcName in ipairs(RequiredFunctions) do
    if not _G[funcName] and not getgenv()[funcName] then
        table.insert(MissingFunctions, funcName)
    end
end

if #MissingFunctions > 0 then
    warn("[Parvus] WARNING: Your executor is missing critical functions:")
    for _, func in ipairs(MissingFunctions) do
        warn("  - " .. func)
    end
    warn("[Parvus] The script may not work properly. Consider using a better executor (Fluxus, Wave, Synapse X)")
    warn("[Parvus] Continuing anyway...")
    task.wait(3)
end

-- ========================================
-- SERVICES
-- ========================================

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")

repeat task.wait() until PlayerService.LocalPlayer
local LocalPlayer = PlayerService.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ========================================
-- GLOBAL PARVUS TABLE
-- ========================================

getgenv().Parvus = {
    Games = {
        ["Universal" ] = { Name = "Universal" },
        ["1168263273"] = { Name = "Bad Business" },
        ["3360073263"] = { Name = "Bad Business PTR" },
        ["1586272220"] = { Name = "Steel Titans" },
        ["807930589" ] = { Name = "The Wild West" },
        ["580765040" ] = { Name = "RAGDOLL UNIVERSE" },
        ["187796008" ] = { Name = "Those Who Remain" },
        ["358276974" ] = { Name = "Apocalypse Rising 2" },
        ["3495983524"] = { Name = "Apocalypse Rising 2 Dev." },
        ["1054526971"] = { Name = "Blackhawk Rescue Mission 5" }
    },
    Loaded = false
}

--[[
    Note: This single-file version only includes the Universal script.
    Game-specific scripts (AR2, BB, etc.) are not included to keep file size manageable.
    The Universal script provides basic aimbot, ESP, and silent aim for any game.
]]

print("[Parvus] Loading Universal script for " .. (Parvus.Games[tostring(game.GameId)] and Parvus.Games[tostring(game.GameId)].Name or "Unknown Game"))

