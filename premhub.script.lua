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
        -- Kill feed hook, assigned by the kill feed region near the end of the
        -- file. Declared here (before the death hook below reads it) so the read
        -- resolves to this local instead of a global that never gets set.
        local PushKillFeed;
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

        -- Hitmarkers: a short animated X plus an expanding ring, drawn where
        -- the shot landed. Headshots and kills get their own colour. Purely
        -- client-side Drawing objects, reused from a small pool so a fast
        -- firing rate never allocates.
        local Hitmarker = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            HeadColor = Color3.fromRGB(255, 90, 90),
            KillColor = Color3.fromRGB(255, 40, 40),
            Size = 16,
            Duration = 0.45,
        }
        local SpawnHitmarker
        do
            local POOL_SIZE = 16
            local pool, cursor = {}, 0

            for _ = 1, POOL_SIZE do
                local marker = { Lines = {}, Active = false, T = 0 }
                for i = 1, 4 do
                    local line = Drawing.new("Line")
                    line.Visible = false
                    line.Thickness = 2
                    line.Transparency = 1
                    marker.Lines[i] = line
                end
                local ring = Drawing.new("Circle")
                ring.Visible = false
                ring.Thickness = 1.5
                ring.Radius = 1
                marker.Ring = ring
                pool[#pool + 1] = marker
            end

            function SpawnHitmarker(position, head, kill)
                if not Hitmarker.Enabled or typeof(position) ~= "Vector2" then return end
                cursor = cursor % POOL_SIZE + 1
                local marker = pool[cursor]
                marker.Active = true
                marker.T = 0
                marker.Position = position
                marker.Head = head == true
                marker.Kill = kill == true
            end

            RunService.RenderStepped:Connect(function(dt)
                local step = math.clamp(dt or 0.016, 0, 0.1)
                for _, marker in ipairs(pool) do
                    if marker.Active then
                        marker.T += step
                        local progress = marker.T / math.max(Hitmarker.Duration, 0.05)
                        if progress >= 1 then
                            marker.Active = false
                            for _, line in ipairs(marker.Lines) do line.Visible = false end
                            marker.Ring.Visible = false
                        else
                            local color = marker.Kill and Hitmarker.KillColor
                                or (marker.Head and Hitmarker.HeadColor or Hitmarker.Color)
                            -- pop out then settle, fade to nothing, spin a touch
                            local pop = 1 + 0.35 * math.sin(math.min(progress, 1) * math.pi)
                            local scale = (0.75 + 0.6 * progress) * pop
                            local alpha = 1 - progress
                            local center = marker.Position
                            local inner = Hitmarker.Size * 0.45 * scale
                            local outer = Hitmarker.Size * scale
                            for i = 1, 4 do
                                local angle = progress * 0.35 + math.rad(45 + (i - 1) * 90)
                                local dir = Vector2.new(math.cos(angle), math.sin(angle))
                                local line = marker.Lines[i]
                                line.From = center + dir * inner
                                line.To = center + dir * outer
                                line.Color = color
                                line.Thickness = marker.Kill and 3 or 2
                                line.Transparency = alpha
                                line.Visible = true
                            end
                            local ring = marker.Ring
                            ring.Position = center
                            ring.Radius = outer * 1.15
                            ring.Color = color
                            ring.Transparency = alpha * 0.55
                            ring.Visible = true
                        end
                    end
                end
            end)
        end

        local function MarkShots(Shots)
            for _, v in Shots do
                local Hit = type(v) == 'table' and v[3]

                if typeof(Hit) ~= "Instance" then
                    continue
                end

                local Model = Hit:FindFirstAncestorOfClass("Model")

                if Model then
                    -- Keep the impact point so the hitmarker can be drawn where
                    -- the shot actually landed (not just under the crosshair).
                    local point = type(v) == 'table' and v[2]
                    ShotAt[Model] = {
                        t = os.clock(),
                        part = Hit,
                        pos = typeof(point) == "Vector3" and point or Hit.Position,
                    }
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

                if Health < LastHealth and Shot and os.clock() - Shot.t < 0.5 then
                    if HitSoundEnabled then
                        PlayHitSound()
                    end
                    if Hitmarker.Enabled then
                        local head = Shot.part and Shot.part.Name == "Head"
                        local world = (head and Shot.part and Shot.part.Position) or Shot.pos
                        local screen
                        local camera = workspace.CurrentCamera
                        if camera and typeof(world) == "Vector3" then
                            local point, onScreen = camera:WorldToViewportPoint(world)
                            if onScreen and point.Z > 0 then
                                screen = Vector2.new(point.X, point.Y)
                            end
                        end
                        SpawnHitmarker(screen or UserInputService:GetMouseLocation(), head, Health <= 0)
                    end
                end

                -- Report the death to the kill feed. A death that follows one of
                -- our own shots (ShotAt is set by MarkShots on every shot we
                -- fire) counts as our kill.
                if Health <= 0 and LastHealth > 0 and PushKillFeed then
                    local victim = Players:GetPlayerFromCharacter(Character)
                    if victim then
                        PushKillFeed(victim, Shot ~= nil and os.clock() - Shot.t < 0.5)
                    end
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
    -- Custom view-model shot hook (assigned near the end of the file). The shot
    -- paths call this so the tracer starts at the view model's barrel instead of
    -- the head. Nil until that region runs.
    local ViewModelShot;
    -- Custom view-model muzzle accessor (assigned near the end of the file). It
    -- returns the barrel's world CFrame while the view model is drawn, so the
    -- snap line can start from the gun barrel instead of the crosshair. Nil
    -- until that region runs.
    local ViewModelMuzzle;
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
        Rank = "developer",
        Size = UDim2.fromOffset(660, 640)
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

-- Player filter (see the "player filter" dropdowns in the aimbot section):
-- whitelisted names are ignored by every combat feature (silent aim,
-- ragebot, peek resolver, chams, hitbox hulls) while ESP still draws them;
-- blacklisted names are forced to the top of every targeting pass, with
-- everyone else still available when they are dead / gone.
local WhitelistedPlayers = {}
local BlacklistedPlayers = {}

-- Team whitelists (the "team whitelist" dropdowns in the player filter).
-- An empty selection means every team is allowed, exactly like the name
-- whitelist above. The dropdown labels match the game's own team names and
-- are mapped onto the roles TeamRole() returns below:
--   inmate -> prisoner, police -> police, criminals -> criminal
local AimTeamWhitelist = {}
local ESPTeamWhitelist = {}
local TEAM_WHITELIST_ITEMS = { "inmate", "police", "criminals" }
local TEAM_WHITELIST_ROLES = {
    inmate = "prisoner",
    police = "police",
    criminals = "criminal",
}

-- Targeting range, always 10 studs past the ESP draw distance: anything the
-- aimbot locks on stays drawn by ESP. Reads the ESP library's live slider
-- value through getgenv (it publishes itself there), the same bridge the
-- advanced-aa settings use; the fallback matches the ESP default of 500.
local targetingRangeAt, targetingRangeValue = 0, 510
local function TargetingRange()
    -- The library's distance slider changes rarely, and this is read from the
    -- aim / ragebot / ESP paths many times per frame, so the resolved value is
    -- cached briefly instead of walking getgenv() and the settings table each
    -- call.
    local t = os.clock()
    if t - targetingRangeAt < 0.25 then return targetingRangeValue end
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local lib = type(env.EspLib) == "table" and env.EspLib or nil
    local value = 510
    if lib and type(lib.Table) == "table" then
        local dist = tonumber(lib.Table.Distance)
        if dist and dist > 0 then value = dist + 10 end
    end
    targetingRangeAt, targetingRangeValue = t, value
    return value
end
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
-- Team whitelist test. `set` is AimTeamWhitelist or ESPTeamWhitelist; empty
-- means "no restriction". Unknown teams (role "unknown") are only allowed by
-- an empty selection, so a whitelist can never accidentally leak them in.
local function TeamWhitelistAllows(set, player)
    if next(set) == nil then return true end
    return set[TeamRole(player)] == true
end
local function TargetPriority(player)
    if not player or player == LocalPlayer then return nil end
    if WhitelistedPlayers[player.Name] then return nil end
    if BlacklistedPlayers[player.Name] then return -1 end
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
    -- Aim team whitelist: when teams are selected, nothing else may be aimed
    -- at (this is checked before the blacklist so a blacklisted player on a
    -- filtered-out team stays filtered out).
    if not TeamWhitelistAllows(AimTeamWhitelist, plr) then return nil end
    local localRole, targetRole = TeamRole(LocalPlayer), TeamRole(plr)
    if localRole == "police" and targetRole == "prisoner" and not IsHostilePrisoner(plr)
        and not BlacklistedPlayers[plr.Name] then
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

-- True when the active AA is a moving square / prism (not UG, not anti-ESP).
-- Orbit shots are built from the live pose, so one occluded frame must not
-- park the orbit with a peek - fire is held briefly instead.
local function AAIsOrbit()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAIsOrbit) == "function" then
        local ok, value = pcall(env.AdvancedAAIsOrbit)
        if ok then return value == true end
    end
    return false
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

-- Shot outcome feedback to the advanced-aa auto UG depth. The watcher below
-- reports each shot that was fired from a displaced pose: hits ease the depth
-- back, misses deepen it.
local function AAFeedback(hit)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAFeedback) == "function" then
        pcall(env.AdvancedAAFeedback, hit == true)
    end
end

-- True while the auto UG depth feature is on, so the shot-outcome watcher
-- keeps running even when the failsafe itself is switched off.
local function AAAutoDepthOn()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    return env.AdvancedAAAutoDepth == true
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

-- Freeze the orbiting server pose at its current point for a moment. While
-- square / prism moves the server position, a shot built from the current
-- pose can arrive after the pose has already moved on, which the server
-- reads as a bad origin: freezing holds the exact pose the shot was built
-- from until the shot has been validated, so the aim keeps landing while
-- the position-based AA is running.
local function AAFreeze(seconds)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAFreeze) == "function" then
        pcall(env.AdvancedAAFreeze, seconds)
    end
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
-- Kept for reference; the live shot paths now pick the pose inline.
local function _ShotOrigin(head)
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
    local half = body.Size * 0.5 + Vector3.new(radius, radius, radius)

    -- Shooting from below (UG / anti-ESP pose): bias the pick
    -- towards the underside of the hull. From an underground origin the
    -- shallow under-map lines are the ones that actually register, so the
    -- lowest clear sample beats an arbitrary first hit. When the origin is
    -- level with or above the body the bias is zero and the most central
    -- clear sample wins instead. Every clear sample is scored (the old code
    -- stopped at the first one, which was order-dependent and often the
    -- wrong side of the hull).
    local below = origin.Y < body.Position.Y - 1
    local toBody = body.Position - origin
    local axis = toBody.Magnitude > 0.01 and toBody.Unit or Vector3.yAxis

    local bestPoint, bestPart, bestScore
    for i = 1, count do
        local y = 1 - 2 * ((i - 0.5) / count)
        local radial = math.sqrt(math.max(0, 1 - y * y))
        local angle = i * golden
        local unit = Vector3.new(math.cos(angle) * radial, y, math.sin(angle) * radial)
        local localPoint = Vector3.new(unit.X * half.X, unit.Y * half.Y, unit.Z * half.Z)
        local point = body.CFrame:PointToWorldSpace(localPoint)
        local delta = point - origin
        if delta.Magnitude > 0.01 then
            local hit = workspace:Raycast(origin, delta * 1.01, params)
            if not hit or hit.Instance:IsDescendantOf(character) then
                -- Lower score = better. Lateral distance off the origin->body
                -- line keeps the shot central; the underside bias (negative
                -- local Y = lower half) pulls it down when we shoot from below.
                local along = delta:Dot(axis)
                local lateral = (delta - axis * along).Magnitude
                local score = lateral
                if below then score += localPoint.Y * 0.6 end
                if not bestScore or score < bestScore then
                    bestPoint, bestPart, bestScore = point, body, score
                end
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
    -- Smart UG: this game lets a bullet skim UNDER the map surface when the
    -- line is angled (terrain wallbang), so terrain must never be treated as
    -- infinite cover. When enabled, a terrain hit is reported as a passable
    -- "terrain" line that the aim may use when nothing cleaner exists.
    TerrainPass = true,
    -- Vehicle wallbang: a part that belongs to a car is stepped through instead
    -- of counted as cover, so a line whose only obstruction is a vehicle reads
    -- as clear and the shot fires through the car.
    VehicleWallbang = false,
    -- Derived from the single budget slider below (percent of the full budget).
    Budget = 25,
    MaxThickness = 5,
    MaxLayers = 2,
    -- Panel readout of the most recent measurement.
    Last = { label = "idle", thickness = 0, layers = 0, time = 0 },
    -- Written at runtime; declared here so the type checker knows the keys.
    BackoffUntil = 0,
    _markerTime = 0,
    Cache = WeakKeyedTable(),
}

local WALLPEN_MIN_SPAN = 0.02
-- Terrain only leaks bullets when the line is angled: |unit.Y| above this is
-- near vertical (straight down into the ground) and stays blocked.
local WALLPEN_TERRAIN_MAX_SLOPE = 0.9
-- Full budget. The old ceiling (5 studs / 6 layers) was below a floor between
-- storeys, so shooting someone on the level below was always "Blocked" and the
-- raw aim just hit the floor. 20 studs also covers a baseplate-thick slab at
-- 100%.
local WALLPEN_FULL_THICKNESS = 20
local WALLPEN_FULL_LAYERS = 8

-- One slider owns both limits so the layer budget can never sit above what the
-- thickness budget allows: 25% = 5 studs / 2 layers, 100% = 20 studs / 8.
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
-- A part belongs to a vehicle when its model (or the model wrapping it) holds
-- a Seat / VehicleSeat. Cached briefly per part: a car is many panels and the
-- trace asks about each one.
local vehicleParts = WeakKeyedTable()
local vehiclePartTime = WeakKeyedTable()
local function IsVehiclePart(part)
    local now = os.clock()
    local cached = vehicleParts[part]
    if cached ~= nil and now - (vehiclePartTime[part] or 0) < 1 then
        return cached
    end
    local result = false
    local model = part:FindFirstAncestorOfClass("Model")
    if model then
        if model:FindFirstChildOfClass("VehicleSeat")
            or model:FindFirstChildOfClass("Seat") then
            result = true
        else
            local outer = model:FindFirstAncestorOfClass("Model")
            if outer and (outer:FindFirstChildOfClass("VehicleSeat")
                or outer:FindFirstChildOfClass("Seat")) then
                result = true
            end
        end
    end
    vehicleParts[part] = result
    vehiclePartTime[part] = now
    return result
end

local function IsCover(part)
    if not part or not part:IsA("BasePart") then return false end
    if not part.CanCollide then return false end
    if part.Transparency >= 0.9 then return false end
    -- Vehicle wallbang: cars are hitbox-dense and would otherwise always read as
    -- solid cover, so they are skipped exactly like decoration.
    if WallPen.VehicleWallbang and IsVehiclePart(part) then return false end
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
        -- Smart UG / terrain wallbang: this game's bullets skim under the map
        -- surface when the line is angled, so terrain is NOT cover. It is
        -- reported as its own "terrain" state and the aim decides whether to
        -- spend the shot on it (EvaluateShot). Steep, near-vertical lines
        -- still count as blocked, and the aim failsafe's backoff quiets
        -- terrain shots exactly like any other wallpen attempt.
        if part:IsA("Terrain") then
            if not WallPen.TerrainPass
                or math.abs(unit.Y) > WALLPEN_TERRAIN_MAX_SLOPE
                or os.clock() < (WallPen.BackoffUntil or 0) then
                return { state = "blocked", thickness = math.huge, layers = layers + 1,
                    part = part, entry = hit.Position, exit = hit.Position, terrain = true }
            end
            return { state = "terrain", thickness = 0, layers = 0,
                part = part, entry = hit.Position, exit = hit.Position }
        end
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
    local MaxAimCandidates = 8;
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

    local function _FailsafeReady()
        return FailsafeEnabled and FailsafeMissStreak >= FailsafeAttempts;
    end

    -- Failsafe trigger now happens inside FailsafeWatch the moment the miss
    -- limit is reached. Kept as a no-op for reference.
    local function _FailsafeApply() end

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
        if not (FailsafeEnabled or AAAutoDepthOn()) or not targetPlayer or FailsafePending then return end
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
                AAFeedback(true);
                return
            end
            -- UG got paused/disabled while waiting: do not count this one.
            if AADesync() < 0.25 then return end
            AAFeedback(false);
            FailsafeMissStreak += 1;
            if FailsafeEnabled and FailsafeMissStreak >= FailsafeAttempts
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
    local AutoWeaponSwitch = false;
    local RagebotTarget = nil 
    local SilentAimTarget = nil 

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
            -- Reused by the curved path so a tracer no longer builds a fresh
            -- RaycastParams (and closure) on every shot.
            local tracerCurveParams = RaycastParams.new()
            tracerCurveParams.FilterType = Enum.RaycastFilterType.Exclude
            tracerCurveParams.IgnoreWater = true
            local tracerAttachments = setmetatable({}, { __mode = "k" })
            local TRACER_POOL_LIMIT = 512

            local function TakeTracerPart()
                local part = table.remove(tracerPartPool)
                if part then return part end
                local new = Instance.new("Part")
                new.Anchored, new.CanCollide, new.CanQuery = true, false, false
                new.Size = Vector3.new(0.2, 0.2, 0.2)
                new.Transparency = 1
                -- Marked so the "remove game tracers" scrubber can tell our
                -- geometry apart from the game's and never hide it.
                new:SetAttribute("NegrohaxTracer", true)
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
                new:SetAttribute("NegrohaxTracer", true)
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
                    local params = tracerCurveParams
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
                    head:SetAttribute("NegrohaxTracer", true)
                    head.Parent = workspace
                    if TracerEffect == "Trail" then
                        local a0 = TracerAttachment(nodes[1], 3)
                        local a1 = Instance.new("Attachment", head)
                        trail = Instance.new("Trail")
                        trail.Attachment0, trail.Attachment1 = a0, a1
                        trail.Lifetime = 0.35
                        trail.LightEmission = 1
                        trail.Color = ColorSequence.new(Color3.fromRGB(180, 225, 255), Color3.fromRGB(90, 130, 255))
                        trail:SetAttribute("NegrohaxTracer", true)
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
        -- Origin manipulation: find the smallest point inside a sphere of
        -- `manip dist` studs around our own head - straight up, straight
        -- sideways, or anywhere between - that can land a shot on the target.
        -- The shot is then fired from the SERVER-held pose moved to that point
        -- (see FireManipShot): the server validates every shot against the pose
        -- it holds, so only the server copy is moved and the client body /
        -- camera never move. That is what lets a shot leave from around or over
        -- cover the straight line cannot clear, while the server still sees a
        -- bullet from a pose the character can plausibly occupy.
        --
        -- Spots the target's own head cannot see are preferred (their aimbot
        -- cannot lock on), and the shot lands on a clear line to any body part
        -- or through cover within the wallpen budget; only when no hidden spot
        -- exists does it fall back to an exposed clear-line spot. A found spot
        -- is reused for a burst of shots and only re-rolled on a timer, so
        -- consecutive shots leave from the same origin (consistent) while the
        -- spot still drifts over time so it cannot be pre-aimed; the
        -- through-cover tier is kept only while it is actually landing (see
        -- ManipWallResult) - no toggle needed.
        local Manip = {
            Enabled = false,
            Max = 20,     -- furthest the origin may move (dist slider, 0-20)
            Scan = 12,    -- angles tried per ring (scan slider, CPU knob)
            Rings = 12,   -- evenly spaced distance steps between ~1 stud and Max
        }

        local manipParams = RaycastParams.new()
        manipParams.FilterType = Enum.RaycastFilterType.Exclude
        manipParams.IgnoreWater = true
        pcall(function() manipParams.CollisionGroup = "ClientBullet" end)

        local manipOverlap = OverlapParams.new()
        manipOverlap.FilterType = Enum.RaycastFilterType.Exclude
        manipOverlap.MaxParts = 8

        -- Open-air test. A ray cast from inside a part reports no hit, so the
        -- only way to reject an origin buried in the wall is an overlap query
        -- around the candidate point.
        local function ManipFree(point)
            manipOverlap.FilterDescendantsInstances = AAIgnoreList()
            local ok, parts = pcall(function()
                return workspace:GetPartBoundsInRadius(point, 0.5, manipOverlap)
            end)
            if not ok or not parts then return true end
            for _, part in ipairs(parts) do
                if part:IsA("BasePart") and part.CanCollide and part.Transparency < 0.95 then
                    return false
                end
            end
            return true
        end

        -- Does a shot from `from` actually reach the target's body? Only the
        -- first hit counts: a descendant of the target's model means the line is
        -- real, anything else is cover.
        local function ManipReaches(from, aim, model)
            manipParams.FilterDescendantsInstances = AAIgnoreList()
            local delta = aim - from
            local distance = delta.Magnitude
            if distance < 0.001 then return nil end
            local hit = workspace:Raycast(from, delta + delta.Unit * 0.02, manipParams)
            if hit and hit.Instance and hit.Instance:IsDescendantOf(model) then
                return hit.Instance, hit.Position
            end
            return nil
        end

        -- Hidden = the target's own head cannot see the spot: every eye-height
        -- ray is blocked by cover, so their aimbot's visibility check fails and
        -- it cannot lock while the server pose stands there. The target's body
        -- and our own ignore list are filtered out. Same rule the old peek
        -- resolver used for its safe spots.
        local manipHideParams = RaycastParams.new()
        manipHideParams.FilterType = Enum.RaycastFilterType.Exclude
        manipHideParams.IgnoreWater = true
        pcall(function() manipHideParams.CollisionGroup = "ClientBullet" end)

        -- Reused filter table: the target model is appended to the cached
        -- AAIgnoreList() instead of cloning a fresh list for every ray.
        local manipHideList, manipHideModel, manipHideBase, manipHideAt = {}, nil, nil, 0
        local function ManipHideFilter(model)
            local base = AAIgnoreList()
            local now = os.clock()
            if model ~= manipHideModel or base ~= manipHideBase
                or base[1] ~= manipHideList[1] or now - manipHideAt > 0.5 then
                table.clear(manipHideList)
                for i = 1, #base do manipHideList[i] = base[i] end
                if model then manipHideList[#manipHideList + 1] = model end
                manipHideModel, manipHideBase, manipHideAt = model, base, now
            end
            return manipHideList
        end

        local function ManipHidden(spot, model)
            local head = model and model:FindFirstChild("Head")
            if not head then return false end
            manipHideParams.FilterDescendantsInstances = ManipHideFilter(model)
            for _, lift in ipairs({ 0, 1.5, 3 }) do
                local eye = head.Position + Vector3.new(0, lift, 0)
                local delta = spot - eye
                if delta.Magnitude > 0.5
                    and not workspace:Raycast(eye, delta, manipHideParams) then
                    return false
                end
            end
            return true
        end

        -- Tier-2 (wallbang) hidden spots are only worth using while the server
        -- is actually registering through-cover shots, which varies by gun and
        -- by how the hit is validated. Auto mode watches the outcome of every
        -- wallbang manip shot: a couple of misses in a row switch tier 2 off
        -- for a moment (the search then uses clear-line spots), and the next
        -- hit switches it back. It finds its own level instead of needing a
        -- toggle.
        local MANIP_WALL_MISSES = 2
        local MANIP_WALL_RETRY = 5
        local manipWallMisses = 0
        local manipWallBlockUntil = 0
        local function ManipWallAllowed()
            return os.clock() >= manipWallBlockUntil
        end
        local function ManipWallResult(hit)
            if hit then
                manipWallMisses = 0
                manipWallBlockUntil = 0
            else
                manipWallMisses = manipWallMisses + 1
                if manipWallMisses >= MANIP_WALL_MISSES then
                    manipWallMisses = 0
                    manipWallBlockUntil = os.clock() + MANIP_WALL_RETRY
                end
            end
        end

        -- Can our shot actually land from `from`? A clear line to ANY part of
        -- the rig counts (the head is usually the only thing the target's own
        -- cover hides), and a measured wallbang on cover within budget counts
        -- too - the same test EvaluateShot runs, kept light here because the
        -- search tries many spots. The third result says whether the shot was a
        -- clear line (`true`) or only a wallbang (`false`): a clear line is
        -- preferred because the server always registers it.
        local function ManipLands(from, model)
            local wallPart, wallPos
            for _, name in ipairs(RIG_PART_NAMES) do
                local part = model:FindFirstChild(name)
                if part and part:IsA("BasePart") then
                    local hitPart, hitPos = ManipReaches(from, part.Position, model)
                    if hitPart then return hitPart, hitPos, true end
                    if WallPen.Enabled and ManipWallAllowed() and not wallPart then
                        local trace = WallPen.Probe(part, from, part.Position, model)
                        if trace.state == "clear" then
                            wallPart, wallPos = trace.reached or part, part.Position
                        elseif trace.state == "blocked"
                            and WallPen.CanPenetrate(trace.thickness, trace.layers) then
                            wallPart, wallPos = part, part.Position
                        end
                    end
                end
            end
            if wallPart then return wallPart, wallPos, false end
            return nil
        end

        -- The directions an origin may move in, cached because the shot paths
        -- call this on every blocked shot. The six cardinal axes come first so
        -- "20 studs straight up" (or straight sideways) is always reachable;
        -- the rest are a Fibonacci sphere, which spreads evenly with no
        -- clumping at the poles. Only rebuilt when the scan slider changes.
        local manipDirs, manipDirsScan = nil, -1
        local function ManipDirections(scan)
            if manipDirs and manipDirsScan == scan then return manipDirs end
            local dirs = {
                Vector3.yAxis, -Vector3.yAxis,
                Vector3.xAxis, -Vector3.xAxis,
                Vector3.zAxis, -Vector3.zAxis,
            }
            local golden = math.pi * (3 - math.sqrt(5))
            for i = 1, scan do
                local y = 1 - 2 * ((i - 0.5) / scan)
                local radial = math.sqrt(math.max(0, 1 - y * y))
                local angle = i * golden
                dirs[#dirs + 1] = Vector3.new(
                    math.cos(angle) * radial, y, math.sin(angle) * radial)
            end
            manipDirs, manipDirsScan = dirs, scan
            return dirs
        end

        -- Returns a shot plan (or nil) tagged with `manip = true`. The shot
        -- paths branch on that tag and hand the plan to FireManipShot, which
        -- moves the server pose onto `origin + plan.offset` before firing - the
        -- offset is NOT added to the shot origin the way the other plans' are.
        --
        -- The search prefers a spot the target's own head cannot see (their
        -- aimbot cannot lock) and only falls back to an exposed clear-line spot
        -- when no hidden one exists. This is the heaviest probe in EvaluateShot
        -- and the aim asks for it every frame, so the result is cached per
        -- target for a moment. Several slots are kept because the same target is
        -- asked about from two origins (the real and the server-held head)
        -- inside one frame while anti-aim is displacing, and a single slot would
        -- thrash between them and never hit.
        -- All manip search state lives in one table. The block this sits in is
        -- already near the -O0 register ceiling, so a dozen separate locals
        -- here would push the unoptimised build over the limit.
        local manipState = {
            cache = setmetatable({}, { __mode = "k" }),
            miss = setmetatable({}, { __mode = "k" }),
            spin = setmetatable({}, { __mode = "k" }),
            -- A found spot is reused for a burst of shots so consecutive manip
            -- shots at the same target leave from the SAME origin. Re-searching
            -- every frame picked a slightly different spot each time, which is
            -- what made the feature feel erratic: one shot landed and the next
            -- did not. FireManipShot re-validates the shot before firing, so a
            -- stale spot can only cause a held shot, never an invalid one.
            cacheTTL = 0.35,
            cacheSlots = 3,
            cacheReach = 1.5,
            -- When nothing works, do not re-run the whole search every frame:
            -- the answer barely changes in a few frames and the scan is the
            -- heaviest probe in the aim, so a miss parks the target for a bit.
            missTTL = 0.2,
            -- Hidden candidates still have to be checked for a landing shot (a
            -- ray per rig part, plus wallpens). That check is the expensive
            -- part, so it is capped; past the cap the search only keeps what it
            -- already found.
            hiddenTries = 24,
            -- Once a usable exposed spot exists the search keeps looking for a
            -- hidden one only this much longer before taking the exposed spot.
            -- Without the bound a blocked target scanned every candidate in
            -- every ring on every frame - the biggest cost in the whole aim -
            -- even though the exposed fallback was already good enough.
            hiddenExtra = 36,
            -- The direction the search starts from is re-rolled on a timer
            -- instead of on every call: every search inside one window walks
            -- the same order, so repeated shots pick the same spot, while the
            -- spot still drifts over time so it cannot be pre-aimed.
            spinTTL = 0.8,
        }

        local function ManipCacheLookup(target, origin)
            local slots = manipState.cache[target]
            if not slots then return false, nil, nil end
            local now = os.clock()
            for i = 1, #slots do
                local slot = slots[i]
                if now - slot.time < manipState.cacheTTL
                    and (slot.origin - origin).Magnitude < manipState.cacheReach then
                    return true, slot.plan, slots
                end
            end
            return false, nil, slots
        end

        local function ManipPlan(target, origin)
            if not Manip.Enabled then return nil end
            local model = target and target:FindFirstAncestorOfClass("Model")
            if not model or typeof(origin) ~= "Vector3" then return nil end
            local part = model:FindFirstChild("Head") or target
            if not part then return nil end
            local aim = part.Position
            local delta = aim - origin
            if delta.Magnitude < 0.5 then return nil end

            -- Keyed by the target's model, not the part: the aim asks about the
            -- head while FireManipShot re-asks about the same model, and both
            -- have to share one cached spot.
            local found, cachedPlan, slots = ManipCacheLookup(model, origin)
            if found then return cachedPlan end
            local missAt = manipState.miss[model]
            if missAt and os.clock() - missAt < manipState.missTTL then return nil end
            local function finish(plan)
                slots = slots or {}
                slots[#slots + 1] = { origin = origin, time = os.clock(), plan = plan }
                while #slots > manipState.cacheSlots do table.remove(slots, 1) end
                manipState.cache[model] = slots
                return plan
            end

            -- Straight shot already reaches the target: one raycast, nothing to
            -- fix. This is the main performance guard, and it is NOT cached -
            -- caching it would keep the manip off for a moment after the target
            -- ducks behind cover.
            if ManipReaches(origin, aim, model) then return nil end

            local limit = math.clamp(Manip.Max, 0, 20)
            if limit <= 0.1 then return nil end
            local rings = math.clamp(math.floor(Manip.Rings), 1, 24)
            local scan = math.clamp(math.floor(Manip.Scan), 4, 48)

            -- Every direction out to `manip dist` studs, at EVENLY spaced radii
            -- from ~1 stud to the maximum (e.g. 1, 2.7, 4.5 ... 20 with 12
            -- steps). Even steps matter more than geometric ones here: the old
            -- geometric set jumped straight from ~9.5 to 20, so a spot that
            -- needed 12-15 studs was never tried and the manip looked like it
            -- "did not reach far enough". The rings are still walked smallest
            -- first, so the smallest shift that works still wins.
            local dirs = ManipDirections(scan)
            local dirCount = #dirs
            local first = math.min(1, limit)
            local step = rings > 1 and (limit - first) / (rings - 1) or 0

            -- Stable per-target start point in the direction list: re-rolled on
            -- a timer, not per call, so repeated shots walk the same order. The
            -- radius order (smallest first) is unchanged, so the shift stays as
            -- small as it can be.
            local spin = manipState.spin[model]
            local spinNow = os.clock()
            if not spin or spinNow - spin.time > manipState.spinTTL then
                spin = { index = math.random(dirCount), time = spinNow }
                manipState.spin[model] = spin
            end
            local start = spin.index

            local exposed, hiddenWall
            local hiddenTries = 0
            local tried = 0
            local hiddenUntil = nil
            for ring = 0, rings - 1 do
                local radius = rings > 1 and first + step * ring or limit
                if radius > 0.05 and radius < delta.Magnitude then
                    for k = 1, dirCount do
                        tried = tried + 1
                        if hiddenUntil and tried > hiddenUntil then break end
                        local i = ((start + k - 2) % dirCount) + 1
                        local offset = dirs[i] * radius
                        local from = origin + offset
                        local hidden = false
                        if hiddenTries < manipState.hiddenTries then
                            hidden = ManipHidden(from, model)
                        end
                        if hidden then
                            -- Hidden spot: the target cannot see it, so their
                            -- aimbot cannot lock. It still has to land - a clear
                            -- line to any body part, or cover we can shoot
                            -- through - and sit in open air. A clear line wins
                            -- outright; a wallbang hidden spot is only kept as a
                            -- fallback, since the server always registers the
                            -- former.
                            hiddenTries = hiddenTries + 1
                            local hitPart, hitPos, clear = ManipLands(from, model)
                            if hitPart and ManipFree(from) then
                                local plan = {
                                    FinalPart = hitPart,
                                    point = hitPos or aim,
                                    offset = offset,
                                    manip = true,
                                    hidden = true,
                                    quality = 1.45 + radius * 0.01,
                                    label = clear
                                        and string.format("Manip: %.1f studs hidden", radius)
                                        or string.format("Manip: %.1f studs hidden/wall", radius),
                                }
                                if clear then return finish(plan) end
                                -- Tier 2: through-cover. Auto mode tracks these
                                -- (see ManipWallResult) so they stop being used
                                -- if the server keeps dropping them.
                                plan.wall = true
                                hiddenWall = hiddenWall or plan
                            end
                        elseif not exposed then
                            -- Exposed but real: keep the first (smallest) clear
                            -- spot as the fallback, but keep looking for a
                            -- hidden one a little further out before settling
                            -- for it (see manipState.hiddenExtra).
                            local hitPart, hitPos = ManipReaches(from, aim, model)
                            if hitPart and ManipFree(from) then
                                exposed = {
                                    FinalPart = hitPart,
                                    point = hitPos or aim,
                                    offset = offset,
                                    manip = true,
                                    quality = 1.45 + radius * 0.01,
                                    label = string.format("Manip: %.1f studs", radius),
                                }
                                hiddenUntil = tried + manipState.hiddenExtra
                            end
                        end
                    end
                    if hiddenUntil and tried >= hiddenUntil then break end
                end
            end
            local plan = hiddenWall or exposed
            if not plan then manipState.miss[model] = os.clock() end
            return finish(plan)
        end

        -- Old helper name, kept so anything that still calls it resolves.
        -- Published to the environment like the script's other bridges, since
        -- its only callers are outside this file.
        function findminoffset(target, origin)
            local plan = ManipPlan(target, origin)
            if plan then return plan.offset, true, plan.FinalPart end
            return nil, false, nil
        end
        do
            local env = (type(getgenv) == "function" and getgenv()) or _G
            env.findminoffset = findminoffset
        end
    --#endregion



    --#region targetting

        -- Draw order, bottom to top: shadow halo -> fill -> outline. Created in
        -- that order so each layer paints over the previous one.
        local FovShadow = Drawing.new("Circle")
        FovShadow.Filled = false
        FovShadow.Color = Color3.fromRGB(0, 0, 0)
        FovShadow.Transparency = 0.5
        FovShadow.Visible = false

        local FovFill = Drawing.new("Circle")
        FovFill.Filled = true
        FovFill.Transparency = 0.85
        FovFill.Visible = false

        local FovCircle = Drawing.new("Circle")

        FovCircle.Radius = 100
        FovCircle.Color = Color3.fromRGB(255, 255, 255)
        FovCircle.Visible = false

        FovFill.Radius = FovCircle.Radius
        FovFill.Color = FovCircle.Color
        FovShadow.Radius = FovCircle.Radius

        -- FOV outline shape. "Sides" draws a regular polygon (3 = triangle,
        -- 6 = hexagon, ... up to 1000 = smooth, where the library Circle takes
        -- over); the star toggle draws a Star of David (two triangles) instead.
        -- Spin rotates the shape continuously, thickness sets the line width,
        -- fill paints the interior, rainbow cycles the colour and shadow lays a
        -- dark, wider halo under the outline so it reads as blurred/darkened.
        local FovShape = {
            Sides = 1000,
            Star = false,
            Spin = 90,            -- degrees/second, positive = CLOCKWISE (0 = static)
            Thickness = 1,
            Fill = false,
            FillTransparency = 0.85,
            Rainbow = false,
            RainbowSpeed = 0.5,   -- colour cycles per second
            Shadow = false,
            ShadowColor = Color3.fromRGB(0, 0, 0),
            ShadowTransparency = 0.5,
        }
        do
            local FOV_SMOOTH_AT = 64
            local lines, tris, shadows = {}, {}, {}
            local angle = 0
            local hue = 0
            -- Tracks the current FOV drawing mode ("off" / "smooth" / "poly").
            -- The polygon shape objects are only hidden on a mode transition
            -- instead of every frame (that was 192 property reads per frame
            -- for nothing).
            local fovMode = "off"

            local function ensureLines(count)
                while #lines < count do
                    local line = Drawing.new("Line")
                    line.Visible = false
                    line.Thickness = 1
                    line.Transparency = 1
                    lines[#lines + 1] = line
                end
            end

            local function ensureTris(count)
                while #tris < count do
                    local tri = Drawing.new("Triangle")
                    tri.Visible = false
                    tri.Transparency = 1
                    tris[#tris + 1] = tri
                end
            end

            local function ensureShadows(count)
                while #shadows < count do
                    local line = Drawing.new("Line")
                    line.Visible = false
                    line.Transparency = 1
                    shadows[#shadows + 1] = line
                end
            end

            local function hideLines()
                for _, line in ipairs(lines) do
                    if line.Visible then line.Visible = false end
                end
            end

            local function hideTris()
                for _, tri in ipairs(tris) do
                    if tri.Visible then tri.Visible = false end
                end
            end

            local function hideShadows()
                for _, line in ipairs(shadows) do
                    if line.Visible then line.Visible = false end
                end
            end

            -- Closed polygons (each a list of Vector2 points) tracing the shape,
            -- rotated by "rot" radians. The star is two triangles, the N-gon is
            -- a single polygon. A non-smooth shape never exceeds 63 points, so
            -- the pools are pre-built here in draw order: shadow (bottom), then
            -- fill triangles, then outline lines (top).
            ensureShadows(64)
            ensureTris(64)
            ensureLines(64)

            local function outline(center, radius, star, rot)
                local polygons = {}
                if star then
                    for _, base in ipairs({ -math.pi / 2, -math.pi / 2 + math.pi / 3 }) do
                        local points = {}
                        for i = 0, 2 do
                            local a = base + rot + i * (math.pi * 2 / 3)
                            points[#points + 1] = center
                                + Vector2.new(math.cos(a), math.sin(a)) * radius
                        end
                        polygons[#polygons + 1] = points
                    end
                    return polygons
                end
                local count = math.clamp(math.floor(FovShape.Sides + 0.5), 3, 1000)
                local points = {}
                for i = 0, count - 1 do
                    local a = -math.pi / 2 + rot + i * (math.pi * 2 / count)
                    points[#points + 1] = center
                        + Vector2.new(math.cos(a), math.sin(a)) * radius
                end
                polygons[#polygons + 1] = points
                return polygons
            end

            local function render(dt)
                local step = math.clamp(dt or 0.016, 0, 0.1)
                angle = (angle + math.rad(FovShape.Spin) * step) % (math.pi * 2)
                hue = (hue + step * FovShape.RainbowSpeed) % 1
                if not FovCircleEnabled then
                    if fovMode ~= "off" then
                        fovMode = "off"
                        FovCircle.Visible = false
                        FovFill.Visible = false
                        FovShadow.Visible = false
                        hideLines()
                        hideTris()
                        hideShadows()
                    end
                    return
                end
                local center = UserInputService:GetMouseLocation()
                local radius = FovCircle.Radius
                local color = FovShape.Rainbow and Color3.fromHSV(hue, 1, 1) or FovCircle.Color
                local fillAlpha = FovShape.Fill and FovShape.FillTransparency or 1
                local thickness = FovShape.Thickness
                FovCircle.Position = center
                FovCircle.Thickness = thickness
                FovCircle.Color = color
                FovFill.Position = center
                FovFill.Radius = radius
                FovFill.Color = color
                FovFill.Transparency = fillAlpha
                FovShadow.Position = center
                FovShadow.Radius = radius
                FovShadow.Thickness = thickness + 3
                FovShadow.Transparency = FovShape.ShadowTransparency
                local smooth = (not FovShape.Star) and FovShape.Sides >= FOV_SMOOTH_AT
                FovCircle.Visible = smooth
                FovFill.Visible = smooth and FovShape.Fill
                FovShadow.Visible = smooth and FovShape.Shadow
                if smooth then
                    if fovMode ~= "smooth" then
                        fovMode = "smooth"
                        hideLines()
                        hideTris()
                        hideShadows()
                    end
                    return
                end
                fovMode = "poly"
                FovFill.Visible = false
                FovShadow.Visible = false
                local polygons = outline(center, radius, FovShape.Star, angle)
                local li, ti, si = 0, 0, 0
                for _, points in ipairs(polygons) do
                    local n = #points
                    for i = 1, n do
                        local a, b = points[i], points[i % n + 1]
                        if FovShape.Shadow then
                            si += 1
                            local shadow = shadows[si]
                            shadow.From = a
                            shadow.To = b
                            shadow.Color = FovShape.ShadowColor
                            shadow.Thickness = thickness + 3
                            shadow.Transparency = FovShape.ShadowTransparency
                            shadow.Visible = true
                        end
                        li += 1
                        local line = lines[li]
                        line.From = a
                        line.To = b
                        line.Color = color
                        line.Thickness = thickness
                        line.Transparency = 1
                        line.Visible = true
                        if FovShape.Fill then
                            ti += 1
                            local tri = tris[ti]
                            tri.PointA = center
                            tri.PointB = a
                            tri.PointC = b
                            tri.Color = color
                            tri.Transparency = fillAlpha
                            tri.Visible = true
                        end
                    end
                end
                for i = li + 1, #lines do lines[i].Visible = false end
                for i = ti + 1, #tris do tris[i].Visible = false end
                for i = si + 1, #shadows do shadows[i].Visible = false end
            end

            local _fovconnection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(render))
        end

        function GetTarget()
            local currentCamera = workspace.CurrentCamera
            if not currentCamera then return nil end
            local mouse = UserInputService:GetMouseLocation()
            local myRoot = LocalPlayer.Character
                and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local maxRange = TargetingRange()
            local bestPart, bestPriority, bestDistance = nil, math.huge, math.huge
            for _, plr in Players:GetPlayers() do
                local priority = CombatPriority(plr)
                local model = plr.Character
                local head = model and model:FindFirstChild("Head")
                local hum = model and model:FindFirstChildOfClass("Humanoid")
                if not priority or not head or not hum or hum.Health <= 0
                    or model:FindFirstChildOfClass("ForceField") then continue end
                -- Past the ESP draw distance (+10): not a target.
                if myRoot and (head.Position - myRoot.Position).Magnitude > maxRange then continue end
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

            -- Smart UG fallback: an angled line whose only obstruction is
            -- terrain (the bullet skims under the map surface). Clear lines,
            -- hitscan and measured wallpen plans always win - this is only
            -- spent when nothing better exists. The shallowest line wins,
            -- because a flatter angle is what lets the bullet travel under the
            -- ground instead of driving straight down into it.
            local bestTerrain
            local function considerTerrain(part, point, origin)
                if not WallPen.TerrainPass then return end
                if typeof(origin) ~= "Vector3" then return end
                local delta = point - origin
                if delta.Magnitude < 0.1 then return end
                local slope = math.abs(delta.Unit.Y)
                if not bestTerrain or slope < bestTerrain.slope then
                    bestTerrain = {part = part, point = point, slope = slope}
                end
            end
            if direct.state == "terrain" then
                considerTerrain(direct.reached or target, target.Position, origin)
            end

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
            -- Smart UG only needs the rest of the rig when the head line already
            -- skims terrain: a lower part gives a shallower under-map angle, and
            -- a wall (not terrain) blocking the head is never bypassed this way.
            local scanBody = HitScanEnabled or HitboxExpander.Enabled or WallPen.Enabled
                or (WallPen.TerrainPass and direct.state == "terrain")
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
                elseif trace.state == "terrain" then
                    considerTerrain(part, point, origin)
                end
            end

            -- 3.5 Origin manipulation: the smallest shift that lands a shot,
            --     preferring spots the target cannot see. Runs before wallpen,
            --     because a clear line from a validated origin beats a claimed
            --     through-wall shot from where we stand.
            if Manip.Enabled then
                local manipPlan = ManipPlan(target, origin)
                if manipPlan then
                    report(manipPlan.label)
                    return manipPlan
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

            -- Smart UG / terrain wallbang: no clear line and no measurable
            -- wallpen was better, so spend the shot on the angled under-map
            -- line - the bullet skims the terrain and still registers.
            if bestTerrain then
                return plan(bestTerrain.part, bestTerrain.point, 1.8,
                    "Smart UG: under map")
            end

            report(direct.state == "blocked" and "Blocked" or "No hit")
            return nil
        end

        -- NOTE: there is deliberately no "blind claim" fallback any more.
        -- The game only registers a shot that has a real line from the pose
        -- the SERVER holds - claiming a part with no line just produced
        -- another invalid, and the misses fed the failsafe until it dropped
        -- UG for nothing. When the server pose cannot see the target, the
        -- callers peek, queue behind a peek, or hold fire instead.

        -- `originOverride` is the head the shot will actually be fired from.
        -- Evaluating from one head and firing from another is what produced
        -- most UG misses (line checked from above ground, bullet sent from
        -- below the floor).
        -- Hoisted out of the call so the ragebot path does not allocate a new
        -- comparator closure every frame.
        local function AimCandidateOrder(a, b)
            if a.priority ~= b.priority then return a.priority < b.priority end
            if math.abs(a.alignment - b.alignment) > 0.01 then
                return a.alignment > b.alignment
            end
            return a.dist < b.dist
        end
        function GetVisibleTarget(Gun, originOverride)
            local LocalCharacter = LocalPlayer.Character
            local LocalHead = LocalCharacter and LocalCharacter:FindFirstChild("Head")
            if not LocalHead then
                return nil
            end

            local origin = originOverride or AARealPartPosition(LocalHead)
            -- Gun range and the ESP-based targeting range, whichever is
            -- shorter, so nobody outside the ESP draw distance (+10) is
            -- ever picked up here either.
            local range = math.min(Gun:GetAttribute("Range") or math.huge, TargetingRange())
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
            table.sort(candidates, AimCandidateOrder)

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
                    -- The tracer is drawn from the namecall choke point below so
                    -- every fired shot gets exactly one.
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

        -- Origin manip, the half that actually registers. The server validates
        -- every shot from the pose it holds for us, so rewriting v[1] alone is
        -- dropped (that was the whole reason the old build moved the server
        -- pose). This shifts ONLY the server-held pose by the manip offset -
        -- never more than the manip distance, in any direction - waits one
        -- network window so the server has it, fires from there, then puts the
        -- pose straight back as soon as the shot is on the wire. The client body
        -- and camera never move, and it is never a teleport to the target.
        local manipBusy = false
        local function FireManipShot(Target, baseHead, plan, count)
            -- Returns true only when this call took ownership and will try to
            -- fire. The ragebot uses that so a manip already in flight does not
            -- burn a round / a fire-rate slot without a shot behind it.
            if manipBusy then return false end
            local env = (type(getgenv) == "function" and getgenv()) or _G
            if type(env.AdvancedAASetOverride) ~= "function" then return false end
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local head = character and character:FindFirstChild("Head")
            local model = Target and Target:FindFirstAncestorOfClass("Model")
            if not (root and head and Target and Target.Parent and model) then return false end

            -- The pose the server will hold once the override lands: the head
            -- goes to baseHead + offset (the offset is never added twice - that
            -- double shift is what the server dropped as invalid). Check NOW,
            -- synchronously, that a shot actually exists from that exact spot:
            -- if it does not there is nothing to wait for, so do not take
            -- ownership and let the caller keep its round / fire-rate slot.
            -- EvaluateShot only reads the origin vector, and the override puts
            -- the head on `spot` to the stud, so this is the same answer the
            -- task would get after the pose has moved.
            local spot = baseHead + plan.offset
            local aimPart = model:FindFirstChild("Head") or Target
            local savedManip = Manip.Enabled
            Manip.Enabled = false
            local okPlan, shotPlan = pcall(EvaluateShot, aimPart, spot)
            Manip.Enabled = savedManip
            if not okPlan or not shotPlan then
                -- The cached spot no longer produces a shot (the target moved,
                -- the cover changed): drop it so the next search re-rolls.
                manipState.cache[model] = nil
                manipState.miss[model] = nil
                manipState.spin[model] = nil
                return false
            end

            manipBusy = true
            task.spawn(function()
                -- Head onto `spot`, root under it, facing the target (same shape
                -- as the old resolver's spot).
                local realRoot = AARealPartPosition(root)
                local realHead = AARealPartPosition(head)
                local rootPos = spot - (realHead - realRoot)
                local look = Vector3.new(Target.Position.X, rootPos.Y, Target.Position.Z)
                local cf = (look - rootPos).Magnitude > 0.1
                    and CFrame.lookAt(rootPos, look) or CFrame.new(rootPos)

                pcall(env.AdvancedAASetOverride, cf)
                local ok, err = pcall(function()
                    -- Let the shifted pose reach the server first, or the shot
                    -- is still validated against the old pose. That mismatch
                    -- was the single biggest source of invalids, so wait for
                    -- the server to actually hold the pose instead of a fixed
                    -- slice of time.
                    local window = math.max(AASyncWindow(), 0.05)
                    local deadline = os.clock() + window + 0.2
                    task.wait(window)
                    while os.clock() < deadline and AAShotState() == "transition" do
                        task.wait()
                    end
                    if not Target.Parent or not head.Parent then return end
                    -- Fire from the EXACT shifted head. The pre-check already
                    -- proved a shot exists there and the override puts the head
                    -- on `spot`, so the origin is `spot` - no second offset.
                    local origin = spot
                    local shots = {}
                    for i = 1, math.max(1, count or 1) do
                        shots[i] = { origin, shotPlan.point, shotPlan.FinalPart }
                    end
                    MarkShots(shots)
                    Remotes.ShootEvent:FireServer(shots)
                    -- Auto tier 2: a through-cover manip only stays enabled while
                    -- it lands. Watch this target's health and feed the result
                    -- back (see ManipWallResult), so a gun that drops wallbangs
                    -- falls back to clear-line spots on its own. A miss while the
                    -- target was clearly moving is not a wallbang rejection, so
                    -- it is ignored instead of counting against tier 2.
                    if plan.wall then
                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local before = humanoid.Health
                            local posBefore = model:GetPivot().Position
                            task.delay(0.35, function()
                                if humanoid.Parent then
                                    if humanoid.Health < before then
                                        ManipWallResult(true)
                                    elseif (model:GetPivot().Position - posBefore).Magnitude <= 3 then
                                        ManipWallResult(false)
                                    end
                                end
                            end)
                        end
                    end
                    -- Restore as soon as the shot is on the wire: it was sent
                    -- before the pose snaps back, so the server validates it
                    -- against the shifted pose. Only a single frame of hold, to
                    -- keep the visible teleport as short as it can be.
                    task.wait()
                end)
                pcall(env.AdvancedAASetOverride, nil)
                if not ok then warn("manip shot:", err) end
                manipBusy = false
            end)
            return true
        end

        -- Fires a silent-aim shot once the server pose has settled (transition
        -- finished or the peek has landed), re-evaluated from that exact pose.
        -- When the pose the server holds cannot see the target it keeps
        -- asking for a peek (waiting out the peek cooldown if needed) and
        -- fires from the real head as soon as the server has it. If the peek
        -- never comes the shot is dropped instead of fired as an invalid.
        local function QueueSilentShot(Args, Target)
            task.spawn(function()
                local queueStart = os.clock()
                local deadline = queueStart + 1.0
                while os.clock() < deadline do
                    local state = AAShotState()
                    if state ~= "transition" then
                        local character = LocalPlayer.Character
                        local head = character and character:FindFirstChild("Head")
                        if not head or not Target or not Target.Parent then return end
                        local origin = (state == "server") and AAServerPartPosition(head)
                            or AARealPartPosition(head)
                        local plan = EvaluateShot(Target, origin)
                        if plan and plan.manip then
                            FireManipShot(Target, origin, plan, #Args[1])
                            return
                        end
                        if plan then
                            origin += plan.offset
                            for _, v in Args[1] do
                                if type(v) == "table" then
                                    v[1] = origin
                                    v[2] = plan.point
                                    v[3] = plan.FinalPart
                                end
                            end
                            if state == "server" then
                                -- Orbiting pose: freeze it for the FULL
                                -- one-way latency so the shot is still
                                -- validated against the exact pose it was
                                -- built from when it reaches the server
                                -- (see AAFreeze).
                                AAFreeze(math.clamp(AASyncWindow(), 0.08, 0.3))
                            else
                                AAPeek(AASyncWindow() + 0.1)
                            end
                            MarkShots(Args[1])
                            Remotes.ShootEvent:FireServer(table.unpack(Args))
                            if state == "server" then
                                local hitModel = plan.FinalPart:FindFirstAncestorOfClass("Model")
                                FailsafeWatch(hitModel and Players:GetPlayerFromCharacter(hitModel))
                            end
                            return
                        end
                        if state == "server" then
                            -- The pose the server holds has no line: ask for a
                            -- peek. AAPeek returns false while peeking is off
                            -- or cooling down - the loop just keeps waiting,
                            -- because firing now would be a guaranteed
                            -- invalid. Square / prism gets a short grace
                            -- window first so a single occluded frame does
                            -- not park the orbit; if the orbit brings a line
                            -- it fires without ever peeking.
                            if not AAIsOrbit() or os.clock() - queueStart >= 0.15 then
                                AAPeek(AASyncWindow() * 2 + 0.15)
                            end
                        else
                            -- Real pose cannot see the target either: drop.
                            return
                        end
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
                            if not plan and EvaluateShot(Target, realOrigin) then
                                -- Underground head has no line but the real
                                -- one does: queue it. QueueSilentShot grabs
                                -- the peek itself (waiting out the cooldown
                                -- if it has to) and fires from the real head
                                -- as soon as the server has it.
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

                        if plan and plan.manip then
                            -- Origin manip plan: the server validates the shot
                            -- from the pose it holds, so move ONLY the server
                            -- pose by the offset and fire from there.
                            FireManipShot(Target, origin, plan, #Args[1])
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
                                -- Orbiting pose: with smooth shots on this
                                -- is a no-op (the orbit keeps running); with
                                -- it off, freeze the pose for the full
                                -- one-way latency so the shot is validated
                                -- against the exact pose it was built from
                                -- (see AAFreeze).
                                AAFreeze(math.clamp(AASyncWindow(), 0.08, 0.3))
                                local hitModel = plan.FinalPart and plan.FinalPart:FindFirstAncestorOfClass("Model")
                                FailsafeWatch(hitModel and Players:GetPlayerFromCharacter(hitModel))
                            end
                        elseif state == "server" then
                            -- No line from the pose the server holds and the
                            -- real head cannot see the target either (or the
                            -- peek is disabled): any origin sent now is
                            -- either wrong (real pose -> invalid) or blocked
                            -- (server pose -> dropped shot), so the shot is
                            -- held instead of firing another invalid. The
                            -- peek / peek resolver makes the target hittable.
                            setnamecallmethod(namecallmethod)
                            return nil
                        end
                    end
                end

                MarkShots(Args[1])

                if ViewModelShot then
                    local point, origin
                    for _, v in ipairs(Args[1]) do
                        if type(v) == 'table' then
                            if typeof(v[2]) == "Vector3" then point = v[2] end
                            if typeof(v[1]) == "Vector3" then origin = v[1] end
                            break
                        end
                    end
                    ViewModelShot(point, origin)
                end

                setnamecallmethod(namecallmethod)

                return mtHook(self, table.unpack(Args, 1, select("#", ...)))
            end
            if rawequal(self, Remotes.ShootEvent) and namecallmethod == "FireServer" and type((...)) == 'table' then
                local Shots = (...)
                MarkShots(Shots)
                if ViewModelShot then
                    local point, origin
                    for _, v in ipairs(Shots) do
                        if type(v) == 'table' then
                            if typeof(v[2]) == "Vector3" then point = v[2] end
                            if typeof(v[1]) == "Vector3" then origin = v[1] end
                            break
                        end
                    end
                    ViewModelShot(point, origin)
                end
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
                        -- Underground head has no line. If the real head
                        -- does, peek: the next shots come from the real pose
                        -- once the server has it, then UG returns. When the
                        -- peek is unavailable (off / cooling down) fire is
                        -- HELD for this tick - shooting from the underground
                        -- pose is a guaranteed invalid, and the miss streak
                        -- would trip the failsafe and drop UG for nothing.
                        local realHead = AARealPartPosition(LocalHead)
                        if GetVisibleTarget(Gun, realHead)
                            and (not AAIsOrbit() or os.clock() - LastShot > 0.15) then
                            AAPeek(AASyncWindow() * 2 + 0.15)
                        end
                        continue
                    end
                    -- Orbiting pose: with smooth shots on this is a no-op
                    -- (the orbit keeps running); with it off, freeze it at
                    -- this point while the shot is in flight so the server
                    -- validates the exact origin it was built from (see
                    -- AAFreeze).
                    AAFreeze(math.clamp(AASyncWindow(), 0.08, 0.3))
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
                if t.manip then
                    -- Origin manip plan: move only the server pose by the
                    -- offset and fire from there (see FireManipShot). Only
                    -- spend the round / fire-rate slot when it actually
                    -- launched - a manip already in flight returns false.
                    if FireManipShot(FinalPart, origin, t, Gun:GetAttribute("ProjectileCount") or 1) then
                        LastShot = os.clock()
                        Gun:SetAttribute("Local_CurrentAmmo", Ammo - 1)
                    end
                    continue
                end
                origin = origin + t.offset
                local Shots = {}

                for i = 1, Gun:GetAttribute("ProjectileCount") or 1 do
                    Shots[i] = { origin, t.point, FinalPart }
                end

                LastShot = os.clock()

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

        -- The police taser reports ToolType == "Gun" in some Prison Life builds
        -- even though it is a utility. It must never be cycled to (or treated
        -- as the gun that starts a cycle), so name matching is the reliable
        -- filter here.
        local function SwitchableGun(tool)
            if not tool or not tool:IsA("Tool") then return false end
            if tool:GetAttribute("ToolType") ~= "Gun" then return false end
            local name = string.lower(tool.Name)
            return not (string.find(name, "taser", 1, true)
                or string.find(name, "taze", 1, true))
        end

        -- Auto weapon switcher: cycles through the guns you carry so every gun
        -- gets refreshed instead of one gun being re-equipped forever. The
        -- 0.2s cadence is deliberately fixed (no slider): it is fast enough to
        -- refresh a shotgun between pumps and slow enough that the equip noise
        -- does not turn into a strobe. Only ToolType == "Gun" tools are
        -- touched, the taser is skipped, it only acts while a gun is already
        -- equipped, and it needs at least two guns in the rig, so keys, melee
        -- and the taser stay where they are.
        task.spawn(function()
            local lastSwitch = 0
            while true do
                task.wait(0.05)
                if not AutoWeaponSwitch then continue end
                local now = os.clock()
                if now - lastSwitch < 0.2 then continue end
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local equipped = char and char:FindFirstChildOfClass("Tool")
                if not (hum and equipped and SwitchableGun(equipped)) then
                    continue
                end
                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                local names = {}
                for _, container in ipairs({ char, backpack }) do
                    if container then
                        for _, tool in ipairs(container:GetChildren()) do
                            if SwitchableGun(tool) then
                                table.insert(names, tool.Name)
                            end
                        end
                    end
                end
                if #names < 2 then continue end
                table.sort(names)
                local index = 1
                for i, name in ipairs(names) do
                    if name == equipped.Name then
                        index = i
                        break
                    end
                end
                local nextName = names[(index % #names) + 1]
                local nextTool = char:FindFirstChild(nextName)
                    or (backpack and backpack:FindFirstChild(nextName))
                if nextTool and nextTool ~= equipped then
                    hum:EquipTool(nextTool)
                    lastSwitch = now
                end
            end
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

        -- Polygon sides: 3 = triangle ... 1000 = smooth. Values at/above 64
        -- are drawn as the smooth circle (a 64-gon already looks round), so the
        -- top of the slider is just "smooth".
        Sections.aimbot:Slider({
            Name = 'fov sides (3 = triangle, 1000 = smooth)';
            Flag = 'fovsides';
            Default = 1000;
            Max = 1000;
            Min = 3;
            Decimals = 0;
            Callback = function(v)
                FovShape.Sides = v;
            end 
        })

        Sections.aimbot:Toggle({
            Name = 'star of david fov';
            Flag = 'fovstar';
            Default = false;
            Callback = function(v)
                FovShape.Star = v;
            end 
        })

        Sections.aimbot:Slider({
            Name = 'fov spin (deg/s clockwise, 0 = off)';
            Flag = 'fovspin';
            Default = 90;
            Max = 720;
            Min = 0;
            Decimals = 0;
            Callback = function(v)
                FovShape.Spin = v;
            end 
        })

        Sections.aimbot:Slider({
            Name = 'fov thickness';
            Flag = 'fovthickness';
            Default = 1;
            Max = 10;
            Min = 1;
            Decimals = 0;
            Callback = function(v)
                FovShape.Thickness = v;
            end 
        })

        Sections.aimbot:Toggle({
            Name = 'fov fill';
            Flag = 'fovfill';
            Default = false;
            Callback = function(v)
                FovShape.Fill = v;
            end 
        })

        Sections.aimbot:Slider({
            Name = 'fov fill transparency';
            Flag = 'fovfilltransparency';
            Default = 0.85;
            Max = 1;
            Min = 0;
            Decimals = 0.05;
            Callback = function(v)
                FovShape.FillTransparency = v;
            end 
        })

        Sections.aimbot:Toggle({
            Name = 'fov rainbow';
            Flag = 'fovrainbow';
            Default = false;
            Callback = function(v)
                FovShape.Rainbow = v;
            end 
        })

        Sections.aimbot:Slider({
            Name = 'fov rainbow speed';
            Flag = 'fovrainbowspeed';
            Default = 0.5;
            Max = 3;
            Min = 0.05;
            Decimals = 0.05;
            Callback = function(v)
                FovShape.RainbowSpeed = v;
            end 
        })

        Sections.aimbot:Toggle({
            Name = 'fov shadow';
            Flag = 'fovshadow';
            Default = false;
            Callback = function(v)
                FovShape.Shadow = v;
            end 
        })

        Sections.aimbot:Slider({
            Name = 'fov shadow transparency';
            Flag = 'fovshadowtransparency';
            Default = 0.5;
            Max = 1;
            Min = 0;
            Decimals = 0.05;
            Callback = function(v)
                FovShape.ShadowTransparency = v;
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
        
        -- Origin manip: fires from the smallest offset around your own head that
        -- can land on the target, preferring spots the target cannot see so
        -- their aimbot cannot lock on. Only the server-held pose moves -
        -- invisibly, by at most the manip distance, in any direction - and it is
        -- put straight back; your client body, camera and physics never move.
        Sections.aimbot:Toggle({
            Name = 'origin manip';
            Flag = 'manip';
            Default = false;
            Callback = function(v)
                Manip.Enabled = v;
            end
        })

        Sections.aimbot:Slider({
            Name = 'manip dist (studs)';
            Flag = 'manipdist';
            Min = 0;
            Max = 20;
            Default = 20;
            Decimals = 0.5;
            Callback = function(v)
                Manip.Max = v;
            end
        })

        Sections.aimbot:Slider({
            Name = 'manip scan count';
            Flag = 'manipscancount';
            Min = 4;
            Max = 48;
            Default = 12;
            Decimals = 1;
            Callback = function(v)
                Manip.Scan = math.floor(v);
            end
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
        -- Vehicle wallbang: cars stop counting as cover, so the aim can shoot
        -- straight through them at whoever is behind or inside. Works with
        -- wallpen off (the line simply reads as clear).
        Sections.aimbot:Toggle({
            Name = "vehicle wallbang (shoot thru cars)"; Flag = "vehiclewallbang"; Default = false;
            Callback = function(v)
                WallPen.VehicleWallbang = v;
                table.clear(WallPen.Cache);
            end;
        })
        -- One slider owns the whole penetration budget: it scales the wall
        -- thickness and the layer count together, so the layer limit can never
        -- sit above what the thickness limit allows.
        --    25%  = 5.00 studs / 2 layers   (default)
        --    100% = 20.0 studs / 8 layers
        Sections.aimbot:Slider({
            Name = "wallpen max (walls + layers)"; Flag = "wallpen_max";
            Min = 1; Max = 100; Default = 25; Decimals = 1;
            Callback = function(v) WallPen.ApplyBudget(v) end;
        })
        Sections.aimbot:Toggle({
            Name = "wallpen hit marker"; Flag = "wallpen_marker"; Default = true;
            Callback = function(v) WallPen.ShowMarker = v end;
        })
        -- Smart UG / terrain wallbang: this game's bullets skim UNDER the map
        -- surface on angled lines, so terrain is not real cover. With this on,
        -- the aim will spend a shot on an angled under-map line when no clear
        -- line, hitscan or measurable wallpen plan exists. Steep (near
        -- vertical) terrain lines stay blocked, and the failsafe backoff still
        -- quiets repeated terrain attempts.
        Sections.aimbot:Toggle({
            Name = "smart UG (terrain wallbang)"; Flag = "smartug"; Default = true;
            Callback = function(v)
                WallPen.TerrainPass = v;
                table.clear(WallPen.Cache);
            end
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

        do -- player filter
            local function PlayerNameList()
                local names = {}
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then names[#names + 1] = plr.Name end
                end
                table.sort(names)
                return names
            end

            -- Whitelist: never aimed at by anything, ESP still draws them.
            -- Blacklist: forced top priority, everyone else stays available
            -- as a fallback when they are dead / gone.
            local whitelistDrop = Sections.aimbot:Dropdown({
                Name = 'whitelist (never aim)';
                Flag = 'playerwhitelist';
                Items = PlayerNameList();
                Multi = true;
                Default = {};
                Callback = function(v)
                    table.clear(WhitelistedPlayers)
                    for _, name in ipairs(v) do WhitelistedPlayers[name] = true end
                end;
            })
            local blacklistDrop = Sections.aimbot:Dropdown({
                Name = 'blacklist (priority)';
                Flag = 'playerblacklist';
                Items = PlayerNameList();
                Multi = true;
                Default = {};
                Callback = function(v)
                    table.clear(BlacklistedPlayers)
                    for _, name in ipairs(v) do BlacklistedPlayers[name] = true end
                end;
            })

            -- Team whitelists: pick which teams the aim and the ESP are
            -- allowed to see. Multi-select and empty = every team, so
            -- leaving them untouched changes nothing. The labels are the
            -- game's team names; TEAM_WHITELIST_ROLES maps them onto the
            -- internal roles used by TeamRole().
            Sections.aimbot:Dropdown({
                Name = 'aim team whitelist (empty = all)';
                Flag = 'aimteamwhitelist';
                Items = TEAM_WHITELIST_ITEMS;
                Multi = true;
                Default = {};
                Callback = function(v)
                    table.clear(AimTeamWhitelist)
                    for _, label in ipairs(v) do
                        local role = TEAM_WHITELIST_ROLES[label]
                        if role then AimTeamWhitelist[role] = true end
                    end
                end;
            })
            Sections.aimbot:Dropdown({
                Name = 'esp team whitelist (empty = all)';
                Flag = 'espteamwhitelist';
                Items = TEAM_WHITELIST_ITEMS;
                Multi = true;
                Default = {};
                Callback = function(v)
                    table.clear(ESPTeamWhitelist)
                    for _, label in ipairs(v) do
                        local role = TEAM_WHITELIST_ROLES[label]
                        if role then ESPTeamWhitelist[role] = true end
                    end
                end;
            })

            local function RefreshPlayerLists()
                whitelistDrop:Refresh(PlayerNameList())
                blacklistDrop:Refresh(PlayerNameList())
            end
            Players.PlayerAdded:Connect(RefreshPlayerLists)
            Players.PlayerRemoving:Connect(function()
                task.defer(RefreshPlayerLists)
            end)
        end


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

        -- Fixed 0.2s cycle through the guns you carry so each one refreshes.
        -- No interval slider on purpose.
        Sections.gunmods:Toggle({
            Name = 'auto weapon switcher (0.2s)';
            Flag = 'autoweaponswitch';
            Default = false;
            Callback = function(v)
                AutoWeaponSwitch = v;
            end
        })


    --#endregion

    --#region snap line
    -- A line from the crosshair to whatever the aim is currently locked on to,
    -- so the snap is visible before the shot lands. One reused Drawing line,
    -- updated in the render step; nothing is allocated per frame.
    do
        local SnapLine = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1.5,
            Transparency = 1,
        }

        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = SnapLine.Thickness
        line.Transparency = SnapLine.Transparency
        line.Color = SnapLine.Color

        RunService.RenderStepped:Connect(function()
            if not SnapLine.Enabled then
                if line.Visible then line.Visible = false end
                return
            end
            local camera = workspace.CurrentCamera
            local target = camera and GetTarget() or nil
            if not target or not target.Parent then
                if line.Visible then line.Visible = false end
                return
            end
            local point, onScreen = camera:WorldToViewportPoint(target.Position)
            if not onScreen or point.Z <= 0 then
                if line.Visible then line.Visible = false end
                return
            end
            -- Start from the gun barrel when the custom view model is drawing,
            -- so the line comes out of the muzzle instead of the crosshair.
            local from = UserInputService:GetMouseLocation()
            local muzzle = ViewModelMuzzle and ViewModelMuzzle()
            if muzzle then
                local mpoint, mOnScreen = camera:WorldToViewportPoint(muzzle.Position)
                if mOnScreen and mpoint.Z > 0 then
                    from = Vector2.new(mpoint.X, mpoint.Y)
                end
            end
            line.From = from
            line.To = Vector2.new(point.X, point.Y)
            line.Color = SnapLine.Color
            line.Thickness = SnapLine.Thickness
            line.Transparency = SnapLine.Transparency
            line.Visible = true
        end)

        Sections.visuals:Toggle({
            Name = 'snap line';
            Flag = 'snapline';
            Default = false;
            Callback = function(v) SnapLine.Enabled = v end
        })

        Sections.visuals:Label({Name = 'snap line color'}):Colorpicker({
            Name = 'snap line color';
            Flag = 'snaplinecolor';
            Default = SnapLine.Color;
            Callback = function(v) SnapLine.Color = v end
        })

        Sections.visuals:Slider({
            Name = 'snap line thickness';
            Flag = 'snaplinethickness';
            Min = 0.5; Max = 6; Default = 1.5; Decimals = 0.5;
            Callback = function(v) SnapLine.Thickness = v end
        })
    end
    --#endregion

    --#region tracker
    -- A crosshair that rides the aim target: the same lock the snap line uses,
    -- but instead of a line from the crosshair it draws the crosshair itself on
    -- the target's head, eased into place so it glides rather than snaps. Every
    -- shape is a list of unit-space segments drawn with one reused Line each, so
    -- nothing is allocated per frame.
    do
        local Tracker = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1.5,
            Size = 12,
            Shape = "Crosshair",   -- Crosshair | Star of David | Polygon
            Sides = 6,             -- points for the star / polygon
            Smooth = 0.5,          -- 0 = instant, 1 = very smooth
            X = 0,
            Y = 0,
            Has = false,           -- whether the smoothed point has been seeded
        }

        local MAX_SEGMENTS = 16
        local segs = {}
        for i = 1, MAX_SEGMENTS do
            local l = Drawing.new("Line")
            l.Visible = false
            segs[i] = l
        end

        local function ringPoints(n)
            local pts = {}
            for k = 0, n - 1 do
                local a = math.rad(90 + k * 360 / n)
                pts[k + 1] = Vector2.new(math.cos(a), -math.sin(a))
            end
            return pts
        end

        local function buildSegments()
            local list = {}
            local shape = Tracker.Shape
            if shape == "Star of David" then
                -- A star polygon: jump s points around the ring each time. At the
                -- default 6 points this is the Star of David (two triangles); at
                -- 5 it is a pentagram, and so on.
                local n = math.max(3, math.floor(Tracker.Sides + 0.5))
                local s = (n % 2 == 1) and ((n - 1) / 2) or (n / 2 - 1)
                s = math.max(1, math.floor(s))
                local pts = ringPoints(n)
                for k = 1, n do
                    list[#list + 1] = { pts[k], pts[(k - 1 + s) % n + 1] }
                end
            elseif shape == "Polygon" then
                local n = math.max(3, math.floor(Tracker.Sides + 0.5))
                local pts = ringPoints(n)
                for k = 1, n do
                    list[#list + 1] = { pts[k], pts[k % n + 1] }
                end
            else
                -- Plain crosshair: four ticks with a gap at the centre.
                local gap, len = 0.35, 1
                list[#list + 1] = { Vector2.new(0, -gap), Vector2.new(0, -len) }
                list[#list + 1] = { Vector2.new(0, gap), Vector2.new(0, len) }
                list[#list + 1] = { Vector2.new(-gap, 0), Vector2.new(-len, 0) }
                list[#list + 1] = { Vector2.new(gap, 0), Vector2.new(len, 0) }
            end
            return list
        end

        local segments = buildSegments()
        local dirty = false

        local function hideAll()
            if Tracker.Has then
                for _, l in ipairs(segs) do
                    if l.Visible then l.Visible = false end
                end
                Tracker.Has = false
            end
        end

        RunService.RenderStepped:Connect(function(dt)
            if not Tracker.Enabled then
                hideAll()
                return
            end
            if dirty then
                segments = buildSegments()
                dirty = false
            end
            local camera = workspace.CurrentCamera
            local target = camera and GetTarget() or nil
            if not target or not target.Parent then
                hideAll()
                return
            end
            local point, onScreen = camera:WorldToViewportPoint(target.Position)
            if not onScreen or point.Z <= 0 then
                hideAll()
                return
            end

            local tx, ty = point.X, point.Y
            if not Tracker.Has then
                Tracker.X, Tracker.Y, Tracker.Has = tx, ty, true
            else
                -- Frame-rate independent ease. Smooth = 0 snaps; the top of the
                -- slider gives a slow, very smooth glide.
                local tau = math.max(Tracker.Smooth * 0.2, 0.0001)
                local k = 1 - math.exp(-(dt or 0.016) / tau)
                Tracker.X += (tx - Tracker.X) * k
                Tracker.Y += (ty - Tracker.Y) * k
            end

            local cx, cy = Tracker.X, Tracker.Y
            local size = Tracker.Size
            for i = 1, MAX_SEGMENTS do
                local l = segs[i]
                local seg = segments[i]
                if seg then
                    l.From = Vector2.new(cx + seg[1].X * size, cy + seg[1].Y * size)
                    l.To = Vector2.new(cx + seg[2].X * size, cy + seg[2].Y * size)
                    l.Color = Tracker.Color
                    l.Thickness = Tracker.Thickness
                    l.Transparency = 1
                    l.Visible = true
                elseif l.Visible then
                    l.Visible = false
                end
            end
        end)

        Sections.visuals:Toggle({
            Name = 'tracker';
            Flag = 'tracker';
            Default = false;
            Callback = function(v) Tracker.Enabled = v end
        })

        Sections.visuals:Dropdown({
            Name = 'tracker shape';
            Flag = 'trackershape';
            Items = { "Crosshair", "Star of David", "Polygon" };
            Default = "Crosshair";
            Callback = function(v) Tracker.Shape = v; dirty = true end
        })

        Sections.visuals:Slider({
            Name = 'tracker sides';
            Flag = 'trackersides';
            Min = 3; Max = 12; Default = 6; Decimals = 1;
            Callback = function(v) Tracker.Sides = v; dirty = true end
        })

        Sections.visuals:Slider({
            Name = 'tracker size';
            Flag = 'trackersize';
            Min = 2; Max = 60; Default = 12; Decimals = 1;
            Callback = function(v) Tracker.Size = v end
        })

        Sections.visuals:Slider({
            Name = 'tracker smoothing';
            Flag = 'trackersmooth';
            Min = 0; Max = 1; Default = 0.5; Decimals = 0.05;
            Callback = function(v) Tracker.Smooth = v end
        })

        Sections.visuals:Label({Name = 'tracker color'}):Colorpicker({
            Name = 'tracker color';
            Flag = 'trackercolor';
            Default = Tracker.Color;
            Callback = function(v) Tracker.Color = v end
        })

        Sections.visuals:Slider({
            Name = 'tracker thickness';
            Flag = 'trackerthickness';
            Min = 0.5; Max = 6; Default = 1.5; Decimals = 0.5;
            Callback = function(v) Tracker.Thickness = v end
        })
    end
    --#endregion
end 


-- Scoped so the ESP region's locals do not stay live for the whole main
-- chunk; the executor compiles with no optimisation and caps active locals.
do -- esp module

-- Apply shared policy after the external ESP library has positioned its holders.
-- This now also runs when "team priority" is off but an ESP team whitelist is
-- set, because the team filter has to work independently of the priority
-- toggle. Entries are hidden by us (and their library visibility restored
-- when they become allowed again) instead of being permanently muted.
local espFilterHidden = setmetatable({}, { __mode = "k" })
-- The allow/deny decision is policy, not geometry: it only changes when the
-- user edits the lists / teams change, so it is resolved at ~10Hz per player
-- instead of every frame. Visibility itself is still applied every frame,
-- because the library re-shows its holders each frame and a throttled apply
-- would flicker.
local espFilterAllowed = setmetatable({}, { __mode = "k" })
local espFilterCheckedAt = setmetatable({}, { __mode = "k" })
local ESP_FILTER_INTERVAL = 0.1
RunService:BindToRenderStep("PriorityESPFilter", Enum.RenderPriority.Camera.Value + 2, function()
    if not EspLib.Cache then return end
    local filterActive = PriorityTeamCheck or next(ESPTeamWhitelist) ~= nil
    if not filterActive then return end
    local now = os.clock()
    for plr, entry in pairs(EspLib.Cache) do
        -- Team whitelist first (it restricts even name-whitelisted players),
        -- then the normal priority/team policy and the name whitelist.
        local checked = espFilterCheckedAt[plr]
        if not checked or now - checked >= ESP_FILTER_INTERVAL then
            espFilterCheckedAt[plr] = now
            espFilterAllowed[plr] = TeamWhitelistAllows(ESPTeamWhitelist, plr)
                and (WhitelistedPlayers[plr.Name] or not PriorityTeamCheck or TargetPriority(plr) ~= nil)
        end
        if not espFilterAllowed[plr] then
            if espFilterHidden[plr] == nil then espFilterHidden[plr] = entry.Visible end
            if entry.Holder then entry.Holder.Visible = false end
            entry.Visible = false
        elseif espFilterHidden[plr] ~= nil then
            -- Allowed again: hand the library its own visibility state back.
            local was = espFilterHidden[plr]
            espFilterHidden[plr] = nil
            local tableEnabled = type(EspLib.Table) == "table" and EspLib.Table.Enabled
            if tableEnabled then
                entry.Visible = was
                if entry.Holder then entry.Holder.Visible = was end
            end
        end
    end
    -- Drop saved states for players the library no longer tracks.
    for plr in pairs(espFilterHidden) do
        if not EspLib.Cache[plr] then espFilterHidden[plr] = nil end
    end
    for plr in pairs(espFilterAllowed) do
        if not EspLib.Cache[plr] then
            espFilterAllowed[plr] = nil
            espFilterCheckedAt[plr] = nil
        end
    end
end)

-- ESP presentation. The library scales its box with distance (Factor / depth),
-- so a player standing next to you fills the screen with a giant rectangle.
-- This caps every box at a fixed maximum pixel size and re-centres it on the
-- same screen point, then paints priority / blacklisted players a solid
-- highlight colour (everyone else keeps the library's own gradient). It runs
-- after the library's own render step (Camera + 1) and after PriorityESPFilter
-- (Camera + 2), so it wins each frame and skips entries the filter hid.
local espSizeCap = 80
local espHighlight = true
local espPriorityColor = Color3.fromRGB(255, 200, 60)
local espBlacklistColor = Color3.fromRGB(255, 70, 70)

-- The two highlight colours are fixed per selection, so their solid sequences
-- are built once and reused. Without this the render step allocated a fresh
-- ColorSequence for every highlighted player every frame (pure GC churn).
local function NewSeqCache() return { color = nil, seq = nil } end
local espPrioritySeqCache = NewSeqCache()
local espBlacklistSeqCache = NewSeqCache()
local function CachedSolidSeq(cache, color)
    if cache.seq and cache.color == color then return cache.seq end
    cache.color, cache.seq = color, ColorSequence.new(color)
    return cache.seq
end

-- The library's own gradient only changes when the user edits the box / fill
-- colours, so its built sequences are cached and rebuilt on a key change.
local espBoxSeqCache = { bot = false, top = false, seq = nil }
local espFillSeqCache = { bot = false, top = false, seq = nil }
local function ESPDefaultBoxColor()
    local box = EspLib.Table.Boxes.Box
    local c = espBoxSeqCache
    if c.seq and c.bot == box.Bot and c.top == box.Top then return c.seq end
    c.bot, c.top, c.seq = box.Bot, box.Top, ColorSequence.new(box.Bot, box.Top)
    return c.seq
end
local function ESPDefaultFillColor()
    local fill = EspLib.Table.Boxes.Fill
    local c = espFillSeqCache
    if c.seq and c.bot == fill.Bot and c.top == fill.Top then return c.seq end
    c.bot, c.top, c.seq = fill.Bot, fill.Top, ColorSequence.new(fill.Bot, fill.Top)
    return c.seq
end
-- nil = leave the library colour alone; otherwise the solid sequence to paint.
local function ESPHighlightSeq(plr)
    if not espHighlight or plr == LocalPlayer then return nil end
    if BlacklistedPlayers[plr.Name] then return CachedSolidSeq(espBlacklistSeqCache, espBlacklistColor) end
    if PriorityTeamCheck and TargetPriority(plr) ~= nil then return CachedSolidSeq(espPrioritySeqCache, espPriorityColor) end
    return nil
end

-- Which colour applies is policy (priority / blacklist), so it is decided at
-- ~10Hz per player and cached on the entry; the cached sequence is re-asserted
-- every frame only when the live gradient actually differs (the library resets
-- it on a settings change). This keeps TargetPriority and ColorSequence off
-- the per-frame path.
local ESP_RECOLOR_INTERVAL = 0.1
local espRecolorAt = setmetatable({}, { __mode = "k" })

RunService:BindToRenderStep("ESPOverlay", Enum.RenderPriority.Camera.Value + 3, function()
    local cache = EspLib.Cache
    if not cache then return end
    local now = os.clock()
    for plr, entry in pairs(cache) do
        if entry.Visible and entry.Holder then
            local h, w = entry.Height, entry.Width
            if h and w and h > espSizeCap and w > 0 then
                local cw = math.max(math.floor(w * (espSizeCap / h) + 0.5), 1)
                local cx, cy = entry.X + w * 0.5, entry.Y + h * 0.5
                entry.Holder.Size = UDim2.fromOffset(cw, espSizeCap)
                entry.Holder.Position = UDim2.fromOffset(
                    math.floor(cx - cw * 0.5 + 0.5),
                    math.floor(cy - espSizeCap * 0.5 + 0.5))
            end
            local checked = espRecolorAt[plr]
            if not checked or now - checked >= ESP_RECOLOR_INTERVAL then
                espRecolorAt[plr] = now
                entry.EspSeq = ESPHighlightSeq(plr)
            end
            local seq = entry.EspSeq
            if seq then
                if entry.BoxGradient.Color ~= seq then
                    entry.BoxGradient.Color = seq
                    entry.FillGradient.Color = seq
                end
                entry.EspRecolored = true
            elseif entry.EspRecolored then
                entry.BoxGradient.Color = ESPDefaultBoxColor()
                entry.FillGradient.Color = ESPDefaultFillColor()
                entry.EspRecolored = false
            end
        end
    end
    -- Drop saved timers for players the library no longer tracks.
    for plr in pairs(espRecolorAt) do
        if not cache[plr] then espRecolorAt[plr] = nil end
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
                Name = 'mid';
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

    -- Keep the on-screen box small and readable: boxes are capped at this
    -- pixel height (the width follows the library's own aspect ratio).
    Sections.Esp:Slider({
        Name = 'max box size (px)';
        Flag = 'espmaxboxsize';
        Min = 20;
        Max = 300;
        Default = 80;
        Decimals = 0;
        Callback = function(v) espSizeCap = v end
    })

    Sections.Esp:Toggle({
        Name = 'highlight priority / blacklist';
        Flag = 'esphighlight';
        Default = true;
        Callback = function(v) espHighlight = v end
    })

    Sections.Esp:Label({Name = 'priority color'}):Colorpicker({
        Name = 'priority color';
        Flag = 'espprioritycolor';
        Default = espPriorityColor;
        Callback = function(v) espPriorityColor = v end
    })

    Sections.Esp:Label({Name = 'blacklist color'}):Colorpicker({
        Name = 'blacklist color';
        Flag = 'espblacklistcolor';
        Default = espBlacklistColor;
        Callback = function(v) espBlacklistColor = v end
    })
end
end -- esp module


-- ==========================================
-- LATENCY GHOST | VISUALS TAB
-- ==========================================

do -- ghost module (scoped: frees main-chunk locals)
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

    -- GHOST_SETTINGS.Transparency is the see-through base the ghost always
    -- keeps; the fade only pushes it further toward invisible. This used to be
    -- ignored (the parts kept the cloned opacity, i.e. solid), which is why the
    -- ghost looked like a plain opaque block.
    local base = GHOST_SETTINGS.Transparency
    for _, object in ipairs(Ghost:GetDescendants()) do
        if object:IsA("BasePart") then
            object.Transparency = base + (1 - base) * GhostFade
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

-- The ghost is a client-only, purely visual shell. A dedicated collision group
-- (when the executor is allowed to register one) keeps it out of every collision
-- pair so it can never block the player or a vehicle.
local GhostCollisionGroup
pcall(function()
    local PhysicsService = game:GetService("PhysicsService")
    PhysicsService:RegisterCollisionGroup("NegrohaxGhost")
    PhysicsService:CollisionGroupSetCollidable("NegrohaxGhost", "Default", false)
    GhostCollisionGroup = "NegrohaxGhost"
end)

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

        elseif object:IsA("JointInstance") or object:IsA("WeldConstraint") then
            -- Drop every joint so the clone can never be welded to something
            -- outside itself (a vehicle seat, for example). The parts keep their
            -- cloned pose and PivotTo moves them as a rigid group.
            object:Destroy()

        elseif object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
            object.Massless = true
            if GhostCollisionGroup then
                pcall(function() object.CollisionGroup = GhostCollisionGroup end)
            end
        end
    end

    -- Strip the Humanoid: without it the ghost is pure geometry, so the game's
    -- seats and physics cannot seat, weld or otherwise interact with it. This is
    -- what used to let a vehicle seat latch onto the ghost and stop the car dead.
    local humanoid = clone:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid:Destroy()
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
    -- Created on the client and parented to workspace: local instances are not
    -- replicated, so other players never receive this clone (it cannot reveal
    -- your position to them).
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

local ghostPingSampleAt = 0
local function GhostGetPing()
    -- Only the smoothed average is used downstream, and the ping itself moves
    -- slowly, so the pcall + GetNetworkPing is sampled a few times a second
    -- instead of on every render frame.
    local t = os.clock()
    if t - ghostPingSampleAt >= 0.25 then
        ghostPingSampleAt = t
        local success, ping = pcall(function()
            return LocalPlayer:GetNetworkPing()
        end)

        if success and type(ping) == "number" then
            GhostAveragePing =
                GhostAveragePing == 0
                and ping
                or GhostAveragePing + (ping - GhostAveragePing) * 0.12
        end
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
    local root = character and character:FindFirstChild("HumanoidRootPart")

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
end -- ghost module


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

do -- advanced team check (scoped: frees main-chunk locals)
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
end -- advanced team check


-- ==========================================
-- MOVEMENT RESOLVER / PLAYER MONITOR
-- VISUALS TAB
-- ==========================================

do -- movement resolver (scoped: frees main-chunk locals)
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
end -- movement resolver
    

    
    
    
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
do -- tool chams module (scoped: frees main-chunk locals)
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
end -- tool chams module


    --#region toggles

-- ==========================================
-- CHAMS | VISUALS TAB
-- ==========================================

local ChamsPlayers = game:GetService("Players")
local ChamsLocalPlayer = ChamsPlayers.LocalPlayer

local ChamsEnabled = false
local ChamsHighlights = {}

-- Colour / transparency are user configurable on the visuals tab, never
-- hardcoded, so every highlight updates live when the values change.
-- Default red, kept distinct from the self chams default (pink) so the two
-- systems never look like the same effect.
local ChamsStyle = {
    Color = Color3.fromRGB(255, 0, 0),
    FillTransparency = 0.45,
    OutlineTransparency = 0.2,
}

local function ChamsPaint(highlight)
    highlight.FillColor = ChamsStyle.Color
    highlight.OutlineColor = ChamsStyle.Color
    highlight.FillTransparency = ChamsStyle.FillTransparency
    highlight.OutlineTransparency = ChamsStyle.OutlineTransparency
end

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

    ChamsPaint(highlight)

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
    Name = "chams (other players)",
    Flag = "chams",
    Default = false,

    Callback = function(value)
        SetChams(value)
    end
})

Sections.visuals:Label({Name = "chams color"}):Colorpicker({
    Name = "chams color";
    Flag = "chamscolor";
    Default = ChamsStyle.Color;
    Callback = function(v)
        ChamsStyle.Color = v
        for _, highlight in pairs(ChamsHighlights) do
            if highlight.Parent then ChamsPaint(highlight) end
        end
    end
})

Sections.visuals:Slider({
    Name = "chams transparency";
    Flag = "chamstransparency";
    Min = 0; Max = 1; Default = ChamsStyle.FillTransparency; Decimals = 0.05;
    Callback = function(v)
        ChamsStyle.FillTransparency = v
        ChamsStyle.OutlineTransparency = math.clamp(v - 0.25, 0, 1)
        for _, highlight in pairs(ChamsHighlights) do
            if highlight.Parent then ChamsPaint(highlight) end
        end
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

        --#region time changer

            -- Locks the client clock so you can force day or night. Re-asserted every
            -- frame because the game's own day / night cycle keeps writing ClockTime
            -- from the server. Purely local: Lighting changes never replicate.
            do
                local TimeChangerEnabled = false
                local TimeChangerValue = 12

                RunService.RenderStepped:Connect(function()
                    if not TimeChangerEnabled then return end
                    if Lighting.ClockTime ~= TimeChangerValue then
                        Lighting.ClockTime = TimeChangerValue
                    end
                end)

                Sections.visuals:Toggle({
                    Name = 'time changer';
                    Flag = 'timechanger';
                    Default = false;
                    Callback = function(v)
                        TimeChangerEnabled = v;
                        if v then Lighting.ClockTime = TimeChangerValue end;
                    end
                })

                Sections.visuals:Slider({
                    Name = 'time of day';
                    Flag = 'timeofday';
                    Min = 0;
                    Max = 24;
                    Default = 12;
                    Decimals = 1;
                    Callback = function(v)
                        TimeChangerValue = v;
                        if TimeChangerEnabled then Lighting.ClockTime = v end;
                    end
                })
            end

        --#endregion

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

        --#region player aura
        -- A client-side aura around you: a soft rising particle column, a
        -- spinning ring of orbs and a gentle point light. It lives in a local
        -- model in workspace (never the character), so it is drawn only on your
        -- client and never replicates. Colour, transparency and rainbow all
        -- restyle live without rebuilding the model.
        do
            local PlayerAura = {
                Enabled = false,
                Color = Color3.fromRGB(255, 110, 230),   -- soft pink/purple
                Rainbow = false,
                RainbowSpeed = 0.25,
                Transparency = 0.35,
                Size = 4,
                Particles = true,
                Ring = true,
            }

            local AURA_TEX = "rbxassetid://243660364"
            local RING_ORBS = 10

            local auraModel, auraAnchor, emitter, auraLight
            local orbs = {}
            local ringAngle = 0

            local function teardown()
                if auraModel then
                    auraModel:Destroy()
                    auraModel = nil
                end
                auraAnchor, emitter, auraLight, orbs = nil, nil, nil, {}
            end

            local function build()
                teardown()
                auraModel = Instance.new("Model")
                auraModel.Name = "NegrohaxAura"

                auraAnchor = Instance.new("Part")
                auraAnchor.Name = "AuraAnchor"
                auraAnchor.Anchored, auraAnchor.CanCollide, auraAnchor.CanQuery, auraAnchor.CanTouch = true, false, false, false
                auraAnchor.Transparency = 1
                auraAnchor.Size = Vector3.new(0.2, 0.2, 0.2)
                auraAnchor.Parent = auraModel

                emitter = Instance.new("ParticleEmitter")
                emitter.Texture = AURA_TEX
                emitter.Color = ColorSequence.new(PlayerAura.Color)
                -- Soft and diffuse, not a harsh neon outline.
                emitter.LightEmission = 0.6
                emitter.Size = NumberSequence.new(1.1)
                emitter.Transparency = NumberSequence.new(PlayerAura.Transparency)
                emitter.Lifetime = NumberRange.new(0.6, 1.1)
                emitter.Speed = NumberRange.new(1, 3)
                emitter.SpreadAngle = Vector2.new(35, 35)
                emitter.Rate = 0
                emitter.Parent = auraAnchor

                auraLight = Instance.new("PointLight")
                auraLight.Name = "AuraLight"
                auraLight.Brightness = 1.4
                auraLight.Range = 14
                auraLight.Shadows = false
                auraLight.Color = PlayerAura.Color
                auraLight.Parent = auraAnchor

                for i = 1, RING_ORBS do
                    local orb = Instance.new("Part")
                    orb.Name = "AuraOrb"
                    orb.Shape = Enum.PartType.Ball
                    orb.Material = Enum.Material.Neon
                    orb.Anchored, orb.CanCollide, orb.CanQuery, orb.CanTouch = true, false, false, false
                    orb.Size = Vector3.new(0.5, 0.5, 0.5)
                    orb.Color = PlayerAura.Color
                    orb.Transparency = PlayerAura.Transparency
                    orb.Parent = auraModel
                    orbs[i] = orb
                end

                auraModel.Parent = workspace
            end

            -- Live restyle: colour and transparency change without ever
            -- rebuilding the aura model.
            local function applyStyle()
                if emitter then
                    emitter.Color = ColorSequence.new(PlayerAura.Color)
                    emitter.Transparency = NumberSequence.new(PlayerAura.Transparency)
                end
                if auraLight then auraLight.Color = PlayerAura.Color end
                for _, orb in ipairs(orbs) do
                    orb.Color = PlayerAura.Color
                    orb.Transparency = PlayerAura.Transparency
                end
            end

            RunService.RenderStepped:Connect(function(dt)
                if not PlayerAura.Enabled then
                    if auraModel then teardown() end
                    return
                end
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not root then
                    if auraModel then auraModel.Parent = nil end
                    return
                end
                if not auraModel then
                    build()
                elseif auraModel.Parent ~= workspace then
                    auraModel.Parent = workspace
                end

                auraAnchor.CFrame = root.CFrame
                if emitter then
                    emitter.Rate = PlayerAura.Particles and 60 or 0
                end

                if PlayerAura.Rainbow then
                    PlayerAura.Color = Color3.fromHSV((os.clock() * PlayerAura.RainbowSpeed) % 1, 0.55, 1)
                    applyStyle()
                end

                ringAngle = (ringAngle + (dt or 0.016) * 90) % 360
                local radius = PlayerAura.Size
                local lift = radius * 0.15
                for i, orb in ipairs(orbs) do
                    local a = math.rad(ringAngle + (i - 1) * 360 / RING_ORBS)
                    orb.CFrame = root.CFrame * CFrame.new(math.cos(a) * radius, lift, math.sin(a) * radius)
                    orb.Transparency = PlayerAura.Ring and PlayerAura.Transparency or 1
                end
            end)

            Sections.visuals:Toggle({
                Name = 'player aura';
                Flag = 'playeraura';
                Default = false;
                Callback = function(v) PlayerAura.Enabled = v end
            })

            Sections.visuals:Label({Name = 'player aura color'}):Colorpicker({
                Name = 'player aura color';
                Flag = 'playerauracolor';
                Default = PlayerAura.Color;
                Callback = function(v)
                    PlayerAura.Color = v
                    applyStyle()
                end
            })

            Sections.visuals:Toggle({
                Name = 'player aura rainbow';
                Flag = 'playeraurarainbow';
                Default = false;
                Callback = function(v) PlayerAura.Rainbow = v end
            })

            Sections.visuals:Slider({
                Name = 'player aura rainbow speed';
                Flag = 'playeraurarainbowspeed';
                Min = 0.05; Max = 1; Default = PlayerAura.RainbowSpeed; Decimals = 0.01;
                Callback = function(v) PlayerAura.RainbowSpeed = v end
            })

            Sections.visuals:Slider({
                Name = 'player aura transparency';
                Flag = 'playerauratransparency';
                Min = 0; Max = 1; Default = PlayerAura.Transparency; Decimals = 0.05;
                Callback = function(v) PlayerAura.Transparency = v; applyStyle() end
            })

            Sections.visuals:Slider({
                Name = 'player aura size';
                Flag = 'playeraurasize';
                Min = 1.5; Max = 12; Default = 4; Decimals = 0.5;
                Callback = function(v) PlayerAura.Size = v end
            })

            Sections.visuals:Toggle({
                Name = 'player aura particles';
                Flag = 'playerauraparticles';
                Default = true;
                Callback = function(v) PlayerAura.Particles = v end
            })

            Sections.visuals:Toggle({
                Name = 'player aura ring';
                Flag = 'playerauraring';
                Default = true;
                Callback = function(v) PlayerAura.Ring = v end
            })
        end
        --#endregion

        --#region self chams
        -- Client-only holographic self chams. A soft translucent Highlight wraps
        -- your own character and, with x-ray off, is depth sorted so the
        -- silhouette reads as layered instead of a flat neon outline. An
        -- optional point light adds a gentle pink glow. Every instance here is
        -- created on your client, so nothing replicates.
        do
            local SelfChams = {
                Enabled = false,
                Color = Color3.fromRGB(255, 110, 230),   -- soft pink/purple
                Rainbow = false,
                RainbowSpeed = 0.25,
                Transparency = 0.55,
                Glow = true,
                Light = true,
                XRay = false,
            }

            local highlight, light

            local function teardown()
                if highlight then highlight:Destroy(); highlight = nil end
                if light then light:Destroy(); light = nil end
            end

            local function build()
                teardown()
                local character = LocalPlayer.Character
                if not character or not character:FindFirstChildOfClass("Humanoid") then return end
                local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
                if not root then return end

                highlight = Instance.new("Highlight")
                highlight.Name = "NegrohaxSelfChams"
                highlight.Adornee = character
                highlight.Parent = character

                light = Instance.new("PointLight")
                light.Name = "NegrohaxSelfChamsLight"
                light.Brightness = 1.5
                light.Range = 13
                light.Shadows = false
                light.Parent = root
            end

            -- Live restyle: colour / transparency / mode update every frame
            -- without rebuilding the highlight.
            local function apply()
                if highlight then
                    highlight.Enabled = SelfChams.Glow
                    highlight.FillColor = SelfChams.Color
                    highlight.OutlineColor = SelfChams.Color
                    highlight.FillTransparency = SelfChams.Transparency
                    highlight.OutlineTransparency = math.clamp(SelfChams.Transparency - 0.35, 0, 1)
                    highlight.DepthMode = SelfChams.XRay and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                end
                if light then
                    light.Enabled = SelfChams.Light
                    light.Color = SelfChams.Color
                end
            end

            RunService.RenderStepped:Connect(function()
                if not SelfChams.Enabled then
                    if highlight or light then teardown() end
                    return
                end
                local character = LocalPlayer.Character
                if not character then
                    if highlight or light then teardown() end
                    return
                end
                if not highlight or highlight.Parent ~= character then
                    build()
                end
                if SelfChams.Rainbow then
                    SelfChams.Color = Color3.fromHSV((os.clock() * SelfChams.RainbowSpeed) % 1, 0.55, 1)
                end
                apply()
            end)

            LocalPlayer.CharacterAdded:Connect(function()
                if SelfChams.Enabled then task.defer(build) end
            end)

            Sections.visuals:Toggle({
                Name = 'self chams';
                Flag = 'selfchams';
                Default = false;
                Callback = function(v)
                    SelfChams.Enabled = v
                    if not v then teardown() end
                end
            })

            Sections.visuals:Label({Name = 'self chams color'}):Colorpicker({
                Name = 'self chams color';
                Flag = 'selfchamscolor';
                Default = SelfChams.Color;
                Callback = function(v)
                    SelfChams.Color = v
                    apply()
                end
            })

            Sections.visuals:Toggle({
                Name = 'self chams rainbow';
                Flag = 'selfchamsrainbow';
                Default = false;
                Callback = function(v) SelfChams.Rainbow = v end
            })

            Sections.visuals:Slider({
                Name = 'self chams rainbow speed';
                Flag = 'selfchamsrainbowspeed';
                Min = 0.05; Max = 1; Default = SelfChams.RainbowSpeed; Decimals = 0.01;
                Callback = function(v) SelfChams.RainbowSpeed = v end
            })

            Sections.visuals:Slider({
                Name = 'self chams transparency';
                Flag = 'selfchamstransparency';
                Min = 0; Max = 1; Default = SelfChams.Transparency; Decimals = 0.05;
                Callback = function(v) SelfChams.Transparency = v; apply() end
            })

            Sections.visuals:Toggle({
                Name = 'self chams x-ray';
                Flag = 'selfchamsxray';
                Default = false;
                Callback = function(v) SelfChams.XRay = v; apply() end
            })

            Sections.visuals:Toggle({
                Name = 'self chams glow';
                Flag = 'selfchamsglow';
                Default = true;
                Callback = function(v) SelfChams.Glow = v; apply() end
            })

            Sections.visuals:Toggle({
                Name = 'self chams light';
                Flag = 'selfchamslight';
                Default = true;
                Callback = function(v) SelfChams.Light = v; apply() end
            })
        end
        --#endregion

        --#region skybox changer
        -- Client-side sky replacement. The original faces are captured once and
        -- restored when the changer is switched off (or "Default" is chosen), so
        -- it always leaves the sky exactly as it found it.
        do
            local Skyboxes = {
                Eyes = { "6823346883", "6823346883", "6823346883", "6823346883", "6823346883", "6823346883" },
                Spongebob = { "277094910", "277094864", "277094957", "277095042", "277094996", "277095139" },
                ["Blue Sky"] = { "591058823", "591059876", "591058104", "591057861", "591057625", "591059642" },
                Vaporwave = { "1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643" },
                Redshift = { "401664839", "401664862", "401664960", "401664881", "401664901", "401664936" },
                Blaze = { "150939022", "150939038", "150939047", "150939056", "150939063", "150939082" },
                ["Among Us"] = { "5752463190", "5752463190", "5752463190", "5752463190", "5752463190", "5752463190" },
                ["Dark Night"] = { "6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635" },
                ["Bright Pink"] = { "271042516", "271077243", "271042556", "271042310", "271042467", "271077958" },
                ["Purple Sky"] = { "570557514", "570557775", "570557559", "570557620", "570557672", "570557727" },
                Galaxy = { "15125283003", "15125281008", "15125277539", "15125279325", "15125274388", "15125275800" },
            }

            local SkyboxChanger = { Enabled = false, Selected = "Default", Original = nil }

            local function sky()
                local instance = Lighting:FindFirstChildWhichIsA("Sky")
                if not instance then
                    instance = Instance.new("Sky")
                    instance.Parent = Lighting
                end
                return instance
            end

            local function captureOriginal()
                local instance = sky()
                SkyboxChanger.Original = {
                    instance.SkyboxBk, instance.SkyboxDn, instance.SkyboxFt,
                    instance.SkyboxLf, instance.SkyboxRt, instance.SkyboxUp,
                }
            end

            local function toAsset(value)
                if type(value) ~= "string" then return value end
                local text: string = value
                if string.sub(text, 1, 3) == "rbx" then return text end
                return "rbxassetid://" .. text
            end

            local function apply(name)
                if not SkyboxChanger.Original then captureOriginal() end
                local instance = sky()
                local faces = Skyboxes[name]
                if name == "Default" or not faces then
                    faces = SkyboxChanger.Original
                end
                if not faces then return end
                instance.SkyboxBk = toAsset(faces[1])
                instance.SkyboxDn = toAsset(faces[2])
                instance.SkyboxFt = toAsset(faces[3])
                instance.SkyboxLf = toAsset(faces[4])
                instance.SkyboxRt = toAsset(faces[5])
                instance.SkyboxUp = toAsset(faces[6])
            end

            local names = { "Default" }
            for name in pairs(Skyboxes) do names[#names + 1] = name end
            table.sort(names)

            Sections.visuals:Toggle({
                Name = 'skybox changer';
                Flag = 'skyboxchanger';
                Default = false;
                Callback = function(v)
                    SkyboxChanger.Enabled = v
                    if v then
                        apply(SkyboxChanger.Selected)
                    else
                        apply("Default")
                    end
                end
            })

            Sections.visuals:Dropdown({
                Name = 'skybox';
                Flag = 'skybox';
                Items = names;
                Default = "Default";
                Callback = function(v)
                    SkyboxChanger.Selected = v
                    if SkyboxChanger.Enabled then apply(v) end
                end
            })
        end
        --#endregion

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


--#region remove doors

    -- Client-side only: makes every door part of the map non-collidable and
    -- invisible so you can walk straight through it. The server still owns the
    -- real door, so this is a movement shortcut, not a server-side remover.
    do
        local DoorRemoval = {
            Enabled = false,
            -- Weak keys: a door that is destroyed / streamed out drops its
            -- saved properties instead of pinning the instance forever.
            Originals = WeakKeyedTable(),
            Connection = nil,
        }

        -- A door is a part whose own name, or the name of one of its three
        -- nearest containers, contains "door" or "gate". That catches the
        -- game's "Door", "CellDoor", "Door1" ... parts, anything inside a
        -- "Doors"/"Gates" folder, and model-based doors (e.g. a "CellDoor"
        -- model with a part called "Part") without touching the rest of the map.
        local function IsDoor(part)
            if not part:IsA("BasePart") then return false end
            local character = LocalPlayer.Character
            if character and part:IsDescendantOf(character) then return false end
            local name = string.lower(part.Name)
            if name:find("door", 1, true) or name:find("gate", 1, true) then
                return true
            end
            local ancestor, depth = part.Parent, 0
            while ancestor and ancestor ~= workspace and depth < 3 do
                local ancestorName = string.lower(ancestor.Name)
                if ancestorName:find("door", 1, true)
                    or ancestorName:find("gate", 1, true) then
                    return true
                end
                ancestor, depth = ancestor.Parent, depth + 1
            end
            return false
        end

        local function StripDoor(part)
            if DoorRemoval.Originals[part] or not part.Parent or not IsDoor(part) then
                return
            end
            DoorRemoval.Originals[part] = {
                CanCollide = part.CanCollide,
                CanQuery = part.CanQuery,
                CanTouch = part.CanTouch,
                Transparency = part.Transparency,
                CastShadow = part.CastShadow,
            }
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.CastShadow = false
            part.Transparency = 1
        end

        local function RestoreDoors()
            for part, saved in pairs(DoorRemoval.Originals) do
                if part.Parent then
                    part.CanCollide = saved.CanCollide
                    part.CanQuery = saved.CanQuery
                    part.CanTouch = saved.CanTouch
                    part.Transparency = saved.Transparency
                    part.CastShadow = saved.CastShadow
                end
                DoorRemoval.Originals[part] = nil
            end
        end

        local function SweepDoors()
            for _, object in ipairs(workspace:GetDescendants()) do
                if object:IsA("BasePart") then
                    StripDoor(object)
                end
            end
        end

        local function SetDoorRemoval(enabled)
            DoorRemoval.Enabled = enabled
            if DoorRemoval.Connection then
                DoorRemoval.Connection:Disconnect()
                DoorRemoval.Connection = nil
            end
            if enabled then
                SweepDoors()
                -- Round resets rebuild the map. New parts are caught as they
                -- arrive; the delayed re-sweep covers a map that was already
                -- parented into workspace when the toggle was switched on.
                task.delay(1, function()
                    if DoorRemoval.Enabled then SweepDoors() end
                end)
                DoorRemoval.Connection = workspace.DescendantAdded:Connect(function(object)
                    if DoorRemoval.Enabled and object:IsA("BasePart") then
                        task.defer(function()
                            if DoorRemoval.Enabled then StripDoor(object) end
                        end)
                    end
                end)
            else
                RestoreDoors()
            end
        end

        Sections.exploits:Toggle({
            Name = "remove doors";
            Flag = "removedoors";
            Default = false;
            Callback = function(value)
                SetDoorRemoval(value);
            end;
        })
    end

--#endregion

--#region restore hitboxes

    -- Counter to other players running a "no hitbox" script: force CanQuery / CanTouch
    -- back on for every other player's character parts on OUR client, so our aim rays
    -- and touch tests always see them. Purely local, and a no-op when the flags were
    -- never cleared. Also fixes the case where a game marks its own body parts or
    -- accessories non-queriable, which would otherwise make them unhittable to us.
    do
        local RestoreHitboxes = {
            Enabled = false,
            Originals = WeakKeyedTable(),
        }

        local function restore(part)
            if not part:IsA("BasePart") then return end
            if part.CanQuery and part.CanTouch then return end
            if RestoreHitboxes.Originals[part] == nil then
                RestoreHitboxes.Originals[part] = {
                    CanQuery = part.CanQuery,
                    CanTouch = part.CanTouch,
                }
            end
            part.CanQuery = true
            part.CanTouch = true
        end

        local function sweep(character)
            for _, part in ipairs(character:GetDescendants()) do
                restore(part)
            end
        end

        local function sweepAll()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local character = plr.Character
                    if character then sweep(character) end
                end
            end
        end

        local function revertAll()
            for part, original in pairs(RestoreHitboxes.Originals) do
                if part.Parent then
                    part.CanQuery = original.CanQuery
                    part.CanTouch = original.CanTouch
                end
                RestoreHitboxes.Originals[part] = nil
            end
        end

        -- A slow catch-all sweep: the flags only change when a player toggles their
        -- own script, so there is no reason to touch every part every frame.
        local sweepClock = 0
        RunService.Heartbeat:Connect(function(dt)
            if not RestoreHitboxes.Enabled then return end
            sweepClock += dt
            if sweepClock < 0.5 then return end
            sweepClock = 0
            sweepAll()
        end)

        Sections.exploits:Toggle({
            Name = "restore hitboxes";
            Flag = "restorehitboxes";
            Default = false;
            Callback = function(value)
                RestoreHitboxes.Enabled = value;
                if value then
                    sweepAll();
                else
                    revertAll();
                end
            end;
        })
    end

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

    --#region car fly

        -- Flies the vehicle you are sitting in. A BodyVelocity on the chassis root
        -- takes over the car's motion (WASD strafes on the XZ plane, Q down / E up)
        -- and a BodyGyro keeps it level. Only runs while you are seated, so it does
        -- nothing on foot and cleans itself up when you get out.
        do
            local CarFly = {
                Enabled = false,
                Speed = 70,
                -- Camera orbit distance. Small = first person (camera sits on the
                -- car), large = third person. The scroll wheel zooms it live and
                -- the "car fly distance" slider sets it, so you can fly in either
                -- view without leaving the shift-lock style camera.
                Distance = 16,
                MinDistance = 0.5,
                MaxDistance = 30,
                Height = 3,
                -- Radians of view turn per pixel of mouse movement. The old 0.25
                -- meant a 3-4px flick snapped the view ~48 degrees, which read as
                -- both "way too sensitive" and "it only turns a little".
                Sensitivity = 0.012,
                -- How fast the view / the car ease toward their targets. Higher is
                -- snappier; these are what make the turn smooth rather than instant.
                ViewSmoothing = 18,
                TurnSmoothing = 10,
                -- Optional spin: an extra yaw offset layered on top of the car's
                -- heading, so the car twirls in place. The camera only ever reads
                -- camYaw (never the car's rotation), so the car can spin freely
                -- while your view stays steady. Speed is degrees per second.
                Spin = false,
                SpinSpeed = 360,
            }

            local bodyVel
            local bodyGyro
            local vehicleRoot
            local vehicleSeat

            -- Shift-lock style camera. While flying, the camera is scriptable and
            -- orbits the car, driven only by the mouse, so the car's own rotation
            -- (the BodyGyro) can never feed back into the view and make it spin.
            -- The mouse only moves a *target* yaw / pitch; the live values ease
            -- toward it so a fast flick glides instead of snapping.
            local camYaw, camPitch = 0, -0.2
            local camYawTarget, camPitchTarget = 0, -0.2
            -- The car's own heading eases toward the view yaw for the same reason.
            local carYaw = 0
            -- Extra yaw applied on top of carYaw by the spin feature.
            local spinAngle = 0
            local savedCameraType
            local cameraActive = false

            local CAMERA_STEP = "NegrohaxCarFlyCamera"

            local function restoreCamera()
                local camera = workspace.CurrentCamera
                if camera and camera.CameraType == Enum.CameraType.Scriptable then
                    camera.CameraType = savedCameraType or Enum.CameraType.Custom
                end
                -- Never leave the mouse locked to the centre once flight ends.
                -- The saved value can itself be LockCenter (captured while the
                -- game had the mouse locked in the seat), which is exactly what
                -- left the screen stuck after stepping out of the car.
                if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end
                savedCameraType = nil
                cameraActive = false
            end

            local function stopCarFly()
                if bodyVel then
                    bodyVel:Destroy()
                    bodyVel = nil
                end
                if bodyGyro then
                    bodyGyro:Destroy()
                    bodyGyro = nil
                end
                vehicleRoot = nil
                vehicleSeat = nil
                spinAngle = 0
                restoreCamera()
            end

            local function seatedSeat()
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                return humanoid and humanoid.SeatPart
            end

            local function seatedRoot(seat)
                if not seat then return nil end
                return seat.AssemblyRootPart or seat
            end

            -- Live world position of the car. The seat is welded to the chassis, so
            -- it always tracks the car; the character root (welded to the seat) is
            -- only a fallback for the odd frame where the seat is not streamed yet.
            local function carPosition()
                if vehicleSeat and vehicleSeat.Parent then return vehicleSeat.Position end
                if vehicleRoot and vehicleRoot.Parent then return vehicleRoot.Position end
                local character = LocalPlayer.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                return hrp and hrp.Position
            end

            -- Scriptable, shift-lock style camera. The mouse drives yaw / pitch
            -- directly and the camera orbits the car, so nothing the car does can
            -- feed back into the view. The whole rig lives in the render step so it
            -- cannot get stuck: it re-checks the seat and re-asserts the camera type
            -- every frame, and hands the camera back the moment you stop.
            local function updateCarFlyCamera(dt)
                local cam = workspace.CurrentCamera
                if not cam then return end

                local seat = CarFly.Enabled and seatedSeat() or nil
                if not seat then
                    if cameraActive then restoreCamera() end
                    return
                end

                if not cameraActive then
                    cameraActive = true
                    savedCameraType = cam.CameraType

                    -- Seed yaw / pitch from wherever the player is already looking.
                    local look = cam.CFrame.LookVector
                    camYaw = math.atan2(-look.X, -look.Z)
                    camPitch = math.asin(math.clamp(look.Y, -1, 1))
                    camYawTarget, camPitchTarget = camYaw, camPitch
                end

                -- The default camera module (and the game) can reset these out from
                -- under us, so re-assert them every frame.
                if cam.CameraType ~= Enum.CameraType.Scriptable then
                    cam.CameraType = Enum.CameraType.Scriptable
                end
                if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                end

                local position = carPosition()
                if not position then return end

                -- GetMouseDelta returns a Vector2. Destructuring it into two locals
                -- gave (Vector2, nil), so the very next line threw every frame and
                -- left the camera frozen at whatever CFrame it had when the step was
                -- first bound.
                local delta = UserInputService:GetMouseDelta()
                camYawTarget -= delta.X * CarFly.Sensitivity
                camPitchTarget = math.clamp(camPitchTarget - delta.Y * CarFly.Sensitivity, -1.1, 1.1)

                -- Frame-rate independent easing: the view glides toward the mouse
                -- target instead of jumping to it, which is what makes turning feel
                -- smooth rather than twitchy.
                local step = dt or 0.016
                local ease = 1 - math.exp(-CarFly.ViewSmoothing * step)
                camYaw += (camYawTarget - camYaw) * ease
                camPitch += (camPitchTarget - camPitch) * ease

                local rot = CFrame.fromEulerAnglesYXZ(camPitch, camYaw, 0)
                local target = position + Vector3.new(0, CarFly.Height, 0)
                -- Clamp so a first-person setting (0) never degenerates into a
                -- zero-length lookAt.
                local distance = math.clamp(
                    CarFly.Distance or 16, CarFly.MinDistance, CarFly.MaxDistance)
                cam.CFrame = CFrame.lookAt(target - rot.LookVector * distance, target)
            end

            -- Bound once for the whole session. Binding inside the toggle (and
            -- unbinding on stop) collided with the script's own stale binding when
            -- it was re-executed: BindToRenderStep throws if the name is already
            -- taken, which silently left the camera frozen where it was enabled.
            pcall(function()
                RunService:UnbindFromRenderStep(CAMERA_STEP)
            end)
            RunService:BindToRenderStep(CAMERA_STEP, Enum.RenderPriority.Camera.Value + 1, updateCarFlyCamera)

            -- Scroll wheel zooms the orbit while flying: pull in for a first-person
            -- view, push out for third person. It only runs while the flight camera
            -- is actually active, so it never swallows the scroll wheel on foot.
            local carFlyDistanceSlider
            UserInputService.InputChanged:Connect(function(input)
                if not cameraActive then return end
                if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
                local distance = (CarFly.Distance or 16) - input.Position.Z * 2
                distance = math.clamp(distance, CarFly.MinDistance, CarFly.MaxDistance)
                CarFly.Distance = distance
                if carFlyDistanceSlider then carFlyDistanceSlider:Set(distance) end
            end)

            RunService.Heartbeat:Connect(function(dt)
                if not CarFly.Enabled then
                    if bodyVel then stopCarFly() end
                    return
                end

                local seat = seatedSeat()
                local root = seatedRoot(seat)
                if not root then
                    if bodyVel then stopCarFly() end
                    return
                end

                vehicleSeat = seat

                if root ~= vehicleRoot or not bodyVel or not bodyVel.Parent then
                    if bodyVel then bodyVel:Destroy() end
                    if bodyGyro then bodyGyro:Destroy() end
                    vehicleRoot = root

                    -- Start the car's heading exactly where the view is so it does
                    -- not swing round to catch up on the first frame.
                    carYaw = camYaw

                    bodyVel = Instance.new("BodyVelocity")
                    bodyVel.Name = "NegrohaxCarFly"
                    bodyVel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                    bodyVel.P = 1250
                    bodyVel.Parent = root

                    bodyGyro = Instance.new("BodyGyro")
                    bodyGyro.Name = "NegrohaxCarFlyGyro"
                    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                    bodyGyro.P = 3000
                    bodyGyro.D = 200
                    bodyGyro.Parent = root
                end

                -- WASD moves on the horizontal plane only: derive forward / right
                -- from the camera yaw so pitch never lifts the car, then flatten.
                local forward = Vector3.new(-math.sin(camYaw), 0, -math.cos(camYaw))
                local strafe = Vector3.new(-forward.Z, 0, forward.X)

                local direction = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= forward end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += strafe end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= strafe end
                if direction.Magnitude > 0 then direction = direction.Unit end

                local vertical = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then vertical += 1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then vertical -= 1 end

                bodyVel.Velocity =
                    direction * CarFly.Speed + Vector3.new(0, vertical * CarFly.Speed, 0)

                -- Keep the car level and eases its heading toward the view so a hard
                -- turn banks round smoothly instead of snapping. The camera never
                -- reads the car's rotation, so this can never feed back into the view.
                local ease = 1 - math.exp(-CarFly.TurnSmoothing * (dt or 0.016))
                carYaw += (camYaw - carYaw) * ease

                -- Spin: a separate yaw offset added on top of the heading. While the
                -- toggle is off the offset eases back to zero so the car settles
                -- level instead of freezing mid-twirl. Normalising to [-pi, pi]
                -- keeps the value small (no precision drift on a long flight) and
                -- makes the settle take the short way round.
                if CarFly.Spin then
                    spinAngle += math.rad(CarFly.SpinSpeed) * (dt or 0.016)
                else
                    spinAngle += (0 - spinAngle) * ease
                end
                spinAngle = (spinAngle + math.pi) % (2 * math.pi) - math.pi

                bodyGyro.CFrame = CFrame.Angles(0, carYaw + spinAngle, 0)
            end)

            Sections.movement:Toggle({
                Name = 'car fly';
                Flag = 'carfly';
                Default = false;
                Callback = function(v)
                    CarFly.Enabled = v
                    if not v then stopCarFly() end
                end
            })

            Sections.movement:Slider({
                Name = 'car fly speed';
                Flag = 'carflyspeed';
                Min = 10;
                Max = 400;
                Default = 70;
                Decimals = 1;
                Callback = function(v)
                    CarFly.Speed = v
                end
            })

            Sections.movement:Slider({
                Name = 'car fly turn speed';
                Flag = 'carflyturnspeed';
                Min = 0.002;
                Max = 0.08;
                Default = 0.012;
                -- NOTE: in this library Decimals is the *step size*, not a digit
                -- count. Passing 3 made the step 3, so every value rounded to 0 and
                -- the slider looked stuck.
                Decimals = 0.001;
                Callback = function(v)
                    CarFly.Sensitivity = v
                end
            })

            carFlyDistanceSlider = Sections.movement:Slider({
                Name = 'car fly distance';
                Flag = 'carflydistance';
                Min = 0;
                Max = 30;
                Default = 16;
                -- Same library quirk as above: Decimals is the step size. 0.5 gives
                -- a smooth half-metre zoom; 0 or a digit count would break it.
                Decimals = 0.5;
                Callback = function(v)
                    CarFly.Distance = v
                end
            })

            Sections.movement:Toggle({
                Name = 'car spin';
                Flag = 'carspin';
                Default = false;
                Callback = function(v)
                    CarFly.Spin = v
                end
            })

            Sections.movement:Slider({
                Name = 'car spin speed';
                Flag = 'carspinspeed';
                Min = 30;
                Max = 1440;
                Default = 360;
                -- Degrees per second; 10 is a fine enough step to feel smooth.
                Decimals = 10;
                Callback = function(v)
                    CarFly.SpinSpeed = v
                end
            })
        end

    --#endregion

    --#region anti fling
    -- Undoes a fling aimed at us. Fling tools either shove the root part with an
    -- absurd velocity / spin, attach a body mover to it, or park the humanoid in
    -- the physics state; all three are caught here and reverted on our client.
    -- The per-frame cost is two property reads, and only while enabled.
    do
        local AntiFling = {
            Enabled = false,
            MaxSpeed = 500,   -- studs/s; faster than this reads as a fling
            MaxSpin = 60,     -- rad/s
        }

        local MOVER_CLASSES = {
            "BodyAngularVelocity", "BodyVelocity", "BodyForce", "BodyThrust",
            "BodyPosition", "BodyGyro", "RocketPropulsion", "AngularVelocity",
            "LinearVelocity", "VectorForce", "Torque", "AlignOrientation",
            "AlignPosition",
        }

        local function stripMovers(model)
            if not model then return end
            for _, d in ipairs(model:GetDescendants()) do
                for _, class in ipairs(MOVER_CLASSES) do
                    if d:IsA(class) then
                        d:Destroy()
                        break
                    end
                end
            end
        end

        local function bindCharacter(model)
            if not model then return end
            if AntiFling.Enabled then stripMovers(model) end
            model.DescendantAdded:Connect(function(d)
                if not AntiFling.Enabled then return end
                for _, class in ipairs(MOVER_CLASSES) do
                    if d:IsA(class) then
                        d:Destroy()
                        return
                    end
                end
            end)
        end

        RunService.Heartbeat:Connect(function()
            if not AntiFling.Enabled then return end
            local model = LocalPlayer.Character
            local root = model and model:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local spin = root.AssemblyAngularVelocity
            if spin.Magnitude > AntiFling.MaxSpin or spin.Magnitude ~= spin.Magnitude then
                root.AssemblyAngularVelocity = Vector3.zero
            end

            local velocity = root.AssemblyLinearVelocity
            local speed = velocity.Magnitude
            if speed > AntiFling.MaxSpeed or speed ~= speed then
                root.AssemblyLinearVelocity = (speed == speed)
                    and velocity * (AntiFling.MaxSpeed / speed)
                    or Vector3.zero
            end

            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid.PlatformStand then humanoid.PlatformStand = false end
                if humanoid:GetState() == Enum.HumanoidStateType.Physics then
                    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end)

        bindCharacter(LocalPlayer.Character)
        LocalPlayer.CharacterAdded:Connect(bindCharacter)

        Sections.exploits:Toggle({
            Name = 'anti fling';
            Flag = 'antifling';
            Default = false;
            Callback = function(v)
                AntiFling.Enabled = v
                if v then stripMovers(LocalPlayer.Character) end
            end
        })

        Sections.exploits:Slider({
            Name = 'anti fling max speed';
            Flag = 'antiflingspeed';
            Min = 50; Max = 2000; Default = 500; Decimals = 10;
            Callback = function(v) AntiFling.MaxSpeed = v end
        })

        Sections.exploits:Slider({
            Name = 'anti fling max spin';
            Flag = 'antiflingspin';
            Min = 5; Max = 500; Default = 60; Decimals = 5;
            Callback = function(v) AntiFling.MaxSpin = v end
        })
    end
    --#endregion

    --#region fence godmode
    -- The map's fences and barbed wire damage you on contact. This finds those
    -- parts by name and turns their collision and touch off locally, so you can
    -- walk through them and they cannot raise a Touched event on your client. A
    -- health guard also puts health back if a hazard still lands a hit while you
    -- are next to it.
    do
        local FenceGod = { Enabled = false }

        local WORDS = { "fence", "barb", "wire", "razor", "spike", "electrif", "electro" }
        local Originals = WeakKeyedTable()
        local hazards = WeakKeyedTable()
        local connection

        local function isHazard(part)
            if not part:IsA("BasePart") then return false end
            local model = LocalPlayer.Character
            if model and part:IsDescendantOf(model) then return false end
            local name = string.lower(part.Name)
            for _, word in ipairs(WORDS) do
                if string.find(name, word, 1, true) then return true end
            end
            local ancestor, depth = part.Parent, 0
            while ancestor and ancestor ~= workspace and depth < 2 do
                local ancestorName = string.lower(ancestor.Name)
                for _, word in ipairs(WORDS) do
                    if string.find(ancestorName, word, 1, true) then return true end
                end
                ancestor, depth = ancestor.Parent, depth + 1
            end
            return false
        end

        local function strip(part)
            if Originals[part] or not isHazard(part) then return end
            Originals[part] = { CanCollide = part.CanCollide, CanTouch = part.CanTouch }
            part.CanCollide = false
            part.CanTouch = false
            hazards[part] = true
        end

        local function restore()
            for part, saved in pairs(Originals) do
                if part.Parent then
                    part.CanCollide = saved.CanCollide
                    part.CanTouch = saved.CanTouch
                end
                Originals[part] = nil
            end
            hazards = WeakKeyedTable()
        end

        local function sweep()
            for _, object in ipairs(workspace:GetDescendants()) do
                if object:IsA("BasePart") then strip(object) end
            end
        end

        local function setEnabled(enabled)
            FenceGod.Enabled = enabled
            if connection then
                connection:Disconnect()
                connection = nil
            end
            if enabled then
                sweep()
                task.delay(1, function()
                    if FenceGod.Enabled then sweep() end
                end)
                connection = workspace.DescendantAdded:Connect(function(object)
                    if FenceGod.Enabled and object:IsA("BasePart") then
                        task.defer(function()
                            if FenceGod.Enabled then strip(object) end
                        end)
                    end
                end)
            else
                restore()
            end
        end

        local function bindCharacter(model)
            if not model then return end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            local last = humanoid.Health
            humanoid.HealthChanged:Connect(function(health)
                if FenceGod.Enabled and health < last then
                    local root = model:FindFirstChild("HumanoidRootPart")
                    if root then
                        for part in pairs(hazards) do
                            if part.Parent
                                and (part.Position - root.Position).Magnitude < 14 then
                                humanoid.Health = last
                                break
                            end
                        end
                    end
                end
                last = health
            end)
        end

        bindCharacter(LocalPlayer.Character)
        LocalPlayer.CharacterAdded:Connect(bindCharacter)

        Sections.exploits:Toggle({
            Name = 'fence godmode';
            Flag = 'fencegod';
            Default = false;
            Callback = function(v) setEnabled(v) end
        })
    end
    --#endregion

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

        -- Animated X + ring where the shot landed. Headshots and kills use
        -- their own colours.
        Sections.hit:Toggle({
            Name = 'hitmarkers';
            Flag = 'hitmarkers';
            Default = false;
            Callback = function(v)
                Hitmarker.Enabled = v;
            end
        })

        Sections.hit:Slider({
            Name = 'hitmarker size';
            Flag = 'hitmarkersize';
            Default = 16;
            Min = 6;
            Max = 48;
            Decimals = 1;
            Callback = function(v)
                Hitmarker.Size = v;
            end
        })

        Sections.hit:Slider({
            Name = 'hitmarker duration (s)';
            Flag = 'hitmarkerduration';
            Default = 0.45;
            Min = 0.15;
            Max = 1.5;
            Decimals = 0.05;
            Callback = function(v)
                Hitmarker.Duration = v;
            end
        })

        Sections.hit:Label({Name = 'hitmarker color'}):Colorpicker({
            Name = 'hitmarker color';
            Flag = 'hitmarkercolor';
            Default = Hitmarker.Color;
            Callback = function(v)
                Hitmarker.Color = v;
            end
        })

        Sections.hit:Label({Name = 'headshot color'}):Colorpicker({
            Name = 'headshot color';
            Flag = 'hitmarkerheadcolor';
            Default = Hitmarker.HeadColor;
            Callback = function(v)
                Hitmarker.HeadColor = v;
            end
        })

        Sections.hit:Label({Name = 'kill color'}):Colorpicker({
            Name = 'kill color';
            Flag = 'hitmarkerkillcolor';
            Default = Hitmarker.KillColor;
            Callback = function(v)
                Hitmarker.KillColor = v;
            end
        })
    --#endregion
end 


-- Advanced AA / underground.
--
-- Anti-ESP character spoof ("anti esp" toggle):
--   * The pose every OTHER client reads (ESP box, chams, their aimbot's
--     target position) is the pose the server holds - and this script owns
--     that pose. The spoof pushes it far away in a random horizontal
--     direction (re-rolled on a timer) AND under the map, so enemy ESP
--     draws the wrong position and enemy aimbots that check visibility
--     (raycast to the head) never lock on. Client-side, our own body and
--     camera stay exactly where they are.
--   * Our own aim compensates automatically: shots are built from the
--     spoofed pose through the peek machinery, exactly like underground -
--     we keep hitting them while they cannot hit us. Square / prism can be
--     combined with it and then orbit around the spoofed centre.
--
-- Position-based shapes (square / prism):
--   * Square walks the server position around a square loop in the XZ
--     plane (range = size, speed = how fast it orbits), clockwise.
--   * Prism walks it around a clockwise triangular loop in the XZ plane.
--   * Omniscient jumps the server position to a random point on a sphere in
--     X/Y/Z (radius capped by the same range slider), re-rolled on its own
--     timer. Because it already moves above AND below ground, enabling it
--     cancels underground and ug horizontal - those would only fight it for
--     the Y axis. Everything else stacks with it.
--   * EVERY mode stacks: anti-ESP + square + prism + omniscient + height
--     can all be enabled together. Square and prism are averaged and the
--     combined path is clamped to the range slider, so having several on
--     keeps the pose inside the requested radius instead of multiplying it;
--     anti-ESP adds its far horizontal centre and the height slider adds
--     its lift on top of that. Underground is mutually exclusive with
--     omniscient.
--   * The default speed is 1 cycle/s on purpose: character replication
--     lands a snapshot on the server roughly every 50ms, and the shot is
--     validated against the pose it holds when the remote arrives. A fast
--     orbit moves several studs between snapshots, so the origin the aim
--     fired from no longer matches the server pose -> invalid shots -> the
--     failsafe drops the AA. The slider still goes up to 20 for
--     experimentation, but shots get unreliable well before that.
--   * The shape paths NEVER move Y. The height slider lifts and the UG depth
--     slider drops; when modes are stacked both apply. Safe footing searches
--     nearby outline points / shorter steps only - no vertical hop any more.
--   * Shots fired while the pose orbits are built from the pose the server
--     holds at fire time; pose replication and the gun remote share the
--     same one-way latency, so that is still the pose the server holds
--     when the shot arrives - the orbit NEVER pauses for gunfire
--     ("smooth shots", default on). Optional stable mode freezes the pose
--     per shot instead (rock-solid validation, but the pose sits still
--     while firing).
--
-- Desync order (per frame):
--   physics -> PostSimulation: save the real pose, move the body to the fake
--              (server) pose. Replication sends THIS pose to the server.
--   Heartbeat: the fake pose is asserted again. The engine's character
--              update flush point has moved between versions; covering
--              both post-physics windows is what makes the server actually
--              HOLD the displaced pose (a Heartbeat-only build left it
--              alive solely in the idle gap between frames, so the server
--              only ever saw the real pose: square / prism looked dead and
--              underground shots went invalid).
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
        -- Smooth shots: the orbit NEVER pauses for gunfire. Shot origins are
        -- built from the pose the server holds at fire time - which, since
        -- pose replication and the gun remote share the same one-way
        -- latency, is still the pose the server holds when the shot arrives.
        -- No freeze needed, so the AA runs at full slider speed while
        -- shooting. Turn this OFF to fall back to the shot-pose freeze
        -- (rock-solid validation, but the pose sits still while firing).
        SmoothShots = true,
        -- Anti-ESP character spoof (HvH): parks the pose everyone ELSE reads
        -- inside solid geometry - under the floor, inside a nearby wall /
        -- building part, or (fallback) far away under the map. Enemy ESP
        -- therefore draws a wrong / enclosed box and their aimbot's
        -- visibility check (raycast to the head) fails. Our own aim
        -- compensates through the same bridges, so we still hit them.
        AntiESP = false,
        -- auto = pick the best available hiding spot each reroll,
        -- underground / wall = force that kind, far = old far-away spoof.
        AntiESPMode = "auto",
        AntiESPDistance = 60,
        AntiESPReroll = 3,
        -- Omniscient: random sphere around the real root, in X/Y/Z. Radius is
        -- capped by the range slider, and the point is re-rolled on its own
        -- timer. Cancels UG (it already goes above and below ground).
        Omniscient = false,
        OmniscientReroll = 0.75,
        Range = 4,
        Height = 0,
        UndergroundDepth = 20,
        -- Auto UG depth: one switch. A miss pushes the underground pose
        -- deeper (deeper = shallower under-map line for HBE) and it never comes
        -- back up, so it just settles past the depth where the under-shots
        -- start landing. Starts from the depth slider and works for the UG
        -- mode and the anti-ESP hide mode alike.
        AutoDepth = false,
        -- Cycles per second. Kept slow on purpose: the server validates a
        -- shot against the pose snapshot it holds when the remote arrives, and
        -- character replication only lands a snapshot every ~50ms. A fast
        -- orbit (the old default of 4 = ~128 studs/s) moves several studs
        -- between snapshots, so the shot origin no longer matches the pose the
        -- server checks -> invalid shots -> the failsafe drops the AA. At 1
        -- cycle/s the mismatch is under a stud, while the shape still reads
        -- clearly on the ghost.
        Speed = 1,
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
    -- Last offset actually applied (used to glide blocked-spot corrections
    -- instead of teleporting between safe-footing candidates).
    local smoothedOffset = nil
    local connections = {}
    local renderKey = "AdvancedAA_Restore_" .. tostring(LocalPlayer.UserId)

    local function now() return os.clock() end
    local function add(connection) table.insert(connections, connection) end

    -- Pose bookkeeping for the aim: when did the server last get each pose.
    local lastDisplacedAt, lastRealAt = 0, os.clock()
    -- Shot peek state.
    local peekUntil, peekStart = 0, 0
    local PEEK_MAX, PEEK_COOLDOWN = 0.8, 0.4
    -- Shot-pose freeze state (see AdvancedAAFreeze below).
    local freezeUntil, frozenRootCF = 0, nil
    -- Hidden-spot cache for anti-ESP (filled by HiddenOffset
    -- further down). Declared here so the bridge callbacks above and the UI
    -- callbacks below all share the same locals.
    local hiddenSpot, hiddenSpotAt, hiddenMode = nil, 0, ""
    -- Auto UG depth state (see AdvancedAAFeedback below). autoDepth overrides
    -- the slider while the feature is on.
    local autoDepth = nil
    local AUTO_DEPTH_STEP, AUTO_DEPTH_CAP = 3, 24

    -- Depth the underground pose / hide spot should use: the auto value when
    -- the feature is on, the slider otherwise.
    local function effectiveDepth()
        return math.clamp(autoDepth or settings.UndergroundDepth, 1, 30)
    end

    -- GetNetworkPing + pcall is not free and this is asked for on every
    -- ragebot tick and on every shot, while ping itself moves slowly: sample it
    -- a few times a second and reuse the value in between.
    local syncWindowAt, syncWindowValue = 0, 0.1
    local function syncWindow()
        local t = os.clock()
        if t - syncWindowAt < 0.1 then return syncWindowValue end
        local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
        ping = (ok and tonumber(ping)) or 0.1
        syncWindowValue = math.clamp(ping + 0.05, 0.08, 0.45)
        syncWindowAt = t
        return syncWindowValue
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
        if not settings.ShotPeek then return false end
        if not (settings.Enabled or settings.AntiESP) then return false end
        -- Square / prism must keep orbiting to stay useful, so a peek there
        -- only holds the real pose for one shot window (~latency + a frame)
        -- instead of the long UG cap. UG / anti-ESP poses are deliberately
        -- unshootable, so those keep the full cap.
        local cap = (settings.Underground or settings.AntiESP) and PEEK_MAX or 0.3
        local t = now()
        if t < peekUntil then
            -- Already peeking: extend, but never past the cap.
            if t - peekStart > cap then return false end
            peekUntil = math.max(peekUntil, math.min(t + seconds, peekStart + cap + 0.05))
            return true
        end
        if peekUntil > 0 and t - peekUntil < PEEK_COOLDOWN then return false end
        peekStart, peekUntil = t, t + seconds
        return true
    end

    -- Freeze the orbiting server pose at its current point for a moment.
    -- Only used when "smooth shots" is OFF: with it on, shot origins are
    -- built from the live pose at fire time and validated against the pose
    -- the server holds when the shot arrives (same one-way latency), so the
    -- orbit never has to stop for gunfire. The freeze remains as the
    -- stable-mode fallback: it re-asserts the exact pose the shot was built
    -- from (absolute, so walking does not slide it) until the shot has been
    -- validated. UG never needs it: its pose is static already.
    env.AdvancedAAFreeze = function(seconds)
        if not settings.Enabled or settings.SmoothShots then
            return false
        end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        if displaced then
            -- Body is currently IN the server pose: hold it where it stands.
            frozenRootCF = root.CFrame
        elseif serverTransform then
            -- Body is in the real pose: capture the pose the server holds.
            frozenRootCF = serverTransform * root.CFrame
        else
            return false
        end
        freezeUntil = math.max(freezeUntil, now() + (seconds or 0.15))
        return true
    end

    env.AdvancedAAPause = pauseAA
    env.AdvancedAAForceSync = forceSync
    -- Auto UG depth: the combat shot watcher reports every shot outcome while
    -- a displaced pose is active. A miss deepens the pose one step (capped),
    -- so it settles past the depth where the under-shots start landing.
    env.AdvancedAAFeedback = function(hit)
        if hit or not settings.AutoDepth then return end
        autoDepth = math.min((autoDepth or settings.UndergroundDepth) + AUTO_DEPTH_STEP,
            AUTO_DEPTH_CAP)
        hiddenSpot, hiddenSpotAt = nil, 0
    end
    -- Flag combat reads to keep the shot watcher running even with the
    -- failsafe off (see AAAutoDepthOn).
    env.AdvancedAAAutoDepth = false
    env.AdvancedAAStatus = function()
        return (settings.Enabled or settings.AntiESP) == true,
            serverOffset.Magnitude, now() < forceSyncUntil
    end
    -- Used by the aim: a moving square / prism keeps orbiting through a shot,
    -- so the aim must not park it on the first occluded frame (UG / anti-ESP
    -- poses are deliberately unshootable and still peek immediately).
    env.AdvancedAAIsOrbit = function()
        return settings.Enabled == true
            and (settings.Square or settings.Prism or settings.Omniscient)
            and not settings.Underground
            and not settings.AntiESP
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
        -- Traces the perimeter of a square (side 2, centred on the origin)
        -- in the XZ plane, clockwise. t in [0, 1) is one full loop.
        local p = (t % 1) * 4
        local edge = math.floor(p)
        local v = -1 + 2 * (p - edge)
        if edge == 0 then return Vector3.new(v, 0, -1) end
        if edge == 1 then return Vector3.new(1, 0, v) end
        if edge == 2 then return Vector3.new(-v, 0, 1) end
        return Vector3.new(-1, 0, -v)
    end

    -- Clockwise equilateral triangle (circumscribed radius 1) in the XZ
    -- plane: north -> south-east -> south-west -> back to north, the same
    -- winding direction as the square.
    local TRIANGLE_VERTICES = {
        Vector3.new(0, 0, -1),
        Vector3.new(0.8660254, 0, 0.5),
        Vector3.new(-0.8660254, 0, 0.5),
    }
    local function triangle(t)
        local p = (t % 1) * 3
        local edge = math.floor(p)
        local v0 = TRIANGLE_VERTICES[edge + 1]
        local v1 = TRIANGLE_VERTICES[(edge + 1) % 3 + 1]
        return v0:Lerp(v1, p - edge)
    end

    -- Anti-ESP hidden spot. Instead of a random far-away
    -- spoof, the pose everyone ELSE reads is parked inside solid geometry
    -- close to the real body, so their ESP box / chams sit inside a wall and
    -- their aimbot's visibility ray to the head is stopped by that same
    -- geometry. Three kinds, chosen by the "anti esp hide mode" dropdown:
    --   underground - straight down under the floor (always available);
    --   wall        - a ray is cast in eight horizontal directions and the
    --                 pose is dropped just inside the first solid part hit;
    --   far         - the old far-away under-map spoof, kept as a fallback.
    -- auto tries wall first, then underground, then far.
    local HIDDEN_DIRECTIONS = {
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        Vector3.new(0.7071, 0, 0.7071), Vector3.new(-0.7071, 0, 0.7071),
        Vector3.new(0.7071, 0, -0.7071), Vector3.new(-0.7071, 0, -0.7071),
    }
    local hiddenParams = RaycastParams.new()
    hiddenParams.FilterType = Enum.RaycastFilterType.Exclude
    hiddenParams.IgnoreWater = true

    -- The picked spot is held for AntiESPReroll seconds so the pose does not
    -- jitter every frame; it is re-picked on the timer or when the mode / the
    -- spot cache is invalidated by the toggles (see hiddenSpot above).
    local function HiddenOffset(root)
        local mode = settings.AntiESPMode
        local depth = effectiveDepth()
        if hiddenSpot and now() < hiddenSpotAt and mode == hiddenMode then
            return hiddenSpot
        end
        hiddenMode = mode
        hiddenSpotAt = now() + math.max(settings.AntiESPReroll, 0.5)

        -- 1) A nearby wall / building to sit inside.
        if mode == "wall" or mode == "auto" then
            hiddenParams.FilterDescendantsInstances = AAIgnoreList()
            local origin = root.Position
            for _, dir in ipairs(HIDDEN_DIRECTIONS) do
                local hit = workspace:Raycast(origin, dir * 60, hiddenParams)
                if hit and IsCover(hit.Instance) then
                    -- Centre the body inside the part when its thickness can
                    -- be measured, otherwise step a little past the surface so
                    -- the pose is never left floating in front of the wall.
                    local span = ExitDistance(hit.Instance, hit.Position, dir)
                    local inset = span and math.max(span * 0.5, 0.4) or 1.5
                    inset = math.min(inset, 8)
                    hiddenSpot = (hit.Position + dir * inset) - origin
                    return hiddenSpot
                end
            end
            -- "wall" mode with nothing nearby: still hide under the floor
            -- instead of leaving the pose out in the open.
            if mode == "wall" then
                hiddenSpot = Vector3.new(0, -depth, 0)
                return hiddenSpot
            end
        end
        -- 2) Straight down under the floor.
        if mode == "underground" or mode == "auto" then
            hiddenSpot = Vector3.new(0, -depth, 0)
            return hiddenSpot
        end
        -- 3) Fallback: the old far-away under-map spoof.
        local angle = math.random() * math.pi * 2
        hiddenSpot = Vector3.new(math.cos(angle), 0, math.sin(angle))
            * math.clamp(settings.AntiESPDistance, 5, 500)
            - Vector3.new(0, depth, 0)
        return hiddenSpot
    end

    -- Omniscient position: a random point on a sphere around the real root.
    -- Unlike square / prism this uses Y as well, so the server pose can sit
    -- above or below ground in any direction. A uniform point on the unit
    -- sphere is z uniform in [-1, 1] plus a uniform azimuth; the radius is
    -- sampled inside the range slider so the pose never leaves the allowed
    -- sphere. The point is held for OmniscientReroll seconds (the normal
    -- offset smoothing sweeps each jump over a few frames) instead of
    -- changing every frame, which would outrun the server snapshot and make
    -- every shot invalid.
    local omniDir = Vector3.new(0, 1, 0)
    local omniScale = 1
    local omniRerollAt = 0
    local function OmniscientOffset()
        if now() > omniRerollAt then
            local z = math.random() * 2 - 1
            local azimuth = math.random() * math.pi * 2
            local radial = math.sqrt(math.max(0, 1 - z * z))
            omniDir = Vector3.new(math.cos(azimuth) * radial, z,
                math.sin(azimuth) * radial)
            -- Anywhere inside the sphere, kept slightly off dead centre so
            -- the mode always desyncs the pose.
            omniScale = 0.35 + math.random() * 0.65
            omniRerollAt = now() + math.max(settings.OmniscientReroll, 0.1)
        end
        return omniDir * (math.max(settings.Range, 0) * omniScale)
    end

    local function calculateOffset(t)
        -- Anti-ESP takes priority: it parks the pose inside solid geometry, so
        -- it must NOT stack with the orbit shapes - a square / prism /
        -- omniscient offset would drag the body back out into the open and
        -- defeat the whole point.
        if settings.AntiESP then
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then return HiddenOffset(root) end
        end
        -- Anti-ESP character spoof: everything other clients see (ESP box,
        -- chams, their aimbot's target position) follows the pose the server
        -- holds, so displacing it breaks their lock. Our own shots are built
        -- from this pose too and flow through the peek machinery, so we keep
        -- hitting them while spoofed.
        local spoof = Vector3.zero
        -- Every AA mode now STACKS instead of one overriding the others:
        -- anti-ESP is the far horizontal centre, square and prism both add
        -- their horizontal paths, omniscient adds a random sphere point, the
        -- height slider lifts and UG drops. The two XZ shapes are averaged,
        -- so turning both on keeps the combined orbit inside the range
        -- slider instead of doubling it - the pose gets harder to predict
        -- without moving the shot origin further away. None of this changes
        -- the aim path itself: every shot is still built and validated from
        -- the exact pose the server holds.
        local shape, shapes = Vector3.zero, 0
        if settings.Square then
            shape += square(t)
            shapes += 1
        end
        if settings.Prism then
            shape += triangle(t)
            shapes += 1
        end
        if shapes > 0 then
            shape = shape * (math.max(settings.Range, 0) / shapes)
        end
        -- Omniscient is a random point on the same sphere, so it stacks with
        -- the XZ shapes instead of replacing them. The combined vector is
        -- clamped back onto the sphere surface: the pose never travels more
        -- than the range slider, no matter how many modes are enabled.
        if settings.Omniscient then
            shape += OmniscientOffset()
            local length = shape.Magnitude
            local range = math.max(settings.Range, 0)
            if length > range and length > 0.001 then
                shape = shape * (range / length)
            end
        end
        local lift = math.max(settings.Height or 0, 0)
        if settings.Underground and not settings.Omniscient then
            lift -= effectiveDepth()
        end
        return spoof + shape + Vector3.new(0, lift, 0)
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

    -- Safe-footing search order, used when the exact path point is blocked:
    -- nearby points on the same square / prism outline first (keeps the
    -- motion on the shape), then progressively shorter steps along the same
    -- direction. There is deliberately no vertical fallback: the shapes own
    -- X/Z, the height slider owns Y, and when even the shortest step is
    -- blocked the pose simply holds still for that frame (a still pose is
    -- always safe to shoot from).
    local SAFE_PATH_SHIFTS = { 0.06, -0.06, 0.13, -0.13, 0.28, -0.28, 0.5, -0.5 }
    local SAFE_PATH_SCALES = { 0.8, 0.6, 0.45, 0.3, 0.2, 0.1 }

    -- Moves the whole body by `transform` for the server only (restored
    -- before render, so the client never sees it).
    local function applyTransform(character, root, transform, offset, destination)
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

    -- Server-only root override (used by the invisible peek resolver). While
    -- set, the server sees the root at this CFrame no matter what UG / pauses
    -- / the failsafe are doing; the client body and camera stay put.
    local overrideRoot = nil
    env.AdvancedAASetOverride = function(cf)
        if typeof(cf) == "CFrame" then overrideRoot = cf else overrideRoot = nil end
    end

    -- Runs right after physics (PostSimulation) and again after Heartbeat.
    -- The path phase only advances on the first call of the frame so the
    -- movement speed still matches the slider.
    local applyServerPoseInner
    local function applyServerPose(dt, advance)
        applyServerPoseInner(dt, advance)
        if displaced then lastDisplacedAt = now() else lastRealAt = now() end
    end
    function applyServerPoseInner(dt, advance)
        restorePose()
        clearServerPose()
        if overrideRoot then
            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if root and humanoid and humanoid.Health > 0 then
                local transform = overrideRoot * root.CFrame:Inverse()
                applyTransform(character, root, transform,
                    overrideRoot.Position - root.Position, overrideRoot.Position)
            end
            return
        end
        if not settings.Enabled and not settings.AntiESP then return end
        if promptHeld then return end
        local hideActive = settings.AntiESP
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

        -- Shot-pose freeze: hold the exact pose an in-flight shot was built
        -- from until the shot has had time to reach the server and be
        -- validated. The peek / override paths above still win.
        if t < freezeUntil and frozenRootCF then
            local transform = frozenRootCF * root.CFrame:Inverse()
            applyTransform(character, root, transform,
                frozenRootCF.Position - root.Position, frozenRootCF.Position)
            return
        end

        if advance then
            phase = (phase + math.min(dt, 0.1) * settings.Speed) % 2
        end
        local offset = calculateOffset(phase)
        -- Safe footing is skipped for the hide mode: the anti-esp pose is
        -- DELIBERATELY inside the floor or a wall, so wall checks would
        -- only zero it out (the exact bug that used to kill square / prism
        -- indoors). Omniscient is skipped for the same reason: it is allowed to
        -- go below the floor and above the target.
        if settings.SafeFooting and not settings.Underground and not hideActive
            and not settings.Omniscient and offset.Magnitude > 0.001 then
            -- The old check shrank this single offset towards zero, so next
            -- to any wall (most of this map) the desync sat at 0 for nearly
            -- every frame and square / prism looked dead. The jitter is only
            -- dropped now when nothing free can be found at all.
            if not SpaceFree(root.Position + offset) then
                local picked = nil
                -- Nearby points on the same square / prism outline.
                for _, shift in ipairs(SAFE_PATH_SHIFTS) do
                    local alt = calculateOffset((phase + shift) % 2)
                    if alt.Magnitude > 0.001 and SpaceFree(root.Position + alt) then
                        picked = alt
                        break
                    end
                end
                -- Shorter steps along the same direction.
                if not picked then
                    for _, scale in ipairs(SAFE_PATH_SCALES) do
                        if SpaceFree(root.Position + offset * scale) then
                            picked = offset * scale
                            break
                        end
                    end
                end
                offset = picked or Vector3.zero
            end
        end
        -- Blocked-spot hops used to teleport the pose between safe-footing
        -- candidates, which read as crazy jitter on the server pose (what
        -- other players and the ghost see). The offset is now rate limited:
        -- normal path motion passes through untouched, while a teleport-scale
        -- jump is swept over a few frames at up to twice the normal speed.
        -- Hide modes snap instantly: rate limiting would sweep the pose out of
        -- the wall / floor it was just parked inside.
        if not hideActive and smoothedOffset and math.max(dt, 0) > 0 then
            local expectedStep = math.max(dt, 0) * settings.Speed * settings.Range * 8
            local maxDelta = expectedStep * 2 + 0.5
            local delta = offset - smoothedOffset
            if delta.Magnitude > maxDelta then
                offset = smoothedOffset + delta.Unit * maxDelta
            end
        end
        smoothedOffset = offset
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

        applyTransform(character, root, transform, offset, destination)
    end

    -- The displaced pose is asserted twice: right after the physics step
    -- (PostSimulation) and again after Heartbeat. The engine's character
    -- update flush point has moved around between versions, so both
    -- post-physics windows are covered; physics itself always simulates the
    -- real pose via the restores below (before the camera AND before the
    -- next step).
    add(RunService.PostSimulation:Connect(function(dt) applyServerPose(dt, true) end))
    add(RunService.Heartbeat:Connect(function(dt) applyServerPose(dt, false) end))
    -- Before the camera and render: real body back, so the client sees and
    -- the camera follows the real pose.
    RunService:BindToRenderStep(renderKey, Enum.RenderPriority.First.Value, restorePose)
    -- Before physics: always simulate the real pose.
    add(RunService.PreSimulation:Connect(restorePose))
    add(LocalPlayer.CharacterRemoving:Connect(function()
        restorePose()
        clearServerPose()
        freezeUntil, frozenRootCF = 0, nil
    end))

    -- Kept so omniscient can switch the UG modes off programmatically: once
    -- it is on, UG no longer has any job (omniscient already moves below and
    -- above ground) and the two would only fight over the Y axis.
    local undergroundToggle, ugHorizontalToggle, omniscientToggle

    local advancedToggle
    advancedToggle = section:Toggle({
        Name = "advanced aa", Flag = "advanced_aa_enabled", Default = false,
        Callback = function(value)
            settings.Enabled = value
            if not value then restorePose(); clearServerPose() end
        end,
    })
    -- Bridge so other features (and the peek resolver's own toggles) can switch
    -- the displacement on programmatically. This displacement is what actually
    -- makes incoming shots miss - a client-side CanQuery strip cannot.
    env.AdvancedAASetEnabled = function(value)
        if advancedToggle then advancedToggle:Set(value == true) end
    end
    section:Toggle({ Name = "square", Flag = "advanced_aa_square", Default = true,
        Callback = function(value) settings.Square = value end })
    section:Toggle({ Name = "prism", Flag = "advanced_aa_prism", Default = false,
        Callback = function(value) settings.Prism = value end })
    undergroundToggle = section:Toggle({
        Name = "underground", Flag = "advanced_aa_underground", Default = false,
        Callback = function(value)
            -- Omniscient covers above and below ground, so UG is redundant
            -- while it is on; turning UG on hands the Y axis back to it.
            if value and omniscientToggle and omniscientToggle.Value then
                omniscientToggle:Set(false)
            end
            settings.Underground = value
        end })
    ugHorizontalToggle = section:Toggle({ Name = "ug horizontal (right side up)", Flag = "advanced_aa_ughorizontal",
        Default = true,
        Callback = function(value) settings.HorizontalUG = value end })
    section:Toggle({ Name = "ug shot peek (fewer invalids)", Flag = "advanced_aa_shotpeek",
        Default = true,
        Callback = function(value) settings.ShotPeek = value; if not value then peekUntil = 0 end end })
    omniscientToggle = section:Toggle({
        Name = "omniscient aa (random sphere)", Flag = "advanced_aa_omniscient",
        Default = false,
        Callback = function(value)
            settings.Omniscient = value
            if value then
                -- Stacks with square / prism / anti esp on purpose, but UG
                -- and its horizontal roll are cancelled: this mode already
                -- travels above and below ground.
                if undergroundToggle then undergroundToggle:Set(false) end
                if ugHorizontalToggle then ugHorizontalToggle:Set(false) end
            end
        end })
    section:Slider({ Name = "omniscient reroll (s)", Flag = "advanced_aa_omniscient_reroll",
        Min = 0.1, Max = 5, Default = 0.75, Decimals = 0.05,
        Callback = function(value) settings.OmniscientReroll = value end })
    section:Toggle({ Name = "anti esp (hide in geometry)", Flag = "advanced_aa_antiesp",
        Default = false,
        Callback = function(value)
            settings.AntiESP = value
            hiddenSpot, hiddenSpotAt = nil, 0
            if not value and not settings.Enabled then
                restorePose()
                clearServerPose()
            end
        end })
    section:Dropdown({ Name = "anti esp hide mode", Flag = "advanced_aa_antiesp_mode",
        Items = { "auto", "underground", "wall", "far" }, Default = "auto",
        Callback = function(value)
            settings.AntiESPMode = value
            hiddenSpot, hiddenSpotAt = nil, 0
        end })
    section:Slider({ Name = "anti esp distance (studs, far mode)", Flag = "advanced_aa_antiesp_dist",
        Min = 10, Max = 300, Default = 60, Decimals = 5,
        Callback = function(value) settings.AntiESPDistance = value end })
    section:Slider({ Name = "anti esp reroll (s)", Flag = "advanced_aa_antiesp_reroll",
        Min = 0.5, Max = 10, Default = 3, Decimals = 0.5,
        Callback = function(value) settings.AntiESPReroll = value end })
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
    section:Toggle({ Name = "smooth shots (orbit never pauses)", Flag = "advanced_aa_smoothshots",
        Default = true,
        Callback = function(value)
            settings.SmoothShots = value
            if value then
                -- Kill any freeze left over from stable mode right away.
                freezeUntil, frozenRootCF = 0, nil
            end
        end })
    section:Slider({
        Name = "aa range (studs)", Flag = "advanced_aa_range",
        Min = 0, Max = 30, Default = 4, Decimals = 1,
        Callback = function(value) settings.Range = value end,
    })
    section:Slider({
        Name = "aa height (studs, Y)", Flag = "advanced_aa_height",
        Min = 0, Max = 30, Default = 0, Decimals = 1,
        Callback = function(value) settings.Height = value end,
    })
    section:Slider({
        Name = "underground depth (studs, Y)", Flag = "advanced_aa_ug_depth",
        Min = 1, Max = 25, Default = 20, Decimals = 1,
        Callback = function(value) settings.UndergroundDepth = value end,
    })
    section:Toggle({ Name = "auto ug depth (deepen on miss)", Flag = "advanced_aa_autodepth",
        Default = false,
        Callback = function(value)
            settings.AutoDepth = value
            env.AdvancedAAAutoDepth = value
            autoDepth = value and settings.UndergroundDepth or nil
            hiddenSpot, hiddenSpotAt = nil, 0
        end })
    section:Slider({
        Name = "aa speed (cycles/sec)", Flag = "advanced_aa_speed",
        -- High speeds still work as a desync, but the shot origin can no
        -- longer match the server's replication snapshot, so shots start
        -- going invalid and the failsafe drops the AA. 1 cycle/s is the
        -- tested default; the cap is 20 for experimentation.
        Min = 0.25, Max = 20, Default = 1, Decimals = 0.25,
        Callback = function(value) settings.Speed = value end,
    })

    env.AdvancedAACleanup = function()
        settings.Enabled = false
        settings.AutoDepth = false
        restorePose()
        clearServerPose()
        freezeUntil, frozenRootCF = 0, nil
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
        env.AdvancedAASetEnabled = nil
        env.AdvancedAAStatus = nil
        env.AdvancedAADesync = nil
        env.AdvancedAAOffset = nil
        env.AdvancedAAServerPosition = nil
        env.AdvancedAAUnshiftPosition = nil
        env.AdvancedAAShotState = nil
        env.AdvancedAASetOverride = nil
        overrideRoot = nil
        env.AdvancedAAPeek = nil
        env.AdvancedAAIsOrbit = nil
        env.AdvancedAAFeedback = nil
        env.AdvancedAAAutoDepth = nil
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


    --#region custom view model
    -- Client-only first-person view model: a copy of the gun you are holding
    -- plus arms, drawn in front of the camera. It appears only while a gun
    -- (ToolType == "Gun") is equipped and, because it is parented to the
    -- camera, it shows in third person too. Nothing here is replicated - the
    -- model lives on your client only.
    do
        local ViewModel = {
            Enabled = false,
            Offset = Vector3.new(0.55, -0.55, -1.3),   -- x right, y up, z back
            Rotation = Vector3.new(0, 0, 0),           -- pitch, yaw, roll (deg)
            Spin = 0,                                  -- deg/s, counter-clockwise (horizontal)
            Arms = true,
            Bob = true,
            BobAmount = 0.045,
            ReplaceFirstPerson = true,                 -- hide the default 1st-person model
            Chams = false,                             -- paint the whole model (gun + arms)
            ChamsColor = Color3.fromRGB(120, 200, 255),
            ChamsRainbow = false,
            ChamsRainbowSpeed = 0.2,
            ChamsMaterial = "Neon",
            ChamsTransparency = 0,
        }

        local ChamsMaterials = { "Neon", "ForceField", "Glass", "Solid" }
        local ChamsMaterialEnums = {
            Neon = Enum.Material.Neon,
            ForceField = Enum.Material.ForceField,
            Glass = Enum.Material.Glass,
            Solid = Enum.Material.SmoothPlastic,
        }

        local model
        local entries = {}
        local activeTool
        local pendingBuild = false
        local readyAt = 0
        local bobPhase = 0
        local spinAngle = 0
        local lastBase
        local MuzzleLocal

        -- Rotate a part so its local "axis" points along "d".
        local function alignAxis(localAxis, d)
            local dot = math.clamp(localAxis:Dot(d), -1, 1)
            if dot > 0.9999 then return CFrame.new() end
            if dot < -0.9999 then
                local perp = math.abs(localAxis.X) < 0.9 and Vector3.xAxis or Vector3.yAxis
                return CFrame.fromAxisAngle(localAxis:Cross(perp).Unit, math.pi)
            end
            return CFrame.fromAxisAngle(localAxis:Cross(d).Unit, math.acos(dot))
        end

        -- Stretch and aim a limb part so it spans from "from" to "to" and return
        -- its base-space CFrame. The size and orientation are constant for a
        -- given pose, so they are computed once here instead of every frame.
        local function prepareLimb(part, from, to)
            local dir = to - from
            local length = math.max(dir.Magnitude, 0.05)
            local d = (from - to).Unit
            local size = part.Size
            local ai, localAxis
            if size.Y >= size.X and size.Y >= size.Z then
                ai, localAxis = 2, Vector3.yAxis
            elseif size.X >= size.Z then
                ai, localAxis = 1, Vector3.xAxis
            else
                ai, localAxis = 3, Vector3.zAxis
            end
            if ai == 1 then
                part.Size = Vector3.new(length, size.Y, size.Z)
            elseif ai == 2 then
                part.Size = Vector3.new(size.X, length, size.Z)
            else
                part.Size = Vector3.new(size.X, size.Y, length)
            end
            return CFrame.new((from + to) * 0.5) * alignAxis(localAxis, d)
        end

        local function prepClone(clone, opaque)
            for _, child in ipairs(clone:GetChildren()) do
                if child:IsA("JointInstance") or child:IsA("WeldConstraint") then
                    child:Destroy()
                end
            end
            clone.Anchored = true
            clone.CanCollide = false
            clone.CanQuery = false
            clone.CanTouch = false
            clone.CastShadow = false
            clone.Massless = true
            clone.LocalTransparencyModifier = 0
            if opaque then clone.Transparency = 0 end
        end

        -- Chams: repaint a cloned part as a flat, glowing shell. Decals / mesh
        -- textures are stripped once so the colour reads clean, exactly like the
        -- tool-chams feature; the colour / material / transparency are re-applied
        -- every frame (see the render loop) so the colourpicker, transparency
        -- slider and rainbow all take effect without rebuilding the model.
        local function stripVisuals(part)
            for _, d in ipairs(part:GetDescendants()) do
                if d:IsA("Decal") or d:IsA("Texture") then
                    d.Transparency = 1
                elseif d:IsA("SpecialMesh") then
                    d.TextureId = ""
                elseif d:IsA("SurfaceAppearance") then
                    -- A SurfaceAppearance overrides Color / Material entirely, so
                    -- the cham colour would never show. Drop it for the shell.
                    d:Destroy()
                end
            end
            if part:IsA("MeshPart") then
                part.TextureID = ""
                local surface = part:FindFirstChildOfClass("SurfaceAppearance")
                if surface then surface:Destroy() end
            end
        end

        local function paintPart(part)
            part.Color = ViewModel.ChamsColor
            part.Material = ChamsMaterialEnums[ViewModel.ChamsMaterial] or Enum.Material.Neon
            part.Transparency = ViewModel.ChamsTransparency
        end

        local function addRigid(parent, clone, rel, opaque, arm)
            prepClone(clone, opaque)
            clone.Parent = parent
            entries[#entries + 1] = { kind = "rigid", part = clone, rel = rel, arm = arm }
            if ViewModel.Chams then stripVisuals(clone) end
        end

        local function addLimb(parent, clone, from, to, opaque, arm)
            prepClone(clone, opaque)
            clone.Parent = parent
            local localCF = prepareLimb(clone, from, to)
            entries[#entries + 1] = { kind = "limb", part = clone, localCF = localCF, arm = arm }
            if ViewModel.Chams then stripVisuals(clone) end
        end

        local function grab(name)
            local character = LocalPlayer.Character
            return character and character:FindFirstChild(name)
        end

        -- Arms are cloned from your own character (so they carry your skin /
        -- shirt) and posed to reach the gun's grip and foregrip.
        local function buildArms(parent)
            local rightUpper, rightLower, rightHand = grab("RightUpperArm"), grab("RightLowerArm"), grab("RightHand")
            local leftUpper, leftLower, leftHand = grab("LeftUpperArm"), grab("LeftLowerArm"), grab("LeftHand")
            local rShoulder = Vector3.new(0.75, -0.85, 1.25)
            local rElbow = Vector3.new(0.55, -0.95, 0.45)
            local rHand = Vector3.new(0.06, -0.12, -0.10)
            local lShoulder = Vector3.new(-0.75, -0.85, 1.25)
            local lElbow = Vector3.new(-0.55, -0.95, 0.45)
            local lHand = Vector3.new(-0.06, -0.18, -1.00)
            if rightUpper and leftUpper then
                addLimb(parent, rightUpper:Clone(), rShoulder, rElbow, true, true)
                if rightLower then addLimb(parent, rightLower:Clone(), rElbow, rHand, true, true) end
                if rightHand then addRigid(parent, rightHand:Clone(), CFrame.new(rHand), true, true) end
                addLimb(parent, leftUpper:Clone(), lShoulder, lElbow, true, true)
                if leftLower then addLimb(parent, leftLower:Clone(), lElbow, lHand, true, true) end
                if leftHand then addRigid(parent, leftHand:Clone(), CFrame.new(lHand), true, true) end
                return
            end
            local rArm, lArm = grab("Right Arm"), grab("Left Arm")
            if rArm then addLimb(parent, rArm:Clone(), rShoulder, rHand, true, true) end
            if lArm then addLimb(parent, lArm:Clone(), lShoulder, lHand, true, true) end
        end

        local function teardown()
            if model then
                model:Destroy()
                model = nil
            end
            table.clear(entries)
            lastBase = nil
        end

        -- Muzzle point: the forward-most corner of any gun part, in the model's
        -- own base space (the frame the entries are posed against). Tracers and
        -- the flash start here.
        local function computeMuzzle()
            MuzzleLocal = nil
            local best = math.huge
            for _, entry in ipairs(entries) do
                if not entry.arm and entry.rel then
                    local h = entry.part.Size * 0.5
                    for ix = -1, 1, 2 do
                        for iy = -1, 1, 2 do
                            for iz = -1, 1, 2 do
                                local p = entry.rel * Vector3.new(h.X * ix, h.Y * iy, h.Z * iz)
                                if p.Z < best then
                                    best = p.Z
                                    MuzzleLocal = p
                                end
                            end
                        end
                    end
                end
            end
        end

        local function build(tool)
            teardown()
            local camera = workspace.CurrentCamera
            local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart"))
            if not camera or not handle then return end
            local origin = handle.CFrame
            local holder = Instance.new("Model")
            holder.Name = "CustomViewModel"
            for _, obj in ipairs(tool:GetDescendants()) do
                if obj:IsA("BasePart") then
                    addRigid(holder, obj:Clone(), origin:Inverse() * obj.CFrame, false, false)
                end
            end
            if ViewModel.Arms then buildArms(holder) end
            computeMuzzle()
            holder.Parent = camera
            model = holder
        end

        local function equippedGun()
            local character = LocalPlayer.Character
            local tool = character and character:FindFirstChildOfClass("Tool")
            if tool and tool:GetAttribute("ToolType") == "Gun" then return tool end
            return nil
        end

        -- The camera can be swapped on respawn; drop the model so it is rebuilt
        -- under the new camera (a camera-parented model dies with its parent).
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            teardown()
            activeTool = nil
            pendingBuild = false
        end)

        -- Replace the default first-person view model. Roblox's camera draws your
        -- own arms and the equipped tool's handle in first person; when the custom
        -- model is active we hide those parts (LocalTransparencyModifier = 1) so
        -- they no longer fill the screen. The camera rewrites that modifier every
        -- frame, so this runs in a render step ordered just after it, and the
        -- values are put back as soon as we leave first person (or the model is
        -- switched off) so third person and the normal body stay intact.
        local hiddenParts = {}
        -- The camera rewrites LocalTransparencyModifier every frame, so the body
        -- parts have to be re-hidden every frame. Rebuilding that list every frame
        -- meant a GetDescendants() allocation per call, so it is cached and only
        -- refreshed when the body or the equipped tool actually changes.
        local hideList = {}
        local hideListNext = 0
        local hideListCharacter, hideListTool

        local function restoreHidden()
            for part in pairs(hiddenParts) do
                -- Only BaseParts carry LocalTransparencyModifier. Touching any other
                -- descendant used to throw, which aborted the loop, left the table
                -- half-cleared and so re-threw every single frame.
                if part:IsA("BasePart") and part.Parent and part.LocalTransparencyModifier ~= 0 then
                    part.LocalTransparencyModifier = 0
                end
                hiddenParts[part] = nil
            end
        end

        -- True only while the camera is actually in first person. The default
        -- camera keeps Camera.Focus on the point it orbits: in first person the
        -- camera sits right on that focus (zoom ~0.5 studs), while third person
        -- is always further out. Measuring the zoom cleanly separates the two,
        -- which a fixed distance-to-head test cannot do (the head sits ~1.5 studs
        -- off the camera even in first person, so it overlaps close third person).
        local function isFirstPerson()
            local camera = workspace.CurrentCamera
            local character = LocalPlayer.Character
            if not camera or not character then return false end
            local head = character:FindFirstChild("Head")
            if not head then return false end

            local focus = camera.Focus
            local zoom = (camera.CFrame.Position - focus.Position).Magnitude
            -- Only trust the zoom when the focus is genuinely on this character
            -- (a custom camera may leave Focus stale).
            if (focus.Position - head.Position).Magnitude < 10 then
                return zoom < 1.5
            end
            return (camera.CFrame.Position - head.Position).Magnitude < 1.0
        end

        -- When a gun was last equipped. The auto weapon switcher briefly leaves the
        -- character with no tool between guns, so the body has to stay hidden across
        -- that gap instead of flashing back on (and blocking the view) each swap.
        local lastGunAt = 0

        local function wantsDefaultHidden()
            if not (ViewModel.Enabled and ViewModel.ReplaceFirstPerson and isFirstPerson()) then
                return false
            end
            -- A pending build still counts as "replacing": the model is torn down
            -- and rebuilt after every weapon swap, and the body must not reappear
            -- during that window.
            if activeTool ~= nil or pendingBuild then return true end
            return os.clock() - lastGunAt < 0.6
        end

        local function hideDefault()
            local character = LocalPlayer.Character
            if not character then return end
            local tool = character:FindFirstChildOfClass("Tool")
            local now = os.clock()
            if now >= hideListNext or hideListCharacter ~= character or hideListTool ~= tool then
                hideListNext = now + 0.25
                hideListCharacter = character
                hideListTool = tool
                table.clear(hideList)
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then hideList[#hideList + 1] = part end
                end
                if tool then
                    for _, part in ipairs(tool:GetDescendants()) do
                        if part:IsA("BasePart") then hideList[#hideList + 1] = part end
                    end
                end
                -- Some games draw their own first-person model as a child of the
                -- camera. Hide any such model too, but never our own.
                local camera = workspace.CurrentCamera
                if camera then
                    for _, obj in ipairs(camera:GetChildren()) do
                        if obj ~= model then
                            if obj:IsA("BasePart") then
                                hideList[#hideList + 1] = obj
                            elseif obj:IsA("Model") then
                                for _, part in ipairs(obj:GetDescendants()) do
                                    if part:IsA("BasePart") then hideList[#hideList + 1] = part end
                                end
                            end
                        end
                    end
                end
            end
            for _, part in ipairs(hideList) do
                if part.Parent and part.LocalTransparencyModifier ~= 1 then
                    part.LocalTransparencyModifier = 1
                end
                hiddenParts[part] = true
            end
        end

        local function updateFirstPersonReplace()
            if wantsDefaultHidden() then
                hideDefault()
            elseif next(hiddenParts) then
                restoreHidden()
            end
        end

        -- The camera rewrites LocalTransparencyModifier every frame, so this runs
        -- right after the camera's own step. It is also run on the very last event
        -- before the frame is drawn (PreRender, falling back to RenderStepped) so
        -- nothing can re-show the body after us.
        RunService:BindToRenderStep("ViewModelHideDefault", Enum.RenderPriority.Camera.Value + 1, updateFirstPersonReplace)
        if RunService.PreRender then
            RunService.PreRender:Connect(updateFirstPersonReplace)
        else
            RunService.RenderStepped:Connect(updateFirstPersonReplace)
        end

        RunService.RenderStepped:Connect(function(dt)
            local gun = ViewModel.Enabled and equippedGun() or nil
            if gun then
                lastGunAt = os.clock()
                if gun ~= activeTool then
                    -- Keep the old model on screen until the new one is built, so a
                    -- weapon swap never flashes an empty first-person view (and the
                    -- body never gets a chance to reappear).
                    activeTool = gun
                    pendingBuild = true
                    -- Let the equipped tool's welds settle before cloning it.
                    readyAt = os.clock() + 0.1
                end
            elseif not ViewModel.Enabled or os.clock() - lastGunAt > 0.4 then
                -- View model switched off, or the gun has been gone long enough to
                -- count as holstered: drop the model. A brief no-tool moment between
                -- two guns does not tear it down.
                if activeTool ~= nil or model then
                    activeTool = nil
                    teardown()
                    pendingBuild = false
                end
            end
            if pendingBuild and activeTool and os.clock() >= readyAt then
                build(activeTool)
                pendingBuild = false
            end
            if not (ViewModel.Enabled and model and activeTool) then return end
            local camera = workspace.CurrentCamera
            if not camera then return end
            if model.Parent ~= camera then model.Parent = camera end

            local step = math.clamp(dt or 0.016, 0, 0.1)
            if ViewModel.Spin ~= 0 then
                spinAngle = (spinAngle + step * ViewModel.Spin) % 360
            elseif spinAngle ~= 0 then
                -- Spin switched off: ease back to the original (un-spun) pose so
                -- the model always ends up exactly where it started.
                local delta = ((0 - spinAngle + 180) % 360) - 180
                if math.abs(delta) < 0.5 then
                    spinAngle = 0
                else
                    spinAngle = (spinAngle + delta * math.min(step * 8, 1)) % 360
                end
            end
            local base = camera.CFrame
                * CFrame.new(ViewModel.Offset)
                -- Horizontal spin: yaw about the model's vertical axis, so it
                -- always turns counter-clockwise as seen from above.
                * CFrame.Angles(0, math.rad(spinAngle), 0)
                * CFrame.Angles(math.rad(ViewModel.Rotation.X), math.rad(ViewModel.Rotation.Y), math.rad(ViewModel.Rotation.Z))
            lastBase = base

            if ViewModel.Bob then
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local move = humanoid and humanoid.MoveDirection.Magnitude or 0
                bobPhase += step * (7 + move * 5)
                local amount = ViewModel.BobAmount * move
                base = base * CFrame.new(math.sin(bobPhase) * amount, -math.abs(math.cos(bobPhase)) * amount, 0)
                    * CFrame.Angles(0, math.sin(bobPhase) * amount * 0.4, -math.sin(bobPhase) * amount * 0.4)
            end

            local paint = ViewModel.Chams
            if paint and ViewModel.ChamsRainbow then
                local h, s, v = ViewModel.ChamsColor:ToHSV()
                ViewModel.ChamsColor = Color3.fromHSV((h + step * ViewModel.ChamsRainbowSpeed) % 1, s, v)
            end

            for _, entry in ipairs(entries) do
                if entry.kind == "limb" then
                    entry.part.CFrame = base * entry.localCF
                else
                    entry.part.CFrame = base * entry.rel
                end
                if paint then paintPart(entry.part) end
            end
        end)


        -- The barrel's world CFrame while the view model is drawn, else nil. The
        -- snap line reads this (through the ViewModelMuzzle forward declaration)
        -- to start at the gun barrel instead of the crosshair.
        local function currentMuzzle()
            if ViewModel.Enabled and model and activeTool and lastBase then
                return lastBase * CFrame.new(MuzzleLocal or Vector3.new(0, 0, -1))
            end
            return nil
        end
        ViewModelMuzzle = currentMuzzle

        -- Called from the shot paths (see the forward declaration near the top of
        -- the file). In first person the tracer starts at the view model's
        -- barrel (it sits on the camera, so that is where the gun looks like it
        -- is); in third person it starts at the body, because the view model is
        -- drawn at the camera and a tracer from it would hang in the air next to
        -- the character. The muzzle flash is deliberately not drawn here - see
        -- the "remove muzzle flash" feature further down.
        ViewModelShot = function(hitPoint, fallbackOrigin)
            if not TracerEnabled or typeof(hitPoint) ~= "Vector3" then return end
            local from
            if isFirstPerson() then
                local muzzle = currentMuzzle()
                if muzzle then from = muzzle.Position end
            end
            if not from then
                local character = LocalPlayer.Character
                local head = character and character:FindFirstChild("Head")
                if head then from = AARealPartPosition(head) end
            end
            if not from then from = fallbackOrigin end
            if typeof(from) == "Vector3" then
                CreateTracer(from, hitPoint, Vector3.zero)
            end
        end

        Sections.visuals:Toggle({
            Name = "custom view model"; Flag = "viewmodel"; Default = false;
            Callback = function(v)
                ViewModel.Enabled = v
            end
        })
        Sections.visuals:Toggle({
            Name = "replace first person model"; Flag = "viewmodelreplace"; Default = true;
            Callback = function(v) ViewModel.ReplaceFirstPerson = v end
        })
        Sections.visuals:Slider({
            Name = "view model x"; Flag = "viewmodelx"; Min = -3; Max = 3; Default = 0.55; Decimals = 0.05;
            Callback = function(v) ViewModel.Offset = Vector3.new(v, ViewModel.Offset.Y, ViewModel.Offset.Z) end
        })
        Sections.visuals:Slider({
            Name = "view model y"; Flag = "viewmodely"; Min = -3; Max = 3; Default = -0.55; Decimals = 0.05;
            Callback = function(v) ViewModel.Offset = Vector3.new(ViewModel.Offset.X, v, ViewModel.Offset.Z) end
        })
        Sections.visuals:Slider({
            Name = "view model z (fwd)"; Flag = "viewmodelz"; Min = -4; Max = 0; Default = -1.3; Decimals = 0.05;
            Callback = function(v) ViewModel.Offset = Vector3.new(ViewModel.Offset.X, ViewModel.Offset.Y, v) end
        })
        Sections.visuals:Slider({
            Name = "view model pitch"; Flag = "viewmodelpitch"; Min = -180; Max = 180; Default = 0; Decimals = 1;
            Callback = function(v) ViewModel.Rotation = Vector3.new(v, ViewModel.Rotation.Y, ViewModel.Rotation.Z) end
        })
        Sections.visuals:Slider({
            Name = "view model yaw"; Flag = "viewmodelyaw"; Min = -180; Max = 180; Default = 0; Decimals = 1;
            Callback = function(v) ViewModel.Rotation = Vector3.new(ViewModel.Rotation.X, v, ViewModel.Rotation.Z) end
        })
        Sections.visuals:Slider({
            Name = "view model roll"; Flag = "viewmodelroll"; Min = -180; Max = 180; Default = 0; Decimals = 1;
            Callback = function(v) ViewModel.Rotation = Vector3.new(ViewModel.Rotation.X, ViewModel.Rotation.Y, v) end
        })
        Sections.visuals:Slider({
            Name = "view model spin (deg/s, ccw)"; Flag = "viewmodelspin"; Min = 0; Max = 720; Default = 0; Decimals = 1;
            Callback = function(v) ViewModel.Spin = v end
        })
        Sections.visuals:Toggle({
            Name = "view model arms"; Flag = "viewmodelarms"; Default = true;
            Callback = function(v)
                ViewModel.Arms = v
                activeTool = nil   -- force a rebuild so the arms appear / vanish now
            end
        })
        Sections.visuals:Toggle({
            Name = "view model bob"; Flag = "viewmodelbob"; Default = true;
            Callback = function(v) ViewModel.Bob = v end
        })
        Sections.visuals:Slider({
            Name = "view model bob amount"; Flag = "viewmodelbobamt"; Min = 0; Max = 0.2; Default = 0.045; Decimals = 0.005;
            Callback = function(v) ViewModel.BobAmount = v end
        })
        Sections.visuals:Toggle({
            Name = "view model chams"; Flag = "viewmodelchams"; Default = false;
            Callback = function(v)
                ViewModel.Chams = v
                activeTool = nil   -- rebuild so the model repaints now
            end
        })
        Sections.visuals:Label({Name = "view model chams color"}):Colorpicker({
            Name = "view model chams color"; Flag = "viewmodelchamscolor";
            Default = ViewModel.ChamsColor;
            Callback = function(v) ViewModel.ChamsColor = v end
        })
        Sections.visuals:Toggle({
            Name = "view model chams rainbow"; Flag = "viewmodelchamsrainbow"; Default = false;
            Callback = function(v) ViewModel.ChamsRainbow = v end
        })
        Sections.visuals:Slider({
            Name = "view model chams rainbow speed"; Flag = "viewmodelchamsrainbowspeed";
            Min = 0.05; Max = 1; Default = ViewModel.ChamsRainbowSpeed; Decimals = 0.01;
            Callback = function(v) ViewModel.ChamsRainbowSpeed = v end
        })
        Sections.visuals:Dropdown({
            Name = "view model chams material"; Flag = "viewmodelchamsmat";
            Items = ChamsMaterials; Default = "Neon";
            Callback = function(v) ViewModel.ChamsMaterial = v end
        })
        Sections.visuals:Slider({
            Name = "view model chams transparency"; Flag = "viewmodelchamstrans"; Min = 0; Max = 1; Default = 0; Decimals = 0.05;
            Callback = function(v) ViewModel.ChamsTransparency = v end
        })
    end
    --#endregion


    --#region muzzle flash removal
    -- Strips the game's own muzzle flash from your equipped gun, client-side.
    -- There is no single documented instance name, so it works by behaviour: on
    -- a gun, any Light is kept off, and any part / emitter whose name contains
    -- "muzzle", "flash" or "blast" is hidden. The few relevant properties are
    -- watched so a flash the game turns on per shot is killed the instant it
    -- happens instead of waiting for a poll. Nothing here replicates - it
    -- changes only what you see.
    do
        local MuzzleScrub = { Enabled = true }
        local WORDS = { "muzzle", "flash", "blast" }
        local watched = WeakKeyedTable()

        local function looksLikeMuzzle(name)
            local lower = string.lower(name)
            for _, word in ipairs(WORDS) do
                if string.find(lower, word, 1, true) then return true end
            end
            return false
        end

        local function watch(inst, prop, enforce)
            if watched[inst] then return end
            watched[inst] = true
            inst:GetPropertyChangedSignal(prop):Connect(function()
                if MuzzleScrub.Enabled then enforce() end
            end)
        end

        local function scrub(inst, isGun)
            if not MuzzleScrub.Enabled then return end
            if inst:IsA("Light") then
                -- Only lights on guns are muzzle flashes; a light on any other
                -- tool is left alone.
                if not isGun then return end
                inst.Enabled = false
                watch(inst, "Enabled", function() inst.Enabled = false end)
            elseif inst:IsA("BasePart") and looksLikeMuzzle(inst.Name) then
                inst.Transparency = 1
                inst.CanQuery = false
                inst.CanTouch = false
                watch(inst, "Transparency", function()
                    if inst.Transparency < 1 then inst.Transparency = 1 end
                end)
            elseif inst:IsA("ParticleEmitter") and looksLikeMuzzle(inst.Name) then
                inst.Enabled = false
                watch(inst, "Enabled", function() inst.Enabled = false end)
            elseif (inst:IsA("Beam") or inst:IsA("Trail")) and looksLikeMuzzle(inst.Name) then
                inst.Enabled = false
                watch(inst, "Enabled", function() inst.Enabled = false end)
            end
        end

        local function scrubTool(tool)
            if not tool or not tool:IsA("Tool") then return end
            local isGun = tool:GetAttribute("ToolType") == "Gun"
            scrub(tool, isGun)
            for _, d in ipairs(tool:GetDescendants()) do scrub(d, isGun) end
            if not watched[tool] then
                watched[tool] = true
                tool.DescendantAdded:Connect(function(d) scrub(d, isGun) end)
            end
        end

        local function equippedTool()
            local character = LocalPlayer.Character
            return character and character:FindFirstChildOfClass("Tool")
        end

        local function rearm()
            scrubTool(equippedTool())
        end

        local function bindCharacter(character)
            if not character then return end
            character.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then scrubTool(child) end
            end)
        end

        bindCharacter(LocalPlayer.Character)
        LocalPlayer.CharacterAdded:Connect(bindCharacter)

        -- Fallback re-arm: covers a gun already equipped at load time and any
        -- path that does not raise ChildAdded (for example the tool type
        -- attribute being set a moment after the tool is parented).
        task.spawn(function()
            while true do
                task.wait(0.5)
                if MuzzleScrub.Enabled then rearm() end
            end
        end)

        Sections.visuals:Toggle({
            Name = "remove muzzle flash";
            Flag = "nomuzzle";
            Default = true;
            Callback = function(v)
                MuzzleScrub.Enabled = v
                if v then rearm() end
            end
        })
    end
    --#endregion


--#region bullet tracer removal
-- Hides the game's own bullet tracers, client-side, while leaving ours alone.
-- The game draws tracers as parts / beams / trails / emitters whose names
-- describe them; there is no single documented instance, so it works by
-- keyword the same way the muzzle-flash remover does. Our own tracer geometry
-- carries the NegrohaxTracer attribute (and its children inherit that), so it
-- is never touched. Only the few properties that make a tracer visible are
-- enforced, and they are watched so a tracer the game turns on per shot is
-- killed the instant it appears. Nothing here replicates.
do
    local TracerScrub = { Enabled = true }
    local WORDS = { "tracer", "bullet", "projectile", "slug", "laser" }
    local watched = WeakKeyedTable()

    local function looksLikeTracer(name)
        local lower = string.lower(name)
        for _, word in ipairs(WORDS) do
            if string.find(lower, word, 1, true) then return true end
        end
        return false
    end

    -- Anything under one of our own tagged tracers (a node's beam, the head's
    -- trail) counts as ours too.
    local function isOurs(inst)
        local node = inst
        for _ = 1, 3 do
            if not node then break end
            if node:GetAttribute("NegrohaxTracer") then return true end
            node = node.Parent
        end
        return false
    end

    local function watch(inst, prop, enforce)
        if watched[inst] then return end
        watched[inst] = true
        inst:GetPropertyChangedSignal(prop):Connect(function()
            if TracerScrub.Enabled then enforce() end
        end)
    end

    local function scrub(inst)
        if not TracerScrub.Enabled then return end
        if isOurs(inst) then return end
        if not looksLikeTracer(inst.Name) then return end
        if inst:IsA("BasePart") then
            inst.Transparency = 1
            inst.CanQuery = false
            inst.CanTouch = false
            watch(inst, "Transparency", function()
                if inst.Transparency < 1 then inst.Transparency = 1 end
            end)
        elseif inst:IsA("ParticleEmitter") or inst:IsA("Beam")
            or inst:IsA("Trail") then
            inst.Enabled = false
            watch(inst, "Enabled", function() inst.Enabled = false end)
        end
    end

    local function sweep()
        for _, inst in ipairs(workspace:GetDescendants()) do
            scrub(inst)
        end
    end

    local connection
    local function setEnabled(enabled)
        TracerScrub.Enabled = enabled
        if connection then
            connection:Disconnect()
            connection = nil
        end
        if enabled then
            sweep()
            connection = workspace.DescendantAdded:Connect(function(inst)
                if TracerScrub.Enabled then scrub(inst) end
            end)
        end
    end

    setEnabled(true)

    Sections.visuals:Toggle({
        Name = "remove game tracers";
        Flag = "notracers";
        Default = true;
        Callback = function(v) setEnabled(v) end
    })
end
--#endregion


--#region kill feed
-- Client-side kill feed drawn as our own ScreenGui (never the game's UI). Every
-- death we can see is listed: kills we landed are highlighted and pop a small
-- burst at the victim, everyone else's deaths are listed plainly. The hook that
-- feeds it lives with the hit detection (PushKillFeed, forward-declared).
do
    local TweenService = game:GetService("TweenService")

    local KillFeed = {
        Enabled = true,
        Duration = 6,
        Max = 6,
        Color = Color3.fromRGB(235, 235, 240),
        KillColor = Color3.fromRGB(255, 90, 120),
        Effect = true,
    }

    local gui = Instance.new("ScreenGui")
    gui.Name = "NegrohaxKillFeed"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 10000
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local holder = Instance.new("Frame")
    holder.Name = "Feed"
    holder.AnchorPoint = Vector2.new(1, 0)
    holder.Position = UDim2.new(1, -14, 0, 88)
    holder.Size = UDim2.new(0, 320, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.Parent = gui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Parent = holder

    local live = {}
    local order = 0

    local function removeEntry(entry)
        for i = #live, 1, -1 do
            if live[i] == entry then
                table.remove(live, i)
                break
            end
        end
        entry.alive = false
        if entry.gui then entry.gui:Destroy() end
    end

    local function push(text, color)
        if not KillFeed.Enabled then return end
        order += 1
        local row = Instance.new("TextLabel")
        row.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.AutomaticSize = Enum.AutomaticSize.X
        row.Size = UDim2.new(0, 0, 0, 22)
        row.LayoutOrder = order
        row.Font = Enum.Font.GothamMedium
        row.TextSize = 14
        row.TextColor3 = color
        row.TextTransparency = 1
        row.Text = "  " .. text .. "  "
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.Parent = holder

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = row

        local stroke = Instance.new("UIStroke")
        stroke.Color = color
        stroke.Transparency = 1
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = row

        TweenService:Create(row, TweenInfo.new(0.18), {
            TextTransparency = 0,
            BackgroundTransparency = 0.15,
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), { Transparency = 0.35 }):Play()

        local entry = { gui = row, alive = true }
        live[#live + 1] = entry
        while #live > KillFeed.Max do removeEntry(live[1]) end

        task.delay(KillFeed.Duration, function()
            if not entry.alive then return end
            entry.alive = false
            TweenService:Create(row, TweenInfo.new(0.35), {
                TextTransparency = 1,
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.35), { Transparency = 1 }):Play()
            task.wait(0.35)
            removeEntry(entry)
        end)
    end

    local function killEffect(position)
        if not KillFeed.Effect or typeof(position) ~= "Vector3" then return end
        local anchor = Instance.new("Part")
        anchor.Name = "NegrohaxKillFX"
        anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
        anchor.Transparency = 1
        anchor.Size = Vector3.new(0.2, 0.2, 0.2)
        anchor.CFrame = CFrame.new(position)
        anchor.Parent = workspace
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxassetid://243660364"
        emitter.Color = ColorSequence.new(KillFeed.KillColor)
        emitter.LightEmission = 1
        emitter.Size = NumberSequence.new(0.7)
        emitter.Transparency = NumberSequence.new(0)
        emitter.Lifetime = NumberRange.new(0.5, 0.95)
        emitter.Speed = NumberRange.new(14, 26)
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.Rate = 0
        emitter.Parent = anchor
        emitter:Emit(45)
        task.delay(1.4, function()
            if anchor.Parent then anchor:Destroy() end
        end)
    end

    PushKillFeed = function(victim, ours)
        if not KillFeed.Enabled then return end
        local name = victim and victim.Name or "?"
        local character = victim and victim.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if ours then
            push("You killed " .. name, KillFeed.KillColor)
            if root then killEffect(root.Position) end
        else
            push(name .. " died", KillFeed.Color)
        end
    end

    -- Our own death is not covered by the per-player hook (it skips the local
    -- player), so it is reported here.
    local function watchSelf(character)
        if not character then return end
        task.spawn(function()
            local humanoid = character:WaitForChild("Humanoid", 10)
            if not humanoid then return end
            humanoid.Died:Connect(function()
                if KillFeed.Enabled then push("You died", Color3.fromRGB(255, 255, 255)) end
            end)
        end)
    end
    watchSelf(LocalPlayer.Character)
    LocalPlayer.CharacterAdded:Connect(watchSelf)

    Sections.hit:Toggle({
        Name = 'kill feed';
        Flag = 'killfeed';
        Default = true;
        Callback = function(v)
            KillFeed.Enabled = v
            if not v then
                for i = #live, 1, -1 do removeEntry(live[i]) end
            end
        end
    })

    Sections.hit:Toggle({
        Name = 'kill feed effect';
        Flag = 'killfeedfx';
        Default = true;
        Callback = function(v) KillFeed.Effect = v end
    })

    Sections.hit:Slider({
        Name = 'kill feed duration (s)';
        Flag = 'killfeedduration';
        Min = 2; Max = 15; Default = 6; Decimals = 0.5;
        Callback = function(v) KillFeed.Duration = v end
    })
end
--#endregion


Window:InitWindow()
