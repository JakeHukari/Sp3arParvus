# Claude Code Prompt: Fix Sp3arParvus ESP Freezing & Aimbot Vertical Offset Issues

## Overview
You're debugging a Roblox ESP/aimbot script with two critical issues: (1) ESP circles freeze on screen after initial load and stop tracking player positions, and (2) the aimbot aims significantly below players' actual positions. This prompt provides the root causes, buggy code patterns, and complete fixes.

---

## ISSUE 1: ESP Circles Freezing On Screen

### Root Cause Analysis

**Primary Problem: Connection Lifecycle Failure**

The ESP system likely uses RunService.RenderStepped or Heartbeat connections that either:
1. **Disconnect prematurely** due to reference issues
2. **Break silently** when encountering nil/destroyed instances
3. **Stop updating** due to conditional checks that fail permanently
4. **Create memory leaks** by accumulating Drawing objects without proper cleanup

**Common Bug Pattern:**
```lua
-- ❌ BUGGY CODE - Connection stops on first error
local function createESP(player)
    local circle = Drawing.new("Circle")
    
    RunService.RenderStepped:Connect(function()
        local character = player.Character  -- Becomes nil on respawn
        local rootPart = character.HumanoidRootPart  -- ERROR HERE when character is nil
        
        local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        circle.Position = Vector2.new(screenPos.X, screenPos.Y)
        circle.Visible = onScreen
    end)
end
```

**What happens:**
- When player dies/respawns, `character` becomes nil
- Attempting to index nil (`character.HumanoidRootPart`) throws an error
- The connection continues but the function errors out every frame
- Circle remains visible at last known position but never updates

### Buggy Code Sections to Find

**Pattern 1: Missing Nil Checks**
```lua
-- LOOK FOR THIS PATTERN
RunService.RenderStepped:Connect(function()
    local character = player.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart")  -- No check if character is nil!
    
    local screenPos = camera:WorldToViewportPoint(rootPart.Position)
    circle.Position = Vector2.new(screenPos.X, screenPos.Y)
end)
```

**Pattern 2: Connection Not Stored**
```lua
-- LOOK FOR THIS PATTERN
local function setupESP(player)
    local espDrawings = {}
    
    -- Connection is created but never stored or cleaned up
    RunService.RenderStepped:Connect(function()
        updateESP(player, espDrawings)
    end)
    
    -- When player leaves, connection keeps running with invalid data
end
```

**Pattern 3: Drawings Created in Loop**
```lua
-- LOOK FOR THIS PATTERN (severe memory leak)
RunService.RenderStepped:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        local circle = Drawing.new("Circle")  -- NEW OBJECT EVERY FRAME!
        -- Update circle...
        -- Circle is never removed, old ones accumulate
    end
end)
```

**Pattern 4: Character Respawn Not Handled**
```lua
-- LOOK FOR THIS PATTERN
local function createESP(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local espData = setupDrawings()
    
    -- Connection references character that gets destroyed
    RunService.RenderStepped:Connect(function()
        updateESP(character, espData)  -- character becomes invalid on respawn
    end)
    
    -- No CharacterAdded handler to reset the connection
end
```

### Complete Fixed Code

```lua
--[[
    ESP System - FIXED VERSION
    Fixes: Connection lifecycle, nil handling, memory leaks, respawn handling
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Manager to handle all players
local ESPManager = {
    players = {},           -- Stores ESP data per player
    mainConnection = nil,   -- Main update loop connection
    settings = {
        enabled = true,
        maxDistance = 650,
        circleRadius = 8,
        circleColor = Color3.fromRGB(255, 255, 255),
        teamCheck = false
    }
}

-- Creates Drawing objects for a player (called once per player)
local function createDrawings()
    local drawings = {
        circle = Drawing.new("Circle"),
        nameTag = Drawing.new("Text"),
        distanceTag = Drawing.new("Text")
    }
    
    -- Initialize circle properties
    drawings.circle.Radius = ESPManager.settings.circleRadius
    drawings.circle.Color = ESPManager.settings.circleColor
    drawings.circle.Thickness = 2
    drawings.circle.NumSides = 30
    drawings.circle.Filled = false
    drawings.circle.Visible = false  -- Start hidden
    drawings.circle.Transparency = 1
    
    -- Initialize name tag
    drawings.nameTag.Size = 14
    drawings.nameTag.Center = true
    drawings.nameTag.Outline = true
    drawings.nameTag.Color = Color3.new(1, 1, 1)
    drawings.nameTag.Visible = false
    drawings.nameTag.Font = Drawing.Fonts.Plex or 2
    
    -- Initialize distance tag
    drawings.distanceTag.Size = 12
    drawings.distanceTag.Center = true
    drawings.distanceTag.Outline = true
    drawings.distanceTag.Color = Color3.fromRGB(200, 200, 200)
    drawings.distanceTag.Visible = false
    
    return drawings
end

-- Hides all drawings for a player
local function hideDrawings(drawings)
    if not drawings then return end
    
    for _, drawing in pairs(drawings) do
        if drawing and typeof(drawing) == "Instance" then
            drawing.Visible = false
        end
    end
end

-- Removes and cleans up all drawings
local function destroyDrawings(drawings)
    if not drawings then return end
    
    for _, drawing in pairs(drawings) do
        if drawing and typeof(drawing) == "Instance" then
            drawing.Visible = false
            pcall(function() drawing:Remove() end)  -- Protected call in case already removed
        end
    end
end

-- Updates ESP for a single player
local function updatePlayerESP(playerData)
    local player = playerData.player
    local drawings = playerData.drawings
    
    -- CRITICAL: Check if player still exists and is valid
    if not player or not player.Parent then
        hideDrawings(drawings)
        return
    end
    
    -- Check if ESP is enabled
    if not ESPManager.settings.enabled then
        hideDrawings(drawings)
        return
    end
    
    -- Team check
    if ESPManager.settings.teamCheck and player.Team == LocalPlayer.Team then
        hideDrawings(drawings)
        return
    end
    
    -- Don't ESP ourselves
    if player == LocalPlayer then
        hideDrawings(drawings)
        return
    end
    
    -- CRITICAL: Nil-safe character access
    local character = player.Character
    if not character or not character.Parent then
        hideDrawings(drawings)
        return
    end
    
    -- CRITICAL: Check if character is alive
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        hideDrawings(drawings)
        return
    end
    
    -- CRITICAL: Get root part with nil check
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    
    if not rootPart or not head then
        hideDrawings(drawings)
        return
    end
    
    -- Calculate distance
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    -- Distance culling
    if distance > ESPManager.settings.maxDistance then
        hideDrawings(drawings)
        return
    end
    
    -- CRITICAL: Protected WorldToViewportPoint call
    local success, screenPos, onScreen = pcall(function()
        return Camera:WorldToViewportPoint(rootPart.Position)
    end)
    
    if not success or not onScreen then
        hideDrawings(drawings)
        return
    end
    
    -- Update circle position
    drawings.circle.Visible = true
    drawings.circle.Position = Vector2.new(screenPos.X, screenPos.Y)
    
    -- Update name tag
    drawings.nameTag.Visible = true
    drawings.nameTag.Text = player.Name
    drawings.nameTag.Position = Vector2.new(screenPos.X, screenPos.Y - 25)
    
    -- Update distance tag
    drawings.distanceTag.Visible = true
    drawings.distanceTag.Text = string.format("[%dm]", math.floor(distance))
    drawings.distanceTag.Position = Vector2.new(screenPos.X, screenPos.Y + 25)
    
    -- Color based on distance (optional visual enhancement)
    local colorFactor = math.clamp(distance / ESPManager.settings.maxDistance, 0, 1)
    drawings.circle.Color = Color3.new(1 - colorFactor, colorFactor, 0)
end

-- Add player to ESP system
function ESPManager:AddPlayer(player)
    if player == LocalPlayer then return end
    if self.players[player] then return end  -- Already tracking
    
    print("[ESP] Adding player:", player.Name)
    
    local playerData = {
        player = player,
        drawings = createDrawings(),
        connections = {}
    }
    
    -- Handle character respawns
    local function onCharacterAdded(character)
        print("[ESP] Character added for:", player.Name)
        
        -- Wait for character to be fully loaded
        local humanoid = character:WaitForChild("Humanoid", 5)
        if not humanoid then return end
        
        -- Handle character death
        local diedConnection = humanoid.Died:Connect(function()
            print("[ESP] Character died:", player.Name)
            hideDrawings(playerData.drawings)
        end)
        
        table.insert(playerData.connections, diedConnection)
        
        -- Handle character removal
        local ancestryConnection = character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                print("[ESP] Character removed:", player.Name)
                hideDrawings(playerData.drawings)
            end
        end)
        
        table.insert(playerData.connections, ancestryConnection)
    end
    
    -- Set up for current character
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    -- Set up for future characters
    local charAddedConnection = player.CharacterAdded:Connect(onCharacterAdded)
    table.insert(playerData.connections, charAddedConnection)
    
    self.players[player] = playerData
end

-- Remove player from ESP system
function ESPManager:RemovePlayer(player)
    local playerData = self.players[player]
    if not playerData then return end
    
    print("[ESP] Removing player:", player.Name)
    
    -- Disconnect all connections
    for _, connection in ipairs(playerData.connections) do
        pcall(function() connection:Disconnect() end)
    end
    
    -- Destroy all drawings
    destroyDrawings(playerData.drawings)
    
    self.players[player] = nil
end

-- Main update loop (runs every frame)
function ESPManager:Update()
    for player, playerData in pairs(self.players) do
        -- CRITICAL: Protected call to prevent one player's error from breaking all ESP
        local success, errorMsg = pcall(updatePlayerESP, playerData)
        if not success then
            warn("[ESP] Error updating player", player.Name, ":", errorMsg)
            hideDrawings(playerData.drawings)
        end
    end
end

-- Initialize ESP system
function ESPManager:Initialize()
    print("[ESP] Initializing...")
    
    -- Add existing players
    for _, player in pairs(Players:GetPlayers()) do
        self:AddPlayer(player)
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        self:AddPlayer(player)
    end)
    
    -- Handle players leaving
    Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end)
    
    -- CRITICAL: Single main update connection
    self.mainConnection = RunService.RenderStepped:Connect(function()
        self:Update()
    end)
    
    print("[ESP] Initialized successfully")
end

-- Cleanup ESP system
function ESPManager:Destroy()
    print("[ESP] Destroying...")
    
    -- Disconnect main update loop
    if self.mainConnection then
        self.mainConnection:Disconnect()
        self.mainConnection = nil
    end
    
    -- Remove all players
    for player, _ in pairs(self.players) do
        self:RemovePlayer(player)
    end
    
    print("[ESP] Destroyed successfully")
end

-- Start the ESP system
ESPManager:Initialize()

-- To stop ESP later:
-- ESPManager:Destroy()
```

### Key Fixes Implemented

1. **Protected pcall() usage** - Prevents errors from breaking the update loop
2. **Comprehensive nil checks** - Every step validates data exists
3. **Single main connection** - One RenderStepped connection for all players
4. **Per-player connection tracking** - Character death/respawn handled individually
5. **Proper cleanup** - All connections disconnected, drawings removed on player leave
6. **Respawn handling** - CharacterAdded event resets ESP for respawned characters
7. **Drawing object reuse** - Each player gets one set of drawings, reused every frame
8. **Early exit pattern** - Cheap checks first, expensive operations only if needed

---

## ISSUE 2: Aimbot Aiming Below Target

### Root Cause Analysis

**Primary Problem: HumanoidRootPart vs Head Position Mismatch**

The aimbot calculates screen distance using **HumanoidRootPart** position but then aims at the **Head**. Since these body parts are 2-3 studs apart vertically on R6/R15 characters, the camera locks to the HRP's screen position but the weapon fires at head height, causing shots to land below the target.

**Visualization:**
```
Head Position:        Y = 7.5 studs  ← Where shots need to go
                      
    ↕ 2.5 stud offset (THE BUG)
                      
HRP Position:         Y = 5.0 studs  ← Where aimbot calculates from
```

**Why This Happens:**
1. FOV calculation uses `WorldToViewportPoint(HumanoidRootPart.Position)`
2. Distance-to-mouse uses HRP's screen coordinates
3. Closest target selection returns `Character["Head"]` or `Character[TargetPart]`
4. Camera aims at screen position calculated from HRP
5. Weapon fires at head height, but camera points 2-3 studs low

### Buggy Code Sections to Find

**Pattern 1: Mixed Part References**
```lua
-- ❌ BUGGY - FOV uses HRP, returns Head
local function getClosestPlayer()
    local closest = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")  -- Using HRP here
            if hrp then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local distance = (Vector2.new(Mouse.X, Mouse.Y) - 
                                    Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    
                    if distance < shortestDistance then
                        closest = character.Head  -- But returning Head! MISMATCH!
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closest
end
```

**Pattern 2: Wrong Part in WorldToViewportPoint**
```lua
-- ❌ BUGGY - Screen position from wrong part
local function aimAtTarget(target)
    local character = target.Parent
    local hrp = character.HumanoidRootPart
    
    -- Gets HRP screen position
    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    
    -- But aims at Head
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, character.Head.Position)
    
    -- Camera direction is correct, but initial calculation used HRP,
    -- causing aiming calculations to be off by the vertical offset
end
```

**Pattern 3: Hardcoded Target Part Without Consistent Usage**
```lua
-- ❌ BUGGY - Settings say Head, code uses HRP
local Settings = {
    TargetPart = "Head"  -- User wants to aim at head
}

local function getTarget()
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        -- BUG: Uses HRP for detection instead of Settings.TargetPart
        local part = character:FindFirstChild("HumanoidRootPart")
        local screenPos = Camera:WorldToViewportPoint(part.Position)
        
        -- Later returns the correct part
        return character:FindFirstChild(Settings.TargetPart)  -- Returns Head
    end
end
```

**Pattern 4: Prediction with Wrong Base**
```lua
-- ❌ BUGGY - Prediction uses HRP velocity for Head target
local function getPredictedPosition(character)
    local hrp = character.HumanoidRootPart
    local head = character.Head
    
    -- Calculates predicted position using HRP
    local predicted = hrp.Position + (hrp.Velocity * 0.165)
    
    -- But aims at Head, which has different position and velocity
    Camera.CFrame = CFrame.new(Camera.Position, head.Position)
    
    -- The prediction is off by the HRP-Head offset
end
```

### Complete Fixed Code

```lua
--[[
    Aimbot System - FIXED VERSION
    Fixes: Consistent target part usage, proper position calculations
]]--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Aimbot Settings
local AimbotSettings = {
    Enabled = false,
    ToggleKey = Enum.KeyCode.E,
    TargetPart = "Head",  -- CRITICAL: This must be used CONSISTENTLY
    FOVRadius = 150,
    TeamCheck = true,
    VisibilityCheck = true,
    PredictionEnabled = false,
    PredictionTime = 0.165,  -- Time in seconds to predict ahead
    Smoothness = 1,  -- 1 = instant, higher = smoother but slower
}

-- FOV Circle (visual indicator)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = true
FOVCircle.Radius = AimbotSettings.FOVRadius
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 2
FOVCircle.NumSides = 64
FOVCircle.Filled = false
FOVCircle.Transparency = 0.5

-- Update FOV circle position
local function updateFOVCircle()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = AimbotSettings.FOVRadius
    FOVCircle.Visible = AimbotSettings.Enabled
end

-- Check if target is visible (raycast check)
local function isVisible(targetPart)
    if not AimbotSettings.VisibilityCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    if result then
        -- Check if we hit the target or its character
        local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
        local targetCharacter = targetPart:FindFirstAncestorOfClass("Model")
        return hitCharacter == targetCharacter
    end
    
    return true
end

-- Get closest player to crosshair - FIXED VERSION
local function getClosestPlayerToMouse()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        -- Skip local player
        if player == LocalPlayer then continue end
        
        -- Team check
        if AimbotSettings.TeamCheck and player.Team == LocalPlayer.Team then
            continue
        end
        
        local character = player.Character
        if not character then continue end
        
        -- Check if alive
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- CRITICAL FIX: Use the SAME target part for ALL calculations
        local targetPart = character:FindFirstChild(AimbotSettings.TargetPart)
        if not targetPart then
            -- Fallback to HumanoidRootPart if target part not found
            targetPart = character:FindFirstChild("HumanoidRootPart")
            if not targetPart then continue end
        end
        
        -- CRITICAL FIX: WorldToViewportPoint uses TARGET PART, not HRP
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        
        if not onScreen then continue end
        
        -- Calculate distance from mouse to target on screen
        local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
        local distance = (mousePos - screenPos2D).Magnitude
        
        -- Check if within FOV
        if distance > AimbotSettings.FOVRadius then continue end
        
        -- Visibility check
        if not isVisible(targetPart) then continue end
        
        -- Update closest target
        if distance < shortestDistance then
            closest = targetPart  -- CRITICAL: Return the SAME part we measured
            shortestDistance = distance
        end
    end
    
    return closest
end

-- Get predicted position - FIXED VERSION
local function getPredictedPosition(targetPart)
    if not AimbotSettings.PredictionEnabled then
        return targetPart.Position
    end
    
    -- CRITICAL FIX: Use velocity from the SAME part we're targeting
    local velocity = targetPart.AssemblyLinearVelocity or targetPart.Velocity or Vector3.new(0, 0, 0)
    local predictedPos = targetPart.Position + (velocity * AimbotSettings.PredictionTime)
    
    return predictedPos
end

-- Aim camera at target - FIXED VERSION
local function aimAtTarget(targetPart)
    if not targetPart or not targetPart.Parent then return end
    
    -- CRITICAL FIX: Get predicted position from the actual target part
    local targetPosition = getPredictedPosition(targetPart)
    
    -- Calculate direction from camera to target
    local cameraPosition = Camera.CFrame.Position
    local direction = (targetPosition - cameraPosition).Unit
    
    if AimbotSettings.Smoothness > 1 then
        -- Smooth aiming
        local currentDirection = Camera.CFrame.LookVector
        local smoothDirection = currentDirection:Lerp(direction, 1 / AimbotSettings.Smoothness)
        Camera.CFrame = CFrame.new(cameraPosition, cameraPosition + smoothDirection)
    else
        -- Instant aiming
        Camera.CFrame = CFrame.new(cameraPosition, targetPosition)
    end
end

-- Main aimbot loop
local aimbotActive = false

RunService.RenderStepped:Connect(function()
    -- Update FOV circle
    updateFOVCircle()
    
    -- Only aim if enabled and key held/toggled
    if not AimbotSettings.Enabled or not aimbotActive then
        return
    end
    
    -- Get closest target
    local target = getClosestPlayerToMouse()
    
    if target then
        aimAtTarget(target)
    end
end)

-- Toggle aimbot with key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == AimbotSettings.ToggleKey then
        aimbotActive = not aimbotActive
        print("[Aimbot]", aimbotActive and "Enabled" or "Disabled")
    end
end)

-- Alternative: Hold to aim (comment out toggle code above and use this)
--[[
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == AimbotSettings.ToggleKey then
        aimbotActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == AimbotSettings.ToggleKey then
        aimbotActive = false
    end
end)
]]--

print("[Aimbot] Initialized")
print("[Aimbot] Target Part:", AimbotSettings.TargetPart)
print("[Aimbot] Toggle Key:", AimbotSettings.ToggleKey.Name)
```

### Alternative Fix: Offset-Aware Targeting

If the script MUST use HumanoidRootPart for detection but aim at Head:

```lua
--[[
    Alternative Fix: Calculate and apply offset between HRP and Head
]]--

local function getClosestPlayerWithOffset()
    local closest = nil
    local shortestDistance = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        -- Get both parts
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        
        if not hrp or not head then continue end
        
        -- Use HRP for FOV detection
        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end
        
        local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
        local distance = (mousePos - screenPos2D).Magnitude
        
        if distance > AimbotSettings.FOVRadius then continue end
        
        -- Calculate offset
        local offset = head.Position - hrp.Position
        
        if distance < shortestDistance then
            closest = {
                part = head,  -- Aim at this
                offset = offset  -- Use this for adjustments if needed
            }
            shortestDistance = distance
        end
    end
    
    return closest
end

-- Usage
local targetData = getClosestPlayerWithOffset()
if targetData then
    aimAtTarget(targetData.part)  -- Aims at Head with correct calculations
end
```

### Key Fixes for Aimbot

1. **Consistent Part Usage** - Same body part for FOV, distance, and aiming calculations
2. **Correct WorldToViewportPoint** - Uses target part's actual position
3. **Unified Prediction** - Velocity from same part being targeted
4. **Proper CFrame Calculation** - Camera looks directly at intended hit point
5. **Offset Handling** - If mixing parts, explicitly calculate vertical offset

---

## Testing Recommendations

### For ESP Freezing Fix:

1. **Basic Functionality Test**
   ```lua
   -- Verify ESP appears for all players
   -- Move around and confirm circles follow players
   ```

2. **Respawn Test**
   ```lua
   -- Kill yourself (reset character)
   -- Verify ESP reappears after respawn
   -- Ask another player to reset, verify their ESP updates
   ```

3. **Player Join/Leave Test**
   ```lua
   -- Have players join the server
   -- Verify ESP appears for new players
   -- Have players leave
   -- Verify ESP is cleaned up (no ghost circles)
   ```

4. **Distance Culling Test**
   ```lua
   -- Adjust maxDistance setting to 100
   -- Move far from players, verify ESP disappears
   -- Move close, verify ESP reappears
   ```

5. **Memory Leak Test**
   ```lua
   -- Run this in console after 5 minutes:
   print("Memory:", collectgarbage("count"), "KB")
   
   -- Let script run for 10+ minutes with players joining/leaving
   -- Memory should stay relatively stable (< 100MB growth)
   ```

6. **Performance Test**
   ```lua
   -- Monitor FPS with ESP enabled
   local frameCount = 0
   local lastTime = tick()
   RunService.RenderStepped:Connect(function()
       frameCount = frameCount + 1
       if tick() - lastTime >= 1 then
           print("FPS:", frameCount)
           frameCount = 0
           lastTime = tick()
       end
   end)
   
   -- Should maintain 60 FPS with 10-15 players
   ```

### For Aimbot Vertical Offset Fix:

1. **Static Target Test**
   ```lua
   -- Stand still and aim at a standing player
   -- Press aimbot key
   -- Verify crosshair locks onto HEAD (not torso/chest)
   -- Fire weapon, confirm hits register on head
   ```

2. **Moving Target Test**
   ```lua
   -- Aim at a running player
   -- Verify aimbot tracks their head position
   -- With prediction OFF: shots should hit slightly behind moving targets
   -- With prediction ON: shots should lead the target
   ```

3. **Height Difference Test**
   ```lua
   -- Stand on elevated position, aim at player below
   -- Verify aimbot doesn't aim too low
   -- Stand below player, aim at player above
   -- Verify aimbot doesn't aim too low
   ```

4. **FOV Circle Alignment Test**
   ```lua
   -- Enable aimbot
   -- FOV circle should be centered on mouse
   -- When target's HEAD is inside FOV circle, aimbot should activate
   -- When target's HEAD is outside, aimbot should not activate
   ```

5. **Target Part Switch Test**
   ```lua
   -- Set TargetPart = "Head", test hits
   -- Set TargetPart = "HumanoidRootPart", test hits
   -- Set TargetPart = "Torso", test hits
   -- All should aim correctly at the specified part
   ```

6. **Character Rig Test**
   ```lua
   -- Test against R6 characters (if applicable)
   -- Test against R15 characters
   -- Test against Rthro characters (varying heights)
   -- All should aim correctly regardless of rig type
   ```

### Debug Output to Add:

```lua
-- Add this to verify calculations during testing
local function debugAimbot(targetPart)
    if not targetPart then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    local mousePos = UserInputService:GetMouseLocation()
    local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
    
    print("=== Aimbot Debug ===")
    print("Target Part:", targetPart.Name)
    print("World Position:", targetPart.Position)
    print("Screen Position:", screenPos)
    print("Mouse Position:", mousePos)
    print("Distance to Mouse:", distance)
    print("Within FOV:", distance <= AimbotSettings.FOVRadius)
    print("==================")
end
```

### Success Criteria:

**ESP System:**
- ✅ Circles follow players smoothly (60 FPS)
- ✅ ESP persists across player respawns
- ✅ No ghost circles remain when players leave
- ✅ Memory usage stays under 50MB after 10 minutes
- ✅ No console errors during normal gameplay

**Aimbot System:**
- ✅ Aims directly at configured body part (Head)
- ✅ Shots land on target consistently (90%+ hit rate on static targets)
- ✅ No vertical offset (shots don't land below target)
- ✅ FOV circle accurately represents target selection radius
- ✅ Works correctly on all character rig types (R6/R15/Rthro)

---

## Additional Notes

### Apocalypse Rising 2 Specifics:

Most Games typically use **R6 character rigs** with these properties:
- HumanoidRootPart at hip level (Y ≈ 5 studs from ground)
- Head at Y ≈ 7.5 studs from ground
- Vertical offset: **2.5 studs**

Common Pitfalls to Avoid:

1. **Don't mix character references** - Always use current `player.Character`, never cache it
2. **Don't skip nil checks** - Every property access should be validated
3. **Don't create drawings in loops** - Create once, update many times
4. **Don't forget to disconnect** - Store all connections for cleanup
5. **Don't use wrong coordinate spaces** - Keep world space and screen space separate

### Performance Targets:

- **ESP System:** 60 FPS with 15+ players, <50MB memory
- **Aimbot System:** <1ms per frame, instant target acquisition
- **Combined:** Should run smoothly together without fps drops

---

## Final Checklist

Before deploying fixes:

- [ ] All connections stored and disconnected on cleanup
- [ ] All Drawing objects removed when players leave
- [ ] Nil checks on every Character/Part access
- [ ] pcall() wraps potentially failing operations
- [ ] CharacterAdded events handle respawns
- [ ] Same body part used throughout aimbot calculations
- [ ] WorldToViewportPoint uses actual target part
- [ ] Camera.CFrame aims at actual target position
- [ ] Distance culling prevents rendering distant players
- [ ] Team check prevents targeting teammates (if enabled)
- [ ] Debug prints added for testing
- [ ] Memory leak test passed (10+ minute runtime)
- [ ] Performance test passed (60 FPS maintained)

Apply these fixes systematically, test thoroughly, and the ESP freezing and aimbot offset issues should be completely resolved.
