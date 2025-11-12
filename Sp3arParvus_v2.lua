--[[
================================================================================
SP3ARPARVUS v2 - HYBRID EDITION
================================================================================

CURRENT VERSION: 2.1.1
RELEASE DATE: 2025-11-11
BUILD STATUS: Hybrid Build - Proven Aimbot + Clean Base

================================================================================
VERSIONING SYSTEM (Semantic Versioning)
================================================================================
Format: MAJOR.MINOR.PATCH (e.g., 2.1.3)

MAJOR (X.0.0) - Breaking changes, complete rewrites, fundamental architecture changes
MINOR (2.X.0) - New features, functionality additions, significant improvements
PATCH (2.1.X) - Bug fixes, small tweaks, optimization improvements

RULES:
- EVERY code change MUST bump the version
- Update the changelog below
- Update "CURRENT VERSION" above
- Test thoroughly before committing

================================================================================
CHANGELOG
================================================================================
v2.1.1 (2025-11-11) - Optimized Defaults
  - Updated default configuration based on user testing
  - All aimbot features enabled by default (Always Enabled, Ballistic Prediction, Line of Sight)
  - Silent aim enabled with optimized settings
  - Trigger bot enabled with continuous fire mode
  - Increased projectile velocity to 3155 studs/s
  - Increased maximum ranges to ~1000 studs for all systems
  - ESP max distance increased to 5000 studs
  - Removed team check (Ignore Teammates = OFF) for aggressive targeting
  - Trigger activation delay reduced to 0s for instant response

v2.1.0 (2025-11-11) - Hybrid Build
  - Integrated WORKING aimbot code from original Parvus
  - Added complete silent aim with all metamethod hooks
  - Added trigger bot (auto-fire) functionality
  - Proper UI with all aimbot/silent aim/trigger toggles
  - Ballistics configuration (velocity, gravity, etc.)
  - FOV circles for visual feedback
  - Kept lightweight ESP and performance display
  - Proper cleanup system

v2.0.0 (2025-11-11) - Initial Release
  - Complete rewrite from ground up for stability
  - Lightweight ESP with nametags and tracers
  - Performance display (FPS, Ping, Players)
  - Minimal UI foundation

================================================================================
FEATURES
================================================================================
[Aimbot]
  - Physics-based targeting with ballistic prediction
  - Hold right-click to lock onto targets
  - Customizable FOV, smoothing, and sensitivity
  - Team check and visibility check
  - Target priority (closest, head, torso, etc.)
  - Works with AR2-style games

[Silent Aim]
  - Metamethod hooks for Mouse.Target, Mouse.Hit
  - Raycast redirection (Workspace:Raycast, FindPartOnRay, etc.)
  - Camera method hooks (WorldToViewportPoint, etc.)
  - Accuracy/hit chance control
  - Independent FOV and settings

[Trigger Bot]
  - Auto-fire when enemy in crosshair
  - Continuous fire mode
  - Activation delay
  - Independent FOV and settings

[ESP]
  - Player nametags with distance
  - Tracers from bottom of screen
  - Color-coded by distance
  - Closest player highlighted in pink

[Performance]
  - Real-time FPS counter
  - Ping display
  - Player count

[UI]
  - Draggable window
  - Minimize/maximize buttons
  - Organized sections with toggles and sliders
  - Clean, minimal styling

================================================================================
]]--

-- Version identifier
local VERSION = "2.1.1"
print(string.format("[Sp3arParvus v%s] Loading...", VERSION))

-- Prevent duplicate loading
repeat task.wait() until game:IsLoaded()
local globalEnv = getgenv and getgenv() or _G
if rawget(globalEnv, "Sp3arParvusV2") then
    return warn("[Sp3arParvus v2] Already loaded! Use Shutdown button to cleanup first.")
end

-- Initialize global state
globalEnv.Sp3arParvusV2 = {
    Active = true,
    Version = VERSION,
    Connections = {},
    Threads = {}
}
local Sp3arParvus = globalEnv.Sp3arParvusV2

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")

-- ============================================================
-- LOCAL REFERENCES
-- ============================================================
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Math shortcuts
local abs, floor, max, min, sqrt = math.abs, math.floor, math.max, math.min, math.sqrt
local deg, atan2, rad, sin, cos = math.deg, math.atan2, math.rad, math.sin, math.cos

-- ============================================================
-- CONNECTION TRACKING (for proper cleanup)
-- ============================================================
local function TrackConnection(connection)
    if connection and typeof(connection) == "RBXScriptConnection" then
        table.insert(Sp3arParvus.Connections, connection)
    end
    return connection
end

local function TrackThread(thread)
    if thread and type(thread) == "thread" then
        table.insert(Sp3arParvus.Threads, thread)
    end
    return thread
end

-- ============================================================
-- CONFIGURATION & FLAGS
-- ============================================================

-- Aimbot state variables
local Aimbot, SilentAim, Trigger = false, nil, false
local ProjectileSpeed, ProjectileGravity, GravityCorrection = 3155, 196.2, 2

-- Known body parts for targeting
local KnownBodyParts = {
    "Head", "HumanoidRootPart",
    "Torso", "UpperTorso", "LowerTorso",
    "Right Arm", "RightUpperArm", "RightLowerArm", "RightHand",
    "Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"
}

-- Settings/Flags storage
local Flags = {
    -- Ballistics
    ["Prediction/Velocity"] = 3155,
    ["Prediction/GravityForce"] = 196.2,
    ["Prediction/GravityMultiplier"] = 2,

    -- Aimbot
    ["Aimbot/Enabled"] = true,
    ["Aimbot/AlwaysEnabled"] = true,
    ["Aimbot/Prediction"] = true,
    ["Aimbot/TeamCheck"] = false,
    ["Aimbot/DistanceCheck"] = false,
    ["Aimbot/VisibilityCheck"] = true,
    ["Aimbot/Sensitivity"] = 20,
    ["Aimbot/FOV/Radius"] = 100,
    ["Aimbot/DistanceLimit"] = 981,
    ["Aimbot/Priority"] = "Closest",
    ["Aimbot/BodyParts"] = {"Head", "HumanoidRootPart"},

    -- Silent Aim
    ["SilentAim/Enabled"] = true,
    ["SilentAim/Prediction"] = true,
    ["SilentAim/TeamCheck"] = false,
    ["SilentAim/DistanceCheck"] = false,
    ["SilentAim/VisibilityCheck"] = true,
    ["SilentAim/HitChance"] = 100,
    ["SilentAim/FOV/Radius"] = 100,
    ["SilentAim/DistanceLimit"] = 995,
    ["SilentAim/Priority"] = "Closest",
    ["SilentAim/BodyParts"] = {"Head", "HumanoidRootPart"},
    ["SilentAim/Mode"] = {
        "Raycast", "FindPartOnRayWithIgnoreList",
        "Target", "Hit"
    },

    -- Trigger Bot
    ["Trigger/Enabled"] = true,
    ["Trigger/AlwaysEnabled"] = true,
    ["Trigger/HoldMouseButton"] = true,
    ["Trigger/Prediction"] = true,
    ["Trigger/TeamCheck"] = false,
    ["Trigger/DistanceCheck"] = false,
    ["Trigger/VisibilityCheck"] = true,
    ["Trigger/Delay"] = 0,
    ["Trigger/FOV/Radius"] = 25,
    ["Trigger/DistanceLimit"] = 1000,
    ["Trigger/Priority"] = "Closest",
    ["Trigger/BodyParts"] = {"Head", "HumanoidRootPart"},

    -- ESP
    ["ESP/Enabled"] = true,
    ["ESP/Nametags"] = true,
    ["ESP/Tracers"] = true,
    ["ESP/MaxDistance"] = 5000,

    -- Performance
    ["Performance/Enabled"] = true
}

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Get ping from server stats
local Ping
do
    local serverStats = Stats.Network:FindFirstChild("ServerStatsItem")
    if serverStats then
        local dataPing = serverStats:FindFirstChild("Data Ping")
        if dataPing and type(dataPing.GetValue) == "function" then
            Ping = dataPing
        end
    end
    if not Ping then
        Ping = {GetValue = function() return 0 end}
    end
end

-- FPS counter setup
local function SetupFPS()
    local StartTime, TimeTable, LastTime = os.clock(), {}, nil

    return function()
        LastTime = os.clock()

        for Index = #TimeTable, 1, -1 do
            TimeTable[Index + 1] = TimeTable[Index] >= LastTime - 1 and TimeTable[Index] or nil
        end

        TimeTable[1] = LastTime
        return os.clock() - StartTime >= 1 and #TimeTable or #TimeTable / (os.clock() - StartTime)
    end
end

local GetFPS = SetupFPS()

-- Rejoin current server
local function Rejoin()
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nSp3arParvus v2\nReconnecting...")
        task.wait(0.5)
        TeleportService:Teleport(game.PlaceId)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end
end

-- Track camera changes
TrackConnection(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local newCamera = Workspace.CurrentCamera
    if newCamera then
        Camera = newCamera
    end
end))

-- ============================================================
-- TEAM & CHARACTER DETECTION
-- ============================================================

-- Check if player is on enemy team
local function InEnemyTeam(Enabled, Player)
    if not Enabled then return true end

    -- Standard team check
    if LocalPlayer.Team and Player.Team then
        if LocalPlayer.Team == Player.Team then
            return false
        end
    end

    -- AR2 Squad check
    local success1, localSquad = pcall(function() return LocalPlayer:FindFirstChild("Squad") end)
    local success2, playerSquad = pcall(function() return Player:FindFirstChild("Squad") end)
    if success1 and success2 and localSquad and playerSquad then
        if localSquad.Value == playerSquad.Value and localSquad.Value ~= nil then
            return false
        end
    end

    return true
end

-- Get character and check health (AR2-style)
local function GetCharacter(player)
    if not player then return nil end
    local character = player.Character
    if not character or not character.Parent then return nil end

    local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not rootPart then return nil end

    -- Check if alive (AR2 Stats.Health or standard Humanoid)
    local success, health = pcall(function()
        return player.Stats.Health.Value
    end)

    if success and health and health > 0 then
        return character, rootPart
    end

    -- Fallback to Humanoid check
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return character, rootPart
    end

    return nil
end

-- ============================================================
-- PHYSICS & BALLISTICS
-- ============================================================

-- Solve projectile trajectory with gravity
local function SolveTrajectory(origin, velocity, time, gravity)
    local gravityVector = Vector3.new(0, -gravity * time * time / GravityCorrection, 0)
    return origin + velocity * time + gravityVector
end

-- ============================================================
-- AIMBOT CORE (EXACT CODE FROM WORKING PARVUS)
-- ============================================================

-- Raycast for visibility check
local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Blacklist
WallCheckParams.IgnoreWater = true

local function Raycast(Origin, Direction, Filter)
    WallCheckParams.FilterDescendantsInstances = Filter
    return Workspace:Raycast(Origin, Direction, WallCheckParams)
end

local function WithinReach(Enabled, Distance, Limit)
    if not Enabled then return true end
    return Distance < Limit
end

local function ObjectOccluded(Enabled, Origin, Position, Object)
    if not Enabled then return false end
    return Raycast(Origin, Position - Origin, {Object, LocalPlayer.Character})
end

-- EXACT GetClosest function from working Parvus
local function GetClosest(Enabled,
    TeamCheck, VisibilityCheck, DistanceCheck,
    DistanceLimit, FieldOfView, Priority, BodyParts,
    PredictionEnabled
)
    if not Enabled then return end
    local CameraPosition, Closest = Camera.CFrame.Position, nil

    for Index, Player in ipairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end

        local Character, RootPart = GetCharacter(Player)
        if not Character or not RootPart then continue end
        if not InEnemyTeam(TeamCheck, Player) then continue end

        if Priority == "Random" then
            local BodyPart = Character:FindFirstChild(BodyParts[math.random(#BodyParts)])
            if not BodyPart then continue end

            local BodyPartPosition = BodyPart.Position
            local Distance = (BodyPartPosition - CameraPosition).Magnitude
            BodyPartPosition = PredictionEnabled and SolveTrajectory(BodyPartPosition,
            BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity) or BodyPartPosition
            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
            ScreenPosition = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
            if not OnScreen then continue end

            Distance = (BodyPartPosition - CameraPosition).Magnitude
            if not WithinReach(DistanceCheck, Distance, DistanceLimit) then continue end
            if ObjectOccluded(VisibilityCheck, CameraPosition, BodyPartPosition, Character) then continue end

            local Magnitude = (ScreenPosition - UserInputService:GetMouseLocation()).Magnitude
            if Magnitude >= FieldOfView then continue end

            return {Player, Character, BodyPart, ScreenPosition}
        elseif Priority ~= "Closest" then
            local BodyPart = Character:FindFirstChild(Priority)
            if not BodyPart then continue end

            local BodyPartPosition = BodyPart.Position
            local Distance = (BodyPartPosition - CameraPosition).Magnitude
            BodyPartPosition = PredictionEnabled and SolveTrajectory(BodyPartPosition,
            BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity) or BodyPartPosition
            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
            ScreenPosition = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
            if not OnScreen then continue end

            Distance = (BodyPartPosition - CameraPosition).Magnitude
            if not WithinReach(DistanceCheck, Distance, DistanceLimit) then continue end
            if ObjectOccluded(VisibilityCheck, CameraPosition, BodyPartPosition, Character) then continue end

            local Magnitude = (ScreenPosition - UserInputService:GetMouseLocation()).Magnitude
            if Magnitude >= FieldOfView then continue end

            return {Player, Character, BodyPart, ScreenPosition}
        end

        for Index, BodyPartName in ipairs(BodyParts) do
            local BodyPart = Character:FindFirstChild(BodyPartName)
            if not BodyPart then continue end

            local BodyPartPosition = BodyPart.Position
            local Distance = (BodyPartPosition - CameraPosition).Magnitude
            BodyPartPosition = PredictionEnabled and SolveTrajectory(BodyPartPosition,
            BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity) or BodyPartPosition
            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
            ScreenPosition = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
            if not OnScreen then continue end

            Distance = (BodyPartPosition - CameraPosition).Magnitude
            if not WithinReach(DistanceCheck, Distance, DistanceLimit) then continue end
            if ObjectOccluded(VisibilityCheck, CameraPosition, BodyPartPosition, Character) then continue end

            local Magnitude = (ScreenPosition - UserInputService:GetMouseLocation()).Magnitude
            if Magnitude >= FieldOfView then continue end

            FieldOfView, Closest = Magnitude, {Player, Character, BodyPart, ScreenPosition}
        end
    end

    return Closest
end

-- EXACT AimAt function from working Parvus
local function AimAt(Hitbox, Sensitivity)
    if not Hitbox then return end
    if not mousemoverel then return end
    local MouseLocation = UserInputService:GetMouseLocation()

    mousemoverel(
        (Hitbox[4].X - MouseLocation.X) * Sensitivity,
        (Hitbox[4].Y - MouseLocation.Y) * Sensitivity
    )
end

-- ============================================================
-- SILENT AIM HOOKS (EXACT CODE FROM WORKING PARVUS)
-- ============================================================

local function Pack(...)
    return {n = select('#', ...), ...}
end

-- Hook __index for Mouse.Target and Mouse.Hit
local OldIndex = nil
if hookmetamethod and checkcaller then
    OldIndex = hookmetamethod(game, "__index", function(Self, Index)
        local success, result = pcall(function()
            if checkcaller() then
                return OldIndex(Self, Index)
            end

            if SilentAim and math.random(100) <= Flags["SilentAim/HitChance"] then
                local Mode = Flags["SilentAim/Mode"]
                if Self == Mouse then
                    if Index == "Target" and table.find(Mode, Index) then
                        return SilentAim[3]
                    elseif Index == "Hit" and table.find(Mode, Index) then
                        return SilentAim[3].CFrame
                    end
                end
            end

            return OldIndex(Self, Index)
        end)

        if not success then
            warn("__index hook error:", result)
            return OldIndex(Self, Index)
        end

        return result
    end)
end

-- Hook __namecall for Workspace:Raycast, Camera methods, etc.
local OldNamecall = nil
if hookmetamethod and checkcaller and getnamecallmethod then
    OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
        local args = {...}
        local results = Pack(pcall(function()
            if checkcaller() then
                return OldNamecall(Self, unpack(args))
            end

            if SilentAim and math.random(100) <= Flags["SilentAim/HitChance"] then
                local Method, Mode = getnamecallmethod(), Flags["SilentAim/Mode"]

                if Self == Workspace then
                    if Method == "Raycast" and table.find(Mode, Method) then
                        args[2] = SilentAim[3].Position - args[1]
                        return OldNamecall(Self, unpack(args))
                    elseif (Method == "FindPartOnRayWithIgnoreList" and table.find(Mode, Method))
                    or (Method == "FindPartOnRayWithWhitelist" and table.find(Mode, Method))
                    or (Method == "FindPartOnRay" and table.find(Mode, Method)) then
                        args[1] = Ray.new(args[1].Origin, SilentAim[3].Position - args[1].Origin)
                        return OldNamecall(Self, unpack(args))
                    end
                elseif Self == Camera then
                    if (Method == "ScreenPointToRay" and table.find(Mode, Method))
                    or (Method == "ViewportPointToRay" and table.find(Mode, Method)) then
                        return Ray.new(SilentAim[3].Position, SilentAim[3].Position - Camera.CFrame.Position)
                    elseif (Method == "WorldToScreenPoint" and table.find(Mode, Method))
                    or (Method == "WorldToViewportPoint" and table.find(Mode, Method)) then
                        args[1] = SilentAim[3].Position
                        return OldNamecall(Self, unpack(args))
                    end
                end
            end

            return OldNamecall(Self, unpack(args))
        end))

        if not results[1] then
            warn("__namecall hook error:", results[2])
            return OldNamecall(Self, unpack(args))
        end

        return unpack(results, 2, results.n)
    end)
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================

local ESPObjects = {} -- [Player] = {Nametag, Tracer, Connections}

local CLOSEST_COLOR = Color3.fromRGB(255, 105, 180) -- Pink
local NORMAL_COLOR = Color3.fromRGB(255, 255, 255)  -- White
local TRACER_COLOR = Color3.fromRGB(0, 255, 255)    -- Cyan

-- Create ESP for a player
local function CreateESP(player)
    if ESPObjects[player] then return end
    if player == LocalPlayer then return end

    local espData = {}

    -- Create nametag (BillboardGui)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Nametag"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = nil

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = NORMAL_COLOR
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard

    espData.Nametag = billboard
    espData.NameLabel = nameLabel

    -- Create tracer (Line)
    if Drawing then
        local tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Color = TRACER_COLOR
        tracer.Thickness = 1
        tracer.Transparency = 0.8

        espData.Tracer = tracer
    end

    ESPObjects[player] = espData
end

-- Update ESP for a player
local function UpdateESP(player)
    if not Flags["ESP/Enabled"] then return end

    local espData = ESPObjects[player]
    if not espData then
        CreateESP(player)
        espData = ESPObjects[player]
    end
    if not espData then return end

    -- Get character
    local character, rootPart = GetCharacter(player)
    if not character or not rootPart then
        espData.Nametag.Parent = nil
        if espData.Tracer then espData.Tracer.Visible = false end
        return
    end

    -- Calculate distance
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude

    -- Distance culling
    if distance > Flags["ESP/MaxDistance"] then
        espData.Nametag.Parent = nil
        if espData.Tracer then espData.Tracer.Visible = false end
        return
    end

    -- Update nametag
    if Flags["ESP/Nametags"] then
        espData.Nametag.Adornee = rootPart
        espData.Nametag.Parent = rootPart
        espData.NameLabel.Text = string.format("%s\n[%d]", player.Name, floor(distance))

        -- Find closest player
        local closestPlayer = nil
        local closestDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char, root = GetCharacter(p)
            if char and root then
                local dist = (root.Position - Camera.CFrame.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlayer = p
                end
            end
        end

        if closestPlayer == player then
            espData.NameLabel.TextColor3 = CLOSEST_COLOR
        else
            espData.NameLabel.TextColor3 = NORMAL_COLOR
        end
    else
        espData.Nametag.Parent = nil
    end

    -- Update tracer
    if espData.Tracer and Flags["ESP/Tracers"] then
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if onScreen then
            espData.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            espData.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            espData.Tracer.Visible = true
        else
            espData.Tracer.Visible = false
        end
    elseif espData.Tracer then
        espData.Tracer.Visible = false
    end
end

-- Remove ESP for a player
local function RemoveESP(player)
    local espData = ESPObjects[player]
    if not espData then return end

    if espData.Nametag then
        espData.Nametag:Destroy()
    end
    if espData.Tracer then
        espData.Tracer:Remove()
    end

    ESPObjects[player] = nil
end

-- ============================================================
-- PERFORMANCE DISPLAY
-- ============================================================

local PerformanceLabel

local function CreatePerformanceDisplay(parent)
    PerformanceLabel = Instance.new("TextLabel")
    PerformanceLabel.Name = "PerformanceDisplay"
    PerformanceLabel.Size = UDim2.fromOffset(150, 60)
    PerformanceLabel.Position = UDim2.new(1, -160, 0, 10)
    PerformanceLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    PerformanceLabel.BackgroundTransparency = 0.3
    PerformanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    PerformanceLabel.Font = Enum.Font.Code
    PerformanceLabel.TextSize = 10
    PerformanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    PerformanceLabel.BorderSizePixel = 0
    PerformanceLabel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = PerformanceLabel

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 4)
    padding.Parent = PerformanceLabel
end

local function UpdatePerformanceDisplay()
    if not Flags["Performance/Enabled"] or not PerformanceLabel then return end

    local fps = floor(GetFPS())
    local ping = floor(Ping:GetValue())
    local playerCount = #Players:GetPlayers()

    PerformanceLabel.Text = string.format(
        "FPS: %d\nPing: %d ms\nPlayers: %d",
        fps, ping, playerCount
    )
end

-- ============================================================
-- UI SYSTEM
-- ============================================================

local ScreenGui
local MainFrame
local ContentFrame
local UIVisible = true
local CurrentYOffset = 0

local function CreateUI()
    -- Create ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Sp3arParvusV2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game.CoreGui
    else
        ScreenGui.Parent = game.CoreGui
    end

    -- Create main frame
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.fromOffset(350, 500)
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = MainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.fromOffset(10, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = string.format("Sp3arParvus v%s", VERSION)
    titleLabel.Parent = titleBar

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.fromOffset(20, 20)
    minimizeBtn.Position = UDim2.new(1, -25, 0, 5)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14
    minimizeBtn.Parent = titleBar

    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(0, 4)
    minBtnCorner.Parent = minimizeBtn

    -- Content frame (scrolling)
    ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -20, 1, -40)
    ContentFrame.Position = UDim2.fromOffset(10, 35)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ScrollBarThickness = 4
    ContentFrame.BorderSizePixel = 0
    ContentFrame.CanvasSize = UDim2.fromOffset(0, 0)
    ContentFrame.Parent = MainFrame

    -- Make draggable
    local dragging, dragInput, dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Minimize/maximize functionality
    local isMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            MainFrame.Size = UDim2.fromOffset(350, 30)
            ContentFrame.Visible = false
            minimizeBtn.Text = "+"
        else
            MainFrame.Size = UDim2.fromOffset(350, 500)
            ContentFrame.Visible = true
            minimizeBtn.Text = "−"
        end
    end)

    -- Create performance display
    CreatePerformanceDisplay(ScreenGui)
end

-- Create a section header
local function CreateSection(name)
    local section = Instance.new("Frame")
    section.Name = name .. "Section"
    section.Size = UDim2.new(1, 0, 0, 25)
    section.Position = UDim2.fromOffset(0, CurrentYOffset)
    section.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    section.BorderSizePixel = 0
    section.Parent = ContentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = section

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.fromOffset(10, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = section

    CurrentYOffset = CurrentYOffset + 30
    return section
end

-- Create a toggle
local function CreateToggle(name, flag, defaultValue, callback)
    local toggle = Instance.new("Frame")
    toggle.Name = name .. "Toggle"
    toggle.Size = UDim2.new(1, 0, 0, 30)
    toggle.Position = UDim2.fromOffset(0, CurrentYOffset)
    toggle.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    toggle.BorderSizePixel = 0
    toggle.Parent = ContentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = toggle

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.fromOffset(8, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = toggle

    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Size = UDim2.fromOffset(35, 18)
    button.Position = UDim2.new(1, -40, 0.5, -9)
    button.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 195, 120) or Color3.fromRGB(55, 55, 70)
    button.BorderSizePixel = 0
    button.Text = defaultValue and "ON" or "OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 9
    button.Parent = toggle

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 9)
    btnCorner.Parent = button

    Flags[flag] = defaultValue
    button.MouseButton1Click:Connect(function()
        Flags[flag] = not Flags[flag]
        button.BackgroundColor3 = Flags[flag] and Color3.fromRGB(0, 195, 120) or Color3.fromRGB(55, 55, 70)
        button.Text = Flags[flag] and "ON" or "OFF"
        if callback then callback(Flags[flag]) end
    end)

    CurrentYOffset = CurrentYOffset + 33
    return toggle
end

-- Create a slider
local function CreateSlider(name, flag, min, max, default, unit, callback)
    local slider = Instance.new("Frame")
    slider.Name = name .. "Slider"
    slider.Size = UDim2.new(1, 0, 0, 40)
    slider.Position = UDim2.fromOffset(0, CurrentYOffset)
    slider.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    slider.BorderSizePixel = 0
    slider.Parent = ContentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = slider

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -10, 0, 15)
    label.Position = UDim2.fromOffset(8, 3)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = string.format("%s: %s%s", name, default, unit or "")
    label.Parent = slider

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -16, 0, 4)
    track.Position = UDim2.new(0, 8, 1, -12)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    track.BorderSizePixel = 0
    track.Parent = slider

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 195, 120)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    Flags[flag] = default

    local function UpdateSlider(percentage)
        percentage = math.clamp(percentage, 0, 1)
        local value = floor(min + (max - min) * percentage)
        Flags[flag] = value
        fill.Size = UDim2.new(percentage, 0, 1, 0)
        label.Text = string.format("%s: %s%s", name, value, unit or "")
        if callback then callback(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local percentage = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            UpdateSlider(percentage)

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    connection:Disconnect()
                end
            end)
        end
    end)

    track.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                local percentage = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                UpdateSlider(percentage)
            end
        end
    end)

    CurrentYOffset = CurrentYOffset + 43
    return slider
end

-- Create a button
local function CreateButton(name, callback)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Size = UDim2.new(1, 0, 0, 35)
    button.Position = UDim2.fromOffset(0, CurrentYOffset)
    button.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
    button.BorderSizePixel = 0
    button.Text = name
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.Parent = ContentFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    button.MouseButton1Click:Connect(callback)

    CurrentYOffset = CurrentYOffset + 38
    return button
end

-- ============================================================
-- CLEANUP SYSTEM
-- ============================================================

local function Cleanup()
    print("[Sp3arParvus v2] Shutting down...")

    Sp3arParvus.Active = false

    -- Disconnect all connections
    for _, connection in ipairs(Sp3arParvus.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    Sp3arParvus.Connections = {}

    -- Stop all threads
    for _, thread in ipairs(Sp3arParvus.Threads) do
        pcall(function() task.cancel(thread) end)
    end
    Sp3arParvus.Threads = {}

    -- Remove all ESP
    for player, _ in pairs(ESPObjects) do
        RemoveESP(player)
    end
    ESPObjects = {}

    -- Destroy UI
    if ScreenGui then
        ScreenGui:Destroy()
    end

    -- Clear global
    globalEnv.Sp3arParvusV2 = nil

    print("[Sp3arParvus v2] Shutdown complete")
end

-- ============================================================
-- MAIN INITIALIZATION
-- ============================================================

-- Create UI
CreateUI()

-- BALLISTICS SECTION
CreateSection("Ballistics Configuration")
CreateSlider("Projectile Velocity", "Prediction/Velocity", 1, 10000, 3155, " studs/s", function(value)
    ProjectileSpeed = value
end)
CreateSlider("Gravity Force", "Prediction/GravityForce", 0, 1000, 196.2, "", function(value)
    ProjectileGravity = value
end)
CreateSlider("Gravity Multiplier", "Prediction/GravityMultiplier", 1, 5, 2, "x", function(value)
    GravityCorrection = value
end)

-- AIMBOT SECTION
CreateSection("Aim Assist")
CreateToggle("Enabled", "Aimbot/Enabled", true)
CreateToggle("Always Enabled", "Aimbot/AlwaysEnabled", true)
CreateToggle("Ballistic Prediction", "Aimbot/Prediction", true)
CreateToggle("Ignore Teammates", "Aimbot/TeamCheck", false)
CreateToggle("Line of Sight Check", "Aimbot/VisibilityCheck", true)
CreateSlider("Smoothing", "Aimbot/Sensitivity", 0, 100, 20, "%")
CreateSlider("FOV Radius", "Aimbot/FOV/Radius", 0, 500, 100, "px")
CreateSlider("Maximum Range", "Aimbot/DistanceLimit", 25, 1000, 981, " studs")

-- SILENT AIM SECTION
CreateSection("Precision Targeting (Silent Aim)")
CreateToggle("Enabled", "SilentAim/Enabled", true)
CreateToggle("Ballistic Prediction", "SilentAim/Prediction", true)
CreateToggle("Ignore Teammates", "SilentAim/TeamCheck", false)
CreateToggle("Line of Sight Check", "SilentAim/VisibilityCheck", true)
CreateSlider("Accuracy", "SilentAim/HitChance", 0, 100, 100, "%")
CreateSlider("FOV Radius", "SilentAim/FOV/Radius", 0, 500, 100, "px")
CreateSlider("Maximum Range", "SilentAim/DistanceLimit", 25, 1000, 995, " studs")

-- TRIGGER BOT SECTION
CreateSection("Auto Fire (Trigger Bot)")
CreateToggle("Enabled", "Trigger/Enabled", true)
CreateToggle("Always Enabled", "Trigger/AlwaysEnabled", true)
CreateToggle("Continuous Fire", "Trigger/HoldMouseButton", true)
CreateToggle("Ballistic Prediction", "Trigger/Prediction", true)
CreateToggle("Ignore Teammates", "Trigger/TeamCheck", false)
CreateToggle("Line of Sight Check", "Trigger/VisibilityCheck", true)
CreateSlider("Activation Delay", "Trigger/Delay", 0, 1, 0, "s")
CreateSlider("FOV Radius", "Trigger/FOV/Radius", 0, 500, 25, "px")
CreateSlider("Maximum Range", "Trigger/DistanceLimit", 25, 1000, 1000, " studs")

-- ESP SECTION
CreateSection("ESP")
CreateToggle("ESP Enabled", "ESP/Enabled", true)
CreateToggle("Nametags", "ESP/Nametags", true)
CreateToggle("Tracers", "ESP/Tracers", true)
CreateSlider("Max Distance", "ESP/MaxDistance", 100, 5000, 5000, " studs")

-- PERFORMANCE SECTION
CreateSection("Performance")
CreateToggle("Show Performance", "Performance/Enabled", true, function(state)
    if PerformanceLabel then
        PerformanceLabel.Visible = state
    end
end)

-- UTILITIES SECTION
CreateSection("Utilities")
CreateButton("Rejoin Server", Rejoin)
CreateButton("Shutdown Script", Cleanup)

-- Update canvas size
ContentFrame.CanvasSize = UDim2.fromOffset(0, CurrentYOffset)

-- Setup ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

-- Player added/removed events
TrackConnection(Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end))

TrackConnection(Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end))

-- ============================================================
-- MAIN UPDATE LOOPS
-- ============================================================

-- Aimbot keybind handler
TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aimbot = Flags["Aimbot/Enabled"]
    end
end))

TrackConnection(UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aimbot = false
    end
end))

-- Trigger keybind handler
TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Trigger = Flags["Trigger/Enabled"]
    end
end))

TrackConnection(UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Trigger = false
    end
end))

-- Aimbot update loop (EXACT CODE FROM WORKING PARVUS)
local aimbotThread = task.spawn(function()
    while Sp3arParvus.Active do
        if Aimbot or Flags["Aimbot/AlwaysEnabled"] then
            AimAt(GetClosest(
                Flags["Aimbot/Enabled"],
                Flags["Aimbot/TeamCheck"],
                Flags["Aimbot/VisibilityCheck"],
                Flags["Aimbot/DistanceCheck"],
                Flags["Aimbot/DistanceLimit"],
                Flags["Aimbot/FOV/Radius"],
                Flags["Aimbot/Priority"],
                Flags["Aimbot/BodyParts"],
                Flags["Aimbot/Prediction"]
            ), Flags["Aimbot/Sensitivity"] / 100)
        end
        task.wait()
    end
end)
TrackThread(aimbotThread)

-- Silent aim update loop (EXACT CODE FROM WORKING PARVUS)
local silentAimThread = task.spawn(function()
    while Sp3arParvus.Active do
        SilentAim = GetClosest(
            Flags["SilentAim/Enabled"],
            Flags["SilentAim/TeamCheck"],
            Flags["SilentAim/VisibilityCheck"],
            Flags["SilentAim/DistanceCheck"],
            Flags["SilentAim/DistanceLimit"],
            Flags["SilentAim/FOV/Radius"],
            Flags["SilentAim/Priority"],
            Flags["SilentAim/BodyParts"],
            Flags["SilentAim/Prediction"]
        )
        task.wait()
    end
end)
TrackThread(silentAimThread)

-- Trigger bot loop (EXACT CODE FROM WORKING PARVUS)
local triggerThread = task.spawn(function()
    local MAX_TRIGGER_ITERATIONS = 1000
    while Sp3arParvus.Active do
        if Trigger or Flags["Trigger/AlwaysEnabled"] then
            if isrbxactive and isrbxactive() and mouse1press and mouse1release then
                local TriggerClosest = GetClosest(
                    Flags["Trigger/Enabled"],
                    Flags["Trigger/TeamCheck"],
                    Flags["Trigger/VisibilityCheck"],
                    Flags["Trigger/DistanceCheck"],
                    Flags["Trigger/DistanceLimit"],
                    Flags["Trigger/FOV/Radius"],
                    Flags["Trigger/Priority"],
                    Flags["Trigger/BodyParts"],
                    Flags["Trigger/Prediction"]
                )

                if TriggerClosest then
                    task.wait(Flags["Trigger/Delay"])
                    mouse1press()

                    if Flags["Trigger/HoldMouseButton"] then
                        local iterations = 0
                        while Sp3arParvus.Active and iterations < MAX_TRIGGER_ITERATIONS do
                            iterations = iterations + 1
                            task.wait()
                            TriggerClosest = GetClosest(
                                Flags["Trigger/Enabled"],
                                Flags["Trigger/TeamCheck"],
                                Flags["Trigger/VisibilityCheck"],
                                Flags["Trigger/DistanceCheck"],
                                Flags["Trigger/DistanceLimit"],
                                Flags["Trigger/FOV/Radius"],
                                Flags["Trigger/Priority"],
                                Flags["Trigger/BodyParts"],
                                Flags["Trigger/Prediction"]
                            )

                            if not TriggerClosest or not Trigger then break end
                        end

                        if iterations >= MAX_TRIGGER_ITERATIONS then
                            warn("Trigger loop reached max iterations, resetting state")
                            Trigger = false
                        end
                    end

                    mouse1release()
                end
            end
        end
        task.wait()
    end
end)
TrackThread(triggerThread)

-- ESP update loop
local espThread = task.spawn(function()
    while Sp3arParvus.Active do
        if Flags["ESP/Enabled"] then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    UpdateESP(player)
                end
            end
        end
        task.wait(0.1)
    end
end)
TrackThread(espThread)

-- Performance display update loop
local perfThread = task.spawn(function()
    while Sp3arParvus.Active do
        UpdatePerformanceDisplay()
        task.wait(0.5)
    end
end)
TrackThread(perfThread)

-- ============================================================
-- INITIALIZATION COMPLETE
-- ============================================================

print(string.format("[Sp3arParvus v%s] Loaded successfully!", VERSION))
print(string.format("[Sp3arParvus v%s] Aimbot: %s | Silent Aim: %s | Trigger: %s | ESP: %s",
    VERSION,
    Flags["Aimbot/Enabled"] and "ON" or "OFF",
    Flags["SilentAim/Enabled"] and "ON" or "OFF",
    Flags["Trigger/Enabled"] and "ON" or "OFF",
    Flags["ESP/Enabled"] and "ON" or "OFF"
))
