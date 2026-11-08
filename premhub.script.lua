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
    local Players = game.Players 
    local LocalPlayer = Players.LocalPlayer 
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local Teams = game:GetService("Teams")
    local SoundService = game:GetService("SoundService")

    local Modules = { -- Modules.

    };

    local Remotes = {
        ShootEvent = ReplicatedStorage.GunRemotes.ShootEvent;
    };

    local cheatinfo = {
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

    local SelectedTracer = "Laser 1";

    local Trails = {
        ["Laser 1"] = { Texture = "rbxassetid://7136858729", Width0 = 0.4, Width1 = 0.4, TextureLength = 1, Lifetime = 1 };
        ["Laser 2"] = { Texture = "rbxassetid://6333823534", Width0 = 0.4, Width1 = 0.4, TextureLength = 1, Lifetime = 1 };
        ["DNA"] = { Texture = "rbxassetid://7071778278", Width0 = 0.6, Width1 = 0.6, TextureLength = 12, Lifetime = 1 };
        ["Energy"]  = { Texture = "rbxassetid://5864341017", Width0 = 0.4, Width1 = 0.4, TextureLength = 1, Lifetime = 1 };
    };
--#endregion



--#region library setup
    --local amity = loadstring(game:HttpGet('https://raw.githubusercontent.com/78n/Roblox/refs/heads/main/Lua/Libraries/DataToCode/DataToCode.luau'))()

    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/skekkstunsua-lgtm/von/refs/heads/main/BullshitLib.lua"))()
    
    local EspLib = loadstring(game:HttpGet('https://github.com/skekkstunsua-lgtm/von/raw/refs/heads/main/EspLib.lua'))()

    local Window = Library:Window({
        Name = 'negrohaxprism<font color="rgb(126, 192, 255)">.cc</font> | developer  | lifetime',
        Rank = "developer"
    }) 

    do
        local Watermark = Window:Watermark({
            Name = "negrohax.cc",
            SubName = "negrohax.cc"
        })

        local KeybindList = Window:KeybindList({
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
local ResolverSnapshot = nil
local ResolverRunning = false
local function ReportTarget(part)
    local model = part and part:FindFirstAncestorOfClass("Model")
    local plr = model and Players:GetPlayerFromCharacter(model)
    if plr then CurrentTargetPlayer, CurrentTargetTime = plr, os.clock() end
end

local PriorityTeamCheck = true
local function TeamRole(player)
    local name = player.Team and string.lower(player.Team.Name) or ""
    if name:find("guard", 1, true) or name:find("police", 1, true) then return "police" end
    if name:find("crim", 1, true) then return "criminal" end
    if name:find("inmate", 1, true) or name:find("prisoner", 1, true) then return "prisoner" end
    return "unknown"
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

local function AAOffset()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAOffset) == "function" then
        local ok, value = pcall(env.AdvancedAAOffset)
        if ok and typeof(value) == "Vector3" then return value end
    end
    return Vector3.zero
end

local function PauseAAForAction(seconds)
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if type(env.AdvancedAAPause) == "function" then
        env.AdvancedAAPause(seconds or 0.2)
    end
end


-- Target panel. Resolver labels describe heuristics, not proof of cheating.
do
    local old = LocalPlayer.PlayerGui:FindFirstChild("TargetingPanel")
    if old then old:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "TargetingPanel"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local box = Instance.new("Frame")
    box.Size = UDim2.fromOffset(280, 108)
    box.Position = UDim2.new(0.5, -140, 0.7, 0)
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
    detail.Size = UDim2.new(1, -90, 0, 73)
    detail.BackgroundTransparency = 1
    detail.Font = Enum.Font.Gotham
    detail.TextSize = 12
    detail.TextColor3 = Color3.fromRGB(225, 230, 240)
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.TextYAlignment = Enum.TextYAlignment.Top
    local shown, lastAvatar = true, nil
    Sections.aimbot:Toggle({
        Name = "targeting panel", Flag = "targetingpanel", Default = true,
        Callback = function(value) shown = value end,
    })
    RunService.RenderStepped:Connect(function()
        local p = CurrentTargetPlayer
        local c = p and p.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local own = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local active = p and p.Parent == Players and h and h.Health > 0 and r and own
            and os.clock() - CurrentTargetTime < 1
        box.Visible = shown and not not active
        if not active then return end
        local status = ResolverRunning and "Unknown (no sample)" or "Unknown (resolver off)"
        local data = ResolverSnapshot and ResolverSnapshot[p]
        if ResolverRunning and data and data.LastPosition then
            status = data.Flagged and "Dangerous (flagged)" or "Safe (not flagged)"
        end
        detail.Text = string.format("%s (@%s)\nHealth: %.0f / %.0f\nDistance: %.0f studs\n%s",
            p.DisplayName, p.Name, h.Health, h.MaxHealth, (r.Position - (own.Position - AAOffset())).Magnitude, status)
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
    local NoSpreadEnabled = false;
    local ManipEnabled = false;
    local Manips = 2;
    local ManipScanCount = 120;
    local ScanProgress = 0;
    local ScanStatus = "idle";
    local NoRecoilEnabled = false;
    local RageBotEnabled = false;
    local SilentReload = false;
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

            CreateTracer = function(origin, direction)
                local data = Trails[SelectedTracer]
                if not data then
                    return
                end
                local result = workspace:Raycast(origin, direction * 2000, autofireparams)
                local hitDist = result and (result.Position - origin).Magnitude or 2000
                hitDist = math.max(hitDist, 150)
                local endPos = origin + direction * hitDist
                local p = Instance.new("Part")
                p.Anchored = true
                p.CanCollide = false
                p.Transparency = 1
                p.Size = Vector3.new(0.1, 0.1, 0.1)
                p.Position = origin
                p.Parent = workspace
                local a = Instance.new("Attachment")
                a.Parent = p
                a.Position = Vector3.zero
                local b = Instance.new("Attachment")
                b.Parent = p
                b.Position = endPos - origin
                local beam = Instance.new("Beam")
                beam.Attachment0 = a
                beam.Attachment1 = b
                beam.Texture = data.Texture
                beam.Width0 = data.Width0
                beam.Width1 = data.Width1
                beam.TextureLength = data.TextureLength
                beam.TextureMode = Enum.TextureMode.Wrap
                beam.LightEmission = 1
                beam.LightInfluence = 0
                beam.Transparency = NumberSequence.new(0.45)
                beam.Parent = p
                task.spawn(function()
                    local duration = data.Lifetime
                    local start = os.clock()
                    while os.clock() - start < duration do
                        local progress = (os.clock() - start) / duration
                        beam.Transparency = NumberSequence.new(0.45 + (0.55 * progress))
                        task.wait()
                    end
                    p:Destroy()
                end)
            end
    
    --#endregion
    
    
    
    --#region manip 

        local cachedoffset = nil
        --local lastShotTarget = nil

        autofireparams.FilterDescendantsInstances = {LocalPlayer.Character}

        LocalPlayer.CharacterAdded:Connect(function(char)
            autofireparams.FilterDescendantsInstances = {char}
        end)

        -- Fixed raycast budget; samples points throughout a sphere, including
        -- near and far offsets. A wider range does not override server checks.
        function findminoffset(target, origin, ignorezeropos)
            if not target or not target.Parent then return nil, false, nil end
            autofireparams.FilterDescendantsInstances = {LocalPlayer.Character}
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
            end
            ScanProgress, ScanStatus = 0, "scanning"
            if not ignorezeropos then
                local hit = test(Vector3.zero)
                if hit then ScanProgress, ScanStatus = 1, "direct"; return Vector3.zero, false, hit end
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
                ScanProgress = i / count
            end
            ScanStatus = bestOffset and "found" or "no path"
            return bestOffset, bestOffset ~= nil, bestHit
        end

    --#endregion



    --#region targetting

        local FovCircle = Drawing.new("Circle")

        FovCircle.Radius = 100
        FovCircle.Color = Color3.fromRGB(255, 255, 255)
        FovCircle.Visible = false

        local fovconnection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function()
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
                local priority = TargetPriority(plr)
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

        function GetVisibleTarget(Gun)
            local LocalCharacter = LocalPlayer.Character
            local LocalHead = LocalCharacter and LocalCharacter:FindFirstChild("Head")
            if not LocalHead then 
                return nil 
            end

            local origin = LocalHead.Position - AAOffset()
            local range = Gun:GetAttribute("Range") or math.huge
            local best, bestDist, bestPriority = nil, math.huge, math.huge
            local bestFacing = -math.huge
            local currentCamera = workspace.CurrentCamera
            local facing = currentCamera and currentCamera.CFrame.LookVector
                or LocalHead.CFrame.LookVector

            for _, plr in Players:GetPlayers() do
                local priority = TargetPriority(plr)
                if not priority then continue end
                local data = plr.Character
                if not data then
                    continue 
                end
                if data:FindFirstChildOfClass("ForceField") then 
                    continue 
                end
                local head = data:FindFirstChild("Head")
                local hum = data:FindFirstChild("Humanoid")
                if not head or not hum or hum.Health <= 0 then 
                    continue 
                end

                local direction = head.Position - origin
                local dist = direction.Magnitude
                if dist <= 0.001 or dist > range then continue end
                -- Preserve team priority, then favor the smallest angle to
                -- the camera's facing direction. Distance breaks close ties.
                local alignment = facing:Dot(direction / dist)
                local better = priority < bestPriority
                    or (priority == bestPriority and alignment > bestFacing + 0.001)
                    or (priority == bestPriority and math.abs(alignment - bestFacing) <= 0.001 and dist < bestDist)
                if not better then continue end

                visparams.FilterDescendantsInstances = {LocalCharacter, data}
                local offset
                if not workspace:Raycast(origin, head.Position - origin, visparams) then
                    offset = Vector3.zero
                elseif ManipEnabled then
                    offset = findminoffset(head, origin, true)
                end

                if offset then
                    best, bestDist, bestPriority, bestFacing = { FinalPart = head, offset = offset }, dist, priority, alignment
                end
            end
            if RageBotEnabled and best then ReportTarget(best.FinalPart) end
            return best
        end
    --#endregion



    --#region silent aim logic

        local castRay = filtergc("function", {Name = "castRay"}, true)

        if isfunctionhooked(castRay) then 
            restorefunction(castRay)
        end 

        local old; old = hookfunction(castRay, function(p30, p31, p32, ...)
            local t = GetTarget() 

            if SilentAimEnabled and t then 
                SilentAimTarget = t

                if TracerEnabled then 
                    CreateTracer(p30, (t.Position - p30).Unit)
                end 

                return t, t.Position 
            end 


            return old(p30, p31, p32, ...)
        end)

    --#endregion

    

    --#region ragebot
        --Remotes.ShootEvent

        if isfunctionhooked(getrawmetatable(game).__namecall) then
            restorefunction(getrawmetatable(game).__namecall)
        end

        local mtHook; mtHook = hookfunction(getrawmetatable(game).__namecall, function(self, ...)
            local namecallmethod = getnamecallmethod()

            if not checkcaller() and SilentAimEnabled and SilentAimTarget and not RagebotTarget and rawequal(self, Remotes.ShootEvent) and namecallmethod == "FireServer" then
                local Args = {...}
                local Target = GetTarget() or SilentAimTarget
                local LocalCharacter = LocalPlayer.Character

                SilentAimTarget = nil

                if LocalCharacter and type(Args[1]) == 'table' then
                    local Head = LocalCharacter:FindFirstChild("Head")

                    if Head then
                        local origin = Head.Position - AAOffset()

                        if ManipEnabled then
                            local offset = findminoffset(Target, origin)

                            if offset then
                                origin = origin + offset
                            end
                        end

                        for i, v in Args[1] do
                            v[1] = origin
                            v[2] = Target.Position
                            v[3] = Target
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

                local t = GetVisibleTarget(Gun)

                if not t then
                    continue
                end

                local FinalPart = t.FinalPart
                local origin = LocalHead.Position - AAOffset() + t.offset
                local Shots = {}

                for i = 1, Gun:GetAttribute("ProjectileCount") or 1 do
                    Shots[i] = { origin, FinalPart.Position, FinalPart }
                end

                LastShot = os.clock()

                if TracerEnabled then
                    CreateTracer(origin, (FinalPart.Position - origin).Unit)
                end

                Remotes.ShootEvent:FireServer(Shots)
                Gun:SetAttribute("Local_CurrentAmmo", Ammo - 1)
            end
        end)

    --#endregion



    --#region gun mods

        local shoot = filtergc("function", {Name = "shoot"}, true)

        if isfunctionhooked(shoot) then 
            restorefunction(shoot)
        end 

        local old; old = hookfunction(shoot, function(...) 
            local upvs = debug.getupvalues(shoot)

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
            
            return old(...)
        end)

        if isfunctionhooked(task.wait) then 
            restorefunction(task.wait)
        end 

        local old; old = hookfunction(task.wait, function(time, ...)
            local tb = debug.traceback()
            
            if InstantReload and tb:find('reload') then 
                time = 0
            end

            return old(time, ...)
        end)

    --#endregion



    --#region toggles

        Sections.aimbot:Toggle({
            Name = 'silent aim';
            Flag = 'silentaim';
            Default = false;
            Callback = function(v)
                SilentAimEnabled = v;
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
            Max = 10;
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
            Name = "team priority (aim / visuals)"; Flag = "priorityteamcheck";
            Default = true; Callback = function(v) PriorityTeamCheck = v end;
        })
        Sections.aimbot:Toggle({
            Name = 'ragebot';
            Flag = 'ragebot';
            Default = false;
            Callback = function(v)
                RageBotEnabled = v;
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
local ResolverPanelEnabled = false

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
        ResolverRows[player]:Destroy()
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
        return
    end

    local now = os.clock()
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
        ResolverPanelEnabled = value
        ResolverPanel.Visible = value
    end
})
    

    
    
    
    local oldmin = LocalPlayer.CameraMinZoomDistance
    local oldmax = LocalPlayer.CameraMaxZoomDistance


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
                Lighting.Brightness = 3
                --Lighting.ClockTime = 18.5
                Lighting.ExposureCompensation = 0.5
                
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

local NoclipEnabled = true

--#region infinite jump

local InfiniteJumpEnabled = false

local InfiniteJumpConnection =
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

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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


    --#region speed hack

        local speedhackconnection = RunService.Heartbeat:Connect(function(delta)
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




-- Advanced AA: offsets are restored before simulation and shown with a local visual copy.
-- Replication is controlled by Roblox and is not guaranteed.
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
        Range = 4,
        Height = 4,
        UndergroundDepth = 20,
        Speed = 4,
    }
    local appliedRoot = nil
    local appliedOffset = Vector3.zero
    local phase = 0
    local pausedUntil = 0
    local promptHeld = false
    local connections = {}
    local renderKey = "AdvancedAA_Restore_" .. tostring(LocalPlayer.UserId)

    local function restoreOffset()
        local oldRoot, offset = appliedRoot, appliedOffset
        appliedRoot = nil
        appliedOffset = Vector3.zero
        if oldRoot and oldRoot.Parent and offset.Magnitude > 0 then
            oldRoot.CFrame = oldRoot.CFrame - offset
        end
    end

    local function pauseAA(seconds)
        pausedUntil = math.max(pausedUntil, os.clock() + (seconds or 1.25))
        restoreOffset()
    end
    env.AdvancedAAPause = pauseAA
    env.AdvancedAAOffset = function() return appliedOffset end

    -- Pause while interacting so pickup distance checks see the undisplaced
    -- character. Mouse clicks only pause for objects with a ClickDetector.
    local mouse = LocalPlayer:GetMouse()
    table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
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
    table.insert(connections, promptService.PromptButtonHoldBegan:Connect(function()
        promptHeld = true
        pauseAA(1.25)
    end))
    table.insert(connections, promptService.PromptButtonHoldEnded:Connect(function()
        promptHeld = false
        pauseAA(1.25)
    end))
    table.insert(connections, promptService.PromptTriggered:Connect(function()
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
        local horizontal = Vector3.zero
        -- Square and prism use the same horizontal path; enabling both does
        -- not double its radius. Prism adds the vertical component.
        if settings.Square or settings.Prism then horizontal = square(t) * settings.Range end
        local height = 0
        if settings.Prism then
            height = (1 - math.abs(2 * ((t * 0.5) % 1) - 1)) * settings.Height
        end
        if settings.Underground then height -= settings.UndergroundDepth end
        return horizontal + Vector3.new(0, height, 0)
    end

    local visual, visualCharacter, pairsList = nil, nil, {}
    local savedTransparency = {}
    local function destroyVisual()
        local cam = workspace.CurrentCamera
        if cam and visual then
            local hum = visualCharacter and visualCharacter:FindFirstChildOfClass("Humanoid")
            if hum and cam.CameraSubject and cam.CameraSubject:IsDescendantOf(visual) then
                cam.CameraSubject = hum
            end
        end
        for part, value in pairs(savedTransparency) do
            if part.Parent then part.LocalTransparencyModifier = value end
        end
        table.clear(savedTransparency)
        table.clear(pairsList)
        if visual then visual:Destroy() end
        visual, visualCharacter = nil, nil
    end
    local function makeVisual(character)
        destroyVisual()
        local was = character.Archivable
        character.Archivable = true
        local ok, clone = pcall(function() return character:Clone() end)
        character.Archivable = was
        if not ok or not clone then return end
        visual, visualCharacter = clone, character
        clone.Name = "AdvancedAALocalVisual"
        for _, obj in ipairs(clone:GetDescendants()) do
            if obj:IsA("BaseScript") then obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.Anchored = true
                obj.CanCollide = false
                obj.CanTouch = false
                obj.CanQuery = false
                obj.LocalTransparencyModifier = 0
            end
        end
        clone.Parent = workspace
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                local parent = part.Parent
                local originalParent = parent == clone and character
                    or (parent and character:FindFirstChild(parent.Name))
                local original = originalParent and originalParent:FindFirstChild(part.Name)
                if original and original:IsA("BasePart") then
                    table.insert(pairsList, {part, original})
                end
            end
        end
        local hum = clone:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            local cam = workspace.CurrentCamera
            if cam then cam.CameraSubject = hum end
        end
    end
    local function renderVisual()
        local character = LocalPlayer.Character
        if not settings.Enabled or not character then destroyVisual(); return end
        if visualCharacter ~= character or not visual then makeVisual(character) end
        if not visual then return end
        for _, pair in ipairs(pairsList) do
            local copy, original = pair[1], pair[2]
            if copy.Parent and original.Parent then
                copy.CFrame = original.CFrame - appliedOffset
                if savedTransparency[original] == nil then
                    savedTransparency[original] = original.LocalTransparencyModifier
                end
                original.LocalTransparencyModifier = 1
            end
        end
    end

    table.insert(connections, RunService.PreSimulation:Connect(restoreOffset))
    table.insert(connections, RunService.Heartbeat:Connect(function(dt)
        restoreOffset()
        if not settings.Enabled or promptHeld or os.clock() < pausedUntil then return end
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return end
        phase = (phase + math.min(dt, 0.1) * settings.Speed) % 2
        local offset = calculateOffset(phase)
        appliedRoot = root
        appliedOffset = offset
        root.CFrame = root.CFrame + offset
    end))

    -- Keep the displacement through rendering to give replication a chance;
    -- show a local copy at the undisplaced location. Server acceptance is not guaranteed.
    RunService:BindToRenderStep(renderKey, Enum.RenderPriority.Camera.Value - 1, renderVisual)
    table.insert(connections, LocalPlayer.CharacterRemoving:Connect(function()
        restoreOffset()
        destroyVisual()
    end))

    section:Toggle({
        Name = "advanced aa", Flag = "advanced_aa_enabled", Default = false,
        Callback = function(value)
            settings.Enabled = value
            if not value then restoreOffset(); destroyVisual() end
        end,
    })
    section:Toggle({ Name = "square", Flag = "advanced_aa_square", Default = true,
        Callback = function(value) settings.Square = value end })
    section:Toggle({ Name = "prism", Flag = "advanced_aa_prism", Default = false,
        Callback = function(value) settings.Prism = value end })
    section:Toggle({ Name = "underground", Flag = "advanced_aa_underground", Default = false,
        Callback = function(value) settings.Underground = value end })
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
        Name = "underground depth (studs)", Flag = "advanced_aa_ug_depth",
        Min = 20, Max = 40, Default = 20, Decimals = 1,
        Callback = function(value) settings.UndergroundDepth = value end,
    })
    section:Slider({
        Name = "aa speed (cycles/sec)", Flag = "advanced_aa_speed",
        Min = 1, Max = 40, Default = 4, Decimals = 1,
        Callback = function(value) settings.Speed = value end,
    })

    env.AdvancedAACleanup = function()
        settings.Enabled = false
        restoreOffset()
        destroyVisual()
        RunService:UnbindFromRenderStep(renderKey)
        for _, connection in ipairs(connections) do connection:Disconnect() end
        table.clear(connections)
        if env.AdvancedAAPause == pauseAA then env.AdvancedAAPause = nil end
        env.AdvancedAAOffset = nil
    end
end

Window:InitWindow()
