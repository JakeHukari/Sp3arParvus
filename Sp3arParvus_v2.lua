-- Version identifier
local VERSION = "2.8.4" -- Wireframe Outlines (Highlight AlwaysOnTop)
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

-- Utility to resolve enums that may have been renamed by Roblox updates
local function ResolveEnumItem(enumContainer, possibleNames)
    for _, name in ipairs(possibleNames) do
        local success, enumItem = pcall(function()
            return enumContainer[name]
        end)

        -- Validate that we got a valid EnumItem, not just any truthy value
        if success and enumItem and typeof(enumItem) == "EnumItem" then
            return enumItem
        end
    end

    return nil
end

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
-- PERFORMANCE CACHING INFRASTRUCTURE
-- ============================================================

-- Cached TweenInfo objects (prevents creating new objects on every tween)
local TWEEN_INSTANT = TweenInfo.new(0.05)
local TWEEN_FAST = TweenInfo.new(0.1)
local TWEEN_MEDIUM = TweenInfo.new(0.2)
local TWEEN_SMOOTH = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_BACK = TweenInfo.new(0.3, Enum.EasingStyle.Back)
local TWEEN_DRAG = TweenInfo.new(0.05)

-- Cached players list (Event-based caching prevents allocation per frame)
local cachedPlayersList = {}

-- Initialize cache immediately
local function InitPlayerCache()
    cachedPlayersList = Players:GetPlayers()
end
InitPlayerCache()

local function GetPlayersCache()
    return cachedPlayersList
end

local function UpdatePlayerCache()
    cachedPlayersList = Players:GetPlayers()
end

local function AddPlayerToCache(player)
    if not table.find(cachedPlayersList, player) then
        table.insert(cachedPlayersList, player)
    end
end

local function RemovePlayerFromCache(player)
    local idx = table.find(cachedPlayersList, player)
    if idx then
        table.remove(cachedPlayersList, idx)
    end
end

-- Cached sorted players for Player Panel (expensive sort operation)
local cachedSortedPlayers = {}
local cachedPlayerListForSort = {}
local lastPlayerCountForSort = 0
local lastSortTime = 0
local SORT_CACHE_DURATION = 0.5 -- Only re-sort every 500ms (was every frame)

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

-- Shared Target Cache (Defined here for scope visibility)
local CachedTarget = nil
local CachedTargetTime = 0

-- Known body parts for targeting
local KnownBodyParts = {
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
    ["Aimbot/AutoFire"] = true,
    ["Aimbot/AlwaysEnabled"] = false,
    ["Aimbot/Prediction"] = true,
    ["Aimbot/TeamCheck"] = false,
    ["Aimbot/DistanceCheck"] = false,
    ["Aimbot/VisibilityCheck"] = true,
    ["Aimbot/Sensitivity"] = 15,
    ["Aimbot/FOV/Radius"] = 100,
    ["Aimbot/DistanceLimit"] = 1000,
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
    ["SilentAim/DistanceLimit"] = 1000,
    ["SilentAim/Priority"] = "Closest",
    ["SilentAim/BodyParts"] = {"Head", "HumanoidRootPart"},
    ["SilentAim/Mode"] = {
        "Raycast", "FindPartOnRayWithIgnoreList",
        "Target", "Hit"
    },

    -- Trigger Bot
    -- ["Trigger/Enabled"] replaced by ["Aimbot/AutoFire"]
    -- ["Trigger/Enabled"] = true,
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
    ["ESP/Tracers"] = false,
    ["ESP/OffscreenIndicators"] = false, -- Off by default for performance
    ["ESP/PlayerPanel"] = false, -- Top 10 closest players panel
    ["ESP/PlayerOutlines"] = true, -- Player body part outlines (off by default for performance)
    ["ESP/MaxDistance"] = 5000,

    -- Performance
    ["Performance/Enabled"] = true,
    
    -- Br3ak3r (Object Breaking Tool)
    ["Br3ak3r/Enabled"] = true
}

-- ============================================================
-- BR3AK3R SYSTEM (Ctrl+Click to hide objects, Ctrl+Z to undo)
-- ============================================================
local CLICKBREAK_ENABLED = true
local UNDO_LIMIT = 25
local RAYCAST_MAX_DISTANCE = 3000

-- Br3ak3r state
local brokenSet = {}        -- [BasePart] = true (parts that are currently hidden)
local brokenIgnoreCache = {} -- Cached array of broken parts for raycast filtering
local scratchIgnore = {}    -- Reusable scratch table for raycast ignore list
local brokenCacheDirty = true
local undoStack = {}        -- LIFO of {part, cc, ltm, t} for undo functionality
local hoverHL = nil         -- Highlight for hover preview
local CTRL_HELD = false     -- Track if Ctrl key is held

-- Br3ak3r reusable RaycastParams (performance optimization)
local br3akerRaycastParams = RaycastParams.new()
br3akerRaycastParams.IgnoreWater = true

-- PERFORMANCE FIX: Cache filter type ONCE at startup, not on every raycast
local Br3ak3rFilterType = (function()
    local ok, val = pcall(function() return Enum.RaycastFilterType.Exclude end)
    if ok and val and typeof(val) == "EnumItem" then return val end
    ok, val = pcall(function() return Enum.RaycastFilterType.Blacklist end)
    if ok and val and typeof(val) == "EnumItem" then return val end
    return nil
end)()

if Br3ak3rFilterType then
    br3akerRaycastParams.FilterType = Br3ak3rFilterType
end

-- Rebuild the broken parts ignore cache for raycasts
local function rebuildBrokenIgnore()
    if not next(brokenSet) then
        table.clear(brokenIgnoreCache)
        brokenCacheDirty = false
        return
    end
    table.clear(brokenIgnoreCache)
    local cacheIndex = 1
    for part, _ in pairs(brokenSet) do
        if part and part:IsDescendantOf(Workspace) then
            brokenIgnoreCache[cacheIndex] = part
            cacheIndex = cacheIndex + 1
        end
    end
    brokenCacheDirty = false
end

-- Get ray from mouse cursor position
local function getMouseRay()
    local mouseLocation = UserInputService:GetMouseLocation()
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return nil end
    
    local ray = Camera:ScreenPointToRay(mouseLocation.X, mouseLocation.Y)
    if not ray then return nil end
    
    return ray.Origin, ray.Direction * RAYCAST_MAX_DISTANCE, mouseLocation.X, mouseLocation.Y
end

-- Raycast with broken parts filtering
-- PERFORMANCE FIX: Removed nested closure function, use inline logic instead
local MAX_IGNORE_COUNT = 200

local function worldRaycastBr3ak3r(origin, direction, ignoreLocalChar, extraIgnore)
    if brokenCacheDirty then
        rebuildBrokenIgnore()
    end
    
    local ignore = scratchIgnore
    table.clear(ignore)
    
    local ignoreCount = 0
    
    -- Always prioritize ignoring the local character
    if ignoreLocalChar then
        local ch = LocalPlayer.Character
        if ch and ignoreCount < MAX_IGNORE_COUNT then
            ignoreCount = ignoreCount + 1
            ignore[ignoreCount] = ch
        end
    end
    
    -- Add extra ignore items
    if extraIgnore then
        for i = 1, #extraIgnore do
            if ignoreCount >= MAX_IGNORE_COUNT then break end
            local item = extraIgnore[i]
            if item then
                ignoreCount = ignoreCount + 1
                ignore[ignoreCount] = item
            end
        end
    end
    
    -- Add broken parts to ignore list
    local brokenCacheLen = #brokenIgnoreCache
    for i = 1, brokenCacheLen do
        if ignoreCount >= MAX_IGNORE_COUNT then break end
        local item = brokenIgnoreCache[i]
        if item then
            ignoreCount = ignoreCount + 1
            ignore[ignoreCount] = item
        end
    end
    
    -- FilterType already set at initialization
    br3akerRaycastParams.FilterDescendantsInstances = ignore
    
    return Workspace:Raycast(origin, direction, br3akerRaycastParams)
end

-- Mark a part as broken (hide it)
local function markBroken(part)
    if not part or not part:IsA("BasePart") then return end
    if brokenSet[part] then return end
    
    brokenSet[part] = true
    brokenCacheDirty = true
    
    -- Save original state for undo
    table.insert(undoStack, {
        part = part,
        cc = part.CanCollide,
        ltm = part.LocalTransparencyModifier,
        t = part.Transparency
    })
    
    -- Limit undo stack size
    if #undoStack > UNDO_LIMIT then
        table.remove(undoStack, 1)
    end
    
    -- Hide the part
    part.CanCollide = false
    part.LocalTransparencyModifier = 1
    part.Transparency = 1
end

-- Undo the last broken part
local function unbreakLast()
    local entry = table.remove(undoStack)
    if not entry or not entry.part or not entry.part:IsDescendantOf(game) then
        if entry and entry.part then
            brokenSet[entry.part] = nil
            brokenCacheDirty = true
        end
        return
    end
    
    brokenSet[entry.part] = nil
    brokenCacheDirty = true
    
    -- Restore original state
    entry.part.CanCollide = entry.cc
    entry.part.LocalTransparencyModifier = entry.ltm
    entry.part.Transparency = entry.t
end

-- Sweep undo stack (periodic cleanup of destroyed parts)
local sweepAccum = 0
local function sweepUndo(dt)
    sweepAccum = sweepAccum + dt
    if sweepAccum < 2 then return end
    sweepAccum = 0
    
    local i = 1
    while i <= #undoStack do
        local entry = undoStack[i]
        if not entry.part or not entry.part:IsDescendantOf(game) then
            if entry and entry.part then
                brokenSet[entry.part] = nil
                brokenCacheDirty = true
            end
            table.remove(undoStack, i)
        else
            i = i + 1
        end
    end
end

-- Prune broken set (remove parts that no longer exist)
local function pruneBrokenSet()
    local removed = false
    for part, _ in pairs(brokenSet) do
        if not part or not part:IsDescendantOf(Workspace) then
            brokenSet[part] = nil
            removed = true
        end
    end
    if removed then
        brokenCacheDirty = true
    end
end

-- Create hover highlight for Br3ak3r preview
local function createHoverHighlight()
    if hoverHL then return hoverHL end
    
    hoverHL = Instance.new("Highlight")
    hoverHL.Name = "Br3ak3r_HoverHighlight"
    hoverHL.FillColor = Color3.fromRGB(255, 105, 180)  -- Pink
    hoverHL.OutlineColor = Color3.fromRGB(255, 255, 255)  -- White
    hoverHL.FillTransparency = 0.6
    hoverHL.OutlineTransparency = 0.2
    hoverHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hoverHL.Enabled = false
    hoverHL.Parent = Workspace
    
    return hoverHL
end

-- Update hover highlight for Br3ak3r (called each frame)
-- PERFORMANCE FIX: Skip raycast entirely when Ctrl not held
local function updateBr3ak3rHover()
    -- Early exit - don't do ANY work if feature disabled or Ctrl not held
    if not CLICKBREAK_ENABLED or not CTRL_HELD then
        if hoverHL and hoverHL.Enabled then
            hoverHL.Enabled = false
        end
        return
    end
    
    if not hoverHL then
        createHoverHighlight()
    end
    
    local origin, direction = getMouseRay()
    if origin and direction then
        local result = worldRaycastBr3ak3r(origin, direction, true)
        local part = result and result.Instance
        if part and part:IsA("BasePart") and not brokenSet[part] then
            hoverHL.Adornee = part
            hoverHL.Enabled = true
        else
            if hoverHL.Enabled then
                hoverHL.Enabled = false
            end
        end
    else
        if hoverHL.Enabled then
            hoverHL.Enabled = false
        end
    end
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================


-- ============================================================
-- MODERN UI LIBRARY
-- ============================================================

local TweenService = game:GetService("TweenService")
local ScreenGui -- Define at top level to be accessible to all functions
local UI = {}
local UIState = {
    MainFrame = nil,
    Tabs = {},
    CurrentTab = nil,
    Visible = true
}

-- UI Constants
local UI_THEME = {
    Background = Color3.fromRGB(18, 18, 18),
    Sidebar = Color3.fromRGB(25, 25, 25),
    Element = Color3.fromRGB(32, 32, 32),
    Accent = Color3.fromRGB(0, 200, 255),
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(0, 220, 100),
    Fail = Color3.fromRGB(220, 50, 50)
}

function UI.CreateWindow(title)
    -- Destroy old instances
    if ScreenGui then ScreenGui:Destroy() end

    -- ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Sp3arParvusUI"
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

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.fromOffset(600, 400)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = UI_THEME.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = UIState.Visible
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

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
    Sidebar.Size = UDim2.new(0, 160, 1, 0)
    Sidebar.BackgroundColor3 = UI_THEME.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    
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
    ContentArea.Size = UDim2.new(1, -170, 1, -20)
    ContentArea.Position = UDim2.new(0, 170, 0, 10)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = MainFrame
    
    UIState.MainFrame = MainFrame
    UIState.ContentArea = ContentArea
    UIState.TabContainer = TabContainer

    -- Dragging Logic Helper
    -- MEMORY LEAK FIX: Track connections and avoid creating new connections on each click
    local function MakeDraggable(Frame)
        local dragging, dragInput, dragStart, startPos
        
        Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Frame.Position
            end
        end)
        
        Frame.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        Frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        
        -- MEMORY LEAK FIX: Track this connection
        TrackConnection(UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                TweenService:Create(Frame, TWEEN_DRAG, {
                    Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                }):Play()
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
    local OldSize = UDim2.fromOffset(600, 400)
    
    MinButton.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        if Minimized then
            OldSize = MainFrame.Size
            TweenService:Create(MainFrame, TWEEN_SMOOTH, {Size = UDim2.fromOffset(600, 30)}):Play()
            ContentArea.Visible = false
            Sidebar.Visible = false
            MinButton.Text = "+"
        else
            TweenService:Create(MainFrame, TWEEN_SMOOTH, {Size = OldSize}):Play()
            task.wait(0.1)
            ContentArea.Visible = true
            Sidebar.Visible = true
            MinButton.Text = "-"
        end
    end)

    -- Toggle Logic (Right Shift)
    -- MEMORY LEAK FIX: Track this connection
    TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightShift then
            UIState.Visible = not UIState.Visible
            MainFrame.Visible = UIState.Visible
            if UIState.Visible then
                MainFrame.Size = UDim2.fromOffset(0,0)
                MainFrame.Visible = true 
                TweenService:Create(MainFrame, TWEEN_BACK, {Size = Minimized and UDim2.fromOffset(600, 30) or UDim2.fromOffset(600, 400)}):Play()
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
    
    local padding = Instance.new("UIPadding")
    padding.PaddingRight = UDim.new(0, 5)
    padding.Parent = Page

    -- Tab Selection Logic
    local function SelectTab()
        -- Deselect all
        for _, t in pairs(UIState.Tabs) do
            TweenService:Create(t.Label, TWEEN_MEDIUM, {TextColor3 = UI_THEME.TextDark}):Play()
            TweenService:Create(t.Indicator, TWEEN_MEDIUM, {BackgroundTransparency = 1}):Play()
            t.Page.Visible = false
        end
        -- Select current
        TweenService:Create(TabLabel, TWEEN_MEDIUM, {TextColor3 = UI_THEME.Text}):Play()
        TweenService:Create(Indicator, TWEEN_MEDIUM, {BackgroundTransparency = 0}):Play()
        Page.Visible = true
        UIState.CurrentTab = name
    end

    TabButton.MouseButton1Click:Connect(SelectTab)
    
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

function UI.CreateToggle(page, text, flag, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 36)
    Frame.BackgroundColor3 = UI_THEME.Element
    Frame.BorderSizePixel = 0
    Frame.Parent = page
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextColor3 = UI_THEME.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
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
    Button.Parent = Frame
    
    Flags[flag] = default
    
    Button.MouseButton1Click:Connect(function()
        Flags[flag] = not Flags[flag]
        local state = Flags[flag]
        
        -- Animate
        local targetColor = state and UI_THEME.Accent or Color3.fromRGB(50, 50, 50)
        local targetPos = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        
        TweenService:Create(Switch, TWEEN_MEDIUM, {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(Knob, TWEEN_SMOOTH, {Position = targetPos}):Play()
        
        if callback then callback(state) end
    end)
end

function UI.CreateSlider(page, text, flag, min, max, default, unit, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 56)
    Frame.BackgroundColor3 = UI_THEME.Element
    Frame.BorderSizePixel = 0
    Frame.Parent = page
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 24)
    Label.Position = UDim2.new(0, 12, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextColor3 = UI_THEME.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 60, 0, 24)
    ValueLabel.AnchorPoint = Vector2.new(1, 0)
    ValueLabel.Position = UDim2.new(1, -12, 0, 4)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default) .. (unit or "")
    ValueLabel.Font = Enum.Font.Gotham
    ValueLabel.TextSize = 12
    ValueLabel.TextColor3 = UI_THEME.TextDark
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Frame
    
    local Track = Instance.new("TextButton") -- Using TextButton for easier input handling area
    Track.Text = ""
    Track.Size = UDim2.new(1, -24, 0, 4)
    Track.Position = UDim2.new(0, 12, 0, 36)
    Track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Track.BorderSizePixel = 0
    Track.AutoButtonColor = false
    Track.Parent = Frame
    
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = Track
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    Fill.BackgroundColor3 = UI_THEME.Accent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = Fill
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 12, 0, 12)
    Circle.AnchorPoint = Vector2.new(0.5, 0.5)
    Circle.Position = UDim2.new(1, 0, 0.5, 0)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    Circle.Parent = Fill
    
    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(1, 0)
    cCorner.Parent = Circle
    
    Flags[flag] = default

    local function Update(input)
        local sizeX = Track.AbsoluteSize.X
        local posX = Track.AbsolutePosition.X
        local percent = math.clamp((input.Position.X - posX) / sizeX, 0, 1)
        local value = math.floor(min + (max - min) * percent)
        
        Flags[flag] = value
        ValueLabel.Text = tostring(value) .. (unit or "")
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        
        if callback then callback(value) end
    end
    
    local dragging = false
    local dragging = false
    
    -- OPTIMIZED: Only connect move/end events while dragging to avoid overhead
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            TweenService:Create(Circle, TWEEN_FAST, {Size = UDim2.fromOffset(16, 16)}):Play()
            Update(input)
            
            local moveConn, endConn
            
            -- Handle dragging
            moveConn = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    Update(input)
                end
            end)
            
            -- Handle release
            endConn = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    TweenService:Create(Circle, TWEEN_FAST, {Size = UDim2.fromOffset(12, 12)}):Play()
                    
                    -- Cleanup connections immediately
                    if moveConn then moveConn:Disconnect() end
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end)
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
    
    Button.MouseButton1Click:Connect(function()
        -- Click animation
        TweenService:Create(Button, TWEEN_INSTANT, {Size = UDim2.new(1, -4, 0, 32)}):Play()
        task.wait(0.05)
        TweenService:Create(Button, TWEEN_INSTANT, {Size = UDim2.new(1, 0, 0, 36)}):Play()
        if callback then callback() end
    end)
end

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

-- FPS counter setup (OPTIMIZED - fixed memory, no allocations per frame)
local GetFPS
do
    local frameCount = 0
    local lastTime = os.clock()
    local cachedFPS = 60
    local updateInterval = 0.25 -- Update every 250ms instead of every frame
    
    GetFPS = function()
        frameCount = frameCount + 1
        local now = os.clock()
        local elapsed = now - lastTime
        
        if elapsed >= updateInterval then
            cachedFPS = frameCount / elapsed
            frameCount = 0
            lastTime = now
        end
        
        return cachedFPS
    end
end

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
    local localSquad = LocalPlayer:FindFirstChild("Squad")
    local playerSquad = Player:FindFirstChild("Squad")
    
    if localSquad and playerSquad then
        if localSquad.Value == playerSquad.Value and localSquad.Value ~= nil then
            return false
        end
    end

    return true
end

-- Get character and check health (Heavily Optimized with Cache)
local CharCache = {} -- [Player] = {Char, Root, Humanoid, HealthInst}

local function GetCharacter(player)
    if not player then return nil end
    
    -- Fast path: Check cache
    local cache = CharCache[player]
    if cache then
        local char = cache.Char
        local root = cache.Root
        
        -- Verify validity (parented)
        if char and char.Parent and root and root.Parent then
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
             -- Invalid cache
             CharCache[player] = nil
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
        if stats then
            healthInst = stats:FindFirstChild("Health")
        end
    end
    
    -- Populate cache
    CharCache[player] = {
        Char = character,
        Root = rootPart,
        Humanoid = humanoid,
        HealthInst = healthInst
    }

    if humanoid and humanoid.Health <= 0 then return nil end
    if healthInst and healthInst.Value <= 0 then return nil end

    return character, rootPart
end

-- ============================================================
-- PHYSICS & BALLISTICS
-- ============================================================

-- Maximum reasonable velocity magnitude (studs/second) - prevents aim snapping to sky
local MAX_TARGET_VELOCITY = 100 -- Most players can't move faster than this legitimately

-- Solve projectile trajectory with gravity (FIXED - clamps extreme values)
local function SolveTrajectory(origin, velocity, time, gravity)
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
    local gravityVector = Vector3.new(0, -gravity * time * time / GravityCorrection, 0)
    local predictedPosition = origin + velocity * time + gravityVector
    
    -- Sanity check: if predicted position is too far from origin, return original
    local predictionOffset = (predictedPosition - origin).Magnitude
    -- Fix: NaN check (NaN > 200 is false in Lua, so we must explicitly check for NaN)
    if predictionOffset ~= predictionOffset or predictionOffset > 200 then 
        return origin -- Fall back to actual position
    end
    
    return predictedPosition
end

-- ============================================================
-- AIMBOT CORE (EXACT CODE FROM PARVUS)
-- ============================================================

-- Raycast for visibility check
-- Cache the FilterType enum value once
local CachedFilterType = (function()
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

local SharedRaycastParams = RaycastParams.new()
SharedRaycastParams.IgnoreWater = true

local function Raycast(Origin, Direction, Filter)
    SharedRaycastParams.FilterDescendantsInstances = Filter

    -- Only set FilterType if we successfully cached a valid enum
    if CachedFilterType then
        SharedRaycastParams.FilterType = CachedFilterType
    end

    return Workspace:Raycast(Origin, Direction, SharedRaycastParams)
end

local function WithinReach(Enabled, Distance, Limit)
    if not Enabled then return true end
    return Distance < Limit
end

-- PERFORMANCE FIX: Reusable filter table for visibility raycasts
local OcclusionFilter = {nil, nil}

local function ObjectOccluded(Enabled, Origin, Position, Object)
    if not Enabled then return false end
    -- Reuse filter table instead of creating new one every call
    OcclusionFilter[1] = Object
    OcclusionFilter[2] = LocalPlayer.Character
    return Raycast(Origin, Position - Origin, OcclusionFilter)
end

-- OPTIMIZED: Reusable result table to avoid allocations per frame
-- Changed to store x,y directly instead of Vector2 to avoid allocations
local ClosestResult = {nil, nil, nil, 0, 0} -- [1]=Player, [2]=Character, [3]=BodyPart, [4]=screenX, [5]=screenY

-- OPTIMIZED: Reusable tables for candidate sorting to avoid per-frame allocations
local CandidateList = {} -- Array of {dist, data...}
local CandidateCount = 0
local MAX_CANDIDATES = 15 -- Cap max candidates to process for performance

-- GetClosest function (HEAVILY OPTIMIZED - Lazy Raycasting)
local function GetClosest(Enabled,
    TeamCheck, VisibilityCheck, DistanceCheck,
    DistanceLimit, FieldOfView, Priority, BodyParts,
    PredictionEnabled
)
    if not Enabled then return nil end
    
    local CameraPosition = Camera.CFrame.Position
    local MouseLocation = UserInputService:GetMouseLocation()
    local mouseX, mouseY = MouseLocation.X, MouseLocation.Y
    
    -- Reset candidate list
    CandidateCount = 0
    
    local players = GetPlayersCache()
    for _, Player in ipairs(players) do
        if Player == LocalPlayer then continue end

        local Character, RootPart = GetCharacter(Player)
        -- Fast existence checks
        if not Character or not RootPart then continue end
        if not InEnemyTeam(TeamCheck, Player) then continue end

        -- Quick distance pre-check using RootPart
        local rootDist = (RootPart.Position - CameraPosition).Magnitude
        if DistanceCheck and rootDist > (DistanceLimit + 50) then continue end
        
        -- Optimization: Start with just RootPart for screen check before iterating all body parts
        local _, rootOnScreen = Camera:WorldToViewportPoint(RootPart.Position)
        if not rootOnScreen then continue end

        -- Gather valid body parts
        if Priority == "Random" then
            -- For Random, just pick one valid part and check it
            local BodyPart = Character:FindFirstChild(BodyParts[math.random(#BodyParts)])
            if BodyPart then
                 local BodyPartPosition = BodyPart.Position
                 local Distance = (BodyPartPosition - CameraPosition).Magnitude
                 
                 if not DistanceCheck or Distance < DistanceLimit then
                     -- Prediction
                     if PredictionEnabled then
                         BodyPartPosition = SolveTrajectory(BodyPartPosition, 
                            BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity)
                     end

                     local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
                     if OnScreen then
                         local screenX, screenY = ScreenPosition.X, ScreenPosition.Y
                         local dx, dy = screenX - mouseX, screenY - mouseY
                         local Magnitude = sqrt(dx*dx + dy*dy)
                         
                         if Magnitude < FieldOfView then
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
                             entry.pos = BodyPartPosition -- Predicted position
                         end
                     end
                 end
            end
        else
            -- Check specified body parts
            -- Optimization: If Priority is specific part (e.g. Head), only check that. 
            -- If Priority is "Closest", check all parts in list
            local checkParts = BodyParts
            if Priority ~= "Closest" and Priority ~= "Random" then
                checkParts = {Priority}
            end
            
            for _, PartName in ipairs(checkParts) do
                local BodyPart = Character:FindFirstChild(PartName)
                if not BodyPart then continue end
                
                local BodyPartPosition = BodyPart.Position
                local Distance = (BodyPartPosition - CameraPosition).Magnitude
                 
                if DistanceCheck and Distance >= DistanceLimit then continue end

                -- Prediction
                if PredictionEnabled then
                    BodyPartPosition = SolveTrajectory(BodyPartPosition, 
                       BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity)
                end

                 local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
                 if OnScreen then
                     local screenX, screenY = ScreenPosition.X, ScreenPosition.Y
                     local dx, dy = screenX - mouseX, screenY - mouseY
                     local Magnitude = sqrt(dx*dx + dy*dy)
                     
                     if Magnitude < FieldOfView then
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
                         entry.pos = BodyPartPosition
                     end
                 end
            end
        end
    end
    
    -- Clear stale entries from the list to ensure table.sort works correctly
    -- The list size might remain large from previous frames otherwise
    for i = CandidateCount + 1, #CandidateList do
        CandidateList[i] = nil
    end
    
    if CandidateCount == 0 then return nil end
    
    -- Sort candidates by screen distance (Magnitude)
    -- We only sort the used portion of the list
    if CandidateCount > 1 then
        table.sort(CandidateList, function(a, b)
            -- Handle potential nil entries in sparse array if any (sanity check)
            if not a then return false end
            if not b then return true end
            return a.mag < b.mag
        end)
    end
    
    -- Iterate sorted candidates and perform Raycast on the closest ones
    -- Stop at the FIRST visible candidate
    local limit = min(CandidateCount, MAX_CANDIDATES)
    
    for i = 1, limit do
        local entry = CandidateList[i]
        if not entry then continue end
        
        -- Lazy Visibility Check
        if ObjectOccluded(VisibilityCheck, CameraPosition, entry.pos, entry.char) then
            continue -- Blocked, try next closest
        end
        
        -- Found best target!
        ClosestResult[1] = entry.ply
        ClosestResult[2] = entry.char
        ClosestResult[3] = entry.part
        ClosestResult[4] = entry.sx
        ClosestResult[5] = entry.sy
        
        return ClosestResult
    end
    
    return nil
end

-- AimAt function (FIXED - handles mouse-locked mode properly)
local function AimAt(Hitbox, Sensitivity)
    if not Hitbox then return end
    if not mousemoverel then return end
    
    -- Get the body part from hitbox
    local BodyPart = Hitbox[3]
    if not BodyPart or not BodyPart.Parent then return end
    
    -- Get FRESH world position (not cached screen position)
    local BodyPartPosition = BodyPart.Position
    
    -- Apply prediction if enabled (same logic as GetClosest)
    if Flags["Aimbot/Prediction"] then
        local CameraPosition = Camera.CFrame.Position
        local Distance = (BodyPartPosition - CameraPosition).Magnitude
        BodyPartPosition = SolveTrajectory(BodyPartPosition,
            BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity)
    end
    
    -- Calculate FRESH screen position from current camera
    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
    
    -- Safety check - don't aim at targets behind camera
    -- WorldToViewportPoint returns Z < 0 for points behind camera
    if not OnScreen or ScreenPosition.Z < 0 then return end
    
    -- Determine mouse/crosshair location based on mouse behavior
    local MouseLocation
    local mouseBehavior = UserInputService.MouseBehavior
    
    -- In LockCenter mode (shift-lock/first-person), use viewport center directly
    -- This avoids stale GetMouseLocation() during mode transitions
    if mouseBehavior == Enum.MouseBehavior.LockCenter then
        local viewportSize = Camera.ViewportSize
        MouseLocation = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    else
        MouseLocation = UserInputService:GetMouseLocation()
    end
    
    -- Calculate delta movement
    local deltaX = (ScreenPosition.X - MouseLocation.X) * Sensitivity
    local deltaY = (ScreenPosition.Y - MouseLocation.Y) * Sensitivity
    
    -- NaN Safety Check: If delta is invalid, abort immediately
    if deltaX ~= deltaX or deltaY ~= deltaY then
        return
    end
    
    -- Sanity check - prevent extreme movements (likely error or edge case)
    -- 180-degree spin would require moving roughly half the screen width
    local maxDelta = min(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 0.3 -- 30% of screen
    if abs(deltaX) > maxDelta or abs(deltaY) > maxDelta then
        return -- Skip this frame, let aim catch up naturally
    end
    
    mousemoverel(deltaX, deltaY)
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
        -- PERFORMANCE: Removed pcall overhead
        if checkcaller() then
            return OldIndex(Self, Index)
        end

        if SilentAim and math.random(100) <= Flags["SilentAim/HitChance"] then
            local Mode = Flags["SilentAim/Mode"]
            if Self == Mouse then
                if Index == "Target" and table.find(Mode, Index) then
                    -- Verify target validity
                    if SilentAim[3] and SilentAim[3].Parent then
                        return SilentAim[3]
                    end
                elseif Index == "Hit" and table.find(Mode, Index) then
                     if SilentAim[3] and SilentAim[3].Parent then
                        return SilentAim[3].CFrame
                     end
                end
            end
        end

        return OldIndex(Self, Index)
    end)
end

-- Hook __namecall for Workspace:Raycast, Camera methods, etc.
local OldNamecall = nil
if hookmetamethod and checkcaller and getnamecallmethod then
    OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
        -- PERFORMANCE: Removed pcall overhead
        if checkcaller() then
            return OldNamecall(Self, ...)
        end

        if SilentAim and math.random(100) <= Flags["SilentAim/HitChance"] then
            local Method = getnamecallmethod()
            local Mode = Flags["SilentAim/Mode"]
            
            -- Validation check
            if not SilentAim[3] or not SilentAim[3].Parent then
                 return OldNamecall(Self, ...)
            end

            if Self == Workspace then
                if Method == "Raycast" and table.find(Mode, Method) then
                    local args = {...}
                    if args[1] then
                        args[2] = SilentAim[3].Position - args[1]
                        return OldNamecall(Self, unpack(args))
                    end
                elseif (Method == "FindPartOnRayWithIgnoreList" and table.find(Mode, Method))
                or (Method == "FindPartOnRayWithWhitelist" and table.find(Mode, Method))
                or (Method == "FindPartOnRay" and table.find(Mode, Method)) then
                    local args = {...}
                    if args[1] then
                         -- Reconstruct ray safely
                         args[1] = Ray.new(args[1].Origin, SilentAim[3].Position - args[1].Origin)
                         return OldNamecall(Self, unpack(args))
                    end
                end
            elseif Self == Camera then
                if (Method == "ScreenPointToRay" and table.find(Mode, Method))
                or (Method == "ViewportPointToRay" and table.find(Mode, Method)) then
                    return Ray.new(SilentAim[3].Position, SilentAim[3].Position - Camera.CFrame.Position)
                elseif (Method == "WorldToScreenPoint" and table.find(Mode, Method))
                or (Method == "WorldToViewportPoint" and table.find(Mode, Method)) then
                    local args = {...}
                    args[1] = SilentAim[3].Position
                    return OldNamecall(Self, unpack(args))
                end
            end
        end

        return OldNamecall(Self, ...)
    end)
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================

local ESPObjects = {} -- [Player] = {Nametag, Tracer, Connections}
local PlayerOutlineObjects = {} -- [Player] = { [BodyPartName] = Highlight instance }

local CLOSEST_COLOR = Color3.fromRGB(255, 105, 180) -- Pink (always for closest)
local NORMAL_COLOR = Color3.fromRGB(255, 255, 255)  -- White
local TRACER_COLOR = Color3.fromRGB(0, 255, 255)    -- Cyan
local OUTLINE_COLOR = Color3.fromRGB(255, 105, 180) -- Pink (same as closest player indicator)

-- Off-screen indicator settings
local OFFSCREEN_EDGE_PADDING = 50  -- Pixels from screen edge
local OFFSCREEN_ARROW_SIZE = 20    -- Size of the direction arrow
local OFFSCREEN_INDICATOR_COLOR = Color3.fromRGB(255, 200, 50) -- Yellow/gold for visibility

-- Distance-based color zones (for tracker, but closest overrides to pink)
local COLOR_CLOSE = Color3.fromRGB(255, 50, 50)     -- Red (0-2000 studs)
local COLOR_MID = Color3.fromRGB(255, 200, 50)      -- Yellow (2001-4000 studs)
local COLOR_FAR = Color3.fromRGB(50, 255, 50)       -- Green (4000+ studs)

-- Closest Player Tracker variables
local ClosestPlayerTrackerLabel
local TrackerMinimized = false
local TrackerOriginalSize = UDim2.fromOffset(220, 70)
local NearestPlayerRef = nil
local CurrentTargetDistance = 0 -- Track distance for color coding
local TrackerStrokeRef = nil -- Cached stroke reference to avoid repeated lookups

-- Get color based on distance (Pink=Closest, Red≤2000, Yellow≤4000, Green>4000)
local function GetDistanceColor(distance, isClosest)
    if isClosest then
        return CLOSEST_COLOR -- Pink always overrides for closest player
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
local function GetTeamColor(player)
    if not player then return NORMAL_COLOR end
    
    -- Optimized: No pcall needed for standard property access
    if player.Team then
        return player.TeamColor.Color
    end
    
    return NORMAL_COLOR
end

-- PERFORMANCE: Cache camera data per-frame for off-screen calculations
local cachedCameraData = {
    cFrame = nil,
    position = nil,
    lookVector = nil,
    rightVector = nil,
    upVector = nil,
    viewportSize = nil,
    cacheTime = 0
}
local CAMERA_CACHE_DURATION = 0.016 -- Cache for 1 frame (~60fps)

local function UpdateCameraCache()
    local now = os.clock()
    if (now - cachedCameraData.cacheTime) < CAMERA_CACHE_DURATION then
        return true -- Cache is still valid
    end
    
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return false end
    
    cachedCameraData.cFrame = Camera.CFrame
    cachedCameraData.position = Camera.CFrame.Position
    cachedCameraData.lookVector = Camera.CFrame.LookVector
    cachedCameraData.rightVector = Camera.CFrame.RightVector
    cachedCameraData.upVector = Camera.CFrame.UpVector
    cachedCameraData.viewportSize = Camera.ViewportSize
    cachedCameraData.cacheTime = now
    return true
end

-- Calculate screen edge position for off-screen indicator
-- Returns the position clamped to screen edges and the angle toward the target
-- PERFORMANCE: Uses cached camera data to avoid redundant property access
local function GetEdgePosition(worldPosition)
    -- Update camera cache (shared across all players per frame)
    if not UpdateCameraCache() then return nil, nil, false end
    
    local viewportSize = cachedCameraData.viewportSize
    
    -- Still need to call WorldToViewportPoint per-player (can't cache this)
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return nil, nil, false end
    local screenPos, onScreen = Camera:WorldToViewportPoint(worldPosition)
    
    -- If on screen, return nil (use normal nametag)
    if onScreen and screenPos.X > OFFSCREEN_EDGE_PADDING and screenPos.X < viewportSize.X - OFFSCREEN_EDGE_PADDING
       and screenPos.Y > OFFSCREEN_EDGE_PADDING and screenPos.Y < viewportSize.Y - OFFSCREEN_EDGE_PADDING then
        return nil, nil, true
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
    
    return Vector2.new(edgeX, edgeY), angle, false
end

-- Create off-screen indicator UI element
local function CreateOffscreenIndicator()
    local indicator = Instance.new("Frame")
    indicator.Name = "OffscreenIndicator"
    indicator.Size = UDim2.fromOffset(120, 50)
    indicator.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    indicator.BackgroundTransparency = 0.3
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.ZIndex = 100
    indicator.Parent = ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = indicator
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = OFFSCREEN_INDICATOR_COLOR
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
    arrow.ImageColor3 = OFFSCREEN_INDICATOR_COLOR
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
    distLabel.TextColor3 = OFFSCREEN_INDICATOR_COLOR
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
local function CreateClosestPlayerTracker()
    ClosestPlayerTrackerLabel = Instance.new("TextLabel")
    ClosestPlayerTrackerLabel.Name = "ClosestPlayerTracker"
    ClosestPlayerTrackerLabel.Size = TrackerOriginalSize
    ClosestPlayerTrackerLabel.Position = UDim2.new(0.5, -110, 0, 10)
    ClosestPlayerTrackerLabel.BackgroundTransparency = 0.2
    ClosestPlayerTrackerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ClosestPlayerTrackerLabel.TextColor3 = CLOSEST_COLOR
    ClosestPlayerTrackerLabel.Font = Enum.Font.GothamBold
    ClosestPlayerTrackerLabel.TextSize = 14
    ClosestPlayerTrackerLabel.TextXAlignment = Enum.TextXAlignment.Center
    ClosestPlayerTrackerLabel.TextYAlignment = Enum.TextYAlignment.Center
    ClosestPlayerTrackerLabel.BorderSizePixel = 0
    ClosestPlayerTrackerLabel.Text = "Closest Player\nSearching..."
    ClosestPlayerTrackerLabel.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = ClosestPlayerTrackerLabel

    local stroke = Instance.new("UIStroke")
    stroke.Color = CLOSEST_COLOR
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = ClosestPlayerTrackerLabel
    TrackerStrokeRef = stroke -- Cache the reference

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
    minimizeBtn.TextColor3 = CLOSEST_COLOR
    minimizeBtn.Parent = ClosestPlayerTrackerLabel

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = minimizeBtn

    minimizeBtn.MouseButton1Click:Connect(function()
        TrackerMinimized = not TrackerMinimized
        if TrackerMinimized then
            ClosestPlayerTrackerLabel.Size = UDim2.fromOffset(220, 30)
            ClosestPlayerTrackerLabel.Text = "Closest Player"
            minimizeBtn.Text = "+"
        else
            ClosestPlayerTrackerLabel.Size = TrackerOriginalSize
            minimizeBtn.Text = "−"
        end
    end)
    
    if UI.MakeDraggable then
        UI.MakeDraggable(ClosestPlayerTrackerLabel)
    end
end

-- Update Nearest Player (finds closest player once)
local function UpdateNearestPlayer()
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
local function UpdateClosestPlayerTracker()
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

                -- Update colors based on distance (closest = always pink)
                local color = GetDistanceColor(distance, true) -- true = is closest
                ClosestPlayerTrackerLabel.TextColor3 = color

                -- Update stroke color to match (using cached reference)
                if TrackerStrokeRef then
                    TrackerStrokeRef.Color = color
                end

                CurrentTargetDistance = distRounded
                ClosestPlayerTrackerLabel.Text = string.format("Closest Player\n%s\n%d studs away", name, distRounded)
            else
                ClosestPlayerTrackerLabel.Text = "Closest Player\n---"
                ClosestPlayerTrackerLabel.TextColor3 = CLOSEST_COLOR
            end
        else
            ClosestPlayerTrackerLabel.Text = "Closest Player\nNo players nearby"
            ClosestPlayerTrackerLabel.TextColor3 = CLOSEST_COLOR
            NearestPlayerRef = nil
        end
    end
end

-- ============================================================
-- PLAYER PANEL (Top 10 Closest Players)
-- ============================================================

local PlayerPanelFrame = nil
local PlayerPanelRows = {}
local PlayerPanelMinimized = false
local PLAYER_PANEL_MAX_ROWS = 10

-- Calculate direction angle for arrow (returns rotation in degrees)
local function GetDirectionToPlayer(targetPosition)
    if not Camera then Camera = Workspace.CurrentCamera end
    if not Camera then return 0 end
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return 0 end
    
    local myPos = myRoot.Position
    local direction = (targetPosition - myPos)
    
    -- Get camera's forward direction (ignoring Y)
    local camLook = Camera.CFrame.LookVector
    local camRight = Camera.CFrame.RightVector
    
    -- Calculate angle relative to camera
    local forward2D = Vector2.new(camLook.X, camLook.Z).Unit
    local right2D = Vector2.new(camRight.X, camRight.Z).Unit
    local dir2D = Vector2.new(direction.X, direction.Z)
    
    if dir2D.Magnitude < 0.01 then return 0 end
    dir2D = dir2D.Unit
    
    -- Dot product gives us the angle components
    local forwardDot = forward2D.X * dir2D.X + forward2D.Y * dir2D.Y
    local rightDot = right2D.X * dir2D.X + right2D.Y * dir2D.Y
    
    local angle = atan2(rightDot, forwardDot)
    return deg(angle)
end

-- Create the Player Panel UI
local function CreatePlayerPanel()
    if PlayerPanelFrame then return end
    
    -- Main container
    PlayerPanelFrame = Instance.new("Frame")
    PlayerPanelFrame.Name = "PlayerPanel"
    PlayerPanelFrame.Size = UDim2.fromOffset(320, 340)
    PlayerPanelFrame.Position = UDim2.new(0, 10, 0.5, -170)
    PlayerPanelFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    PlayerPanelFrame.BackgroundTransparency = 0.1
    PlayerPanelFrame.BorderSizePixel = 0
    PlayerPanelFrame.Visible = false
    PlayerPanelFrame.ZIndex = 50
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
    minimizeBtn.MouseButton1Click:Connect(function()
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
    end)
    
    -- Make draggable
    if UI.MakeDraggable then
        UI.MakeDraggable(PlayerPanelFrame)
    end
end

-- Get sorted list of closest players (OPTIMIZED - uses caching to avoid GC spikes)
local function GetSortedPlayersByDistance()
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
    
    -- Clear any extra entries from previous iterations
    for i = insertIdx + 1, #cachedPlayerListForSort do
        cachedPlayerListForSort[i] = nil
    end
    
    -- Sort by distance (closest first)
    table.sort(cachedPlayerListForSort, function(a, b)
        return a.distance < b.distance
    end)
    
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
local DIRECTION_ARROWS = {
    "↑", "↗", "→", "↘", "↓", "↙", "←", "↖"
}

local function GetArrowForAngle(angleDeg)
    -- Normalize angle to 0-360
    local normalized = (angleDeg + 180) % 360
    -- Convert to 8 segments (0-7)
    local segment = floor((normalized + 22.5) / 45) % 8
    return DIRECTION_ARROWS[segment + 1] or "→"
end

-- Update Player Panel
local function UpdatePlayerPanel()
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
        lastUsername = "",
        lastDistance = -1,
        lastTeamColor = nil,
        lastDistanceColor = nil,
        Connections = {} -- Store player-specific connections here
    }

    -- Create nametag (BillboardGui) with Username, Nickname, and Distance
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Nametag"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 60) -- Increased height for 3 lines
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = nil

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
    nicknameLabel.Name = "NicknameLabel"
    nicknameLabel.Size = UDim2.new(1, 0, 0, 18)
    nicknameLabel.BackgroundTransparency = 1
    nicknameLabel.TextColor3 = NORMAL_COLOR
    nicknameLabel.TextStrokeTransparency = 0
    nicknameLabel.Font = Enum.Font.GothamBold
    nicknameLabel.TextSize = 14
    nicknameLabel.LayoutOrder = 1
    nicknameLabel.Parent = container

    -- Username (@name) - Middle line (colored by team)
    local usernameLabel = Instance.new("TextLabel")
    usernameLabel.Name = "UsernameLabel"
    usernameLabel.Size = UDim2.new(1, 0, 0, 18)
    usernameLabel.BackgroundTransparency = 1
    usernameLabel.TextColor3 = NORMAL_COLOR
    usernameLabel.TextStrokeTransparency = 0
    usernameLabel.Font = Enum.Font.GothamBold
    usernameLabel.TextSize = 14
    usernameLabel.LayoutOrder = 2
    usernameLabel.Parent = container

    -- Distance label - Bottom line (colored by distance heat-map)
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0, 18)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = NORMAL_COLOR
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextSize = 14
    distanceLabel.LayoutOrder = 3
    distanceLabel.Parent = container

    espData.Nametag = billboard
    espData.NicknameLabel = nicknameLabel
    espData.UsernameLabel = usernameLabel
    espData.DistanceLabel = distanceLabel

    -- Create tracer (Frame based for AlwaysOnTop)
    -- Using a Frame instead of Drawing ensures it renders through walls
    local tracer = Instance.new("Frame")
    tracer.Name = "Tracer"
    tracer.Visible = false
    tracer.BackgroundColor3 = TRACER_COLOR
    tracer.BorderSizePixel = 0
    tracer.AnchorPoint = Vector2.new(0.5, 0.5) -- Center anchor for rotation
    tracer.Parent = ScreenGui -- Render on top of everything
    
    espData.Tracer = tracer

    -- Create off-screen indicator
    espData.OffscreenIndicator = CreateOffscreenIndicator()
    espData.lastOffscreenVisible = false

    ESPObjects[player] = espData
end

-- Create/Update player body part outlines (Highlight based for Wireframe + AlwaysOnTop)
-- OPTIMIZED: Object Pooling to prevent churning
local ObjectPool = {
    Highlights = {},
    Billboards = {}
}

local function GetPooledObject(poolName, className)
    local pool = ObjectPool[poolName]
    if #pool > 0 then
        local obj = table.remove(pool)
        if obj.Parent then obj.Parent = nil end -- Safety
        return obj
    end
    return Instance.new(className)
end

local function ReturnPooledObject(obj)
    if not obj then return end
    
    obj.Adornee = nil
    obj.Parent = nil
    
    if obj:IsA("Highlight") then
        table.insert(ObjectPool.Highlights, obj)
    elseif obj:IsA("BillboardGui") then
        table.insert(ObjectPool.Billboards, obj)
    else
        obj:Destroy()
    end
end
local function UpdatePlayerOutlines(player, character)
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
        local highlight = GetPooledObject("Highlights", "Highlight")
        highlight.Name = "PlayerOutlineHighlight"
        highlight.Adornee = character
        highlight.FillColor = OUTLINE_COLOR
        highlight.FillTransparency = 1 -- Invisible fill (Wireframe only)
        highlight.OutlineColor = OUTLINE_COLOR
        highlight.OutlineTransparency = 0 -- Fully visible outline
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Visible through walls
        highlight.Enabled = true
        highlight.Parent = character
        
        storage.Highlight = highlight
    else
        local highlight = storage.Highlight
        -- Validate existence
        if not highlight then -- Parent check removed, we can re-parent
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
        if highlight.OutlineColor ~= OUTLINE_COLOR then
            highlight.OutlineColor = OUTLINE_COLOR
        end
        if not highlight.Enabled then
            highlight.Enabled = true
        end
    end

    -- Helper to create/update Dot Indicator
    local function UpdateDot(dotType, partName)
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
            dot.Parent = character
            
            -- Check if we need to recreate the child frame (it might be gone if we pooled a destroyed gui)
            -- But since we pool logic correctly, children should stay.
            -- However, let's verify children exist
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
            if dot.Adornee ~= part then
                dot.Adornee = part
                dot.Parent = character
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

    -- Update Head and Root dots
    UpdateDot("HeadDot", "Head")
    UpdateDot("RootDot", "HumanoidRootPart")
end

-- Remove all outlines for a player (Optimized: Return to pool)
local function RemovePlayerOutlines(player)
    local storage = PlayerOutlineObjects[player]
    if not storage then return end
    
    -- Cleanup Highlight
    if storage.Highlight then
        ReturnPooledObject(storage.Highlight)
    end
    
    -- Cleanup Billboard dots
    if storage.HeadDot then ReturnPooledObject(storage.HeadDot) end
    if storage.RootDot then ReturnPooledObject(storage.RootDot) end
    
    -- Cleanup any legacy parts
    for k, v in pairs(storage) do
        if k ~= "Highlight" and k ~= "HeadDot" and k ~= "RootDot" then
            if v and v.Parent then v:Destroy() end
        end
    end
    
    PlayerOutlineObjects[player] = nil
end

-- Update ESP for a player (optimized - uses cached closest player)
local function UpdateESP(player, isClosest)
    if not Flags["ESP/Enabled"] then return end

    local espData = ESPObjects[player]
    
    -- Check if ESP data exists and if the Nametag is still valid (not destroyed)
    if espData then
        -- Check if nametag is valid
        local nametag = espData.Nametag
        if not nametag or not nametag.Parent then
            -- Recreate if missing
             -- Fix: Capture connections to preserve them (prevents untracked CharacterAdded listeners)
             local savedConnections = espData.Connections
             
             if nametag then nametag:Destroy() end
             if espData.Tracer then espData.Tracer:Destroy() end -- Fix: Use Destroy instead of Remove (deprecated)
             
             -- Fix: Explicitly destroy OffscreenIndicator to prevent memory leak
             if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
                 espData.OffscreenIndicator.Frame:Destroy()
             end
             
             ESPObjects[player] = nil
             espData = nil
             
             -- Recreate immediately to restore connections
             CreateESP(player)
             espData = ESPObjects[player]
             if espData then
                 espData.Connections = savedConnections
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

    -- Distance culling
    if distance > Flags["ESP/MaxDistance"] then
        RemovePlayerOutlines(player)
        if espData.Nametag then espData.Nametag.Enabled = false end
        if espData.Tracer then espData.Tracer.Visible = false end
        if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
            espData.OffscreenIndicator.Frame.Visible = false
        end
        return
    end

    -- Update nametag
    if Flags["ESP/Nametags"] and espData.Nametag then
        local nametag = espData.Nametag
        -- Ensure nametag is attached and enabled
        if nametag.Adornee ~= rootPart then
            nametag.Adornee = rootPart
            nametag.Parent = rootPart
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
            local length = math.sqrt(diffX*diffX + diffY*diffY)
            local rotation = math.deg(math.atan2(diffY, diffX))
            
            tracerLine.Visible = true
            tracerLine.Size = UDim2.fromOffset(length, 1)
            tracerLine.Position = UDim2.fromOffset((originX + targetX)/2, (originY + targetY)/2)
            tracerLine.Rotation = rotation
        else
            espData.Tracer.Visible = false
        end
    elseif espData.Tracer then
        espData.Tracer.Visible = false
    end

    -- Update off-screen indicator
    if Flags["ESP/Nametags"] and Flags["ESP/OffscreenIndicators"] and espData.OffscreenIndicator then
        local indicator = espData.OffscreenIndicator
        local edgePos, angle, isOnScreen = GetEdgePosition(rootPart.Position)
        
        if isOnScreen then
            if espData.lastOffscreenVisible then
                indicator.Frame.Visible = false
                espData.lastOffscreenVisible = false
            end
        elseif edgePos then
            if not espData.lastOffscreenVisible then
                indicator.Frame.Visible = true
                espData.lastOffscreenVisible = true
            end
            
            -- Only update pos if moved > 5px for perf
            local newX = floor(edgePos.X - 60)
            local newY = floor(edgePos.Y - 25)
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
local function RemoveESP(player)
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

    ESPObjects[player] = nil
end

-- ============================================================
-- PERFORMANCE DISPLAY
-- ============================================================

local PerformanceLabel
local PerfMinimized = false
local PerfOriginalSize = UDim2.fromOffset(180, 95)

local function CreatePerformanceDisplay(parent)
    PerformanceLabel = Instance.new("TextLabel")
    PerformanceLabel.Name = "PerformanceDisplay"
    PerformanceLabel.Size = PerfOriginalSize
    PerformanceLabel.Position = UDim2.new(1, -190, 0, 10)
    PerformanceLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    PerformanceLabel.BackgroundTransparency = 0.3
    PerformanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    PerformanceLabel.Font = Enum.Font.Code
    PerformanceLabel.TextSize = 10
    PerformanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    PerformanceLabel.Text = "Loading..." -- Initial text
    PerformanceLabel.BorderSizePixel = 0
    PerformanceLabel.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = PerformanceLabel

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 4)
    padding.Parent = PerformanceLabel

    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minimizeBtn.BackgroundTransparency = 0.5
    minimizeBtn.Size = UDim2.fromOffset(16, 16)
    minimizeBtn.Position = UDim2.new(1, -20, 0, 4)
    minimizeBtn.Text = "-"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 12
    minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Parent = PerformanceLabel

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 4)
    mCorner.Parent = minimizeBtn

    minimizeBtn.MouseButton1Click:Connect(function()
        PerfMinimized = not PerfMinimized
        if PerfMinimized then
            PerformanceLabel.Size = UDim2.fromOffset(180, 24)
            PerformanceLabel.TextYAlignment = Enum.TextYAlignment.Center
            PerformanceLabel.Text = "Performance Stats"
            minimizeBtn.Text = "+"
        else
            PerformanceLabel.Size = PerfOriginalSize
            PerformanceLabel.TextYAlignment = Enum.TextYAlignment.Top
            minimizeBtn.Text = "-"
        end
    end)

    if UI.MakeDraggable then
        UI.MakeDraggable(PerformanceLabel)
    end
end

local function UpdatePerformanceDisplay()
    if not Flags["Performance/Enabled"] or not PerformanceLabel then return end

    -- Only update if visible (performance optimization)
    if not PerformanceLabel.Visible then return end

    local fps = floor(GetFPS())
    local ping = floor(Ping:GetValue())
    local playerCount = #GetPlayersCache()

    -- Get memory usage (MB)
    local memoryUsed = floor(Stats:GetTotalMemoryUsageMb())

    -- PERFORMANCE FIX: Use playerCount - 1 instead of iterating ESPObjects
    -- This is a good approximation since ESP is created for all non-local players
    local activeTargets = max(0, playerCount - 1)

    -- Aimbot lock status
    local aimbotStatus = "─"
    if Aimbot or Flags["Aimbot/AlwaysEnabled"] then
        aimbotStatus = "🔒" -- Locked indicator
    end

    -- FPS color coding
    local fpsColor
    if fps >= 60 then
        fpsColor = Color3.fromRGB(50, 255, 50) -- Green
    elseif fps >= 30 then
        fpsColor = Color3.fromRGB(255, 200, 50) -- Yellow
    else
        fpsColor = Color3.fromRGB(255, 50, 50) -- Red
    end

    PerformanceLabel.TextColor3 = fpsColor

    PerformanceLabel.Text = string.format(
        "FPS: %d\nPing: %d ms\nPlayers: %d\nTargets: %d\nMemory: %d MB\nAimbot: %s",
        fps, ping, playerCount, activeTargets, memoryUsed, aimbotStatus
    )
end

-- ============================================================
-- MAIN INITIALIZATION & CLEANUP
-- ============================================================

-- Cleanup Function (FIXED - properly clears global state for reload)
local function Cleanup()
    Sp3arParvus.Active = false

    -- Disconnect all tracked connections
    for _, conn in pairs(Sp3arParvus.Connections) do
        pcall(function()
            if conn then conn:Disconnect() end
        end)
    end
    table.clear(Sp3arParvus.Connections)

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
    
    -- Cleanup ESP objects
    for player, espData in pairs(ESPObjects) do
        pcall(function()
            if espData.Nametag then espData.Nametag:Destroy() end
            if espData.Tracer then espData.Tracer:Remove() end
            if espData.OffscreenIndicator and espData.OffscreenIndicator.Frame then
                espData.OffscreenIndicator.Frame:Destroy()
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

    -- Cleanup Br3ak3r (restore all broken parts)
    for part, _ in pairs(brokenSet) do
        pcall(function()
            -- Find original state in undo stack
            for i = #undoStack, 1, -1 do
                local entry = undoStack[i]
                if entry.part == part then
                    part.CanCollide = entry.cc
                    part.LocalTransparencyModifier = entry.ltm
                    part.Transparency = entry.t
                    break
                end
            end
        end)
    end
    table.clear(brokenSet)
    table.clear(undoStack)
    table.clear(brokenIgnoreCache)
    brokenCacheDirty = true
    CTRL_HELD = false
    
    -- Cleanup hover highlight
    if hoverHL then
        pcall(function() hoverHL:Destroy() end)
        hoverHL = nil
    end

    -- Reset module-level state
    SilentAim = nil
    Aimbot = false
    Trigger = false
    CachedTarget = nil
    NearestPlayerRef = nil
    PerformanceLabel = nil
    ClosestPlayerTrackerLabel = nil
    PlayerPanelFrame = nil
    table.clear(PlayerPanelRows)

    -- CRITICAL: Clear the global environment flag so script can be reloaded
    local globalEnv = getgenv and getgenv() or _G
    rawset(globalEnv, "Sp3arParvusV2", nil)

    warn("[Sp3arParvus] Script Unloaded! You can now reload the script.")
end

-- Create Main Window
local Window = UI.CreateWindow("Sp3arParvusV2")

-- Initialize HUD Elements
CreatePerformanceDisplay(ScreenGui)
CreateClosestPlayerTracker()

-- Create Tabs
local AimTab = UI.CreateTab("Aimbot")
local VisualsTab = UI.CreateTab("Visuals")
local MiscTab = UI.CreateTab("Misc")
local SettingsTab = UI.CreateTab("Settings")

-- AIMBOT TAB
UI.CreateSection(AimTab, "General Aim")
UI.CreateToggle(AimTab, "Enable Aim Lock", "Aimbot/AimLock", Flags["Aimbot/AimLock"])
UI.CreateToggle(AimTab, "Enable Auto Fire", "Aimbot/AutoFire", Flags["Aimbot/AutoFire"])
UI.CreateToggle(AimTab, "Always Active (No Keybind, If OFF: hold RMB to Lock)", "Aimbot/AlwaysEnabled", Flags["Aimbot/AlwaysEnabled"])
UI.CreateToggle(AimTab, "Team Check", "Aimbot/TeamCheck", Flags["Aimbot/TeamCheck"])
UI.CreateToggle(AimTab, "Visibility Check", "Aimbot/VisibilityCheck", Flags["Aimbot/VisibilityCheck"])
UI.CreateSlider(AimTab, "Smoothing", "Aimbot/Sensitivity", 0, 100, Flags["Aimbot/Sensitivity"], "%")
UI.CreateSlider(AimTab, "FOV Radius", "Aimbot/FOV/Radius", 0, 500, Flags["Aimbot/FOV/Radius"], "px")
UI.CreateSlider(AimTab, "Distance Limit", "Aimbot/DistanceLimit", 25, 3000, Flags["Aimbot/DistanceLimit"], " st")

UI.CreateSection(AimTab, "Ballistics")
UI.CreateToggle(AimTab, "Predict Movement", "Aimbot/Prediction", Flags["Aimbot/Prediction"])
UI.CreateSlider(AimTab, "Bullet Speed", "Prediction/Velocity", 100, 5000, Flags["Prediction/Velocity"], " st/s", function(v) ProjectileSpeed = v end)
UI.CreateSlider(AimTab, "Gravity Scale", "Prediction/GravityMultiplier", 0, 5, Flags["Prediction/GravityMultiplier"], "x", function(v) GravityCorrection = v end)

UI.CreateSection(AimTab, "Silent Aim")
UI.CreateToggle(AimTab, "Enable Silent Aim", "SilentAim/Enabled", Flags["SilentAim/Enabled"])
UI.CreateSlider(AimTab, "Hit Chance", "SilentAim/HitChance", 0, 100, Flags["SilentAim/HitChance"], "%")
UI.CreateSlider(AimTab, "Silent FOV", "SilentAim/FOV/Radius", 0, 500, Flags["SilentAim/FOV/Radius"], "px")

UI.CreateSection(AimTab, "Trigger Bot")
-- Linked to Auto Fire
UI.CreateToggle(AimTab, "Enable Trigger", "Aimbot/AutoFire", Flags["Aimbot/AutoFire"])
UI.CreateToggle(AimTab, "Hold Fire", "Trigger/HoldMouseButton", Flags["Trigger/HoldMouseButton"])
UI.CreateSlider(AimTab, "Trigger Delay", "Trigger/Delay", 0, 100, Flags["Trigger/Delay"], "ms", function(v) Flags["Trigger/Delay"] = v/1000 end)

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
UI.CreateSlider(VisualsTab, "Maximum Distance", "ESP/MaxDistance", 100, 8000, Flags["ESP/MaxDistance"], " st")

-- MISC TAB
UI.CreateSection(MiscTab, "Br3ak3r Tool")
UI.CreateToggle(MiscTab, "Enable Br3ak3r", "Br3ak3r/Enabled", Flags["Br3ak3r/Enabled"], function(state)
    CLICKBREAK_ENABLED = state
    if not state and hoverHL then
        hoverHL.Enabled = false
    end
end)
UI.CreateButton(MiscTab, "Undo Last Break (Ctrl+Z)", unbreakLast)

UI.CreateSection(MiscTab, "Utilities")
UI.CreateButton(MiscTab, "Rejoin Server", Rejoin)
UI.CreateButton(MiscTab, "Unload Script", Cleanup)

-- SETTINGS TAB
UI.CreateSection(SettingsTab, "Configuration")
UI.CreateToggle(SettingsTab, "Show Performance Stats", "Performance/Enabled", Flags["Performance/Enabled"], function(state)
    if PerformanceLabel then PerformanceLabel.Visible = state end
end)

-- Helper to setup player ESP and connections
local function SetupPlayerESP(player)
    if player == LocalPlayer then return end
    
    CreateESP(player)
    local espData = ESPObjects[player]
    
    if espData then
        -- Track CharacterAdded connection LOCALLY in espData, not globally
        -- this ensures it gets cleaned up when the player leaves
        local conn = player.CharacterAdded:Connect(function(character)
            -- FIX: Invalidate character cache immediately on spawn
            CharCache[player] = nil
            
            task.delay(0.1, function()
                if player.Parent and Sp3arParvus.Active then
                    -- Force ESP update for this player when their character spawns
                    if ESPObjects[player] then -- Re-fetch in case it changed
                        local data = ESPObjects[player]
                        data.lastNickname = ""
                        data.lastUsername = ""
                        data.lastDistance = -1
                        data.lastTeamColor = nil
                        data.lastDistanceColor = nil
                    end
                end
            end)
        end)
        table.insert(espData.Connections, conn)
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

-- ============================================================
-- MAIN UPDATE LOOPS
-- ============================================================

-- CONSOLIDATED Input Handler (includes Br3ak3r Ctrl+Click functionality)
TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Track Ctrl key state
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        CTRL_HELD = true
    end
    
    -- Handle RMB for Aimbot/Trigger (only when not processed by game)
    if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aimbot = Flags["Aimbot/AimLock"]
        Trigger = Flags["Aimbot/AutoFire"]
    end
    
    -- Br3ak3r: Ctrl+Click to break object
    if not gameProcessed and CTRL_HELD and input.UserInputType == Enum.UserInputType.MouseButton1 and CLICKBREAK_ENABLED then
        local origin, direction = getMouseRay()
        if origin and direction then
            local hit = worldRaycastBr3ak3r(origin, direction, true)
            if hit and hit.Instance and hit.Instance:IsA("BasePart") then
                markBroken(hit.Instance)
            end
        end
    end
    
    -- Br3ak3r keyboard shortcuts (only when not processed by game)
    if not gameProcessed and CTRL_HELD and input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.Z then
            -- Ctrl+Z: Undo last break
            unbreakLast()
        elseif input.KeyCode == Enum.KeyCode.B then
            -- Ctrl+B: Toggle Br3ak3r
            CLICKBREAK_ENABLED = not CLICKBREAK_ENABLED
            Flags["Br3ak3r/Enabled"] = CLICKBREAK_ENABLED
            if not CLICKBREAK_ENABLED and hoverHL then
                hoverHL.Enabled = false
            end
        end
    end
end))

-- CONSOLIDATED InputEnded Handler (includes Ctrl key tracking)
TrackConnection(UserInputService.InputEnded:Connect(function(input)
    -- Track Ctrl key release
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        CTRL_HELD = false
    end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Aimbot = false
        Trigger = false
    end
end))

-- OPTIMIZED: Shared target cache (prevents redundant GetClosest calls)
-- GetClosest is EXPENSIVE (iterates all players + raycasts) - call it ONCE per frame max
local TARGET_CACHE_DURATION = 0.016 -- ~1 frame at 60fps

local function GetCachedTarget()
    local now = os.clock()
    if CachedTarget and (now - CachedTargetTime) < TARGET_CACHE_DURATION then
        return CachedTarget
    end
    
    -- Use broadest settings to find targets (Aimbot settings as primary)
    CachedTarget = GetClosest(
        Flags["Aimbot/Enabled"] or Flags["SilentAim/Enabled"] or Flags["Trigger/Enabled"],
        Flags["Aimbot/TeamCheck"],
        Flags["Aimbot/VisibilityCheck"],
        Flags["Aimbot/DistanceCheck"],
        Flags["Aimbot/DistanceLimit"],
        max(Flags["Aimbot/FOV/Radius"], Flags["SilentAim/FOV/Radius"], Flags["Trigger/FOV/Radius"]),
        Flags["Aimbot/Priority"],
        Flags["Aimbot/BodyParts"],
        Flags["Aimbot/Prediction"]
    )
    CachedTargetTime = now
    return CachedTarget
end

-- Aimbot & Silent Aim update loop (OPTIMIZED - uses cached target)
local function UpdateAimAndSilent()
    if not Sp3arParvus.Active then return end
    
    -- PERFORMANCE FIX: Early exit if nothing is enabled - prevents expensive GetClosest calls
    -- Logic Fix: Aimbot/AimLock is the master switch. AlwaysEnabled just bypasses keybind check (if implemented)
    local aimbotActive = Flags["Aimbot/AimLock"] and (Flags["Aimbot/AlwaysEnabled"] or Aimbot) -- Aimbot global var acts as keybind state
    local silentActive = Flags["SilentAim/Enabled"]
    
    if not aimbotActive and not silentActive then
        SilentAim = nil
        return
    end

    -- Get cached target (single GetClosest call per frame)
    local target = GetCachedTarget()
    
    -- Silent Aim uses cached target
    SilentAim = silentActive and target or nil

    -- Aimbot uses cached target
    if aimbotActive and target then
        AimAt(target, Flags["Aimbot/Sensitivity"] / 100)
    end
end

TrackConnection(RunService.RenderStepped:Connect(UpdateAimAndSilent))

-- Trigger bot loop (FIXED - maintains fire while target is alive)
local triggerThread = task.spawn(function()
    local MAX_TRIGGER_ITERATIONS = 1000
    while Sp3arParvus.Active do
        if Trigger or Flags["Aimbot/AutoFire"] or Flags["Trigger/AlwaysEnabled"] then
            if isrbxactive and isrbxactive() and mouse1press and mouse1release then
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

                            -- Break if target died, player left, or trigger released
                            if not targetStillValid or not Trigger then break end
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

-- ESP update loop (OPTIMIZED - throttled updates, no per-frame player iteration)
local lastEspUpdate = 0
local espUpdateRate = 0.2 -- ~5 FPS for ESP (reduced from 10fps - big perf gain on low-end devices)
local lastTrackerUpdate = 0
local trackerUpdateRate = 0.5 -- Tracker updates at ~2 FPS (reduced from 3fps)
local lastBr3ak3rCleanup = 0
local br3ak3rCleanupRate = 2.0 
local lastHoverUpdate = 0
local hoverUpdateRate = 0.033 -- Hover at 30fps

-- Unified Heartbeat Loop (Optimized: Single connection for all non-render-critical updates)
-- Combines ESP, Tracker, Br3ak3r logic into one scheduler
local function UnifiedHeartbeat(dt)
    if not Sp3arParvus.Active then return end
    
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

    if (shouldUpdateEsp or forceUpdateTarget) and Flags["ESP/Enabled"] then
        if shouldUpdateEsp then
            lastEspUpdate = now
        end
        
        -- Update ESP for all players
        local players = GetPlayersCache()
        for _, player in ipairs(players) do
            if player ~= LocalPlayer then
                -- Standard update if throttled timer allows, OR force update if this is the locked target
                if shouldUpdateEsp or (player == forceUpdateTarget) then
                   UpdateESP(player, player == NearestPlayerRef)
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
        updateBr3ak3rHover()
    end
    
    -- Periodic cleanup (throttled)
    if (now - lastBr3ak3rCleanup) > br3ak3rCleanupRate then
        lastBr3ak3rCleanup = now
        pruneBrokenSet()
    end
    
    -- Sweep undo stack (very cheap)
    sweepUndo(dt)
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

-- ============================================================
-- INITIALIZATION COMPLETE
-- ============================================================

print(string.format("[Sp3arParvus v%s] Loaded successfully!", VERSION))
print(string.format("[Sp3arParvus v%s] Aimbot: %s | Silent Aim: %s | Trigger: %s | ESP: %s",
    VERSION,
    Flags["Aimbot/AimLock"] and "ON" or "OFF",
    Flags["SilentAim/Enabled"] and "ON" or "OFF",
    Flags["Aimbot/AutoFire"] and "ON" or "OFF",
    Flags["ESP/Enabled"] and "ON" or "OFF"
))
print(string.format("[Sp3arParvus v%s] Br3ak3r: %s", VERSION, Flags["Br3ak3r/Enabled"] and "ON" or "OFF"))
print(string.format("[Sp3arParvus v%s] Press RIGHT SHIFT to toggle UI visibility", VERSION))
print(string.format("[Sp3arParvus v%s] Br3ak3r Controls: Ctrl+Click=Break | Ctrl+Z=Undo | Ctrl+B=Toggle", VERSION))
print(string.format("[Sp3arParvus v%s] Distance Colors: Pink=Closest | Red≤2000 | Yellow≤4000 | Green>4000", VERSION))