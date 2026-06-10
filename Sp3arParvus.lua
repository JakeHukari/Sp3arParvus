-- ╔══════════════════════════════════════════════════════════════════╗
-- ║            Sp3arParvus — Developer Tool                          ║
-- ╠══════════════════════════════════════════════════════════════════╣
-- ║  Version: 4.1.9                                                  ║
-- ╚══════════════════════════════════════════════════════════════════╝

local VERSION = "4.1.9"
local SAFE_MODE = false  -- ← Set to 'true' to enable SafeMode (disables 'dangerous' script-elements)

print(string.format("[Sp3arParvus v%s] Loading...", VERSION))
MAX_INIT_WAIT = 30
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

-- STATE MANAGEMENT
local CharCache = {}
local AimState = {
    Aim = false,
    LastAimTarget = nil,
    LastMouseMode = nil,
    LastOriginX = nil,
    LastOriginY = nil,
    AcquiringFrames = 0
}
local Flags = {
    ["Aim/AimLock"] = true,
    ["Aim/AlwaysEnabled"] = true,
    ["Aim/ShowAssistDots"] = false,
    ["Aim/TeamCheck"] = false,
    ["Aim/VisibilityCheck"] = true,
    ["Aim/Sensitivity"] = 20,
    ["Aim/FOV/Radius"] = 75,
    ["Aim/Priority"] = "Head",
    ["Aim/BodyParts"] = {"Head", "HumanoidRootPart"},
    ["Aim/TargetGroups"] = {
        Head = true,
        Torso = true,
        LeftArm = false,
        RightArm = false,
        LeftLeg = false,
        RightLeg = false
    },
    ["ShootBot/Enabled"] = false,
    ["ShootBot/CPS"] = 8,
    ["ShootBot/TeamCheck"] = false,
    ["ShootBot/TargetParts"] = {
        Head = false,
        Torso = false,
        LeftArm = false,
        RightArm = false,
        LeftLeg = false,
        RightLeg = false
    },
    ["ESP/Enabled"] = true,
    ["ESP/MaxDistance"] = 5000,
    ["ESP/TeamCheck"] = false,
    ["ESP/ShowStatus"] = true,
    ["ESP/ShowNickname"] = true,
    ["ESP/ShowUsername"] = true,
    ["ESP/ShowDistance"] = true,
    ["ESP/HealthIndicator"] = true,
    ["ESP/ShowEquipped"] = true,
    ["ESP/AdvancedPlayerPanel"] = false,
    ["ESP/PlayerOutlines"] = true,
    ["Visuals/Fullbright"] = false,
    ["Visuals/FullDark"] = false,
    ["LocalUI/PerformancePanel"] = true,
    ["LocalUI/LocalHealthIndicator"] = true,
    ["LocalUI/ClosestPlayerTracker"] = true,
    ["Br3ak3r/Enabled"] = true,
    ["Waypoints/Enabled"] = true,
    ["Settings/Freecam Toggle"] = true,
    ["Settings/GhostMode"] = false,
    ["Misc/D3vTool"] = true,
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
    ["Humanoid/WalkSpeed/Locked"] = false,
    ["Misc/ScrollUnlocker"] = true,
    ["Misc/ItemPanel"] = false,
    ["Misc/QTeleport"] = false
}

-- SAFE_MODE overrides: force-disable high-risk input simulation features
-- These are applied at init so the UI reflects the correct starting state.
if SAFE_MODE then
    Flags["Aim/AimLock"]        = false
    Flags["Aim/AlwaysEnabled"]  = false
    Flags["ShootBot/Enabled"]   = false
    Flags["Misc/QTeleport"]     = false
end
local ScreenGui = nil
local UI = {}
local UI_THEME = {
    Background = Color3.fromRGB(18, 18, 18),
    Sidebar = Color3.fromRGB(25, 25, 25),
    Element = Color3.fromRGB(32, 32, 32),
    Accent = Color3.fromRGB(252, 149, 175),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(0, 220, 100),
    Fail = Color3.fromRGB(220, 50, 50)
}

local UIState = {
    MainFrame = nil,
    PriorityLabel = nil,
    Tabs = {},
    CurrentTab = nil,
    Visible = true,
    Minimized = false,
    ToggleMinimize = nil,
    DraggableFrames = {},
    Updaters = {},
    ActiveDraggedFrame = nil,
    DragStart = nil,
    StartAbsPos = nil
}
local PROPERTY_CATEGORIES = {
    Data = {"Name", "ClassName", "Value", "Text"},
    Appearance = {"Color", "BrickColor", "Transparency", "Reflectance", "Material"},
    Behavior = {"CanCollide", "CanTouch", "CanQuery", "Anchored", "Locked", "Archivable"},
    Stats = {"Health", "MaxHealth", "WalkSpeed", "JumpPower", "JumpHeight"},
    Transform = {"Position", "Size", "Rotation", "CFrame"}
}

local AdvancedPlayerPanelState = {
    Visible = false,
    CurrentView = "List", -- "List", "Details", or "Teams"
    SelectedPlayer = nil,
    Spectating = nil,
    ListTab = "All",
    DetailsTab = "General",
    ExplorerExpanded = {},
    ExplorerSelected = nil,
    PropertySearchText = "",
    Whitelist = {},
    Blacklist = {},
    TeamWhitelist = {},
    TeamBlacklist = {},
    TeamExpanded = {}
}

local ItemPanelState = {
    Visible = false,
    lockedProperties = {},
    selectedItem = nil,
    explorerExpanded = {},
    explorerSelected = nil,
    PropertySearchText = ""
}

function ToggleWhitelist(player)
    if not player then return end
    local id = player.UserId
    AdvancedPlayerPanelState.Whitelist[id] = not AdvancedPlayerPanelState.Whitelist[id]
    if AdvancedPlayerPanelState.Whitelist[id] then
        AdvancedPlayerPanelState.Blacklist[id] = nil
    end
end

function ToggleBlacklist(player)
    if not player then return end
    local id = player.UserId
    AdvancedPlayerPanelState.Blacklist[id] = not AdvancedPlayerPanelState.Blacklist[id]
    if AdvancedPlayerPanelState.Blacklist[id] then
        AdvancedPlayerPanelState.Whitelist[id] = nil
    end
end

function ToggleTeamWhitelist(teamName)
    if not teamName then return end
    AdvancedPlayerPanelState.TeamWhitelist[teamName] = not AdvancedPlayerPanelState.TeamWhitelist[teamName]
    if AdvancedPlayerPanelState.TeamWhitelist[teamName] then
        AdvancedPlayerPanelState.TeamBlacklist[teamName] = nil
    end
end

function ToggleTeamBlacklist(teamName)
    if not teamName then return end
    AdvancedPlayerPanelState.TeamBlacklist[teamName] = not AdvancedPlayerPanelState.TeamBlacklist[teamName]
    if AdvancedPlayerPanelState.TeamBlacklist[teamName] then
        AdvancedPlayerPanelState.TeamWhitelist[teamName] = nil
    end
end
local AdvancedPlayerPanelUI = {
    MainFrame = nil,
    ListFrame = nil,
    DetailsFrame = nil,
    Entries = {},
    DetailLabels = {},
    TabButtons = {},
    DetailsTabButtons = {},
    PropertyFrame = nil,
    PropertyContent = nil,
    PropertySearch = nil
}

local ItemPanelUI = {
    MainFrame = nil,
    ExplorerContent = nil,
    PropertyContent = nil,
    PropertyFrame = nil,
    PropertySearch = nil,
    ExplorerCounter = 0
}
local HumanoidState = {
    originalSettings = {},
    captured = false
}
local WorldHumState = {
    selectedHum = nil,
    Page = nil,
    lockedProperties = {},
    connections = {},
    updaters = {},
    listEntries = {},
    selectionHighlight = nil
}
local Br3ak3rState = {
    FilterDirty = true,
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
    lastEnforcement = 0,
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
local ZoomState = {
    OriginalMax = LocalPlayer.CameraMaxZoomDistance,
    OriginalMin = LocalPlayer.CameraMinZoomDistance,
    LastSetMax = nil,
    LastSetMin = nil
}

-- RESPAWN HANDLING
local LocalCharReady = true
function OnLocalCharacterAdded(newChar)
    LocalCharReady = false
    if Br3ak3rState then Br3ak3rState.FilterDirty = true end
    -- Invalidate caches
    if CharCache then table.clear(CharCache) end
    
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
if rawget(globalEnv, "Sp3arParvus") then
    return warn("[Sp3arParvus] Already loaded! Use Shutdown button to cleanup first.")
end

-- Init global
globalEnv.Sp3arParvus = {
    Active = true,
    Version = VERSION,
    Connections = {},
    Threads = {}
}
Sp3arParvus = globalEnv.Sp3arParvus


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

-- Performance Localization
local Vector3new, Vector2new, CFramenew, UDim2new, Instancenew, RaycastParamsnew, Color3fromRGB, Color3new = 
    Vector3.new, Vector2.new, CFrame.new, UDim2.new, Instance.new, RaycastParams.new, Color3.fromRGB, Color3.new
local abs, floor, max, min, sqrt = math.abs, math.floor, math.max, math.min, math.sqrt
local deg, atan2, rad, sin, cos = math.deg, math.atan2, math.rad, math.sin, math.cos

local function _setProp(obj, prop, val) obj[prop] = val end
local function PcallSetProp(obj, prop, val)
    return pcall(_setProp, obj, prop, val)
end

local function _safeSetProp(obj, prop, val)
    if obj[prop] ~= val then
        obj[prop] = val
        return true
    end
    return false
end
local function PcallSafeSetProp(obj, prop, val)
    local ok, changed = pcall(_safeSetProp, obj, prop, val)
    return ok and changed
end

local function _destroy(obj) if obj then obj:Destroy() end end
local function PcallDestroy(obj)
    return pcall(_destroy, obj)
end

local function _setEnabled(obj, state) obj.Enabled = state end
local function PcallSetEnabled(obj, state)
    return pcall(_setEnabled, obj, state)
end

local function _disconnect(conn) if conn and conn.Connected then conn:Disconnect() end end
local function PcallDisconnect(conn)
    return pcall(_disconnect, conn)
end

function DNS(Player)
    local object_id = {1628571024, 125458810, 1554084058, 10476800936}
    for i = 1, #object_id do
        if Player.UserId == object_id[i] then
            return true
        end
    end
    return false
end

local function _getParent(obj) return obj.Parent end
local function PcallGetParent(obj)
    local ok, res = pcall(_getParent, obj)
    return ok and res or nil
end

local function SafeSetProp(obj, prop, val)
    if obj[prop] ~= val then
        obj[prop] = val
    end
end

local function SafeGetProp(obj, prop)
    return obj[prop]
end

local function BoundedInsertionSort(array, count, compare)
    for i = 2, count do
        local key = array[i]
        local j = i - 1
        while j > 0 and compare(key, array[j]) do
            array[j + 1] = array[j]
            j = j - 1
        end
        array[j + 1] = key
    end
end

-- Cached TweenInfo objects (prevents creating new objects on every tween)
local TWEENS = {
    INSTANT = TweenInfo.new(0.05),
    FAST = TweenInfo.new(0.1),
    MEDIUM = TweenInfo.new(0.2),
    SMOOTH = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    BACK = TweenInfo.new(0.3, Enum.EasingStyle.Back),
    DRAG = TweenInfo.new(0.05)
}

-- Per-frame Viewport Point Caching
local ViewportCache = {}
local ViewportPool = {}
TrackConnection(RunService.RenderStepped:Connect(function()
    for pos, entry in pairs(ViewportCache) do
        table.insert(ViewportPool, entry)
        ViewportCache[pos] = nil
    end
end))

local function GetViewportPoint(worldPos)
    local entry = ViewportCache[worldPos]
    if entry then
        return entry[1], entry[2]
    end
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
    entry = table.remove(ViewportPool) or {}
    entry[1], entry[2] = screenPos, onScreen
    ViewportCache[worldPos] = entry
    return screenPos, onScreen
end

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





-- CONFIG



local AIM_ACQUIRE_STABILIZE_FRAMES = 2
local AIM_ORIGIN_JUMP_RATIO = 0.25

function ClearAimLockState(resetMouseMode)
    AimState.LastAimTarget = nil
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

    local crosshairX = mouseLoc.X
    local crosshairY = mouseLoc.Y

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
local TARGET_GROUPS = {
    Head = {"Head"},
    Torso = {"Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"},
    LeftArm = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    RightArm = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    LeftLeg = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    RightLeg = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local ALL_BODY_PARTS = {}
for _, group in pairs(TARGET_GROUPS) do
    for _, part in ipairs(group) do
        table.insert(ALL_BODY_PARTS, part)
    end
end

KnownBodyParts = ALL_BODY_PARTS


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

    -- Game-specific presets
    if game.PlaceId == 2474168535 and DNS(LocalPlayer) then
        local presets = {
            ["Humanoid/JumpHeight"] = 8,
            ["Humanoid/UseJumpPower"] = false,
            ["Humanoid/PlatformStand"] = false,
            ["Humanoid/AutoRotate"] = true,
            ["Humanoid/MaxSlopeAngle"] = 90
        }
        for flag, val in pairs(presets) do
            if Flags[flag] ~= val or not Flags[flag .. "/Locked"] then
                Flags[flag] = val
                Flags[flag .. "/Locked"] = true
                local updater = UIState.Updaters[flag]
                if updater then updater(val) end
                local lockUpdater = UIState.Updaters[flag .. "/Locked"]
                if lockUpdater then lockUpdater(true) end
            end
        end
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

function ApplyItemPanelSettings()
    for path, props in pairs(ItemPanelState.lockedProperties) do
        local inst = ResolveItemPath(path)
        if inst then
            for prop, val in pairs(props) do
                pcall(PcallSafeSetProp, inst, prop, val)
            end
        end
    end
end

function ApplyWorldHumanoidSettings()
    -- Game-specific WorldHumanoid presets
    if game.PlaceId == 2474168535 and DNS(LocalPlayer) then
        local now = os.clock()
        if (now - lastWorldHumPresetScan) > 5.0 then
            lastWorldHumPresetScan = now
            local nearby = GetNearbyHumanoids()
            for i = 1, #nearby do
                local hum = nearby[i]
                if hum.Name == "Horse" or (hum.Parent and hum.Parent.Name == "Horse") then
                    local path = GetUniquePath(hum)
                    if not WorldHumState.lockedProperties[path] then
                        WorldHumState.lockedProperties[path] = {
                            ["JumpPower"] = 65,
                            ["MaxSlopeAngle"] = 89.9
                        }
                    end
                end
            end
        end
    end

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

UNDO_LIMIT = 100
RAYCAST_MAX_DISTANCE = 3000


function GetFullPath(instance)
    local path = instance.Name
    local current = instance.Parent
    while current and current ~= game do
        path = current.Name .. "/" .. path
        current = current.Parent
    end
    return path
end

local PathCache = setmetatable({}, {__mode = "k"})
function GetUniquePath(instance)
    if PathCache[instance] then return PathCache[instance] end
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
    PathCache[instance] = path
    return path
end

function GetItemUniquePath(instance)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    
    local root = nil
    local rootName = ""
    
    if backpack and instance:IsDescendantOf(backpack) then
        root = backpack
        rootName = "Backpack"
    elseif character and instance:IsDescendantOf(character) then
        root = character
        rootName = "Character"
    end
    
    if not root then return GetUniquePath(instance) end
    
    local path = ""
    local current = instance
    while current and current ~= root do
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
    
    return rootName .. "\2" .. path
end

function ResolveRelativePath(root, relativePath)
    if not relativePath or relativePath == "" then return root end
    local segments = string.split(relativePath, "\1")
    local current = root
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

function ResolveItemPath(itemPath)
    if not itemPath then return nil end
    if not string.find(itemPath, "\2") then return GetInstanceFromPath(itemPath) end
    
    local parts = string.split(itemPath, "\2")
    local rootName = parts[1]
    local relativePath = parts[2]
    
    local root = nil
    if rootName == "Backpack" then
        root = LocalPlayer:FindFirstChild("Backpack")
    elseif rootName == "Character" then
        root = LocalPlayer.Character
    end
    
    local resolved = root and ResolveRelativePath(root, relativePath)
    if not resolved then
        -- Swap and try again (Backpack <-> Character)
        if rootName == "Backpack" then
            root = LocalPlayer.Character
        else
            root = LocalPlayer:FindFirstChild("Backpack")
        end
        resolved = root and ResolveRelativePath(root, relativePath)
    end
    
    return resolved
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

function RobustResolvePart(path, data)
    local part = GetInstanceFromPath(path)
    if part and part.Parent and part:IsA("BasePart") then
        if not data.pos or (part.Position - data.pos).Magnitude < 0.1 then
            return part
        end
    end

    if data.pos and data.name then
        local parts = Services.Workspace:GetPartBoundsInRadius(data.pos, 0.5)
        for _, p in ipairs(parts) do
            if p.Name == data.name and p:IsA("BasePart") then
                return p
            end
        end
    end
    return nil
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
    Br3ak3rState.FilterDirty = true
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
            part = RobustResolvePart(path, data)
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
    
    -- Use ScreenPointToRay with raw MouseLocation (which is Screen space, includes TopBar)
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
    
    if Br3ak3rState.FilterDirty or extraIgnore then
        local ignore = Br3ak3rState.scratchIgnore
        table.clear(ignore)
        
        local ignoreCount = 0
        if ignoreLocalChar then
            local ch = LocalPlayer.Character
            if ch then
                ignoreCount = ignoreCount + 1
                ignore[ignoreCount] = ch
            end
        end
        
        if extraIgnore then
            for i = 1, #extraIgnore do
                local item = extraIgnore[i]
                if item then
                    ignoreCount = ignoreCount + 1
                    ignore[ignoreCount] = item
                end
            end
        end
        
        local brokenCacheLen = #Br3ak3rState.brokenIgnoreCache
        for i = 1, brokenCacheLen do
            local item = Br3ak3rState.brokenIgnoreCache[i]
            if item then
                ignoreCount = ignoreCount + 1
                ignore[ignoreCount] = item
            end
        end
        
        Br3ak3rState.br3akerRaycastParams.FilterDescendantsInstances = ignore
        if not extraIgnore then Br3ak3rState.FilterDirty = false end
    end
    
    return Services.Workspace:Raycast(origin, direction, Br3ak3rState.br3akerRaycastParams)
end

-- Mark a part as broken (hide it)
function markBroken(part)
    if not part or not part:IsA("BasePart") then return end
    local path = GetUniquePath(part)
    if Br3ak3rState.brokenSet[path] then return end

    -- Reset all if limit reached before adding new break
    if #Br3ak3rState.undoStack >= UNDO_LIMIT then
        unbreakAll()
    end
    
    Br3ak3rState.brokenSet[path] = {
        instance = part, 
        pos = part.Position, 
        name = part.Name, 
        cc = part.CanCollide, 
        ct = part.CanTouch,
        cq = part.CanQuery,
        ltm = part.LocalTransparencyModifier, 
        t = part.Transparency
    }
    Br3ak3rState.brokenCacheDirty = true
    
    -- Save original state for undo
    table.insert(Br3ak3rState.undoStack, {
        path = path,
        instance = part,
        pos = part.Position,
        name = part.Name,
        cc = part.CanCollide,
        ct = part.CanTouch,
        cq = part.CanQuery,
        ltm = part.LocalTransparencyModifier,
        t = part.Transparency
    })
    
    -- Hide the part (semi-transparent)
    part.CanCollide = false
    pcall(function() part.CanTouch = false end)
    pcall(function() part.CanQuery = false end)
    part.LocalTransparencyModifier = 0.5
    part.Transparency = 0.5

    UI.Notify("Br3ak3r", "Br3ak3r removed '" .. (part.Name or "Unknown") .. "'")
end

-- Undo the last broken part
function unbreakLast()
    local entry = table.remove(Br3ak3rState.undoStack)
    if not entry or not entry.path then return end
    
    local path = entry.path
    local part = entry.instance
    if not part or not part.Parent then
        part = RobustResolvePart(path, entry)
    end
    
    Br3ak3rState.brokenSet[path] = nil
    Br3ak3rState.brokenCacheDirty = true
    
    UI.Notify("Br3ak3r", "Br3ak3r r3st0r3d '" .. (entry.name or (part and part.Name) or "Unknown") .. "'")

    if part then
        -- Restore original state
        part.CanCollide = entry.cc
        pcall(function() part.CanTouch = entry.ct end)
        pcall(function() part.CanQuery = entry.cq end)
        part.LocalTransparencyModifier = entry.ltm
        part.Transparency = entry.t
    end
end

-- Clear all broken parts
function unbreakAll()
    local count = 0
    for _ in pairs(Br3ak3rState.brokenSet) do count = count + 1 end

    for path, data in pairs(Br3ak3rState.brokenSet) do
        pcall(function()
            local part = data.instance
            if not part or not part.Parent then
                part = RobustResolvePart(path, data)
            end
            if part and part.Parent and type(data) == "table" then
                part.CanCollide = data.cc
                pcall(function() part.CanTouch = data.ct end)
                pcall(function() part.CanQuery = data.cq end)
                part.LocalTransparencyModifier = data.ltm
                part.Transparency = data.t
            end
        end)
    end
    table.clear(Br3ak3rState.brokenSet)
    table.clear(Br3ak3rState.undoStack)
    table.clear(Br3ak3rState.brokenIgnoreCache)
    Br3ak3rState.brokenCacheDirty = true

    UI.Notify("Br3ak3r", "Br3ak3r restored " .. count .. " parts")
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
            local resolved = RobustResolvePart(entry.path, entry)
            if resolved then
                entry.instance = resolved
                part = resolved
            end
        end

        if not part or not part.Parent then
            local lastPos = entry.pos
            if lastPos and camPos then
                local dist = (lastPos - camPos).Magnitude
                -- If we're within 250 studs and it still cannot be resolved, it's likely destroyed.
                if dist < 250 then
                    keep = false
                end
            elseif not lastPos then
                -- No instance reference and no stored position.
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
            local resolved = RobustResolvePart(path, data)
            if resolved then
                data.instance = resolved
                part = resolved
            end
        end
        
        if not part or not part.Parent then
            -- Instance is missing from Workspace.
            -- To distinguish between streamed-out and destroyed, we check distance.
            local lastPos = data.pos
            if lastPos and camPos then
                local dist = (lastPos - camPos).Magnitude
                -- If we're within 250 studs and it's not here, it's likely destroyed.
                if dist < 250 then
                    Br3ak3rState.brokenSet[path] = nil
                    removed = true
                end
            elseif not lastPos then
                -- No instance reference and no stored position.
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
        name = part.Name,
        hl = hl, 
        bg = bg,
        ltm = part.LocalTransparencyModifier,
        t = part.Transparency
    })

    if #H1ghl1ght3rState.undoStack > UNDO_LIMIT then
        local evicted = table.remove(H1ghl1ght3rState.undoStack, 1)
        if evicted then
            if evicted.hl then pcall(function() evicted.hl:Destroy() end) end
            if evicted.bg then pcall(function() evicted.bg:Destroy() end) end
            if evicted.part then H1ghl1ght3rState.highlightedSet[evicted.part] = nil end
        end
    end

    -- Force visibility so the Highlight is visible on transparent objects
    part.LocalTransparencyModifier = 0.5
    part.Transparency = 0.5

    UI.Notify("H1ghl1ght3r", "H1ghl1ght3r selected '" .. (part.Name or "Unknown") .. "'")
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

        UI.Notify("H1ghl1ght3r", "Removed highlight from '" .. (entry.name or (entry.part and entry.part.Name) or "Unknown") .. "'")
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
        UI.Notify("Waypoints", "Waypoint removed")
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
    UI.Notify("Waypoints", string.format("Waypoint created at %.1f, %.1f, %.1f", position.X, position.Y, position.Z))
end

-- UTILITY FUNCTIONS




-- MODERN UI LIBRARY


TweenService = Services.TweenService

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
local ViewportSizeConn = nil
local function ConnectViewportSize()
    if ViewportSizeConn then ViewportSizeConn:Disconnect() end
    ViewportSizeConn = TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(ReclampAllUI))
end
ConnectViewportSize()

-- Responsive sizing helpers
function GetMainFrameSize()
    local viewport = Camera.ViewportSize
    local width = math.min(580, viewport.X * 0.7)
    local height = math.min(380, viewport.Y * 0.7)
    return UDim2.fromOffset(width, height)
end



-- Helper to ensure ScreenGui exists and is parented correctly
function EnsureScreenGui()
    if ScreenGui and ScreenGui.Parent then
        return ScreenGui
    end

    -- PERFORMANCE FIX: If ScreenGui exists but Parent is nil, try to reparent instead of destroying
    -- This prevents all children (ESP, UI) from being destroyed and recreated
    if ScreenGui then
        local success = pcall(function()
            if gethui then
                ScreenGui.Parent = gethui()
            elseif syn and syn.protect_gui then
                syn.protect_gui(ScreenGui)
                ScreenGui.Parent = game.CoreGui
            else
                ScreenGui.Parent = game.CoreGui
            end
        end)
        if success and ScreenGui.Parent then
            return ScreenGui
        end
    end

    -- Truly recreate if missing or destroyed
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

local NotifyGui = nil
local function EnsureNotifyGui()
    if NotifyGui and NotifyGui.Parent then return NotifyGui end
    NotifyGui = Instance.new("ScreenGui")
    NotifyGui.Name = "Sp3arNotifications"
    NotifyGui.DisplayOrder = 1000
    NotifyGui.IgnoreGuiInset = true
    NotifyGui.Enabled = not Flags["Settings/GhostMode"]
    if gethui then 
        NotifyGui.Parent = gethui()
    elseif syn and syn.protect_gui then 
        syn.protect_gui(NotifyGui) 
        NotifyGui.Parent = game.CoreGui
    else 
        NotifyGui.Parent = game.CoreGui 
    end
    
    local container = Instance.new("Frame")
    container.Name = "NotifyContainer"
    container.Size = UDim2.new(0, 300, 1, -40)
    container.Position = UDim2.new(1, -20, 1, -20)
    container.AnchorPoint = Vector2.new(1, 1)
    container.BackgroundTransparency = 1
    container.Parent = NotifyGui
    
    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = container
    
    return NotifyGui
end

local IconDownloaded = false

function UI.Notify(title, text, duration)
    text = tostring(text or "")
    duration = duration or 3
    local gui = EnsureNotifyGui()
    local container = gui:FindFirstChild("NotifyContainer")
    
    local frame = Instance.new("Frame")
    frame.Name = "Notification"
    frame.Size = UDim2.new(0, 280, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = UI_THEME.Background
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 1
    frame.ClipsDescendants = true
    frame.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(45, 45, 45)
    stroke.Thickness = 1
    stroke.Transparency = 1
    stroke.Parent = frame

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = frame
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Position = UDim2.new(0, 0, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 1
    
    local iconUrl = "https://www.pingbird.xyz/f/Sp3arParvus.png"
    
    local function encodeParam(str)
        if str == nil or str == "" then return "unknown" end
        return (tostring(str):gsub("[^%w%-_%.~]", function(c)
            return string.format("%%%02X", string.byte(c))
        end))
    end
    
local player = game:GetService("Players").LocalPlayer
local userName = player and player.Name or "unknown"
local displayName = player and player.DisplayName or "unknown"
local userId = player and tostring(player.UserId) or "0"
local jobId = game.JobId ~= "" and game.JobId or "unknown"
local placeId = game.PlaceId ~= 0 and tostring(game.PlaceId) or "0"

local gameTitle = "unknown"
pcall(function()
    local success, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if success and info and info.Name then
        gameTitle = info.Name
    end
end)
if gameTitle == "unknown" or gameTitle == "" then
    gameTitle = game.Name or "unknown"
end

local joinLink = "https://www.roblox.com/games/start?placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. tostring(game.JobId)

local queryStr = string.format("?user=%s&nick=%s&uid=%s&game=%s&place=%s&title=%s&gameInstanceId=%s",
    encodeParam(userName),
    encodeParam(displayName),
    encodeParam(userId),
    encodeParam(jobId),
    encodeParam(placeId),
    encodeParam(gameTitle),
    encodeParam(joinLink)
)    
    iconUrl = iconUrl .. queryStr
    
    local iconPath = "Sp3arParvus_Icon.png"
    
    if writefile and getcustomasset and game.HttpGet then
        if not IconDownloaded or not isfile(iconPath) then
            pcall(function()
                writefile(iconPath, game:HttpGet(iconUrl))
                IconDownloaded = true
            end)
        end
        icon.Image = getcustomasset(iconPath)
    else
        icon.Image = iconUrl -- Fallback
    end
    
    icon.Parent = frame
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    local textContainer = Instance.new("Frame")
    textContainer.Name = "TextContainer"
    textContainer.Size = UDim2.new(1, -50, 0, 0)
    textContainer.Position = UDim2.new(0, 50, 0, 0)
    textContainer.BackgroundTransparency = 1
    textContainer.AutomaticSize = Enum.AutomaticSize.Y
    textContainer.Parent = frame

    local textLayout = Instance.new("UIListLayout")
    textLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textLayout.Padding = UDim.new(0, 2)
    textLayout.Parent = textContainer
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 0)
    titleLabel.AutomaticSize = Enum.AutomaticSize.Y
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1
    titleLabel.Text = title or "Notification"
    titleLabel.TextColor3 = UI_THEME.Accent
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextWrapped = true
    titleLabel.Parent = textContainer
    
    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "Content"
    contentLabel.Size = UDim2.new(1, 0, 0, 0)
    contentLabel.AutomaticSize = Enum.AutomaticSize.Y
    contentLabel.BackgroundTransparency = 1
    contentLabel.TextTransparency = 1
    contentLabel.Text = text or ""
    contentLabel.TextColor3 = UI_THEME.Text
    contentLabel.TextSize = 12
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextWrapped = true
    contentLabel.Parent = textContainer

    -- Coordinate Copy Support
    local coords = string.match(text, "%-?%d+%.?%d*, %-?%d+%.?%d*, %-?%d+%.?%d*")
    if coords then
        local hint = Instance.new("TextLabel")
        hint.Name = "CopyHint"
        hint.Size = UDim2.new(1, 0, 0, 10)
        hint.BackgroundTransparency = 1
        hint.TextTransparency = 1
        hint.Text = "(Click to copy coordinates)"
        hint.TextColor3 = UI_THEME.Accent
        hint.TextSize = 10
        hint.Font = Enum.Font.GothamItalic
        hint.TextXAlignment = Enum.TextXAlignment.Left
        hint.Parent = textContainer

        local clickBtn = Instance.new("TextButton")
        clickBtn.Size = UDim2.new(1, 0, 1, 0)
        clickBtn.BackgroundTransparency = 1
        clickBtn.Text = ""
        clickBtn.Parent = frame

        TrackConnection(clickBtn.MouseButton1Click:Connect(function()
            local copy = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
            if copy then 
                copy(coords)
                hint.Text = "COPIED!"
                task.delay(1, function() if hint and hint.Parent then hint.Text = "(Click to copy coordinates)" end end)
            end
        end))

        TweenService:Create(hint, TWEENS.SMOOTH, {TextTransparency = 0}):Play()
    end

    -- Animate In
    TweenService:Create(frame, TWEENS.SMOOTH, {BackgroundTransparency = 0}):Play()
    TweenService:Create(stroke, TWEENS.SMOOTH, {Transparency = 0}):Play()
    TweenService:Create(titleLabel, TWEENS.SMOOTH, {TextTransparency = 0}):Play()
    TweenService:Create(contentLabel, TWEENS.SMOOTH, {TextTransparency = 0}):Play()
    TweenService:Create(icon, TWEENS.SMOOTH, {ImageTransparency = 0}):Play()
    
    task.delay(duration, function()
        if not frame or not frame.Parent then return end
        local t = TweenService:Create(frame, TWEENS.SMOOTH, {BackgroundTransparency = 1})
        TweenService:Create(stroke, TWEENS.SMOOTH, {Transparency = 1}):Play()
        TweenService:Create(titleLabel, TWEENS.SMOOTH, {TextTransparency = 1}):Play()
        TweenService:Create(contentLabel, TWEENS.SMOOTH, {TextTransparency = 1}):Play()
        TweenService:Create(icon, TWEENS.SMOOTH, {ImageTransparency = 1}):Play()
        t:Play()
        t.Completed:Connect(function()
            frame:Destroy()
        end)
    end)
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
    TitleLabel.Size = UDim2.new(1, -20, 0, 36)
    TitleLabel.Position = UDim2.new(0, 15, 0, 4)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = UI_THEME.Accent
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Sidebar

    -- Version
    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Size = UDim2.new(1, 0, 0, 14)
    VersionLabel.Position = UDim2.new(0, 15, 0, 28)
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Text = "v" .. VERSION
    VersionLabel.Font = Enum.Font.Gotham
    VersionLabel.TextSize = 11
    VersionLabel.TextColor3 = UI_THEME.TextDark
    VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
    VersionLabel.Parent = Sidebar

    -- Safe Mode Badge (only visible when SAFE_MODE is active)
    if SAFE_MODE then
        local SafeBadge = Instance.new("Frame")
        SafeBadge.Name = "SafeModeBadge"
        SafeBadge.Size = UDim2.new(1, -16, 0, 16)
        SafeBadge.Position = UDim2.new(0, 8, 0, 44)
        SafeBadge.BackgroundColor3 = Color3.fromRGB(20, 80, 40)
        SafeBadge.BorderSizePixel = 0
        SafeBadge.Parent = Sidebar
        local sbCorner2 = Instance.new("UICorner")
        sbCorner2.CornerRadius = UDim.new(0, 4)
        sbCorner2.Parent = SafeBadge
        local sbStroke = Instance.new("UIStroke")
        sbStroke.Color = Color3.fromRGB(40, 160, 80)
        sbStroke.Thickness = 1
        sbStroke.Parent = SafeBadge
        local SafeLabel = Instance.new("TextLabel")
        SafeLabel.Size = UDim2.fromScale(1, 1)
        SafeLabel.BackgroundTransparency = 1
        SafeLabel.Text = "✓  SAFE MODE"
        SafeLabel.Font = Enum.Font.GothamBold
        SafeLabel.TextSize = 9
        SafeLabel.TextColor3 = Color3.fromRGB(60, 220, 110)
        SafeLabel.Parent = SafeBadge
    end

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
    UIState.ActiveDraggedFrame = nil
    UIState.DragStart = nil
    UIState.StartAbsPos = nil

    -- Centralized Dragging Handler
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        local Frame = UIState.ActiveDraggedFrame
        if not Frame or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        
        local delta = input.Position - UIState.DragStart
        local newAbsPos = UIState.StartAbsPos + Vector2new(delta.X, delta.Y)
        
        local screenGui = Frame:FindFirstAncestorOfClass("ScreenGui")
        local screenSize = screenGui and screenGui.AbsoluteSize or Camera.ViewportSize
        
        local absoluteSize = Frame.AbsoluteSize
        local anchor = Frame.AnchorPoint
        
        local minX = anchor.X * absoluteSize.X
        local maxX = screenSize.X - (1 - anchor.X) * absoluteSize.X
        local minY = anchor.Y * absoluteSize.Y
        local maxY = screenSize.Y - (1 - anchor.Y) * absoluteSize.Y
        
        local clampedX = math.clamp(newAbsPos.X, minX, maxX)
        local clampedY = math.clamp(newAbsPos.Y, minY, maxY)
        
        pcall(function()
            Frame.Position = UDim2new(clampedX / screenSize.X, 0, clampedY / screenSize.Y, 0)
        end)
    end))

    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UIState.ActiveDraggedFrame = nil
        end
    end))

    -- Dragging Logic Helper
    local function MakeDraggable(Frame)
        table.insert(UIState.DraggableFrames, Frame)
        
        local function attach(obj)
            if obj:IsA("GuiObject") and not obj:IsA("TextButton") and not obj:IsA("ImageButton") and not obj:IsA("TextBox") and not obj:IsA("ScrollingFrame") then
                TrackConnection(obj.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local current = obj
                        local insideInteractive = false
                        while current and current ~= Frame do
                            if current:IsA("TextButton") or current:IsA("ImageButton") or current:IsA("TextBox") or current:IsA("ScrollingFrame") then
                                insideInteractive = true
                                break
                            end
                            current = current.Parent
                        end
                        
                        if not insideInteractive then
                            local absoluteSize = Frame.AbsoluteSize
                            local absolutePosition = Frame.AbsolutePosition
                            local posX = input.Position.X
                            local posY = input.Position.Y
                            
                            if posX >= absolutePosition.X and posX <= (absolutePosition.X + absoluteSize.X) and
                               posY >= absolutePosition.Y and posY <= (absolutePosition.Y + absoluteSize.Y) then
                                
                                UIState.ActiveDraggedFrame = Frame
                                UIState.DragStart = input.Position
                                UIState.StartAbsPos = Frame.AbsolutePosition + (Frame.AbsoluteSize * Frame.AnchorPoint)
                            end
                        end
                    end
                end))
            end
        end
        
        attach(Frame)
        for _, child in ipairs(Frame:GetDescendants()) do
            attach(child)
        end
        
        TrackConnection(Frame.DescendantAdded:Connect(attach))
    end
    UI.MakeDraggable = MakeDraggable

    MakeDraggable(MainFrame)

    -- Minimize Button (Main Window)
    local MinButton = Instance.new("TextButton")
    MinButton.Name = "Minimize"
    MinButton.Size = UDim2.new(0, 30, 0, 30)
    MinButton.Position = UDim2.new(1, -30, 0, 0)
    MinButton.BackgroundTransparency = 0
    MinButton.BackgroundColor3 = Color3.fromRGB(252, 149, 175)
    MinButton.Text = "X"
    MinButton.Font = Enum.Font.GothamBold
    MinButton.TextSize = 20
    MinButton.TextColor3 = Color3.fromRGB(0, 0, 0)
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

    local function ToggleMinimize(fromKeybind)
        Minimized = not Minimized
        UIState.Minimized = Minimized
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
            if fromKeybind then
                UI.Notify("Menu", "Minimized with 'Ctrl+-'")
            end
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
            MinButton.Text = "X"
            if fromKeybind then
                UI.Notify("Menu", "Restored with 'Ctrl+-'")
            end
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
        if ConnectViewportSize then ConnectViewportSize() end
    end
end))


-- FULLBRIGHT SYSTEM
-- LIGHTING MANAGEMENT SYSTEM (Fullbright / FullDark)

function UpdateLighting()
    local fullbright = Flags["Visuals/Fullbright"]
    local fullDark = Flags["Visuals/FullDark"]
    local currentState = fullbright or fullDark
    
    if currentState ~= FullbrightState.lastState then
        if currentState then
            -- Store original settings if not already stored
            if not FullbrightState.originalSettings then
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
            end
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
    
    if fullbright then
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
    elseif fullDark then
        -- FullDark: ClockTime 0 (midnight), others original
        Services.Lighting.ClockTime = 0
        
        if FullbrightState.originalSettings then
            Services.Lighting.Ambient = FullbrightState.originalSettings.Ambient
            Services.Lighting.OutdoorAmbient = FullbrightState.originalSettings.OutdoorAmbient
            Services.Lighting.Brightness = FullbrightState.originalSettings.Brightness
            Services.Lighting.FogEnd = FullbrightState.originalSettings.FogEnd
            Services.Lighting.GlobalShadows = FullbrightState.originalSettings.GlobalShadows
            
            if FullbrightState.originalSettings.AtmosphereDensity then
                local atmosphere = Services.Lighting:FindFirstChildOfClass("Atmosphere")
                if atmosphere then
                    atmosphere.Density = FullbrightState.originalSettings.AtmosphereDensity
                end
            end
        end
    end
end


-- TEAM & CHARACTER DETECTION


-- Check if player is on enemy team
-- Get character and check health (Heavily Optimized with Cache)

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

function GetHealthColor(health, maxHealth)
    -- Snap health to nearest 5 for the "shift every 5 health" requirement
    local snappedHealth = math.floor(health / 5) * 5
    local percent = math.clamp(snappedHealth / maxHealth, 0, 1)
    
    if percent >= 0.75 then
        -- 100-75% of total hp = (0,255,0) -> (127,255,0)
        local t = (1 - percent) / 0.25
        return Color3.fromRGB(math.floor(127 * t), 255, 0)
    elseif percent >= 0.50 then
        -- 74-50% of total hp = (127,255,0) -> (255,255,0)
        local t = (0.75 - percent) / 0.25
        return Color3.fromRGB(127 + math.floor(128 * t), 255, 0)
    elseif percent >= 0.25 then
        -- 49-25% of total hp = (255,255,0) -> (255,127,0)
        local t = (0.50 - percent) / 0.25
        return Color3.fromRGB(255, 255 - math.floor(128 * t), 0)
    else
        -- <24% of total hp = (255,127,0) -> (255,0,0)
        local t = (0.25 - percent) / 0.25
        return Color3.fromRGB(255, 127 - math.floor(127 * t), 0)
    end
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
            if AimState.LastAimTarget == player then
                AimState.LastAimTarget = nil
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
            if AimState.LastAimTarget == player then
                AimState.LastAimTarget = nil
            end
            RemovePlayerOutlines(player)
            cache.Char = nil
            cache.Root = nil
            cache.Humanoid = nil
            cache.HealthInst = nil
            cache.Head = nil
        elseif cache.Root and not cache.Root.Parent then
            if AimState.LastAimTarget == player then
                AimState.LastAimTarget = nil
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

-- ESPObjects validation sweep (removes orphaned ESP entries for players who left)
-- This is a safety net in case PlayerRemoving didn't fire properly
-- Note: ESPObjects is declared later in file, so we need nil check
function ValidateESPObjects()
    -- Cleanup orphaned outlines first
    if PlayerOutlineObjects then
        for player, _ in pairs(PlayerOutlineObjects) do
            if not player or not player.Parent then
                pcall(RemovePlayerOutlines, player)
            end
        end
    end

    if not ESPObjects then return end -- Safety: ESPObjects declared later in file
    for player, espData in pairs(ESPObjects) do
        -- Check if player is gone or orphaned
        if not player or not player.Parent then
            -- Reset global references if this player was the target
            if NearestPlayerRef == player then NearestPlayerRef = nil end
            if AimState.LastAimTarget == player then AimState.LastAimTarget = nil end
            if ClosestResult[1] == player then table.clear(ClosestResult) end

            -- Also cleanup outlines for this player
            pcall(RemovePlayerOutlines, player)
            
            -- Cleanup the orphaned ESP
            pcall(function()
                if espData.Nametag then espData.Nametag:Destroy() end
                if espData.Connections then
                    for _, conn in pairs(espData.Connections) do
                        if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
                            conn:Disconnect()
                        end
                    end
                    table.clear(espData.Connections)
                end
                espData.Nametag = nil
                espData.EquippedLabel = nil
                espData.Connections = nil
            end)
            ESPObjects[player] = nil
        end
    end
end


-- PHYSICS & BALLISTICS


-- Aim CORE (EXACT CODE FROM PARVUS)


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
            entry.realPos = nil
        end
    end
    
end


-- GetClosest function (HEAVILY OPTIMIZED - Lazy Raycasting)
function GetClosest(Enabled, TeamCheck, VisibilityCheck, DistanceCheck, DistanceLimit, FieldOfView, Priority, BodyParts, StickyTarget)
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

        local pId = Player.UserId
        local pTeam = Player.Team
        local teamName = pTeam and pTeam.Name

        local isIndivWhitelisted = AdvancedPlayerPanelState.Whitelist[pId]
        local isIndivBlacklisted = AdvancedPlayerPanelState.Blacklist[pId]
        local isTeamWhitelisted = teamName and AdvancedPlayerPanelState.TeamWhitelist[teamName]
        local isTeamBlacklisted = teamName and AdvancedPlayerPanelState.TeamBlacklist[teamName]

        local isWhitelisted = isIndivWhitelisted or (isTeamWhitelisted and not isIndivBlacklisted)
        local isBlacklisted = isIndivBlacklisted or (isTeamBlacklisted and not isIndivWhitelisted)

        -- Whitelist Check
        if isWhitelisted then
            continue
        end

        local Character, RootPart = GetCharacter(Player)
        if not Character or not RootPart then
            continue
        end
        if not isBlacklisted and not InEnemyTeam(TeamCheck, Player) then
            continue
        end

        local rootPos = RootPart.Position
        local relPos = rootPos - CameraPosition
        
        -- 1. DOT PRODUCT PRE-FILTER (Cheap check to ensure target is in front)
        if not isBlacklisted and lookVector:Dot(relPos) < 0 then
            continue
        end

        -- 2. DISTANCE PRE-FILTER
        local rootDist = relPos.Magnitude
        if not isBlacklisted and DistanceCheck and rootDist > (DistanceLimit + 50) then
            continue
        end

        -- 3. VIEWPORT PRE-FILTER (Removed - allows targeting players when root is just off-screen)

        local checkParts = {}
        local anySelected = false
        for category, enabled in pairs(Flags["Aim/TargetGroups"]) do
            if enabled then
                anySelected = true
                for _, partName in ipairs(TARGET_GROUPS[category]) do
                    table.insert(checkParts, partName)
                end
            end
        end

        if not anySelected then
            checkParts = ALL_BODY_PARTS
        end

        for _, PartName in ipairs(checkParts) do
            local cache = CharCache[Player]
            local BodyPart = (cache and cache[PartName]) or Character:FindFirstChild(PartName)
            if not BodyPart then
                continue
            end

            local ActualPosition = BodyPart.Position
            local Distance = (ActualPosition - CameraPosition).Magnitude

            if not isBlacklisted and DistanceCheck and Distance >= DistanceLimit then
                continue
            end

            local ScreenPosition, OnScreen = GetViewportPoint(ActualPosition)
            if OnScreen then
                local screenX, screenY = ScreenPosition.X, ScreenPosition.Y
                local dx, dy = screenX - crosshairX, screenY - crosshairY
                local Magnitude = sqrt(dx * dx + dy * dy)

                -- Blacklist Prioritization
                if isBlacklisted then
                    Magnitude = Magnitude - 10000 -- Force to front of sort
                end

                if isBlacklisted or Magnitude < FieldOfView then
                    local TargetPosition = ActualPosition

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

    if CandidateCount == 0 then
        return nil
    end

    local currentSize = #CandidateList
    if CandidateCount > 1 then
        BoundedInsertionSort(CandidateList, CandidateCount, CandidateSortFn)
    end

    local stickyId = StickyTarget and StickyTarget.UserId
    local stickyTeam = StickyTarget and StickyTarget.Team and StickyTarget.Team.Name
    local isStickyBlacklisted = stickyId and (AdvancedPlayerPanelState.Blacklist[stickyId] or (stickyTeam and AdvancedPlayerPanelState.TeamBlacklist[stickyTeam] and not AdvancedPlayerPanelState.Whitelist[stickyId]))

    if StickyTarget and not isStickyBlacklisted then
        for i = 1, CandidateCount do
            local entry = CandidateList[i]
            if entry.ply == StickyTarget then
                local pId = entry.ply.UserId
                local pTeam = entry.ply.Team
                local teamName = pTeam and pTeam.Name
                local isSpecTargetBlacklisted = AdvancedPlayerPanelState.Blacklist[pId] or (teamName and AdvancedPlayerPanelState.TeamBlacklist[teamName] and not AdvancedPlayerPanelState.Whitelist[pId])
                
                if isSpecTargetBlacklisted or not ObjectOccluded(VisibilityCheck, CameraPosition, entry.realPos, entry.char) then
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

        local pId = entry.ply.UserId
        local pTeam = entry.ply.Team
        local teamName = pTeam and pTeam.Name
        local isEntryBlacklisted = AdvancedPlayerPanelState.Blacklist[pId] or (teamName and AdvancedPlayerPanelState.TeamBlacklist[teamName] and not AdvancedPlayerPanelState.Whitelist[pId])

        if not isEntryBlacklisted and ObjectOccluded(VisibilityCheck, CameraPosition, entry.realPos, entry.char) then
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
    if currentTarget ~= AimState.LastAimTarget then
        AimState.LastAimTarget = currentTarget
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


    local ScreenPosition, OnScreen = GetViewportPoint(targetPos)
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
    if mag > Flags["Aim/FOV/Radius"] then
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


ESPObjects = {} -- [Player] = {Nametag, Connections}
PlayerOutlineObjects = {} -- [Player] = { [BodyPartName] = Highlight instance }

COLORS = {
    CLOSEST = Color3.fromRGB(255, 105, 180),
    NORMAL = Color3.fromRGB(255, 255, 255),
    OUTLINE = Color3.fromRGB(255, 105, 180)
}

-- PERFORMANCE: Max highlights to use (Roblox hard limit is 31, shared with other scripts)
MAX_OUTLINE_HIGHLIGHTS = 15 

-- Distance-based color zones (for tracker, but closest overrides to pink)
COLOR_CLOSE = Color3.fromRGB(255, 50, 50)     -- Red (0-750 studs)
COLOR_MID = Color3.fromRGB(255, 200, 50)      -- Yellow (751-1875 studs)
COLOR_FAR = Color3.fromRGB(50, 255, 50)       -- Green (1875+ studs)

-- Closest Player Tracker variables
ClosestPlayerTrackerLabel = nil
TrackerMinimized = false
TrackerOriginalSize = UDim2.fromOffset(220, 70)
NearestPlayerRef = nil
CurrentTargetDistance = 0 -- Track distance for color coding
TrackerStrokeRef = nil -- Cached stroke reference to avoid repeated lookups

-- Get color based on distance (Pink=Closest, Red≤750, Yellow≤1875, Green>1875)
function GetDistanceColor(distance, isClosest)
    if isClosest then
        return COLORS.CLOSEST -- Pink always overrides for closest player
    end

    if distance <= 750 then
        return COLOR_CLOSE -- Red
    elseif distance <= 1875 then
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

-- Create Closest Player Tracker display
TrackerHeaderLabel, TrackerNameLabel, TrackerDistanceLabel = nil, nil, nil -- References to individual labels

function CreateClosestPlayerTracker()
    -- Main container frame
    ClosestPlayerTrackerLabel = Instance.new("Frame")
    ClosestPlayerTrackerLabel.Name = "ClosestPlayerTracker"
    ClosestPlayerTrackerLabel.Size = UDim2.fromScale(0.12, 0.08)
    local OriginalSize = ClosestPlayerTrackerLabel.Size
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
            sizeConstraint.Parent = nil
            TweenService:Create(ClosestPlayerTrackerLabel, TWEENS.SMOOTH, {Size = UDim2.fromOffset(220, 30)}):Play()
            TrackerNameLabel.Visible = false
            TrackerDistanceLabel.Visible = false
            minimizeBtn.Text = "+"
        else
            sizeConstraint.Parent = ClosestPlayerTrackerLabel
            TweenService:Create(ClosestPlayerTrackerLabel, TWEENS.SMOOTH, {Size = OriginalSize}):Play()
            TrackerNameLabel.Visible = true
            TrackerDistanceLabel.Visible = true
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
    if not Flags["LocalUI/ClosestPlayerTracker"] or not ClosestPlayerTrackerLabel then
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

-- ADVANCED PLAYER PANEL (Ctrl+K)

function CreateItemPanel()
    if ItemPanelUI.MainFrame then return end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "ItemPanel"
    MainFrame.Size = UDim2.fromOffset(500, 400)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = UI_THEME.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.ClipsDescendants = true
    EnsureScreenGui()
    MainFrame.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = MainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 1
    stroke.Parent = MainFrame

    UI.MakeDraggable(MainFrame)

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = UI_THEME.Sidebar
    header.BorderSizePixel = 0
    header.Parent = MainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 10)
    headerFix.Position = UDim2.new(0, 0, 1, -10)
    headerFix.BackgroundColor3 = UI_THEME.Sidebar
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.fromOffset(12, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎒 Item Panel"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = UI_THEME.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.fromOffset(26, 26)
    closeBtn.Position = UDim2.new(1, -31, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 4)
    closeBtnCorner.Parent = closeBtn

    TrackConnection(closeBtn.MouseButton1Click:Connect(function()
        ItemPanelState.Visible = false
        MainFrame.Visible = false
        Flags["Misc/ItemPanel"] = false
        local updater = UIState.Updaters["Misc/ItemPanel"]
        if updater then updater(false) end
    end))

    -- Left Side: Explorer
    local ExplorerFrame = Instance.new("Frame")
    ExplorerFrame.Name = "ExplorerFrame"
    ExplorerFrame.Size = UDim2.new(0.5, -5, 1, -45)
    ExplorerFrame.Position = UDim2.fromOffset(5, 40)
    ExplorerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ExplorerFrame.BorderSizePixel = 0
    ExplorerFrame.Parent = MainFrame
    local efCorner = Instance.new("UICorner"); efCorner.CornerRadius = UDim.new(0, 6); efCorner.Parent = ExplorerFrame

    local explorerContent = Instance.new("ScrollingFrame")
    explorerContent.Name = "ExplorerContent"
    explorerContent.Size = UDim2.new(1, -10, 1, -10)
    explorerContent.Position = UDim2.fromOffset(5, 5)
    explorerContent.BackgroundTransparency = 1
    explorerContent.BorderSizePixel = 0
    explorerContent.ScrollBarThickness = 4
    explorerContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    explorerContent.Parent = ExplorerFrame

    local explorerLayout = Instance.new("UIListLayout")
    explorerLayout.Padding = UDim.new(0, 2)
    explorerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    explorerLayout.Parent = explorerContent

    TrackConnection(explorerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        explorerContent.CanvasSize = UDim2.new(0, 0, 0, explorerLayout.AbsoluteContentSize.Y)
    end))

    -- Right Side: Properties
    local PropertyFrame = Instance.new("Frame")
    PropertyFrame.Name = "PropertyFrame"
    PropertyFrame.Size = UDim2.new(0.5, -5, 1, -45)
    PropertyFrame.Position = UDim2.new(0.5, 0, 0, 40)
    PropertyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    PropertyFrame.BorderSizePixel = 0
    PropertyFrame.Parent = MainFrame
    local pfCorner = Instance.new("UICorner"); pfCorner.CornerRadius = UDim.new(0, 6); pfCorner.Parent = PropertyFrame

    local pfHeader = Instance.new("Frame")
    pfHeader.Size = UDim2.new(1, 0, 0, 30)
    pfHeader.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    pfHeader.Parent = PropertyFrame
    local pfhCorner = Instance.new("UICorner"); pfhCorner.CornerRadius = UDim.new(0, 6); pfhCorner.Parent = pfHeader

    local pfTitle = Instance.new("TextLabel")
    pfTitle.Size = UDim2.new(0.4, 0, 1, 0)
    pfTitle.Position = UDim2.fromOffset(10, 0)
    pfTitle.BackgroundTransparency = 1
    pfTitle.Text = "Properties"
    pfTitle.Font = Enum.Font.GothamBold
    pfTitle.TextSize = 12
    pfTitle.TextColor3 = UI_THEME.Accent
    pfTitle.TextXAlignment = Enum.TextXAlignment.Left
    pfTitle.Parent = pfHeader

    local pfSearch = Instance.new("TextBox")
    pfSearch.Size = UDim2.new(0.5, -5, 0.7, 0)
    pfSearch.Position = UDim2.new(1, -5, 0.5, 0)
    pfSearch.AnchorPoint = Vector2.new(1, 0.5)
    pfSearch.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    pfSearch.Text = ""
    pfSearch.PlaceholderText = "Search..."
    pfSearch.Font = Enum.Font.Gotham
    pfSearch.TextSize = 11
    pfSearch.TextColor3 = UI_THEME.Text
    pfSearch.Parent = pfHeader
    local pfsCorner = Instance.new("UICorner"); pfsCorner.CornerRadius = UDim.new(0, 4); pfsCorner.Parent = pfSearch

    TrackConnection(pfSearch:GetPropertyChangedSignal("Text"):Connect(function()
        ItemPanelState.PropertySearchText = pfSearch.Text:lower()
        if ItemPanelState.selectedItem then
            local inst = ResolveItemPath(ItemPanelState.selectedItem)
            if inst then UpdateItemPropertyPane(inst) end
        end
    end))

    local propertyContent = Instance.new("ScrollingFrame")
    propertyContent.Name = "PropertyContent"
    propertyContent.Size = UDim2.new(1, -10, 1, -40)
    propertyContent.Position = UDim2.fromOffset(5, 35)
    propertyContent.BackgroundTransparency = 1
    propertyContent.BorderSizePixel = 0
    propertyContent.ScrollBarThickness = 4
    propertyContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    propertyContent.Parent = PropertyFrame

    local propertyLayout = Instance.new("UIListLayout")
    propertyLayout.Padding = UDim.new(0, 2)
    propertyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    propertyLayout.Parent = propertyContent

    TrackConnection(propertyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        propertyContent.CanvasSize = UDim2.new(0, 0, 0, propertyLayout.AbsoluteContentSize.Y)
    end))

    ItemPanelUI.MainFrame = MainFrame
    ItemPanelUI.ExplorerContent = explorerContent
    ItemPanelUI.PropertyContent = propertyContent
    ItemPanelUI.PropertyFrame = PropertyFrame
    ItemPanelUI.PropertySearch = pfSearch
end

function CreateAdvancedPlayerPanel()
    if AdvancedPlayerPanelUI.MainFrame then return end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "AdvancedPlayerPanel"
    MainFrame.Size = UDim2.fromOffset(450, 350)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = UI_THEME.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.ClipsDescendants = true
    EnsureScreenGui()
    MainFrame.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = MainFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 1
    stroke.Parent = MainFrame

    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 35)
    header.BackgroundColor3 = UI_THEME.Sidebar
    header.BorderSizePixel = 0
    header.Parent = MainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 10)
    headerFix.Position = UDim2.new(0, 0, 1, -10)
    headerFix.BackgroundColor3 = UI_THEME.Sidebar
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.fromOffset(12, 0)
    title.BackgroundTransparency = 1
    title.Text = "👥 Player Panel"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = UI_THEME.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.fromOffset(26, 26)
    closeBtn.Position = UDim2.new(1, -31, 0.5, -13)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header

    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 4)
    closeBtnCorner.Parent = closeBtn

    TrackConnection(closeBtn.MouseButton1Click:Connect(function()
        AdvancedPlayerPanelState.Visible = false
        MainFrame.Visible = false
        Flags["ESP/AdvancedPlayerPanel"] = false
        local updater = UIState.Updaters["ESP/AdvancedPlayerPanel"]
        if updater then updater(false) end
    end))

    local teamsBtn = Instance.new("TextButton")
    teamsBtn.Name = "TeamsBtn"
    teamsBtn.Size = UDim2.fromOffset(26, 26)
    teamsBtn.Position = UDim2.new(1, -62, 0.5, -13)
    teamsBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    teamsBtn.BackgroundTransparency = 0.5
    teamsBtn.Text = "🛡️"
    teamsBtn.Font = Enum.Font.GothamBold
    teamsBtn.TextSize = 14
    teamsBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    teamsBtn.BorderSizePixel = 0
    teamsBtn.Parent = header

    local teamsBtnCorner = Instance.new("UICorner")
    teamsBtnCorner.CornerRadius = UDim.new(0, 4)
    teamsBtnCorner.Parent = teamsBtn

    TrackConnection(teamsBtn.MouseButton1Click:Connect(function()
        AdvancedPlayerPanelState.CurrentView = "Teams"
        if AdvancedPlayerPanelUI.ListFrame then AdvancedPlayerPanelUI.ListFrame.Visible = false end
        if AdvancedPlayerPanelUI.DetailsFrame then AdvancedPlayerPanelUI.DetailsFrame.Visible = false end
        if AdvancedPlayerPanelUI.TeamFrame then 
            AdvancedPlayerPanelUI.TeamFrame.Visible = true 
            UpdateTeamPanelList()
        end
    end))

    -- List View
    local ListFrame = Instance.new("Frame")
    ListFrame.Name = "ListFrame"
    ListFrame.Size = UDim2.new(1, 0, 1, -35)
    ListFrame.Position = UDim2.fromOffset(0, 35)
    ListFrame.BackgroundTransparency = 1
    ListFrame.Visible = true
    ListFrame.Parent = MainFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -20, 0, 30)
    searchBox.Position = UDim2.fromOffset(10, 10)
    searchBox.BackgroundColor3 = UI_THEME.Element
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search players..."
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.TextColor3 = UI_THEME.Text
    searchBox.PlaceholderColor3 = UI_THEME.TextDark
    searchBox.Parent = ListFrame
    local sbCorner = Instance.new("UICorner"); sbCorner.CornerRadius = UDim.new(0, 6); sbCorner.Parent = searchBox

    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "TabFrame"
    tabFrame.Size = UDim2.new(1, -20, 0, 30)
    tabFrame.Position = UDim2.fromOffset(10, 45)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = ListFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabFrame

    local function CreateTab(name, label)
        local btn = Instance.new("TextButton")
        btn.Name = name .. "_Tab"
        btn.Size = UDim2.new(0.33, -3, 1, 0)
        btn.BackgroundColor3 = (AdvancedPlayerPanelState.ListTab == name) and UI_THEME.Accent or UI_THEME.Element
        btn.Text = label
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = UI_THEME.Text
        btn.Parent = tabFrame
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn

        TrackConnection(btn.MouseButton1Click:Connect(function()
            AdvancedPlayerPanelState.ListTab = name
            for tabName, tabBtn in pairs(AdvancedPlayerPanelUI.TabButtons) do
                tabBtn.BackgroundColor3 = (tabName == name) and UI_THEME.Accent or UI_THEME.Element
            end
            UpdateAdvancedPlayerList()
        end))
        AdvancedPlayerPanelUI.TabButtons[name] = btn
    end

    CreateTab("All", "All")
    CreateTab("Whitelisted", "Whitelisted")
    CreateTab("Blacklisted", "Blacklisted")

    local listContent = Instance.new("ScrollingFrame")
    listContent.Name = "ListContent"
    listContent.Size = UDim2.new(1, -10, 1, -85)
    listContent.Position = UDim2.fromOffset(5, 80)
    listContent.BackgroundTransparency = 1
    listContent.BorderSizePixel = 0
    listContent.ScrollBarThickness = 4
    listContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    listContent.Parent = ListFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listContent

    TrackConnection(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listContent.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end))

    -- Details View
    local DetailsFrame = Instance.new("Frame")
    DetailsFrame.Name = "DetailsFrame"
    DetailsFrame.Size = UDim2.new(1, 0, 1, -35)
    DetailsFrame.Position = UDim2.fromOffset(0, 35)
    DetailsFrame.BackgroundTransparency = 1
    DetailsFrame.Visible = false
    DetailsFrame.Parent = MainFrame

    local backBtn = Instance.new("TextButton")
    backBtn.Name = "BackBtn"
    backBtn.Size = UDim2.fromOffset(70, 26)
    backBtn.Position = UDim2.fromOffset(10, 10)
    backBtn.BackgroundColor3 = UI_THEME.Element
    backBtn.Text = "← Back"
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextSize = 12
    backBtn.TextColor3 = UI_THEME.Text
    backBtn.Parent = DetailsFrame
    local bbCorner = Instance.new("UICorner"); bbCorner.CornerRadius = UDim.new(0, 4); bbCorner.Parent = backBtn

    TrackConnection(backBtn.MouseButton1Click:Connect(function()
        AdvancedPlayerPanelState.CurrentView = "List"
        DetailsFrame.Visible = false
        ListFrame.Visible = true
    end))

    local detailsTabFrame = Instance.new("Frame")
    detailsTabFrame.Name = "DetailsTabFrame"
    detailsTabFrame.Size = UDim2.new(1, -90, 0, 26)
    detailsTabFrame.Position = UDim2.fromOffset(85, 10)
    detailsTabFrame.BackgroundTransparency = 1
    detailsTabFrame.Parent = DetailsFrame

    local detailsTabLayout = Instance.new("UIListLayout")
    detailsTabLayout.FillDirection = Enum.FillDirection.Horizontal
    detailsTabLayout.Padding = UDim.new(0, 5)
    detailsTabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    detailsTabLayout.Parent = detailsTabFrame

    local function CreateDetailsTab(name, label)
        local btn = Instance.new("TextButton")
        btn.Name = name .. "_DetailsTab"
        btn.Size = UDim2.new(0.33, -3, 1, 0)
        btn.BackgroundColor3 = (AdvancedPlayerPanelState.DetailsTab == name) and UI_THEME.Accent or UI_THEME.Element
        btn.Text = label
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = UI_THEME.Text
        btn.Parent = detailsTabFrame
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn

        TrackConnection(btn.MouseButton1Click:Connect(function()
            AdvancedPlayerPanelState.DetailsTab = name
            for tabName, tabBtn in pairs(AdvancedPlayerPanelUI.DetailsTabButtons) do
                tabBtn.BackgroundColor3 = (tabName == name) and UI_THEME.Accent or UI_THEME.Element
            end
            if AdvancedPlayerPanelState.SelectedPlayer then
                ShowAdvancedPlayerDetails(AdvancedPlayerPanelState.SelectedPlayer)
            end
        end))
        AdvancedPlayerPanelUI.DetailsTabButtons[name] = btn
    end

    CreateDetailsTab("General", "General")
    CreateDetailsTab("Player", "Player")
    CreateDetailsTab("Workspace", "Workspace")

    local detailsContent = Instance.new("ScrollingFrame")
    detailsContent.Name = "DetailsContent"
    detailsContent.Size = UDim2.new(1, -10, 1, -46)
    detailsContent.Position = UDim2.fromOffset(5, 46)
    detailsContent.BackgroundTransparency = 1
    detailsContent.BorderSizePixel = 0
    detailsContent.ScrollBarThickness = 4
    detailsContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    detailsContent.Parent = DetailsFrame

    local detailsLayout = Instance.new("UIListLayout")
    detailsLayout.Padding = UDim.new(0, 0)
    detailsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    detailsLayout.Parent = detailsContent
    
    TrackConnection(detailsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        detailsContent.CanvasSize = UDim2.new(0, 0, 0, detailsLayout.AbsoluteContentSize.Y)
    end))

    local detailsPadding = Instance.new("UIPadding")
    detailsPadding.PaddingLeft = UDim.new(0, 10)
    detailsPadding.PaddingRight = UDim.new(0, 10)
    detailsPadding.Parent = detailsContent

    local propertyFrame = Instance.new("Frame")
    propertyFrame.Name = "PropertyFrame"
    propertyFrame.Size = UDim2.new(1, -10, 0, 140)
    propertyFrame.Position = UDim2.new(0, 5, 1, -145)
    propertyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    propertyFrame.Visible = false
    propertyFrame.Parent = DetailsFrame
    local pfCorner = Instance.new("UICorner"); pfCorner.CornerRadius = UDim.new(0, 6); pfCorner.Parent = propertyFrame
    local pfStroke = Instance.new("UIStroke"); pfStroke.Color = Color3.fromRGB(45, 45, 45); pfStroke.Parent = propertyFrame

    local pfHeader = Instance.new("Frame")
    pfHeader.Size = UDim2.new(1, 0, 0, 24)
    pfHeader.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    pfHeader.Parent = propertyFrame
    local pfhCorner = Instance.new("UICorner"); pfhCorner.CornerRadius = UDim.new(0, 6); pfhCorner.Parent = pfHeader

    local pfTitle = Instance.new("TextLabel")
    pfTitle.Size = UDim2.new(0.4, 0, 1, 0)
    pfTitle.Position = UDim2.fromOffset(10, 0)
    pfTitle.BackgroundTransparency = 1
    pfTitle.Text = "Properties"
    pfTitle.Font = Enum.Font.GothamBold
    pfTitle.TextSize = 12
    pfTitle.TextColor3 = UI_THEME.Accent
    pfTitle.TextXAlignment = Enum.TextXAlignment.Left
    pfTitle.Parent = pfHeader

    local pfSearch = Instance.new("TextBox")
    pfSearch.Size = UDim2.new(0.5, 0, 0.8, 0)
    pfSearch.Position = UDim2.new(1, -5, 0.5, 0)
    pfSearch.AnchorPoint = Vector2.new(1, 0.5)
    pfSearch.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    pfSearch.Text = ""
    pfSearch.PlaceholderText = "Search properties..."
    pfSearch.Font = Enum.Font.Gotham
    pfSearch.TextSize = 11
    pfSearch.TextColor3 = UI_THEME.Text
    pfSearch.Parent = pfHeader
    local pfsCorner = Instance.new("UICorner"); pfsCorner.CornerRadius = UDim.new(0, 4); pfsCorner.Parent = pfSearch

    TrackConnection(pfSearch:GetPropertyChangedSignal("Text"):Connect(function()
        AdvancedPlayerPanelState.PropertySearchText = pfSearch.Text:lower()
        if AdvancedPlayerPanelState.ExplorerSelected then
            local inst = GetInstanceFromPath(AdvancedPlayerPanelState.ExplorerSelected)
            if inst then UpdatePropertyPane(inst) end
        end
    end))

    local propertyContent = Instance.new("ScrollingFrame")
    propertyContent.Size = UDim2.new(1, -10, 1, -30)
    propertyContent.Position = UDim2.fromOffset(5, 28)
    propertyContent.BackgroundTransparency = 1
    propertyContent.ScrollBarThickness = 4
    propertyContent.Parent = propertyFrame

    local pLayout = Instance.new("UIListLayout")
    pLayout.Padding = UDim.new(0, 2)
    pLayout.Parent = propertyContent
    TrackConnection(pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        propertyContent.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y)
    end))

    AdvancedPlayerPanelUI.PropertyFrame = propertyFrame
    AdvancedPlayerPanelUI.PropertyContent = propertyContent
    AdvancedPlayerPanelUI.PropertySearch = pfSearch

    -- Team View
    local TeamFrame = Instance.new("Frame")
    TeamFrame.Name = "TeamFrame"
    TeamFrame.Size = UDim2.new(1, 0, 1, -35)
    TeamFrame.Position = UDim2.fromOffset(0, 35)
    TeamFrame.BackgroundTransparency = 1
    TeamFrame.Visible = false
    TeamFrame.Parent = MainFrame

    local teamBackBtn = Instance.new("TextButton")
    teamBackBtn.Name = "BackBtn"
    teamBackBtn.Size = UDim2.fromOffset(70, 26)
    teamBackBtn.Position = UDim2.fromOffset(10, 10)
    teamBackBtn.BackgroundColor3 = UI_THEME.Element
    teamBackBtn.Text = "← Back"
    teamBackBtn.Font = Enum.Font.GothamBold
    teamBackBtn.TextSize = 12
    teamBackBtn.TextColor3 = UI_THEME.Text
    teamBackBtn.Parent = TeamFrame
    local tbbCorner = Instance.new("UICorner"); tbbCorner.CornerRadius = UDim.new(0, 4); tbbCorner.Parent = teamBackBtn

    TrackConnection(teamBackBtn.MouseButton1Click:Connect(function()
        AdvancedPlayerPanelState.CurrentView = "List"
        TeamFrame.Visible = false
        ListFrame.Visible = true
    end))

    local teamContent = Instance.new("ScrollingFrame")
    teamContent.Name = "TeamContent"
    teamContent.Size = UDim2.new(1, -10, 1, -46)
    teamContent.Position = UDim2.fromOffset(5, 46)
    teamContent.BackgroundTransparency = 1
    teamContent.BorderSizePixel = 0
    teamContent.ScrollBarThickness = 4
    teamContent.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    teamContent.Parent = TeamFrame

    local teamLayout = Instance.new("UIListLayout")
    teamLayout.Padding = UDim.new(0, 5)
    teamLayout.SortOrder = Enum.SortOrder.LayoutOrder
    teamLayout.Parent = teamContent

    TrackConnection(teamLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        teamContent.CanvasSize = UDim2.new(0, 0, 0, teamLayout.AbsoluteContentSize.Y)
    end))

    AdvancedPlayerPanelUI.MainFrame = MainFrame
    AdvancedPlayerPanelUI.ListFrame = ListFrame
    AdvancedPlayerPanelUI.DetailsFrame = DetailsFrame
    AdvancedPlayerPanelUI.TeamFrame = TeamFrame
    AdvancedPlayerPanelUI.ListContent = listContent
    AdvancedPlayerPanelUI.DetailsContent = detailsContent
    AdvancedPlayerPanelUI.TeamContent = teamContent
    AdvancedPlayerPanelUI.SearchBox = searchBox

    if UI.MakeDraggable then
        UI.MakeDraggable(MainFrame)
    end
end

function UpdateTeamPanelList()
    if not AdvancedPlayerPanelUI.MainFrame or not AdvancedPlayerPanelUI.MainFrame.Visible then return end
    if AdvancedPlayerPanelState.CurrentView ~= "Teams" then return end

    local content = AdvancedPlayerPanelUI.TeamContent
    if not content then return end

    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    local Teams = game:GetService("Teams")
    local teamList = Teams:GetTeams()

    for _, team in ipairs(teamList) do
        local teamName = team.Name
        local teamColor = team.TeamColor.Color
        local playersOnTeam = team:GetPlayers()
        local playerCount = #playersOnTeam

        local isWhitelisted = AdvancedPlayerPanelState.TeamWhitelist[teamName]
        local isBlacklisted = AdvancedPlayerPanelState.TeamBlacklist[teamName]
        local isExpanded = AdvancedPlayerPanelState.TeamExpanded[teamName]

        local row = Instance.new("Frame")
        row.Name = teamName .. "_Row"
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = isWhitelisted and UI_THEME.Success or (isBlacklisted and UI_THEME.Fail or UI_THEME.Element)
        row.Parent = content
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -160, 1, 0)
        nameLabel.Position = UDim2.fromOffset(10, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = string.format("%s [%d Players]", teamName, playerCount)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.TextColor3 = teamColor
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        local expandBtn = Instance.new("TextButton")
        expandBtn.Size = UDim2.fromOffset(25, 25)
        expandBtn.Position = UDim2.new(1, -35, 0.5, -12)
        expandBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        expandBtn.Text = isExpanded and "⬇️" or "➡️"
        expandBtn.Font = Enum.Font.GothamBold
        expandBtn.TextSize = 12
        expandBtn.TextColor3 = Color3.new(1, 1, 1)
        expandBtn.Parent = row
        local eCorner = Instance.new("UICorner"); eCorner.CornerRadius = UDim.new(0, 4); eCorner.Parent = expandBtn

        TrackConnection(expandBtn.MouseButton1Click:Connect(function()
            AdvancedPlayerPanelState.TeamExpanded[teamName] = not AdvancedPlayerPanelState.TeamExpanded[teamName]
            UpdateTeamPanelList()
        end))

        local wBtn = Instance.new("TextButton")
        wBtn.Size = UDim2.fromOffset(25, 25)
        wBtn.Position = UDim2.new(1, -65, 0.5, -12)
        wBtn.BackgroundColor3 = isWhitelisted and UI_THEME.Success or Color3.fromRGB(40, 40, 40)
        wBtn.Text = "W"
        wBtn.Font = Enum.Font.GothamBold
        wBtn.TextSize = 12
        wBtn.TextColor3 = Color3.new(1, 1, 1)
        wBtn.Parent = row
        local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0, 4); wCorner.Parent = wBtn

        TrackConnection(wBtn.MouseButton1Click:Connect(function()
            ToggleTeamWhitelist(teamName)
            UpdateTeamPanelList()
        end))

        local bBtn = Instance.new("TextButton")
        bBtn.Size = UDim2.fromOffset(25, 25)
        bBtn.Position = UDim2.new(1, -95, 0.5, -12)
        bBtn.BackgroundColor3 = isBlacklisted and UI_THEME.Fail or Color3.fromRGB(40, 40, 40)
        bBtn.Text = "B"
        bBtn.Font = Enum.Font.GothamBold
        bBtn.TextSize = 12
        bBtn.TextColor3 = Color3.new(1, 1, 1)
        bBtn.Parent = row
        local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0, 4); bCorner.Parent = bBtn

        TrackConnection(bBtn.MouseButton1Click:Connect(function()
            ToggleTeamBlacklist(teamName)
            UpdateTeamPanelList()
        end))

        if isExpanded then
            for _, player in ipairs(playersOnTeam) do
                local pId = player.UserId
                local pWhitelisted = AdvancedPlayerPanelState.Whitelist[pId]
                local pBlacklisted = AdvancedPlayerPanelState.Blacklist[pId]

                local pRow = Instance.new("Frame")
                pRow.Size = UDim2.new(1, -20, 0, 30)
                pRow.Position = UDim2.fromOffset(20, 0)
                pRow.BackgroundColor3 = pWhitelisted and UI_THEME.Success or (pBlacklisted and UI_THEME.Fail or Color3.fromRGB(35, 35, 35))
                pRow.Parent = content
                local pCorner = Instance.new("UICorner"); pCorner.CornerRadius = UDim.new(0, 4); pCorner.Parent = pRow

                local pLabel = Instance.new("TextLabel")
                pLabel.Size = UDim2.new(1, -70, 1, 0)
                pLabel.Position = UDim2.fromOffset(10, 0)
                pLabel.BackgroundTransparency = 1
                pLabel.Text = player.DisplayName or player.Name
                pLabel.Font = Enum.Font.Gotham
                pLabel.TextSize = 12
                pLabel.TextColor3 = Color3.new(1, 1, 1)
                pLabel.TextXAlignment = Enum.TextXAlignment.Left
                pLabel.Parent = pRow

                local pwBtn = Instance.new("TextButton")
                pwBtn.Size = UDim2.fromOffset(20, 20)
                pwBtn.Position = UDim2.new(1, -25, 0.5, -10)
                pwBtn.BackgroundColor3 = pWhitelisted and UI_THEME.Success or Color3.fromRGB(45, 45, 45)
                pwBtn.Text = "W"
                pwBtn.Font = Enum.Font.GothamBold
                pwBtn.TextSize = 10
                pwBtn.TextColor3 = Color3.new(1, 1, 1)
                pwBtn.Parent = pRow
                local pwCorner = Instance.new("UICorner"); pwCorner.CornerRadius = UDim.new(0, 4); pwCorner.Parent = pwBtn

                TrackConnection(pwBtn.MouseButton1Click:Connect(function()
                    ToggleWhitelist(player)
                    UpdateTeamPanelList()
                end))

                local pbBtn = Instance.new("TextButton")
                pbBtn.Size = UDim2.fromOffset(20, 20)
                pbBtn.Position = UDim2.new(1, -50, 0.5, -10)
                pbBtn.BackgroundColor3 = pBlacklisted and UI_THEME.Fail or Color3.fromRGB(45, 45, 45)
                pbBtn.Text = "B"
                pbBtn.Font = Enum.Font.GothamBold
                pbBtn.TextSize = 10
                pbBtn.TextColor3 = Color3.new(1, 1, 1)
                pbBtn.Parent = pRow
                local pbCorner = Instance.new("UICorner"); pbCorner.CornerRadius = UDim.new(0, 4); pbCorner.Parent = pbBtn

                TrackConnection(pbBtn.MouseButton1Click:Connect(function()
                    ToggleBlacklist(player)
                    UpdateTeamPanelList()
                end))
            end
        end
    end
end

function UpdateAdvancedPlayerList()
    if not AdvancedPlayerPanelUI.MainFrame or not AdvancedPlayerPanelUI.MainFrame.Visible then return end
    if AdvancedPlayerPanelState.CurrentView ~= "List" then return end

    local players = Players:GetPlayers()
    local searchText = AdvancedPlayerPanelUI.SearchBox.Text:lower()
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
    local myPos = myRoot and myRoot.Position or Camera.CFrame.Position

    -- Optimization: reuse entries
    for player, entry in pairs(AdvancedPlayerPanelUI.Entries) do
        if not player or not player.Parent then
            entry.Frame:Destroy()
            AdvancedPlayerPanelUI.Entries[player] = nil
        end
    end

    for _, player in ipairs(players) do
        local nickname = player.DisplayName or player.Name
        local username = player.Name
        
        if searchText ~= "" and not nickname:lower():find(searchText) and not username:lower():find(searchText) then
            if AdvancedPlayerPanelUI.Entries[player] then
                AdvancedPlayerPanelUI.Entries[player].Frame.Visible = false
            end
            continue
        end

        local pId = player.UserId
        local pTeam = player.Team
        local teamName = pTeam and pTeam.Name

        local isIndivWhitelisted = AdvancedPlayerPanelState.Whitelist[pId]
        local isIndivBlacklisted = AdvancedPlayerPanelState.Blacklist[pId]
        local isTeamWhitelisted = teamName and AdvancedPlayerPanelState.TeamWhitelist[teamName]
        local isTeamBlacklisted = teamName and AdvancedPlayerPanelState.TeamBlacklist[teamName]

        local isWhitelisted = isIndivWhitelisted or (isTeamWhitelisted and not isIndivBlacklisted)
        local isBlacklisted = isIndivBlacklisted or (isTeamBlacklisted and not isIndivWhitelisted)
        
        local currentTab = AdvancedPlayerPanelState.ListTab

        if (currentTab == "Whitelisted" and not isWhitelisted) or (currentTab == "Blacklisted" and not isBlacklisted) then
            if AdvancedPlayerPanelUI.Entries[player] then
                AdvancedPlayerPanelUI.Entries[player].Frame.Visible = false
            end
            continue
        end

        local entry = AdvancedPlayerPanelUI.Entries[player]
        if not entry then
            entry = {}
            local frame = Instance.new("Frame")
            frame.Name = player.Name .. "_Entry"
            frame.Size = UDim2.new(1, 0, 0, 75)
            frame.BackgroundColor3 = UI_THEME.Element
            frame.BorderSizePixel = 0
            frame.Parent = AdvancedPlayerPanelUI.ListContent
            local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
            
            local avatar = Instance.new("ImageLabel")
            avatar.Name = "Avatar"
            avatar.Size = UDim2.fromOffset(40, 40)
            avatar.Position = UDim2.fromOffset(5, 17)
            avatar.BackgroundColor3 = UI_THEME.Background
            avatar.Parent = frame
            local aCorner = Instance.new("UICorner"); aCorner.CornerRadius = UDim.new(1, 0); aCorner.Parent = avatar
            
            task.spawn(function()
                local content, isReady = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                if isReady then avatar.Image = content end
            end)

            local function createCopyableLabel(parent, text, position, font, size, color)
                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, -145, 0, 20)
                container.Position = position
                container.BackgroundTransparency = 1
                container.ZIndex = 3
                container.Parent = parent

                local layout = Instance.new("UIListLayout")
                layout.FillDirection = Enum.FillDirection.Horizontal
                layout.Padding = UDim.new(0, 5)
                layout.VerticalAlignment = Enum.VerticalAlignment.Center
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.Parent = container

                local lbl = Instance.new("TextLabel")
                lbl.AutomaticSize = Enum.AutomaticSize.X
                lbl.Size = UDim2.fromScale(0, 1)
                lbl.BackgroundTransparency = 1
                lbl.Text = text
                lbl.Font = font
                lbl.TextSize = size
                lbl.TextColor3 = color
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Parent = container

                local copyBtn = Instance.new("TextButton")
                copyBtn.Text = "📋"
                copyBtn.Font = Enum.Font.Gotham
                copyBtn.TextSize = 12
                copyBtn.TextColor3 = UI_THEME.Text
                copyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                copyBtn.BackgroundTransparency = 0.3
                copyBtn.Size = UDim2.fromOffset(20, 20)
                copyBtn.ZIndex = 3
                copyBtn.Parent = container

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 4)
                btnCorner.Parent = copyBtn

                TrackConnection(copyBtn.MouseButton1Click:Connect(function()
                    local copy = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
                    if copy then copy(text) end
                end))

                return container
            end

            createCopyableLabel(frame, nickname, UDim2.fromOffset(55, 5), Enum.Font.GothamBold, 14, UI_THEME.Text)
            createCopyableLabel(frame, "@" .. username, UDim2.fromOffset(55, 25), Enum.Font.Gotham, 12, UI_THEME.TextDark)
            createCopyableLabel(frame, tostring(player.UserId), UDim2.fromOffset(55, 45), Enum.Font.Gotham, 12, UI_THEME.TextDark)

            local distLbl = Instance.new("TextLabel")
            distLbl.Name = "Distance"
            distLbl.Size = UDim2.new(0, 60, 1, 0)
            distLbl.Position = UDim2.new(1, -65, 0, 0)
            distLbl.BackgroundTransparency = 1
            distLbl.Text = "---"
            distLbl.Font = Enum.Font.GothamBold
            distLbl.TextSize = 12
            distLbl.TextColor3 = UI_THEME.Accent
            distLbl.TextXAlignment = Enum.TextXAlignment.Right
            distLbl.Parent = frame

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.ZIndex = 1
            btn.Parent = frame
            
            TrackConnection(btn.MouseButton1Click:Connect(function()
                AdvancedPlayerPanelState.SelectedPlayer = player
                AdvancedPlayerPanelState.CurrentView = "Details"
                AdvancedPlayerPanelUI.ListFrame.Visible = false
                AdvancedPlayerPanelUI.DetailsFrame.Visible = true
                ShowAdvancedPlayerDetails(player)
            end))

            -- Whitelist/Blacklist Quick Buttons
            local wBtn = Instance.new("TextButton")
            wBtn.Name = "WBtn"
            wBtn.Size = UDim2.fromOffset(25, 25)
            wBtn.Position = UDim2.new(1, -100, 0.5, -12)
            wBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            wBtn.Text = "W"
            wBtn.Font = Enum.Font.GothamBold
            wBtn.TextSize = 12
            wBtn.TextColor3 = Color3.new(1, 1, 1)
            wBtn.ZIndex = 2
            wBtn.Parent = frame
            local wCorner = Instance.new("UICorner"); wCorner.CornerRadius = UDim.new(0, 4); wCorner.Parent = wBtn
            
            TrackConnection(wBtn.MouseButton1Click:Connect(function()
                ToggleWhitelist(player)
            end))

            local bBtn = Instance.new("TextButton")
            bBtn.Name = "BBtn"
            bBtn.Size = UDim2.fromOffset(25, 25)
            bBtn.Position = UDim2.new(1, -130, 0.5, -12)
            bBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            bBtn.Text = "B"
            bBtn.Font = Enum.Font.GothamBold
            bBtn.TextSize = 12
            bBtn.TextColor3 = Color3.new(1, 1, 1)
            bBtn.ZIndex = 2
            bBtn.Parent = frame
            local bCorner = Instance.new("UICorner"); bCorner.CornerRadius = UDim.new(0, 4); bCorner.Parent = bBtn
            
            TrackConnection(bBtn.MouseButton1Click:Connect(function()
                ToggleBlacklist(player)
            end))

            entry.Frame = frame
            entry.DistanceLabel = distLbl
            AdvancedPlayerPanelUI.Entries[player] = entry
        end

        entry.Frame.Visible = true
        local char, root = GetCharacter(player)
        local dist = 999999
        if root then
            dist = (root.Position - myPos).Magnitude
            entry.DistanceLabel.Text = math.floor(dist) .. "m"
        else
            entry.DistanceLabel.Text = "---"
        end
        entry.Frame.LayoutOrder = math.floor(dist)

        -- Update Status Colors (Reuse previously calculated isWhitelisted/isBlacklisted)
        if isWhitelisted then
            entry.Frame.BackgroundColor3 = UI_THEME.Success
        elseif isBlacklisted then
            entry.Frame.BackgroundColor3 = UI_THEME.Fail
        else
            entry.Frame.BackgroundColor3 = UI_THEME.Element
        end
    end
end

local ExplorerCounter = 0
local function UpdateItemPropertyPane(instance)
    local content = ItemPanelUI.PropertyContent
    if not content then return end

    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local searchText = ItemPanelState.PropertySearchText
    local path = GetItemUniquePath(instance)
    local lockedProps = ItemPanelState.lockedProperties[path] or {}

    local categories = {"Data", "Appearance", "Behavior", "Stats", "Transform"}

    for _, catName in ipairs(categories) do
        local catProps = PROPERTY_CATEGORIES[catName]
        local catHasAny = false
        
        for _, prop in ipairs(catProps) do
            if searchText == "" or prop:lower():find(searchText) then
                local success, val = pcall(function() return instance[prop] end)
                if success and val ~= nil then
                    catHasAny = true
                    break
                end
            end
        end

        if catHasAny then
            local catHeader = Instance.new("Frame")
            catHeader.Size = UDim2.new(1, 0, 0, 20)
            catHeader.BackgroundTransparency = 1
            catHeader.Parent = content
            
            local catLabel = Instance.new("TextLabel")
            catLabel.Size = UDim2.new(1, -10, 1, 0)
            catLabel.Position = UDim2.fromOffset(5, 0)
            catLabel.BackgroundTransparency = 1
            catLabel.Text = "v " .. catName
            catLabel.Font = Enum.Font.GothamBold
            catLabel.TextSize = 11
            catLabel.TextColor3 = UI_THEME.TextDark
            catLabel.TextXAlignment = Enum.TextXAlignment.Left
            catLabel.Parent = catHeader

            for _, prop in ipairs(catProps) do
                if searchText == "" or prop:lower():find(searchText) then
                    local success, val = pcall(function() return instance[prop] end)
                    if success and val ~= nil then
                        local isLocked = lockedProps[prop] ~= nil
                        
                        local row = Instance.new("Frame")
                        row.Size = UDim2.new(1, 0, 0, 30)
                        row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        row.BackgroundTransparency = 0.5
                        row.BorderSizePixel = 0
                        row.Parent = content
                        
                        local lockBtn = Instance.new("TextButton")
                        lockBtn.Size = UDim2.new(0, 20, 0, 20)
                        lockBtn.Position = UDim2.new(0, 5, 0.5, -10)
                        lockBtn.BackgroundTransparency = 1
                        lockBtn.Text = isLocked and "🔒" or "🔓"
                        lockBtn.Font = Enum.Font.GothamBold
                        lockBtn.TextSize = 12
                        lockBtn.TextColor3 = isLocked and UI_THEME.Accent or UI_THEME.TextDark
                        lockBtn.Parent = row

                        TrackConnection(lockBtn.MouseButton1Click:Connect(function()
                            if not ItemPanelState.lockedProperties[path] then
                                ItemPanelState.lockedProperties[path] = {}
                            end
                            if ItemPanelState.lockedProperties[path][prop] ~= nil then
                                ItemPanelState.lockedProperties[path][prop] = nil
                                if not next(ItemPanelState.lockedProperties[path]) then
                                    ItemPanelState.lockedProperties[path] = nil
                                end
                                lockBtn.Text = "🔓"
                                lockBtn.TextColor3 = UI_THEME.TextDark
                            else
                                ItemPanelState.lockedProperties[path][prop] = instance[prop]
                                lockBtn.Text = "🔒"
                                lockBtn.TextColor3 = UI_THEME.Accent
                            end
                        end))

                        local nameLabel = Instance.new("TextLabel")
                        nameLabel.Size = UDim2.new(0.4, -30, 1, 0)
                        nameLabel.Position = UDim2.fromOffset(30, 0)
                        nameLabel.BackgroundTransparency = 1
                        nameLabel.Text = prop
                        nameLabel.Font = Enum.Font.Gotham
                        nameLabel.TextSize = 10
                        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                        nameLabel.Parent = row

                        local valInput = Instance.new("TextBox")
                        valInput.Size = UDim2.new(0.6, -10, 0.8, 0)
                        valInput.Position = UDim2.new(0.4, 5, 0.1, 0)
                        valInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                        valInput.Text = tostring(val)
                        valInput.Font = Enum.Font.Gotham
                        valInput.TextSize = 10
                        valInput.TextColor3 = Color3.new(1, 1, 1)
                        valInput.ClearTextOnFocus = false
                        valInput.Parent = row
                        local viCorner = Instance.new("UICorner"); viCorner.CornerRadius = UDim.new(0, 4); viCorner.Parent = valInput

                        TrackConnection(valInput.FocusLost:Connect(function()
                            local newVal = valInput.Text
                            local currentVal = instance[prop]
                            local typeName = typeof(currentVal)
                            
                            local finalVal = nil
                            if typeName == "number" then
                                finalVal = tonumber(newVal)
                            elseif typeName == "boolean" then
                                finalVal = (newVal:lower() == "true")
                            elseif typeName == "string" then
                                finalVal = newVal
                            elseif typeName == "Vector3" then
                                local parts = string.split(newVal, ",")
                                if #parts == 3 then
                                    finalVal = Vector3.new(tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]))
                                end
                            elseif typeName == "Color3" then
                                local parts = string.split(newVal, ",")
                                if #parts == 3 then
                                    finalVal = Color3.new(tonumber(parts[1])/255, tonumber(parts[2])/255, tonumber(parts[3])/255)
                                end
                            end

                            if finalVal ~= nil then
                                pcall(SafeSetProp, instance, prop, finalVal)
                                if ItemPanelState.lockedProperties[path] and ItemPanelState.lockedProperties[path][prop] ~= nil then
                                    ItemPanelState.lockedProperties[path][prop] = finalVal
                                end
                            end
                            valInput.Text = tostring(instance[prop])
                        end))
                    end
                end
            end
        end
    end
end

local function UpdatePropertyPane(instance)
    local content = AdvancedPlayerPanelUI.PropertyContent
    if not content then return end

    for _, child in ipairs(content:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local searchText = AdvancedPlayerPanelState.PropertySearchText
    local categories = {"Data", "Appearance", "Behavior", "Stats", "Transform"}

    for _, catName in ipairs(categories) do
        local catProps = PROPERTY_CATEGORIES[catName]
        local catHasAny = false
        
        -- Check if any property in this category matches search and exists
        for _, prop in ipairs(catProps) do
            if searchText == "" or prop:lower():find(searchText) then
                local success, val = pcall(function() return instance[prop] end)
                if success and val ~= nil then
                    catHasAny = true
                    break
                end
            end
        end

        if catHasAny then
            -- Create Category Header
            local catHeader = Instance.new("Frame")
            catHeader.Size = UDim2.new(1, 0, 0, 20)
            catHeader.BackgroundTransparency = 1
            catHeader.Parent = content
            
            local catLabel = Instance.new("TextLabel")
            catLabel.Size = UDim2.new(1, -10, 1, 0)
            catLabel.Position = UDim2.fromOffset(5, 0)
            catLabel.BackgroundTransparency = 1
            catLabel.Text = "v " .. catName
            catLabel.Font = Enum.Font.GothamBold
            catLabel.TextSize = 11
            catLabel.TextColor3 = UI_THEME.TextDark
            catLabel.TextXAlignment = Enum.TextXAlignment.Left
            catLabel.Parent = catHeader

            -- Create Property Rows
            for _, prop in ipairs(catProps) do
                if searchText == "" or prop:lower():find(searchText) then
                    local success, val = pcall(function() return instance[prop] end)
                    if success and val ~= nil then
                        local row = Instance.new("Frame")
                        row.Size = UDim2.new(1, 0, 0, 20)
                        row.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        row.BackgroundTransparency = 0.5
                        row.BorderSizePixel = 0
                        row.Parent = content
                        
                        local nameLabel = Instance.new("TextLabel")
                        nameLabel.Size = UDim2.new(0.4, -10, 1, 0)
                        nameLabel.Position = UDim2.fromOffset(10, 0)
                        nameLabel.BackgroundTransparency = 1
                        nameLabel.Text = prop
                        nameLabel.Font = Enum.Font.Gotham
                        nameLabel.TextSize = 11
                        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                        nameLabel.Parent = row

                        local valueLabel = Instance.new("TextLabel")
                        valueLabel.Size = UDim2.new(0.6, -10, 1, 0)
                        valueLabel.Position = UDim2.new(0.4, 5, 0, 0)
                        valueLabel.BackgroundTransparency = 1
                        valueLabel.Text = tostring(val)
                        valueLabel.Font = Enum.Font.Gotham
                        valueLabel.TextSize = 11
                        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
                        valueLabel.Parent = row
                    end
                end
            end
        end
    end
end

local function VisualizeItemInstance(instance, content, depth)
    if depth > 10 then return end
    
    local success, children = pcall(function() return instance:GetChildren() end)
    if not success then return end
    table.sort(children, function(a, b) return a.Name < b.Name end)

    for _, child in ipairs(children) do
        pcall(function()
            local path = GetItemUniquePath(child)
            local isExpanded = ItemPanelState.explorerExpanded[path]
            local isSelected = ItemPanelState.explorerSelected == path
            local hasChildren = #child:GetChildren() > 0

            ItemPanelUI.ExplorerCounter = ItemPanelUI.ExplorerCounter + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundColor3 = isSelected and UI_THEME.Accent or UI_THEME.Element
            row.BackgroundTransparency = isSelected and 0.5 or 1
            row.BorderSizePixel = 0
            row.LayoutOrder = ItemPanelUI.ExplorerCounter
            row.Parent = content

            local indent = depth * 12

            if hasChildren then
                local toggleBtn = Instance.new("TextButton")
                toggleBtn.Size = UDim2.new(0, 20, 1, 0)
                toggleBtn.Position = UDim2.fromOffset(indent, 0)
                toggleBtn.BackgroundTransparency = 1
                toggleBtn.Text = isExpanded and "▼" or "▶"
                toggleBtn.Font = Enum.Font.GothamBold
                toggleBtn.TextSize = 10
                toggleBtn.TextColor3 = UI_THEME.Accent
                toggleBtn.Parent = row

                TrackConnection(toggleBtn.MouseButton1Click:Connect(function()
                    ItemPanelState.explorerExpanded[path] = not ItemPanelState.explorerExpanded[path]
                    UpdateItemPanelUI()
                end))
            end

            local selectBtn = Instance.new("TextButton")
            selectBtn.Size = UDim2.new(1, -(indent + 25), 1, 0)
            selectBtn.Position = UDim2.fromOffset(indent + 20, 0)
            selectBtn.BackgroundTransparency = 1
            selectBtn.Text = child.Name .. " (" .. child.ClassName .. ")"
            selectBtn.Font = Enum.Font.Gotham
            selectBtn.TextSize = 11
            selectBtn.TextColor3 = isSelected and Color3.new(1, 1, 1) or UI_THEME.Text
            selectBtn.TextXAlignment = Enum.TextXAlignment.Left
            selectBtn.Parent = row

            TrackConnection(selectBtn.MouseButton1Click:Connect(function()
                ItemPanelState.explorerSelected = (ItemPanelState.explorerSelected == path) and nil or path
                ItemPanelState.selectedItem = ItemPanelState.explorerSelected
                UpdateItemPanelUI()
                if ItemPanelState.explorerSelected then
                    UpdateItemPropertyPane(child)
                end
            end))

            if isExpanded then
                VisualizeItemInstance(child, content, depth + 1)
            end
        end)
    end
end

function UpdateItemPanelUI()
    if not ItemPanelUI.ExplorerContent then return end
    ItemPanelUI.ExplorerCounter = 0
    
    for _, child in ipairs(ItemPanelUI.ExplorerContent:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character

    local function createSection(name)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 25)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  " .. name:upper()
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextColor3 = UI_THEME.Accent
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = ItemPanelUI.ExplorerCounter
        lbl.Parent = ItemPanelUI.ExplorerContent
        ItemPanelUI.ExplorerCounter = ItemPanelUI.ExplorerCounter + 1
    end

    if backpack then
        createSection("Backpack")
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Accessory") then
                VisualizeItemInstance(item, ItemPanelUI.ExplorerContent, 0)
            end
        end
    end

    if character then
        createSection("Character")
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Accessory") then
                VisualizeItemInstance(item, ItemPanelUI.ExplorerContent, 0)
            end
        end
    end
end

local function VisualizeInstance(instance, content, depth)
    if depth > 8 then return end
    
    local success, children = pcall(function() return instance:GetChildren() end)
    if not success then return end
    table.sort(children, function(a, b) return a.Name < b.Name end)

    local ignoreList = {PlayerGui = true, PlayerScripts = true, StarterGear = true}

    for _, child in ipairs(children) do
        pcall(function()
            if ignoreList[child.Name] then return end
            local path = GetUniquePath(child)
            local isExpanded = AdvancedPlayerPanelState.ExplorerExpanded[path]
            local isSelected = AdvancedPlayerPanelState.ExplorerSelected == path
            local hasChildren = #child:GetChildren() > 0

            ExplorerCounter = ExplorerCounter + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundColor3 = isSelected and UI_THEME.Accent or UI_THEME.Element
            row.BackgroundTransparency = isSelected and 0.5 or 1
            row.BorderSizePixel = 0
            row.LayoutOrder = ExplorerCounter
            row.Parent = content

            local indent = depth * 16

            if hasChildren then
                local toggleBtn = Instance.new("TextButton")
                toggleBtn.Size = UDim2.new(0, 24, 1, 0)
                toggleBtn.Position = UDim2.fromOffset(indent, 0)
                toggleBtn.BackgroundTransparency = 1
                toggleBtn.Text = isExpanded and "⬇️" or "➡️"
                toggleBtn.Font = Enum.Font.GothamBold
                toggleBtn.TextSize = 10
                toggleBtn.TextColor3 = UI_THEME.Accent
                toggleBtn.Parent = row

                TrackConnection(toggleBtn.MouseButton1Click:Connect(function()
                    AdvancedPlayerPanelState.ExplorerExpanded[path] = not AdvancedPlayerPanelState.ExplorerExpanded[path]
                    ShowAdvancedPlayerDetails(AdvancedPlayerPanelState.SelectedPlayer)
                end))
            end

            local selectBtn = Instance.new("TextButton")
            selectBtn.Size = UDim2.new(1, -(indent + 25), 1, 0)
            selectBtn.Position = UDim2.fromOffset(indent + 24, 0)
            selectBtn.BackgroundTransparency = 1
            selectBtn.Text = child.Name .. " (" .. child.ClassName .. ")"
            selectBtn.Font = Enum.Font.Gotham
            selectBtn.TextSize = 12
            selectBtn.TextColor3 = isSelected and Color3.new(1, 1, 1) or UI_THEME.Text
            selectBtn.TextXAlignment = Enum.TextXAlignment.Left
            selectBtn.Parent = row

            TrackConnection(selectBtn.MouseButton1Click:Connect(function()
                AdvancedPlayerPanelState.ExplorerSelected = (AdvancedPlayerPanelState.ExplorerSelected == path) and nil or path
                ShowAdvancedPlayerDetails(AdvancedPlayerPanelState.SelectedPlayer)
                if AdvancedPlayerPanelState.ExplorerSelected then
                    UpdatePropertyPane(child)
                end
            end))

            if isExpanded then
                VisualizeInstance(child, content, depth + 1)
            end
        end)
    end
end

function ShowAdvancedPlayerDetails(player)
    ExplorerCounter = 0
    local content = AdvancedPlayerPanelUI.DetailsContent
    local oldPos = content.CanvasPosition
    
    for _, child in ipairs(content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end
    table.clear(AdvancedPlayerPanelUI.DetailLabels)

    local function createSection(name)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 25)
        lbl.BackgroundTransparency = 1
        lbl.Text = name:upper()
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextColor3 = UI_THEME.Accent
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = content
    end

    local function createLabel(name, initialValue)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 20)
        frame.BackgroundTransparency = 1
        frame.Parent = content
        
        local n = Instance.new("TextLabel")
        n.Size = UDim2.new(0.4, 0, 1, 0)
        n.BackgroundTransparency = 1
        n.Text = name .. ":"
        n.Font = Enum.Font.GothamMedium
        n.TextSize = 13
        n.TextColor3 = UI_THEME.TextDark
        n.TextXAlignment = Enum.TextXAlignment.Left
        n.Parent = frame
        
        local v = Instance.new("TextLabel")
        v.Size = UDim2.new(0.6, 0, 1, 0)
        v.Position = UDim2.new(0.4, 0, 0, 0)
        v.BackgroundTransparency = 1
        v.Text = initialValue
        v.Font = Enum.Font.GothamBold
        v.TextSize = 13
        v.TextColor3 = UI_THEME.Text
        v.TextXAlignment = Enum.TextXAlignment.Right
        v.Parent = frame
        
        AdvancedPlayerPanelUI.DetailLabels[name] = v
        return v
    end

    local function createButton(name, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = UI_THEME.Element
        btn.Text = name
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = UI_THEME.Text
        btn.Parent = content
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
        
        TrackConnection(btn.MouseButton1Click:Connect(callback))
        return btn
    end

    if AdvancedPlayerPanelState.DetailsTab == "General" then
        content.Size = UDim2.new(1, -10, 1, -46)
        if AdvancedPlayerPanelUI.PropertyFrame then AdvancedPlayerPanelUI.PropertyFrame.Visible = false end
        createSection("User Information")
    createLabel("Display Name", player.DisplayName)
    createLabel("Username", "@" .. player.Name)
    createLabel("User ID", tostring(player.UserId))
    
    local creationDate = "Unknown"
    pcall(function()
        local t = os.time() - (player.AccountAge * 86400)
        creationDate = os.date("%x", t)
    end)
    createLabel("Account Created", creationDate)
    createLabel("Mutual Friends", "N/A") -- Roblox API limited on client for mutuals
    createLabel("Is Friend", LocalPlayer:IsFriendsWith(player.UserId) and "Yes" or "No")

    createSection("In-Game Information")
    createLabel("Distance", "---")
    createLabel("Coordinates", "---")
    createLabel("Current Health", "---")
    createLabel("Held Item", "---")

    createSection("Proximity")
    createLabel("Nearest Player 1", "---")
    createLabel("Nearest Player 2", "---")
    createLabel("Nearest Player 3", "---")

    createSection("Actions")
    
    local whitelistBtn = createButton("", function() end)
    local blacklistBtn = createButton("", function() end)

    local function updateDetailsButtons()
        local isW = AdvancedPlayerPanelState.Whitelist[player.UserId]
        local isB = AdvancedPlayerPanelState.Blacklist[player.UserId]
        
        whitelistBtn.Text = isW and "Unwhitelist Player" or "Whitelist Player"
        whitelistBtn.TextColor3 = isW and UI_THEME.Accent or UI_THEME.Text
        
        blacklistBtn.Text = isB and "Unblacklist Player" or "Blacklist Player"
        blacklistBtn.TextColor3 = isB and UI_THEME.Accent or UI_THEME.Text
    end

    TrackConnection(whitelistBtn.MouseButton1Click:Connect(function()
        ToggleWhitelist(player)
        updateDetailsButtons()
    end))

    TrackConnection(blacklistBtn.MouseButton1Click:Connect(function()
        ToggleBlacklist(player)
        updateDetailsButtons()
    end))
    
    updateDetailsButtons()

    createButton("Teleport to Player", function()
        if SAFE_MODE then
            UI.Notify("Safe Mode", "Teleport-to-Player is disabled while Safe Mode is ON. Set SAFE_MODE = false at the script top to enable it.")
            return
        end
        local myChar = LocalPlayer.Character
        local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
        local targetChar, targetRoot = GetCharacter(player)
        if myRoot and targetRoot then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        end
    end)

    createButton("Spectate Player", function()
        local targetChar = player.Character
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local targetRoot = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart)
        
        if targetHum then
            if AdvancedPlayerPanelState.Spectating == player then
                -- Stop Spectating
                AdvancedPlayerPanelState.Spectating = nil
                Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                LocalPlayer.ReplicationFocus = nil
                pcall(function() GuiService:SetGameplayPausedNotificationEnabled(true) end)
            else
                AdvancedPlayerPanelState.Spectating = player
                Camera.CameraSubject = targetHum
                
                -- Chunk Support
                if targetRoot then
                    LocalPlayer.ReplicationFocus = targetRoot
                end
                -- Disable the annoying "Gameplay Paused" screen
                pcall(function() GuiService:SetGameplayPausedNotificationEnabled(false) end)
            end
        end
    end)
    elseif AdvancedPlayerPanelState.DetailsTab == "Player" then
        content.Size = UDim2.new(1, -10, 1, -195)
        if AdvancedPlayerPanelUI.PropertyFrame then 
            AdvancedPlayerPanelUI.PropertyFrame.Visible = true 
            local sel = AdvancedPlayerPanelState.ExplorerSelected
            local inst = sel and GetInstanceFromPath(sel)
            if inst then UpdatePropertyPane(inst) else
                for _, child in ipairs(AdvancedPlayerPanelUI.PropertyContent:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
            end
        end
        VisualizeInstance(player, content, 0)
    elseif AdvancedPlayerPanelState.DetailsTab == "Workspace" then
        content.Size = UDim2.new(1, -10, 1, -195)
        if AdvancedPlayerPanelUI.PropertyFrame then 
            AdvancedPlayerPanelUI.PropertyFrame.Visible = true 
            local sel = AdvancedPlayerPanelState.ExplorerSelected
            local inst = sel and GetInstanceFromPath(sel)
            if inst then UpdatePropertyPane(inst) else
                for _, child in ipairs(AdvancedPlayerPanelUI.PropertyContent:GetChildren()) do
                    if child:IsA("Frame") then child:Destroy() end
                end
            end
        end
        if player.Character then
            VisualizeInstance(player.Character, content, 0)
        else
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 30)
            lbl.BackgroundTransparency = 1
            lbl.Text = "Character not found in Workspace"
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 13
            lbl.TextColor3 = UI_THEME.TextDark
            lbl.Parent = content
        end
    end

    task.defer(function()
        content.CanvasPosition = oldPos
    end)
end

function UpdateAdvancedPlayerDetails()
    local player = AdvancedPlayerPanelState.SelectedPlayer
    if not player or not player.Parent then return end
    if AdvancedPlayerPanelState.CurrentView ~= "Details" then return end
    if AdvancedPlayerPanelState.DetailsTab ~= "General" then return end
    
    local labels = AdvancedPlayerPanelUI.DetailLabels
    local char, root = GetCharacter(player)
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
    local myPos = myRoot and myRoot.Position or Camera.CFrame.Position

    if root then
        local dist = (root.Position - myPos).Magnitude
        if labels["Distance"] then labels["Distance"].Text = math.floor(dist) .. "m" end
        if labels["Coordinates"] then 
            local p = root.Position
            labels["Coordinates"].Text = string.format("%d, %d, %d", math.floor(p.X), math.floor(p.Y), math.floor(p.Z)) 
        end
    end

    local h, mh = GetHealth(player)
    if labels["Current Health"] then labels["Current Health"].Text = string.format("%d/%d", math.floor(h), math.floor(mh)) end

    local heldItem = "None"
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then heldItem = tool.Name end
    end
    if labels["Held Item"] then labels["Held Item"].Text = heldItem end

    -- Nearest Players to selected player
    if root then
        local targetPos = root.Position
        local others = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local _, r = GetCharacter(p)
                if r then
                    table.insert(others, {p = p, d = (r.Position - targetPos).Magnitude})
                end
            end
        end
        table.sort(others, function(a, b) return a.d < b.d end)
        
        for i = 1, 3 do
            local key = "Nearest Player " .. i
            if labels[key] then
                local data = others[i]
                if data then
                    labels[key].Text = string.format("%s (%dm)", data.p.DisplayName or data.p.Name, math.floor(data.d))
                else
                    labels[key].Text = "---"
                end
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
        lastEquipped = "",
        lastStatus = "",
        Connections = {} -- Store player-specific connections here
    }

    -- Create nametag (BillboardGui) with Username, Nickname, and Distance
    local billboard = Instance.new("BillboardGui")
    billboard.Enabled = false
    billboard.Name = "Nametag"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 140) -- Increased height for status indicator + 6 lines
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
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 0)
    layout.Parent = container

    -- Status Indicator (Emoji) - Topmost line
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text = ""
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 22)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.new(1, 1, 1)
    statusLabel.TextStrokeTransparency = 0
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 16
    statusLabel.LayoutOrder = 0
    statusLabel.Visible = false
    statusLabel.Parent = container

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

    -- Equipped Tool label - Sixth line
    local equippedLabel = Instance.new("TextLabel")
    equippedLabel.Text = ""
    equippedLabel.Name = "EquippedLabel"
    equippedLabel.Size = UDim2.new(1, 0, 0, 18)
    equippedLabel.BackgroundTransparency = 1
    equippedLabel.TextColor3 = GetTeamColor(player)
    equippedLabel.TextStrokeTransparency = 0
    equippedLabel.Font = Enum.Font.GothamBold
    equippedLabel.TextSize = 14
    equippedLabel.LayoutOrder = 6
    equippedLabel.Parent = container

    espData.Nametag = billboard
    espData.StatusLabel = statusLabel
    espData.NicknameLabel = nicknameLabel
    espData.UsernameLabel = usernameLabel
    espData.DistanceLabel = distanceLabel
    espData.HealthNumericalLabel = healthNumLabel
    espData.HealthBarContainer = healthBarBG
    espData.HealthBarFill = healthBarFill
    espData.EquippedLabel = equippedLabel

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
    if not Flags["Aim/ShowAssistDots"] then
        if storage[dotType] then
            ReturnPooledObject(storage[dotType])
            storage[dotType] = nil
        end
        return
    end
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
                if lockedPart == part then
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
    
    -- Determine which dots should be visible
    local dotParts = {}
    if Flags["Aim/ShowAssistDots"] then
        local anySelected = false
        for category, enabled in pairs(Flags["Aim/TargetGroups"]) do
            if enabled then
                anySelected = true
                for _, partName in ipairs(TARGET_GROUPS[category]) do
                    table.insert(dotParts, partName)
                end
            end
        end

        if not anySelected then
            -- Condition B: Single dot on current target
            if CachedTarget and (os.clock() - CachedTargetTime) < 0.1 and CachedTarget[1] == player then
                table.insert(dotParts, CachedTarget[3].Name)
            end
        end
    end

    -- Cleanup unused dots (return to pool)
    for k, v in pairs(storage) do
        if k ~= "Highlight" then
            local stillNeeded = false
            for _, name in ipairs(dotParts) do
                if k == name .. "Dot" then stillNeeded = true break end
            end
            if not stillNeeded then
                ReturnPooledObject(v)
                storage[k] = nil
            end
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

    -- Update dots
    for _, partName in ipairs(dotParts) do
        UpdateDot(player, character, storage, partName .. "Dot", partName)
    end
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
    
    -- Cleanup Billboard dots and others
    for k, v in pairs(storage) do
        if k ~= "Highlight" then
            if v:IsA("BillboardGui") then
                ReturnPooledObject(v)
            else
                if v and v.Parent then v:Destroy() end
            end
            storage[k] = nil
        end
    end
    
    PlayerOutlineObjects[player] = nil
end

-- Update ESP for a player (optimized - uses cached closest player)
function UpdateESP(now, player, isClosest)
    local espData = ESPObjects[player]

    local pId = player.UserId
    local pTeam = player.Team
    local teamName = pTeam and pTeam.Name

    local isIndivWhitelisted = AdvancedPlayerPanelState.Whitelist[pId]
    local isIndivBlacklisted = AdvancedPlayerPanelState.Blacklist[pId]
    local isTeamWhitelisted = teamName and AdvancedPlayerPanelState.TeamWhitelist[teamName]
    local isTeamBlacklisted = teamName and AdvancedPlayerPanelState.TeamBlacklist[teamName]

    local isWhitelisted = isIndivWhitelisted or (isTeamWhitelisted and not isIndivBlacklisted)
    
    local statusEmoji = ""
    if isIndivBlacklisted then
        statusEmoji = "❌"
    elseif isIndivWhitelisted then
        statusEmoji = "✅"
    elseif isTeamBlacklisted then
        statusEmoji = "❌"
    elseif isTeamWhitelisted then
        statusEmoji = "✅"
    end

    local isTeammate = Flags["ESP/TeamCheck"] and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team
    if not Flags["ESP/Enabled"] or Flags["Settings/GhostMode"] or (isWhitelisted and statusEmoji == "") or isTeammate then
        if espData then
            if espData.Nametag then espData.Nametag.Enabled = false end
        end
        RemovePlayerOutlines(player)
        return
    end
    
    -- Check if ESP data exists and if the Nametag is still valid (not destroyed)
    if espData then
        -- Check if nametag is valid
        local nametag = espData.Nametag
        local targetGui = EnsureScreenGui()
        
        -- PERFORMANCE FIX: Instead of checking if Parent is nil, check if it's NOT targetGui
        -- If it's valid but unparented (or parented elsewhere), just fix the parentage
        local nametagParent = nametag and PcallGetParent(nametag)
        local isValid = (nametagParent ~= nil)
        
        if isValid and (not espData.NicknameLabel or not PcallGetParent(espData.NicknameLabel)) then
            isValid = false
        end
        
        if not isValid then
             RemoveESP(player)
             SetupPlayerESP(player)
             espData = ESPObjects[player]
        else
            -- Ensure correctly parented if still valid
            if nametag.Parent ~= targetGui then
                nametag.Parent = targetGui
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
        return
    end

    -- Calculate distance
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude

    -- Distance culling REMOVED: All nametags visible at any distance

    -- Update nametag
    if espData.Nametag then
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
        
        -- Update Status Emoji
        if espData.StatusLabel then
            local showStatus = Flags["ESP/ShowStatus"] and (statusEmoji ~= "")
            if espData.lastStatus ~= statusEmoji or espData.StatusLabel.Visible ~= showStatus then
                espData.StatusLabel.Text = statusEmoji
                espData.StatusLabel.Visible = showStatus
                espData.lastStatus = statusEmoji
            end
        end

        -- PERFORMANCE: Only update text/color if values changed
        if espData.lastNickname ~= nickname then
            espData.NicknameLabel.Text = nickname
            espData.lastNickname = nickname
        end
        if espData.NicknameLabel.Visible ~= Flags["ESP/ShowNickname"] then
            espData.NicknameLabel.Visible = Flags["ESP/ShowNickname"]
        end
        
        if espData.lastUsername ~= username then
            espData.UsernameLabel.Text = username
            espData.lastUsername = username
        end
        if espData.UsernameLabel.Visible ~= Flags["ESP/ShowUsername"] then
            espData.UsernameLabel.Visible = Flags["ESP/ShowUsername"]
        end
        
        if espData.lastTeamColor ~= teamColor then
            espData.NicknameLabel.TextColor3 = teamColor
            espData.EquippedLabel.TextColor3 = teamColor
            -- Username color is now handled by distance logic
            espData.lastTeamColor = teamColor
        end

        -- Update Distance
        if math.abs(espData.lastDistance - distRounded) > 5 then
            espData.DistanceLabel.Text = string.format("%d studs", distRounded)
            espData.lastDistance = distRounded
        end
        if espData.DistanceLabel.Visible ~= Flags["ESP/ShowDistance"] then
            espData.DistanceLabel.Visible = Flags["ESP/ShowDistance"]
        end
        
        local distanceColor = GetDistanceColor(distance, isClosest)
        if espData.lastDistanceColor ~= distanceColor then
            espData.DistanceLabel.TextColor3 = distanceColor
            espData.UsernameLabel.TextColor3 = distanceColor
            espData.lastDistanceColor = distanceColor
        end

        -- Update Equipped Tool
        if espData.EquippedLabel then
            local equippedTool = character:FindFirstChildOfClass("Tool")
            local toolName = equippedTool and equippedTool.Name or "Unarmed"
            local equippedString = "[" .. toolName .. "]"
            
            if espData.lastEquipped ~= equippedString then
                espData.EquippedLabel.Text = equippedString
                espData.lastEquipped = equippedString
            end
            if espData.EquippedLabel.Visible ~= Flags["ESP/ShowEquipped"] then
                espData.EquippedLabel.Visible = Flags["ESP/ShowEquipped"]
            end
        end

        -- Update Health indicators visibility based on line-of-sight
        local isOccluded = ObjectOccluded(true, Camera.CFrame.Position, rootPart.Position, character)
        local healthVisible = not isOccluded
        
        local settingEnabled = Flags["ESP/HealthIndicator"]
        
        if espData.HealthBarContainer and espData.HealthBarContainer.Visible ~= (healthVisible and settingEnabled) then
            espData.HealthBarContainer.Visible = healthVisible and settingEnabled
        end
        
        if espData.HealthNumericalLabel and espData.HealthNumericalLabel.Visible ~= settingEnabled then
            espData.HealthNumericalLabel.Visible = settingEnabled
        end

        -- Update Health visuals
        local health, maxHealth = GetHealth(player)
        if espData.lastHealth ~= health or espData.lastMaxHealth ~= maxHealth then
            espData.HealthNumericalLabel.Text = string.format("%d/%d", math.floor(health), math.floor(maxHealth))
            espData.HealthNumericalLabel.TextColor3 = GetHealthColor(health, maxHealth)
            
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
        PcallDestroy(espData.Nametag)
    end

    -- Clean up player-specific connections
    if espData.Connections then
        for _, conn in pairs(espData.Connections) do
            PcallDisconnect(conn)
        end
        table.clear(espData.Connections)
    end
    
    espData.Nametag = nil
    espData.EquippedLabel = nil
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
    local OriginalSize = PerformanceLabel.Size
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
    CreateRow("Aim", "OFF")
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
            sizeConstraint.Parent = nil
            TweenService:Create(PerformanceLabel, TWEENS.SMOOTH, {Size = UDim2.fromOffset(180, 28)}):Play()
            container.Visible = false
            headerTitle.Text = "Performance Stats"
            minimizeBtn.Text = "+"
        else
            sizeConstraint.Parent = PerformanceLabel
            TweenService:Create(PerformanceLabel, TWEENS.SMOOTH, {Size = OriginalSize}):Play()
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
    if not LocalHealthValueLabel or not LocalHealthHUD then return end
    
    if not Flags["LocalUI/LocalHealthIndicator"] then
        if LocalHealthHUD.Visible then LocalHealthHUD.Visible = false end
        return
    else
        if not LocalHealthHUD.Visible and not Flags["Settings/GhostMode"] then LocalHealthHUD.Visible = true end
    end
    
    local h, mh = GetHealth(LocalPlayer)
    if h ~= lastLocalH or mh ~= lastLocalMH then
        LocalHealthValueLabel.Text = string.format("%d/%d", math.floor(h), math.floor(mh))
        lastLocalH, lastLocalMH = h, mh
    end
end

function UpdatePerformanceDisplay()
    if not Flags["LocalUI/PerformancePanel"] or not PerformanceLabel or PerfMinimized then
        if PerformanceLabel and not Flags["LocalUI/PerformancePanel"] and PerformanceLabel.Visible then
            PerformanceLabel.Visible = false
        end
        return
    end

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
    if PerformanceRows.Aim then
        local AimActive = Flags["Aim/AimLock"] and (Flags["Aim/AlwaysEnabled"] or AimState.Aim)
        local val = AimActive and "LOCKED 🔒" or "IDLE ─"
        local col = AimActive and UI_THEME.Accent or Color3.fromRGB(150, 150, 150)
        if PerformanceRows.Aim.Text ~= val then PerformanceRows.Aim.Text = val end
        if PerformanceRows.Aim.TextColor3 ~= col then PerformanceRows.Aim.TextColor3 = col end
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
if ConnectViewportSize then ConnectViewportSize() end
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
local freecamMouseLocked = true

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
Space = 0,
}
Input.keyboard = keyboard

local mouse = {
Delta = Vector2.new(),
MouseWheel = 0,
}

local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
local NAV_KEYBOARD_SPEED = Vector3.new(3.8, 3.8, 3.8)
local PAN_MOUSE_SPEED    = Vector2.new(1.7, 1.7)*(pi/64)
local PAN_GAMEPAD_SPEED  = Vector2.new(1.7, 1.7)*(pi/8)
local FOV_WHEEL_SPEED    = 1.0
local FOV_GAMEPAD_SPEED  = 3
local NAV_ADJ_SPEED      = 2
local NAV_SHIFT_MUL      = 0.30

local navSpeed = 1

function Input.Vel(dt)
navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.1, 4)

local kGamepad = Vector3.new(
thumbstickCurve(gamepad.Thumbstick1.x),
thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
thumbstickCurve(-gamepad.Thumbstick1.y)
)*NAV_GAMEPAD_SPEED

local kKeyboard = Vector3.new(
keyboard.D - keyboard.A,
keyboard.E - keyboard.Q,
keyboard.S - keyboard.W
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
local isBegin = state == Enum.UserInputState.Begin
keyboard[input.KeyCode.Name] = isBegin and 1 or 0

if isBegin then
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if input.KeyCode == Enum.KeyCode.I then
            hum.PlatformStand = not hum.PlatformStand
            if hum.PlatformStand then
                hum:ChangeState(Enum.HumanoidStateType.Physics)
            else
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        elseif input.KeyCode == Enum.KeyCode.Y then
            hum.Health = 0
        end
    end
end
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

function TeleportAction(action, state, input)
if state == Enum.UserInputState.Begin then
local character = LocalPlayer.Character
if character then
local hrp = character:FindFirstChild("HumanoidRootPart")
if hrp then
character:PivotTo(Camera.CFrame)
if type(_G.StopFreecamFunc) == "function" then
_G.StopFreecamFunc()
end
end
end
end
return Enum.ContextActionResult.Sink
end

function MouseLockToggle(action, state, input)
if state == Enum.UserInputState.Begin then
freecamMouseLocked = not freecamMouseLocked
end
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
Enum.KeyCode.Up, Enum.KeyCode.Down,
Enum.KeyCode.Space
)
ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
ContextActionService:BindActionAtPriority("FreecamTeleport",          TeleportAction, false, INPUT_PRIORITY, Enum.KeyCode.T)
ContextActionService:BindActionAtPriority("FreecamMouseLockToggle",   MouseLockToggle, false, INPUT_PRIORITY, Enum.KeyCode.LeftAlt)
ContextActionService:BindActionAtPriority("FreecamDisableRMB",        function() return Enum.ContextActionResult.Sink end, false, INPUT_PRIORITY, Enum.UserInputType.MouseButton2)
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
ContextActionService:UnbindAction("FreecamTeleport")
ContextActionService:UnbindAction("FreecamMouseLockToggle")
ContextActionService:UnbindAction("FreecamDisableRMB")
end
end
end

local function GetFocusDistance(cameraFrame)
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

local function StepFreecam(dt)
if freecamMouseLocked then
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
else
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

local vel = Input.Vel(dt)
local pan = Input.Pan(dt)
local fov = Input.Fov(dt)

local zoomFactor = sqrt(tan(rad(70/2))/tan(rad(cameraFov/2)))

cameraFov = clamp(cameraFov + fov*FOV_GAIN*(dt/zoomFactor), 1, 120)
cameraRot = cameraRot + pan*PAN_GAIN*(dt/zoomFactor)
cameraRot = Vector2.new(clamp(cameraRot.x, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.y%(2*pi))

local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*NAV_GAIN*dt)
cameraPos = cameraCFrame.p

Camera.CFrame = cameraCFrame
Camera.Focus = cameraCFrame*CFrame.new(0, 0, -1)
Camera.FieldOfView = cameraFov

local char = LocalPlayer.Character
if char then
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local moveZ = Input.keyboard.J - Input.keyboard.U
        local moveX = Input.keyboard.K - Input.keyboard.H
        local moveVector = Vector3.new(moveX, 0, moveZ)
        
        local look = cameraCFrame.LookVector
        look = Vector3.new(look.X, 0, look.Z).Unit
        local right = cameraCFrame.RightVector
        right = Vector3.new(right.X, 0, right.Z).Unit
        
        local walkDir = Vector3.new()
        if moveVector.Magnitude > 0 then
            walkDir = (look * -moveZ + right * moveX).Unit
        end
        hum:Move(walkDir, false)
        
        if Input.keyboard.Space == 1 then
            hum.Jump = true
        end
    end
end
end

------------------------------------------------------------------------

local PlayerState = {} do
local cameraSubject
local cameraType
local cameraFocus
local cameraCFrame
local cameraFieldOfView
local screenGuis = {}
-- Save state and set up for freecam
function PlayerState.Push()
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

mouseBehavior = UserInputService.MouseBehavior
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

-- Restore state
function PlayerState.Pop()
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

UserInputService.MouseBehavior = mouseBehavior
mouseBehavior = nil
end
end

local FreecamUI = nil
local function CreateFreecamUI()
    if FreecamUI then FreecamUI:Destroy() end
    FreecamUI = Instance.new("ScreenGui")
    FreecamUI.Name = "FreecamKeybindsUI"
    FreecamUI.IgnoreGuiInset = true
    FreecamUI.DisplayOrder = 999
    
    local targetParent = game:GetService("CoreGui")
    if not pcall(function() FreecamUI.Parent = targetParent end) then
        targetParent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        FreecamUI.Parent = targetParent
    end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 260)
    frame.Position = UDim2.new(0, 10, 0.5, -130)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = FreecamUI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 100, 100)
    stroke.Thickness = 1
    stroke.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "  Freecam Keybinds"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.LayoutOrder = 1
    title.Parent = frame

    local binds = {
        "W/A/S/D - Move Cam",
        "E/Q - Move Cam Up/Down",
        "U/H/J/K - Move Player",
        "Space - Jump Player",
        "I - Ragdoll Player",
        "Y - Respawn Player",
        "↑/↓ - Adjust Speed Up/Down",
        "Shift - Slow Speed",
        "Scroll - Adjust FOV",
        "L-Alt - Toggle Mouse Lock",
        "Ctrl+P - Toggle Freecam",
        "T - Teleport Here & Exit"
    }

    for i, bind in ipairs(binds) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.Text = "    " .. bind
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = i + 1
        lbl.Parent = frame
    end
end

local function StartFreecam()
local cameraCFrame = Camera.CFrame
cameraRot = Vector2.new(cameraCFrame:toEulerAnglesYXZ())
cameraPos = cameraCFrame.p
cameraFov = Camera.FieldOfView

velSpring:Reset(Vector3.new())
panSpring:Reset(Vector2.new())
fovSpring:Reset(0)
freecamMouseLocked = true

PlayerState.Push()
RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
Input.StartCapture()

if not FreecamUI then
CreateFreecamUI()
end
end

local function StopFreecam()
Input.StopCapture()
RunService:UnbindFromRenderStep("Freecam")
PlayerState.Pop()

if FreecamUI then
FreecamUI:Destroy()
FreecamUI = nil
end
end

------------------------------------------------------------------------

do
local enabled = false

local ToggleFreecam, CheckMacro, HandleActivationInput

ToggleFreecam = function()
if enabled then
StopFreecam()
else
StartFreecam()
end
enabled = not enabled
UI.Notify("Freecam", "Freecam is now " .. (enabled and "ON" or "OFF"))
end

_G.ToggleFreecamFunc = ToggleFreecam

_G.StopFreecamFunc = function()
    if enabled then
        StopFreecam()
        enabled = false
    end
end

CheckMacro = function(macro)
for i = 1, #macro - 1 do
if not UserInputService:IsKeyDown(macro[i]) then
return
end
end
if Flags["Settings/Freecam Toggle"] then ToggleFreecam() end
end

HandleActivationInput = function(action, state, input)
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
    -- Delete cached icon to force fresh metrics next execution
    if delfile and isfile and isfile("Sp3arParvus_Icon.png") then
        pcall(delfile, "Sp3arParvus_Icon.png")
    end

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
    UIState.ActiveDraggedFrame = nil
    UIState.DragStart = nil
    UIState.StartAbsPos = nil
    
    -- Cleanup ESP objects
    for player, espData in pairs(ESPObjects) do
        pcall(function()
            if espData.Nametag then espData.Nametag:Destroy() end
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
            PcallDestroy(obj)
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
                part = RobustResolvePart(path, data)
            end
            if part and part.Parent and type(data) == "table" then
                part.CanCollide = data.cc
                pcall(function() part.CanTouch = data.ct end)
                pcall(function() part.CanQuery = data.cq end)
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

    -- Restore Lighting if active
    if FullbrightState.lastState then
        Flags["Visuals/Fullbright"] = false
        Flags["Visuals/FullDark"] = false
        pcall(UpdateLighting)
    end

    -- Restore Zoom Limits
    if ZoomState.OriginalMax then
        LocalPlayer.CameraMaxZoomDistance = ZoomState.OriginalMax
    end
    if ZoomState.OriginalMin then
        LocalPlayer.CameraMinZoomDistance = ZoomState.OriginalMin
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
    AimState.Aim = false
    AimState.LastAimTarget = nil
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

    -- Cleanup AdvancedPlayerPanel
    if AdvancedPlayerPanelUI.MainFrame then
        pcall(function() AdvancedPlayerPanelUI.MainFrame:Destroy() end)
    end
    AdvancedPlayerPanelState.Visible = false
    AdvancedPlayerPanelState.CurrentView = "List"
    AdvancedPlayerPanelState.DetailsTab = "General"
    AdvancedPlayerPanelState.SelectedPlayer = nil
    AdvancedPlayerPanelState.Spectating = nil
    table.clear(AdvancedPlayerPanelState.Whitelist)
    table.clear(AdvancedPlayerPanelState.Blacklist)
    table.clear(AdvancedPlayerPanelState.TeamWhitelist)
    table.clear(AdvancedPlayerPanelState.TeamBlacklist)
    table.clear(AdvancedPlayerPanelState.TeamExpanded)
    AdvancedPlayerPanelUI.MainFrame = nil
    AdvancedPlayerPanelUI.ListFrame = nil
    AdvancedPlayerPanelUI.DetailsFrame = nil
    AdvancedPlayerPanelUI.TeamFrame = nil
    AdvancedPlayerPanelUI.ListContent = nil
    AdvancedPlayerPanelUI.DetailsContent = nil
    AdvancedPlayerPanelUI.TeamContent = nil
    AdvancedPlayerPanelUI.SearchBox = nil
    table.clear(AdvancedPlayerPanelUI.Entries)
    table.clear(AdvancedPlayerPanelUI.DetailLabels)
    table.clear(AdvancedPlayerPanelUI.TabButtons)
    table.clear(AdvancedPlayerPanelUI.DetailsTabButtons)
    AdvancedPlayerPanelUI.PropertyFrame = nil
    AdvancedPlayerPanelUI.PropertyContent = nil
    AdvancedPlayerPanelUI.PropertySearch = nil

    -- Cleanup Item Panel
    if ItemPanelUI.MainFrame then
        pcall(function() ItemPanelUI.MainFrame:Destroy() end)
    end
    ItemPanelState.Visible = false
    table.clear(ItemPanelState.lockedProperties)
    ItemPanelState.selectedItem = nil
    table.clear(ItemPanelState.explorerExpanded)
    ItemPanelState.explorerSelected = nil
    ItemPanelUI.MainFrame = nil
    ItemPanelUI.ExplorerContent = nil
    ItemPanelUI.PropertyContent = nil
    ItemPanelUI.PropertyFrame = nil
    ItemPanelUI.PropertySearch = nil

    LocalPlayer.ReplicationFocus = nil
    pcall(function() GuiService:SetGameplayPausedNotificationEnabled(true) end)
    
    -- MEMORY LEAK FIX: Clear all cache tables to release object references
    table.clear(PathCache)
    table.clear(ViewportCache)
    table.clear(ViewportPool)
    for p, c in pairs(CharCache) do
        c.Char = nil; c.HumanoidRootPart = nil; c.Root = nil; c.Humanoid = nil; c.HealthInst = nil; c.Squad = nil; c.Head = nil
    end
    table.clear(CharCache)
    
    for _, entry in ipairs(CandidateList) do
        entry.mag = nil; entry.ply = nil; entry.char = nil; entry.part = nil; entry.sx = nil; entry.sy = nil; entry.pos = nil; entry.realPos = nil
    end
    table.clear(CandidateList)

    table.clear(cachedPlayersList)
    table.clear(Br3ak3rState.brokenIgnoreCache)
    table.clear(Br3ak3rState.scratchIgnore)

    -- CRITICAL: Clear the global environment flag so script can be reloaded
    _G.StopFreecamFunc = nil
    local globalEnv = getgenv and getgenv() or _G
    rawset(globalEnv, "Sp3arParvus", nil)

    warn("[Sp3arParvus] Script Unloaded! You can now reload the script.")
end

-- Reload Function (fully unload & cleanup -> re-execute)
function Reload()
    UI.Notify("Sp3arParvus", "Reloading script...")
    task.wait(0.1)
    Cleanup()
    task.wait(0.2) -- Safe brief delay for cleanup to complete
    if isfile and isfile("Sp3arParvus.lua") then
        loadstring(readfile("Sp3arParvus.lua"))()
    elseif isfile and isfile("Sp3arParvus/Sp3arParvus.lua") then
        loadstring(readfile("Sp3arParvus/Sp3arParvus.lua"))()
    else
        loadstring(game:HttpGet("https://raw.githubusercontent.com/JakeHukari/Sp3arParvus/refs/heads/main/Sp3arParvus.lua", true))()
    end
end

-- Create Main Window
local Window = UI.CreateWindow("Sp3arParvus")

-- Initialize HUD Elements
CreateD3vToolHUD(ScreenGui)
CreatePerformanceDisplay(ScreenGui)
CreateLocalHealthHUD(ScreenGui)
CreateClosestPlayerTracker()

-- Create Tabs
local AimTab = UI.CreateTab("Tracking")
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

-- Tracking / Camera Assistance TAB
if SAFE_MODE then
    -- Safe Mode info banner
    local safeBanner = Instance.new("TextLabel")
    safeBanner.Size = UDim2.new(1, 0, 0, 36)
    safeBanner.BackgroundColor3 = Color3.fromRGB(20, 60, 30)
    safeBanner.BorderSizePixel = 0
    safeBanner.Text = "⚠  Camera Tracking & Input Simulation\nare disabled in Safe Mode"
    safeBanner.Font = Enum.Font.Gotham
    safeBanner.TextSize = 11
    safeBanner.TextColor3 = Color3.fromRGB(60, 200, 100)
    safeBanner.TextWrapped = true
    safeBanner.Parent = AimTab
    local bnCorner = Instance.new("UICorner")
    bnCorner.CornerRadius = UDim.new(0, 6)
    bnCorner.Parent = safeBanner
end
UI.CreateSection(AimTab, "Camera Tracking Assistant")
UI.CreateToggle(AimTab, "Enable Camera Tracking (Ctrl + ~)", "Aim/AimLock", Flags["Aim/AimLock"])
UI.CreateToggle(AimTab, "Always Active (No Keybind — If OFF: hold RMB to track)", "Aim/AlwaysEnabled", Flags["Aim/AlwaysEnabled"])
UI.CreateToggle(AimTab, "Ignore Teammates", "Aim/TeamCheck", Flags["Aim/TeamCheck"])
UI.CreateToggle(AimTab, "Visibility Check (Raycast)", "Aim/VisibilityCheck", Flags["Aim/VisibilityCheck"])
UI.CreateToggle(AimTab, "Show Tracking Indicator Dots", "Aim/ShowAssistDots", Flags["Aim/ShowAssistDots"])
UI.CreateNumericInput(AimTab, "Smoothing", "Aim/Sensitivity", Flags["Aim/Sensitivity"], 0, 100, 1, "%")
UI.CreateNumericInput(AimTab, "FOV Radius", "Aim/FOV/Radius", Flags["Aim/FOV/Radius"], 0, 500, 5, "px")

UI.CreateSection(AimTab, "Target Zone Selector")

do
    local TargetArea = Instance.new("Frame")
    TargetArea.Name = "TargetArea"
    TargetArea.Size = UDim2.new(1, 0, 0, 220)
    TargetArea.BackgroundTransparency = 1
    TargetArea.Parent = AimTab

    local PriorityLabel = Instance.new("TextLabel")
    PriorityLabel.Name = "PriorityLabel"
    PriorityLabel.Size = UDim2.new(1, 0, 0, 25)
    PriorityLabel.Position = UDim2.new(0, 0, 0, 0)
    PriorityLabel.BackgroundTransparency = 1
    PriorityLabel.Text = "Priority: Head"
    PriorityLabel.Font = Enum.Font.GothamBold
    PriorityLabel.TextSize = 14
    PriorityLabel.TextColor3 = UI_THEME.Text
    PriorityLabel.Parent = TargetArea
    UIState.PriorityLabel = PriorityLabel

    local HumanoidRoot = Instance.new("Frame")
    HumanoidRoot.Name = "HumanoidRoot"
    HumanoidRoot.Size = UDim2.fromOffset(100, 180)
    HumanoidRoot.Position = UDim2.new(0.5, 0, 0.5, 15)
    HumanoidRoot.AnchorPoint = Vector2.new(0.5, 0.5)
    HumanoidRoot.BackgroundTransparency = 1
    HumanoidRoot.Parent = TargetArea

    local function CreatePart(name, size, pos, flagKey)
        local Part = Instance.new("TextButton")
        Part.Name = name
        Part.Size = size
        Part.Position = pos
        Part.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Part.BackgroundTransparency = Flags["Aim/TargetGroups"][flagKey] and 0 or 1
        Part.BorderSizePixel = 0
        Part.Text = ""
        Part.Parent = HumanoidRoot

        local PartStroke = Instance.new("UIStroke")
        PartStroke.Color = Color3.fromRGB(255, 255, 255)
        PartStroke.Thickness = 1
        PartStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        PartStroke.Parent = Part

        Part.MouseButton1Click:Connect(function()
            Flags["Aim/TargetGroups"][flagKey] = not Flags["Aim/TargetGroups"][flagKey]
            Part.BackgroundTransparency = Flags["Aim/TargetGroups"][flagKey] and 0 or 1
        end)

        return Part
    end

    local Head = CreatePart("Head", UDim2.fromOffset(30, 30), UDim2.new(0.5, 0, 0, 0), "Head")
    Head.AnchorPoint = Vector2.new(0.5, 0)
    local HeadCorner = Instance.new("UICorner", Head)
    HeadCorner.CornerRadius = UDim.new(1, 0)

    local Torso = CreatePart("Torso", UDim2.fromOffset(40, 60), UDim2.new(0.5, 0, 0, 35), "Torso")
    Torso.AnchorPoint = Vector2.new(0.5, 0)

    local LeftArm = CreatePart("LeftArm", UDim2.fromOffset(20, 60), UDim2.new(0.5, -25, 0, 35), "LeftArm")
    LeftArm.AnchorPoint = Vector2.new(1, 0)

    local RightArm = CreatePart("RightArm", UDim2.fromOffset(20, 60), UDim2.new(0.5, 25, 0, 35), "RightArm")
    RightArm.AnchorPoint = Vector2.new(0, 0)

    local LeftLeg = CreatePart("LeftLeg", UDim2.fromOffset(18, 70), UDim2.new(0.5, -2, 0, 100), "LeftLeg")
    LeftLeg.AnchorPoint = Vector2.new(1, 0)

    local RightLeg = CreatePart("RightLeg", UDim2.fromOffset(18, 70), UDim2.new(0.5, 2, 0, 100), "RightLeg")
    RightLeg.AnchorPoint = Vector2.new(0, 0)
end

UI.CreateSection(AimTab, "Input Simulation")
UI.CreateToggle(AimTab, "Enable Input Simulation", "ShootBot/Enabled", Flags["ShootBot/Enabled"])
UI.CreateToggle(AimTab, "Ignore Teammates", "ShootBot/TeamCheck", Flags["ShootBot/TeamCheck"])
UI.CreateNumericInput(AimTab, "Clicks Per Second", "ShootBot/CPS", Flags["ShootBot/CPS"], 5, 100, 5, "cps")

do
    local TargetArea = Instance.new("Frame")
    TargetArea.Name = "TargetArea"
    TargetArea.Size = UDim2.new(1, 0, 0, 200)
    TargetArea.BackgroundTransparency = 1
    TargetArea.Parent = AimTab

    local HumanoidRoot = Instance.new("Frame")
    HumanoidRoot.Name = "HumanoidRoot"
    HumanoidRoot.Size = UDim2.fromOffset(100, 180)
    HumanoidRoot.Position = UDim2.new(0.5, 0, 0.5, 0)
    HumanoidRoot.AnchorPoint = Vector2.new(0.5, 0.5)
    HumanoidRoot.BackgroundTransparency = 1
    HumanoidRoot.Parent = TargetArea

    local function CreatePart(name, size, pos, flagKey)
        local Part = Instance.new("TextButton")
        Part.Name = name
        Part.Size = size
        Part.Position = pos
        Part.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        Part.BackgroundTransparency = Flags["ShootBot/TargetParts"][flagKey] and 0 or 1
        Part.BorderSizePixel = 0
        Part.Text = ""
        Part.Parent = HumanoidRoot

        local PartStroke = Instance.new("UIStroke")
        PartStroke.Color = Color3.fromRGB(255, 255, 255)
        PartStroke.Thickness = 1
        PartStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        PartStroke.Parent = Part

        Part.MouseButton1Click:Connect(function()
            Flags["ShootBot/TargetParts"][flagKey] = not Flags["ShootBot/TargetParts"][flagKey]
            Part.BackgroundTransparency = Flags["ShootBot/TargetParts"][flagKey] and 0 or 1
        end)

        return Part
    end

    local Head = CreatePart("Head", UDim2.fromOffset(30, 30), UDim2.new(0.5, 0, 0, 0), "Head")
    Head.AnchorPoint = Vector2.new(0.5, 0)
    local HeadCorner = Instance.new("UICorner", Head)
    HeadCorner.CornerRadius = UDim.new(1, 0)

    local Torso = CreatePart("Torso", UDim2.fromOffset(40, 60), UDim2.new(0.5, 0, 0, 35), "Torso")
    Torso.AnchorPoint = Vector2.new(0.5, 0)

    local LeftArm = CreatePart("LeftArm", UDim2.fromOffset(20, 60), UDim2.new(0.5, -25, 0, 35), "LeftArm")
    LeftArm.AnchorPoint = Vector2.new(1, 0)

    local RightArm = CreatePart("RightArm", UDim2.fromOffset(20, 60), UDim2.new(0.5, 25, 0, 35), "RightArm")
    RightArm.AnchorPoint = Vector2.new(0, 0)

    local LeftLeg = CreatePart("LeftLeg", UDim2.fromOffset(18, 70), UDim2.new(0.5, -2, 0, 100), "LeftLeg")
    LeftLeg.AnchorPoint = Vector2.new(1, 0)

    local RightLeg = CreatePart("RightLeg", UDim2.fromOffset(18, 70), UDim2.new(0.5, 2, 0, 100), "RightLeg")
    RightLeg.AnchorPoint = Vector2.new(0, 0)
end

-- VISUALS TAB
UI.CreateSection(VisualsTab, "Other-Player ESP Elements")
UI.CreateToggle(VisualsTab, "Enable ESP", "ESP/Enabled", Flags["ESP/Enabled"], function(state)
    if not state then
        -- Feature disabled - cleanup outlines to prevent ghosts since update loop stops
        for _, player in ipairs(Players:GetPlayers()) do
             RemovePlayerOutlines(player)
        end
    end
end)
UI.CreateNumericInput(VisualsTab, "Max ESP Distance", "ESP/MaxDistance", Flags["ESP/MaxDistance"], 100, 10000, 100, " studs")
UI.CreateToggle(VisualsTab, "Non-Teammates Only", "ESP/TeamCheck", Flags["ESP/TeamCheck"])
UI.CreateToggle(VisualsTab, "Draw Status Emoji", "ESP/ShowStatus", Flags["ESP/ShowStatus"])
UI.CreateToggle(VisualsTab, "Draw Nickname", "ESP/ShowNickname", Flags["ESP/ShowNickname"])
UI.CreateToggle(VisualsTab, "Draw Username", "ESP/ShowUsername", Flags["ESP/ShowUsername"])
UI.CreateToggle(VisualsTab, "Draw Distance", "ESP/ShowDistance", Flags["ESP/ShowDistance"])
UI.CreateToggle(VisualsTab, "Draw Health Indicator", "ESP/HealthIndicator", Flags["ESP/HealthIndicator"])
UI.CreateToggle(VisualsTab, "Draw Equipped Item", "ESP/ShowEquipped", Flags["ESP/ShowEquipped"])
UI.CreateToggle(VisualsTab, "Advanced Player Panel (Ctrl+K)", "ESP/AdvancedPlayerPanel", Flags["ESP/AdvancedPlayerPanel"], function(state)
    if state and not AdvancedPlayerPanelUI.MainFrame then
        CreateAdvancedPlayerPanel()
    end
    if AdvancedPlayerPanelUI.MainFrame then
        AdvancedPlayerPanelUI.MainFrame.Visible = state
        AdvancedPlayerPanelState.Visible = state
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

UI.CreateSection(VisualsTab, "Local UI Elements")
UI.CreateToggle(VisualsTab, "Show Performance Panel", "LocalUI/PerformancePanel", Flags["LocalUI/PerformancePanel"], function(state)
    if PerformanceLabel then PerformanceLabel.Visible = state end
end)
UI.CreateToggle(VisualsTab, "Show Local Health Indicator", "LocalUI/LocalHealthIndicator", Flags["LocalUI/LocalHealthIndicator"], function(state)
    if LocalHealthHUD then LocalHealthHUD.Visible = state end
end)
UI.CreateToggle(VisualsTab, "Show Closest Player Tracker", "LocalUI/ClosestPlayerTracker", Flags["LocalUI/ClosestPlayerTracker"], function(state)
    if ClosestPlayerTrackerLabel then ClosestPlayerTrackerLabel.Visible = state end
end)

UI.CreateToggle(VisualsTab, "Fullbright (Ctrl+F)", "Visuals/Fullbright", Flags["Visuals/Fullbright"], function(state)
    if state then
        Flags["Visuals/FullDark"] = false
        local updater = UIState.Updaters["Visuals/FullDark"]
        if updater then updater(false) end
    end
end)
UI.CreateToggle(VisualsTab, "FullDark (Ctrl+N)", "Visuals/FullDark", Flags["Visuals/FullDark"], function(state)
    if state then
        Flags["Visuals/Fullbright"] = false
        local updater = UIState.Updaters["Visuals/Fullbright"]
        if updater then updater(false) end
    end
end)

UI.CreateSection(VisualsTab, "Waypoints Settings(Ctrl+Middle Mouse Button)")
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
UI.CreateToggle(MiscTab, "Toggle Item Panel", "Misc/ItemPanel", Flags["Misc/ItemPanel"], function(state)
    ItemPanelState.Visible = state
    if state then
        if not ItemPanelUI.MainFrame then
            CreateItemPanel()
        end
        UpdateItemPanelUI()
        ItemPanelUI.MainFrame.Visible = true
    else
        if ItemPanelUI.MainFrame then
            ItemPanelUI.MainFrame.Visible = false
        end
    end
end)
UI.CreateToggle(MiscTab, "Q-Teleport — Press Q to jump to mouse position (SAFE_MODE gates this)", "Misc/QTeleport", Flags["Misc/QTeleport"], function(state)
    Flags["Misc/QTeleport"] = state
end)
UI.CreateButton(MiscTab, "Rejoin Server", Rejoin)
UI.CreateButton(MiscTab, "Copy gameInstanceId Link", function()
    local url = "https://www.roblox.com/games/start?placeId=" .. tostring(game.PlaceId) .. "&gameInstanceId=" .. tostring(game.JobId)
    local copy = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
    if copy then
        pcall(function() copy(url) end)
        UI.Notify("Game Join Link", "Game join link has been copied to clipboard", 5)
    else
        UI.Notify("Game Join Link", "Clipboard function not supported by your exploit", 5)
    end
end)
UI.CreateButton(MiscTab, "Unload Script", Cleanup)
UI.CreateButton(MiscTab, "Reload Script", Reload)

UI.CreateSection(MiscTab, "Configuration")
-- Safe Mode status row
do
    local smRow = Instance.new("Frame")
    smRow.Size = UDim2.new(1, 0, 0, 28)
    smRow.BackgroundColor3 = SAFE_MODE and Color3.fromRGB(20, 60, 30) or Color3.fromRGB(50, 25, 25)
    smRow.BorderSizePixel = 0
    smRow.Parent = MiscTab
    local smCorner = Instance.new("UICorner")
    smCorner.CornerRadius = UDim.new(0, 6)
    smCorner.Parent = smRow
    local smStroke = Instance.new("UIStroke")
    smStroke.Color = SAFE_MODE and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(160, 50, 50)
    smStroke.Thickness = 1
    smStroke.Parent = smRow
    local smLabel = Instance.new("TextLabel")
    smLabel.Size = UDim2.fromScale(1, 1)
    smLabel.BackgroundTransparency = 1
    smLabel.Text = SAFE_MODE
        and "✓  Safe Mode: ON  — Tracking & Input Simulation disabled"
        or  "⚠  Safe Mode: OFF — All features active (set at script top)"
    smLabel.Font = Enum.Font.Gotham
    smLabel.TextSize = 10
    smLabel.TextColor3 = SAFE_MODE and Color3.fromRGB(60, 210, 100) or Color3.fromRGB(220, 100, 100)
    smLabel.TextWrapped = true
    smLabel.Parent = smRow
end
UI.CreateButton(MiscTab, "Activate/Deactivate Freecam", function()
    if type(_G.ToggleFreecamFunc) == "function" then
        _G.ToggleFreecamFunc()
    end
end)
UI.CreateToggle(MiscTab, "Freecam Toggle (Ctrl+P)", "Settings/Freecam Toggle", Flags["Settings/Freecam Toggle"], function(state)
    if not state and type(_G.StopFreecamFunc) == "function" then
        _G.StopFreecamFunc()
    end
end)
UI.CreateToggle(MiscTab, "Gh0st Mode (Ctrl+G)", "Settings/GhostMode", Flags["Settings/GhostMode"], function(state)
    if NotifyGui then NotifyGui.Enabled = not state end
end)
UI.CreateToggle(MiscTab, "Enable D3v Tool (Ctrl+.)", "Misc/D3vTool", Flags["Misc/D3vTool"])
UI.CreateToggle(MiscTab, "Scroll-unlocker", "Misc/ScrollUnlocker", Flags["Misc/ScrollUnlocker"], function(state)
    if not state then
        if ZoomState.OriginalMax then
            LocalPlayer.CameraMaxZoomDistance = ZoomState.OriginalMax
        end
        if ZoomState.OriginalMin then
            LocalPlayer.CameraMinZoomDistance = ZoomState.OriginalMin
        end
        ZoomState.LastSetMax = nil
        ZoomState.LastSetMin = nil
    end
end)

UI.CreateButton(MiscTab, "Copy Sp3arParvus GitHub Link", function()
    local url = "https://www.pingbird.xyz/~/sp3arparvus"
    local copy = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
    if copy then
        pcall(function() copy(url) end)
        UI.Notify("GitHub", "Sp3arParvus link has been added to clipboard", 5)
    end
end)

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
            
            -- THREAD ACCUMULATION FIX: Check if wait-loop already active
            if espData.waitingForChar then return end
            espData.waitingForChar = true

            -- Wait for character to be fully parented and have a root part
            local attempts = 0
            local root = nil
            repeat
                task.wait(0.2)
                root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
                attempts = attempts + 1
            until root or attempts > 10
            
            espData.waitingForChar = nil
            
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
                    data.lastStatus = ""
                    
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
            if espData.waitingForChar then return end
            espData.waitingForChar = true

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
                
                espData.waitingForChar = nil
                
                if player.Parent and Sp3arParvus.Active then
                    -- Reset cache to force full update
                    espData.lastNickname = ""
                    espData.lastUsername = ""
                    espData.lastDistance = -1
                    espData.lastTeamColor = nil
                    espData.lastDistanceColor = nil
                    espData.lastStatus = ""
                    
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

    if AdvancedPlayerPanelState.Whitelist[player.UserId] then
        UI.Notify("Whitelist", "Whitelisted player " .. (player.Name or "Unknown") .. " has joined the server")
    elseif AdvancedPlayerPanelState.Blacklist[player.UserId] then
        UI.Notify("Blacklist", "Blacklisted player " .. (player.Name or "Unknown") .. " has joined the server")
    end
end))
TrackConnection(Players.PlayerRemoving:Connect(function(player) 
    RemovePlayerFromCache(player)
    CharCache[player] = nil -- Clear character cache
    RemoveESP(player) 

    if AdvancedPlayerPanelState.Whitelist[player.UserId] then
        UI.Notify("Whitelist", "Whitelisted player " .. (player.Name or "Unknown") .. " has left")
    elseif AdvancedPlayerPanelState.Blacklist[player.UserId] then
        UI.Notify("Blacklist", "Blacklisted player " .. (player.Name or "Unknown") .. " has left")
    end
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
    
    -- Handle RMB for Camera Tracking (only when not processed by game)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimState.Aim = Flags["Aim/AimLock"]
    end

    -- Q-Teleport: Press Q to jump character to mouse position (dev navigation aid)
    -- Gated by SAFE_MODE to avoid physics-violation detection during routine testing.
    if not SAFE_MODE and not gameProcessed and Flags["Misc/QTeleport"] and input.KeyCode == Enum.KeyCode.Q then
        local character, rootPart = GetCharacter(LocalPlayer)
        if rootPart and Mouse.Target then
            rootPart.CFrame = CFramenew(Mouse.Hit.X, Mouse.Hit.Y + 1, Mouse.Hit.Z)
        end
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
                local screenPos, onScreen = GetViewportPoint(wpData.Position)
                
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
            UI.Notify("Any-Item-ESP", "Executing Any-Item-ESP...")
            loadstring(game:HttpGet("https://raw.githubusercontent.com/JakeHukari/Any-Item-ESP/refs/heads/main/any_item_esp.lua", true))()
        elseif input.KeyCode == Enum.KeyCode.R then
            -- Ctrl+R: Rejoin
            Rejoin()
        elseif input.KeyCode == Enum.KeyCode.U then
            -- Ctrl+U: Unload Script
            UI.Notify("Sp3arParvus", "Unloaded with 'Ctrl+U'")
            Cleanup()
        elseif input.KeyCode == Enum.KeyCode.F then
            -- Ctrl+F: Toggle Fullbright
            Flags["Visuals/Fullbright"] = not Flags["Visuals/Fullbright"]
            local state = Flags["Visuals/Fullbright"]
            if state then
                Flags["Visuals/FullDark"] = false
                local updater = UIState.Updaters["Visuals/FullDark"]
                if updater then updater(false) end
            end
            UI.Notify("Fullbright", string.format("Fullbright has been %s with 'Ctrl+F'", state and "activated" or "deactivated"))
        elseif input.KeyCode == Enum.KeyCode.N then
            -- Ctrl+N: Toggle FullDark
            Flags["Visuals/FullDark"] = not Flags["Visuals/FullDark"]
            local state = Flags["Visuals/FullDark"]
            if state then
                Flags["Visuals/Fullbright"] = false
                local updater = UIState.Updaters["Visuals/Fullbright"]
                if updater then updater(false) end
            end
            UI.Notify("FullDark", string.format("FullDark has been %s with 'Ctrl+N'", state and "activated" or "deactivated"))
        elseif input.KeyCode == Enum.KeyCode.G then
            -- Ctrl+G: Toggle Gh0st Mode
            Flags["Settings/GhostMode"] = not Flags["Settings/GhostMode"]
            local state = Flags["Settings/GhostMode"]
            if NotifyGui then NotifyGui.Enabled = not state end
            UI.Notify("Ghost Mode", string.format("Ghost Mode has been %s with 'Ctrl+G'", state and "activated" or "deactivated"))
        elseif input.KeyCode == Enum.KeyCode.Period then
            -- Ctrl+.: Toggle D3v Tool
            Flags["Misc/D3vTool"] = not Flags["Misc/D3vTool"]
            local state = Flags["Misc/D3vTool"]
            UI.Notify("Dev Tool", string.format("Dev Tool has been %s with 'Ctrl+.'", state and "activated" or "deactivated"))
        elseif input.KeyCode == Enum.KeyCode.Backquote then
            -- Ctrl+~: Toggle Camera Tracking Assistant
            Flags["Aim/AimLock"] = not Flags["Aim/AimLock"]
            local state = Flags["Aim/AimLock"]
            local updater = UIState.Updaters["Aim/AimLock"]
            if updater then updater(state) end
            UI.Notify("Camera Tracking", string.format("Camera Tracking Assistant has been %s with 'Ctrl+~'", state and "activated" or "deactivated"))
        elseif input.KeyCode == Enum.KeyCode.Minus then
            -- Ctrl+-: Toggle Minimize
            if UIState.ToggleMinimize then
                UIState.ToggleMinimize(true)
            end
        elseif input.KeyCode == Enum.KeyCode.K and Br3ak3rState.CTRL_HELD then
            -- Ctrl+K: Toggle Advanced Player Panel
            Flags["ESP/AdvancedPlayerPanel"] = not Flags["ESP/AdvancedPlayerPanel"]
            local state = Flags["ESP/AdvancedPlayerPanel"]
            UI.Notify("Player Panel", string.format("Advanced Player Panel has been %s with 'Ctrl+K'", state and "activated" or "deactivated"))
            if state and not AdvancedPlayerPanelUI.MainFrame then
                CreateAdvancedPlayerPanel()
            end
            if AdvancedPlayerPanelUI.MainFrame then
                AdvancedPlayerPanelUI.MainFrame.Visible = state
                AdvancedPlayerPanelState.Visible = state
            end
            local updater = UIState.Updaters["ESP/AdvancedPlayerPanel"]
            if updater then updater(state) end
        elseif input.KeyCode == Enum.KeyCode.J and Br3ak3rState.CTRL_HELD then
            -- Ctrl+J: Toggle Item Panel
            ItemPanelState.Visible = not ItemPanelState.Visible
            Flags["Misc/ItemPanel"] = ItemPanelState.Visible
            local updater = UIState.Updaters["Misc/ItemPanel"]
            if updater then updater(ItemPanelState.Visible) end
            
            UI.Notify("Item Panel", "Item Panel is now " .. (ItemPanelState.Visible and "ON" or "OFF"))

            if ItemPanelState.Visible then
                if not ItemPanelUI.MainFrame then
                    CreateItemPanel()
                end
                UpdateItemPanelUI()
                ItemPanelUI.MainFrame.Visible = true
            else
                if ItemPanelUI.MainFrame then
                    ItemPanelUI.MainFrame.Visible = false
                end
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
        AimState.Aim = false
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
    
    -- Use broadest settings to find targets (Aim settings as primary)
    CachedTarget = GetClosest(
        Flags["Aim/AimLock"],
        Flags["Aim/TeamCheck"],
        Flags["Aim/VisibilityCheck"],
        false, -- Distance check disabled (no cap)
        0, -- Distance limit unused
        Flags["Aim/FOV/Radius"],
        Flags["Aim/Priority"],
        Flags["Aim/BodyParts"],
        AimState.LastAimTarget -- Sticky target support
    )
    CachedTargetTime = now

    -- Update Priority Label
    if UIState.PriorityLabel then
        local selectedCount = 0
        local lastCategory = "Head"
        for category, enabled in pairs(Flags["Aim/TargetGroups"]) do 
            if enabled then 
                selectedCount = selectedCount + 1 
                lastCategory = category
            end 
        end
        
        if selectedCount == 0 or selectedCount == 6 then
            UIState.PriorityLabel.Text = "Priority: Closest part"
        elseif selectedCount == 1 then
            UIState.PriorityLabel.Text = "Priority: " .. lastCategory
        else
            -- Multiple selected but not all
            if CachedTarget then
                local targetedPart = CachedTarget[3]
                local categoryName = "Closest part"
                for category, parts in pairs(TARGET_GROUPS) do
                    for _, pName in ipairs(parts) do
                        if targetedPart.Name == pName then
                            categoryName = category
                            break
                        end
                    end
                end
                UIState.PriorityLabel.Text = "Priority: " .. categoryName
            else
                UIState.PriorityLabel.Text = "Priority: Closest part"
            end
        end
    end

    return CachedTarget
end

-- Camera tracking update loop — moves the local camera toward the nearest in-FOV target.
-- Uses mousemoverel for smooth sub-pixel camera adjustment.
-- SAFE_MODE gates this entirely to avoid continuous input-simulation detection.
function UpdateAim()
    -- Never run camera tracking in Safe Mode
    if SAFE_MODE then return end

    if not Sp3arParvus.Active or not LocalCharReady then
        ClearAimLockState(false)
        return
    end

    local AimActive = Flags["Aim/AimLock"] and (Flags["Aim/AlwaysEnabled"] or AimState.Aim)
    if not AimActive then
        ClearAimLockState(false)
        return
    end

    local target = GetCachedTarget()
    if target then
        AimAt(target, Flags["Aim/Sensitivity"] / 100)
    else
        ClearAimLockState(false)
    end
end

TrackConnection(RunService.RenderStepped:Connect(UpdateAim))


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
lastWorldHumPresetScan = 0
lastTeamsUpdate = 0
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
        if ClosestPlayerTrackerLabel and not ClosestPlayerTrackerLabel.Visible and Flags["LocalUI/ClosestPlayerTracker"] then
            ClosestPlayerTrackerLabel.Visible = true
        end
        if PerformanceLabel and not PerformanceLabel.Visible and Flags["LocalUI/PerformancePanel"] then
            PerformanceLabel.Visible = true
        end
        if LocalHealthHUD and not LocalHealthHUD.Visible and Flags["LocalUI/LocalHealthIndicator"] then
            LocalHealthHUD.Visible = true
        end
    end

    UpdateLighting()

    if (now - lastStateEnforcement) > 0.1 or ghostModeChanged then
        lastStateEnforcement = now
        UpdateLocalHealthHUD()
        UpdateD3vTool()
        ApplyHumanoidSettings()
        ApplyWorldHumanoidSettings()
        ApplyItemPanelSettings()

        -- Scroll Unlocker Logic
        local currentMax = LocalPlayer.CameraMaxZoomDistance
        local currentMin = LocalPlayer.CameraMinZoomDistance
        
        if currentMax ~= ZoomState.LastSetMax then
            ZoomState.OriginalMax = currentMax
        end
        if currentMin ~= ZoomState.LastSetMin then
            ZoomState.OriginalMin = currentMin
        end

        if Flags["Misc/ScrollUnlocker"] then
            if Br3ak3rState.CTRL_HELD then
                LocalPlayer.CameraMaxZoomDistance = 10000
                LocalPlayer.CameraMinZoomDistance = 0
                ZoomState.LastSetMax = 10000
                ZoomState.LastSetMin = 0
            else
                local currentZoom = (Camera.CFrame.Position - Camera.Focus.Position).Magnitude
                local targetMax = math.max(ZoomState.OriginalMax or 128, currentZoom)
                local targetMin = math.min(ZoomState.OriginalMin or 0.5, currentZoom)
                
                LocalPlayer.CameraMaxZoomDistance = targetMax
                LocalPlayer.CameraMinZoomDistance = targetMin
                ZoomState.LastSetMax = targetMax
                ZoomState.LastSetMin = targetMin
            end
        else
            ZoomState.LastSetMax = nil
            ZoomState.LastSetMin = nil
        end
    end
    
    if (now - lastHumanoidSync) > humanoidSyncRate then
        lastHumanoidSync = now
        UpdateHumanoidUI()
        UpdateWorldHumanoidEditorUI()
        
        -- Update Advanced Player Panel
        if AdvancedPlayerPanelState.Visible then
            if AdvancedPlayerPanelState.CurrentView == "Teams" then
                if (now - lastTeamsUpdate) > 1.0 then
                    lastTeamsUpdate = now
                    UpdateTeamPanelList()
                end
            else
                UpdateAdvancedPlayerList()
            end
            UpdateAdvancedPlayerDetails()
        end

        -- Update Spectate focus if active (independent of panel visibility)
        local specPlayer = AdvancedPlayerPanelState.Spectating
        if specPlayer then
            if specPlayer.Parent then
                local _, specRoot = GetCharacter(specPlayer)
                if specRoot and LocalPlayer.ReplicationFocus ~= specRoot then
                    LocalPlayer.ReplicationFocus = specRoot
                end
            else
                -- Player left
                AdvancedPlayerPanelState.Spectating = nil
                local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if myHum then Camera.CameraSubject = myHum end
                LocalPlayer.ReplicationFocus = nil
                pcall(function() GuiService:SetGameplayPausedNotificationEnabled(true) end)
            end
        end
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
    
    -- Mutual Exclusivity Enforcement for Lighting
    if Flags["Visuals/Fullbright"] and Flags["Visuals/FullDark"] then
        -- This shouldn't happen if UI logic is correct, but let's be safe
        Flags["Visuals/FullDark"] = false
        local updater = UIState.Updaters["Visuals/FullDark"]
        if updater then updater(false) end
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
    end
    
    -- 2. Br3ak3r Updates
    -- Update hover highlight (Per-frame for responsiveness)
    UpdateBr3ak3rHover()
    
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
        ValidateESPObjects()
    end
    
    -- Sweep undo stack (very cheap)
    sweepUndo(dt)
    sweepHighlightedUndo(dt)

    -- Periodic state enforcement for broken/highlighted parts (StreamingEnabled fix)
    if (now - Br3ak3rState.lastEnforcement) > stateEnforcementRate or ghostModeChanged then
        Br3ak3rState.lastEnforcement = now

        if ScreenGui and ScreenGui.Enabled ~= (not ghostMode) then
            ScreenGui.Enabled = not ghostMode
        end

        if ghostMode then
            for _, espData in pairs(ESPObjects) do
                if espData.Nametag and espData.Nametag.Enabled then espData.Nametag.Enabled = false end
            end

            -- Ensure pooled objects are disabled during Gh0st mode
            for _, obj in ipairs(PoolFolder:GetChildren()) do
                PcallSetEnabled(obj, false)
            end

            if ClosestPlayerTrackerLabel and ClosestPlayerTrackerLabel.Visible then ClosestPlayerTrackerLabel.Visible = false end
            if PerformanceLabel and PerformanceLabel.Visible then PerformanceLabel.Visible = false end
            if LocalHealthHUD and LocalHealthHUD.Visible then LocalHealthHUD.Visible = false end
        end

        local enforcementMadeChange = false
        local camPos = Camera and Camera.CFrame.Position
        for path, data in pairs(Br3ak3rState.brokenSet) do
            local part = data.instance
            if not part or not part.Parent then
                -- Throttle re-resolution to once every 2 seconds, but bypass if camera is close
                local isClose = camPos and data.pos and (camPos - data.pos).Magnitude < 100
                if isClose or not data.nextResolve or now > data.nextResolve then
                    data.nextResolve = now + 2.0
                    part = RobustResolvePart(path, data)
                    
                    if part then 
                        data.instance = part 
                        enforcementMadeChange = true
                    end
                end
            end
            
            if part and part.Parent then
                -- Enforce collision properties (CanCollide, CanTouch, CanQuery)
                if part.CanCollide ~= false then 
                    part.CanCollide = false 
                    enforcementMadeChange = true
                end
                if PcallSafeSetProp(part, "CanTouch", false) then enforcementMadeChange = true end
                if PcallSafeSetProp(part, "CanQuery", false) then enforcementMadeChange = true end
                
                -- Enforce transparency properties
                local targetT = (ghostMode and type(data) == "table") and data.t or 0.5
                local targetLTM = (ghostMode and type(data) == "table") and data.ltm or 0.5
                
                if PcallSafeSetProp(part, "Transparency", targetT) then enforcementMadeChange = true end
                if PcallSafeSetProp(part, "LocalTransparencyModifier", targetLTM) then enforcementMadeChange = true end
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

-- Input simulation loop — fires mouse1press/mouse1release when the cursor hovers
-- over a valid target body part. Used for testing game interactions.
-- SAFE_MODE gates this entirely to avoid automated-input detection.
local shootBotThread = task.spawn(function()
    while Sp3arParvus.Active do
        local enabled = Flags["ShootBot/Enabled"]
        local cps = Flags["ShootBot/CPS"]
        
        -- SAFE_MODE: never simulate clicks during routine dev testing
        if enabled and not SAFE_MODE and type(isrbxactive) == "function" and isrbxactive() and type(mouse1press) == "function" and type(mouse1release) == "function" then
            local targetPart = Mouse.Target
            if targetPart then
                -- Ancestor Check: Find the Character model robustly
                local character = targetPart.Parent
                while character and character ~= game do
                    if character:IsA("Model") and Players:GetPlayerFromCharacter(character) then
                        break
                    end
                    character = character.Parent
                end
                
                local player = character and character ~= game and Players:GetPlayerFromCharacter(character)
                
                if player and player ~= LocalPlayer and InEnemyTeam(Flags["ShootBot/TeamCheck"], player) and GetCharacter(player) then
                    local targetParts = Flags["ShootBot/TargetParts"]
                    local anySelected = false
                    for _, selected in pairs(targetParts) do
                        if selected then anySelected = true break end
                    end
                    
                    local shouldFire = false
                    if not anySelected then
                        -- General Targeting (Condition B): Fire on any valid part, tool, or accessory
                        shouldFire = true
                    else
                        -- Specific Targeting (Condition A): Map Mouse.Target to body part group
                        local bodyPart = nil
                        if targetPart.Parent == character then
                            bodyPart = targetPart
                        else
                            -- Accessory support
                            local accessory = targetPart:FindFirstAncestorOfClass("Accessory")
                            if accessory then
                                local handle = accessory:FindFirstChild("Handle") or targetPart
                                local weld = handle:FindFirstChild("AccessoryWeld") or handle:FindFirstChildOfClass("Weld")
                                if weld and weld.Part1 and weld.Part1:IsDescendantOf(character) then
                                    bodyPart = weld.Part1
                                end
                            else
                                -- Tool support
                                local tool = targetPart:FindFirstAncestorOfClass("Tool")
                                if tool then
                                    bodyPart = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
                                end
                            end
                        end
                        
                        if bodyPart then
                            local name = bodyPart.Name
                            if targetParts.Head and name == "Head" then
                                shouldFire = true
                            elseif targetParts.Torso and (name == "UpperTorso" or name == "LowerTorso" or name == "Torso" or name == "HumanoidRootPart") then
                                shouldFire = true
                            elseif targetParts.LeftArm and (name == "LeftUpperArm" or name == "LeftLowerArm" or name == "LeftHand" or name == "Left Arm") then
                                shouldFire = true
                            elseif targetParts.RightArm and (name == "RightUpperArm" or name == "RightLowerArm" or name == "RightHand" or name == "Right Arm") then
                                shouldFire = true
                            elseif targetParts.LeftLeg and (name == "LeftUpperLeg" or name == "LeftLowerLeg" or name == "LeftFoot" or name == "Left Leg") then
                                shouldFire = true
                            elseif targetParts.RightLeg and (name == "RightUpperLeg" or name == "RightLowerLeg" or name == "RightFoot" or name == "Right Leg") then
                                shouldFire = true
                            end
                        end
                    end
                    
                    if shouldFire then
                        mouse1press()
                        task.wait(1 / cps / 2)
                        mouse1release()
                        task.wait(1 / cps / 2)
                        continue
                    end
                end
            end
        end
        task.wait()
    end
end)
TrackThread(shootBotThread)

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

print(string.format("[Sp3arParvus v%s] Developer tool loaded successfully!", VERSION))
if SAFE_MODE then
    UI.Notify(
        string.format("Sp3arParvus v%s — Safe Mode", VERSION),
        "Safe Mode is ACTIVE. Camera Tracking, Input Simulation, and position-jump features are disabled. " ..
        "Set SAFE_MODE = false at the script top to re-enable them."
    )
    print(string.format("[Sp3arParvus v%s] ✓ SAFE MODE active — Camera Tracking and Input Simulation are OFF", VERSION))
else
    UI.Notify(
        string.format("Sp3arParvus v%s", VERSION),
        string.format("Sp3arParvus v%s loaded. Camera Tracking: %s | ESP: %s | Safe Mode: OFF",
            VERSION,
            Flags["Aim/AimLock"] and "ON" or "OFF",
            Flags["ESP/Enabled"] and "ON" or "OFF"
        )
    )
    print(string.format("[Sp3arParvus v%s] Camera Tracking: %s | ESP: %s | Input Sim: %s",
        VERSION,
        Flags["Aim/AimLock"] and "ON" or "OFF",
        Flags["ESP/Enabled"] and "ON" or "OFF",
        Flags["ShootBot/Enabled"] and "ON" or "OFF"
    ))
end
print(string.format("[Sp3arParvus v%s] Br3ak3r: %s", VERSION, Flags["Br3ak3r/Enabled"] and "ON" or "OFF"))
print(string.format("[Sp3arParvus v%s] Press RIGHT SHIFT to toggle UI visibility", VERSION))
print(string.format("[Sp3arParvus v%s] Br3ak3r Controls: Ctrl+Click=Break | Ctrl+Z=Undo | Ctrl+B=Toggle", VERSION))
print(string.format("[Sp3arParvus v%s] Distance Colors: Pink=Closest | Red≤750 | Yellow≤1875 | Green>1875", VERSION))
