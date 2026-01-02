if getgenv().Rayfield then getgenv().Rayfield:Destroy() end
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

if game.PlaceId == 10595058975 then

	-- Anti Afk

	local VirtualUser = game:GetService('VirtualUser')
	
	game:GetService('Players').LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)

	-- Adonis Disabler

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
						return true
					end)
					table.insert(Hooked, Detected)
				end

				if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
					Kill = KillFunc
					local Old; Old = hookfunction(Kill, function(Info)
						print("ok")
					end)
					table.insert(Hooked, Kill)
				end
			end
		end

		local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
			local LevelOrFunc, Info = ...
			if Detected and LevelOrFunc == Detected then
				return coroutine.yield(coroutine.running())
			end
			return Old(...)
		end))

		setthreadidentity(7)
	end
	
	print("Done")

	-- Rayfield Window or sum

	local Window = Rayfield:CreateWindow({
	Name = "Arcanium - Free",
	Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
	LoadingTitle = "Welcome to Arcanium",
	LoadingSubtitle = "by Yours Truly",
	ShowText = "Arcanium", -- for mobile users to unhide rayfield, change if you'd like
	Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

	ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

	DisableRayfieldPrompts = true,
	DisableBuildWarnings = true, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

	ConfigurationSaving = {
		Enabled = true,
		FolderName = nil, -- Create a custom folder for your hub/game
		FileName = "Arcanium"
	},

	Discord = {
		Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
		Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
		RememberJoins = true -- Set this to false to make them join the discord every time they load it up
	}
	})

	local QOLTab = Window:CreateTab("Quality Of Life", "crown")
	QOLTab:CreateSection("QOL Main")
	QOLTab:CreateLabel("Use these to feel reeeeeal good")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")

	local player = Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui")
	local event = ReplicatedStorage.Remotes.Information.RemoteFunction

	local function isIndicatorInDodge(perfectCenter)
		local combat = gui:FindFirstChild("Combat")
		local block = combat and combat:FindFirstChild("Block")
		if not block or not block.Visible then return false end

		local indicator = block:FindFirstChild("Inset") and block.Inset:FindFirstChild("Indicator")
		local dodgeZone = block:FindFirstChild("Inset") and block.Inset:FindFirstChild("Dodge")

		if indicator and dodgeZone then
			local iPos = indicator.AbsolutePosition.X + (indicator.AbsoluteSize.X / 2)
			local dPos = dodgeZone.AbsolutePosition.X
			local dSize = dodgeZone.AbsoluteSize.X
			
			if perfectCenter then
				-- Semi-Legit: Targets the exact middle of the dodge zone
				local dCenter = dPos + (dSize / 2)
				return math.abs(iPos - dCenter) < 10 -- 5 pixel tolerance
			else
				-- Legit: Triggers as soon as it touches the zone
				return iPos >= dPos and iPos <= (dPos + dSize)
			end
		end
		return false
	end

	-- =========================================================
	-- UI COMPONENTS (Dropdown + Toggle)
	-- =========================================================
	local ADMethodDropdown = QOLTab:CreateDropdown({
		Name = "Dodge Method",
		Options = {"Blatant", "Semi-Legit", "Legit"},
		CurrentOption = {"Semi-Legit"},
		MultipleOptions = false,
		Callback = function(Options)
			_G.AD_METHOD = Options[1]
		end,
	})

	-- =========================================================
	-- GLOBAL SETTINGS
	-- =========================================================
	_G.AD_ON = _G.AD_ON or false
	_G.AD_METHOD = _G.AD_METHOD or "Semi-Legit"
	_G.AD_CHANCE = _G.AD_CHANCE or 100 

	local hasDodgedThisCycle = false -- Prevents spamming

	-- =========================================================
	-- REMOTE HOOK (Success Chance + Safety)
	-- =========================================================
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		local args = {...}

		if not checkcaller() and _G.AD_ON and (method == "FireServer" or method == "InvokeServer") then
			if args[2] == "DodgeMinigame" and type(args[1]) == "table" then
				-- Every time a dodge fires, roll the dice based on the slider
				local roll = math.random(1, 100)
				if roll <= _G.AD_CHANCE then
					args[1][1] = true
					args[1][2] = true
				else
					args[1][1] = true
					args[1][2] = false -- Failure state
				end
				return oldNamecall(self, unpack(args))
			end
		end
		return oldNamecall(self, ...)
	end)

	-- =========================================================
	-- UI COMPONENTS
	-- =========================================================

	local ADChanceSlider = QOLTab:CreateSlider({
		Name = "Dodge Success Chance",
		Range = {0, 100},
		Increment = 1,
		Suffix = "%",
		CurrentValue = _G.AD_CHANCE,
		Flag = "ADChance",
		Callback = function(Value)
			_G.AD_CHANCE = Value
		end,
	})

	local ADToggle = QOLTab:CreateToggle({
		Name = "Auto Dodge",
		CurrentValue = false,
		Flag = "AD",
		Callback = function(Value)
			_G.AD_ON = Value

			-- PROBLEM 1 FIX: Always clear old connection before starting
			if _G.AD_CONN then 
				_G.AD_CONN:Disconnect() 
				_G.AD_CONN = nil 
			end

			if not Value then 
				hasDodgedThisCycle = false
				return 
			end

			-- Re-acquire GUI inside the loop to avoid Problem 6 (Stale References)
			_G.AD_CONN = game:GetService("RunService").Heartbeat:Connect(function()
				if not _G.AD_ON then return end

				local pGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
				local combat = pGui and pGui:FindFirstChild("Combat")
				local block = combat and combat:FindFirstChild("Block")

				-- PROBLEM 4 FIX: Reset debounce when UI goes away
				if not block or not block.Visible then
					hasDodgedThisCycle = false
					return
				end

				-- If already fired for this specific prompt, wait for next one
				if hasDodgedThisCycle then return end

				if _G.AD_METHOD == "Blatant" then
					hasDodgedThisCycle = true
					block.Visible = false
					local pGui = game:GetService("Players").LocalPlayer.PlayerGui.Combat
					if pGui:FindFirstChild("Go") then pGui.Go.Visible = false end
					game:GetService("Players").LocalPlayer.PlayerGui.Combat.BlockBar.Visible = false
					-- Fire once. Let the Hook decide if it's a success or fail.
					event:FireServer({true, true}, "DodgeMinigame")

				elseif _G.AD_METHOD == "Semi-Legit" then
					if isIndicatorInDodge(true) then
						hasDodgedThisCycle = true
						-- PROBLEM 2 FIX: Use task.spawn to avoid yielding Heartbeat
						task.spawn(function()
							task.wait(math.random(5, 12) / 100) -- Small random human delay
							event:FireServer({true, true}, "DodgeMinigame")
						end)
					end

				elseif _G.AD_METHOD == "Legit" then
					if isIndicatorInDodge(false) then
						local goBtn = combat:FindFirstChild("Go")
						if goBtn and goBtn.Visible then
							hasDodgedThisCycle = true
							firesignal(goBtn.MouseButton1Click)
						end
					end
				end
			end)
		end,
	})

	-- =========================================================
	-- AUTO QTE SETTINGS
	-- =========================================================
	_G.AQTE_METHOD = _G.AQTE_METHOD or "Blatant"
	local activeQTEs = {} -- Debounce table for Legit mode delay

	local QTEMethodDropdown = QOLTab:CreateDropdown({
		Name = "QTE Method",
		Options = {"Blatant", "Semi-Legit"},
		CurrentOption = {"Semi-Legit"},
		MultipleOptions = false,
		Callback = function(Options)
			_G.AQTE_METHOD = Options[1]
		end,
	})

	local AQTEToggle = QOLTab:CreateToggle({
		Name = "Auto QTE",
		CurrentValue = false,
		Flag = "AQTE",
		Callback = function(Value)
			_G.AQTE_ON = Value

			if not Value then
				if _G.AQTE_CONN then _G.AQTE_CONN:Disconnect() _G.AQTE_CONN = nil end
				activeQTEs = {} 
				return
			end

			if _G.AQTE_CONN then return end

			local combat = gui:WaitForChild("Combat")

			_G.AQTE_CONN = RunService.RenderStepped:Connect(function()
				if not _G.AQTE_ON then return end

				for _, ui in ipairs(combat:GetChildren()) do
					if ui:IsA("GuiObject") and ui.Name:find("QTE") and ui.Visible then
						
						if _G.AQTE_METHOD == "Blatant" then
							-- BLATANT: Instant fire and hide
							ui.Visible = false
							if combat:FindFirstChild("Go") then combat.Go.Visible = false end
							event:FireServer(true, ui.Name)
							
						elseif _G.AQTE_METHOD == "Semi-Legit" then
							-- LEGIT: Wait 1-2 seconds, then fire
							if not activeQTEs[ui.Name] then
								activeQTEs[ui.Name] = true -- Mark as "processing"
								
								task.spawn(function()
									local delayTime = math.random(100, 200) / 100 -- Random 1.0 to 2.0
									task.wait(delayTime)
									
									-- Check if QTE is still active/visible after the wait
									if ui.Visible and _G.AQTE_ON then
										event:FireServer(true, ui.Name)
									end
									
									-- Small cooldown before this specific QTE type can be handled again
									task.wait(0.5)
									activeQTEs[ui.Name] = nil
								end)
							end
						end
					end
				end
			end)
		end,
	})

	local QOLDivider = QOLTab:CreateDivider()

	local QualityButton = QOLTab:CreateButton({
		Name = "Lower Quality",
		Callback = function()
			local Lighting = game:GetService("Lighting")
			local Terrain = workspace:FindFirstChildOfClass("Terrain")

			-- 1. Immediate Lighting & Global Quality Drop
			settings().Rendering.QualityLevel = 1
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			
			if Terrain then
				Terrain.WaterWaveSize = 0
				Terrain.WaterWaveSpeed = 0
				Terrain.WaterReflectance = 0
				Terrain.WaterTransparency = 0
			end

			-- 2. Optimized Loop (Targeting only relevant areas)
			local function Optimize(parent)
				for _, v in ipairs(parent:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Material = Enum.Material.SmoothPlastic
						v.Reflectance = 0
					elseif v:IsA("Decal") or v:IsA("Texture") then
						v.Transparency = 1 -- More efficient than clearing string
					elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
						v.Enabled = false
					elseif v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
						v.Enabled = false
					elseif v:IsA("Sky") then
						v:Destroy()
					end
					
					-- Prevent the "Freeze" by yielding every 100 iterations
					if _ % 500 == 0 then
						task.wait()
					end
				end
			end

			-- Run optimization on Workspace and Lighting
			task.spawn(function() Optimize(workspace) end)
			task.spawn(function() Optimize(Lighting) end)
			
			Rayfield:Notify({
				Title = "Quality Lowered",
				Content = "Textures and effects are being cleared in the background.",
				Duration = 3
			})
		end,
	})

	local QOLDivider = QOLTab:CreateDivider()

	-- =========================================================
	-- AUTO OPEN PRESENT (Index Path Version)
	-- =========================================================
	_G.AP_ON = _G.AP_ON or false
	_G.SavedPresentIndex = _G.SavedPresentIndex or nil -- Stores the [Number]

	local PresentToggle = QOLTab:CreateToggle({
		Name = "Auto Inf Present (Must have 1)",
		CurrentValue = false,
		Flag = "AP",
		Callback = function(Value)
			_G.AP_ON = Value

			if not Value then
				if _G.AP_CONN then
					_G.AP_CONN:Disconnect()
					_G.AP_CONN = nil
				end
				return
			end

			if _G.AP_CONN then return end

			local lastOpen = 0
			local cooldown = 0.3 -- Safety delay

			_G.AP_CONN = game:GetService("RunService").Heartbeat:Connect(function()
				if not _G.AP_ON then return end
				if os.clock() - lastOpen < cooldown then return end

				local toolsFolder = game:GetService("Players").LocalPlayer.Backpack:FindFirstChild("Tools")
				if not toolsFolder then return end

				-- 1. LOCK THE INDEX: Find the number index if we don't have one
				if _G.SavedPresentIndex == nil then
					local children = toolsFolder:GetChildren()
					for i, child in ipairs(children) do
						if child.Name == "Unopened Present" then
							_G.SavedPresentIndex = i
							break
						end
					end
				end

				-- 2. EXECUTION: Try to use the locked index path
				if _G.SavedPresentIndex then
					local children = toolsFolder:GetChildren()
					local targetPresent = children[_G.SavedPresentIndex]
					
					local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
					local presentGui = playerGui:FindFirstChild("PresentOpen")
					
					-- Fire if GUI isn't open OR if the reward is already visible (skipping the animation)
					local shouldFire = false
					if not presentGui then
						shouldFire = true
					else
						local reward = presentGui:FindFirstChild("Spinner") and presentGui.Spinner:FindFirstChild("Reward")
						if reward and reward.Visible then
							shouldFire = true
							task.wait(0.6) -- Tiny delay to let the game register the win
						end
					end

					if shouldFire then
						lastOpen = os.clock()
						local args = {
							[1] = "Use",
							[2] = "Unopened Present",
							[3] = targetPresent -- This is now the object found at the specific index
						}
						game:GetService("ReplicatedStorage").Remotes.Information.InventoryManage:FireServer(unpack(args))
						print("open new")
					end
				else
					print("[AP] Must have 1 present")
				end
			end)
		end,
	})

	local QualityButton = QOLTab:CreateButton({
	Name = "New Present",
	Callback = function()
		_G.SavedPresentIndex = nil
	end,
	})

	-- Attack Section --

	--// Auto Attack GUI (battle-truth version) + DEBUG PRINTS
	--// Assumes you already have `Window` from your UI lib.

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local player = Players.LocalPlayer
	local Fights = ReplicatedStorage:WaitForChild("Fights")

	-- =========================================================
	-- DEBUG
	-- =========================================================
	local DEBUG = true
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
	-- UI
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

			local function isOnCooldown(btn)
				local cd = btn and btn:FindFirstChild("CD")
				return (cd and cd:IsA("GuiObject") and cd.Visible) or false
			end

			local function canUse(btn)
				if not btn or not btn:IsA("GuiButton") then return false end
				if isOnCooldown(btn) then return false end
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

	local PlayerTab = Window:CreateTab("Player", "hand-metal")
	PlayerTab:CreateSection("Player Main")
	PlayerTab:CreateLabel("Tuff player stuff")

	local HNToggle = PlayerTab:CreateToggle({
		Name = "Hide Names",
		CurrentValue = false,
		Flag = "HN",
		Callback = function(Value)
			game:GetService("Players").LocalPlayer.PlayerGui.HUD.Holder.CharacterName.Visible = not Value
			game:GetService("Players").LocalPlayer.PlayerGui.HUD.ServerInfo.Visible = not Value
			game:GetService("Players").LocalPlayer.PlayerGui.HUD.ServerInfo["Age/Region"].Visible = not Value
		end,
	})

	local DupeTab = Window:CreateTab("Duplication", "copy")
	DupeTab:CreateSection("Item Duper Settings")

	_G.DupeScript = _G.DupeScript or {
		Enabled = false,
		ItemName = "",
		DummyName = "",
		UnequipEnabled = false,
		Interval = 0.2
	}

	-- Input for the Item we WANT to duplicate
	DupeTab:CreateInput({
		Name = "Target Item Name",
		PlaceholderText = "e.g. Frosty Topper (NOT SAME AS DUMMY)",
		RemoveTextAfterFocusLost = false,
		Callback = function(Text)
			_G.DupeScript.ItemName = Text
		end,
	})

	-- Input for the Item used as the Dummy
	DupeTab:CreateInput({
		Name = "Dummy Item Name",
		PlaceholderText = "e.g. Crystal Sphere (MUST BE A GEAR)",
		RemoveTextAfterFocusLost = false,
		Callback = function(Text)
			_G.DupeScript.DummyName = Text
		end,
	})

	-- The Duplication Loop
	local DupeToggle -- Define variable ahead of time so the loop can see it
	DupeToggle = DupeTab:CreateToggle({
		Name = "Enable Item Duper",
		CurrentValue = false,
		Flag = "ItemDuper",
		Callback = function(Value)
			-- 1. Validation: Prevent same-item configuration
			if Value and (_G.DupeScript.ItemName == _G.DupeScript.DummyName) then
				Rayfield:Notify({
					Title = "Invalid Configuration",
					Content = "Target Item and Dummy Item cannot be the same!",
					Duration = 5,
					Image = 4483362458,
				})
				_G.DupeScript.Enabled = false
				DupeToggle:Set(false)
				return
			end

			_G.DupeScript.Enabled = Value
			
			if Value then
				task.spawn(function()
					while _G.DupeScript.Enabled do
						local toolsFolder = player.Backpack:FindFirstChild("Tools")
						
						-- 2. Check if tools exist and inputs are filled
						if toolsFolder and _G.DupeScript.ItemName ~= "" and _G.DupeScript.DummyName ~= "" then
							local children = toolsFolder:GetChildren()
							local foundIndex = nil
							
							for i, item in ipairs(children) do
								if item.Name == _G.DupeScript.DummyName then
									foundIndex = i
									break
								end
							end

							if foundIndex then
								local args = {
									[1] = "Use",
									[2] = _G.DupeScript.ItemName,
									[3] = children[foundIndex] 
								}
								game:GetService("ReplicatedStorage").Remotes.Information.InventoryManage:FireServer(unpack(args))
							else
								-- 3. FAIL CONDITION: Dummy item disappeared or wasn't found
								_G.DupeScript.Enabled = false
								DupeToggle:Set(false) -- Visually turn off the toggle
								
								Rayfield:Notify({
									Title = "Dupe Failed",
									Content = "Dummy item '".. _G.DupeScript.DummyName .."' not found in backpack. Stopping.",
									Duration = 5,
									Image = 4483362458,
								})
								break -- Kill the loop
							end
						end
						task.wait(_G.DupeScript.Interval)
					end
				end)
			end
		end,
	})

	DupeTab:CreateSection("Auto Unequip")

	-- The Automated Unequip Loop
	DupeTab:CreateToggle({
		Name = "Auto Unequip Matches",
		CurrentValue = false,
		Flag = "AutoUnequip",
		Callback = function(Value)
			_G.DupeScript.UnequipEnabled = Value
			
			if Value then
				task.spawn(function()
					while _G.DupeScript.UnequipEnabled do
						if _G.DupeScript.ItemName ~= "" then
							local equipmentFolder = game:GetService("Players").LocalPlayer.PlayerGui.StatMenu.Main.Container.Equipment
							
							for i = 1, 4 do
								local slotName = "Gear" .. i
								local slot = equipmentFolder:FindFirstChild(slotName)
								
								-- Check for Body first since everything is inside it
								local body = slot and slot:FindFirstChild("Body")
								if body then
									local label = body:FindFirstChild("TextLabel")
									local unequipBtn = body:FindFirstChild("GearUnequip")
									
									-- Only click if the text matches AND the button exists
									if label and label.Text == _G.DupeScript.ItemName and unequipBtn then
										firesignal(unequipBtn.MouseButton1Click)
									end
								end
							end
						end
						task.wait(0.15)
					end
				end)
			end
		end,
	})
else
	Rayfield:Destroy()
end
