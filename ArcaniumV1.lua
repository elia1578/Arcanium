-- Paid

if getgenv().Rayfield then getgenv().Rayfield:Destroy() end
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

if game.PlaceId == 10595058975 then
	-- Anti Afk
	local VirtualUser = game:GetService('VirtualUser')
	game:GetService('Players').LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)

	-- Adonis Raper

	if not _G.ADONIS_HOOKED then
		_G.ADONIS_HOOKED = true

		local getinfo = getinfo or debug.getinfo
		local DEBUG = false
		local Hooked = {}

		local Detected, Kill

		setthreadidentity(2)

		for i, v in getgc(true) do
			if typeof(v) == "table" then
					local DetectFunc = rawget(v, "Detected")
				local KillFunc = rawget(v, "Kill")
				
				if typeof(DetectFunc) == "function" and not Detected then
					Detected = DetectFunc
					local Old; Old = hookfunction(Detected, function(Action, Info, NoCrash)
						if Action ~= "_" and DEBUG then
							warn(`Adonis AntiCheat flagged\nMethod: {Action}\nInfo: {Info}`)
						end
						return true
					end)
					table.insert(Hooked, Detected)
				end

				if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
					Kill = KillFunc
					local Old; Old = hookfunction(Kill, function(Info)
						if DEBUG then
							warn(`Adonis AntiCheat tried to kill (fallback): {Info}`)
						end
					end)
					table.insert(Hooked, Kill)
				end
			end
		end

		local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
			local LevelOrFunc, Info = ...
			if Detected and LevelOrFunc == Detected then
				if DEBUG then warn(`zins | adonis bypassed`) end
				return coroutine.yield(coroutine.running())
				end
			return Old(...)
		end))
		setthreadidentity(7)
	end

	wait(2)

    -- Rayfield Window
    local Window = Rayfield:CreateWindow({
        Name = "Arcanium - Paid",
        LoadingTitle = "Welcome to Arcanium",
        LoadingSubtitle = "by Yours Truly",
        ShowText = "Arcanium",
        Theme = "Default",
        ToggleUIKeybind = "K",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = {
            Enabled = true,
            FileName = "Arcanium"
        },

		Discord = {
			Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
			Invite = "q3kQ3eESUZ", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
			RememberJoins = true -- Set this to false to make them join the discord every time they load it up
		},

		KeySystem = false, -- Set this to true to use our key system
    })

    local QOLTab = Window:CreateTab("Quality Of Life", "crown")
    QOLTab:CreateSection("QOL Main")
    QOLTab:CreateLabel("Use these to feel reeeeeal good")

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")    
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    -- =========================================================
    -- GLOBALS & DEFAULTS
    -- =========================================================
    _G.AD_ON = _G.AD_ON or false
    _G.AD_METHOD = _G.AD_METHOD or "Legit"
    _G.AQTE_ON = _G.AQTE_ON or false
    _G.AQTE_METHOD = _G.AQTE_METHOD or "Legit"
    _G.INSTANT_END = _G.INSTANT_END or false  -- Option to instantly end fight

    -- =========================================================
    -- SINGLE-INSTANCE GUARD
    -- =========================================================
    _G.__AD_DATA = _G.__AD_DATA or {
        ad_runId = 0,
        qte_runId = 0,
        ad_conn = nil,
        qte_conn = nil,
        activeQTEs = {}
    }
    local State = _G.__AD_DATA

    -- Initialize if they don't exist (for backward compatibility)
    State.ad_runId = State.ad_runId or 0
    State.qte_runId = State.qte_runId or 0
    State.activeQTEs = State.activeQTEs or {}

    local function stopADLogic()
        State.ad_runId = (State.ad_runId or 0) + 1
        if State.ad_conn then 
            State.ad_conn:Disconnect() 
            State.ad_conn = nil
        end
    end

    local function stopQTELogic()
        State.qte_runId = (State.qte_runId or 0) + 1
        if State.qte_conn then 
            State.qte_conn:Disconnect() 
            State.qte_conn = nil
        end
        State.activeQTEs = {}
    end

    -- =========================================================
    -- CORE REMOTE MANAGEMENT
    -- =========================================================
    local function getRemote()
        return ReplicatedStorage:FindFirstChild("Remotes") 
            and ReplicatedStorage.Remotes:FindFirstChild("Information")
            and ReplicatedStorage.Remotes.Information:FindFirstChild("RemoteFunction")
    end

    -- Unified remote caller with proper format handling
    local function callRemote(...)
        local remote = getRemote()
        if not remote then 
            print("[Remote] No remote found")
            return nil 
        end
        
        local args = {...}
        
        if remote:IsA("RemoteEvent") then
            return remote:FireServer(unpack(args))
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(unpack(args))
        end
    end

    -- Special function to send dodge success with correct format
    local function sendDodgeSuccess()
        -- Format: { true, true, "DodgeMinigame" }
        local args = {
            [1] = {
                [1] = true,
                [2] = true
            },
            [2] = "DodgeMinigame"
        }
        callRemote(unpack(args))
        print("[Dodge] Success signal sent")
    end

    local Sigma = false

    -- Function to instantly end fight
    local function sendFightEnd()
        -- First, temporarily disable the hook
        if remoteHook then
            remoteHook.disable()
        end
        
        -- Send the alternative format that you want
        local args = {
            [1] = false,
            [2] = "DodgeMinigame"
        }
        
        callRemote(unpack(args))
        print("[Fight] Manually ended with alternative format")
        
        -- Re-enable the hook after a short delay
        wait(0.5)
        if remoteHook then
            remoteHook.enable()
        end
    end

    -- Function to send QTE success
    local function sendQTESuccess(qteName)
        -- Format: { true, "QTEName" }
        local args = {
            [1] = true,
            [2] = qteName
        }
        callRemote(unpack(args))
        print("[QTE] Success signal sent for:", qteName)
    end

    -- =========================================================
    -- REMOTE INTERCEPTION SYSTEM - FIXED
    -- =========================================================
    local function installRemoteHook()
        local remote = getRemote()
        if not remote then return nil end
        
        local originalNamecall
        local hookActive = true  -- Always active to intercept false signals
        
        -- Hook to intercept and convert false remotes to true
        originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if self == remote and (method == "FireServer" or method == "InvokeServer") then
                if hookActive then
                    -- Check for failure signals and convert to success
                    if #args >= 2 then
                        local firstArg = args[1]
                        local secondArg = args[2]
                        
                        -- FORMAT 1: {false, "QTEName"} -> convert to { true, "QTEName" }
                        if firstArg == false and type(secondArg) == "string" and secondArg:find("QTE") then
                            local qteName = secondArg
                            print("[Hook] Converting QTE failure to success for:", qteName)
                            
                            -- Send success signal instead: { true, qteName }
                            local successArgs = {
                                [1] = true,
                                [2] = qteName
                            }
                            
                            if remote:IsA("RemoteEvent") then
                                return remote.FireServer(remote, unpack(successArgs))
                            elseif remote:IsA("RemoteFunction") then
                                return remote.InvokeServer(remote, unpack(successArgs))
                            end
                            return nil
                        end
                        
                        -- FORMAT 2: {false, "DodgeMinigame"} -> ALLOW THIS TO PASS THROUGH (manual end fight)
                        -- We don't convert this, we allow it as-is
                        if firstArg == false and secondArg == "DodgeMinigame" then
                            print("[Hook] Allowing manual fight end signal to pass through")
                            return originalNamecall(self, ...)
                        end
                        
                        -- FORMAT 3: {table format} where first element is false
                        if type(firstArg) == "table" then
                            local innerFirst = firstArg[1]
                            local innerSecond = firstArg[2]
                            
                            -- { {false, false}, "DodgeMinigame" } -> convert to { {true, true}, "DodgeMinigame" }
                            if innerFirst == false and innerSecond == false and secondArg == "DodgeMinigame" then
                                print("[Hook] Converting table format dodge failure to success...")
                                
                                -- Send success signal: { {true, true}, "DodgeMinigame" }
                                local successArgs = {
                                    [1] = {
                                        [1] = true,
                                        [2] = true
                                    },
                                    [2] = "DodgeMinigame"
                                }
                                
                                if remote:IsA("RemoteEvent") then
                                    return remote.FireServer(remote, unpack(successArgs))
                                elseif remote:IsA("RemoteFunction") then
                                    return remote.InvokeServer(remote, unpack(successArgs))
                                end
                                return nil
                            end
                        end
                    end
                end
            end
            
            return originalNamecall(self, ...)
        end)
        
        return {
            enable = function()
                hookActive = true
                print("[Hook] Enabled - converting false signals to true")
            end,
            disable = function()
                hookActive = false
                print("[Hook] Disabled - not converting signals")
            end,
            destroy = function()
                if originalNamecall then
                    hookmetamethod(game, "__namecall", originalNamecall)
                    print("[Hook] Destroyed")
                end
            end
        }
    end

    -- Initialize hook
    local remoteHook = installRemoteHook()

    -- =========================================================
    -- UI MANAGEMENT
    -- =========================================================
    local function getCombatUI()
        local playerGui = player:FindFirstChild("PlayerGui")
        return playerGui and playerGui:FindFirstChild("Combat")
    end

    local function hideCombatUI()
        local playerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        local combat = playerGui:FindFirstChild("Combat")
        if not combat then return end
        
        for _, child in ipairs(combat:GetChildren()) do
            if child:IsA("GuiObject") then
                child.Visible = false
            end
        end
    end

    local function isIndicatorInZone(zoneName)
        local combat = getCombatUI()
        local block = combat and combat:FindFirstChild("Block")
        local inset = block and block:FindFirstChild("Inset")
        if not (inset and block and block.Visible) then return false end

        local indicator = inset:FindFirstChild("Indicator")
        local target = inset:FindFirstChild(zoneName)
        if not (indicator and target) then return false end

        local iX = indicator.AbsolutePosition.X + indicator.AbsoluteSize.X / 2
        local tX, tW = target.AbsolutePosition.X, target.AbsoluteSize.X
        
        return iX >= tX and iX <= (tX + tW)
    end

    -- =========================================================
    -- DODGE SYSTEM
    -- =========================================================
    QOLTab:CreateSection("Auto Dodge")

    local ADMethodDropdown = QOLTab:CreateDropdown({
        Name = "Dodge Method",
        Options = {"Instant", "Indicator"},
        CurrentOption = {_G.AD_METHOD == "Legit" and "Indicator" or _G.AD_METHOD},
        MultipleOptions = false,
        Callback = function(opt)
            _G.AD_METHOD = opt[1] == "Indicator" and "Legit" or opt[1]
            stopADLogic()
            -- Don't stop QTE logic when changing Dodge method
        end
    })

    local ADToggle = QOLTab:CreateToggle({
        Name = "Auto Dodge",
        CurrentValue = _G.AD_ON,
        Flag = "AD",
        Callback = function(val)
            _G.AD_ON = val
            stopADLogic()  -- Only stop AD logic
            
            if not val then return end
            
            local myId = (State.ad_runId or 0)
            State.ad_conn = RunService.Heartbeat:Connect(function()
                if (State.ad_runId or 0) ~= myId or not _G.AD_ON then 
                    stopADLogic()
                    return 
                end

                local combat = getCombatUI()
                local block = combat and combat:FindFirstChild("Block")
                if not block then return end
                
                local inset = block:FindFirstChild("Inset")
                
                -- Look for dodge minigame
                if block.Visible then
                    local hasDodge = inset and inset:FindFirstChild("Dodge")
                    local hasBlock = inset and inset:FindFirstChild("Block")
                    
                    if hasDodge or hasBlock then
                        local targetZone = hasDodge and "Dodge" or "Block"
                        
                        if _G.AD_METHOD == "Instant" then
                            -- Send dodge success signal
                            wait(0.5)
                            sendDodgeSuccess()
                            hideCombatUI()
                        elseif _G.AD_METHOD == "Legit" or _G.AD_METHOD == "Indicator" then
                            -- Wait for indicator to be in zone
                            if isIndicatorInZone(targetZone) then
                                local go = combat:FindFirstChild("Go")
                                if go and go.Visible then
                                    sendDodgeSuccess()
                                    hideCombatUI()
                                end
                            end
                        end
                    end
                end
            end)
        end
    })

    -- =========================================================
    -- QTE SYSTEM
    -- =========================================================
    QOLTab:CreateSection("Auto QTE")

    local QTEMethodDropdown = QOLTab:CreateDropdown({
        Name = "QTE Method",
        Options = {"Instant", "Delayed"},
        CurrentOption = {_G.AQTE_METHOD == "Legit" and "Delayed" or _G.AQTE_METHOD},
        MultipleOptions = false,
        Callback = function(opt)
            _G.AQTE_METHOD = opt[1] == "Delayed" and "Legit" or opt[1]
            stopQTELogic()
            -- Don't stop AD logic when changing QTE method
        end
    })

    local AQTEToggle = QOLTab:CreateToggle({
        Name = "Auto QTE",
        CurrentValue = _G.AQTE_ON,
        Flag = "AQTE",
        Callback = function(val)
            _G.AQTE_ON = val
            stopQTELogic()  -- Only stop QTE logic
            
            if not val then return end
            
            local qteNames = {
                "DaggerQTE", "FistQTE", "MagicQTE", 
                "SpearQTE", "SwordQTE", "ThorianQTE"
            }
            
            local myId = (State.qte_runId or 0)
            State.qte_conn = RunService.Heartbeat:Connect(function()
                if (State.qte_runId or 0) ~= myId or not _G.AQTE_ON then 
                    stopQTELogic()
                    return 
                end
                
                local combat = getCombatUI()
                if not combat then return end
                
                for _, qteName in ipairs(qteNames) do
                    local qteUI = combat:FindFirstChild(qteName)
                    if qteUI and qteUI.Visible and not State.activeQTEs[qteName] then
                        State.activeQTEs[qteName] = true
                        
                        task.spawn(function()
                            if _G.AQTE_METHOD == "Instant" then
                                -- Send QTE success immediately
                                hideCombatUI()
                                wait(0.5)
                                sendQTESuccess(qteName)
                            elseif _G.AQTE_METHOD == "Legit" or _G.AQTE_METHOD == "Delayed" then
                                -- Random delay 2-3 seconds for delayed mode
                                local delay = math.random(2000, 3000) / 1000
                                task.wait(delay)
                                
                                if _G.AQTE_ON and qteUI and qteUI.Visible then
                                    sendQTESuccess(qteName)
                                    hideCombatUI()
                                end
                            end
                            
                            task.wait(0.5) -- Cooldown before checking same QTE again
                            State.activeQTEs[qteName] = nil
                        end)
                    end
                end
            end)
        end
    })

    -- =========================================================
    -- END FIGHT SYSTEM (AFTER SEPARATOR)
    -- =========================================================
    QOLTab:CreateSection("Fight Controls")

    QOLTab:CreateButton({
        Name = "Manual End Fight Now",
        Callback = function()
            sendFightEnd()
        end
    })

    -- =========================================================
    -- LOWER QUALITY BUTTON
    -- =========================================================
    local QOLDivider = QOLTab:CreateDivider()
    QOLTab:CreateButton({
        Name = "Lower Quality",
        Callback = function()
            local Lighting = game:GetService("Lighting")
            local Terrain = workspace:FindFirstChildOfClass("Terrain")
            
            settings().Rendering.QualityLevel = 1
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            
            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 0
            end

            task.spawn(function()
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.Material = Enum.Material.SmoothPlastic
                        v.Reflectance = 0
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = 1
                    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                        v.Enabled = false
                    elseif v:IsA("PostEffect") then
                        v.Enabled = false
                    end
                end
                
                Rayfield:Notify({
                    Title = "Quality Lowered",
                    Content = "Textures and effects have been optimized.",
                    Duration = 3
                })
            end)
        end,
    })

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local player = Players.LocalPlayer
	local Fights = ReplicatedStorage:WaitForChild("Fights")

	-- =========================================================
	-- DEBUG
	-- =========================================================
	local DEBUG = false
	local _last = {}

	local function dbg(key, msg, every)
		if not DEBUG then return end
		every = every or 0.35
		local t = os.clock()
		if not _last[key] or (t - _last[key]) >= every then
			_last[key] = t
			print("[AA]", msg)
		end
	end

	local function dbgOnce(key, msg)
		if not DEBUG then return end
		if _last[key] then return end
		_last[key] = os.clock()
		print("[AA]", msg)
	end

    -- =========================================================
    -- ATTACK SECTION (Optimized)
    -- =========================================================
    local AttackTab = Window:CreateTab("Farming Settings", "settings")
    AttackTab:CreateSection("Attack Main")
    AttackTab:CreateLabel("Sometimes attacks after you get into a fight.")

	local function getAttackSF()
		return player.PlayerGui.Combat.ActionBG.AttacksPage.Attack.ScrollingFrame
	end

	local function getButtonNames()
		local sf = getAttackSF()
		local seen = {}
		local names = {}

		for _, ui in ipairs(sf:GetChildren()) do
			if ui:IsA("TextButton") then
				local t = ui.Name
				if t ~= "" and not seen[t] then
					seen[t] = true
					table.insert(names, t)
				end
			end
		end

		table.sort(names, function(a, b) return a:lower() < b:lower() end)
		table.insert(names, 1, "None")
		return names
	end

	local FirstSkill = AttackTab:CreateDropdown({
		Name = "First Skill",
		Options = {"None"},
		CurrentOption = {"None"},
		MultipleOptions = false,
		Flag = "FS",
		Callback = function(Options)
			_G.AA_FS = (typeof(Options) == "table" and Options[1]) or Options or "None"
			dbg("pick_fs", ("FirstSkill=%s"):format(tostring(_G.AA_FS)), 0.0)
		end,
	})

	local SecondSkill = AttackTab:CreateDropdown({
		Name = "Second Skill",
		Options = {"None"},
		CurrentOption = {"None"},
		MultipleOptions = false,
		Flag = "SS",
		Callback = function(Options)
			_G.AA_SS = (typeof(Options) == "table" and Options[1]) or Options or "None"
			dbg("pick_ss", ("SecondSkill=%s"):format(tostring(_G.AA_SS)), 0.0)
		end,
	})

	local ThirdSkill = AttackTab:CreateDropdown({
		Name = "Third Skill",
		Options = {"None"},
		CurrentOption = {"None"},
		MultipleOptions = false,
		Flag = "TS",
		Callback = function(Options)
			_G.AA_TS = (typeof(Options) == "table" and Options[1]) or Options or "None"
			dbg("pick_ts", ("ThirdSkill=%s"):format(tostring(_G.AA_TS)), 0.0)
		end,
	})

	local function refreshAll()
		local opts = getButtonNames()
		FirstSkill:Refresh(opts)
		SecondSkill:Refresh(opts)
		ThirdSkill:Refresh(opts)
		dbg("refresh", ("Refreshed attacks. options=%d"):format(#opts), 0.25)
	end

	AttackTab:CreateButton({
		Name = "Refresh Attacks",
		Callback = refreshAll,
	})

	task.defer(function()
		pcall(refreshAll)

		local ok, sf = pcall(getAttackSF)
		if ok and sf then
			-- disconnect any existing ones first (prevents buildup if you re-run)
			if _G.AA_SF_ADDED then
				_G.AA_SF_ADDED:Disconnect()
				_G.AA_SF_ADDED = nil
			end
			if _G.AA_SF_REMOVED then
				_G.AA_SF_REMOVED:Disconnect()
				_G.AA_SF_REMOVED = nil
			end

			-- reconnect cleanly
			_G.AA_SF_ADDED = sf.ChildAdded:Connect(function(c)
				if c:IsA("TextButton") then
					dbg("sf_add", ("Attack button added: %s"):format(c.Name), 0.15)
					refreshAll()
				end
			end)

			_G.AA_SF_REMOVED = sf.ChildRemoved:Connect(function(c)
				if c:IsA("TextButton") then
					dbg("sf_rem", ("Attack button removed: %s"):format(c.Name), 0.15)
					refreshAll()
				end
			end)
		else
			dbgOnce("sf_fail", "Could not get Attacks ScrollingFrame yet (Combat UI not ready?)")
		end
	end)


	AttackTab:CreateDivider()

	-- =========================================================
	-- UI action helpers
	-- =========================================================

	local function safeActivate(btn)
		if btn and btn:IsA("GuiButton") then
			dbg("try_" .. btn.Name, ("Try Activate: %s vis=%s act=%s")
				:format(btn:GetFullName(), tostring(btn.Visible), tostring(btn.Active)), 0.75)
		end

		if btn and btn:IsA("GuiButton") and btn.Visible and btn.Active then
			firesignal(btn.MouseButton1Click)
			dbg("did_" .. btn.Name, ("Activated: %s"):format(btn:GetFullName()), 0.75)
			return true
		end

		return false
	end

	local function pickUsableAbility(attacksSF)
		local order = {_G.AA_FS, _G.AA_SS, _G.AA_TS}

		for _, name in ipairs(order) do
			if name and name ~= "None" then
				local btn = attacksSF:FindFirstChild(name)
				if btn and btn:IsA("GuiButton") then
					local cd = btn:FindFirstChild("CD")
					local onCd = (cd and cd:IsA("GuiObject") and cd.Visible) or false
					dbg("ab_check", ("Ability %s onCd=%s"):format(name, tostring(onCd)), 0.5)
					if not onCd then
						return btn
					end
				else
					dbg("ab_missing_" .. tostring(name), ("Ability missing: %s"):format(tostring(name)), 1.0)
				end
			end
		end

		local strike = attacksSF:FindFirstChild("Strike")
		if strike and strike:IsA("GuiButton") then
			local cd = strike:FindFirstChild("CD")
			local onCd = (cd and cd:IsA("GuiObject") and cd.Visible) or false
			dbg("strike_check", ("Strike onCd=%s"):format(tostring(onCd)), 0.5)
			if not onCd then
				return strike
			end
		else
			dbg("strike_missing", "Strike button missing in attacksSF", 1.0)
		end

		return nil
	end

	local function firstEnemyButton(enemiesSF)
		local count = 0
		for _, ui in ipairs(enemiesSF:GetDescendants()) do
			if ui:IsA("TextButton") or ui:IsA("ImageButton") then
				count += 1
				if ui.Visible and ui.Active then
					dbg("enemy_pick", ("Enemy button picked: %s (buttons=%d)")
						:format(ui:GetFullName(), count), 0.25)
					return ui
				end
			end
		end
		dbg("enemy_none", ("No enemy buttons ready (buttons found=%d)"):format(count), 0.35)
		return nil
	end

	-- =========================================================
	-- Auto Attack state machine (anti-spam + guard fallback)
	-- =========================================================

	_G.AA_METHOD = _G.AA_METHOD or "Semi-Legit"

	local AAMethodDropdown = AttackTab:CreateDropdown({
		Name = "Attack Method",
		Options = {"Blatant", "Semi-Legit"},
		CurrentOption = {"Semi-Legit"},
		MultipleOptions = false,
		Callback = function(Options)
			_G.AA_METHOD = Options[1]
		end,
	})

	local AAToggle = AttackTab:CreateToggle({
		Name = "Auto Attack",
		CurrentValue = false,
		Flag = "AA",
		Callback = function(Value)
			_G.AA_ON = Value
			dbg("toggle", ("Toggle AutoAttack=%s"):format(tostring(Value)), 0.0)

			-- OFF: stop
			if not Value then
				if _G.AA_CONN then
					_G.AA_CONN:Disconnect()
					_G.AA_CONN = nil
				end
				dbgOnce("stopped_once", "Auto Attack stopped.")
				return
			end

			-- ON: start (only one connection)
			if _G.AA_CONN then
				dbgOnce("already_running", "Auto Attack already running (connection exists).")
				return
			end

			-- UI refs
			local gui = player:WaitForChild("PlayerGui")
			local combat = gui:WaitForChild("Combat")
			local actionBG = combat:WaitForChild("ActionBG")

			local contextPage = actionBG:WaitForChild("ContextPage")
			local guardButton = contextPage:WaitForChild("GuardButton")

			local attacksSF = actionBG:WaitForChild("AttacksPage"):WaitForChild("Attack"):WaitForChild("ScrollingFrame")
			local enemiesPanel = actionBG.AttacksPage:WaitForChild("Enemies")
			local enemiesSF = enemiesPanel:WaitForChild("ScrollingFrame")

			dbgOnce("boot", "AA loop booted. Turn = ActionBG.Visible true (rising edge).")

			-- ===== helpers =====
			local function pressButton(btn)
				if not btn or not btn:IsA("GuiButton") then return false end
				local ok = pcall(function()
					firesignal(btn.MouseButton1Click)
				end)
				if ok then
					dbg("press_" .. btn.Name, ("Pressed: %s"):format(btn.Name), 0.3)
					return true
				end
				return false
			end

			-- ===== helpers ====

            local function isOnCooldown(btn)
                local cd = btn and btn:FindFirstChild("CD")
                return (cd and cd:IsA("GuiObject") and cd.Visible) or false
            end

			-- ===== DEBUGGED ENERGY & EFFECT HELPERS =====
            
            local function getPlayerModel()
                local living = workspace:FindFirstChild("Living")
                return living and living:FindFirstChild(player.Name)
            end

            local function getPlayerEnergy()
                local charModel = getPlayerModel()
                local status = charModel and charModel:FindFirstChild("Status")
                local energyValue = status and status:FindFirstChild("Energy")
                
                local val = energyValue and energyValue.Value or 0
                dbg("energy_check", ("Current Energy: %d"):format(val), 1.0)
                return val
            end

            -- NEW: Check for Darkcore stacks/value
            local function getDarkcoreValue()
                local charModel = getPlayerModel()
                local effects = charModel and charModel:FindFirstChild("Effects")
                local darkcore = effects and effects:FindFirstChild("Darkcore")
                
                local val = darkcore and darkcore.Value or 0
                dbg("darkcore_check", ("Darkcore Value: %d"):format(val), 1.0)
                return val
            end

            local function getAbilityCost(btn)
                if not btn then return 0 end
                local costContainer = btn:FindFirstChild("Cost")
                local textLabel = costContainer and costContainer:FindFirstChild("TextLabel")
                
                if textLabel and textLabel:IsA("TextLabel") then
                    local cost = tonumber(textLabel.Text) or 0
                    dbg("cost_check_" .. btn.Name, ("%s Cost: %d"):format(btn.Name, cost), 1.0)
                    return cost
                end
                return 0
            end

            local function canUse(btn)
                if not btn or not btn:IsA("GuiButton") then return false end
                
                -- 1. Check Cooldown
                if isOnCooldown(btn) then 
                    return false 
                end
                
                -- 2. Check Energy
                local currentEnergy = getPlayerEnergy()
                local requiredEnergy = getAbilityCost(btn)
                
                if currentEnergy < requiredEnergy then
                    dbg("energy_low", ("Skipping %s: Need %d Energy"):format(btn.Name, requiredEnergy), 0.5)
                    return false 
                end

                -- 3. Special Requirement: Darkcore Eruption
                if btn.Name == "Darkcore Eruption" then
                    local darkcoreVal = getDarkcoreValue()
                    if darkcoreVal < 1 then
                        dbg("darkcore_low", "Skipping Darkcore Eruption: Need at least 1 Darkcore value", 0.5)
                        return false
                    end
                end
                
                -- If all checks pass
                return true
            end

			local function pickBestAbility()
				local order = {_G.AA_FS, _G.AA_SS, _G.AA_TS}
				for _, name in ipairs(order) do
					if name and name ~= "None" then
						local btn = attacksSF:FindFirstChild(name)
						if canUse(btn) then return btn end
					end
				end
				return attacksSF:FindFirstChild("Strike")
			end

			local function firstEnemyButton()
				for _, ui in ipairs(enemiesSF:GetDescendants()) do
					if (ui:IsA("TextButton") or ui:IsA("ImageButton")) and ui.Visible and ui.Active then
						return ui
					end
				end
			end

			-- ===== FSM =====
			local state = "IDLE"
			local stateSince = 0
			local lastTurnVisible = actionBG.Visible
			local isWaitingLegit = false -- NEW: Prevents loop overlap during delay

			-- timing
			local MIN_STEP_GAP = 0.25
			local lastActionAt = 0
			local WAIT_ENEMIES_POPULATE_TIMEOUT = 4.25
			local MAX_STATE_STUCK = 5
			local lastStateChange = os.clock()

			local function go(newState)
				state = newState
				stateSince = os.clock()
				lastStateChange = os.clock()
				dbg("state", ("STATE -> %s"):format(newState), 0.0)
			end

			-- ===== GUARD FAILSAFE =====
			local consecutiveGuards = 0
			local MAX_GUARDS = 3
			local function resetGuardCount() consecutiveGuards = 0 end
			local function guardAndFinish(reason)
				consecutiveGuards += 1
				dbg("guard", ("Guard #%d (%s)"):format(consecutiveGuards, reason or "?"), 0.0)
				pressButton(guardButton)
				go("DONE")
				if consecutiveGuards >= MAX_GUARDS then
					warn("[AA] Guarded " .. consecutiveGuards .. " times! Stopping auto attack.")
					pcall(function() AAToggle:Set(false) end)
					_G.AA_ON = false
					if _G.AA_CONN then _G.AA_CONN:Disconnect() _G.AA_CONN = nil end
				end
			end

			if actionBG.Visible then
				go("PRESS_ABILITY")
			end

			-- ===== HEARTBEAT LOOP =====
			local DONE_RETRY_EVERY = 0.5
			local doneLastTryAt = 0

			_G.AA_CONN = RunService.Heartbeat:Connect(function()
				if not _G.AA_ON or isWaitingLegit then return end

				-- === HEALTH FAILSAFE ===
				local living = workspace:FindFirstChild("Living")
				if living then
					local model = living:FindFirstChild(player.Name)
					if model then
						local hum = model:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health < 15 then
							_G.AA_ON = false
							pcall(function() AAToggle:Set(false) end)
							if _G.AA_CONN then _G.AA_CONN:Disconnect() _G.AA_CONN = nil end
							return
						end
					end
				end

				-- Watchdog
				if os.clock() - lastStateChange > MAX_STATE_STUCK and actionBG.Visible then
					go("PRESS_ABILITY")
				end

				-- Detect NEW TURN
				local nowTurnVisible = actionBG.Visible
				if nowTurnVisible and not lastTurnVisible then
					dbg("turn", "NEW TURN detected", 0.0)
					
					-- LEGIT DELAY INJECTION
					if _G.AA_METHOD == "Semi-Legit" then
						isWaitingLegit = true
						task.spawn(function()
							task.wait(math.random(5, 20) / 10) -- Random 0.5 to 2.0s
							isWaitingLegit = false
							go("PRESS_ABILITY")
						end)
					else
						go("PRESS_ABILITY") -- Blatant (Instant)
					end
					
				elseif (not nowTurnVisible) and lastTurnVisible then
					state = "IDLE"
				end
				lastTurnVisible = nowTurnVisible

				if not nowTurnVisible then return end
				if os.clock() - lastActionAt < MIN_STEP_GAP then return end
				lastActionAt = os.clock()

				-- DONE Retry
				if state == "DONE" then
					local now = os.clock()
					if (now - doneLastTryAt) >= DONE_RETRY_EVERY then
						doneLastTryAt = now
						go("PRESS_ABILITY")
					end
					return
				end

				-- Press ability
				if state == "PRESS_ABILITY" then
					local hasAnyAttackButton = false
					for _, b in ipairs(attacksSF:GetChildren()) do
						if b:IsA("GuiButton") then hasAnyAttackButton = true break end
					end

					if not hasAnyAttackButton then return end

					local btn = pickBestAbility()
					if not btn then
						guardAndFinish("no ability button found")
						return
					end

					local attackBtn = player.PlayerGui.Combat.ActionBG.ContextPage.AttackButton
					pressButton(attackBtn)
					task.delay(0.1, function()
						pressButton(btn)
						go("WAIT_ENEMIES_POPULATE")
					end)
					return
				end

				-- Wait enemies populate
				if state == "WAIT_ENEMIES_POPULATE" then
					local ebtn = firstEnemyButton()
					if ebtn then
						pressButton(ebtn)
						resetGuardCount()
						go("DONE")
						return
					end
					if os.clock() - stateSince > WAIT_ENEMIES_POPULATE_TIMEOUT then
						guardAndFinish("timeout enemies")
					end
				end
			end)
		end,
	})

	task.spawn(function()
		while task.wait(2) do
			if not _G.AA_ON then break end
			if not game:IsLoaded() or not game:GetService("Players").LocalPlayer then break end
			if _G.AA_ON and not _G.AA_CONN then
				warn("[AA] Connection lost — restarting auto attack loop.")
				AAToggle.Callback(true)
			end
		end
	end)

    -- =========================================================
    -- AUTO FARM SECTION (Enhanced with Accurate Essence Costs)
    -- =========================================================
    local FarmTab = Window:CreateTab("Auto Farm", "wheat")
    FarmTab:CreateSection("Auto Farm Settings")

    -- Farm state machine
    _G.AF_ON = false
    _G.AF_SPEED = 50
    _G.AF_TARGET_POS = CFrame.new(5001.64307, 621.612122, -4952.12451, 0.999987781, -1.38148621e-08, -0.00493754121, 1.37753133e-08, 1, -8.04379408e-09, 0.00493754121, 7.97567967e-09, 0.999987781)
    _G.AF_START_HEIGHT = 598
    _G.AF_STATE = "IDLE" -- IDLE, MOVING_UNDERGROUND, MOVING_TO_FARM, MOVING_TO_CRYSTALS, AT_CRYSTALS, CRYSTAL_WAIT, MOVING_TO_CHECKPOINT, AT_CHECKPOINT, CHECKPOINT_WAIT, IN_FIGHT, POST_FIGHT
    _G.AF_CURRENT_MOVEMENT = nil
    _G.AF_LOOP_CONNECTION = nil
    _G.AF_LAST_CRYSTAL_CHECK = 0
    _G.AF_AT_FARM_POSITION = false
    _G.AF_WENT_UNDERGROUND = false
    _G.AF_POST_FIGHT_TIMER = 0
    
    -- Level up settings
    _G.AF_LEVEL_UPS_TO_FARM = 3  -- Default: farm enough essence for 3 level ups (min 1, max 3)
    _G.AF_CURRENT_LEVEL = 1
    _G.AF_FARM_ESSENCE_TARGET = 0  -- Will be calculated based on current level and levels to farm
    
        -- Noclip and Flight integration - FIXED
    local NOCLIP_ENABLED_SAVED = false
    local FLIGHT_ENABLED_SAVED = false

    -- Enable Noclip and Flight for farm (WITH COLLISION SAFETY)
    local function enableFarmMovement()
        -- Save current states BEFORE enabling
        NOCLIP_ENABLED_SAVED = _G.NOCLIP_ENABLED or false
        FLIGHT_ENABLED_SAVED = _G.FLIGHT_ENABLED or false
        
        print("[Farm] Saving states - Noclip:", NOCLIP_ENABLED_SAVED, "Flight:", FLIGHT_ENABLED_SAVED)
        
        -- Enable noclip ONLY if it wasn't already enabled
        if NoclipToggle and not _G.NOCLIP_ENABLED then
            print("[Farm] Enabling noclip for farm")
            NoclipToggle:Set(true)
        else
            print("[Farm] Noclip already enabled or toggle not found")
        end
        
        -- Enable flight ONLY if it wasn't already enabled
        if FlightToggle and not _G.FLIGHT_ENABLED then
            print("[Farm] Enabling flight for farm")
            FlightToggle:Set(true)
        else
            print("[Farm] Flight already enabled or toggle not found")
        end
        
        -- Wait a bit for toggles to take effect
        task.wait(0.1)
    end

    -- Disable Noclip and Flight after farm (RESTORE ORIGINAL STATE)
    local function disableFarmMovement()
        print("[Farm] Restoring states - Original Noclip:", NOCLIP_ENABLED_SAVED, "Original Flight:", FLIGHT_ENABLED_SAVED)
        
        -- Disable noclip ONLY if we enabled it (it was false when we started)
        if _G.NOCLIP_ENABLED and not NOCLIP_ENABLED_SAVED and NoclipToggle then
            print("[Farm] Disabling noclip (we enabled it)")
            NoclipToggle:Set(false)
        else
            print("[Farm] Keeping noclip state (original:", NOCLIP_ENABLED_SAVED, ")")
        end
        
        -- Disable flight ONLY if we enabled it (it was false when we started)
        if _G.FLIGHT_ENABLED and not FLIGHT_ENABLED_SAVED and FlightToggle then
            print("[Farm] Disabling flight (we enabled it)")
            FlightToggle:Set(false)
        else
            print("[Farm] Keeping flight state (original:", FLIGHT_ENABLED_SAVED, ")")
        end
    end

    -- Crystal phase positions
    _G.CRYSTAL_CHECKPOINT_1 = Vector3.new(788.5406494140625, 231.45736694335938, 1970.32275390625)
    _G.CRYSTAL_CHECKPOINT_2 = Vector3.new(789.3740844726562, 228.14146423339844, 2119.9736328125)

    -- ESSENCE COST TABLE (Level 1-40)
    local ESSENCE_COSTS = {
        [1] = 0,      -- Level 1 (N/A)
        [2] = 21,     -- Level 2
        [3] = 24,     -- Level 3
        [4] = 29,     -- Level 4
        [5] = 36,     -- Level 5 (Unlocks Base Class and Sub Class)
        [6] = 45,     -- Level 6
        [7] = 56,     -- Level 7
        [8] = 69,     -- Level 8
        [9] = 84,     -- Level 9
        [10] = 101,   -- Level 10 (Can join a Covenant)
        [11] = 120,   -- Level 11
        [12] = 141,   -- Level 12
        [13] = 164,   -- Level 13
        [14] = 189,   -- Level 14
        [15] = 216,   -- Level 15 (Unlocks Super Class/1st Super Class skill)
        [16] = 245,   -- Level 16
        [17] = 276,   -- Level 17 (2nd Super Class skill)
        [18] = 309,   -- Level 18
        [19] = 344,   -- Level 19 (3rd Super Class skill)
        [20] = 381,   -- Level 20 (Can use Lineage Shard)
        [21] = 420,   -- Level 21 (4th Super Class skill)
        [22] = 461,   -- Level 22
        [23] = 504,   -- Level 23 (5th Super Class skill)
        [24] = 549,   -- Level 24
        [25] = 596,   -- Level 25 (Can unlock Inferno Enchant)
        [26] = 645,   -- Level 26
        [27] = 696,   -- Level 27
        [28] = 749,   -- Level 28
        [29] = 804,   -- Level 29
        [30] = 861,   -- Level 30
        [31] = 920,   -- Level 31
        [32] = 981,   -- Level 32
        [33] = 1044,  -- Level 33
        [34] = 1109,  -- Level 34
        [35] = 1176,  -- Level 35 (Can unlock Lifesong, Cursed and Reaper Enchant)
        [36] = 1245,  -- Level 36
        [37] = 1316,  -- Level 37
        [38] = 1389,  -- Level 38
        [39] = 1464,  -- Level 39
        [40] = 1541   -- Level 40 (Max Level)
    }

    -- Calculate total essence needed for N level ups from current level
    local function calculateTotalEssenceNeeded(currentLevel, levelUpsToFarm)
        if currentLevel >= 40 then
            return 0  -- Max level reached
        end
        
        local totalEssence = 0
        local levelsLeft = 40 - currentLevel
        
        -- Cap levelUpsToFarm at remaining levels or 3
        local effectiveLevelUps = math.min(levelUpsToFarm, levelsLeft, 3)
        
        for i = 1, effectiveLevelUps do
            local targetLevel = currentLevel + i
            if targetLevel <= 40 then
                totalEssence = totalEssence + (ESSENCE_COSTS[targetLevel] or 0)
            end
        end
        
        return totalEssence
    end

    -- Update the farm essence target based on current level and level ups to farm
    local function updateFarmEssenceTarget()
        _G.AF_FARM_ESSENCE_TARGET = calculateTotalEssenceNeeded(_G.AF_CURRENT_LEVEL, _G.AF_LEVEL_UPS_TO_FARM)
        print("[Farm] Updated essence target: " .. _G.AF_FARM_ESSENCE_TARGET .. " for " .. _G.AF_LEVEL_UPS_TO_FARM .. " level ups from level " .. _G.AF_CURRENT_LEVEL)
    end

    -- Get current player level from the correct location
    local function getCurrentLevel()
        local hud = player.PlayerGui:FindFirstChild("HUD")
        if not hud then return 1 end
        
        local holder = hud:FindFirstChild("Holder")
        if not holder then return 1 end
        
        local characterLevel = holder:FindFirstChild("CharacterLevel")
        if not characterLevel then return 1 end
        
        local levelText = characterLevel:FindFirstChild("Level")
        if not levelText then return 1 end
        
        -- Extract number from "Level: NUM"
        local text = levelText.Text
        local levelNum = string.match(text, "Level:%s*(%d+)")
        
        if levelNum then
            return tonumber(levelNum)
        end
        
        return 1  -- Default level
    end

    -- Get crystal proximity position (right under the prox)
    local function getCrystalProxPosition()
        local mats = workspace:FindFirstChild("Mats")
        if not mats then return nil end
        
        local children = mats:GetChildren()
        if #children < 3 then return nil end
        
        local thirdChild = children[3]
        if not thirdChild then return nil end
        
        local root = thirdChild:FindFirstChild("Root")
        if not root then return nil end
        
        local prox = root:FindFirstChild("Prox")
        if not prox then return nil end
        
        -- Position right under the prox (exactly at root)
        return root.Position + Vector3.new(0, -2, 0) -- 2 studs below root
    end

    -- Get current essence count (crystals)
    local function getEssenceCount()
        local hud = player.PlayerGui:FindFirstChild("HUD")
        if not hud then return 0 end
        
        local holder = hud:FindFirstChild("Holder")
        if not holder then return 0 end
        
        local currency = holder:FindFirstChild("Currency")
        if not currency then return 0 end
        
        local container = currency:FindFirstChild("Container")
        if not container then return 0 end
        
        local crystals = container:FindFirstChild("Crystals")
        if not crystals then return 0 end
        
        local amount = crystals:FindFirstChild("Amount")
        if not amount then return 0 end
        
        local textLabel = amount:FindFirstChild("TextLabel") or amount
        if not textLabel then return 0 end
        
        -- Extract number from text
        local text = textLabel.Text
        local cleanText = text:gsub("[^%d,]", ""):gsub(",", "")
        return tonumber(cleanText) or 0
    end

    -- Fire meditation remote with delay
    local isMeditating = false
    local lastMeditateTime = 0
    local MEDITATE_COOLDOWN = 2.0 -- 2 second cooldown to prevent spam

    local function fireMeditate()
        local currentTime = os.clock()
        
        -- Check cooldown to prevent spam
        if isMeditating or (currentTime - lastMeditateTime) < MEDITATE_COOLDOWN then
            return false
        end
        
        local character = player.Character
        if not character then return false end
        
        local meditateHandler = character:FindFirstChild("MeditateHandler")
        if not meditateHandler then return false end
        
        local meditateRemote = meditateHandler:FindFirstChild("Meditate")
        if not meditateRemote then return false end
        
        isMeditating = true
        lastMeditateTime = currentTime
        
        task.spawn(function()
            -- Wait 1.5 seconds before firing
            task.wait(1.5)
            
            local success, err = pcall(function()
                meditateRemote:FireServer()
            end)
            
            isMeditating = false
            
            if success then
                print("[Farm] Fired Meditate remote (after 1.5s delay)")
                return true
            else
                print("[Farm] Error firing Meditate remote:", err)
                return false
            end
        end)
        
        return true
    end

    -- Smooth LERP movement function with dynamic speed adjustment
    local function lerpTo(targetCFrame, nextState)
        local character = player.Character
        if not character then return false end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return false end
        
        -- Cancel any existing movement
        if _G.AF_CURRENT_MOVEMENT then
            _G.AF_CURRENT_MOVEMENT:Disconnect()
            _G.AF_CURRENT_MOVEMENT = nil
        end
        
        local startPos = humanoidRootPart.Position
        local endPos = targetCFrame.Position
        local distance = (endPos - startPos).Magnitude
        
        if distance < 5 then
            -- Already close enough
            humanoidRootPart.CFrame = targetCFrame
            if nextState then
                _G.AF_STATE = nextState
            end
            return true
        end
        
        -- Calculate time needed based on current speed
        local speed = _G.AF_SPEED
        local timeToReach = distance / speed
        local startTime = os.clock()
        local startCFrame = humanoidRootPart.CFrame
        
        print("[Farm] Starting LERP movement, distance:", math.floor(distance), "time:", timeToReach, "speed:", speed)
        
        -- Create smooth movement connection with dynamic speed adjustment
        _G.AF_CURRENT_MOVEMENT = RunService.Heartbeat:Connect(function()
            local elapsed = os.clock() - startTime
            
            -- Get current speed (might have changed during movement)
            local currentSpeed = _G.AF_SPEED
            local adjustedTimeToReach = distance / currentSpeed
            local progress = math.min(elapsed / adjustedTimeToReach, 1)
            
            -- Smooth LERP interpolation
            local currentPos = startPos + (endPos - startPos) * progress
            
            -- For rotation, also LERP smoothly
            local currentCFrame
            if progress < 1 then
                -- Interpolate rotation too
                currentCFrame = startCFrame:Lerp(targetCFrame, progress)
                -- Keep the position from our smooth movement
                currentCFrame = CFrame.new(currentPos) * currentCFrame.Rotation
            else
                currentCFrame = targetCFrame
            end
            
            humanoidRootPart.CFrame = currentCFrame
            
            -- Check if we've reached the destination
            if progress >= 1 then
                _G.AF_CURRENT_MOVEMENT:Disconnect()
                _G.AF_CURRENT_MOVEMENT = nil
                if nextState then
                    _G.AF_STATE = nextState
                    print("[Farm] Arrived at destination, state:", nextState)
                else
                    _G.AF_STATE = "IDLE"
                    print("[Farm] Arrived at destination")
                end
            end
        end)
        
        return true
    end

    -- Check if player is in fight
    local function isInFight()
        local fights = game:GetService("ReplicatedStorage"):FindFirstChild("Fights")
        if not fights then return false end
        
        for _, fight in ipairs(fights:GetDescendants()) do
            if fight:IsA("ObjectValue") and fight.Name == player.Name then
                return true
            end
        end
        
        return false
    end

    -- Check if player is near a position
    local function isNearPosition(position, distance)
        local character = player.Character
        if not character then return false end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return false end
        
        return (humanoidRootPart.Position - position).Magnitude < distance
    end

    -- Enable Noclip and Flight for farm
    local function enableFarmMovement()
        -- Save current states
        NOCLIP_ENABLED_SAVED = NOCLIP_ENABLED
        FLIGHT_ENABLED_SAVED = FLIGHT_ENABLED
        
        -- Enable noclip
        if NoclipToggle then
            if not NOCLIP_ENABLED then
                NoclipToggle:Set(true)
            end
        end
        
        -- Enable flight
        if FlightToggle then
            if not FLIGHT_ENABLED then
                FlightToggle:Set(true)
            end
        end
    end

    -- Disable Noclip and Flight after farm
    local function disableFarmMovement()
        -- Restore to original states
        if NOCLIP_ENABLED and not NOCLIP_ENABLED_SAVED and NoclipToggle then
            NoclipToggle:Set(false)
        end
        
        if FLIGHT_ENABLED and not FLIGHT_ENABLED_SAVED and FlightToggle then
            FlightToggle:Set(false)
        end
    end

    -- Main farm decision logic
    local function farmLogic()
        if not _G.AF_ON then return end
        
        -- Update current level periodically (every 10 seconds)
        local currentTime = os.clock()
        if currentTime - _G.AF_LAST_CRYSTAL_CHECK >= 10 then
            local newLevel = getCurrentLevel()
            if newLevel ~= _G.AF_CURRENT_LEVEL then
                _G.AF_CURRENT_LEVEL = newLevel
                updateFarmEssenceTarget()
            end
            _G.AF_LAST_CRYSTAL_CHECK = currentTime
        end
        
        -- Check if we're in a fight
        if isInFight() then
            if _G.AF_STATE ~= "IN_FIGHT" then
                print("[Farm] Fight detected, pausing farm")
                _G.AF_STATE = "IN_FIGHT"
                
                -- Cancel any movement
                if _G.AF_CURRENT_MOVEMENT then
                    _G.AF_CURRENT_MOVEMENT:Disconnect()
                    _G.AF_CURRENT_MOVEMENT = nil
                end
            end
            return
        elseif _G.AF_STATE == "IN_FIGHT" then
            -- Just came out of fight, wait 2 seconds
            print("[Farm] Fight ended, waiting 2 seconds before resuming")
            _G.AF_STATE = "POST_FIGHT"
            _G.AF_POST_FIGHT_TIMER = os.clock()
        end
        
        -- Handle post-fight wait
        if _G.AF_STATE == "POST_FIGHT" then
            if os.clock() - _G.AF_POST_FIGHT_TIMER >= 2 then
                print("[Farm] Post-fight wait complete, resuming farm")
                _G.AF_STATE = "IDLE"
            else
                return  -- Still waiting
            end
        end
        
        -- Don't do anything if we're already moving
        if _G.AF_STATE == "MOVING_UNDERGROUND" or 
        _G.AF_STATE == "MOVING_TO_FARM" or 
        _G.AF_STATE == "MOVING_TO_CRYSTALS" or
        _G.AF_STATE == "MOVING_TO_CHECKPOINT" then
            return
        end
        
        -- Handle waiting states
        if _G.AF_STATE == "CRYSTAL_WAIT" or _G.AF_STATE == "CHECKPOINT_WAIT" then
            return -- These states are handled by their own timing
        end
        
        -- Check character
        local character = player.Character
        if not character then 
            _G.AF_STATE = "IDLE"
            return 
        end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then 
            _G.AF_STATE = "IDLE"
            return 
        end
        
        -- CRYSTAL PHASE LOGIC
        if _G.AF_STATE == "AT_CRYSTALS" then
            print("[Farm] At crystals, firing meditate remote")
            fireMeditate()
            _G.AF_STATE = "CRYSTAL_WAIT"
            task.spawn(function()
                task.wait(8) -- Wait 8 seconds for meditation
                
                -- Check if near checkpoint 1
                if isNearPosition(_G.CRYSTAL_CHECKPOINT_1, 100) then
                    print("[Farm] Near checkpoint 1, moving to checkpoint 2")
                    _G.AF_STATE = "MOVING_TO_CHECKPOINT"
                    lerpTo(CFrame.new(_G.CRYSTAL_CHECKPOINT_2), "AT_CHECKPOINT")
                else
                    print("[Farm] Not near checkpoint 1, returning to farm")
                    _G.AF_STATE = "IDLE"
                    _G.AF_AT_FARM_POSITION = false
                    _G.AF_WENT_UNDERGROUND = false
                end
            end)
            return
        end
        
        -- Update the checkpoint state logic with new requirements
        if _G.AF_STATE == "AT_CHECKPOINT" then
            print("[Farm] At checkpoint, starting NPC interaction sequence")
            _G.AF_STATE = "CHECKPOINT_WAIT"
            task.spawn(function()
                -- (Keep the existing checkpoint interaction code here)
                local function waitForElement(path, elementName, timeout, parent)
                    local start = os.clock()
                    local element = parent or game
                    for _, part in ipairs(path) do
                        while os.clock() - start < timeout do
                            element = element:FindFirstChild(part)
                            if element then break end
                            task.wait(0.1)
                        end
                        if not element then
                            print("[Farm] Could not find:", part, "in path")
                            return nil
                        end
                    end
                    return element
                end
                
                -- Step 1: Wait for NPC and fire proximity prompt
                print("[Farm] Step 1: Looking for Aretim...")
                local aretim = waitForElement({"NPCs", "Aretim"}, "Aretim", 5, workspace)
                if aretim then
                    local body = waitForElement({"Body"}, "Body", 3, aretim)
                    if body then
                        local prompt = waitForElement({"ProximityPrompt"}, "ProximityPrompt", 3, body)
                        if prompt and prompt:IsA("ProximityPrompt") then
                            print("[Farm] Found Aretim, firing proximity prompt...")
                            fireproximityprompt(prompt)
                            task.wait(0.5)
                            
                            -- Try again in case first press didn't work
                            for i = 1, 3 do
                                if not player.PlayerGui:FindFirstChild("NPCDialogue") then
                                    fireproximityprompt(prompt)
                                    task.wait(0.5)
                                else
                                    break
                                end
                            end
                        end
                    end
                end
                
                -- Step 2: Wait for NPCDialogue GUI with longer timeout
                print("[Farm] Step 2: Waiting for NPCDialogue GUI...")
                local npcDialogueGui = nil
                for i = 1, 20 do  -- Wait up to 5 seconds (20 * 0.25)
                    npcDialogueGui = player.PlayerGui:FindFirstChild("NPCDialogue")
                    if npcDialogueGui and npcDialogueGui.Enabled then
                        break
                    end
                    task.wait(0.25)
                end
                
                if npcDialogueGui and npcDialogueGui.Enabled then
                    print("[Farm] NPCDialogue GUI found, waiting for options...")
                    
                    -- Wait for Options to populate
                    local options = nil
                    for i = 1, 20 do  -- Wait up to 5 seconds
                        options = npcDialogueGui:FindFirstChild("BG") and 
                                npcDialogueGui.BG:FindFirstChild("Options")
                        if options and #options:GetChildren() > 0 then
                            break
                        end
                        task.wait(0.25)
                    end
                    
                    if options then
                        print("[Farm] Options found, looking for correct button...")
                        task.wait(0.8)  -- Extra wait for UI to settle
                        
                        -- Look for the button with the specific text
                        local targetButton = nil
                        for _, child in ipairs(options:GetChildren()) do
                            if child:IsA("TextButton") and child.Text then
                                -- More flexible text matching
                                local searchText = child.Text:lower()
                                if string.find(searchText, "show me as much light") or
                                string.find(searchText, "as much light") or
                                string.find(searchText, "light as i can handle") then
                                    targetButton = child
                                    print("[Farm] Found matching button:", child.Text)
                                    break
                                end
                            end
                        end
                        
                        if targetButton then
                            -- Try to click the button with verification
                            for attempt = 1, 3 do
                                firesignal(targetButton.MouseButton1Click)
                                print("[Farm] Attempt", attempt, "to click dialogue option")
                                task.wait(6)
                                
                                -- Check if LevelUp GUI appears as confirmation
                                local levelUpGui = player.PlayerGui:FindFirstChild("LevelUp")
                                if levelUpGui.Enabled then
                                    wait(1)
                                    print("[Farm] LevelUp GUI appeared, dialogue selection successful")
                                    break
                                end
                            end
                        else
                            print("[Farm] Could not find dialogue option button, trying first available...")
                            -- Try first TextButton as fallback
                            for _, child in ipairs(options:GetChildren()) do
                                if child:IsA("TextButton") then
                                    firesignal(child.MouseButton1Click)
                                    print("[Farm] Clicked first available button as fallback")
                                    task.wait(0.5)
                                    break
                                end
                            end
                        end
                    else
                        print("[Farm] Options not found in NPCDialogue GUI")
                    end
                else
                    print("[Farm] NPCDialogue GUI not found or not enabled")
                end
                
                -- Step 3: Wait for LevelUp GUI to appear
                print("[Farm] Step 3: Waiting for LevelUp GUI...")
                local levelUpGui = nil
                for i = 1, 20 do  -- Wait up to 5 seconds
                    levelUpGui = player.PlayerGui:FindFirstChild("LevelUp")
                    if levelUpGui then
                        break
                    end
                    task.wait(0.25)
                end
                
                if levelUpGui then
                    print("[Farm] LevelUp GUI found, waiting 1 second for it to fully load...")
                    task.wait(1)  -- Wait for GUI to fully load
                    
                    -- Step 4: Find the StrengthUp button
                    print("[Farm] Step 4: Looking for StrengthUp button...")
                    local strengthUp = nil
                    local path = {"Container", "Body", "Buttons", "Strength", "Frame", "StrengthUp"}
                    
                    for i = 1, 30 do  -- Wait up to 7.5 seconds
                        local current = levelUpGui
                        local found = true
                        
                        for _, part in ipairs(path) do
                            current = current:FindFirstChild(part)
                            if not current then
                                found = false
                                break
                            end
                        end
                        
                        if found and current:IsA("ImageButton") then
                            strengthUp = current
                            break
                        end
                        task.wait(0.25)
                    end
                    
                    if strengthUp then
                        print("[Farm] StrengthUp button found, waiting for PointsLeft text...")
                        
                        -- Wait for PointsLeft text to be available
                        local pointsLeftText = nil
                        for i = 1, 20 do  -- Wait up to 5 seconds
                            local container = levelUpGui:FindFirstChild("Container")
                            if container then
                                local header = container:FindFirstChild("Header")
                                if header then
                                    pointsLeftText = header:FindFirstChild("PointsLeft")
                                    if pointsLeftText and pointsLeftText:IsA("TextLabel") then
                                        break
                                    end
                                end
                            end
                            task.wait(0.25)
                        end
                        
                        if pointsLeftText then
                            print("[Farm] Starting StrengthUp clicks until stat points are 0...")
                            
                            -- Function to get current stat points
                            local function getStatPoints()
                                return pointsLeftText.Text
                            end
                            
                            -- Click StrengthUp button every 0.1 seconds until "Stat Points: 0"
                            local startTime = os.clock()
                            local maxTime = 30  -- Maximum 30 seconds to prevent infinite loop
                            
                            while getStatPoints() ~= "Stat Points: 0" and os.clock() - startTime < maxTime and _G.AF_ON do
                                if strengthUp and strengthUp.Parent then
                                    firesignal(strengthUp.MouseButton1Click)
                                end
                                
                                -- Log progress every 5 seconds
                                if math.floor(os.clock() - startTime) % 5 == 0 then
                                    print("[Farm] Current stat points:", getStatPoints(), "Time elapsed:", os.clock() - startTime)
                                end
                                
                                task.wait(0.1)  -- Wait 0.1 seconds between clicks
                            end
                            
                            if getStatPoints() == "Stat Points: 0" then
                                print("[Farm] Stat points reached 0, proceeding to Finish button")
                            else
                                print("[Farm] Timeout or farm disabled before reaching 0 stat points")
                            end
                        else
                            print("[Farm] PointsLeft text not found, clicking StrengthUp 25 times as fallback...")
                            -- Fallback: Click 25 times
                            for i = 1, 25 do
                                if _G.AF_ON then
                                    firesignal(strengthUp.MouseButton1Click)
                                    task.wait(0.1)
                                else
                                    break
                                end
                            end
                        end
                    else
                        print("[Farm] StrengthUp button not found, trying to find any upgrade button...")
                        -- Fallback: look for any button with "Up" in the name
                        for _, descendant in ipairs(levelUpGui:GetDescendants()) do
                            if descendant:IsA("ImageButton") and descendant.Name:find("Up") then
                                print("[Farm] Found fallback button, clicking 25 times...")
                                for i = 1, 25 do
                                    if _G.AF_ON then
                                        firesignal(descendant.MouseButton1Click)
                                        task.wait(0.1)
                                    else
                                        break
                                    end
                                end
                                print("[Farm] Clicked fallback button:", descendant.Name)
                                break
                            end
                        end
                    end
                    
                    -- Step 5: Wait 0.2 seconds and click Finish button
                    task.wait(0.2)
                    print("[Farm] Step 5: Looking for Finish button...")
                    
                    local finishButton = nil
                    for i = 1, 10 do  -- Wait up to 2.5 seconds
                        finishButton = levelUpGui:FindFirstChild("Finish")
                        if finishButton then
                            break
                        end
                        task.wait(0.25)
                    end
                    
                    if finishButton and (finishButton:IsA("TextButton") or finishButton:IsA("ImageButton")) then
                        print("[Farm] Finish button found, clicking...")
                        firesignal(finishButton.MouseButton1Click)
                    else
                        print("[Farm] Finish button not found, trying alternative...")
                        -- Look for any button with "Finish" in name or text
                        for _, descendant in ipairs(levelUpGui:GetDescendants()) do
                            if descendant:IsA("GuiButton") and 
                            (descendant.Name:find("Finish") or 
                                (descendant:IsA("TextButton") and descendant.Text and descendant.Text:find("Finish"))) then
                                firesignal(descendant.MouseButton1Click)
                                print("[Farm] Clicked alternative finish button:", descendant.Name)
                                break
                            end
                        end
                    end
                else
                    print("[Farm] LevelUp GUI not found, skipping strength upgrade...")
                end
                
                -- Step 6: Final meditation and return to farming with new timing
                print("[Farm] Step 6: Final meditation and returning to farm...")
                task.wait(0.5)  -- Wait 0.3 seconds after Finish button
                
                -- Fire meditate remote
                fireMeditate()

                wait(4.5)
                
                -- After level up sequence, update target for next batch
                updateFarmEssenceTarget()
                
                -- Return to farming
                print("[Farm] Returning to normal farming")
                _G.AF_STATE = "IDLE"
                _G.AF_AT_FARM_POSITION = false
                _G.AF_WENT_UNDERGROUND = false
                
            end)
            return
        end
        
        -- NORMAL FARM LOGIC
        -- Check if we have enough essence for the target number of level ups
        local essenceCount = getEssenceCount()
        if _G.AF_FARM_ESSENCE_TARGET > 0 and essenceCount >= _G.AF_FARM_ESSENCE_TARGET then
            print("[Farm] Collecting essence, count:", essenceCount, "target:", _G.AF_FARM_ESSENCE_TARGET)
            
            local targetPos = getCrystalProxPosition()
            if targetPos then
                _G.AF_STATE = "MOVING_TO_CRYSTALS"
                lerpTo(CFrame.new(targetPos), "AT_CRYSTALS")
                return
            else
                print("[Farm] Could not find crystal position")
            end
        else
            -- Display progress
            local progressPercent = 0
            if _G.AF_FARM_ESSENCE_TARGET > 0 then
                progressPercent = (essenceCount / _G.AF_FARM_ESSENCE_TARGET) * 100
            end
            
            if os.clock() % 10 < 0.1 then  -- Log progress every 10 seconds
                print(string.format("[Farm] Essence progress: %d/%d (%.1f%%) - Level %d → %d", 
                    essenceCount, _G.AF_FARM_ESSENCE_TARGET, progressPercent,
                    _G.AF_CURRENT_LEVEL, _G.AF_CURRENT_LEVEL + _G.AF_LEVEL_UPS_TO_FARM))
            end
        end
        
        -- Check if we're at farm position (within 15 studs)
        local distanceToFarm = (humanoidRootPart.Position - _G.AF_TARGET_POS.Position).Magnitude
        if distanceToFarm < 15 and humanoidRootPart.Position.Y <= _G.AF_START_HEIGHT + 5 then
            if not _G.AF_AT_FARM_POSITION then
                _G.AF_AT_FARM_POSITION = true
                _G.AF_WENT_UNDERGROUND = true
                print("[Farm] At farm position, waiting for encounters")
            end
            return
        end
        
        -- If not at farm position, move to farm
        if humanoidRootPart.Position.Y > _G.AF_START_HEIGHT then
            -- Need to go underground first
            if not _G.AF_WENT_UNDERGROUND then
                print("[Farm] Moving underground")
                _G.AF_STATE = "MOVING_UNDERGROUND"
                
                local undergroundPos = Vector3.new(
                    humanoidRootPart.Position.X,
                    _G.AF_START_HEIGHT,
                    humanoidRootPart.Position.Z
                )
                
                -- Look towards farm position
                local lookVector = (_G.AF_TARGET_POS.Position - undergroundPos).Unit
                local undergroundCFrame = CFrame.new(undergroundPos, undergroundPos + lookVector)
                
                lerpTo(undergroundCFrame, "IDLE")
                _G.AF_WENT_UNDERGROUND = true
            else
                -- Already went underground, go to farm
                print("[Farm] Moving to farm position")
                _G.AF_STATE = "MOVING_TO_FARM"
                lerpTo(_G.AF_TARGET_POS, "IDLE")
            end
        else
            -- Already underground, go to farm
            print("[Farm] Moving to farm position")
            _G.AF_STATE = "MOVING_TO_FARM"
            lerpTo(_G.AF_TARGET_POS, "IDLE")
        end
    end

    -- Start farm
    local function startFarm()
        if _G.AF_LOOP_CONNECTION then
            _G.AF_LOOP_CONNECTION:Disconnect()
        end
        
        -- Reset flags
        _G.AF_STATE = "IDLE"
        _G.AF_AT_FARM_POSITION = false
        _G.AF_WENT_UNDERGROUND = false
        
        -- Get current level and update target
        _G.AF_CURRENT_LEVEL = getCurrentLevel()
        updateFarmEssenceTarget()
        
        -- Enable noclip and flight for farm
        enableFarmMovement()
        
        _G.AF_LOOP_CONNECTION = RunService.Heartbeat:Connect(function()
            local success, err = pcall(farmLogic)
            if not success then
                print("[Farm] Error in farmLogic:", err)
            end
        end)
        
        print("[Farm] Auto Farm Started")
        print("[Farm] Speed:", _G.AF_SPEED, "studs/sec")
        print("[Farm] Farming for", _G.AF_LEVEL_UPS_TO_FARM, "level ups")
        print("[Farm] Current level:", _G.AF_CURRENT_LEVEL)
        print("[Farm] Target essence:", _G.AF_FARM_ESSENCE_TARGET)
    end

    -- Stop farm
    local function stopFarm()
        if _G.AF_LOOP_CONNECTION then
            _G.AF_LOOP_CONNECTION:Disconnect()
            _G.AF_LOOP_CONNECTION = nil
        end
        
        if _G.AF_CURRENT_MOVEMENT then
            _G.AF_CURRENT_MOVEMENT:Disconnect()
            _G.AF_CURRENT_MOVEMENT = nil
        end
        
        _G.AF_STATE = "IDLE"
        _G.AF_AT_FARM_POSITION = false
        _G.AF_WENT_UNDERGROUND = false
        
        -- Disable farm movement features
        disableFarmMovement()
        
        print("[Farm] Auto Farm Stopped")
    end

    -- UI Elements
    FarmTab:CreateSection("Movement Settings")

    local FarmToggle = FarmTab:CreateToggle({
        Name = "Enable Auto Farm",
        CurrentValue = _G.AF_ON,
        Flag = "AutoFarm",
        Callback = function(val)
            _G.AF_ON = val
            if val then
                startFarm()
                Rayfield:Notify({
                    Title = "Auto Farm Started",
                    Content = "Player will now farm automatically with smooth LERP movement.",
                    Duration = 3
                })
            else
                stopFarm()
                Rayfield:Notify({
                    Title = "Auto Farm Stopped",
                    Content = "Farming has been stopped.",
                    Duration = 2
                })
            end
        end,
    })

    FarmTab:CreateSlider({
        Name = "LERP Speed",
        Range = {10, 200},
        Increment = 5,
        Suffix = " studs/sec",
        CurrentValue = _G.AF_SPEED,
        Flag = "LerpSpeed",
        Callback = function(val)
            _G.AF_SPEED = val
            print("[Farm] Speed updated to:", val, "studs/sec")
        end,
    })

    FarmTab:CreateSection("Essence Farming")

    FarmTab:CreateSlider({
        Name = "Level Ups Before Collection",
        Range = {1, 3},
        Increment = 1,
        Suffix = " level ups",
        CurrentValue = _G.AF_LEVEL_UPS_TO_FARM,
        Flag = "LevelUpsToFarm",
        Callback = function(val)
            _G.AF_LEVEL_UPS_TO_FARM = val
            if _G.AF_ON then
                updateFarmEssenceTarget()
            end
            print("[Farm] Will collect after", val, "level ups worth of essence")
        end,
    })

    FarmTab:CreateButton({
        Name = "Update Current Level",
        Callback = function()
            _G.AF_CURRENT_LEVEL = getCurrentLevel()
            updateFarmEssenceTarget()
            Rayfield:Notify({
                Title = "Level Updated",
                Content = string.format("Current Level: %d\nEssence Target: %d\nLevel Goal: %d", 
                    _G.AF_CURRENT_LEVEL, 
                    _G.AF_FARM_ESSENCE_TARGET,
                    _G.AF_CURRENT_LEVEL + _G.AF_LEVEL_UPS_TO_FARM),
                Duration = 5
            })
        end,
    })

    -- Auto restart on character respawn
    player.CharacterAdded:Connect(function()
        if _G.AF_ON then
            task.wait(2) -- Wait for character to fully load
            
            -- Reset flags for new character
            _G.AF_AT_FARM_POSITION = false
            _G.AF_WENT_UNDERGROUND = false
            _G.AF_STATE = "IDLE"
            
            -- Get new level
            _G.AF_CURRENT_LEVEL = getCurrentLevel()
            updateFarmEssenceTarget()
            
            -- Enable farm movement
            enableFarmMovement()
            
            startFarm()
        end
    end)

    -- Handle movement cancellation when character changes
    game:GetService("Players").LocalPlayer:GetPropertyChangedSignal("Character"):Connect(function()
        if _G.AF_CURRENT_MOVEMENT then
            _G.AF_CURRENT_MOVEMENT:Disconnect()
            _G.AF_CURRENT_MOVEMENT = nil
        end
        _G.AF_STATE = "IDLE"
        _G.AF_AT_FARM_POSITION = false
        _G.AF_WENT_UNDERGROUND = false
    end)

    -- Initial status
    print("[Farm] Auto Farm Module Loaded")
    print("[Farm] Using accurate essence costs table (Level 1-40)")
    print("[Farm] Post-fight delay: 2 seconds")
    print("[Farm] Noclip and Flight enabled during farm")

    -- =========================================================
    -- PLAYER SECTION (Optimized with State Persistence)
    -- =========================================================
    local PlayerTab = Window:CreateTab("Player", "hand-metal")
    PlayerTab:CreateSection("Player Main")
    PlayerTab:CreateLabel("Tuff player stuff")

    local WS_Enabled = false
    local WS_Value = 16
    local JP_Enabled = false
    local JP_Value = 50
    -- State variables - MAKE THESE GLOBAL FOR FARM TO ACCESS
    _G.NOCLIP_ENABLED = false
    _G.FLIGHT_ENABLED = false
    local FLIGHT_SPEED = 50

    -- Optimized movement loop
    local movementConn
    local noclipConn
    local flightConn
    local flightBodyVelocity

    -- Helper function to safely disconnect connections
    local function safeDisconnect(connection)
        if connection and typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
        return nil
    end

    -- Cleanup function for noclip - RESTORES COLLISIONS
    local originalCollisionStates = {}
    
    local function cleanupNoclip()
        _G.NOCLIP_ENABLED = false
        if noclipConn then
            noclipConn = safeDisconnect(noclipConn)
        end
        -- RESTORE original collision states
        local char = player.Character
        if char then
            for part, originalState in pairs(originalCollisionStates) do
                if part and part.Parent and originalState ~= nil then
                    pcall(function()
                        part.CanCollide = originalState
                    end)
                end
            end
            -- Also restore collisions for all parts (in case we missed some)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and originalCollisionStates[part] == nil then
                    pcall(function()
                        part.CanCollide = true  -- Default to true if we don't know original state
                    end)
                end
            end
        end
        originalCollisionStates = {}
    end

    -- Cleanup function for flight - RESTORES GRAVITY AND NORMAL MOVEMENT
    local function cleanupFlight()
        _G.FLIGHT_ENABLED = false
        if flightConn then
            flightConn = safeDisconnect(flightConn)
        end
        if flightBodyVelocity then
            pcall(function() 
                flightBodyVelocity:Destroy() 
            end)
            flightBodyVelocity = nil
        end
    end

    -- Clean up any existing connections when script loads
    cleanupNoclip()
    cleanupFlight()

    local function updateMovementLoop()
        if movementConn then movementConn:Disconnect() end
        
        movementConn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then return end
            
            if WS_Enabled then hum.WalkSpeed = WS_Value end
            if JP_Enabled then 
                hum.JumpPower = JP_Value 
                hum.UseJumpPower = true
            end
        end)
    end

    updateMovementLoop()
    player.CharacterAdded:Connect(function()
        updateMovementLoop()
        -- Reset flight and noclip on new character
        if _G.NOCLIP_ENABLED then
            cleanupNoclip()
            pcall(function() 
                if NoclipToggle then 
                    NoclipToggle:Set(false) 
                end 
            end)
        end
        if _G.FLIGHT_ENABLED then
            cleanupFlight()
            pcall(function() 
                if FlightToggle then 
                    FlightToggle:Set(false) 
                end 
            end)
        end
    end)

    PlayerTab:CreateToggle({
        Name = "Hide Names",
        CurrentValue = false,
        Flag = "HN",
        Callback = function(val)
            local HUD = player.PlayerGui:FindFirstChild("HUD")
            if HUD then
                local holders = {"CharacterName", "ServerInfo", "Age/Region"}
                for _, name in ipairs(holders) do
                    local element = HUD:FindFirstChild(name) or 
                                (HUD.Holder and HUD.Holder:FindFirstChild(name))
                    if element then element.Visible = not val end
                end
            end
        end,
    })

    PlayerTab:CreateSection("Movement")

    PlayerTab:CreateToggle({
        Name = "Enable WalkSpeed",
        CurrentValue = WS_Enabled,
        Flag = "WSToggle",
        Callback = function(val)
            WS_Enabled = val
            if not val then
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end,
    })

    PlayerTab:CreateSlider({
        Name = "WalkSpeed Value",
        Range = {16, 150},
        Increment = 1,
        Suffix = " Speed",
        CurrentValue = WS_Value,
        Flag = "WSVal",
        Callback = function(val)
            WS_Value = val
        end,
    })

    PlayerTab:CreateToggle({
        Name = "Enable JumpPower",
        CurrentValue = JP_Enabled,
        Flag = "JPToggle",
        Callback = function(val)
            JP_Enabled = val
            if not val then
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = 50 end
            end
        end,
    })

    PlayerTab:CreateSlider({
        Name = "JumpPower Value",
        Range = {50, 200},
        Increment = 1,
        Suffix = " Power",
        CurrentValue = JP_Value,
        Flag = "JPVal",
        Callback = function(val)
            JP_Value = val
        end,
    })

    -- =========================================================
    -- NOCLIP TOGGLE (Fixed with proper collision restoration)
    -- =========================================================
    PlayerTab:CreateSection("Collision")

    local NoclipToggle = PlayerTab:CreateToggle({
        Name = "Noclip",
        CurrentValue = _G.NOCLIP_ENABLED,
        Flag = "Noclip",
        Callback = function(val)
            -- If trying to turn off but variable says already off, still run cleanup
            if not val and not _G.NOCLIP_ENABLED then
                cleanupNoclip()
                return
            end
            
            _G.NOCLIP_ENABLED = val
            
            if noclipConn then
                noclipConn = safeDisconnect(noclipConn)
            end
            
            local char = player.Character
            if not char then 
                if val then
                    -- Queue noclip for when character loads
                    player.CharacterAdded:Wait()
                    char = player.Character
                else
                    return
                end
            end
            
            if not val then
                -- IMMEDIATELY RESTORE COLLISIONS
                cleanupNoclip()
                return
            end
            
            -- Store original collision states before changing
            originalCollisionStates = {}
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    originalCollisionStates[part] = part.CanCollide
                end
            end
            
            -- Noclip loop
            noclipConn = RunService.Stepped:Connect(function()
                if not _G.NOCLIP_ENABLED then 
                    cleanupNoclip()
                    return 
                end
                
                local char = player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            -- Store state if we haven't already
                            if originalCollisionStates[part] == nil then
                                originalCollisionStates[part] = part.CanCollide
                            end
                            part.CanCollide = false
                        end
                    end
                end
            end)
        end,
    })

    -- =========================================================
    -- FLIGHT SYSTEM (Fixed with proper gravity restoration)
    -- =========================================================
    PlayerTab:CreateSection("Flight")

    local flightSpeedSlider = PlayerTab:CreateSlider({
        Name = "Flight Speed",
        Range = {20, 150},
        Increment = 5,
        Suffix = " Speed",
        CurrentValue = FLIGHT_SPEED,
        Flag = "FlightSpeed",
        Callback = function(val)
            FLIGHT_SPEED = val
            if flightBodyVelocity and flightBodyVelocity.Parent then
                flightBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000) * FLIGHT_SPEED
            end
        end,
    })

    local FlightToggle = PlayerTab:CreateToggle({
        Name = "Flight",
        CurrentValue = FLIGHT_ENABLED,
        Flag = "Flight",
        Callback = function(val)
            -- If trying to turn off but variable says already off, still run cleanup
            if not val and not FLIGHT_ENABLED then
                cleanupFlight()
                return
            end
            
            FLIGHT_ENABLED = val
            
            if flightConn then
                flightConn = safeDisconnect(flightConn)
            end
            
            if flightBodyVelocity then
                pcall(function() flightBodyVelocity:Destroy() end)
                flightBodyVelocity = nil
            end
            
            if not val then 
                -- RESTORE GRAVITY - destroy the velocity object
                cleanupFlight()
                return 
            end
            
            -- Create flight velocity object
            local char = player.Character
            if not char then 
                -- Queue flight for when character loads
                player.CharacterAdded:Wait()
                char = player.Character
            end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then 
                cleanupFlight()
                pcall(function() FlightToggle:Set(false) end)
                return 
            end
            
            -- Remove any existing velocity
            for _, obj in ipairs(root:GetChildren()) do
                if obj.Name == "FlightVelocity" then
                    obj:Destroy()
                end
            end
            
            flightBodyVelocity = Instance.new("BodyVelocity")
            flightBodyVelocity.Name = "FlightVelocity"
            flightBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000) * FLIGHT_SPEED
            flightBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            flightBodyVelocity.P = 10000
            flightBodyVelocity.Parent = root
            
            -- Flight control loop with look direction movement
            flightConn = RunService.Heartbeat:Connect(function()
                if not FLIGHT_ENABLED or not flightBodyVelocity or not flightBodyVelocity.Parent then 
                    cleanupFlight()
                    return 
                end
                
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then 
                    cleanupFlight()
                    return 
                end
                
                -- Get movement direction from camera look direction
                local cam = workspace.CurrentCamera
                local moveDirection = Vector3.new(0, 0, 0)
                
                -- Check input states
                local UIS = game:GetService("UserInputService")
                
                -- Move in the direction the camera is looking
                if UIS:IsKeyDown(Enum.KeyCode.W) then
                    moveDirection = moveDirection + cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.S) then
                    moveDirection = moveDirection - cam.CFrame.LookVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.A) then
                    moveDirection = moveDirection - cam.CFrame.RightVector
                end
                if UIS:IsKeyDown(Enum.KeyCode.D) then
                    moveDirection = moveDirection + cam.CFrame.RightVector
                end
                
                -- Q for down, E for up (vertical movement)
                if UIS:IsKeyDown(Enum.KeyCode.E) then
                    moveDirection = moveDirection + Vector3.new(0, 1, 0)
                end
                if UIS:IsKeyDown(Enum.KeyCode.Q) then
                    moveDirection = moveDirection - Vector3.new(0, 1, 0)
                end
                
                -- Normalize and apply speed (only if moving)
                if moveDirection.Magnitude > 0 then
                    moveDirection = moveDirection.Unit * FLIGHT_SPEED
                    flightBodyVelocity.Velocity = moveDirection
                else
                    flightBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                end
                
                -- Update max force for speed changes
                flightBodyVelocity.MaxForce = Vector3.new(40000, 40000, 40000) * FLIGHT_SPEED
            end)
        end,
    })

    PlayerTab:CreateButton({
        Name = "Reset Flight (if stuck)",
        Callback = function()
            cleanupFlight()
            FLIGHT_ENABLED = false
            pcall(function() 
                if FlightToggle then 
                    FlightToggle:Set(false) 
                end 
            end)
            Rayfield:Notify({
                Title = "Flight Reset",
                Content = "Flight system has been reset",
                Duration = 3
            })
        end,
    })

    -- =========================================================
    -- DUPE SECTION (Optimized)
    -- =========================================================
    local DupeTab = Window:CreateTab("Duplication", "copy")
    DupeTab:CreateSection("Item Duper Settings")

    _G.DupeScript = _G.DupeScript or {
        Enabled = false,
        ItemName = "",
        DummyName = "",
        UnequipEnabled = false,
        Interval = 0.2
    }

    local dupeConn

    DupeTab:CreateInput({
        Name = "Target Item Name",
        PlaceholderText = "e.g. Vainglorious Locket (NOT SAME AS DUMMY)",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            _G.DupeScript.ItemName = text
        end,
    })

    DupeTab:CreateInput({
        Name = "Dummy Item Name",
        PlaceholderText = "e.g. Crystal Sphere (MUST BE A GEAR)",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            _G.DupeScript.DummyName = text
        end,
    })

    local function stopDupe()
        if dupeConn then
            dupeConn:Disconnect()
            dupeConn = nil
        end
    end

    local DupeToggle = DupeTab:CreateToggle({
        Name = "Enable Item Duper",
        CurrentValue = _G.DupeScript.Enabled,
        Flag = "ItemDuper",
        Callback = function(val)
            _G.DupeScript.Enabled = val
            stopDupe()
            
            if not val then return end
            
            if _G.DupeScript.ItemName == _G.DupeScript.DummyName then
                Rayfield:Notify({
                    Title = "Invalid Configuration",
                    Content = "Target Item and Dummy Item cannot be the same!",
                    Duration = 5,
                })
                _G.DupeScript.Enabled = false
                return
            end

            dupeConn = RunService.Heartbeat:Connect(function()
                if not _G.DupeScript.Enabled then 
                    stopDupe()
                    return 
                end
                
                local toolsFolder = player.Backpack:FindFirstChild("Tools")
                if not toolsFolder then return end
                
                local foundIndex = nil
                local children = toolsFolder:GetChildren()
                
                for i, item in ipairs(children) do
                    if item.Name == _G.DupeScript.DummyName then
                        foundIndex = i
                        break
                    end
                end

                if foundIndex then
                    game:GetService("ReplicatedStorage").Remotes.Information.InventoryManage:FireServer(
                        "Use", _G.DupeScript.ItemName, children[foundIndex]
                    )
                else
                    _G.DupeScript.Enabled = false
                    stopDupe()
                    Rayfield:Notify({
                        Title = "Dupe Failed",
                        Content = "Dummy item not found in backpack.",
                        Duration = 5,
                    })
                end
            end)
        end,
    })

    DupeTab:CreateSection("Auto Unequip")

    local unequipConn
    local function stopUnequip()
        if unequipConn then
            unequipConn:Disconnect()
            unequipConn = nil
        end
    end

    DupeTab:CreateToggle({
        Name = "Auto Unequip Matches",
        CurrentValue = _G.DupeScript.UnequipEnabled,
        Flag = "AutoUnequip",
        Callback = function(val)
            _G.DupeScript.UnequipEnabled = val
            stopUnequip()
            
            if not val then return end
            
            unequipConn = RunService.Heartbeat:Connect(function()
                if not _G.DupeScript.UnequipEnabled then 
                    stopUnequip()
                    return 
                end
                
                if _G.DupeScript.ItemName == "" then return end
                
                local equipmentFolder = player.PlayerGui.StatMenu.Main.Container.Equipment
                for i = 1, 4 do
                    local slot = equipmentFolder:FindFirstChild("Gear" .. i)
                    local body = slot and slot:FindFirstChild("Body")
                    if body then
                        local label = body:FindFirstChild("TextLabel")
                        local unequipBtn = body:FindFirstChild("GearUnequip")
                        if label and label.Text == _G.DupeScript.ItemName and unequipBtn then
                            firesignal(unequipBtn.MouseButton1Click)
                        end
                    end
                end
            end)
        end,
    })
else
    Rayfield:Destroy()
end
