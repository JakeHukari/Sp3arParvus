-- Sp3arParvus
local VERSION = "3.8.6" --  Ui enhancement 
print(string.format("[Sp3arParvus v%s] Loading...", VERSION))
MAX_INIT_WAIT = 30 -- Maximum seconds to wait for initialization (add more for super huge games)
initStartTime = tick()
print("[Sp3arParvus] Waiting for game to load...")
repeat task.wait() until game:IsLoaded()
print("[Sp3arParvus] Game loaded!")
print("[Sp3arParvus] Waiting for LocalPlayer...")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat 
        task.wait(0.1) 
        LocalPlayer = Players.LocalPlayer
    until LocalPlayer or (tick() - initStartTime > MAX_INIT_WAIT)
end
if not LocalPlayer then
    return warn("[Sp3arParvus] Failed to get LocalPlayer after " .. MAX_INIT_WAIT .. " seconds. Aborting.")
end
print("[Sp3arParvus] LocalPlayer ready: " .. LocalPlayer.Name)

-- (with timeout)
print("[Sp3arParvus] Waiting for Character...")
local character = LocalPlayer.Character
if not character then
    character = LocalPlayer.CharacterAdded:Wait()
end
-- Wait for character to be parented to workspace
repeat 
    task.wait(0.1) 
    character = LocalPlayer.Character
until (character and character.Parent) or (tick() - initStartTime > MAX_INIT_WAIT)
if not character or not character.Parent then
    warn("[Sp3arParvus] Character not fully loaded, continuing anyway...")
end
print("[Sp3arParvus] Character ready!")

-- Wait for Camera
print("[Sp3arParvus] Waiting for Camera...")
local Workspace = game:GetService("Workspace")
repeat 
    task.wait(0.1) 
until Workspace.CurrentCamera or (tick() - initStartTime > MAX_INIT_WAIT)
if not Workspace.CurrentCamera then
    warn("[Sp3arParvus] Camera not found, continuing anyway...")
end
print("[Sp3arParvus] Camera ready!")

-- (critical for avoiding CameraSettings errors)
print("[Sp3arParvus] Waiting for PlayerScripts to initialize...")
local playerScripts = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
if not playerScripts then
    repeat 
        task.wait(0.1) 
        playerScripts = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
    until playerScripts or (tick() - initStartTime > MAX_INIT_WAIT)
end
if playerScripts then
    task.wait(0.5) -- Brief delay so CameraSettings and other modules can setup
end
print("[Sp3arParvus] PlayerScripts ready!")

task.wait(0.2)
print(string.format("[Sp3arParvus] Initialization complete! (%.2fs)", tick() - initStartTime))

-- RESPAWN HANDLING
local LocalCharReady = true
function OnLocalCharacterAdded(newChar)
    LocalCharReady = false
    -- Invalidate caches
    table.clear(CharCache)
    
    -- Pause specifically for camera/PlayerModule setup
    task.wait(1.5) 
    
    -- Wait for root part
    local root = nil
    local attempts = 0
    repeat
        task.wait(0.2)
        root = newChar:FindFirstChild("HumanoidRootPart") or newChar.PrimaryPart
        attempts = attempts + 1
    until root or attempts > 15
    
    LocalCharReady = true
    print("[Sp3arParvus] Local character re-cached and ready.")
end
-- Prevent duplicate
globalEnv = getgenv and getgenv() or _G
if rawget(globalEnv, "Sp3arParvusV2") then
    return warn("[Sp3arParvus v2] Already loaded! Use Shutdown button to cleanup first.")
end

-- Init global
globalEnv.Sp3arParvusV2 = {
    Active = true,
    Version = VERSION,
    Connections = {},
    Threads = {}
}
Sp3arParvus = globalEnv.Sp3arParvusV2


-- CONNECTION TRACKING (for proper cleanup)

function TrackConnection(connection)
    if connection and typeof(connection) == "RBXScriptConnection" then
        table.insert(Sp3arParvus.Connections, connection)
    end
    return connection
end

function TrackThread(thread)
    if thread and type(thread) == "thread" then
        table.insert(Sp3arParvus.Threads, thread)
    end
    return thread
end

function CleanupDeadConnections()
    local connections = Sp3arParvus.Connections
    for i = #connections, 1, -1 do
        local conn = connections[i]
        if not conn or not conn.Connected then
            table.remove(connections, i)
        end
    end
end

function CleanupDeadThreads()
    local threads = Sp3arParvus.Threads
    for i = #threads, 1, -1 do
        local t = threads[i]
        if not t or coroutine.status(t) == "dead" then
            table.remove(threads, i)
        end
    end
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(OnLocalCharacterAdded))

-- ANTI-AFK (Prevents idle kick)
-- SERVICES (additional services not declared during init)

local Services = {
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    Lighting = game:GetService("Lighting"),
    TeleportService = game:GetService("TeleportService"),
    Stats = game:GetService("Stats"),
    GuiService = game:GetService("GuiService"),
    TweenService = game:GetService("TweenService"),
    Workspace = game:GetService("Workspace"),
    Players = game:GetService("Players"),
    VirtualUser = game:GetService("VirtualUser"),
    TextService = game:GetService("TextService")
}
local RunService, UserInputService, Lighting, TeleportService, Stats, GuiService, TweenService, Workspace, Players, VirtualUser, TextService = 
    Services.RunService, Services.UserInputService, Services.Lighting, Services.TeleportService, Services.Stats, Services.GuiService, Services.TweenService, Services.Workspace, Services.Players, Services.VirtualUser, Services.TextService

-- ANTI-AFK (Prevents idle kick)
TrackConnection(LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))

-- resolve
function ResolveEnumItem(enumContainer, possibleNames)
    for _, name in ipairs(possibleNames) do
        local success, enumItem = pcall(function()
            return enumContainer[name]
        end)

        -- Validate 
        if success and enumItem and typeof(enumItem) == "EnumItem" then
            return enumItem
        end
    end

    return nil
end

local Camera = Services.Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Math shortcuts
abs, floor, max, min, sqrt = math.abs, math.floor, math.max, math.min, math.sqrt

local function SafeSetProp(obj, prop, val)
    if obj[prop] ~= val then
        obj[prop] = val
    end
end

local function SafeGetProp(obj, prop)
    return obj[prop]
end
deg, atan2, rad, sin, cos = math.deg, math.atan2, math.rad, math.sin, math.cos

-- Cached TweenInfo objects (prevents creating new objects on every tween)
local TWEENS = {
    INSTANT = TweenInfo.new(0.05),
    FAST = TweenInfo.new(0.1),
    MEDIUM = TweenInfo.new(0.2),
    SMOOTH = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    BACK = TweenInfo.new(0.3, Enum.EasingStyle.Back),
    DRAG = TweenInfo.new(0.05)
}

-- Cached players list (Event-based caching prevents allocation per frame)
local cachedPlayersList = {}

-- Initialize cache immediately
function InitPlayerCache()
    cachedPlayersList = Players:GetPlayers()
end
InitPlayerCache()

function GetPlayersCache()
    return cachedPlayersList
end

function UpdatePlayerCache()
    cachedPlayersList = Players:GetPlayers()
end

function AddPlayerToCache(player)
    if not table.find(cachedPlayersList, player) then
        table.insert(cachedPlayersList, player)
    end
end

function RemovePlayerFromCache(player)
    local idx = table.find(cachedPlayersList, player)
    if idx then
        table.remove(cachedPlayersList, idx)
    end
end

-- Cached sorted players for Player Panel (expensive sort operation)
cachedSortedPlayers = {}
cachedPlayerListForSort = {}
lastPlayerCountForSort = 0
lastSortTime = 0
SORT_CACHE_DURATION = 0.5 -- Only re-sort every 500ms (was every frame)




-- CONFIG


-- Aimbot state variables
local AimState = {
    Aimbot = false,
    Trigger = false,
    ProjectileSpeed = 3155,
    ProjectileGravity = 196.2,
    GravityCorrection = 2,
    LastAimbotTarget = nil,
    LastMouseMode = nil,
    LastOriginX = nil,
    LastOriginY = nil,
    AcquiringFrames = 0
}

local AIM_ACQUIRE_STABILIZE_FRAMES = 2
local AIM_ORIGIN_JUMP_RATIO = 0.25

function ClearAimLockState(resetMouseMode)
    AimState.LastAimbotTarget = nil
    AimState.LastOriginX = nil
    AimState.LastOriginY = nil
    AimState.AcquiringFrames = 0

    if resetMouseMode then
        AimState.LastMouseMode = nil
    end
end

function GetCrosshairViewportPosition(mouseBehavior)
    if not Camera then
        Camera = Services.Workspace.CurrentCamera
    end
    if not Camera then
        return nil, nil, false
    end

    local viewportSize = Camera.ViewportSize

    if mouseBehavior == Enum.MouseBehavior.LockCenter then
        return viewportSize.X * 0.5, viewportSize.Y * 0.5, true
    end

    local mouseLoc = Services.UserInputService:GetMouseLocation()
    local guiInset = GuiService:GetGuiInset()

    local crosshairX = mouseLoc.X - guiInset.X
    local crosshairY = mouseLoc.Y - guiInset.Y

    if crosshairX ~= crosshairX or crosshairY ~= crosshairY then
        return nil, nil, false
    end

    if crosshairX < 0 or crosshairY < 0 or crosshairX > viewportSize.X or crosshairY > viewportSize.Y then
        return nil, nil, false
    end

    return crosshairX, crosshairY, true
end

-- Shared Target Cache (Defined here for scope visibility)
local CachedTarget = nil
local CachedTargetTime = 0

-- Known body parts for targeting
KnownBodyParts = {
    "Head", "HumanoidRootPart"
}

-- Settings/Flags storage
local Flags = {
    -- Ballistics
    ["Prediction/Velocity"] = 3155,
    ["Prediction/GravityForce"] = 196.2,
    ["Prediction/GravityMultiplier"] = 2,

    -- Aimbot
    ["Aimbot/AimLock"] = true,
    ["Aimbot/AutoFire"] = false,
    ["Aimbot/AlwaysEnabled"] = true,
    ["Aimbot/Prediction"] = true,
    ["Aimbot/TeamCheck"] = false,
    ["Aimbot/VisibilityCheck"] = true,
    ["Aimbot/Sensitivity"] = 15,
    ["Aimbot/FOV/Radius"] = 100,
    ["Aimbot/Priority"] = "Head",
    ["Aimbot/BodyParts"] = {"Head", "HumanoidRootPart"},

    ["Trigger/AlwaysEnabled"] = false,
    ["Trigger/HoldMouseButton"] = true,
    ["Trigger/Delay"] = 0,
    ["Trigger/FOV/Radius"] = 25,

    -- ESP
    ["ESP/Enabled"] = true,
    ["ESP/Nametags"] = true,
    ["ESP/Tracers"] = false,
    ["ESP/OffscreenIndicators"] = false, -- Off by default for performance
    ["ESP/PlayerPanel"] = false, -- Top 10 closest players panel
    ["ESP/PlayerOutlines"] = true, -- Player body part outlines (off by default for performance)

    -- Visuals
    ["Visuals/Fullbright"] = false,

    -- Performance
    ["Performance/Enabled"] = true,
    
    -- Br3ak3r (Object Breaking Tool)
    ["Br3ak3r/Enabled"] = true,
    
    -- Waypoints
    ["Waypoints/Enabled"] = true,

    -- Freecam
    ["Settings/Freecam Toggle"] = true,
    ["Settings/GhostMode"] = false,

    -- Misc
    ["Misc/D3vTool"] = true,

    -- Humanoid
    ["Humanoid/Archivable"] = true,
    ["Humanoid/Archivable/Locked"] = false,
    ["Humanoid/BreakJointsOnDeath"] = true,
    ["Humanoid/BreakJointsOnDeath/Locked"] = false,
    ["Humanoid/EvaluateStateMachine"] = true,
    ["Humanoid/EvaluateStateMachine/Locked"] = false,
    ["Humanoid/RequiresNeck"] = true,
    ["Humanoid/RequiresNeck/Locked"] = false,
    ["Humanoid/AutoRotate"] = true,
    ["Humanoid/AutoRotate/Locked"] = false,
    ["Humanoid/PlatformStand"] = false,
    ["Humanoid/PlatformStand/Locked"] = false,
    ["Humanoid/Sit"] = false,
    ["Humanoid/Sit/Locked"] = false,
    ["Humanoid/Jump"] = false,
    ["Humanoid/Jump/Locked"] = false,
    ["Humanoid/AutoJumpEnabled"] = false,
    ["Humanoid/AutoJumpEnabled/Locked"] = false,
    ["Humanoid/JumpHeight"] = 7.2,
    ["Humanoid/JumpHeight/Locked"] = false,
    ["Humanoid/JumpPower"] = 50,
    ["Humanoid/JumpPower/Locked"] = false,
    ["Humanoid/UseJumpPower"] = true,
    ["Humanoid/UseJumpPower/Locked"] = false,
    ["Humanoid/AutomaticScalingEnabled"] = true,
    ["Humanoid/AutomaticScalingEnabled/Locked"] = false,
    ["Humanoid/Health"] = 100,
    ["Humanoid/Health/Locked"] = false,
    ["Humanoid/MaxHealth"] = 100,
    ["Humanoid/MaxHealth/Locked"] = false,
    ["Humanoid/HipHeight"] = 1.35,
    ["Humanoid/HipHeight/Locked"] = false,
    ["Humanoid/MaxSlopeAngle"] = 89,
    ["Humanoid/MaxSlopeAngle/Locked"] = false,
    ["Humanoid/WalkSpeed"] = 16,
    ["Humanoid/WalkSpeed/Locked"] = false
}

local UIState = {
    MainFrame = nil,
    Tabs = {},
    CurrentTab = nil,
    Visible = true,
    ToggleMinimize = nil,
    DraggableFrames = {},
    Updaters = {}
}

local HUMANOID_PROPERTY_MAPPING = {
    ["Humanoid/Archivable"] = "Archivable",
    ["Humanoid/BreakJointsOnDeath"] = "BreakJointsOnDeath",
    ["Humanoid/EvaluateStateMachine"] = "EvaluateStateMachine",
    ["Humanoid/RequiresNeck"] = "RequiresNeck",
    ["Humanoid/AutoRotate"] = "AutoRotate",
    ["Humanoid/PlatformStand"] = "PlatformStand",
    ["Humanoid/Sit"] = "Sit",
    ["Humanoid/Jump"] = "Jump",
    ["Humanoid/AutoJumpEnabled"] = "AutoJumpEnabled",
    ["Humanoid/JumpHeight"] = "JumpHeight",
    ["Humanoid/JumpPower"] = "JumpPower",
    ["Humanoid/UseJumpPower"] = "UseJumpPower",
    ["Humanoid/AutomaticScalingEnabled"] = "AutomaticScalingEnabled",
    ["Humanoid/Health"] = "Health",
    ["Humanoid/MaxHealth"] = "MaxHealth",
    ["Humanoid/HipHeight"] = "HipHeight",
    ["Humanoid/MaxSlopeAngle"] = "MaxSlopeAngle",
    ["Humanoid/WalkSpeed"] = "WalkSpeed"
}

local HUMANOID_ENFORCED_PROPERTIES = {
    ["Humanoid/Archivable"] = "Archivable",
    ["Humanoid/BreakJointsOnDeath"] = "BreakJointsOnDeath",
    ["Humanoid/EvaluateStateMachine"] = "EvaluateStateMachine",
    ["Humanoid/RequiresNeck"] = "RequiresNeck",
    ["Humanoid/AutoRotate"] = "AutoRotate",
    ["Humanoid/PlatformStand"] = "PlatformStand",
    ["Humanoid/AutoJumpEnabled"] = "AutoJumpEnabled",
    ["Humanoid/UseJumpPower"] = "UseJumpPower",
    ["Humanoid/AutomaticScalingEnabled"] = "AutomaticScalingEnabled",
    ["Humanoid/MaxHealth"] = "MaxHealth",
    ["Humanoid/MaxSlopeAngle"] = "MaxSlopeAngle"
}

local HumanoidState = {
    originalSettings = {},
    captured = false
}

local WorldHumState = {
    selectedHum = nil,
    Page = nil,
    lockedProperties = {}, -- [path] = { propName = value }
    connections = {},
    updaters = {},
    listEntries = {},
    selectionHighlight = nil
}

function TrackWorldHumConnection(connection)
    if connection and typeof(connection) == "RBXScriptConnection" then
        table.insert(WorldHumState.connections, connection)
    end
    return connection
end

function ClearWorldHumConnections()
    for _, conn in ipairs(WorldHumState.connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(WorldHumState.connections)
    table.clear(WorldHumState.updaters)
end

function CaptureHumanoidSettings(humanoid)
    if not humanoid or HumanoidState.captured then return end
    
    local properties = {
        "Archivable", "BreakJointsOnDeath", "EvaluateStateMachine", "RequiresNeck",
        "AutoRotate", "PlatformStand", "Sit", "Jump", "AutoJumpEnabled",
        "JumpHeight", "JumpPower", "UseJumpPower", "AutomaticScalingEnabled",
        "Health", "MaxHealth", "HipHeight", "MaxSlopeAngle", "WalkSpeed"
    }
    
    local flagMapping = {
        Archivable = "Humanoid/Archivable",
        BreakJointsOnDeath = "Humanoid/BreakJointsOnDeath",
        EvaluateStateMachine = "Humanoid/EvaluateStateMachine",
        RequiresNeck = "Humanoid/RequiresNeck",
        AutoRotate = "Humanoid/AutoRotate",
        PlatformStand = "Humanoid/PlatformStand",
        Sit = "Humanoid/Sit",
        Jump = "Humanoid/Jump",
        AutoJumpEnabled = "Humanoid/AutoJumpEnabled",
        JumpHeight = "Humanoid/JumpHeight",
        JumpPower = "Humanoid/JumpPower",
        UseJumpPower = "Humanoid/UseJumpPower",
        AutomaticScalingEnabled = "Humanoid/AutomaticScalingEnabled",
        Health = "Humanoid/Health",
        MaxHealth = "Humanoid/MaxHealth",
        HipHeight = "Humanoid/HipHeight",
        MaxSlopeAngle = "Humanoid/MaxSlopeAngle",
        WalkSpeed = "Humanoid/WalkSpeed"
    }

    for _, prop in ipairs(properties) do
        pcall(function()
            local val = humanoid[prop]
            HumanoidState.originalSettings[prop] = val
            -- Sync initial flags with game defaults
            if flagMapping[prop] then
                local flag = flagMapping[prop]
                Flags[flag] = val
                local updater = UIState.Updaters[flag]
                if updater then
                    updater(val)
                end
            end
        end)
    end
    
    HumanoidState.captured = true
    print("[Sp3arParvus] Local Humanoid settings captured and synced.")
end

function ApplyHumanoidSettings()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not humanoid then return end
    
    if not HumanoidState.captured then
        CaptureHumanoidSettings(humanoid)
    end
    
    for flag, prop in pairs(HUMANOID_PROPERTY_MAPPING) do
        local isEnforced = HUMANOID_ENFORCED_PROPERTIES[flag] ~= nil
        local isLocked = Flags[flag .. "/Locked"] == true
        
        if isEnforced or isLocked then
            local val = Flags[flag]
            if val ~= nil then
                pcall(SafeSetProp, humanoid, prop, val)
            end
        end
    end
end

function UpdateHumanoidUI()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    for flag, prop in pairs(HUMANOID_PROPERTY_MAPPING) do
        if Flags[flag .. "/Locked"] then continue end
        
        local success, val = pcall(SafeGetProp, humanoid, prop)
        
        if success and val ~= nil and Flags[flag] ~= val then
            Flags[flag] = val
            local updater = UIState.Updaters[flag]
            if updater then
                updater(val)
            end
        end
    end
end

function GetNearbyHumanoids()
    local humanoids = {}
    local myChar = LocalPlayer.Character
    
    -- Optimized spatial query
    local parts = Services.Workspace:GetPartBoundsInRadius(Camera.CFrame.Position, 500)
    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        local hum = model and model:FindFirstChildOfClass("Humanoid")
        if hum and model ~= myChar and not table.find(humanoids, hum) then
            -- EXCLUDE REAL PLAYERS
            if not Players:GetPlayerFromCharacter(model) then
                table.insert(humanoids, hum)
            end
        end
    end
    
    return humanoids
end

function ApplyWorldHumanoidSettings()
    for path, props in pairs(WorldHumState.lockedProperties) do
        local hum = GetInstanceFromPath(path)
        if hum and hum:IsA("Humanoid") then
            for prop, val in pairs(props) do
                pcall(SafeSetProp, hum, prop, val)
            end
        else
            -- Humanoid destroyed or gone, stop enforcing
            WorldHumState.lockedProperties[path] = nil
        end
    end
end

function UpdateWorldHumanoidEditorUI()
    local hum = WorldHumState.selectedHum
    if not hum then return end
    
    if not hum.Parent then 
        WorldHumState.selectedHum = nil
        ClearWorldHumConnections()
        if WorldHumState.Page then
            ShowWorldHumList(WorldHumState.Page)
        end
        return 
    end

    local path = GetUniquePath(hum)
    local lockedProps = WorldHumState.lockedProperties[path] or {}

    for prop, updater in pairs(WorldHumState.updaters) do
        if lockedProps[prop] ~= nil then continue end
        
        local success, val = pcall(SafeGetProp, hum, prop)
        if success and val ~= nil then
            updater(val)
        end
    end
end

-- WAYPOINTS SYSTEM STATE
ActiveWaypoints = {}
WaypointCounter = 0
WaypointColors = {
    Color3.fromRGB(0, 200, 255),
    Color3.fromRGB(255, 100, 100),
    Color3.fromRGB(100, 255, 100),
    Color3.fromRGB(255, 200, 50),
    Color3.fromRGB(200, 100, 255)
}
WaypointsTabButton = nil
WaypointsPage = nil
WaypointsUIList = nil
WaypointConnections = {}


-- BR3AK3R SYSTEM (Ctrl+Click to hide objects, Ctrl+Z to undo)

UNDO_LIMIT = 50
RAYCAST_MAX_DISTANCE = 3000

-- Br3ak3r state
local Br3ak3rState = {
    CLICKBREAK_ENABLED = true,
    brokenSet = {},
    brokenIgnoreCache = {},
    scratchIgnore = {},
    brokenCacheDirty = true,
    undoStack = {},
    hoverHL = nil,
    CTRL_HELD = false,
    LEFT_CTRL_HELD = false,
    RIGHT_CTRL_HELD = false,
    br3akerRaycastParams = RaycastParams.new()
}
Br3ak3rState.br3akerRaycastParams.IgnoreWater = true

local H1ghl1ght3rState = {
    ENABLED = true,
    highlightedSet = {},
    undoStack = {},
    SHIFT_HELD = false
}

local FullbrightState = {
    lastState = false,
    originalSettings = nil
}

function GetFullPath(instance)
    local path = instance.Name
    local current = instance.Parent
    while current and current ~= game do
        path = current.Name .. "/" .. path
        current = current.Parent
    end
    return path
end

function GetUniquePath(instance)
    local path = ""
    local current = instance
    while current and current ~= game do
        local name = current.Name
        local parent = current.Parent
        local index = 1
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child == current then break end
                if child.Name == name then
                    index = index + 1
                end
            end
        end
        path = name .. "[" .. index .. "]" .. (path == "" and "" or "\1" .. path)
        current = parent
    end
    return path
end

function GetInstanceFromPath(uniquePath)
    if type(uniquePath) ~= "string" then return nil end
    local segments = string.split(uniquePath, "\1")
    local current = game
    for _, segment in ipairs(segments) do
        local name, index = string.match(segment, "^(.*)%[(%d+)%]$")
        if name and index then
            index = tonumber(index)
            local count = 0
            local found = false
            for _, child in ipairs(current:GetChildren()) do
                if child.Name == name then
                    count = count + 1
                    if count == index then
                        current = child
                        found = true
                        break
                    end
                end
            end
            if not found then return nil end
        else
            current = current:FindFirstChild(segment)
            if not current then return nil end
        end
    end
    return current
end

-- PERFORMANCE FIX: Cache filter type ONCE at startup
Br3ak3rFilterType = (function()
    local ok, val = pcall(function() return Enum.RaycastFilterType.Exclude end)
    if ok and val and typeof(val) == "EnumItem" then return val end
    ok, val = pcall(function() return Enum.RaycastFilterType.Blacklist end)
    if ok and val and typeof(val) == "EnumItem" then return val end
    return nil
end)()

if Br3ak3rFilterType then
    Br3ak3rState.br3akerRaycastParams.FilterType = Br3ak3rFilterType
end

-- Rebuild the broken parts ignore cache for raycasts
function RebuildBrokenIgnore()
    if not next(Br3ak3rState.brokenSet) then
        table.clear(Br3ak3rState.brokenIgnoreCache)
        Br3ak3rState.brokenCacheDirty = false
        return
    end
    table.clear(Br3ak3rState.brokenIgnoreCache)
    local cacheIndex = 1
    for path, data in pairs(Br3ak3rState.brokenSet) do
        local part = data.instance
        if not part or not part.Parent then
            part = GetInstanceFromPath(path)
            if part then data.instance = part end
        end
        if part and part:IsDescendantOf(Services.Workspace) then
            Br3ak3rState.brokenIgnoreCache[cacheIndex] = part
            cacheIndex = cacheIndex + 1
        end
    end
    Br3ak3rState.brokenCacheDirty = false
end

-- Get ray from mouse cursor position
function GetMouseRay()
    local mouseLocation = Services.UserInputService:GetMouseLocation()
    if not Camera then Camera = Services.Workspace.CurrentCamera end
    if not Camera then return nil end
    
    -- Normalize to Viewport space (ScreenPointToRay expects Screen space which includes TopBar)
    local ray = Camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)
    if not ray then return nil end
    
    return ray.Origin, ray.Direction * RAYCAST_MAX_DISTANCE, mouseLocation.X, mouseLocation.Y
end

-- Raycast with broken parts filtering
-- PERFORMANCE FIX: Removed nested closure function, use inline logic instead
MAX_IGNORE_COUNT = 200

function WorldRaycastBr3ak3r(origin, direction, ignoreLocalChar, extraIgnore)
    if Br3ak3rState.brokenCacheDirty then
        RebuildBrokenIgnore()
    end
    
    local ignore = Br3ak3rState.scratchIgnore
    -- Optimization: Instead of clearing and repopulating every frame, 
    -- we manage the table indices directly if possible, or use table.clear
    table.clear(ignore)
    
    local ignoreCount = 0
    
    -- Always prioritize ignoring the local character
    if ignoreLocalChar then
        local ch = LocalPlayer.Character
        if ch then
            ignoreCount = ignoreCount + 1
            ignore[ignoreCount] = ch
        end
    end
    
    -- Add extra ignore items
    if extraIgnore then
        for i = 1, #extraIgnore do
            local item = extraIgnore[i]
            if item then
                ignoreCount = ignoreCount + 1
                ignore[ignoreCount] = item
            end
        end
    end
    
    -- Add broken parts to ignore list
    -- Use cached length to avoid repeated table length lookups
    local brokenCacheLen = #Br3ak3rState.brokenIgnoreCache
    for i = 1, brokenCacheLen do
        local item = Br3ak3rState.brokenIgnoreCache[i]
        if item then
            ignoreCount = ignoreCount + 1
            ignore[ignoreCount] = item
        end
    end
    
    -- FilterType already set at initialization
    Br3ak3rState.br3akerRaycastParams.FilterDescendantsInstances = ignore
    
    return Services.Workspace:Raycast(origin, direction, Br3ak3rState.br3akerRaycastParams)
end

-- Mark a part as broken (hide it)
function markBroken(part)
    if not part or not part:IsA("BasePart") then return end
    local path = GetUniquePath(part)
    if Br3ak3rState.brokenSet[path] then return end
    
    Br3ak3rState.brokenSet[path] = {instance = part, cc = part.CanCollide, ltm = part.LocalTransparencyModifier, t = part.Transparency}
    Br3ak3rState.brokenCacheDirty = true
    
    -- Save original state for undo
    table.insert(Br3ak3rState.undoStack, {
        path = path,
        instance = part,
        cc = part.CanCollide,
        ltm = part.LocalTransparencyModifier,
        t = part.Transparency
    })
    
    -- Limit undo stack size
    if #Br3ak3rState.undoStack > UNDO_LIMIT then
        table.remove(Br3ak3rState.undoStack, 1)
    end
    
    -- Hide the part (semi-transparent)
    part.CanCollide = false
    part.LocalTransparencyModifier = 0.5
    part.Transparency = 0.5
end

-- Undo the last broken part
function unbreakLast()
    local entry = table.remove(Br3ak3rState.undoStack)
    if not entry or not entry.path then return end
    
    local path = entry.path
    local part = entry.instance
    if not part or not part.Parent then
        part = GetInstanceFromPath(path)
    end
    
    Br3ak3rState.brokenSet[path] = nil
    Br3ak3rState.brokenCacheDirty = true
    
    if part then
        -- Restore original state
        part.CanCollide = entry.cc
        part.LocalTransparencyModifier = entry.ltm
        part.Transparency = entry.t
    end
end

-- Clear all broken parts
function unbreakAll()
    for path, data in pairs(Br3ak3rState.brokenSet) do
        pcall(function()
            local part = data.instance
            if not part or not part.Parent then
                part = GetInstanceFromPath(path)
            end
            if part and part.Parent and type(data) == "table" then
                part.CanCollide = data.cc
                part.LocalTransparencyModifier = data.ltm
                part.Transparency = data.t
            end
        end)
    end
    table.clear(Br3ak3rState.brokenSet)
    table.clear(Br3ak3rState.undoStack)
    table.clear(Br3ak3rState.brokenIgnoreCache)
    Br3ak3rState.brokenCacheDirty = true
end

-- Sweep undo stack (periodic cleanup of destroyed parts)
-- Sweep undo stack (periodic cleanup)
sweepAccum = 0
function sweepUndo(dt)
    sweepAccum = sweepAccum + dt
    if sweepAccum < 2 then return end
    sweepAccum = 0
    
    local n = #Br3ak3rState.undoStack
    if n == 0 then return end

    local j = 1
    local camPos = Camera and Camera.CFrame.Position
    for i = 1, n do
        local entry = Br3ak3rState.undoStack[i]
        local keep = true
        
        local part = entry.instance
        if not part or not part.Parent then
            local resolved = GetInstanceFromPath(entry.path)
            if resolved then
                entry.instance = resolved
                part = resolved
            end
        end

        if not part or not part.Parent then
            if part and camPos then
                local success, dist = pcall(function() return (part.Position - camPos).Magnitude end)
                if success and dist < 250 then
                    keep = false
                end
            elseif not part then
                keep = false
            end
        end

        if keep then
            if i ~= j then
                Br3ak3rState.undoStack[j] = entry
            end
            j = j + 1
        end
    end

    for i = j, n do
        Br3ak3rState.undoStack[i] = nil
    end
end

-- Prune broken set (remove parts that no longer exist)
function pruneBrokenSet()
    -- Path-based indexing allows objects to persist across streaming events.
    -- To distinguish between streamed-out and destroyed, we check distance.
    local removed = false
    local camPos = Camera and Camera.CFrame.Position
    for path, data in pairs(Br3ak3rState.brokenSet) do
        local part = data.instance
        if not part or not part.Parent then
            local resolved = GetInstanceFromPath(path)
            if resolved then
                data.instance = resolved
                part = resolved
            end
        end
        
        if not part or not part.Parent then
            -- Instance is missing from Workspace.
            -- If we have an old reference, check its position to see if it should be streamed in.
            if part and camPos then
                pcall(function()
                    local dist = (part.Position - camPos).Magnitude
                    -- If we're within 250 studs and it's not here, it's likely destroyed.
                    if dist < 250 then
                        Br3ak3rState.brokenSet[path] = nil
                        removed = true
                    end
                end)
            elseif not part then
                -- No instance reference and can't resolve by path.
                Br3ak3rState.brokenSet[path] = nil
                removed = true
            end
        end
    end
    if removed then
        Br3ak3rState.brokenCacheDirty = true
    end
end

-- MARK HIGHLIGHTED (H1GHL1GHT3R)
function markHighlighted(part)
    if not part or not part:IsA("BasePart") then return end
    if H1ghl1ght3rState.highlightedSet[part] then return end
    
    local hl = Instance.new("Highlight")
    hl.Enabled = not Flags["Settings/GhostMode"]
    hl.Name = "H1ghl1ght3r_Highlight"
    hl.FillColor = Color3.fromRGB(255, 105, 180) -- Pink
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = part
    hl.Parent = part
    
    local bg = Instance.new("BillboardGui")
    bg.Enabled = not Flags["Settings/GhostMode"]
    bg.Name = "H1ghl1ght3r_Nametag"
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.StudsOffset = Vector3.new(0, 2, 0)
    bg.Adornee = part
    bg.Parent = part
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = GetFullPath(part)
    lbl.TextColor3 = Color3.fromRGB(255, 105, 180)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextStrokeTransparency = 0.5
    lbl.Parent = bg
    
    H1ghl1ght3rState.highlightedSet[part] = {
        hl = hl, 
        bg = bg,
        ltm = part.LocalTransparencyModifier,
        t = part.Transparency
    }
    
    table.insert(H1ghl1ght3rState.undoStack, {
        part = part, 
        hl = hl, 
        bg = bg,
        ltm = part.LocalTransparencyModifier,
        t = part.Transparency
    })

    if #H1ghl1ght3rState.undoStack > UNDO_LIMIT then
        table.remove(H1ghl1ght3rState.undoStack, 1)
    end

    -- Force visibility so the Highlight is visible on transparent objects
    part.LocalTransparencyModifier = 0.5
    part.Transparency = 0.5
end

function unhighlightLast()
    local entry = table.remove(H1ghl1ght3rState.undoStack)
    if entry then
        if entry.part and entry.part.Parent then
            pcall(function()
                entry.part.LocalTransparencyModifier = entry.ltm
                entry.part.Transparency = entry.t
            end)
        end
        if entry.hl then pcall(function() entry.hl:Destroy() end) end
        if entry.bg then pcall(function() entry.bg:Destroy() end) end
        if entry.part then H1ghl1ght3rState.highlightedSet[entry.part] = nil end
    end
end

function sweepHighlightedUndo(dt)
    -- Throttling already handled by caller or dt
    local n = #H1ghl1ght3rState.undoStack
    if n == 0 then return end
    local j = 1
    for i = 1, n do
        local entry = H1ghl1ght3rState.undoStack[i]
        if entry.part and entry.part.Parent then
            if i ~= j then H1ghl1ght3rState.undoStack[j] = entry end
            j = j + 1
        else
            if entry.hl then pcall(function() entry.hl:Destroy() end) end
            if entry.bg then pcall(function() entry.bg:Destroy() end) end
            entry.part = nil
            entry.hl = nil
            entry.bg = nil
        end
    end
    for i = j, n do H1ghl1ght3rState.undoStack[i] = nil end
end

function pruneHighlightedSet()
    for part, data in pairs(H1ghl1ght3rState.highlightedSet) do
        if not part or not part.Parent then
            if data.hl then pcall(function() data.hl:Destroy() end) end
            if data.bg then pcall(function() data.bg:Destroy() end) end
            H1ghl1ght3rState.highlightedSet[part] = nil
        end
    end
end

-- Create hover highlight for Br3ak3r preview
function createHoverHighlight()
    if Br3ak3rState.hoverHL then return Br3ak3rState.hoverHL end
    
    Br3ak3rState.hoverHL = Instance.new("Highlight")
    Br3ak3rState.hoverHL.Name = "Br3ak3r_HoverHighlight"
    Br3ak3rState.hoverHL.FillColor = Color3.fromRGB(255, 105, 180)  -- Pink
    Br3ak3rState.hoverHL.OutlineColor = Color3.fromRGB(255, 255, 255)  -- White
    Br3ak3rState.hoverHL.FillTransparency = 0.6
    Br3ak3rState.hoverHL.OutlineTransparency = 0.2
    Br3ak3rState.hoverHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Br3ak3rState.hoverHL.Enabled = false
    Br3ak3rState.hoverHL.Parent = Services.Workspace
    
    return Br3ak3rState.hoverHL
end

-- Update hover highlight for Br3ak3r (called each frame)
-- Update hover highlight for Br3ak3r / H1ghl1ght3r (called each frame)
-- PERFORMANCE FIX: Skip raycast entirely when Ctrl not held
function UpdateBr3ak3rHover()
    -- Early exit - don't do ANY work if Gh0st mode active
    if Flags["Settings/GhostMode"] then
        if Br3ak3rState.hoverHL and Br3ak3rState.hoverHL.Enabled then
            Br3ak3rState.hoverHL.Enabled = false
        end
        return
    end
    -- Early exit - don't do ANY work if feature disabled or Ctrl not held
    local breakerActive = Br3ak3rState.CLICKBREAK_ENABLED and not H1ghl1ght3rState.SHIFT_HELD
    local highlighterActive = H1ghl1ght3rState.ENABLED and H1ghl1ght3rState.SHIFT_HELD
    
    if not Br3ak3rState.CTRL_HELD or (not breakerActive and not highlighterActive) then
        if Br3ak3rState.hoverHL and Br3ak3rState.hoverHL.Enabled then
            Br3ak3rState.hoverHL.Enabled = false
        end
        return
    end
    
    if not Br3ak3rState.hoverHL then
        createHoverHighlight()
    end

    -- Differentiate color: Pink for breaker, Green for highlighter
    if H1ghl1ght3rState.SHIFT_HELD then
        Br3ak3rState.hoverHL.FillColor = Color3.fromRGB(0, 255, 0) -- Green
    else
        Br3ak3rState.hoverHL.FillColor = Color3.fromRGB(255, 105, 180) -- Pink
    end
    
    local origin, direction = GetMouseRay()
    if origin and direction then
        local result = WorldRaycastBr3ak3r(origin, direction, true)
        local part = result and result.Instance
        local alreadyProcessed = (part and Br3ak3rState.brokenSet[GetUniquePath(part)]) or H1ghl1ght3rState.highlightedSet[part]
        
        if part and part:IsA("BasePart") and not alreadyProcessed then
            Br3ak3rState.hoverHL.Adornee = part
            Br3ak3rState.hoverHL.Enabled = true
        else
            if Br3ak3rState.hoverHL.Enabled then
                Br3ak3rState.hoverHL.Enabled = false
            end
        end
    else
        if Br3ak3rState.hoverHL.Enabled then
            Br3ak3rState.hoverHL.Enabled = false
        end
    end
end


-- WAYPOINTS SYSTEM LOGIC

function RefreshWaypointUI()
    if not WaypointsUIList then return end
    
    -- Disconnect old row-specific connections
    for _, conn in ipairs(WaypointConnections) do
        if conn.Connected then conn:Disconnect() end
    end
    table.clear(WaypointConnections)

    -- Clear current UI logic
    for _, child in ipairs(WaypointsUIList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    
    local keys = {}
    for id in pairs(ActiveWaypoints) do
        table.insert(keys, id)
    end
    table.sort(keys) -- Display in order
    
    for _, id in ipairs(keys) do
        local wpData = ActiveWaypoints[id]
        
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = UI_THEME.Element
        row.BorderSizePixel = 0
        row.Parent = WaypointsUIList
        local rC = Instance.new("UICorner", row)
        rC.CornerRadius = UDim.new(0, 4)
        
        local nameBox = Instance.new("TextBox")
        nameBox.Size = UDim2.new(0.5, -5, 1, 0)
        nameBox.Position = UDim2.new(0, 5, 0, 0)
        nameBox.BackgroundTransparency = 1
        nameBox.Text = wpData.Name
        nameBox.Font = Enum.Font.Gotham
        nameBox.TextSize = 13
        nameBox.TextColor3 = wpData.Color
        nameBox.TextXAlignment = Enum.TextXAlignment.Left
        nameBox.ClearTextOnFocus = false
        nameBox.Parent = row
        table.insert(WaypointConnections, nameBox.FocusLost:Connect(function()
            wpData.Name = nameBox.Text
            if wpData.Label then
                wpData.Label.Text = string.format("%s\n%s", wpData.Name, wpData.DistanceText)
            end
        end))
        
        -- Color cycle button
        local colBtn = Instance.new("TextButton")
        colBtn.Size = UDim2.new(0, 24, 0, 24)
        colBtn.Position = UDim2.new(1, -60, 0.5, -12)
        colBtn.BackgroundColor3 = wpData.Color
        colBtn.Text = ""
        colBtn.Parent = row
        local cC = Instance.new("UICorner", colBtn)
        cC.CornerRadius = UDim.new(0, 4)
        table.insert(WaypointConnections, colBtn.MouseButton1Click:Connect(function()
            wpData.ColorIndex = (wpData.ColorIndex % #WaypointColors) + 1
            wpData.Color = WaypointColors[wpData.ColorIndex]
            colBtn.BackgroundColor3 = wpData.Color
            nameBox.TextColor3 = wpData.Color
            if wpData.Label then
                wpData.Label.TextColor3 = wpData.Color
            end
            if wpData.Pin then
                wpData.Pin.BackgroundColor3 = wpData.Color
            end
        end))
        
        -- Del button
        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 24, 0, 24)
        delBtn.Position = UDim2.new(1, -30, 0.5, -12)
        delBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        delBtn.Text = "X"
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextColor3 = Color3.fromRGB(255,255,255)
        delBtn.TextSize = 12
        delBtn.Parent = row
        local dC = Instance.new("UICorner", delBtn)
        dC.CornerRadius = UDim.new(0, 4)
        
        table.insert(WaypointConnections, delBtn.MouseButton1Click:Connect(function()
            if Sp3arParvus.DestroyWaypointFunc then Sp3arParvus.DestroyWaypointFunc(id) end
        end))
    end
    
    -- Update Tab Visibility
    local hasWaypoints = #keys > 0
    if WaypointsTabButton then
        WaypointsTabButton.Visible = hasWaypoints
    end
end

function DestroyWaypoint(id)
    local wpData = ActiveWaypoints[id]
    if wpData then
        if wpData.Billboard then
            wpData.Billboard:Destroy()
        end
        if wpData.Part then
            wpData.Part:Destroy()
        end
        ActiveWaypoints[id] = nil
        RefreshWaypointUI()
    end
end
function SetDestroyWaypointFunc(func)
    Sp3arParvus.DestroyWaypointFunc = func
end
SetDestroyWaypointFunc(DestroyWaypoint)

function CreateWaypoint(position)
    if not Flags["Waypoints/Enabled"] then return end
    
    WaypointCounter = WaypointCounter + 1
    local id = WaypointCounter
    local colorIndex = ((id - 1) % #WaypointColors) + 1
    local color = WaypointColors[colorIndex]
    local name = "Waypoint " .. id
    
    -- Create anchor part
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Position = position
    part.Parent = Services.Workspace
    
    -- Create Billboard
    local bg = Instance.new("BillboardGui")
    bg.Enabled = not Flags["Settings/GhostMode"]
    bg.AlwaysOnTop = true
    bg.Size = UDim2.new(0, 100, 0, 50)
    bg.StudsOffset = Vector3.new(0, 2, 0)
    bg.Adornee = part
    bg.Parent = part
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s\n0 studs", name)
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextStrokeTransparency = 0.2
    label.Parent = bg
    
    -- Create Pin (Dot)
    local pinBg = Instance.new("BillboardGui")
    pinBg.Enabled = not Flags["Settings/GhostMode"]
    pinBg.AlwaysOnTop = true
    pinBg.Size = UDim2.new(0, 8, 0, 8)
    pinBg.Adornee = part
    pinBg.Parent = part
    
    local pin = Instance.new("Frame")
    pin.Size = UDim2.new(1,0,1,0)
    pin.BackgroundColor3 = color
    pin.Parent = pinBg
    local pinC = Instance.new("UICorner", pin)
    pinC.CornerRadius = UDim.new(1,0)
    
    ActiveWaypoints[id] = {
        Id = id,
        Name = name,
        Position = position,
        ColorIndex = colorIndex,
        Color = color,
        Part = part,
        Billboard = bg,
        PinBg = pinBg,
        Pin = pin,
        Label = label,
        DistanceText = "0 studs"
    }
    
    RefreshWaypointUI()
end

-- UTILITY FUNCTIONS




-- MODERN UI LIBRARY


TweenService = Services.TweenService
local ScreenGui = nil -- Define at top level to be accessible to all functions
local UI = {}

function ReclampAllUI()
    local viewportSize = Camera.ViewportSize
    if not viewportSize or viewportSize.X == 0 then return end
    
    for _, Frame in ipairs(UIState.DraggableFrames) do
        pcall(function()
            if not Frame or not Frame.Parent then return end
            
            local absoluteSize = Frame.AbsoluteSize
            local anchor = Frame.AnchorPoint
            
            -- Get current center-point position in absolute pixels
            local currentPos = Frame.AbsolutePosition + (absoluteSize * anchor)
            
            -- Calculate bounds for the anchor point
            local minX = anchor.X * absoluteSize.X
            local maxX = viewportSize.X - (1 - anchor.X) * absoluteSize.X
            local minY = anchor.Y * absoluteSize.Y
            local maxY = viewportSize.Y - (1 - anchor.Y) * absoluteSize.Y
            
            -- Clamp
            local clampedX = math.clamp(currentPos.X, minX, maxX)
            local clampedY = math.clamp(currentPos.Y, minY, maxY)
            
            -- Set position in Scale to keep it responsive
            Frame.Position = UDim2.fromScale(clampedX / viewportSize.X, clampedY / viewportSize.Y)
        end)
    end
end

-- Listen for viewport changes to re-clamp UI
TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(ReclampAllUI))

-- Responsive sizing helpers
function GetMainFrameSize()
    local viewport = Camera.ViewportSize
    local width = math.min(580, viewport.X * 0.7)
    local height = math.min(380, viewport.Y * 0.7)
    return UDim2.fromOffset(width, height)
end

function GetPlayerPanelSize()
    local viewport = Camera.ViewportSize
    local width = math.min(280, viewport.X * 0.35)
    local height = math.min(320, viewport.Y * 0.5)
    return UDim2.fromOffset(width, height)
end

-- UI Constants
UI_THEME = {
    Background = Color3.fromRGB(18, 18, 18),
    Sidebar = Color3.fromRGB(25, 25, 25),
    Element = Color3.fromRGB(32, 32, 32),
    Accent = Color3.fromRGB(252, 149, 175),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(0, 220, 100),
    Fail = Color3.fromRGB(220, 50, 50)
}

-- Helper to ensure ScreenGui exists and is parented correctly
function EnsureScreenGui()
    if ScreenGui and ScreenGui.Parent then
        return ScreenGui
    end

    -- Re-create if missing or parented to nil
    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Enabled = not Flags["Settings/GhostMode"]
    ScreenGui.Name = "Sp3arParvusUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.IgnoreGuiInset = true

    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = game.CoreGui
    else
        ScreenGui.Parent = game.CoreGui
    end

    return ScreenGui
end

function UI.CreateWindow(title)
    -- Destroy old instances
    EnsureScreenGui()

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.fromScale(0.4, 0.45)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = UI_THEME.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = UIState.Visible
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local mainConstraint = Instance.new("UISizeConstraint")
    mainConstraint.MinSize = Vector2.new(420, 280)
    mainConstraint.MaxSize = Vector2.new(650, 450)
    mainConstraint.Parent = MainFrame

    local aspect = Instance.new("UIAspectRatioConstraint")
    aspect.AspectRatio = 1.5
    aspect.DominantAxis = Enum.DominantAxis.Width
    aspect.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = MainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(45, 45, 45)
    stroke.Thickness = 1
    stroke.Parent = MainFrame

    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.Size = UDim2.new(1, 100, 1, 100)
    shadow.ZIndex = 0
    shadow.Image = "rbxassetid://6015897843" -- Generic shadow
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.4
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = MainFrame

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0.26, 0, 1, 0) -- Responsive width
    Sidebar.BackgroundColor3 = UI_THEME.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local sideConstraint = Instance.new("UISizeConstraint")
    sideConstraint.MinSize = Vector2.new(120, 0)
    sideConstraint.MaxSize = Vector2.new(180, 9999)
    sideConstraint.Parent = Sidebar
    
    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 8)
    sbCorner.Parent = Sidebar
    
    -- Fix rounded corner clipping on right side
    local sbFix = Instance.new("Frame")
    sbFix.BackgroundColor3 = UI_THEME.Sidebar
    sbFix.BorderSizePixel = 0
    sbFix.Size = UDim2.new(0, 10, 1, 0)
    sbFix.Position = UDim2.new(1, -10, 0, 0)
    sbFix.Parent = Sidebar

    -- Title
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 50)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = UI_THEME.Accent
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Sidebar

    -- Version
    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Size = UDim2.new(1, 0, 0, 20)
    VersionLabel.Position = UDim2.new(0, 15, 0, 28)
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Text = "v" .. VERSION
    VersionLabel.Font = Enum.Font.Gotham
    VersionLabel.TextSize = 12
    VersionLabel.TextColor3 = UI_THEME.TextDark
    VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
    VersionLabel.Parent = Sidebar

    -- Tab Container
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "Tabs"
    TabContainer.Size = UDim2.new(1, 0, 1, -60)
    TabContainer.Position = UDim2.new(0, 0, 0, 60)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 2
    TabContainer.Parent = Sidebar

    local uiLayout = Instance.new("UIListLayout")
    uiLayout.Padding = UDim.new(0, 5)
    uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiLayout.Parent = TabContainer

    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "Content"
    ContentArea.Size = UDim2.new(0.72, 0, 1, -20) -- Responsive width
    ContentArea.Position = UDim2.new(0.28, 0, 0, 10)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = MainFrame
    
    UIState.MainFrame = MainFrame
    UIState.ContentArea = ContentArea
    UIState.TabContainer = TabContainer

    -- Dragging Logic Helper
    -- MEMORY LEAK FIX: Track ALL connections including frame-level ones
    -- CRITICAL FIX: Don't create new Tweens every frame - only update position directly
    -- RESPONSIVE FIX: Update to use Scale-based positioning and screen bounding
    local function MakeDraggable(Frame)
        table.insert(UIState.DraggableFrames, Frame)
        local dragging, dragInput, dragStart, startAbsPos
        
        -- Track frame-level connections for cleanup
        TrackConnection(Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                -- Store the initial anchor position in absolute pixels
                startAbsPos = Frame.AbsolutePosition + (Frame.AbsoluteSize * Frame.AnchorPoint)
            end
        end))
        
        TrackConnection(Frame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end))
        
        TrackConnection(Frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end))
        
        -- CRITICAL MEMORY FIX: Update position DIRECTLY instead of creating new Tweens every frame
        TrackConnection(UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                local newAbsPos = startAbsPos + Vector2.new(delta.X, delta.Y)
                
                local viewportSize = Camera.ViewportSize
                local absoluteSize = Frame.AbsoluteSize
                local anchor = Frame.AnchorPoint
                
                -- MATHEMATICAL BOUNDING: Clamp against ViewportSize using AbsoluteSize and AnchorPoint
                local minX = anchor.X * absoluteSize.X
                local maxX = viewportSize.X - (1 - anchor.X) * absoluteSize.X
                local minY = anchor.Y * absoluteSize.Y
                local maxY = viewportSize.Y - (1 - anchor.Y) * absoluteSize.Y
                
                local clampedX = math.clamp(newAbsPos.X, minX, maxX)
                local clampedY = math.clamp(newAbsPos.Y, minY, maxY)
                
                -- Update to SCALE for responsiveness
                pcall(function()
                    local clampedX = math.clamp(newAbsPos.X, minX, maxX)
                    local clampedY = math.clamp(newAbsPos.Y, minY, maxY)
                    Frame.Position = UDim2.fromScale(clampedX / viewportSize.X, clampedY / viewportSize.Y)
                end)
            end
        end))
    end
    UI.MakeDraggable = MakeDraggable

    MakeDraggable(MainFrame)

    -- Minimize Button (Main Window)
    local MinButton = Instance.new("TextButton")
    MinButton.Name = "Minimize"
    MinButton.Size = UDim2.new(0, 30, 0, 30)
    MinButton.Position = UDim2.new(1, -30, 0, 0)
    MinButton.BackgroundTransparency = 1
    MinButton.Text = "-"
    MinButton.Font = Enum.Font.GothamBold
    MinButton.TextSize = 20
    MinButton.TextColor3 = UI_THEME.TextDark
    MinButton.Parent = MainFrame

    local Minimized = false
    local OldSize = MainFrame.Size
    
    local minimizedText = "Sp3arParvus v" .. VERSION
    local textSize = TextService:GetTextSize(minimizedText, 14, Enum.Font.GothamBold, Vector2.new(1000, 1000))
    local minimizedWidth = textSize.X + 45

    local MinimizedLabel = Instance.new("TextLabel")
    MinimizedLabel.Name = "MinimizedLabel"
    MinimizedLabel.Text = minimizedText
    MinimizedLabel.Font = Enum.Font.GothamBold
    MinimizedLabel.TextSize = 14
    MinimizedLabel.TextColor3 = UI_THEME.Accent
    MinimizedLabel.Position = UDim2.fromOffset(10, 0)
    MinimizedLabel.Size = UDim2.new(1, -45, 1, 0)
    MinimizedLabel.BackgroundTransparency = 1
    MinimizedLabel.TextXAlignment = Enum.TextXAlignment.Left
    MinimizedLabel.Visible = false
    MinimizedLabel.Parent = MainFrame

    local function ToggleMinimize()
        Minimized = not Minimized
        if Minimized then
            OldSize = MainFrame.Size
            aspect.Parent = nil
            mainConstraint.Parent = nil
            -- Responsive Minimize: Use relative Scale for position (Top-Right)
            TweenService:Create(MainFrame, TWEENS.SMOOTH, {
                Size = UDim2.fromOffset(minimizedWidth, 30),
                Position = UDim2.new(1, -minimizedWidth, 0, 30),
                AnchorPoint = Vector2.new(0, 0)
            }):Play()
            ContentArea.Visible = false
            Sidebar.Visible = false
            MinimizedLabel.Visible = true
            MinButton.Text = "+"
        else
            MinimizedLabel.Visible = false
            aspect.Parent = MainFrame
            mainConstraint.Parent = MainFrame
            TweenService:Create(MainFrame, TWEENS.SMOOTH, {
                Size = OldSize,
                Position = UDim2.fromScale(0.5, 0.5),
                AnchorPoint = Vector2.new(0.5, 0.5)
            }):Play()
            task.wait(0.1)
            ContentArea.Visible = true
            Sidebar.Visible = true
            MinButton.Text = "-"
        end
    end
    UIState.ToggleMinimize = ToggleMinimize

    -- MEMORY LEAK FIX: Track minimize button connection
    TrackConnection(MinButton.MouseButton1Click:Connect(ToggleMinimize))

    -- Toggle Logic (Right Shift)
    -- MEMORY LEAK FIX: Track this connection
    TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.CapsLock then
            UIState.Visible = not UIState.Visible
            MainFrame.Visible = UIState.Visible
            if UIState.Visible then
                MainFrame.Size = UDim2.fromOffset(0,0)
                MainFrame.Visible = true 
                TweenService:Create(MainFrame, TWEENS.BACK, {Size = Minimized and UDim2.fromOffset(minimizedWidth, 30) or UDim2.fromOffset(600, 400)}):Play()
            end
        end
    end))

    return UI
end

function UI.CreateTab(name, icon)
    local TabButton = Instance.new("TextButton")
    TabButton.Name = name .. "Tab"
    TabButton.Size = UDim2.new(1, -20, 0, 32)
    TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TabButton.BackgroundTransparency = 1
    TabButton.Text = ""
    TabButton.Parent = UIState.TabContainer

    local TabLabel = Instance.new("TextLabel")
    TabLabel.Size = UDim2.new(1, -20, 1, 0)
    TabLabel.Position = UDim2.new(0, 15, 0, 0)
    TabLabel.BackgroundTransparency = 1
    TabLabel.Text = name
    TabLabel.Font = Enum.Font.GothamMedium
    TabLabel.TextSize = 14
    TabLabel.TextColor3 = UI_THEME.TextDark
    TabLabel.TextXAlignment = Enum.TextXAlignment.Left
    TabLabel.Parent = TabButton
    
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 3, 0, 16)
    Indicator.Position = UDim2.new(0, 0, 0.5, -8)
    Indicator.BackgroundColor3 = UI_THEME.Accent
    Indicator.BorderSizePixel = 0
    Indicator.BackgroundTransparency = 1
    Indicator.Parent = TabButton
    local indCorner = Instance.new("UICorner"); indCorner.CornerRadius = UDim.new(1,0); indCorner.Parent = Indicator

    -- Page Frame
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 2
    Page.Visible = false
    Page.Parent = UIState.ContentArea
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = Page
    
    TrackConnection(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    end))
    
    local padding = Instance.new("UIPadding")
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = Page

    -- Tab Selection Logic
    local function SelectTab()
        -- Deselect all
        for _, t in pairs(UIState.Tabs) do
            TweenService:Create(t.Label, TWEENS.MEDIUM, {TextColor3 = UI_THEME.TextDark}):Play()
            TweenService:Create(t.Indicator, TWEENS.MEDIUM, {BackgroundTransparency = 1}):Play()
            t.Page.Visible = false
        end
        -- Select current
        TweenService:Create(TabLabel, TWEENS.MEDIUM, {TextColor3 = UI_THEME.Text}):Play()
        TweenService:Create(Indicator, TWEENS.MEDIUM, {BackgroundTransparency = 0}):Play()
        Page.Visible = true
        UIState.CurrentTab = name
    end

    -- MEMORY LEAK FIX: Track tab button connection
    TrackConnection(TabButton.MouseButton1Click:Connect(SelectTab))
    
    -- Register
    table.insert(UIState.Tabs, {Button = TabButton, Label = TabLabel, Indicator = Indicator, Page = Page})
    
    -- Auto-select first tab
    if #UIState.Tabs == 1 then
        SelectTab()
    end

    return Page
end

function UI.CreateSection(page, name)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 30)
    Container.BackgroundTransparency = 1
    Container.Parent = page
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.Position = UDim2.new(0, 2, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = string.upper(name)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 11
    Label.TextColor3 = UI_THEME.Accent
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
end

function UI.CreateToggle(page, text, flag, default, callback, lockable)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = UI_THEME.Element
    Frame.BorderSizePixel = 0
    Frame.Parent = page
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, lockable and -30 or 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextColor3 = UI_THEME.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    if lockable then
        local LockBtn = Instance.new("TextButton")
        LockBtn.Name = "Lock"
        LockBtn.Size = UDim2.new(0, 24, 0, 24)
        LockBtn.AnchorPoint = Vector2.new(1, 0.5)
        LockBtn.Position = UDim2.new(1, -64, 0.5, 0)
        LockBtn.BackgroundTransparency = 1
        LockBtn.Text = Flags[flag .. "/Locked"] and "🔒" or "🔓"
        LockBtn.Font = Enum.Font.GothamBold
        LockBtn.TextSize = 14
        LockBtn.TextColor3 = Flags[flag .. "/Locked"] and UI_THEME.Accent or UI_THEME.TextDark
        LockBtn.Parent = Frame
        
        TrackConnection(LockBtn.MouseButton1Click:Connect(function()
            Flags[flag .. "/Locked"] = not Flags[flag .. "/Locked"]
            LockBtn.TextColor3 = Flags[flag .. "/Locked"] and UI_THEME.Accent or UI_THEME.TextDark
            LockBtn.Text = Flags[flag .. "/Locked"] and "🔒" or "🔓"
        end))
    end
    
    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.new(0, 44, 0, 22)
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.Position = UDim2.new(1, -12, 0.5, 0)
    Switch.BackgroundColor3 = default and UI_THEME.Accent or Color3.fromRGB(50, 50, 50)
    Switch.BorderSizePixel = 0
    Switch.Parent = Frame
    
    local swCorner = Instance.new("UICorner")
    swCorner.CornerRadius = UDim.new(1, 0)
    swCorner.Parent = Switch
    
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.AnchorPoint = Vector2.new(0, 0.5)
    Knob.Position = default and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent = Switch
    
    local kbCorner = Instance.new("UICorner")
    kbCorner.CornerRadius = UDim.new(1, 0)
    kbCorner.Parent = Knob
    
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.Parent = Switch
    
    Flags[flag] = default
    
    local function updateVisuals(state)
        local targetColor = state and UI_THEME.Accent or Color3.fromRGB(50, 50, 50)
        local targetPos = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        
        TweenService:Create(Switch, TWEENS.MEDIUM, {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(Knob, TWEENS.SMOOTH, {Position = targetPos}):Play()
    end

    UIState.Updaters[flag] = updateVisuals

    -- MEMORY LEAK FIX: Track button connection
    TrackConnection(Button.MouseButton1Click:Connect(function()
        Flags[flag] = not Flags[flag]
        local state = Flags[flag]
        updateVisuals(state)
        if callback then callback(state) end
    end))
end

function UI.CreateNumericInput(page, text, flag, default, min, max, step, unit, callback, lockable)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 48)
    Frame.BackgroundColor3 = UI_THEME.Element
    Frame.BorderSizePixel = 0
    Frame.Parent = page
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, lockable and -42 or -12, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextColor3 = UI_THEME.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    if lockable then
        local LockBtn = Instance.new("TextButton")
        LockBtn.Name = "Lock"
        LockBtn.Size = UDim2.new(0, 24, 0, 24)
        LockBtn.AnchorPoint = Vector2.new(1, 0.5)
        LockBtn.Position = UDim2.new(0.6, -12, 0.5, 0)
        LockBtn.BackgroundTransparency = 1
        LockBtn.Text = Flags[flag .. "/Locked"] and "🔒" or "🔓"
        LockBtn.Font = Enum.Font.GothamBold
        LockBtn.TextSize = 14
        LockBtn.TextColor3 = Flags[flag .. "/Locked"] and UI_THEME.Accent or UI_THEME.TextDark
        LockBtn.Parent = Frame
        
        TrackConnection(LockBtn.MouseButton1Click:Connect(function()
            Flags[flag .. "/Locked"] = not Flags[flag .. "/Locked"]
            LockBtn.TextColor3 = Flags[flag .. "/Locked"] and UI_THEME.Accent or UI_THEME.TextDark
            LockBtn.Text = Flags[flag .. "/Locked"] and "🔒" or "🔓"
        end))
    end
    
    local InputFrame = Instance.new("Frame")
    InputFrame.Size = UDim2.new(0.4, -12, 0, 30)
    InputFrame.Position = UDim2.new(1, -12, 0.5, 0)
    InputFrame.AnchorPoint = Vector2.new(1, 0.5)
    InputFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    InputFrame.Parent = Frame
    local ifCorner = Instance.new("UICorner"); ifCorner.CornerRadius = UDim.new(0, 4); ifCorner.Parent = InputFrame

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -50, 1, 0)
    Input.Position = UDim2.new(0, 25, 0, 0)
    Input.BackgroundTransparency = 1
    Input.Text = tostring(default)
    Input.Font = Enum.Font.GothamBold
    Input.TextSize = 13
    Input.TextColor3 = UI_THEME.Accent
    Input.ClearTextOnFocus = false
    Input.Parent = InputFrame

    local function updateValue(val)
        val = math.clamp(tonumber(val) or default, min, max)
        if step and step > 0 then
            val = math.floor(val / step + 0.5) * step
        end
        Flags[flag] = val
        Input.Text = tostring(val)
        if callback then callback(val) end
    end

    UIState.Updaters[flag] = function(val)
        if not Input:IsFocused() then
            val = math.clamp(tonumber(val) or default, min, max)
            if step and step > 0 then
                val = math.floor(val / step + 0.5) * step
            end
            Input.Text = tostring(val)
        end
    end

    TrackConnection(Input.FocusLost:Connect(function()
        updateValue(Input.Text)
    end))

    local function createBtn(t, pos, xAlign)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 25, 1, 0)
        btn.Position = pos
        btn.BackgroundTransparency = 1
        btn.Text = t
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.TextColor3 = UI_THEME.TextDark
        btn.Parent = InputFrame
        return btn
    end

    local minusBtn = createBtn("-", UDim2.new(0, 0, 0, 0))
    local plusBtn = createBtn("+", UDim2.new(1, -25, 0, 0))

    TrackConnection(minusBtn.MouseButton1Click:Connect(function()
        updateValue(Flags[flag] - (step or 1))
    end))

    TrackConnection(plusBtn.MouseButton1Click:Connect(function()
        updateValue(Flags[flag] + (step or 1))
    end))

    Flags[flag] = default
end

function UI.CreateButton(page, text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 36)
    Button.BackgroundColor3 = UI_THEME.Accent
    Button.BackgroundTransparency = 0.2
    Button.BorderSizePixel = 0
    Button.Text = text
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 13
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Parent = page
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = Button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = UI_THEME.Accent
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = Button
    
    -- MEMORY LEAK FIX: Track button connection
    TrackConnection(Button.MouseButton1Click:Connect(function()
        -- Click animation
        TweenService:Create(Button, TWEENS.INSTANT, {Size = UDim2.new(1, -4, 0, 32)}):Play()
        task.wait(0.05)
        TweenService:Create(Button, TWEENS.INSTANT, {Size = UDim2.new(1, 0, 0, 36)}):Play()
        if callback then callback() end
    end))
end

-- Get ping (uses GetNetworkPing for accuracy relative to built-in monitor)
function GetPing()
    local success, ping = pcall(LocalPlayer.GetNetworkPing, LocalPlayer)
    return success and ping * 1000 or 0
end

-- FPS counter setup (OPTIMIZED - fixed memory, no allocations per frame)
-- FPS counter setup (RE-OPTIMIZED - uses proper frame counting via RenderStepped)
GetFPS = nil
do
    local frameCount = 0
    local lastTime = os.clock()
    local cachedFPS = 60
    local updateInterval = 0.5 -- Update display value every 500ms
    
    GetFPS = function() return cachedFPS end
    
    -- Hidden internal update loop
    TrackConnection(Services.RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = os.clock()
        local elapsed = now - lastTime
        
        if elapsed >= updateInterval then
            cachedFPS = math.floor(frameCount / elapsed)
            frameCount = 0
            lastTime = now
        end
    end))
end

-- Rejoin current server
function Rejoin()
    if #Services.Players:GetPlayers() <= 1 then
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


-- FULLBRIGHT SYSTEM

function UpdateFullbright()
    local currentState = Flags["Visuals/Fullbright"]
    
    if currentState ~= FullbrightState.lastState then
        if currentState then
            -- Store original settings
            local atmosphere = Services.Lighting:FindFirstChildOfClass("Atmosphere")
            FullbrightState.originalSettings = {
                Ambient = Services.Lighting.Ambient,
                OutdoorAmbient = Services.Lighting.OutdoorAmbient,
                Brightness = Services.Lighting.Brightness,
                ClockTime = Services.Lighting.ClockTime,
                FogEnd = Services.Lighting.FogEnd,
                GlobalShadows = Services.Lighting.GlobalShadows,
                AtmosphereDensity = atmosphere and atmosphere.Density or nil
            }
        else
            -- Restore original settings
            if FullbrightState.originalSettings then
                Services.Lighting.Ambient = FullbrightState.originalSettings.Ambient
                Services.Lighting.OutdoorAmbient = FullbrightState.originalSettings.OutdoorAmbient
                Services.Lighting.Brightness = FullbrightState.originalSettings.Brightness
                Services.Lighting.ClockTime = FullbrightState.originalSettings.ClockTime
                Services.Lighting.FogEnd = FullbrightState.originalSettings.FogEnd
                Services.Lighting.GlobalShadows = FullbrightState.originalSettings.GlobalShadows
                
                if FullbrightState.originalSettings.AtmosphereDensity then
                    local atmosphere = Services.Lighting:FindFirstChildOfClass("Atmosphere")
                    if atmosphere then
                        atmosphere.Density = FullbrightState.originalSettings.AtmosphereDensity
                    end
                end
                FullbrightState.originalSettings = nil
            end
        end
        FullbrightState.lastState = currentState
    end

    if not currentState then return end
    
    Services.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Services.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Services.Lighting.Brightness = 2
    Services.Lighting.ClockTime = 12
    Services.Lighting.FogEnd = 1e5
    Services.Lighting.GlobalShadows = false
    
    local atmosphere = Services.Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        atmosphere.Density = 0
    end
end


-- TEAM & CHARACTER DETECTION


-- Check if player is on enemy team
-- Get character and check health (Heavily Optimized with Cache)
CharCache = {} -- [Player] = {Char, Root, Humanoid, HealthInst, Squad}

function GetCharacter(player)
    if not player then return nil end
    
    -- Fast path: Check cache
    local cache = CharCache[player]
    if cache then
        local char = cache.Char
        local root = cache.Root
        
        -- Verify validity (parented) and ensure it's the current character
        if char and char.Parent and char == player.Character and root and root.Parent then
            -- Standard Humanoid Check
            if cache.Humanoid then
                if cache.Humanoid.Health > 0 then
                    return char, root
                end
                return nil
            -- Fallback Custom Health Check (AR2)
            elseif cache.HealthInst then
                 if cache.HealthInst.Value > 0 then
                     return char, root
                 end
                 return nil
            else
                -- No health object found, assume alive
                return char, root
            end
        else
             -- Stale cache
             cache.Char = nil
             cache.Root = nil
             cache.Humanoid = nil
             cache.HealthInst = nil
             cache.Head = nil
        end
    end

    -- Slow path: Find and cache
    local character = player.Character
    if not character or not character.Parent then return nil end

    local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not rootPart then return nil end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local healthInst = nil
    
    -- If no humanoid, check for AR2 style stats
    if not humanoid then
        local stats = player:FindFirstChild("Stats")
        if stats and stats:IsA("Folder") then
            local health = stats:FindFirstChild("Health")
            if health and health:IsA("ValueBase") then
                healthInst = health
            end
        end
    end
    
    -- Populate cache
    if not cache then
        cache = {}
        CharCache[player] = cache
    end
    cache.Char = character
    cache.HumanoidRootPart = rootPart
    cache.Root = rootPart
    cache.Humanoid = humanoid
    cache.HealthInst = healthInst
    
    -- Pre-cache common target parts
    cache.Head = character:FindFirstChild("Head")

    if humanoid and humanoid.Health <= 0 then return nil end
    if healthInst and healthInst.Value <= 0 then return nil end

    return character, rootPart
end

function GetHealth(player)
    if not player then return 0, 100 end
    
    local cache = CharCache[player]
    if cache then
        if cache.Humanoid then
            return cache.Humanoid.Health, cache.Humanoid.MaxHealth
        elseif cache.HealthInst then
            return cache.HealthInst.Value, 100 -- AR2 style health usually defaults to 100 max
        end
    end
    
    -- Fallback: Slow search
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return humanoid.Health, humanoid.MaxHealth
        end
        
        -- AR2 Fallback
        local stats = player:FindFirstChild("Stats")
        if stats and stats:IsA("Folder") then
            local health = stats:FindFirstChild("Health")
            if health and health:IsA("ValueBase") then
                return health.Value, 100
            end
        end
    end
    
    return 0, 100
end

function InEnemyTeam(Enabled, Player)
    if not Enabled then return true end

    -- Standard team check
    local lpTeam, pTeam = LocalPlayer.Team, Player.Team
    if lpTeam and pTeam then
        if lpTeam == pTeam then
            return false
        end
    end

    -- AR2 Squad check
    local pCache = CharCache[Player]
    if not pCache then 
        GetCharacter(Player)
        pCache = CharCache[Player]
    end
    
    if pCache then
        if pCache.Squad == nil then
            pCache.Squad = Player:FindFirstChild("Squad") or false
        end
        
        local playerSquad = pCache.Squad
        if playerSquad then
            local lpCache = CharCache[LocalPlayer]
            if not lpCache then
                GetCharacter(LocalPlayer)
                lpCache = CharCache[LocalPlayer]
            end
            
            if lpCache then
                if lpCache.Squad == nil then
                    lpCache.Squad = LocalPlayer:FindFirstChild("Squad") or false
                end
                
                local localSquad = lpCache.Squad
                if localSquad and localSquad.Value ~= "" and localSquad.Value == playerSquad.Value then
                    return false
                end
            end
        end
    end

    return true
end

function DNS(Player)
    local whtels = {1628571024, 125458810, 8259510869, 1554084058, 10476800936}
    for i = 1, #whtels do
        if Player.UserId == whtels[i] then
            return true
        end
    end
    return false
end

-- Periodic CharCache pruning (removes stale entries for players who left or have invalid characters)
lastCharCachePrune = 0
CHAR_CACHE_PRUNE_INTERVAL = 5.0 -- Prune every 5 seconds

function PruneCharCache()
    local now = os.clock()
    if (now - lastCharCachePrune) < CHAR_CACHE_PRUNE_INTERVAL then return end
    lastCharCachePrune = now
    
    local players = Players:GetPlayers()
    local playerMap = {}
    for i = 1, #players do playerMap[players[i]] = true end

    for player, cache in pairs(CharCache) do
        -- Remove if player left the game
        if not playerMap[player] or not player.Parent then
            if AimState.LastAimbotTarget == player then
                AimState.LastAimbotTarget = nil
            end
            RemoveESP(player)
            cache.Char = nil
            cache.HumanoidRootPart = nil
            cache.Head = nil
            cache.Root = nil
            cache.Humanoid = nil
            cache.HealthInst = nil
            cache.Squad = nil
            CharCache[player] = nil
        -- Clear character-linked fields if character is invalid/destroyed
        elseif cache.Char and not cache.Char.Parent then
            if AimState.LastAimbotTarget == player then
                AimState.LastAimbotTarget = nil
            end
            RemovePlayerOutlines(player)
            cache.Char = nil
            cache.Root = nil
            cache.Humanoid = nil
            cache.HealthInst = nil
            cache.Head = nil
        elseif cache.Root and not cache.Root.Parent then
            if AimState.LastAimbotTarget == player then
                AimState.LastAimbotTarget = nil
            end
            RemovePlayerOutlines(player)
            cache.Root = nil
            cache.Humanoid = nil
            cache.HealthInst = nil
            cache.Head = nil
        end
    end
end

-- Forward declarations for cleanup functions (implemented after variable declarations)
ClearCandidateReferences = nil
ClearSortCacheReferences = nil

-- ESPObjects validation sweep (removes orphaned ESP entries for players who left)
-- This is a safety net in case PlayerRemoving didn't fire properly
-- Note: ESPObjects is declared later in file, so we need nil check
function ValidateESPObjects()
    if not ESPObjects then return end -- Safety: ESPObjects declared later in file
    for player, espData in pairs(ESPObjects) do
        -- Check if player is gone or orphaned
        if not player or not player.Parent then
            -- Cleanup the orphaned ESP
            pcall(function()
                if espData.Nametag then espData.Nametag:Destroy() end
                if espData.Tracer then espData.Tracer:Destroy() end
                if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
                    espData.OffscreenIndicator.Frame:Destroy()
                end
                if espData.Connections then
                    for _, conn in pairs(espData.Connections) do
                        if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                            conn:Disconnect()
                        end
                    end
                    table.clear(espData.Connections)
                end
                espData.Nametag = nil
                espData.Tracer = nil
                if espData.OffscreenIndicator then
                    espData.OffscreenIndicator.Frame = nil
                    espData.OffscreenIndicator.Arrow = nil
                    espData.OffscreenIndicator.NameLabel = nil
                    espData.OffscreenIndicator.DistLabel = nil
                    espData.OffscreenIndicator.Stroke = nil
                end
                espData.OffscreenIndicator = nil
                espData.Connections = nil
            end)
            ESPObjects[player] = nil
        end
    end
end


-- PHYSICS & BALLISTICS


-- Maximum reasonable velocity magnitude (studs/second) - tries to prevents aim snapping to sky (fails) 
MAX_TARGET_VELOCITY = 100 -- Most players can't move faster than this legitimately

-- Solve projectile trajectory with gravity (FIXED - clamps extreme values)
function SolveTrajectory(origin, velocity, time, gravity)
    -- Safety check for NaN in time
    if time ~= time then return origin end

    -- Safety check for NaN or zero velocity
    local velocityMagnitude = velocity.Magnitude
    if velocityMagnitude ~= velocityMagnitude or velocityMagnitude == 0 then
        -- NaN check (NaN ~= NaN is true) or zero velocity - just return origin
        return origin
    end
    
    -- Clamp time to reasonable values (prevents extreme predictions at long range)
    time = min(time, 1.0) -- Max 1 second of prediction
    
    -- Clamp velocity magnitude to prevent extreme predictions
    if velocityMagnitude > MAX_TARGET_VELOCITY then
        -- Scale down to max velocity while keeping direction
        velocity = velocity.Unit * MAX_TARGET_VELOCITY
    end
    
    -- Calculate predicted position
    local gravityVector = Vector3.new(0, -0.5 * gravity * AimState.GravityCorrection * time * time, 0)
    local predictedPosition = origin + velocity * time + gravityVector
    
    -- Sanity check: if predicted position is too far from origin, return original
    local predictionOffset = (predictedPosition - origin).Magnitude
    -- Fix: NaN check (NaN > 200 is false in Lua, so we must explicitly check for NaN)
    if predictionOffset ~= predictionOffset or predictionOffset > 200 then 
        return origin -- Fall back to actual position
    end
    
    return predictedPosition
end


-- AIMBOT CORE (EXACT CODE FROM PARVUS)


-- Raycast for visibility check
-- Cache the FilterType enum value once
CachedFilterType = (function()
    -- Try Exclude first (modern)
    local ok, val = pcall(function()
        local ft = Enum.RaycastFilterType.Exclude
        -- Validate it's actually an EnumItem
        if typeof(ft) == "EnumItem" then
            return ft
        end
    end)
    if ok and val then
        print("[Sp3arParvus] Successfully cached RaycastFilterType.Exclude")
        return val
    end

    -- Try Blacklist (legacy)
    ok, val = pcall(function()
        local ft = Enum.RaycastFilterType.Blacklist
        if typeof(ft) == "EnumItem" then
            return ft
        end
    end)
    if ok and val then
        print("[Sp3arParvus] Successfully cached RaycastFilterType.Blacklist")
        return val
    end

    -- Return nil if neither works
    warn("[Sp3arParvus] WARNING: Could not cache any RaycastFilterType enum - raycasts may not filter properly")
    return nil
end)()

SharedRaycastParams = RaycastParams.new()
SharedRaycastParams.IgnoreWater = true

function Raycast(Origin, Direction, Filter)
    SharedRaycastParams.FilterDescendantsInstances = Filter

    -- Only set FilterType if we successfully cached a valid enum
    if CachedFilterType then
        SharedRaycastParams.FilterType = CachedFilterType
    end

    return Workspace:Raycast(Origin, Direction, SharedRaycastParams)
end

function WithinReach(Enabled, Distance, Limit)
    if not Enabled then return true end
    return Distance < Limit
end

-- PERFORMANCE FIX: Reusable filter table for visibility raycasts
OcclusionFilter = {nil, nil}

function ObjectOccluded(Enabled, Origin, Position, Object)
    if not Enabled then return false end
    -- Safety check: Ensure Position is a valid Vector3 to prevent arithmetic errors
    if typeof(Position) ~= "Vector3" then return false end
    
    -- Reuse filter table instead of creating new one every call
    OcclusionFilter[1] = LocalPlayer.Character
    local hit = Raycast(Origin, Position - Origin, OcclusionFilter)
    
    if hit and hit.Instance and not hit.Instance:IsDescendantOf(Object) then
        return true
    end
    
    return false
end

-- OPTIMIZED: Reusable result table to avoid allocations per frame
-- Changed to store x,y directly instead of Vector2 to avoid allocations
ClosestResult = {nil, nil, nil, 0, 0, nil} -- [1]=Player, [2]=Character, [3]=BodyPart, [4]=screenX, [5]=screenY, [6]=pos

-- Hoisted comparator for candidate sorting
function CandidateSortFn(a, b)
    return a.mag < b.mag
end

-- Hoisted comparator for distance sorting
function DistanceSortFn(a, b)
    return a.distance < b.distance
end

-- OPTIMIZED: Reusable tables for candidate sorting to avoid per-frame allocations
CandidateList = {} -- Array of {dist, data...}
CandidateCount = 0
MAX_CANDIDATES = 15 -- Cap max candidates to process for performance

-- CandidateList cleanup (clears object references to prevent stale refs and shrinks table)
-- Now properly placed after CandidateList and ClosestResult are declared
function ClearCandidateReferences()
    if not CandidateList then return end -- Safety check
    
    -- If CandidateList bloated beyond reasonable bounds, explicitly shrink it
    -- but keep a reasonable pool size to avoid re-allocation
    if #CandidateList > MAX_CANDIDATES * 3 then
        for i = MAX_CANDIDATES * 3 + 1, #CandidateList do
            CandidateList[i] = nil
        end
    end

    for i = 1, #CandidateList do
        local entry = CandidateList[i]
        if entry then
            entry.ply = nil
            entry.char = nil
            entry.part = nil
            entry.pos = nil
        end
    end
    
end

-- ClearSortCacheReferences - Clears cachedPlayerListForSort references
-- Note: cachedPlayerListForSort is declared at line 118
function ClearSortCacheReferences()
    if not cachedPlayerListForSort then return end -- Safety check
    for i = 1, #cachedPlayerListForSort do
        local entry = cachedPlayerListForSort[i]
        if entry then
            entry.player = nil
            entry.position = nil
        end
    end
end

-- GetClosest function (HEAVILY OPTIMIZED - Lazy Raycasting)
function GetClosest(Enabled, TeamCheck, VisibilityCheck, DistanceCheck, DistanceLimit, FieldOfView, Priority, BodyParts, PredictionEnabled, StickyTarget)
    if not Enabled then
        return nil
    end

    local CameraPosition = Camera.CFrame.Position
    local mouseBehavior = UserInputService.MouseBehavior

    -- Calculate crosshair/origin in Viewport space
    local crosshairX, crosshairY, crosshairValid = GetCrosshairViewportPosition(mouseBehavior)
    if not crosshairValid then
        return nil
    end

    -- Reset candidate list
    CandidateCount = 0

    local players = GetPlayersCache()
    local lookVector = Camera.CFrame.LookVector
    local maxCandsLimit = MAX_CANDIDATES * 3

    for _, Player in ipairs(players) do
        if Player == LocalPlayer or DNS(Player) then
            continue
        end

        local Character, RootPart = GetCharacter(Player)
        if not Character or not RootPart then
            continue
        end
        if not InEnemyTeam(TeamCheck, Player) then
            continue
        end

        local rootPos = RootPart.Position
        local relPos = rootPos - CameraPosition
        
        -- 1. DOT PRODUCT PRE-FILTER (Cheap check to ensure target is in front)
        if lookVector:Dot(relPos) < 0 then
            continue
        end

        -- 2. DISTANCE PRE-FILTER
        local rootDist = relPos.Magnitude
        if DistanceCheck and rootDist > (DistanceLimit + 50) then
            continue
        end

        -- 3. VIEWPORT PRE-FILTER (Removed - allows targeting players when root is just off-screen)

        if Priority == "Random" then
            local PartName = BodyParts[math.random(#BodyParts)]
            local cache = CharCache[Player]
            local BodyPart = (cache and cache[PartName]) or Character:FindFirstChild(PartName)
            if BodyPart then
                local ActualPosition = BodyPart.Position
                local Distance = (ActualPosition - CameraPosition).Magnitude

                if not DistanceCheck or Distance < DistanceLimit then
                    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(ActualPosition)
                    if OnScreen then
                        local screenX, screenY = ScreenPosition.X, ScreenPosition.Y
                        local dx, dy = screenX - crosshairX, screenY - crosshairY
                        local Magnitude = sqrt(dx * dx + dy * dy)

                        if Magnitude < FieldOfView then
                            local TargetPosition = ActualPosition
                            if PredictionEnabled then
                                local velocity = BodyPart.AssemblyLinearVelocity
                                if typeof(velocity) ~= "Vector3" then
                                    velocity = Vector3.new(0, 0, 0)
                                end
                                TargetPosition = SolveTrajectory(
                                    ActualPosition,
                                    velocity,
                                    Distance / AimState.ProjectileSpeed,
                                    AimState.ProjectileGravity
                                )
                            end

                            if CandidateCount < maxCandsLimit then
                                CandidateCount = CandidateCount + 1
                                local entry = CandidateList[CandidateCount]
                                if not entry then
                                    entry = {}
                                    CandidateList[CandidateCount] = entry
                                end
                                entry.mag = Magnitude
                                entry.ply = Player
                                entry.char = Character
                                entry.part = BodyPart
                                entry.sx = screenX
                                entry.sy = screenY
                                entry.pos = TargetPosition
                                entry.realPos = ActualPosition
                            end
                        end
                    end
                end
            end
        else
            local checkParts = BodyParts
            if Priority ~= "Closest" and Priority ~= "Random" then
                checkParts = {Priority}
            end

            for _, PartName in ipairs(checkParts) do
                local cache = CharCache[Player]
                local BodyPart = (cache and cache[PartName]) or Character:FindFirstChild(PartName)
                if not BodyPart then
                    continue
                end

                local ActualPosition = BodyPart.Position
                local Distance = (ActualPosition - CameraPosition).Magnitude

                if DistanceCheck and Distance >= DistanceLimit then
                    continue
                end

                local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(ActualPosition)
                if OnScreen then
                    local screenX, screenY = ScreenPosition.X, ScreenPosition.Y
                    local dx, dy = screenX - crosshairX, screenY - crosshairY
                    local Magnitude = sqrt(dx * dx + dy * dy)

                    if Magnitude < FieldOfView then
                        local TargetPosition = ActualPosition
                        if PredictionEnabled then
                            local velocity = BodyPart.AssemblyLinearVelocity
                            if typeof(velocity) ~= "Vector3" then
                                velocity = Vector3.new(0, 0, 0)
                            end
                            TargetPosition = SolveTrajectory(
                                ActualPosition,
                                velocity,
                                Distance / AimState.ProjectileSpeed,
                                AimState.ProjectileGravity
                            )
                        end

                        if CandidateCount < maxCandsLimit then
                            CandidateCount = CandidateCount + 1
                            local entry = CandidateList[CandidateCount]
                            if not entry then
                                entry = {}
                                CandidateList[CandidateCount] = entry
                            end
                            entry.mag = Magnitude
                            entry.ply = Player
                            entry.char = Character
                            entry.part = BodyPart
                            entry.sx = screenX
                            entry.sy = screenY
                            entry.pos = TargetPosition
                            entry.realPos = ActualPosition
                        end
                    end
                end
            end
        end
    end

    if CandidateCount == 0 then
        return nil
    end

    local currentSize = #CandidateList
    if currentSize > CandidateCount then
        for i = CandidateCount + 1, currentSize do
            local entry = CandidateList[i]
            if entry then
                entry.ply = nil
                entry.char = nil
                entry.part = nil
                entry.pos = nil
            end
            CandidateList[i] = nil
        end
    end

    if CandidateCount > 1 then
        table.sort(CandidateList, CandidateSortFn)
    end

    if StickyTarget then
        for i = 1, CandidateCount do
            local entry = CandidateList[i]
            if entry.ply == StickyTarget then
                if not ObjectOccluded(VisibilityCheck, CameraPosition, entry.realPos, entry.char) then
                    ClosestResult[1] = entry.ply
                    ClosestResult[2] = entry.char
                    ClosestResult[3] = entry.part
                    ClosestResult[4] = entry.sx
                    ClosestResult[5] = entry.sy
                    ClosestResult[6] = entry.pos
                    return ClosestResult
                end
                break
            end
        end
    end

    local limit = min(CandidateCount, MAX_CANDIDATES)

    for i = 1, limit do
        local entry = CandidateList[i]
        if not entry then
            continue
        end

        if ObjectOccluded(VisibilityCheck, CameraPosition, entry.realPos, entry.char) then
            continue
        end

        ClosestResult[1] = entry.ply
        ClosestResult[2] = entry.char
        ClosestResult[3] = entry.part
        ClosestResult[4] = entry.sx
        ClosestResult[5] = entry.sy
        ClosestResult[6] = entry.pos

        return ClosestResult
    end

    return nil
end

-- AimAt function (FIXED - handles mouse-locked mode properly)
-- AimAt function (FIXED - stabilized initial acquisition / reacquisition)
function AimAt(Hitbox, Sensitivity)
    if not Hitbox then
        ClearAimLockState(false)
        return
    end
    if not mousemoverel then
        return
    end

    local targetPart = Hitbox[3]
    if not targetPart or not targetPart.Parent then
        ClearAimLockState(false)
        return
    end

    local currentMode = Services.UserInputService.MouseBehavior
    if currentMode ~= AimState.LastMouseMode then
        AimState.LastMouseMode = currentMode
        AimState.LastOriginX = nil
        AimState.LastOriginY = nil
    end

    local currentTarget = Hitbox[1]
    if currentTarget ~= AimState.LastAimbotTarget then
        AimState.LastAimbotTarget = currentTarget
        AimState.LastOriginX = nil
        AimState.LastOriginY = nil
    end

    local targetPos = targetPart.Position
    local cameraCFrame = Camera.CFrame
    local cameraPos = cameraCFrame.Position
    local dist = (targetPos - cameraPos).Magnitude

    if dist < 1 then
        return
    end

    if Flags["Aimbot/Prediction"] then
        local velocity = targetPart.AssemblyLinearVelocity
        if typeof(velocity) ~= "Vector3" then
            velocity = Vector3.new(0, 0, 0)
        end
        targetPos = SolveTrajectory(
            targetPos,
            velocity,
            dist / AimState.ProjectileSpeed,
            AimState.ProjectileGravity
        )
    end

    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(targetPos)
    if not OnScreen or ScreenPosition.Z <= 0 then
        return
    end

    local viewportSize = Camera.ViewportSize
    local originX, originY, originValid = GetCrosshairViewportPosition(currentMode)
    if not originValid then
        return
    end

    local lastOriginX = AimState.LastOriginX
    local lastOriginY = AimState.LastOriginY
    AimState.LastOriginX = originX
    AimState.LastOriginY = originY


    local targetX, targetY = ScreenPosition.X, ScreenPosition.Y
    local dx, dy = targetX - originX, targetY - originY

    local mag = sqrt(dx * dx + dy * dy)
    if mag > Flags["Aimbot/FOV/Radius"] then
        return
    end

    local deltaX = dx * Sensitivity
    local deltaY = dy * Sensitivity

    if deltaX ~= deltaX or deltaY ~= deltaY then
        return
    end

    -- Clamp movement to 50% of viewport size to keep target in view while ensuring continuous tracking
    local maxClampX = viewportSize.X * 0.5
    local maxClampY = viewportSize.Y * 0.5
    
    deltaX = math.clamp(deltaX, -maxClampX, maxClampX)
    deltaY = math.clamp(deltaY, -maxClampY, maxClampY)

    mousemoverel(floor(deltaX + 0.5), floor(deltaY + 0.5))
end


-- ESP SYSTEM


ESPObjects = {} -- [Player] = {Nametag, Tracer, Connections}
PlayerOutlineObjects = {} -- [Player] = { [BodyPartName] = Highlight instance }

COLORS = {
    CLOSEST = Color3.fromRGB(255, 105, 180),
    NORMAL = Color3.fromRGB(255, 255, 255),
    TRACER = Color3.fromRGB(0, 255, 255),
    OUTLINE = Color3.fromRGB(255, 105, 180),
    OFFSCREEN_INDICATOR = Color3.fromRGB(255, 200, 50)
}

-- Off-screen indicator settings
OFFSCREEN_EDGE_PADDING = 50  -- Pixels from screen edge
OFFSCREEN_ARROW_SIZE = 20    -- Size of the direction arrow
-- PERFORMANCE: Max highlights to use (Roblox hard limit is 31, shared with other scripts)
MAX_OUTLINE_HIGHLIGHTS = 15 

-- Distance-based color zones (for tracker, but closest overrides to pink)
COLOR_CLOSE = Color3.fromRGB(255, 50, 50)     -- Red (0-2000 studs)
COLOR_MID = Color3.fromRGB(255, 200, 50)      -- Yellow (2001-4000 studs)
COLOR_FAR = Color3.fromRGB(50, 255, 50)       -- Green (4000+ studs)

-- Closest Player Tracker variables
ClosestPlayerTrackerLabel = nil
TrackerMinimized = false
TrackerOriginalSize = UDim2.fromOffset(220, 70)
NearestPlayerRef = nil
CurrentTargetDistance = 0 -- Track distance for color coding
TrackerStrokeRef = nil -- Cached stroke reference to avoid repeated lookups

-- Get color based on distance (Pink=Closest, Red≤2000, Yellow≤4000, Green>4000)
function GetDistanceColor(distance, isClosest)
    if isClosest then
        return COLORS.CLOSEST -- Pink always overrides for closest player
    end

    if distance <= 2000 then
        return COLOR_CLOSE -- Red
    elseif distance <= 4000 then
        return COLOR_MID -- Yellow
    else
        return COLOR_FAR -- Green
    end
end

-- Get a player's team color (returns white if no team)
-- Wrapped in pcall to prevent errors if Team property access fails
-- Get a player's team color (returns white if no team)
function GetTeamColor(player)
    if not player then return COLORS.NORMAL end
    
    -- Optimized: No pcall needed for standard property access
    if player.Team then
        return player.TeamColor.Color
    end
    
    return COLORS.NORMAL
end

-- PERFORMANCE: Cache camera data per-frame for off-screen calculations
cachedCameraData = {
    cFrame = nil,
    position = nil,
    lookVector = nil,
    rightVector = nil,
    upVector = nil,
    viewportSize = nil,
    cacheTime = 0
}
CAMERA_CACHE_DURATION = 0.016 -- Cache for 1 frame (~60fps)

function UpdateCameraCache(now)
    if (now - cachedCameraData.cacheTime) < CAMERA_CACHE_DURATION then
        return true -- Cache is still valid
    end
    
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return false end
    
    local cframe = Camera.CFrame
    cachedCameraData.cFrame = cframe
    cachedCameraData.position = cframe.Position
    cachedCameraData.lookVector = cframe.LookVector
    cachedCameraData.rightVector = cframe.RightVector
    cachedCameraData.upVector = cframe.UpVector
    cachedCameraData.viewportSize = Camera.ViewportSize
    cachedCameraData.cacheTime = now
    return true
end

-- Calculate screen edge position for off-screen indicator
-- Returns the position clamped to screen edges and the angle toward the target
-- PERFORMANCE: Uses cached camera data to avoid redundant property access
function GetEdgePosition(now, worldPosition)
    -- Update camera cache (shared across all players per frame)
    if not UpdateCameraCache(now) then return nil, nil, nil, false end
    
    local viewportSize = cachedCameraData.viewportSize
    
    -- Still need to call WorldToViewportPoint per-player (can't cache this)
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return nil, nil, nil, false end
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPosition)
    
    -- If on screen, return nil (use normal nametag)
    if onScreen and screenPos.X > OFFSCREEN_EDGE_PADDING and screenPos.X < viewportSize.X - OFFSCREEN_EDGE_PADDING
       and screenPos.Y > OFFSCREEN_EDGE_PADDING and screenPos.Y < viewportSize.Y - OFFSCREEN_EDGE_PADDING then
        return nil, nil, nil, true
    end
    
    -- Calculate center of screen
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2
    
    -- Use cached camera vectors
    local cameraPos = cachedCameraData.position
    local cameraLook = cachedCameraData.lookVector
    local rightVector = cachedCameraData.rightVector
    local upVector = cachedCameraData.upVector
    
    -- Get direction from camera to world position
    local directionToTarget = (worldPosition - cameraPos).Unit
    
    -- Project direction onto camera plane
    local rightDot = rightVector:Dot(directionToTarget)
    local upDot = upVector:Dot(directionToTarget)
    local forwardDot = cameraLook:Dot(directionToTarget)
    
    -- If target is behind camera, we need to flip the direction
    if forwardDot < 0 then
        rightDot = -rightDot
        upDot = -upDot
    end
    
    -- Calculate angle for arrow rotation
    local angle = atan2(rightDot, -upDot)
    
    -- Normalize to get direction on screen
    local screenDirX = rightDot
    local screenDirY = -upDot
    local magnitude = sqrt(screenDirX * screenDirX + screenDirY * screenDirY)
    if magnitude > 0 then
        screenDirX = screenDirX / magnitude
        screenDirY = screenDirY / magnitude
    else
        screenDirX = 0
        screenDirY = 1
    end
    
    -- Calculate edge intersection using constrained approach
    local edgeX, edgeY
    local maxX = viewportSize.X - OFFSCREEN_EDGE_PADDING - 100 -- Extra space for label
    local maxY = viewportSize.Y - OFFSCREEN_EDGE_PADDING - 40
    local minX = OFFSCREEN_EDGE_PADDING
    local minY = OFFSCREEN_EDGE_PADDING
    
    -- Scale direction to reach screen edge
    local scaleX = 1e10
    local scaleY = 1e10
    
    if screenDirX > 0.001 then
        scaleX = (maxX - centerX) / screenDirX
    elseif screenDirX < -0.001 then
        scaleX = (minX - centerX) / screenDirX
    end
    
    if screenDirY > 0.001 then
        scaleY = (maxY - centerY) / screenDirY
    elseif screenDirY < -0.001 then
        scaleY = (minY - centerY) / screenDirY
    end
    
    local scale = min(abs(scaleX), abs(scaleY))
    edgeX = centerX + screenDirX * scale
    edgeY = centerY + screenDirY * scale
    
    -- Clamp to screen bounds
    edgeX = max(minX, min(maxX, edgeX))
    edgeY = max(minY, min(maxY, edgeY))
    
    -- MEMORY FIX: Return raw numbers instead of Vector2.new() to avoid allocations
    return edgeX, edgeY, angle, false
end

-- Create off-screen indicator UI element
function CreateOffscreenIndicator()
    local indicator = Instance.new("Frame")
    indicator.Name = "OffscreenIndicator"
    indicator.Size = UDim2.fromOffset(120, 50)
    indicator.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    indicator.BackgroundTransparency = 0.3
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.ZIndex = 100
    EnsureScreenGui()
    indicator.Parent = ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = indicator
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.OFFSCREEN_INDICATOR
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = indicator
    
    -- Arrow indicator (pointing toward player)
    local arrow = Instance.new("ImageLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.fromOffset(OFFSCREEN_ARROW_SIZE, OFFSCREEN_ARROW_SIZE)
    arrow.Position = UDim2.new(0, 5, 0.5, -OFFSCREEN_ARROW_SIZE/2)
    arrow.BackgroundTransparency = 1
    arrow.Image = "rbxassetid://6034818372" -- Arrow/chevron icon
    arrow.ImageColor3 = COLORS.OFFSCREEN_INDICATOR
    arrow.ImageTransparency = 0
    arrow.ZIndex = 101
    arrow.Parent = indicator
    
    -- Name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -30, 0, 20)
    nameLabel.Position = UDim2.fromOffset(28, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 101
    nameLabel.Text = ""
    nameLabel.Parent = indicator
    
    -- Distance label
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, -30, 0, 18)
    distLabel.Position = UDim2.fromOffset(28, 26)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = COLORS.OFFSCREEN_INDICATOR
    distLabel.TextStrokeTransparency = 0
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 11
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    distLabel.ZIndex = 101
    distLabel.Text = ""
    distLabel.Parent = indicator
    
    return {
        Frame = indicator,
        Arrow = arrow,
        NameLabel = nameLabel,
        DistLabel = distLabel,
        Stroke = stroke
    }
end

-- Create Closest Player Tracker display
TrackerHeaderLabel, TrackerNameLabel, TrackerDistanceLabel = nil, nil, nil -- References to individual labels

function CreateClosestPlayerTracker()
    -- Main container frame
    ClosestPlayerTrackerLabel = Instance.new("Frame")
    ClosestPlayerTrackerLabel.Name = "ClosestPlayerTracker"
    ClosestPlayerTrackerLabel.Size = UDim2.fromScale(0.12, 0.08)
    ClosestPlayerTrackerLabel.Position = UDim2.new(0.5, 0, 0, 0) -- Top Center
    ClosestPlayerTrackerLabel.AnchorPoint = Vector2.new(0.5, 0)
    
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(180, 60)
    sizeConstraint.MaxSize = Vector2.new(250, 60)
    sizeConstraint.Parent = ClosestPlayerTrackerLabel

    ClosestPlayerTrackerLabel.BackgroundTransparency = 0.5
    ClosestPlayerTrackerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ClosestPlayerTrackerLabel.BorderSizePixel = 0
    EnsureScreenGui()
    ClosestPlayerTrackerLabel.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = ClosestPlayerTrackerLabel

    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.CLOSEST
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = ClosestPlayerTrackerLabel
    TrackerStrokeRef = stroke -- Cache the reference

    -- Container for text labels with vertical layout
    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -30, 1, 0)
    textContainer.Position = UDim2.fromOffset(0, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.Parent = ClosestPlayerTrackerLabel

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 2)
    layout.Parent = textContainer

    -- Header label ("Closest Player")
    TrackerHeaderLabel = Instance.new("TextLabel")
    TrackerHeaderLabel.Name = "HeaderLabel"
    TrackerHeaderLabel.Size = UDim2.new(1, 0, 0, 18)
    TrackerHeaderLabel.BackgroundTransparency = 1
    TrackerHeaderLabel.TextColor3 = COLORS.CLOSEST
    TrackerHeaderLabel.Font = Enum.Font.GothamBold
    TrackerHeaderLabel.TextSize = 14
    TrackerHeaderLabel.Text = "Closest Player"
    TrackerHeaderLabel.LayoutOrder = 1
    TrackerHeaderLabel.Parent = textContainer

    -- Name label (player name with team color)
    TrackerNameLabel = Instance.new("TextLabel")
    TrackerNameLabel.Name = "NameLabel"
    TrackerNameLabel.Size = UDim2.new(1, 0, 0, 18)
    TrackerNameLabel.BackgroundTransparency = 1
    TrackerNameLabel.TextColor3 = COLORS.NORMAL
    TrackerNameLabel.Font = Enum.Font.GothamBold
    TrackerNameLabel.TextSize = 14
    TrackerNameLabel.Text = "Searching..."
    TrackerNameLabel.LayoutOrder = 2
    TrackerNameLabel.Parent = textContainer

    -- Distance label (distance with distance-based color)
    TrackerDistanceLabel = Instance.new("TextLabel")
    TrackerDistanceLabel.Name = "DistanceLabel"
    TrackerDistanceLabel.Size = UDim2.new(1, 0, 0, 18)
    TrackerDistanceLabel.BackgroundTransparency = 1
    TrackerDistanceLabel.TextColor3 = COLORS.CLOSEST
    TrackerDistanceLabel.Font = Enum.Font.GothamBold
    TrackerDistanceLabel.TextSize = 14
    TrackerDistanceLabel.Text = ""
    TrackerDistanceLabel.LayoutOrder = 3
    TrackerDistanceLabel.Parent = textContainer

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 30, 40)
    minimizeBtn.BackgroundTransparency = 0.3
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Size = UDim2.fromOffset(20, 20)
    minimizeBtn.Position = UDim2.new(1, -25, 0, 5)
    minimizeBtn.Text = "−"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14
    minimizeBtn.TextColor3 = COLORS.CLOSEST
    minimizeBtn.Parent = ClosestPlayerTrackerLabel

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = minimizeBtn

    -- MEMORY LEAK FIX: Track minimize button connection
    TrackConnection(minimizeBtn.MouseButton1Click:Connect(function()
        TrackerMinimized = not TrackerMinimized
        if TrackerMinimized then
            ClosestPlayerTrackerLabel.Size = UDim2.fromOffset(220, 30)
            textContainer.Visible = false
            minimizeBtn.Text = "+"
        else
            ClosestPlayerTrackerLabel.Size = TrackerOriginalSize
            textContainer.Visible = true
            minimizeBtn.Text = "−"
        end
    end))
    
    if UI.MakeDraggable then
        UI.MakeDraggable(ClosestPlayerTrackerLabel)
    end
end

-- Update Nearest Player (finds closest player once)
function UpdateNearestPlayer()
    local myChar = LocalPlayer.Character
    if not myChar then
        NearestPlayerRef = nil
        return
    end

    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        NearestPlayerRef = nil
        return
    end

    local myRootPos = myRoot.Position
    local best, bestDist = nil, nil

    -- Find closest alive player (OPTIMIZED: removed pcall overhead)
    for _, player in ipairs(GetPlayersCache()) do
        if player ~= LocalPlayer and player.Parent then
            local character, rootPart = GetCharacter(player)
            if character and rootPart then
                local dist = (rootPart.Position - myRootPos).Magnitude
                if not bestDist or dist < bestDist then
                    bestDist = dist
                    best = player
                end
            end
        end
    end

    NearestPlayerRef = best
end

-- Update Closest Player Tracker display
function UpdateClosestPlayerTracker()
    if not Flags["ESP/Enabled"] or not ClosestPlayerTrackerLabel then
        if ClosestPlayerTrackerLabel then
            ClosestPlayerTrackerLabel.Visible = false
        end
        return
    end

    ClosestPlayerTrackerLabel.Visible = true

    if not TrackerMinimized then
        if NearestPlayerRef and NearestPlayerRef.Parent then
            -- PERFORMANCE: Removed pcall for speed, using strict checks instead
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local targetChar = NearestPlayerRef.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

            if myRoot and targetRoot then
                local distance = (targetRoot.Position - myRoot.Position).Magnitude
                local distRounded = floor(distance + 0.5)
                local name = "Unknown"
                if NearestPlayerRef then
                    name = NearestPlayerRef.DisplayName or NearestPlayerRef.Name
                end

                -- Get team color for player name
                local teamColor = GetTeamColor(NearestPlayerRef)
                
                -- Get distance color using gradient system (red/yellow/green, NOT always pink)
                local distColor = GetDistanceColor(distance, false) -- false = use gradient, not pink

                -- Update stroke color to match distance color (using cached reference)
                if TrackerStrokeRef then
                    TrackerStrokeRef.Color = distColor
                end

                -- Update individual labels with their respective colors
                if TrackerNameLabel then
                    TrackerNameLabel.Text = name
                    TrackerNameLabel.TextColor3 = teamColor
                end
                
                if TrackerDistanceLabel then
                    TrackerDistanceLabel.Text = string.format("%d studs away", distRounded)
                    TrackerDistanceLabel.TextColor3 = distColor
                end

                CurrentTargetDistance = distRounded
            else
                if TrackerNameLabel then
                    TrackerNameLabel.Text = "---"
                    TrackerNameLabel.TextColor3 = COLORS.NORMAL
                end
                if TrackerDistanceLabel then
                    TrackerDistanceLabel.Text = ""
                    TrackerDistanceLabel.TextColor3 = COLORS.CLOSEST
                end
            end
        else
            if TrackerNameLabel then
                TrackerNameLabel.Text = "No players nearby"
                TrackerNameLabel.TextColor3 = COLORS.NORMAL
            end
            if TrackerDistanceLabel then
                TrackerDistanceLabel.Text = ""
                TrackerDistanceLabel.TextColor3 = COLORS.CLOSEST
            end
            NearestPlayerRef = nil
        end
    end
end

-- PLAYER PANEL (Top 10 Closest Players)

PlayerPanelFrame = nil
PlayerPanelRows = {}
PlayerPanelMinimized = false
PLAYER_PANEL_MAX_ROWS = 10

-- Calculate direction angle for arrow (returns rotation in degrees)
function GetDirectionToPlayer(targetPosition)
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return 0 end
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return 0 end
    
    local myPos = myRoot.Position
    local dx = targetPosition.X - myPos.X
    local dz = targetPosition.Z - myPos.Z
    
    local dirMag = sqrt(dx*dx + dz*dz)
    if dirMag < 0.01 then return 0 end
    
    local dirX = dx / dirMag
    local dirZ = dz / dirMag
    
    local camLook = Camera.CFrame.LookVector
    local camRight = Camera.CFrame.RightVector
    
    -- 2D components
    local fwdX, fwdZ = camLook.X, camLook.Z
    local fwdMag = sqrt(fwdX*fwdX + fwdZ*fwdZ)
    if fwdMag > 0 then
        fwdX = fwdX / fwdMag
        fwdZ = fwdZ / fwdMag
    end
    
    local rgtX, rgtZ = camRight.X, camRight.Z
    local rgtMag = sqrt(rgtX*rgtX + rgtZ*rgtZ)
    if rgtMag > 0 then
        rgtX = rgtX / rgtMag
        rgtZ = rgtZ / rgtMag
    end
    
    -- Dot products (scalar)
    local forwardDot = fwdX * dirX + fwdZ * dirZ
    local rightDot = rgtX * dirX + rgtZ * dirZ
    
    return deg(atan2(rightDot, forwardDot))
end

-- Create the Player Panel UI
function CreatePlayerPanel()
    if PlayerPanelFrame then return end
    
    -- Main container
    PlayerPanelFrame = Instance.new("Frame")
    PlayerPanelFrame.Name = "PlayerPanel"
    PlayerPanelFrame.Size = UDim2.fromScale(0.15, 0.45)
    PlayerPanelFrame.Position = UDim2.fromScale(0, 0.5) -- Left Center
    PlayerPanelFrame.AnchorPoint = Vector2.new(0, 0.5)
    
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(200, 220)
    sizeConstraint.MaxSize = Vector2.new(300, 360)
    sizeConstraint.Parent = PlayerPanelFrame

    PlayerPanelFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    PlayerPanelFrame.BackgroundTransparency = 0.1
    PlayerPanelFrame.BorderSizePixel = 0
    PlayerPanelFrame.Visible = false
    PlayerPanelFrame.ZIndex = 50
    EnsureScreenGui()
    PlayerPanelFrame.Parent = ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = PlayerPanelFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 1
    stroke.Parent = PlayerPanelFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    header.BorderSizePixel = 0
    header.ZIndex = 51
    header.Parent = PlayerPanelFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    -- Fix bottom corners of header
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 10)
    headerFix.Position = UDim2.new(0, 0, 1, -10)
    headerFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    headerFix.BorderSizePixel = 0
    headerFix.ZIndex = 51
    headerFix.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.fromOffset(10, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎯 Nearby Players"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 52
    title.Parent = header
    
    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.Size = UDim2.fromOffset(24, 24)
    minimizeBtn.Position = UDim2.new(1, -30, 0, 3)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minimizeBtn.BackgroundTransparency = 0.5
    minimizeBtn.Text = "−"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 16
    minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.ZIndex = 52
    minimizeBtn.Parent = header
    
    local minBtnCorner = Instance.new("UICorner")
    minBtnCorner.CornerRadius = UDim.new(0, 4)
    minBtnCorner.Parent = minimizeBtn
    
    -- Content container (scrolling frame for rows)
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -10, 1, -40)
    content.Position = UDim2.fromOffset(5, 35)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    content.CanvasSize = UDim2.fromOffset(0, PLAYER_PANEL_MAX_ROWS * 28)
    content.ZIndex = 51
    content.Parent = PlayerPanelFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 2)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content
    
    -- Create rows for players
    for i = 1, PLAYER_PANEL_MAX_ROWS do
        local row = Instance.new("Frame")
        row.Name = "Row" .. i
        row.Size = UDim2.new(1, -5, 0, 26)
        row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        row.BackgroundTransparency = 0.5
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.ZIndex = 52
        row.Visible = false
        row.Parent = content
        
        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 4)
        rowCorner.Parent = row
        
        -- Rank number
        local rankLabel = Instance.new("TextLabel")
        rankLabel.Name = "Rank"
        rankLabel.Size = UDim2.fromOffset(20, 26)
        rankLabel.Position = UDim2.fromOffset(3, 0)
        rankLabel.BackgroundTransparency = 1
        rankLabel.Text = "#" .. i
        rankLabel.Font = Enum.Font.GothamBold
        rankLabel.TextSize = 10
        rankLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        rankLabel.ZIndex = 53
        rankLabel.Parent = row
        
        -- Direction arrow
        local arrow = Instance.new("TextLabel")
        arrow.Name = "Arrow"
        arrow.Size = UDim2.fromOffset(20, 26)
        arrow.Position = UDim2.fromOffset(22, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "→"
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 14
        arrow.TextColor3 = Color3.fromRGB(255, 200, 50)
        arrow.ZIndex = 53
        arrow.Parent = row
        
        -- Name (nickname) - with team color
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(0, 100, 1, 0)
        nameLabel.Position = UDim2.fromOffset(44, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = ""
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex = 53
        nameLabel.Parent = row
        
        -- Username (@name)
        local usernameLabel = Instance.new("TextLabel")
        usernameLabel.Name = "Username"
        usernameLabel.Size = UDim2.new(0, 80, 1, 0)
        usernameLabel.Position = UDim2.fromOffset(148, 0)
        usernameLabel.BackgroundTransparency = 1
        usernameLabel.Text = ""
        usernameLabel.Font = Enum.Font.Gotham
        usernameLabel.TextSize = 10
        usernameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
        usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        usernameLabel.ZIndex = 53
        usernameLabel.Parent = row
        
        -- Distance
        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "Distance"
        distLabel.Size = UDim2.new(0, 60, 1, 0)
        distLabel.Position = UDim2.new(1, -65, 0, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = ""
        distLabel.Font = Enum.Font.GothamBold
        distLabel.TextSize = 10
        distLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        distLabel.TextXAlignment = Enum.TextXAlignment.Right
        distLabel.ZIndex = 53
        distLabel.Parent = row
        
        PlayerPanelRows[i] = {
            Frame = row,
            Rank = rankLabel,
            Arrow = arrow,
            Name = nameLabel,
            Username = usernameLabel,
            Distance = distLabel,
            lastPlayer = nil,
            lastDist = -1,
            lastAngle = 0
        }
    end
    
    -- Minimize toggle
    -- MEMORY LEAK FIX: Track minimize button connection
    TrackConnection(minimizeBtn.MouseButton1Click:Connect(function()
        PlayerPanelMinimized = not PlayerPanelMinimized
        if PlayerPanelMinimized then
            PlayerPanelFrame.Size = UDim2.fromOffset(320, 30)
            content.Visible = false
            minimizeBtn.Text = "+"
        else
            PlayerPanelFrame.Size = UDim2.fromOffset(320, 340)
            content.Visible = true
            minimizeBtn.Text = "−"
        end
    end))
    
    -- Make draggable
    if UI.MakeDraggable then
        UI.MakeDraggable(PlayerPanelFrame)
    end
end

-- Get sorted list of closest players (OPTIMIZED - uses caching to avoid GC spikes)
function GetSortedPlayersByDistance()
    local now = os.clock()
    local currentPlayers = GetPlayersCache()
    local currentCount = #currentPlayers
    
    -- Return cached result if still valid
    if (now - lastSortTime) < SORT_CACHE_DURATION and currentCount == lastPlayerCountForSort then
        return cachedSortedPlayers
    end
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then 
        table.clear(cachedSortedPlayers)
        return cachedSortedPlayers 
    end
    
    local myPos = myRoot.Position
    
    -- Reuse cached table instead of creating new one
    table.clear(cachedPlayerListForSort)
    local insertIdx = 0
    
    for _, player in ipairs(currentPlayers) do
        if player ~= LocalPlayer and player.Parent then
            local character, rootPart = GetCharacter(player)
            if character and rootPart then
                local dist = (rootPart.Position - myPos).Magnitude
                if dist <= Flags["ESP/MaxDistance"] then
                    insertIdx = insertIdx + 1
                    -- Reuse or create entry
                    local entry = cachedPlayerListForSort[insertIdx]
                    if not entry then
                        entry = {}
                        cachedPlayerListForSort[insertIdx] = entry
                    end
                    entry.player = player
                    entry.distance = dist
                    entry.position = rootPart.Position
                end
            end
        end
    end
    
    -- Sort by distance (closest first)
    -- We only sort the active portion of the list
    if insertIdx > 1 then
        table.sort(cachedPlayerListForSort, DistanceSortFn)
    end
    
    -- Build result (reusing cached result table)
    table.clear(cachedSortedPlayers)
    for i = 1, min(PLAYER_PANEL_MAX_ROWS, #cachedPlayerListForSort) do
        cachedSortedPlayers[i] = cachedPlayerListForSort[i]
    end
    
    lastSortTime = now
    lastPlayerCountForSort = currentCount
    
    return cachedSortedPlayers
end

-- Arrow characters for 8 directions
DIRECTION_ARROWS = {
    "↑", "↗", "→", "↘", "↓", "↙", "←", "↖"
}

function GetArrowForAngle(angleDeg)
    -- Normalize angle to 0-360
    local normalized = (angleDeg + 180) % 360
    -- Convert to 8 segments (0-7)
    local segment = floor((normalized + 22.5) / 45) % 8
    return DIRECTION_ARROWS[segment + 1] or "→"
end

-- Update Player Panel
function UpdatePlayerPanel()
    if not Flags["ESP/PlayerPanel"] or not PlayerPanelFrame then
        if PlayerPanelFrame then
            PlayerPanelFrame.Visible = false
        end
        return
    end
    
    PlayerPanelFrame.Visible = true
    
    -- Skip content update if minimized
    if PlayerPanelMinimized then return end
    
    local sortedPlayers = GetSortedPlayersByDistance()
    
    for i = 1, PLAYER_PANEL_MAX_ROWS do
        local rowData = PlayerPanelRows[i]
        local playerData = sortedPlayers[i]
        
        if playerData then
            local player = playerData.player
            local dist = playerData.distance
            local distRounded = floor(dist)
            
            rowData.Frame.Visible = true
            
            -- Only update if player changed or distance changed significantly
            local playerChanged = rowData.lastPlayer ~= player
            local distChanged = abs((rowData.lastDist or 0) - distRounded) > 3
            
            if playerChanged then
                -- Update name and username
                local nickname = player.DisplayName or player.Name
                local username = "@" .. player.Name
                
                rowData.Name.Text = nickname
                rowData.Username.Text = username
                
                -- Get team color
                local teamColor = GetTeamColor(player)
                rowData.Name.TextColor3 = teamColor
                
                rowData.lastPlayer = player
            end
            
            if distChanged then
                rowData.Distance.Text = distRounded .. "m"
                
                -- Color based on distance
                local distColor = GetDistanceColor(dist, i == 1)
                rowData.Distance.TextColor3 = distColor
                
                rowData.lastDist = distRounded
            end
            
            -- Update direction arrow (always update since player/camera moves)
            local angle = GetDirectionToPlayer(playerData.position)
            local arrowChar = GetArrowForAngle(angle)
            if rowData.Arrow.Text ~= arrowChar then
                rowData.Arrow.Text = arrowChar
            end
        else
            -- No player for this row
            if rowData.Frame.Visible then
                rowData.Frame.Visible = false
                rowData.lastPlayer = nil
                rowData.lastDist = -1
            end
        end
    end
end

PoolFolder = Instance.new("Folder")
PoolFolder.Name = "Sp3arParvus_Pool"
if gethui then
    PoolFolder.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(PoolFolder)
    PoolFolder.Parent = game.CoreGui
else
    PoolFolder.Parent = game.CoreGui
end

-- Create ESP for a player
local function CreateESP(player)
    if ESPObjects[player] then return end
    if player == LocalPlayer then return end

    local espData = {
        -- Cache previous values to avoid redundant updates
        lastNickname = "",
        lastUsername = "",
        lastDistance = -1,
        lastTeamColor = nil,
        lastDistanceColor = nil,
        Connections = {} -- Store player-specific connections here
    }

    -- Create nametag (BillboardGui) with Username, Nickname, and Distance
    local billboard = Instance.new("BillboardGui")
    billboard.Enabled = false
    billboard.Name = "Nametag"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 90) -- Increased height for 5 lines
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    EnsureScreenGui() -- Ensure parent exists
    billboard.Parent = ScreenGui

    -- Container frame for vertical layout
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = billboard

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 0)
    layout.Parent = container

    -- Display Name (Nickname) - Top line (colored by team)
    local nicknameLabel = Instance.new("TextLabel")
    nicknameLabel.Text = ""
    nicknameLabel.Name = "NicknameLabel"
    nicknameLabel.Size = UDim2.new(1, 0, 0, 18)
    nicknameLabel.BackgroundTransparency = 1
    nicknameLabel.TextColor3 = COLORS.NORMAL
    nicknameLabel.TextStrokeTransparency = 0
    nicknameLabel.Font = Enum.Font.GothamBold
    nicknameLabel.TextSize = 14
    nicknameLabel.LayoutOrder = 1
    nicknameLabel.Parent = container

    -- Username (@name) - Middle line (colored by team)
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Text = ""
    usernameLabel.Name = "UsernameLabel"
    usernameLabel.Size = UDim2.new(1, 0, 0, 18)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.TextColor3 = COLORS.NORMAL
    usernameLabel.TextStrokeTransparency = 0
    usernameLabel.Font = Enum.Font.GothamBold
    usernameLabel.TextSize = 14
    usernameLabel.LayoutOrder = 2
    usernameLabel.Parent = container

    -- Distance label - Third line (colored by distance heat-map)
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Text = ""
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0, 18)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = COLORS.NORMAL
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextSize = 14
    distanceLabel.LayoutOrder = 3
    distanceLabel.Parent = container

    -- Numerical Health label - Fourth line
    local healthNumLabel = Instance.new("TextLabel")
    healthNumLabel.Name = "HealthNumericalLabel"
    healthNumLabel.Size = UDim2.new(1, 0, 0, 18)
    healthNumLabel.BackgroundTransparency = 1
    healthNumLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthNumLabel.TextStrokeTransparency = 0
    healthNumLabel.Font = Enum.Font.GothamBold
    healthNumLabel.TextSize = 14
    healthNumLabel.LayoutOrder = 4
    healthNumLabel.Text = "100/100"
    healthNumLabel.Parent = container

    -- Health Bar Container - Fifth line
    local healthBarBG = Instance.new("Frame")
    healthBarBG.Name = "HealthBarContainer"
    healthBarBG.Size = UDim2.new(0.8, 0, 0, 6)
    healthBarBG.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red for lost health
    healthBarBG.BorderSizePixel = 0
    healthBarBG.LayoutOrder = 5
    healthBarBG.Parent = container
    local hbCorner = Instance.new("UICorner"); hbCorner.CornerRadius = UDim.new(1,0); hbCorner.Parent = healthBarBG

    local healthBarFill = Instance.new("Frame")
    healthBarFill.Name = "HealthBarFill"
    healthBarFill.Size = UDim2.fromScale(1, 1)
    healthBarFill.BackgroundColor3 = Color3.fromRGB(50, 220, 100) -- Green for current health
    healthBarFill.BorderSizePixel = 0
    healthBarFill.Parent = healthBarBG
    local hbfCorner = Instance.new("UICorner"); hbfCorner.CornerRadius = UDim.new(1,0); hbfCorner.Parent = healthBarFill

    espData.Nametag = billboard
    espData.NicknameLabel = nicknameLabel
    espData.UsernameLabel = usernameLabel
    espData.DistanceLabel = distanceLabel
    espData.HealthNumericalLabel = healthNumLabel
    espData.HealthBarContainer = healthBarBG
    espData.HealthBarFill = healthBarFill

    -- Create tracer (Frame based for AlwaysOnTop)
    -- Using a Frame instead of Drawing ensures it renders through walls
    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.Visible = false
    tracer.BackgroundColor3 = COLORS.TRACER
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5) -- Center anchor for rotation
    EnsureScreenGui()
    tracer.Parent = ScreenGui -- Render on top of everything
    
    espData.Tracer = tracer

    -- Create off-screen indicator
    espData.OffscreenIndicator = CreateOffscreenIndicator()
    espData.lastOffscreenVisible = false

    ESPObjects[player] = espData
end

-- Create/Update player body part outlines (Highlight based for Wireframe + AlwaysOnTop)
-- OPTIMIZED: Object Pooling to prevent churning
ObjectPool = {
    Highlights = {},
    Billboards = {}
}
MAX_POOL_SIZE = 50 -- Prevent unbounded pool growth
ActiveHighlightCount = 0 -- Performance: Keep track of count instead of iterating

function GetPooledObject(poolName, className)
    local pool = ObjectPool[poolName]
    while #pool > 0 do
        local obj = table.remove(pool)
        -- PERFORMANCE FIX: O(1) validity check using PoolFolder
        if obj and obj.Parent == PoolFolder then
            obj.Parent = nil
            return obj
        end
    end
    return Instance.new(className)
end

function _resetPooledObject(obj)
    obj.Adornee = nil
    pcall(function() obj.Enabled = false end)
    obj.Parent = PoolFolder
end

function ReturnPooledObject(obj)
    if not obj then return end
    
    -- PERFORMANCE FIX: O(1) check with argument-passing pcall to avoid closures
    local success = pcall(_resetPooledObject, obj)
    
    if not success then return end
    
    if obj:IsA("Highlight") then
        if #ObjectPool.Highlights < MAX_POOL_SIZE then
            table.insert(ObjectPool.Highlights, obj)
        else
            obj:Destroy()
        end
    elseif obj:IsA("BillboardGui") then
        if #ObjectPool.Billboards < MAX_POOL_SIZE then
            table.insert(ObjectPool.Billboards, obj)
        else
            obj:Destroy()
        end
    else
        obj:Destroy()
    end
end
-- Helper to create/update Dot Indicator
function UpdateDot(player, character, storage, dotType, partName)
    local part = character:FindFirstChild(partName)
    if not part then
        if storage[dotType] then
            ReturnPooledObject(storage[dotType])
            storage[dotType] = nil
        end
        return
    end

    local dot = storage[dotType]
    if not dot then
        -- Create BillboardGui
        dot = GetPooledObject("Billboards", "BillboardGui")
        dot.Name = dotType
        dot.AlwaysOnTop = true
        dot.Size = UDim2.fromOffset(6, 6)
        dot.StudsOffset = Vector3.new(0, 0, 0)
        dot.Adornee = part
        dot.Enabled = true
        dot.Parent = character
        
        -- Check if we need to recreate the child frame (it might be gone if we pooled a destroyed gui)
        local dotFrame = dot:FindFirstChild("Dot")
        if not dotFrame then
            dotFrame = Instance.new("Frame")
            dotFrame.Name = "Dot"
            dotFrame.Size = UDim2.new(1, 0, 1, 0)
            dotFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green by default
            dotFrame.BorderSizePixel = 0
            dotFrame.Parent = dot
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = dotFrame
        end

        storage[dotType] = dot
    else
        -- PERFORMANCE FIX: Assume valid if matched in storage, or basic check
        if not dot.Parent and dot ~= storage[dotType] then
            storage[dotType] = nil
            return UpdateDot(player, character, storage, dotType, partName)
        end
        
        -- Update adornee and parent
        if dot.Adornee ~= part then
            dot.Adornee = part
        end
        if dot.Parent ~= character then
            dot.Parent = character
        end
        if not dot.Enabled then
            dot.Enabled = true
        end
        
        -- FIX: Ensure the dot frame child still exists
        local dotFrame = dot:FindFirstChild("Dot")
        if not dotFrame then
            dotFrame = Instance.new("Frame")
            dotFrame.Name = "Dot"
            dotFrame.Size = UDim2.new(1, 0, 1, 0)
            dotFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            dotFrame.BorderSizePixel = 0
            dotFrame.Parent = dot
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = dotFrame
        end
    end

    -- Update Color based on Locked Status
    local dotFrame = dot:FindFirstChild("Dot")
    if dotFrame then
            local dotColor = Color3.fromRGB(0, 255, 0) -- Default Green
            
            -- Check if this specific part is being locked onto
            if CachedTarget and (os.clock() - CachedTargetTime) < 0.1 and CachedTarget[1] == player then
                local lockedPart = CachedTarget[3]
                if lockedPart and lockedPart.Name == partName then
                    dotColor = Color3.fromRGB(255, 0, 0) -- Red when locked
                end
            end

            if dotFrame.BackgroundColor3 ~= dotColor then
                dotFrame.BackgroundColor3 = dotColor
            end
    end
end

function UpdatePlayerOutlines(player, character)
    if not character then return end
    
    -- Initialize outline storage for this player if needed
    if not PlayerOutlineObjects[player] then
        PlayerOutlineObjects[player] = {}
    end
    
    local storage = PlayerOutlineObjects[player]
    
    -- Cleanup legacy/previous outlines (SelectionBoxes/BoxHandleAdornments)
    for k, v in pairs(storage) do
        if k ~= "Highlight" and k ~= "HeadDot" and k ~= "RootDot" then
            if v then v:Destroy() end
            storage[k] = nil
        end
    end
    
    -- Create single Highlight for the character
    if not storage.Highlight then
        -- Count current highlights to respect cap
        if ActiveHighlightCount >= MAX_OUTLINE_HIGHLIGHTS then
            -- Find the furthest player with a highlight and steal it
            local furthest = nil
            local maxDist = -1
            local myPos = Camera.CFrame.Position
            
            for p, obj in pairs(PlayerOutlineObjects) do
                if obj.Highlight then
                    local _, root = GetCharacter(p)
                    if root then
                        local d = (root.Position - myPos).Magnitude
                        if d > maxDist then
                            maxDist = d
                            furthest = p
                        end
                    else
                        -- Orphaned highlighting, just take it
                        furthest = p
                        break
                    end
                end
            end
            
            if furthest and PlayerOutlineObjects[furthest] then
                storage.Highlight = PlayerOutlineObjects[furthest].Highlight
                PlayerOutlineObjects[furthest].Highlight = nil
                storage.Highlight.Adornee = character
                storage.Highlight.Parent = character
                -- Count remains same as we stole one
            end
        end

        if not storage.Highlight then
            local highlight = GetPooledObject("Highlights", "Highlight")
            highlight.Name = "PlayerOutlineHighlight"
            highlight.Adornee = character
            highlight.FillColor = COLORS.OUTLINE
            highlight.FillTransparency = 1 -- Invisible fill (Wireframe only)
            highlight.OutlineColor = COLORS.OUTLINE
            highlight.OutlineTransparency = 0 -- Fully visible outline
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Visible through walls
            highlight.Enabled = true
            highlight.Parent = character
            
            storage.Highlight = highlight
            ActiveHighlightCount = ActiveHighlightCount + 1
        end
    else
        local highlight = storage.Highlight
        -- PERFORMANCE FIX: Check Parent instead of pcall for validity
        if not highlight.Parent and highlight ~= storage.Highlight then -- unlikely but safe
             storage.Highlight = nil
             return UpdatePlayerOutlines(player, character)
        end
        
        -- Update properties
        if highlight.Adornee ~= character then
            highlight.Adornee = character
        end
        if highlight.Parent ~= character then
            highlight.Parent = character
        end
        if highlight.OutlineColor ~= COLORS.OUTLINE then
            highlight.OutlineColor = COLORS.OUTLINE
        end
        if not highlight.Enabled then
            highlight.Enabled = true
        end
    end

    -- Update Head and Root dots
    UpdateDot(player, character, storage, "HeadDot", "Head")
    UpdateDot(player, character, storage, "RootDot", "HumanoidRootPart")
end

-- Remove all outlines for a player (Optimized: Return to pool)
function RemovePlayerOutlines(player)
    local storage = PlayerOutlineObjects[player]
    if not storage then return end
    
    -- Cleanup Highlight
    if storage.Highlight then
        ReturnPooledObject(storage.Highlight)
        storage.Highlight = nil
        ActiveHighlightCount = math.max(0, ActiveHighlightCount - 1)
    end
    
    -- Cleanup Billboard dots
    if storage.HeadDot then 
        ReturnPooledObject(storage.HeadDot) 
        storage.HeadDot = nil
    end
    if storage.RootDot then 
        ReturnPooledObject(storage.RootDot) 
        storage.RootDot = nil
    end
    
    -- Cleanup any legacy parts
    for k, v in pairs(storage) do
        if k ~= "Highlight" and k ~= "HeadDot" and k ~= "RootDot" then
            if v and v.Parent then v:Destroy() end
        end
    end
    
    PlayerOutlineObjects[player] = nil
end

-- Update ESP for a player (optimized - uses cached closest player)
function UpdateESP(now, player, isClosest)
    local espData = ESPObjects[player]
    if not Flags["ESP/Enabled"] or Flags["Settings/GhostMode"] then
        if espData then
            if espData.Nametag then espData.Nametag.Enabled = false end
            if espData.Tracer then espData.Tracer.Visible = false end
            if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
                espData.OffscreenIndicator.Frame.Visible = false
            end
        end
        return
    end
    
    -- Check if ESP data exists and if the Nametag is still valid (not destroyed)
    if espData then
        -- Check if nametag is valid
        local nametag = espData.Nametag
        local isValid = nametag and nametag.Parent ~= nil
        
        if isValid and (not espData.NicknameLabel or not espData.NicknameLabel.Parent) then
            isValid = false
        end
        
        if not isValid then
            -- Recreate if missing
             if nametag then nametag:Destroy() end
             if espData.Tracer then espData.Tracer:Destroy() end 
             
             -- Fix: Explicitly destroy OffscreenIndicator to prevent memory leak
             if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
                 espData.OffscreenIndicator.Frame:Destroy()
             end
             
             -- Properly cleanup old connections before setting to nil
             if espData.Connections then
                 for _, conn in pairs(espData.Connections) do
                     if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                         conn:Disconnect()
                     end
                 end
                 table.clear(espData.Connections)
             end

             ESPObjects[player] = nil
             espData = nil
             
             -- Recreate immediately via SetupPlayerESP to ensure CharacterAdded is re-established
             SetupPlayerESP(player)
             espData = ESPObjects[player]
        else
            -- Ensure correctly parented if still valid
            local targetGui = EnsureScreenGui()
            if nametag.Parent ~= targetGui then
                nametag.Parent = targetGui
            end
            if espData.Tracer and espData.Tracer.Parent ~= targetGui then
                espData.Tracer.Parent = targetGui
            end
            if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame and espData.OffscreenIndicator.Frame.Parent ~= targetGui then
                espData.OffscreenIndicator.Frame.Parent = targetGui
            end
        end
    end
    
    -- Create ESP if it doesn't exist
    if not espData then
        CreateESP(player)
        espData = ESPObjects[player]
    end
    if not espData then return end

    -- Get character
    local character, rootPart = GetCharacter(player)
    if not character or not rootPart then
        RemovePlayerOutlines(player) 
        -- Hide ESP elements
        if espData.Nametag then espData.Nametag.Enabled = false end
        if espData.Tracer then espData.Tracer.Visible = false end
        if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
            espData.OffscreenIndicator.Frame.Visible = false
        end
        return
    end

    -- Calculate distance
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude

    -- Distance culling REMOVED: All nametags visible at any distance

    -- Update nametag
    if Flags["ESP/Nametags"] and espData.Nametag then
        local nametag = espData.Nametag
        -- Ensure nametag is attached and enabled
        if nametag.Adornee ~= rootPart then
            nametag.Adornee = rootPart
        end
        if not nametag.Enabled then
            nametag.Enabled = true
        end

        -- Get team color for name labels
        local teamColor = GetTeamColor(player)
        
        -- Get display name and username
        local nickname = player.DisplayName or player.Name
        local username = "@" .. player.Name
        local distRounded = floor(distance)
        
        -- PERFORMANCE: Only update text/color if values changed
        if espData.lastNickname ~= nickname then
            espData.NicknameLabel.Text = nickname
            espData.lastNickname = nickname
        end
        
        if espData.lastUsername ~= username then
            espData.UsernameLabel.Text = username
            espData.lastUsername = username
        end
        
        if espData.lastTeamColor ~= teamColor then
            espData.NicknameLabel.TextColor3 = teamColor
            -- Username color is now handled by distance logic
            espData.lastTeamColor = teamColor
        end

        -- Update Distance
        if math.abs(espData.lastDistance - distRounded) > 5 then
            espData.DistanceLabel.Text = string.format("%d studs", distRounded)
            espData.lastDistance = distRounded
        end
        
        local distanceColor = GetDistanceColor(distance, isClosest)
        if espData.lastDistanceColor ~= distanceColor then
            espData.DistanceLabel.TextColor3 = distanceColor
            espData.UsernameLabel.TextColor3 = distanceColor
            espData.lastDistanceColor = distanceColor
        end

        -- Update Health indicators visibility based on line-of-sight
        local isOccluded = ObjectOccluded(true, Camera.CFrame.Position, rootPart.Position, character)
        local healthVisible = not isOccluded
        
        if espData.HealthBarContainer and espData.HealthBarContainer.Visible ~= healthVisible then
            espData.HealthBarContainer.Visible = healthVisible
        end

        -- Update Health visuals
        local health, maxHealth = GetHealth(player)
        if espData.lastHealth ~= health or espData.lastMaxHealth ~= maxHealth then
            espData.HealthNumericalLabel.Text = string.format("%d/%d", math.floor(health), math.floor(maxHealth))
            
            local healthPercent = math.clamp(health / maxHealth, 0, 1)
            espData.HealthBarFill.Size = UDim2.fromScale(healthPercent, 1)
            
            -- Optional: adjust color based on health? Requirements say green fill, red BG.
            -- Requirement also says "turns red to indicate any lost health"
            -- The BG is red, fill is green. So if health is 50%, 50% green is shown over red.
            
            espData.lastHealth = health
            espData.lastMaxHealth = maxHealth
        end
    elseif espData.Nametag then
        if espData.Nametag.Enabled then espData.Nametag.Enabled = false end
    end

    -- Update tracer (LOD: skip for distant players to save performance)
    if espData.Tracer and Flags["ESP/Tracers"] and distance <= 2000 then
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if onScreen then
            local tracerLine = espData.Tracer
            local viewportSize = Camera.ViewportSize
            
            local originX = viewportSize.X / 2
            local originY = viewportSize.Y
            local targetX = screenPos.X
            local targetY = screenPos.Y
            
            local diffX = targetX - originX
            local diffY = targetY - originY
            local length = floor(sqrt(diffX*diffX + diffY*diffY) + 0.5)
            local rotation = floor(deg(atan2(diffY, diffX)) + 0.5)
            local midX = floor((originX + targetX) / 2 + 0.5)
            local midY = floor((originY + targetY) / 2 + 0.5)
            
            tracerLine.Visible = true
            
            -- MEMORY FIX: Only update if values changed to avoid UDim2 allocations
            local lastTracerLength = espData.lastTracerLength or 0
            local lastTracerMidX = espData.lastTracerMidX or 0
            local lastTracerMidY = espData.lastTracerMidY or 0
            local lastTracerRot = espData.lastTracerRot or 0
            
            if abs(length - lastTracerLength) > 3 then
                tracerLine.Size = UDim2.fromOffset(length, 1)
                espData.lastTracerLength = length
            end
            if abs(midX - lastTracerMidX) > 3 or abs(midY - lastTracerMidY) > 3 then
                tracerLine.Position = UDim2.fromOffset(midX, midY)
                espData.lastTracerMidX = midX
                espData.lastTracerMidY = midY
            end
            if abs(rotation - lastTracerRot) > 1 then
                tracerLine.Rotation = rotation
                espData.lastTracerRot = rotation
            end
        else
            espData.Tracer.Visible = false
        end
    elseif espData.Tracer then
        espData.Tracer.Visible = false
    end

    -- Update off-screen indicator
    if Flags["ESP/Nametags"] and Flags["ESP/OffscreenIndicators"] and espData.OffscreenIndicator then
        local indicator = espData.OffscreenIndicator
        -- MEMORY FIX: GetEdgePosition now returns raw numbers instead of Vector2
        local edgeX, edgeY, angle, isOnScreen = GetEdgePosition(now, rootPart.Position)
        
        -- Logic Fix: WorldToViewportPoint/GetEdgePosition and/or ternary bug prevention
        if edgeX == nil and isOnScreen == nil then
            -- Failed to get position (likely camera not ready)
            return
        end

        if isOnScreen then
            if espData.lastOffscreenVisible then
                indicator.Frame.Visible = false
                espData.lastOffscreenVisible = false
            end
        elseif edgeX then
            if not espData.lastOffscreenVisible then
                indicator.Frame.Visible = true
                espData.lastOffscreenVisible = true
            end
            
            -- Only update pos if moved > 5px for perf
            local newX = floor(edgeX - 60)
            local newY = floor(edgeY - 25)
            local lastX = espData.lastOffscreenX or 0
            local lastY = espData.lastOffscreenY or 0
            
            if abs(newX - lastX) > 5 or abs(newY - lastY) > 5 then
                indicator.Frame.Position = UDim2.fromOffset(newX, newY)
                espData.lastOffscreenX = newX
                espData.lastOffscreenY = newY
            end
            
            if angle then
                local newRotation = floor(deg(angle) - 90)
                if espData.lastOffscreenAngle ~= newRotation then
                    indicator.Arrow.Rotation = newRotation
                    espData.lastOffscreenAngle = newRotation
                end
            end
            
            local nickname = espData.lastNickname or (player.DisplayName or player.Name)
            if espData.lastOffscreenName ~= nickname then
                indicator.NameLabel.Text = nickname
                espData.lastOffscreenName = nickname
            end
            
            local distRounded = floor(distance)
            if abs((espData.lastOffscreenDist or 0) - distRounded) > 5 then
                indicator.DistLabel.Text = distRounded .. " studs"
                espData.lastOffscreenDist = distRounded
            end
            
            local distanceColor = espData.lastDistanceColor or GetDistanceColor(distance, isClosest)
            if espData.lastOffscreenColor ~= distanceColor then
                indicator.DistLabel.TextColor3 = distanceColor
                indicator.Stroke.Color = distanceColor
                indicator.Arrow.ImageColor3 = distanceColor
                espData.lastOffscreenColor = distanceColor
            end
            
            if espData.Nametag and espData.Nametag.Enabled then
                espData.Nametag.Enabled = false
            end
        else
            if espData.lastOffscreenVisible then
                indicator.Frame.Visible = false
                espData.lastOffscreenVisible = false
            end
        end
    elseif espData.OffscreenIndicator and espData.lastOffscreenVisible then
        espData.OffscreenIndicator.Frame.Visible = false
        espData.lastOffscreenVisible = false
    end
    
    if Flags["ESP/PlayerOutlines"] then
        UpdatePlayerOutlines(player, character)
    else
        RemovePlayerOutlines(player)
    end
end



-- Remove ESP for a player
function RemoveESP(player)
    -- Also remove player outlines
    RemovePlayerOutlines(player)
    
    local espData = ESPObjects[player]
    if not espData then return end

    if espData.Nametag then
        espData.Nametag:Destroy()
    end
    if espData.Tracer then
        espData.Tracer:Destroy()
    end
    -- Clean up off-screen indicator
    if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
        espData.OffscreenIndicator.Frame:Destroy()
    end

    -- Clean up player-specific connections
    if espData.Connections then
        for _, conn in pairs(espData.Connections) do
            if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                conn:Disconnect()
            end
        end
        table.clear(espData.Connections)
    end
    
    espData.Nametag = nil
    espData.Tracer = nil
    if espData.OffscreenIndicator then
        espData.OffscreenIndicator.Frame = nil
        espData.OffscreenIndicator.Arrow = nil
        espData.OffscreenIndicator.NameLabel = nil
        espData.OffscreenIndicator.DistLabel = nil
        espData.OffscreenIndicator.Stroke = nil
    end
    espData.OffscreenIndicator = nil
    espData.Connections = nil

    ESPObjects[player] = nil
end

-- D3V TOOL DISPLAY

local D3vToolHUD = nil
local D3vToolLabel = nil

function CreateD3vToolHUD(parent)
    D3vToolHUD = Instance.new("Frame")
    D3vToolHUD.Name = "D3vToolHUD"
    D3vToolHUD.Position = UDim2.new(1, -450, 0, 3) -- Top right
    D3vToolHUD.AnchorPoint = Vector2.new(0, 0)
    D3vToolHUD.BackgroundTransparency = 1
    D3vToolHUD.AutomaticSize = Enum.AutomaticSize.XY
    D3vToolHUD.Parent = parent

    D3vToolLabel = Instance.new("TextLabel")
    D3vToolLabel.Name = "D3vToolLabel"
    D3vToolLabel.Text = ""
    D3vToolLabel.BackgroundTransparency = 1
    D3vToolLabel.Font = Enum.Font.GothamBold
    D3vToolLabel.TextSize = 15
    D3vToolLabel.TextColor3 = Color3.new(1, 1, 1)
    D3vToolLabel.TextXAlignment = Enum.TextXAlignment.Left
    D3vToolLabel.AutomaticSize = Enum.AutomaticSize.XY
    D3vToolLabel.Parent = D3vToolHUD
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Parent = D3vToolLabel
end

function UpdateD3vTool()
    if not D3vToolHUD then return end
    
    local visible = Flags["Misc/D3vTool"] and not Flags["Settings/GhostMode"]
    if D3vToolHUD.Visible ~= visible then
        D3vToolHUD.Visible = visible
    end
    
    if not visible then return end
    
    -- Clock
    local clockTime = Lighting.ClockTime
    local hours = math.floor(clockTime)
    local minutes = math.floor((clockTime - hours) * 60)
    local period = hours >= 12 and "PM" or "AM"
    local hours12 = hours % 12
    if hours12 == 0 then hours12 = 12 end
    local timeStr = string.format("%d:%02d %s", hours12, minutes, period)
    
    -- LPC (Local Player Coordinates)
    local lpcStr = "N/A"
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if root then
        local pos = root.Position
        lpcStr = string.format("%d,%d,%d", floor(pos.X), floor(pos.Y), floor(pos.Z))
    end
    
    -- LMC (Local Mouse Coordinates)
    local mouseLoc = UserInputService:GetMouseLocation()
    local lmcStr = string.format("%d,%d", floor(mouseLoc.X), floor(mouseLoc.Y))
    
    local newText = string.format("WorldTime[%s] Humanoid[%s] Mouse[%s]", timeStr, lpcStr, lmcStr)
    if D3vToolLabel.Text ~= newText then
        D3vToolLabel.Text = newText
    end
end

-- PERFORMANCE DISPLAY

PerformanceLabel = nil
PerfMinimized = false
PerfOriginalSize = UDim2.fromOffset(180, 145)

PerformanceRows = {}

function CreatePerformanceDisplay(parent)
    PerformanceLabel = Instance.new("Frame")
    PerformanceLabel.Name = "PerformanceDisplay"
    PerformanceLabel.Size = UDim2.fromScale(0.1, 0.14)
    PerformanceLabel.Position = UDim2.new(1, -240, 0, 100) -- Next to player list
    PerformanceLabel.AnchorPoint = Vector2.new(1, 0)
    
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(160, 140)
    sizeConstraint.MaxSize = Vector2.new(220, 180)
    sizeConstraint.Parent = PerformanceLabel

    PerformanceLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    PerformanceLabel.BackgroundTransparency = 0
    PerformanceLabel.BorderSizePixel = 0
    PerformanceLabel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = PerformanceLabel

    local stroke = Instance.new("UIStroke")
    stroke.Color = UI_THEME.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = PerformanceLabel

    -- Header Title
    local headerTitle = Instance.new("TextLabel")
    headerTitle.Name = "HeaderTitle"
    headerTitle.Size = UDim2.new(1, -30, 0, 24)
    headerTitle.Position = UDim2.fromOffset(8, 2)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text = "Performance"
    headerTitle.Font = Enum.Font.GothamBold
    headerTitle.TextSize = 12
    headerTitle.TextColor3 = UI_THEME.Accent
    headerTitle.TextXAlignment = Enum.TextXAlignment.Left
    headerTitle.Parent = PerformanceLabel

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, -16, 1, -36)
    container.Position = UDim2.fromOffset(8, 28)
    container.BackgroundTransparency = 1
    container.Parent = PerformanceLabel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = container

    local function CreateRow(name, initialValue)
        local row = Instance.new("Frame")
        row.Name = name .. "Row"
        row.Size = UDim2.new(1, 0, 0, 14)
        row.BackgroundTransparency = 1
        row.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = name .. ":"
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 11
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        local value = Instance.new("TextLabel")
        value.Size = UDim2.new(0.6, 0, 1, 0)
        value.Position = UDim2.new(0.4, 0, 0, 0)
        value.BackgroundTransparency = 1
        value.Text = initialValue
        value.Font = Enum.Font.GothamBold
        value.TextSize = 11
        value.TextColor3 = Color3.fromRGB(255, 255, 255)
        value.TextXAlignment = Enum.TextXAlignment.Right
        value.Parent = row

        PerformanceRows[name] = value
    end

    CreateRow("FPS", "0")
    CreateRow("Ping", "0 ms")
    CreateRow("Memory", "0 MB")
    CreateRow("Players", "0")
    CreateRow("Aimbot", "OFF")
    CreateRow("Br0k3n Objects", "0")
    CreateRow("H1ghL1ghted Objects", "0")

    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minimizeBtn.BackgroundTransparency = 0.5
    minimizeBtn.Size = UDim2.fromOffset(18, 18)
    minimizeBtn.Position = UDim2.new(1, -22, 0, 4)
    minimizeBtn.Text = "−"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14
    minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.ZIndex = 10
    minimizeBtn.Parent = PerformanceLabel

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 4)
    mCorner.Parent = minimizeBtn

    TrackConnection(minimizeBtn.MouseButton1Click:Connect(function()
        PerfMinimized = not PerfMinimized
        if PerfMinimized then
            PerformanceLabel.Size = UDim2.fromOffset(180, 28)
            container.Visible = false
            headerTitle.Text = "Performance Stats"
            minimizeBtn.Text = "+"
        else
            PerformanceLabel.Size = PerfOriginalSize
            container.Visible = true
            headerTitle.Text = "Performance"
            minimizeBtn.Text = "−"
        end
    end))

    if UI.MakeDraggable then
        UI.MakeDraggable(PerformanceLabel)
    end
end

local LocalHealthHUD = nil
local LocalHealthValueLabel = nil

function CreateLocalHealthHUD(parent)
    LocalHealthHUD = Instance.new("Frame")
    LocalHealthHUD.Name = "LocalHealthHUD"
    LocalHealthHUD.Size = UDim2.fromScale(0.08, 0.05)
    LocalHealthHUD.Position = UDim2.new(1, -260, 0, 70) -- Right Side, above Performance
    LocalHealthHUD.AnchorPoint = Vector2.new(1, 0)
    
    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(110, 30)
    sizeConstraint.MaxSize = Vector2.new(160, 30)
    sizeConstraint.Parent = LocalHealthHUD

    LocalHealthHUD.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    LocalHealthHUD.BackgroundTransparency = 0.2
    LocalHealthHUD.BorderSizePixel = 0
    LocalHealthHUD.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = LocalHealthHUD

    local stroke = Instance.new("UIStroke")
    stroke.Color = UI_THEME.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = LocalHealthHUD

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "100/100"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Parent = LocalHealthHUD
    LocalHealthValueLabel = label

    if UI.MakeDraggable then
        UI.MakeDraggable(LocalHealthHUD)
    end
end

local lastLocalH, lastLocalMH = -1, -1
function UpdateLocalHealthHUD()
    if not LocalHealthValueLabel then return end
    
    local h, mh = GetHealth(LocalPlayer)
    if h ~= lastLocalH or mh ~= lastLocalMH then
        LocalHealthValueLabel.Text = string.format("%d/%d", math.floor(h), math.floor(mh))
        lastLocalH, lastLocalMH = h, mh
    end
end

function UpdatePerformanceDisplay()
    if not Flags["Performance/Enabled"] or not PerformanceLabel or PerfMinimized then return end

    -- Only update if visible (performance optimization)
    if not PerformanceLabel.Visible then return end

    local fps = floor(GetFPS())
    local ping = floor(GetPing())
    local playerCount = #GetPlayersCache()
    local memoryUsed = floor(Stats:GetTotalMemoryUsageMb())
    local activeTargets = max(0, playerCount - 1)

    -- FPS color coding
    local fpsColor = Color3.fromRGB(50, 255, 50) -- Green
    if fps < 30 then
        fpsColor = Color3.fromRGB(255, 50, 50) -- Red
    elseif fps < 60 then
        fpsColor = Color3.fromRGB(255, 200, 50) -- Yellow
    end

    -- Ping color coding
    local pingColor = Color3.fromRGB(50, 255, 50) -- Green
    if ping > 200 then
        pingColor = Color3.fromRGB(255, 50, 50) -- Red
    elseif ping > 100 then
        pingColor = Color3.fromRGB(255, 200, 50) -- Yellow
    end

    -- Update Rows
    if PerformanceRows.FPS then
        local val = tostring(fps)
        if PerformanceRows.FPS.Text ~= val then PerformanceRows.FPS.Text = val end
        if PerformanceRows.FPS.TextColor3 ~= fpsColor then PerformanceRows.FPS.TextColor3 = fpsColor end
    end
    if PerformanceRows.Ping then
        local val = ping .. " ms"
        if PerformanceRows.Ping.Text ~= val then PerformanceRows.Ping.Text = val end
        if PerformanceRows.Ping.TextColor3 ~= pingColor then PerformanceRows.Ping.TextColor3 = pingColor end
    end
    if PerformanceRows.Memory then
        local val = memoryUsed .. " MB"
        if PerformanceRows.Memory.Text ~= val then PerformanceRows.Memory.Text = val end
    end
    if PerformanceRows.Players then
        local val = tostring(playerCount)
        if PerformanceRows.Players.Text ~= val then PerformanceRows.Players.Text = val end
    end
    if PerformanceRows.Aimbot then
        local aimbotActive = Flags["Aimbot/AimLock"] and (Flags["Aimbot/AlwaysEnabled"] or AimState.Aimbot)
        local val = aimbotActive and "LOCKED 🔒" or "IDLE ─"
        local col = aimbotActive and UI_THEME.Accent or Color3.fromRGB(150, 150, 150)
        if PerformanceRows.Aimbot.Text ~= val then PerformanceRows.Aimbot.Text = val end
        if PerformanceRows.Aimbot.TextColor3 ~= col then PerformanceRows.Aimbot.TextColor3 = col end
    end
    if PerformanceRows["Br0k3n Objects"] then
        local brokenCount = 0
        for _ in pairs(Br3ak3rState.brokenSet) do brokenCount = brokenCount + 1 end
        local val = tostring(brokenCount)
        if PerformanceRows["Br0k3n Objects"].Text ~= val then PerformanceRows["Br0k3n Objects"].Text = val end
    end
    if PerformanceRows["H1ghL1ghted Objects"] then
        local highlightedCount = 0
        for _ in pairs(H1ghl1ght3rState.highlightedSet) do highlightedCount = highlightedCount + 1 end
        local val = tostring(highlightedCount)
        if PerformanceRows["H1ghL1ghted Objects"].Text ~= val then PerformanceRows["H1ghL1ghted Objects"].Text = val end
    end
end

------------------------------------------------------------------------
-- FREECAM INTEGRATION
------------------------------------------------------------------------
local function ___InitializeFreecam()
-----------------------------------------------------------------------
-- Freecam
-- Cinematic free camera for spectating and video production.
------------------------------------------------------------------------

local pi    = math.pi
local abs   = math.abs
local clamp = math.clamp
local exp   = math.exp
local rad   = math.rad
local sign  = math.sign
local sqrt  = math.sqrt
local tan   = math.tan

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
LocalPlayer = Players.LocalPlayer
end

local Camera = workspace.CurrentCamera
TrackConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
local newCamera = workspace.CurrentCamera
if newCamera then
Camera = newCamera
end
end))

------------------------------------------------------------------------

local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local FREECAM_MACRO_KB = {Enum.KeyCode.LeftControl, Enum.KeyCode.P}

local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8
local FOV_GAIN = 300

local PITCH_LIMIT = rad(90)

local VEL_STIFFNESS = 1.5
local PAN_STIFFNESS = 1.0
local FOV_STIFFNESS = 4.0

------------------------------------------------------------------------

local Spring = {} do
Spring.__index = Spring

function Spring.new(freq, pos)
local self = setmetatable({}, Spring)
self.f = freq
self.p = pos
self.v = pos*0
return self
end

function Spring:Update(dt, goal)
local f = self.f*2*pi
local p0 = self.p
local v0 = self.v

local offset = goal - p0
local decay = exp(-f*dt)

local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
local v1 = (f*dt*(offset*f - v0) + v0)*decay

self.p = p1
self.v = v1

return p1
end

function Spring:Reset(pos)
self.p = pos
self.v = pos*0
end
end

------------------------------------------------------------------------

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 0

local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
local fovSpring = Spring.new(FOV_STIFFNESS, 0)

------------------------------------------------------------------------

local Input = {} do
local thumbstickCurve do
local K_CURVATURE = 2.0
local K_DEADZONE = 0.15

function fCurve(x)
return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
end

function fDeadzone(x)
return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
end

function thumbstickCurve(x)
return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
end
end

local gamepad = {
ButtonX = 0,
ButtonY = 0,
DPadDown = 0,
DPadUp = 0,
ButtonL2 = 0,
ButtonR2 = 0,
Thumbstick1 = Vector2.new(),
Thumbstick2 = Vector2.new(),
}

local keyboard = {
W = 0,
A = 0,
S = 0,
D = 0,
E = 0,
Q = 0,
U = 0,
H = 0,
J = 0,
K = 0,
I = 0,
Y = 0,
Up = 0,
Down = 0,
LeftShift = 0,
RightShift = 0,
}

local mouse = {
Delta = Vector2.new(),
MouseWheel = 0,
}

local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
local FOV_WHEEL_SPEED    = 1.0
local FOV_GAMEPAD_SPEED  = 0.25
local NAV_ADJ_SPEED      = 0.75
local NAV_SHIFT_MUL      = 0.25

local navSpeed = 1

function Input.Vel(dt)
navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

local kGamepad = Vector3.new(
thumbstickCurve(gamepad.Thumbstick1.x),
thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
thumbstickCurve(-gamepad.Thumbstick1.y)
)*NAV_GAMEPAD_SPEED

local kKeyboard = Vector3.new(
keyboard.D - keyboard.A + keyboard.K - keyboard.H,
keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
keyboard.S - keyboard.W + keyboard.J - keyboard.U
)*NAV_KEYBOARD_SPEED

local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
end

function Input.Pan(dt)
local kGamepad = Vector2.new(
thumbstickCurve(gamepad.Thumbstick2.y),
thumbstickCurve(-gamepad.Thumbstick2.x)
)*PAN_GAMEPAD_SPEED
local kMouse = mouse.Delta*PAN_MOUSE_SPEED
mouse.Delta = Vector2.new()
return kGamepad + kMouse
end

function Input.Fov(dt)
local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
mouse.MouseWheel = 0
return kGamepad + kMouse
end

do
function Keypress(action, state, input)
keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
return Enum.ContextActionResult.Sink
end

function GpButton(action, state, input)
gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
return Enum.ContextActionResult.Sink
end

function MousePan(action, state, input)
local delta = input.Delta
mouse.Delta = Vector2.new(-delta.y, -delta.x)
return Enum.ContextActionResult.Sink
end

function Thumb(action, state, input)
gamepad[input.KeyCode.Name] = input.Position
return Enum.ContextActionResult.Sink
end

function Trigger(action, state, input)
gamepad[input.KeyCode.Name] = input.Position.z
return Enum.ContextActionResult.Sink
end

function MouseWheel(action, state, input)
mouse[input.UserInputType.Name] = -input.Position.z
return Enum.ContextActionResult.Sink
end

function Zero(t)
for k, v in pairs(t) do
t[k] = v*0
end
end

function Input.StartCapture()
ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
Enum.KeyCode.W, Enum.KeyCode.U,
Enum.KeyCode.A, Enum.KeyCode.H,
Enum.KeyCode.S, Enum.KeyCode.J,
Enum.KeyCode.D, Enum.KeyCode.K,
Enum.KeyCode.E, Enum.KeyCode.I,
Enum.KeyCode.Q, Enum.KeyCode.Y,
Enum.KeyCode.Up, Enum.KeyCode.Down
)
ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
end

function Input.StopCapture()
navSpeed = 1
Zero(gamepad)
Zero(keyboard)
Zero(mouse)
ContextActionService:UnbindAction("FreecamKeyboard")
ContextActionService:UnbindAction("FreecamMousePan")
ContextActionService:UnbindAction("FreecamMouseWheel")
ContextActionService:UnbindAction("FreecamGamepadButton")
ContextActionService:UnbindAction("FreecamGamepadTrigger")
ContextActionService:UnbindAction("FreecamGamepadThumbstick")
end
end
end

function GetFocusDistance(cameraFrame)
local znear = 0.1
local viewport = Camera.ViewportSize
local projy = 2*tan(cameraFov/2)
local projx = viewport.x/viewport.y*projy
local fx = cameraFrame.rightVector
local fy = cameraFrame.upVector
local fz = cameraFrame.lookVector

local minVect = Vector3.new()
local minDist = 512

for x = 0, 1, 0.5 do
for y = 0, 1, 0.5 do
local cx = (x - 0.5)*projx
local cy = (y - 0.5)*projy
local offset = fx*cx - fy*cy + fz
local origin = cameraFrame.p + offset*znear
local part, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
local dist = (hit - origin).magnitude
if minDist > dist then
minDist = dist
minVect = offset.unit
end
end
end

return fz:Dot(minVect)*minDist
end

------------------------------------------------------------------------

function StepFreecam(dt)
local vel = velSpring:Update(dt, Input.Vel(dt))
local pan = panSpring:Update(dt, Input.Pan(dt))
local fov = fovSpring:Update(dt, Input.Fov(dt))

local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))

cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))

local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
cameraPos = cameraCFrame.p

Camera.CFrame = cameraCFrame
Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
Camera.FieldOfView = cameraFov
end

------------------------------------------------------------------------

local PlayerState = {} do
local mouseIconEnabled
local cameraSubject
local cameraType
local cameraFocus
local cameraCFrame
local cameraFieldOfView
local screenGuis = {}
local coreGuis = {
Backpack = true,
Chat = true,
Health = true,
PlayerList = true,
}
local setCores = {
BadgesNotificationsActive = true,
PointsNotificationsActive = true,
}

-- Save state and set up for freecam
function PlayerState.Push()
for name in pairs(coreGuis) do
coreGuis[name] = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
end
for name in pairs(setCores) do
setCores[name] = StarterGui:GetCore(name)
StarterGui:SetCore(name, false)
end
local playergui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
if playergui then
for _, gui in pairs(playergui:GetChildren()) do
if gui:IsA("ScreenGui") and gui.Enabled then
screenGuis[#screenGuis + 1] = gui
gui.Enabled = false
end
end
end

cameraFieldOfView = Camera.FieldOfView
Camera.FieldOfView = 70

cameraType = Camera.CameraType
Camera.CameraType = Enum.CameraType.Custom

cameraSubject = Camera.CameraSubject
Camera.CameraSubject = nil

cameraCFrame = Camera.CFrame
cameraFocus = Camera.Focus

mouseIconEnabled = UserInputService.MouseIconEnabled
UserInputService.MouseIconEnabled = false

mouseBehavior = UserInputService.MouseBehavior
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

-- Restore state
function PlayerState.Pop()
for name, isEnabled in pairs(coreGuis) do
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
end
for name, isEnabled in pairs(setCores) do
StarterGui:SetCore(name, isEnabled)
end
for _, gui in pairs(screenGuis) do
if gui.Parent then
gui.Enabled = true
end
end

Camera.FieldOfView = cameraFieldOfView
cameraFieldOfView = nil

Camera.CameraType = cameraType
cameraType = nil

Camera.CameraSubject = cameraSubject
cameraSubject = nil

Camera.CFrame = cameraCFrame
cameraCFrame = nil

Camera.Focus = cameraFocus
cameraFocus = nil

UserInputService.MouseIconEnabled = mouseIconEnabled
mouseIconEnabled = nil

UserInputService.MouseBehavior = mouseBehavior
mouseBehavior = nil
end
end

function StartFreecam()
local cameraCFrame = Camera.CFrame
cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
cameraPos = cameraCFrame.p
cameraFov = Camera.FieldOfView

velSpring:Reset(Vector3.new())
panSpring:Reset(Vector2.new())
fovSpring:Reset(0)

PlayerState.Push()
RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
Input.StartCapture()
end

function StopFreecam()
Input.StopCapture()
RunService:UnbindFromRenderStep("Freecam")
PlayerState.Pop()
end

------------------------------------------------------------------------

do
local enabled = false

function ToggleFreecam()
if enabled then
StopFreecam()
else
StartFreecam()
end
enabled = not enabled
end

_G.StopFreecamFunc = function()
    if enabled then
        StopFreecam()
        enabled = false
    end
end

function CheckMacro(macro)
for i = 1, #macro - 1 do
if not UserInputService:IsKeyDown(macro[i]) then
return
end
end
if Flags["Settings/Freecam Toggle"] then ToggleFreecam() end
end

function HandleActivationInput(action, state, input)
if state == Enum.UserInputState.Begin then
if input.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
CheckMacro(FREECAM_MACRO_KB)
end
end
return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority("FreecamToggle", HandleActivationInput, false, TOGGLE_INPUT_PRIORITY, FREECAM_MACRO_KB[#FREECAM_MACRO_KB])
end
end
___InitializeFreecam()

-- MAIN INITIALIZATION & CLEANUP

-- Cleanup Function (FIXED - properly clears global state for reload)
function Cleanup()
    if type(_G.StopFreecamFunc) == "function" then
        pcall(_G.StopFreecamFunc)
    end
    pcall(function()
        game:GetService("ContextActionService"):UnbindAction("FreecamToggle")
    end)

    Sp3arParvus.Active = false

    -- Disconnect all tracked connections
    for _, conn in pairs(Sp3arParvus.Connections) do
        pcall(function()
            if conn then conn:Disconnect() end
        end)
    end
    table.clear(Sp3arParvus.Connections)

    -- Cleanup Waypoint Connections
    for _, conn in ipairs(WaypointConnections) do
        pcall(function()
            if conn then conn:Disconnect() end
        end)
    end
    table.clear(WaypointConnections)

    -- Cancel all tracked threads
    for _, thread in pairs(Sp3arParvus.Threads) do
        pcall(function()
            if thread then task.cancel(thread) end
        end)
    end
    table.clear(Sp3arParvus.Threads)

    -- Cleanup UI
    if ScreenGui then 
        pcall(function() ScreenGui:Destroy() end)
        ScreenGui = nil
    end
    table.clear(UIState.Tabs)
    table.clear(UIState.DraggableFrames)
    table.clear(UIState.Updaters)
    UIState.MainFrame = nil
    UIState.ContentArea = nil
    UIState.TabContainer = nil
    
    -- Cleanup ESP objects
    for player, espData in pairs(ESPObjects) do
        pcall(function()
            if espData.Nametag then espData.Nametag:Destroy() end
            if espData.Tracer then espData.Tracer:Destroy() end
            if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
                espData.OffscreenIndicator.Frame:Destroy()
            end
            -- MEMORY LEAK FIX: Disconnect player-specific connections
            if espData.Connections then
                for _, conn in pairs(espData.Connections) do
                    if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                        conn:Disconnect()
                    end
                end
                table.clear(espData.Connections)
            end
        end)
    end
    table.clear(ESPObjects)
    
    -- Cleanup Player Outline objects
    for player, outlines in pairs(PlayerOutlineObjects) do
        for partName, obj in pairs(outlines) do
            pcall(function() obj:Destroy() end)
        end
    end
    table.clear(PlayerOutlineObjects)
    
    -- Cleanup Object Pool
    for _, pool in pairs(ObjectPool) do
        for _, obj in ipairs(pool) do
            pcall(function() obj:Destroy() end)
        end
        table.clear(pool)
    end
    if PoolFolder then
        pcall(function() PoolFolder:Destroy() end)
        PoolFolder = nil
    end

    -- Cleanup Waypoints
    for id, wpData in pairs(ActiveWaypoints) do
        pcall(function()
            if wpData.Billboard then wpData.Billboard:Destroy() end
            if wpData.Part then wpData.Part:Destroy() end
        end)
    end
    table.clear(ActiveWaypoints)

    -- Cleanup Br3ak3r (restore all broken parts)
    for path, data in pairs(Br3ak3rState.brokenSet) do
        pcall(function()
            local part = data.instance
            if not part or not part.Parent then
                part = GetInstanceFromPath(path)
            end
            if part and part.Parent and type(data) == "table" then
                part.CanCollide = data.cc
                part.LocalTransparencyModifier = data.ltm
                part.Transparency = data.t
            end
        end)
    end
    table.clear(Br3ak3rState.brokenSet)
    table.clear(Br3ak3rState.undoStack)
    table.clear(Br3ak3rState.brokenIgnoreCache)
    Br3ak3rState.brokenCacheDirty = true
    Br3ak3rState.CTRL_HELD = false
    Br3ak3rState.LEFT_CTRL_HELD = false

    -- Cleanup H1ghl1ght3r (remove all highlights and nametags, restore transparency)
    for part, data in pairs(H1ghl1ght3rState.highlightedSet) do
        pcall(function()
            if part.Parent and type(data) == "table" then
                part.LocalTransparencyModifier = data.ltm
                part.Transparency = data.t
            end
            if type(data) == "table" then
                if data.hl then data.hl:Destroy() end
                if data.bg then data.bg:Destroy() end
            end
        end)
    end
    table.clear(H1ghl1ght3rState.highlightedSet)
    table.clear(H1ghl1ght3rState.undoStack)
    H1ghl1ght3rState.SHIFT_HELD = false

    -- Cleanup WorldHumanoidEditor
    ClearWorldHumConnections()
    if WorldHumState.selectionHighlight then
        pcall(function() WorldHumState.selectionHighlight:Destroy() end)
    end
    table.clear(WorldHumState.lockedProperties)
    WorldHumState.selectedHum = nil
    WorldHumState.selectionHighlight = nil
    
    -- Cleanup hover highlight
    if Br3ak3rState.hoverHL then
        pcall(function() Br3ak3rState.hoverHL:Destroy() end)
        Br3ak3rState.hoverHL = nil
    end

    -- Restore Fullbright if active
    if FullbrightState.lastState then
        Flags["Visuals/Fullbright"] = false
        pcall(UpdateFullbright)
    end

    -- Restore Humanoid settings
    if HumanoidState.captured then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            for prop, value in pairs(HumanoidState.originalSettings) do
                pcall(function()
                    humanoid[prop] = value
                end)
            end
        end
        table.clear(HumanoidState.originalSettings)
        HumanoidState.captured = false
    end

    -- Reset module-level state
    AimState.Aimbot = false
    AimState.Trigger = false
    AimState.LastAimbotTarget = nil
    CachedTarget = nil
    NearestPlayerRef = nil
    PerformanceLabel = nil
    if D3vToolHUD then
        pcall(function() D3vToolHUD:Destroy() end)
    end
    D3vToolHUD = nil
    D3vToolLabel = nil
    ClosestPlayerTrackerLabel = nil
    LocalHealthHUD = nil
    LocalHealthValueLabel = nil
    PlayerPanelFrame = nil
    table.clear(PlayerPanelRows)
    
    -- MEMORY LEAK FIX: Clear all cache tables to release object references
    for p, c in pairs(CharCache) do
        c.Char = nil; c.HumanoidRootPart = nil; c.Root = nil; c.Humanoid = nil; c.HealthInst = nil; c.Squad = nil; c.Head = nil
    end
    table.clear(CharCache)
    
    for _, entry in ipairs(CandidateList) do
        entry.ply = nil; entry.char = nil; entry.part = nil; entry.pos = nil
    end
    table.clear(CandidateList)

    for _, entry in ipairs(cachedPlayerListForSort) do
        entry.player = nil; entry.position = nil
    end
    table.clear(cachedPlayerListForSort)
    
    table.clear(cachedSortedPlayers)
    table.clear(cachedPlayersList)
    table.clear(Br3ak3rState.brokenIgnoreCache)
    table.clear(Br3ak3rState.scratchIgnore)

    -- CRITICAL: Clear the global environment flag so script can be reloaded
    _G.StopFreecamFunc = nil
    local globalEnv = getgenv and getgenv() or _G
    rawset(globalEnv, "Sp3arParvusV2", nil)

    warn("[Sp3arParvus] Script Unloaded! You can now reload the script.")
end

-- Create Main Window
local Window = UI.CreateWindow("Sp3arParvusV2")

-- Initialize HUD Elements
CreateD3vToolHUD(ScreenGui)
CreatePerformanceDisplay(ScreenGui)
CreateLocalHealthHUD(ScreenGui)
CreateClosestPlayerTracker()

-- Create Tabs
local AimTab = UI.CreateTab("Aimbot")
local VisualsTab = UI.CreateTab("Visuals")
local HumanoidTab = UI.CreateTab("Humanoid")
WorldHumState.Page = UI.CreateTab("WorldHumanoids")
local MiscTab = UI.CreateTab("Misc")

function ShowWorldHumList(page)
    if not page then return end
    for _, child in ipairs(page:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    ClearWorldHumConnections()
    WorldHumState.selectedHum = nil
    table.clear(WorldHumState.listEntries)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local layout = page:FindFirstChildOfClass("UIListLayout")
    if not layout then
        layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page
    end
    
    UI.CreateSection(page, "Nearby Humanoids")
    
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(1, 0, 0, 30)
    refreshBtn.BackgroundColor3 = UI_THEME.Element
    refreshBtn.Text = "Refresh Scan"
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.TextSize = 13
    refreshBtn.TextColor3 = UI_THEME.Accent
    refreshBtn.Parent = page
    local rC = Instance.new("UICorner"); rC.CornerRadius = UDim.new(0, 6); rC.Parent = refreshBtn
    TrackWorldHumConnection(refreshBtn.MouseButton1Click:Connect(function()
        ShowWorldHumList(page)
    end))

    local humanoids = GetNearbyHumanoids()
    if #humanoids == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 30)
        lbl.BackgroundTransparency = 1
        lbl.Text = "No non-local humanoids found."
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 13
        lbl.TextColor3 = UI_THEME.TextDark
        lbl.Parent = page
        return
    end

    -- Sorting Logic
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
    local myPos = myRoot and myRoot.Position or Camera.CFrame.Position

    local humDataList = {}
    for _, hum in ipairs(humanoids) do
        local model = hum.Parent
        local root = hum.RootPart or (model and model.PrimaryPart)
        local dist = root and (root.Position - myPos).Magnitude or 999999
        table.insert(humDataList, {hum = hum, dist = dist})
    end

    table.sort(humDataList, function(a, b)
        return a.dist < b.dist
    end)
    
    for _, data in ipairs(humDataList) do
        local hum = data.hum
        local model = hum.Parent
        if not model then continue end
        
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 45)
        card.BackgroundColor3 = UI_THEME.Element
        card.BorderSizePixel = 0
        card.LayoutOrder = math.floor(data.dist)
        card.Parent = page
        local cC = Instance.new("UICorner"); cC.CornerRadius = UDim.new(0, 6); cC.Parent = card
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -100, 0, 22)
        nameLabel.Position = UDim2.new(0, 12, 0, 4)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = model.Name
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextSize = 14
        nameLabel.TextColor3 = UI_THEME.Text
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = card

        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Size = UDim2.new(1, -100, 0, 16)
        distanceLabel.Position = UDim2.new(0, 12, 0, 22)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.Text = math.floor(data.dist) .. " studs away"
        distanceLabel.Font = Enum.Font.Gotham
        distanceLabel.TextSize = 12
        distanceLabel.TextColor3 = UI_THEME.TextDark
        distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
        distanceLabel.Parent = card

        table.insert(WorldHumState.listEntries, {hum = hum, card = card, label = distanceLabel})
        
        local selectionBtn = Instance.new("TextButton")
        selectionBtn.Size = UDim2.new(1, 0, 1, 0)
        selectionBtn.BackgroundTransparency = 1
        selectionBtn.Text = ""
        selectionBtn.ZIndex = 1
        selectionBtn.Parent = card
        
        local editBtn = Instance.new("TextButton")
        editBtn.Name = "Edit"
        editBtn.Size = UDim2.new(0, 60, 0, 26)
        editBtn.Position = UDim2.new(1, -10, 0.5, 0)
        editBtn.AnchorPoint = Vector2.new(1, 0.5)
        editBtn.BackgroundColor3 = UI_THEME.Accent
        editBtn.Text = "Edit"
        editBtn.Font = Enum.Font.GothamBold
        editBtn.TextSize = 12
        editBtn.TextColor3 = Color3.new(1, 1, 1)
        editBtn.Visible = false
        editBtn.ZIndex = 2
        editBtn.Parent = card
        local eC = Instance.new("UICorner"); eC.CornerRadius = UDim.new(0, 4); eC.Parent = editBtn
        
        TrackWorldHumConnection(selectionBtn.MouseButton1Click:Connect(function()
            -- Clear previous selection
            if WorldHumState.selectionHighlight then
                pcall(function() WorldHumState.selectionHighlight:Destroy() end)
                WorldHumState.selectionHighlight = nil
            end
            
            -- Hide all other edit buttons
            for _, child in ipairs(page:GetChildren()) do
                local eb = child:FindFirstChild("Edit") or child:FindFirstChild("TextButton")
                if eb and eb:IsA("TextButton") and eb.Text == "Edit" then 
                    eb.Visible = false 
                end
            end
            
            -- Set selection
            WorldHumState.selectedHum = hum
            editBtn.Visible = true
            
            local hl = Instance.new("Highlight")
            hl.Enabled = not Flags["Settings/GhostMode"]
            hl.Name = "WorldHumSelectionHighlight"
            hl.Adornee = model
            hl.FillTransparency = 1
            hl.OutlineColor = Color3.new(255, 255, 255) -- White
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = model
            WorldHumState.selectionHighlight = hl
        end))
        
        TrackWorldHumConnection(editBtn.MouseButton1Click:Connect(function()
            if WorldHumState.selectionHighlight then
                WorldHumState.selectionHighlight:Destroy()
                WorldHumState.selectionHighlight = nil
            end
            ShowWorldHumEditor(page, hum)
        end))
    end
end

-- Refresh list when tab is opened
for _, t in pairs(UIState.Tabs) do
    if t.Label.Text == "WorldHumanoids" then
        TrackConnection(t.Button.MouseButton1Click:Connect(function()
            ShowWorldHumList(WorldHumState.Page)
        end))
        break
    end
end

function CreateWorldHumToggle(page, text, targetHum, prop)
    local path = GetUniquePath(targetHum)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = UI_THEME.Element
    Frame.BorderSizePixel = 0
    Frame.Parent = page
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, -30, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextColor3 = UI_THEME.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local initialLocked = (WorldHumState.lockedProperties[path] and WorldHumState.lockedProperties[path][prop] ~= nil)
    local LockBtn = Instance.new("TextButton")
    LockBtn.Size = UDim2.new(0, 24, 0, 24)
    LockBtn.AnchorPoint = Vector2.new(1, 0.5)
    LockBtn.Position = UDim2.new(1, -64, 0.5, 0)
    LockBtn.BackgroundTransparency = 1
    LockBtn.Text = initialLocked and "🔒" or "🔓"
    LockBtn.Font = Enum.Font.GothamBold
    LockBtn.TextSize = 14
    LockBtn.TextColor3 = initialLocked and UI_THEME.Accent or UI_THEME.TextDark
    LockBtn.Parent = Frame
    
    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.new(0, 44, 0, 22)
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.Position = UDim2.new(1, -12, 0.5, 0)
    Switch.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Switch.Parent = Frame
    local swCorner = Instance.new("UICorner"); swCorner.CornerRadius = UDim.new(1, 0); swCorner.Parent = Switch
    
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 18, 0, 18)
    Knob.AnchorPoint = Vector2.new(0, 0.5)
    Knob.Position = UDim2.new(0, 2, 0.5, 0)
    Knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Knob.Parent = Switch
    local kbCorner = Instance.new("UICorner"); kbCorner.CornerRadius = UDim.new(1, 0); kbCorner.Parent = Knob
    
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 1, 0)
    Button.BackgroundTransparency = 1
    Button.Text = ""
    Button.Parent = Switch
    
    local function updateVisuals(state)
        TweenService:Create(Switch, TWEENS.MEDIUM, {BackgroundColor3 = state and UI_THEME.Accent or Color3.fromRGB(50, 50, 50)}):Play()
        TweenService:Create(Knob, TWEENS.SMOOTH, {Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)}):Play()
    end

    WorldHumState.updaters[prop] = updateVisuals

    TrackWorldHumConnection(LockBtn.MouseButton1Click:Connect(function()
        local isLocked = not (WorldHumState.lockedProperties[path] and WorldHumState.lockedProperties[path][prop] ~= nil)
        if isLocked then
            if not WorldHumState.lockedProperties[path] then WorldHumState.lockedProperties[path] = {} end
            WorldHumState.lockedProperties[path][prop] = targetHum[prop]
        else
            WorldHumState.lockedProperties[path][prop] = nil
        end
        LockBtn.Text = isLocked and "🔒" or "🔓"
        LockBtn.TextColor3 = isLocked and UI_THEME.Accent or UI_THEME.TextDark
    end))

    TrackWorldHumConnection(Button.MouseButton1Click:Connect(function()
        local newState = not targetHum[prop]
        pcall(SafeSetProp, targetHum, prop, newState)
        if WorldHumState.lockedProperties[path] and WorldHumState.lockedProperties[path][prop] ~= nil then
            WorldHumState.lockedProperties[path][prop] = newState
        end
        updateVisuals(newState)
    end))
    
    updateVisuals(targetHum[prop])
end

function CreateWorldHumNumeric(page, text, targetHum, prop, min, max, step)
    local path = GetUniquePath(targetHum)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 48)
    Frame.BackgroundColor3 = UI_THEME.Element
    Frame.BorderSizePixel = 0
    Frame.Parent = page
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, -42, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextColor3 = UI_THEME.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local initialLocked = (WorldHumState.lockedProperties[path] and WorldHumState.lockedProperties[path][prop] ~= nil)
    local LockBtn = Instance.new("TextButton")
    LockBtn.Size = UDim2.new(0, 24, 0, 24)
    LockBtn.AnchorPoint = Vector2.new(1, 0.5)
    LockBtn.Position = UDim2.new(0.6, -12, 0.5, 0)
    LockBtn.BackgroundTransparency = 1
    LockBtn.Text = initialLocked and "🔒" or "🔓"
    LockBtn.Font = Enum.Font.GothamBold
    LockBtn.TextSize = 14
    LockBtn.TextColor3 = initialLocked and UI_THEME.Accent or UI_THEME.TextDark
    LockBtn.Parent = Frame
    
    local InputFrame = Instance.new("Frame")
    InputFrame.Size = UDim2.new(0.4, -12, 0, 30)
    InputFrame.Position = UDim2.new(1, -12, 0.5, 0)
    InputFrame.AnchorPoint = Vector2.new(1, 0.5)
    InputFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    InputFrame.Parent = Frame
    local ifCorner = Instance.new("UICorner"); ifCorner.CornerRadius = UDim.new(0, 4); ifCorner.Parent = InputFrame

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -50, 1, 0)
    Input.Position = UDim2.new(0, 25, 0, 0)
    Input.BackgroundTransparency = 1
    Input.Text = tostring(math.floor(targetHum[prop] * 100) / 100)
    Input.Font = Enum.Font.GothamBold
    Input.TextSize = 13
    Input.TextColor3 = UI_THEME.Accent
    Input.ClearTextOnFocus = false
    Input.Parent = InputFrame

    local function updateValue(val)
        val = math.clamp(tonumber(val) or targetHum[prop], min, max)
        if step and step > 0 then val = math.floor(val / step + 0.5) * step end
        pcall(SafeSetProp, targetHum, prop, val)
        if WorldHumState.lockedProperties[path] and WorldHumState.lockedProperties[path][prop] ~= nil then
            WorldHumState.lockedProperties[path][prop] = val
        end
        Input.Text = tostring(math.floor(val * 100) / 100)
    end

    WorldHumState.updaters[prop] = function(val)
        if not Input:IsFocused() then
            Input.Text = tostring(math.floor(val * 100) / 100)
        end
    end

    TrackWorldHumConnection(LockBtn.MouseButton1Click:Connect(function()
        local isLocked = not (WorldHumState.lockedProperties[path] and WorldHumState.lockedProperties[path][prop] ~= nil)
        if isLocked then
            if not WorldHumState.lockedProperties[path] then WorldHumState.lockedProperties[path] = {} end
            WorldHumState.lockedProperties[path][prop] = targetHum[prop]
        else
            WorldHumState.lockedProperties[path][prop] = nil
        end
        LockBtn.Text = isLocked and "🔒" or "🔓"
        LockBtn.TextColor3 = isLocked and UI_THEME.Accent or UI_THEME.TextDark
    end))

    TrackWorldHumConnection(Input.FocusLost:Connect(function() updateValue(Input.Text) end))
    
    local mBtn = Instance.new("TextButton")
    mBtn.Size = UDim2.new(0, 25, 1, 0)
    mBtn.BackgroundTransparency = 1
    mBtn.Text = "-"
    mBtn.Font = Enum.Font.GothamBold
    mBtn.TextSize = 16
    mBtn.TextColor3 = UI_THEME.TextDark
    mBtn.Parent = InputFrame
    TrackWorldHumConnection(mBtn.MouseButton1Click:Connect(function() updateValue(targetHum[prop] - (step or 1)) end))

    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0, 25, 1, 0)
    pBtn.Position = UDim2.new(1, -25, 0, 0)
    pBtn.BackgroundTransparency = 1
    pBtn.Text = "+"
    pBtn.Font = Enum.Font.GothamBold
    pBtn.TextSize = 16
    pBtn.TextColor3 = UI_THEME.TextDark
    pBtn.Parent = InputFrame
    TrackWorldHumConnection(pBtn.MouseButton1Click:Connect(function() updateValue(targetHum[prop] + (step or 1)) end))
end

function ShowWorldHumEditor(page, hum)
    page:ClearAllChildren()
    ClearWorldHumConnections()
    WorldHumState.selectedHum = hum
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(0, 80, 0, 24)
    backBtn.BackgroundColor3 = UI_THEME.Element
    backBtn.Text = "← Back"
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextSize = 12
    backBtn.TextColor3 = UI_THEME.Text
    backBtn.Parent = page
    local bC = Instance.new("UICorner"); bC.CornerRadius = UDim.new(0, 4); bC.Parent = backBtn
    TrackWorldHumConnection(backBtn.MouseButton1Click:Connect(function()
        ShowWorldHumList(page)
    end))

    UI.CreateSection(page, "Editor: " .. hum.Parent.Name)
    
    UI.CreateSection(page, "Behavior")
    CreateWorldHumToggle(page, "Archivable", hum, "Archivable")
    CreateWorldHumToggle(page, "Break Joints On Death", hum, "BreakJointsOnDeath")
    CreateWorldHumToggle(page, "Evaluate State Machine", hum, "EvaluateStateMachine")
    CreateWorldHumToggle(page, "Requires Neck", hum, "RequiresNeck")

    UI.CreateSection(page, "Control")
    CreateWorldHumToggle(page, "Auto Rotate", hum, "AutoRotate")
    CreateWorldHumToggle(page, "Platform Stand", hum, "PlatformStand")
    CreateWorldHumToggle(page, "Sit", hum, "Sit")

    UI.CreateSection(page, "Jump Settings")
    CreateWorldHumToggle(page, "Auto Jump Enabled", hum, "AutoJumpEnabled")
    CreateWorldHumNumeric(page, "Jump Height", hum, "JumpHeight", 0, 500, 1)
    CreateWorldHumNumeric(page, "Jump Power", hum, "JumpPower", 0, 500, 1)
    CreateWorldHumToggle(page, "Use Jump Power", hum, "UseJumpPower")

    UI.CreateSection(page, "Game")
    CreateWorldHumToggle(page, "Automatic Scaling Enabled", hum, "AutomaticScalingEnabled")
    CreateWorldHumNumeric(page, "Health", hum, "Health", 0, 100000, 1)
    CreateWorldHumNumeric(page, "Max Health", hum, "MaxHealth", 0, 100000, 1)
    CreateWorldHumNumeric(page, "Hip Height", hum, "HipHeight", 0, 100, 1)
    CreateWorldHumNumeric(page, "Max Slope Angle", hum, "MaxSlopeAngle", 0, 90, 1)
    CreateWorldHumNumeric(page, "Walk Speed", hum, "WalkSpeed", 0, 500, 1)
end

local WaypointsPage = UI.CreateTab("Waypoints")

-- Find the button to hide it initially
for _, t in pairs(UIState.Tabs) do
    if t.Label.Text == "Waypoints" then
        WaypointsTabButton = t.Button
        WaypointsTabButton.Visible = false
        break
    end
end

UI.CreateSection(WaypointsPage, "Active Waypoints")
WaypointsUIList = Instance.new("Frame")
WaypointsUIList.Size = UDim2.new(1, 0, 0, 0)
WaypointsUIList.BackgroundTransparency = 1
WaypointsUIList.Parent = WaypointsPage
local wListLayout = Instance.new("UIListLayout")
wListLayout.Padding = UDim.new(0, 5)
wListLayout.SortOrder = Enum.SortOrder.LayoutOrder
wListLayout.Parent = WaypointsUIList

-- Automatic canvas resizing for WaypointsPage based on children
TrackConnection(wListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    WaypointsUIList.Size = UDim2.new(1, 0, 0, wListLayout.AbsoluteContentSize.Y)
end))

-- AIMBOT TAB
UI.CreateSection(AimTab, "General Aim")
UI.CreateToggle(AimTab, "Enable Aim Lock", "Aimbot/AimLock", Flags["Aimbot/AimLock"])
UI.CreateToggle(AimTab, "Enable Auto Fire", "Aimbot/AutoFire", Flags["Aimbot/AutoFire"])
UI.CreateToggle(AimTab, "Always Active (No Keybind, If OFF: hold RMB to Lock on)", "Aimbot/AlwaysEnabled", Flags["Aimbot/AlwaysEnabled"])
UI.CreateToggle(AimTab, "Team Check", "Aimbot/TeamCheck", Flags["Aimbot/TeamCheck"])
UI.CreateToggle(AimTab, "Visibility Check", "Aimbot/VisibilityCheck", Flags["Aimbot/VisibilityCheck"])
UI.CreateNumericInput(AimTab, "Smoothing", "Aimbot/Sensitivity", Flags["Aimbot/Sensitivity"], 0, 100, 1, "%")
UI.CreateNumericInput(AimTab, "FOV Radius", "Aimbot/FOV/Radius", Flags["Aimbot/FOV/Radius"], 0, 500, 5, "px")

UI.CreateSection(AimTab, "Ballistics")
UI.CreateToggle(AimTab, "Predict Movement", "Aimbot/Prediction", Flags["Aimbot/Prediction"])
UI.CreateNumericInput(AimTab, "Bullet Speed", "Prediction/Velocity", Flags["Prediction/Velocity"], 100, 5000, 50, " st/s", function(v) AimState.ProjectileSpeed = v end)
UI.CreateNumericInput(AimTab, "Gravity Scale", "Prediction/GravityMultiplier", Flags["Prediction/GravityMultiplier"], 0, 5, 0.1, "x", function(v) AimState.GravityCorrection = v end)

UI.CreateSection(AimTab, "Trigger Bot")
-- Linked to Auto Fire
UI.CreateToggle(AimTab, "Enable Trigger", "Aimbot/AutoFire", Flags["Aimbot/AutoFire"])
UI.CreateToggle(AimTab, "Hold Fire", "Trigger/HoldMouseButton", Flags["Trigger/HoldMouseButton"])
UI.CreateNumericInput(AimTab, "Trigger Delay", "Trigger/Delay", Flags["Trigger/Delay"] * 1000, 0, 1000, 10, "ms", function(v) Flags["Trigger/Delay"] = v/1000 end)

-- VISUALS TAB
UI.CreateSection(VisualsTab, "Player ESP")
UI.CreateToggle(VisualsTab, "Enable ESP", "ESP/Enabled", Flags["ESP/Enabled"], function(state)
    if not state then
        -- Feature disabled - cleanup outlines to prevent ghosts since update loop stops
        for _, player in ipairs(Players:GetPlayers()) do
             RemovePlayerOutlines(player)
        end
    end
end)
UI.CreateToggle(VisualsTab, "Draw Names", "ESP/Nametags", Flags["ESP/Nametags"])
UI.CreateToggle(VisualsTab, "Draw Tracers", "ESP/Tracers", Flags["ESP/Tracers"])
UI.CreateToggle(VisualsTab, "Off-Screen Indicators", "ESP/OffscreenIndicators", Flags["ESP/OffscreenIndicators"], function(state)
    -- When disabled, hide all existing off-screen indicators
    if not state then
        for _, espData in pairs(ESPObjects) do
            if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
                espData.OffscreenIndicator.Frame.Visible = false
                espData.lastOffscreenVisible = false
            end
        end
    end
end)
UI.CreateToggle(VisualsTab, "Player Panel (Top 10)", "ESP/PlayerPanel", Flags["ESP/PlayerPanel"], function(state)
    -- Create panel if it doesn't exist yet
    if state and not PlayerPanelFrame then
        CreatePlayerPanel()
    end
    -- Toggle visibility
    if PlayerPanelFrame then
        PlayerPanelFrame.Visible = state
    end
end)
UI.CreateToggle(VisualsTab, "Player Outlines (Hitbox)", "ESP/PlayerOutlines", Flags["ESP/PlayerOutlines"], function(state)
    -- When disabled, remove all existing outlines immediately
    if not state then
        for player, outlines in pairs(PlayerOutlineObjects) do
            for partName, highlight in pairs(outlines) do
                pcall(function() highlight:Destroy() end)
            end
        end
        table.clear(PlayerOutlineObjects)
    end
end)
UI.CreateToggle(VisualsTab, "Fullbright (Remove Shadows/Fog)", "Visuals/Fullbright", Flags["Visuals/Fullbright"])

UI.CreateSection(VisualsTab, "Waypoints Settings")
UI.CreateToggle(VisualsTab, "Enable Waypoints", "Waypoints/Enabled", Flags["Waypoints/Enabled"], function(state)
    RefreshWaypointUI()
end)

-- HUMANOID TAB
local function _updateHum(prop, val)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(SafeSetProp, hum, prop, val)
    end
end

UI.CreateSection(HumanoidTab, "Behavior")
UI.CreateToggle(HumanoidTab, "Archivable", "Humanoid/Archivable", Flags["Humanoid/Archivable"], function(v) _updateHum("Archivable", v) end, true)
UI.CreateToggle(HumanoidTab, "Break Joints On Death", "Humanoid/BreakJointsOnDeath", Flags["Humanoid/BreakJointsOnDeath"], function(v) _updateHum("BreakJointsOnDeath", v) end, true)
UI.CreateToggle(HumanoidTab, "Evaluate State Machine", "Humanoid/EvaluateStateMachine", Flags["Humanoid/EvaluateStateMachine"], function(v) _updateHum("EvaluateStateMachine", v) end, true)
UI.CreateToggle(HumanoidTab, "Requires Neck", "Humanoid/RequiresNeck", Flags["Humanoid/RequiresNeck"], function(v) _updateHum("RequiresNeck", v) end, true)

UI.CreateSection(HumanoidTab, "Control")
UI.CreateToggle(HumanoidTab, "Auto Rotate", "Humanoid/AutoRotate", Flags["Humanoid/AutoRotate"], function(v) _updateHum("AutoRotate", v) end, true)
UI.CreateToggle(HumanoidTab, "Platform Stand", "Humanoid/PlatformStand", Flags["Humanoid/PlatformStand"], function(v) _updateHum("PlatformStand", v) end, true)
UI.CreateToggle(HumanoidTab, "Sit", "Humanoid/Sit", Flags["Humanoid/Sit"], function(v) _updateHum("Sit", v) end, true)
UI.CreateToggle(HumanoidTab, "Jump", "Humanoid/Jump", Flags["Humanoid/Jump"], function(v) 
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Jump = v
    end
end, true)

UI.CreateSection(HumanoidTab, "Jump Settings")
UI.CreateToggle(HumanoidTab, "Auto Jump Enabled", "Humanoid/AutoJumpEnabled", Flags["Humanoid/AutoJumpEnabled"], function(v) _updateHum("AutoJumpEnabled", v) end, true)
UI.CreateNumericInput(HumanoidTab, "Jump Height", "Humanoid/JumpHeight", Flags["Humanoid/JumpHeight"], 0, 500, 1, nil, function(v) _updateHum("JumpHeight", v) end, true)
UI.CreateNumericInput(HumanoidTab, "Jump Power", "Humanoid/JumpPower", Flags["Humanoid/JumpPower"], 0, 500, 1, nil, function(v) _updateHum("JumpPower", v) end, true)
UI.CreateToggle(HumanoidTab, "Use Jump Power", "Humanoid/UseJumpPower", Flags["Humanoid/UseJumpPower"], function(v) _updateHum("UseJumpPower", v) end, true)

UI.CreateSection(HumanoidTab, "Game")
UI.CreateToggle(HumanoidTab, "Automatic Scaling Enabled", "Humanoid/AutomaticScalingEnabled", Flags["Humanoid/AutomaticScalingEnabled"], function(v) _updateHum("AutomaticScalingEnabled", v) end, true)
UI.CreateNumericInput(HumanoidTab, "Health", "Humanoid/Health", Flags["Humanoid/Health"], 0, 2000, 1, nil, function(v) _updateHum("Health", v) end, true)
UI.CreateNumericInput(HumanoidTab, "Max Health", "Humanoid/MaxHealth", Flags["Humanoid/MaxHealth"], 0, 2000, 1, nil, function(v) _updateHum("MaxHealth", v) end, true)
UI.CreateNumericInput(HumanoidTab, "Hip Height", "Humanoid/HipHeight", Flags["Humanoid/HipHeight"], 0, 100, 1, nil, function(v) _updateHum("HipHeight", v) end, true)
UI.CreateNumericInput(HumanoidTab, "Max Slope Angle", "Humanoid/MaxSlopeAngle", Flags["Humanoid/MaxSlopeAngle"], 0, 90, 1, nil, function(v) _updateHum("MaxSlopeAngle", v) end, true)
UI.CreateNumericInput(HumanoidTab, "Walk Speed", "Humanoid/WalkSpeed", Flags["Humanoid/WalkSpeed"], 0, 500, 1, nil, function(v) _updateHum("WalkSpeed", v) end, true)

-- MISC TAB
UI.CreateSection(MiscTab, "Br3ak3r Tool")
UI.CreateToggle(MiscTab, "Enable Br3ak3r", "Br3ak3r/Enabled", Flags["Br3ak3r/Enabled"], function(state)
    Br3ak3rState.CLICKBREAK_ENABLED = state
    if not state and Br3ak3rState.hoverHL then
        Br3ak3rState.hoverHL.Enabled = false
    end
end)
UI.CreateButton(MiscTab, "Undo Last Break (Ctrl+Z)", unbreakLast)
UI.CreateButton(MiscTab, "Clear All Breaks (Ctrl+X)", unbreakAll)

UI.CreateSection(MiscTab, "H1ghl1ght3r Tool")
UI.CreateToggle(MiscTab, "Enable H1ghl1ght3r", "H1ghl1ght3r/Enabled", H1ghl1ght3rState.ENABLED, function(state)
    H1ghl1ght3rState.ENABLED = state
    if not state and Br3ak3rState.hoverHL then
        Br3ak3rState.hoverHL.Enabled = false
    end
end)
UI.CreateButton(MiscTab, "Undo Last Highlight (Ctrl+Shift+Z)", unhighlightLast)

UI.CreateSection(MiscTab, "Utilities")
UI.CreateButton(MiscTab, "Rejoin Server", Rejoin)
UI.CreateButton(MiscTab, "Unload Script", Cleanup)

UI.CreateSection(MiscTab, "Configuration")
UI.CreateToggle(MiscTab, "Freecam Toggle (Ctrl+P)", "Settings/Freecam Toggle", Flags["Settings/Freecam Toggle"], function(state)
    if not state and type(_G.StopFreecamFunc) == "function" then
        _G.StopFreecamFunc()
    end
end)
UI.CreateToggle(MiscTab, "Gh0st Mode (Ctrl+G)", "Settings/GhostMode", Flags["Settings/GhostMode"])
UI.CreateToggle(MiscTab, "Show Performance Stats", "Performance/Enabled", Flags["Performance/Enabled"], function(state)
    if PerformanceLabel then PerformanceLabel.Visible = state end
end)
UI.CreateToggle(MiscTab, "Enable D3v Tool (Ctrl+.)", "Misc/D3vTool", Flags["Misc/D3vTool"])

-- Helper to setup player ESP and connections
function SetupPlayerESP(player)
    if player == LocalPlayer then return end
    
    CreateESP(player)
    local espData = ESPObjects[player]
    
    if espData then
        -- FIX: Prevent duplicate connections if SetupPlayerESP is called multiple times for the same player
        if espData.Connections then
            for _, conn in pairs(espData.Connections) do
                if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                    conn:Disconnect()
                end
            end
            table.clear(espData.Connections)
        else
            espData.Connections = {}
        end

        -- Track CharacterAdded connection LOCALLY in espData, not globally
        local conn = player.CharacterAdded:Connect(function(character)
            -- FIX: Invalidate character cache immediately on spawn
            CharCache[player] = nil
            
            -- Wait for character to be fully parented and have a root part
            local attempts = 0
            local root = nil
            repeat
                task.wait(0.2)
                root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
                attempts = attempts + 1
            until root or attempts > 10
            
            if player.Parent and Sp3arParvus.Active then
                -- Force ESP update for this player when their character spawns
                local data = ESPObjects[player]
                if data then
                    -- Reset cache to force full update of labels and colors
                    data.lastNickname = ""
                    data.lastUsername = ""
                    data.lastDistance = -1
                    data.lastTeamColor = nil
                    data.lastDistanceColor = nil
                    
                    -- Ensure ScreenGui is valid
                    EnsureScreenGui()
                    
                    -- Update immediately
                    UpdateESP(os.clock(), player, player == NearestPlayerRef)
                end
            end
        end)
        table.insert(espData.Connections, conn)
        
        -- Handle players whose character spawned before the event was hooked
        if player.Character then
            task.spawn(function()
                local character = player.Character
                
                -- Invalidate character cache
                CharCache[player] = nil
                
                -- Wait for character to be fully parented and have a root part
                local attempts = 0
                local root = nil
                repeat
                    task.wait(0.2)
                    root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
                    attempts = attempts + 1
                until root or attempts > 10
                
                if player.Parent and Sp3arParvus.Active then
                    -- Reset cache to force full update
                    espData.lastNickname = ""
                    espData.lastUsername = ""
                    espData.lastDistance = -1
                    espData.lastTeamColor = nil
                    espData.lastDistanceColor = nil
                    
                    EnsureScreenGui()
                    UpdateESP(os.clock(), player, player == NearestPlayerRef)
                end
            end)
        end
    end
end

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    SetupPlayerESP(player)
end

-- Event Listeners
-- Handle new players joining
TrackConnection(Players.PlayerAdded:Connect(function(player)
    AddPlayerToCache(player)
    SetupPlayerESP(player)
end))
TrackConnection(Players.PlayerRemoving:Connect(function(player) 
    RemovePlayerFromCache(player)
    CharCache[player] = nil -- Clear character cache
    RemoveESP(player) 
end))

-- MAIN UPDATE LOOPS

-- CONSOLIDATED Input Handler (includes Br3ak3r Ctrl+Click functionality)
TrackConnection(Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Track Ctrl & Shift key state
    if input.KeyCode == Enum.KeyCode.LeftControl then
        Br3ak3rState.LEFT_CTRL_HELD = true
        Br3ak3rState.CTRL_HELD = true
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        Br3ak3rState.RIGHT_CTRL_HELD = true
        Br3ak3rState.CTRL_HELD = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        H1ghl1ght3rState.SHIFT_HELD = true
    end
    
    -- Handle RMB for Aimbot/Trigger (only when not processed by game)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimState.Aimbot = Flags["Aimbot/AimLock"]
        AimState.Trigger = Flags["Aimbot/AutoFire"]
    end
    
    -- Br3ak3r / H1ghl1ght3r: Ctrl+Click
    if not gameProcessed and Br3ak3rState.CTRL_HELD and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if H1ghl1ght3rState.SHIFT_HELD and H1ghl1ght3rState.ENABLED then
            local origin, direction = GetMouseRay()
            if origin and direction then
                local hit = WorldRaycastBr3ak3r(origin, direction, true)
                if hit and hit.Instance and hit.Instance:IsA("BasePart") then
                    markHighlighted(hit.Instance)
                end
            end
        elseif Br3ak3rState.CLICKBREAK_ENABLED then
            local origin, direction = GetMouseRay()
            if origin and direction then
                local hit = WorldRaycastBr3ak3r(origin, direction, true)
                if hit and hit.Instance and hit.Instance:IsA("BasePart") then
                    markBroken(hit.Instance)
                end
            end
        end
    end

    -- Waypoints: Ctrl+MiddleClick to add/remove
    if not gameProcessed and Br3ak3rState.CTRL_HELD and input.UserInputType == Enum.UserInputType.MouseButton3 then
        if Flags["Waypoints/Enabled"] then
            -- First check for deletion (click on existing waypoint screen pos)
            local mouseLoc = UserInputService:GetMouseLocation()
            local origin, direction = GetMouseRay()
            local raycastHit = nil
            if origin and direction then
                raycastHit = WorldRaycastBr3ak3r(origin, direction, true)
            end
            
            local deleted = false
            for id, wpData in pairs(ActiveWaypoints) do
                local screenPos, onScreen = Camera:WorldToViewportPoint(wpData.Position)
                
                -- Check 1: Is it close in 2D Screen Space? (Increased buffer to 60px)
                local screenClose = false
                if onScreen then
                    local dist = math.sqrt((mouseLoc.X - screenPos.X)^2 + (mouseLoc.Y - screenPos.Y)^2)
                    if dist < 60 then 
                        screenClose = true
                    end
                end
                
                -- Check 2: Is it close in 3D World Space? (15 studs buffer if raycast hit)
                local worldClose = false
                if raycastHit and raycastHit.Position then
                    local dist3D = (wpData.Position - raycastHit.Position).Magnitude
                    if dist3D < 15 then
                        worldClose = true
                    end
                end
                
                if screenClose or worldClose then
                    DestroyWaypoint(id)
                    deleted = true
                    -- Note: Intentionally NOT breaking here, so we can delete multiple clustered waypoints at once
                end
            end
            
            -- If not deleted, create a new one via raycast
            if not deleted then
                if raycastHit then
                    CreateWaypoint(raycastHit.Position)
                end
            end
        end
    end
    
    -- Br3ak3r / H1ghl1ght3r keyboard shortcuts (only when not processed by game)
    if not gameProcessed and Br3ak3rState.CTRL_HELD and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.Z then
            if H1ghl1ght3rState.SHIFT_HELD then
                -- Ctrl+Shift+Z: Undo last highlight
                unhighlightLast()
            else
                -- Ctrl+Z: Undo last break
                unbreakLast()
            end
        elseif input.KeyCode == Enum.KeyCode.X then
            -- Ctrl+X: Clear all breaks
            unbreakAll()
        elseif input.KeyCode == Enum.KeyCode.B then
            -- Ctrl+B: Toggle Br3ak3r
            Br3ak3rState.CLICKBREAK_ENABLED = not Br3ak3rState.CLICKBREAK_ENABLED
            Flags["Br3ak3r/Enabled"] = Br3ak3rState.CLICKBREAK_ENABLED
            if not Br3ak3rState.CLICKBREAK_ENABLED and Br3ak3rState.hoverHL then
                Br3ak3rState.hoverHL.Enabled = false
            end
        elseif input.KeyCode == Enum.KeyCode.E then
            -- Ctrl+E: Load Any-Item-ESP
            loadstring(game:HttpGet("https://raw.githubusercontent.com/JakeHukari/Any-Item-ESP/refs/heads/main/any_item_esp.lua", true))()
        elseif input.KeyCode == Enum.KeyCode.R then
            -- Ctrl+R: Rejoin
            Rejoin()
        elseif input.KeyCode == Enum.KeyCode.U then
            -- Ctrl+U: Unload Script
            Cleanup()
        elseif input.KeyCode == Enum.KeyCode.F then
            -- Ctrl+F: Toggle Fullbright
            Flags["Visuals/Fullbright"] = not Flags["Visuals/Fullbright"]
        elseif input.KeyCode == Enum.KeyCode.G then
            -- Ctrl+G: Toggle Gh0st Mode
            Flags["Settings/GhostMode"] = not Flags["Settings/GhostMode"]
        elseif input.KeyCode == Enum.KeyCode.Period then
            -- Ctrl+.: Toggle D3v Tool
            Flags["Misc/D3vTool"] = not Flags["Misc/D3vTool"]
        elseif input.KeyCode == Enum.KeyCode.Minus then
            -- Ctrl+-: Toggle Minimize
            if UIState.ToggleMinimize then
                UIState.ToggleMinimize()
            end
        end
    end
end))

-- CONSOLIDATED InputEnded Handler (includes Ctrl key tracking)
TrackConnection(Services.UserInputService.InputEnded:Connect(function(input)
    -- Track Ctrl key release
    if input.KeyCode == Enum.KeyCode.LeftControl then
        Br3ak3rState.LEFT_CTRL_HELD = false
        if not UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            Br3ak3rState.CTRL_HELD = false
        end
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        Br3ak3rState.RIGHT_CTRL_HELD = false
        if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            Br3ak3rState.CTRL_HELD = false
        end
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and not UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
            H1ghl1ght3rState.SHIFT_HELD = false
        end
    end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimState.Aimbot = false
        AimState.Trigger = false
    end
end))

-- OPTIMIZED: Shared target cache (prevents redundant GetClosest calls)
-- GetClosest is EXPENSIVE (iterates all players + raycasts) - call it ONCE per frame max
local TARGET_CACHE_DURATION = 0.016 -- ~1 frame at 60fps

function GetCachedTarget()
    local now = os.clock()
    if CachedTarget and (now - CachedTargetTime) < TARGET_CACHE_DURATION then
        return CachedTarget
    end
    
    -- Use broadest settings to find targets (Aimbot settings as primary)
    CachedTarget = GetClosest(
        Flags["Aimbot/AimLock"] or Flags["Aimbot/AutoFire"],
        Flags["Aimbot/TeamCheck"],
        Flags["Aimbot/VisibilityCheck"],
        false, -- Distance check disabled (no cap)
        0, -- Distance limit unused
        max(Flags["Aimbot/FOV/Radius"], Flags["Trigger/FOV/Radius"]),
        Flags["Aimbot/Priority"],
        Flags["Aimbot/BodyParts"],
        Flags["Aimbot/Prediction"],
        AimState.LastAimbotTarget -- Sticky target support
    )
    CachedTargetTime = now
    return CachedTarget
end

-- Aimbot update loop (OPTIMIZED - uses cached target)
-- Aimbot update loop (FIXED - clears state when target is lost)
function UpdateAimbot()
    if not Sp3arParvus.Active or not LocalCharReady then
        ClearAimLockState(false)
        return
    end


    local aimbotActive = Flags["Aimbot/AimLock"] and (Flags["Aimbot/AlwaysEnabled"] or AimState.Aimbot)
    if not aimbotActive then
        ClearAimLockState(false)
        return
    end

    local target = GetCachedTarget()
    if target then
        AimAt(target, Flags["Aimbot/Sensitivity"] / 100)
    else
        ClearAimLockState(false)
    end
end

TrackConnection(RunService.RenderStepped:Connect(UpdateAimbot))

-- Trigger bot loop (FIXED - maintains fire while target is alive)
-- Logic: Trigger fires when:
--   1. Trigger/AlwaysEnabled is true (always auto-fire when target in FOV), OR
--   2. RMB is held (AimState.Trigger=true) AND AutoFire is enabled
local triggerThread = task.spawn(function()
    local MAX_TRIGGER_ITERATIONS = 1000
    while Sp3arParvus.Active do
        local triggerActive = Flags["Trigger/AlwaysEnabled"] or (AimState.Trigger and Flags["Aimbot/AutoFire"])
        if triggerActive and not Br3ak3rState.LEFT_CTRL_HELD then
            if type(isrbxactive) == "function" and isrbxactive() and type(mouse1press) == "function" and type(mouse1release) == "function" then
                -- Get initial target
                local TriggerClosest = GetCachedTarget()

                if TriggerClosest then
                    -- Store the target player reference for tracking
                    local lockedPlayer = TriggerClosest[1]
                    local lockedCharacter = TriggerClosest[2]
                    
                    task.wait(Flags["Trigger/Delay"])
                    mouse1press()

                    if Flags["Trigger/HoldMouseButton"] then
                        local iterations = 0
                        while Sp3arParvus.Active and iterations < MAX_TRIGGER_ITERATIONS do
                            iterations = iterations + 1
                            task.wait()
                            
                            -- Check if locked target is still valid and alive (cheaper than GetClosest)
                            local targetStillValid = false
                            if lockedPlayer and lockedPlayer.Parent then
                                local character, rootPart = GetCharacter(lockedPlayer)
                                if character and rootPart then
                                    targetStillValid = true
                                    -- Update character reference in case it changed
                                    lockedCharacter = character
                                end
                            end

                            -- Break if target died, player left, trigger released, or clutch pressed
                            local shouldContinue = (Flags["Trigger/AlwaysEnabled"] or AimState.Trigger) and not Br3ak3rState.LEFT_CTRL_HELD
                            if not targetStillValid or not shouldContinue then break end
                        end

                        if iterations >= MAX_TRIGGER_ITERATIONS then
                            warn("Trigger loop reached max iterations, resetting state")
                            AimState.Trigger = false
                        end
                    end

                    mouse1release()
                    
                    -- Explicitly release strong references that might keep characters alive
                    TriggerClosest = nil
                    lockedPlayer = nil
                    lockedCharacter = nil
                end
            end
        end
        task.wait()
    end
end)
TrackThread(triggerThread)

-- ESP update loop (OPTIMIZED - throttled updates, no per-frame player iteration)
lastEspUpdate = 0
espUpdateRate = 0.2 -- ~5 FPS for ESP (reduced from 10fps - big perf gain on low-end devices)
lastTrackerUpdate = 0
trackerUpdateRate = 0.5 -- Tracker updates at ~2 FPS (reduced from 3fps)
lastBr3ak3rCleanup = 0
br3ak3rCleanupRate = 2.0 
lastHoverUpdate = 0
hoverUpdateRate = 0.033 -- Hover at 30fps
lastStateEnforcement = 0
stateEnforcementRate = 0.1 -- 10 FPS for StreamingEnabled/GhostMode enforcement
lastHumanoidSync = 0
humanoidSyncRate = 0.1 -- 10 FPS
lastWorldHumListUpdate = 0
lastGhostMode = nil

-- Unified Heartbeat Loop (Optimized: Single connection for all non-render-critical updates)
-- Combines ESP, Tracker, Br3ak3r logic into one scheduler
function UnifiedHeartbeat(dt)
    if not Sp3arParvus.Active or not LocalCharReady then return end
    
    local now = os.clock()
    local ghostMode = Flags["Settings/GhostMode"]
    local ghostModeChanged = (ghostMode ~= lastGhostMode)
    lastGhostMode = ghostMode

    if ghostModeChanged and not ghostMode then
        -- Restore visibility when Gh0st mode toggled off
        if ClosestPlayerTrackerLabel and not ClosestPlayerTrackerLabel.Visible and Flags["ESP/Enabled"] then
            ClosestPlayerTrackerLabel.Visible = true
        end
        if PerformanceLabel and not PerformanceLabel.Visible and Flags["Performance/Enabled"] then
            PerformanceLabel.Visible = true
        end
        if LocalHealthHUD and not LocalHealthHUD.Visible then
            LocalHealthHUD.Visible = true
        end
        if PlayerPanelFrame and not PlayerPanelFrame.Visible and Flags["ESP/PlayerPanel"] then
            PlayerPanelFrame.Visible = true
        end
    end

    if (now - lastStateEnforcement) > stateEnforcementRate or ghostModeChanged then
        lastStateEnforcement = now
        UpdateLocalHealthHUD()
        UpdateD3vTool()
    end
    
    UpdateFullbright()
    ApplyHumanoidSettings()
    ApplyWorldHumanoidSettings()
    
    if (now - lastHumanoidSync) > humanoidSyncRate then
        lastHumanoidSync = now
        UpdateHumanoidUI()
        UpdateWorldHumanoidEditorUI()
    end

    if UIState.CurrentTab == "WorldHumanoids" and not WorldHumState.selectedHum then
        if (now - lastWorldHumListUpdate) > 1.0 then
            lastWorldHumListUpdate = now
            local myChar = LocalPlayer.Character
            local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
            local myPos = myRoot and myRoot.Position or Camera.CFrame.Position

            for _, entry in ipairs(WorldHumState.listEntries) do
                local hum = entry.hum
                local card = entry.card
                local label = entry.label
                if hum and hum.Parent and card and label then
                    local root = hum.RootPart or hum.Parent.PrimaryPart
                    if root then
                        local dist = (root.Position - myPos).Magnitude
                        local distFloor = math.floor(dist)
                        label.Text = distFloor .. " studs away"
                        card.LayoutOrder = distFloor
                    end
                end
            end
        end
    end
    
    -- Update Waypoint Distances
    if Flags["Waypoints/Enabled"] then
        for id, wpData in pairs(ActiveWaypoints) do
            if wpData.Part and wpData.Label then
                local dist = (wpData.Position - Camera.CFrame.Position).Magnitude
                local distRounded = math.floor(dist)
                wpData.DistanceText = distRounded .. " studs"
                wpData.Label.Text = string.format("%s\n%s", wpData.Name, wpData.DistanceText)
            end
            local wpVisible = not ghostMode
            if wpData.Billboard and wpData.Billboard.Enabled ~= wpVisible then wpData.Billboard.Enabled = wpVisible end
            if wpData.PinBg and wpData.PinBg.Enabled ~= wpVisible then wpData.PinBg.Enabled = wpVisible end
        end
    else
        -- Hide all if disabled
        for id, wpData in pairs(ActiveWaypoints) do
            if wpData.Billboard then wpData.Billboard.Enabled = false end
            if wpData.PinBg then wpData.PinBg.Enabled = false end
        end
    end

    local now = os.clock()
    
    -- 1. ESP & Tracker Updates
    -- Check throttle FIRST before anything else to save perf
    local shouldUpdateEsp = (now - lastEspUpdate) > espUpdateRate
    local shouldUpdateTracker = (now - lastTrackerUpdate) > trackerUpdateRate
    
    -- Also force update the LOCKED target every frame for instant dot color feedback
    local forceUpdateTarget = nil
    if CachedTarget and (now - CachedTargetTime) < 0.1 then
        forceUpdateTarget = CachedTarget[1]
    end

    if (shouldUpdateEsp or forceUpdateTarget) then
        if shouldUpdateEsp then
            lastEspUpdate = now
        end
        
        -- Update ESP for all players
        local players = GetPlayersCache()
        local myPos = Camera.CFrame.Position
        local espEnabled = Flags["ESP/Enabled"]
        
        for _, player in ipairs(players) do
            if player ~= LocalPlayer then
                if not espEnabled then
                    -- If ESP is disabled, ensure all elements are hidden immediately
                    local espData = ESPObjects[player]
                    if espData then
                        if espData.Nametag and espData.Nametag.Enabled then espData.Nametag.Enabled = false end
                        if espData.Tracer and espData.Tracer.Visible then espData.Tracer.Visible = false end
                        if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame and espData.OffscreenIndicator.Frame.Visible then
                            espData.OffscreenIndicator.Frame.Visible = false
                        end
                    end
                    RemovePlayerOutlines(player)
                    continue
                end
                -- Optimization: Level of Detail (LoD) updates
                -- Only update specific target if not in a full update cycle
                local pChar, pRoot = GetCharacter(player)
                local skip = false
                
                if not shouldUpdateEsp and player ~= forceUpdateTarget then
                    skip = true
                end
                
                -- Extra throttling for distant players
                if not skip and pRoot and player ~= forceUpdateTarget then
                    local dist = (pRoot.Position - myPos).Magnitude
                    if dist > 1000 then
                        -- Update very distant players only every ~2 seconds (1 in 10 full updates)
                        if (floor(now * 5) % 10) ~= 0 then skip = true end
                    elseif dist > 400 then
                        -- Update mid-range players only every ~0.8 seconds (1 in 4 full updates)
                        if (floor(now * 5) % 4) ~= 0 then skip = true end
                    end
                end

                if not skip then
                   UpdateESP(now, player, player == NearestPlayerRef)
                end
            end
        end
    end

    -- Tracker updates (low freq)
    if shouldUpdateTracker then
        lastTrackerUpdate = now
        UpdateNearestPlayer()
        UpdateClosestPlayerTracker()
        UpdatePlayerPanel()
    end
    
    -- 2. Br3ak3r Updates
    -- Update hover highlight (throttled to 30fps)
    if (now - lastHoverUpdate) > hoverUpdateRate then
        lastHoverUpdate = now
        UpdateBr3ak3rHover()
    end
    
    -- Periodic cleanup (throttled)
    if (now - lastBr3ak3rCleanup) > br3ak3rCleanupRate then
        lastBr3ak3rCleanup = now
        UpdatePlayerCache()
        pcall(pruneBrokenSet)
        pcall(pruneHighlightedSet)
        
        -- MEMORY LEAK FIX: Periodic cache pruning to clear stale references
        CleanupDeadConnections()
        CleanupDeadThreads()
        PruneCharCache()
        ClearCandidateReferences()
        ClearSortCacheReferences()
        ValidateESPObjects()
    end
    
    -- Sweep undo stack (very cheap)
    sweepUndo(dt)
    sweepHighlightedUndo(dt)

    -- Periodic state enforcement for broken/highlighted parts (StreamingEnabled fix)
    if (now - lastStateEnforcement) > stateEnforcementRate or ghostModeChanged then
        lastStateEnforcement = now

        if ScreenGui and ScreenGui.Enabled ~= (not ghostMode) then
            ScreenGui.Enabled = not ghostMode
        end

        if ghostMode then
            for _, espData in pairs(ESPObjects) do
                if espData.Nametag and espData.Nametag.Enabled then espData.Nametag.Enabled = false end
                if espData.Tracer and espData.Tracer.Visible then espData.Tracer.Visible = false end
                if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame and espData.OffscreenIndicator.Frame.Visible then
                    espData.OffscreenIndicator.Frame.Visible = false
                end
            end

            -- Ensure pooled objects are disabled during Gh0st mode
            for _, obj in ipairs(PoolFolder:GetChildren()) do
                pcall(function()
                    if obj.Enabled then obj.Enabled = false end
                end)
            end

            if ClosestPlayerTrackerLabel and ClosestPlayerTrackerLabel.Visible then ClosestPlayerTrackerLabel.Visible = false end
            if PerformanceLabel and PerformanceLabel.Visible then PerformanceLabel.Visible = false end
            if LocalHealthHUD and LocalHealthHUD.Visible then LocalHealthHUD.Visible = false end
            if PlayerPanelFrame and PlayerPanelFrame.Visible then PlayerPanelFrame.Visible = false end
        end

        local enforcementMadeChange = false
        for path, data in pairs(Br3ak3rState.brokenSet) do
            local part = data.instance
            if not part or not part.Parent then
                part = GetInstanceFromPath(path)
                if part then data.instance = part end
            end
            if part and part.Parent then
                if part.CanCollide ~= false then 
                    part.CanCollide = false 
                    enforcementMadeChange = true
                end
                local targetT = (ghostMode and type(data) == "table") and data.t or 0.5
                local targetLTM = (ghostMode and type(data) == "table") and data.ltm or 0.5
                if part.Transparency ~= targetT then 
                    part.Transparency = targetT 
                    enforcementMadeChange = true
                end
                if part.LocalTransparencyModifier ~= targetLTM then 
                    part.LocalTransparencyModifier = targetLTM 
                    enforcementMadeChange = true
                end
            end
        end
        if enforcementMadeChange then
            Br3ak3rState.brokenCacheDirty = true
        end

        -- Continuous state enforcement for highlighted parts (ensure visibility)
        for part, data in pairs(H1ghl1ght3rState.highlightedSet) do
            if part.Parent then
                local targetT = (ghostMode and type(data) == "table") and data.t or 0.5
                local targetLTM = (ghostMode and type(data) == "table") and data.ltm or 0.5
                if part.Transparency ~= targetT then part.Transparency = targetT end
                if part.LocalTransparencyModifier ~= targetLTM then part.LocalTransparencyModifier = targetLTM end
                
                local hVisible = not ghostMode
                if data.hl and data.hl.Enabled ~= hVisible then data.hl.Enabled = hVisible end
                if data.bg and data.bg.Enabled ~= hVisible then data.bg.Enabled = hVisible end
            end
        end

        -- Continuous state enforcement for player outlines (ensure Ghost Mode)
        for player, storage in pairs(PlayerOutlineObjects) do
            local outlineVisible = not ghostMode
            if storage.Highlight and storage.Highlight.Enabled ~= outlineVisible then
                storage.Highlight.Enabled = outlineVisible
            end
            if storage.HeadDot and storage.HeadDot.Enabled ~= outlineVisible then
                storage.HeadDot.Enabled = outlineVisible
            end
            if storage.RootDot and storage.RootDot.Enabled ~= outlineVisible then
                storage.RootDot.Enabled = outlineVisible
            end
        end
    end
end

-- Single Heartbeat connection
TrackConnection(RunService.Heartbeat:Connect(UnifiedHeartbeat))

-- Initialize Br3ak3r hover highlight
createHoverHighlight()

-- Performance display update loop
local perfThread = task.spawn(function()
    while Sp3arParvus.Active do
        UpdatePerformanceDisplay()
        task.wait(0.5)
    end
end)
TrackThread(perfThread)

-- INITIALIZATION COMPLETE

print(string.format("[Sp3arParvus v%s] Loaded successfully!", VERSION))
print(string.format("[Sp3arParvus v%s] Aimbot: %s | Trigger: %s | ESP: %s",
    VERSION,
    Flags["Aimbot/AimLock"] and "ON" or "OFF",
    Flags["Aimbot/AutoFire"] and "ON" or "OFF",
    Flags["ESP/Enabled"] and "ON" or "OFF"
))
print(string.format("[Sp3arParvus v%s] Br3ak3r: %s", VERSION, Flags["Br3ak3r/Enabled"] and "ON" or "OFF"))
print(string.format("[Sp3arParvus v%s] Press RIGHT SHIFT to toggle UI visibility", VERSION))
print(string.format("[Sp3arParvus v%s] Br3ak3r Controls: Ctrl+Click=Break | Ctrl+Z=Undo | Ctrl+B=Toggle", VERSION))
print(string.format("[Sp3arParvus v%s] Distance Colors: Pink=Closest | Red≤2000 | Yellow≤4000 | Green>4000", VERSION))
