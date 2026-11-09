-- prison life

--#region checks

    if not game:IsLoaded() then 
        game.Loaded:Wait()
    end

    if not LPH_OBFUSCATED then 
        local FakeFunction = function(...)
            return(...)
        end;

        LPH_NO_VIRTUALIZE = FakeFunction;
        LPH_NO_UPVALUES = FakeFunction;
        LPH_JIT = FakeFunction;
        LPH_JIT_MAX = FakeFunction;
    end;

--#endregion



--#region defs

    local Camera = workspace.CurrentCamera
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players") 
    local LocalPlayer = Players.LocalPlayer 
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local _Teams = game:GetService("Teams")
    local SoundService = game:GetService("SoundService")

    local _Modules = { -- Modules.

    };

    local Remotes = {
        ShootEvent = ReplicatedStorage.GunRemotes.ShootEvent;
    };

    local _cheatinfo = {
        autofireconnection = nil;
        offset = Vector3.new(0, 0, 0);
        didmanip = false;
        target = nil;
        manip_corners = {
            Vector3.new(0, 0, 0), --center
            Vector3.new(0, 0, 1), --front
            Vector3.new(0, 0, -1), --back
            
            Vector3.new(0, 1, 0), -- up
            Vector3.new(0, 1, 1), -- up front
            Vector3.new(0, 1, -1), -- up back
            
            
            Vector3.new(0, -1, 0), -- down
            Vector3.new(-1, 0, 0), -- left
            Vector3.new(1, 0, 0), --right
            Vector3.new(-1, 1, 0), -- top lef
            Vector3.new(1, 1, 0), -- top right
            Vector3.new(-1, -1, 0), -- bottom left
            Vector3.new(1, -1, 0), -- bottom right
        };
        box_corners = {
            Vector3.new(-1, -1, -1);
            Vector3.new(1, -1, -1);
            Vector3.new(1, 1, -1);
            Vector3.new(-1, 1, -1);
            Vector3.new(-1, -1, 1);
            Vector3.new(1, -1, 1);
            Vector3.new(1, 1, 1);
            Vector3.new(-1, 1, 1);
        };
        box_faces = {
            -- top
            {1,2}, {2,3}, {3,4}, {4,1},
            -- bottom
            {5,6}, {6,7}, {7,8}, {8,5},
            -- poles/sides/stick whatever
            {1,5}, {2,6}, {3,7}, {4,8}
        };
    }

    --#region hitsounds
        local HitSoundEnabled = false;
        local SelectedHitSound = "Neverlose";
        local HitSoundVolume = 1;
        local ShotAt = setmetatable({}, {__mode = "k"})

        local sounds = {
            ["Neverlose"] = "rbxassetid://8726881116";
            ["TF2"] = "rbxassetid://8255306220";
            ["Gamesense"] = "rbxassetid://4817809188";
            ["Rust"] = "rbxassetid://1255040462";
            ["Bubble"] = "rbxassetid://85730811347567";
            ["Quake"] = "rbxassetid://1455817260";
            ["Among-Us"] = "rbxassetid://7227567562";
            ["Ding"] = "rbxassetid://2868331684";
            ["Minecraft"] = "rbxassetid://6361963422";
            ["Blackout"] = "rbxassetid://3748776946";
            ["Osu!"] = "rbxassetid://7151989073";
            ["Windows XP"] = "rbxassetid://9066167010";
            ["HEADSHOT"] = "rbxassetid://18362692980";
            ["Hitmarker"] = "rbxassetid://705502934";
            ["Plush toy"] = "rbxassetid://136601315351295";
            ["Chomp"] = "rbxassetid://81906463817396";
            ["Gnome"] = "rbxassetid://115441166024380";
            ["Exp"] = "rbxassetid://80611228518495";
            ["Sans"] = "rbxassetid://132322331764933";
            ["Snap"] = "rbxassetid://93172144688075";
            ["Die"] = "rbxassetid://98450680047632";
            ["Mega kill!"] = "rbxassetid://92723765069002";
            ["OOF"] = "rbxassetid://79348298352567";
            ["CSGO Headshot"] = "rbxassetid://18315629371";
            ["MW2019 Killsound"] = "rbxassetid://7644722553";
            ["nn dog"] = "rbxassetid://5902468562";
            ["ar2 body"] = "rbxassetid://2062015952";
            ["ar2 head"] = "rbxassetid://2062016772";
            ["ar2 limb"] = "rbxassetid://6659353525";
            ["bag"] = "rbxassetid://364942410";
            ["bamboo"] = "rbxassetid://3769434519";
            ["bambi"] = "rbxassetid://8437203821";
            ["bameware"] = "rbxassetid://7898991882";
            ["bb hit"] = "rbxassetid://4645745735";
            ["bb kill"] = "rbxassetid://2636743632";
            ["bell"] = "rbxassetid://6534947240";
            ["bonk"] = "rbxassetid://3765689841";
            ["bruh"] = "rbxassetid://4275842574";
            ["cod"] = "rbxassetid://160432334";
            ["crit"] = "rbxassetid://296102734";
            ["headshot"] = "rbxassetid://8418469749";
            ["hl crowbar"] = "rbxassetid://546410481";
        }

        local function MarkShots(Shots)
            for _, v in Shots do
                local Hit = type(v) == 'table' and v[3]

                if typeof(Hit) ~= "Instance" then
                    continue
                end

                local Model = Hit:FindFirstAncestorOfClass("Model")

                if Model then
                    ShotAt[Model] = os.clock()
                end
            end
        end

        local function PlayHitSound()
            local Sound = Instance.new("Sound")
            Sound.SoundId = sounds[SelectedHitSound]
            Sound.Volume = HitSoundVolume
            Sound.Parent = SoundService
            Sound:Play()
            Sound.Ended:Once(function()
                Sound:Destroy()
            end)
        end

        local function HookCharacter(Character)
            local Humanoid = Character:WaitForChild("Humanoid", 5)

            if not Humanoid then
                return
            end

            local LastHealth = Humanoid.Health

            Humanoid.HealthChanged:Connect(function(Health)
                local Shot = ShotAt[Character]

                if HitSoundEnabled and Health < LastHealth and Shot and os.clock() - Shot < 0.5 then
                    PlayHitSound()
                end

                LastHealth = Health
            end)
        end

        local function HookPlayer(plr)
            if plr == LocalPlayer then
                return
            end

            if plr.Character then
                task.spawn(HookCharacter, plr.Character)
            end

            plr.CharacterAdded:Connect(HookCharacter)
        end

        for _, plr in Players:GetPlayers() do
            HookPlayer(plr)
        end

        Players.PlayerAdded:Connect(HookPlayer)

    --#endregion

    local CreateTracer;
    local TracerEnabled = false;
    local TracerSpeed = 900;
    local TracerBend = 0.75;
    local TracerEffect = "Beam";
    local TracerPath = "Curved";

    local SelectedTracer = "Laser 1";

    local Trails = {
        ["Laser 1"] = { Texture = "rbxassetid://7136858729", Width0 = 0.4, Width1 = 0.4, TextureLength = 1, Lifetime = 1 };
        ["Laser 2"] = { Texture = "rbxassetid://6333823534", Width0 = 0.4, Width1 = 0.4, TextureLength = 1, Lifetime = 1 };
        ["DNA"] = { Texture = "rbxassetid://7071778278", Width0 = 0.6, Width1 = 0.6, TextureLength = 12, Lifetime = 1 };
        ["Energy"]  = { Texture = "rbxassetid://5864341017", Width0 = 0.4, Width1 = 0.4, TextureLength = 1, Lifetime = 1 };
    };
--#endregion



--#region library setup
    --local amity = loadstring((game :: any):HttpGet('https://raw.githubusercontent.com/78n/Roblox/refs/heads/main/Lua/Libraries/DataToCode/DataToCode.luau'))()

    local LibraryChunk = loadstring((game :: any):HttpGet("https://raw.githubusercontent.com/skekkstunsua-lgtm/von/refs/heads/main/BullshitLib.lua"))
    if not LibraryChunk then error("negrohax: could not load the UI library") end
    local Library = LibraryChunk()
    
    local EspLibChunk = loadstring((game :: any):HttpGet('https://github.com/skekkstunsua-lgtm/von/raw/refs/heads/main/EspLib.lua'))
    if not EspLibChunk then error("negrohax: could not load the ESP library") end
    local EspLib = EspLibChunk()

    local Window = Library:Window({
        Name = 'negrohaxprism<font color="rgb(126, 192, 255)">.cc</font> | developer  | lifetime',
        Rank = "developer"
    }) 

    do
        local _Watermark = Window:Watermark({
            Name = "negrohax.cc",
            SubName = "negrohax.cc"
        })

        local _KeybindList = Window:KeybindList({
            Name = 'hot<font color="rgb(126, 192, 255)">keys</font>'
        })
    end



    local Pages = {
        CombatPage = Window:Page({Name = "combat"});
        VisualsPage = Window:Page({Name = "visuals"});
        MiscPage = Window:Page({Name = "misc"});
    };

    local Sections = {
        aimbot = Pages.CombatPage:Section({
            Name = 'aimbot';
            Side = 1;
        });
        gunmods = Pages.CombatPage:Section({
            Name = 'gun mods';
            Side = 2;
        });
        exploits = Pages.MiscPage:Section({
            Name = 'exploits';
            Side = 1;
        });
        movement = Pages.MiscPage:Section({
            Name = 'movement';
            Side = 2;
        });
        hit = Pages.MiscPage:Section({
            Name = 'hit';
            Side = 1;
        });
        visuals = Pages.VisualsPage:Section({
            Name = 'world';
            Side = 2;
        });
        Esp = Pages.VisualsPage:Section({
            Name = 'esp';
            Side = 1;
        })
    };

--#endregion



-- Shared team policy for aim, ESP and chams. Unknown teams fall back to
-- same-team exclusion instead of guessing their role.
local CurrentTargetPlayer, CurrentTargetTime = nil, 0
local ShotScanResults = setmetatable({}, {__mode = "k"})
local ResolverSnapshot = nil
local ResolverRunning = false
local function ReportTarget(part)
    local model = part and part:FindFirstAncestorOfClass("Model")
    local plr = model and Players:GetPlayerFromCharacter(model)
    if plr then CurrentTargetPlayer, CurrentTargetTime = plr, os.clock() end
end

local PriorityTeamCheck = true
local AggroThreatRange = 80
-- Role from the team name, memoised per Team instance: this runs several times
-- per player per frame across the aim, ESP and chams code.
local teamRoleCache = setmetatable({}, { __mode = "k" })
local function TeamRole(player)
    local team = player and player.Team
    if team then
        local cached = teamRoleCache[team]
        if cached then return cached end
    end
    local name = team and string.lower(team.Name) or ""
    local role = "unknown"
    if name:find("guard", 1, true) or name:find("police", 1, true) then
        role = "police"
    elseif name:find("crim", 1, true) then
        role = "criminal"
    elseif name:find("inmate", 1, true) or name:find("prisoner", 1, true) then
        role = "prisoner"
    end
    if team then teamRoleCache[team] = role end
    return role
end
local function TargetPriority(player)
    if not player or player == LocalPlayer then return nil end
    if not PriorityTeamCheck then return 1 end
    local localRole, role = TeamRole(LocalPlayer), TeamRole(player)
    if localRole == "police" then
        if role == "criminal" then return 1 end
        if role == "prisoner" then return 2 end
        return nil
    elseif localRole == "criminal" then
        if role == "police" then return 1 end
        return nil
    elseif localRole == "prisoner" then
        if role == "police" then return 1 end
        if role == "criminal" then return 2 end
        return nil
    end
    if LocalPlayer.Team and LocalPlayer.Team == player.Team then return nil end
    return 1
end

-- Guards must not target non-hostile or restrained prisoners. Prefer the
-- game's Hostile attribute; textual icon fallback only applies if absent.
-- The icon fallback walks the whole character with GetDescendants(), and this
-- is asked for every prisoner on every aim/ESP/chams pass. Results are kept for
-- a third of a second per character.
local hostileCache = setmetatable({}, { __mode = "k" })
local function IsHostilePrisoner(plr)
    local model = plr and plr.Character
    if not model then return false end
    if model:GetAttribute("Cuffed") == true or model:GetAttribute("Arrested") == true then
        return false
    end
    local cached = hostileCache[model]
    if cached and os.clock() - cached.time < 0.33 then return cached.value end
    local angryIcon, cuffIcon = false, false
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local text = obj.Text or ""
            local lower = string.lower(text)
            if lower:find("cuff", 1, true) or text:find("🔒", 1, true)
                or text:find("⛓", 1, true) or text:find("🔗", 1, true) then
                cuffIcon = true
            end
            if text:find("💢", 1, true) or text:find("😡", 1, true) then
                angryIcon = true
            end
        end
    end
    local result
    if cuffIcon then
        result = false
    else
        local hostile = model:GetAttribute("Hostile")
        if hostile ~= nil then
            result = hostile == true
        else
            result = angryIcon
        end
    end
    hostileCache[model] = { value = result, time = os.clock() }
    return result
end

-- Combat-only priority; visual filtering remains independent.
local function CombatPriority(plr)
    if not plr or plr == LocalPlayer then return nil end
    local localRole, targetRole = TeamRole(LocalPlayer), TeamRole(plr)
    if localRole == "police" and targetRole == "prisoner" and not IsHostilePrisoner(plr) then
        return nil
    end
    local priority = TargetPriority(plr)
    if not priority then return nil end
    if localRole == "police" and targetRole == "prisoner" then
        local own = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local model = plr.Character
        local root = model and model:FindFirstChild("HumanoidRootPart")
        if own and root and (root.Position - own.Position).Magnitude <= AggroThreatRange then
            return 0
        end
    end
    return priority
end

local function AAOffset()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAOffset) == "function" then
        local ok, value = pcall(env.AdvancedAAOffset)
        if ok and typeof(value) == "Vector3" then return value end
    end
    return Vector3.zero
end

local function AARealPartPosition(part)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAUnshiftPosition) == "function" then
        local ok, position = pcall(env.AdvancedAAUnshiftPosition, part.Position)
        if ok and typeof(position) == "Vector3" then return position end
    end
    return part.Position - AAOffset()
end

-- Pose the server currently believes we are in. While UG/AA displaces the
-- character this is the displaced pose, and it is exactly what a shot origin
-- has to match or the server drops the shot.
local function AAServerPartPosition(part)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAServerPosition) == "function" then
        local ok, position = pcall(env.AdvancedAAServerPosition, part.Position)
        if ok and typeof(position) == "Vector3" then return position end
    end
    return part.Position
end

-- How far we are currently displaced (0 = synced).
local function AADesync()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAADesync) == "function" then
        local ok, value = pcall(env.AdvancedAADesync)
        if ok and type(value) == "number" then return value end
    end
    return 0
end

-- enabled / current displacement, for the panel readout.
local function AAStatus()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAStatus) == "function" then
        local ok, enabled, offset = pcall(env.AdvancedAAStatus)
        if ok then return enabled == true, tonumber(offset) or 0 end
    end
    return false, 0
end

-- Drop AA entirely for a few seconds. This is the failsafe path and the ONLY
-- thing that interrupts UG mid-fight: no offset at all means every shot comes
-- from the real pose. There is no per-shot sync any more.
local function AAForceSync(seconds)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAForceSync) == "function" then
        pcall(env.AdvancedAAForceSync, seconds or 2)
    end
end

-- Which pose the SERVER currently holds for us, with network lag included:
--   "server"     UG has been on long enough that the server has the underground
--                pose -> shots must come from the underground head.
--   "real"       UG has been off long enough that the server has the real pose
--                -> shots must come from the real head.
--   "transition" the server is still catching up -> any shot fired now is an
--                invalid (wrong origin), so the aim waits a few frames.
local function AAShotState()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAShotState) == "function" then
        local ok, state = pcall(env.AdvancedAAShotState)
        if ok and type(state) == "string" then return state end
    end
    return "real"
end

-- Shot peek: briefly hold the real pose so a shot the underground head cannot
-- make is fired (and validated) from the real head instead. Returns false when
-- peek is off or on cooldown.
local function AAPeek(seconds)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAPeek) == "function" then
        local ok, granted = pcall(env.AdvancedAAPeek, seconds)
        return ok and granted == true
    end
    return false
end

-- How long the server needs to receive a pose change (ping based).
local function AASyncWindow()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAASyncWindow) == "function" then
        local ok, value = pcall(env.AdvancedAASyncWindow)
        if ok and type(value) == "number" then return value end
    end
    return 0.15
end

-- The origin a shot has to be built from. While displaced the server holds the
-- displaced pose, so shooting from the "real" head is what produces invalid
-- shots - which is why UG used to look like it never hit anything.
local function ShotOrigin(head)
    if not head then return nil end
    if AADesync() > 0.25 then return AAServerPartPosition(head) end
    return AARealPartPosition(head)
end

-- Rays must ignore the local AA visual copy: it sits at the real position and
-- used to block our own silent-aim, hitscan and manipulation casts.
--
-- This used to scan workspace and allocate a new table for every single ray,
-- which is the hottest path in the script (every scan sample, every probe, every
-- frame of square/prism). The table is now reused and refreshed at most every
-- 0.4s or when the character changes.
local ignoreList, ignoreCharacter, ignoreTime = {}, nil, 0
local function AAIgnoreList()
    local character = LocalPlayer.Character
    local now = os.clock()
    if ignoreCharacter == character and now - ignoreTime < 0.4 and ignoreList[1] == character then
        return ignoreList
    end
    table.clear(ignoreList)
    local count = 0
    if character then
        count = count + 1
        ignoreList[count] = character
    end
    for _, obj in ipairs(workspace:GetChildren()) do
        local name = obj.Name
        if name == "AdvancedAALocalVisual" or name == "WallPenFX"
            or name == "HitboxExpanderHulls" or name == "LatencyGhost" then
            count = count + 1
            ignoreList[count] = obj
        end
    end
    ignoreCharacter, ignoreTime = character, now
    return ignoreList
end

-- Body parts sampled by the aim. Hoisted out of EvaluateShot, which used to
-- rebuild this literal array on every call (every player, every frame).
local RIG_PART_NAMES = { "Head", "UpperTorso", "Torso", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm",
    "Left Leg", "Right Leg" }

-- Shared with the aim, tracer and visual code below.
local HitboxExpander = { Enabled = false, Size = 1.5, Visual = true, Samples = 12,
    Color = Color3.fromRGB(120, 190, 255), Transparency = 0.8,
    State = {}, Cache = {} }

-- One RaycastParams object for every hull probe instead of a fresh one per call.
local hbeParams = RaycastParams.new()
hbeParams.FilterType = Enum.RaycastFilterType.Exclude
hbeParams.IgnoreWater = true

-- Samples the expanded hull around a target and returns the first point that
-- has a clear line back to the origin. Visible hull means "try to shoot".
function HitboxExpander.Probe(player, origin)
    if not player or typeof(origin) ~= "Vector3" then return nil end
    local character = player.Character
    local body = character and (character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart"))
    if not body then return nil end
    local now = os.clock()
    local cached = HitboxExpander.Cache[player]
    if cached and now - cached.time < 0.08 then return cached.point, cached.part end
    local params = hbeParams
    params.FilterDescendantsInstances = AAIgnoreList()
    local radius = math.max(HitboxExpander.Size, 0.05)
    local count = math.clamp(math.floor(HitboxExpander.Samples), 4, 64)
    local golden = math.pi * (3 - math.sqrt(5))
    local bestPoint, bestPart
    for i = 1, count do
        local y = 1 - 2 * ((i - 0.5) / count)
        local radial = math.sqrt(math.max(0, 1 - y * y))
        local angle = i * golden
        local unit = Vector3.new(math.cos(angle) * radial, y, math.sin(angle) * radial)
        local half = body.Size * 0.5 + Vector3.new(radius, radius, radius)
        local point = body.CFrame:PointToWorldSpace(Vector3.new(unit.X * half.X, unit.Y * half.Y, unit.Z * half.Z))
        local delta = point - origin
        if delta.Magnitude > 0.01 then
            local hit = workspace:Raycast(origin, delta * 1.01, params)
            if not hit or hit.Instance:IsDescendantOf(character) then
                bestPoint, bestPart = point, body
                break
            end
        end
    end
    HitboxExpander.State[player] = { visible = bestPoint ~= nil, time = now }
    HitboxExpander.Cache[player] = { point = bestPoint, part = bestPart, time = now }
    return bestPoint, bestPart
end

--#region wall penetration (local prediction only)
-- Replaces the old one-ray check. The old check measured from the target point
-- back to the wall's inner face, so it reported the distance to the wall
-- instead of the wall's own thickness, could not describe a two-part wall at
-- all (it demanded the entry and exit hit be the *same* part), and treated any
-- thin decoration that the ray touched as infinitely thick cover.
--
-- This walks the ray from the muzzle to the shot point and adds up every solid
-- span it has to cross: wall thickness per layer, layer count, and the exact
-- entry/exit faces. Local prediction only - the server still validates shots,
-- so this decides *when it is worth trying*, and aims at the point that has
-- the least cover in front of it.
-- setmetatable with __mode returns a weak-table type that Studio's checker will
-- not accept as a plain table literal field, so the weakening happens here and
-- the field itself stays a normal table.
local function WeakKeyedTable()
    return setmetatable({}, { __mode = "k" })
end

local WallPen = {
    Enabled = false,
    ShowMarker = true,
    -- Derived from the single budget slider below (percent of the full budget).
    Budget = 25,
    MaxThickness = 1.25,
    MaxLayers = 2,
    -- Panel readout of the most recent measurement.
    Last = { label = "idle", thickness = 0, layers = 0, time = 0 },
    -- Written at runtime; declared here so the type checker knows the keys.
    BackoffUntil = 0,
    _markerTime = 0,
    Cache = WeakKeyedTable(),
}

local WALLPEN_MIN_SPAN = 0.02
local WALLPEN_FULL_THICKNESS = 5
local WALLPEN_FULL_LAYERS = 6

-- One slider owns both limits so the layer budget can never sit above what the
-- thickness budget allows: 25% = 1.25 studs / 2 layers, 100% = 5 studs / 6.
function WallPen.ApplyBudget(percent)
    local value = tonumber(percent) or 25
    local fraction = math.clamp(value / 100, 0.01, 1)
    WallPen.Budget = value
    WallPen.MaxThickness = WALLPEN_FULL_THICKNESS * fraction
    WallPen.MaxLayers = math.max(1, math.ceil(WALLPEN_FULL_LAYERS * fraction))
    table.clear(WallPen.Cache)
    return WallPen.MaxThickness, WallPen.MaxLayers
end

WallPen.ApplyBudget(25)

local wallPenParams = RaycastParams.new()
wallPenParams.FilterType = Enum.RaycastFilterType.Exclude
wallPenParams.IgnoreWater = true
pcall(function() wallPenParams.CollisionGroup = "ClientBullet" end)

-- The ignore list is a workspace scan, so it is shared for a few frames instead
-- of being rebuilt for every single probe.
local wallIgnore, wallIgnoreTime = nil, 0
local function WallParams()
    local now = os.clock()
    if not wallIgnore or now - wallIgnoreTime > 0.4 then
        wallIgnore = AAIgnoreList()
        wallIgnoreTime = now
        wallPenParams.FilterDescendantsInstances = wallIgnore
    end
    return wallPenParams
end

-- Cover is something a bullet is actually stopped by. Decals, non-colliding
-- props and nearly invisible helpers are stepped through instead of being
-- counted as a 100 stud wall, which is what silently killed wallpen before.
local function IsCover(part)
    if not part or not part:IsA("BasePart") then return false end
    if not part.CanCollide then return false end
    if part.Transparency >= 0.9 then return false end
    return true
end

-- Distance from `from` to the face where the ray leaves `part`, from a slab
-- test in the part's own space. nil means "not measurable" (terrain, mesh
-- hulls), and the caller refuses to claim penetration through those instead of
-- inventing a number.
local function ExitDistance(part, from, unit)
    if part:IsA("Terrain") then return nil end
    local ok, cf, size = pcall(function() return part.CFrame, part.Size end)
    if not ok or not cf or not size then return nil end
    local origin = cf:PointToObjectSpace(from)
    local dir = cf:VectorToObjectSpace(unit)
    local half = size * 0.5
    local enter, leave = -math.huge, math.huge
    for _, key in ipairs({ "X", "Y", "Z" }) do
        local o, d, h = origin[key], dir[key], half[key]
        if math.abs(d) < 1e-6 then
            if math.abs(o) > h + 1e-3 then return nil end
        else
            local t1, t2 = (-h - o) / d, (h - o) / d
            if t1 > t2 then t1, t2 = t2, t1 end
            if t1 > enter then enter = t1 end
            if t2 < leave then leave = t2 end
            if enter > leave then return nil end
        end
    end
    if leave <= 0 then return nil end
    local span = leave - math.max(enter, 0)
    return math.max(span, WALLPEN_MIN_SPAN)
end

-- Walks origin -> point and returns:
--   state     "clear" (unobstructed line to the target)
--             "blocked" (measurable cover in front of the target)
--             "miss"    (the ray never reached the target at all)
--   thickness total solid span crossed, in studs
--   layers    how many separate solid spans that was
--   entry/exit the faces of the first/last span (for the marker)
function WallPen.Trace(origin, point, model)
    local direction = point - origin
    local distance = direction.Magnitude
    if distance < 0.1 then
        return { state = "miss", thickness = math.huge, layers = 0 }
    end
    local unit = direction / distance
    local params = WallParams()

    local cursor = origin
    local thickness, layers = 0, 0
    local entryPart, entryPos, exitPos, reachedPart
    -- Two extra probes past the layer budget so an over-budget wall still gets
    -- a real measured number instead of "unknown".
    local guard = math.max(WallPen.MaxLayers, 1) + 2

    for _ = 1, guard do
        local toPoint = point - cursor
        if toPoint.Magnitude < 0.06 then break end
        local hit = workspace:Raycast(cursor, toPoint, params)
        if not hit then break end
        if model and hit.Instance:IsDescendantOf(model) then
            reachedPart = hit.Instance
            break
        end

        local part = hit.Instance
        if IsCover(part) then
            layers += 1
            local span = ExitDistance(part, hit.Position, unit)
            if not span then
                -- Solid we cannot measure: never claim we can shoot through it.
                return { state = "blocked", thickness = math.huge, layers = layers,
                    part = part, entry = hit.Position, exit = hit.Position }
            end
            thickness += span
            if not entryPart then
                entryPart, entryPos = part, hit.Position
            end
            exitPos = hit.Position + unit * span
            if thickness > WallPen.MaxThickness * 1.5 then
                -- Far over budget: stop paying for rays, keep the measurement.
                return { state = "blocked", thickness = thickness, layers = layers,
                    part = entryPart, entry = entryPos, exit = exitPos }
            end
            -- Step just past the exit face so the next cast sees the next layer.
            cursor = exitPos + unit * 0.02
        else
            -- Decoration / non-solid: look straight past it.
            cursor = hit.Position + unit * 0.02
        end
    end

    if layers == 0 then
        if reachedPart then
            return { state = "clear", thickness = 0, layers = 0, reached = reachedPart }
        end
        return { state = "miss", thickness = math.huge, layers = 0 }
    end
    return { state = "blocked", thickness = thickness, layers = layers,
        part = entryPart, entry = entryPos, exit = exitPos, reached = reachedPart }
end

-- Same trace, cached briefly per target part: silent aim, the namecall rewrite
-- and the ragebot all ask the same question inside one frame.
function WallPen.Probe(part, origin, point, model)
    -- Numeric comparison instead of building a format string for every probe:
    -- the aim asks for the same handful of points many times per frame and the
    -- old key allocation was showing up in the hot path.
    local now = os.clock()
    local cached = WallPen.Cache[part]
    if cached and now - cached.time < 0.035
        and math.abs(cached.ox - origin.X) < 0.15 and math.abs(cached.oy - origin.Y) < 0.15
        and math.abs(cached.oz - origin.Z) < 0.15 and math.abs(cached.px - point.X) < 0.15
        and math.abs(cached.py - point.Y) < 0.15 and math.abs(cached.pz - point.Z) < 0.15 then
        return cached.result
    end
    local result = WallPen.Trace(origin, point, model)
    WallPen.Cache[part] = { ox = origin.X, oy = origin.Y, oz = origin.Z,
        px = point.X, py = point.Y, pz = point.Z, time = now, result = result }
    return result
end

function WallPen.CanPenetrate(thickness, layers)
    if not WallPen.Enabled then return false end
    -- Set by the aim failsafe when shots stop registering: wallpen attempts are
    -- the most likely cause, so quiet them down for a moment instead of
    -- spamming rejected shots.
    if os.clock() < (WallPen.BackoffUntil or 0) then return false end
    if not thickness or thickness == math.huge then return false end
    if thickness > WallPen.MaxThickness + 1e-3 then return false end
    return (layers or 1) >= 1 and (layers or 1) <= WallPen.MaxLayers
end

-- A wallpen is worth less when it has to cross more material or more layers,
-- so a 0.2 stud single wall always beats a 1.2 stud double wall.
function WallPen.Cost(thickness, layers)
    return (thickness or math.huge) + math.max((layers or 1) - 1, 0) * 0.15
end

-- Purely visual feedback: a rod through the wall between the entry and exit
-- faces plus a dot on the face the bullet enters. CanQuery = false so it can
-- never block our own traces.
function WallPen.Marker(trace)
    if not WallPen.ShowMarker or not trace or not trace.entry then return end
    local now = os.clock()
    if now - (WallPen._markerTime or 0) < 0.12 then return end
    WallPen._markerTime = now
    local entry = trace.entry
    local exitPos = trace.exit or entry
    local span = math.max((exitPos - entry).Magnitude, 0.06)
    local rod = Instance.new("Part")
    rod.Name = "WallPenFX"
    rod.Anchored, rod.CanCollide, rod.CanQuery, rod.CanTouch = true, false, false, false
    rod.Material = Enum.Material.Neon
    rod.Color = Color3.fromRGB(255, 90, 120)
    rod.Size = Vector3.new(0.09, 0.09, span)
    rod.CFrame = CFrame.lookAt(entry:Lerp(exitPos, 0.5), exitPos)
    rod.Parent = workspace
    local dot = Instance.new("Part")
    dot.Name = "WallPenFX"
    dot.Anchored, dot.CanCollide, dot.CanQuery, dot.CanTouch = true, false, false, false
    dot.Shape = Enum.PartType.Ball
    dot.Material = Enum.Material.Neon
    dot.Color = Color3.fromRGB(255, 200, 90)
    dot.Size = Vector3.new(0.22, 0.22, 0.22)
    dot.CFrame = CFrame.new(entry)
    dot.Parent = workspace
    task.delay(0.45, function()
        if rod.Parent then rod:Destroy() end
        if dot.Parent then dot:Destroy() end
    end)
end
--#endregion

-- Written by the aim toggles so the panel can show readiness even with no target.
local AimState = { Silent = false, Ragebot = false, Origin = nil }

-- Target panel. Resolver labels describe heuristics, not proof of cheating.
do
    local old = LocalPlayer.PlayerGui:FindFirstChild("TargetingPanel")
    if old then old:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "TargetingPanel"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(310, 186)
    box.Position = UDim2.new(0.5, -155, 0.7, 0)
    box.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
    box.BorderSizePixel = 0
    box.Visible = false
    box.Active = true
    box.Draggable = true
    box.Parent = gui
    local corner = Instance.new("UICorner", box)
    corner.CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", box)
    stroke.Color = Color3.fromRGB(65, 135, 210)
    local header = Instance.new("TextLabel", box)
    header.Size = UDim2.new(1, 0, 0, 25)
    header.BackgroundColor3 = Color3.fromRGB(27, 39, 57)
    header.BorderSizePixel = 0
    header.Font = Enum.Font.GothamBold
    header.TextSize = 12
    header.TextColor3 = Color3.fromRGB(130, 195, 255)
    header.Text = "TARGETING"
    local avatar = Instance.new("ImageLabel", box)
    avatar.Position = UDim2.fromOffset(8, 32)
    avatar.Size = UDim2.fromOffset(67, 67)
    avatar.BackgroundColor3 = Color3.fromRGB(31, 35, 45)
    local detail = Instance.new("TextLabel", box)
    detail.Position = UDim2.fromOffset(84, 30)
    detail.Size = UDim2.new(1, -90, 0, 152)
    detail.BackgroundTransparency = 1
    detail.Font = Enum.Font.Gotham
    detail.TextSize = 12
    detail.TextColor3 = Color3.fromRGB(225, 230, 240)
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.TextYAlignment = Enum.TextYAlignment.Top
    local shown, lastAvatar = true, nil
    local lastPanelUpdate = 0
    Sections.aimbot:Toggle({
        Name = "targeting panel", Flag = "targetingpanel", Default = true,
        Callback = function(value) shown = value end,
    })
    local visCache = { player = nil, time = 0, text = "Visibility: —" }
    local function visibilityText(p, origin)
        local now = os.clock()
        if visCache.player == p and now - visCache.time < 0.12 then return visCache.text end
        local text = "Visibility: no target"
        local character = p and p.Character
        local head = character and character:FindFirstChild("Head")
        if head and origin then
            -- Same tracer wallpen uses, so the panel and the aim always agree
            -- on how much cover is actually in the way.
            local trace = WallPen.Trace(origin, head.Position, character)
            if trace.state == "clear" then
                text = "Visibility: visible"
            elseif trace.thickness == math.huge then
                text = "Visibility: hidden (unmeasurable)"
            elseif trace.layers > 0 then
                text = string.format("Visibility: wall %.2f studs / %dL", trace.thickness, trace.layers)
            else
                text = "Visibility: hidden"
            end
        end
        visCache.player, visCache.time, visCache.text = p, now, text
        return text
    end

    RunService.RenderStepped:Connect(function()
        local armed = AimState.Silent or AimState.Ragebot
        local p = CurrentTargetPlayer
        local c = p and p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local own = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local active = p and p.Parent == Players and h and h.Health > 0 and r and own
            and os.clock() - CurrentTargetTime < 1
        box.Visible = shown and (not not active or armed)
        if not box.Visible then return end

        -- The panel is text, not a game render: updating it 20 times a second
        -- instead of every frame removes a surprising amount of string work
        -- from the render step and changes nothing you can see.
        local panelNow = os.clock()
        if panelNow - lastPanelUpdate < 0.05 then return end
        lastPanelUpdate = panelNow

        local aimText = "Aim: off"
        if AimState.Silent and AimState.Ragebot then
            aimText = "Aim: silent + ragebot ready"
        elseif AimState.Silent then
            aimText = "Aim: silent ready"
        elseif AimState.Ragebot then
            aimText = "Aim: ragebot ready"
        end

        if not active then
            lastAvatar = nil
            avatar.Image = ""
            detail.Text = string.format("No target in view\n%s\nScan: idle | HBE: %s | WP: %s",
                aimText, HitboxExpander.Enabled and "on" or "off",
                WallPen.Enabled and "on" or "off")
            return
        end

        local status = ResolverRunning and "Unknown (no sample)" or "Unknown (resolver off)"
        local data = ResolverSnapshot and ResolverSnapshot[p]
        if ResolverRunning and data and data.LastPosition then
            status = data.Flagged and "Dangerous (flagged)" or "Safe (not flagged)"
        end
        local scan = ShotScanResults[p]
        local scanText = scan and os.clock() - scan.time < 1.5 and scan.label or "Not scanned"
        local hbe = HitboxExpander.State[p]
        local hbeText = "HBE: off"
        if HitboxExpander.Enabled then
            hbeText = (hbe and os.clock() - hbe.time < 1 and hbe.visible)
                and "HBE: visible" or "HBE: covered"
        end
        local origin = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
        origin = origin and AARealPartPosition(origin) or nil
        local aaOn, aaDisplace, aaHeld = AAStatus()
        local aaText = "AA: off"
        if aaOn then
            if aaHeld then
                aaText = "AA: dropped (failsafe)"
            else
                aaText = aaDisplace > 0.25
                    and string.format("AA: displaced %.1f", aaDisplace) or "AA: synced"
            end
        end
        local wpText = "WP: off"
        if WallPen.Enabled then
            local last = WallPen.Last
            if last and os.clock() - last.time < 2 then
                local value = last.thickness == math.huge and "unmeasurable"
                    or string.format("%.2f studs", last.thickness or 0)
                wpText = string.format("WP: %s / %dL  (max %.2f / %dL)",
                    value, last.layers or 0, WallPen.MaxThickness, WallPen.MaxLayers)
            else
                wpText = string.format("WP: max %.2f studs / %dL",
                    WallPen.MaxThickness, WallPen.MaxLayers)
            end
        end
        detail.Text = string.format(
            "%s (@%s)\nHealth: %.0f / %.0f\nDistance: %.0f studs\n%s\n%s\n%s\nScan: %s | %s\n%s\n%s",
            p.DisplayName, p.Name, h.Health, h.MaxHealth,
            (r.Position - (own.Position - AAOffset())).Magnitude, status,
            visibilityText(p, origin), aimText, scanText, hbeText, wpText, aaText)
        if lastAvatar ~= p.UserId then
            local id = p.UserId
            lastAvatar = id
            avatar.Image = ""
            task.spawn(function()
                local ok, content = pcall(function()
                    return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
                if ok and lastAvatar == id and avatar.Parent then avatar.Image = content end
            end)
        end
    end)
end

do -- combat
    local SilentAimEnabled = false; 
    local _NoSpreadEnabled = false;
    local ManipEnabled = false;
    local Manips = 2;
    local MaxAimCandidates = 8;
    local ManipScanCount = 120;
    local HitScanEnabled = false;
    local HitScanCount = 32;
    -- Failsafe: the only thing allowed to interrupt UG. Shots are fired from
    -- the pose the server holds; if a streak of them stops registering, the
    -- displacement is dropped completely for a few seconds (plain valid shots
    -- from the real pose) and wallpen rests. UG then returns on its own.
    local FailsafeEnabled = true;
    local FailsafeAttempts = 3;
    -- How long UG pauses when the failsafe fires (slider: 0.10s - 8s).
    local FailsafeSyncTime = 1;
    local FailsafeMissStreak = 0;
    local FailsafePending = false;
    local FailsafeLastForce = 0;

    local function FailsafeReady()
        return FailsafeEnabled and FailsafeMissStreak >= FailsafeAttempts;
    end

    -- Failsafe trigger now happens inside FailsafeWatch the moment the miss
    -- limit is reached. Kept as a no-op so the shot paths still compile.
    local function FailsafeApply() end

    -- Published so the advanced-aa section (a later scope) can drive the
    -- failsafe. Writing to `FailsafeEnabled` from there used to hit a global
    -- with the same name while combat kept reading its own local, so the
    -- toggles silently did nothing.
    local aaEnv = (type(getgenv) == "function" and getgenv()) or _G
    aaEnv.AdvancedAASetFailsafe = function(enabled, attempts, syncTime)
        if type(enabled) == "boolean" then
            FailsafeEnabled = enabled
            if not enabled then FailsafeMissStreak = 0 end
        end
        if type(attempts) == "number" then
            FailsafeAttempts = math.clamp(attempts, 1, 8)
        end
        if type(syncTime) == "number" then
            FailsafeSyncTime = math.clamp(syncTime, 0.1, 8)
        end
    end

    -- Failsafe: while UG is active, count shots that do no damage. When the
    -- miss limit is reached, UG pauses for FailsafeSyncTime (1s) right away,
    -- the streak resets, and UG comes back on its own. Misses while UG is
    -- off or already paused are not counted.
    local function FailsafeWatch(targetPlayer)
        if not FailsafeEnabled or not targetPlayer or FailsafePending then return end
        if AADesync() < 0.25 then return end -- UG not active: nothing to fail
        local character = targetPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local before = humanoid.Health;
        FailsafePending = true;
        task.delay(0.35, function()
            FailsafePending = false;
            if not humanoid.Parent then return end
            if humanoid.Health < before then
                FailsafeMissStreak = 0;
                return
            end
            -- UG got paused/disabled while waiting: do not count this one.
            if AADesync() < 0.25 then return end
            FailsafeMissStreak += 1;
            if FailsafeMissStreak >= FailsafeAttempts
                and os.clock() - FailsafeLastForce >= FailsafeSyncTime then
                FailsafeMissStreak = 0;
                FailsafeLastForce = os.clock();
                WallPen.BackoffUntil = os.clock() + FailsafeSyncTime;
                AAForceSync(FailsafeSyncTime);
            end
        end)
    end
    local _ScanProgress = 0;
    local _ScanStatus = "idle";
    local _NoRecoilEnabled = false;
    local RageBotEnabled = false;
    local _SilentReload = false;
    local FovCircleEnabled = false;
    local RapidFireEnabled = false;
    local FireRate = 0;
    local InstantReload = false;
    local ForceFullAuto = false;
    local NoSpread = false;
    local RagebotTarget = nil 
    local SilentAimTarget = nil 

    local autofireparams = RaycastParams.new()
    autofireparams.FilterType = Enum.RaycastFilterType.Exclude

    --#region tracers

            -- Animated tracer: the head travels from muzzle to the resolved
            -- point at TracerSpeed. The midpoint is pushed along the manip
            -- offset so the curve shows how the shot was bent. Purely visual.
            local function samplePath(path, travelled)
                for i = 1, #path - 1 do
                    local from, to = path[i], path[i + 1]
                    local length = (to - from).Magnitude
                    if travelled <= length or i == #path - 1 then
                        local alpha = length > 0.001 and math.clamp(travelled / length, 0, 1) or 1
                        return from:Lerp(to, alpha)
                    end
                    travelled -= length
                end
                return path[#path]
            end

            -- Recycles tracer geometry. One curved tracer used to build 15-40
            -- fresh instances per bullet and destroy them a second later; at
            -- high fire rates that churn alone costs frames.
            local tracerPartPool, tracerBeamPool = {}, {}
            local tracerAttachments = setmetatable({}, { __mode = "k" })
            local TRACER_POOL_LIMIT = 512

            local function TakeTracerPart()
                local part = table.remove(tracerPartPool)
                if part then return part end
                local new = Instance.new("Part")
                new.Anchored, new.CanCollide, new.CanQuery = true, false, false
                new.Size = Vector3.new(0.2, 0.2, 0.2)
                new.Transparency = 1
                return new
            end
            local function ReleaseTracerPart(part)
                part.Parent = nil
                if #tracerPartPool < TRACER_POOL_LIMIT then
                    table.insert(tracerPartPool, part)
                else
                    part:Destroy()
                end
            end
            local function TakeTracerBeam()
                local beam = table.remove(tracerBeamPool)
                if beam then return beam end
                local new = Instance.new("Beam")
                new.LightEmission, new.LightInfluence = 1, 0
                new.FaceCamera = true
                new.TextureMode = Enum.TextureMode.Wrap
                return new
            end
            local function ReleaseTracerBeam(beam)
                beam.Attachment0, beam.Attachment1 = nil, nil
                beam.Parent = nil
                if #tracerBeamPool < TRACER_POOL_LIMIT then
                    table.insert(tracerBeamPool, beam)
                else
                    beam:Destroy()
                end
            end
            -- Two attachment slots per pooled node, created once and reused.
            local function TracerAttachment(part, slot)
                local list = tracerAttachments[part]
                if not list then
                    list = {}
                    tracerAttachments[part] = list
                end
                local attachment = list[slot]
                if not attachment then
                    attachment = Instance.new("Attachment")
                    attachment.Parent = part
                    list[slot] = attachment
                end
                return attachment
            end

            CreateTracer = function(origin, hitPoint, bendOffset)
                local data = Trails[SelectedTracer]
                if not data or typeof(origin) ~= "Vector3" then return end
                if typeof(hitPoint) ~= "Vector3" then
                    hitPoint = origin + Vector3.new(0, 0, -200)
                end
                local bend = (typeof(bendOffset) == "Vector3" and bendOffset or Vector3.zero) * TracerBend
                local segment = hitPoint - origin
                local length = segment.Magnitude
                local forward = length > 0.001 and segment.Unit or Vector3.new(0, 0, -1)
                local path
                if TracerPath == "Straight" then
                    path = { origin, hitPoint }
                elseif TracerPath == "Lightning" then
                    local right = forward:Cross(Vector3.new(0, 1, 0))
                    if right.Magnitude < 0.01 then right = forward:Cross(Vector3.new(1, 0, 0)) end
                    right = right.Unit
                    local up = right:Cross(forward).Unit
                    local zigzags = math.clamp(math.floor(length / 6), 3, 14)
                    local amplitude = math.max(length * 0.03, 0.4) * math.max(TracerBend, 0.15)
                    path = { origin }
                    for i = 1, zigzags - 1 do
                        local alpha = i / zigzags
                        local sign = (i % 2 == 0) and 1 or -1
                        local offset = right * (sign * amplitude * (0.4 + math.random()))
                            + up * (amplitude * 0.5 * (math.random() - 0.5))
                            + bend * alpha
                        table.insert(path, origin:Lerp(hitPoint, alpha) + offset)
                    end
                    table.insert(path, hitPoint)
                else
                    -- Curved: try to arc around the obstacle that blocks the
                    -- direct line, otherwise fall back to the bend offset.
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = AAIgnoreList()
                    local function clear(a, b)
                        local delta = b - a
                        if delta.Magnitude < 0.05 then return true end
                        local hit = workspace:Raycast(a, delta, params)
                        return hit == nil
                    end
                    local control = nil
                    if not clear(origin, hitPoint) then
                        local direction = forward
                        local right = direction:Cross(Vector3.new(0, 1, 0))
                        if right.Magnitude < 0.01 then right = direction:Cross(Vector3.new(1, 0, 0)) end
                        right = right.Unit
                        local up = right:Cross(direction).Unit
                        local middle = origin:Lerp(hitPoint, 0.5)
                        local directions = { right, up, (right + up).Unit, (right - up).Unit, -right, -up }
                        for _, radius in ipairs({ 4, 7, 11, 16, 24, 34 }) do
                            for _, axis in ipairs(directions) do
                                local candidate = middle + axis * radius
                                if clear(origin, candidate) and clear(candidate, hitPoint) then
                                    control = candidate
                                    break
                                end
                            end
                            if control then break end
                        end
                    end
                    local anchor = control or (origin:Lerp(hitPoint, 0.5) + bend)
                    anchor += bend * 0.25
                    -- Fewer segments than before: the curve reads the same and
                    -- every segment costs a part plus a beam.
                    local steps = math.clamp(math.floor((hitPoint - origin).Magnitude / 6), 5, 14)
                    path = {}
                    for i = 0, steps do
                        local alpha = i / steps
                        local inverse = 1 - alpha
                        local point = origin * (inverse * inverse)
                            + anchor * (2 * inverse * alpha)
                            + hitPoint * (alpha * alpha)
                        table.insert(path, point)
                    end
                end

                local nodes = {}
                local function nodeAt(position)
                    local node = TakeTracerPart()
                    node.CFrame = CFrame.new(position)
                    node.Parent = workspace
                    nodes[#nodes + 1] = node
                    return node
                end

                local beams = {}
                if TracerEffect ~= "Orb" then
                    -- Full path is drawn at once so the tracer reads as one
                    -- continuous line instead of a ball drifting along.
                    local previous = nodeAt(path[1])
                    for i = 2, #path do
                        local current = nodeAt(path[i])
                        if (path[i] - path[i - 1]).Magnitude > 0.05 then
                            local a0 = TracerAttachment(previous, 1)
                            local a1 = TracerAttachment(current, 2)
                            local beam = TakeTracerBeam()
                            beam.Attachment0, beam.Attachment1 = a0, a1
                            beam.Texture = data.Texture
                            beam.Width0, beam.Width1 = data.Width0, data.Width1
                            beam.TextureLength = data.TextureLength
                            beam.TextureMode = Enum.TextureMode.Wrap
                            beam.LightEmission, beam.LightInfluence = 1, 0
                            beam.FaceCamera = true
                            beam.Transparency = NumberSequence.new(0.2)
                            beam.Parent = previous
                            table.insert(beams, beam)
                        end
                        previous = current
                    end
                end

                local head, trail
                if TracerEffect == "Orb" or TracerEffect == "Trail" then
                    head = Instance.new("Part")
                    head.Anchored, head.CanCollide, head.CanQuery = true, false, false
                    head.Material = Enum.Material.Neon
                    head.Color = Color3.fromRGB(200, 235, 255)
                    head.Size = Vector3.new(0.35, 0.35, 0.35)
                    head.Shape = Enum.PartType.Ball
                    head.CFrame = CFrame.new(TracerEffect == "Orb" and origin or hitPoint)
                    head.Parent = workspace
                    if TracerEffect == "Trail" then
                        local a0 = TracerAttachment(nodes[1], 3)
                        local a1 = Instance.new("Attachment", head)
                        trail = Instance.new("Trail")
                        trail.Attachment0, trail.Attachment1 = a0, a1
                        trail.Lifetime = 0.35
                        trail.LightEmission = 1
                        trail.Color = ColorSequence.new(Color3.fromRGB(180, 225, 255), Color3.fromRGB(90, 130, 255))
                        trail.Parent = head
                    end
                end

                task.spawn(function()
                    local lifetime = math.max(data.Lifetime or 1, 0.1)
                    if head and TracerEffect == "Orb" then
                        local total = 0
                        for i = 1, #path - 1 do total += (path[i + 1] - path[i]).Magnitude end
                        local travelled = 0
                        local previous = os.clock()
                        while travelled < total and head.Parent do
                            local now = os.clock()
                            local dt = math.clamp(now - previous, 0, 0.1)
                            previous = now
                            travelled += math.max(TracerSpeed, 1) * dt
                            local position = samplePath(path, travelled)
                            head.CFrame = CFrame.new(position)
                            task.wait()
                        end
                    end
                    -- Fading every frame meant building a fresh NumberSequence
                    -- for every beam every frame. 25Hz looks identical.
                    local fadeStart = os.clock()
                    local lastFade = -1
                    while true do
                        local elapsed = os.clock() - fadeStart
                        if elapsed >= lifetime then break end
                        local progress = elapsed / lifetime
                        if progress - lastFade >= 0.04 or lastFade < 0 then
                            lastFade = progress
                            local sequence = NumberSequence.new(0.2 + 0.8 * progress)
                            for _, beam in ipairs(beams) do
                                if beam.Parent then
                                    beam.Transparency = sequence
                                end
                            end
                            if head and head.Parent then head.Transparency = progress end
                        end
                        task.wait()
                    end
                    if trail then trail:Destroy() end
                    if head and head.Parent then head:Destroy() end
                    for _, beam in ipairs(beams) do
                        ReleaseTracerBeam(beam)
                    end
                    for _, node in ipairs(nodes) do
                        ReleaseTracerPart(node)
                    end
                end)
            end

    --#endregion
    
    
    
    --#region manip 

        local _cachedoffset = nil
        --local lastShotTarget = nil

        autofireparams.FilterDescendantsInstances = AAIgnoreList()

        LocalPlayer.CharacterAdded:Connect(function(char)
            autofireparams.FilterDescendantsInstances = AAIgnoreList()
        end)

        -- Fixed raycast budget; samples points throughout a sphere, including
        -- near and far offsets. A wider range does not override server checks.
        function findminoffset(target, origin, ignorezeropos)
            if not target or not target.Parent then return nil, false, nil end
            autofireparams.FilterDescendantsInstances = AAIgnoreList()
            local function test(offset)
                if not target.Parent then return nil end
                -- Reject origins reached through a wall. This is only a
                -- conservative local check, not a server validation guarantee.
                if offset.Magnitude > 0.001
                    and workspace:Raycast(origin, offset, autofireparams) then
                    return nil
                end
                local start = origin + offset
                local direction = target.Position - start
                if direction.Magnitude < 0.001 then return nil end
                local hit = workspace:Raycast(start, direction, autofireparams)
                if hit and hit.Instance and hit.Instance:IsDescendantOf(target.Parent) then
                    return hit.Instance
                end
                return nil
            end
            _ScanProgress, _ScanStatus = 0, "scanning"
            if not ignorezeropos then
                local hit = test(Vector3.zero)
                if hit then _ScanProgress, _ScanStatus = 1, "direct"; return Vector3.zero, false, hit end
            end
            local count = math.clamp(math.floor(ManipScanCount), 1, 500)
            local bestOffset, bestHit, bestLength = nil, nil, math.huge
            local golden = math.pi * (3 - math.sqrt(5))
            for i = 1, count do
                local y = 1 - 2 * ((i - 0.5) / count)
                local radial = math.sqrt(math.max(0, 1 - y * y))
                local angle = i * golden
                -- Interleave distances so small and large offsets are both tested.
                local fraction = (((i * 37) % count) + 1) / count
                local length = Manips * fraction
                local offset = Vector3.new(math.cos(angle) * radial, y, math.sin(angle) * radial) * length
                local hit = test(offset)
                if hit and length < bestLength then
                    bestOffset, bestHit, bestLength = offset, hit, length
                end
                _ScanProgress = i / count
            end
            _ScanStatus = bestOffset and "found" or "no path"
            return bestOffset, bestOffset ~= nil, bestHit
        end

    --#endregion



    --#region targetting

        local FovCircle = Drawing.new("Circle")

        FovCircle.Radius = 100
        FovCircle.Color = Color3.fromRGB(255, 255, 255)
        FovCircle.Visible = false

        local _fovconnection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
            if FovCircleEnabled then 
                FovCircle.Position = UserInputService:GetMouseLocation()
            end
        end))

        function GetTarget()
            local currentCamera = workspace.CurrentCamera
            if not currentCamera then return nil end
            local mouse = UserInputService:GetMouseLocation()
            local bestPart, bestPriority, bestDistance = nil, math.huge, math.huge
            for _, plr in Players:GetPlayers() do
                local priority = CombatPriority(plr)
                local model = plr.Character
                local head = model and model:FindFirstChild("Head")
                local hum = model and model:FindFirstChildOfClass("Humanoid")
                if not priority or not head or not hum or hum.Health <= 0
                    or model:FindFirstChildOfClass("ForceField") then continue end
                local position, onScreen = currentCamera:WorldToViewportPoint(head.Position)
                if not onScreen or position.Z <= 0 then continue end
                local distance = (Vector2.new(position.X, position.Y) - mouse).Magnitude
                if FovCircleEnabled and distance > FovCircle.Radius then continue end
                if priority < bestPriority or (priority == bestPriority and distance < bestDistance) then
                    bestPart, bestPriority, bestDistance = head, priority, distance
                end
            end
            if SilentAimEnabled then ReportTarget(bestPart) end
            return bestPart
        end



        local visparams = RaycastParams.new()
        visparams.FilterType = Enum.RaycastFilterType.Exclude
        visparams.CollisionGroup = "ClientBullet"
        local gameReload = filtergc("function", {Name = "reload", Constants = {"ReloadSound"}}, true)

        -- Fibonacci surface sampling searches visible points on body parts.
        -- Every sample is measured by WallPen, so "blocked" now means a real,
        -- measurable amount of cover instead of "something got in the way".
        local function EvaluateShot(target, origin)
            if not target or not target.Parent then return nil end
            if typeof(origin) ~= "Vector3" then return nil end
            local model = target:FindFirstAncestorOfClass("Model")
            if not model then return nil end
            local plr = Players:GetPlayerFromCharacter(model)
            local function report(label)
                if plr then ShotScanResults[plr] = {label = label, time = os.clock()} end
            end
            local function plan(part, point, quality, label, offset)
                report(label)
                return {FinalPart = part, point = point, offset = offset or Vector3.zero, quality = quality}
            end

            -- 1. Direct line to the head (or whatever the caller asked for).
            local direct = WallPen.Probe(target, origin, target.Position, model)
            if direct.state == "clear" then
                return plan(direct.reached or target, target.Position, 1, "Direct: clear")
            end

            -- Thinnest cover found so far, used by the wallpen step below.
            local bestWall
            local function considerWall(part, point, trace)
                if not trace or trace.layers <= 0 or trace.thickness == math.huge then return end
                local cost = WallPen.Cost(trace.thickness, trace.layers)
                if not bestWall or cost < bestWall.cost then
                    bestWall = {part = part, point = point, trace = trace, cost = cost}
                end
            end
            considerWall(target, target.Position, direct)

            -- 2. Expanded hull: cheapest way to turn a graze into a hit.
            if HitboxExpander.Enabled and plr then
                local hbePoint, hbePart = HitboxExpander.Probe(plr, origin)
                if hbePoint and hbePart then
                    return plan(hbePart, hbePoint, 1.2, "HBE: visible")
                end
            end

            -- 3. Sample the rest of the rig: clear samples win, blocked ones feed
            --    the wallpen decision.
            local parts = { target }
            local scanBody = HitScanEnabled or HitboxExpander.Enabled or WallPen.Enabled
            if scanBody then
                for _, name in ipairs(RIG_PART_NAMES) do
                    local part = model:FindFirstChild(name)
                    if part and part:IsA("BasePart") and part ~= target then
                        table.insert(parts, part)
                    end
                end
            end
            -- With hitscan off, wallpen still needs one ray per body part, so the
            -- ray budget never drops below the number of parts being examined.
            local count = HitScanEnabled
                and math.clamp(math.floor(HitScanCount), 1, 200)
                or (scanBody and math.max(#parts, 1) or 1)
            local golden = math.pi * (3 - math.sqrt(5))
            local expand = HitboxExpander.Enabled and math.max(HitboxExpander.Size, 0) or 0
            for i = 1, count do
                local part = parts[((i - 1) % #parts) + 1]
                local point = part.Position
                if i > #parts then
                    -- Extra hitscan samples: surface points (with the expander
                    -- radius applied when it is on).
                    local y = 1 - 2 * ((i - 0.5) / math.max(count, 1))
                    local radial = math.sqrt(math.max(0, 1 - y * y))
                    local angle = i * golden
                    local unit = Vector3.new(math.cos(angle) * radial, y, math.sin(angle) * radial)
                    local half = part.Size * 0.42 + Vector3.new(expand, expand, expand)
                    point = part.CFrame:PointToWorldSpace(
                        Vector3.new(unit.X * half.X, unit.Y * half.Y, unit.Z * half.Z))
                end
                local trace = WallPen.Probe(part, origin, point, model)
                if trace.state == "clear" then
                    return plan(trace.reached or part, point, 1,
                        HitScanEnabled and "Hitscan: clear" or "Body: clear")
                elseif trace.state == "blocked" then
                    considerWall(part, point, trace)
                end
            end

            -- 4. Wallpen: only when the measured cover fits the whole budget
            --    (thickness and layers), on the thinnest point we found.
            if WallPen.Enabled and bestWall then
                -- Refine around the cheapest blocked part: cover is rarely a
                -- flat slab, so edges of the same wall are often thinner than
                -- its centre. Only worth the extra rays when we are already
                -- close to the budget.
                local trace0 = bestWall.trace
                if trace0.thickness <= WallPen.MaxThickness * 1.6 then
                    local part = bestWall.part
                    for _, axis in ipairs({ {1, 0}, {-1, 0}, {0, 1}, {0, -1} }) do
                        local offset = Vector3.new(
                            axis[1] * part.Size.X * 0.35,
                            axis[2] * part.Size.Y * 0.35,
                            0)
                        local point = part.CFrame:PointToWorldSpace(offset)
                        local trace = WallPen.Probe(part, origin, point, model)
                        if trace.state == "clear" then
                            return plan(trace.reached or part, point, 1,
                                HitScanEnabled and "Hitscan: clear" or "Body: clear")
                        elseif trace.state == "blocked" then
                            considerWall(part, point, trace)
                        end
                    end
                end
                local trace = bestWall.trace
                local label = string.format("Wallpen: %.2f studs / %dL (max %.2f / %dL)",
                    trace.thickness, trace.layers, WallPen.MaxThickness, WallPen.MaxLayers)
                WallPen.Last = {label = label, thickness = trace.thickness,
                    layers = trace.layers, time = os.clock()}
                if WallPen.CanPenetrate(trace.thickness, trace.layers) then
                    if WallPen.ShowMarker then WallPen.Marker(trace) end
                    return plan(bestWall.part, bestWall.point,
                        1.5 + trace.thickness * 0.1 + math.max(trace.layers - 1, 0) * 0.05, label)
                end
                report(label)
            end

            -- 5. Origin manipulation is the last resort: it always carries risk.
            if ManipEnabled then
                local offset, _, hitPart = findminoffset(target, origin, true)
                if offset and hitPart then
                    return plan(hitPart, hitPart.Position, 2, "Manipulated: candidate", offset)
                end
            end

            report(direct.state == "blocked" and "Blocked" or "No hit")
            return nil
        end

        -- `originOverride` is the head the shot will actually be fired from.
        -- Evaluating from one head and firing from another is what produced
        -- most UG misses (line checked from above ground, bullet sent from
        -- below the floor).
        function GetVisibleTarget(Gun, originOverride)
            local LocalCharacter = LocalPlayer.Character
            local LocalHead = LocalCharacter and LocalCharacter:FindFirstChild("Head")
            if not LocalHead then
                return nil
            end

            local origin = originOverride or AARealPartPosition(LocalHead)
            local range = Gun:GetAttribute("Range") or math.huge
            local currentCamera = workspace.CurrentCamera
            local facing = currentCamera and currentCamera.CFrame.LookVector
                or LocalHead.CFrame.LookVector

            -- Cheap pass, zero rays: only team/alive/range/alignment. The old
            -- version ran the full shot evaluation (hitscan + wallpen traces)
            -- on every player in the server, every frame, which is where the
            -- frame time went. Only the best few candidates get evaluated now.
            local candidates = {}
            for _, plr in Players:GetPlayers() do
                local priority = CombatPriority(plr)
                if priority then
                    local data = plr.Character
                    if data and not data:FindFirstChildOfClass("ForceField") then
                        local head = data:FindFirstChild("Head")
                        local hum = data:FindFirstChild("Humanoid")
                        if head and hum and hum.Health > 0 then
                            local direction = head.Position - origin
                            local dist = direction.Magnitude
                            if dist > 0.001 and dist <= range then
                                candidates[#candidates + 1] = {
                                    head = head,
                                    priority = priority,
                                    dist = dist,
                                    alignment = facing:Dot(direction / dist),
                                }
                            end
                        end
                    end
                end
            end
            if #candidates == 0 then return nil end

            -- Team priority first, then the smallest angle to the crosshair,
            -- then distance - exactly the old ordering, just without the rays.
            table.sort(candidates, function(a, b)
                if a.priority ~= b.priority then return a.priority < b.priority end
                if math.abs(a.alignment - b.alignment) > 0.01 then
                    return a.alignment > b.alignment
                end
                return a.dist < b.dist
            end)

            local best, bestDist, bestPriority = nil, math.huge, math.huge
            local bestFacing, bestQuality = -math.huge, math.huge
            local limit = math.min(#candidates, math.max(1, math.floor(MaxAimCandidates)))
            for i = 1, limit do
                local candidate = candidates[i]
                if best and candidate.priority > bestPriority then break end
                local plan = EvaluateShot(candidate.head, origin)
                if plan then
                    local better = best == nil
                        or candidate.priority < bestPriority
                        or (candidate.priority == bestPriority and plan.quality < bestQuality - 0.001)
                        or (candidate.priority == bestPriority
                            and math.abs(plan.quality - bestQuality) <= 0.001
                            and candidate.alignment > bestFacing + 0.001)
                        or (candidate.priority == bestPriority
                            and math.abs(plan.quality - bestQuality) <= 0.001
                            and math.abs(candidate.alignment - bestFacing) <= 0.001
                            and candidate.dist < bestDist)
                    if better then
                        best, bestDist, bestPriority = plan, candidate.dist, candidate.priority
                        bestFacing, bestQuality = candidate.alignment, plan.quality
                    end
                end
                -- A clean line to the top-priority candidate cannot be beaten.
                if best and bestPriority == candidates[1].priority and bestQuality <= 1.01 then
                    break
                end
            end
            if RageBotEnabled and best then ReportTarget(best.FinalPart) end
            return best
        end


    --#region silent aim logic

        local castRay = filtergc("function", {Name = "castRay"}, true)

        if isfunctionhooked(castRay) then 
            restorefunction(castRay)
        end 

        local old; old = hookfunction(castRay, function(p30, p31, p32, ...)
            local character = LocalPlayer.Character
            local head = character and character:FindFirstChild("Head")
            local realOrigin = head and AARealPartPosition(head)
            local serverOrigin = head and AAServerPartPosition(head)
            local target = SilentAimEnabled and GetTarget()
            if target and realOrigin then
                -- While UG/AA is displaced the server only validates the
                -- displaced pose, so that origin is tried first; the real head
                -- is the fallback for when AA is synced or paused.
                local plan = serverOrigin and EvaluateShot(target, serverOrigin) or nil
                if not plan then
                    plan = EvaluateShot(target, realOrigin)
                end
                -- Last resort: the game's own cast origin (usually the camera),
                -- which still works when both head origins are inside geometry.
                if not plan and typeof(p30) == "Vector3" then
                    plan = EvaluateShot(target, p30)
                end
                if plan then
                    SilentAimTarget = target
                    if TracerEnabled then
                        local tracerOrigin = (typeof(p30) == "Vector3") and p30 or realOrigin
                        CreateTracer(tracerOrigin, plan.point, plan.offset)
                    end
                    return plan.FinalPart, plan.point
                end
            end
            SilentAimTarget = nil
            return old(p30, p31, p32, ...)
        end)

    --#endregion

    

    --#region ragebot
        --Remotes.ShootEvent

        if isfunctionhooked(getrawmetatable(game).__namecall) then
            restorefunction(getrawmetatable(game).__namecall)
        end

        -- Fires a silent-aim shot once the server pose has settled (transition
        -- finished or the peek has landed), re-evaluated from that exact pose.
        local function QueueSilentShot(Args, Target)
            task.spawn(function()
                local deadline = os.clock() + 0.6
                while os.clock() < deadline do
                    local state = AAShotState()
                    if state ~= "transition" then
                        local character = LocalPlayer.Character
                        local head = character and character:FindFirstChild("Head")
                        if not head or not Target or not Target.Parent then return end
                        local origin = (state == "server") and AAServerPartPosition(head)
                            or AARealPartPosition(head)
                        local plan = EvaluateShot(Target, origin)
                        if plan then
                            origin += plan.offset
                            for _, v in Args[1] do
                                if type(v) == "table" then
                                    v[1] = origin
                                    v[2] = plan.point
                                    v[3] = plan.FinalPart
                                end
                            end
                            if state == "real" then AAPeek(AASyncWindow() + 0.1) end
                            MarkShots(Args[1])
                            Remotes.ShootEvent:FireServer(table.unpack(Args))
                            if state == "server" then
                                local hitModel = plan.FinalPart:FindFirstAncestorOfClass("Model")
                                FailsafeWatch(hitModel and Players:GetPlayerFromCharacter(hitModel))
                            end
                            return
                        end
                        -- Underground head still blocked: wait for the peek.
                        if state == "real" then return end
                    end
                    task.wait()
                end
            end)
        end

        local mtHook; mtHook = hookfunction(getrawmetatable(game).__namecall, function(self, ...)
            local namecallmethod = getnamecallmethod()

            if not checkcaller() and SilentAimEnabled and SilentAimTarget and not RagebotTarget and rawequal(self, Remotes.ShootEvent) and namecallmethod == "FireServer" then
                local Args = {...}
                local Target = GetTarget()
                local LocalCharacter = LocalPlayer.Character
                SilentAimTarget = nil
                if not Target then
                    setnamecallmethod(namecallmethod)
                    return mtHook(self, ...)
                end

                if LocalCharacter and type(Args[1]) == 'table' then
                    local Head = LocalCharacter:FindFirstChild("Head")

                    if Head then
                        -- Build the shot from the pose the server holds RIGHT
                        -- NOW (lag included). Never fire from the real head
                        -- while the server still has us underground (= invalid).
                        local state = AAShotState()
                        local serverOrigin = AAServerPartPosition(Head)
                        local realOrigin = AARealPartPosition(Head)
                        local origin, plan, queue = nil, nil, false
                        if state == "server" then
                            origin = serverOrigin
                            plan = EvaluateShot(Target, serverOrigin)
                            if not plan and EvaluateShot(Target, realOrigin)
                                and AAPeek(AASyncWindow() * 2 + 0.15) then
                                -- Underground head has no line but the real one
                                -- does: peek and fire once the server has it.
                                queue = true
                            end
                        elseif state == "real" then
                            origin = realOrigin
                            plan = EvaluateShot(Target, realOrigin)
                            -- Keep the real pose until this shot is validated.
                            if plan then AAPeek(AASyncWindow() + 0.1) end
                        else
                            queue = true
                        end

                        if queue then
                            QueueSilentShot(Args, Target)
                            setnamecallmethod(namecallmethod)
                            return nil
                        end

                        if plan then
                            origin += plan.offset
                            for _, v in Args[1] do
                                v[1] = origin
                                v[2] = plan.point
                                v[3] = plan.FinalPart
                            end
                            if state == "server" then
                                local hitModel = plan.FinalPart and plan.FinalPart:FindFirstAncestorOfClass("Model")
                                FailsafeWatch(hitModel and Players:GetPlayerFromCharacter(hitModel))
                            end
                        elseif state == "server" then
                            -- No plan: still send it from the pose the server
                            -- holds so it is a plain miss, not an invalid.
                            for _, v in Args[1] do
                                if type(v) == "table" then v[1] = serverOrigin end
                            end
                        end
                    end
                end

                MarkShots(Args[1])

                setnamecallmethod(namecallmethod)

                return mtHook(self, table.unpack(Args, 1, select("#", ...)))
            end
            if rawequal(self, Remotes.ShootEvent) and namecallmethod == "FireServer" and type((...)) == 'table' then
                MarkShots((...))
            end

            setnamecallmethod(namecallmethod)

            return mtHook(self, ...)
        end)

        task.spawn(function()
            local LastShot = 0

            while true do
                task.wait()

                if not RageBotEnabled then
                    continue
                end

                local LocalCharacter = LocalPlayer.Character
                local Gun = LocalCharacter and LocalCharacter:FindFirstChildOfClass("Tool")

                if not Gun or Gun:GetAttribute("ToolType") ~= "Gun" then
                    continue
                end

                if (Gun:GetAttribute("Local_ReloadSession") or 0) ~= 0 then
                    continue
                end

                local Ammo = Gun:GetAttribute("Local_CurrentAmmo") or 0

                if Ammo <= 0 then
                    task.spawn(gameReload)
                    continue
                end

                local Rate = RapidFireEnabled and FireRate or (Gun:GetAttribute("FireRate") or 0.1)

                if os.clock() - LastShot < Rate then
                    continue
                end

                local LocalHead = LocalCharacter:FindFirstChild("Head")

                if not LocalHead then
                    continue
                end

                -- Shot origin = the pose the server holds right now, lag
                -- included. During a pose change nothing is fired (those were
                -- the invalids); the loop just waits a few frames.
                local state = AAShotState()
                if state == "transition" then
                    continue
                end

                local origin, t
                if state == "server" then
                    origin = AAServerPartPosition(LocalHead)
                    t = GetVisibleTarget(Gun, origin)
                    if not t then
                        -- Underground head has no line. If the real head does,
                        -- peek: the next shots come from the real pose once the
                        -- server has it, then UG returns.
                        local realHead = AARealPartPosition(LocalHead)
                        if GetVisibleTarget(Gun, realHead) then
                            AAPeek(AASyncWindow() * 2 + 0.15)
                        end
                        continue
                    end
                else
                    origin = AARealPartPosition(LocalHead)
                    t = GetVisibleTarget(Gun, origin)
                    if not t then
                        continue
                    end
                    -- Hold the real pose until the server validated this shot.
                    AAPeek(AASyncWindow() + 0.1)
                end

                local FinalPart = t.FinalPart
                local targetModel = FinalPart and FinalPart:FindFirstAncestorOfClass("Model")
                local targetPlayer = targetModel and Players:GetPlayerFromCharacter(targetModel)
                if not targetPlayer or not CombatPriority(targetPlayer) then continue end
                origin = origin + t.offset
                local Shots = {}

                for i = 1, Gun:GetAttribute("ProjectileCount") or 1 do
                    Shots[i] = { origin, t.point, FinalPart }
                end

                LastShot = os.clock()

                if TracerEnabled then
                    CreateTracer(origin, t.point, t.offset)
                end

                Remotes.ShootEvent:FireServer(Shots)
                if state == "server" then FailsafeWatch(targetPlayer) end
                Gun:SetAttribute("Local_CurrentAmmo", Ammo - 1)
            end
        end)

    --#endregion



    --#region gun mods

        local shoot = filtergc("function", {Name = "shoot"}, true)

        if isfunctionhooked(shoot) then 
            restorefunction(shoot)
        end 

        local oldShoot; oldShoot = hookfunction(shoot, function(...) 
            -- The upvalue walk is not free and the gun config table never
            -- moves, so it is only read while one of the mods is actually on.
            if not (ForceFullAuto or RapidFireEnabled or NoSpread) then
                return oldShoot(...)
            end
            local upvs = (debug :: any).getupvalues(shoot)

            --[[for i, v in upvs do 
                if type(v) == 'table' then 
                    for id, va in v do 
                        print(id, va)
                    end 
                else 
                    print(i, v)
                end
            end ]]
            
            if ForceFullAuto then 
                upvs[10].AutoFire = true 
            end 

            if RapidFireEnabled then 
                upvs[10].FireRate = FireRate
            end 

            if NoSpread then 
                upvs[10].SpreadRadius = 0
            end
            
            return oldShoot(...)
        end)

        if isfunctionhooked(task.wait) then 
            restorefunction(task.wait)
        end 

        -- debug.traceback() is one of the most expensive calls available and
        -- the old version ran it on EVERY task.wait() in the whole game, even
        -- with instant reload off. It is only needed while the mod is on.
        local oldWait; oldWait = hookfunction(task.wait, function(time, ...)
            if InstantReload and type(time) == "number" and time > 0 then
                local ok, tb = pcall(debug.traceback)
                if ok and type(tb) == "string" and tb:find("reload", 1, true) then
                    time = 0
                end
            end

            return oldWait(time, ...)
        end)

    --#endregion



    --#region toggles

        Sections.aimbot:Toggle({
            Name = 'silent aim';
            Flag = 'silentaim';
            Default = false;
            Callback = function(v)
                SilentAimEnabled = v;
                AimState.Silent = v;
            end
        })

        Sections.aimbot:Toggle({
            Name = 'fov circle';
            Flag = 'fovcircle';
            Default = false; 
            Callback = function(v)
                FovCircleEnabled = v;
                FovCircle.Visible = v;
            end 
        })

        Sections.aimbot:Slider({
            Name = 'fov radius';
            Flag = 'fovradius';
            Default = FovCircle.Radius;
            Max = 1000;
            Min = 1;
            Decimals = 1;
            Callback = function(v)
                FovCircle.Radius = v;
            end 
        })

        Sections.aimbot:Label({Name = 'fov color'}):Colorpicker({
            Name = 'fov color';
            Flag = 'fovcolor';
            Default = FovCircle.Color;
            Callback = function(v)
                FovCircle.Color = v;
            end 
        })
        
        Sections.aimbot:Toggle({
            Name = 'origin manip';
            Flag = 'manip';
            Default = false;
            Callback = function(v)
                ManipEnabled = v;
            end
        })
        
        Sections.aimbot:Slider({
            Name = "manip dist";
            Flag = 'manipdist';
            Max = 20;
            Min = 0;
            Default = 2;
            Decimals = 1;
            Callback = function(v)
                Manips = v;
            end
        })

        Sections.aimbot:Slider({
            Name = "manip scan count"; Flag = "manipscancount";
            Min = 10; Max = 500; Default = 120; Decimals = 1;
            Callback = function(v) ManipScanCount = v end;
        })
        Sections.aimbot:Toggle({
            Name = "hitscan"; Flag = "fibonaccihitscan"; Default = false;
            Callback = function(v) HitScanEnabled = v end;
        })
        Sections.aimbot:Slider({
            Name = "hitscan samples"; Flag = "hitscansamples";
            Min = 1; Max = 200; Default = 32; Decimals = 1;
            Callback = function(v) HitScanCount = v end;
        })
        -- How many of the best candidates the aim actually evaluates per shot.
        -- Lower = fewer raycasts = more fps; every candidate above this is only
        -- sorted by team/alignment/distance, so the chosen target rarely changes.
        Sections.aimbot:Slider({
            Name = "aim candidates (fps)"; Flag = "aimcandidates";
            Min = 1; Max = 25; Default = 8; Decimals = 1;
            Callback = function(v) MaxAimCandidates = v end;
        })
        Sections.aimbot:Toggle({
            Name = "wallpen"; Flag = "wallpen"; Default = false;
            Callback = function(v) WallPen.Enabled = v end;
        })
        -- One slider owns the whole penetration budget: it scales the wall
        -- thickness and the layer count together, so the layer limit can never
        -- sit above what the thickness limit allows.
        --    25%  = 1.25 studs / 2 layers   (default)
        --    100% = 5.00 studs / 6 layers
        Sections.aimbot:Slider({
            Name = "wallpen max (walls + layers)"; Flag = "wallpen_max";
            Min = 1; Max = 100; Default = 25; Decimals = 1;
            Callback = function(v) WallPen.ApplyBudget(v) end;
        })
        Sections.aimbot:Toggle({
            Name = "wallpen hit marker"; Flag = "wallpen_marker"; Default = true;
            Callback = function(v) WallPen.ShowMarker = v end;
        })
        Sections.aimbot:Slider({
            Name = "hostile inmate threat range"; Flag = "aggrorange";
            Min = 10; Max = 300; Default = 80; Decimals = 1;
            Callback = function(v) AggroThreatRange = v end;
        })
        Sections.aimbot:Toggle({
            Name = "team priority (aim / visuals)"; Flag = "priorityteamcheck";
            Default = true; Callback = function(v) PriorityTeamCheck = v end;
        })
        Sections.aimbot:Toggle({
            Name = 'ragebot';
            Flag = 'ragebot';
            Default = false;
            Callback = function(v)
                RageBotEnabled = v;
                AimState.Ragebot = v;
            end 
        })


        Sections.gunmods:Toggle({
            Name = 'fire rate modifier';
            Flag = 'firerate';
            Default = false;
            Callback = function(v)
                RapidFireEnabled = v; 
            end 
        })

        Sections.gunmods:Slider({
            Name = 'fire rate (lower the faster)';
            Flag = 'firerates';
            Default = 0;
            Min = 0;
            Max = 1;
            Decimals = 0.01;
            Callback = function(v)
                FireRate = v; 
            end
        })

        Sections.gunmods:Toggle({
            Name = 'force full auto';
            Flag = 'ffa';
            Default = false;
            Callback = function(v)
                ForceFullAuto = v; 
            end 
        })

        Sections.gunmods:Toggle({
            Name = 'instant reload';
            Flag = 'instantreload';
            Default = false;
            Callback = function(v)
                InstantReload = v;
            end 
        })

        Sections.gunmods:Toggle({
            Name = 'no spread';
            Flag = 'nospread';
            Default = false;
            Callback = function(v)
                NoSpread = v;
            end 
        })


    --#endregion
end 



-- Apply shared policy after the external ESP library has positioned its holders.
RunService:BindToRenderStep("PriorityESPFilter", Enum.RenderPriority.Camera.Value + 2, function()
    if not PriorityTeamCheck or not EspLib.Cache then return end
    for plr, entry in pairs(EspLib.Cache) do
        if not TargetPriority(plr) and entry.Holder then
            entry.Holder.Visible = false
            -- Keep the library's visibility state consistent so it can show it again.
            entry.Visible = false
        end
    end
end)

do -- esp

    
    Sections.Esp:Toggle({
        Name = 'player esp';
        Flag = 'espenabled';
        Default = true;
        Callback = function(v)
            EspLib['Table']['Enabled'] = v
        end
    })
    
    Sections.Esp:Toggle({
        Name = 'team check';
        Flag = 'tc';
        Default = false;
        Callback = function(v)
            EspLib['Table']['TeamCheck'] = v;
        end 
    })

    Sections.Esp:Toggle({
        Name = 'box enabled';
        Flag = 'boxenable';
        Default = true;
        Callback = function(v)
            EspLib['Table']['Boxes']['Enabled'] = v
        end
    })

    for i, v in EspLib['Table']['Boxes'] do
        if type(v) ~= 'table' then 
            continue 
        end
        if rawget(v, 'Enabled') then
            Sections.Esp:Toggle({
                Name = i;
                Flag = 'boxtoggle'..i;
                Default = v['Enabled'];
                Callback = function(dih)
                    v['Enabled'] = dih
                end
            })
        end

        if v['Top'] then
            Sections.Esp:Label({Name = i})

            Sections.Esp:Label({Name = 'top'}):Colorpicker({
                Name = 'top color';
                Flag = 'boxtopcolor'..i;
                Default = v['Top'];
                Callback = function(dih)
                    v['Top'] = dih
                end;
            })
        end

        if v['Bot'] then
            Sections.Esp:Label({Name = i})

            Sections.Esp:Label({Name = 'bottom'}):Colorpicker({
                Name = 'bottom color';
                Flag = 'boxbotcolor'..i;
                Default = v['Bot'];
                Callback = function(dih)
                    v['Bot'] = dih
                end;
            })
        end
    end

    for i, v in EspLib['Table']['Bars'] do
        if type(v) ~= 'table' then 
            continue 
        end
        if rawget(v, 'Enabled') then
            Sections.Esp:Toggle({
                Name = i;
                Flag = 'bartoggle'..i;
                Default = v['Enabled'];
                Callback = function(dih)
                    v['Enabled'] = dih
                end
            })
        end

        if v['Top'] then
            Sections.Esp:Label({Name = i})

            Sections.Esp:Label({Name = 'top'}):Colorpicker({
                Name = 'top color';
                Flag = 'bartopcolor'..i;
                Default = v['Top'];
                Callback = function(dih)
                    v['Top'] = dih
                end;
            })
        end

        if v['Bot'] then
            Sections.Esp:Label({Name = i})

            Sections.Esp:Label({Name = 'bottom'}):Colorpicker({
                Name = 'bottom color';
                Flag = 'barbotcolor'..i;
                Default = v['Bot'];
                Callback = function(dih)
                    v['Bot'] = dih
                end;
            })
        end

        if v['Mid'] then
            Sections.Esp:Label({Name = i})

            Sections.Esp:Label({Name = 'mid'}):Colorpicker({
                Name = 'mid color';
                Flag = 'barmidcolor'..i;
                Default = v['Mid'];
                Callback = function(dih)
                    v['Mid'] = dih
                end;
            })
        end
    end

    for i, v in EspLib['Table']['Texts'] do
        if type(v) ~= 'table' then 
            continue 
        end
        if rawget(v, 'Enabled') then
            Sections.Esp:Toggle({
                Name = i;
                Flag = 'texttoggle'..i;
                Default = v['Enabled'];
                Callback = function(dih)
                    v['Enabled'] = dih
                end
            })
        end

        if v['Color'] then
            Sections.Esp:Label({Name = i})

            Sections.Esp:Label({Name = 'color'}):Colorpicker({
                Name = 'color';
                Flag = 'textcolor'..i;
                Default = v['Color'];
                Callback = function(dih)
                    v['Color'] = dih
                end;
            })
        end
    end

    Sections.Esp:Slider({
        Name = 'max distance';
        Flag = 'espmaxdistance';
        Min = 200;
        Max = 5000;
        Default = 500;
        Decimals = 1;
        Callback = function(v)
            EspLib['Table']['Distance'] = v
        end
    })
end


-- ==========================================
-- LATENCY GHOST | VISUALS TAB
-- ==========================================

local GhostEnabled = false
local GhostColor = Color3.fromRGB(120, 190, 255)

local Ghost
local GhostHighlight
local GhostCharacter
local GhostRootOffset = CFrame.new()

local GhostState = "TRACKING"
local GhostFade = 0
local GhostStateStart = 0

local GhostHistory = {}
local GhostLastPosition
local GhostIdleStart = os.clock()
local GhostLastSample = 0

local GhostAveragePing = 0

local GHOST_SETTINGS = {
    SampleRate = 0.025,
    MaxHistory = 2,
    MaxPingDelay = 0.5,

    MovementThreshold = 0.08,
    IdleTime = 0.75,

    TrackingSmoothness = 3.5,
    ReturnSmoothness = 4,

    DissipateTime = 0.55,
    ReformTime = 0.65,

    Transparency = 0.48
}

local function GhostSetFade(amount)
    GhostFade = math.clamp(amount, 0, 1)

    if not Ghost then return end

    for _, object in ipairs(Ghost:GetDescendants()) do
        if object:IsA("BasePart") then
            local original = object:GetAttribute("GhostOriginalTransparency") or 0

            object.Transparency =
                original + (1 - original) * GhostFade
        end
    end

    if GhostHighlight then
        GhostHighlight.FillTransparency =
            0.45 + (0.55 * GhostFade)

        GhostHighlight.OutlineTransparency =
            GhostFade
    end
end

local function GhostDestroy()
    if Ghost then
        Ghost:Destroy()
    end

    Ghost = nil
    GhostHighlight = nil
end

local function GhostCreate(character)
    GhostDestroy()

    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local previousArchivable = character.Archivable
    character.Archivable = true

    local success, clone = pcall(function()
        return character:Clone()
    end)

    character.Archivable = previousArchivable

    if not success or not clone then
        warn("Latency Ghost: Character clone failed")
        return
    end

    clone.Name = "LatencyGhost"

    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") then
            object:Destroy()

        elseif object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false

            object:SetAttribute(
                "GhostOriginalTransparency",
                object.Transparency
            )
        end
    end

    local humanoid = clone:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.DisplayDistanceType =
            Enum.HumanoidDisplayDistanceType.None
    end

    GhostHighlight = Instance.new("Highlight")
    GhostHighlight.Name = "LatencyGhostHighlight"
    GhostHighlight.Adornee = clone
    GhostHighlight.FillColor = GhostColor
    GhostHighlight.OutlineColor = GhostColor
    GhostHighlight.FillTransparency = 0.45
    GhostHighlight.OutlineTransparency = 0
    GhostHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    GhostHighlight.Parent = clone

    Ghost = clone
    GhostRootOffset = root.CFrame:ToObjectSpace(character:GetPivot())

    Ghost:PivotTo(character:GetPivot())
    Ghost.Parent = workspace

    GhostSetFade(0)
end

local function GhostSetupCharacter(character)
    GhostCharacter = character

    GhostHistory = {}
    GhostLastPosition = nil
    GhostIdleStart = os.clock()
    GhostLastSample = 0

    GhostState = "TRACKING"
    GhostStateStart = os.clock()

    task.wait(0.2)

    if GhostCharacter == character then
        GhostCreate(character)
    end
end

local function GhostRecordPosition()
    local character = GhostCharacter
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then return end

    local now = os.clock()

    if now - GhostLastSample < GHOST_SETTINGS.SampleRate then
        return
    end

    GhostLastSample = now

    local position = root.Position

    if GhostLastPosition then
        local movement = (position - GhostLastPosition).Magnitude

        if movement > GHOST_SETTINGS.MovementThreshold then
            GhostIdleStart = now

            if GhostState == "HIDDEN"
                or GhostState == "RETURNING"
                or GhostState == "DISSIPATING" then

                GhostState = "REFORMING"
                GhostStateStart = now

                GhostHistory = {}

                if Ghost then
                    Ghost.Parent = workspace
                    Ghost:PivotTo(character:GetPivot())
                    GhostSetFade(1)
                end
            end
        end
    end

    GhostLastPosition = position

    table.insert(GhostHistory, {
        Time = now,
        CFrame = root.CFrame
    })

    while #GhostHistory > 0
        and now - GhostHistory[1].Time > GHOST_SETTINGS.MaxHistory do

        table.remove(GhostHistory, 1)
    end

    if now - GhostIdleStart >= GHOST_SETTINGS.IdleTime
        and GhostState == "TRACKING" then

        GhostState = "RETURNING"
        GhostStateStart = now
    end
end

local function GhostGetHistoricalCFrame(targetTime)
    if #GhostHistory == 0 then
        return nil
    end

    if #GhostHistory == 1 then
        return GhostHistory[1].CFrame
    end

    for i = 1, #GhostHistory - 1 do
        local first = GhostHistory[i]
        local second = GhostHistory[i + 1]

        if targetTime >= first.Time and targetTime <= second.Time then
            local difference = second.Time - first.Time

            local alpha = difference > 0
                and (targetTime - first.Time) / difference
                or 0

            return first.CFrame:Lerp(second.CFrame, alpha)
        end
    end

    if targetTime < GhostHistory[1].Time then
        return GhostHistory[1].CFrame
    end

    return GhostHistory[#GhostHistory].CFrame
end

local function GhostGetPing()
    local success, ping = pcall(function()
        return LocalPlayer:GetNetworkPing()
    end)

    if success and type(ping) == "number" then
        GhostAveragePing =
            GhostAveragePing == 0
            and ping
            or GhostAveragePing + (ping - GhostAveragePing) * 0.12
    end

    return math.clamp(
        GhostAveragePing,
        0,
        GHOST_SETTINGS.MaxPingDelay
    )
end

local function GhostSetColor(color)
    GhostColor = color

    if GhostHighlight then
        GhostHighlight.FillColor = color
        GhostHighlight.OutlineColor = color
    end
end

-- Character setup
if LocalPlayer.Character then
    task.spawn(GhostSetupCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    task.spawn(GhostSetupCharacter, character)
end)

-- Position recording
RunService.Heartbeat:Connect(function()
    if not GhostEnabled then return end

    GhostRecordPosition()
end)

-- Ghost animation
RunService.RenderStepped:Connect(function(delta)
    if not GhostEnabled or not Ghost or not GhostCharacter then
        return
    end
    if not Ghost.Parent then return end

    local character = GhostCharacter
    local root = character:FindFirstChild("HumanoidRootPart")

    if not root then return end

    local now = os.clock()
    local bodyPivot = character:GetPivot()

    local pingDelay = GhostGetPing()

    if GhostState == "TRACKING" then
        local historical = GhostGetHistoricalCFrame(now - pingDelay)

        if historical then
            local targetPivot = historical * GhostRootOffset

            local alpha = 1 - math.exp(
                -GHOST_SETTINGS.TrackingSmoothness * delta
            )

            Ghost:PivotTo(
                Ghost:GetPivot():Lerp(targetPivot, alpha)
            )
        end

        GhostSetFade(0)

    elseif GhostState == "RETURNING" then
        local alpha = 1 - math.exp(
            -GHOST_SETTINGS.ReturnSmoothness * delta
        )

        Ghost:PivotTo(
            Ghost:GetPivot():Lerp(bodyPivot, alpha)
        )

        GhostSetFade(0)

        if (Ghost:GetPivot().Position - bodyPivot.Position).Magnitude < 0.4 then
            GhostState = "DISSIPATING"
            GhostStateStart = now
        end

    elseif GhostState == "DISSIPATING" then
        Ghost:PivotTo(bodyPivot)

        local progress = math.clamp(
            (now - GhostStateStart) / GHOST_SETTINGS.DissipateTime,
            0,
            1
        )

        GhostSetFade(progress)

        if progress >= 1 then
            GhostState = "HIDDEN"
            Ghost.Parent = nil
        end

    elseif GhostState == "REFORMING" then
        local historical = GhostGetHistoricalCFrame(now - pingDelay)

        local targetPivot = historical
            and historical * GhostRootOffset
            or bodyPivot

        local alpha = 1 - math.exp(
            -GHOST_SETTINGS.TrackingSmoothness * delta
        )

        Ghost:PivotTo(
            Ghost:GetPivot():Lerp(targetPivot, alpha)
        )

        local progress = math.clamp(
            (now - GhostStateStart) / GHOST_SETTINGS.ReformTime,
            0,
            1
        )

        GhostSetFade(1 - progress)

        if progress >= 1 then
            GhostState = "TRACKING"
            GhostSetFade(0)
        end
    end
end)

-- ==========================================
-- VISUALS CONTROLS
-- ==========================================

Sections.visuals:Toggle({
    Name = "Latency Ghost",
    Flag = "latencyghost",
    Default = false,

    Callback = function(value)
        GhostEnabled = value

        if value then
            if Ghost and GhostState ~= "HIDDEN" then
                Ghost.Parent = workspace
            end
        else
            if Ghost then
                Ghost.Parent = nil
            end
        end
    end
})

Sections.visuals:Label({
    Name = "Ghost color"
}):Colorpicker({
    Name = "Ghost color",
    Flag = "latencyghostcolor",
    Default = GhostColor,

    Callback = function(value)
        GhostSetColor(value)
    end
})


do -- visuals
    local FullbrightEnabled = false;
    local NoFogEnabled = false;
    local TsAmbient = Color3.fromRGB(255, 255, 255)
    local TsOutdoorAmbient = Color3.fromRGB(255, 255, 255)
    local Fov = 200
    local FovChanger = false;
    local TpDistance = 15
    

-- ==========================================
-- ADVANCED TEAM CHECK
-- VISUALS TAB
-- ==========================================

local AdvancedTeamCheck = {
    Enabled = true,
    IgnoreSameTeam = true,
    IgnoreNeutral = true,
    IgnoreDead = true
}

-- Player eligibility filter
function AdvancedTeamCheck:IsAllowed(player)

    if not player or player == LocalPlayer then
        return false
    end

    if not self.Enabled then
        return true
    end

    if self.IgnoreSameTeam
        and LocalPlayer.Team ~= nil
        and player.Team == LocalPlayer.Team then

        return false
    end

    if self.IgnoreNeutral and player.Neutral then
        return false
    end

    local character = player.Character

    if not character then
        return false
    end

    if self.IgnoreDead then
        local humanoid =
            character:FindFirstChildOfClass("Humanoid")

        if not humanoid or humanoid.Health <= 0 then
            return false
        end
    end

    return true
end

-- ==========================================
-- GUI
-- ==========================================

Sections.visuals:Toggle({
    Name = "Advanced Team Check",
    Flag = "advancedteamcheck",
    Default = true,

    Callback = function(value)
        AdvancedTeamCheck.Enabled = value
    end
})

Sections.visuals:Toggle({
    Name = "Ignore Same Team",
    Flag = "atc_sameteam",
    Default = true,

    Callback = function(value)
        AdvancedTeamCheck.IgnoreSameTeam = value
    end
})

Sections.visuals:Toggle({
    Name = "Ignore Neutral",
    Flag = "atc_neutral",
    Default = true,

    Callback = function(value)
        AdvancedTeamCheck.IgnoreNeutral = value
    end
})

Sections.visuals:Toggle({
    Name = "Ignore Dead Players",
    Flag = "atc_dead",
    Default = true,

    Callback = function(value)
        AdvancedTeamCheck.IgnoreDead = value
    end
})


-- ==========================================
-- MOVEMENT RESOLVER / PLAYER MONITOR
-- VISUALS TAB
-- ==========================================

local ResolverEnabled = false

local ResolverPlayers = {}
ResolverSnapshot = ResolverPlayers
local ResolverRows = {}

local ResolverSettings = {
    SpeedThreshold = 90,
    TeleportThreshold = 45,
    UndergroundY = -10,
    FlagThreshold = 35,
    UpdateRate = 0.25
}

-- GUI setup
local ResolverGui = Instance.new("ScreenGui")
ResolverGui.Name = "ResolverMonitor"
ResolverGui.ResetOnSpawn = false
ResolverGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ResolverPanel = Instance.new("Frame")
ResolverPanel.Name = "ResolverPanel"
ResolverPanel.Size = UDim2.fromOffset(300, 340)
ResolverPanel.Position = UDim2.new(0, 30, 0.35, 0)
ResolverPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
ResolverPanel.BorderSizePixel = 0
ResolverPanel.Visible = false
ResolverPanel.Parent = ResolverGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 7)
PanelCorner.Parent = ResolverPanel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Color = Color3.fromRGB(65, 135, 210)
PanelStroke.Thickness = 1
PanelStroke.Parent = ResolverPanel

-- Header
local ResolverHeader = Instance.new("TextLabel")
ResolverHeader.Size = UDim2.new(1, 0, 0, 36)
ResolverHeader.BackgroundColor3 = Color3.fromRGB(27, 39, 57)
ResolverHeader.BorderSizePixel = 0
ResolverHeader.Text = "  RESOLVER  |  PLAYER MONITOR"
ResolverHeader.TextColor3 = Color3.fromRGB(130, 195, 255)
ResolverHeader.TextSize = 12
ResolverHeader.Font = Enum.Font.GothamBold
ResolverHeader.TextXAlignment = Enum.TextXAlignment.Left
ResolverHeader.Parent = ResolverPanel

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 7)
HeaderCorner.Parent = ResolverHeader

-- Summary
local ResolverSummary = Instance.new("TextLabel")
ResolverSummary.Position = UDim2.fromOffset(10, 43)
ResolverSummary.Size = UDim2.new(1, -20, 0, 22)
ResolverSummary.BackgroundTransparency = 1
ResolverSummary.Text = "Players: 0  |  Flagged: 0"
ResolverSummary.TextColor3 = Color3.fromRGB(190, 195, 205)
ResolverSummary.TextSize = 11
ResolverSummary.Font = Enum.Font.Gotham
ResolverSummary.TextXAlignment = Enum.TextXAlignment.Left
ResolverSummary.Parent = ResolverPanel

-- Player list
local ResolverList = Instance.new("ScrollingFrame")
ResolverList.Position = UDim2.fromOffset(8, 70)
ResolverList.Size = UDim2.new(1, -16, 1, -80)
ResolverList.BackgroundColor3 = Color3.fromRGB(23, 26, 34)
ResolverList.BorderSizePixel = 0
ResolverList.ScrollBarThickness = 3
ResolverList.ScrollBarImageColor3 = Color3.fromRGB(90, 155, 220)
ResolverList.CanvasSize = UDim2.new(0, 0, 0, 0)
ResolverList.Parent = ResolverPanel

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 5)
ListCorner.Parent = ResolverList

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 5)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ResolverList

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 6)
ListPadding.PaddingLeft = UDim.new(0, 6)
ListPadding.PaddingRight = UDim.new(0, 6)
ListPadding.Parent = ResolverList

ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ResolverList.CanvasSize = UDim2.new(
        0, 0, 0, ListLayout.AbsoluteContentSize.Y + 12
    )
end)

-- ==========================================
-- DRAGGING
-- ==========================================

local Dragging = false
local DragStart
local StartPosition
local DragInput

ResolverHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true
        DragStart = input.Position
        StartPosition = ResolverPanel.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

ResolverHeader.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        DragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Dragging and input == DragInput then
        local delta = input.Position - DragStart

        ResolverPanel.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end
end)

-- ==========================================
-- PLAYER TRACKING
-- ==========================================

local function ResolverSetupPlayer(player)
    if player == LocalPlayer then return end

    ResolverPlayers[player] = {
        LastPosition = nil,
        LastCharacter = nil,
        LastUpdate = os.clock(),
        Suspicion = 0,
        Speed = 0,
        Underground = false,
        Flagged = false
    }
end

local function ResolverRemovePlayer(player)
    ResolverPlayers[player] = nil

    if ResolverRows[player] then
        ResolverRows[player].Frame:Destroy()
        ResolverRows[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    ResolverSetupPlayer(player)
end

Players.PlayerAdded:Connect(ResolverSetupPlayer)
Players.PlayerRemoving:Connect(ResolverRemovePlayer)

-- ==========================================
-- MOVEMENT ANALYSIS
-- ==========================================

local function ResolverAnalyzePlayer(player, data)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        data.Speed = 0
        data.Underground = false
        data.LastPosition = nil
        data.LastCharacter = nil
        return
    end

    local now = os.clock()
    if data.LastCharacter ~= character or now - data.LastUpdate > 1.5 then
        data.LastPosition = nil
        data.LastCharacter = character
        data.LastUpdate = now
    end
    local position = root.Position

    data.Underground = position.Y < ResolverSettings.UndergroundY

    if data.LastPosition then
        local elapsed = now - data.LastUpdate

        if elapsed > 0 then
            local distance = (position - data.LastPosition).Magnitude
            local speed = distance / elapsed

            data.Speed = speed

            if speed > ResolverSettings.SpeedThreshold then
                data.Suspicion = math.min(
                    data.Suspicion + 12,
                    100
                )
            end

            if distance > ResolverSettings.TeleportThreshold
                and elapsed < 0.5 then

                data.Suspicion = math.min(
                    data.Suspicion + 15,
                    100
                )
            end
        end
    end

    data.LastPosition = position
    data.LastUpdate = now

    -- Suspicion gradually decreases over time.
    data.Suspicion = math.max(
        0,
        data.Suspicion - 1
    )

    data.Flagged =
        data.Suspicion >= ResolverSettings.FlagThreshold
end

-- ==========================================
-- PLAYER ROWS
-- ==========================================

local function ResolverCreateRow(player)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 57)
    row.BackgroundColor3 = Color3.fromRGB(31, 35, 45)
    row.BorderSizePixel = 0
    row.Parent = ResolverList

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = row

    local name = Instance.new("TextLabel")
    name.Position = UDim2.fromOffset(8, 5)
    name.Size = UDim2.new(1, -16, 0, 18)
    name.BackgroundTransparency = 1
    name.Text = player.DisplayName
    name.TextColor3 = Color3.fromRGB(225, 230, 240)
    name.TextSize = 12
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = row

    local status = Instance.new("TextLabel")
    status.Position = UDim2.fromOffset(8, 26)
    status.Size = UDim2.new(1, -16, 0, 22)
    status.BackgroundTransparency = 1
    status.TextColor3 = Color3.fromRGB(160, 170, 185)
    status.TextSize = 10
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = row

    ResolverRows[player] = {
        Frame = row,
        Name = name,
        Status = status
    }

    return ResolverRows[player]
end

local function ResolverUpdateRows()
    local playerCount = 0
    local flaggedCount = 0

    for player, data in pairs(ResolverPlayers) do
        if player.Parent ~= Players then
            continue
        end

        playerCount += 1

        if data.Flagged then
            flaggedCount += 1
        end

        local row = ResolverRows[player]

        if not row then
            row = ResolverCreateRow(player)
        end

        row.Name.Text = player.DisplayName

        local statusText = string.format(
            "Speed: %.1f  |  Score: %d",
            data.Speed,
            math.floor(data.Suspicion)
        )

        if data.Underground then
            statusText ..= "  |  BELOW MAP"
        end

        if data.Flagged then
            statusText ..= "  |  FLAGGED"
            row.Frame.BackgroundColor3 =
                Color3.fromRGB(75, 35, 42)

            row.Status.TextColor3 =
                Color3.fromRGB(255, 115, 125)

        elseif data.Underground then
            row.Frame.BackgroundColor3 =
                Color3.fromRGB(65, 53, 35)

            row.Status.TextColor3 =
                Color3.fromRGB(255, 190, 100)

        else
            row.Frame.BackgroundColor3 =
                Color3.fromRGB(31, 35, 45)

            row.Status.TextColor3 =
                Color3.fromRGB(160, 190, 215)
        end

        row.Status.Text = statusText
    end

    ResolverSummary.Text = string.format(
        "Players: %d  |  Flagged: %d",
        playerCount,
        flaggedCount
    )
end

-- ==========================================
-- UPDATE LOOP
-- ==========================================

local ResolverAccumulator = 0

RunService.Heartbeat:Connect(function(delta)
    if not ResolverEnabled then return end

    ResolverAccumulator += delta

    if ResolverAccumulator < ResolverSettings.UpdateRate then
        return
    end

    ResolverAccumulator = 0

    for player, data in pairs(ResolverPlayers) do
        ResolverAnalyzePlayer(player, data)
    end

    ResolverUpdateRows()
end)

-- ==========================================
-- VISUALS TAB CONTROLS
-- ==========================================

Sections.visuals:Toggle({
    Name = "Movement Resolver",
    Flag = "movementresolver",
    Default = false,

    Callback = function(value)
        ResolverEnabled = value
        ResolverRunning = value

        if not value then
            for _, data in pairs(ResolverPlayers) do
                data.Suspicion = 0
                data.Flagged = false
            end

            ResolverUpdateRows()
        end
    end
})

Sections.visuals:Toggle({
    Name = "Resolver Player Monitor",
    Flag = "resolvermonitor",
    Default = false,

    Callback = function(value)
        ResolverPanel.Visible = value
    end
})
    

    
    
    
    local _oldmin = LocalPlayer.CameraMinZoomDistance
    local _oldmax = LocalPlayer.CameraMaxZoomDistance


    --[[
    --#region Skyboxes
        --repeat task.wait() until Lighting:FindFirstChildWhichIsA("Sky")

        local Sky = Lighting:FindFirstChildWhichIsA("Sky")

        
        local von = game:HttpGet('https://gist.githubusercontent.com/skekkstunsua-lgtm/131b1921a45d4cce654140b916ec0ccd/raw/15241ee33e8b0db830697c0a6d14b725acd8a035/gistfile1.txt')

        local decrypted = base64decode(von)

        writefile("von.png", decrypted)

        local vonasset = getcustomasset("von.png")

        local Skyboxes = {
            ["Default"] = {
                Sky.SkyboxBk,
                Sky.SkyboxDn,
                Sky.SkyboxFt,
                Sky.SkyboxLf,
                Sky.SkyboxRt,
                Sky.SkyboxUp,
            },
            ["king von"] = {vonasset, vonasset, vonasset, vonasset, vonasset, vonasset},
            ["Eyes"] = { "6823346883", "6823346883", "6823346883", "6823346883", "6823346883", "6823346883" },
            ["Spongebob"] = { "277094910", "277094864", "277094957", "277095042", "277094996", "277095139" },

            -- Omen
            ["Blue Sky"] = { "591058823", "591059876", "591058104", "591057861", "591057625", "591059642" },
            ["Vaporwave"] = { "1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643" },
            ["Redshift"] = { "401664839", "401664862", "401664960", "401664881", "401664901", "401664936" },
            ["Blaze"] = { "150939022", "150939038", "150939047", "150939056", "150939063", "150939082" },
            ["Among Us"] = { "5752463190", "5752463190", "5752463190", "5752463190", "5752463190", "5752463190" },
            ["Dark Night"] = { "6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635" },
            ["Bright Pink"] = { "271042516", "271077243", "271042556", "271042310", "271042467", "271077958" },
            ["Purple Sky"] = { "570557514", "570557775", "570557559", "570557620", "570557672", "570557727" },
            ["Galaxy"] = { "15125283003", "15125281008", "15125277539", "15125279325", "15125274388", "15125275800" },
        }

        local SkyOptions = {}
        for Option,_ in Skyboxes do
            table.insert(SkyOptions, Option)
        end
    --#endregion
    ]]


    --#region calm luh logic brader

        RunService.RenderStepped:Connect(function()
            if FullbrightEnabled then
                -- Guarded: writing the same value every frame still fires
                -- property-changed signals all over the lighting system.
                if Lighting.Brightness ~= 3 then Lighting.Brightness = 3 end
                --Lighting.ClockTime = 18.5
                if Lighting.ExposureCompensation ~= 0.5 then
                    Lighting.ExposureCompensation = 0.5
                end
                
                if Lighting.Ambient ~= TsAmbient then 
                    Lighting.Ambient = TsAmbient 
                end

                if Lighting.OutdoorAmbient ~= TsOutdoorAmbient then 
                    Lighting.OutdoorAmbient = TsOutdoorAmbient 
                end
            end
            if NoFogEnabled then
                local atmo = Lighting:FindFirstChildWhichIsA('Atmosphere')
                if atmo and atmo.Density ~= 0 then 
                    atmo.Density = 0 
                end
            end
            if FovChanger and Camera.FieldOfView ~= Fov then
                Camera.FieldOfView = Fov
            end
        end)
        RunService:BindToRenderStep("tpcam", Enum.RenderPriority.Last.Value + 1, function()
            if ThirdPerson then
                Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, TpDistance)
                local char = LocalPlayer.Character
                if char then
                    for _, part in char:GetDescendants() do
                        if part:IsA("BasePart") or part:IsA("Decal") then
                            part.LocalTransparencyModifier = 0
                        end
                    end
                end
            end
        end)
        Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function() 
            if FovChanger and Camera.FieldOfView ~= Fov then 
                Camera.FieldOfView = Fov
            end
        end)


    --#endregion


-- Equipped-tool chams. Controls live on the visuals tab.
local ToolChams = {
    Enabled = false,
    Glow = true,
    XRay = true,
    Rainbow = false,
    RainbowSpeed = 0.2,
    Color = Color3.fromHSV(0.53, 1, 1),
    FillTransparency = 0.15,
    PartTransparency = 0,
    OutlineTransparency = 0,
    Material = "Neon",
}

local ToolChamsMaterials = { "Neon", "ForceField", "Glass", "Solid" }
local ToolChamsMaterialEnums = {
    Neon = Enum.Material.Neon,
    ForceField = Enum.Material.ForceField,
    Glass = Enum.Material.Glass,
    Solid = Enum.Material.SmoothPlastic,
}

local ToolChamsTool
local ToolChamsHighlight
local ToolChamsOriginals = {}
local ToolChamsTracked = {}
local ToolChamsCharacterConns = {}
local ToolChamsToolConns = {}

local ToolChamsGui = Instance.new("ScreenGui")
ToolChamsGui.Name = "ToolChams"
ToolChamsGui.ResetOnSpawn = false
ToolChamsGui.Enabled = true
ToolChamsGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function ToolChamsDisconnect(list)
    for _, connection in ipairs(list) do
        connection:Disconnect()
    end
    table.clear(list)
end

local function ToolChamsSave(object)
    if ToolChamsOriginals[object] then
        return
    end

    if object:IsA("BasePart") then
        local saved = {
            Kind = "Part",
            Color = object.Color,
            Transparency = object.Transparency,
            Material = object.Material,
        }

        if object:IsA("MeshPart") then
            saved.TextureID = object.TextureID
        end

        ToolChamsOriginals[object] = saved
    elseif object:IsA("SpecialMesh") then
        ToolChamsOriginals[object] = {
            Kind = "Mesh",
            TextureId = object.TextureId,
        }
    elseif object:IsA("Decal") or object:IsA("Texture") then
        ToolChamsOriginals[object] = {
            Kind = "Decal",
            Transparency = object.Transparency,
        }
    end
end

local function ToolChamsPaint(object)
    if object:IsA("BasePart") then
        object.Color = ToolChams.Color
        object.Transparency = ToolChams.PartTransparency
        object.Material = ToolChamsMaterialEnums[ToolChams.Material] or Enum.Material.Neon

        if object:IsA("MeshPart") then
            object.TextureID = ""
        end
    elseif object:IsA("SpecialMesh") then
        object.TextureId = ""
    elseif object:IsA("Decal") or object:IsA("Texture") then
        object.Transparency = 1
    end
end

local function ToolChamsRestore()
    if ToolChamsHighlight then
        ToolChamsHighlight:Destroy()
        ToolChamsHighlight = nil
    end

    ToolChamsDisconnect(ToolChamsToolConns)

    for object, saved in pairs(ToolChamsOriginals) do
        if object.Parent then
            if saved.Kind == "Part" then
                object.Color = saved.Color
                object.Transparency = saved.Transparency
                object.Material = saved.Material

                if saved.TextureID ~= nil and object:IsA("MeshPart") then
                    object.TextureID = saved.TextureID
                end
            elseif saved.Kind == "Mesh" and object:IsA("SpecialMesh") then
                object.TextureId = saved.TextureId
            elseif saved.Kind == "Decal" then
                object.Transparency = saved.Transparency
            end
        end
    end

    table.clear(ToolChamsOriginals)
    table.clear(ToolChamsTracked)
    ToolChamsTool = nil
end

local function ToolChamsIsVisual(object)
    return object:IsA("BasePart")
        or object:IsA("SpecialMesh")
        or object:IsA("Decal")
        or object:IsA("Texture")
end

local function ToolChamsTrack(object)
    if not ToolChamsIsVisual(object) then
        return
    end

    if ToolChamsTracked[object] then
        ToolChamsPaint(object)
        return
    end

    ToolChamsSave(object)
    ToolChamsTracked[object] = true
    ToolChamsPaint(object)
end

local function ToolChamsUpdate()
    if ToolChamsHighlight then
        ToolChamsHighlight.Enabled = ToolChams.Glow
        ToolChamsHighlight.FillColor = ToolChams.Color
        ToolChamsHighlight.OutlineColor = ToolChams.Color
        ToolChamsHighlight.FillTransparency = ToolChams.FillTransparency
        ToolChamsHighlight.OutlineTransparency = ToolChams.OutlineTransparency
        ToolChamsHighlight.DepthMode = ToolChams.XRay
            and Enum.HighlightDepthMode.AlwaysOnTop
            or Enum.HighlightDepthMode.Occluded
    end

    if not ToolChams.Enabled then
        return
    end

    for object in pairs(ToolChamsTracked) do
        if object.Parent then
            ToolChamsPaint(object)
        else
            ToolChamsTracked[object] = nil
            ToolChamsOriginals[object] = nil
        end
    end
end

local function ToolChamsBind(tool)
    ToolChamsDisconnect(ToolChamsToolConns)

    table.insert(ToolChamsToolConns, tool.DescendantAdded:Connect(function(object)
        if ToolChams.Enabled then
            ToolChamsTrack(object)
        end
    end))

    table.insert(ToolChamsToolConns, tool.DescendantRemoving:Connect(function(object)
        ToolChamsTracked[object] = nil
        ToolChamsOriginals[object] = nil
    end))

    for _, object in tool:GetDescendants() do
        ToolChamsTrack(object)
    end
end

local function ToolChamsGetEquipped()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    for _, object in character:GetChildren() do
        if object:IsA("Tool") then
            return object
        end
    end

    return nil
end

local function ApplyToolChams()
    local tool = ToolChamsGetEquipped()

    if not ToolChams.Enabled or not tool then
        ToolChamsRestore()
        return
    end

    if tool ~= ToolChamsTool then
        ToolChamsRestore()
        ToolChamsTool = tool

        ToolChamsHighlight = Instance.new("Highlight")
        ToolChamsHighlight.Name = "ToolChams"
        ToolChamsHighlight.Adornee = tool
        ToolChamsHighlight.Parent = ToolChamsGui
        ToolChamsBind(tool)
    end

    ToolChamsUpdate()
end

local function ToolChamsWatch(character)
    ToolChamsDisconnect(ToolChamsCharacterConns)
    ToolChamsRestore()

    table.insert(ToolChamsCharacterConns, character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.defer(ApplyToolChams)
        end
    end))

    table.insert(ToolChamsCharacterConns, character.ChildRemoved:Connect(function(child)
        if child == ToolChamsTool or child:IsA("Tool") then
            task.defer(ApplyToolChams)
        end
    end))

    task.defer(ApplyToolChams)
end

LocalPlayer.CharacterAdded:Connect(ToolChamsWatch)
if LocalPlayer.Character then
    ToolChamsWatch(LocalPlayer.Character)
end

RunService.RenderStepped:Connect(function(dt)
    if ToolChams.Rainbow and ToolChams.Enabled then
        local hue, saturation, brightness = ToolChams.Color:ToHSV()
        ToolChams.Color = Color3.fromHSV((hue + dt * ToolChams.RainbowSpeed) % 1, saturation, brightness)
        ToolChamsUpdate()
    end
end)

Sections.visuals:Toggle({
    Name = "tool chams",
    Flag = "toolchams",
    Default = false,
    Callback = function(value)
        ToolChams.Enabled = value
        ApplyToolChams()
    end
})

Sections.visuals:Label({
    Name = "tool chams color"
}):Colorpicker({
    Name = "tool chams color",
    Flag = "toolchamscolor",
    Default = ToolChams.Color,
    Callback = function(value)
        ToolChams.Color = value
        ToolChamsUpdate()
    end
})

Sections.visuals:Slider({
    Name = "tool fill transparency",
    Flag = "toolchamsfill",
    Min = 0,
    Max = 1,
    Default = ToolChams.FillTransparency,
    Decimals = 0.01,
    Callback = function(value)
        ToolChams.FillTransparency = value
        ToolChamsUpdate()
    end
})

Sections.visuals:Slider({
    Name = "tool part transparency",
    Flag = "toolchamspart",
    Min = 0,
    Max = 1,
    Default = ToolChams.PartTransparency,
    Decimals = 0.01,
    Callback = function(value)
        ToolChams.PartTransparency = value
        ToolChamsUpdate()
    end
})

Sections.visuals:Slider({
    Name = "tool outline transparency",
    Flag = "toolchamsoutline",
    Min = 0,
    Max = 1,
    Default = ToolChams.OutlineTransparency,
    Decimals = 0.01,
    Callback = function(value)
        ToolChams.OutlineTransparency = value
        ToolChamsUpdate()
    end
})

Sections.visuals:Toggle({
    Name = "tool chams glow",
    Flag = "toolchamsglow",
    Default = true,
    Callback = function(value)
        ToolChams.Glow = value
        ToolChamsUpdate()
    end
})

Sections.visuals:Toggle({
    Name = "tool chams x-ray",
    Flag = "toolchamsxray",
    Default = true,
    Callback = function(value)
        ToolChams.XRay = value
        ToolChamsUpdate()
    end
})

Sections.visuals:Dropdown({
    Name = "tool chams material",
    Flag = "toolchamsmaterial",
    Items = ToolChamsMaterials,
    Default = "Neon",
    Callback = function(value)
        if ToolChamsMaterialEnums[value] then
            ToolChams.Material = value
            ToolChamsUpdate()
        end
    end
})

Sections.visuals:Toggle({
    Name = "tool chams rainbow",
    Flag = "toolchamsrainbow",
    Default = false,
    Callback = function(value)
        ToolChams.Rainbow = value
    end
})

Sections.visuals:Slider({
    Name = "tool chams rainbow speed",
    Flag = "toolchamsrainbowspeed",
    Min = 0.05,
    Max = 1,
    Default = ToolChams.RainbowSpeed,
    Decimals = 0.01,
    Callback = function(value)
        ToolChams.RainbowSpeed = value
    end
})


    --#region toggles

-- ==========================================
-- CHAMS | VISUALS TAB
-- ==========================================

local ChamsPlayers = game:GetService("Players")
local ChamsLocalPlayer = ChamsPlayers.LocalPlayer

local ChamsEnabled = false
local ChamsHighlights = {}

local function ApplyChams(player)
    if player == ChamsLocalPlayer or not TargetPriority(player) then return end

    local character = player.Character
    if not character then return end

    if ChamsHighlights[player] then
        ChamsHighlights[player]:Destroy()
        ChamsHighlights[player] = nil
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ClientChams"
    highlight.Adornee = character

    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)

    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0

    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = ChamsEnabled
    highlight.Parent = character

    ChamsHighlights[player] = highlight
end

local function SetupChamsPlayer(player)
    if player == ChamsLocalPlayer then return end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        if ChamsEnabled then
            ApplyChams(player)
        end
    end)

    if ChamsEnabled and player.Character then
        ApplyChams(player)
    end
end

local function SetChams(state)
    ChamsEnabled = state

    for _, player in ipairs(ChamsPlayers:GetPlayers()) do
        if player ~= ChamsLocalPlayer then
            if state then
                ApplyChams(player)
            elseif ChamsHighlights[player] then
                ChamsHighlights[player]:Destroy()
                ChamsHighlights[player] = nil
            end
        end
    end
end

-- Existing players
for _, player in ipairs(ChamsPlayers:GetPlayers()) do
    SetupChamsPlayer(player)
end

-- New players
ChamsPlayers.PlayerAdded:Connect(SetupChamsPlayer)

-- Leaving players
ChamsPlayers.PlayerRemoving:Connect(function(player)
    if ChamsHighlights[player] then
        ChamsHighlights[player]:Destroy()
        ChamsHighlights[player] = nil
    end
end)

-- Reconcile highlights when teams or the shared policy change.
task.spawn(function()
    while task.wait(0.5) do
        if ChamsEnabled then
            for _, plr in ipairs(ChamsPlayers:GetPlayers()) do
                if plr ~= ChamsLocalPlayer then
                    local existing = ChamsHighlights[plr]
                    local allowed = TargetPriority(plr) ~= nil
                    if existing and (not allowed or existing.Adornee ~= plr.Character) then
                        existing:Destroy()
                        ChamsHighlights[plr] = nil
                    elseif allowed and not existing and plr.Character then
                        ApplyChams(plr)
                    end
                end
            end
        end
    end
end)

-- VISUALS TAB TOGGLE
Sections.visuals:Toggle({
    Name = "Chams",
    Flag = "chams",
    Default = false,

    Callback = function(value)
        SetChams(value)
    end
})

        Sections.visuals:Toggle({
            Name = 'fov changer';
            Flag = 'fovchanger';
            Default = false;
            Callback = function(v)
                FovChanger = v;
            end 
        })

        Sections.visuals:Slider({
            Name = 'fov';
            Flag = 'fov';
            Max = 110;
            Min = 60;
            Default = 110;
            Decimals = 1;
            Callback = function(v)
                Fov = v;
            end
        })

        --[[Sections.visuals:Toggle({
            Name = 'third person';
            Flag = 'ThirdPerson';
            Default = false;
            Callback = function(v)
                ThirdPerson = v;
            end
        })

        Sections.visuals:Slider({
            Name = 'camera distance';
            Flag = 'tpdistance';
            Default = 15;
            Min = 1;
            Max = 15;
            Decimals = 1;
            Callback = function(v)
                TpDistance = v;
            end
        })]]
        
        Sections.visuals:Toggle({
            Name = 'fullbright';
            Flag = 'fullbright';
            Default = false;
            Callback = function(v)
                FullbrightEnabled = v;
            end
        })

        Sections.visuals:Label({Name = 'ambient'}):Colorpicker({
            Name = 'ambient';
            Flag = 'ambient';
            Default = TsAmbient;
            Callback = function(v)
                TsAmbient = v;
            end
        })

        Sections.visuals:Label({Name = 'outdoor ambient'}):Colorpicker({
            Name = 'outdoor ambient';
            Flag = 'outdoor ambient';
            Default = TsOutdoorAmbient;
            Callback = function(v)
                TsOutdoorAmbient = v;
            end
        })
        --[[Sections.visuals:Dropdown({
            Name = 'skybox';
            Items = SkyOptions;
            Default = 1;
            Callback = function(v)
                local chosen = Skyboxes[v]

                local function toAsset(val)
                    if type(val) ~= "string" then 
                        return val 
                    end
                    if val:sub(1, 3) == "rbx" then 
                        return val 
                    end

                    return "rbxassetid://" .. val
                end

                Sky.SkyboxBk = toAsset(chosen[1])
                Sky.SkyboxDn = toAsset(chosen[2])
                Sky.SkyboxFt = toAsset(chosen[3])
                Sky.SkyboxLf = toAsset(chosen[4])
                Sky.SkyboxRt = toAsset(chosen[5])
                Sky.SkyboxUp = toAsset(chosen[6])
            end;
        })]]
        Sections.visuals:Toggle({
            Name = 'no fog';
            Flag = 'nofog';
            Default = false;
            Callback = function(v)
                NoFogEnabled = v;
            end
        })

        Sections.visuals:Toggle({ 
            Name = 'bullet tracers';
            Flag = 'tracers';
            Default = false;
            Callback = function(v) 
                TracerEnabled = v; 
            end
        })

        Sections.visuals:Dropdown({
            Name = 'tracer style';
            Items = {"Laser 1", "Laser 2", "DNA", "Energy"};
            Default = "Laser 1";
            Callback = function(v) 
                SelectedTracer = v; 
            end
        })

        Sections.visuals:Dropdown({
            Name = 'tracer effect';
            Items = { "Beam", "Trail", "Orb" };
            Default = "Beam";
            Callback = function(v)
                TracerEffect = v;
            end
        })

        Sections.visuals:Dropdown({
            Name = 'tracer path';
            Items = { "Straight", "Curved", "Lightning" };
            Default = "Curved";
            Callback = function(v)
                TracerPath = v;
            end
        })

        Sections.visuals:Slider({
            Name = 'tracer speed (studs/sec)'; Flag = 'tracerspeed';
            Min = 50; Max = 4000; Default = 900; Decimals = 10;
            Callback = function(v) TracerSpeed = v end
        })

        Sections.visuals:Slider({
            Name = 'tracer bend'; Flag = 'tracerbend';
            Min = 0; Max = 2; Default = 0.75; Decimals = 0.05;
            Callback = function(v) TracerBend = v end
        })

        --[[Sections.visuals:Toggle({
            Name = 'no grass';
            Flag = 'nograss';
            Default = false;
            Callback = function(v)
                sethiddenproperty(workspace.Terrain, "Decoration", not v)
            end
        })]]
    --#endregion toggles
end 



do -- misc

    local SpeedhackEnabled = false;
local SpeedhackSpeed = 2;

local _NoclipEnabled = true

--#region infinite jump

local InfiniteJumpEnabled = false

local _InfiniteJumpConnection =
    UserInputService.JumpRequest:Connect(function()

        if not InfiniteJumpEnabled then
            return
        end

        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

        if Humanoid and Humanoid.Health > 0 then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)

--#endregion


-- ==========================================
-- INVAL TIMER - STANDALONE LOCAL SCRIPT
-- ==========================================

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local DURATION = 3
local ENABLED = true

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "InvalTimerGUI"
GUI.ResetOnSpawn = false
GUI.Parent = PlayerGui

local Container = Instance.new("Frame")
Container.Size = UDim2.fromOffset(260, 45)
Container.Position = UDim2.new(0.5, -130, 0, 80)
Container.BackgroundTransparency = 1
Container.Parent = GUI

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 15)
Title.BackgroundTransparency = 1
Title.Text = "Inval Timer Bar"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = Container

-- Outline
local Outline = Instance.new("Frame")
Outline.Position = UDim2.fromOffset(0, 17)
Outline.Size = UDim2.fromOffset(260, 12)
Outline.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
Outline.BorderSizePixel = 0
Outline.Parent = Container

-- Background
local Background = Instance.new("Frame")
Background.Position = UDim2.fromOffset(1, 1)
Background.Size = UDim2.new(1, -2, 1, -2)
Background.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Background.BorderSizePixel = 0
Background.ClipsDescendants = true
Background.Parent = Outline

-- Blue fill
local Fill = Instance.new("Frame")
Fill.Size = UDim2.new(0, 0, 1, 0)
Fill.BackgroundColor3 = Color3.fromRGB(45, 145, 255)
Fill.BorderSizePixel = 0
Fill.Parent = Background

-- Timer
local TimerText = Instance.new("TextLabel")
TimerText.Position = UDim2.fromOffset(0, 30)
TimerText.Size = UDim2.new(1, 0, 0, 15)
TimerText.BackgroundTransparency = 1
TimerText.Text = "0.00s"
TimerText.TextColor3 = Color3.new(1, 1, 1)
TimerText.Font = Enum.Font.Gotham
TimerText.TextSize = 12
TimerText.Parent = Container

-- Timer function
local Connection

local function StartInvalTimer()
    if not ENABLED then return end

    if Connection then
        Connection:Disconnect()
    end

    local StartTime = os.clock()

    Fill.Size = UDim2.new(0, 0, 1, 0)

    Connection = RunService.RenderStepped:Connect(function()
        local Elapsed = os.clock() - StartTime
        local Progress = math.clamp(Elapsed / DURATION, 0, 1)

        Fill.Size = UDim2.new(Progress, 0, 1, 0)
        TimerText.Text = string.format(
            "%.2fs",
            math.min(Elapsed, DURATION)
        )

        if Progress >= 1 then
            Connection:Disconnect()
            Connection = nil
        end
    end)
end

-- Toggle function
local function ToggleInvalTimer(State)
    ENABLED = State
    GUI.Enabled = State

    if not State and Connection then
        Connection:Disconnect()
        Connection = nil
    end
end

-- Functions for your main script
_G.StartInvalTimer = StartInvalTimer
_G.ToggleInvalTimer = ToggleInvalTimer

-- TEST
StartInvalTimer()

-- ==========================================
-- AUTOMATIC ITEM EQUIP DETECTION
-- ==========================================

local function ConnectTool(tool)
    if not tool:IsA("Tool") then return end

    tool.Equipped:Connect(function()
        if _G.StartInvalTimer then
            _G.StartInvalTimer()
        end
    end)
end

local function MonitorCharacter(character)

    -- Existing equipped tools
    for _, item in ipairs(character:GetChildren()) do
        ConnectTool(item)
    end

    -- Newly equipped tools
    character.ChildAdded:Connect(function(item)
        ConnectTool(item)
    end)
end

-- Monitor current character
if Players.LocalPlayer.Character then
    MonitorCharacter(Players.LocalPlayer.Character)
end

-- Monitor respawns
Players.LocalPlayer.CharacterAdded:Connect(function(character)
    MonitorCharacter(character)
end)


    -- Proximity warning only; this cannot block a server-authorized arrest.
    local arrestAlert = false
    local arrestAlertRange = 24
    local arrestGui = Instance.new("ScreenGui")
    arrestGui.Name = "ArrestRiskWarning"
    arrestGui.ResetOnSpawn = false
    arrestGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local arrestText = Instance.new("TextLabel")
    arrestText.Size = UDim2.fromOffset(300, 28)
    arrestText.Position = UDim2.new(0.5, -150, 0, 155)
    arrestText.BackgroundColor3 = Color3.fromRGB(75, 35, 42)
    arrestText.TextColor3 = Color3.fromRGB(255, 200, 200)
    arrestText.Font = Enum.Font.GothamBold
    arrestText.TextSize = 12
    arrestText.Visible = false
    arrestText.Parent = arrestGui
    Sections.movement:Toggle({
        Name = "nearby guard warning"; Flag = "arrestwarning"; Default = false;
        Callback = function(v) arrestAlert = v end;
    })
    Sections.movement:Slider({
        Name = "guard warning range"; Flag = "arrestwarningrange";
        Min = 5; Max = 100; Default = 24; Decimals = 1;
        Callback = function(v) arrestAlertRange = v end;
    })
    local alertClock = 0
    RunService.Heartbeat:Connect(function(dt)
        alertClock += dt
        if alertClock < 0.15 then return end
        alertClock = 0
        local role = TeamRole(LocalPlayer)
        local ownRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local nearest, nearestDistance = nil, arrestAlertRange
        if arrestAlert and ownRoot and (role == "criminal" or role == "prisoner") then
            for _, plr in ipairs(Players:GetPlayers()) do
                local c = plr.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if TeamRole(plr) == "police" and r and hum and hum.Health > 0 then
                    local d = (r.Position - (ownRoot.Position - AAOffset())).Magnitude
                    if d < nearestDistance then nearest, nearestDistance = plr, d end
                end
            end
        end
        arrestText.Visible = nearest ~= nil
        if nearest then
            arrestText.Text = string.format("Nearby guard: %s (%.0f studs)", nearest.DisplayName, nearestDistance)
        end
    end)

    --#region speed hack

        -- PreSimulation (before physics): always moves the real body, never
        -- the UG server pose, so UG cannot erase the movement.
        local _speedhackconnection = RunService.PreSimulation:Connect(function(delta)
            if SpeedhackEnabled then 
                if not LocalPlayer.Character then 
                    return 
                end 

                local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
                if not humanoid then 
                    return 
                end 
                LocalPlayer.Character:TranslateBy(humanoid.MoveDirection * (SpeedhackSpeed) * delta * 10)
            end;
        end)

    --#endregion



    --#region toggles

        Sections.movement:Toggle({
            Name = 'speed hack';
            Flag = 'speedhack';
            Default = false;
            Callback = function(v)
                SpeedhackEnabled = v;
            end 
        })

        Sections.movement:Slider({
            Name = 'speed';
            Flag = 'speed';
            Default = 2;
            Min = 1;
            Max = 40;
            Decimals = 1;
            Callback = function(v)
                SpeedhackSpeed = v;
            end;
        })

Sections.movement:Toggle({
    Name = 'infinite jump';
    Flag = 'infinitejump';
    Default = false;
    Callback = function(v)
        InfiniteJumpEnabled = v;
    end
})
        
        local SoundNames = {}

        for Name in sounds do
            table.insert(SoundNames, Name)
        end

        table.sort(SoundNames)

        Sections.hit:Toggle({
            Name = 'hitsounds';
            Flag = 'hitsounds';
            Default = false;
            Callback = function(v)
                HitSoundEnabled = v;
            end
        })

        Sections.hit:Dropdown({
            Name = 'hitsound';
            Items = SoundNames;
            Default = "Neverlose";
            Callback = function(v)
                SelectedHitSound = v;
            end
        })

        Sections.hit:Slider({
            Name = 'hitsound volume';
            Flag = 'hitsoundvolume';
            Default = 1;
            Min = 0;
            Max = 5;
            Decimals = 0.1;
            Callback = function(v)
                HitSoundVolume = v;
            end
        })
    --#endregion
end 




-- Advanced AA / underground.
--
-- Desync order (per frame):
--   physics -> Heartbeat: save the real pose, move the body to the fake
--              (server) pose. Replication sends THIS pose to the server.
--   next frame, RenderStep First (before the camera): put the real pose back.
--   PreSimulation: safety restore, so physics only ever simulates the real
--              pose.
-- Result: the server body sits underground, the client body stays above
-- ground with normal physics, and the camera (shift lock included) only ever
-- sees the real body. Collision is never touched, so no falling through the
-- map. The real CFrames are saved and written back exactly (not inverted), so
-- knockback / teleports can never leave the body stuck below the floor.
--
-- UG is a pure Y move: the depth slider only changes height. Horizontal pose
-- rolls the body 90 degrees around the character's facing direction so it
-- lies flat with its right side facing up.
--
-- The ONLY thing that drops the desync mid-fight is the failsafe - a miss
-- streak turns UG off for one second, then it returns on its own.
do
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAACleanup) == "function" then
        pcall(env.AdvancedAACleanup)
    end

    local section = Pages.CombatPage:Section({Name = "advanced aa", Side = 2})
    local settings = {
        Enabled = false,
        Square = true,
        Prism = false,
        Underground = false,
        SafeFooting = true,
        HorizontalUG = true,
        ShotPeek = true,
        Range = 4,
        Height = 4,
        UndergroundDepth = 20,
        Speed = 4,
    }

    -- Real pose saved at Heartbeat, written back before render / physics.
    local savedPose = {}          -- [part] = real CFrame
    local savedCharacter = nil
    local savedRoot, savedExpected, savedOffset = nil, nil, Vector3.zero
    local displaced = false       -- body is currently in the server pose
    -- Last server pose, kept after the restore so shot origins stay correct
    -- for code that runs while the body is back in the real pose.
    local serverTransform = nil
    local serverOffset = Vector3.zero

    local assemblyParts, assemblyCharacter, assemblyDirty = {}, nil, true
    local assemblyConns = {}
    local function BindAssembly(character)
        for _, connection in ipairs(assemblyConns) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(assemblyConns)
        table.clear(assemblyParts)
        assemblyCharacter, assemblyDirty = character, true
        if character then
            table.insert(assemblyConns, character.DescendantAdded:Connect(function()
                assemblyDirty = true
            end))
            table.insert(assemblyConns, character.DescendantRemoving:Connect(function()
                assemblyDirty = true
            end))
        end
    end
    local function AssemblyParts(character)
        if assemblyCharacter ~= character then BindAssembly(character) end
        if assemblyDirty then
            table.clear(assemblyParts)
            for _, obj in ipairs(character:GetDescendants()) do
                if obj:IsA("BasePart") and not obj.Anchored then
                    assemblyParts[#assemblyParts + 1] = obj
                end
            end
            assemblyDirty = false
        end
        return assemblyParts
    end

    local phase = 0
    local pausedUntil = 0
    local forceSyncUntil = 0
    local promptHeld = false
    local connections = {}
    local renderKey = "AdvancedAA_Restore_" .. tostring(LocalPlayer.UserId)

    local function now() return os.clock() end
    local function add(connection) table.insert(connections, connection) end

    -- Pose bookkeeping for the aim: when did the server last get each pose.
    local lastDisplacedAt, lastRealAt = 0, os.clock()
    -- Shot peek state.
    local peekUntil, peekStart, peekEndedAt = 0, 0, 0
    local PEEK_MAX, PEEK_COOLDOWN = 0.8, 0.4

    local function syncWindow()
        local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
        ping = (ok and tonumber(ping)) or 0.1
        return math.clamp(ping + 0.05, 0.08, 0.45)
    end

    -- Put the exact real pose back. Never skipped.
    local function restorePose()
        if not displaced then return end
        displaced = false
        local character = savedCharacter
        savedCharacter = nil
        -- Anything that moved us while displaced (speed hack, fly, knockback,
        -- teleports) is carried over instead of being erased.
        local correction = Vector3.zero
        if savedRoot and savedRoot.Parent and savedExpected then
            local drift = savedRoot.Position - savedExpected
            if drift.Magnitude > 50 then
                -- teleport: land exactly where the game put the root
                correction = drift + savedOffset
            elseif drift.Magnitude > 0.001 then
                correction = drift
            end
        end
        savedRoot, savedExpected, savedOffset = nil, nil, Vector3.zero
        if character and character.Parent then
            for part, cf in pairs(savedPose) do
                if part.Parent then
                    pcall(function() part.CFrame = cf + correction end)
                end
            end
        end
        table.clear(savedPose)
    end

    local function clearServerPose()
        serverTransform, serverOffset = nil, Vector3.zero
    end

    local function pauseAA(seconds)
        pausedUntil = math.max(pausedUntil, now() + (seconds or 1.25))
        restorePose()
        clearServerPose()
    end

    -- Failsafe: drop the desync entirely for a moment (real-pose shots).
    local function forceSync(seconds)
        forceSyncUntil = math.max(forceSyncUntil, now() + (seconds or 1))
        pausedUntil = math.max(pausedUntil, forceSyncUntil)
        restorePose()
        clearServerPose()
    end

    env.AdvancedAASyncWindow = syncWindow
    env.AdvancedAAShotState = function()
        local t, w = now(), syncWindow()
        if lastDisplacedAt > lastRealAt then
            -- Displacing: the server has the underground pose once the
            -- last real-pose frame is older than the network window.
            return (t - lastRealAt >= w) and "server" or "transition"
        end
        return (t - lastDisplacedAt >= w) and "real" or "transition"
    end
    env.AdvancedAAPeek = function(seconds)
        if not settings.ShotPeek or not settings.Enabled then return false end
        local t = now()
        if t < peekUntil then
            -- Already peeking: extend, but never past the cap.
            if t - peekStart > PEEK_MAX then return false end
            peekUntil = math.max(peekUntil, math.min(t + seconds, peekStart + PEEK_MAX + 0.2))
            return true
        end
        if peekUntil > 0 and t - peekUntil < PEEK_COOLDOWN then return false end
        peekStart, peekUntil = t, t + seconds
        return true
    end

    env.AdvancedAAPause = pauseAA
    env.AdvancedAAForceSync = forceSync
    env.AdvancedAAStatus = function()
        return settings.Enabled == true, serverOffset.Magnitude, now() < forceSyncUntil
    end
    env.AdvancedAADesync = function()
        if now() < forceSyncUntil then return 0 end
        return serverOffset.Magnitude
    end
    env.AdvancedAAOffset = function() return serverOffset end
    -- Where a given part position is on the SERVER body.
    env.AdvancedAAServerPosition = function(position)
        if displaced or not serverTransform then return position end
        return serverTransform * position
    end
    -- Where a given part position is on the REAL (client) body.
    env.AdvancedAAUnshiftPosition = function(position)
        if not displaced or not serverTransform then return position end
        return serverTransform:Inverse() * position
    end

    -- Pause while interacting so pickup distance checks see the real body.
    local mouse = LocalPlayer:GetMouse()
    add(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.E then
            pauseAA(1.25)
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            local object = mouse.Target
            for _ = 1, 4 do
                if not object or object == workspace then break end
                if object:FindFirstChildOfClass("ClickDetector") then
                    pauseAA(1.25)
                    break
                end
                object = object.Parent
            end
        end
    end))

    local promptService = game:GetService("ProximityPromptService")
    add(promptService.PromptButtonHoldBegan:Connect(function()
        promptHeld = true
        pauseAA(1.25)
    end))
    add(promptService.PromptButtonHoldEnded:Connect(function()
        promptHeld = false
        pauseAA(1.25)
    end))
    add(promptService.PromptTriggered:Connect(function()
        promptHeld = false
        pauseAA(1.25)
    end))

    local function square(t)
        local p = (t % 1) * 4
        local edge = math.floor(p)
        local v = -1 + 2 * (p - edge)
        if edge == 0 then return Vector3.new(v, 0, -1) end
        if edge == 1 then return Vector3.new(1, 0, v) end
        if edge == 2 then return Vector3.new(-v, 0, 1) end
        return Vector3.new(-1, 0, -v)
    end

    local function calculateOffset(t)
        -- UG is a pure vertical move: X and Z are always 0, the depth slider
        -- is the only thing that changes it.
        if settings.Underground then
            return Vector3.new(0, -math.clamp(settings.UndergroundDepth, 1, 30), 0)
        end
        local horizontal = Vector3.zero
        if settings.Square or settings.Prism then horizontal = square(t) * settings.Range end
        local height = 0
        if settings.Prism then
            height = (1 - math.abs(2 * ((t * 0.5) % 1) - 1)) * settings.Height
        end
        return horizontal + Vector3.new(0, height, 0)
    end

    -- Safe footing for square / prism: the server pose must not end up
    -- inside a wall.
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.MaxParts = 8
    local function SpaceFree(position)
        overlap.FilterDescendantsInstances = AAIgnoreList()
        local ok, parts = pcall(function()
            return workspace:GetPartBoundsInRadius(position, 0.8, overlap)
        end)
        if not ok or not parts then return true end
        local character = LocalPlayer.Character
        for _, part in ipairs(parts) do
            if character and part:IsDescendantOf(character) then continue end
            if part:IsA("BasePart") and part.CanCollide and part.Transparency < 0.95 then
                return false
            end
        end
        return true
    end

    -- Heartbeat: runs after physics, right before replication is sent.
    local applyServerPoseInner
    local function applyServerPose(dt)
        applyServerPoseInner(dt)
        if displaced then lastDisplacedAt = now() else lastRealAt = now() end
    end
    function applyServerPoseInner(dt)
        restorePose()
        clearServerPose()
        if not settings.Enabled or promptHeld then return end
        local t = now()
        if t < pausedUntil or t < forceSyncUntil or t < peekUntil then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return end
        if humanoid.SeatPart ~= nil or humanoid.Sit then return end
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Seated or state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Dead then
            return
        end

        phase = (phase + math.min(dt, 0.1) * settings.Speed) % 2
        local offset = calculateOffset(phase)
        if settings.SafeFooting and not settings.Underground and offset.Magnitude > 0.001 then
            local scale = 1
            for _ = 1, 4 do
                if SpaceFree(root.Position + offset * scale) then break end
                scale = scale * 0.5
            end
            offset = (scale < 0.25) and Vector3.zero or offset * scale
        end
        if offset.Magnitude < 0.001 then return end
        local pivot = root.Position
        local destination = pivot + offset
        if destination.Y < workspace.FallenPartsDestroyHeight + 50 then return end

        -- Rotation (UG horizontal only): roll -90 degrees around the
        -- character's own facing direction -> lies flat, right side up.
        local rotation = CFrame.new()
        if settings.Underground and settings.HorizontalUG then
            local look = root.CFrame.LookVector
            look = Vector3.new(look.X, 0, look.Z)
            if look.Magnitude > 0.01 then
                rotation = CFrame.fromAxisAngle(look.Unit, -math.pi / 2)
            end
        end
        -- Rotate around the root, then move straight down by the offset.
        local transform = CFrame.new(pivot + offset) * rotation * CFrame.new(-pivot)

        local parts = AssemblyParts(character)
        table.clear(savedPose)
        for i = 1, #parts do
            local part = parts[i]
            if part.Parent then savedPose[part] = part.CFrame end
        end
        savedCharacter = character
        savedRoot, savedExpected, savedOffset = root, destination, offset
        displaced = true
        for part, cf in pairs(savedPose) do
            pcall(function() part.CFrame = transform * cf end)
        end
        serverTransform, serverOffset = transform, offset
    end

    add(RunService.Heartbeat:Connect(applyServerPose))
    -- Before the camera and render: real body back, so the client sees and
    -- the camera follows the real pose.
    RunService:BindToRenderStep(renderKey, Enum.RenderPriority.First.Value, restorePose)
    -- Before physics: always simulate the real pose.
    add(RunService.PreSimulation:Connect(restorePose))
    add(LocalPlayer.CharacterRemoving:Connect(function()
        restorePose()
        clearServerPose()
    end))

    section:Toggle({
        Name = "advanced aa", Flag = "advanced_aa_enabled", Default = false,
        Callback = function(value)
            settings.Enabled = value
            if not value then restorePose(); clearServerPose() end
        end,
    })
    section:Toggle({ Name = "square", Flag = "advanced_aa_square", Default = true,
        Callback = function(value) settings.Square = value end })
    section:Toggle({ Name = "prism", Flag = "advanced_aa_prism", Default = false,
        Callback = function(value) settings.Prism = value end })
    section:Toggle({ Name = "underground", Flag = "advanced_aa_underground", Default = false,
        Callback = function(value) settings.Underground = value end })
    section:Toggle({ Name = "ug horizontal (right side up)", Flag = "advanced_aa_ughorizontal",
        Default = true,
        Callback = function(value) settings.HorizontalUG = value end })
    section:Toggle({ Name = "ug shot peek (fewer invalids)", Flag = "advanced_aa_shotpeek",
        Default = true,
        Callback = function(value) settings.ShotPeek = value; if not value then peekUntil = 0 end end })
    local function failsafeSet(enabled, attempts, syncTime)
        local target = (type(getgenv) == "function" and getgenv()) or _G
        if type(target.AdvancedAASetFailsafe) == "function" then
            pcall(target.AdvancedAASetFailsafe, enabled, attempts, syncTime)
        end
    end
    section:Toggle({ Name = "failsafe", Flag = "failsafe", Default = true,
        Callback = function(value) failsafeSet(value) end })
    section:Slider({ Name = "failsafe after misses", Flag = "failsafeattempts",
        Min = 1, Max = 8, Default = 3, Decimals = 1,
        Callback = function(value) failsafeSet(nil, value) end })
    section:Slider({ Name = "failsafe pause time (s)", Flag = "failsafepausetime",
        Min = 0.1, Max = 8, Default = 1, Decimals = 0.05,
        Callback = function(value) failsafeSet(nil, nil, value) end })
    section:Toggle({ Name = "safe footing (square / prism)", Flag = "advanced_aa_safefooting",
        Default = true,
        Callback = function(value) settings.SafeFooting = value end })
    section:Slider({
        Name = "aa range (studs)", Flag = "advanced_aa_range",
        Min = 0, Max = 30, Default = 4, Decimals = 1,
        Callback = function(value) settings.Range = value end,
    })
    section:Slider({
        Name = "prism height (studs)", Flag = "advanced_aa_height",
        Min = 0, Max = 30, Default = 4, Decimals = 1,
        Callback = function(value) settings.Height = value end,
    })
    section:Slider({
        Name = "underground depth (studs, Y)", Flag = "advanced_aa_ug_depth",
        Min = 1, Max = 25, Default = 20, Decimals = 1,
        Callback = function(value) settings.UndergroundDepth = value end,
    })
    section:Slider({
        Name = "aa speed (cycles/sec)", Flag = "advanced_aa_speed",
        Min = 1, Max = 40, Default = 4, Decimals = 1,
        Callback = function(value) settings.Speed = value end,
    })

    env.AdvancedAACleanup = function()
        settings.Enabled = false
        restorePose()
        clearServerPose()
        pcall(function() RunService:UnbindFromRenderStep(renderKey) end)
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)
        for _, connection in ipairs(assemblyConns) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(assemblyConns)
        table.clear(assemblyParts)
        assemblyCharacter = nil
        if env.AdvancedAAPause == pauseAA then env.AdvancedAAPause = nil end
        if env.AdvancedAAForceSync == forceSync then env.AdvancedAAForceSync = nil end
        env.AdvancedAAStatus = nil
        env.AdvancedAADesync = nil
        env.AdvancedAAOffset = nil
        env.AdvancedAAServerPosition = nil
        env.AdvancedAAUnshiftPosition = nil
        env.AdvancedAAShotState = nil
        env.AdvancedAAPeek = nil
        env.AdvancedAASyncWindow = nil
    end
end


    --#region hitbox expander
    -- Widens the surface the aim code samples around each target and draws a
    -- smooth translucent hull that follows chams. It does not change server
    -- hitboxes; only our own sampling and visuals are affected.
    do
        local HullFolder = Instance.new("Folder")
        HullFolder.Name = "HitboxExpanderHulls"
        local hulls = {}

        local function destroyHull(player)
            local hull = hulls[player]
            if hull then hull:Destroy(); hulls[player] = nil end
        end

        local function clearHulls()
            for player in pairs(hulls) do destroyHull(player) end
            HullFolder.Parent = nil
        end

        Sections.visuals:Toggle({
            Name = "hitbox expander"; Flag = "hitboxexpander"; Default = false;
            Callback = function(v)
                HitboxExpander.Enabled = v
                if not v then clearHulls() end
            end
        })
        Sections.visuals:Slider({
            Name = "expander size (studs)"; Flag = "hitboxexpandsize";
            Min = 0.5; Max = 8; Default = 1.5; Decimals = 1;
            Callback = function(v) HitboxExpander.Size = v end
        })
        Sections.visuals:Slider({
            Name = "expander samples"; Flag = "hitboxexpandsamples";
            Min = 4; Max = 64; Default = 12; Decimals = 1;
            Callback = function(v) HitboxExpander.Samples = v end
        })
        Sections.visuals:Toggle({
            Name = "expander visual"; Flag = "hitboxexpandvisual"; Default = true;
            Callback = function(v)
                HitboxExpander.Visual = v
                if not v then clearHulls() end
            end
        })
        Sections.visuals:Label({Name = "expander color"}):Colorpicker({
            Default = Color3.fromRGB(120, 190, 255);
            Callback = function(v) HitboxExpander.Color = v end
        })

        RunService.RenderStepped:Connect(function(dt)
            local follow = 1 - math.exp(-14 * math.clamp(dt or 0.016, 0, 0.1))
            if not (HitboxExpander.Enabled and HitboxExpander.Visual) then
                if next(hulls) then clearHulls() end
                return
            end
            if HullFolder.Parent ~= workspace then HullFolder.Parent = workspace end
            local seen = {}
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and TargetPriority(plr) then
                    local character = plr.Character
                    local body = character and (character:FindFirstChild("UpperTorso")
                        or character:FindFirstChild("Torso")
                        or character:FindFirstChild("HumanoidRootPart"))
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if body and humanoid and humanoid.Health > 0 then
                        seen[plr] = true
                        local hull = hulls[plr]
                        if not hull or not hull.Parent then
                            hull = Instance.new("Part")
                            hull.Name = "HitboxHull_" .. plr.Name
                            hull.Anchored, hull.CanCollide, hull.CanQuery = true, false, false
                            hull.Massless = true
                            hull.Material = Enum.Material.ForceField
                            hull.CastShadow = false
                            hull.Parent = HullFolder
                            hulls[plr] = hull
                        end
                        local expand = math.max(HitboxExpander.Size, 0)
                        local goalCFrame = CFrame.new(body.Position) * (body.CFrame - body.CFrame.Position)
                        local goalSize = Vector3.new(body.Size.X + expand * 2, body.Size.Y + expand * 2, body.Size.Z + expand * 2)
                        -- Smooth follow so the hull glides between frames.
                        hull.CFrame = hull.CFrame:Lerp(goalCFrame, follow)
                        hull.Size = hull.Size:Lerp(goalSize, follow)
                        hull.Color = HitboxExpander.Color
                        hull.Transparency = HitboxExpander.Transparency
                    end
                end
            end
            for plr in pairs(hulls) do
                if not seen[plr] then destroyHull(plr) end
            end
        end)
    end
    --#endregion

Window:InitWindow()
