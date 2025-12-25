-- Version identifier
local VERSION = "2.3.5"
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
    ["Aimbot/Sensitivity"] = 30,
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
    local function MakeDraggable(Frame)
        local dragging, dragInput, dragStart, startPos
        Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Frame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        Frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                TweenService:Create(Frame, TweenInfo.new(0.05), {
                    Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                }):Play()
            end
        end)
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
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(600, 30)}):Play()
            ContentArea.Visible = false
            Sidebar.Visible = false
            MinButton.Text = "+"
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = OldSize}):Play()
            task.wait(0.1)
            ContentArea.Visible = true
            Sidebar.Visible = true
            MinButton.Text = "-"
        end
    end)

    -- Toggle Logic (Right Shift)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.RightShift then
            UIState.Visible = not UIState.Visible
            MainFrame.Visible = UIState.Visible
            if UIState.Visible then
                MainFrame.Size = UDim2.fromOffset(0,0)
                MainFrame.Visible = true 
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = Minimized and UDim2.fromOffset(600, 30) or UDim2.fromOffset(600, 400)}):Play()
            end
        end
    end)

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
            TweenService:Create(t.Label, TweenInfo.new(0.2), {TextColor3 = UI_THEME.TextDark}):Play()
            TweenService:Create(t.Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            t.Page.Visible = false
        end
        -- Select current
        TweenService:Create(TabLabel, TweenInfo.new(0.2), {TextColor3 = UI_THEME.Text}):Play()
        TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
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
        
        TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        
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
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            TweenService:Create(Circle, TweenInfo.new(0.1), {Size = UDim2.fromOffset(16, 16)}):Play()
            Update(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            TweenService:Create(Circle, TweenInfo.new(0.1), {Size = UDim2.fromOffset(12, 12)}):Play()
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            Update(input)
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
        TweenService:Create(Button, TweenInfo.new(0.05), {Size = UDim2.new(1, -4, 0, 32)}):Play()
        task.wait(0.05)
        TweenService:Create(Button, TweenInfo.new(0.05), {Size = UDim2.new(1, 0, 0, 36)}):Play()
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
    local localSquad = LocalPlayer:FindFirstChild("Squad")
    local playerSquad = Player:FindFirstChild("Squad")
    
    if localSquad and playerSquad then
        if localSquad.Value == playerSquad.Value and localSquad.Value ~= nil then
            return false
        end
    end

    return true
end

-- Get character and check health (Optimized)
local function GetCharacter(player)
    if not player then return nil end
    local character = player.Character
    if not character or not character.Parent then return nil end

    local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not rootPart then return nil end

    -- Optimization: Check standard Humanoid first (faster/more common)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if humanoid.Health > 0 then
            return character, rootPart
        end
        -- If humanoid exists but dead, return nil immediately
        return nil
    end

    -- Fallback to AR2 Stats.Health check (only if no humanoid found)
    local success, health = pcall(function()
        return player.Stats.Health.Value
    end)

    if success and health and health > 0 then
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

local function ObjectOccluded(Enabled, Origin, Position, Object)
    if not Enabled then return false end
    return Raycast(Origin, Position - Origin, {Object, LocalPlayer.Character})
end

-- EXACT GetClosest function from working Parvus (Optimized)
local function GetClosest(Enabled,
    TeamCheck, VisibilityCheck, DistanceCheck,
    DistanceLimit, FieldOfView, Priority, BodyParts,
    PredictionEnabled
)
    if not Enabled then return end
    local CameraPosition, Closest = Camera.CFrame.Position, nil
    
    -- Optimization: Pre-calculate mouse location once
    local MouseLocation = UserInputService:GetMouseLocation()

    for Index, Player in ipairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end

        -- Optimization: Quick team check before character search (if possible)
        -- Note: We need character for Squad check, so we do standard checks first
        if LocalPlayer.Team and Player.Team and LocalPlayer.Team == Player.Team and TeamCheck then
             -- Simple team check failed, might still be squad, but usually good enough to skip if strictly simple teams
             -- But we'll stick to full check to be safe
        end

        local Character, RootPart = GetCharacter(Player)
        if not Character or not RootPart then continue end
        if not InEnemyTeam(TeamCheck, Player) then continue end

        -- Optimization: Quick Distance Check using RootPart
        -- Avoids iterating bodyparts if player is wildly out of range
        local rootDist = (RootPart.Position - CameraPosition).Magnitude
        if DistanceCheck and rootDist > (DistanceLimit + 50) then continue end

        if Priority == "Random" then
            local BodyPart = Character:FindFirstChild(BodyParts[math.random(#BodyParts)])
            if not BodyPart then continue end

            local BodyPartPosition = BodyPart.Position
            local Distance = (BodyPartPosition - CameraPosition).Magnitude
            
            -- Strict distance check on actual body part
            if not WithinReach(DistanceCheck, Distance, DistanceLimit) then continue end

            BodyPartPosition = PredictionEnabled and SolveTrajectory(BodyPartPosition,
            BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity) or BodyPartPosition
            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
            ScreenPosition = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
            if not OnScreen then continue end

            if ObjectOccluded(VisibilityCheck, CameraPosition, BodyPartPosition, Character) then continue end

            local Magnitude = (ScreenPosition - MouseLocation).Magnitude
            if Magnitude >= FieldOfView then continue end

            return {Player, Character, BodyPart, ScreenPosition}
        elseif Priority ~= "Closest" then
            local BodyPart = Character:FindFirstChild(Priority)
            if not BodyPart then continue end

            local BodyPartPosition = BodyPart.Position
            local Distance = (BodyPartPosition - CameraPosition).Magnitude
            
             -- Strict distance check
            if not WithinReach(DistanceCheck, Distance, DistanceLimit) then continue end

            BodyPartPosition = PredictionEnabled and SolveTrajectory(BodyPartPosition,
            BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity) or BodyPartPosition
            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
            ScreenPosition = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
            if not OnScreen then continue end

            if ObjectOccluded(VisibilityCheck, CameraPosition, BodyPartPosition, Character) then continue end

            local Magnitude = (ScreenPosition - MouseLocation).Magnitude
            if Magnitude >= FieldOfView then continue end

            return {Player, Character, BodyPart, ScreenPosition}
        end

        for Index, BodyPartName in ipairs(BodyParts) do
            local BodyPart = Character:FindFirstChild(BodyPartName)
            if not BodyPart then continue end

            local BodyPartPosition = BodyPart.Position
            local Distance = (BodyPartPosition - CameraPosition).Magnitude
            
            if not WithinReach(DistanceCheck, Distance, DistanceLimit) then continue end
            
            BodyPartPosition = PredictionEnabled and SolveTrajectory(BodyPartPosition,
            BodyPart.AssemblyLinearVelocity, Distance / ProjectileSpeed, ProjectileGravity) or BodyPartPosition
            local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(BodyPartPosition)
            ScreenPosition = Vector2.new(ScreenPosition.X, ScreenPosition.Y)
            if not OnScreen then continue end

            if ObjectOccluded(VisibilityCheck, CameraPosition, BodyPartPosition, Character) then continue end

            local Magnitude = (ScreenPosition - MouseLocation).Magnitude
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

local CLOSEST_COLOR = Color3.fromRGB(255, 105, 180) -- Pink (always for closest)
local NORMAL_COLOR = Color3.fromRGB(255, 255, 255)  -- White
local TRACER_COLOR = Color3.fromRGB(0, 255, 255)    -- Cyan

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

-- Get color based on distance (Red=0-2000, Yellow=2001-4000, Green=4000+)
local function GetDistanceColor(distance, isClosest)
    if isClosest then
        return CLOSEST_COLOR -- Pink always overrides for closest player
    end

    if distance <= 1000 then
        return COLOR_CLOSE -- Red
    elseif distance <= 2000 then
        return COLOR_MID -- Yellow
    else
        return COLOR_FAR -- Green
    end
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

    -- Find closest alive player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Parent then
            local success = pcall(function()
                local character, rootPart = GetCharacter(player)
                if character and rootPart then
                    local dist = (rootPart.Position - myRootPos).Magnitude
                    if not bestDist or dist < bestDist then
                        bestDist = dist
                        best = player
                    end
                end
            end)
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
            local success = pcall(function()
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

                    -- Update stroke color to match
                    local stroke = ClosestPlayerTrackerLabel:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        stroke.Color = color
                    end

                    CurrentTargetDistance = distRounded
                    ClosestPlayerTrackerLabel.Text = string.format("Closest Player\n%s\n%d studs away", name, distRounded)
                else
                    ClosestPlayerTrackerLabel.Text = "Closest Player\n---"
                    ClosestPlayerTrackerLabel.TextColor3 = CLOSEST_COLOR
                end
            end)

            if not success then
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

-- Update ESP for a player (optimized - uses cached closest player)
local function UpdateESP(player, isClosest)
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

        -- Use cached closest player check with distance-based colors
        local nameColor = GetDistanceColor(distance, isClosest)
        espData.NameLabel.TextColor3 = nameColor
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
    local playerCount = #Players:GetPlayers()

    -- Get memory usage (MB)
    local memoryUsed = floor(Stats:GetTotalMemoryUsageMb())

    -- Count active targets (players with ESP visible)
    local activeTargets = 0
    for player, espData in pairs(ESPObjects) do
        if espData.Nametag and espData.Nametag.Parent then
            activeTargets = activeTargets + 1
        end
    end

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
-- MAIN INITIALIZATION
-- ============================================================

-- ============================================================
-- MAIN INITIALIZATION
-- ============================================================

-- Cleanup Function
local function Cleanup()
    Sp3arParvus.Active = false

    -- Disconnect connections
    for _, conn in pairs(Sp3arParvus.Connections) do
        if conn then conn:Disconnect() end
    end
    table.clear(Sp3arParvus.Connections)

    -- Cancel threads
    for _, thread in pairs(Sp3arParvus.Threads) do
        if thread then task.cancel(thread) end
    end
    table.clear(Sp3arParvus.Threads)

    -- Cleanup Visuals
    if ScreenGui then ScreenGui:Destroy() end
    
    for _, espData in pairs(ESPObjects) do
        if espData.Nametag then espData.Nametag:Destroy() end
        if espData.Tracer then espData.Tracer:Remove() end
    end
    table.clear(ESPObjects)

    warn("[Sp3arParvus] Script Unloaded!")
end

-- Create Main Window
local Window = UI.CreateWindow("Grub Cheat Suite")

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
UI.CreateToggle(AimTab, "Enable Aimbot", "Aimbot/Enabled", true)
UI.CreateToggle(AimTab, "Always Active (No Keybind)", "Aimbot/AlwaysEnabled", true)
UI.CreateToggle(AimTab, "Team Check", "Aimbot/TeamCheck", false)
UI.CreateToggle(AimTab, "Visibility Check", "Aimbot/VisibilityCheck", true)
UI.CreateSlider(AimTab, "Smoothing", "Aimbot/Sensitivity", 0, 100, 10, "%")
UI.CreateSlider(AimTab, "FOV Radius", "Aimbot/FOV/Radius", 0, 500, 100, "px")
UI.CreateSlider(AimTab, "Distance Limit", "Aimbot/DistanceLimit", 25, 3000, 1000, " st")

UI.CreateSection(AimTab, "Ballistics")
UI.CreateToggle(AimTab, "Predict Movement", "Aimbot/Prediction", true)
UI.CreateSlider(AimTab, "Bullet Speed", "Prediction/Velocity", 100, 5000, 3155, " st/s", function(v) ProjectileSpeed = v end)
UI.CreateSlider(AimTab, "Gravity Scale", "Prediction/GravityMultiplier", 0, 5, 2, "x", function(v) GravityCorrection = v end)

UI.CreateSection(AimTab, "Silent Aim")
UI.CreateToggle(AimTab, "Enable Silent Aim", "SilentAim/Enabled", true)
UI.CreateSlider(AimTab, "Hit Chance", "SilentAim/HitChance", 0, 100, 100, "%")
UI.CreateSlider(AimTab, "Silent FOV", "SilentAim/FOV/Radius", 0, 500, 100, "px")

UI.CreateSection(AimTab, "Trigger Bot")
UI.CreateToggle(AimTab, "Enable Trigger", "Trigger/Enabled", true)
UI.CreateToggle(AimTab, "Hold Fire", "Trigger/HoldMouseButton", true)
UI.CreateSlider(AimTab, "Trigger Delay", "Trigger/Delay", 0, 100, 0, "ms", function(v) Flags["Trigger/Delay"] = v/1000 end)

-- VISUALS TAB
UI.CreateSection(VisualsTab, "Player ESP")
UI.CreateToggle(VisualsTab, "Enable ESP", "ESP/Enabled", true)
UI.CreateToggle(VisualsTab, "Draw Names", "ESP/Nametags", true)
UI.CreateToggle(VisualsTab, "Draw Tracers", "ESP/Tracers", false)
UI.CreateSlider(VisualsTab, "Maximum Distance", "ESP/MaxDistance", 100, 8000, 5000, " st")

-- MISC TAB
UI.CreateSection(MiscTab, "Utilities")
UI.CreateButton(MiscTab, "Rejoin Server", Rejoin)
UI.CreateButton(MiscTab, "Unload Script", Cleanup)

-- SETTINGS TAB
UI.CreateSection(SettingsTab, "Configuration")
UI.CreateToggle(SettingsTab, "Show Performance Stats", "Performance/Enabled", true, function(state)
    if PerformanceLabel then PerformanceLabel.Visible = state end
end)

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

-- Event Listeners
TrackConnection(Players.PlayerAdded:Connect(function(player) CreateESP(player) end))
TrackConnection(Players.PlayerRemoving:Connect(function(player) RemoveESP(player) end))

-- ============================================================
-- MAIN UPDATE LOOPS
-- ============================================================

-- Aimbot Keybind (Hold RMB)
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

-- Trigger Keybind (Hold RMB)
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
TrackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Trigger = Flags["Trigger/Enabled"]
    end

    -- UI Toggle keybind (Right Shift)
    if input.KeyCode == Enum.KeyCode.RightShift then
        UIVisible = not UIVisible
        if MainFrame then
            MainFrame.Visible = UIVisible
        end
        if PerformanceLabel then
            PerformanceLabel.Visible = UIVisible and Flags["Performance/Enabled"]
        end
        if ClosestPlayerTrackerLabel then
            ClosestPlayerTrackerLabel.Visible = UIVisible and Flags["ESP/Enabled"]
        end
    end
end))

TrackConnection(UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Trigger = false
    end
end))

-- Aimbot & Silent Aim update loop (Optimized - RenderStepped)
-- Replaced separate while loops with a single synced RenderStepped connection for smoothness and performance
local function UpdateAimAndSilent()
    if not Sp3arParvus.Active then return end

    -- Silent Aim
    if Flags["SilentAim/Enabled"] then
        SilentAim = GetClosest(
            true,
            Flags["SilentAim/TeamCheck"],
            Flags["SilentAim/VisibilityCheck"],
            Flags["SilentAim/DistanceCheck"],
            Flags["SilentAim/DistanceLimit"],
            Flags["SilentAim/FOV/Radius"],
            Flags["SilentAim/Priority"],
            Flags["SilentAim/BodyParts"],
            Flags["SilentAim/Prediction"]
        )
    else
        SilentAim = nil
    end

    -- Aimbot
    if Aimbot or Flags["Aimbot/AlwaysEnabled"] then
        local target = GetClosest(
            Flags["Aimbot/Enabled"],
            Flags["Aimbot/TeamCheck"],
            Flags["Aimbot/VisibilityCheck"],
            Flags["Aimbot/DistanceCheck"],
            Flags["Aimbot/DistanceLimit"],
            Flags["Aimbot/FOV/Radius"],
            Flags["Aimbot/Priority"],
            Flags["Aimbot/BodyParts"],
            Flags["Aimbot/Prediction"]
        )
        AimAt(target, Flags["Aimbot/Sensitivity"] / 100)
    end
end

TrackConnection(RunService.RenderStepped:Connect(UpdateAimAndSilent))

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

-- ESP update loop (optimized - single pass for closest player)
-- ESP update loop (Optimized - RenderStepped)
local lastEspUpdate = 0
local espUpdateRate = 0.1 -- 100 stud radius check every 100ms

local function UpdateESPStep()
    if not Sp3arParvus.Active then return end
    
    -- Frequent updates (Visuals - every frame)
    if Flags["ESP/Enabled"] then
        -- Update all visuals immediately aligned with frame
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                UpdateESP(player, player == NearestPlayerRef)
            end
        end
    end

    -- Throttled updates (Calculations)
    local now = os.clock()
    if now - lastEspUpdate > espUpdateRate then
        lastEspUpdate = now
        
        if Flags["ESP/Enabled"] then
            -- Update nearest player reference
            UpdateNearestPlayer()
            -- Update closest player tracker display
            UpdateClosestPlayerTracker()
        end
    end
end

TrackConnection(RunService.RenderStepped:Connect(UpdateESPStep))

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
print(string.format("[Sp3arParvus v%s] Press RIGHT SHIFT to toggle UI visibility", VERSION))
print(string.format("[Sp3arParvus v%s] Distance Colors: Pink=Closest | Red≤2000 | Yellow≤4000 | Green>4000", VERSION))
