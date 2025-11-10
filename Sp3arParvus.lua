-- SP3ARPARVUS - ADVANCED GAME ENHANCEMENT SUITE
-- Optimized single-file architecture for maximum performance
--
-- VERSION: 1.2.0
--
-- VERSIONING RULES (Semantic Versioning):
-- Format: MAJOR.MINOR.PATCH (e.g., 1.1.0)
--
-- MAJOR (X.0.0): Breaking changes, major rewrites, incompatible changes
-- MINOR (1.X.0): New features, functionality additions, significant improvements
-- PATCH (1.1.X): Bug fixes, small tweaks, optimization improvements
--
-- WHEN TO BUMP:
-- - Add new features or systems → Bump MINOR (1.0.0 → 1.1.0)
-- - Fix bugs or make small changes → Bump PATCH (1.1.0 → 1.1.1)
-- - Major rewrite or breaking changes → Bump MAJOR (1.1.0 → 2.0.0)
--
-- ALWAYS update version on every commit that changes functionality
--
-- RECENT ADDITIONS:
-- v1.2.0 - ESP Optimization & Always-On Features:
--   - All ESP features now enabled by default (boxes, tracers, nametags, etc.)
--   - Fixed 10,000 stud detection range (no distance modifiers or exceptions)
--   - Removed distance UI controls (range is always 10,000 studs)
--   - ESP automatically updates when players enter/exit range
--   - Enhanced ESP cleanup when players leave, die, or exit proximity
--
-- v1.1.0 - Overpowered ESP System:
--   - Increased maximum ESP distance from 500 to 10,000 studs
--   - Continuous character monitoring (checks every 2s for new characters)
--   - Aggressive ESP refresh system (rebuilds stale ESP every 10s)
--   - Enhanced character loading with retry mechanism
--   - Fixes players outside render distance not being detected
--
-- v1.0.1 - Performance & Utility Features:
--   - Performance Display: Real-time FPS, ping, and player count monitoring
--   - Closest Player Tracker: Tracks and displays nearest player with distance
--   - Br3ak3r (Part Breaker): Hide/remove parts with Ctrl+LMB, undo with Ctrl+Z
--   - Enhanced ESP System: Fixed stuck tracers/nametags with CharacterAdded listeners

-- ============================================================
-- VERSIONING SYSTEM
-- ============================================================
local SP3ARPARVUS_VERSION = "1.2.0"
local DEFAULT_CURSOR_DATA = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAPklEQVR4nO3RsQ0AIAhFQfZfGlsLKwVj4r0BPpcQIR2UUwAAAAD/AXJR23B1AG2vKhneRVw/DgAAAPAEQBUNAL1B2xVjF+gAAAAASUVORK5CYII="

repeat task.wait() until game.IsLoaded
if Sp3arParvus and Sp3arParvus.Loaded then return end

getgenv().Sp3arParvus = {Loaded = false, Utilities = {}, DefaultCursor = DEFAULT_CURSOR_DATA, Cursor = DEFAULT_CURSOR_DATA}

Sp3arParvus.Games = {
	["Universal"] = {Name = "Universal"},
	["1168263273"] = {Name = "Bad Business"},
	["3360073263"] = {Name = "Bad Business PTR"},
	["1586272220"] = {Name = "Steel Titans"},
	["807930589"] = {Name = "The Wild West"},
	["580765040"] = {Name = "RAGDOLL UNIVERSE"},
	["187796008"] = {Name = "Those Who Remain"},
	["358276974"] = {Name = "Apocalypse Rising 2"},
	["3495983524"] = {Name = "Apocalypse Rising 2 Dev."},
	["1054526971"] = {Name = "Blackhawk Rescue Mission 5"}
}

Sp3arParvus.Game = Sp3arParvus.Games[tostring(game.GameId)] or Sp3arParvus.Games["Universal"]

-- ===== PHYSICS ENGINE =====
-- Advanced ballistics and trajectory calculation system
Sp3arParvus.Utilities.Physics = (function()

-- Mathematical utilities for polynomial root-finding

local eps = 1e-09

-- Numerical precision helper
local function isZero(d)
	return (d > -eps and d < eps)
end

-- Cubic root calculation with proper handling of negative values
local function cuberoot(x)
	return (x > 0) and math.pow(x, (1 / 3)) or -math.pow(math.abs(x), (1 / 3))
end

-- Quadratic equation solver

local function solveQuadric(c0, c1, c2)
	local s0, s1

	local p, q, D

	-- x^2 + px + q = 0
	p = c1 / (2 * c0)
	q = c2 / c0

	D = p * p - q

	if isZero(D) then
		s0 = -p
		return s0
	elseif (D < 0) then
		return
	else -- if (D > 0)
		local sqrt_D = math.sqrt(D)

		s0 = sqrt_D - p
		s1 = -sqrt_D - p
		return s0, s1
	end
end

-- Cubic equation solver

local function solveCubic(c0, c1, c2, c3)
	local s0, s1, s2

	local num, sub
	local A, B, C
	local sq_A, p, q
	local cb_p, D

	-- normal form: x^3 + Ax^2 + Bx + C = 0
	A = c1 / c0
	B = c2 / c0
	C = c3 / c0

	-- substitute x = y - A/3 to eliminate quadric term: x^3 + px + q = 0
	sq_A = A * A
	p = (1 / 3) * (-(1 / 3) * sq_A + B)
	q = 0.5 * ((2 / 27) * A * sq_A - (1 / 3) * A * B + C)

	-- use Cardano's formula
	cb_p = p * p * p
	D = q * q + cb_p

	if isZero(D) then
		if isZero(q) then -- one triple solution
			s0 = 0
			num = 1
			--return s0
		else -- one single and one double solution
			local u = cuberoot(-q)
			s0 = 2 * u
			s1 = -u
			num = 2
			--return s0, s1
		end
	elseif (D < 0) then -- Casus irreducibilis: three real solutions
		local phi = (1 / 3) * math.acos(-q / math.sqrt(-cb_p))
		local t = 2 * math.sqrt(-p)

		s0 = t * math.cos(phi)
		s1 = -t * math.cos(phi + math.pi / 3)
		s2 = -t * math.cos(phi - math.pi / 3)
		num = 3
		--return s0, s1, s2
	else -- one real solution
		local sqrt_D = math.sqrt(D)
		local u = cuberoot(sqrt_D - q)
		local v = -cuberoot(sqrt_D + q)

		s0 = u + v
		num = 1

		--return s0
	end

	-- resubstitute
	sub = (1 / 3) * A

	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end

	return s0, s1, s2
end

-- Quartic equation solver

local function solveQuartic(c0, c1, c2, c3, c4)
	local s0, s1, s2, s3

	local coeffs = {}
	local z, u, v, sub
	local A, B, C, D
	local sq_A, p, q, r
	local num

	-- normal form: x^4 + Ax^3 + Bx^2 + Cx + D = 0
	A = c1 / c0
	B = c2 / c0
	C = c3 / c0
	D = c4 / c0

	-- substitute x = y - A/4 to eliminate cubic term: x^4 + px^2 + qx + r = 0
	sq_A = A * A
	p = -0.375 * sq_A + B
	q = 0.125 * sq_A * A - 0.5 * A * B + C
	r = -(3 / 256) * sq_A * sq_A + 0.0625 * sq_A * B - 0.25 * A * C + D

	if isZero(r) then
		-- no absolute term: y(y^3 + py + q) = 0
		coeffs[3] = q
		coeffs[2] = p
		coeffs[1] = 0
		coeffs[0] = 1

		local results = {solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])}
		num = #results
		s0, s1, s2 = results[1], results[2], results[3]
	else
		-- solve the resolvent cubic …
		coeffs[3] = 0.5 * r * p - 0.125 * q * q
		coeffs[2] = -r
		coeffs[1] = -0.5 * p
		coeffs[0] = 1

		s0, s1, s2 = solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])

		-- … and take the one real solution …
		z = s0

		-- … to build two quadric equations
		u = z * z - r
		v = 2 * z - p

		if isZero(u) then
			u = 0
		elseif (u > 0) then
			u = math.sqrt(u)
		else
			return
		end

		if isZero(v) then
			v = 0
		elseif (v > 0) then
			v = math.sqrt(v)
		else
			return
		end

		coeffs[2] = z - u
		coeffs[1] = q < 0 and -v or v
		coeffs[0] = 1

		do
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = #results
			s0, s1 = results[1], results[2]
		end

		coeffs[2] = z + u
		coeffs[1] = q < 0 and v or -v
		coeffs[0] = 1

		if (num == 0) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s0, s1 = results[1], results[2]
		end

		if (num == 1) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s1, s2 = results[1], results[2]
		end

		if (num == 2) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s2, s3 = results[1], results[2]
		end
	end

	-- resubstitute
	sub = 0.25 * A

	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end
	if (num > 3) then s3 = s3 - sub end

	--return s0, s1, s2, s3
	--return s3, s2, s1, s0
	return {s3, s2, s1, s0}
end

local module = {}

function module.SolveTrajectory(origin, targetPosition, targetVelocity, projectileSpeed, gravity, gravityCorrection)
	gravity = gravity or workspace.Gravity
	gravityCorrection = gravityCorrection or 2

	local delta = targetPosition - origin
	gravity = -gravity / gravityCorrection

	local solutions = solveQuartic(
		gravity * gravity,
		-2 * targetVelocity.Y * gravity,
		targetVelocity.Y * targetVelocity.Y - 2 * delta.Y * gravity - projectileSpeed * projectileSpeed + targetVelocity.X * targetVelocity.X + targetVelocity.Z * targetVelocity.Z,
		2 * delta.Y * targetVelocity.Y + 2 * delta.X * targetVelocity.X + 2 * delta.Z * targetVelocity.Z,
		delta.Y * delta.Y + delta.X * delta.X + delta.Z * delta.Z
	)

	if solutions then
		for index = 1, #solutions do
			if solutions[index] > 0 then
				local tof = solutions[index] -- time of flight

				return origin + Vector3.new(
					(delta.X + targetVelocity.X * tof) / tof,
					(delta.Y + targetVelocity.Y * tof - gravity * tof * tof) / tof,
					(delta.Z + targetVelocity.Z * tof) / tof
				)
			end
		end
	end

	return targetPosition
end

return module
end)()

-- ===== MAIN UTILITIES =====
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
--local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
--local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")

local Utility = { DefaultLighting = {} }

local Camera = Workspace.CurrentCamera
local LocalPlayer = PlayerService.LocalPlayer
local Request = request or (http and http.request)
local SetIdentity = setthreadidentity or function() end

-- Anti-plugin crash (only runs if executor functions are available)
if setthreadidentity and hookfunction and getrenv then
    do -- Thanks to Kiriot22
        local OldPluginManager, Message = nil, nil

        task.spawn(function()
            SetIdentity(2)
            local Success, Error = pcall(getrenv().PluginManager)
            Message = Error
        end)

        OldPluginManager = hookfunction(getrenv().PluginManager, function()
            return error(Message)
        end)
    end
end

repeat task.wait() until Stats.Network:FindFirstChild("ServerStatsItem")
local Ping = Stats.Network.ServerStatsItem["Data Ping"]

repeat task.wait() until Workspace:FindFirstChildOfClass("Terrain")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local XZVector, YVector = Vector3.new(1, 0, 1), Vector3.new(0, 1, 0)
local Movement = { Forward = 0, Backward = 0, Right = 0, Left = 0, Up = 0, Down = 0 }
local function GetFlatVector(CF) return CF.LookVector * XZVector, CF.RightVector * XZVector end
local function GetUnit(Vector) if Vector.Magnitude == 0 then return Vector end return Vector.Unit end

local function MovementBind(ActionName, InputState)
    Movement[ActionName] = InputState == Enum.UserInputState.Begin and 1 or 0
    return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("Forward", MovementBind, false, Enum.KeyCode.W)
ContextActionService:BindAction("Backward", MovementBind, false, Enum.KeyCode.S)
ContextActionService:BindAction("Left", MovementBind, false, Enum.KeyCode.A)
ContextActionService:BindAction("Right", MovementBind, false, Enum.KeyCode.D)
ContextActionService:BindAction("Up", MovementBind, false, Enum.KeyCode.Space)
ContextActionService:BindAction("Down", MovementBind, false, Enum.KeyCode.LeftShift)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

--[[function Utility.HideObject(Object)
    Object.Parent = gethui()
end]]

function Utility.SetupFPS()
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
function Utility.MovementToDirection()
    local LookVector, RightVector = GetFlatVector(Camera.CFrame)
    local ZMovement = LookVector * (Movement.Forward - Movement.Backward)
    local XMovement = RightVector * (Movement.Right - Movement.Left)
    local YMovement = YVector * (Movement.Up - Movement.Down)

    return GetUnit(ZMovement + XMovement + YMovement)
end
function Utility.MakeBeam(Origin, Position, Color)
    --local BeamFolder = Instance.new("Folder")

    local OriginAttachment = Instance.new("Attachment")
    OriginAttachment.CFrame = CFrame.new(Origin)
    OriginAttachment.Name = "OriginAttachment"
    OriginAttachment.Parent = Terrain

    local PositionAttachment = Instance.new("Attachment")
    PositionAttachment.CFrame = CFrame.new(Position)
    PositionAttachment.Name = "PositionAttachment"
    PositionAttachment.Parent = Terrain

    local Beam = Instance.new("Beam")

    Beam.Name = "Beam"
    Beam.Color = ColorSequence.new(Color[6])
    Beam.LightEmission = 1
    Beam.LightInfluence = 1
    Beam.TextureMode = Enum.TextureMode.Static
    Beam.TextureSpeed = 0
    Beam.Transparency = NumberSequence.new(0)

    Beam.Attachment0 = OriginAttachment
    Beam.Attachment1 = PositionAttachment
    Beam.FaceCamera = true
    Beam.Segments = 1
    Beam.Width0 = 0.1
    Beam.Width1 = 0.1

    Beam.Parent = Terrain

    --BeamFolder = Terrain

    task.spawn(function()
        local Time = 1 * 60

        for Index = 1, Time do
            RunService.Heartbeat:Wait()
            Beam.Transparency = NumberSequence.new(Index / Time)
            Beam.Color = ColorSequence.new(Color[6])
        end

        OriginAttachment:Destroy()
        PositionAttachment:Destroy()
        Beam:Destroy()
    end)

    return Beam
end
function Utility.NewThreadLoop(Wait, Function)
    task.spawn(function()
        while true do
            local Delta = task.wait(Wait)
            local Success, Error = pcall(Function, Delta)
            if not Success then
                warn("thread error " .. Error)
            elseif Error == "break" then
                --print("thread stopped")
                break
            end
        end
    end)
end
function Utility.FixUpValue(fn, hook, gvar)
    if not hookfunction then return end
    if gvar then
        old = hookfunction(fn, function(...)
            return hook(old, ...)
        end)
    else
        local old = nil
        old = hookfunction(fn, function(...)
            return hook(old, ...)
        end)
    end
end

function Utility.ReJoin()
    if #PlayerService:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nSp3arParvus\nReconnecting to server...")
        task.wait(0.5)
        TeleportService:Teleport(game.PlaceId)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end
end
function Utility.ServerHop()
    local DataDecoded, Servers = HttpService:JSONDecode(game:HttpGet(
        "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/0?sortOrder=2&excludeFullGames=true&limit=100"
    )).data, {}

    for Index, ServerData in ipairs(DataDecoded) do
        if type(ServerData) == "table" and ServerData.id ~= game.JobId then
            table.insert(Servers, ServerData.id)
        end
    end

    if #Servers > 0 then
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId, Servers[math.random(#Servers)]
        )
    else
        Sp3arParvus.Utilities.UI:Push({
            Title = "Server Browser",
            Description = "No available servers found",
            Duration = 5
        })
    end
end
-- Removed Discord integration - keeping code clean and focused

function Utility.InitAutoLoad(Window)
    Window:AutoLoadConfig("Sp3arParvus")
    Window:SetValue("UI/Enabled", Window.Flags["UI/OOL"])
end
function Utility.SetupWatermark(Self, Window)
    local GetFPS = Self:SetupFPS()

    RunService.Heartbeat:Connect(function()
        if Window.Watermark.Enabled then
            Window.Watermark.Title = string.format(
                "Sp3arParvus    %s    %i FPS    %i MS",
                os.date("%X"), GetFPS(), math.round(Ping:GetValue())
            )
        end
    end)
end

-- UI Theme Configuration

function Utility.SettingsSection(Self, Window, UIKeybind, CustomMouse)
    local Backgrounds = {
        {"None", "", false},
        {"Legacy", "rbxassetid://2151741365", false},
        {"Hearts", "rbxassetid://6073763717", false},
        {"Abstract", "rbxassetid://6073743871", false},
        {"Hexagon", "rbxassetid://6073628839", false},
        {"Geometric", "rbxassetid://2062021684", false},
        {"Circles", "rbxassetid://6071579801", false},
        {"Checkered", "rbxassetid://4806196507", false},
        {"Lace With Flowers", "rbxassetid://6071575925", false},
        {"Flowers & Leafs", "rbxassetid://10921866694", false},
        {"Floral", "rbxassetid://5553946656", true},
        {"Leafs", "rbxassetid://10921868665", false},
        {"Mountains", "rbxassetid://10921801398", false},
        {"Halloween", "rbxassetid://11113209821", false},
        {"Christmas", "rbxassetid://11711560928", false},
        --{"A", "rbxassetid://5843010904", false},
        {"Polka dots", "rbxassetid://6214418014", false},
        {"Mountains", "rbxassetid://6214412460", false},
        {"Zigzag", "rbxassetid://6214416834", false},
        {"Zigzag 2", "rbxassetid://6214375242", false},
        {"Tartan", "rbxassetid://6214404863", false},
        {"Roses", "rbxassetid://6214374619", false},
        {"Hexagons", "rbxassetid://6214320051", false},
        {"Leopard print", "rbxassetid://6214318622", false},
        {"Blue Cubes", "rbxassetid://7188838187", false},
        {"Blue Waves", "rbxassetid://10952910471", false},
        {"White Circles", "rbxassetid://5168924660", false},
        {"Animal Print", "rbxassetid://6299360527", false},
        {"Fur", "rbxassetid://990886896", false},
        {"Marble", "rbxassetid://8904067198", false},
        {"Touhou", "rbxassetid://646426813", false},
        --{"Anime", "rbxassetid://9730243545", false},
        --{"Anime2", "rbxassetid://12756726256", false},
        --{"Anime3", "rbxassetid://7027352997", false},
        --{"Anime4", "rbxassetid://5931352430", false},
        --{"Hu Tao Edit", "rbxassetid://11424961420", false},
        --{"Waves", "rbxassetid://5351821237", false},
        --{"Nebula", "rbxassetid://159454288", false},
        --{"VaporWave", "rbxassetid://1417494643", false},
        --{"Clouds", "rbxassetid://570557727", false},
        --{"Twilight", "rbxassetid://264907379", false},
        --{"ZXC Cat", "rbxassetid://10300256322", false},
        --{"Pavuk Redan", "rbxassetid://12652997937", false},
        --{"Pink Anime Girl", "rbxassetid://11696859404", false},
        --{"Dark Anime Girl", "rbxassetid://10341849875", false},
        --{"TokyoGhoul", "rbxassetid://14007782187", false}
    }

    local BackgroundsList = {}
    for Index, Data in pairs(Backgrounds) do
        BackgroundsList[#BackgroundsList + 1] = {
            Name = Data[1], Mode = "Button", Value = Data[3], Callback = function()
            Window.Flags["Background/CustomImage"] = ""
            Window.Background.Image = Data[2]
        end}
    end

    local OptionsTab = Window:Tab({Name = "Options"}) do
        local MenuSection = OptionsTab:Section({Name = "Menu", Side = "Left"}) do
            local UIToggle = MenuSection:Toggle({Name = "UI Enabled", Flag = "UI/Enabled", IgnoreFlag = true,
            Value = Window.Enabled, Callback = function(Bool) Window.Enabled = Bool end})
            UIToggle:Keybind({Value = UIKeybind, Flag = "UI/Keybind", IgnoreList = true, DoNotClear = true})
            UIToggle:Colorpicker({Flag = "UI/Color", Value = {0.55, 0.85, 1, 0, true},
            Callback = function(HSVAR, Color) Window.Color = Color end})

            MenuSection:Toggle({Name = "Keybinds", IgnoreFlag = true, Flag = "UI/KeybindList",
            Value = false, Callback = function(Bool) Window.KeybindList.Enabled = Bool end})

            MenuSection:Toggle({Name = "Open On Load", Flag = "UI/OOL", Value = true})
            MenuSection:Toggle({Name = "Blur Gameplay", Flag = "UI/Blur", Value = false,
            Callback = function(Bool) Window.Blur = Bool end})

            MenuSection:Toggle({Name = "Custom Mouse", Flag = "Mouse/Enabled", Value = CustomMouse})

            MenuSection:Toggle({Name = "Watermark", Flag = "UI/Watermark/Enabled", Value = true,
            Callback = function(Bool) Window.Watermark.Enabled = Bool end}):Keybind({Flag = "UI/Watermark/Keybind"})

            MenuSection:Button({Name = "Rejoin", Callback = Self.ReJoin})
            MenuSection:Button({Name = "Server Hop", Callback = Self.ServerHop})
            MenuSection:Button({Name = "Copy Lua Invite", Callback = function()
                if setclipboard then
                    setclipboard("game:GetService(\"TeleportService\"):TeleportToPlaceInstance(" .. game.PlaceId .. ", \"" .. game.JobId .. "\")")
                end
            end})
            MenuSection:Button({Name = "Copy JS Invite", Callback = function()
                if setclipboard then
                    setclipboard("Roblox.GameLauncher.joinGameInstance(" .. game.PlaceId .. ", \"" .. game.JobId .. "\");")
                end
            end})
        end
        OptionsTab:AddConfigSection("Sp3arParvus", "Left")
        local BackgroundSection = OptionsTab:Section({Name = "Background", Side = "Right"}) do
            BackgroundSection:Colorpicker({Name = "Color", Flag = "Background/Color", Value = {0.6, 0.15, 0.15, 0.1, false},
            Callback = function(HSVAR, Color) Window.Background.ImageColor3 = Color Window.Background.ImageTransparency = HSVAR[4] end})
            BackgroundSection:Textbox({HideName = true, Flag = "Background/CustomImage", Placeholder = "rbxassetid://ImageId",
            Callback = function(String, EnterPressed) if EnterPressed then Window.Background.Image = String end end})
            BackgroundSection:Dropdown({HideName = true, Flag = "Background/Image", List = BackgroundsList})

            local TileSize = nil
            BackgroundSection:Divider({Text = "Background Tile"})
            BackgroundSection:Dropdown({HideName = true, Flag = "Background/TileMode", List = {
                {Name = "Tile Offset", Mode = "Button", Value = true, Callback = function()
                    if not TileSize then return end
                    TileSize.Name = "Offset"
                    TileSize.Min = 74
                    TileSize.Max = 296
                    TileSize.Unit = ""

                    TileSize.Value = TileSize.Value
                end},
                {Name = "Tile Scale", Mode = "Button", Callback = function()
                    if not TileSize then return end
                    TileSize.Name = "Scale"
                    TileSize.Min = 25
                    TileSize.Max = 100
                    TileSize.Unit = "%"

                    TileSize.Value = TileSize.Value
                end}
            }})

            TileSize = BackgroundSection:Slider({Name = "Offset", Flag = "Background/TileSize", Min = 74, Max = 296, Value = 74,
            Callback = function(Number)
                if TileSize.Name == "Offset" then
                    Window.Background.TileSize = UDim2.fromOffset(Number, Number)
                elseif TileSize.Name == "Scale" then
                    Window.Background.TileSize = UDim2.fromScale(Number / 100, Number / 100)
                end
            end})

            TileSize.Value = TileSize.Value
        end
        local CrosshairSection = OptionsTab:Section({Name = "Custom Crosshair", Side = "Right"}) do
            CrosshairSection:Toggle({Name = "Enabled", Flag = "Crosshair/Enabled", Value = false})
            :Colorpicker({Flag = "Crosshair/Color", Value = {1, 1, 1, 0, false}})
            CrosshairSection:Slider({Name = "Size", Flag = "Crosshair/Size", Min = 0, Max = 20, Value = 4, Unit = "px"})
            CrosshairSection:Slider({Name = "Gap", Flag = "Crosshair/Gap", Min = 0, Max = 10, Value = 2, Unit = "px"})
        end
        local InfoSection = OptionsTab:Section({Name = "Information", Side = "Right"}) do
            InfoSection:Label({Text = "Sp3arParvus v2.0"})
            InfoSection:Label({Text = "Advanced Game Enhancement Suite"})
            InfoSection:Divider({Text = "System Status"})
            InfoSection:Label({Text = "All systems operational"})
            InfoSection:Label({Text = "Optimized for performance"})
        end
    end

    Window:KeybindList({Enabled = false})
    Window:Watermark({Enabled = true})
end

function Utility.ESPSection(Self, Window, Name, Flag, BoxEnabled, ChamEnabled, HeadEnabled, TracerEnabled, OoVEnabled, LightingEnabled)
    local VisualsTab = Window:Tab({Name = Name}) do
        local GlobalSection = VisualsTab:Section({Name = "Global", Side = "Left"})

        GlobalSection:Toggle({Name = "Enable ESP", Flag = Flag .. "/Enabled", Value = true, Callback = function(Value)
            local DrawingUtilities = Sp3arParvus.Utilities and Sp3arParvus.Utilities.Drawing
            if not DrawingUtilities then return end

            if not Value then
                if DrawingUtilities.HideAll then
                    DrawingUtilities:HideAll()
                end
            else
                if DrawingUtilities.ResetAllESPCounters then
                    DrawingUtilities:ResetAllESPCounters()
                end
            end
        end})
        if BoxEnabled then
            local BoxSection = VisualsTab:Section({Name = "Boxes", Side = "Left"}) do
                BoxSection:Toggle({Name = "Box Enabled", Flag = Flag .. "/Box/Enabled", Value = true})
                BoxSection:Toggle({Name = "Healthbar", Flag = Flag .. "/Box/HealthBar", Value = true})

                BoxSection:Toggle({Name = "Filled", Flag = Flag .. "/Box/Filled", Value = true})
                BoxSection:Toggle({Name = "Outline", Flag = Flag .. "/Box/Outline", Value = true})
                BoxSection:Slider({Name = "Thickness", Flag = Flag .. "/Box/Thickness", Min = 1, Max = 19, Value = 1, OnlyOdd = true})
                BoxSection:Slider({Name = "Transparency", Flag = Flag .. "/Box/Transparency", Min = 0, Max = 1, Precise = 2, Value = 0})
                BoxSection:Slider({Name = "Corner Size", Flag = Flag .. "/Box/CornerSize", Min = 10, Max = 100, Value = 50, Unit = "%"})
                BoxSection:Divider()
                BoxSection:Toggle({Name = "Name Enabled", Flag = Flag .. "/Name/Enabled", Value = true})
                BoxSection:Toggle({Name = "Health Enabled", Flag = Flag .. "/Health/Enabled", Value = true})
                BoxSection:Toggle({Name = "Distance Enabled", Flag = Flag .. "/Distance/Enabled", Value = true})
                BoxSection:Toggle({Name = "Weapon Enabled", Flag = Flag .. "/Weapon/Enabled", Value = true})
                BoxSection:Toggle({Name = "Outline", Flag = Flag .. "/Name/Outline", Value = true})
                BoxSection:Toggle({Name = "Autoscale", Flag = Flag .. "/Name/Autoscale", Value = true})
                BoxSection:Slider({Name = "Size", Flag = Flag .. "/Name/Size", Min = 1, Max = 100, Value = 8})
                BoxSection:Slider({Name = "Transparency", Flag = Flag .. "/Name/Transparency", Min = 0, Max = 1, Precise = 2, Value = 0.25})
                --BoxSection:Slider({Name = "Test", Flag = Flag .. "/Test", Min = 0, Max = 100, Value = 0})
            end
        end
        --[[if ChamEnabled then
            local ChamSection = VisualsTab:Section({Name = "Chams", Side = "Left"}) do
                ChamSection:Toggle({Name = "Enabled", Flag = Flag .. "/Highlight/Enabled", Value = false})
                ChamSection:Toggle({Name = "Occluded", Flag = Flag .. "/Highlight/Occluded", Value = false})
                ChamSection:Slider({Name = "Transparency", Flag = Flag .. "/Highlight/Transparency", Min = 0, Max = 1, Precise = 2, Value = 0})
                ChamSection:Colorpicker({Name = "Outline Color", Flag = Flag .. "/Highlight/OutlineColor", Value = {1, 1, 0, 0.5, false}})
            end
        end]]
        if HeadEnabled then
            local HeadSection = VisualsTab:Section({Name = "Head Dots", Side = "Right"}) do
                HeadSection:Toggle({Name = "Enabled", Flag = Flag .. "/HeadDot/Enabled", Value = true})
                HeadSection:Toggle({Name = "Filled", Flag = Flag .. "/HeadDot/Filled", Value = true})
                HeadSection:Toggle({Name = "Outline", Flag = Flag .. "/HeadDot/Outline", Value = true})
                HeadSection:Toggle({Name = "Autoscale", Flag = Flag .. "/HeadDot/Autoscale", Value = true})
                HeadSection:Slider({Name = "Size", Flag = Flag .. "/HeadDot/Radius", Min = 1, Max = 100, Value = 4})
                --HeadSection:Slider({Name = "Smoothness", Flag = Flag .. "/HeadDot/Smoothness", Min = 0, Max = 100, Value = 10, Unit = "%"})
                HeadSection:Slider({Name = "NumSides", Flag = Flag .. "/HeadDot/NumSides", Min = 3, Max = 100, Value = 4})
                HeadSection:Slider({Name = "Thickness", Flag = Flag .. "/HeadDot/Thickness", Min = 1, Max = 10, Value = 1})
                HeadSection:Slider({Name = "Transparency", Flag = Flag .. "/HeadDot/Transparency", Min = 0, Max = 1, Precise = 2, Value = 0})
            end
        end
        if TracerEnabled then
            local TracerSection = VisualsTab:Section({Name = "Tracers", Side = "Right"}) do
                TracerSection:Toggle({Name = "Enabled", Flag = Flag .. "/Tracer/Enabled", Value = true})
                TracerSection:Toggle({Name = "Outline", Flag = Flag .. "/Tracer/Outline", Value = true})
                TracerSection:Dropdown({Name = "Mode", Flag = Flag .. "/Tracer/Mode", List = {
                    {Name = "From Bottom", Mode = "Button", Value = true},
                    {Name = "From Mouse", Mode = "Button"}
                }})
                TracerSection:Slider({Name = "Thickness", Flag = Flag .. "/Tracer/Thickness", Min = 1, Max = 10, Value = 1})
                TracerSection:Slider({Name = "Transparency", Flag = Flag .. "/Tracer/Transparency", Min = 0, Max = 1, Precise = 2, Value = 0})
            end
        end
        if OoVEnabled then
            local OoVSection = VisualsTab:Section({Name = "Offscreen Arrows", Side = "Right"}) do
                OoVSection:Toggle({Name = "Enabled", Flag = Flag .. "/Arrow/Enabled", Value = true})
                OoVSection:Toggle({Name = "Filled", Flag = Flag .. "/Arrow/Filled", Value = true})
                OoVSection:Toggle({Name = "Outline", Flag = Flag .. "/Arrow/Outline", Value = true})
                OoVSection:Slider({Name = "Width", Flag = Flag .. "/Arrow/Width", Min = 14, Max = 28, Value = 14})
                OoVSection:Slider({Name = "Height", Flag = Flag .. "/Arrow/Height", Min = 14, Max = 28, Value = 28})
                OoVSection:Slider({Name = "Distance From Center", Flag = Flag .. "/Arrow/Radius", Min = 80, Max = 200, Value = 150})
                OoVSection:Slider({Name = "Thickness", Flag = Flag .. "/Arrow/Thickness", Min = 1, Max = 10, Value = 1})
                OoVSection:Slider({Name = "Transparency", Flag = Flag .. "/Arrow/Transparency", Min = 0, Max = 1, Precise = 2, Value = 0})
            end
        end
        if LightingEnabled then
            Self:LightingSection(VisualsTab)
        end

        return GlobalSection
    end
end

function Utility.LightingSection(Self, Tab, Side)
    local LightingSection = Tab:Section({Name = "Lighting", Side = Side}) do
        LightingSection:Toggle({Name = "Enabled", Flag = "Lighting/Enabled", Value = false,
        Callback = function(Bool) if Bool then return end
            for Property, Value in pairs(Self.DefaultLighting) do
                Lighting[Property] = Value
            end
        end})

        LightingSection:Colorpicker({Name = "Ambient", Flag = "Lighting/Ambient", Value = {1, 0, 1, 0, false}})
        LightingSection:Slider({Name = "Brightness", Flag = "Lighting/Brightness", Min = 0, Max = 10, Precise = 2, Value = 3})
        LightingSection:Slider({Name = "ClockTime", Flag = "Lighting/ClockTime", Min = 0, Max = 24, Precise = 2, Value = 12})
        LightingSection:Colorpicker({Name = "ColorShift_Bottom", Flag = "Lighting/ColorShift_Bottom", Value = {1, 0, 1, 0, false}})
        LightingSection:Colorpicker({Name = "ColorShift_Top", Flag = "Lighting/ColorShift_Top", Value = {1, 0, 1, 0, false}})
        LightingSection:Slider({Name = "EnvironmentDiffuseScale", Flag = "Lighting/EnvironmentDiffuseScale", Min = 0, Max = 1, Precise = 3, Value = 0})
        LightingSection:Slider({Name = "EnvironmentSpecularScale", Flag = "Lighting/EnvironmentSpecularScale", Min = 0, Max = 1, Precise = 3, Value = 0})
        LightingSection:Slider({Name = "ExposureCompensation", Flag = "Lighting/ExposureCompensation", Min = -3, Max = 3, Precise = 2, Value = 0})
        LightingSection:Colorpicker({Name = "FogColor", Flag = "Lighting/FogColor", Value = {1, 0, 1, 0, false}})
        LightingSection:Slider({Name = "FogEnd", Flag = "Lighting/FogEnd", Min = 0, Max = 100000, Value = 100000})
        LightingSection:Slider({Name = "FogStart", Flag = "Lighting/FogStart", Min = 0, Max = 100000, Value = 0})
        LightingSection:Slider({Name = "GeographicLatitude", Flag = "Lighting/GeographicLatitude", Min = 0, Max = 360, Precise = 1, Value = 23.5})
        LightingSection:Toggle({Name = "GlobalShadows", Flag = "Lighting/GlobalShadows", Value = false})
        LightingSection:Colorpicker({Name = "OutdoorAmbient", Flag = "Lighting/OutdoorAmbient", Value = {1, 0, 1, 0, false}})
        LightingSection:Slider({Name = "ShadowSoftness", Flag = "Lighting/ShadowSoftness", Min = 0, Max = 1, Precise = 2, Value = 0})
        LightingSection:Toggle({Name = "Terrain Decoration", Flag = "Terrain/Decoration",
        Value = gethiddenproperty and gethiddenproperty(Terrain, "Decoration") or false,
        Callback = function(Value)
            if sethiddenproperty then
                sethiddenproperty(Terrain, "Decoration", Value)
            end
        end})
    end
end
function Utility.SetupLighting(Self, Flags)
    Self.DefaultLighting = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        ExposureCompensation = Lighting.ExposureCompensation,
        FogColor = Lighting.FogColor,
        FogEnd = Lighting.FogEnd,
        FogStart = Lighting.FogStart,
        GeographicLatitude = Lighting.GeographicLatitude,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ShadowSoftness = Lighting.ShadowSoftness
    }

    Lighting.Changed:Connect(function(Property)
        if Property == "TimeOfDay" then return end local Value = nil
        if not pcall(function() Value = Lighting[Property] end) then return end
        local CustomValue, FormatedValue = Flags["Lighting/" .. Property], Value
        local DefaultValue = Self.DefaultLighting[Property]

        if type(CustomValue) == "table" then
            CustomValue = CustomValue[6]
        end

        if type(FormatedValue) == "number" then
            if Property == "EnvironmentSpecularScale" or Property == "EnvironmentDiffuseScale" then
                FormatedValue = tonumber(string.format("%.3f", FormatedValue))
            else
                FormatedValue = tonumber(string.format("%.2f", FormatedValue))
            end --print("format current", Property, FormatedValue)
        end

        if CustomValue ~= FormatedValue and Value ~= DefaultValue then
            --print("default prop", Property, Value)
            Self.DefaultLighting[Property] = Value
        end
    end)
    RunService.Heartbeat:Connect(function()
        if Flags["Lighting/Enabled"] then
            for Property in pairs(Self.DefaultLighting) do
                local CustomValue = Flags["Lighting/" .. Property]
                if type(CustomValue) == "table" then
                    CustomValue = CustomValue[6]
                end
                if Lighting[Property] ~= CustomValue then
                    Lighting[Property] = CustomValue
                end
            end
        end
    end)
end

for Key, Value in pairs(Utility) do
    Sp3arParvus.Utilities[Key] = Value
end

-- ===== UI SYSTEM =====
-- Modern, lightweight UI framework
Sp3arParvus.Utilities.UI = loadstring([=[
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local GuiInset = GuiService:GetGuiInset()
local LocalPlayer = PlayerService.LocalPlayer
local Bracket = {IsLocal = not identifyexecutor}

Bracket.Utilities = {
	TableToColor = function(Table)
		if type(Table) ~= "table" then return Table end
		return Color3.fromHSV(Table[1], Table[2], Table[3])
	end,
	ColorToString = function(Color)
		return ("%i, %i, %i"):format(Color.R * 255, Color.G * 255, Color.B * 255)
	end,
	Scale = function(Value, InputMin, InputMax, OutputMin, OutputMax)
		return OutputMin + (Value - InputMin) * (OutputMax - OutputMin) / (InputMax - InputMin)
	end,
	DeepCopy = function(Self, Original)
		local Copy = {}

		for Index, Value in pairs(Original) do
			if type(Value) == "table" then
				Value = Self:DeepCopy(Value)
			end

			Copy[Index] = Value
		end

		return Copy
	end,
	Proxify = function(Table)
		local Proxy, Events = {}, {}
		local ChangedEvent = Instance.new("BindableEvent")
		Table.Changed = ChangedEvent.Event
		Proxy.Internal = Table

		function Table:GetPropertyChangedSignal(Property)
			local PropertyEvent = Instance.new("BindableEvent")

			Events[Property] = Events[Property] or {}
			table.insert(Events[Property], PropertyEvent)

			return PropertyEvent.Event
		end

		setmetatable(Proxy, {
			__index = function(Self, Key)
				return Table[Key]
			end,
			__newindex = function(Self, Key, Value)
				local OldValue = Table[Key]
				Table[Key] = Value

				ChangedEvent:Fire(Key, Value, OldValue)
				if Events[Key] then
					for Index, Event in ipairs(Events[Key]) do
						Event:Fire(Value, OldValue)
					end
				end
			end
		})

		return Proxy
	end,
	GetType = function(Self, Object, Default, Type, UseProxify)
		if typeof(Object) == Type then
			return UseProxify and Self.Proxify(Object) or Object
		end

		return UseProxify and Self.Proxify(Default) or Default
	end,
	GetTextBounds = function(Text, Font, Size)
		return TextService:GetTextSize(Text, Size.Y, Font, Vector2.new(Size.X, 1e6))
	end,
	MakeDraggable = function(Dragger, Object, OnChange, OnEnd)
		local Position, StartPosition = nil, nil

		Dragger.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Position = UserInputService:GetMouseLocation()
				StartPosition = Object.AbsolutePosition
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if StartPosition and Input.UserInputType == Enum.UserInputType.MouseMovement then
				local Mouse = UserInputService:GetMouseLocation()
				local Delta = Mouse - Position
				Position = Mouse

				Delta = Object.Position + UDim2.fromOffset(Delta.X, Delta.Y)
				if OnChange then OnChange(Delta) end
			end
		end)
		Dragger.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if OnEnd then OnEnd(Object.Position, StartPosition) end
				Position, StartPosition = nil, nil
			end
		end)
	end,
	MakeResizeable = function(Dragger, Object, MinSize, MaxSize, OnChange, OnEnd)
		local Position, StartSize = nil, nil

		Dragger.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Position = UserInputService:GetMouseLocation()
				StartSize = Object.AbsoluteSize
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if StartSize and Input.UserInputType == Enum.UserInputType.MouseMovement then
				local Mouse = UserInputService:GetMouseLocation()
				local Delta = Mouse - Position
				local Size = StartSize + Delta

				local SizeX = math.max(MinSize.X, Size.X)
				--SizeX = math.min(MaxSize.X, Size.X)

				local SizeY = math.max(MinSize.Y, Size.Y)
				--SizeY = math.min(MaxSize.Y, Size.Y)

				OnChange(UDim2.fromOffset(SizeX, SizeY))
			end
		end)
		Dragger.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if OnEnd then OnEnd(Object.Size, StartSize) end
				Position, StartSize = nil, nil
			end
		end)
	end,
	ClosePopUps = function()
		for Index, Object in pairs(Bracket.Screen:GetChildren()) do
			if Object.Name == "OptionContainer" or Object.Name == "Palette" then
				Object.Visible = false
			end
		end
	end,
	ChooseTab = function(TabButtonAsset, TabAsset)
		for Index, Object in pairs(Bracket.Screen:GetChildren()) do
			if Object.Name == "OptionContainer" or Object.Name == "Palette" then
				Object.Visible = false
			end
		end
		for Index, Object in pairs(Bracket.Screen.Window.TabContainer:GetChildren()) do
			if Object:IsA("ScrollingFrame") then
				Object.Visible = Object == TabAsset
			end
		end
		for Index, Object in pairs(Bracket.Screen.Window.TabButtonContainer:GetChildren()) do
			if Object:IsA("TextButton") then
				Object.Highlight.Visible = Object == TabButtonAsset
			end
		end
	end,
	GetLongestSide = function(TabAsset)
		local LeftSideSize = TabAsset.LeftSide.ListLayout.AbsoluteContentSize
		local RightSideSize = TabAsset.RightSide.ListLayout.AbsoluteContentSize
		return LeftSideSize.Y >= RightSideSize.Y and TabAsset.LeftSide or TabAsset.RightSide
	end,
	GetShortestSide = function(TabAsset)
		local LeftSideSize = TabAsset.LeftSide.ListLayout.AbsoluteContentSize
		local RightSideSize = TabAsset.RightSide.ListLayout.AbsoluteContentSize
		return LeftSideSize.Y <= RightSideSize.Y and TabAsset.LeftSide or TabAsset.RightSide
	end,
	ChooseTabSide = function(Self, TabAsset, Mode)
		if Mode == "Left" then
			return TabAsset.LeftSide
		elseif Mode == "Right" then
			return TabAsset.RightSide
		else
			return Self.GetShortestSide(TabAsset)
		end
	end,
	FindElementByFlag = function(Elements, Flag)
		for Index, Element in pairs(Elements) do
			if Element.Flag == Flag then
				return Element
			end
		end
	end,
	GetConfigs = function(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfolder(FolderName .. "\\Configs") then makefolder(FolderName .. "\\Configs") end

		local Configs = {}
		for Index, Config in pairs(listfiles(FolderName .. "\\Configs") or {}) do
			Config = Config:gsub(FolderName .. "\\Configs\\", "")
			Config = Config:gsub(".json", "")

			Configs[#Configs + 1] = Config
		end

		return Configs
	end,
	ConfigsToList = function(FolderName)
		if not isfolder(FolderName) then makefolder(FolderName) end
		if not isfolder(FolderName .. "\\Configs") then makefolder(FolderName .. "\\Configs") end
		if not isfile(FolderName .. "\\AutoLoads.json") then writefile(FolderName .. "\\AutoLoads.json", "[]") end

		local AutoLoads = HttpService:JSONDecode(readfile(FolderName .. "\\AutoLoads.json"))
		local AutoLoad = AutoLoads[tostring(game.GameId)]

		local Configs = {}
		for Index, Config in pairs(listfiles(FolderName .. "\\Configs") or {}) do
			Config = Config:gsub(FolderName .. "\\Configs\\", "")
			Config = Config:gsub(".json", "")

			Configs[#Configs + 1] = {
				Name = Config,
				Mode = "Button",
				Value = Config == AutoLoad
			}
		end

		return Configs
	end
}
Bracket.Assets = {
	Screen = function(Self)
		local Screen = Instance.new("ScreenGui")
		Screen.Name = "Bracket"
		Screen.ResetOnSpawn = false
		Screen.IgnoreGuiInset = true
		Screen.DisplayOrder = Bracket.IsLocal and 0 or 10

		local ToolTip = Instance.new("TextLabel")
		ToolTip.Name = "ToolTip"
		ToolTip.ZIndex = 6
		ToolTip.Visible = false
		ToolTip.AnchorPoint = Vector2.new(0, 1)
		ToolTip.Size = UDim2.new(0, 45, 0, 20)
		ToolTip.BorderColor3 = Color3.fromRGB(63, 63, 63)
		ToolTip.Position = UDim2.new(0, 50, 0, 50)
		ToolTip.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		ToolTip.TextStrokeTransparency = 0.75
		ToolTip.TextSize = 14
		ToolTip.RichText = true
		ToolTip.TextColor3 = Color3.fromRGB(255, 255, 255)
		ToolTip.Text = "ToolTip"
		ToolTip.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		ToolTip.Parent = Screen

		local Watermark = Instance.new("TextLabel")
		Watermark.Name = "Watermark"
		Watermark.Visible = false
		Watermark.AnchorPoint = Vector2.new(1, 0)
		Watermark.Size = UDim2.new(0, 61, 0, 20)
		Watermark.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Watermark.Position = UDim2.new(1, -20, 0, 20)
		Watermark.BorderSizePixel = 2
		Watermark.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Watermark.TextStrokeTransparency = 0.75
		Watermark.TextSize = 14
		Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)
		Watermark.Text = "Watermark"
		Watermark.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Watermark.Parent = Screen

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = Watermark

		-- Push Notification
		local PNContainer = Instance.new("Frame")
		PNContainer.Name = "PNContainer"
		PNContainer.AnchorPoint = Vector2.new(0.5, 0.5)
		PNContainer.Size = UDim2.new(1, 0, 1, 0)
		PNContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		PNContainer.BackgroundTransparency = 1
		PNContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
		PNContainer.BorderSizePixel = 0
		PNContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		PNContainer.Parent = Screen

		local PNPadding = Instance.new("UIPadding")
		PNPadding.Name = "Padding"
		PNPadding.PaddingTop = UDim.new(0, 10)
		PNPadding.PaddingBottom = UDim.new(0, 10)
		PNPadding.PaddingLeft = UDim.new(0, 10)
		PNPadding.PaddingRight = UDim.new(0, 10)
		PNPadding.Parent = PNContainer

		local PNListLayout = Instance.new("UIListLayout")
		PNListLayout.Name = "ListLayout"
		PNListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		PNListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		PNListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PNListLayout.Padding = UDim.new(0, 12)
		PNListLayout.Parent = PNContainer

		-- Toast Notification
		local TNContainer = Instance.new("Frame")
		TNContainer.Name = "TNContainer"
		TNContainer.AnchorPoint = Vector2.new(0.5, 0.5)
		TNContainer.Size = UDim2.new(1, 0, 1, 0)
		TNContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TNContainer.BackgroundTransparency = 1
		TNContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
		TNContainer.BorderSizePixel = 0
		TNContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		TNContainer.Parent = Screen

		local TNPadding = Instance.new("UIPadding")
		TNPadding.Name = "Padding"
		TNPadding.PaddingTop = UDim.new(0, 39)
		TNPadding.PaddingBottom = UDim.new(0, 10)
		TNPadding.Parent = TNContainer

		local TNListLayout = Instance.new("UIListLayout")
		TNListLayout.Name = "ListLayout"
		TNListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		TNListLayout.Padding = UDim.new(0, 5)
		TNListLayout.Parent = TNContainer

		local KeybindList = Self.KeybindList()
		KeybindList.Parent = Screen

		return Screen
	end,
	Window = function()
		local Window = Instance.new("Frame")
		Window.Name = "Window"
		Window.Size = UDim2.new(0, 496, 0, 496)
		Window.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Window.Position = UDim2.new(0.5, -248, 0.5, -248)
		Window.BorderSizePixel = 2
		Window.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = Window

		local Drag = Instance.new("Frame")
		Drag.Name = "Drag"
		Drag.AnchorPoint = Vector2.new(0.5, 0)
		Drag.Size = UDim2.new(1, 0, 0, 16)
		Drag.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Drag.Position = UDim2.new(0.5, 0, 0, 0)
		Drag.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Drag.Parent = Window

		local Resize = Instance.new("ImageButton")
		Resize.Name = "Resize"
		Resize.ZIndex = 3
		Resize.AnchorPoint = Vector2.new(1, 1)
		Resize.Size = UDim2.new(0, 10, 0, 10)
		Resize.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Resize.BackgroundTransparency = 1
		Resize.Position = UDim2.new(1, 0, 1, 0)
		Resize.BorderSizePixel = 0
		Resize.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Resize.ImageColor3 = Color3.fromRGB(63, 63, 63)
		Resize.ScaleType = Enum.ScaleType.Fit
		Resize.ResampleMode = Enum.ResamplerMode.Pixelated
		Resize.Image = "rbxassetid://7368471234"
		Resize.Parent = Window

		local Snowflake = Instance.new("ImageLabel")
		Snowflake.Name = "Snowflake"
		Snowflake.Visible = false
		Snowflake.AnchorPoint = Vector2.new(0.5, 0)
		Snowflake.Size = UDim2.new(0, 10, 0, 10)
		Snowflake.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Snowflake.BackgroundTransparency = 1
		Snowflake.BorderSizePixel = 0
		Snowflake.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Snowflake.Image = "rbxassetid://242109931"
		Snowflake.Parent = Window

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0)
		Title.Size = UDim2.new(1, -10, 0, 16)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Window"
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Window

		local Label = Instance.new("TextLabel")
		Label.Name = "Version"
		Label.AnchorPoint = Vector2.new(0.5, 0)
		Label.Size = UDim2.new(1, -10, 0, 16)
		Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Label.BackgroundTransparency = 1
		Label.Position = UDim2.new(0.5, 0, 0, 0)
		Label.BorderSizePixel = 0
		Label.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Label.TextStrokeTransparency = 0.75
		Label.TextSize = 14
		Label.RichText = true
		Label.TextColor3 = Color3.fromRGB(120, 200, 255)
		Label.Text = "v2.0"
		Label.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Label.TextXAlignment = Enum.TextXAlignment.Right
		Label.Parent = Window

		local MinimizeButton = Instance.new("TextButton")
		MinimizeButton.Name = "MinimizeButton"
		MinimizeButton.AnchorPoint = Vector2.new(1, 0.5)
		MinimizeButton.Size = UDim2.new(0, 16, 0, 16)
		MinimizeButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		MinimizeButton.BackgroundTransparency = 0.5
		MinimizeButton.Position = UDim2.new(1, -2, 0, 8)
		MinimizeButton.BorderSizePixel = 0
		MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		MinimizeButton.TextStrokeTransparency = 0.75
		MinimizeButton.TextSize = 14
		MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		MinimizeButton.Text = "−"
		MinimizeButton.FontFace = Font.fromEnum(Enum.Font.SourceSansBold)
		MinimizeButton.Parent = Window

		local MinimizeStroke = Instance.new("UIStroke")
		MinimizeStroke.Name = "Stroke"
		MinimizeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		MinimizeStroke.LineJoinMode = Enum.LineJoinMode.Miter
		MinimizeStroke.Color = Color3.fromRGB(80, 80, 80)
		MinimizeStroke.Thickness = 1
		MinimizeStroke.Parent = MinimizeButton

		local MinimizeCorner = Instance.new("UICorner")
		MinimizeCorner.CornerRadius = UDim.new(0, 2)
		MinimizeCorner.Parent = MinimizeButton

		local Background = Instance.new("ImageLabel")
		Background.Name = "Background"
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 1, -34)
		Background.ClipsDescendants = true
		Background.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Background.Position = UDim2.new(0.5, 0, 0, 34)
		Background.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Background.ScaleType = Enum.ScaleType.Tile
		Background.ImageColor3 = Color3.fromRGB(0, 0, 0)
		Background.TileSize = UDim2.new(0, 74, 0, 74)
		Background.Image = "rbxassetid://5553946656"
		Background.Parent = Window

		local TabContainer = Instance.new("Frame")
		TabContainer.Name = "TabContainer"
		TabContainer.AnchorPoint = Vector2.new(0.5, 0)
		TabContainer.Size = UDim2.new(1, 0, 1, -34)
		TabContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabContainer.BackgroundTransparency = 1
		TabContainer.Position = UDim2.new(0.5, 0, 0, 34)
		TabContainer.BorderSizePixel = 0
		TabContainer.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		TabContainer.Parent = Window

		local TabButtonContainer = Instance.new("ScrollingFrame")
		TabButtonContainer.Name = "TabButtonContainer"
		TabButtonContainer.AnchorPoint = Vector2.new(0.5, 0)
		TabButtonContainer.Size = UDim2.new(1, 0, 0, 17)
		TabButtonContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabButtonContainer.BackgroundTransparency = 1
		TabButtonContainer.Position = UDim2.new(0.5, 0, 0, 17)
		TabButtonContainer.Active = true
		TabButtonContainer.BorderSizePixel = 0
		TabButtonContainer.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		TabButtonContainer.ScrollingDirection = Enum.ScrollingDirection.X
		TabButtonContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		TabButtonContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		TabButtonContainer.MidImage = "rbxassetid://6432766838"
		TabButtonContainer.ScrollBarThickness = 0
		TabButtonContainer.TopImage = "rbxassetid://6432766838"
		TabButtonContainer.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		TabButtonContainer.BottomImage = "rbxassetid://6432766838"
		TabButtonContainer.Parent = Window

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.FillDirection = Enum.FillDirection.Horizontal
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Parent = TabButtonContainer

		return Window
	end,
	PushNotification = function()
		local Notification = Instance.new("Frame")
		Notification.Name = "Notification"
		Notification.Size = UDim2.new(0, 200, 0, 48)
		Notification.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Notification.BorderSizePixel = 2
		Notification.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = Notification

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 4)
		Padding.PaddingBottom = UDim.new(0, 4)
		Padding.PaddingLeft = UDim.new(0, 4)
		Padding.PaddingRight = UDim.new(0, 4)
		Padding.Parent = Notification

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 5)
		ListLayout.Parent = Notification

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.Size = UDim2.new(1, 0, 0, 14)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Title"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Notification

		local Description = Instance.new("TextLabel")
		Description.Name = "Description"
		Description.LayoutOrder = 2
		Description.Size = UDim2.new(1, 0, 0, 14)
		Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Description.BorderSizePixel = 0
		Description.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Description.TextStrokeTransparency = 0.75
		Description.TextSize = 14
		Description.RichText = true
		Description.TextColor3 = Color3.fromRGB(255, 255, 255)
		Description.Text = "Description"
		Description.TextWrapped = true
		Description.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Description.TextXAlignment = Enum.TextXAlignment.Left
		Description.Parent = Notification

		local Divider = Instance.new("Frame")
		Divider.Name = "Divider"
		Divider.LayoutOrder = 1
		Divider.Size = UDim2.new(1, -2, 0, 2)
		Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Divider.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Divider.Parent = Notification

		local Close = Instance.new("TextButton")
		Close.Name = "Close"
		Close.AnchorPoint = Vector2.new(1, 0.5)
		Close.Size = UDim2.new(0, 14, 1, 0)
		Close.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Close.Position = UDim2.new(1, 0, 0.5, 0)
		Close.BorderSizePixel = 0
		Close.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Close.AutoButtonColor = false
		Close.TextStrokeTransparency = 0.75
		Close.TextSize = 14
		Close.TextColor3 = Color3.fromRGB(255, 255, 255)
		Close.Text = "X"
		Close.FontFace = Font.fromEnum(Enum.Font.Nunito)
		Close.Parent = Title

		return Notification
	end,
	ToastNotification = function()
		local Notification = Instance.new("Frame")
		Notification.Name = "Notification"
		Notification.Size = UDim2.new(0, 259, 0, 24)
		Notification.ClipsDescendants = true
		Notification.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Notification.BackgroundTransparency = 1
		Notification.BorderSizePixel = 2
		Notification.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Main = Instance.new("Frame")
		Main.Name = "Main"
		Main.Size = UDim2.new(0, 255, 0, 20)
		Main.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Main.Position = UDim2.new(0, 2, 0, 2)
		Main.BorderSizePixel = 2
		Main.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Main.Parent = Notification

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = Main

		local GradientLine = Instance.new("Frame")
		GradientLine.Name = "GradientLine"
		GradientLine.AnchorPoint = Vector2.new(1, 0.5)
		GradientLine.Size = UDim2.new(0, 2, 1, 4)
		GradientLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
		GradientLine.Position = UDim2.new(0, 0, 0.5, 0)
		GradientLine.BorderSizePixel = 0
		GradientLine.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
		GradientLine.Parent = Main

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0),
			NumberSequenceKeypoint.new(0.75, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		Gradient.Rotation = 90
		Gradient.Parent = GradientLine

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, -10, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Hit OnlyTwentyCharacters in the Head with AK47"
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Main

		return Notification
	end,
	KeybindList = function()
		local KeybindList = Instance.new("Frame")
		KeybindList.Name = "KeybindList"
		KeybindList.ZIndex = 4
		KeybindList.Visible = false
		KeybindList.Size = UDim2.new(0, 121, 0, 246)
		KeybindList.BorderColor3 = Color3.fromRGB(0, 0, 0)
		KeybindList.Position = UDim2.new(0, 10, 0.5, -123)
		KeybindList.BorderSizePixel = 2
		KeybindList.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = KeybindList

		local Drag = Instance.new("Frame")
		Drag.Name = "Drag"
		Drag.ZIndex = 4
		Drag.AnchorPoint = Vector2.new(0.5, 0)
		Drag.Size = UDim2.new(1, 0, 0, 16)
		Drag.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Drag.Position = UDim2.new(0.5, 0, 0, 0)
		Drag.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Drag.Parent = KeybindList

		local Resize = Instance.new("ImageButton")
		Resize.Name = "Resize"
		Resize.ZIndex = 5
		Resize.AnchorPoint = Vector2.new(1, 1)
		Resize.Size = UDim2.new(0, 10, 0, 10)
		Resize.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Resize.BackgroundTransparency = 1
		Resize.Position = UDim2.new(1, 0, 1, 0)
		Resize.BorderSizePixel = 0
		Resize.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Resize.ImageColor3 = Color3.fromRGB(63, 63, 63)
		Resize.ScaleType = Enum.ScaleType.Fit
		Resize.ResampleMode = Enum.ResamplerMode.Pixelated
		Resize.Image = "rbxassetid://7368471234"
		Resize.Parent = KeybindList

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 4
		Title.AnchorPoint = Vector2.new(0.5, 0)
		Title.Size = UDim2.new(1, -10, 0, 16)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Keybinds"
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSansSemibold)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = KeybindList

		local Background = Instance.new("ImageLabel")
		Background.Name = "Background"
		Background.ZIndex = 4
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 1, -17)
		Background.ClipsDescendants = true
		Background.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Background.Position = UDim2.new(0.5, 0, 0, 17)
		Background.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Background.ScaleType = Enum.ScaleType.Tile
		Background.ImageColor3 = Color3.fromRGB(0, 0, 0)
		Background.TileSize = UDim2.new(0, 74, 0, 74)
		Background.Image = "rbxassetid://5553946656"
		Background.Parent = KeybindList

		local List = Instance.new("ScrollingFrame")
		List.Name = "List"
		List.ZIndex = 4
		List.AnchorPoint = Vector2.new(0.5, 0)
		List.Size = UDim2.new(1, 0, 1, -17)
		List.BorderColor3 = Color3.fromRGB(0, 0, 0)
		List.BackgroundTransparency = 1
		List.Position = UDim2.new(0.5, 0, 0, 17)
		List.Active = true
		List.BorderSizePixel = 0
		List.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		List.ScrollingDirection = Enum.ScrollingDirection.Y
		List.CanvasSize = UDim2.new(0, 0, 0, 0)
		List.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		List.MidImage = "rbxassetid://6432766838"
		List.ScrollBarThickness = 0
		List.TopImage = "rbxassetid://6432766838"
		List.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		List.BottomImage = "rbxassetid://6432766838"
		List.Parent = KeybindList

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 5)
		Padding.PaddingLeft = UDim.new(0, 5)
		Padding.PaddingRight = UDim.new(0, 5)
		Padding.Parent = List

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 5)
		ListLayout.Parent = List

		return KeybindList
	end,
	KeybindMimic = function()
		local KeybindMimic = Instance.new("Frame")
		KeybindMimic.Name = "KeybindMimic"
		KeybindMimic.ZIndex = 4
		KeybindMimic.Size = UDim2.new(1, 0, 0, 14)
		KeybindMimic.BorderColor3 = Color3.fromRGB(0, 0, 0)
		KeybindMimic.BackgroundTransparency = 1
		KeybindMimic.BorderSizePixel = 0
		KeybindMimic.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 5
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -14, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 14, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Toggle"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = KeybindMimic

		local Tick = Instance.new("Frame")
		Tick.Name = "Tick"
		Tick.ZIndex = 5
		Tick.AnchorPoint = Vector2.new(0, 0.5)
		Tick.Size = UDim2.new(0, 10, 0, 10)
		Tick.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tick.Position = UDim2.new(0, 0, 0.5, 0)
		Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Tick.Parent = KeybindMimic

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Tick

		local Layout = Instance.new("Frame")
		Layout.Name = "Layout"
		Layout.ZIndex = 5
		Layout.AnchorPoint = Vector2.new(1, 0.5)
		Layout.Size = UDim2.new(1, -56, 1, 0)
		Layout.ClipsDescendants = true
		Layout.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Layout.BackgroundTransparency = 1
		Layout.Position = UDim2.new(1, 1, 0.5, 0)
		Layout.BorderSizePixel = 0
		Layout.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Layout.Parent = KeybindMimic

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingRight = UDim.new(0, 1)
		Padding.Parent = Layout

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.FillDirection = Enum.FillDirection.Horizontal
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout.Parent = Layout

		local Keybind = Instance.new("TextLabel")
		Keybind.Name = "Keybind"
		Keybind.ZIndex = 5
		Keybind.Size = UDim2.new(0, 42, 1, 0)
		Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Keybind.BackgroundTransparency = 1
		Keybind.BorderSizePixel = 0
		Keybind.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		--Keybind.AutoButtonColor = false
		Keybind.TextStrokeTransparency = 0.75
		Keybind.TextSize = 14
		Keybind.RichText = true
		Keybind.TextColor3 = Color3.fromRGB(189, 189, 189)
		Keybind.Text = "[ NONE ]"
		Keybind.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Keybind.TextXAlignment = Enum.TextXAlignment.Right
		Keybind.Parent = Layout

		return KeybindMimic
	end,
	Tab = function()
		local Tab = Instance.new("ScrollingFrame")
		Tab.Name = "Tab"
		Tab.AnchorPoint = Vector2.new(0.5, 0.5)
		Tab.Size = UDim2.new(1, 0, 1, 0)
		Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tab.BackgroundTransparency = 1
		Tab.Position = UDim2.new(0.5, 0, 0.5, 0)
		Tab.Active = true
		Tab.BorderSizePixel = 0
		Tab.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Tab.ScrollingDirection = Enum.ScrollingDirection.Y
		Tab.CanvasSize = UDim2.new(0, 0, 0, 0)
		Tab.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		Tab.MidImage = "rbxassetid://6432766838"
		Tab.ScrollBarThickness = 0
		Tab.TopImage = "rbxassetid://6432766838"
		Tab.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		Tab.BottomImage = "rbxassetid://6432766838"

		local LeftSide = Instance.new("Frame")
		LeftSide.Name = "LeftSide"
		LeftSide.Size = UDim2.new(0.5, 0, 1, 0)
		LeftSide.BorderColor3 = Color3.fromRGB(0, 0, 0)
		LeftSide.BackgroundTransparency = 1
		LeftSide.BorderSizePixel = 0
		LeftSide.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		LeftSide.Parent = Tab

		local LeftPadding = Instance.new("UIPadding")
		LeftPadding.Name = "Padding"
		LeftPadding.PaddingTop = UDim.new(0, 11)
		LeftPadding.PaddingLeft = UDim.new(0, 5)
		LeftPadding.PaddingRight = UDim.new(0, 5)
		LeftPadding.Parent = LeftSide

		local LeftListLayout = Instance.new("UIListLayout")
		LeftListLayout.Name = "ListLayout"
		LeftListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		LeftListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		LeftListLayout.Padding = UDim.new(0, 10)
		LeftListLayout.Parent = LeftSide

		local RightSide = Instance.new("Frame")
		RightSide.Name = "RightSide"
		RightSide.AnchorPoint = Vector2.new(1, 0)
		RightSide.Size = UDim2.new(0.5, 0, 1, 0)
		RightSide.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RightSide.BackgroundTransparency = 1
		RightSide.Position = UDim2.new(1, 0, 0, 0)
		RightSide.BorderSizePixel = 0
		RightSide.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		RightSide.Parent = Tab

		local RightPadding = Instance.new("UIPadding")
		RightPadding.Name = "Padding"
		RightPadding.PaddingTop = UDim.new(0, 11)
		RightPadding.PaddingLeft = UDim.new(0, 5)
		RightPadding.PaddingRight = UDim.new(0, 5)
		RightPadding.Parent = RightSide

		local RightListLayout = Instance.new("UIListLayout")
		RightListLayout.Name = "ListLayout"
		RightListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		RightListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RightListLayout.Padding = UDim.new(0, 10)
		RightListLayout.Parent = RightSide

		return Tab
	end,
	TabButton = function()
		local TabButton = Instance.new("TextButton")
		TabButton.Name = "TabButton"
		TabButton.Size = UDim2.new(0, 67, 1, -1)
		TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BackgroundTransparency = 1
		TabButton.BorderSizePixel = 0
		TabButton.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		TabButton.AutoButtonColor = false
		TabButton.TextStrokeTransparency = 0.75
		TabButton.TextSize = 14
		TabButton.RichText = true
		TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		TabButton.Text = "TabButton"
		TabButton.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Highlight = Instance.new("Frame")
		Highlight.Name = "Highlight"
		Highlight.Visible = false
		Highlight.AnchorPoint = Vector2.new(0.5, 1)
		Highlight.Size = UDim2.new(1, 0, 0, 1)
		Highlight.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Highlight.Position = UDim2.new(0.5, 0, 1, 1)
		Highlight.BorderSizePixel = 0
		Highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Highlight.Parent = TabButton

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.25, 0),
			NumberSequenceKeypoint.new(0.75, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		Gradient.Parent = Highlight

		return TabButton
	end,
	Section = function()
		local Section = Instance.new("Frame")
		Section.Name = "Section"
		Section.ZIndex = 2
		Section.Size = UDim2.new(1, 0, 0, 10)
		Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Section.BorderSizePixel = 2
		Section.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Color = Color3.fromRGB(63, 63, 63)
		Stroke.Parent = Section

		local Border = Instance.new("Frame")
		Border.Name = "Border"
		Border.Visible = false
		Border.AnchorPoint = Vector2.new(0.5, 0.5)
		Border.Size = UDim2.new(1, 2, 1, 2)
		Border.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Border.Position = UDim2.new(0.5, 0, 0.5, 0)
		Border.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Border.Parent = Section

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.Size = UDim2.new(0, 44, 0, 2)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.Position = UDim2.new(0, 5, 0, -2)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Section"
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.Parent = Section

		local Container = Instance.new("Frame")
		Container.Name = "Container"
		Container.ZIndex = 2
		Container.AnchorPoint = Vector2.new(0.5, 0)
		Container.Size = UDim2.new(1, 0, 1, -10)
		Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Container.BackgroundTransparency = 1
		Container.BorderSizePixel = 0
		Container.Position = UDim2.new(0.5, 0, 0, 10)
		Container.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Container.Parent = Section

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingLeft = UDim.new(0, 5)
		Padding.PaddingRight = UDim.new(0, 5)
		Padding.Parent = Container

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 5)
		ListLayout.Parent = Container

		return Section
	end,
	Divider = function()
		local Divider = Instance.new("Frame")
		Divider.Name = "Divider"
		Divider.ZIndex = 2
		Divider.AnchorPoint = Vector2.new(0.5, 0)
		Divider.Size = UDim2.new(1, 0, 0, 14)
		Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Divider.BackgroundTransparency = 1
		Divider.BorderSizePixel = 0
		Divider.BackgroundColor3 = Color3.fromRGB(31, 31, 31)

		local Left = Instance.new("Frame")
		Left.Name = "Left"
		Left.ZIndex = 2
		Left.AnchorPoint = Vector2.new(0, 0.5)
		Left.Size = UDim2.new(0.5, -24, 0, 2)
		Left.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Left.Position = UDim2.new(0, 0, 0.5, 0)
		Left.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Left.Parent = Divider

		local Right = Instance.new("Frame")
		Right.Name = "Right"
		Right.ZIndex = 2
		Right.AnchorPoint = Vector2.new(1, 0.5)
		Right.Size = UDim2.new(0.5, -24, 0, 2)
		Right.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Right.Position = UDim2.new(1, 0, 0.5, 0)
		Right.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Right.Parent = Divider

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, 0, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Divider"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.Parent = Divider

		return Divider
	end,
	Label = function()
		local Label = Instance.new("TextLabel")
		Label.Name = "Label"
		Label.ZIndex = 2
		Label.Size = UDim2.new(1, 0, 0, 14)
		Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Label.BackgroundTransparency = 1
		Label.BorderSizePixel = 0
		Label.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Label.TextStrokeTransparency = 0.75
		Label.TextSize = 14
		Label.RichText = true
		Label.TextColor3 = Color3.fromRGB(255, 255, 255)
		Label.Text = "Text Label"
		Label.TextWrapped = true
		Label.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		return Label
	end,
	Button = function()
		local Button = Instance.new("TextButton")
		Button.Name = "Button"
		Button.ZIndex = 2
		Button.Size = UDim2.new(1, 0, 0, 16)
		Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Button.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Button.AutoButtonColor = false
		Button.TextStrokeTransparency = 0.75
		Button.TextSize = 14
		Button.RichText = true
		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		Button.Text = ""
		Button.TextWrapped = true
		Button.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, -12, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Button"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.Parent = Button

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Button

		return Button
	end,
	Toggle = function()
		local Toggle = Instance.new("TextButton")
		Toggle.Name = "Toggle"
		Toggle.ZIndex = 2
		Toggle.Size = UDim2.new(1, 0, 0, 14)
		Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Toggle.BackgroundTransparency = 1
		Toggle.BorderSizePixel = 0
		Toggle.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Toggle.AutoButtonColor = false
		Toggle.TextStrokeTransparency = 0.75
		Toggle.TextSize = 14
		Toggle.RichText = true
		Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
		Toggle.Text = ""
		Toggle.TextWrapped = true
		Toggle.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -14, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 14, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Toggle"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Toggle

		local Tick = Instance.new("Frame")
		Tick.Name = "Tick"
		Tick.ZIndex = 2
		Tick.AnchorPoint = Vector2.new(0, 0.5)
		Tick.Size = UDim2.new(0, 10, 0, 10)
		Tick.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tick.Position = UDim2.new(0, 0, 0.5, 0)
		Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Tick.Parent = Toggle

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Tick

		local Layout = Instance.new("Frame")
		Layout.Name = "Layout"
		Layout.ZIndex = 2
		Layout.AnchorPoint = Vector2.new(1, 0.5)
		Layout.Size = UDim2.new(1, -56, 1, 0)
		Layout.ClipsDescendants = true
		Layout.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Layout.BackgroundTransparency = 1
		Layout.Position = UDim2.new(1, 1, 0.5, 0)
		Layout.BorderSizePixel = 0
		Layout.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Layout.Parent = Toggle

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingRight = UDim.new(0, 1)
		Padding.Parent = Layout

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.FillDirection = Enum.FillDirection.Horizontal
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout.Parent = Layout

		return Toggle
	end,
	Slider = function()
		local Slider = Instance.new("TextButton")
		Slider.Name = "Slider"
		Slider.ZIndex = 2
		Slider.Size = UDim2.new(1, 0, 0, 16)
		Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Slider.BackgroundTransparency = 1
		Slider.BorderSizePixel = 0
		Slider.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Slider.AutoButtonColor = false
		Slider.TextStrokeTransparency = 0.75
		Slider.TextSize = 14
		Slider.RichText = true
		Slider.TextColor3 = Color3.fromRGB(255, 255, 255)
		Slider.Text = ""
		Slider.TextWrapped = true
		Slider.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.ZIndex = 2
		Background.AnchorPoint = Vector2.new(0.5, 0.5)
		Background.Size = UDim2.new(1, 0, 1, 0)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.Position = UDim2.new(0.5, 0, 0.5, 0)
		Background.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Background.Parent = Slider

		local BackGradient = Instance.new("UIGradient")
		BackGradient.Name = "Gradient"
		BackGradient.Rotation = 90
		BackGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		BackGradient.Parent = Background

		local Bar = Instance.new("Frame")
		Bar.Name = "Bar"
		Bar.ZIndex = 2
		Bar.AnchorPoint = Vector2.new(0, 0.5)
		Bar.Size = UDim2.new(0.5, 0, 1, 0)
		Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Bar.Position = UDim2.new(0, 0, 0.5, 0)
		Bar.BorderSizePixel = 0
		Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Bar.Parent = Background

		local BarGradient = Instance.new("UIGradient")
		BarGradient.Name = "Gradient"
		BarGradient.Rotation = 90
		BarGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		BarGradient.Parent = Bar

		local Value = Instance.new("TextBox")
		Value.Name = "Value"
		Value.ZIndex = 2
		Value.AnchorPoint = Vector2.new(1, 0)
		Value.Size = UDim2.new(0, 12, 1, 0)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(1, -6, 0, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Value.TextStrokeTransparency = 0.75
		Value.PlaceholderColor3 = Color3.fromRGB(189, 189, 189)
		Value.TextSize = 14
		Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		Value.PlaceholderText = "50"
		Value.Text = ""
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Right
		Value.Parent = Slider

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.Size = UDim2.new(1, -24, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 6, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Slider"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Slider

		return Slider
	end,
	SlimSlider = function()
		local Slider = Instance.new("TextButton")
		Slider.Name = "Slider"
		Slider.ZIndex = 2
		Slider.Size = UDim2.new(1, 0, 0, 22)
		Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Slider.BackgroundTransparency = 1
		Slider.BorderSizePixel = 0
		Slider.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Slider.AutoButtonColor = false
		Slider.TextStrokeTransparency = 0.75
		Slider.TextSize = 14
		Slider.RichText = true
		Slider.TextColor3 = Color3.fromRGB(255, 255, 255)
		Slider.Text = ""
		Slider.TextWrapped = true
		Slider.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.Size = UDim2.new(1, -12, 0, 16)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Slider"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Slider

		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.ZIndex = 2
		Background.AnchorPoint = Vector2.new(0.5, 1)
		Background.Size = UDim2.new(1, 0, 0, 6)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.Position = UDim2.new(0.5, 0, 1, 0)
		Background.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Background.Parent = Slider

		local BackGradient = Instance.new("UIGradient")
		BackGradient.Name = "Gradient"
		BackGradient.Rotation = 90
		BackGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		BackGradient.Parent = Background

		local Bar = Instance.new("Frame")
		Bar.Name = "Bar"
		Bar.ZIndex = 2
		Bar.AnchorPoint = Vector2.new(0, 0.5)
		Bar.Size = UDim2.new(0.5, 0, 1, 0)
		Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Bar.Position = UDim2.new(0, 0, 0.5, 0)
		Bar.BorderSizePixel = 0
		Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Bar.Parent = Background

		local BarGradient = Instance.new("UIGradient")
		BarGradient.Name = "Gradient"
		BarGradient.Rotation = 90
		BarGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		BarGradient.Parent = Bar

		local Value = Instance.new("TextBox")
		Value.Name = "Value"
		Value.ZIndex = 2
		Value.AnchorPoint = Vector2.new(1, 0)
		Value.Size = UDim2.new(0, 12, 0, 16)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(1, 0, 0, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Value.TextStrokeTransparency = 0.75
		Value.PlaceholderColor3 = Color3.fromRGB(189, 189, 189)
		Value.TextSize = 14
		Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		Value.PlaceholderText = "50"
		Value.Text = ""
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Right
		Value.Parent = Slider

		return Slider
	end,
	Textbox = function()
		local Textbox = Instance.new("TextButton")
		Textbox.Name = "Textbox"
		Textbox.ZIndex = 2
		Textbox.Size = UDim2.new(1, 0, 0, 32)
		Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Textbox.BackgroundTransparency = 1
		Textbox.BorderSizePixel = 0
		Textbox.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Textbox.AutoButtonColor = false
		Textbox.TextStrokeTransparency = 0.75
		Textbox.TextSize = 14
		Textbox.RichText = true
		Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
		Textbox.Text = ""
		Textbox.TextWrapped = true
		Textbox.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.AnchorPoint = Vector2.new(0.5, 0)
		Title.Size = UDim2.new(1, 0, 0, 16)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Textbox"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Textbox

		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.ZIndex = 2
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 0, 16)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.Position = UDim2.new(0.5, 0, 0, 16)
		Background.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Background.Parent = Textbox

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Background

		local Input = Instance.new("TextBox")
		Input.Name = "Input"
		Input.ZIndex = 2
		Input.AnchorPoint = Vector2.new(0.5, 0.5)
		Input.Size = UDim2.new(1, -10, 1, 0)
		Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Input.BackgroundTransparency = 1
		Input.Position = UDim2.new(0.5, 0, 0.5, 0)
		Input.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Input.TextStrokeTransparency = 0.75
		Input.TextWrapped = true
		Input.PlaceholderColor3 = Color3.fromRGB(189, 189, 189)
		Input.TextSize = 14
		Input.TextColor3 = Color3.fromRGB(255, 255, 255)
		Input.PlaceholderText = "Input here"
		Input.Text = ""
		Input.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Input.ClearTextOnFocus = false
		Input.Parent = Background

		return Textbox
	end,
	Keybind = function()
		local Keybind = Instance.new("TextButton")
		Keybind.Name = "Keybind"
		Keybind.ZIndex = 2
		Keybind.Size = UDim2.new(1, 0, 0, 14)
		Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Keybind.BackgroundTransparency = 1
		Keybind.BorderSizePixel = 0
		Keybind.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Keybind.AutoButtonColor = false
		Keybind.TextStrokeTransparency = 0.75
		Keybind.TextSize = 14
		Keybind.RichText = true
		Keybind.TextColor3 = Color3.fromRGB(255, 255, 255)
		Keybind.Text = ""
		Keybind.TextWrapped = true
		Keybind.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -42, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Keybind"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Keybind

		local Value = Instance.new("TextLabel")
		Value.Name = "Value"
		Value.ZIndex = 2
		Value.AnchorPoint = Vector2.new(1, 0.5)
		Value.Size = UDim2.new(0, 42, 1, 0)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(1, 0, 0.5, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Value.TextStrokeTransparency = 0.75
		Value.TextSize = 14
		Value.RichText = true
		Value.TextColor3 = Color3.fromRGB(189, 189, 189)
		Value.Text = "[ NONE ]"
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Right
		Value.Parent = Keybind

		return Keybind
	end,
	ToggleKeybind = function()
		local Keybind = Instance.new("TextButton")
		Keybind.Name = "Keybind"
		Keybind.ZIndex = 2
		Keybind.Size = UDim2.new(0, 42, 1, 0)
		Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Keybind.BackgroundTransparency = 1
		Keybind.BorderSizePixel = 0
		Keybind.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Keybind.AutoButtonColor = false
		Keybind.TextStrokeTransparency = 0.75
		Keybind.TextSize = 14
		Keybind.RichText = true
		Keybind.TextColor3 = Color3.fromRGB(189, 189, 189)
		Keybind.Text = "[ NONE ]"
		Keybind.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Keybind.TextXAlignment = Enum.TextXAlignment.Right

		return Keybind
	end,
	Dropdown = function()
		local Dropdown = Instance.new("TextButton")
		Dropdown.Name = "Dropdown"
		Dropdown.ZIndex = 2
		Dropdown.Size = UDim2.new(1, 0, 0, 32)
		Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Dropdown.BackgroundTransparency = 1
		Dropdown.BorderSizePixel = 0
		Dropdown.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Dropdown.AutoButtonColor = false
		Dropdown.TextStrokeTransparency = 0.75
		Dropdown.TextSize = 14
		Dropdown.RichText = true
		Dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
		Dropdown.Text = ""
		Dropdown.TextWrapped = true
		Dropdown.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.AnchorPoint = Vector2.new(0.5, 0)
		Title.Size = UDim2.new(1, 0, 0, 16)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Dropdown"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Dropdown

		local Background = Instance.new("Frame")
		Background.Name = "Background"
		Background.ZIndex = 2
		Background.AnchorPoint = Vector2.new(0.5, 0)
		Background.Size = UDim2.new(1, 0, 0, 16)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.Position = UDim2.new(0.5, 0, 0, 16)
		Background.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Background.Parent = Dropdown

		local Value = Instance.new("TextLabel")
		Value.Name = "Value"
		Value.ZIndex = 2
		Value.AnchorPoint = Vector2.new(0.5, 0.5)
		Value.Size = UDim2.new(1, -10, 1, 0)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(0.5, 0, 0.5, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Value.TextStrokeTransparency = 0.75
		Value.TextTruncate = Enum.TextTruncate.AtEnd
		Value.TextSize = 14
		Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		Value.Text = "..."
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Left
		Value.Parent = Background

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Background

		return Dropdown
	end,
	DropdownContainer = function()
		local OptionContainer = Instance.new("ScrollingFrame")
		OptionContainer.Name = "OptionContainer"
		OptionContainer.ZIndex = 3
		OptionContainer.Visible = false
		OptionContainer.Size = UDim2.new(0, 100, 0, 100)
		OptionContainer.BorderColor3 = Color3.fromRGB(0, 0, 0)
		OptionContainer.Active = true
		OptionContainer.BorderSizePixel = 0
		OptionContainer.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		OptionContainer.ScrollingDirection = Enum.ScrollingDirection.Y
		OptionContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
		OptionContainer.ScrollBarImageColor3 = Color3.fromRGB(31, 31, 31)
		OptionContainer.MidImage = "rbxassetid://6432766838"
		OptionContainer.ScrollBarThickness = 2
		OptionContainer.TopImage = "rbxassetid://6432766838"
		OptionContainer.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
		OptionContainer.BottomImage = "rbxassetid://6432766838"

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Parent = OptionContainer

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingTop = UDim.new(0, 2)
		Padding.PaddingBottom = UDim.new(0, 2)
		Padding.PaddingLeft = UDim.new(0, 2)
		Padding.PaddingRight = UDim.new(0, 2)
		Padding.Parent = OptionContainer

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 2)
		ListLayout.Parent = OptionContainer

		return OptionContainer
	end,
	DropdownOption = function()
		local Option = Instance.new("TextButton")
		Option.Name = "Option"
		Option.ZIndex = 3
		Option.Size = UDim2.new(1, 0, 0, 16)
		Option.BorderColor3 = Color3.fromRGB(63, 63, 63)
		Option.BorderSizePixel = 0
		Option.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Option.AutoButtonColor = false
		Option.TextStrokeTransparency = 0.75
		Option.TextSize = 14
		Option.RichText = true
		Option.TextColor3 = Color3.fromRGB(255, 255, 255)
		Option.Text = ""
		Option.TextWrapped = true
		Option.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Option

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 3
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -18, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 18, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextTruncate = Enum.TextTruncate.AtEnd
		Title.TextSize = 14
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Toggle"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Option

		local Tick = Instance.new("Frame")
		Tick.Name = "Tick"
		Tick.ZIndex = 3
		Tick.AnchorPoint = Vector2.new(0, 0.5)
		Tick.Size = UDim2.new(0, 12, 0, 12)
		Tick.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tick.Position = UDim2.new(0, 2, 0.5, 0)
		Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		Tick.Parent = Option

		local TickGradient = Instance.new("UIGradient")
		TickGradient.Name = "Gradient"
		TickGradient.Rotation = 90
		TickGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		TickGradient.Parent = Tick

		local Layout = Instance.new("Frame")
		Layout.Name = "Layout"
		Layout.ZIndex = 3
		Layout.AnchorPoint = Vector2.new(1, 0.5)
		Layout.Size = UDim2.new(1, -54, 1, 0)
		Layout.ClipsDescendants = true
		Layout.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Layout.BackgroundTransparency = 1
		Layout.Position = UDim2.new(1, -1, 0.5, 0)
		Layout.BorderSizePixel = 0
		Layout.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Layout.Parent = Option

		local Padding = Instance.new("UIPadding")
		Padding.Name = "Padding"
		Padding.PaddingRight = UDim.new(0, 1)
		Padding.Parent = Layout

		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Name = "ListLayout"
		ListLayout.FillDirection = Enum.FillDirection.Horizontal
		ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout.Parent = Layout

		return Option
	end,
	Colorpicker = function()
		local Colorpicker = Instance.new("TextButton")
		Colorpicker.Name = "Colorpicker"
		Colorpicker.ZIndex = 2
		Colorpicker.Size = UDim2.new(1, 0, 0, 14)
		Colorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Colorpicker.BackgroundTransparency = 1
		Colorpicker.BorderSizePixel = 0
		Colorpicker.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Colorpicker.AutoButtonColor = false
		Colorpicker.TextStrokeTransparency = 0.75
		Colorpicker.TextSize = 14
		Colorpicker.RichText = true
		Colorpicker.TextColor3 = Color3.fromRGB(255, 255, 255)
		Colorpicker.Text = ""
		Colorpicker.TextWrapped = true
		Colorpicker.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 2
		Title.AnchorPoint = Vector2.new(0.5, 0.5)
		Title.Size = UDim2.new(1, 0, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0.5, 0, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Colorpicker"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Colorpicker

		local Color = Instance.new("Frame")
		Color.Name = "Color"
		Color.ZIndex = 2
		Color.AnchorPoint = Vector2.new(1, 0.5)
		Color.Size = UDim2.new(0, 20, 0, 10)
		Color.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Color.Position = UDim2.new(1, 0, 0.5, 0)
		Color.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		Color.Parent = Colorpicker

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Color

		return Colorpicker
	end,
	ToggleColorpicker = function()
		local TColorpicker = Instance.new("TextButton")
		TColorpicker.Name = "TColorpicker"
		TColorpicker.ZIndex = 2
		TColorpicker.AnchorPoint = Vector2.new(1, 0.5)
		TColorpicker.Size = UDim2.new(0, 24, 0, 12)
		TColorpicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TColorpicker.Position = UDim2.new(1, 0, 0.5, 0)
		TColorpicker.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		TColorpicker.AutoButtonColor = false
		TColorpicker.TextStrokeTransparency = 0.75
		TColorpicker.TextSize = 14
		TColorpicker.RichText = true
		TColorpicker.TextColor3 = Color3.fromRGB(255, 255, 255)
		TColorpicker.Text = ""
		TColorpicker.TextWrapped = true
		TColorpicker.FontFace = Font.fromEnum(Enum.Font.SourceSans)

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = TColorpicker

		return TColorpicker
	end,
	ColorpickerPalette = function()
		local Palette = Instance.new("Frame")
		Palette.Name = "Palette"
		Palette.ZIndex = 3
		Palette.Visible = false
		Palette.Size = UDim2.new(0, 150, 0, 290)
		Palette.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Palette.Position = UDim2.new(0, 20, 0, 20)
		Palette.BackgroundColor3 = Color3.fromRGB(63, 63, 63)

		local Gradient = Instance.new("UIGradient")
		Gradient.Name = "Gradient"
		Gradient.Rotation = 90
		Gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		Gradient.Parent = Palette

		local SVPicker = Instance.new("TextButton")
		SVPicker.Name = "SVPicker"
		SVPicker.ZIndex = 3
		SVPicker.AnchorPoint = Vector2.new(0.5, 0)
		SVPicker.Size = UDim2.new(1, -10, 0, 180)
		SVPicker.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SVPicker.Position = UDim2.new(0.5, 0, 0, 5)
		SVPicker.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		SVPicker.AutoButtonColor = false
		SVPicker.TextStrokeTransparency = 0.75
		SVPicker.TextSize = 14
		SVPicker.RichText = true
		SVPicker.TextColor3 = Color3.fromRGB(255, 255, 255)
		SVPicker.Text = ""
		SVPicker.TextWrapped = true
		SVPicker.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		SVPicker.Parent = Palette

		local Saturation = Instance.new("Frame")
		Saturation.Name = "Saturation"
		Saturation.ZIndex = 3
		Saturation.AnchorPoint = Vector2.new(0.5, 0.5)
		Saturation.Size = UDim2.new(1, 0, 1, 0)
		Saturation.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Saturation.Position = UDim2.new(0.5, 0, 0.5, 0)
		Saturation.BorderSizePixel = 0
		Saturation.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		Saturation.Parent = SVPicker

		local SaturationGradient = Instance.new("UIGradient")
		SaturationGradient.Name = "Gradient"
		SaturationGradient.Transparency = NumberSequence.new(1, 0)
		SaturationGradient.Rotation = 90
		SaturationGradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
		SaturationGradient.Parent = Saturation

		local Brightness = Instance.new("Frame")
		Brightness.Name = "Brightness"
		Brightness.ZIndex = 3
		Brightness.AnchorPoint = Vector2.new(0.5, 0.5)
		Brightness.Size = UDim2.new(1, 0, 1, 0)
		Brightness.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Brightness.Position = UDim2.new(0.5, 0, 0.5, 0)
		Brightness.BorderSizePixel = 0
		Brightness.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Brightness.Parent = SVPicker

		local BrightnessGradient = Instance.new("UIGradient")
		BrightnessGradient.Name = "Gradient"
		BrightnessGradient.Transparency = NumberSequence.new(0, 1)
		BrightnessGradient.Parent = Brightness

		local SVPin = Instance.new("Frame")
		SVPin.Name = "Pin"
		SVPin.ZIndex = 3
		SVPin.AnchorPoint = Vector2.new(0.5, 0.5)
		SVPin.Size = UDim2.new(0, 3, 0, 3)
		SVPin.BorderColor3 = Color3.fromRGB(0, 0, 0)
		SVPin.Rotation = 45
		SVPin.BackgroundTransparency = 1
		SVPin.Position = UDim2.new(0.5, 0, 0.5, 0)
		SVPin.BorderSizePixel = 0
		SVPin.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SVPin.Parent = SVPicker

		local SVPinStroke = Instance.new("UIStroke")
		SVPinStroke.Name = "Stroke"
		SVPinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		SVPinStroke.LineJoinMode = Enum.LineJoinMode.Miter
		SVPinStroke.Thickness = 1.5
		SVPinStroke.Parent = SVPin

		local Hue = Instance.new("TextButton")
		Hue.Name = "Hue"
		Hue.ZIndex = 3
		Hue.AnchorPoint = Vector2.new(0.5, 0)
		Hue.Size = UDim2.new(1, -10, 0, 10)
		Hue.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Hue.Position = UDim2.new(0.5, 0, 0, 191)
		Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Hue.AutoButtonColor = false
		Hue.TextStrokeTransparency = 0.75
		Hue.TextSize = 14
		Hue.RichText = true
		Hue.TextColor3 = Color3.fromRGB(255, 255, 255)
		Hue.Text = ""
		Hue.TextWrapped = true
		Hue.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Hue.Parent = Palette

		local HuePin = Instance.new("Frame")
		HuePin.Name = "Pin"
		HuePin.ZIndex = 3
		HuePin.AnchorPoint = Vector2.new(0.5, 0.5)
		HuePin.Size = UDim2.new(0, 1, 1, 0)
		HuePin.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HuePin.Position = UDim2.new(0, 0, 0.5, 0)
		HuePin.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		HuePin.Parent = Hue

		local HueGradient = Instance.new("UIGradient")
		HueGradient.Name = "Gradient"
		HueGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1 / 3, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(1 / 1.5, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(1 / 1.2, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
		})
		HueGradient.Parent = Hue

		local Alpha = Instance.new("TextButton")
		Alpha.Name = "Alpha"
		Alpha.ZIndex = 3
		Alpha.AnchorPoint = Vector2.new(0.5, 0)
		Alpha.Size = UDim2.new(1, -10, 0, 10)
		Alpha.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Alpha.Position = UDim2.new(0.5, 0, 0, 207)
		Alpha.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		Alpha.AutoButtonColor = false
		Alpha.TextStrokeTransparency = 0.75
		Alpha.TextSize = 14
		Alpha.RichText = true
		Alpha.TextColor3 = Color3.fromRGB(255, 255, 255)
		Alpha.Text = ""
		Alpha.TextWrapped = true
		Alpha.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Alpha.Parent = Palette

		local Stroke = Instance.new("UIStroke")
		Stroke.Name = "Stroke"
		Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Stroke.LineJoinMode = Enum.LineJoinMode.Miter
		Stroke.Parent = Alpha

		local AlphaGradient = Instance.new("UIGradient")
		AlphaGradient.Name = "Gradient"
		AlphaGradient.Transparency = NumberSequence.new(0, 1)
		AlphaGradient.Parent = Alpha

		local AlphaPin = Instance.new("Frame")
		AlphaPin.Name = "Pin"
		AlphaPin.ZIndex = 3
		AlphaPin.AnchorPoint = Vector2.new(0.5, 0.5)
		AlphaPin.Size = UDim2.new(0, 1, 1, 0)
		AlphaPin.BorderColor3 = Color3.fromRGB(0, 0, 0)
		AlphaPin.Position = UDim2.new(0, 0, 0.5, 0)
		AlphaPin.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		AlphaPin.Parent = Alpha

		local Value = Instance.new("TextLabel")
		Value.Name = "Value"
		Value.ZIndex = 3
		Value.AnchorPoint = Vector2.new(0.5, 0.5)
		Value.Size = UDim2.new(1, -8, 1, 0)
		Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Value.BackgroundTransparency = 1
		Value.Position = UDim2.new(0.5, 0, 0.5, 0)
		Value.BorderSizePixel = 0
		Value.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		Value.TextStrokeTransparency = 0.75
		Value.TextSize = 12
		Value.TextColor3 = Color3.fromRGB(255, 255, 255)
		Value.TextYAlignment = Enum.TextYAlignment.Bottom
		Value.Text = "1"
		Value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Value.TextXAlignment = Enum.TextXAlignment.Right
		Value.Parent = Alpha

		local RGB = Instance.new("Frame")
		RGB.Name = "RGB"
		RGB.ZIndex = 3
		RGB.AnchorPoint = Vector2.new(0.5, 0)
		RGB.Size = UDim2.new(1, -10, 0, 20)
		RGB.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RGB.Position = UDim2.new(0.5, 0, 0, 223)
		RGB.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		RGB.Parent = Palette

		local RGBBox = Instance.new("TextBox")
		RGBBox.Name = "RGBBox"
		RGBBox.ZIndex = 3
		RGBBox.AnchorPoint = Vector2.new(0, 0.5)
		RGBBox.Size = UDim2.new(1, -36, 1, 0)
		RGBBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RGBBox.BackgroundTransparency = 1
		RGBBox.Position = UDim2.new(0, 31, 0.5, 0)
		RGBBox.BorderSizePixel = 0
		RGBBox.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		RGBBox.TextStrokeTransparency = 0.75
		RGBBox.PlaceholderColor3 = Color3.fromRGB(189, 189, 189)
		RGBBox.TextSize = 14
		RGBBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		RGBBox.PlaceholderText = "255, 0, 0"
		RGBBox.Text = ""
		RGBBox.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		RGBBox.TextXAlignment = Enum.TextXAlignment.Left
		RGBBox.Parent = RGB

		local RGBText = Instance.new("TextLabel")
		RGBText.Name = "RGBText"
		RGBText.ZIndex = 3
		RGBText.Size = UDim2.new(0, 26, 0, 20)
		RGBText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RGBText.BackgroundTransparency = 1
		RGBText.Position = UDim2.new(0, 5, 0, 0)
		RGBText.BorderSizePixel = 0
		RGBText.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		RGBText.TextStrokeTransparency = 0.75
		RGBText.TextSize = 14
		RGBText.RichText = true
		RGBText.TextColor3 = Color3.fromRGB(255, 255, 255)
		RGBText.Text = "RGB: "
		RGBText.TextWrapped = true
		RGBText.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		RGBText.TextXAlignment = Enum.TextXAlignment.Left
		RGBText.Parent = RGB

		local RGBGradient = Instance.new("UIGradient")
		RGBGradient.Name = "Gradient"
		RGBGradient.Rotation = 90
		RGBGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		RGBGradient.Parent = RGB

		local HEX = Instance.new("Frame")
		HEX.Name = "HEX"
		HEX.ZIndex = 3
		HEX.AnchorPoint = Vector2.new(0.5, 0)
		HEX.Size = UDim2.new(1, -10, 0, 20)
		HEX.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HEX.Position = UDim2.new(0.5, 0, 0, 249)
		HEX.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		HEX.Parent = Palette

		local HEXBox = Instance.new("TextBox")
		HEXBox.Name = "HEXBox"
		HEXBox.ZIndex = 3
		HEXBox.AnchorPoint = Vector2.new(0, 0.5)
		HEXBox.Size = UDim2.new(1, -36, 1, 0)
		HEXBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HEXBox.BackgroundTransparency = 1
		HEXBox.Position = UDim2.new(0, 36, 0.5, 0)
		HEXBox.BorderSizePixel = 0
		HEXBox.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		HEXBox.TextStrokeTransparency = 0.75
		HEXBox.PlaceholderColor3 = Color3.fromRGB(189, 189, 189)
		HEXBox.TextSize = 14
		HEXBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		HEXBox.PlaceholderText = "ff0000"
		HEXBox.Text = ""
		HEXBox.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		HEXBox.TextXAlignment = Enum.TextXAlignment.Left
		HEXBox.Parent = HEX

		local HEXText = Instance.new("TextLabel")
		HEXText.Name = "HEXText"
		HEXText.ZIndex = 3
		HEXText.Size = UDim2.new(0, 31, 0, 20)
		HEXText.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HEXText.BackgroundTransparency = 1
		HEXText.Position = UDim2.new(0, 5, 0, 0)
		HEXText.BorderSizePixel = 0
		HEXText.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		HEXText.TextStrokeTransparency = 0.75
		HEXText.TextSize = 14
		HEXText.RichText = true
		HEXText.TextColor3 = Color3.fromRGB(255, 255, 255)
		HEXText.Text = "HEX: #"
		HEXText.TextWrapped = true
		HEXText.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		HEXText.TextXAlignment = Enum.TextXAlignment.Left
		HEXText.Parent = HEX

		local HEXGradient = Instance.new("UIGradient")
		HEXGradient.Name = "Gradient"
		HEXGradient.Rotation = 90
		HEXGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		HEXGradient.Parent = HEX

		local Rainbow = Instance.new("TextButton")
		Rainbow.Name = "Rainbow"
		Rainbow.ZIndex = 3
		Rainbow.AnchorPoint = Vector2.new(0.5, 0)
		Rainbow.Size = UDim2.new(1, -10, 0, 20)
		Rainbow.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Rainbow.BackgroundTransparency = 1
		Rainbow.Position = UDim2.new(0.5, 0, 0, 270)
		Rainbow.BorderSizePixel = 0
		Rainbow.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Rainbow.AutoButtonColor = false
		Rainbow.TextStrokeTransparency = 0.75
		Rainbow.TextSize = 14
		Rainbow.RichText = true
		Rainbow.TextColor3 = Color3.fromRGB(255, 255, 255)
		Rainbow.Text = ""
		Rainbow.TextWrapped = true
		Rainbow.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Rainbow.Parent = Palette

		local Title = Instance.new("TextLabel")
		Title.Name = "Title"
		Title.ZIndex = 3
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.Size = UDim2.new(1, -15, 1, 0)
		Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 15, 0.5, 0)
		Title.BorderSizePixel = 0
		Title.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
		Title.TextStrokeTransparency = 0.75
		Title.TextSize = 14
		Title.RichText = true
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.Text = "Rainbow"
		Title.TextWrapped = true
		Title.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		Title.TextXAlignment = Enum.TextXAlignment.Left
		Title.Parent = Rainbow

		local RainbowTick = Instance.new("Frame")
		RainbowTick.Name = "Tick"
		RainbowTick.ZIndex = 3
		RainbowTick.AnchorPoint = Vector2.new(0, 0.5)
		RainbowTick.Size = UDim2.new(0, 10, 0, 10)
		RainbowTick.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RainbowTick.Position = UDim2.new(0, 0, 0.5, 0)
		RainbowTick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
		RainbowTick.Parent = Rainbow

		local RainbowTickGradient = Instance.new("UIGradient")
		RainbowTickGradient.Name = "Gradient"
		RainbowTickGradient.Rotation = 90
		RainbowTickGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(191, 191, 191))
		RainbowTickGradient.Parent = RainbowTick

		return Palette
	end
}
Bracket.Elements = {
	Screen = function()
		local ScreenAsset = Bracket.Assets:Screen()
		if not Bracket.IsLocal then sethiddenproperty(ScreenAsset, "OnTopOfCoreBlur", true) end
		ScreenAsset.Name = "Bracket " .. game:GetService("HttpService"):GenerateGUID(false)
		ScreenAsset.Parent = Bracket.IsLocal and LocalPlayer:FindFirstChildOfClass("PlayerGui") or CoreGui
		Bracket.Screen = ScreenAsset
	end,
	Window = function(Window)
		local WindowAsset = Bracket.Assets.Window()

		Window.Elements, Window.Flags, Window.Colorable = {}, {}, {}
		Window.RainbowHue, Window.RainbowSpeed = 0, 10

		Window.Asset = WindowAsset
		Window.Background = Window.Asset.Background

		WindowAsset.Parent = Bracket.Screen
		WindowAsset.Visible = Window.Enabled
		WindowAsset.Title.Text = Window.Name
		WindowAsset.Position = Window.Position
		WindowAsset.Size = Window.Size

		Bracket.Utilities.MakeDraggable(WindowAsset.Drag, WindowAsset, function(Position)
			Window.Position = Position
		end)
		Bracket.Utilities.MakeResizeable(WindowAsset.Resize, WindowAsset, Vector2.new(296, 296), Vector2.new(896, 896), function(Size)
			Window.Size = Size
		end)

		-- Minimize/Maximize functionality
		local IsMinimized = false
		local SavedSize = Window.Size
		WindowAsset.MinimizeButton.MouseButton1Click:Connect(function()
			IsMinimized = not IsMinimized
			if IsMinimized then
				SavedSize = WindowAsset.Size
				WindowAsset.MinimizeButton.Text = "□"
				WindowAsset.Size = UDim2.new(0, WindowAsset.AbsoluteSize.X, 0, 34)
				WindowAsset.TabButtonContainer.Visible = false
				WindowAsset.Background.Visible = false
				WindowAsset.TabContainer.Visible = false
			else
				WindowAsset.MinimizeButton.Text = "−"
				WindowAsset.Size = SavedSize
				WindowAsset.TabButtonContainer.Visible = true
				WindowAsset.Background.Visible = true
				WindowAsset.TabContainer.Visible = true
			end
		end)

		--local Month = tonumber(os.date("%m"))
		--if Month == 12 or Month == 1 then task.spawn(Bracket.Elements.Snowflakes, WindowAsset) end
		WindowAsset.TabButtonContainer.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			WindowAsset.TabButtonContainer.CanvasSize = UDim2.fromOffset(WindowAsset.TabButtonContainer.ListLayout.AbsoluteContentSize.X, 0)
		end)

		UserInputService.InputChanged:Connect(function(Input)
			if WindowAsset.Visible and Input.UserInputType == Enum.UserInputType.MouseMovement then
				local Mouse = UserInputService:GetMouseLocation()
				Bracket.Screen.ToolTip.Position = UDim2.fromOffset(Mouse.X + 5, Mouse.Y - 5)
			end
		end)
		RunService.RenderStepped:Connect(function()
			Window.RainbowHue = os.clock() % Window.RainbowSpeed / Window.RainbowSpeed
		end)

		Window:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
			WindowAsset.Visible = Enabled

			if not Bracket.IsLocal then
				RunService:SetRobloxGuiFocused(Enabled and Window.Blur)
			end
			if not Enabled then
				for Index, Object in pairs(Bracket.Screen:GetChildren()) do
					if Object.Name == "Palette" or Object.Name == "OptionContainer" then
						Object.Visible = false
					end
				end
			end
		end)
		Window:GetPropertyChangedSignal("Blur"):Connect(function(Blur)
			if not Bracket.IsLocal then
				RunService:SetRobloxGuiFocused(Window.Enabled and Blur)
			end
		end)
		Window:GetPropertyChangedSignal("Name"):Connect(function(Name)
			WindowAsset.Title.Text = Name
		end)
		Window:GetPropertyChangedSignal("Position"):Connect(function(Position)
			WindowAsset.Position = Position
		end)
		Window:GetPropertyChangedSignal("Size"):Connect(function(Size)
			WindowAsset.Size = Size
		end)
		Window:GetPropertyChangedSignal("Color"):Connect(function(Color)
			for Object, ColorConfig in pairs(Window.Colorable) do
				if ColorConfig[1] then
					Object[ColorConfig[2]] = Color
				end
			end
		end)

		function Window.SetValue(Self, Flag, Value)
			for Index, Element in pairs(Self.Elements) do
				if Element.Flag == Flag then
					Element.Value = Value
				end
			end
		end
		function Window.GetValue(Self, Flag)
			for Index, Element in pairs(Self.Elements) do
				if Element.Flag == Flag then
					return Element.Value
				end
			end
		end

		function Window.Watermark(Self, Watermark)
			Watermark = Bracket.Utilities:GetType(Watermark, {}, "table", true)
			Watermark.Enabled = Bracket.Utilities:GetType(Watermark.Enabled, false, "boolean")
			Watermark.Title = Bracket.Utilities:GetType(Watermark.Title, "Hello World!", "string")
			Watermark.Flag = Bracket.Utilities:GetType(Watermark.Flag, "UI/Watermark/Position", "string")

			Bracket.Screen.Watermark.Visible = Watermark.Enabled
			Bracket.Screen.Watermark.Text = Watermark.Title

			Bracket.Screen.Watermark.Size = UDim2.fromOffset(
				Bracket.Screen.Watermark.TextBounds.X + 6,
                Bracket.Utilities.GetTextBounds(
                    Bracket.Screen.Watermark.Text,
                    Bracket.Screen.Watermark.Font.Name,
                    Vector2.new(Bracket.Screen.Watermark.AbsoluteSize.X, Bracket.Screen.Watermark.TextSize)
                ).Y + 6
			)

			Bracket.Utilities.MakeDraggable(Bracket.Screen.Watermark, Bracket.Screen.Watermark, function(Position)
				if not Window.Enabled then return end
				Bracket.Screen.Watermark.Position = Position
			end, function(Position)
				if not Window.Enabled then return end
				Watermark.Value = {
					Position.X.Scale, Position.X.Offset,
					Position.Y.Scale, Position.Y.Offset
				}
			end)

			Watermark:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
				Bracket.Screen.Watermark.Visible = Enabled
			end)
			Watermark:GetPropertyChangedSignal("Title"):Connect(function(Title)
				Bracket.Screen.Watermark.Text = Title
				Bracket.Screen.Watermark.Size = UDim2.fromOffset(
					Bracket.Screen.Watermark.TextBounds.X + 6,
                    Bracket.Utilities.GetTextBounds(
                        Bracket.Screen.Watermark.Text,
                        Bracket.Screen.Watermark.Font.Name,
                        Vector2.new(Bracket.Screen.Watermark.AbsoluteSize.X, Bracket.Screen.Watermark.TextSize)
                    ).Y + 6
				)
			end)
			Watermark:GetPropertyChangedSignal("Value"):Connect(function(Value)
				if type(Value) ~= "table" then return end
				Bracket.Screen.Watermark.Position = UDim2.new(
					Value[1], Value[2],
					Value[3], Value[4]
				)
				Self.Flags[Watermark.Flag] = {
					Value[1], Value[2],
					Value[3], Value[4]
				}
			end)

			Self.Elements[#Self.Elements + 1] = Watermark
			Self.Watermark = Watermark
			return Watermark
		end
		function Window.KeybindList(Self, KeybindList)
			KeybindList = Bracket.Utilities:GetType(KeybindList, {}, "table", true)
			KeybindList.Enabled = Bracket.Utilities:GetType(KeybindList.Enabled, false, "boolean")
			KeybindList.Title = Bracket.Utilities:GetType(KeybindList.Title, "Keybinds", "string")

			KeybindList.Position = Bracket.Utilities:GetType(KeybindList.Position, UDim2.new(0, 10, 0.5, -123), "UDim2")
			KeybindList.Size = Bracket.Utilities:GetType(KeybindList.Size, UDim2.new(0, 121, 0, 246), "UDim2")
			KeybindList.List = Bracket.Screen.KeybindList.List

			Bracket.Screen.KeybindList.Visible = KeybindList.Enabled
			Bracket.Screen.KeybindList.Title.Text = KeybindList.Title

			Bracket.Utilities.MakeDraggable(Bracket.Screen.KeybindList.Drag, Bracket.Screen.KeybindList, function(Position)
				KeybindList.Position = Position
			end)
			Bracket.Utilities.MakeResizeable(Bracket.Screen.KeybindList.Resize, Bracket.Screen.KeybindList, Vector2.new(121, 246), Vector2.new(896, 896), function(Size)
				KeybindList.Size = Size
			end)

			KeybindList:GetPropertyChangedSignal("Title"):Connect(function(Title)
				Bracket.Screen.KeybindList.Title.Text = Title
			end)
			KeybindList:GetPropertyChangedSignal("Enabled"):Connect(function(Enabled)
				Bracket.Screen.KeybindList.Visible = Enabled
			end)
			KeybindList:GetPropertyChangedSignal("Position"):Connect(function(Position)
				Bracket.Screen.KeybindList.Position = Position
			end)
			KeybindList:GetPropertyChangedSignal("Size"):Connect(function(Size)
				Bracket.Screen.KeybindList.Size = Size
			end)

			WindowAsset.Background.Changed:Connect(function(Property)
				if Property == "Image" then
					Bracket.Screen.KeybindList.Background.Image = WindowAsset.Background.Image
				elseif Property == "ImageColor3" then
					Bracket.Screen.KeybindList.Background.ImageColor3 = WindowAsset.Background.ImageColor3
				elseif Property == "ImageTransparency" then
					Bracket.Screen.KeybindList.Background.ImageTransparency = WindowAsset.Background.ImageTransparency
				elseif Property == "TileSize" then
					Bracket.Screen.KeybindList.Background.TileSize = WindowAsset.Background.TileSize
				end
			end)

			for Index, Element in pairs(Self.Elements) do
				if type(Element.WaitingForBind) == "boolean" and not Element.IgnoreList then
					Element.ListMimic = {}
					Element.ListMimic.Asset = Bracket.Assets.KeybindMimic()
					Element.ListMimic.Asset.Title.Text = Element.Name or Element.Toggle.Name
					Element.ListMimic.Asset.Visible = Element.Value ~= "NONE"
					Element.ListMimic.Asset.Parent = KeybindList.List

					Element.ListMimic.ColorConfig = {false, "BackgroundColor3"}
					Self.Colorable[Element.ListMimic.Asset.Tick] = Element.ListMimic.ColorConfig
				end
			end

			--Self.Elements[#Self.Elements + 1] = KeybindList
			Self.KeybindList = KeybindList
			return KeybindList
		end

		function Window.SaveConfig(Self, FolderName, Name)
			local Config = {}
			for Index, Element in pairs(Self.Elements) do
				if Element.Flag and not Element.IgnoreFlag then
					Config[Element.Flag] = Self.Flags[Element.Flag]
				end
			end
			writefile(
				FolderName .. "\\Configs\\" .. Name .. ".json",
				HttpService:JSONEncode(Config)
			)
		end
		function Window.LoadConfig(Self, FolderName, Name)
			if table.find(Bracket.Utilities.GetConfigs(FolderName), Name) then
				local DecodedJSON = HttpService:JSONDecode(
					readfile(FolderName .. "\\Configs\\" .. Name .. ".json")
				)
				for Flag, Value in pairs(DecodedJSON) do
					local Element = Bracket.Utilities.FindElementByFlag(Self.Elements, Flag)
					if Element ~= nil then Element.Value = Value end
				end
			end
		end
		function Window:DeleteConfig(FolderName, Name)
			if table.find(Bracket.Utilities.GetConfigs(FolderName), Name) then
				delfile(FolderName .. "\\Configs\\" .. Name .. ".json")
			end
		end
		function Window:GetAutoLoadConfig(FolderName)
			if not isfolder(FolderName) then makefolder(FolderName) end
			if not isfile(FolderName .. "\\AutoLoads.json") then
				writefile(FolderName .. "\\AutoLoads.json", "[]")
			end

			local AutoLoads = HttpService:JSONDecode(
				readfile(FolderName .. "\\AutoLoads.json")
			) local AutoLoad = AutoLoads[tostring(game.GameId)]

			if table.find(Bracket.Utilities.GetConfigs(FolderName), AutoLoad) then
				return AutoLoad
			end
		end
		function Window:AddToAutoLoad(FolderName, Name)
			if not isfolder(FolderName) then makefolder(FolderName) end
			if not isfile(FolderName .. "\\AutoLoads.json") then
				writefile(FolderName .. "\\AutoLoads.json", "[]")
			end

			local AutoLoads = HttpService:JSONDecode(
				readfile(FolderName .. "\\AutoLoads.json")
			) AutoLoads[tostring(game.GameId)] = Name

			writefile(FolderName .. "\\AutoLoads.json",
				HttpService:JSONEncode(AutoLoads)
			)
		end
		function Window:RemoveFromAutoLoad(FolderName)
			if not isfolder(FolderName) then makefolder(FolderName) end
			if not isfile(FolderName .. "\\AutoLoads.json") then
				writefile(FolderName .. "\\AutoLoads.json", "[]")
				return
			end

			local AutoLoads = HttpService:JSONDecode(
				readfile(FolderName .. "\\AutoLoads.json")
			) AutoLoads[tostring(game.GameId)] = nil

			writefile(FolderName .. "\\AutoLoads.json",
				HttpService:JSONEncode(AutoLoads)
			)
		end
		function Window.AutoLoadConfig(Self, FolderName)
			if not isfolder(FolderName) then makefolder(FolderName) end
			if not isfile(FolderName .. "\\AutoLoads.json") then
				writefile(FolderName .. "\\AutoLoads.json", "[]")
			end

			local AutoLoads = HttpService:JSONDecode(
				readfile(FolderName .. "\\AutoLoads.json")
			) local AutoLoad = AutoLoads[tostring(game.GameId)]

			if table.find(Bracket.Utilities.GetConfigs(FolderName), AutoLoad) then
				Self:LoadConfig(FolderName, AutoLoad)
			end
		end

		return WindowAsset
	end,
	Tab = function(WindowAsset, Window, Tab)
		local TabAsset = Bracket.Assets.Tab()
		local TabButtonAsset = Bracket.Assets.TabButton()

		Tab.ColorConfig = {true, "BackgroundColor3"}
		Window.Colorable[TabButtonAsset.Highlight] = Tab.ColorConfig

		TabAsset.Parent = WindowAsset.TabContainer
		TabButtonAsset.Parent = WindowAsset.TabButtonContainer

		TabAsset.Visible = false
		TabButtonAsset.Text = Tab.Name
		TabButtonAsset.Highlight.BackgroundColor3 = Window.Color
		TabButtonAsset.Size = UDim2.new(0, TabButtonAsset.TextBounds.X + 12, 1, -1)
		TabButtonAsset.Parent = WindowAsset.TabButtonContainer

		TabAsset.LeftSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local Side = Bracket.Utilities.GetLongestSide(TabAsset)
			TabAsset.CanvasSize = UDim2.fromOffset(0, Side.ListLayout.AbsoluteContentSize.Y + 21)
		end)
		TabAsset.RightSide.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local Side = Bracket.Utilities.GetLongestSide(TabAsset)
			TabAsset.CanvasSize = UDim2.fromOffset(0, Side.ListLayout.AbsoluteContentSize.Y + 21)
		end)
		TabButtonAsset.MouseButton1Click:Connect(function()
			Bracket.Utilities.ChooseTab(TabButtonAsset, TabAsset)
		end)

		if #WindowAsset.TabContainer:GetChildren() == 1 then
			Bracket.Utilities.ChooseTab(TabButtonAsset, TabAsset)
		end

		Tab:GetPropertyChangedSignal("Name"):Connect(function(Name)
			TabButtonAsset.Text = Name
			TabButtonAsset.Size = UDim2.new(
				0, TabButtonAsset.TextBounds.X + 12,
				1, -1
			)
		end)

		return TabAsset
	end,
	Section = function(Parent, Section)
		local SectionAsset = Bracket.Assets.Section()

		SectionAsset.Parent = Parent
		SectionAsset.Title.Text = Section.Name
		SectionAsset.Title.Size = UDim2.fromOffset(
			SectionAsset.Title.TextBounds.X + 6, 2
		)

		SectionAsset.Container.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			SectionAsset.Size = UDim2.new(1, 0, 0, SectionAsset.Container.ListLayout.AbsoluteContentSize.Y + 15)
		end)

		Section:GetPropertyChangedSignal("Name"):Connect(function(Name)
			SectionAsset.Title.Text = Name
			SectionAsset.Title.Size = UDim2.fromOffset(
				Section.Title.TextBounds.X + 6, 2
			)
		end)

		return SectionAsset.Container
	end,
	Tooltip = function(Parent, Text)
		Parent.MouseEnter:Connect(function()
			Bracket.Screen.ToolTip.Text = Text
			Bracket.Screen.ToolTip.Size = UDim2.fromOffset(
				Bracket.Screen.ToolTip.TextBounds.X + 6,
                Bracket.Utilities.GetTextBounds(
                    Bracket.Screen.ToolTip.Text,
                    Bracket.Screen.ToolTip.Font.Name,
                    Vector2.new(Bracket.Screen.ToolTip.AbsoluteSize.X, Bracket.Screen.ToolTip.TextSize)
                ).Y + 6
			)

			Bracket.Screen.ToolTip.Visible = true
		end)
		Parent.MouseLeave:Connect(function()
			Bracket.Screen.ToolTip.Visible = false
		end)
	end,
	Snowflakes = function(WindowAsset)
		local ParticleEmitter = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/rParticle/master/Main.lua"))()
		local Emitter = ParticleEmitter.new(WindowAsset.Background, WindowAsset.Snowflake)
		local NewRandom = Random.new() Emitter.SpawnRate = 20

		Emitter.OnSpawn = function(Particle)
			local RandomPosition = NewRandom:NextNumber()
			local RandomSize = NewRandom:NextInteger(10, 50)
			local RandomYVelocity = NewRandom:NextInteger(10, 50)
			local RandomXVelocity = NewRandom:NextInteger(-50, 50)

			Particle.Object.ImageTransparency = RandomSize / 50
			Particle.Object.Size = UDim2.fromOffset(RandomSize, RandomSize)
			Particle.Velocity = Vector2.new(RandomXVelocity, RandomYVelocity)
			Particle.Position = Vector2.new(RandomPosition * WindowAsset.Background.AbsoluteSize.X, 0)
			Particle.MaxAge = 20 task.wait(0.5) Particle.Object.Visible = true
		end

		Emitter.OnUpdate = function(Particle, Delta)
			Particle.Position += Particle.Velocity * Delta
		end
	end,
	Divider = function(Parent, Divider)
		local DividerAsset = Bracket.Assets.Divider()

		DividerAsset.Parent = Parent
		DividerAsset.Title.Text = Divider.Text

		DividerAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			if DividerAsset.Title.TextBounds.X > 0 then
				DividerAsset.Size = UDim2.new(1, 0, 0, 
                    Bracket.Utilities.GetTextBounds(
                        DividerAsset.Title.Text,
                        DividerAsset.Title.Font.Name,
                        Vector2.new(DividerAsset.Title.AbsoluteSize.X, DividerAsset.Title.TextSize)
                    ).Y
                )
				DividerAsset.Left.Size = UDim2.new(0.5, -(DividerAsset.Title.TextBounds.X / 2) - 6, 0 , 2)
				DividerAsset.Right.Size = UDim2.new(0.5, -(DividerAsset.Title.TextBounds.X / 2) - 6, 0, 2)
			else
				DividerAsset.Size = UDim2.new(1, 0, 0, 14)
				DividerAsset.Left.Size = UDim2.new(1, 0, 0, 2)
				DividerAsset.Right.Size = UDim2.new(1, 0, 0, 2)
			end
		end)

		Divider:GetPropertyChangedSignal("Text"):Connect(function(Text)
			DividerAsset.Title.Text = Text
		end)
	end,
	Label = function(Parent, Label)
		local LabelAsset = Bracket.Assets.Label()

		LabelAsset.Parent = Parent
		LabelAsset.Text = Label.Text

		LabelAsset:GetPropertyChangedSignal("TextBounds"):Connect(function()
			LabelAsset.Size = UDim2.new(1, 0, 0, 
                Bracket.Utilities.GetTextBounds(
                    LabelAsset.Text,
                    LabelAsset.Font.Name,
                    Vector2.new(LabelAsset.AbsoluteSize.X, LabelAsset.TextSize)
                ).Y
            )
		end)

		Label:GetPropertyChangedSignal("Text"):Connect(function(Text)
			LabelAsset.Text = Text
		end)
	end,
	Button = function(Parent, Window, Button)
		local ButtonAsset = Bracket.Assets.Button()

		Button.ColorConfig = {false, "BorderColor3"}
		Window.Colorable[ButtonAsset] = Button.ColorConfig

		Button.Connection = ButtonAsset.MouseButton1Click:Connect(Button.Callback)

		ButtonAsset.Parent = Parent
		ButtonAsset.Title.Text = Button.Name

		ButtonAsset.MouseButton1Down:Connect(function()
			Button.ColorConfig[1] = true
			ButtonAsset.BorderColor3 = Window.Color
		end)
		ButtonAsset.MouseButton1Up:Connect(function()
			Button.ColorConfig[1] = false
			ButtonAsset.BorderColor3 = Color3.new(0, 0, 0)
		end)
		ButtonAsset.MouseLeave:Connect(function()
			Button.ColorConfig[1] = false
			ButtonAsset.BorderColor3 = Color3.new(0, 0, 0)
		end)
		ButtonAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			ButtonAsset.Size = UDim2.new(1, 0, 0, 
                Bracket.Utilities.GetTextBounds(
                    ButtonAsset.Title.Text,
                    ButtonAsset.Title.Font.Name,
                    Vector2.new(ButtonAsset.Title.AbsoluteSize.X, ButtonAsset.Title.TextSize)
                ).Y + 2
            )
		end)

		Button:GetPropertyChangedSignal("Name"):Connect(function(Name)
			ButtonAsset.Title.Text = Name
		end)
		Button:GetPropertyChangedSignal("Callback"):Connect(function(Callback)
			Button.Connection:Disconnect()
			Button.Connection = ButtonAsset.MouseButton1Click:Connect(Callback)
		end)

		function Button:Tooltip(Text)
			Bracket.Elements.Tooltip(ButtonAsset, Text)
		end
	end,
	Toggle = function(Parent, Window, Toggle)
		local ToggleAsset = Bracket.Assets.Toggle()

		Toggle.ColorConfig = {Toggle.Value, "BackgroundColor3"}
		Window.Colorable[ToggleAsset.Tick] = Toggle.ColorConfig

		ToggleAsset.Parent = Parent
		ToggleAsset.Title.Text = Toggle.Name
		ToggleAsset.Tick.BackgroundColor3 = Toggle.Value
			and Window.Color or Color3.fromRGB(63, 63, 63)

		ToggleAsset.MouseButton1Click:Connect(function()
			Toggle.Value = not Toggle.Value
		end)
		ToggleAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			ToggleAsset.Size = UDim2.new(1, 0, 0, 
                Bracket.Utilities.GetTextBounds(
                    ToggleAsset.Title.Text,
                    ToggleAsset.Title.Font.Name,
                    Vector2.new(ToggleAsset.Title.AbsoluteSize.X, ToggleAsset.Title.TextSize)
                ).Y
            )
			ToggleAsset.Layout.Size = UDim2.new(1, -ToggleAsset.Title.TextBounds.X - 18, 1, 0)
		end)

		Toggle:GetPropertyChangedSignal("Name"):Connect(function(Name)
			ToggleAsset.Title.Text = Name
		end)
		Toggle:GetPropertyChangedSignal("Value"):Connect(function(Value)
			Toggle.ColorConfig[1] = Value
			ToggleAsset.Tick.BackgroundColor3 = Value
				and Window.Color or Color3.fromRGB(63, 63, 63)
			Window.Flags[Toggle.Flag] = Value
			Toggle.Callback(Value)
		end)

		function Toggle:Tooltip(Text)
			Bracket.Elements.Tooltip(ToggleAsset, Text)
		end

		return ToggleAsset
	end,
	Slider = function(Parent, Window, Slider)
		local SliderAsset = Slider.Slim and Bracket.Assets.SlimSlider() or Bracket.Assets.Slider()

		Slider.ColorConfig = {true, "BackgroundColor3"}
		Window.Colorable[SliderAsset.Background.Bar] = Slider.ColorConfig

		Slider.Active = false
		Slider.Value = tonumber(string.format("%." .. Slider.Precise .. "f", Slider.Value))

		SliderAsset.Parent = Parent
		SliderAsset.Title.Text = Slider.Name
		SliderAsset.Background.Bar.BackgroundColor3 = Window.Color
		SliderAsset.Background.Bar.Size = UDim2.fromScale(Bracket.Utilities.Scale(Slider.Value, Slider.Min, Slider.Max, 0, 1), 1)
		SliderAsset.Value.PlaceholderText = #Slider.Unit == 0 and Slider.Value or Slider.Value .. " " .. Slider.Unit

		local function AttachToMouse(Input)
			local ScaleX = math.clamp((Input.Position.X - SliderAsset.Background.AbsolutePosition.X) / SliderAsset.Background.AbsoluteSize.X, 0, 1)
			Slider.Value = Bracket.Utilities.Scale(ScaleX, 0, 1, Slider.Min, Slider.Max)
		end

		if Slider.Slim then
			SliderAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				SliderAsset.Value.Size = UDim2.fromOffset(SliderAsset.Value.TextBounds.X, 16)
				SliderAsset.Title.Size = UDim2.new(1, -SliderAsset.Value.Size.X.Offset, 0, 16)
				SliderAsset.Size = UDim2.new(1, 0, 0,
                    Bracket.Utilities.GetTextBounds(
                        SliderAsset.Title.Title.Text,
                        SliderAsset.Title.Title.Font.Name,
                        Vector2.new(SliderAsset.Title.Title.AbsoluteSize.X, SliderAsset.Title.Title.TextSize)
                    ).Y + 8
                )
			end)
			SliderAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
				SliderAsset.Value.Size = UDim2.fromOffset(SliderAsset.Value.TextBounds.X, 16)
				SliderAsset.Title.Size = UDim2.new(1, -SliderAsset.Value.Size.X.Offset, 0, 16)
			end)
		else
			SliderAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				SliderAsset.Value.Size = UDim2.new(0, SliderAsset.Value.TextBounds.X, 1, 0)
				SliderAsset.Title.Size = UDim2.new(1, -SliderAsset.Value.Size.X.Offset - 12, 1, 0)
				SliderAsset.Size = UDim2.new(1, 0, 0,
                    Bracket.Utilities.GetTextBounds(
                        SliderAsset.Title.Text,
                        SliderAsset.Title.Font.Name,
                        Vector2.new(SliderAsset.Title.AbsoluteSize.X, SliderAsset.Title.TextSize)
                    ).Y + 2
                )
			end)
			SliderAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
				SliderAsset.Value.Size = UDim2.new(0, SliderAsset.Value.TextBounds.X, 1, 0)
				SliderAsset.Title.Size = UDim2.new(1, -SliderAsset.Value.Size.X.Offset - 12, 1, 0)
			end)
		end

		SliderAsset.Value.FocusLost:Connect(function()
			if not tonumber(SliderAsset.Value.Text) then
				SliderAsset.Value.Text = ""
				return
			end

			Slider.Value = SliderAsset.Value.Text
			SliderAsset.Value.Text = ""
		end)
		SliderAsset.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				AttachToMouse(Input)
				Slider.Active = true
			end
		end)
		SliderAsset.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Slider.Active = false
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Slider.Active and Input.UserInputType == Enum.UserInputType.MouseMovement then
				AttachToMouse(Input)
			end
		end)

		Slider:GetPropertyChangedSignal("Name"):Connect(function(Name)
			SliderAsset.Title.Text = Name
		end)
		Slider:GetPropertyChangedSignal("Value"):Connect(function(Value)
			Value = tonumber(string.format("%." .. Slider.Precise .. "f", Value))

			if Value < Slider.Min then
				Value = Slider.Min
			elseif Value > Slider.Max then
				Value = Slider.Max
			end

			if Slider.OnlyOdd and Slider.Precise == 0 then
				if Value % 2 == 0 then return end
			elseif Slider.OnlyEven and Slider.Precise == 0 then
				if Value % 2 == 1 then return end
			end

			SliderAsset.Background.Bar.Size = UDim2.fromScale(Bracket.Utilities.Scale(Value, Slider.Min, Slider.Max, 0, 1), 1)
			SliderAsset.Value.PlaceholderText = #Slider.Unit == 0
				and Value or Value .. " " .. Slider.Unit

			Slider.Internal.Value = Value
			Window.Flags[Slider.Flag] = Value
			Slider.Callback(Value)
		end)

		function Slider:Tooltip(Text)
			Bracket.Elements.Tooltip(SliderAsset, Text)
		end
	end,
	Textbox = function(Parent, Window, Textbox)
		local TextboxAsset = Bracket.Assets.Textbox()
		Textbox.EnterPressed = false

		TextboxAsset.Parent = Parent
		TextboxAsset.Title.Text = Textbox.Name
		TextboxAsset.Background.Input.Text = Textbox.Value
		TextboxAsset.Background.Input.PlaceholderText = Textbox.Placeholder
		TextboxAsset.Title.Visible = not Textbox.HideName

		TextboxAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			TextboxAsset.Title.Size = Textbox.HideName and UDim2.fromScale(1, 0) or UDim2.new(1, 0, 0,
                Bracket.Utilities.GetTextBounds(
                    TextboxAsset.Title.Title.Text,
                    TextboxAsset.Title.Title.Font.Name,
                    Vector2.new(TextboxAsset.Title.Title.AbsoluteSize.X, TextboxAsset.Title.Title.TextSize)
                ).Y + 2
            )
			TextboxAsset.Background.Position = UDim2.new(0.5, 0, 0, TextboxAsset.Title.Size.Y.Offset)
			TextboxAsset.Size = UDim2.new(1, 0, 0, TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)
		end)
		TextboxAsset.Background.Input:GetPropertyChangedSignal("Text"):Connect(function()
			local TextBounds = Bracket.Utilities.GetTextBounds(
				TextboxAsset.Background.Input.Text,
				TextboxAsset.Background.Input.Font.Name,
				Vector2.new(TextboxAsset.Background.Input.AbsoluteSize.X, TextboxAsset.Background.Input.TextSize)
			)

			TextboxAsset.Background.Size = UDim2.new(1, 0, 0, TextBounds.Y + 2)
			TextboxAsset.Size = UDim2.new(1, 0, 0, TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)
		end)

		TextboxAsset.Background.Input.Focused:Connect(function()
			local TextBounds = Bracket.Utilities.GetTextBounds(
				TextboxAsset.Background.Input.Text,
				TextboxAsset.Background.Input.Font.Name,
				Vector2.new(TextboxAsset.Background.Input.AbsoluteSize.X, TextboxAsset.Background.Input.TextSize)
			)

			TextboxAsset.Background.Size = UDim2.new(1, 0, 0, TextBounds.Y + 2)
			TextboxAsset.Size = UDim2.new(1, 0, 0, TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)

			TextboxAsset.Background.Input.Text = Textbox.Value
		end)
		TextboxAsset.Background.Input.FocusLost:Connect(function(EnterPressed)
			local Input = TextboxAsset.Background.Input

			Textbox.EnterPressed = EnterPressed
			Textbox.Value = Input.Text Textbox.EnterPressed = false
		end)

		Textbox:GetPropertyChangedSignal("Name"):Connect(function(Name)
			TextboxAsset.Title.Text = Name
		end)
		Textbox:GetPropertyChangedSignal("Placeholder"):Connect(function(PlaceHolder)
			TextboxAsset.Background.Input.PlaceholderText = PlaceHolder
		end)
		Textbox:GetPropertyChangedSignal("Value"):Connect(function(Value)
			local Input = TextboxAsset.Background.Input
			Input.Text = Textbox.AutoClear and "" or Value
			if Textbox.PasswordMode then Input.Text = string.rep(utf8.char(8226), #Input.Text) end

			TextboxAsset.Background.Size = UDim2.new(1, 0, 0, Input.TextSize + 2)
			TextboxAsset.Size = UDim2.new(1, 0, 0, TextboxAsset.Title.Size.Y.Offset + TextboxAsset.Background.Size.Y.Offset)

			Window.Flags[Textbox.Flag] = Value
			Textbox.Callback(Value, Textbox.EnterPressed)
		end)

		function Textbox:Tooltip(Text)
			Bracket.Elements.Tooltip(TextboxAsset, Text)
		end
	end,
	Keybind = function(Parent, Window, Keybind)
		local KeybindAsset = Bracket.Assets.Keybind()
		Keybind.WaitingForBind = false

		KeybindAsset.Parent = Parent
		KeybindAsset.Title.Text = Keybind.Name
		KeybindAsset.Value.Text = "[ " .. Keybind.Value .. " ]"

		KeybindAsset.MouseButton1Click:Connect(function()
			KeybindAsset.Value.Text = "[ ... ]"
			Keybind.WaitingForBind = true
		end)
		KeybindAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			KeybindAsset.Size = UDim2.new(1, 0, 0,
                Bracket.Utilities.GetTextBounds(
                    KeybindAsset.Title.Text,
                    KeybindAsset.Title.Font.Name,
                    Vector2.new(KeybindAsset.Title.AbsoluteSize.X, KeybindAsset.Title.TextSize)
                ).Y
            )
		end)
		KeybindAsset.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
			KeybindAsset.Value.Size = UDim2.new(0, KeybindAsset.Value.TextBounds.X, 1, 0)
			KeybindAsset.Title.Size = UDim2.new(1, -KeybindAsset.Value.Size.X.Offset, 1, 0)
		end)

		if type(Window.KeybindList) == "table" and not Keybind.IgnoreList then
			Keybind.ListMimic = {}
			Keybind.ListMimic.Asset = Bracket.Assets.KeybindMimic()
			Keybind.ListMimic.Asset.Title.Text = Keybind.Name
			Keybind.ListMimic.Asset.Visible = Keybind.Value ~= "NONE"
			Keybind.ListMimic.Asset.Parent = Window.KeybindList.List


			Keybind.ListMimic.ColorConfig = {false, "BackgroundColor3"}
			Window.Colorable[Keybind.ListMimic.Asset.Tick] = Keybind.ListMimic.ColorConfig
		end

		UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
			if GameProcessedEvent then return end
			local Key = Input.KeyCode.Name
			if Keybind.WaitingForBind and Input.UserInputType.Name == "Keyboard" then
				Keybind.Value = Key
			elseif Input.UserInputType.Name == "Keyboard" then
				if Key == Keybind.Value then
					Keybind.Toggle = not Keybind.Toggle
					if Keybind.ListMimic then
						Keybind.ListMimic.ColorConfig[1] = true
						Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Window.Color
					end
					Keybind.Callback(Keybind.Value, true, Keybind.Toggle)
				end
			end
			if Keybind.Mouse then Key = Input.UserInputType.Name
				if Keybind.WaitingForBind and (Key == "MouseButton1"
					or Key == "MouseButton2" or Key == "MouseButton3") then
					Keybind.Value = Key
				elseif Key == "MouseButton1"
					or Key == "MouseButton2"
					or Key == "MouseButton3" then
					if Key == Keybind.Value then
						Keybind.Toggle = not Keybind.Toggle
						if Keybind.ListMimic then
							Keybind.ListMimic.ColorConfig[1] = true
							Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Window.Color
						end
						Keybind.Callback(Keybind.Value, true, Keybind.Toggle)
					end
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
			if GameProcessedEvent then return end
			local Key = Input.KeyCode.Name
			if Input.UserInputType.Name == "Keyboard" then
				if Key == Keybind.Value then
					if Keybind.ListMimic then
						Keybind.ListMimic.ColorConfig[1] = false
						Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
					end
					Keybind.Callback(Keybind.Value, false, Keybind.Toggle)
				end
			end
			if Keybind.Mouse then Key = Input.UserInputType.Name
				if Key == "MouseButton1"
					or Key == "MouseButton2"
					or Key == "MouseButton3" then
					if Key == Keybind.Value then
						if Keybind.ListMimic then
							Keybind.ListMimic.ColorConfig[1] = false
							Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Color3.fromRGB(63, 63, 63)
						end
						Keybind.Callback(Keybind.Value, false, Keybind.Toggle)
					end
				end
			end
		end)

		Keybind:GetPropertyChangedSignal("Name"):Connect(function(Name)
			KeybindAsset.Title.Text = Name
		end)
		Keybind:GetPropertyChangedSignal("Value"):Connect(function(Value, OldValue)
			if table.find(Keybind.Blacklist, Value) then
				Value = Keybind.DoNotClear and OldValue or "NONE"
			end

			KeybindAsset.Value.Text = "[ " .. tostring(Value) .. " ]"
			if Keybind.ListMimic then
				Keybind.ListMimic.Asset.Visible = Value ~= "NONE"
				Keybind.ListMimic.Asset.Layout.Keybind.Text = "[ " .. tostring(Value) .. " ]"
			end

			Keybind.WaitingForBind = false
			Keybind.Internal.Value = Value
			Window.Flags[Keybind.Flag] = Value
			Keybind.Callback(Value, false, Keybind.Toggle)
		end)

		function Keybind:Tooltip(Text)
			Bracket.Elements.Tooltip(KeybindAsset, Text)
		end
	end,
	ToggleKeybind = function(Parent, Window, Keybind, Toggle)
		local KeybindAsset = Bracket.Assets.ToggleKeybind()
		Keybind.WaitingForBind = false
		Keybind.Toggle = Toggle

		KeybindAsset.Parent = Parent
		KeybindAsset.Text = "[ " .. Keybind.Value .. " ]"

		KeybindAsset.MouseButton1Click:Connect(function()
			KeybindAsset.Text = "[ ... ]"
			Keybind.WaitingForBind = true
		end)
		KeybindAsset:GetPropertyChangedSignal("TextBounds"):Connect(function()
			KeybindAsset.Size = UDim2.new(0, KeybindAsset.TextBounds.X, 1, 0)
		end)

		if type(Window.KeybindList) == "table" and not Keybind.IgnoreList then
			Keybind.ListMimic = {}
			Keybind.ListMimic.Asset = Bracket.Assets.KeybindMimic()
			Keybind.ListMimic.Asset.Title.Text = Toggle.Name
			Keybind.ListMimic.Asset.Visible = Keybind.Value ~= "NONE"
			Keybind.ListMimic.Asset.Parent = Window.KeybindList.List

			Keybind.ListMimic.ColorConfig = {false, "BackgroundColor3"}
			Window.Colorable[Keybind.ListMimic.Asset.Tick] = Keybind.ListMimic.ColorConfig
		end

		UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
			if GameProcessedEvent then return end
			local Key = Input.KeyCode.Name
			if Keybind.WaitingForBind and Input.UserInputType.Name == "Keyboard" then
				Keybind.Value = Key
			elseif Input.UserInputType.Name == "Keyboard" then
				if Key == Keybind.Value then
					if not Keybind.DisableToggle then Toggle.Value = not Toggle.Value end
					Keybind.Callback(Keybind.Value, true, Toggle.Value)
				end
			end
			if Keybind.Mouse then Key = Input.UserInputType.Name
				if Keybind.WaitingForBind and (Key == "MouseButton1"
					or Key == "MouseButton2" or Key == "MouseButton3") then
					Keybind.Value = Key
				elseif Key == "MouseButton1"
					or Key == "MouseButton2"
					or Key == "MouseButton3" then
					if Key == Keybind.Value then
						if not Keybind.DisableToggle then Toggle.Value = not Toggle.Value end
						Keybind.Callback(Keybind.Value, true, Toggle.Value)
					end
				end
			end
		end)
		UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
			if GameProcessedEvent then return end
			local Key = Input.KeyCode.Name
			if Input.UserInputType.Name == "Keyboard" then
				if Key == Keybind.Value then
					Keybind.Callback(Keybind.Value, false, Toggle.Value)
				end
			end
			if Keybind.Mouse then Key = Input.UserInputType.Name
				if Key == "MouseButton1"
					or Key == "MouseButton2"
					or Key == "MouseButton3" then
					if Key == Keybind.Value then
						Keybind.Callback(Keybind.Value, false, Toggle.Value)
					end
				end
			end
		end)

		Toggle:GetPropertyChangedSignal("Value"):Connect(function(Value)
			if Keybind.ListMimic then
				Keybind.ListMimic.ColorConfig[1] = Value
				Keybind.ListMimic.Asset.Tick.BackgroundColor3 = Value
					and Window.Color or Color3.fromRGB(63, 63, 63)
			end
		end)

		Keybind:GetPropertyChangedSignal("Value"):Connect(function(Value, OldValue)
			if table.find(Keybind.Blacklist, Value) then
				Value = Keybind.DoNotClear and OldValue or "NONE"
			end

			KeybindAsset.Text = "[ " .. tostring(Value) .. " ]"
			if Keybind.ListMimic then
				Keybind.ListMimic.Asset.Visible = Value ~= "NONE"
				Keybind.ListMimic.Asset.Layout.Keybind.Text = "[ " .. tostring(Value) .. " ]"
			end

			Keybind.WaitingForBind = false
			Keybind.Internal.Value = Value
			Window.Flags[Keybind.Flag] = Value
			Keybind.Callback(Value, false, Toggle.Value)
		end)
	end,
	Dropdown = function(Parent, Window, Dropdown)
		local OptionContainerAsset = Bracket.Assets.DropdownContainer()
		local DropdownAsset = Bracket.Assets.Dropdown()

		Dropdown.Internal.Value = {}
		local ContainerRender = nil

		DropdownAsset.Parent = Parent
		OptionContainerAsset.Parent = Bracket.Screen

		DropdownAsset.Title.Text = Dropdown.Name
		DropdownAsset.Title.Visible = not Dropdown.HideName

		DropdownAsset.MouseButton1Click:Connect(function()
			if not OptionContainerAsset.Visible and OptionContainerAsset.ListLayout.AbsoluteContentSize.Y ~= 0 then
				Bracket.Utilities.ClosePopUps()
				OptionContainerAsset.Visible = true

				ContainerRender = RunService.RenderStepped:Connect(function()
					if not OptionContainerAsset.Visible then ContainerRender:Disconnect() end

					local TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y + Window.Asset.TabContainer.AbsoluteSize.Y
					local DropdownPosition = DropdownAsset.Background.AbsolutePosition.Y + DropdownAsset.Background.AbsoluteSize.Y
					if TabPosition < DropdownPosition then
						OptionContainerAsset.Visible = false
					end

					TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y
					DropdownPosition = DropdownAsset.Background.AbsolutePosition.Y
					if TabPosition > DropdownPosition then
						OptionContainerAsset.Visible = false
					end

					OptionContainerAsset.Position = UDim2.fromOffset(
						DropdownAsset.Background.AbsolutePosition.X,
						(DropdownAsset.Background.AbsolutePosition.Y + GuiInset.Y) + DropdownAsset.Background.AbsoluteSize.Y + 4
					)
					OptionContainerAsset.Size = UDim2.fromOffset(
						DropdownAsset.Background.AbsoluteSize.X,
						math.clamp(OptionContainerAsset.ListLayout.AbsoluteContentSize.Y, 16, 112) + 4
						--OptionContainerAsset.ListLayout.AbsoluteContentSize.Y + 2
					)
				end)
			else
				OptionContainerAsset.Visible = false
			end
		end)
		DropdownAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			DropdownAsset.Title.Size = Dropdown.HideName and UDim2.fromScale(1, 0) or UDim2.new(1, 0, 0, 
                Bracket.Utilities.GetTextBounds(
                    DropdownAsset.Title.Text,
                    DropdownAsset.Title.Font.Name,
                    Vector2.new(DropdownAsset.Title.AbsoluteSize.X, DropdownAsset.Title.TextSize)
                ).Y + 2
            )

			DropdownAsset.Background.Position = UDim2.new(0.5, 0, 0, DropdownAsset.Title.Size.Y.Offset)
			DropdownAsset.Size = UDim2.new(1, 0, 0, DropdownAsset.Title.Size.Y.Offset + DropdownAsset.Background.Size.Y.Offset)
		end)
		OptionContainerAsset.ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			OptionContainerAsset.CanvasSize = UDim2.fromOffset(0, OptionContainerAsset.ListLayout.AbsoluteContentSize.Y + 4)
		end)
		--[[DropdownAsset.Background.Value:GetPropertyChangedSignal("TextBounds"):Connect(function()
			DropdownAsset.Background.Size = UDim2.new(1, 0, 0, DropdownAsset.Background.Value.TextBounds.Y + 2)
			DropdownAsset.Size = UDim2.new(1, 0, 0, DropdownAsset.Title.Size.Y.Offset + DropdownAsset.Background.Size.Y.Offset)
		end)]]

		local function RefreshSelected()
			table.clear(Dropdown.Internal.Value)

			for Index, Option in pairs(Dropdown.List) do
				if Option.Value then
					table.insert(Dropdown.Internal.Value, Option.Name)
				end
			end

			Window.Flags[Dropdown.Flag] = Dropdown.Internal.Value
			DropdownAsset.Background.Value.Text = #Dropdown.Internal.Value == 0
				and "..." or table.concat(Dropdown.Internal.Value, ", ")
		end

		local function SetValue(Option, Value)
			Option.Value = Value
			Option.ColorConfig[1] = Value
			Option.Object.Tick.BackgroundColor3 = Value
				and Window.Color or Color3.fromRGB(63, 63, 63)
			--Option.Callback(Dropdown.Selected, Option)
		end

		local function AddOption(Option, AddToList, Order)
			Option = Bracket.Utilities:GetType(Option, {}, "table", true)
			Option.Name = Bracket.Utilities:GetType(Option.Name, "Option", "string")
			Option.Mode = Bracket.Utilities:GetType(Option.Mode, "Button", "string")
			Option.Value = Bracket.Utilities:GetType(Option.Value, false, "boolean")
			Option.Callback = Bracket.Utilities:GetType(Option.Callback, function() end, "function")

			local OptionAsset = Bracket.Assets.DropdownOption()
			Option.Object = OptionAsset

			OptionAsset.LayoutOrder = Order
			OptionAsset.Parent = OptionContainerAsset
			OptionAsset.Title.Text = Option.Name
			OptionAsset.Tick.BackgroundColor3 = Option.Value
				and Window.Color or Color3.fromRGB(63, 63, 63)

			Option.ColorConfig = {Option.Value, "BackgroundColor3"}
			Window.Colorable[OptionAsset.Tick] = Option.ColorConfig
			if AddToList then table.insert(Dropdown.List, Option) end

			OptionAsset.MouseButton1Click:Connect(function()
				Option.Value = not Option.Value
			end)
			OptionAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
				OptionAsset.Layout.Size = UDim2.new(1, -OptionAsset.Title.TextBounds.X - 22, 1, 0)
			end)

			Option:GetPropertyChangedSignal("Name"):Connect(function(Name)
				OptionAsset.Title.Text = Name
			end)
			Option:GetPropertyChangedSignal("Value"):Connect(function(Value)
				if Option.Mode == "Button" then
					for Index, OldOption in pairs(Dropdown.List) do
						SetValue(OldOption.Internal, false)
					end

					Value = true
					Option.Internal.Value = Value
					OptionContainerAsset.Visible = false
				end

				RefreshSelected()
				Option.ColorConfig[1] = Value
				Option.Object.Tick.BackgroundColor3 = Value
					and Window.Color or Color3.fromRGB(63, 63, 63)
				Option.Callback(Dropdown.Value, Option)
			end)

			for Index, Value in pairs(Option.Internal) do
				if string.find(Index, "Colorpicker") then
					Option[Index] = Bracket.Utilities:GetType(Option[Index], {}, "table", true)
					Option[Index].Flag = Bracket.Utilities:GetType(Option[Index].Flag,
						Dropdown.Flag .. "/" .. Option.Name .. "/Colorpicker", "string")

					Option[Index].Value = Bracket.Utilities:GetType(Option[Index].Value, {1, 1, 1, 0, false}, "table")
					Option[Index].Callback = Bracket.Utilities:GetType(Option[Index].Callback, function() end, "function")
					Window.Elements[#Window.Elements + 1] = Option[Index]
					Window.Flags[Option[Index].Flag] = Option[Index].Value

					Bracket.Elements.ToggleColorpicker(OptionAsset.Layout, Window, Option[Index])
				end
			end

			return Option
		end

		-- Dropdown Update
		for Index, Option in pairs(Dropdown.List) do
			Dropdown.List[Index] = AddOption(Option, false, Index)
		end for Index, Option in pairs(Dropdown.List) do
			if Option.Value then Option.Value = true end
		end RefreshSelected()

		function Dropdown:BulkAdd(Table)
			for Index, Option in pairs(Table) do
				AddOption(Option, true, Index)
			end
		end
		function Dropdown.AddOption(Self, Option)
			AddOption(Option, true, #Self.List)
		end

		function Dropdown.Clear(Self)
			for Index, Option in pairs(Self.List) do
				Option.Object:Destroy()
			end table.clear(Self.List)
		end
		function Dropdown.RemoveOption(Self, Name)
			for Index, Option in pairs(Self.List) do
				if Option.Name == Name then
					Option.Object:Destroy()
					table.remove(Self.List, Index)
				end
			end
			for Index, Option in pairs(Self.List) do
				Option.Object.LayoutOrder = Index
			end
		end
		function Dropdown.RefreshToPlayers(Self, ToggleMode)
			local Players = {}
			for Index, Player in pairs(PlayerService:GetPlayers()) do
				if Player == LocalPlayer then continue end
				table.insert(Players, {Name = Player.Name,
					Mode = ToggleMode == "Toggle" or "Button"
				})
			end
			Self:Clear()
			Self:BulkAdd(Players)
		end

		Dropdown:GetPropertyChangedSignal("Name"):Connect(function(Name)
			DropdownAsset.Title.Text = Name
		end)
		Dropdown:GetPropertyChangedSignal("Value"):Connect(function(Value)
			if type(Value) ~= "table" then return end
			if #Value == 0 then RefreshSelected() return end

			for Index, Option in pairs(Dropdown.List) do
				if table.find(Value, Option.Name) then
					Option.Value = true
				else
					if Option.Mode ~= "Button" then
						Option.Value = false
					end
				end
			end
		end)

		function Dropdown:Tooltip(Text)
			Bracket.Elements.Tooltip(DropdownAsset, Text)
		end
	end,
	Colorpicker = function(Parent, Window, Colorpicker)
		local ColorpickerAsset = Bracket.Assets.Colorpicker()
		local PaletteAsset = Bracket.Assets.ColorpickerPalette()

		Colorpicker.ColorConfig = {Colorpicker.Value[5], "BackgroundColor3"}
		Window.Colorable[PaletteAsset.Rainbow.Tick] = Colorpicker.ColorConfig
		local PaletteRender, SVRender, HueRender, AlphaRender = nil, nil, nil, nil


		ColorpickerAsset.Parent = Parent
		PaletteAsset.Parent = Bracket.Screen

		ColorpickerAsset.Title.Text = Colorpicker.Name
		PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
			and Window.Color or Color3.fromRGB(63, 63, 63)


		ColorpickerAsset.Title:GetPropertyChangedSignal("TextBounds"):Connect(function()
			ColorpickerAsset.Size = UDim2.new(1, 0, 0,
                Bracket.Utilities.GetTextBounds(
                    ColorpickerAsset.Title.Text,
                    ColorpickerAsset.Title.Font.Name,
                    Vector2.new(ColorpickerAsset.Title.AbsoluteSize.X, ColorpickerAsset.Title.TextSize)
                ).Y
            )
		end)

		ColorpickerAsset.MouseButton1Click:Connect(function()
			if not PaletteAsset.Visible then
				Bracket.Utilities.ClosePopUps()
				PaletteAsset.Visible = true

				PaletteRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then PaletteRender:Disconnect() end

					local TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y + Window.Asset.TabContainer.AbsoluteSize.Y
					local ColorpickerPosition = ColorpickerAsset.Color.AbsolutePosition.Y + ColorpickerAsset.Color.AbsoluteSize.Y
					if TabPosition < ColorpickerPosition then
						PaletteAsset.Visible = false
					end

					TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y
					ColorpickerPosition = ColorpickerAsset.Color.AbsolutePosition.Y
					if TabPosition > ColorpickerPosition then
						PaletteAsset.Visible = false
					end

					PaletteAsset.Position = UDim2.fromOffset(
						(ColorpickerAsset.Color.AbsolutePosition.X - PaletteAsset.AbsoluteSize.X) + 20,
						(ColorpickerAsset.Color.AbsolutePosition.Y + GuiInset.Y) + 14
					)
				end)
			else
				PaletteAsset.Visible = false
			end
		end)

		PaletteAsset.Rainbow.MouseButton1Click:Connect(function()
			Colorpicker.Value[5] = not Colorpicker.Value[5]
			Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
			PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
				and Window.Color or Color3.fromRGB(63, 63, 63)
		end)
		PaletteAsset.SVPicker.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if SVRender then SVRender:Disconnect() end
				SVRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then SVRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X, 0, PaletteAsset.SVPicker.AbsoluteSize.X) / PaletteAsset.SVPicker.AbsoluteSize.X
					local ColorY = math.clamp(Mouse.Y - (PaletteAsset.SVPicker.AbsolutePosition.Y + GuiInset.Y), 0, PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPicker.AbsoluteSize.Y

					Colorpicker.Value[2] = ColorX
					Colorpicker.Value[3] = 1 - ColorY
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.SVPicker.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if SVRender then SVRender:Disconnect() end
			end
		end)
		PaletteAsset.Hue.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if HueRender then HueRender:Disconnect() end
				HueRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then HueRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.Hue.AbsolutePosition.X, 0, PaletteAsset.Hue.AbsoluteSize.X) / PaletteAsset.Hue.AbsoluteSize.X
					Colorpicker.Value[1] = 1 - ColorX
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.Hue.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if HueRender then HueRender:Disconnect() end
			end
		end)
		PaletteAsset.Alpha.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if AlphaRender then AlphaRender:Disconnect() end
				AlphaRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then AlphaRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.Alpha.AbsolutePosition.X, 0, PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.X
					Colorpicker.Value[4] = math.floor(ColorX * 10^2) / (10^2) -- idk %.2f little bit broken with this
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.Alpha.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if AlphaRender then AlphaRender:Disconnect() end
			end
		end)

		PaletteAsset.RGB.RGBBox.FocusLost:Connect(function(Enter)
			if not Enter then return end
			local ColorString = string.split(string.gsub(PaletteAsset.RGB.RGBBox.Text, " ", ""), ", ")
			local Hue, Saturation, Value = Color3.fromRGB(ColorString[1], ColorString[2], ColorString[3]):ToHSV()
			PaletteAsset.RGB.RGBBox.Text = ""
			Colorpicker.Value[1] = Hue
			Colorpicker.Value[2] = Saturation
			Colorpicker.Value[3] = Value
			Colorpicker.Value = Colorpicker.Value
		end)
		PaletteAsset.HEX.HEXBox.FocusLost:Connect(function(Enter)
			if not Enter then return end
			local Hue, Saturation, Value = Color3.fromHex("#" .. PaletteAsset.HEX.HEXBox.Text):ToHSV()
			PaletteAsset.RGB.RGBBox.Text = ""
			Colorpicker.Value[1] = Hue
			Colorpicker.Value[2] = Saturation
			Colorpicker.Value[3] = Value
			Colorpicker.Value = Colorpicker.Value
		end)

		RunService.Heartbeat:Connect(function()
			if Colorpicker.Value[5] then
				if PaletteAsset.Visible then
					Colorpicker.Value[1] = Window.RainbowHue
					Colorpicker.Value = Colorpicker.Value
				else 
					Colorpicker.Value[1] = Window.RainbowHue
					Colorpicker.Value[6] = Bracket.Utilities.TableToColor(Colorpicker.Value)
					ColorpickerAsset.Color.BackgroundColor3 = Colorpicker.Value[6]
					Window.Flags[Colorpicker.Flag] = Colorpicker.Value
					Colorpicker.Callback(Colorpicker.Value, Colorpicker.Value[6])
				end
			end
		end)

		Colorpicker:GetPropertyChangedSignal("Name"):Connect(function(Name)
			ColorpickerAsset.Title.Text = Name
		end)
		Colorpicker:GetPropertyChangedSignal("Value"):Connect(function(Value)
			Value[6] = Bracket.Utilities.TableToColor(Value)
			Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
			ColorpickerAsset.Color.BackgroundColor3 = Value[6]

			PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
				and Window.Color or Color3.fromRGB(63, 63, 63)

			PaletteAsset.SVPicker.BackgroundColor3 = Color3.fromHSV(Value[1], 1, 1)
			PaletteAsset.SVPicker.Pin.Position = UDim2.fromScale(Value[2], 1 - Value[3])
			PaletteAsset.Hue.Pin.Position = UDim2.fromScale(1 - Value[1], 0.5)

			PaletteAsset.Alpha.Pin.Position = UDim2.fromScale(Value[4], 0.5)
			PaletteAsset.Alpha.Value.Text = Value[4]
			PaletteAsset.Alpha.BackgroundColor3 = Value[6]

			PaletteAsset.RGB.RGBBox.PlaceholderText = Bracket.Utilities.ColorToString(Value[6])
			PaletteAsset.HEX.HEXBox.PlaceholderText = string.upper(Value[6]:ToHex())
			Window.Flags[Colorpicker.Flag] = Value
			Colorpicker.Callback(Value, Value[6])
		end) Colorpicker.Value = Colorpicker.Value

		function Colorpicker:Tooltip(Text)
			Bracket.Elements.Tooltip(ColorpickerAsset, Text)
		end
	end,
	ToggleColorpicker = function(Parent, Window, Colorpicker)
		local ColorpickerAsset = Bracket.Assets.ToggleColorpicker()
		local PaletteAsset = Bracket.Assets.ColorpickerPalette()

		Colorpicker.ColorConfig = {Colorpicker.Value[5], "BackgroundColor3"}
		Window.Colorable[PaletteAsset.Rainbow.Tick] = Colorpicker.ColorConfig
		local PaletteRender, SVRender, HueRender, AlphaRender = nil, nil, nil, nil

		ColorpickerAsset.Parent = Parent
		PaletteAsset.Parent = Bracket.Screen

		PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
			and Window.Color or Color3.fromRGB(63, 63, 63)

		ColorpickerAsset.MouseButton1Click:Connect(function()
			if not PaletteAsset.Visible then
				Bracket.Utilities.ClosePopUps()
				PaletteAsset.Visible = true

				PaletteRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then PaletteRender:Disconnect() end

					local TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y + Window.Asset.TabContainer.AbsoluteSize.Y
					local ColorpickerPosition = ColorpickerAsset.AbsolutePosition.Y + ColorpickerAsset.AbsoluteSize.Y
					if TabPosition < ColorpickerPosition then
						PaletteAsset.Visible = false
					end

					TabPosition = Window.Asset.TabContainer.AbsolutePosition.Y
					ColorpickerPosition = ColorpickerAsset.AbsolutePosition.Y
					if TabPosition > ColorpickerPosition then
						PaletteAsset.Visible = false
					end

					PaletteAsset.Position = UDim2.fromOffset(
						(ColorpickerAsset.AbsolutePosition.X - PaletteAsset.AbsoluteSize.X) + 24,
						(ColorpickerAsset.AbsolutePosition.Y + GuiInset.Y) + 16
					)
				end)
			else
				PaletteAsset.Visible = false
			end
		end)

		PaletteAsset.Rainbow.MouseButton1Click:Connect(function()
			Colorpicker.Value[5] = not Colorpicker.Value[5]
			Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
			PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
				and Window.Color or Color3.fromRGB(63, 63, 63)
		end)
		PaletteAsset.SVPicker.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if SVRender then SVRender:Disconnect() end
				SVRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then SVRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.SVPicker.AbsolutePosition.X, 0, PaletteAsset.SVPicker.AbsoluteSize.X) / PaletteAsset.SVPicker.AbsoluteSize.X
					local ColorY = math.clamp(Mouse.Y - (PaletteAsset.SVPicker.AbsolutePosition.Y + GuiInset.Y), 0, PaletteAsset.SVPicker.AbsoluteSize.Y) / PaletteAsset.SVPicker.AbsoluteSize.Y

					Colorpicker.Value[2] = ColorX
					Colorpicker.Value[3] = 1 - ColorY
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.SVPicker.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if SVRender then SVRender:Disconnect() end
			end
		end)
		PaletteAsset.Hue.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if HueRender then HueRender:Disconnect() end
				HueRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then HueRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.Hue.AbsolutePosition.X, 0, PaletteAsset.Hue.AbsoluteSize.X) / PaletteAsset.Hue.AbsoluteSize.X
					Colorpicker.Value[1] = 1 - ColorX
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.Hue.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if HueRender then HueRender:Disconnect() end
			end
		end)
		PaletteAsset.Alpha.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if AlphaRender then AlphaRender:Disconnect() end
				AlphaRender = RunService.RenderStepped:Connect(function()
					if not PaletteAsset.Visible then AlphaRender:Disconnect() end
					local Mouse = UserInputService:GetMouseLocation()
					local ColorX = math.clamp(Mouse.X - PaletteAsset.Alpha.AbsolutePosition.X, 0, PaletteAsset.Alpha.AbsoluteSize.X) / PaletteAsset.Alpha.AbsoluteSize.X
					Colorpicker.Value[4] = math.floor(ColorX * 10^2) / (10^2) -- idk %.2f little bit broken with this
					Colorpicker.Value = Colorpicker.Value
				end)
			end
		end)
		PaletteAsset.Alpha.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				if AlphaRender then AlphaRender:Disconnect() end
			end
		end)

		PaletteAsset.RGB.RGBBox.FocusLost:Connect(function(Enter)
			if not Enter then return end
			local ColorString = string.split(string.gsub(PaletteAsset.RGB.RGBBox.Text, " ", ""), ", ")
			local Hue, Saturation, Value = Color3.fromRGB(ColorString[1], ColorString[2], ColorString[3]):ToHSV()
			PaletteAsset.RGB.RGBBox.Text = ""
			Colorpicker.Value[1] = Hue
			Colorpicker.Value[2] = Saturation
			Colorpicker.Value[3] = Value
			Colorpicker.Value = Colorpicker.Value
		end)
		PaletteAsset.HEX.HEXBox.FocusLost:Connect(function(Enter)
			if not Enter then return end
			local Hue, Saturation, Value = Color3.fromHex("#" .. PaletteAsset.HEX.HEXBox.Text):ToHSV()
			PaletteAsset.RGB.RGBBox.Text = ""
			Colorpicker.Value[1] = Hue
			Colorpicker.Value[2] = Saturation
			Colorpicker.Value[3] = Value
			Colorpicker.Value = Colorpicker.Value
		end)

		RunService.Heartbeat:Connect(function()
			if Colorpicker.Value[5] then
				if PaletteAsset.Visible then
					Colorpicker.Value[1] = Window.RainbowHue
					Colorpicker.Value = Colorpicker.Value
				else 
					Colorpicker.Value[1] = Window.RainbowHue
					Colorpicker.Value[6] = Bracket.Utilities.TableToColor(Colorpicker.Value)
					ColorpickerAsset.BackgroundColor3 = Colorpicker.Value[6]
					Window.Flags[Colorpicker.Flag] = Colorpicker.Value
					Colorpicker.Callback(Colorpicker.Value, Colorpicker.Value[6])
				end
			end
		end)
		Colorpicker:GetPropertyChangedSignal("Value"):Connect(function(Value)
			Value[6] = Bracket.Utilities.TableToColor(Value)
			Colorpicker.ColorConfig[1] = Colorpicker.Value[5]
			ColorpickerAsset.BackgroundColor3 = Value[6]

			PaletteAsset.Rainbow.Tick.BackgroundColor3 = Colorpicker.Value[5]
				and Window.Color or Color3.fromRGB(63, 63, 63)

			PaletteAsset.SVPicker.BackgroundColor3 = Color3.fromHSV(Value[1], 1, 1)
			PaletteAsset.SVPicker.Pin.Position = UDim2.fromScale(Value[2], 1 - Value[3])
			PaletteAsset.Hue.Pin.Position = UDim2.fromScale(1 - Value[1], 0.5)

			PaletteAsset.Alpha.Pin.Position = UDim2.fromScale(Value[4], 0.5)
			PaletteAsset.Alpha.Value.Text = Value[4]
			PaletteAsset.Alpha.BackgroundColor3 = Value[6]

			PaletteAsset.RGB.RGBBox.PlaceholderText = Bracket.Utilities.ColorToString(Value[6])
			PaletteAsset.HEX.HEXBox.PlaceholderText = string.upper(Value[6]:ToHex())
			Window.Flags[Colorpicker.Flag] = Value
			Colorpicker.Callback(Value, Value[6])
		end) Colorpicker.Value = Colorpicker.Value
	end
}

Bracket.Elements.Screen()
function Bracket:Window(Window)
	Window = Bracket.Utilities:GetType(Window, {}, "table", true)
	Window.Blur = Bracket.Utilities:GetType(Window.Blur, false, "boolean")
	Window.Name = Bracket.Utilities:GetType(Window.Name, "Window", "string")
	Window.Enabled = Bracket.Utilities:GetType(Window.Enabled, true, "boolean")
	Window.Color = Bracket.Utilities:GetType(Window.Color, Color3.new(1, 0.5, 0.25), "Color3")
	Window.Position = Bracket.Utilities:GetType(Window.Position, UDim2.new(0.5, -248, 0.5, -248), "UDim2")
	Window.Size = Bracket.Utilities:GetType(Window.Size, UDim2.new(0, 496, 0, 496), "UDim2")
	local WindowAsset = Bracket.Elements.Window(Window)

	function Window:Tab(Tab)
		Tab = Bracket.Utilities:GetType(Tab, {}, "table", true)
		Tab.Name = Bracket.Utilities:GetType(Tab.Name, "Tab", "string")
		local TabAsset = Bracket.Elements.Tab(WindowAsset, Window, Tab)

		function Tab:AddConfigSection(FolderName, Side)
			local ConfigSection = Tab:Section({Name = "Config System", Side = Side}) do
				local ConfigList, ConfigDropdown = Bracket.Utilities.ConfigsToList(FolderName), nil
				local ALConfig = Window:GetAutoLoadConfig(FolderName)

				local function UpdateList(Name) ConfigDropdown:Clear()
					ConfigList = Bracket.Utilities.ConfigsToList(FolderName) ConfigDropdown:BulkAdd(ConfigList)
					ConfigDropdown.Value = {}
					--ConfigDropdown.Value = {Name or (ConfigList[#ConfigList] and ConfigList[#ConfigList].Name)}
				end

				local ConfigTextbox = ConfigSection:Textbox({HideName = true, Placeholder = "Config Name", IgnoreFlag = true})
				ConfigSection:Button({Name = "Create", Callback = function()
					Window:SaveConfig(FolderName, ConfigTextbox.Value) UpdateList(ConfigTextbox.Value)
				end})

				ConfigSection:Divider({Text = "Configs"})

				ConfigDropdown = ConfigSection:Dropdown({HideName = true, IgnoreFlag = true, List = ConfigList})
				--ConfigDropdown.Value = {ConfigList[#ConfigList] and ConfigList[#ConfigList].Name}

				ConfigSection:Button({Name = "Save", Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:SaveConfig(FolderName, ConfigDropdown.Value[1])
					else
						Bracket:Notification({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Load", Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:LoadConfig(FolderName, ConfigDropdown.Value[1])
					else
						Bracket:Notification({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Delete", Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:DeleteConfig(FolderName, ConfigDropdown.Value[1])
						UpdateList()
					else
						Bracket:Notification({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Refresh", Callback = UpdateList})

				local ConfigDivider = ConfigSection:Divider({Text = not ALConfig and "AutoLoad Config"
					or "AutoLoad Config\n<font color=\"rgb(189, 189, 189)\">[ " .. ALConfig .. " ]</font>"})

				ConfigSection:Button({Name = "Set AutoLoad Config", Callback = function()
					if ConfigDropdown.Value and ConfigDropdown.Value[1] then
						Window:AddToAutoLoad(FolderName, ConfigDropdown.Value[1])
						ConfigDivider.Text = "AutoLoad Config\n<font color=\"rgb(189, 189, 189)\">[ " .. ConfigDropdown.Value[1] .. " ]</font>"
					else
						Bracket:Notification({
							Title = "Config System",
							Description = "Select Config First",
							Duration = 10
						})
					end
				end})
				ConfigSection:Button({Name = "Clear AutoLoad Config", Callback = function()
					Window:RemoveFromAutoLoad(FolderName)
					ConfigDivider.Text = "AutoLoad Config"
				end})
			end
		end

		function Tab:Divider(Divider)
			Divider = Bracket.Utilities:GetType(Divider, {}, "table", true)
			Divider.Text = Bracket.Utilities:GetType(Divider.Text, "", "string")
			Bracket.Elements.Divider(Bracket.Utilities:ChooseTabSide(TabAsset, Divider.Side), Divider)
			return Divider
		end
		function Tab:Label(Label)
			Label = Bracket.Utilities:GetType(Label, {}, "table", true)
			Label.Text = Bracket.Utilities:GetType(Label.Text, "Label", "string")
			Bracket.Elements.Label(Bracket.Utilities:ChooseTabSide(TabAsset, Label.Side), Label)
			return Label
		end
		function Tab:Button(Button)
			Button = Bracket.Utilities:GetType(Button, {}, "table", true)
			Button.Name = Bracket.Utilities:GetType(Button.Name, "Button", "string")
			Button.Callback = Bracket.Utilities:GetType(Button.Callback, function() end, "function")
			Bracket.Elements.Button(Bracket.Utilities:ChooseTabSide(TabAsset, Button.Side), Window, Button)
			return Button
		end
		function Tab:Toggle(Toggle)
			Toggle = Bracket.Utilities:GetType(Toggle, {}, "table", true)
			Toggle.Name = Bracket.Utilities:GetType(Toggle.Name, "Toggle", "string")
			Toggle.Flag = Bracket.Utilities:GetType(Toggle.Flag, Toggle.Name, "string")

			Toggle.Value = Bracket.Utilities:GetType(Toggle.Value, false, "boolean")
			Toggle.Callback = Bracket.Utilities:GetType(Toggle.Callback, function() end, "function")
			Window.Elements[#Window.Elements + 1] = Toggle
			Window.Flags[Toggle.Flag] = Toggle.Value

			local ToggleAsset = Bracket.Elements.Toggle(Bracket.Utilities:ChooseTabSide(TabAsset, Toggle.Side), Window, Toggle)
			function Toggle:Keybind(Keybind)
				Keybind = Bracket.Utilities:GetType(Keybind, {}, "table", true)
				Keybind.Flag = Bracket.Utilities:GetType(Keybind.Flag, Toggle.Flag .. "/Keybind", "string")

				Keybind.Value = Bracket.Utilities:GetType(Keybind.Value, "NONE", "string")
				Keybind.Mouse = Bracket.Utilities:GetType(Keybind.Mouse, false, "boolean")
				Keybind.Callback = Bracket.Utilities:GetType(Keybind.Callback, function() end, "function")
				Keybind.Blacklist = Bracket.Utilities:GetType(Keybind.Blacklist, {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"}, "table")
				Window.Elements[#Window.Elements + 1] = Keybind
				Window.Flags[Keybind.Flag] = Keybind.Value

				Bracket.Elements.ToggleKeybind(ToggleAsset.Layout, Window, Keybind, Toggle)
				return Keybind
			end
			function Toggle:Colorpicker(Colorpicker)
				Colorpicker = Bracket.Utilities:GetType(Colorpicker, {}, "table", true)
				Colorpicker.Flag = Bracket.Utilities:GetType(Colorpicker.Flag, Toggle.Flag .. "/Colorpicker", "string")

				Colorpicker.Value = Bracket.Utilities:GetType(Colorpicker.Value, {1, 1, 1, 0, false}, "table")
				Colorpicker.Callback = Bracket.Utilities:GetType(Colorpicker.Callback, function() end, "function")
				Window.Elements[#Window.Elements + 1] = Colorpicker
				Window.Flags[Colorpicker.Flag] = Colorpicker.Value

				Bracket.Elements.ToggleColorpicker(ToggleAsset.Layout, Window, Colorpicker)
				return Colorpicker
			end
			return Toggle
		end
		function Tab:Slider(Slider)
			Slider = Bracket.Utilities:GetType(Slider, {}, "table", true)
			Slider.Name = Bracket.Utilities:GetType(Slider.Name, "Slider", "string")
			Slider.Flag = Bracket.Utilities:GetType(Slider.Flag, Slider.Name, "string")

			Slider.Min = Bracket.Utilities:GetType(Slider.Min, 0, "number")
			Slider.Max = Bracket.Utilities:GetType(Slider.Max, 100, "number")
			Slider.Precise = Bracket.Utilities:GetType(Slider.Precise, 0, "number")
			Slider.Unit = Bracket.Utilities:GetType(Slider.Unit, "", "string")
			Slider.Value = Bracket.Utilities:GetType(Slider.Value, Slider.Max / 2, "number")
			Slider.Callback = Bracket.Utilities:GetType(Slider.Callback, function() end, "function")
			Window.Elements[#Window.Elements + 1] = Slider
			Window.Flags[Slider.Flag] = Slider.Value

			Bracket.Elements.Slider(Bracket.Utilities:ChooseTabSide(TabAsset, Slider.Side), Window, Slider)
			return Slider
		end
		function Tab:Textbox(Textbox)
			Textbox = Bracket.Utilities:GetType(Textbox, {}, "table", true)
			Textbox.Name = Bracket.Utilities:GetType(Textbox.Name, "Textbox", "string")
			Textbox.Flag = Bracket.Utilities:GetType(Textbox.Flag, Textbox.Name, "string")

			Textbox.Value = Bracket.Utilities:GetType(Textbox.Value, "", "string")
			Textbox.NumbersOnly = Bracket.Utilities:GetType(Textbox.NumbersOnly, false, "boolean")
			Textbox.Placeholder = Bracket.Utilities:GetType(Textbox.Placeholder, "Input here", "string")
			Textbox.Callback = Bracket.Utilities:GetType(Textbox.Callback, function() end, "function")
			Window.Elements[#Window.Elements + 1] = Textbox
			Window.Flags[Textbox.Flag] = Textbox.Value

			Bracket.Elements.Textbox(Bracket.Utilities:ChooseTabSide(TabAsset, Textbox.Side), Window, Textbox)
			return Textbox
		end
		function Tab:Keybind(Keybind)
			Keybind = Bracket.Utilities:GetType(Keybind, {}, "table", true)
			Keybind.Name = Bracket.Utilities:GetType(Keybind.Name, "Keybind", "string")
			Keybind.Flag = Bracket.Utilities:GetType(Keybind.Flag, Keybind.Name, "string")

			Keybind.Value = Bracket.Utilities:GetType(Keybind.Value, "NONE", "string")
			Keybind.Mouse = Bracket.Utilities:GetType(Keybind.Mouse, false, "boolean")
			Keybind.Callback = Bracket.Utilities:GetType(Keybind.Callback, function() end, "function")
			Keybind.Blacklist = Bracket.Utilities:GetType(Keybind.Blacklist, {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"}, "table")
			Window.Elements[#Window.Elements + 1] = Keybind
			Window.Flags[Keybind.Flag] = Keybind.Value

			Bracket.Elements.Keybind(Bracket.Utilities:ChooseTabSide(TabAsset, Keybind.Side), Window, Keybind)
			return Keybind
		end
		function Tab:Dropdown(Dropdown)
			Dropdown = Bracket.Utilities:GetType(Dropdown, {}, "table", true)
			Dropdown.Name = Bracket.Utilities:GetType(Dropdown.Name, "Dropdown", "string")
			Dropdown.Flag = Bracket.Utilities:GetType(Dropdown.Flag, Dropdown.Name, "string")
			Dropdown.List = Bracket.Utilities:GetType(Dropdown.List, {}, "table")
			Window.Elements[#Window.Elements + 1] = Dropdown
			Window.Flags[Dropdown.Flag] = Dropdown.Value

			Bracket.Elements.Dropdown(Bracket.Utilities:ChooseTabSide(TabAsset, Dropdown.Side), Window, Dropdown)
			return Dropdown
		end
		function Tab:Colorpicker(Colorpicker)
			Colorpicker = Bracket.Utilities:GetType(Colorpicker, {}, "table", true)
			Colorpicker.Name = Bracket.Utilities:GetType(Colorpicker.Name, "Colorpicker", "string")
			Colorpicker.Flag = Bracket.Utilities:GetType(Colorpicker.Flag, Colorpicker.Name, "string")

			Colorpicker.Value = Bracket.Utilities:GetType(Colorpicker.Value, {1, 1, 1, 0, false}, "table")
			Colorpicker.Callback = Bracket.Utilities:GetType(Colorpicker.Callback, function() end, "function")
			Window.Elements[#Window.Elements + 1] = Colorpicker
			Window.Flags[Colorpicker.Flag] = Colorpicker.Value

			Bracket.Elements.Colorpicker(Bracket.Utilities:ChooseTabSide(TabAsset, Colorpicker.Side), Window, Colorpicker)
			return Colorpicker
		end
		function Tab:Section(Section)
			Section = Bracket.Utilities:GetType(Section, {}, "table", true)
			Section.Name = Bracket.Utilities:GetType(Section.Name, "Section", "string")
			local SectionContainer = Bracket.Elements.Section(Bracket.Utilities:ChooseTabSide(TabAsset, Section.Side), Section)

			function Section:Divider(Divider)
				Divider = Bracket.Utilities:GetType(Divider, {}, "table", true)
				Divider.Text = Bracket.Utilities:GetType(Divider.Text, "", "string")
				Bracket.Elements.Divider(SectionContainer, Divider)
				return Divider
			end
			function Section:Label(Label)
				Label = Bracket.Utilities:GetType(Label, {}, "table", true)
				Label.Text = Bracket.Utilities:GetType(Label.Text, "Label", "string")
				Bracket.Elements.Label(SectionContainer, Label)
				return Label
			end
			function Section:Button(Button)
				Button = Bracket.Utilities:GetType(Button, {}, "table", true)
				Button.Name = Bracket.Utilities:GetType(Button.Name, "Button", "string")
				Button.Callback = Bracket.Utilities:GetType(Button.Callback, function() end, "function")
				Bracket.Elements.Button(SectionContainer, Window, Button)
				return Button
			end
			function Section:Toggle(Toggle)
				Toggle = Bracket.Utilities:GetType(Toggle, {}, "table", true)
				Toggle.Name = Bracket.Utilities:GetType(Toggle.Name, "Toggle", "string")
				Toggle.Flag = Bracket.Utilities:GetType(Toggle.Flag, Toggle.Name, "string")

				Toggle.Value = Bracket.Utilities:GetType(Toggle.Value, false, "boolean")
				Toggle.Callback = Bracket.Utilities:GetType(Toggle.Callback, function() end, "function")
				Window.Elements[#Window.Elements + 1] = Toggle
				Window.Flags[Toggle.Flag] = Toggle.Value

				local ToggleAsset = Bracket.Elements.Toggle(SectionContainer, Window, Toggle)
				function Toggle:Keybind(Keybind)
					Keybind = Bracket.Utilities:GetType(Keybind, {}, "table", true)
					Keybind.Flag = Bracket.Utilities:GetType(Keybind.Flag, Toggle.Flag .. "/Keybind", "string")

					Keybind.Value = Bracket.Utilities:GetType(Keybind.Value, "NONE", "string")
					Keybind.Mouse = Bracket.Utilities:GetType(Keybind.Mouse, false, "boolean")
					Keybind.Callback = Bracket.Utilities:GetType(Keybind.Callback, function() end, "function")
					Keybind.Blacklist = Bracket.Utilities:GetType(Keybind.Blacklist, {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"}, "table")
					Window.Elements[#Window.Elements + 1] = Keybind
					Window.Flags[Keybind.Flag] = Keybind.Value

					Bracket.Elements.ToggleKeybind(ToggleAsset.Layout, Window, Keybind, Toggle)
					return Keybind
				end
				function Toggle:Colorpicker(Colorpicker)
					Colorpicker = Bracket.Utilities:GetType(Colorpicker, {}, "table", true)
					Colorpicker.Flag = Bracket.Utilities:GetType(Colorpicker.Flag, Toggle.Flag .. "/Colorpicker", "string")

					Colorpicker.Value = Bracket.Utilities:GetType(Colorpicker.Value, {1, 1, 1, 0, false}, "table")
					Colorpicker.Callback = Bracket.Utilities:GetType(Colorpicker.Callback, function() end, "function")
					Window.Elements[#Window.Elements + 1] = Colorpicker
					Window.Flags[Colorpicker.Flag] = Colorpicker.Value

					Bracket.Elements.ToggleColorpicker(ToggleAsset.Layout, Window, Colorpicker)
					return Colorpicker
				end
				return Toggle
			end
			function Section:Slider(Slider)
				Slider = Bracket.Utilities:GetType(Slider, {}, "table", true)
				Slider.Name = Bracket.Utilities:GetType(Slider.Name, "Slider", "string")
				Slider.Flag = Bracket.Utilities:GetType(Slider.Flag, Slider.Name, "string")

				Slider.Min = Bracket.Utilities:GetType(Slider.Min, 0, "number")
				Slider.Max = Bracket.Utilities:GetType(Slider.Max, 100, "number")
				Slider.Precise = Bracket.Utilities:GetType(Slider.Precise, 0, "number")
				Slider.Unit = Bracket.Utilities:GetType(Slider.Unit, "", "string")
				Slider.Value = Bracket.Utilities:GetType(Slider.Value, Slider.Max / 2, "number")
				Slider.Callback = Bracket.Utilities:GetType(Slider.Callback, function() end, "function")
				Window.Elements[#Window.Elements + 1] = Slider
				Window.Flags[Slider.Flag] = Slider.Value

				Bracket.Elements.Slider(SectionContainer, Window, Slider)
				return Slider
			end
			function Section:Textbox(Textbox)
				Textbox = Bracket.Utilities:GetType(Textbox, {}, "table", true)
				Textbox.Name = Bracket.Utilities:GetType(Textbox.Name, "Textbox", "string")
				Textbox.Flag = Bracket.Utilities:GetType(Textbox.Flag, Textbox.Name, "string")

				Textbox.Value = Bracket.Utilities:GetType(Textbox.Value, "", "string")
				Textbox.NumbersOnly = Bracket.Utilities:GetType(Textbox.NumbersOnly, false, "boolean")
				Textbox.Placeholder = Bracket.Utilities:GetType(Textbox.Placeholder, "Input here", "string")
				Textbox.Callback = Bracket.Utilities:GetType(Textbox.Callback, function() end, "function")
				Window.Elements[#Window.Elements + 1] = Textbox
				Window.Flags[Textbox.Flag] = Textbox.Value

				Bracket.Elements.Textbox(SectionContainer, Window, Textbox)
				return Textbox
			end
			function Section:Keybind(Keybind)
				Keybind = Bracket.Utilities:GetType(Keybind, {}, "table", true)
				Keybind.Name = Bracket.Utilities:GetType(Keybind.Name, "Keybind", "string")
				Keybind.Flag = Bracket.Utilities:GetType(Keybind.Flag, Keybind.Name, "string")

				Keybind.Value = Bracket.Utilities:GetType(Keybind.Value, "NONE", "string")
				Keybind.Mouse = Bracket.Utilities:GetType(Keybind.Mouse, false, "boolean")
				Keybind.Callback = Bracket.Utilities:GetType(Keybind.Callback, function() end, "function")
				Keybind.Blacklist = Bracket.Utilities:GetType(Keybind.Blacklist, {"W", "A", "S", "D", "Slash", "Tab", "Backspace", "Escape", "Space", "Delete", "Unknown", "Backquote"}, "table")
				Window.Elements[#Window.Elements + 1] = Keybind
				Window.Flags[Keybind.Flag] = Keybind.Value

				Bracket.Elements.Keybind(SectionContainer, Window, Keybind)
				return Keybind
			end
			function Section:Dropdown(Dropdown)
				Dropdown = Bracket.Utilities:GetType(Dropdown, {}, "table", true)
				Dropdown.Name = Bracket.Utilities:GetType(Dropdown.Name, "Dropdown", "string")
				Dropdown.Flag = Bracket.Utilities:GetType(Dropdown.Flag, Dropdown.Name, "string")
				Dropdown.List = Bracket.Utilities:GetType(Dropdown.List, {}, "table")
				Window.Elements[#Window.Elements + 1] = Dropdown
				Window.Flags[Dropdown.Flag] = Dropdown.Value

				Bracket.Elements.Dropdown(SectionContainer, Window, Dropdown)
				return Dropdown
			end
			function Section:Colorpicker(Colorpicker)
				Colorpicker = Bracket.Utilities:GetType(Colorpicker, {}, "table", true)
				Colorpicker.Name = Bracket.Utilities:GetType(Colorpicker.Name, "Colorpicker", "string")
				Colorpicker.Flag = Bracket.Utilities:GetType(Colorpicker.Flag, Colorpicker.Name, "string")

				Colorpicker.Value = Bracket.Utilities:GetType(Colorpicker.Value, {1, 1, 1, 0, false}, "table")
				Colorpicker.Callback = Bracket.Utilities:GetType(Colorpicker.Callback, function() end, "function")
				Window.Elements[#Window.Elements + 1] = Colorpicker
				Window.Flags[Colorpicker.Flag] = Colorpicker.Value

				Bracket.Elements.Colorpicker(SectionContainer, Window, Colorpicker)
				return Colorpicker
			end
			return Section
		end
		return Tab
	end
	return Window
end

function Bracket:Notification(Notification)
	Notification = Bracket.Utilities:GetType(Notification, {}, "table")

	local Style = Notification.Style
	if type(Style) == "string" then
		Style = Style:lower()
	end

	if Style == "toast" then
		return self:Toast(Notification)
	end

	if Style == "push" then
		return self:Push(Notification)
	end

	if Notification.Description ~= nil then
		return self:Push(Notification)
	end

	return self:Toast(Notification)
end

function Bracket:Push(Notification)
	Notification = Bracket.Utilities:GetType(Notification, {}, "table")
	Notification.Title = Bracket.Utilities:GetType(Notification.Title, "Title", "string")
	Notification.Description = Bracket.Utilities:GetType(Notification.Description, "Description", "string")

	local NotificationAsset = Bracket.Assets.PushNotification()
	NotificationAsset.Parent = Bracket.Screen.PNContainer
	NotificationAsset.Title.Text = Notification.Title
	NotificationAsset.Description.Text = Notification.Description
	NotificationAsset.Title.Size = UDim2.new(1, 0, 0,
        Bracket.Utilities.GetTextBounds(
            NotificationAsset.Title.Text,
            NotificationAsset.Title.Font.Name,
            Vector2.new(NotificationAsset.Title.AbsoluteSize.X, NotificationAsset.Title.TextSize)
        ).Y
    )
    NotificationAsset.Description.Size = UDim2.new(1, 0, 0,
        Bracket.Utilities.GetTextBounds(
            NotificationAsset.Description.Text,
            NotificationAsset.Description.Font.Name,
            Vector2.new(NotificationAsset.Description.AbsoluteSize.X, NotificationAsset.Description.TextSize)
        ).Y
    )

	NotificationAsset.Size = UDim2.fromOffset(
		(NotificationAsset.Title.TextBounds.X > NotificationAsset.Description.TextBounds.X
			and NotificationAsset.Title.TextBounds.X or NotificationAsset.Description.TextBounds.X) + 24,
		NotificationAsset.ListLayout.AbsoluteContentSize.Y + 8
	)

	if Notification.Duration then
		task.spawn(function()
			for Time = Notification.Duration, 1, -1 do
				NotificationAsset.Title.Close.Text = Time
				task.wait(1)
			end
			NotificationAsset.Title.Close.Text = 0

			NotificationAsset:Destroy()
			if Notification.Callback then
				Notification.Callback()
			end
		end)
	else
		NotificationAsset.Title.Close.MouseButton1Click:Connect(function()
			NotificationAsset:Destroy()
		end)
	end
end

function Bracket:Toast(Notification)
	Notification = Bracket.Utilities:GetType(Notification, {}, "table")
	Notification.Title = Bracket.Utilities:GetType(Notification.Title, "Title", "string")
	Notification.Duration = Bracket.Utilities:GetType(Notification.Duration, 5, "number")
	Notification.Color = Bracket.Utilities:GetType(Notification.Color, Color3.new(1, 0.5, 0.25), "Color3")

	local NotificationAsset = Bracket.Assets.ToastNotification()
	NotificationAsset.Parent = Bracket.Screen.TNContainer
	NotificationAsset.Main.Title.Text = Notification.Title
	NotificationAsset.Main.GradientLine.BackgroundColor3 = Notification.Color

	NotificationAsset.Main.Size = UDim2.fromOffset(
		NotificationAsset.Main.Title.TextBounds.X + 10,
        Bracket.Utilities.GetTextBounds(
            NotificationAsset.Main.Title.Text,
            NotificationAsset.Main.Title.Font.Name,
            Vector2.new(NotificationAsset.Main.Title.AbsoluteSize.X, NotificationAsset.Main.Title.TextSize)
        ).Y + 6
	)
	NotificationAsset.Size = UDim2.fromOffset(0,
		NotificationAsset.Main.Size.Y.Offset + 4
	)

	local function TweenSize(X, Y, Callback)
		NotificationAsset:TweenSize(
			UDim2.fromOffset(X, Y),
			Enum.EasingDirection.InOut,
			Enum.EasingStyle.Linear,
			0.25, false, Callback
		)
	end

	TweenSize(NotificationAsset.Main.Size.X.Offset + 4, NotificationAsset.Main.Size.Y.Offset + 4, function()
		task.wait(Notification.Duration) TweenSize(0, NotificationAsset.Main.Size.Y.Offset + 4, function()
			NotificationAsset:Destroy() if Notification.Callback then Notification.Callback() end
		end)
	end)
end

return Bracket
]=])()

-- ===== DRAWING/ESP MODULE =====
Sp3arParvus.Utilities.Drawing = loadstring([=[
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

repeat task.wait() until PlayerService.LocalPlayer
local LocalPlayer = PlayerService.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Declarations
local Cos = math.cos
local Rad = math.rad
local Sin = math.sin
local Tan = math.tan
local Abs = math.abs
local Deg = math.deg
local Max = math.max
local Atan2 = math.atan2
local Clamp = math.clamp
local Floor = math.floor

local WTVP = Camera.WorldToViewportPoint
local FindFirstChild = Workspace.FindFirstChild
local FindFirstChildOfClass = Workspace.FindFirstChildOfClass
local FindFirstChildWhichIsA = Workspace.FindFirstChildWhichIsA
local PointToObjectSpace = CFrame.identity.PointToObjectSpace

local UDimNew = UDim.new
local V2New = Vector2.new
local UDim2New = UDim2.new
local UDim2FromOffset = UDim2.fromOffset
local ColorNew = Color3.new
local RedColor = ColorNew(1, 0, 0)
local GreenColor = ColorNew(0, 1, 0)
local YellowColor = ColorNew(1, 1, 0)
local WhiteColor = ColorNew(1, 1, 1)
local BlackColor = ColorNew(0, 0, 0)
local LerpColor = BlackColor.Lerp
local Fonts = Drawing.Fonts

local DrawingLibrary = {
    ESP = {},--setmetatable({}, { __mode = "kv" }),
    ObjectESP = {},--setmetatable({}, { __mode = "kv" }),
    CharacterSize = Vector3.new(4, 5, 1),

    CS = ColorSequence.new({
        ColorSequenceKeypoint.new(0, RedColor),
        ColorSequenceKeypoint.new(0.5, YellowColor),
        ColorSequenceKeypoint.new(1, GreenColor)
    })
}

local function AddDrawing(Type, Properties)
    local DrawingObject = Drawing.new(Type)

    if Properties then
        for Property, Value in pairs(Properties) do
            DrawingObject[Property] = Value
        end
    end

    return DrawingObject
end
local function ClearDrawing(Table)
    for _, Value in pairs(Table) do
        if typeof(Value) == "table" then
            ClearDrawing(Value)
        else
            if isrenderobj and not isrenderobj(Value) then
                continue
            end
            pcall(function() Value:Destroy() end)
        end
    end
end

local function HideESPDrawings(ESP)
    if not ESP or not ESP.Drawing then return end

    local function HideContainer(Container)
        local ContainerType = typeof(Container)

        if ContainerType == "table" then
            if rawget(Container, "Visible") ~= nil then
                Container.Visible = false
            end

            if rawget(Container, "OutlineVisible") ~= nil then
                Container.OutlineVisible = false
            end

            for _, Value in pairs(Container) do
                HideContainer(Value)
            end

            return
        end

        if ContainerType == "userdata" then
            pcall(function()
                if Container.Visible ~= nil then
                    Container.Visible = false
                end
            end)
        end
    end

    HideContainer(ESP.Drawing)
end

-- Track error counts for ESP objects to clean up broken ones
local ESPErrorCounts = {}
local MAX_ESP_ERRORS = 3 -- Remove ESP after this many consecutive errors

-- Performance optimization tracking tables
local ESPUpdateAccumulators = {}
local ESPCleanupQueue = {}

-- Expose tracking tables so callers can inspect or reset them safely
DrawingLibrary.ESPErrorCounts = ESPErrorCounts
DrawingLibrary.ESPUpdateAccumulators = ESPUpdateAccumulators

function DrawingLibrary.ResetESPCounters(Self, Target)
    if not Target then return end
    ESPErrorCounts[Target] = nil
    ESPUpdateAccumulators[Target] = nil
end

function DrawingLibrary.ResetAllESPCounters(Self)
    table.clear(ESPErrorCounts)
    table.clear(ESPUpdateAccumulators)
    table.clear(ESPCleanupQueue)
end

function DrawingLibrary.HideAll(Self)
    for _, ESP in pairs(Self.ESP) do
        HideESPDrawings(ESP)
    end

    for _, ESP in pairs(Self.ObjectESP) do
        if ESP.Name then
            ESP.Name.Visible = false
        end
    end
end

local function GetFlag(Flags, Flag, Option)
    return Flags[Flag .. Option]
end
local function GetDistance(Position)
    return (Position - Camera.CFrame.Position).Magnitude
end
local CLOSE_ZONE_MAX = 5000
local MID_ZONE_MAX = 10000
local FAR_ZONE_MAX = 15000
local ZONE_COLORS = {
	Close = Color3.fromRGB(255, 0, 0),
	Mid = Color3.fromRGB(255, 140, 0),
	Far = Color3.fromRGB(0, 255, 0)
}
local function GetDistanceZone(distance)
	if not distance then
		return "Far", ZONE_COLORS.Far
	elseif distance <= CLOSE_ZONE_MAX then
		return "Close", ZONE_COLORS.Close
	elseif distance <= MID_ZONE_MAX then
		return "Mid", ZONE_COLORS.Mid
	elseif distance <= FAR_ZONE_MAX then
		return "Far", ZONE_COLORS.Far
	else
		return "OutOfRange", ZONE_COLORS.Far
	end
end
local function IsWithinReach(Enabled, Limit, Distance)
	-- Fixed 15000 stud range - always active, no exceptions
	return Distance <= FAR_ZONE_MAX
end
local function GetScaleFactor(Enabled, Size, Distance)
    if not Enabled then return Size end
    return Max(1, Size / (Distance * Tan(Rad(Camera.FieldOfView / 2)) * 10) * 1000)
end
--[[local function DynamicFOV(Enabled, FOV)
    if not Enabled then return FOV end
    --return FOV / (Camera.FieldOfView / 80)
    return FOV * (1 + (80 - Camera.FieldOfView) / 100)
end]]
local function AntiAliasingXY(X, Y)
    return V2New(Floor(X), Floor(Y))
end
local function AntiAliasingP(P)
    return V2New(Floor(P.X), Floor(P.Y))
end
local function WorldToScreen(WorldPosition)
    local Screen, OnScreen = WTVP(Camera, WorldPosition)
    return V2New(Screen.X, Screen.Y), OnScreen--, Screen.Z
end

-- evalCS by devforum guy
local function EvalHealth(Percent)
    local CS = DrawingLibrary.CS
    if Percent == 0 then return CS.Keypoints[1].Value end
    if Percent == 1 then return CS.Keypoints[#CS.Keypoints].Value end

    for Index = 1, #CS.Keypoints - 1 do
        local KIndex = CS.Keypoints[Index]
        local NIndex = CS.Keypoints[Index + 1]
        if Percent >= KIndex.Time and Percent < NIndex.Time then
            local Alpha = (Percent - KIndex.Time) / (NIndex.Time - KIndex.Time)
            return KIndex.Value:Lerp(NIndex.Value, Alpha)
        end
    end
end
-- CalculateBox by mickeyrbx (highly edited)
local function CalculateBoxSize(Model, Distance)
    local CharacterSize = Model:GetExtentsSize()
    local FrustumHeight = Tan(Rad(Camera.FieldOfView / 2)) * 2 * Distance
    local BoxSize = Camera.ViewportSize.Y / FrustumHeight * CharacterSize
    return AntiAliasingXY(BoxSize.X, BoxSize.Y)
end
-- Offscreen Arrows by Blissful
local function GetRelative(Position)
    local Relative = PointToObjectSpace(Camera.CFrame, Position)
    return V2New(-Relative.X, -Relative.Z)
end
local function RotateVector(Vector, Radians)
    local C, S = Cos(Radians), Sin(Radians)

    return V2New(
        Vector.X * C - Vector.Y * S,
        Vector.X * S + Vector.Y * C
    )
end
local function RelativeToCenter(Size)
    return Camera.ViewportSize / 2 - Size
end

--[[function HighlightNew(Target, Parent)
    local Highlight = Instance.new("Highlight")
    Highlight.Adornee = Target
    Highlight.Parent = Parent
    return Highlight
end]]
function GetCharacter(Target, Mode)
    if Mode == "Player" then
        local Character = Target.Character if not Character then return end
        return Character, FindFirstChild(Character, "HumanoidRootPart")
    else
        return Target, FindFirstChild(Target, "HumanoidRootPart")
    end
end
function GetHealth(Target, Character, Mode)
    local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
    if not Humanoid then return 100, 100, true end
    return Humanoid.Health, Humanoid.MaxHealth, Humanoid.Health > 0
end
function GetTeam(Target, Character, Mode)
    if Mode == "Player" then
        -- Safely check team with error handling
        local Success, IsEnemy, TeamColor = pcall(function()
            -- Check if player is neutral
            if Target.Neutral then
                return true, WhiteColor
            end

            -- Get teams and team color
            local LocalTeam = LocalPlayer.Team
            local TargetTeam = Target.Team
            local Color = WhiteColor

            -- Try to get team color
            if TargetTeam and TargetTeam.TeamColor then
                Color = TargetTeam.TeamColor.Color
            end

            -- Players on different teams or if either has no team
            local DifferentTeam = LocalTeam ~= TargetTeam

            return DifferentTeam, Color
        end)

        -- If error occurred, assume enemy for safety
        if not Success then
            return true, WhiteColor
        end

        return IsEnemy, TeamColor
    else
        return true, WhiteColor
    end
end
function GetWeapon(Target, Character, Mode)
    return "N/A"
end

if game.GameId == 1168263273 or game.GameId == 3360073263 then -- Bad Business
    DrawingLibrary.CharacterSize = Vector3.new(2.05, 7.3, 1.35)
    local TeamService = game:GetService("Teams")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- Safely get Tortoiseshell and Characters with error handling
    local Tortoiseshell, Characters = nil, {}

    if getupvalue and ReplicatedStorage:FindFirstChild("TS") then
        local Success, TortoiseResult = pcall(function()
            return getupvalue(require(ReplicatedStorage.TS), 1)
        end)

        if Success and TortoiseResult then
            Tortoiseshell = TortoiseResult

            -- Try to get Characters table
            if Tortoiseshell.Characters and Tortoiseshell.Characters.GetCharacter then
                local CharSuccess, CharResult = pcall(function()
                    return getupvalue(Tortoiseshell.Characters.GetCharacter, 1)
                end)

                if CharSuccess and CharResult then
                    Characters = CharResult
                end
            end
        end
    end

    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

    local function GetPlayerTeam(Player)
        for Index, Team in pairs(TeamService:GetChildren()) do
            if FindFirstChild(Team.Players, Player.Name) then
                return Team.Name
            end
        end
    end
    --[[local function FindHighlightForCharacter(Character)
        for Index, Highlight in pairs(PlayerGui:GetChildren()) do
            if not Highlight:IsA("Highlight") then continue end
            if Highlight.Adornee == Character then
                return Highlight
            end
        end
    end]]

    --[[function HighlightNew(Target, Parent)
        local Character = Characters[Target]
        return FindHighlightForCharacter(Character)
    end]]
    function GetCharacter(Target, Mode)
        if not Characters then return end
        local Character = Characters[Target]
        if not Character or Character.Parent == nil then return end
        --DrawingLibrary.ESP[Target].Highlight = FindHighlightForCharacter(Character)
        return Character, Character.PrimaryPart
    end
    function GetHealth(Target, Character, Mode)
        local Success, Health = pcall(function()
            return Character.Health
        end)

        if not Success or not Health then
            return 100, 100, true
        end

        return Health.Value, Health.MaxHealth.Value, Health.Value > 0
    end
    function GetTeam(Target, Character, Mode)
        local Team, LocalTeam = GetPlayerTeam(Target), GetPlayerTeam(LocalPlayer)
        local TeamColor = WhiteColor

        if Tortoiseshell and Tortoiseshell.Teams and Tortoiseshell.Teams.Colors and Team then
            TeamColor = Tortoiseshell.Teams.Colors[Team] or WhiteColor
        end

        return LocalTeam ~= Team or Team == "FFA", TeamColor
    end
    function GetWeapon(Target, Character, Mode)
        local Success, Weapon = pcall(function()
            return tostring(Character.Backpack.Equipped.Value or "Hands")
        end)

        return Success and Weapon or "Hands"
    end
elseif game.GameId == 358276974 or game.GameId == 3495983524 then -- Apocalypse Rising 2
    function GetHealth(Target, Character, Mode)
        local Success, Health, Bonus = pcall(function()
            return Target.Stats.Health, Target.Stats.HealthBonus
        end)

        if not Success or not Health then
            return 100, 100, true
        end

        return Health.Value + Bonus.Value,
        100 + Bonus.Value, Health.Value > 0
    end

    function GetWeapon(Target, Character, Mode)
        local Success, Result = pcall(function()
            local Equipped = Character.Equipped:GetChildren()
            return Equipped[1] and Equipped[1].Name or "Hands"
        end)

        return Success and Result or "Hands"
    end

    function GetTeam(Target, Character, Mode)
        if Mode ~= "Player" then
            return true, WhiteColor
        end

        -- AR2 uses a squad system, not standard Roblox teams
        -- Check if both players have squad data
        local Success, LocalSquad, TargetSquad = pcall(function()
            local LocalSquadData = LocalPlayer:FindFirstChild("Squad")
            local TargetSquadData = Target:FindFirstChild("Squad")
            return LocalSquadData, TargetSquadData
        end)

        if not Success then
            -- If we can't determine squads, treat as enemy for safety
            return true, WhiteColor
        end

        -- If either player has no squad, they're solo (treat as enemy)
        if not LocalSquad or not TargetSquad then
            return true, WhiteColor
        end

        -- Check if squad values match
        local SameSquad = LocalSquad.Value == TargetSquad.Value and LocalSquad.Value ~= nil

        -- Return true if different squads (is enemy), false if same squad (is ally)
        return not SameSquad, WhiteColor
    end
elseif game.GameId == 1054526971 then -- Blackhawk Rescue Mission 5
    local function RequireModule(Name)
        if not getmodules then return nil end

        local Success, Result = pcall(function()
            for Index, Instance in pairs(getmodules()) do
                if Instance.Name == Name then
                    return require(Instance)
                end
            end
        end)

        return Success and Result or nil
    end

    -- Wait for RoundInterface with timeout
    local RoundInterface = nil
    local TimeoutSeconds = 30
    local StartTime = tick()

    while not RoundInterface and (tick() - StartTime) < TimeoutSeconds do
        RoundInterface = RequireModule("RoundInterface")
        if not RoundInterface then
            task.wait(0.5)
        end
    end

    if not RoundInterface then
        warn("[Sp3arParvus] BRM5: Failed to load RoundInterface module after " .. TimeoutSeconds .. " seconds")
    end

    local function GetSkirmishTeam(Player)
        if not RoundInterface or not RoundInterface.Teams then return nil end

        local Success, Result = pcall(function()
            for TeamName, TeamData in pairs(RoundInterface.Teams) do
                for UserId, UserData in pairs(TeamData.Players) do
                    if tonumber(UserId) == Player.UserId then
                        return TeamName
                    end
                end
            end
        end)

        return Success and Result or nil
    end
    function GetTeam(Target, Character, Mode)
        if Mode == "Player" then
            local Success, IsEnemy = pcall(function()
                return not Target.Neutral and LocalPlayer.Team ~= Target.Team
                or GetSkirmishTeam(LocalPlayer) ~= GetSkirmishTeam(Target)
            end)

            return Success and IsEnemy or true, WhiteColor
        else
            local Success, IsEnemy = pcall(function()
                return not FindFirstChildWhichIsA(Character, "ProximityPrompt", true)
            end)

            return Success and IsEnemy or true, WhiteColor
        end
    end
elseif game.GameId == 580765040 then -- RAGDOLL UNIVERSE
    function GetCharacter(Target, Mode)
        local Character = Target.Character
        if not Character then return end
        return Character, Character.PrimaryPart
    end
    function GetTeam(Target, Character, Mode)
        local LocalCharacter = LocalPlayer.Character
        if not LocalCharacter then return false, Character.PrimaryPart.Color end
        if FindFirstChild(LocalCharacter, "Team") and FindFirstChild(Character, "Team") then
            return Character.Team.Value ~= LocalCharacter.Team.Value
            or Character.Team.Value == "None", Character.PrimaryPart.Color
        end

        return false, Character.PrimaryPart.Color
    end
    function GetWeapon(Target, Character, Mode)
        return tostring(FindFirstChildOfClass(Character, "Tool") or "Hands")
    end
elseif game.GameId == 1586272220 then -- Steel Titans
    local function GetPlayerTank(Player)
        local Character = FindFirstChild(Player, "Char")
        if not Character then return end
        if Character.Value == nil then return end
        return Character.Value.Parent.Parent.Parent
    end

    function GetCharacter(Target, Mode)
        local PlayerTank = GetPlayerTank(Target)
        if not PlayerTank then return end
        return PlayerTank, PlayerTank.PrimaryPart
    end
    function GetHealth(Target, Character, Mode)
        return Character.Stats.Health.Value,
        Character.Stats.Health.Orig.Value,
        Character.Stats.Health.Value > 0
    end
end

function DrawingLibrary.Update(ESP, Target)
    local Textboxes = ESP.Drawing.Textboxes
    local Mode, Flag, Flags = ESP.Mode, ESP.Flag, ESP.Flags

    local enabledFlag = GetFlag(Flags, Flag, "/Enabled")
    if enabledFlag == false then
        HideESPDrawings(ESP)
        return
    end

    local Character, RootPart = nil, nil
    local ScreenPosition, OnScreen = Vector2.zero, false
    local Distance, InTheRange, BoxTooSmall = 0, false, false
    local Health, MaxHealth, IsAlive = 100, 100, false
    local InEnemyTeam, TeamColor = true, WhiteColor
    local Color = WhiteColor
    local ZoneName, ZoneColor = "OutOfRange", ZONE_COLORS.Far

    Character, RootPart = GetCharacter(Target, Mode)
    if Character and RootPart then
        ScreenPosition, OnScreen = WorldToScreen(RootPart.Position)

        if OnScreen then
            Distance = GetDistance(RootPart.Position)
            ZoneName, ZoneColor = GetDistanceZone(Distance)
            ESP.CurrentZone = ZoneName
            ESP.ZoneColor = ZoneColor
            InTheRange = IsWithinReach(GetFlag(Flags, Flag, "/DistanceCheck"), GetFlag(Flags, Flag, "/Distance"), Distance)

            if InTheRange then
                Health, MaxHealth, IsAlive = GetHealth(Target, Character, Mode)
                InEnemyTeam, TeamColor = GetTeam(Target, Character, Mode)
                Color = GetFlag(Flags, Flag, "/TeamColor") and TeamColor
                or (InEnemyTeam and GetFlag(Flags, Flag, "/Enemy")[6]
                or GetFlag(Flags, Flag, "/Ally")[6])

                -- if ESP.Highlight and ESP.Highlight.Enabled then
                --     local OutlineColor = GetFlag(Flags, Flag, "/Highlight/OutlineColor")
                --     ESP.Highlight.DepthMode = GetFlag(Flags, Flag, "/Highlight/Occluded")
                --     and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
                --     --ESP.Highlight.Adornee = Character
                --     ESP.Highlight.FillColor = Color
                --     ESP.Highlight.OutlineColor = OutlineColor[6]
                --     ESP.Highlight.OutlineTransparency = OutlineColor[4]
                --     ESP.Highlight.FillTransparency = GetFlag(Flags, Flag, "/Highlight/Transparency")
                -- end

                if ESP.Drawing.Tracer.Main.Visible or ESP.Drawing.HeadDot.Main.Visible then
                    local Head = FindFirstChild(Character, "Head", true)

                    if Head then
                        local HeadPosition = WorldToScreen(Head.Position)

                        if ESP.Drawing.Tracer.Main.Visible then
                            local FromPosition = GetFlag(Flags, Flag, "/Tracer/Mode")
                            local Thickness = GetFlag(Flags, Flag, "/Tracer/Thickness")
                            local Transparency = 1 - GetFlag(Flags, Flag, "/Tracer/Transparency")
                            FromPosition = (FromPosition[1] == "From Mouse" and UserInputService:GetMouseLocation())
                            or (FromPosition[1] == "From Bottom" and V2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y))

                            local TracerColor = ZoneColor or Color
                            ESP.Drawing.Tracer.Main.Color = TracerColor
                            ESP.Drawing.Tracer.Outline.Color = TracerColor

                            ESP.Drawing.Tracer.Main.Thickness = Thickness
                            ESP.Drawing.Tracer.Outline.Thickness = Thickness + 2

                            ESP.Drawing.Tracer.Main.Transparency = Transparency
                            ESP.Drawing.Tracer.Outline.Transparency = Transparency

                            ESP.Drawing.Tracer.Main.From = FromPosition
                            ESP.Drawing.Tracer.Outline.From = FromPosition

                            ESP.Drawing.Tracer.Main.To = HeadPosition
                            ESP.Drawing.Tracer.Outline.To = HeadPosition
                        end
                        if ESP.Drawing.HeadDot.Main.Visible then
                            local Filled = GetFlag(Flags, Flag, "/HeadDot/Filled")
                            local Radius = GetFlag(Flags, Flag, "/HeadDot/Radius")
                            local NumSides = GetFlag(Flags, Flag, "/HeadDot/NumSides")
                            local Thickness = GetFlag(Flags, Flag, "/HeadDot/Thickness")
                            local Autoscale = GetFlag(Flags, Flag, "/HeadDot/Autoscale")
                            local Transparency = 1 - GetFlag(Flags, Flag, "/HeadDot/Transparency")
                            Radius = GetScaleFactor(Autoscale, Radius, Distance)

                            ESP.Drawing.HeadDot.Main.Color = Color

                            ESP.Drawing.HeadDot.Main.Transparency = Transparency
                            ESP.Drawing.HeadDot.Outline.Transparency = Transparency

                            ESP.Drawing.HeadDot.Main.NumSides = NumSides
                            ESP.Drawing.HeadDot.Outline.NumSides = NumSides

                            ESP.Drawing.HeadDot.Main.Radius = Radius
                            ESP.Drawing.HeadDot.Outline.Radius = Radius

                            ESP.Drawing.HeadDot.Main.Thickness = Thickness
                            ESP.Drawing.HeadDot.Outline.Thickness = Thickness + 2

                            ESP.Drawing.HeadDot.Main.Filled = Filled

                            ESP.Drawing.HeadDot.Main.Position = HeadPosition
                            ESP.Drawing.HeadDot.Outline.Position = HeadPosition
                        end
                    end
                end
                if ESP.Drawing.Box.Visible then
                    local BoxSize = CalculateBoxSize(Character, Distance)
                    local HealthPercent = Health / MaxHealth
                    BoxTooSmall = BoxSize.Y < 18

                    local Transparency = 1 - GetFlag(Flags, Flag, "/Box/Transparency")
                    local CornerSize = GetFlag(Flags, Flag, "/Box/CornerSize")
                    local Thickness = GetFlag(Flags, Flag, "/Box/Thickness")
                    local Filled = GetFlag(Flags, Flag, "/Box/Filled")

                    local ThicknessAdjust = Floor(Thickness / 2)
                    CornerSize = V2New(
                        (BoxSize.X / 2) * (CornerSize / 100),
                        (BoxSize.Y / 2) * (CornerSize / 100)
                    )

                    local From = AntiAliasingXY(
                        ScreenPosition.X - (BoxSize.X / 2),
                        ScreenPosition.Y - (BoxSize.Y / 2)
                    )
                    local To = AntiAliasingXY(
                        ScreenPosition.X - (BoxSize.X / 2),
                        (ScreenPosition.Y - (BoxSize.Y / 2)) + CornerSize.Y
                    )

                    ESP.Drawing.Box.LineLT.Main.Color = Color
                    ESP.Drawing.Box.LineLT.Main.Thickness = Thickness
                    ESP.Drawing.Box.LineLT.Outline.Thickness = Thickness + 2
                    ESP.Drawing.Box.LineLT.Main.Transparency = Transparency
                    ESP.Drawing.Box.LineLT.Outline.Transparency = Transparency
                    ESP.Drawing.Box.LineLT.Main.From = From - V2New(0, ThicknessAdjust)
                    ESP.Drawing.Box.LineLT.Outline.From = From - V2New(0, ThicknessAdjust + 1)
                    ESP.Drawing.Box.LineLT.Main.To = To
                    ESP.Drawing.Box.LineLT.Outline.To = To + V2New(0, 1)

                    From = AntiAliasingXY(
                        ScreenPosition.X - (BoxSize.X / 2),
                        ScreenPosition.Y - (BoxSize.Y / 2)
                    )
                    To = AntiAliasingXY(
                        (ScreenPosition.X - (BoxSize.X / 2)) + CornerSize.X,
                        ScreenPosition.Y - (BoxSize.Y / 2)
                    )

                    ESP.Drawing.Box.LineTL.Main.Color = Color
                    ESP.Drawing.Box.LineTL.Main.Thickness = Thickness
                    ESP.Drawing.Box.LineTL.Outline.Thickness = Thickness + 2
                    ESP.Drawing.Box.LineTL.Main.Transparency = Transparency
                    ESP.Drawing.Box.LineTL.Outline.Transparency = Transparency
                    ESP.Drawing.Box.LineTL.Main.From = From - V2New(ThicknessAdjust, 0)
                    ESP.Drawing.Box.LineTL.Outline.From = From - V2New(ThicknessAdjust + 1, 0)
                    ESP.Drawing.Box.LineTL.Main.To = To
                    ESP.Drawing.Box.LineTL.Outline.To = To + V2New(1, 0)

                    From = AntiAliasingXY(
                        ScreenPosition.X - (BoxSize.X / 2),
                        ScreenPosition.Y + (BoxSize.Y / 2)
                    )
                    To = AntiAliasingXY(
                        ScreenPosition.X - (BoxSize.X / 2),
                        (ScreenPosition.Y + (BoxSize.Y / 2)) - CornerSize.Y
                    )

                    ESP.Drawing.Box.LineLB.Main.Color = Color
                    ESP.Drawing.Box.LineLB.Main.Thickness = Thickness
                    ESP.Drawing.Box.LineLB.Outline.Thickness = Thickness + 2
                    ESP.Drawing.Box.LineLB.Main.Transparency = Transparency
                    ESP.Drawing.Box.LineLB.Outline.Transparency = Transparency
                    ESP.Drawing.Box.LineLB.Main.From = From + V2New(0, ThicknessAdjust)
                    ESP.Drawing.Box.LineLB.Outline.From = From + V2New(0, ThicknessAdjust + 1)
                    ESP.Drawing.Box.LineLB.Main.To = To
                    ESP.Drawing.Box.LineLB.Outline.To = To - V2New(0, 1)

                    From = AntiAliasingXY(
                        ScreenPosition.X - (BoxSize.X / 2),
                        ScreenPosition.Y + (BoxSize.Y / 2)
                    )
                    To = AntiAliasingXY(
                        (ScreenPosition.X - (BoxSize.X / 2)) + CornerSize.X,
                        ScreenPosition.Y + (BoxSize.Y / 2)
                    )

                    ESP.Drawing.Box.LineBL.Main.Color = Color
                    ESP.Drawing.Box.LineBL.Main.Thickness = Thickness
                    ESP.Drawing.Box.LineBL.Main.Transparency = Transparency
                    ESP.Drawing.Box.LineBL.Outline.Thickness = Thickness + 2
                    ESP.Drawing.Box.LineBL.Outline.Transparency = Transparency
                    ESP.Drawing.Box.LineBL.Main.From = From - V2New(ThicknessAdjust, 1)
                    ESP.Drawing.Box.LineBL.Outline.From = From - V2New(ThicknessAdjust + 1, 1)
                    ESP.Drawing.Box.LineBL.Main.To = To - V2New(0, 1)
                    ESP.Drawing.Box.LineBL.Outline.To = To - V2New(-1, 1)

                    From = AntiAliasingXY(
                        ScreenPosition.X + (BoxSize.X / 2),
                        ScreenPosition.Y - (BoxSize.Y / 2)
                    )
                    To = AntiAliasingXY(
                        ScreenPosition.X + (BoxSize.X / 2),
                        (ScreenPosition.Y - (BoxSize.Y / 2)) + CornerSize.Y
                    )

                    ESP.Drawing.Box.LineRT.Main.Color = Color
                    ESP.Drawing.Box.LineRT.Main.Thickness = Thickness
                    ESP.Drawing.Box.LineRT.Outline.Thickness = Thickness + 2
                    ESP.Drawing.Box.LineRT.Main.Transparency = Transparency
                    ESP.Drawing.Box.LineRT.Outline.Transparency = Transparency
                    ESP.Drawing.Box.LineRT.Main.From = From - V2New(1, ThicknessAdjust)
                    ESP.Drawing.Box.LineRT.Outline.From = From - V2New(1, ThicknessAdjust + 1)
                    ESP.Drawing.Box.LineRT.Main.To = To - V2New(1, 0)
                    ESP.Drawing.Box.LineRT.Outline.To = To + V2New(-1, 1)

                    From = AntiAliasingXY(
                        ScreenPosition.X + (BoxSize.X / 2),
                        ScreenPosition.Y - (BoxSize.Y / 2)
                    )
                    To = AntiAliasingXY(
                        (ScreenPosition.X + (BoxSize.X / 2)) - CornerSize.X,
                        ScreenPosition.Y - (BoxSize.Y / 2)
                    )

                    ESP.Drawing.Box.LineTR.Main.Color = Color
                    ESP.Drawing.Box.LineTR.Main.Thickness = Thickness
                    ESP.Drawing.Box.LineTR.Outline.Thickness = Thickness + 2
                    ESP.Drawing.Box.LineTR.Main.Transparency = Transparency
                    ESP.Drawing.Box.LineTR.Outline.Transparency = Transparency
                    ESP.Drawing.Box.LineTR.Main.From = From + V2New(ThicknessAdjust, 0)
                    ESP.Drawing.Box.LineTR.Outline.From = From + V2New(ThicknessAdjust + 1, 0)
                    ESP.Drawing.Box.LineTR.Main.To = To
                    ESP.Drawing.Box.LineTR.Outline.To = To - V2New(1, 0)

                    From = AntiAliasingXY(
                        ScreenPosition.X + (BoxSize.X / 2),
                        ScreenPosition.Y + (BoxSize.Y / 2)
                    )
                    To = AntiAliasingXY(
                        ScreenPosition.X + (BoxSize.X / 2),
                        (ScreenPosition.Y + (BoxSize.Y / 2)) - CornerSize.Y
                    )

                    ESP.Drawing.Box.LineRB.Main.Color = Color
                    ESP.Drawing.Box.LineRB.Main.Thickness = Thickness
                    ESP.Drawing.Box.LineRB.Outline.Thickness = Thickness + 2
                    ESP.Drawing.Box.LineRB.Main.Transparency = Transparency
                    ESP.Drawing.Box.LineRB.Outline.Transparency = Transparency
                    ESP.Drawing.Box.LineRB.Main.From = From + V2New(-1, ThicknessAdjust)
                    ESP.Drawing.Box.LineRB.Outline.From = From + V2New(-1, ThicknessAdjust + 1)
                    ESP.Drawing.Box.LineRB.Main.To = To - V2New(1, 0)
                    ESP.Drawing.Box.LineRB.Outline.To = To - V2New(1, 1)

                    From = AntiAliasingXY(
                        ScreenPosition.X + (BoxSize.X / 2),
                        ScreenPosition.Y + (BoxSize.Y / 2)
                    )
                    To = AntiAliasingXY(
                        (ScreenPosition.X + (BoxSize.X / 2)) - CornerSize.X,
                        ScreenPosition.Y + (BoxSize.Y / 2)
                    )

                    ESP.Drawing.Box.LineBR.Main.Color = Color
                    ESP.Drawing.Box.LineBR.Main.Thickness = Thickness
                    ESP.Drawing.Box.LineBR.Outline.Thickness = Thickness + 2
                    ESP.Drawing.Box.LineBR.Main.Transparency = Transparency
                    ESP.Drawing.Box.LineBR.Outline.Transparency = Transparency
                    ESP.Drawing.Box.LineBR.Main.From = From + V2New(ThicknessAdjust, -1)
                    ESP.Drawing.Box.LineBR.Outline.From = From + V2New(ThicknessAdjust + 1, -1)
                    ESP.Drawing.Box.LineBR.Main.To = To - V2New(0, 1)
                    ESP.Drawing.Box.LineBR.Outline.To = To - V2New(1, 1)

                    if ESP.Drawing.HealthBar.Main.Visible then
                        ESP.Drawing.HealthBar.Main.Color = EvalHealth(HealthPercent)
                        ESP.Drawing.HealthBar.Main.Transparency = Transparency
                        ESP.Drawing.HealthBar.Outline.Transparency = Transparency

                        ESP.Drawing.HealthBar.Outline.Size = AntiAliasingXY(Thickness + 2, BoxSize.Y + (Thickness + 1))
                        ESP.Drawing.HealthBar.Outline.Position = AntiAliasingXY(
                            (ScreenPosition.X - (BoxSize.X / 2)) - Thickness - ThicknessAdjust - 4,
                            ScreenPosition.Y - (BoxSize.Y / 2) - ThicknessAdjust - 1
                        )
                        ESP.Drawing.HealthBar.Main.Size = V2New(ESP.Drawing.HealthBar.Outline.Size.X - 2, -HealthPercent * (ESP.Drawing.HealthBar.Outline.Size.Y - 2))
                        ESP.Drawing.HealthBar.Main.Position = ESP.Drawing.HealthBar.Outline.Position + V2New(1, ESP.Drawing.HealthBar.Outline.Size.Y - 1)
                    end

                    if Textboxes.Name.Visible
                    or Textboxes.Health.Visible
                    or Textboxes.Distance.Visible
                    or Textboxes.Weapon.Visible then
                        local Size = GetFlag(Flags, Flag, "/Name/Size")
                        local Autoscale = GetFlag(Flags, Flag, "/Name/Autoscale")
                        --local Font = GetFont(GetFlag(ESP.Flags, ESP.Flag, "/Name/Font")[1])
                        Autoscale = Floor(GetScaleFactor(Autoscale, Size, Distance))

                        Transparency = 1 - GetFlag(Flags, Flag, "/Name/Transparency")
                        Outline = GetFlag(Flags, Flag, "/Name/Outline")

                        if Textboxes.Name.Visible then
                            Textboxes.Name.Outline = Outline
                            --Textboxes.Name.Font = Font
                            Textboxes.Name.Transparency = Transparency
                            Textboxes.Name.Size = Autoscale
                            Textboxes.Name.Text = Mode == "Player" and Target.Name
                            or (InEnemyTeam and "Enemy NPC" or "Ally NPC")
                            Textboxes.Name.Color = ZoneColor or Color

                            Textboxes.Name.Position = AntiAliasingXY(
                                ScreenPosition.X,
                                ScreenPosition.Y - (BoxSize.Y / 2) - Textboxes.Name.TextBounds.Y - ThicknessAdjust - 2
                            )
                        end
                        if Textboxes.Health.Visible then
                            Textboxes.Health.Outline = Outline
                            --Textboxes.Health.Font = Font
                            Textboxes.Health.Transparency = Transparency
                            Textboxes.Health.Size = Autoscale
                            Textboxes.Health.Text = tostring(math.floor(HealthPercent * 100)) .. "%"

                            local HealthPositionX = ESP.Drawing.HealthBar.Main.Visible and ((ScreenPosition.X - (BoxSize.X / 2)) - Textboxes.Health.TextBounds.X - (Thickness + ThicknessAdjust + 5)) or ((ScreenPosition.X - (BoxSize.X / 2)) - Textboxes.Health.TextBounds.X - ThicknessAdjust - 2)
                            Textboxes.Health.Position = AntiAliasingXY(
                                HealthPositionX,
                                (ScreenPosition.Y - (BoxSize.Y / 2)) - ThicknessAdjust - 1
                            )

                            --ESP.Drawing.Test.Position = Textboxes.Health.Position
                            --ESP.Drawing.Test.Size = V2New(Textboxes.Health.TextBounds.X, Textboxes.Health.TextBounds.Y)
                        end
                        if Textboxes.Distance.Visible then
                            Textboxes.Distance.Outline = Outline
                            --Textboxes.Distance.Font = Font
                            Textboxes.Distance.Transparency = Transparency
                            Textboxes.Distance.Size = Autoscale
                            Textboxes.Distance.Text = tostring(math.floor(Distance)) .. " studs"

                            Textboxes.Distance.Position = AntiAliasingXY(
                                ScreenPosition.X,
                                (ScreenPosition.Y + (BoxSize.Y / 2)) + ThicknessAdjust + 2
                            )

                            --ESP.Drawing.Test.Position = Textboxes.Distance.Position
                            --ESP.Drawing.Test.Size = V2New(Textboxes.Distance.TextBounds.X, Textboxes.Distance.TextBounds.Y)
                        end
                        if Textboxes.Weapon.Visible then
                            local Weapon = GetWeapon(Target, Character, Mode)

                            Textboxes.Weapon.Outline = Outline
                            --Textboxes.Weapon.Font = Font
                            Textboxes.Weapon.Transparency = Transparency
                            Textboxes.Weapon.Size = Autoscale
                            Textboxes.Weapon.Text = Weapon

                            Textboxes.Weapon.Position = AntiAliasingXY(
                                (ScreenPosition.X + (BoxSize.X / 2)) + ThicknessAdjust + 2,
                                ScreenPosition.Y - (BoxSize.Y / 2) - ThicknessAdjust - 1
                            )

                            --ESP.Drawing.Test.Position = Textboxes.Weapon.Position
                            --ESP.Drawing.Test.Size = V2New(Textboxes.Weapon.TextBounds.X, Textboxes.Weapon.TextBounds.Y)
                        end
                    end
                end
            end
        else
            if ESP.Drawing.Arrow.Main.Visible then
                Distance = GetDistance(RootPart.Position)
                InTheRange = IsWithinReach(GetFlag(Flags, Flag, "/DistanceCheck"), GetFlag(Flags, Flag, "/Distance"), Distance)
                Health, MaxHealth, IsAlive = GetHealth(Target, Character, Mode)
                InEnemyTeam, TeamColor = GetTeam(Target, Character, Mode)
                Color = GetFlag(Flags, Flag, "/TeamColor") and TeamColor
                or (InEnemyTeam and GetFlag(Flags, Flag, "/Enemy")[6]
                or GetFlag(Flags, Flag, "/Ally")[6])

                local Direction = GetRelative(RootPart.Position).Unit
                local SideLength = GetFlag(Flags, Flag, "/Arrow/Width") / 2
                local ArrowRadius = GetFlag(Flags, Flag, "/Arrow/Radius")
                local Base, Radians90 = Direction * ArrowRadius, Rad(90)

                local PointA = RelativeToCenter(Base + RotateVector(Direction, Radians90) * SideLength)
                local PointB = RelativeToCenter(Direction * (ArrowRadius + GetFlag(Flags, Flag, "/Arrow/Height")))
                local PointC = RelativeToCenter(Base + RotateVector(Direction, -Radians90) * SideLength)

                local Filled = GetFlag(Flags, Flag, "/Arrow/Filled")
                local Thickness = GetFlag(Flags, Flag, "/Arrow/Thickness")
                local Transparency = 1 - GetFlag(Flags, Flag, "/Arrow/Transparency")

                ESP.Drawing.Arrow.Main.Color = Color

                ESP.Drawing.Arrow.Main.Filled = Filled

                ESP.Drawing.Arrow.Main.Thickness = Thickness
                ESP.Drawing.Arrow.Outline.Thickness = Thickness + 2

                ESP.Drawing.Arrow.Main.Transparency = Transparency
                ESP.Drawing.Arrow.Outline.Transparency = Transparency

                ESP.Drawing.Arrow.Main.PointA = PointA
                ESP.Drawing.Arrow.Outline.PointA = PointA
                ESP.Drawing.Arrow.Main.PointB = PointB
                ESP.Drawing.Arrow.Outline.PointB = PointB
                ESP.Drawing.Arrow.Main.PointC = PointC
                ESP.Drawing.Arrow.Outline.PointC = PointC
            end
        end
    end

    -- Simplified team check: show all if TeamCheck disabled, otherwise show only enemies
    local TeamCheck = not GetFlag(Flags, Flag, "/TeamCheck") or InEnemyTeam
    local Visible = RootPart and OnScreen and InTheRange and IsAlive and TeamCheck
    local ArrowVisible = RootPart and (not OnScreen) and InTheRange and IsAlive and TeamCheck

    -- if ESP.Highlight then
    --     ESP.Highlight.Enabled = Visible and GetFlag(Flags, Flag, "/Highlight/Enabled") or false
    -- end

    ESP.Drawing.Box.Visible = Visible and GetFlag(Flags, Flag, "/Box/Enabled") or false
    ESP.Drawing.Box.OutlineVisible = ESP.Drawing.Box.Visible and GetFlag(Flags, Flag, "/Box/Outline") or false

    for Index, Line in pairs(ESP.Drawing.Box) do
        if type(Line) ~= "table" then continue end
        Line.Main.Visible = ESP.Drawing.Box.Visible
        Line.Outline.Visible = ESP.Drawing.Box.OutlineVisible
    end

    ESP.Drawing.HealthBar.Main.Visible = ESP.Drawing.Box.Visible and GetFlag(Flags, Flag, "/Box/HealthBar") and not BoxTooSmall or false
    ESP.Drawing.HealthBar.Outline.Visible = ESP.Drawing.HealthBar.Main.Visible and GetFlag(Flags, Flag, "/Box/Outline") or false

    ESP.Drawing.Arrow.Main.Visible = ArrowVisible and GetFlag(Flags, Flag, "/Arrow/Enabled") or false
    ESP.Drawing.Arrow.Outline.Visible = GetFlag(Flags, Flag, "/Arrow/Outline") and ESP.Drawing.Arrow.Main.Visible or false

    ESP.Drawing.HeadDot.Main.Visible = Visible and GetFlag(Flags, Flag, "/HeadDot/Enabled") or false
    ESP.Drawing.HeadDot.Outline.Visible = GetFlag(Flags, Flag, "/HeadDot/Outline") and ESP.Drawing.HeadDot.Main.Visible or false

    ESP.Drawing.Tracer.Main.Visible = Visible and GetFlag(Flags, Flag, "/Tracer/Enabled") or false
    ESP.Drawing.Tracer.Outline.Visible = GetFlag(Flags, Flag, "/Tracer/Outline") and ESP.Drawing.Tracer.Main.Visible or false

    ESP.Drawing.Textboxes.Name.Visible = Visible and GetFlag(Flags, Flag, "/Name/Enabled") or false
    ESP.Drawing.Textboxes.Health.Visible = Visible and GetFlag(Flags, Flag, "/Health/Enabled") or false
    ESP.Drawing.Textboxes.Distance.Visible = Visible and GetFlag(Flags, Flag, "/Distance/Enabled") or false
    ESP.Drawing.Textboxes.Weapon.Visible = Visible and GetFlag(Flags, Flag, "/Weapon/Enabled") or false
end

--[[function DrawingLibrary.InitRender(Self, Target, Mode, Flag, Flags)
    local ESP = Self.ESP[Target]
    local Textboxes = ESP.Drawing.Textboxes

    local Character, RootPart = nil, nil
    local ScreenPosition, OnScreen = Vector2.zero, false
    local Distance, InTheRange, BoxTooSmall = 0, false, false
    local Health, MaxHealth, IsAlive = 100, 100, false
    local InEnemyTeam, TeamColor = true, WhiteColor
    local Color = WhiteColor

    return RunService.RenderStepped:Connect(function()
        debug.profilebegin("PARVUS_DRAWING")
        Character, RootPart = GetCharacter(Target, Mode)
        if Character and RootPart then
            ScreenPosition, OnScreen = WorldToScreen(RootPart.Position)

            if OnScreen then
                Distance = GetDistance(RootPart.Position)
                InTheRange = IsWithinReach(GetFlag(Flags, Flag, "/DistanceCheck"), GetFlag(Flags, Flag, "/Distance"), Distance)

                if InTheRange then
                    Health, MaxHealth, IsAlive = GetHealth(Target, Character, Mode)
                    InEnemyTeam, TeamColor = GetTeam(Target, Character, Mode)
                    Color = GetFlag(Flags, Flag, "/TeamColor") and TeamColor
                    or (InEnemyTeam and GetFlag(Flags, Flag, "/Enemy")[6]
                    or GetFlag(Flags, Flag, "/Ally")[6])

                    -- if ESP.Highlight and ESP.Highlight.Enabled then
                    --     local OutlineColor = GetFlag(Flags, Flag, "/Highlight/OutlineColor")
                    --     ESP.Highlight.DepthMode = GetFlag(Flags, Flag, "/Highlight/Occluded")
                    --     and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
                    --     --ESP.Highlight.Adornee = Character
                    --     ESP.Highlight.FillColor = Color
                    --     ESP.Highlight.OutlineColor = OutlineColor[6]
                    --     ESP.Highlight.OutlineTransparency = OutlineColor[4]
                    --     ESP.Highlight.FillTransparency = GetFlag(Flags, Flag, "/Highlight/Transparency")
                    -- end

                    if ESP.Drawing.Tracer.Main.Visible or ESP.Drawing.HeadDot.Main.Visible then
                        local Head = FindFirstChild(Character, "Head", true)

                        if Head then
                            local HeadPosition = WorldToScreen(Head.Position)

                            if ESP.Drawing.Tracer.Main.Visible then
                                local FromPosition = GetFlag(Flags, Flag, "/Tracer/Mode")
                                local Thickness = GetFlag(Flags, Flag, "/Tracer/Thickness")
                                local Transparency = 1 - GetFlag(Flags, Flag, "/Tracer/Transparency")
                                FromPosition = (FromPosition[1] == "From Mouse" and UserInputService:GetMouseLocation())
                                or (FromPosition[1] == "From Bottom" and V2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y))

                                ESP.Drawing.Tracer.Main.Color = Color

                                ESP.Drawing.Tracer.Main.Thickness = Thickness
                                ESP.Drawing.Tracer.Outline.Thickness = Thickness + 2

                                ESP.Drawing.Tracer.Main.Transparency = Transparency
                                ESP.Drawing.Tracer.Outline.Transparency = Transparency

                                ESP.Drawing.Tracer.Main.From = FromPosition
                                ESP.Drawing.Tracer.Outline.From = FromPosition

                                ESP.Drawing.Tracer.Main.To = HeadPosition
                                ESP.Drawing.Tracer.Outline.To = HeadPosition
                            end
                            if ESP.Drawing.HeadDot.Main.Visible then
                                local Filled = GetFlag(Flags, Flag, "/HeadDot/Filled")
                                local Radius = GetFlag(Flags, Flag, "/HeadDot/Radius")
                                local NumSides = GetFlag(Flags, Flag, "/HeadDot/NumSides")
                                local Thickness = GetFlag(Flags, Flag, "/HeadDot/Thickness")
                                local Autoscale = GetFlag(Flags, Flag, "/HeadDot/Autoscale")
                                local Transparency = 1 - GetFlag(Flags, Flag, "/HeadDot/Transparency")
                                Radius = GetScaleFactor(Autoscale, Radius, Distance)

                                ESP.Drawing.HeadDot.Main.Color = Color

                                ESP.Drawing.HeadDot.Main.Transparency = Transparency
                                ESP.Drawing.HeadDot.Outline.Transparency = Transparency

                                ESP.Drawing.HeadDot.Main.NumSides = NumSides
                                ESP.Drawing.HeadDot.Outline.NumSides = NumSides

                                ESP.Drawing.HeadDot.Main.Radius = Radius
                                ESP.Drawing.HeadDot.Outline.Radius = Radius

                                ESP.Drawing.HeadDot.Main.Thickness = Thickness
                                ESP.Drawing.HeadDot.Outline.Thickness = Thickness + 2

                                ESP.Drawing.HeadDot.Main.Filled = Filled

                                ESP.Drawing.HeadDot.Main.Position = HeadPosition
                                ESP.Drawing.HeadDot.Outline.Position = HeadPosition
                            end
                        end
                    end
                    if ESP.Drawing.Box.Visible then
                        local BoxSize = CalculateBoxSize(Character, Distance)
                        local HealthPercent = Health / MaxHealth
                        BoxTooSmall = BoxSize.Y < 18

                        local Transparency = 1 - GetFlag(Flags, Flag, "/Box/Transparency")
                        local CornerSize = GetFlag(Flags, Flag, "/Box/CornerSize")
                        local Thickness = GetFlag(Flags, Flag, "/Box/Thickness")
                        local Filled = GetFlag(Flags, Flag, "/Box/Filled")

                        local ThicknessAdjust = Floor(Thickness / 2)
                        CornerSize = V2New(
                            (BoxSize.X / 2) * (CornerSize / 100),
                            (BoxSize.Y / 2) * (CornerSize / 100)
                        )

                        local From = AntiAliasingXY(
                            ScreenPosition.X - (BoxSize.X / 2),
                            ScreenPosition.Y - (BoxSize.Y / 2)
                        )
                        local To = AntiAliasingXY(
                            ScreenPosition.X - (BoxSize.X / 2),
                            (ScreenPosition.Y - (BoxSize.Y / 2)) + CornerSize.Y
                        )

                        ESP.Drawing.Box.LineLT.Main.Color = Color
                        ESP.Drawing.Box.LineLT.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineLT.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineLT.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineLT.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineLT.Main.From = From - V2New(0, ThicknessAdjust)
                        ESP.Drawing.Box.LineLT.Outline.From = From - V2New(0, ThicknessAdjust + 1)
                        ESP.Drawing.Box.LineLT.Main.To = To
                        ESP.Drawing.Box.LineLT.Outline.To = To + V2New(0, 1)

                        From = AntiAliasingXY(
                            ScreenPosition.X - (BoxSize.X / 2),
                            ScreenPosition.Y - (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            (ScreenPosition.X - (BoxSize.X / 2)) + CornerSize.X,
                            ScreenPosition.Y - (BoxSize.Y / 2)
                        )

                        ESP.Drawing.Box.LineTL.Main.Color = Color
                        ESP.Drawing.Box.LineTL.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineTL.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineTL.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineTL.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineTL.Main.From = From - V2New(ThicknessAdjust, 0)
                        ESP.Drawing.Box.LineTL.Outline.From = From - V2New(ThicknessAdjust + 1, 0)
                        ESP.Drawing.Box.LineTL.Main.To = To
                        ESP.Drawing.Box.LineTL.Outline.To = To + V2New(1, 0)

                        From = AntiAliasingXY(
                            ScreenPosition.X - (BoxSize.X / 2),
                            ScreenPosition.Y + (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            ScreenPosition.X - (BoxSize.X / 2),
                            (ScreenPosition.Y + (BoxSize.Y / 2)) - CornerSize.Y
                        )

                        ESP.Drawing.Box.LineLB.Main.Color = Color
                        ESP.Drawing.Box.LineLB.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineLB.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineLB.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineLB.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineLB.Main.From = From + V2New(0, ThicknessAdjust)
                        ESP.Drawing.Box.LineLB.Outline.From = From + V2New(0, ThicknessAdjust + 1)
                        ESP.Drawing.Box.LineLB.Main.To = To
                        ESP.Drawing.Box.LineLB.Outline.To = To - V2New(0, 1)

                        From = AntiAliasingXY(
                            ScreenPosition.X - (BoxSize.X / 2),
                            ScreenPosition.Y + (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            (ScreenPosition.X - (BoxSize.X / 2)) + CornerSize.X,
                            ScreenPosition.Y + (BoxSize.Y / 2)
                        )

                        ESP.Drawing.Box.LineBL.Main.Color = Color
                        ESP.Drawing.Box.LineBL.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineBL.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineBL.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineBL.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineBL.Main.From = From - V2New(ThicknessAdjust, 1)
                        ESP.Drawing.Box.LineBL.Outline.From = From - V2New(ThicknessAdjust + 1, 1)
                        ESP.Drawing.Box.LineBL.Main.To = To - V2New(0, 1)
                        ESP.Drawing.Box.LineBL.Outline.To = To - V2New(-1, 1)

                        From = AntiAliasingXY(
                            ScreenPosition.X + (BoxSize.X / 2),
                            ScreenPosition.Y - (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            ScreenPosition.X + (BoxSize.X / 2),
                            (ScreenPosition.Y - (BoxSize.Y / 2)) + CornerSize.Y
                        )

                        ESP.Drawing.Box.LineRT.Main.Color = Color
                        ESP.Drawing.Box.LineRT.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineRT.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineRT.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineRT.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineRT.Main.From = From - V2New(1, ThicknessAdjust)
                        ESP.Drawing.Box.LineRT.Outline.From = From - V2New(1, ThicknessAdjust + 1)
                        ESP.Drawing.Box.LineRT.Main.To = To - V2New(1, 0)
                        ESP.Drawing.Box.LineRT.Outline.To = To + V2New(-1, 1)

                        From = AntiAliasingXY(
                            ScreenPosition.X + (BoxSize.X / 2),
                            ScreenPosition.Y - (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            (ScreenPosition.X + (BoxSize.X / 2)) - CornerSize.X,
                            ScreenPosition.Y - (BoxSize.Y / 2)
                        )

                        ESP.Drawing.Box.LineTR.Main.Color = Color
                        ESP.Drawing.Box.LineTR.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineTR.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineTR.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineTR.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineTR.Main.From = From + V2New(ThicknessAdjust, 0)
                        ESP.Drawing.Box.LineTR.Outline.From = From + V2New(ThicknessAdjust + 1, 0)
                        ESP.Drawing.Box.LineTR.Main.To = To
                        ESP.Drawing.Box.LineTR.Outline.To = To - V2New(1, 0)

                        From = AntiAliasingXY(
                            ScreenPosition.X + (BoxSize.X / 2),
                            ScreenPosition.Y + (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            ScreenPosition.X + (BoxSize.X / 2),
                            (ScreenPosition.Y + (BoxSize.Y / 2)) - CornerSize.Y
                        )

                        ESP.Drawing.Box.LineRB.Main.Color = Color
                        ESP.Drawing.Box.LineRB.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineRB.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineRB.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineRB.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineRB.Main.From = From + V2New(-1, ThicknessAdjust)
                        ESP.Drawing.Box.LineRB.Outline.From = From + V2New(-1, ThicknessAdjust + 1)
                        ESP.Drawing.Box.LineRB.Main.To = To - V2New(1, 0)
                        ESP.Drawing.Box.LineRB.Outline.To = To - V2New(1, 1)

                        From = AntiAliasingXY(
                            ScreenPosition.X + (BoxSize.X / 2),
                            ScreenPosition.Y + (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            (ScreenPosition.X + (BoxSize.X / 2)) - CornerSize.X,
                            ScreenPosition.Y + (BoxSize.Y / 2)
                        )

                        ESP.Drawing.Box.LineBR.Main.Color = Color
                        ESP.Drawing.Box.LineBR.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineBR.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineBR.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineBR.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineBR.Main.From = From + V2New(ThicknessAdjust, -1)
                        ESP.Drawing.Box.LineBR.Outline.From = From + V2New(ThicknessAdjust + 1, -1)
                        ESP.Drawing.Box.LineBR.Main.To = To - V2New(0, 1)
                        ESP.Drawing.Box.LineBR.Outline.To = To - V2New(1, 1)

                        if ESP.Drawing.HealthBar.Main.Visible then
                            ESP.Drawing.HealthBar.Main.Color = EvalHealth(HealthPercent)
                            ESP.Drawing.HealthBar.Main.Transparency = Transparency
                            ESP.Drawing.HealthBar.Outline.Transparency = Transparency

                            ESP.Drawing.HealthBar.Outline.Size = AntiAliasingXY(Thickness + 2, BoxSize.Y + (Thickness + 1))
                            ESP.Drawing.HealthBar.Outline.Position = AntiAliasingXY(
                                (ScreenPosition.X - (BoxSize.X / 2)) - Thickness - ThicknessAdjust - 4,
                                ScreenPosition.Y - (BoxSize.Y / 2) - ThicknessAdjust - 1
                            )
                            ESP.Drawing.HealthBar.Main.Size = V2New(ESP.Drawing.HealthBar.Outline.Size.X - 2, -HealthPercent * (ESP.Drawing.HealthBar.Outline.Size.Y - 2))
                            ESP.Drawing.HealthBar.Main.Position = ESP.Drawing.HealthBar.Outline.Position + V2New(1, ESP.Drawing.HealthBar.Outline.Size.Y - 1)
                        end

                        if Textboxes.Name.Visible
                        or Textboxes.Health.Visible
                        or Textboxes.Distance.Visible
                        or Textboxes.Weapon.Visible then
                            local Size = GetFlag(Flags, Flag, "/Name/Size")
                            local Autoscale = GetFlag(Flags, Flag, "/Name/Autoscale")
                            --local Font = GetFont(GetFlag(ESP.Flags, ESP.Flag, "/Name/Font")[1])
                            Autoscale = Floor(GetScaleFactor(Autoscale, Size, Distance))

                            Transparency = 1 - GetFlag(Flags, Flag, "/Name/Transparency")
                            Outline = GetFlag(Flags, Flag, "/Name/Outline")

                            if Textboxes.Name.Visible then
                                Textboxes.Name.Outline = Outline
                                --Textboxes.Name.Font = Font
                                Textboxes.Name.Transparency = Transparency
                                Textboxes.Name.Size = Autoscale
                                Textboxes.Name.Text = Mode == "Player" and Target.Name
                                or (InEnemyTeam and "Enemy NPC" or "Ally NPC")
                                Textboxes.Name.Color = ZoneColor or Color

                                Textboxes.Name.Position = AntiAliasingXY(
                                    ScreenPosition.X,
                                    ScreenPosition.Y - (BoxSize.Y / 2) - Textboxes.Name.TextBounds.Y - ThicknessAdjust - 2
                                )
                            end
                            if Textboxes.Health.Visible then
                                Textboxes.Health.Outline = Outline
                                --Textboxes.Health.Font = Font
                                Textboxes.Health.Transparency = Transparency
                                Textboxes.Health.Size = Autoscale
                                Textboxes.Health.Text = tostring(math.floor(HealthPercent * 100)) .. "%"

                                local HealthPositionX = ESP.Drawing.HealthBar.Main.Visible and ((ScreenPosition.X - (BoxSize.X / 2)) - Textboxes.Health.TextBounds.X - (Thickness + ThicknessAdjust + 5)) or ((ScreenPosition.X - (BoxSize.X / 2)) - Textboxes.Health.TextBounds.X - ThicknessAdjust - 2)
                                Textboxes.Health.Position = AntiAliasingXY(
                                    HealthPositionX,
                                    (ScreenPosition.Y - (BoxSize.Y / 2)) - ThicknessAdjust - 1
                                )

                                --ESP.Drawing.Test.Position = Textboxes.Health.Position
                                --ESP.Drawing.Test.Size = V2New(Textboxes.Health.TextBounds.X, Textboxes.Health.TextBounds.Y)
                            end
                            if Textboxes.Distance.Visible then
                                Textboxes.Distance.Outline = Outline
                                --Textboxes.Distance.Font = Font
                                Textboxes.Distance.Transparency = Transparency
                                Textboxes.Distance.Size = Autoscale
                                Textboxes.Distance.Text = tostring(math.floor(Distance)) .. " studs"

                                Textboxes.Distance.Position = AntiAliasingXY(
                                    ScreenPosition.X,
                                    (ScreenPosition.Y + (BoxSize.Y / 2)) + ThicknessAdjust + 2
                                )

                                --ESP.Drawing.Test.Position = Textboxes.Distance.Position
                                --ESP.Drawing.Test.Size = V2New(Textboxes.Distance.TextBounds.X, Textboxes.Distance.TextBounds.Y)
                            end
                            if Textboxes.Weapon.Visible then
                                local Weapon = GetWeapon(Target, Character, Mode)

                                Textboxes.Weapon.Outline = Outline
                                --Textboxes.Weapon.Font = Font
                                Textboxes.Weapon.Transparency = Transparency
                                Textboxes.Weapon.Size = Autoscale
                                Textboxes.Weapon.Text = Weapon

                                Textboxes.Weapon.Position = AntiAliasingXY(
                                    (ScreenPosition.X + (BoxSize.X / 2)) + ThicknessAdjust + 2,
                                    ScreenPosition.Y - (BoxSize.Y / 2) - ThicknessAdjust - 1
                                )

                                --ESP.Drawing.Test.Position = Textboxes.Weapon.Position
                                --ESP.Drawing.Test.Size = V2New(Textboxes.Weapon.TextBounds.X, Textboxes.Weapon.TextBounds.Y)
                            end
                        end
                    end
                end
            else
                if ESP.Drawing.Arrow.Main.Visible then
                    Distance = GetDistance(RootPart.Position)
                    InTheRange = IsWithinReach(GetFlag(Flags, Flag, "/DistanceCheck"), GetFlag(Flags, Flag, "/Distance"), Distance)
                    Health, MaxHealth, IsAlive = GetHealth(Target, Character, Mode)
                    InEnemyTeam, TeamColor = GetTeam(Target, Character, Mode)
                    Color = GetFlag(Flags, Flag, "/TeamColor") and TeamColor
                    or (InEnemyTeam and GetFlag(Flags, Flag, "/Enemy")[6]
                    or GetFlag(Flags, Flag, "/Ally")[6])

                    local Direction = GetRelative(RootPart.Position).Unit
                    local SideLength = GetFlag(Flags, Flag, "/Arrow/Width") / 2
                    local ArrowRadius = GetFlag(Flags, Flag, "/Arrow/Radius")
                    local Base, Radians90 = Direction * ArrowRadius, Rad(90)

                    local PointA = RelativeToCenter(Base + RotateVector(Direction, Radians90) * SideLength)
                    local PointB = RelativeToCenter(Direction * (ArrowRadius + GetFlag(Flags, Flag, "/Arrow/Height")))
                    local PointC = RelativeToCenter(Base + RotateVector(Direction, -Radians90) * SideLength)

                    local Filled = GetFlag(Flags, Flag, "/Arrow/Filled")
                    local Thickness = GetFlag(Flags, Flag, "/Arrow/Thickness")
                    local Transparency = 1 - GetFlag(Flags, Flag, "/Arrow/Transparency")

                    ESP.Drawing.Arrow.Main.Color = Color

                    ESP.Drawing.Arrow.Main.Filled = Filled

                    ESP.Drawing.Arrow.Main.Thickness = Thickness
                    ESP.Drawing.Arrow.Outline.Thickness = Thickness + 2

                    ESP.Drawing.Arrow.Main.Transparency = Transparency
                    ESP.Drawing.Arrow.Outline.Transparency = Transparency

                    ESP.Drawing.Arrow.Main.PointA = PointA
                    ESP.Drawing.Arrow.Outline.PointA = PointA
                    ESP.Drawing.Arrow.Main.PointB = PointB
                    ESP.Drawing.Arrow.Outline.PointB = PointB
                    ESP.Drawing.Arrow.Main.PointC = PointC
                    ESP.Drawing.Arrow.Outline.PointC = PointC
                end
            end
        end

        local TeamCheck = (not GetFlag(Flags, Flag, "/TeamCheck") and not InEnemyTeam) or InEnemyTeam
        local Visible = RootPart and OnScreen and InTheRange and IsAlive and TeamCheck
        local ArrowVisible = RootPart and (not OnScreen) and InTheRange and IsAlive and TeamCheck

        -- if ESP.Highlight then
        --     ESP.Highlight.Enabled = Visible and GetFlag(Flags, Flag, "/Highlight/Enabled") or false
        -- end

        ESP.Drawing.Box.Visible = Visible and GetFlag(Flags, Flag, "/Box/Enabled") or false
        ESP.Drawing.Box.OutlineVisible = ESP.Drawing.Box.Visible and GetFlag(Flags, Flag, "/Box/Outline") or false

        for Index, Line in pairs(ESP.Drawing.Box) do
            if type(Line) ~= "table" then continue end
            Line.Main.Visible = ESP.Drawing.Box.Visible
            Line.Outline.Visible = ESP.Drawing.Box.OutlineVisible
        end

        ESP.Drawing.HealthBar.Main.Visible = ESP.Drawing.Box.Visible and GetFlag(Flags, Flag, "/Box/HealthBar") and not BoxTooSmall or false
        ESP.Drawing.HealthBar.Outline.Visible = ESP.Drawing.HealthBar.Main.Visible and GetFlag(Flags, Flag, "/Box/Outline") or false

        ESP.Drawing.Arrow.Main.Visible = ArrowVisible and GetFlag(Flags, Flag, "/Arrow/Enabled") or false
        ESP.Drawing.Arrow.Outline.Visible = GetFlag(Flags, Flag, "/Arrow/Outline") and ESP.Drawing.Arrow.Main.Visible or false

        ESP.Drawing.HeadDot.Main.Visible = Visible and GetFlag(Flags, Flag, "/HeadDot/Enabled") or false
        ESP.Drawing.HeadDot.Outline.Visible = GetFlag(Flags, Flag, "/HeadDot/Outline") and ESP.Drawing.HeadDot.Main.Visible or false

        ESP.Drawing.Tracer.Main.Visible = Visible and GetFlag(Flags, Flag, "/Tracer/Enabled") or false
        ESP.Drawing.Tracer.Outline.Visible = GetFlag(Flags, Flag, "/Tracer/Outline") and ESP.Drawing.Tracer.Main.Visible or false

        ESP.Drawing.Textboxes.Name.Visible = Visible and GetFlag(Flags, Flag, "/Name/Enabled") or false
        ESP.Drawing.Textboxes.Health.Visible = Visible and GetFlag(Flags, Flag, "/Health/Enabled") or false
        ESP.Drawing.Textboxes.Distance.Visible = Visible and GetFlag(Flags, Flag, "/Distance/Enabled") or false
        ESP.Drawing.Textboxes.Weapon.Visible = Visible and GetFlag(Flags, Flag, "/Weapon/Enabled") or false

        debug.profileend()
    end)
end]]

function DrawingLibrary.AddObject(Self, Object, ObjectName, ObjectPosition, GlobalFlag, Flag, Flags)
    if Self.ObjectESP[Object] then return end

    Self.ObjectESP[Object] = {
        Target = {Name = ObjectName, Position = ObjectPosition},
        Flag = Flag, GlobalFlag = GlobalFlag, Flags = Flags,
        IsBasePart = typeof(ObjectPosition) ~= "Vector3",

        Name = AddDrawing("Text", { Visible = false, ZIndex = 0, Center = true, Outline = true, Color = WhiteColor, Font = Fonts.Plex })
    }

    if Self.ObjectESP[Object].IsBasePart then
        Self.ObjectESP[Object].Target.RootPart = ObjectPosition
        Self.ObjectESP[Object].Target.Position = ObjectPosition.Position
    end
end
function DrawingLibrary.AddESP(Self, Target, Mode, Flag, Flags)
    if Self.ESP[Target] then return end

    -- Things with Visible = false, ZIndex = 0 properties table can be removed
    Self.ESP[Target] = {
        Target = {}, Mode = Mode,
        Flag = Flag, Flags = Flags,
        Drawing = {
            Box = {
                Visible = false,
                OutlineVisible = false,
                LineLT = {
                    Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                    Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
                },
                LineTL = {
                    Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                    Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
                },
                LineLB = {
                    Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                    Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
                },
                LineBL = {
                    Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                    Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
                },
                LineRT = {
                    Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                    Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
                },
                LineTR = {
                    Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                    Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
                },
                LineRB = {
                    Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                    Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
                },
                LineBR = {
                    Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                    Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
                }
            },
            HealthBar = {
                Outline = AddDrawing("Square", { Visible = false, ZIndex = 0, Filled = true }),
                Main = AddDrawing("Square", { Visible = false, ZIndex = 1, Filled = true }),
            },
            Tracer = {
                Outline = AddDrawing("Line", { Visible = false, ZIndex = 0 }),
                Main = AddDrawing("Line", { Visible = false, ZIndex = 1 }),
            },
            HeadDot = {
                Outline = AddDrawing("Circle", { Visible = false, ZIndex = 0 }),
                Main = AddDrawing("Circle", { Visible = false, ZIndex = 1 }),
            },
            Arrow = {
                Outline = AddDrawing("Triangle", { Visible = false, ZIndex = 0 }),
                Main = AddDrawing("Triangle", { Visible = false, ZIndex = 1 }),
            },
            Textboxes = {
                Name = AddDrawing("Text", { Visible = false, ZIndex = 0, Center = true, Outline = true, Color = WhiteColor, Font = Fonts.Plex }),
                Distance = AddDrawing("Text", { Visible = false, ZIndex = 0, Center = true, Outline = true, Color = WhiteColor, Font = Fonts.Plex }),
                Health = AddDrawing("Text", { Visible = false, ZIndex = 0, Center = false, Outline = true, Color = WhiteColor, Font = Fonts.Plex }),
                Weapon = AddDrawing("Text", { Visible = false, ZIndex = 0, Center = false, Outline = true, Color = WhiteColor, Font = Fonts.Plex })
            },
            --Test = AddDrawing("Square", { Visible = true, ZIndex = -1, Filled = true })
        }
    }

    --Self.ESP[Target].Connection = Self:InitRender(Target, Mode, Flag, Flags)
    --Self.ESP[Target].Highlight = HighlightNew(Target, Self.ESP[Target].RESP)
end

function DrawingLibrary.RemoveESP(Self, Target)
    local ESP = Self.ESP[Target]
    if not ESP then return end

    -- Clean up drawing objects recursively
    pcall(function()
        ClearDrawing(ESP.Drawing)
    end)

    -- Remove from ESP table
    Self.ESP[Target] = nil

    -- Clean up tracking tables to prevent memory leaks
    Self:ResetESPCounters(Target)

    -- Clear any reference to the ESP object
    ESP = nil
end

function DrawingLibrary.RebuildESP(Self, Target, Mode, Flag, Flags)
    -- Remove existing ESP and create fresh one
    Self:RemoveESP(Target)
    Self:AddESP(Target, Mode, Flag, Flags)
end

function DrawingLibrary.RemoveObject(Self, Target)
    local ESP = Self.ObjectESP[Target]
    if not ESP then return end

    ESP.Name:Destroy()
    Self.ObjectESP[Target] = nil
end

function DrawingLibrary.SetupCursor(Window)
    local Cursor = AddDrawing("Image", {
        Size = V2New(64, 64) / 1.5,
        ZIndex = 3
    })

    local CursorData = Sp3arParvus.Cursor
    local DefaultCursorData = Sp3arParvus.DefaultCursor

    if type(CursorData) == "string" and #CursorData > 0 then
        Cursor.Data = CursorData
    elseif type(DefaultCursorData) == "string" and #DefaultCursorData > 0 then
        Cursor.Data = DefaultCursorData
    else
        Cursor:Remove()
        UserInputService.MouseIconEnabled = true
        return
    end

    local LastVisibility = nil

    RunService.Heartbeat:Connect(function()
        local ShouldShow = Window.Flags["Mouse/Enabled"] and Window.Enabled and UserInputService.MouseBehavior == Enum.MouseBehavior.Default
        Cursor.Visible = ShouldShow
        if ShouldShow then Cursor.Position = UserInputService:GetMouseLocation() - Cursor.Size / 2 end

        if LastVisibility ~= ShouldShow then
            UserInputService.MouseIconEnabled = not ShouldShow
            LastVisibility = ShouldShow
        end
    end)
end

function DrawingLibrary.SetupCrosshair(Flags)
    local CrosshairL = AddDrawing("Line", { Thickness = 1.5, Transparency = 1, Visible = false, ZIndex = 2 })
    local CrosshairR = AddDrawing("Line", { Thickness = 1.5, Transparency = 1, Visible = false, ZIndex = 2 })
    local CrosshairT = AddDrawing("Line", { Thickness = 1.5, Transparency = 1, Visible = false, ZIndex = 2 })
    local CrosshairB = AddDrawing("Line", { Thickness = 1.5, Transparency = 1, Visible = false, ZIndex = 2 })

    RunService.Heartbeat:Connect(function()
        local CrosshairEnabled = Flags["Crosshair/Enabled"] and UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default and not UserInputService.MouseIconEnabled
        CrosshairL.Visible, CrosshairR.Visible, CrosshairT.Visible, CrosshairB.Visible = CrosshairEnabled, CrosshairEnabled, CrosshairEnabled, CrosshairEnabled

        if CrosshairEnabled then
            local MouseLocation = UserInputService:GetMouseLocation()
            local Color = Flags["Crosshair/Color"]
            local Size = Flags["Crosshair/Size"]
            local Gap = Flags["Crosshair/Gap"]
            local Transparency = 1 - Color[4]
            Color = Color[6]

            CrosshairL.Color = Color
            CrosshairL.Transparency = Transparency
            CrosshairL.From = MouseLocation - V2New(Gap, 0)
            CrosshairL.To = MouseLocation - V2New(Size + Gap, 0)

            CrosshairR.Color = Color
            CrosshairR.Transparency = Transparency
            CrosshairR.From = MouseLocation + V2New(Gap + 1, 0)
            CrosshairR.To = MouseLocation + V2New(Size + (Gap + 1), 0)

            CrosshairT.Color = Color
            CrosshairT.Transparency = Transparency
            CrosshairT.From = MouseLocation - V2New(0, Gap)
            CrosshairT.To = MouseLocation - V2New(0, Size + Gap)

            CrosshairB.Color = Color
            CrosshairB.Transparency = Transparency
            CrosshairB.From = MouseLocation + V2New(0, Gap + 1)
            CrosshairB.To = MouseLocation + V2New(0, Size + (Gap + 1))
        end
    end)
end

function DrawingLibrary.SetupFOV(Flag, Flags)
    local FOV = AddDrawing("Circle", { ZIndex = 4 })
    local FOVOutline = AddDrawing("Circle", { ZIndex = 3 })

    RunService.Heartbeat:Connect(function()
        local Visible = GetFlag(Flags, Flag, "/Enabled")
        and GetFlag(Flags, Flag, "/FOV/Enabled")

        FOV.Visible = Visible
        FOVOutline.Visible = Visible

        if Visible then
            local MouseLocation = UserInputService:GetMouseLocation()
            local Thickness = GetFlag(Flags, Flag, "/FOV/Thickness")
            local NumSides = GetFlag(Flags, Flag, "/FOV/NumSides")
            local Filled = GetFlag(Flags, Flag, "/FOV/Filled")
            local Radius = GetFlag(Flags, Flag, "/FOV/Radius")
            local Color = GetFlag(Flags, Flag, "/FOV/Color")
            local Transparency = 1 - Color[4]
            Color = Color[6]

            FOV.Color = Color

            FOV.Transparency = Transparency
            FOVOutline.Transparency = Transparency

            FOV.Thickness = Thickness
            FOVOutline.Thickness = Thickness + 2
            
            FOV.NumSides = NumSides
            FOVOutline.NumSides = NumSides

            FOV.Filled = Filled
            --FOVOutline.Filled = Filled

            FOV.Radius = Radius
            FOVOutline.Radius = Radius

            FOV.Position = MouseLocation
            FOVOutline.Position = MouseLocation
        end
    end)
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

local FORCE_FULL_FPS_ESP = true -- Force every RenderStepped tick for ESP to prevent frozen tracers
local NEAR_UPDATE_INTERVAL = 0 -- Update every frame for players within 5k studs
local MID_UPDATE_INTERVAL = 0.033 -- ~30 FPS for players between 5k-10k studs
local FAR_UPDATE_INTERVAL = 0.1 -- ~10 FPS for players between 10k-15k studs
local MAX_DISTANCE = FAR_ZONE_MAX -- Don't render beyond far zone ceiling

DrawingLibrary.Connection = RunService.RenderStepped:Connect(function(dt)
    debug.profilebegin("PARVUS_DRAWING")

    -- Process ESP updates with distance-based throttling and error recovery
    for Target, ESP in pairs(DrawingLibrary.ESP) do
        local shouldUpdate = false
        local quickCheck = true

        -- Quick validation check without pcall overhead
        pcall(function()
            if not Target or not Target.Parent then
                quickCheck = false
                return
            end

            -- Distance-based throttling
            local character = Target.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart and Camera then
                    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude

                    -- Skip if beyond max distance
                    if distance > MAX_DISTANCE then
                        HideESPDrawings(ESP)
                        return
                    end

                    if FORCE_FULL_FPS_ESP then
                        ESPUpdateAccumulators[Target] = 0
                        shouldUpdate = true
                    else
                        -- Determine update interval based on distance
                        local updateInterval = NEAR_UPDATE_INTERVAL
                        if distance > MID_ZONE_MAX then
                            updateInterval = FAR_UPDATE_INTERVAL
                        elseif distance > CLOSE_ZONE_MAX then
                            updateInterval = MID_UPDATE_INTERVAL
                        end

                        -- Check accumulator for this target
                        ESPUpdateAccumulators[Target] = (ESPUpdateAccumulators[Target] or 0) + dt
                        if ESPUpdateAccumulators[Target] >= updateInterval then
                            ESPUpdateAccumulators[Target] = 0
                            shouldUpdate = true
                        end
                    end
                else
                    shouldUpdate = true
                end
            else
                shouldUpdate = true
            end
        end)

        -- If quick check failed, mark for cleanup
        if not quickCheck then
            ESPErrorCounts[Target] = (ESPErrorCounts[Target] or 0) + 1
            if ESPErrorCounts[Target] >= MAX_ESP_ERRORS then
                table.insert(ESPCleanupQueue, Target)
            end
            HideESPDrawings(ESP)
        elseif shouldUpdate then
            -- Perform actual ESP update with error handling
            local Success, Error = pcall(DrawingLibrary.Update, ESP, Target)
            if not Success then
                -- Increment error count
                ESPErrorCounts[Target] = (ESPErrorCounts[Target] or 0) + 1

                -- If too many errors, mark for cleanup
                if ESPErrorCounts[Target] >= MAX_ESP_ERRORS then
                    table.insert(ESPCleanupQueue, Target)
                end

                HideESPDrawings(ESP)
            else
                -- Reset error count on success
                ESPErrorCounts[Target] = 0
            end
        end
    end

    -- Clean up broken ESP objects
    for _, Target in ipairs(ESPCleanupQueue) do
        DrawingLibrary:RemoveESP(Target)
        ESPErrorCounts[Target] = nil
        ESPUpdateAccumulators[Target] = nil
    end
    table.clear(ESPCleanupQueue)

    -- Update object ESP (items, etc.)
    for Object, ESP in pairs(DrawingLibrary.ObjectESP) do
        local Success, Error = pcall(function()
            if not GetFlag(ESP.Flags, ESP.GlobalFlag, "/Enabled")
            or not GetFlag(ESP.Flags, ESP.Flag, "/Enabled") then
                ESP.Name.Visible = false
                return
            end

            ESP.Target.Position = ESP.IsBasePart and ESP.Target.RootPart.Position or ESP.Target.Position
            ESP.Target.ScreenPosition, ESP.Target.OnScreen = WorldToScreen(ESP.Target.Position)

            ESP.Target.Distance = GetDistance(ESP.Target.Position)
            ESP.Target.InTheRange = IsWithinReach(GetFlag(ESP.Flags, ESP.GlobalFlag, "/DistanceCheck"),
            GetFlag(ESP.Flags, ESP.GlobalFlag, "/Distance"), ESP.Target.Distance)

            ESP.Name.Visible = (ESP.Target.OnScreen and ESP.Target.InTheRange) or false

            if ESP.Name.Visible then
                local Color = GetFlag(ESP.Flags, ESP.Flag, "/Color")
                ESP.Name.Transparency = 1 - Color[4]
                ESP.Name.Color = Color[6]

            ESP.Name.Position = ESP.Target.ScreenPosition
            ESP.Name.Text = string.format("%s\n%i studs", ESP.Target.Name, ESP.Target.Distance)
            end
        end)

        if not Success then
            -- Hide ESP on error and remove if object is invalid
            if ESP and ESP.Name then
                ESP.Name.Visible = false
            end
            if not Object or not Object.Parent then
                DrawingLibrary:RemoveObject(Object)
            end
        end
    end
    debug.profileend()
end)

--[[DrawingLibrary.Connection = RunService.RenderStepped:Connect(function()
    debug.profilebegin("PARVUS_DRAWING")
    for Target, ESP in pairs(DrawingLibrary.ESP) do
        ESP.Target.Character, ESP.Target.RootPart = GetCharacter(Target, ESP.Mode)
        if ESP.Target.Character and ESP.Target.RootPart then
            ESP.Target.ScreenPosition, ESP.Target.OnScreen = WorldToScreen(ESP.Target.RootPart.Position)

            if ESP.Target.OnScreen then
                ESP.Target.Distance = GetDistance(ESP.Target.RootPart.Position)
                ESP.Target.InTheRange = IsWithinReach(GetFlag(ESP.Flags, ESP.Flag, "/DistanceCheck"), GetFlag(ESP.Flags, ESP.Flag, "/Distance"), ESP.Target.Distance)

                if ESP.Target.InTheRange then
                    ESP.Target.Health, ESP.Target.MaxHealth, ESP.Target.IsAlive = GetHealth(Target, ESP.Target.Character, ESP.Mode)
                    ESP.Target.InEnemyTeam, ESP.Target.TeamColor = GetTeam(Target, ESP.Target.Character, ESP.Mode)
                    ESP.Target.Color = GetFlag(ESP.Flags, ESP.Flag, "/TeamColor") and ESP.Target.TeamColor
                    or (ESP.Target.InEnemyTeam and GetFlag(ESP.Flags, ESP.Flag, "/Enemy")[6]
                    or GetFlag(ESP.Flags, ESP.Flag, "/Ally")[6])

                    -- if ESP.Highlight and ESP.Highlight.Enabled then
                    --     local OutlineColor = GetFlag(ESP.Flags, Flag, "/Highlight/OutlineColor")
                    --     ESP.Highlight.DepthMode = GetFlag(ESP.Flags, Flag, "/Highlight/Occluded")
                    --     and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
                    --     --ESP.Highlight.Adornee = Character
                    --     ESP.Highlight.FillColor = ESP.Target.Color
                    --     ESP.Highlight.OutlineColor = OutlineColor[6]
                    --     ESP.Highlight.OutlineTransparency = OutlineColor[4]
                    --     ESP.Highlight.FillTransparency = GetFlag(ESP.Flags, Flag, "/Highlight/Transparency")
                    -- end

                    if ESP.Drawing.Tracer.Main.Visible or ESP.Drawing.HeadDot.Main.Visible then
                        local Head = FindFirstChild(ESP.Target.Character, "Head", true)

                        if Head then
                            local HeadPosition = WorldToScreen(Head.Position)

                            if ESP.Drawing.Tracer.Main.Visible then
                                local FromPosition = GetFlag(ESP.Flags, ESP.Flag, "/Tracer/Mode")
                                local Thickness = GetFlag(ESP.Flags, ESP.Flag, "/Tracer/Thickness")
                                local Transparency = 1 - GetFlag(ESP.Flags, ESP.Flag, "/Tracer/Transparency")
                                FromPosition = (FromPosition[1] == "From Mouse" and UserInputService:GetMouseLocation())
                                or (FromPosition[1] == "From Bottom" and V2New(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y))

                                ESP.Drawing.Tracer.Main.Color = ESP.Target.Color

                                ESP.Drawing.Tracer.Main.Thickness = Thickness
                                ESP.Drawing.Tracer.Outline.Thickness = Thickness + 2

                                ESP.Drawing.Tracer.Main.Transparency = Transparency
                                ESP.Drawing.Tracer.Outline.Transparency = Transparency

                                ESP.Drawing.Tracer.Main.From = FromPosition
                                ESP.Drawing.Tracer.Outline.From = FromPosition

                                ESP.Drawing.Tracer.Main.To = HeadPosition
                                ESP.Drawing.Tracer.Outline.To = HeadPosition
                            end
                            if ESP.Drawing.HeadDot.Main.Visible then
                                local Filled = GetFlag(ESP.Flags, ESP.Flag, "/HeadDot/Filled")
                                local Radius = GetFlag(ESP.Flags, ESP.Flag, "/HeadDot/Radius")
                                local NumSides = GetFlag(ESP.Flags, ESP.Flag, "/HeadDot/NumSides")
                                local Thickness = GetFlag(ESP.Flags, ESP.Flag, "/HeadDot/Thickness")
                                local Autoscale = GetFlag(ESP.Flags, ESP.Flag, "/HeadDot/Autoscale")
                                local Transparency = 1 - GetFlag(ESP.Flags, ESP.Flag, "/HeadDot/Transparency")
                                Radius = GetScaleFactor(Autoscale, Radius, ESP.Target.Distance)

                                ESP.Drawing.HeadDot.Main.Color = ESP.Target.Color

                                ESP.Drawing.HeadDot.Main.Transparency = Transparency
                                ESP.Drawing.HeadDot.Outline.Transparency = Transparency

                                ESP.Drawing.HeadDot.Main.NumSides = NumSides
                                ESP.Drawing.HeadDot.Outline.NumSides = NumSides

                                ESP.Drawing.HeadDot.Main.Radius = Radius
                                ESP.Drawing.HeadDot.Outline.Radius = Radius

                                ESP.Drawing.HeadDot.Main.Thickness = Thickness
                                ESP.Drawing.HeadDot.Outline.Thickness = Thickness + 2

                                ESP.Drawing.HeadDot.Main.Filled = Filled

                                ESP.Drawing.HeadDot.Main.Position = HeadPosition
                                ESP.Drawing.HeadDot.Outline.Position = HeadPosition
                            end
                        end
                    end
                    if ESP.Drawing.Box.Visible then
                        local BoxSize = CalculateBoxSize(ESP.Target.Character, ESP.Target.Distance)
                        local HealthPercent = ESP.Target.Health / ESP.Target.MaxHealth
                        local Textboxes = ESP.Drawing.Textboxes
                        ESP.Target.BoxTooSmall = BoxSize.Y < 18

                        local Transparency = 1 - GetFlag(ESP.Flags, ESP.Flag, "/Box/Transparency")
                        local CornerSize = GetFlag(ESP.Flags, ESP.Flag, "/Box/CornerSize")
                        local Thickness = GetFlag(ESP.Flags, ESP.Flag, "/Box/Thickness")
                        local Filled = GetFlag(ESP.Flags, ESP.Flag, "/Box/Filled")

                        local ThicknessAdjust = Floor(Thickness / 2)
                        CornerSize = V2New(
                            (BoxSize.X / 2) * (CornerSize / 100),
                            (BoxSize.Y / 2) * (CornerSize / 100)
                        )

                        local From = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X - (BoxSize.X / 2),
                            ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)
                        )
                        local To = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X - (BoxSize.X / 2),
                            (ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)) + CornerSize.Y
                        )

                        ESP.Drawing.Box.LineLT.Main.Color = ESP.Target.Color
                        ESP.Drawing.Box.LineLT.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineLT.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineLT.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineLT.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineLT.Main.From = From - V2New(0, ThicknessAdjust)
                        ESP.Drawing.Box.LineLT.Outline.From = From - V2New(0, ThicknessAdjust + 1)
                        ESP.Drawing.Box.LineLT.Main.To = To
                        ESP.Drawing.Box.LineLT.Outline.To = To + V2New(0, 1)

                        From = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X - (BoxSize.X / 2),
                            ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            (ESP.Target.ScreenPosition.X - (BoxSize.X / 2)) + CornerSize.X,
                            ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)
                        )

                        ESP.Drawing.Box.LineTL.Main.Color = ESP.Target.Color
                        ESP.Drawing.Box.LineTL.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineTL.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineTL.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineTL.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineTL.Main.From = From - V2New(ThicknessAdjust, 0)
                        ESP.Drawing.Box.LineTL.Outline.From = From - V2New(ThicknessAdjust + 1, 0)
                        ESP.Drawing.Box.LineTL.Main.To = To
                        ESP.Drawing.Box.LineTL.Outline.To = To + V2New(1, 0)

                        From = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X - (BoxSize.X / 2),
                            ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X - (BoxSize.X / 2),
                            (ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)) - CornerSize.Y
                        )

                        ESP.Drawing.Box.LineLB.Main.Color = ESP.Target.Color
                        ESP.Drawing.Box.LineLB.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineLB.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineLB.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineLB.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineLB.Main.From = From + V2New(0, ThicknessAdjust)
                        ESP.Drawing.Box.LineLB.Outline.From = From + V2New(0, ThicknessAdjust + 1)
                        ESP.Drawing.Box.LineLB.Main.To = To
                        ESP.Drawing.Box.LineLB.Outline.To = To - V2New(0, 1)

                        From = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X - (BoxSize.X / 2),
                            ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            (ESP.Target.ScreenPosition.X - (BoxSize.X / 2)) + CornerSize.X,
                            ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)
                        )

                        ESP.Drawing.Box.LineBL.Main.Color = ESP.Target.Color
                        ESP.Drawing.Box.LineBL.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineBL.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineBL.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineBL.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineBL.Main.From = From - V2New(ThicknessAdjust, 1)
                        ESP.Drawing.Box.LineBL.Outline.From = From - V2New(ThicknessAdjust + 1, 1)
                        ESP.Drawing.Box.LineBL.Main.To = To - V2New(0, 1)
                        ESP.Drawing.Box.LineBL.Outline.To = To - V2New(-1, 1)

                        From = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X + (BoxSize.X / 2),
                            ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X + (BoxSize.X / 2),
                            (ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)) + CornerSize.Y
                        )

                        ESP.Drawing.Box.LineRT.Main.Color = ESP.Target.Color
                        ESP.Drawing.Box.LineRT.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineRT.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineRT.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineRT.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineRT.Main.From = From - V2New(1, ThicknessAdjust)
                        ESP.Drawing.Box.LineRT.Outline.From = From - V2New(1, ThicknessAdjust + 1)
                        ESP.Drawing.Box.LineRT.Main.To = To - V2New(1, 0)
                        ESP.Drawing.Box.LineRT.Outline.To = To + V2New(-1, 1)

                        From = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X + (BoxSize.X / 2),
                            ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            (ESP.Target.ScreenPosition.X + (BoxSize.X / 2)) - CornerSize.X,
                            ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)
                        )

                        ESP.Drawing.Box.LineTR.Main.Color = ESP.Target.Color
                        ESP.Drawing.Box.LineTR.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineTR.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineTR.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineTR.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineTR.Main.From = From + V2New(ThicknessAdjust, 0)
                        ESP.Drawing.Box.LineTR.Outline.From = From + V2New(ThicknessAdjust + 1, 0)
                        ESP.Drawing.Box.LineTR.Main.To = To
                        ESP.Drawing.Box.LineTR.Outline.To = To - V2New(1, 0)

                        From = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X + (BoxSize.X / 2),
                            ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X + (BoxSize.X / 2),
                            (ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)) - CornerSize.Y
                        )

                        ESP.Drawing.Box.LineRB.Main.Color = ESP.Target.Color
                        ESP.Drawing.Box.LineRB.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineRB.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineRB.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineRB.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineRB.Main.From = From + V2New(-1, ThicknessAdjust)
                        ESP.Drawing.Box.LineRB.Outline.From = From + V2New(-1, ThicknessAdjust + 1)
                        ESP.Drawing.Box.LineRB.Main.To = To - V2New(1, 0)
                        ESP.Drawing.Box.LineRB.Outline.To = To - V2New(1, 1)

                        From = AntiAliasingXY(
                            ESP.Target.ScreenPosition.X + (BoxSize.X / 2),
                            ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)
                        )
                        To = AntiAliasingXY(
                            (ESP.Target.ScreenPosition.X + (BoxSize.X / 2)) - CornerSize.X,
                            ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)
                        )

                        ESP.Drawing.Box.LineBR.Main.Color = ESP.Target.Color
                        ESP.Drawing.Box.LineBR.Main.Thickness = Thickness
                        ESP.Drawing.Box.LineBR.Outline.Thickness = Thickness + 2
                        ESP.Drawing.Box.LineBR.Main.Transparency = Transparency
                        ESP.Drawing.Box.LineBR.Outline.Transparency = Transparency
                        ESP.Drawing.Box.LineBR.Main.From = From + V2New(ThicknessAdjust, -1)
                        ESP.Drawing.Box.LineBR.Outline.From = From + V2New(ThicknessAdjust + 1, -1)
                        ESP.Drawing.Box.LineBR.Main.To = To - V2New(0, 1)
                        ESP.Drawing.Box.LineBR.Outline.To = To - V2New(1, 1)

                        if ESP.Drawing.HealthBar.Main.Visible then
                            ESP.Drawing.HealthBar.Main.Color = EvalHealth(HealthPercent)
                            ESP.Drawing.HealthBar.Main.Transparency = Transparency
                            ESP.Drawing.HealthBar.Outline.Transparency = Transparency

                            ESP.Drawing.HealthBar.Outline.Size = AntiAliasingXY(Thickness + 2, BoxSize.Y + (Thickness + 1))
                            ESP.Drawing.HealthBar.Outline.Position = AntiAliasingXY(
                                (ESP.Target.ScreenPosition.X - (BoxSize.X / 2)) - Thickness - ThicknessAdjust - 4,
                                ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2) - ThicknessAdjust - 1
                            )
                            ESP.Drawing.HealthBar.Main.Size = V2New(ESP.Drawing.HealthBar.Outline.Size.X - 2, -HealthPercent * (ESP.Drawing.HealthBar.Outline.Size.Y - 2))
                            ESP.Drawing.HealthBar.Main.Position = ESP.Drawing.HealthBar.Outline.Position + V2New(1, ESP.Drawing.HealthBar.Outline.Size.Y - 1)
                        end

                        if Textboxes.Name.Visible
                        or Textboxes.Health.Visible
                        or Textboxes.Distance.Visible
                        or Textboxes.Weapon.Visible then
                            local Size = GetFlag(ESP.Flags, ESP.Flag, "/Name/Size")
                            local Autoscale = GetFlag(ESP.Flags, ESP.Flag, "/Name/Autoscale")
                            --local Font = GetFont(GetFlag(ESP.ESP.Flags, ESP.ESP.Flag, "/Name/Font")[1])
                            Autoscale = Floor(GetScaleFactor(Autoscale, Size, ESP.Target.Distance))

                            Transparency = 1 - GetFlag(ESP.Flags, ESP.Flag, "/Name/Transparency")
                            Outline = GetFlag(ESP.Flags, ESP.Flag, "/Name/Outline")

                            if Textboxes.Name.Visible then
                                Textboxes.Name.Outline = Outline
                                --Textboxes.Name.Font = Font
                                Textboxes.Name.Transparency = Transparency
                                Textboxes.Name.Size = Autoscale
                                Textboxes.Name.Text = ESP.Mode == "Player" and Target.Name
                                or (InEnemyTeam and "Enemy NPC" or "Ally NPC")

                                Textboxes.Name.Position = AntiAliasingXY(
                                    ESP.Target.ScreenPosition.X,
                                    ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2) - Textboxes.Name.TextBounds.Y - ThicknessAdjust - 2
                                )
                            end
                            if Textboxes.Health.Visible then
                                Textboxes.Health.Outline = Outline
                                --Textboxes.Health.Font = Font
                                Textboxes.Health.Transparency = Transparency
                                Textboxes.Health.Size = Autoscale
                                Textboxes.Health.Text = tostring(math.floor(HealthPercent * 100)) .. "%"

                                local HealthPositionX = ESP.Drawing.HealthBar.Main.Visible and ((ESP.Target.ScreenPosition.X - (BoxSize.X / 2)) - Textboxes.Health.TextBounds.X - (Thickness + ThicknessAdjust + 5)) or ((ESP.Target.ScreenPosition.X - (BoxSize.X / 2)) - Textboxes.Health.TextBounds.X - ThicknessAdjust - 2)
                                Textboxes.Health.Position = AntiAliasingXY(
                                    HealthPositionX,
                                    (ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2)) - ThicknessAdjust - 1
                                )

                                --ESP.Drawing.Test.Position = Textboxes.Health.Position
                                --ESP.Drawing.Test.Size = V2New(Textboxes.Health.TextBounds.X, Textboxes.Health.TextBounds.Y)
                            end
                            if Textboxes.Distance.Visible then
                                Textboxes.Distance.Outline = Outline
                                --Textboxes.Distance.Font = Font
                                Textboxes.Distance.Transparency = Transparency
                                Textboxes.Distance.Size = Autoscale
                                Textboxes.Distance.Text = tostring(math.floor(ESP.Target.Distance)) .. " studs"

                                Textboxes.Distance.Position = AntiAliasingXY(
                                    ESP.Target.ScreenPosition.X,
                                    (ESP.Target.ScreenPosition.Y + (BoxSize.Y / 2)) + ThicknessAdjust + 2
                                )

                                --ESP.Drawing.Test.Position = Textboxes.Distance.Position
                                --ESP.Drawing.Test.Size = V2New(Textboxes.Distance.TextBounds.X, Textboxes.Distance.TextBounds.Y)
                            end
                            if Textboxes.Weapon.Visible then
                                local Weapon = GetWeapon(Target, Character, ESP.Mode)

                                Textboxes.Weapon.Outline = Outline
                                --Textboxes.Weapon.Font = Font
                                Textboxes.Weapon.Transparency = Transparency
                                Textboxes.Weapon.Size = Autoscale
                                Textboxes.Weapon.Text = Weapon

                                Textboxes.Weapon.Position = AntiAliasingXY(
                                    (ESP.Target.ScreenPosition.X + (BoxSize.X / 2)) + ThicknessAdjust + 2,
                                    ESP.Target.ScreenPosition.Y - (BoxSize.Y / 2) - ThicknessAdjust - 1
                                )

                                --ESP.Drawing.Test.Position = Textboxes.Weapon.Position
                                --ESP.Drawing.Test.Size = V2New(Textboxes.Weapon.TextBounds.X, Textboxes.Weapon.TextBounds.Y)
                            end
                        end
                    end
                end
            else
                if ESP.Drawing.Arrow.Main.Visible then
                    ESP.Target.Distance = GetDistance(ESP.Target.RootPart.Position)
                    ESP.Target.InTheRange = IsWithinReach(GetFlag(ESP.Flags, ESP.Flag, "/DistanceCheck"), GetFlag(ESP.Flags, ESP.Flag, "/Distance"), ESP.Target.Distance)
                    ESP.Target.Health, ESP.Target.MaxHealth, ESP.Target.IsAlive = GetHealth(Target, ESP.Target.Character, ESP.Mode)
                    ESP.Target.InEnemyTeam, ESP.Target.TeamColor = GetTeam(Target, ESP.Target.Character, ESP.Mode)
                    ESP.Target.Color = GetFlag(ESP.Flags, ESP.Flag, "/TeamColor") and ESP.Target.TeamColor
                    or (ESP.Target.InEnemyTeam and GetFlag(ESP.Flags, ESP.Flag, "/Enemy")[6]
                    or GetFlag(ESP.Flags, ESP.Flag, "/Ally")[6])

                    local Direction = GetRelative(ESP.Target.RootPart.Position).Unit
                    local SideLength = GetFlag(ESP.Flags, ESP.Flag, "/Arrow/Width") / 2
                    local ArrowRadius = GetFlag(ESP.Flags, ESP.Flag, "/Arrow/Radius")
                    local Base, Radians90 = Direction * ArrowRadius, Rad(90)

                    local PointA = RelativeToCenter(Base + RotateVector(Direction, Radians90) * SideLength)
                    local PointB = RelativeToCenter(Direction * (ArrowRadius + GetFlag(ESP.Flags, ESP.Flag, "/Arrow/Height")))
                    local PointC = RelativeToCenter(Base + RotateVector(Direction, -Radians90) * SideLength)

                    local Filled = GetFlag(ESP.Flags, ESP.Flag, "/Arrow/Filled")
                    local Thickness = GetFlag(ESP.Flags, ESP.Flag, "/Arrow/Thickness")
                    local Transparency = 1 - GetFlag(ESP.Flags, ESP.Flag, "/Arrow/Transparency")

                    ESP.Drawing.Arrow.Main.Color = ESP.Target.Color

                    ESP.Drawing.Arrow.Main.Filled = Filled

                    ESP.Drawing.Arrow.Main.Thickness = Thickness
                    ESP.Drawing.Arrow.Outline.Thickness = Thickness + 2

                    ESP.Drawing.Arrow.Main.Transparency = Transparency
                    ESP.Drawing.Arrow.Outline.Transparency = Transparency

                    ESP.Drawing.Arrow.Main.PointA = PointA
                    ESP.Drawing.Arrow.Outline.PointA = PointA
                    ESP.Drawing.Arrow.Main.PointB = PointB
                    ESP.Drawing.Arrow.Outline.PointB = PointB
                    ESP.Drawing.Arrow.Main.PointC = PointC
                    ESP.Drawing.Arrow.Outline.PointC = PointC
                end
            end
        end

        local TeamCheck = (not GetFlag(ESP.Flags, ESP.Flag, "/TeamCheck") and not ESP.Target.InEnemyTeam) or ESP.Target.InEnemyTeam
        local Visible = ESP.Target.RootPart and ESP.Target.OnScreen and ESP.Target.InTheRange and ESP.Target.IsAlive and TeamCheck
        local ArrowVisible = ESP.Target.RootPart and (not ESP.Target.OnScreen) and ESP.Target.InTheRange and ESP.Target.IsAlive and TeamCheck

        -- if ESP.Highlight then
        --     ESP.Highlight.Enabled = Visible and GetFlag(ESP.Flags, ESP.Flag, "/Highlight/Enabled") or false
        -- end

        ESP.Drawing.Box.Visible = Visible and GetFlag(ESP.Flags, ESP.Flag, "/Box/Enabled") or false
        ESP.Drawing.Box.OutlineVisible = ESP.Drawing.Box.Visible and GetFlag(ESP.Flags, ESP.Flag, "/Box/Outline") or false

        for Index, Line in pairs(ESP.Drawing.Box) do
            if type(Line) ~= "table" then continue end
            Line.Main.Visible = ESP.Drawing.Box.Visible
            Line.Outline.Visible = ESP.Drawing.Box.OutlineVisible
        end

        ESP.Drawing.HealthBar.Main.Visible = ESP.Drawing.Box.Visible and GetFlag(ESP.Flags, ESP.Flag, "/Box/HealthBar") and not ESP.Target.BoxTooSmall or false
        ESP.Drawing.HealthBar.Outline.Visible = ESP.Drawing.HealthBar.Main.Visible and GetFlag(ESP.Flags, ESP.Flag, "/Box/Outline") or false

        ESP.Drawing.Arrow.Main.Visible = ArrowVisible and GetFlag(ESP.Flags, ESP.Flag, "/Arrow/Enabled") or false
        ESP.Drawing.Arrow.Outline.Visible = GetFlag(ESP.Flags, ESP.Flag, "/Arrow/Outline") and ESP.Drawing.Arrow.Main.Visible or false

        ESP.Drawing.HeadDot.Main.Visible = Visible and GetFlag(ESP.Flags, ESP.Flag, "/HeadDot/Enabled") or false
        ESP.Drawing.HeadDot.Outline.Visible = GetFlag(ESP.Flags, ESP.Flag, "/HeadDot/Outline") and ESP.Drawing.HeadDot.Main.Visible or false

        ESP.Drawing.Tracer.Main.Visible = Visible and GetFlag(ESP.Flags, ESP.Flag, "/Tracer/Enabled") or false
        ESP.Drawing.Tracer.Outline.Visible = GetFlag(ESP.Flags, ESP.Flag, "/Tracer/Outline") and ESP.Drawing.Tracer.Main.Visible or false

        ESP.Drawing.Textboxes.Name.Visible = ESP.Drawing.Box.Visible and GetFlag(ESP.Flags, ESP.Flag, "/Name/Enabled") or false
        ESP.Drawing.Textboxes.Health.Visible = ESP.Drawing.Box.Visible and GetFlag(ESP.Flags, ESP.Flag, "/Health/Enabled") or false
        ESP.Drawing.Textboxes.Distance.Visible = ESP.Drawing.Box.Visible and GetFlag(ESP.Flags, ESP.Flag, "/Distance/Enabled") or false
        ESP.Drawing.Textboxes.Weapon.Visible = ESP.Drawing.Box.Visible and GetFlag(ESP.Flags, ESP.Flag, "/Weapon/Enabled") or false
    end
    debug.profileend()
end)]]

return DrawingLibrary
]=])()

-- ===== UNIVERSAL GAME SCRIPT =====
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PlayerService = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local LocalPlayer = PlayerService.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local SilentAim, Aimbot, Trigger = nil, false, false
local ProjectileSpeed, ProjectileGravity, GravityCorrection = 1000, 196.2, 2

local KnownBodyParts = {
    {"Head", true}, {"HumanoidRootPart", true},
    {"Torso", false}, {"UpperTorso", false}, {"LowerTorso", false},

    {"Right Arm", false}, {"RightUpperArm", false}, {"RightLowerArm", false}, {"RightHand", false},
    {"Left Arm", false}, {"LeftUpperArm", false}, {"LeftLowerArm", false}, {"LeftHand", false},

    {"Right Leg", false}, {"RightUpperLeg", false}, {"RightLowerLeg", false}, {"RightFoot", false},
    {"Left Leg", false}, {"LeftUpperLeg", false}, {"LeftLowerLeg", false}, {"LeftFoot", false}
}

-- ============================================================
-- MISC FEATURE VARIABLES (MOVED OUTSIDE WINDOW SCOPE)
-- These were previously inside Window block causing nil errors
-- ============================================================
local performanceLabel
local perfMinimized = false
local perfOriginalSize = UDim2.fromOffset(180, 80)
local perfAccum = 0

local closestPlayerTrackerLabel
local closestTrackerMinimized = false
local closestTrackerOriginalSize = UDim2.fromOffset(220, 70)
local nearestPlayerRef = nil

local brokenSet = {}
local brokenCacheDirty = true
local undoStack = {}
local UNDO_LIMIT = 25
local hoverHL
local CTRL_HELD = false

-- ============================================================
-- SCRIPT LIFECYCLE FUNCTIONS
-- ============================================================
local Window -- Declare Window at file scope (will be assigned below)

local function ResolveUIRoot()
    local cached = Sp3arParvus and Sp3arParvus.UIRoot
    if cached and cached.Parent and cached:IsDescendantOf(game) then
        return cached
    end

    local screenGui = game:GetService("CoreGui"):FindFirstChild("Parvus")
    if screenGui and Sp3arParvus then
        Sp3arParvus.UIRoot = screenGui
    elseif Sp3arParvus then
        Sp3arParvus.UIRoot = nil
    end

    return screenGui
end

local function ReloadScript()
    print(string.format("[Sp3arParvus v%s] Reloading script...", SP3ARPARVUS_VERSION))

    -- Clean up existing UI
    local ScreenGui = ResolveUIRoot()
    if ScreenGui then
        ScreenGui:Destroy()
        if Sp3arParvus then
            Sp3arParvus.UIRoot = nil
        end
    end

    performanceLabel = nil
    closestPlayerTrackerLabel = nil

    -- Clean up ESP objects
    if Sp3arParvus and Sp3arParvus.Utilities and Sp3arParvus.Utilities.Drawing then
        -- Clear ESP for all players
        for _, Player in ipairs(PlayerService:GetPlayers()) do
            Sp3arParvus.Utilities.Drawing:RemoveESP(Player)
        end
    end

    -- Reset loaded flag
    if Sp3arParvus then
        Sp3arParvus.Loaded = false
    end

    -- Clear global
    getgenv().Sp3arParvus = nil

    print(string.format("[Sp3arParvus v%s] Cleanup complete. Reloading in 1 second...", SP3ARPARVUS_VERSION))
    task.wait(1)

    -- Reload the script
    loadstring(game:HttpGet("https://raw.githubusercontent.com/JakeHukari/Sp3arParvus/refs/heads/main/Sp3arParvus.lua", true))()
end

local function ShutdownScript()
    print(string.format("[Sp3arParvus v%s] Shutting down...", SP3ARPARVUS_VERSION))

    -- Clean up UI
    local ScreenGui = ResolveUIRoot()
    if ScreenGui then
        ScreenGui:Destroy()
        if Sp3arParvus then
            Sp3arParvus.UIRoot = nil
        end
    end

    -- Clean up ESP objects
    if Sp3arParvus and Sp3arParvus.Utilities and Sp3arParvus.Utilities.Drawing then
        for _, Player in ipairs(PlayerService:GetPlayers()) do
            Sp3arParvus.Utilities.Drawing:RemoveESP(Player)
        end
    end

    -- Clean up performance display
    if performanceLabel then
        performanceLabel:Destroy()
        performanceLabel = nil
    end

    -- Clean up closest player tracker
    if closestPlayerTrackerLabel then
        closestPlayerTrackerLabel:Destroy()
        closestPlayerTrackerLabel = nil
    end

    -- Clean up br3ak3r highlight
    if hoverHL then
        hoverHL:Destroy()
        hoverHL = nil
    end

    -- Reset all broken parts
    for part, _ in pairs(brokenSet) do
        if part and part:IsDescendantOf(game) then
            for _, entry in ipairs(undoStack) do
                if entry.part == part then
                    part.CanCollide = entry.cc
                    part.LocalTransparencyModifier = entry.ltm
                    part.Transparency = entry.t
                    break
                end
            end
        end
    end

    -- Clear state
    brokenSet = {}
    undoStack = {}
    nearestPlayerRef = nil

    -- Reset loaded flag
    if Sp3arParvus then
        Sp3arParvus.Loaded = false
    end

    -- Clear global
    getgenv().Sp3arParvus = nil

    print(string.format("[Sp3arParvus v%s] Shutdown complete. All resources cleaned up.", SP3ARPARVUS_VERSION))
end

-- ============================================================
-- PERFORMANCE DISPLAY FEATURE FUNCTIONS
-- ============================================================
local function CreatePerformanceDisplay()
    local ScreenGui = ResolveUIRoot()
    if not ScreenGui then return end

    if performanceLabel then
        if performanceLabel.Parent and performanceLabel:IsDescendantOf(game) then
            if performanceLabel.Parent ~= ScreenGui then
                performanceLabel.Parent = ScreenGui
            end
            return
        end

        performanceLabel = nil
    end

    performanceLabel = Instance.new("TextLabel")
    performanceLabel.Name = "PerfMetrics"
    performanceLabel.Size = perfOriginalSize
    performanceLabel.Position = UDim2.new(1, -190, 0, 10)
    performanceLabel.BackgroundTransparency = 0.3
    performanceLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    performanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    performanceLabel.Font = Enum.Font.Code
    performanceLabel.TextSize = 11
    performanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    performanceLabel.TextYAlignment = Enum.TextYAlignment.Top
    performanceLabel.BorderSizePixel = 0
    performanceLabel.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = performanceLabel

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 6)
    padding.Parent = performanceLabel

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "MinimizeBtn"
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    minimizeBtn.BackgroundTransparency = 0.3
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Size = UDim2.fromOffset(20, 20)
    minimizeBtn.Position = UDim2.new(1, -25, 0, 5)
    minimizeBtn.Text = "−"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 14
    minimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    minimizeBtn.ZIndex = performanceLabel.ZIndex + 1
    minimizeBtn.Parent = performanceLabel

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = minimizeBtn

    minimizeBtn.MouseButton1Click:Connect(function()
        perfMinimized = not perfMinimized
        if perfMinimized then
            performanceLabel.Size = UDim2.fromOffset(180, 30)
            performanceLabel.Text = "Performance"
            minimizeBtn.Text = "+"
        else
            performanceLabel.Size = perfOriginalSize
            minimizeBtn.Text = "−"
        end
    end)
end

local function UpdatePerformanceDisplay()
    if not Window or not Window.Flags["Misc/PerformanceDisplay"] then
        if performanceLabel then performanceLabel.Visible = false end
        return
    end

    if not performanceLabel then
        CreatePerformanceDisplay()
    end

    if performanceLabel then
        performanceLabel.Visible = true

        if not perfMinimized then
            local fps = math.floor(1 / RunService.Heartbeat:Wait())
            local playerCount = #PlayerService:GetPlayers()
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())

            performanceLabel.Text = string.format(
                "Performance\nFPS: %d\nPlayers: %d\nPing: %dms",
                fps,
                playerCount,
                ping
            )
        end
    end
end

-- ============================================================
-- CLOSEST PLAYER TRACKER FEATURE FUNCTIONS
-- ============================================================
local function CreateClosestPlayerTracker()
    local ScreenGui = ResolveUIRoot()
    if not ScreenGui then return end

    if closestPlayerTrackerLabel then
        if closestPlayerTrackerLabel.Parent and closestPlayerTrackerLabel:IsDescendantOf(game) then
            if closestPlayerTrackerLabel.Parent ~= ScreenGui then
                closestPlayerTrackerLabel.Parent = ScreenGui
            end
            return
        end

        closestPlayerTrackerLabel = nil
    end

    closestPlayerTrackerLabel = Instance.new("TextLabel")
    closestPlayerTrackerLabel.Name = "ClosestPlayerTracker"
    closestPlayerTrackerLabel.Size = closestTrackerOriginalSize
    closestPlayerTrackerLabel.Position = UDim2.new(0.5, -110, 0, 10)
    closestPlayerTrackerLabel.BackgroundTransparency = 0.2
    closestPlayerTrackerLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    closestPlayerTrackerLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
    closestPlayerTrackerLabel.Font = Enum.Font.GothamBold
    closestPlayerTrackerLabel.TextSize = 14
    closestPlayerTrackerLabel.TextXAlignment = Enum.TextXAlignment.Center
    closestPlayerTrackerLabel.TextYAlignment = Enum.TextYAlignment.Center
    closestPlayerTrackerLabel.BorderSizePixel = 0
    closestPlayerTrackerLabel.Parent = ScreenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = closestPlayerTrackerLabel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 105, 180)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = closestPlayerTrackerLabel

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
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 105, 180)
    minimizeBtn.ZIndex = closestPlayerTrackerLabel.ZIndex + 1
    minimizeBtn.Parent = closestPlayerTrackerLabel

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = minimizeBtn

    minimizeBtn.MouseButton1Click:Connect(function()
        closestTrackerMinimized = not closestTrackerMinimized
        if closestTrackerMinimized then
            closestPlayerTrackerLabel.Size = UDim2.fromOffset(220, 30)
            closestPlayerTrackerLabel.Text = "Closest Player"
            minimizeBtn.Text = "+"
        else
            closestPlayerTrackerLabel.Size = closestTrackerOriginalSize
            minimizeBtn.Text = "−"
        end
    end)
end

local function UpdateNearestPlayer()
    -- Validate local player character
    local myChar = LocalPlayer.Character
    if not myChar then
        nearestPlayerRef = nil
        return
    end

    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        nearestPlayerRef = nil
        return
    end

    local myRootPos = myRoot.Position
    local best, bestDist = nil, nil

    -- Find closest alive player
    for _, player in ipairs(PlayerService:GetPlayers()) do
        if player ~= LocalPlayer and player.Parent then
            pcall(function()
                local character = player.Character
                if character and character.Parent then
                    local root = character:FindFirstChild("HumanoidRootPart")
                    local hum = character:FindFirstChildOfClass("Humanoid")

                    if root and hum and hum.Health > 0 then
                        local dist = (root.Position - myRootPos).Magnitude
                        -- Only track players within reasonable distance (1000 studs)
                        if dist <= 1000 and (not bestDist or dist < bestDist) then
                            best, bestDist = player, dist
                        end
                    end
                end
            end)
        end
    end

    nearestPlayerRef = best
end

local function UpdateClosestPlayerTracker()
    if not Window or not Window.Flags["Misc/ClosestPlayerTracker"] then
        if closestPlayerTrackerLabel then closestPlayerTrackerLabel.Visible = false end
        return
    end

    if not closestPlayerTrackerLabel then
        pcall(CreateClosestPlayerTracker)
    end

    if closestPlayerTrackerLabel then
        closestPlayerTrackerLabel.Visible = true

        if not closestTrackerMinimized then
            -- Validate nearestPlayerRef before using it
            if nearestPlayerRef and nearestPlayerRef.Parent then
                pcall(function()
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    local targetChar = nearestPlayerRef.Character
                    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

                    if myRoot and targetRoot then
                        local distance = (targetRoot.Position - myRoot.Position).Magnitude
                        local distRounded = math.floor(distance + 0.5)
                        local name = nearestPlayerRef.DisplayName or nearestPlayerRef.Name

                        closestPlayerTrackerLabel.Text = string.format("Closest Player\n%s\n%d studs away", name, distRounded)
                    else
                        closestPlayerTrackerLabel.Text = "Closest Player\n---"
                    end
                end)
            else
                closestPlayerTrackerLabel.Text = "Closest Player\nNo players nearby"
                nearestPlayerRef = nil -- Clear invalid reference
            end
        end
    end
end

-- ============================================================
-- BR3AK3R FEATURE FUNCTIONS (PART BREAKER)
-- ============================================================
local function MarkBroken(part)
    if not part or not part:IsA("BasePart") then return end
    if brokenSet[part] then return end

    brokenSet[part] = true
    brokenCacheDirty = true

    table.insert(undoStack, {
        part = part,
        cc = part.CanCollide,
        ltm = part.LocalTransparencyModifier,
        t = part.Transparency
    })

    if #undoStack > UNDO_LIMIT then
        table.remove(undoStack, 1)
    end

    part.CanCollide = false
    part.LocalTransparencyModifier = 1
    part.Transparency = 1
end

local function UnbreakLast()
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
    entry.part.CanCollide = entry.cc
    entry.part.LocalTransparencyModifier = entry.ltm
    entry.part.Transparency = entry.t
end

local function GetMouseRay()
    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    return ray.Origin, ray.Direction * 1000
end

local function WorldRaycast(origin, direction)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.IgnoreWater = true

    return Workspace:Raycast(origin, direction, raycastParams)
end

local function CreateHoverHighlight()
    if hoverHL then return end

    hoverHL = Instance.new("Highlight")
    hoverHL.Name = "Br3ak3rHoverHL"
    hoverHL.FillTransparency = 0.5
    hoverHL.OutlineTransparency = 0
    hoverHL.OutlineColor = Color3.fromRGB(255, 255, 0)
    hoverHL.FillColor = Color3.fromRGB(255, 255, 0)
    hoverHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hoverHL.Enabled = false
    hoverHL.Parent = game:GetService("CoreGui")
end

-- ============================================================
-- WINDOW INITIALIZATION (NO LONGER LOCAL - FIXES SCOPING ISSUES)
-- ============================================================
Window = Sp3arParvus.Utilities.UI:Window({
    Name = string.format("Sp3arParvus v%s %s %s", SP3ARPARVUS_VERSION, utf8.char(8212), Sp3arParvus.Game.Name),
    Position = UDim2.new(0.5, -248 * 3, 0.5, -248)
}) do

    local uiRoot = Window.Asset and Window.Asset.Parent
    if uiRoot and uiRoot.Parent then
        Sp3arParvus.UIRoot = uiRoot
    end

    local CombatTab = Window:Tab({Name = "Combat"}) do
        local PredictionSection = CombatTab:Section({Name = "Ballistics Configuration", Side = "Left"}) do
            PredictionSection:Slider({Name = "Projectile Velocity", Flag = "Prediction/Velocity", Min = 1, Max = 10000, Value = 1000, Callback = function(Number)
                ProjectileSpeed = Number
            end})
            PredictionSection:Slider({Name = "Gravity Force", Flag = "Prediction/GravityForce", Min = 0, Max = 1000, Precise = 1, Value = 196.2, Callback = function(Number)
                ProjectileGravity = Number
            end})
            PredictionSection:Slider({Name = "Gravity Multiplier", Flag = "Prediction/GravityMultiplier", Min = 1, Max = 5, Value = 2, Callback = function(Number)
                GravityCorrection = Number
            end})
        end
        local AimbotSection = CombatTab:Section({Name = "Aim Assist", Side = "Left"}) do
            AimbotSection:Toggle({Name = "Enabled", Flag = "Aimbot/Enabled", Value = false})
            :Keybind({Flag = "Aimbot/Keybind", Value = "MouseButton2", Mouse = true, DisableToggle = true,
            Callback = function(Key, KeyDown) Aimbot = Window.Flags["Aimbot/Enabled"] and KeyDown end})

            AimbotSection:Toggle({Name = "Persistent Mode", Flag = "Aimbot/AlwaysEnabled", Value = false})
            AimbotSection:Toggle({Name = "Ballistic Prediction", Flag = "Aimbot/Prediction", Value = false})

            AimbotSection:Toggle({Name = "Ignore Teammates", Flag = "Aimbot/TeamCheck", Value = false})
            AimbotSection:Toggle({Name = "Range Limit", Flag = "Aimbot/DistanceCheck", Value = false})
            AimbotSection:Toggle({Name = "Line of Sight Check", Flag = "Aimbot/VisibilityCheck", Value = false})
            AimbotSection:Slider({Name = "Smoothing", Flag = "Aimbot/Sensitivity", Min = 0, Max = 100, Value = 20, Unit = "%"})
            AimbotSection:Slider({Name = "FOV Radius", Flag = "Aimbot/FOV/Radius", Min = 0, Max = 500, Value = 100, Unit = "px"})
            AimbotSection:Slider({Name = "Maximum Range", Flag = "Aimbot/DistanceLimit", Min = 25, Max = 1000, Value = 250, Unit = "studs"})

            local PriorityList, BodyPartsList = {{Name = "Closest", Mode = "Button", Value = true}}, {}
            for Index, Value in pairs(KnownBodyParts) do
                PriorityList[#PriorityList + 1] = {Name = Value[1], Mode = "Button", Value = false}
                BodyPartsList[#BodyPartsList + 1] = {Name = Value[1], Mode = "Toggle", Value = Value[2]}
            end

            AimbotSection:Dropdown({Name = "Target Priority", Flag = "Aimbot/Priority", List = PriorityList})
            AimbotSection:Dropdown({Name = "Hit Detection Parts", Flag = "Aimbot/BodyParts", List = BodyPartsList})
        end
        local AFOVSection = CombatTab:Section({Name = "Aim Assist Indicator", Side = "Left"}) do
            AFOVSection:Toggle({Name = "Show FOV Circle", Flag = "Aimbot/FOV/Enabled", Value = true})
            AFOVSection:Toggle({Name = "Fill Circle", Flag = "Aimbot/FOV/Filled", Value = false})
            AFOVSection:Colorpicker({Name = "Circle Color", Flag = "Aimbot/FOV/Color", Value = {1, 0.66666662693024, 1, 0.25, false}})
            AFOVSection:Slider({Name = "Circle Quality", Flag = "Aimbot/FOV/NumSides", Min = 3, Max = 100, Value = 14})
            AFOVSection:Slider({Name = "Line Thickness", Flag = "Aimbot/FOV/Thickness", Min = 1, Max = 10, Value = 2})
        end
        local SilentAimSection = CombatTab:Section({Name = "Precision Targeting", Side = "Right"}) do
            SilentAimSection:Dropdown({HideName = true, Flag = "SilentAim/Mode", List = {
                {Name = "FindPartOnRayWithIgnoreList", Mode = "Toggle"},
                {Name = "FindPartOnRayWithWhitelist", Mode = "Toggle"},
                {Name = "WorldToViewportPoint", Mode = "Toggle"},
                {Name = "WorldToScreenPoint", Mode = "Toggle"},
                {Name = "ViewportPointToRay", Mode = "Toggle"},
                {Name = "ScreenPointToRay", Mode = "Toggle"},
                {Name = "FindPartOnRay", Mode = "Toggle"},
                {Name = "Raycast", Mode = "Toggle"},
                {Name = "Target", Mode = "Toggle"},
                {Name = "Hit", Mode = "Toggle"}
            }})

            SilentAimSection:Toggle({Name = "Enabled", Flag = "SilentAim/Enabled", Value = false}):Keybind({Mouse = true, Flag = "SilentAim/Keybind"})

            SilentAimSection:Toggle({Name = "Ballistic Prediction", Flag = "SilentAim/Prediction", Value = false})

            SilentAimSection:Toggle({Name = "Ignore Teammates", Flag = "SilentAim/TeamCheck", Value = false})
            SilentAimSection:Toggle({Name = "Range Limit", Flag = "SilentAim/DistanceCheck", Value = false})
            SilentAimSection:Toggle({Name = "Line of Sight Check", Flag = "SilentAim/VisibilityCheck", Value = false})
            SilentAimSection:Slider({Name = "Accuracy", Flag = "SilentAim/HitChance", Min = 0, Max = 100, Value = 100, Unit = "%"})
            SilentAimSection:Slider({Name = "FOV Radius", Flag = "SilentAim/FOV/Radius", Min = 0, Max = 500, Value = 100, Unit = "px"})
            SilentAimSection:Slider({Name = "Maximum Range", Flag = "SilentAim/DistanceLimit", Min = 25, Max = 1000, Value = 250, Unit = "studs"})

            local PriorityList, BodyPartsList = {{Name = "Closest", Mode = "Button", Value = true}, {Name = "Random", Mode = "Button"}}, {}
            for Index, Value in pairs(KnownBodyParts) do
                PriorityList[#PriorityList + 1] = {Name = Value[1], Mode = "Button", Value = false}
                BodyPartsList[#BodyPartsList + 1] = {Name = Value[1], Mode = "Toggle", Value = Value[2]}
            end

            SilentAimSection:Dropdown({Name = "Target Priority", Flag = "SilentAim/Priority", List = PriorityList})
            SilentAimSection:Dropdown({Name = "Hit Detection Parts", Flag = "SilentAim/BodyParts", List = BodyPartsList})
        end
        local SAFOVSection = CombatTab:Section({Name = "Precision Targeting Indicator", Side = "Right"}) do
            SAFOVSection:Toggle({Name = "Show FOV Circle", Flag = "SilentAim/FOV/Enabled", Value = true})
            SAFOVSection:Toggle({Name = "Fill Circle", Flag = "SilentAim/FOV/Filled", Value = false})
            SAFOVSection:Colorpicker({Name = "Circle Color", Flag = "SilentAim/FOV/Color",
            Value = {0.6666666865348816, 0.6666666269302368, 1, 0.25, false}})
            SAFOVSection:Slider({Name = "Circle Quality", Flag = "SilentAim/FOV/NumSides", Min = 3, Max = 100, Value = 14})
            SAFOVSection:Slider({Name = "Line Thickness", Flag = "SilentAim/FOV/Thickness", Min = 1, Max = 10, Value = 2})
        end
        local TriggerSection = CombatTab:Section({Name = "Auto Fire", Side = "Right"}) do
            TriggerSection:Toggle({Name = "Enabled", Flag = "Trigger/Enabled", Value = false})
            :Keybind({Flag = "Trigger/Keybind", Value = "MouseButton2", Mouse = true, DisableToggle = true,
            Callback = function(Key, KeyDown) Trigger = Window.Flags["Trigger/Enabled"] and KeyDown end})

            TriggerSection:Toggle({Name = "Persistent Mode", Flag = "Trigger/AlwaysEnabled", Value = false})
            TriggerSection:Toggle({Name = "Continuous Fire", Flag = "Trigger/HoldMouseButton", Value = false})
            TriggerSection:Toggle({Name = "Ballistic Prediction", Flag = "Trigger/Prediction", Value = false})

            TriggerSection:Toggle({Name = "Ignore Teammates", Flag = "Trigger/TeamCheck", Value = false})
            TriggerSection:Toggle({Name = "Range Limit", Flag = "Trigger/DistanceCheck", Value = false})
            TriggerSection:Toggle({Name = "Line of Sight Check", Flag = "Trigger/VisibilityCheck", Value = false})

            TriggerSection:Slider({Name = "Activation Delay", Flag = "Trigger/Delay", Min = 0, Max = 1, Precise = 2, Value = 0.15, Unit = "s"})
            TriggerSection:Slider({Name = "Maximum Range", Flag = "Trigger/DistanceLimit", Min = 25, Max = 1000, Value = 250, Unit = "studs"})
            TriggerSection:Slider({Name = "FOV Radius", Flag = "Trigger/FOV/Radius", Min = 0, Max = 500, Value = 25, Unit = "px"})

            local PriorityList, BodyPartsList = {{Name = "Closest", Mode = "Button", Value = true}, {Name = "Random", Mode = "Button"}}, {}
            for Index, Value in pairs(KnownBodyParts) do
                PriorityList[#PriorityList + 1] = {Name = Value[1], Mode = "Button", Value = false}
                BodyPartsList[#BodyPartsList + 1] = {Name = Value[1], Mode = "Toggle", Value = Value[2]}
            end

            TriggerSection:Dropdown({Name = "Target Priority", Flag = "Trigger/Priority", List = PriorityList})
            TriggerSection:Dropdown({Name = "Hit Detection Parts", Flag = "Trigger/BodyParts", List = BodyPartsList})
        end
        local TFOVSection = CombatTab:Section({Name = "Auto Fire Indicator", Side = "Left"}) do
            TFOVSection:Toggle({Name = "Show FOV Circle", Flag = "Trigger/FOV/Enabled", Value = true})
            TFOVSection:Toggle({Name = "Fill Circle", Flag = "Trigger/FOV/Filled", Value = false})
            TFOVSection:Colorpicker({Name = "Circle Color", Flag = "Trigger/FOV/Color", Value = {0.0833333358168602, 0.6666666269302368, 1, 0.25, false}})
            TFOVSection:Slider({Name = "Circle Quality", Flag = "Trigger/FOV/NumSides", Min = 3, Max = 100, Value = 14})
            TFOVSection:Slider({Name = "Line Thickness", Flag = "Trigger/FOV/Thickness", Min = 1, Max = 10, Value = 2})
        end
    end
    local VisualsSection = Sp3arParvus.Utilities:ESPSection(Window, "Visuals", "ESP/Player", true, true, true, true, true, true) do
        VisualsSection:Colorpicker({Name = "Teammate Highlight", Flag = "ESP/Player/Ally", Value = {0.55, 0.85, 1, 0, false}})
        VisualsSection:Colorpicker({Name = "Enemy Highlight", Flag = "ESP/Player/Enemy", Value = {0, 0.9, 1, 0, false}})
        VisualsSection:Toggle({Name = "Distinguish Teams", Flag = "ESP/Player/TeamCheck", Value = false})
        VisualsSection:Toggle({Name = "Use Game Team Colors", Flag = "ESP/Player/TeamColor", Value = false})
    end

    -- ============================================================
    -- MISCELLANEOUS TAB
    -- ============================================================
    local MiscTab = Window:Tab({Name = "Miscellaneous"}) do
        local UtilitySection = MiscTab:Section({Name = "Utility Features", Side = "Left"}) do
            UtilitySection:Toggle({Name = "Performance Display", Flag = "Misc/PerformanceDisplay", Value = false, Callback = function(Value)
                if Value then
                    CreatePerformanceDisplay()
                    UpdatePerformanceDisplay()
                elseif performanceLabel then
                    performanceLabel.Visible = false
                end
            end})

            UtilitySection:Toggle({Name = "Closest Player Tracker", Flag = "Misc/ClosestPlayerTracker", Value = false, Callback = function(Value)
                if Value then
                    CreateClosestPlayerTracker()
                    UpdateClosestPlayerTracker()
                elseif closestPlayerTrackerLabel then
                    closestPlayerTrackerLabel.Visible = false
                end
            end})

            UtilitySection:Toggle({Name = "Br3ak3r (Part Breaker)", Flag = "Misc/Br3ak3r", Value = false, Callback = function(Value)
                if Value then
                    CreateHoverHighlight()
                elseif hoverHL then
                    hoverHL.Enabled = false
                end
            end})

            UtilitySection:Label({Text = "Br3ak3r Controls:"})
            UtilitySection:Label({Text = "  Ctrl + LMB: Break part under cursor"})
            UtilitySection:Label({Text = "  Ctrl + Z: Undo last break (max 25)"})
            UtilitySection:Label({Text = "  Ctrl (hold): Preview part to break"})
        end

        local ScriptControlSection = MiscTab:Section({Name = "Script Control", Side = "Right"}) do
            ScriptControlSection:Label({Text = string.format("Version: %s", SP3ARPARVUS_VERSION)})
            ScriptControlSection:Divider()

            ScriptControlSection:Button({Name = "Reload Script", Callback = function()
                ReloadScript()
            end})

            ScriptControlSection:Label({Text = "Reloads the entire script"})
            ScriptControlSection:Label({Text = "Useful for fixing broken state"})
            ScriptControlSection:Divider()

            ScriptControlSection:Button({Name = "Shutdown Script", Callback = function()
                ShutdownScript()
            end})

            ScriptControlSection:Label({Text = "Completely unloads script"})
            ScriptControlSection:Label({Text = "Cleans up all resources"})
        end
    end
    Sp3arParvus.Utilities:SettingsSection(Window, "RightShift", true)
end

Sp3arParvus.Utilities.InitAutoLoad(Window)

ProjectileSpeed = Window.Flags["Prediction/Velocity"]
ProjectileGravity = Window.Flags["Prediction/GravityForce"]
GravityCorrection = Window.Flags["Prediction/GravityMultiplier"]

Sp3arParvus.Utilities:SetupWatermark(Window)
Sp3arParvus.Utilities:SetupLighting(Window.Flags)
Sp3arParvus.Utilities.Drawing.SetupCursor(Window)
Sp3arParvus.Utilities.Drawing.SetupCrosshair(Window.Flags)
Sp3arParvus.Utilities.Drawing.SetupFOV("Aimbot", Window.Flags)
Sp3arParvus.Utilities.Drawing.SetupFOV("Trigger", Window.Flags)
Sp3arParvus.Utilities.Drawing.SetupFOV("SilentAim", Window.Flags)

local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Blacklist
WallCheckParams.IgnoreWater = true

local function Raycast(Origin, Direction, Filter)
    WallCheckParams.FilterDescendantsInstances = Filter
    return Workspace:Raycast(Origin, Direction, WallCheckParams)
end
local function InEnemyTeam(Enabled, Player)
    if not Enabled then return true end
    return LocalPlayer.Team ~= Player.Team
end
local function WithinReach(Enabled, Distance, Limit)
    if not Enabled then return true end
    return Distance < Limit
end
local function ObjectOccluded(Enabled, Origin, Position, Object)
    if not Enabled then return false end
    return Raycast(Origin, Position - Origin, {Object, LocalPlayer.Character})
end
local function SolveTrajectory(Origin, Velocity, Time, Gravity)
    -- Gravity is a scalar (number), so we apply it only to Y-axis
    -- Negative because gravity pulls down
    local GravityVector = Vector3.new(0, -Gravity * Time * Time / GravityCorrection, 0)
    return Origin + Velocity * Time + GravityVector
end
local function GetClosest(Enabled,
    TeamCheck, VisibilityCheck, DistanceCheck,
    DistanceLimit, FieldOfView, Priority, BodyParts,
    PredictionEnabled
)

    if not Enabled then return end
    local CameraPosition, Closest = Camera.CFrame.Position, nil
    for Index, Player in ipairs(PlayerService:GetPlayers()) do
        if Player == LocalPlayer then continue end

        local Character = Player.Character if not Character then continue end
        if not InEnemyTeam(TeamCheck, Player) then continue end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid then continue end if Humanoid.Health <= 0 then continue end

        if Priority == "Random" then
            Priority = BodyParts[math.random(#BodyParts)]
            BodyPart = Character:FindFirstChild(Priority)
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
            BodyPart = Character:FindFirstChild(Priority)
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

        for Index, BodyPart in ipairs(BodyParts) do
            BodyPart = Character:FindFirstChild(BodyPart)
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
local function AimAt(Hitbox, Sensitivity)
    if not Hitbox then return end
    if not mousemoverel then return end
    local MouseLocation = UserInputService:GetMouseLocation()

    mousemoverel(
        (Hitbox[4].X - MouseLocation.X) * Sensitivity,
        (Hitbox[4].Y - MouseLocation.Y) * Sensitivity
    )
end

local OldIndex = nil
if hookmetamethod and checkcaller then
    OldIndex = hookmetamethod(game, "__index", function(Self, Index)
        if checkcaller() then return OldIndex(Self, Index) end

        if SilentAim and math.random(100) <= Window.Flags["SilentAim/HitChance"] then
            local Mode = Window.Flags["SilentAim/Mode"]
            if Self == Mouse then
                if Index == "Target" and table.find(Mode, Index) then
                    return SilentAim[3]
                elseif Index== "Hit" and table.find(Mode, Index) then
                    return SilentAim[3].CFrame
                end
            end
        end

        return OldIndex(Self, Index)
    end)
end

local OldNamecall = nil
if hookmetamethod and checkcaller and getnamecallmethod then
    OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
        if checkcaller() then return OldNamecall(Self, ...) end

        if SilentAim and math.random(100) <= Window.Flags["SilentAim/HitChance"] then
            local Args, Method, Mode = {...}, getnamecallmethod(), Window.Flags["SilentAim/Mode"]

            if Self == Workspace then
                if Method == "Raycast" and table.find(Mode, Method) then
                    Args[2] = SilentAim[3].Position - Args[1]
                    return OldNamecall(Self, unpack(Args))
                elseif (Method == "FindPartOnRayWithIgnoreList" and table.find(Mode, Method))
                or (Method == "FindPartOnRayWithWhitelist" and table.find(Mode, Method))
                or (Method == "FindPartOnRay" and table.find(Mode, Method)) then
                    Args[1] = Ray.new(Args[1].Origin, SilentAim[3].Position - Args[1].Origin)
                    return OldNamecall(Self, unpack(Args))
                end
            elseif Self == Camera then
                if (Method == "ScreenPointToRay" and table.find(Mode, Method))
                or (Method == "ViewportPointToRay" and table.find(Mode, Method)) then
                    return Ray.new(SilentAim[3].Position, SilentAim[3].Position - Camera.CFrame.Position)
                elseif (Method == "WorldToScreenPoint" and table.find(Mode, Method))
                or (Method == "WorldToViewportPoint" and table.find(Mode, Method)) then
                    Args[1] = SilentAim[3].Position return OldNamecall(Self, unpack(Args))
                end
            end
        end

        return OldNamecall(Self, ...)
    end)
end

Sp3arParvus.Utilities.NewThreadLoop(0, function()
    if not (Aimbot or Window.Flags["Aimbot/AlwaysEnabled"]) then return end

    AimAt(GetClosest(
        Window.Flags["Aimbot/Enabled"],
        Window.Flags["Aimbot/TeamCheck"],
        Window.Flags["Aimbot/VisibilityCheck"],
        Window.Flags["Aimbot/DistanceCheck"],
        Window.Flags["Aimbot/DistanceLimit"],
        Window.Flags["Aimbot/FOV/Radius"],
        Window.Flags["Aimbot/Priority"][1],
        Window.Flags["Aimbot/BodyParts"],
        Window.Flags["Aimbot/Prediction"]
    ), Window.Flags["Aimbot/Sensitivity"] / 100)
end)
Sp3arParvus.Utilities.NewThreadLoop(0, function()
    SilentAim = GetClosest(
        Window.Flags["SilentAim/Enabled"],
        Window.Flags["SilentAim/TeamCheck"],
        Window.Flags["SilentAim/VisibilityCheck"],
        Window.Flags["SilentAim/DistanceCheck"],
        Window.Flags["SilentAim/DistanceLimit"],
        Window.Flags["SilentAim/FOV/Radius"],
        Window.Flags["SilentAim/Priority"][1],
        Window.Flags["SilentAim/BodyParts"],
        Window.Flags["SilentAim/Prediction"]
    )
end)
Sp3arParvus.Utilities.NewThreadLoop(0, function()
    if not (Trigger or Window.Flags["Trigger/AlwaysEnabled"]) then return end
    if isrbxactive and not isrbxactive() then return end
    if not mouse1press or not mouse1release then return end

    local TriggerClosest = GetClosest(
        Window.Flags["Trigger/Enabled"],
        Window.Flags["Trigger/TeamCheck"],
        Window.Flags["Trigger/VisibilityCheck"],
        Window.Flags["Trigger/DistanceCheck"],
        Window.Flags["Trigger/DistanceLimit"],
        Window.Flags["Trigger/FOV/Radius"],
        Window.Flags["Trigger/Priority"][1],
        Window.Flags["Trigger/BodyParts"],
        Window.Flags["Trigger/Prediction"]
    )

    if not TriggerClosest then return end
    task.wait(Window.Flags["Trigger/Delay"])
    mouse1press()

    if Window.Flags["Trigger/HoldMouseButton"] then
        while task.wait() do
            TriggerClosest = GetClosest(
                Window.Flags["Trigger/Enabled"],
                Window.Flags["Trigger/TeamCheck"],
                Window.Flags["Trigger/VisibilityCheck"],
                Window.Flags["Trigger/DistanceCheck"],
                Window.Flags["Trigger/DistanceLimit"],
                Window.Flags["Trigger/FOV/Radius"],
                Window.Flags["Trigger/Priority"][1],
                Window.Flags["Trigger/BodyParts"],
                Window.Flags["Trigger/Prediction"]
            )

            if not TriggerClosest or not Trigger then break end
        end
    end

    mouse1release()
end)

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

-- Track CharacterAdded connections for proper cleanup on player leave/respawn
local CharacterAddedConnections = {}

-- Function to set up ESP for a player with CharacterAdded listener
local function SetupPlayerESP(Player)
    if Player == LocalPlayer then return end

    -- Clean up any existing connection for this player (prevents accumulation)
    local ExistingConnection = CharacterAddedConnections[Player]
    if ExistingConnection then
        ExistingConnection:Disconnect()
        CharacterAddedConnections[Player] = nil
    end

    -- Create initial ESP
    Sp3arParvus.Utilities.Drawing:AddESP(Player, "Player", "ESP/Player", Window.Flags)

    -- Set up CharacterAdded listener to rebuild ESP on respawn
    local function OnCharacterAdded(Character)
        -- Wait for character to fully load, especially for distant characters
        task.wait(0.3)

        -- Retry mechanism: wait for HumanoidRootPart to ensure character is fully loaded
        local maxRetries = 5
        local retryCount = 0
        while retryCount < maxRetries do
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                break
            end
            retryCount = retryCount + 1
            task.wait(0.2)
        end

        -- Rebuild ESP with fresh character reference
        pcall(function()
            Sp3arParvus.Utilities.Drawing:RebuildESP(Player, "Player", "ESP/Player", Window.Flags)
        end)
    end

    -- Connect to CharacterAdded
    local Connection = Player.CharacterAdded:Connect(OnCharacterAdded)
    CharacterAddedConnections[Player] = Connection

    -- If player already has a character, set up ESP for it
    if Player.Character then
        task.spawn(function()
            OnCharacterAdded(Player.Character)
        end)
    end
end

-- Set up ESP for existing players
for Index, Player in pairs(PlayerService:GetPlayers()) do
    SetupPlayerESP(Player)
end

-- Set up ESP for new players
PlayerService.PlayerAdded:Connect(function(Player)
    SetupPlayerESP(Player)
end)

-- Clean up ESP and connections when player leaves
PlayerService.PlayerRemoving:Connect(function(Player)
    -- Disconnect CharacterAdded listener
    local Connection = CharacterAddedConnections[Player]
    if Connection then
        pcall(function() Connection:Disconnect() end)
        CharacterAddedConnections[Player] = nil
    end

    -- Remove ESP and clean up all tracking data
    Sp3arParvus.Utilities.Drawing:RemoveESP(Player)

    -- Ensure any tracking counters are reset without touching module locals
    local DrawingUtilities = Sp3arParvus.Utilities.Drawing
    if DrawingUtilities and DrawingUtilities.ResetESPCounters then
        DrawingUtilities:ResetESPCounters(Player)
    end
end)

-- ============================================================
-- CONTINUOUS CHARACTER MONITORING
-- ============================================================
-- Periodically check for players whose characters have loaded after initial setup
-- This handles cases where characters stream in from far distances
local CharacterMonitorInterval = 2 -- Check every 2 seconds
local LastCharacterStates = {} -- Track whether each player had a character last check

task.spawn(function()
    while task.wait(CharacterMonitorInterval) do
        for _, Player in pairs(PlayerService:GetPlayers()) do
            if Player ~= LocalPlayer then
                local hasCharacterNow = Player.Character ~= nil
                local hadCharacterBefore = LastCharacterStates[Player]

                -- If player now has a character but didn't before, rebuild ESP
                if hasCharacterNow and not hadCharacterBefore then
                    pcall(function()
                        Sp3arParvus.Utilities.Drawing:RebuildESP(Player, "Player", "ESP/Player", Window.Flags)
                    end)
                end

                -- Update state
                LastCharacterStates[Player] = hasCharacterNow
            end
        end
    end
end)

-- Clean up character state tracking when players leave
PlayerService.PlayerRemoving:Connect(function(Player)
    LastCharacterStates[Player] = nil
end)

-- ============================================================
-- AGGRESSIVE ESP REFRESH SYSTEM
-- ============================================================
-- Force rebuild ESP for all players periodically to catch any edge cases
-- This ensures ESP always works even on very large maps with streaming issues
local AggressiveRefreshInterval = 10 -- Full refresh every 10 seconds
local PlayerRefreshIndex = 1

task.spawn(function()
    while task.wait(AggressiveRefreshInterval) do
        local players = PlayerService:GetPlayers()
        -- Refresh one player at a time to avoid performance spikes
        if #players > 0 then
            -- Cycle through players
            if PlayerRefreshIndex > #players then
                PlayerRefreshIndex = 1
            end

            local Player = players[PlayerRefreshIndex]
            if Player and Player ~= LocalPlayer and Player.Character then
                pcall(function()
                    -- Only rebuild if ESP exists but might be stale
                    if Sp3arParvus.Utilities.Drawing.ESP[Player] then
                        Sp3arParvus.Utilities.Drawing:RebuildESP(Player, "Player", "ESP/Player", Window.Flags)
                    end
                end)
            end

            PlayerRefreshIndex = PlayerRefreshIndex + 1
        end
    end
end)

-- ============================================================
-- INPUT HANDLING FOR BR3AK3R
-- ============================================================
CreateHoverHighlight()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Track Ctrl key
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        CTRL_HELD = true
    end

    -- Br3ak3r: Ctrl + Left Mouse Button to break part
    if Window.Flags["Misc/Br3ak3r"] and CTRL_HELD and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local origin, direction = GetMouseRay()
        if origin and direction then
            local hit = WorldRaycast(origin, direction)
            if hit and hit.Instance and hit.Instance:IsA("BasePart") then
                MarkBroken(hit.Instance)
            end
        end
    end

    -- Br3ak3r: Ctrl + Z to undo
    if Window.Flags["Misc/Br3ak3r"] and CTRL_HELD and input.KeyCode == Enum.KeyCode.Z then
        UnbreakLast()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    -- Release Ctrl key
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        CTRL_HELD = false
    end
end)

-- ============================================================
-- MAIN UPDATE LOOP
-- ============================================================
local nearestPlayerAccum = 0
local closestTrackerAccum = 0

RunService.Heartbeat:Connect(function(dt)
    -- Update nearest player for Closest Player Tracker (throttled to 20 Hz)
    if Window.Flags["Misc/ClosestPlayerTracker"] then
        nearestPlayerAccum = nearestPlayerAccum + dt
        if nearestPlayerAccum >= 0.05 then
            nearestPlayerAccum = 0
            pcall(UpdateNearestPlayer) -- Protect against errors
        end
    else
        -- Reset accumulator when disabled to avoid stale state
        nearestPlayerAccum = 0
        nearestPlayerRef = nil
    end

    -- Update Closest Player Tracker display (throttled to 10 Hz)
    closestTrackerAccum = closestTrackerAccum + dt
    if closestTrackerAccum >= 0.1 then
        closestTrackerAccum = 0
        pcall(UpdateClosestPlayerTracker) -- Protect against errors
    end

    -- Update Performance Display (throttled to 2 Hz)
    perfAccum = perfAccum + dt
    if perfAccum >= 0.5 then
        perfAccum = 0
        UpdatePerformanceDisplay()
    end

    -- Br3ak3r hover preview
    if Window.Flags["Misc/Br3ak3r"] and CTRL_HELD and hoverHL then
        local origin, direction = GetMouseRay()
        if origin and direction then
            local result = WorldRaycast(origin, direction)
            local part = result and result.Instance

            if part and part:IsA("BasePart") and not brokenSet[part] then
                hoverHL.Adornee = part
                hoverHL.Enabled = true
            else
                hoverHL.Enabled = false
            end
        else
            hoverHL.Enabled = false
        end
    elseif hoverHL then
        hoverHL.Enabled = false
    end
end)

-- Mark as loaded
Sp3arParvus.Loaded = true
print(string.format("[Sp3arParvus v%s] Initialization complete. All systems ready.", SP3ARPARVUS_VERSION))
