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
        Name = "Arcanium - Free",
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
        }
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
    _G.AD_CHANCE = _G.AD_CHANCE or 100
    _G.AQTE_ON = _G.AQTE_ON or false
    _G.AQTE_METHOD = _G.AQTE_METHOD or "Legit"
    _G.SPAM_COUNT = _G.SPAM_COUNT or 5 -- Default to 5 as requested

    -- =========================================================
    -- SINGLE-INSTANCE GUARD
    -- =========================================================
    _G.__AD_DATA = _G.__AD_DATA or {
        runId = 0,
        conn = nil,
        activeTarget = nil,
        dodging = false,
        lastUI = nil,
        qteConn = nil,
        activeQTEs = {}
    }
    local State = _G.__AD_DATA

    local function stopLogic()
        if State.conn then State.conn:Disconnect() end
        State.runId += 1
        State.conn = nil
        State.activeTarget = nil
        State.dodging = false
        State.lastUI = nil
    end

    -- =========================================================
    -- REMOTE SPAMMING HELPERS
    -- =========================================================
    local function getRemote()
        return ReplicatedStorage:FindFirstChild("Remotes") 
            and ReplicatedStorage.Remotes:FindFirstChild("Information")
            and ReplicatedStorage.Remotes.Information:FindFirstChild("RemoteFunction")
    end

    local function spamRemote(args, remoteName)
        local remote = getRemote()
        if not remote then return end
        
        local spamCount = _G.SPAM_COUNT or 5
        for i = 1, spamCount do
            task.spawn(function()
                remote:FireServer(args, remoteName)
            end)
        end
    end

    -- =========================================================
    -- QTE REMOTE SPAMMER (Exactly 5 times as requested)
    -- =========================================================
    local function spamQTERemote(qteName)
        local remote = getRemote()
        if not remote then return end
        
        -- Always send exactly 5 times for QTE as requested
        for i = 1, 5 do
            task.spawn(function()
                remote:FireServer(true, qteName)
            end)
        end
    end

    -- =========================================================
    -- HELPERS
    -- =========================================================
    local function getCombatUI()
        local playerGui = player:FindFirstChild("PlayerGui")
        return playerGui and playerGui:FindFirstChild("Combat")
    end

    local function isIndicatorInZone(zoneName, perfectCenter)
        local combat = getCombatUI()
        local block = combat and combat:FindFirstChild("Block")
        local inset = block and block:FindFirstChild("Inset")
        if not (inset and block and block.Visible) then return false end

        local indicator = inset:FindFirstChild("Indicator")
        local target = inset:FindFirstChild(zoneName)
        if not (indicator and target) then return false end

        local iX = indicator.AbsolutePosition.X + indicator.AbsoluteSize.X / 2
        local tX, tW = target.AbsolutePosition.X, target.AbsoluteSize.X
        
        if perfectCenter then
            local tC = tX + tW / 2
            return math.abs(iX - tC) < 10
        else
            return iX >= tX and iX <= (tX + tW)
        end
    end

    -- =========================================================
    -- SETTINGS UI
    -- =========================================================
    local ADMethodDropdown = QOLTab:CreateDropdown({
        Name = "Dodge Method",
        Options = {"Blatant", "Legit"},
        CurrentOption = {_G.AD_METHOD == "Semi-Legit" and "Legit" or _G.AD_METHOD},
        MultipleOptions = false,
        Callback = function(opt)
            _G.AD_METHOD = opt[1]
        end
    })

    local ADChanceSlider = QOLTab:CreateSlider({
        Name = "Dodge Success Chance",
        Range = {0, 100},
        Increment = 1,
        Suffix = "%",
        CurrentValue = _G.AD_CHANCE,
        Flag = "ADChance",
        Callback = function(val)
            _G.AD_CHANCE = val
        end
    })

    local SpamCountSlider = QOLTab:CreateSlider({
        Name = "Remote Spam Count",
        Range = {1, 20},
        Increment = 1,
        CurrentValue = _G.SPAM_COUNT,
        Flag = "SpamCount",
        Callback = function(val)
            _G.SPAM_COUNT = val
        end
    })

    -- =========================================================
    -- AUTO DODGE LOOP (Optimized)
    -- =========================================================
    local ADToggle = QOLTab:CreateToggle({
        Name = "Auto Dodge",
        CurrentValue = _G.AD_ON,
        Flag = "AD",
        Callback = function(val)
            _G.AD_ON = val
            stopLogic()
            if not val then return end

            local myId = State.runId
            State.conn = RunService.Heartbeat:Connect(function()
                if State.runId ~= myId or not _G.AD_ON then 
                    stopLogic() 
                    return 
                end

                local combat = getCombatUI()
                local block = combat and combat:FindFirstChild("Block")
                local inset = block and block:FindFirstChild("Inset")

                if not (block and inset and block.Visible) then
                    State.activeTarget = nil
                    State.dodging = false
                    State.lastUI = nil
                    return
                end

                if State.lastUI ~= inset then
                    State.activeTarget = nil
                    State.dodging = false
                    State.lastUI = inset
                end

                if State.dodging then return end

                if not State.activeTarget then
                    local hasDodge = inset:FindFirstChild("Dodge")
                    local hasBlock = inset:FindFirstChild("Block")

                    if hasDodge and hasBlock then
                        local success = (math.random(1,100) <= _G.AD_CHANCE)
                        State.activeTarget = success and "Dodge" or "Block"
                        State.willSucceed = success
                    elseif hasDodge then
                        State.activeTarget = "Dodge"
                        State.willSucceed = true
                    elseif hasBlock then
                        State.activeTarget = "Block"
                        State.willSucceed = true
                    end
                end

                if not State.activeTarget then return end

                if _G.AD_METHOD == "Blatant" then
                    State.dodging = true
                    task.spawn(function()
                        local args = {true, State.activeTarget == "Dodge"}
                        spamRemote(args, "DodgeMinigame")
                        task.wait(0.05)
                        State.dodging = false
                        State.activeTarget = nil
                    end)
                elseif _G.AD_METHOD == "Legit" then
                    if isIndicatorInZone(State.activeTarget, false) then
                        local go = combat:FindFirstChild("Go")
                        if go and go.Visible then
                            State.dodging = true
                            task.spawn(function()
                                local args = {true, State.activeTarget == "Dodge"}
                                local remote = getRemote()
                                if remote then remote:FireServer(args, "DodgeMinigame") end
                                firesignal(go.MouseButton1Click)
                                task.wait(0.05)
                                State.dodging = false
                                State.activeTarget = nil
                            end)
                        end
                    end
                end
            end)
        end
    })

    -- =========================================================
    -- AUTO QTE LOOP (Fixed and optimized)
    -- =========================================================
    local QTEMethodDropdown = QOLTab:CreateDropdown({
        Name = "QTE Method",
        Options = {"Blatant", "Legit"},
        CurrentOption = {_G.AQTE_METHOD == "Semi-Legit" and "Legit" or _G.AQTE_METHOD},
        MultipleOptions = false,
        Callback = function(opt)
            _G.AQTE_METHOD = opt[1]
        end
    })

    local function stopAutoQTE()
        if State.qteConn then 
            State.qteConn:Disconnect() 
            State.qteConn = nil 
        end
        State.activeQTEs = {}
    end

    local AQTEToggle = QOLTab:CreateToggle({
        Name = "Auto QTE",
        CurrentValue = _G.AQTE_ON,
        Flag = "AQTE",
        Callback = function(val)
            _G.AQTE_ON = val
            stopAutoQTE()
            if not val then return end

            State.qteConn = RunService.Heartbeat:Connect(function()
                if not _G.AQTE_ON then 
                    stopAutoQTE()
                    return 
                end
                
                local combat = getCombatUI()
                if not combat then return end

                for _, ui in ipairs(combat:GetChildren()) do
                    if ui:IsA("GuiObject") and ui.Name:find("QTE") and ui.Visible then
                        if not State.activeQTEs[ui.Name] then
                            State.activeQTEs[ui.Name] = true
                            
                            if _G.AQTE_METHOD == "Blatant" then
                                task.spawn(function()
                                    spamQTERemote(ui.Name)
                                    task.wait(0.5)
                                    State.activeQTEs[ui.Name] = nil
                                end)
                            elseif _G.AQTE_METHOD == "Legit" then
                                task.spawn(function()
                                    local delay = math.random(120, 240) / 1000 -- Convert to seconds
                                    task.wait(delay)
                                    if ui.Visible and _G.AQTE_ON then
                                        spamQTERemote(ui.Name)
                                    end
                                    task.wait(0.4)
                                    State.activeQTEs[ui.Name] = nil
                                end)
                            end
                        end
                    end
                end
            end)
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

    QOLTab:CreateDivider()

    -- =========================================================
    -- AUTO OPEN PRESENT (Optimized)
    -- =========================================================
    _G.AP_ON = _G.AP_ON or false
    _G.SavedPresentIndex = _G.SavedPresentIndex or nil
    _G.AP_CONN = _G.AP_CONN or nil

    local function stopAutoPresent()
        if _G.AP_CONN then
            _G.AP_CONN:Disconnect()
            _G.AP_CONN = nil
        end
    end

    local PresentToggle = QOLTab:CreateToggle({
        Name = "Auto Inf Present (Must have 1)",
        CurrentValue = _G.AP_ON,
        Flag = "AP",
        Callback = function(val)
            _G.AP_ON = val
            stopAutoPresent()
            if not val then return end

            local lastOpen = 0
            local cooldown = 0.3
            
            _G.AP_CONN = RunService.Heartbeat:Connect(function()
                if not _G.AP_ON then 
                    stopAutoPresent()
                    return 
                end
                if os.clock() - lastOpen < cooldown then return end

                local toolsFolder = player.Backpack:FindFirstChild("Tools")
                if not toolsFolder then return end

                if _G.SavedPresentIndex == nil then
                    local children = toolsFolder:GetChildren()
                    for i, child in ipairs(children) do
                        if child.Name == "Unopened Present" then
                            _G.SavedPresentIndex = i
                            break
                        end
                    end
                end

                if _G.SavedPresentIndex then
                    local children = toolsFolder:GetChildren()
                    local targetPresent = children[_G.SavedPresentIndex]
                    
                    if targetPresent and targetPresent.Name == "Unopened Present" then
                        local playerGui = player:WaitForChild("PlayerGui")
                        local presentGui = playerGui:FindFirstChild("PresentOpen")
                        
                        local shouldFire = false
                        if not presentGui then
                            shouldFire = true
                        else
                            local reward = presentGui:FindFirstChild("Spinner") and presentGui.Spinner:FindFirstChild("Reward")
                            if reward and reward.Visible then
                                shouldFire = true
                                task.wait(0.6)
                            end
                        end

                        if shouldFire then
                            lastOpen = os.clock()
                            game:GetService("ReplicatedStorage").Remotes.Information.InventoryManage:FireServer(
                                "Use", "Unopened Present", targetPresent
                            )
                        end
                    end
                end
            end)
        end,
    })

    QOLTab:CreateButton({
        Name = "Reset Present Index",
        Callback = function()
            _G.SavedPresentIndex = nil
            Rayfield:Notify({
                Title = "Present Index Reset",
                Content = "Will find new present on next run.",
                Duration = 2
            })
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
    -- PLAYER SECTION (Optimized)
    -- =========================================================
    local PlayerTab = Window:CreateTab("Player", "hand-metal")
    PlayerTab:CreateSection("Player Main")
    PlayerTab:CreateLabel("Tuff player stuff")

    local WS_Enabled = false
    local WS_Value = 16
    local JP_Enabled = false
    local JP_Value = 50

    -- Optimized movement loop
    local movementConn
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
    player.CharacterAdded:Connect(updateMovementLoop)

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
        PlaceholderText = "e.g. Frosty Topper (NOT SAME AS DUMMY)",
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
