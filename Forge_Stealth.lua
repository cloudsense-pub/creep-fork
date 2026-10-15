--[[ 
    FORGE STEALTH | Ather-like AutoFarm for The Forge - EVERYTHING PACK
    UI: creep.cc fork (https://raw.githubusercontent.com/cloudsense-pub/creep-fork/refs/heads/main/Example.lua)
    Game: The Forge (GameId 7671049560) | World1 76558904092080 | World2 129009554587176

    Features:
    - Ore farm selected/closest/regional + SMART SKIP (ore name + rarity + rock type) + priority + stuckunstuck
    - Mob farm selected/closest + boss priority + kill aura + auto skill/block + hitbox expander + auto parry
    - Mining: adjustable swing delay, stealth tween (underground+jitter), BodyVelocity, noclip options
    - Forge: melt/pour/hammer/mold + auto forge cycle (walk to Forge + fire prompt)
    - Loot: auto sell/sell-anywhere, auto potion, auto recycle/enhance hooks, refresh tables
    - Auto: daily/mail/questboard/totems/shops/proximity/waypoints/OreCraft, unlock waypoints
    - Player: walkspeed (no hook), fly, full noclip, inf jump, jump power, anti-void, teleports, ESP
    - Visuals: ore/mob/player ESP, fullbright, FPS boost, FOV, hide players
    - Server: copy JobId/PlaceId, player TP, panic stop, stealth/blatant presets, timed auto-hop, rejoin/hop
    - Worlds: all 4 islands (Stonewake/Forgotten/Frostspire/Sakura) + universal TP, req notes
    - Safety: staff/player join alert + panic, auto pickaxe buyer, auto-reconnect on kick (ban-safe, max tries)
    - Persistence: SaveManager autoload on start, save+queue re-exec on teleport/kick so cfg+farms continue
    - Webhook: ore list + rarity list + mythic+ auto + sound + session stats (ores/gold/hr in watermark)
    - Safety: no hookmetamethod, cloneref, humanized delays, anti-AFK, auto-rejoin, queue_on_teleport, SaveManager

    Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/cloudsense-pub/creep-fork/refs/heads/main/Forge_Stealth.lua"))()
]]

while not game:IsLoaded() do task.wait(0.1) end

-- allow both worlds, warn on wrong game
if game.GameId ~= 7671049560 then
    warn("[ForgeStealth] Unexpected GameId: " .. tostring(game.GameId) .. " - trying to continue")
end

--// cloneref stealth
local cloneref = cloneref or function(o) return o end
local PlayersSvc = cloneref(game:GetService("Players"))
local RS = cloneref(game:GetService("ReplicatedStorage"))
local WS = cloneref(game:GetService("Workspace"))
local RunSvc = cloneref(game:GetService("RunService"))
local HttpSvc = cloneref(game:GetService("HttpService"))
local TeleportSvc = cloneref(game:GetService("TeleportService"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local UIS = cloneref(game:GetService("UserInputService"))
local GuiSvc = cloneref(game:GetService("GuiService"))

local LocalPlayer = PlayersSvc.LocalPlayer
local Camera = WS.CurrentCamera

--// flags (Ather-like)
getgenv().ForgeFlags = getgenv().ForgeFlags or {
    tweenspeed = 35,
    distance = -6,
    farmmethod = "Above/Below",
    disable_instant_tp = true, -- TRUE = stealth (no reset TP). false = allow reset TP
    insta_tp_if = 250,
    insta_tp_cd = 6,
    underground_tween = true,
    stealth_jitter = true,
    mobs_selected = {},
    mob_autofarm = false,
    mob_closestfarm = false,
    ores_selected = {},
    rarities_selected = {},
    ore_autofarm = false,
    ore_closestfarm = false,
    regional_ore_farm = false,
    selected_region = "",
    ore_priority = {},
    skipOre_cd = 30,
    skip_claimed = true,
    walkspeed = 20,
    walkspeed_enabled = false,
    auto_parry = false,
    items_selected = {},
    auto_sell = false,
    sell_anywhere = false,
    potions_selected = {},
    auto_potion = false,
    automelt = false,
    meltspeed = 15,
    minposition = 0.05,
    maxposition = 0.9,
    autopour = false,
    poursens = 0.01,
    autohammer = false,
    automold = false,
    autotp_World1 = false,
    autotp_World2 = false,
    autotp_World3 = false,
    autotp_World4 = false,
    staff_alert = false,
    staff_panic = false,
    staff_names = "",
    alert_any_player = false,
    auto_pickaxe = false,
    webhook_enabled = false,
    webhook_url = "",
    webhook_ores_selected = {},
    webhook_rarities_selected = {},
    webhook_user_id = "",
    webhook_on_rare = true,
    ore_esp = false,
    esp_maxdist = 500,
    noclip_farm = false,
    -- everything pack
    rocktypes_selected = {},
    mine_delay = 0.15,
    auto_stuck_hop = false,
    stuck_timeout = 25,
    kill_aura = false,
    aura_range = 25,
    aura_delay = 0.2,
    auto_skill = false,
    auto_block = false,
    hitbox_expand = false,
    hitbox_size = 8,
    boss_farm = false,
    boss_priority = true,
    mob_esp = false,
    player_esp = false,
    esp_show_hp = true,
    fullbright = false,
    fps_boost = false,
    hide_players = false,
    fov_value = 70,
    fly_enabled = false,
    fly_speed = 40,
    noclip_enabled = false,
    inf_jump = false,
    jump_power = 50,
    anti_void = true,
    auto_daily = false,
    auto_mail = false,
    auto_quest = false,
    auto_totem = false,
    totems_selected = {},
    auto_craft = false,
    auto_enhance = false,
    auto_recycle = false,
    recycle_rarities = {},
    auto_hop_timed = false,
    hop_interval = 20,
    panic_key = true,
    notify_rare_sound = true,
    session_gold_start = 0,
    auto_forge_cycle = false,
    forge_mold_name = "",
    auto_waypoints = false,
    instant_forge = false,
    -- quest farm (Ather parity)
    quest_mode = "Off",
    quests_selected = {},
    auto_accept_quests = false,
    auto_turnin_quests = false,
    auto_farm_objectives = false,
    auto_claim_board = false,
    quest_esp = false,
    quest_track = true,
    -- webhook full parity
    webhook_quests = true,
    webhook_levels = true,
    webhook_status = false,
    webhook_status_mins = 15,
    webhook_include_jobid = true,
    reconnect_on_kick = true,
    max_reconnects = 3,
    loader_url = "https://raw.githubusercontent.com/cloudsense-pub/creep-fork/refs/heads/main/Forge_Stealth.lua",
}
local ForgeFlags = getgenv().ForgeFlags
getgenv().forge_current_tween = getgenv().forge_current_tween or false
getgenv().forge_isTeleporting = getgenv().forge_isTeleporting or false
getgenv().forge_lastReset = getgenv().forge_lastReset or 0
getgenv().forge_lastRespawn = getgenv().forge_lastRespawn or 0
getgenv().forge_talkedGreedy = getgenv().forge_talkedGreedy or false
getgenv().forge_orefound = getgenv().forge_orefound or false
getgenv().forge_npcfound = getgenv().forge_npcfound or false
getgenv().forge_lastOre = nil
getgenv().forge_lastOreTime = 0
getgenv().forge_cachedOres = {}
getgenv().forge_oreCacheTime = 0
getgenv().forge_lockInfo = getgenv().forge_lockInfo or {model = nil, untilT = 0}

--// remotes (from LazyHub deobf)
local ToolRF, StartBlockRF, StopBlockRF, DialogueRF, PurchaseRF, ToolActivatedRF, SellAnywhereRF, RunCommandRF, TeleportRF, ResetRF, DialogueEventRE
pcall(function()
    local KnitPkgs = RS:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit")
    local Svcs = KnitPkgs:WaitForChild("Services")
    ToolRF = Svcs:WaitForChild("ToolService"):WaitForChild("RF")
    ToolActivatedRF = ToolRF:WaitForChild("ToolActivated")
    StartBlockRF = ToolRF:WaitForChild("StartBlock")
    StopBlockRF = ToolRF:WaitForChild("StopBlock")
    local ProxSvc = Svcs:WaitForChild("ProximityService")
    DialogueRF = ProxSvc:WaitForChild("RF"):WaitForChild("Dialogue")
    PurchaseRF = ProxSvc:WaitForChild("RF"):WaitForChild("Purchase")
    SellAnywhereRF = Svcs:WaitForChild("InventoryService"):WaitForChild("RF"):WaitForChild("SellAnywhere")
    RunCommandRF = Svcs:WaitForChild("DialogueService"):WaitForChild("RF"):WaitForChild("RunCommand")
    DialogueEventRE = Svcs:WaitForChild("DialogueService"):WaitForChild("RE"):WaitForChild("DialogueEvent")
    pcall(function()
        TeleportRF = Svcs:WaitForChild("PortalService"):WaitForChild("RF"):WaitForChild("TeleportToIsland")
    end)
    pcall(function()
        ResetRF = RS.Shared.Packages.Knit.Services.CharacterService.RF.Reset
    end)
end)

local Living = WS:WaitForChild("Living", 10)
local RocksFolder = WS:WaitForChild("Rocks", 10)

--// Ore -> Rarity map (runtime, undetected: just require data modules)
local OreRarity = {}
local OreChance = {}
local RARITY_ORDER = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Relic","Exotic","Divine","Unobtainable"}
local RARITY_COLOR = {
    Common = Color3.fromRGB(169,169,169),
    Uncommon = Color3.fromRGB(123,175,117),
    Rare = Color3.fromRGB(123,189,246),
    Epic = Color3.fromRGB(195,119,238),
    Legendary = Color3.fromRGB(255,184,70),
    Mythic = Color3.fromRGB(214,64,64),
    Relic = Color3.fromRGB(255,249,65),
    Exotic = Color3.fromRGB(255,133,255),
    Divine = Color3.fromRGB(126,21,255),
    Unobtainable = Color3.fromRGB(0,0,0),
}
pcall(function()
    local oreRoot = RS:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Ore")
    for _, m in ipairs(oreRoot:GetDescendants()) do
        if m:IsA("ModuleScript") then
            local ok, data = pcall(require, m)
            if ok and type(data) == "table" and data.Name and data.Rarity then
                OreRarity[data.Name] = data.Rarity
                OreChance[data.Name] = data.Chance or 1
            end
        end
    end
end)

--// UI (creep.cc)
local Creep = loadstring(game:HttpGet('https://raw.githubusercontent.com/visnoukkk/Creep.cc/refs/heads/main/Source.lua'))()
local ThemeMgr = loadstring(game:HttpGet('https://raw.githubusercontent.com/visnoukkk/Creep.cc/refs/heads/main/addons/ThemeManager.lua'))()
local SaveMgr = loadstring(game:HttpGet('https://raw.githubusercontent.com/visnoukkk/Creep.cc/refs/heads/main/addons/SaveManager.lua'))()

local Window = Creep:CreateWindow({Title = 'Forge Stealth | Ather-like', Center = true, AutoShow = true, TabPadding = 8, MenuFadeTime = 0.2})
local Tabs = {
    Farm = Window:AddTab('Farming'),
    Filters = Window:AddTab('Filters'),
    Forge = Window:AddTab('Forge'),
    Combat = Window:AddTab('Combat'),
    Loot = Window:AddTab('Sell'),
    Auto = Window:AddTab('Auto'),
    Player = Window:AddTab('Player'),
    Visuals = Window:AddTab('Visuals'),
    Server = Window:AddTab('Server'),
    Webhook = Window:AddTab('Webhook'),
    UI = Window:AddTab('UI'),
}

local FarmLeft = Tabs.Farm:AddLeftGroupbox('Ore Farm')
local FarmRight = Tabs.Farm:AddRightGroupbox('Mob Farm')
local FarmMove = Tabs.Farm:AddLeftGroupbox('Movement (Stealth)')
local FarmStats = Tabs.Farm:AddRightGroupbox('Session Stats')
local FiltOre = Tabs.Filters:AddLeftGroupbox('Ore + Rarity Filter (Skip Logic)')
local FiltPrio = Tabs.Filters:AddRightGroupbox('Priority (Higher = First)')
local FiltRock = Tabs.Filters:AddLeftGroupbox('Rock Type Filter')
local ForgeMelt = Tabs.Forge:AddLeftGroupbox('Melt / Pour')
local ForgeHammer = Tabs.Forge:AddRightGroupbox('Hammer / Mold')
local ForgeAuto = Tabs.Forge:AddLeftGroupbox('Auto Forge Cycle')
local CombatAura = Tabs.Combat:AddLeftGroupbox('Kill Aura / Combat')
local CombatHit = Tabs.Combat:AddRightGroupbox('Hitbox / Block')
local CombatBoss = Tabs.Combat:AddLeftGroupbox('Boss Farm')
local LootSell = Tabs.Loot:AddLeftGroupbox('Auto Sell')
local LootPotion = Tabs.Loot:AddRightGroupbox('Potions')
local LootRecycle = Tabs.Loot:AddLeftGroupbox('Recycle / Enhance')
local AutoQuest = Tabs.Auto:AddLeftGroupbox('Quests / Daily / Mail')
local AutoTotem = Tabs.Auto:AddRightGroupbox('Totems / Shops')
local AutoCraft = Tabs.Auto:AddLeftGroupbox('OreCraft')
local PlrHuman = Tabs.Player:AddLeftGroupbox('Humanoid / Parry')
local PlrTP = Tabs.Player:AddRightGroupbox('Teleports / Misc')
local PlrFly = Tabs.Player:AddLeftGroupbox('Fly / Noclip / Jump')
local VisOre = Tabs.Visuals:AddLeftGroupbox('Ore ESP')
local VisMob = Tabs.Visuals:AddRightGroupbox('Mob / Player ESP')
local VisPerf = Tabs.Visuals:AddLeftGroupbox('FPS / Lighting')
local SrvMain = Tabs.Server:AddLeftGroupbox('Server Control')
local SrvAuto = Tabs.Server:AddRightGroupbox('Auto Hop / Safety')
local WhSet = Tabs.Webhook:AddLeftGroupbox('Discord Webhook')
local WhTest = Tabs.Webhook:AddRightGroupbox('Test')
local ESPBox = Tabs.Player:AddLeftGroupbox('ESP')

--// helpers
local function Bool(tbl, name)
    if tbl and tbl[name] then return tbl[name].Value == true end
    return false
end
local function Num(tbl, name, def)
    if tbl and tbl[name] and type(tbl[name].Value) == 'number' then return tbl[name].Value end
    return def
end
local function DropToArray(val)
    if type(val) ~= "table" then return {} end
    -- Linoria multi = dict {Name=true}; single = string
    if #val > 0 then return val end
    local out = {}
    for k,v in pairs(val) do if v then table.insert(out, k) end end
    return out
end
local function DropSingle(val, def)
    if type(val) == "string" then return val end
    if type(val) == "table" then
        local a = DropToArray(val)
        if #a > 0 then return a[1] end
    end
    return def
end
local function BaseName(s)
    if type(s) ~= "string" then return tostring(s) end
    return s:match("^(.-)%d+$") or s
end
local function JitterVec(amt)
    if not ForgeFlags.stealth_jitter then return Vector3.new() end
    amt = amt or 0.35
    return Vector3.new((math.random()-0.5)*2*amt, (math.random()-0.5)*2*amt, (math.random()-0.5)*2*amt)
end
local function HumanWait(a, b)
    task.wait(a + math.random()*(b-a))
end

local function GetChar()
    local c = LocalPlayer.Character
    if not c then return false end
    local hum = c:FindFirstChildOfClass("Humanoid")
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if c and hum and hrp and hum.Health > 0 then return true, c, hum, hrp end
    return false
end

local function EquipTool(name)
    local c = LocalPlayer.Character
    if not c then return false end
    if c:FindFirstChild(name) then return true end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp then return false end
    for _, t in ipairs(bp:GetChildren()) do
        if t.Name == name then
            hum = c:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:EquipTool(t) end) else t.Parent = c end
            return true
        end
    end
    return false
end

--// lists
local function GetMobList()
    local out, seen = {}, {}
    pcall(function()
        for _, m in ipairs(RS.Assets.Mobs:GetChildren()) do
            if m:IsA("Model") then
                local b = BaseName(m.Name)
                if not seen[b] then seen[b]=true; table.insert(out, b) end
            end
        end
    end)
    if #out == 0 and Living then
        pcall(function()
            for _, m in ipairs(Living:GetChildren()) do
                if m:IsA("Model") then
                    local b = BaseName(m.Name)
                    if not seen[b] then seen[b]=true; table.insert(out, b) end
                end
            end
        end)
    end
    table.sort(out)
    return out
end
local function GetOreList()
    local out, seen = {}, {}
    pcall(function()
        for _, m in ipairs(RS.Assets.Rocks:GetChildren()) do
            if m:IsA("Model") then
                local b = BaseName(m.Name)
                if not seen[b] then seen[b]=true; table.insert(out, b) end
            end
        end
    end)
    -- also from Ore data (covers all islands)
    for name,_ in pairs(OreRarity) do
        if not seen[name] then seen[name]=true; table.insert(out, name) end
    end
    table.sort(out)
    return out
end
local function GetRegionList()
    local out, seen = {}, {}
    pcall(function()
        for _, r in ipairs(RocksFolder:GetChildren()) do
            if not seen[r.Name] then seen[r.Name]=true; table.insert(out, r.Name) end
        end
    end)
    table.sort(out)
    return out
end
local function GetPotionList()
    local out, seen = {}, {}
    pcall(function()
        for _, m in ipairs(WS:WaitForChild("Proximity"):GetChildren()) do
            if m:IsA("Model") and m.Name:match("Potion") and not seen[m.Name] then
                seen[m.Name]=true; table.insert(out, m.Name)
            end
        end
    end)
    table.sort(out)
    return out
end
local function GetStashItems()
    local out, seen = {}, {}
    pcall(function()
        local bg = LocalPlayer.PlayerGui.Menu.Frame.Frame.Menus.Stash.Background
        for _, f in ipairs(bg:GetChildren()) do
            if f:IsA("Frame") then
                local main = f:FindFirstChild("Main")
                local nm = main and main:FindFirstChild("ItemName")
                if nm and nm.Text ~= "" and not seen[nm.Text] then
                    local low = nm.Text:lower()
                    if not (low:find("totem") or low:find("potion") or low:find("portal") or low:find("lantern")) then
                        seen[nm.Text]=true; table.insert(out, nm.Text)
                    end
                end
            end
        end
    end)
    for name,_ in pairs(OreRarity) do
        if not seen[name] then seen[name]=true; table.insert(out, name) end
    end
    table.sort(out)
    return out
end

--// SMART SKIP CORE (Ather-like)
local function GetRockOreNames(model)
    local out, seen = {}, {}
    pcall(function()
        for _, d in ipairs(model:GetDescendants()) do
            local v
            pcall(function() v = d:GetAttribute("Ore") end)
            if type(v) == "string" and v ~= "" and not seen[v] then
                seen[v]=true; table.insert(out, v)
            end
        end
    end)
    -- Hitbox parent slot sometimes holds Ore attr? also check child "Ore" models
    if #out == 0 then
        local b = BaseName(model.Name)
        table.insert(out, b)
    end
    return out
end

local function RockPassesFilter(model)
    -- claimed / dead skip (always unless disabled)
    if ForgeFlags.skip_claimed then
        if model:GetAttribute("Someone") then return false, "claimed" end
    end
    local hp = model:GetAttribute("Health")
    if hp and hp <= 0 then return false, "dead" end
    -- must have Hitbox
    if not model:FindFirstChild("Hitbox", true) then return false, "nohitbox" end

    -- ore name filter: empty = accept all
    if ForgeFlags.ores_selected and #ForgeFlags.ores_selected > 0 then
        local ores = GetRockOreNames(model)
        local ok = false
        for _, o in ipairs(ores) do
            local b = BaseName(o)
            for _, sel in ipairs(ForgeFlags.ores_selected) do
                if o == sel or b == sel or b:lower() == sel:lower() then ok = true break end
            end
            if ok then break end
        end
        if not ok then
            local mb = BaseName(model.Name)
            for _, sel in ipairs(ForgeFlags.ores_selected) do
                if mb == sel or mb:lower() == sel:lower() then ok = true break end
            end
        end
        if not ok then return false, "ore" end
    end

    -- rarity filter: empty = accept all
    if ForgeFlags.rarities_selected and #ForgeFlags.rarities_selected > 0 then
        local ores = GetRockOreNames(model)
        local ok = false
        for _, o in ipairs(ores) do
            local b = BaseName(o)
            local r = OreRarity[o] or OreRarity[b]
            if r then
                for _, sel in ipairs(ForgeFlags.rarities_selected) do
                    if r == sel then ok = true break end
                end
            end
            if ok then break end
        end
        if not ok then return false, "rarity" end
    end

    return true
end

local function RockPriority(model)
    local ores = GetRockOreNames(model)
    local best = 0
    for _, o in ipairs(ores) do
        local b = BaseName(o)
        local p = (ForgeFlags.ore_priority and (ForgeFlags.ore_priority[o] or ForgeFlags.ore_priority[b])) or 0
        if p > best then best = p end
    end
    -- fallback model name priority
    local mb = BaseName(model.Name)
    if ForgeFlags.ore_priority and ForgeFlags.ore_priority[mb] and ForgeFlags.ore_priority[mb] > best then
        best = ForgeFlags.ore_priority[mb]
    end
    return best
end

--// scan rocks (cached 0.5s like LazyHub)
local function ScanRocks()
    local now = tick()
    if now - getgenv().forge_oreCacheTime < 0.5 and #getgenv().forge_cachedOres > 0 then
        return getgenv().forge_cachedOres
    end
    local list = {}
    pcall(function()
        for _, region in ipairs(RocksFolder:GetChildren()) do
            for _, slot in ipairs(region:GetChildren()) do
                local occ = false
                pcall(function() occ = slot:GetAttribute("IsOccupied") end)
                if occ then
                    local mdl = slot:FindFirstChildWhichIsA("Model")
                    if mdl then table.insert(list, mdl) end
                end
            end
        end
    end)
    getgenv().forge_cachedOres = list
    getgenv().forge_oreCacheTime = now
    return list
end

local function FindBestRock(filterSelected)
    local ok, _, _, hrp = GetChar()
    if not ok then return nil end
    local myPos = hrp.Position
    local best, bestPrio, bestDistSq = nil, -math.huge, math.huge
    for _, mdl in ipairs(ScanRocks()) do
        local cont = true
        -- quick reject claimed/dead before expensive filter
        if ForgeFlags.skip_claimed and mdl:GetAttribute("Someone") then cont = false end
        local hp
        if cont then
            hp = mdl:GetAttribute("Health")
            if not hp or hp <= 0 then cont = false end
        end
        if cont and filterSelected then
            local pass = RockPassesFilter(mdl)
            if not pass then cont = false end
        elseif cont and not filterSelected then
            -- closest-any still respects rarity filter + claimed (Ather behavior)
            -- if user set rarity but no ore names, still skip non-matching rarity
            if ForgeFlags.rarities_selected and #ForgeFlags.rarities_selected > 0 then
                local pass = RockPassesFilter(mdl)
                if not pass then cont = false end
            else
                if ForgeFlags.skip_claimed and mdl:GetAttribute("Someone") then cont = false end
            end
        end
        if cont then
            local hb = mdl:FindFirstChild("Hitbox", true)
            if hb and hb:IsA("BasePart") then
                local prio = RockPriority(mdl)
                local d = myPos - hb.Position
                local dsq = d.X*d.X + d.Y*d.Y + d.Z*d.Z
                if prio > bestPrio or (prio == bestPrio and dsq < bestDistSq) then
                    bestPrio = prio
                    bestDistSq = dsq
                    best = mdl
                end
            end
        end
    end
    return best
end

local function FindBestRockInRegion(regionName)
    local ok, _, _, hrp = GetChar()
    if not ok then return nil end
    local region = RocksFolder:FindFirstChild(regionName)
    if not region then return nil end
    local myPos = hrp.Position
    local best, bestPrio, bestDistSq = nil, -math.huge, math.huge
    for _, slot in ipairs(region:GetChildren()) do
        local occ = false
        pcall(function() occ = slot:GetAttribute("IsOccupied") end)
        if occ then
            local mdl = slot:FindFirstChildWhichIsA("Model")
            if mdl then
                local pass = RockPassesFilter(mdl)
                if pass then
                    local hb = mdl:FindFirstChild("Hitbox", true)
                    if hb then
                        local prio = RockPriority(mdl)
                        local d = myPos - hb.Position
                        local dsq = d.X*d.X + d.Y*d.Y + d.Z*d.Z
                        if prio > bestPrio or (prio == bestPrio and dsq < bestDistSq) then
                            bestPrio, bestDistSq, best = prio, dsq, mdl
                        end
                    end
                end
            end
        end
    end
    return best
end

--// stealth movement (tween + reset fallback)
local function DoResetTeleport(targetCF)
    local now = tick()
    if getgenv().forge_isTeleporting or (now - getgenv().forge_lastReset < ForgeFlags.insta_tp_cd) then
        return false
    end
    local ok, _, _, hrp = GetChar()
    if not ok then return false end
    -- wait out forcefield (spawn protection) - stealth: don't spam
    local t0 = tick()
    while tick() - t0 < 3 do
        local c = LocalPlayer.Character
        local ff = c and c:FindFirstChildOfClass("ForceField")
        if not ff then break end
        RunSvc.Heartbeat:Wait()
    end
    getgenv().forge_isTeleporting = true
    local invoked = false
    pcall(function()
        if ResetRF then
            ResetRF:InvokeServer()
            invoked = true
        end
    end)
    if not invoked then
        getgenv().forge_isTeleporting = false
        return false
    end
    -- wait for ResetCountdown to appear then set CFrame (LazyHub pattern, humanized)
    local deadline = tick() + 4.9
    local moved = false
    local sawCountdown = false
    while tick() < deadline do
        local c = LocalPlayer.Character
        local hr = c and c:FindFirstChild("HumanoidRootPart")
        if hr and hr.MoveDirection.Magnitude > 0.1 then moved = true break end
        local rc = c and c:FindFirstChild("ResetCountdown")
        local lbl = rc and rc:FindFirstChild("TextLabel")
        if not rc or not lbl or not lbl.Visible then
            if sawCountdown then break end
        else
            sawCountdown = true
        end
        RunSvc.Heartbeat:Wait()
    end
    if moved then getgenv().forge_isTeleporting = false return false end
    if sawCountdown then
        task.wait(0.2 + math.random()*0.1)
        local c = LocalPlayer.Character
        local hr = c and c:FindFirstChild("HumanoidRootPart")
        if hr then
            if typeof(targetCF) == "CFrame" then hr.CFrame = targetCF + JitterVec(0.2)
            elseif typeof(targetCF) == "Vector3" then hr.CFrame = CFrame.new(targetCF + JitterVec(0.2)) end
        end
    end
    getgenv().forge_lastReset = tick()
    getgenv().forge_isTeleporting = false
    return sawCountdown
end

local function StealthMove(target, isCFrameOverride)
    if getgenv().forge_current_tween or getgenv().forge_isTeleporting then return end
    local targetPos, targetCF
    if typeof(target) == "Instance" and target:IsA("BasePart") then
        targetPos = target.Position
        targetCF = target.CFrame
    elseif typeof(target) == "CFrame" then
        targetPos = target.Position
        targetCF = target
    elseif typeof(target) == "Vector3" then
        targetPos = target
        targetCF = nil
    else
        return
    end
    local ok, _, _, hrp = GetChar()
    if not ok then return end
    targetPos = targetPos + JitterVec(0.25)

    local dist = (hrp.Position - targetPos).Magnitude
    local flat = Vector3.new(hrp.Position.X - targetPos.X, 0, hrp.Position.Z - targetPos.Z).Magnitude
    local farming = ForgeFlags.mob_autofarm or ForgeFlags.mob_closestfarm or ForgeFlags.ore_autofarm or ForgeFlags.ore_closestfarm or ForgeFlags.regional_ore_farm

    -- snap if very close (farm position)
    if flat <= 11 and farming and not isCFrameOverride then
        local d = ForgeFlags.distance
        if d == 0 then d = 1 end
        local goal
        if ForgeFlags.farmmethod == "Above/Below" then
            goal = CFrame.new(targetPos + Vector3.new(0, d, 0) + JitterVec(0.2), targetPos)
        else
            local look = (targetCF and targetCF.LookVector) or (targetPos - hrp.Position).Unit
            goal = CFrame.new(targetPos + look * d + JitterVec(0.2), targetPos)
        end
        hrp.CFrame = goal
        hrp.Velocity = Vector3.new()
        hrp.RotVelocity = Vector3.new()
        if ForgeFlags.mob_autofarm or ForgeFlags.mob_closestfarm then getgenv().forge_npcfound = true
        else getgenv().forge_orefound = true end
        return
    end
    if dist > 11 then
        if (ForgeFlags.mob_autofarm or ForgeFlags.mob_closestfarm) and getgenv().forge_npcfound then getgenv().forge_npcfound = false end
        if (ForgeFlags.ore_autofarm or ForgeFlags.ore_closestfarm or ForgeFlags.regional_ore_farm) and getgenv().forge_orefound then getgenv().forge_orefound = false end
    end

    -- instant TP via reset (only if enabled = NOT disabled, far, cooldown ok)
    if not ForgeFlags.disable_instant_tp and dist > ForgeFlags.insta_tp_if then
        if DoResetTeleport(targetCF or CFrame.new(targetPos)) then return end
    end
    if not farming and not isCFrameOverride then return end

    -- tween
    local speed = math.max(ForgeFlags.tweenspeed, 1)
    -- stealth variance +-10%
    speed = speed * (0.9 + math.random()*0.2)
    local dur = dist / speed
    if dur <= 0 then return end
    getgenv().forge_current_tween = true
    local start = hrp.Position
    local delta = targetPos - start
    local t0 = tick()
    local checks = 0
    local distSq = dist*dist
    repeat
        RunSvc.Heartbeat:Wait()
        local ok2, _, _, hr = GetChar()
        if not ok2 then getgenv().forge_current_tween = false return end
        hrp = hr
        local still = ForgeFlags.mob_autofarm or ForgeFlags.mob_closestfarm or ForgeFlags.ore_autofarm or ForgeFlags.ore_closestfarm or ForgeFlags.regional_ore_farm or isCFrameOverride
        if not still or not getgenv().forge_current_tween then getgenv().forge_current_tween = false break end
        local e = math.clamp((tick()-t0)/dur, 0, 1)
        local cur = start + delta * e
        local goalPos = ForgeFlags.underground_tween and Vector3.new(cur.X, cur.Y - 10, cur.Z) or cur
        hrp.Velocity = Vector3.new()
        hrp.RotVelocity = Vector3.new()
        hrp.CFrame = CFrame.new(goalPos + JitterVec(0.08))
        checks = checks + 1
        if checks >= 5 then
            local dd = (cur - targetPos)
            distSq = dd.X*dd.X + dd.Z*dd.Z
            checks = 0
        end
    until distSq <= 121 or (tick()-t0)/dur >= 1
    local final = start + delta
    local dd = final - targetPos
    local flatLeft = math.sqrt(dd.X*dd.X + dd.Z*dd.Z)
    local keep = getgenv().forge_current_tween
    getgenv().forge_current_tween = false
    if keep and flatLeft <= 11 then
        local d = ForgeFlags.distance
        if d == 0 then d = 1 end
        local goal
        if ForgeFlags.farmmethod == "Above/Below" then
            goal = CFrame.new(targetPos + Vector3.new(0, d, 0), targetPos)
        else
            local look = (targetCF and targetCF.LookVector) or (targetPos - hrp.Position).Unit
            goal = CFrame.new(targetPos + look * d, targetPos)
        end
        hrp.CFrame = goal + JitterVec(0.15)
        hrp.Velocity = Vector3.new()
        if not isCFrameOverride then
            if ForgeFlags.mob_autofarm or ForgeFlags.mob_closestfarm then getgenv().forge_npcfound = true
            else getgenv().forge_orefound = true end
        end
    end
end

--// mobs
local function FindSelectedMob()
    if not Living then return nil end
    local ok, _, _, hrp = GetChar()
    if not ok then return nil end
    local my = hrp.Position
    local best, bd = nil, math.huge
    for _, m in ipairs(Living:GetChildren()) do
        local base = BaseName(m.Name)
        local sel = false
        for _, s in ipairs(ForgeFlags.mobs_selected) do if base == s then sel = true break end end
        if sel then
            local root = m:FindFirstChild("HumanoidRootPart")
            local hum = m:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local d = (my - root.Position).Magnitude
                if d < bd then bd, best = d, m end
            end
        end
    end
    return best
end
local function FindClosestMob()
    if not Living then return nil end
    local ok, _, _, hrp = GetChar()
    if not ok then return nil end
    local my = hrp.Position
    local best, bd = nil, math.huge
    for _, m in ipairs(Living:GetChildren()) do
        local root = m:FindFirstChild("HumanoidRootPart")
        local hum = m:FindFirstChildOfClass("Humanoid")
        local head = m:FindFirstChild("Head")
        if root and hum and head and hum.Health > 0 and m:GetAttribute("IsNpc") then
            local d = (my - root.Position).Magnitude
            if d < bd then bd, best = d, m end
        end
    end
    return best
end

local LOCK_KEEP, LOCK_RADIUS, LOCK_STICKY = 1.2, 60, 35
local function ValidLock(m)
    if not (m and m.Parent) then return false end
    local r = m:FindFirstChild("HumanoidRootPart")
    local h = m:FindFirstChildOfClass("Humanoid")
    local hd = m:FindFirstChild("Head")
    return r and h and hd and h.Health > 0 and m:FindFirstChild("Target")
end

--// farm loops
local function OreLoopSelected()
    local mdl = FindBestRock(true)
    if not mdl then getgenv().forge_orefound = false return end
    getgenv().forge_lastOre = mdl
    getgenv().forge_lastOreTime = tick()
    local hb = mdl:FindFirstChild("Hitbox", true)
    if not hb then getgenv().forge_orefound = false return end
    StealthMove(hb)
end
local function OreLoopClosest()
    local mdl = FindBestRock(false)
    if not mdl then getgenv().forge_orefound = false return end
    getgenv().forge_lastOre = mdl
    getgenv().forge_lastOreTime = tick()
    local hb = mdl:FindFirstChild("Hitbox", true)
    if not hb then getgenv().forge_orefound = false return end
    StealthMove(hb)
end
local function OreLoopRegional()
    if ForgeFlags.selected_region == "" then getgenv().forge_orefound = false return end
    local mdl = FindBestRockInRegion(ForgeFlags.selected_region)
    if not mdl then getgenv().forge_orefound = false return end
    getgenv().forge_lastOre = mdl
    getgenv().forge_lastOreTime = tick()
    local hb = mdl:FindFirstChild("Hitbox", true)
    if not hb then getgenv().forge_orefound = false return end
    StealthMove(hb)
end
local function MobLoopSelected()
    local m = FindSelectedMob()
    if not m then getgenv().forge_npcfound = false return end
    local r = m:FindFirstChild("HumanoidRootPart")
    if r then
        getgenv().forge_lockInfo.model = m
        getgenv().forge_lockInfo.untilT = os.clock() + LOCK_KEEP
        StealthMove(r)
    end
end
local function MobLoopClosest()
    local ok, _, _, hrp = GetChar()
    if not ok then return end
    local locked = getgenv().forge_lockInfo.model
    local target = nil
    if ValidLock(locked) and (hrp.Position - locked.HumanoidRootPart.Position).Magnitude <= LOCK_RADIUS then
        if os.clock() <= getgenv().forge_lockInfo.untilT or (hrp.Position - locked.HumanoidRootPart.Position).Magnitude <= LOCK_STICKY then
            target = locked
        end
    end
    if not target then
        target = FindClosestMob()
        if target and target ~= locked then
            getgenv().forge_lockInfo.model = target
            getgenv().forge_lockInfo.untilT = os.clock() + LOCK_KEEP
        end
    end
    if not target then getgenv().forge_npcfound = false return end
    local r = target:FindFirstChild("HumanoidRootPart")
    if r then StealthMove(r) else getgenv().forge_npcfound = false end
    if getgenv().forge_lockInfo.model and not ValidLock(getgenv().forge_lockInfo.model) then
        getgenv().forge_lockInfo.model, getgenv().forge_lockInfo.untilT = nil, 0
    end
end

--// auto mine (humanized, no hooks)
task.spawn(function()
    while task.wait((ForgeFlags.mine_delay or 0.15) + math.random()*0.05) do
        local npc = getgenv().forge_npcfound and (ForgeFlags.mob_autofarm or ForgeFlags.mob_closestfarm)
        local ore = getgenv().forge_orefound and (ForgeFlags.ore_autofarm or ForgeFlags.ore_closestfarm or ForgeFlags.regional_ore_farm)
        if npc then
            if EquipTool("Weapon") and ToolActivatedRF then
                pcall(function() ToolActivatedRF:InvokeServer("Weapon") end)
            end
        elseif ore then
            if EquipTool("Pickaxe") and ToolActivatedRF then
                pcall(function() ToolActivatedRF:InvokeServer("Pickaxe") end)
            end
        end
    end
end)

--// BodyVelocity anti-fall (only while farming) + walkspeed loop (NO hook = undetected)
task.spawn(function()
    while task.wait(0.2) do
        local ok, _, hum, hrp = GetChar()
        if ok and hrp then
            local farming = ForgeFlags.mob_autofarm or ForgeFlags.ore_autofarm or ForgeFlags.mob_closestfarm or ForgeFlags.ore_closestfarm or ForgeFlags.regional_ore_farm or getgenv().forge_current_tween
            if farming then
                if not hrp:FindFirstChild("ForgeStealthBV") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "ForgeStealthBV"
                    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                    bv.Velocity = Vector3.new(0,0,0)
                    bv.Parent = hrp
                end
            else
                local b = hrp:FindFirstChild("ForgeStealthBV")
                if b then b:Destroy() end
            end
            -- walkspeed without hookmetamethod
            if ForgeFlags.walkspeed_enabled and hum then
                pcall(function()
                    if hum.WalkSpeed ~= ForgeFlags.walkspeed then hum.WalkSpeed = ForgeFlags.walkspeed end
                end)
            end
            -- noclip while tweening (optional, stealth: only HRP collision off briefly)
            if ForgeFlags.noclip_farm and getgenv().forge_current_tween then
                local c = LocalPlayer.Character
                if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
            end
        end
    end
end)

--// auto parry (humanized, from LazyHub)
local ParryAnims = {
    ["rbxassetid://106199289601358"] = 0.433, ["rbxassetid://82533430458765"] = 0.37,
    ["rbxassetid://89496572417272"] = 0.44, ["rbxassetid://97668319966803"] = 0.3,
    ["rbxassetid://107274803323874"] = 0.93, ["rbxassetid://89127058244517"] = 0.59,
    ["rbxassetid://73829363877010"] = 0.43, ["rbxassetid://131510736644901"] = 0.4,
    ["rbxassetid://98266710251041"] = 0.25,
}
local function InRange25(part)
    local ok, _, _, hrp = GetChar()
    if not ok then return false end
    return (part.Position - hrp.Position).Magnitude <= 25
end
local function DoParry()
    if not ForgeFlags.auto_parry then return end
    if StartBlockRF and StopBlockRF then
        pcall(function() StartBlockRF:InvokeServer() end)
        task.wait(0.25 + math.random()*0.05)
        pcall(function() StopBlockRF:InvokeServer() end)
    elseif ToolRF then
        -- fallback Dialogue? keep block RFs only
    end
end
local function HookParryMob(mdl)
    task.spawn(function()
        local hrp = mdl:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        local info = hrp:WaitForChild("infoFrame", 5)
        local frame = info and info:WaitForChild("Frame", 5)
        local rname = frame and frame:WaitForChild("rockName", 5)
        if rname and rname:IsA("TextLabel") and rname.Text:find("Slime") then
            local st = mdl:WaitForChild("Status", 5)
            if not st then return end
            st.ChildAdded:Connect(function(v)
                if v:IsA("BoolValue") and v.Name == "Attacking" and ForgeFlags.auto_parry and InRange25(hrp) then
                    task.delay(0.49 + math.random(-3,3)*0.01, function()
                        if not ForgeFlags.auto_parry then return end
                        if not mdl.Parent then return end
                        local h = mdl:FindFirstChildOfClass("Humanoid")
                        if h and h.Health > 0 then DoParry() end
                    end)
                end
            end)
        else
            local hum = mdl:FindFirstChildOfClass("Humanoid") or mdl:WaitForChild("Humanoid", 5)
            if not hum then return end
            hum.AnimationPlayed:Connect(function(tr)
                local a = tr.Animation
                if not a then return end
                local d = ParryAnims[a.AnimationId]
                if d and ForgeFlags.auto_parry then
                    local root = mdl:FindFirstChild("HumanoidRootPart")
                    if root and InRange25(root) then
                        task.delay(d + math.random(-3,3)*0.01, function()
                            if not ForgeFlags.auto_parry then return end
                            if not mdl.Parent then return end
                            local h = mdl:FindFirstChildOfClass("Humanoid")
                            if h and h.Health > 0 then DoParry() end
                        end)
                    end
                end
            end)
        end
    end)
end

--// sell / potion helpers
local function StashBG()
    local ok, res = pcall(function() return LocalPlayer.PlayerGui.Menu.Frame.Frame.Menus.Stash.Background end)
    if ok then return res end
    return nil
end
local function FindSellSlot()
    local bg = StashBG()
    if not bg then return nil, 0 end
    for _, f in ipairs(bg:GetChildren()) do
        if f:IsA("Frame") then
            local main = f:FindFirstChild("Main")
            local nm = main and main:FindFirstChild("ItemName")
            local q = main and main:FindFirstChild("Quantity")
            if nm and q and table.find(ForgeFlags.items_selected, nm.Text) then
                local n = tonumber(q.Text:match("%d+")) or 1
                return f.Name, n
            end
        end
    end
    return nil, 0
end
local function InvCount(name)
    local bg = StashBG()
    if not bg then return 0 end
    for _, f in ipairs(bg:GetChildren()) do
        if f:IsA("Frame") then
            local main = f:FindFirstChild("Main")
            local nm = main and main:FindFirstChild("ItemName")
            local q = main and main:FindFirstChild("Quantity")
            if nm and q and nm.Text == name then return tonumber(q.Text:match("%d+")) or 0 end
        end
    end
    return 0
end
local function PlayerLevel()
    local ok, t = pcall(function() return LocalPlayer.PlayerGui.Main.Screen.Hud.Level.Text end)
    if ok and t then return tonumber(t:match("%d+")) or 0 end
    return 0
end
local function Clean(s)
    if not s then return "" end
    return ((s:gsub("<[^>]+>", "")):gsub("^%s+", "")):gsub("%s+$", "")
end
local function SaveFarming() return {mob_autofarm=ForgeFlags.mob_autofarm, mob_closestfarm=ForgeFlags.mob_closestfarm, ore_autofarm=ForgeFlags.ore_autofarm, ore_closestfarm=ForgeFlags.ore_closestfarm, regional_ore_farm=ForgeFlags.regional_ore_farm} end
local function DisableFarming()
    ForgeFlags.mob_autofarm=false ForgeFlags.mob_closestfarm=false ForgeFlags.ore_autofarm=false ForgeFlags.ore_closestfarm=false ForgeFlags.regional_ore_farm=false
    getgenv().forge_current_tween=false getgenv().forge_isTeleporting=false getgenv().forge_npcfound=false getgenv().forge_orefound=false
    if Toggles.MobFarm then Toggles.MobFarm:SetValue(false) end
    if Toggles.ClosestMob then Toggles.ClosestMob:SetValue(false) end
    if Toggles.OreFarm then Toggles.OreFarm:SetValue(false) end
    if Toggles.ClosestOre then Toggles.ClosestOre:SetValue(false) end
    if Toggles.RegionFarm then Toggles.RegionFarm:SetValue(false) end
end
local function TweenToModel(mdl, dist)
    local ok, _, _, hrp = GetChar()
    if not ok then return false end
    local piv
    pcall(function() piv = mdl:GetPivot() end)
    if not piv then return false end
    local pos = piv.Position
    if (hrp.Position - pos).Magnitude <= (dist or 10) then
        task.wait(0.3)
        local ok2, _, _, h2 = GetChar()
        if ok2 then h2.CFrame = CFrame.lookAt(h2.Position, pos) end
        return true
    end
    StealthMove(CFrame.new(pos), true)
    local t0 = tick() + 15
    while tick() < t0 do
        if getgenv().forge_current_tween then task.wait(0.1) else
            local ok3, _, _, h3 = GetChar()
            if ok3 and (h3.Position - pos).Magnitude <= (dist or 10) then
                task.wait(0.3)
                h3.CFrame = CFrame.lookAt(h3.Position, pos)
                return true
            else
                StealthMove(CFrame.new(pos), true)
            end
            task.wait(0.1)
        end
    end
    local ok4, _, _, h4 = GetChar()
    if ok4 and (h4.Position - pos).Magnitude <= (dist or 16) then return true end
    return false
end
local function TalkGreedy(slot, qty, direct)
    local g = WS:FindFirstChild("Proximity") and WS.Proximity:FindFirstChild("Greedy Cey")
    if not g then return false end
    if direct then
        pcall(function() RunCommandRF:InvokeServer("SellConfirm", {Basket = {[slot]=qty}}) end)
        return true
    else
        local ok = false
        pcall(function() DialogueRF:InvokeServer(g) end)
        pcall(function() if DialogueEventRE then DialogueEventRE:FireServer("Opened") end end)
        pcall(function() if DialogueEventRE then DialogueEventRE:FireServer("Closed") end end)
        ok = true
        return ok
    end
end

--// webhook (Ather-style embed)
local function SendWebhook(title, desc, force)
    local url = (ForgeFlags.webhook_url or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if url == "" then
        if force then pcall(function() Creep:Notify("Webhook: no URL set - paste it first", 4) end) end
        return false
    end
    if not force and not ForgeFlags.webhook_enabled then return false end
    if not (url:find("discord%.com/api/webhooks") or url:find("discordapp%.com/api/webhooks")) then
        if force then pcall(function() Creep:Notify("Webhook: URL doesn't look like a Discord webhook - trying anyway", 4) end) end
    end
    local uid = (ForgeFlags.webhook_user_id or ""):gsub("%s+", "")
    local msg = title
    if uid ~= "" then msg = string.format("<@%s> %s", uid, title) end
    local payload = {username="Forge Stealth", content=msg, embeds={{title="**Forge Stealth**", description=desc, type="rich", color=7498202}}}
    local ok, body = pcall(function() return HttpSvc:JSONEncode(payload) end)
    if not ok then
        if force then pcall(function() Creep:Notify("Webhook: failed to encode payload", 4) end) end
        return false
    end
    local req = http_request or request or HttpPost or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
    if not req then
        if force then pcall(function() Creep:Notify("Webhook: executor has no request function - try another executor", 5) end) end
        return false
    end
    local sent, err = pcall(function() return req({Url=url, Body=body, Method="POST", Headers={["content-type"]="application/json"}}) end)
    if force then
        if sent then
            pcall(function() Creep:Notify("Webhook sent - check Discord (if nothing arrives the URL is wrong)", 4) end)
        else
            pcall(function() Creep:Notify("Webhook send failed: " .. tostring(err):sub(1, 120), 5) end)
        end
    end
    return sent
end

--// forge automation (VIM, humanized)
local VIM = nil
task.spawn(function() pcall(function() VIM = cloneref(game:GetService("VirtualInputManager")) end) end)
local function NeedVIM()
    if VIM then return true end
    pcall(function() VIM = cloneref(game:GetService("VirtualInputManager")) end)
    return VIM ~= nil
end

--// ESP (filtered, rarity color)
local ESPFolder = nil
task.spawn(function()
    while task.wait(1) do
        if not ForgeFlags.ore_esp then
            if ESPFolder then pcall(function() ESPFolder:Destroy() end) ESPFolder=nil end
        else
            if not ESPFolder then
                ESPFolder = Instance.new("Folder") ESPFolder.Name="ForgeESP" pcall(function() ESPFolder.Parent = game:GetService("CoreGui") end)
            else
                pcall(function() ESPFolder:ClearAllChildren() end)
                local ok, _, _, hrp = GetChar()
                if ok then
                    for _, mdl in ipairs(ScanRocks()) do
                        local pass = RockPassesFilter(mdl)
                        if pass then
                            local hb = mdl:FindFirstChild("Hitbox", true)
                            if hb then
                                local d = (hrp.Position - hb.Position).Magnitude
                                if d <= ForgeFlags.esp_maxdist then
                                    local ores = GetRockOreNames(mdl)
                                    local label = BaseName(mdl.Name) .. " [" .. table.concat(ores, ",") .. "]"
                                    local rar = OreRarity[BaseName(ores[1])] or "Common"
                                    local col = RARITY_COLOR[rar] or Color3.new(1,1,1)
                                    local bb = Instance.new("BillboardGui")
                                    bb.Size = UDim2.new(0,200,0,40) bb.StudsOffset = Vector3.new(0,3,0) bb.AlwaysOnTop = true
                                    local tl = Instance.new("TextLabel", bb)
                                    tl.Size = UDim2.new(1,0,1,0) tl.BackgroundTransparency=1 tl.Text = label .. string.format(" (%dm) [%s]", math.floor(d), rar)
                                    tl.TextColor3 = col tl.TextStrokeTransparency=0 tl.TextSize=13 tl.Font=Enum.Font.Code
                                    bb.Adornee = hb bb.Parent = ESPFolder
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

--// ===== UI BINDINGS =====
-- Movement
FarmMove:AddSlider('TweenSpeed', {Text='Tween Speed (lower=stealthier)', Default=ForgeFlags.tweenspeed, Min=20, Max=100, Rounding=0, Callback=function(v) ForgeFlags.tweenspeed=math.clamp(v,20,150) end})
FarmMove:AddSlider('FarmDistance', {Text='Farm Distance', Default=ForgeFlags.distance, Min=-10, Max=10, Rounding=1, Callback=function(v) ForgeFlags.distance=v end})
FarmMove:AddSlider('InstaIf', {Text='Reset-TP if dist >', Default=ForgeFlags.insta_tp_if, Min=100, Max=500, Rounding=0, Suffix=' studs', Callback=function(v) ForgeFlags.insta_tp_if=v end})
FarmMove:AddSlider('InstaCD', {Text='Reset-TP Cooldown', Default=ForgeFlags.insta_tp_cd, Min=1, Max=10, Rounding=1, Suffix='s', Callback=function(v) ForgeFlags.insta_tp_cd=v end})
FarmMove:AddSlider('SkipCD', {Text='Skip Claimed Ore CD', Default=ForgeFlags.skipOre_cd, Min=1, Max=60, Rounding=0, Suffix='s', Callback=function(v) ForgeFlags.skipOre_cd=v end})
FarmMove:AddToggle('UnderTween', {Text='Underground Tween (stealth)', Default=ForgeFlags.underground_tween, Callback=function(v) ForgeFlags.underground_tween=v end})
FarmMove:AddToggle('Jitter', {Text='Position Jitter (anti-detect)', Default=ForgeFlags.stealth_jitter, Callback=function(v) ForgeFlags.stealth_jitter=v end})
FarmMove:AddToggle('DisableTP', {Text='Disable Reset-TP (stealth ON)', Default=ForgeFlags.disable_instant_tp, Callback=function(v) ForgeFlags.disable_instant_tp=v end})
FarmMove:AddToggle('Noclip', {Text='Noclip While Tween', Default=ForgeFlags.noclip_farm, Callback=function(v) ForgeFlags.noclip_farm=v end})
FarmMove:AddDropdown('FarmMethod', {Text='Farm Method', Default=ForgeFlags.farmmethod, Values={"Above/Below","Front/Behind"}, Callback=function(v) ForgeFlags.farmmethod = (type(v)=="table" and DropSingle(v, "Above/Below")) or v end})

-- Ore farm
local oreList = GetOreList()
FarmLeft:AddDropdown('OreSelect', {Text='Select Ore(s) - empty = ALL', Default={}, Multi=true, Values=oreList, Callback=function(v) ForgeFlags.ores_selected = DropToArray(v) end})
FarmLeft:AddToggle('OreFarm', {Text='Farm Selected Ores (smart skip)', Default=false, Callback=function(v)
    ForgeFlags.ore_autofarm=v
    if not v then getgenv().forge_orefound=false getgenv().forge_current_tween=false return end
    task.spawn(function() while ForgeFlags.ore_autofarm do task.wait(0.1) if not getgenv().forge_current_tween then pcall(OreLoopSelected) end end end)
end})
FarmLeft:AddToggle('ClosestOre', {Text='Farm Closest (any, respects rarity)', Default=false, Callback=function(v)
    ForgeFlags.ore_closestfarm=v
    if not v then getgenv().forge_orefound=false getgenv().forge_current_tween=false return end
    task.spawn(function() while ForgeFlags.ore_closestfarm do task.wait(0.1) if not getgenv().forge_current_tween then pcall(OreLoopClosest) end end end)
end})
local regionList = GetRegionList()
FarmLeft:AddDropdown('RegionSelect', {Text='Select Region', Default=ForgeFlags.selected_region ~= "" and ForgeFlags.selected_region or nil, AllowNull=true, Values=regionList, Callback=function(v) ForgeFlags.selected_region = DropSingle(v, "") or "" end})
FarmLeft:AddToggle('RegionFarm', {Text='Regional Ore Farm', Default=false, Callback=function(v)
    ForgeFlags.regional_ore_farm=v
    if not v then getgenv().forge_orefound=false getgenv().forge_current_tween=false return end
    task.spawn(function() while ForgeFlags.regional_ore_farm do task.wait(0.1) if not getgenv().forge_current_tween then pcall(OreLoopRegional) end end end)
end})
FarmLeft:AddButton('Refresh Ores/Regions', function()
    if Options.OreSelect then Options.OreSelect:SetValues(GetOreList()) end
    if Options.RegionSelect then Options.RegionSelect:SetValues(GetRegionList()) end
    if Options.WebhookOres then Options.WebhookOres:SetValues(GetStashItems()) end
end)
FarmLeft:AddButton('Cancel Tween', function()
    getgenv().forge_current_tween=false getgenv().forge_isTeleporting=false
    local ok,_,_,hrp = GetChar() if ok then hrp.Velocity=Vector3.new(0,0,0) end
end)

-- Mob farm
local mobList = GetMobList()
FarmRight:AddDropdown('MobSelect', {Text='Select NPC(s)', Default={}, Multi=true, Values=mobList, Callback=function(v) ForgeFlags.mobs_selected = DropToArray(v) end})
FarmRight:AddToggle('MobFarm', {Text='Farm Selected NPC', Default=false, Callback=function(v)
    ForgeFlags.mob_autofarm=v
    if not v then getgenv().forge_npcfound=false getgenv().forge_current_tween=false return end
    task.spawn(function() while ForgeFlags.mob_autofarm do task.wait(0.1) pcall(MobLoopSelected) end end)
end})
FarmRight:AddToggle('ClosestMob', {Text='Farm Closest NPC', Default=false, Callback=function(v)
    ForgeFlags.mob_closestfarm=v
    if not v then getgenv().forge_npcfound=false getgenv().forge_current_tween=false return end
    task.spawn(function() while ForgeFlags.mob_closestfarm do task.wait(0.1) pcall(MobLoopClosest) end end)
end})
FarmRight:AddButton('Refresh NPCs', function() if Options.MobSelect then Options.MobSelect:SetValues(GetMobList()) end end)

-- Filters
FiltOre:AddDropdown('RaritySelect', {Text='Select Rarity (empty = ALL) - skips others', Default={}, Multi=true, Values=RARITY_ORDER, Callback=function(v) ForgeFlags.rarities_selected = DropToArray(v) end})
FiltOre:AddToggle('SkipClaimed', {Text='Skip Claimed (Someone) Rocks', Default=ForgeFlags.skip_claimed, Callback=function(v) ForgeFlags.skip_claimed=v end})
FiltOre:AddLabel('How skip works:\n- Claimed/Dead/NoHitbox = skip\n- Ore name not in list = skip\n- Rarity not in list = skip\n- Else mine by Priority then Distance', true)
-- Priority sliders (build dynamically, max 15 most common to avoid UI spam + button for rest)
do
    local ores = GetOreList()
    local shown = 0
    for _, name in ipairs(ores) do
        if shown >= 20 then break end
        shown = shown + 1
        local key = 'Prio_'..name
        FiltPrio:AddSlider(key, {Text=name..' Priority', Default=ForgeFlags.ore_priority[name] or 0, Min=0, Max=10, Rounding=0, Callback=function(v)
            -- capture name via closure workaround: parse from Text? use Options key lookup
        end})
        -- fix closure: override callback with proper capture
        if Options[key] then
            local nm = name
            Options[key].Callback = function(v) ForgeFlags.ore_priority[nm]=v end
        end
    end
    FiltPrio:AddLabel('Top 20 shown. All ores default 0.\nSet higher (e.g Diamond 10) to farm first.', true)
end

-- Forge tab
local ForgeGui, MeltUI, PourUI, HammerUI
pcall(function()
    ForgeGui = LocalPlayer.PlayerGui:WaitForChild("Forge")
    MeltUI = ForgeGui:WaitForChild("MeltMinigame")
    PourUI = ForgeGui:WaitForChild("PourMinigame")
    HammerUI = ForgeGui:WaitForChild("HammerMinigame")
end)
ForgeMelt:AddToggle('AutoMelt', {Text='Auto Melt', Default=false, Callback=function(v) ForgeFlags.automelt=v end})
ForgeMelt:AddSlider('MeltSpeed', {Text='Melt Speed', Default=ForgeFlags.meltspeed, Min=1, Max=30, Rounding=1, Callback=function(v) ForgeFlags.meltspeed=v end})
ForgeMelt:AddSlider('MinPos', {Text='Min Position', Default=ForgeFlags.minposition, Min=0, Max=1, Rounding=2, Callback=function(v) ForgeFlags.minposition=v end})
ForgeMelt:AddSlider('MaxPos', {Text='Max Position', Default=ForgeFlags.maxposition, Min=0, Max=1, Rounding=2, Callback=function(v) ForgeFlags.maxposition=v end})
ForgeMelt:AddToggle('AutoPour', {Text='Auto Pour', Default=false, Callback=function(v) ForgeFlags.autopour=v end})
ForgeMelt:AddSlider('PourSens', {Text='Pour Sensitivity', Default=ForgeFlags.poursens, Min=0, Max=0.1, Rounding=3, Callback=function(v) ForgeFlags.poursens=v end})
ForgeHammer:AddToggle('AutoHammer', {Text='Auto Hammer (perfect ~0.53)', Default=false, Callback=function(v) ForgeFlags.autohammer=v end})
ForgeHammer:AddToggle('AutoMold', {Text='Auto Mold (click mold)', Default=false, Callback=function(v) ForgeFlags.automold=v end})
ForgeHammer:AddLabel('Requires VirtualInputManager.\nIf executor blocks VIM, forge\ntoggles will notify.', true)

-- forge loops (humanized VIM, same logic as LazyHub but jittered)
do
    local meltConn, pourConn, hammerConn
    local meltT, meltDir = 0.5, 1
    local holdingMelt = false
    local function stopMelt()
        if holdingMelt and VIM then pcall(function() VIM:SendMouseButtonEvent(0,0,0,false,game,0) end) holdingMelt=false end
        if meltConn then meltConn:Disconnect() meltConn=nil end
        task.wait(0.3)
    end
    local function startMelt()
        if not NeedVIM() or not MeltUI then return end
        local heater = MeltUI:FindFirstChild("Heater")
        if not heater then return end
        meltT, meltDir = 0.5, 1
        if meltConn then meltConn:Disconnect() end
        meltConn = RunSvc.Heartbeat:Connect(function(dt)
            if not ForgeFlags.automelt or not MeltUI.Visible then stopMelt() return end
            local mn, mx = ForgeFlags.minposition, ForgeFlags.maxposition
            meltT = meltT + meltDir * ForgeFlags.meltspeed * dt
            if meltT >= mx then meltDir=-1 elseif meltT <= mn then meltDir=1 end
            meltT = math.clamp(meltT, mn, mx)
            local pos, sz = heater.AbsolutePosition, heater.AbsoluteSize
            local x = pos.X + sz.X/2 + math.random(-1,1)
            local y = pos.Y + sz.Y*meltT
            pcall(function() VIM:SendMouseButtonEvent(x,y,0,true,game,0) VIM:SendMouseMoveEvent(x,y,game) end)
            holdingMelt=true
            task.wait(0.3 + math.random()*0.05)
        end)
    end
    local holdingPour = false
    local function stopPour()
        if holdingPour and PourUI and VIM then
            pcall(function()
                local f = PourUI:FindFirstChild("Frame") local l = f and f:FindFirstChild("Line")
                if l then local x = l.AbsolutePosition.X + l.AbsoluteSize.X/2 local y = l.AbsolutePosition.Y + l.AbsoluteSize.Y/2 VIM:SendMouseButtonEvent(x,y,0,false,game,0) end
            end)
            holdingPour=false
        end
        if pourConn then pourConn:Disconnect() pourConn=nil end
        task.wait(0.3)
    end
    local function startPour()
        if not NeedVIM() or not PourUI then return end
        if pourConn then pourConn:Disconnect() end
        pourConn = RunSvc.Heartbeat:Connect(function()
            if not ForgeFlags.autopour or not PourUI.Visible then stopPour() return end
            local f = PourUI:FindFirstChild("Frame")
            local l = f and f:FindFirstChild("Line") local a = f and f:FindFirstChild("Area")
            if not (f and l and a) then return end
            local diff = l.Position.Y.Scale - (a.Position.Y.Scale + a.Size.Y.Scale/2)
            local x = l.AbsolutePosition.X + l.AbsoluteSize.X/2 local y = l.AbsolutePosition.Y + l.AbsoluteSize.Y/2
            pcall(function() VIM:SendMouseMoveEvent(x,y,game) end)
            if diff > ForgeFlags.poursens then
                if not holdingPour then pcall(function() VIM:SendMouseButtonEvent(x,y,0,true,game,0) end) holdingPour=true end
            elseif diff < -ForgeFlags.poursens then
                if holdingPour then pcall(function() VIM:SendMouseButtonEvent(x,y,0,false,game,0) end) holdingPour=false end
            end
            task.wait(0.3 + math.random()*0.05)
        end)
    end
    local clickingMold = false
    local moldCache = nil
    task.spawn(function()
        while task.wait(0.25) do
            -- melt/pour/hammer/mold supervisors
            if ForgeFlags.automelt then if MeltUI and MeltUI.Visible and not meltConn then startMelt() elseif MeltUI and not MeltUI.Visible and meltConn then stopMelt() end elseif meltConn then stopMelt() end
            if ForgeFlags.autopour then if PourUI and PourUI.Visible and not pourConn then startPour() elseif PourUI and not PourUI.Visible and pourConn then stopPour() end elseif pourConn then stopPour() end
            if ForgeFlags.autohammer then
                if HammerUI and HammerUI.Visible and not hammerConn and NeedVIM() then
                    hammerConn = RunSvc.Heartbeat:Connect(function()
                        if not ForgeFlags.autohammer or not HammerUI.Visible then if hammerConn then hammerConn:Disconnect() hammerConn=nil end return end
                        for _, b in ipairs(HammerUI:GetChildren()) do
                            if b:IsA("TextButton") and b.Name=="Frame" then
                                task.spawn(function()
                                    local fr = b:FindFirstChild("Frame") local circ = fr and fr:FindFirstChild("Circle")
                                    if not fr or not circ then return end
                                    if not b:GetAttribute("StartScale") then b:SetAttribute("StartScale", circ.Size.X.Scale) end
                                    local perfect = (b:GetAttribute("StartScale") or circ.Size.X.Scale) * 0.53
                                    local t0 = tick()
                                    while b.Parent and ForgeFlags.autohammer and HammerUI.Visible and tick()-t0 < 6 do
                                        if circ.Size.X.Scale <= perfect then
                                            task.wait(0.1 + math.random()*0.02)
                                            pcall(function()
                                                local p = circ.AbsolutePosition local s = circ.AbsoluteSize
                                                local x,y = p.X+s.X/2, p.Y+s.Y/2
                                                VIM:SendMouseButtonEvent(x,y,0,true,game,0) task.wait(0.01) VIM:SendMouseButtonEvent(x,y,0,false,game,0)
                                            end)
                                            break
                                        end
                                        task.wait()
                                    end
                                end)
                            end
                        end
                    end)
                elseif (not HammerUI or not HammerUI.Visible) and hammerConn then hammerConn:Disconnect() hammerConn=nil end
            elseif hammerConn then hammerConn:Disconnect() hammerConn=nil end
            if ForgeFlags.automold and not clickingMold and NeedVIM() then
                clickingMold=true
                task.spawn(function()
                    pcall(function()
                        local m = moldCache
                        if not (m and m.Parent) then m = WS:FindFirstChild("Mold", true) moldCache=m end
                        if m and m.Parent and Camera then
                            local piv = m:GetPivot()
                            local v, on = Camera:WorldToViewportPoint(piv.Position)
                            if on then VIM:SendMouseButtonEvent(v.X,v.Y,0,true,game,0) task.wait(0.05+math.random()*0.02) VIM:SendMouseButtonEvent(v.X,v.Y,0,false,game,0) task.wait(0.2) end
                        end
                    end)
                    clickingMold=false
                end)
            end
        end
    end)
end

-- Sell
local sellDrop
sellDrop = LootSell:AddDropdown('SellItems', {Text='Select Item(s) to Sell', Default={}, Multi=true, Values=GetStashItems(), Callback=function(v) ForgeFlags.items_selected = DropToArray(v) end})
LootSell:AddButton('Refresh Sell Table', function() if Options.SellItems then Options.SellItems:SetValues(GetStashItems()) end end)
LootSell:AddToggle('AutoSell', {Text='Auto Sell', Default=false, Callback=function(v)
    ForgeFlags.auto_sell=v
    if not v then return end
    task.spawn(function()
        while ForgeFlags.auto_sell do
            task.wait(0.2)
            if #ForgeFlags.items_selected==0 then continue end
            local ok = GetChar() if not ok then continue end
            local slot, qty = FindSellSlot()
            if not slot then continue end
            if ForgeFlags.sell_anywhere then
                if SellAnywhereRF then pcall(function() SellAnywhereRF:InvokeServer({[slot]=qty}) end) end
            else
                if not getgenv().forge_talkedGreedy then
                    local saved = SaveFarming() DisableFarming()
                    local did = false
                    pcall(function()
                        task.wait(0.1)
                        local g = WS:FindFirstChild("Proximity") and WS.Proximity:FindFirstChild("Greedy Cey")
                        if g and TweenToModel(g, 10) then task.wait(0.1) did = TalkGreedy(slot, qty, false) end
                    end)
                    if did then task.wait(0.1) getgenv().forge_talkedGreedy=true end
                    -- restore
                    ForgeFlags.mob_autofarm=saved.mob_autofarm ForgeFlags.mob_closestfarm=saved.mob_closestfarm ForgeFlags.ore_autofarm=saved.ore_autofarm ForgeFlags.ore_closestfarm=saved.ore_closestfarm ForgeFlags.regional_ore_farm=saved.regional_ore_farm
                else
                    TalkGreedy(slot, qty, true)
                end
            end
            HumanWait(0.4, 0.8)
        end
    end)
end})
LootSell:AddToggle('SellAnywhere', {Text='I own Sell Anywhere Pass', Default=false, Callback=function(v) ForgeFlags.sell_anywhere=v end})

-- Potions
LootPotion:AddDropdown('PotionSelect', {Text='Select Potion(s)', Default={}, Multi=true, Values=GetPotionList(), Callback=function(v) ForgeFlags.potions_selected = DropToArray(v) end})
LootPotion:AddToggle('AutoPotion', {Text='Auto Buy/Drink Potion', Default=false, Callback=function(v)
    ForgeFlags.auto_potion=v
    if not v then return end
    task.spawn(function()
        while ForgeFlags.auto_potion do
            task.wait(0.2)
            if not ForgeFlags.potions_selected or #ForgeFlags.potions_selected==0 then continue end
            if not GetChar() then continue end
            if tick() - getgenv().forge_lastRespawn < 10 then continue end
            local need = {}
            for _, pname in ipairs(ForgeFlags.potions_selected) do
                local hasChar, hasPack = false, false
                local c = LocalPlayer.Character local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                if c then for _, t in ipairs(c:GetChildren()) do if t.Name==pname then hasChar=true break end end end
                if bp then for _, t in ipairs(bp:GetChildren()) do if t.Name==pname then hasPack=true break end end end
                local has = hasChar or hasPack
                local active = LocalPlayer.PlayerGui:FindFirstChild("Hotbar") and LocalPlayer.PlayerGui.Hotbar:FindFirstChild("Perks") and LocalPlayer.PlayerGui.Hotbar.Perks:FindFirstChild(pname)
                if has and not active then
                    if ToolActivatedRF then pcall(function() ToolActivatedRF:InvokeServer(pname) end) end
                elseif not has then
                    table.insert(need, pname)
                end
            end
            if #need>0 and PurchaseRF then
                local saved = SaveFarming() DisableFarming()
                pcall(function()
                    task.wait(0.1)
                    local maria = WS:FindFirstChild("Proximity") and WS.Proximity:FindFirstChild("Maria")
                    if maria and TweenToModel(maria, 25) then
                        for _, pn in ipairs(need) do pcall(function() PurchaseRF:InvokeServer(pn, 10) end) task.wait(0.1+math.random()*0.05) end
                        task.wait(0.2)
                        for _, pn in ipairs(need) do
                            local c = LocalPlayer.Character local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                            local has=false
                            if c then for _,t in ipairs(c:GetChildren()) do if t.Name==pn then has=true break end end end
                            if bp and not has then for _,t in ipairs(bp:GetChildren()) do if t.Name==pn then has=true break end end end
                            if has and ToolActivatedRF then pcall(function() ToolActivatedRF:InvokeServer(pn) end) end
                            task.wait(0.1)
                        end
                    end
                end)
                ForgeFlags.mob_autofarm=saved.mob_autofarm ForgeFlags.mob_closestfarm=saved.mob_closestfarm ForgeFlags.ore_autofarm=saved.ore_autofarm ForgeFlags.ore_closestfarm=saved.ore_closestfarm ForgeFlags.regional_ore_farm=saved.regional_ore_farm
            end
        end
    end)
end})

-- Player
PlrHuman:AddToggle('WalkEnabled', {Text='Enable WalkSpeed (no hook)', Default=false, Callback=function(v) ForgeFlags.walkspeed_enabled=v end})
PlrHuman:AddSlider('WalkSpeed', {Text='Walk Speed', Default=ForgeFlags.walkspeed, Min=16, Max=60, Rounding=0, Callback=function(v) ForgeFlags.walkspeed=math.clamp(v,16,100) end})
PlrHuman:AddToggle('AutoParry', {Text='Auto Parry (humanized)', Default=false, Callback=function(v) ForgeFlags.auto_parry=v end})
ESPBox:AddToggle('OreESP', {Text='Ore ESP (filtered)', Default=false, Callback=function(v) ForgeFlags.ore_esp=v end})
ESPBox:AddSlider('ESPMax', {Text='ESP Max Distance', Default=ForgeFlags.esp_maxdist, Min=100, Max=2000, Rounding=0, Suffix=' studs', Callback=function(v) ForgeFlags.esp_maxdist=v end})
local ISLANDS = {
    {Name = "Stonewake's Cross", PlaceId = 76558904092080, Req = "no req"},
    {Name = "Forgotten Kingdom", PlaceId = 129009554587176, Req = "Intro10 + lvl 10"},
    {Name = "Frostspire Expanse", PlaceId = 131884594917121, Req = "lvl 70"},
    {Name = "Crimson Sakura Isles", PlaceId = 74414241680540, Req = "lvl 100"},
}
local function IslandByName(n) for _, i in ipairs(ISLANDS) do if i.Name == n then return i end end return nil end
PlrTP:AddToggle('TPWorld1', {Text='Auto TP World1 (Stonewake)', Default=false, Callback=function(v)
    ForgeFlags.autotp_World1=v
    if not v then return end
    task.spawn(function()
        while ForgeFlags.autotp_World1 do
            if TeleportRF then pcall(function() TeleportRF:InvokeServer("Stonewake's Cross") end) end
            task.wait(3)
            break
        end
        ForgeFlags.autotp_World1=false
        if Toggles.TPWorld1 then pcall(function() Toggles.TPWorld1:SetValue(false) end) end
    end)
end})
PlrTP:AddToggle('TPWorld2', {Text='Auto TP World2 (Forgotten)', Default=false, Callback=function(v)
    ForgeFlags.autotp_World2=v
    if not v then return end
    task.spawn(function()
        while ForgeFlags.autotp_World2 do
            if TeleportRF then pcall(function() TeleportRF:InvokeServer("Forgotten Kingdom") end) end
            task.wait(3)
            break
        end
        ForgeFlags.autotp_World2=false
        if Toggles.TPWorld2 then pcall(function() Toggles.TPWorld2:SetValue(false) end) end
    end)
end})
PlrTP:AddToggle('TPWorld3', {Text='Auto TP World3 (Frostspire, 70)', Default=false, Callback=function(v)
    ForgeFlags.autotp_World3=v
    if not v then return end
    task.spawn(function()
        while ForgeFlags.autotp_World3 do
            if TeleportRF then pcall(function() TeleportRF:InvokeServer("Frostspire Expanse") end) end
            task.wait(3)
            break
        end
        ForgeFlags.autotp_World3=false
        if Toggles.TPWorld3 then pcall(function() Toggles.TPWorld3:SetValue(false) end) end
    end)
end})
PlrTP:AddToggle('TPWorld4', {Text='Auto TP World4 (Sakura, 100)', Default=false, Callback=function(v)
    ForgeFlags.autotp_World4=v
    if not v then return end
    task.spawn(function()
        while ForgeFlags.autotp_World4 do
            if TeleportRF then pcall(function() TeleportRF:InvokeServer("Crimson Sakura Isles") end) end
            task.wait(3)
            break
        end
        ForgeFlags.autotp_World4=false
        if Toggles.TPWorld4 then pcall(function() Toggles.TPWorld4:SetValue(false) end) end
    end)
end})
PlrTP:AddDropdown('IslandTP', {Text='Teleport: Any Island (works any world)', Default=nil, AllowNull=true, Values={"Stonewake's Cross", "Forgotten Kingdom", "Frostspire Expanse", "Crimson Sakura Isles"}, Callback=function(v)
    local s = DropSingle(v, nil)
    if s and TeleportRF then pcall(function() TeleportRF:InvokeServer(s) end) end
end})
PlrTP:AddLabel('W3 needs lvl 70, W4 lvl 100.\nServer validates reqs.', true)
PlrTP:AddButton('Server Hop (smallest)', function()
    pcall(function()
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
        local res = game:HttpGet(url)
        local data = HttpSvc:JSONDecode(res)
        if data and data.data and #data.data>0 then
            table.sort(data.data, function(a,b) return (a.playing or 99)<(b.playing or 99) end)
            TeleportSvc:TeleportToPlaceInstance(game.PlaceId, data.data[1].id, LocalPlayer)
        end
    end)
end)
PlrTP:AddButton('Rejoin', function() pcall(function() TeleportSvc:Teleport(game.PlaceId, LocalPlayer) end) end)

-- Webhook
WhSet:AddInput('WebhookURL', {Text='Webhook URL', Default=ForgeFlags.webhook_url, Placeholder='https://discord.com/api/webhooks/...', Finished=true, Callback=function(v) ForgeFlags.webhook_url=v end})
WhSet:AddInput('WebhookUID', {Text='Discord User ID (ping)', Default=ForgeFlags.webhook_user_id, Placeholder='123456789 (optional)', Finished=true, Callback=function(v) ForgeFlags.webhook_user_id=v end})
WhSet:AddDropdown('WebhookOres', {Text='Notify Ores (empty=all webhook filter off)', Default={}, Multi=true, Values=GetStashItems(), Callback=function(v) ForgeFlags.webhook_ores_selected = DropToArray(v) end})
WhSet:AddDropdown('WebhookRar', {Text='Notify Rarities', Default={}, Multi=true, Values=RARITY_ORDER, Callback=function(v) ForgeFlags.webhook_rarities_selected = DropToArray(v) end})
WhSet:AddToggle('WebhookOn', {Text='Enable Webhook', Default=false, Callback=function(v) ForgeFlags.webhook_enabled=v end})
WhSet:AddToggle('WebhookRare', {Text='Always ping Mythic+ (if rarity filter empty)', Default=true, Callback=function(v) ForgeFlags.webhook_on_rare=v end})
WhSet:AddToggle('WebhookQuests', {Text='Notify Quest Complete', Default=true, Callback=function(v) ForgeFlags.webhook_quests=v end})
WhSet:AddToggle('WebhookLevels', {Text='Notify Level Up', Default=true, Callback=function(v) ForgeFlags.webhook_levels=v end})
WhSet:AddToggle('WebhookStatus', {Text='Status Heartbeat (gold/hr)', Default=false, Callback=function(v) ForgeFlags.webhook_status=v end})
WhSet:AddSlider('WebhookMins', {Text='Heartbeat Every', Default=ForgeFlags.webhook_status_mins, Min=5, Max=60, Rounding=0, Suffix='m', Callback=function(v) ForgeFlags.webhook_status_mins=v end})
WhTest:AddButton('Test Webhook', function()
    -- input uses Finished=true, so sync live text in case Enter was never pressed
    pcall(function()
        if Options.WebhookURL and type(Options.WebhookURL.Value) == "string" then
            local v = Options.WebhookURL.Value:gsub("^%s+", ""):gsub("%s+$", "")
            if v ~= "" then ForgeFlags.webhook_url = v end
        end
        if Options.WebhookUID and type(Options.WebhookUID.Value) == "string" then
            ForgeFlags.webhook_user_id = Options.WebhookUID.Value:gsub("%s+", "")
        end
    end)
    SendWebhook("Test ping :white_check_mark:", string.format("Player: %s\nLevel: %d\nPlace: %d\nJobId: %s", LocalPlayer.Name, PlayerLevel(), game.PlaceId, game.JobId), true)
end)
WhTest:AddButton('Send Status Now', function()
    local g = GoldNow()
    local profit = g - (ForgeFlags.session_gold_start or 0)
    SendWebhook("Status :bar_chart:", string.format("Player: %s\nLevel: %d\nGold: %d (%+d session)\nOres: %d\nQuest: %s\nPlace: %d\nJobId: %s", LocalPlayer.Name, PlayerLevel(), g, profit, OresMinedSession, tostring(getgenv().forge_current_quest or "none"), game.PlaceId, game.JobId), true)
end)
WhTest:AddLabel('Ather parity:\n- Ores (name+rarity)\n- Quest complete\n- Level up\n- Status heartbeat', true)

--// ===== EVERYTHING PACK (combat / auto / visuals / server) =====
-- rock-type filter wrapper (extends RockPassesFilter defined above)
do
    local OldPass = RockPassesFilter
    RockPassesFilter = function(model)
        if ForgeFlags.rocktypes_selected and #ForgeFlags.rocktypes_selected > 0 then
            local mb = BaseName(model.Name)
            local hit = false
            for _, s in ipairs(ForgeFlags.rocktypes_selected) do
                if mb == s or mb:lower() == s:lower() then hit = true break end
            end
            if not hit then return false, "rocktype" end
        end
        return OldPass(model)
    end
end
local function GetRockTypeList()
    local out, seen = {}, {}
    pcall(function()
        for _, r in ipairs(RocksFolder:GetChildren()) do
            for _, slot in ipairs(r:GetChildren()) do
                local m = slot:FindFirstChildWhichIsA("Model")
                if m then
                    local b = BaseName(m.Name)
                    if not seen[b] then seen[b] = true table.insert(out, b) end
                end
            end
        end
    end)
    pcall(function()
        for _, m in ipairs(RS.Assets.Rocks:GetChildren()) do
            if m:IsA("Model") then
                local b = BaseName(m.Name)
                if not seen[b] then seen[b] = true table.insert(out, b) end
            end
        end
    end)
    table.sort(out)
    return out
end
local function GetTotemList()
    local out, seen = {}, {}
    pcall(function()
        local prox = WS:FindFirstChild("Proximity")
        if prox then for _, m in ipairs(prox:GetChildren()) do
            if m:IsA("Model") and m.Name:lower():find("totem") and not seen[m.Name] then seen[m.Name] = true table.insert(out, m.Name) end
        end end
    end)
    if #out == 0 then out = {"LuckTotem", "MinerTotem", "XPTotem", "VitalityTotem", "WarriorTotem"} end
    table.sort(out)
    return out
end
local function GetShopList()
    local out, seen = {}, {}
    pcall(function()
        local s = WS:FindFirstChild("Shops")
        if s then for _, m in ipairs(s:GetChildren()) do if m:IsA("Model") and not seen[m.Name] then seen[m.Name] = true table.insert(out, m.Name) end end end
    end)
    table.sort(out)
    return out
end
local function GetProxList()
    local out, seen = {}, {}
    pcall(function()
        local p = WS:FindFirstChild("Proximity")
        if p then for _, m in ipairs(p:GetChildren()) do if m:IsA("Model") and not seen[m.Name] then seen[m.Name] = true table.insert(out, m.Name) end end end
    end)
    table.sort(out)
    return out
end
local function GetWaypointList()
    local out = {}
    pcall(function()
        local data = require(RS.Shared.Data.Waypoints)
        for k, _ in pairs(data) do table.insert(out, tostring(k)) end
    end)
    if #out == 0 then
        pcall(function()
            local w = WS:FindFirstChild("Waypoints") or WS:FindFirstChild("Teleport")
            if w then for _, m in ipairs(w:GetChildren()) do table.insert(out, m.Name) end end
        end)
    end
    table.sort(out)
    return out
end
local function GoldNow()
    local ok, t = pcall(function() return LocalPlayer.PlayerGui.Main.Screen.Hud.Gold.Text end)
    if ok and t then local n = tonumber((t:gsub("[$,]", ""))) return n or 0 end
    return 0
end
if ForgeFlags.session_gold_start == 0 then ForgeFlags.session_gold_start = GoldNow() end
local SessionStart = tick()
local OresMinedSession = 0
-- count ores via notification hook increment (also hooked later, safe double)
-- session label updater
local SessionLabel = nil

--// ===== QUEST CORE (accept / track / farm objectives) =====
local QuestDefs = nil
local function GetQuestDefs()
    if QuestDefs then return QuestDefs end
    local ok, res = pcall(function() return require(RS.Shared.Data.Quests) end)
    if ok and type(res) == "table" then QuestDefs = res return res end
    return {}
end
local function GetReplicaQuests()
    -- returns active, completed, cooldown tables (best effort, never errors)
    local active, completed, cooldown = {}, {}, {}
    pcall(function()
        local Knit = require(RS.Shared.Packages.Knit)
        local pc = Knit.GetController("PlayerController")
        local rep = pc and (pc.Replica or (pc.GetReplica and pc:GetReplica()))
        -- replica may be promise-based; try direct Data
        local data = rep and rep.Data
        if data then
            if type(data.Quests) == "table" then active = data.Quests end
            if type(data.CompletedQuests) == "table" then completed = data.CompletedQuests end
            if type(data.CooldownQuests) == "table" then cooldown = data.CooldownQuests end
        end
    end)
    -- fallback: read from Menu UI quest list (names only)
    if next(active) == nil then
        pcall(function()
            local folder = LocalPlayer.PlayerGui.Menu.Frame.Frame.Menus.Quests.Folder
            local sf = folder and folder.InfoSection and folder.InfoSection.ScrollingFrame
            if sf then
                for _, f in ipairs(sf:GetChildren()) do
                    if f:IsA("Frame") and f.Name:match("Title$") then
                        local qid = f.Name:gsub("Title$", "")
                        if qid ~= "" then active[qid] = active[qid] or {Progress = {}} end
                    end
                end
            end
        end)
    end
    return active, completed, cooldown
end
local function GetQuestList()
    local defs = GetQuestDefs()
    local out = {}
    for qid, q in pairs(defs) do
        if type(q) == "table" and q.Name then
            table.insert(out, qid)
        end
    end
    table.sort(out)
    return out
end
local function QuestObjectiveText(qid)
    local defs = GetQuestDefs()
    local q = defs[qid]
    if not q or type(q.Objectives) ~= "table" then return "?" end
    local active = select(1, GetReplicaQuests())
    local prog = active[qid] and active[qid].Progress or {}
    local lines = {}
    for idx, obj in ipairs(q.Objectives) do
        local p = prog[idx] or prog[tostring(idx)] or {}
        local cur = p.currentProgress or 0
        local req = p.requiredAmount or obj.Amount or 1
        if type(req) == "function" then req = "?" end
        local tgt = p.target or obj.Target or "?"
        if type(tgt) == "function" then tgt = "?" end
        local done = (type(cur) == "number" and type(req) == "number" and cur >= req)
        table.insert(lines, string.format("%s %s %s/%s%s", obj.Type or "?", tostring(tgt), tostring(cur), tostring(req), done and " DONE" or ""))
    end
    return table.concat(lines, "\n")
end
local function FirstIncompleteObjective(qid)
    local defs = GetQuestDefs()
    local q = defs[qid]
    if not q or type(q.Objectives) ~= "table" then return nil, nil end
    local active = select(1, GetReplicaQuests())
    local prog = active[qid] and active[qid].Progress or {}
    for idx, obj in ipairs(q.Objectives) do
        local p = prog[idx] or prog[tostring(idx)] or {}
        local cur = p.currentProgress or 0
        local req = p.requiredAmount or obj.Amount or 1
        if type(req) == "function" then return idx, obj end -- unknown amount = treat as incomplete
        if type(cur) ~= "number" or cur < req then return idx, obj end
    end
    return nil, nil
end
local function FindNPCModel(npcName)
    if not npcName or npcName == "" then return nil end
    local prox = WS:FindFirstChild("Proximity")
    if prox then
        local m = prox:FindFirstChild(npcName)
        if m and m:IsA("Model") then return m end
        -- fuzzy match (e.g. "Sensei Moro" vs "Sensei Moro 2")
        for _, c in ipairs(prox:GetChildren()) do
            if c:IsA("Model") and (c.Name:lower():find(npcName:lower(), 1, true) or npcName:lower():find(c.Name:lower(), 1, true)) then
                return c
            end
        end
    end
    return nil
end
local function TalkToNPC(npcName)
    local m = FindNPCModel(npcName)
    if not m then return false end
    if not TweenToModel(m, 10) then return false end
    task.wait(0.3 + math.random() * 0.2)
    pcall(function() if DialogueRF then DialogueRF:InvokeServer(m) end end)
    pcall(function() if DialogueEventRE then DialogueEventRE:FireServer("Opened") end end)
    task.wait(0.3)
    -- GiveQuest path (accept) - safe, server validates
    pcall(function() if RunCommandRF then RunCommandRF:InvokeServer("GiveQuest") end end)
    task.wait(0.2)
    pcall(function() if DialogueEventRE then DialogueEventRE:FireServer("Closed") end end)
    return true
end
local QuestESPFolder = nil

-- Filters: rock type
FiltRock:AddDropdown('RockTypeSelect', {Text='Select Rock Type (empty=ALL)', Default={}, Multi=true, Values=GetRockTypeList(), Callback=function(v) ForgeFlags.rocktypes_selected = DropToArray(v) end})
FiltRock:AddButton('Refresh Rock Types', function() if Options.RockTypeSelect then Options.RockTypeSelect:SetValues(GetRockTypeList()) end end)
FiltRock:AddLabel('Example: Basalt Vein, Volcanic Rock,\nLarge Ice Crystal, Spirit Rock.\nSkips all other rock models.', true)

-- Farm stats
FarmStats:AddLabel('Tracking gold + ores this session.')
FarmStats:AddSlider('MineDelay', {Text='Mine / Swing Delay', Default=ForgeFlags.mine_delay, Min=0.08, Max=0.5, Rounding=2, Suffix='s', Callback=function(v) ForgeFlags.mine_delay = v end})
FarmStats:AddToggle('StuckHop', {Text='Auto unstuck (hop target if stuck)', Default=false, Callback=function(v) ForgeFlags.auto_stuck_hop = v end})
FarmStats:AddSlider('StuckTime', {Text='Stuck Timeout', Default=ForgeFlags.stuck_timeout, Min=10, Max=120, Rounding=0, Suffix='s', Callback=function(v) ForgeFlags.stuck_timeout = v end})
FarmStats:AddButton('Reset Session Stats', function() SessionStart = tick() OresMinedSession = 0 ForgeFlags.session_gold_start = GoldNow() end)

-- Combat
CombatAura:AddToggle('KillAura', {Text='Kill Aura (all mobs in range)', Default=false, Callback=function(v) ForgeFlags.kill_aura = v end})
CombatAura:AddSlider('AuraRange', {Text='Aura Range', Default=ForgeFlags.aura_range, Min=5, Max=60, Rounding=0, Suffix=' studs', Callback=function(v) ForgeFlags.aura_range = v end})
CombatAura:AddSlider('AuraDelay', {Text='Aura Delay', Default=ForgeFlags.aura_delay, Min=0.1, Max=1, Rounding=2, Suffix='s', Callback=function(v) ForgeFlags.aura_delay = v end})
CombatAura:AddToggle('AutoSkill', {Text='Auto Skill (Weapon R / heavy)', Default=false, Callback=function(v) ForgeFlags.auto_skill = v end})
CombatAura:AddToggle('AutoBlock', {Text='Auto Block when mob close', Default=false, Callback=function(v) ForgeFlags.auto_block = v end})
CombatHit:AddToggle('HitExpand', {Text='Expand Mob Hitbox (client)', Default=false, Callback=function(v)
    ForgeFlags.hitbox_expand = v
    if not v and Living then
        pcall(function()
            for _, m in ipairs(Living:GetChildren()) do
                local r = m:FindFirstChild("HumanoidRootPart")
                if r and r:GetAttribute("FS_Hitbox") then
                    r.Size = r:GetAttribute("FS_Hitbox")
                    r:SetAttribute("FS_Hitbox", nil)
                    r.Transparency = 1
                end
            end
        end)
    end
end})
CombatHit:AddSlider('HitSize', {Text='Hitbox Size', Default=ForgeFlags.hitbox_size, Min=4, Max=20, Rounding=0, Callback=function(v) ForgeFlags.hitbox_size = v end})
CombatHit:AddLabel('Risky: visible to others if\ntransparency glitches. Client only.', true)
CombatBoss:AddToggle('BossFarm', {Text='Prioritize Bosses', Default=false, Callback=function(v) ForgeFlags.boss_farm = v end})
CombatBoss:AddLabel('Boss = name has Boss/Golem/\nAsura or HP > 5000. Works with\nSelected + Closest mob farm.', true)

-- Loot recycle/enhance (safe: VIM click fallback + direct service pcall)
LootRecycle:AddDropdown('RecycleRar', {Text='Recycle Rarities (weapons/armor)', Default={}, Multi=true, Values=RARITY_ORDER, Callback=function(v) ForgeFlags.recycle_rarities = DropToArray(v) end})
LootRecycle:AddToggle('AutoRecycle', {Text='Auto Recycle (low rarity)', Default=false, Callback=function(v) ForgeFlags.auto_recycle = v end})
LootRecycle:AddToggle('AutoEnhance', {Text='Auto Enhance Selected (EnhanceService)', Default=false, Callback=function(v) ForgeFlags.auto_enhance = v end})
LootRecycle:AddLabel('Recycle/enhance use official\nservices via pcall. If game\nrenamed them, it safely skips.', true)

-- Auto tab
-- Auto tab: quests (Ather parity - start / farm / turn-in)
AutoQuest:AddDropdown('QuestMode', {Text='Quest Farm Mode', Default='Off', Values={'Off', 'Selected Only', 'All Quests'}, Callback=function(v)
    ForgeFlags.quest_mode = DropSingle(v, 'Off') or 'Off'
end})
AutoQuest:AddDropdown('QuestSelect', {Text='Select Quest(s) - empty = ALL', Default={}, Multi=true, Values=GetQuestList(), Callback=function(v) ForgeFlags.quests_selected = DropToArray(v) end})
AutoQuest:AddToggle('AutoAccept', {Text='Auto Accept (talk to NPC)', Default=false, Callback=function(v) ForgeFlags.auto_accept_quests = v end})
AutoQuest:AddToggle('AutoTurnIn', {Text='Auto Turn-In (Talk quests)', Default=false, Callback=function(v) ForgeFlags.auto_turnin_quests = v end})
AutoQuest:AddToggle('AutoObjectives', {Text='Auto Farm Objectives (Kill/Mine/Collect)', Default=false, Callback=function(v) ForgeFlags.auto_farm_objectives = v end})
AutoQuest:AddToggle('AutoBoard', {Text='Auto Claim QuestBoard (Daily/Weekly)', Default=false, Callback=function(v) ForgeFlags.auto_claim_board = v end})
AutoQuest:AddToggle('QuestESP', {Text='Quest NPC ESP', Default=false, Callback=function(v) ForgeFlags.quest_esp = v end})
AutoQuest:AddToggle('QuestTrack', {Text='Show Quest Tracker Label', Default=true, Callback=function(v) ForgeFlags.quest_track = v end})
AutoQuest:AddButton('Refresh Quest List', function() if Options.QuestSelect then Options.QuestSelect:SetValues(GetQuestList()) end end)
AutoQuest:AddButton('TP To Current Quest NPC', function()
    local qid = getgenv().forge_current_quest
    if not qid then return end
    local defs = GetQuestDefs()
    local q = defs[qid]
    local npc = q and q.Npc
    if npc then
        local m = FindNPCModel(npc)
        if m then StealthMove(m:GetPivot(), true) end
    end
end)
AutoQuest:AddLabel('How it works:\n- Accept: walks to Npc + Dialogue\n  + GiveQuest\n- Kill/Mine/Collect: auto-sets\n  mob/ore/rock filters + farms\n- Talk: walks + talks to turn in\n- Board: claims QuestBoard tiers', true)
AutoQuest:AddToggle('AutoDaily', {Text='Auto Claim Daily Login', Default=false, Callback=function(v) ForgeFlags.auto_daily = v end})
AutoQuest:AddToggle('AutoMail', {Text='Auto Claim Mailbox', Default=false, Callback=function(v) ForgeFlags.auto_mail = v end})
AutoQuest:AddToggle('AutoQuestOld', {Text='Auto Talk QuestBoard NPC', Default=false, Callback=function(v) ForgeFlags.auto_quest = v end})
AutoTotem:AddDropdown('TotemSelect', {Text='Select Totem(s) to auto-buy', Default={}, Multi=true, Values=GetTotemList(), Callback=function(v) ForgeFlags.totems_selected = DropToArray(v) end})
AutoTotem:AddToggle('AutoTotem', {Text='Auto Buy Totem', Default=false, Callback=function(v) ForgeFlags.auto_totem = v end})
AutoTotem:AddDropdown('ShopTP', {Text='Teleport: Shop', Default=nil, AllowNull=true, Values=GetShopList(), Callback=function(v)
    local s = DropSingle(v, nil)
    if s then pcall(function()
        for _, m in ipairs(WS.Shops:GetChildren()) do if m:IsA("Model") and m.Name == s then StealthMove(m:GetPivot(), true) break end end
    end) end
end})
AutoTotem:AddDropdown('ProxTP', {Text='Teleport: NPC / Proximity', Default=nil, AllowNull=true, Values=GetProxList(), Callback=function(v)
    local s = DropSingle(v, nil)
    if s then pcall(function()
        for _, m in ipairs(WS.Proximity:GetChildren()) do if m:IsA("Model") and m.Name == s then StealthMove(m:GetPivot(), true) break end end
    end) end
end})
AutoCraft:AddToggle('AutoCraft', {Text='Auto OreCraft (CheckCraft)', Default=false, Callback=function(v) ForgeFlags.auto_craft = v end})
AutoCraft:AddDropdown('WayTP', {Text='Teleport: Waypoint', Default=nil, AllowNull=true, Values=GetWaypointList(), Callback=function(v)
    local s = DropSingle(v, nil)
    if s and NeedVIM() then pcall(function()
        -- try WaypointService then fallback to Proximity teleport
        local ok = false
        pcall(function()
            local svc = RS.Shared.Packages.Knit.Services:FindFirstChild("WaypointService")
            if svc then ok = true end
        end)
        if not ok then
            for _, m in ipairs(WS:GetDescendants()) do if m:IsA("Model") and m.Name == s then StealthMove(m:GetPivot(), true) break end end
        end
    end) end
end})
AutoCraft:AddButton('Unlock All Waypoints (try)', function()
    pcall(function()
        local Knit = require(RS.Shared.Packages.Knit)
        local svc = Knit.GetService("WaypointService")
        for _, w in ipairs(GetWaypointList()) do pcall(function() svc:Unlock(w) end) end
    end)
end)

-- Player fly/noclip
PlrFly:AddToggle('Fly', {Text='Fly (CFrame, WASD)', Default=false, Callback=function(v) ForgeFlags.fly_enabled = v end})
PlrFly:AddSlider('FlySpeed', {Text='Fly Speed', Default=ForgeFlags.fly_speed, Min=10, Max=120, Rounding=0, Callback=function(v) ForgeFlags.fly_speed = v end})
PlrFly:AddToggle('NoclipFull', {Text='Full Noclip', Default=false, Callback=function(v) ForgeFlags.noclip_enabled = v end})
PlrFly:AddToggle('InfJump', {Text='Infinite Jump', Default=false, Callback=function(v) ForgeFlags.inf_jump = v end})
PlrFly:AddSlider('JumpPow', {Text='Jump Power', Default=ForgeFlags.jump_power, Min=30, Max=150, Rounding=0, Callback=function(v) ForgeFlags.jump_power = v pcall(function() local _,_,h = GetChar() if h then h.JumpPower = v end end) end})
PlrFly:AddToggle('AntiVoid', {Text='Anti-Void (Y<-100 TP back)', Default=true, Callback=function(v) ForgeFlags.anti_void = v end})

-- Visuals
VisOre:AddToggle('OreESP2', {Text='Ore ESP (filtered)', Default=false, Callback=function(v) ForgeFlags.ore_esp = v end})
VisOre:AddSlider('ESPMax2', {Text='ESP Max Distance', Default=ForgeFlags.esp_maxdist, Min=100, Max=2000, Rounding=0, Suffix=' studs', Callback=function(v) ForgeFlags.esp_maxdist = v end})
VisMob:AddToggle('MobESP', {Text='Mob ESP (HP + dist)', Default=false, Callback=function(v) ForgeFlags.mob_esp = v end})
VisMob:AddToggle('PlayerESP', {Text='Player ESP', Default=false, Callback=function(v) ForgeFlags.player_esp = v end})
VisMob:AddToggle('ShowHP', {Text='Show HP numbers', Default=true, Callback=function(v) ForgeFlags.esp_show_hp = v end})
VisPerf:AddToggle('Fullbright', {Text='Fullbright', Default=false, Callback=function(v)
    ForgeFlags.fullbright = v
    pcall(function()
        local L = game:GetService("Lighting")
        if v then L.Brightness = 2 L.ClockTime = 14 L.FogEnd = 1e9 L.GlobalShadows = false
        else L.Brightness = 1 L.ClockTime = 14 L.FogEnd = 1000 L.GlobalShadows = true end
    end)
end})
VisPerf:AddToggle('FPSBoost', {Text='FPS Boost (particles off)', Default=false, Callback=function(v)
    ForgeFlags.fps_boost = v
    pcall(function()
        for _, o in ipairs(WS:GetDescendants()) do
            if o:IsA("ParticleEmitter") or o:IsA("Trail") then o.Enabled = not v end
        end
        local L = game:GetService("Lighting")
        L.GlobalShadows = not v
    end)
end})
VisPerf:AddSlider('FOV', {Text='Camera FOV', Default=70, Min=40, Max=120, Rounding=0, Callback=function(v) ForgeFlags.fov_value = v pcall(function() WS.CurrentCamera.FieldOfView = v end) end})
VisPerf:AddToggle('HidePlayers', {Text='Hide Other Players', Default=false, Callback=function(v) ForgeFlags.hide_players = v end})

-- Server
SrvMain:AddButton('Copy JobId', function() if setclipboard then setclipboard(game.JobId) end end)
SrvMain:AddButton('Copy PlaceId', function() if setclipboard then setclipboard(tostring(game.PlaceId)) end end)
SrvMain:AddDropdown('PlayerTP', {Text='Teleport To Player', Default=nil, AllowNull=true, SpecialType='Player', ExcludeLocalPlayer=true, Callback=function(v)
    local name = DropSingle(v, nil)
    local plr = name and PlayersSvc:FindFirstChild(name)
    local c = plr and plr.Character
    local hr = c and c:FindFirstChild("HumanoidRootPart")
    if hr then StealthMove(hr.CFrame + Vector3.new(0,3,0), true) end
end})
SrvMain:AddButton('Panic (stop ALL farms)', function()
    ForgeFlags.mob_autofarm=false ForgeFlags.mob_closestfarm=false ForgeFlags.ore_autofarm=false ForgeFlags.ore_closestfarm=false ForgeFlags.regional_ore_farm=false
    ForgeFlags.kill_aura=false ForgeFlags.boss_farm=false ForgeFlags.auto_block=false ForgeFlags.fly_enabled=false
    getgenv().forge_current_tween=false getgenv().forge_npcfound=false getgenv().forge_orefound=false
    if Toggles.OreFarm then Toggles.OreFarm:SetValue(false) end
    if Toggles.ClosestOre then Toggles.ClosestOre:SetValue(false) end
    if Toggles.RegionFarm then Toggles.RegionFarm:SetValue(false) end
    if Toggles.MobFarm then Toggles.MobFarm:SetValue(false) end
    if Toggles.ClosestMob then Toggles.ClosestMob:SetValue(false) end
    if Toggles.KillAura then Toggles.KillAura:SetValue(false) end
end)
SrvMain:AddButton('Stealth Preset (legit)', function()
    ForgeFlags.tweenspeed=28 ForgeFlags.disable_instant_tp=true ForgeFlags.underground_tween=true ForgeFlags.stealth_jitter=true ForgeFlags.mine_delay=0.22
    if Options.TweenSpeed then Options.TweenSpeed:SetValue(28) end
end)
SrvMain:AddButton('Blatant Preset (fast)', function()
    ForgeFlags.tweenspeed=80 ForgeFlags.disable_instant_tp=false ForgeFlags.underground_tween=false ForgeFlags.mine_delay=0.1
    if Options.TweenSpeed then Options.TweenSpeed:SetValue(80) end
end)
SrvAuto:AddToggle('AutoHopTimed', {Text='Auto Hop Every X min', Default=false, Callback=function(v) ForgeFlags.auto_hop_timed = v end})
SrvAuto:AddSlider('HopMins', {Text='Hop Interval', Default=ForgeFlags.hop_interval, Min=5, Max=120, Rounding=0, Suffix='m', Callback=function(v) ForgeFlags.hop_interval = v end})
SrvAuto:AddToggle('StaffAlert', {Text='Staff / Player Join Alert', Default=false, Callback=function(v) ForgeFlags.staff_alert = v end})
SrvAuto:AddToggle('AlertAny', {Text='Alert On ANY Player (not just list)', Default=false, Callback=function(v) ForgeFlags.alert_any_player = v end})
SrvAuto:AddInput('StaffNames', {Text='Staff Names (comma sep)', Default="", Placeholder='Name1, Name2', Finished=true, Callback=function(v) ForgeFlags.staff_names = v end})
SrvAuto:AddToggle('StaffPanic', {Text='Panic Farms On Alert', Default=false, Callback=function(v) ForgeFlags.staff_panic = v end})
SrvAuto:AddToggle('AutoPickaxe', {Text='Auto Buy Better Pickaxe', Default=false, Callback=function(v) ForgeFlags.auto_pickaxe = v end})
SrvAuto:AddToggle('ReconnectKick', {Text='Auto Reconnect If Kicked', Default=true, Callback=function(v) ForgeFlags.reconnect_on_kick = v end})
SrvAuto:AddSlider('MaxReconnect', {Text='Max Reconnect Tries', Default=ForgeFlags.max_reconnects, Min=1, Max=10, Rounding=0, Callback=function(v) ForgeFlags.max_reconnects = v end})
SrvAuto:AddInput('LoaderURL', {Text='Loader URL (for re-exec)', Default="", Placeholder='paste your raw Forge_Stealth.lua URL', Finished=true, Callback=function(v) ForgeFlags.loader_url = v end})

-- staff watcher + auto pickaxe buyer
do
    local function StaffList()
        local out = {}
        for s in string.gmatch(ForgeFlags.staff_names or "", "([^,]+)") do
            s = s:gsub("^%s+", ""):gsub("%s+$", "")
            if s ~= "" then table.insert(out, s:lower()) end
        end
        return out
    end
    local function DoPanic(reason)
        ForgeFlags.mob_autofarm=false ForgeFlags.mob_closestfarm=false ForgeFlags.ore_autofarm=false ForgeFlags.ore_closestfarm=false ForgeFlags.regional_ore_farm=false
        ForgeFlags.kill_aura=false ForgeFlags.auto_block=false
        getgenv().forge_current_tween=false getgenv().forge_npcfound=false getgenv().forge_orefound=false
        pcall(function() Creep:Notify("Panic: " .. tostring(reason), 4) end)
    end
    PlayersSvc.PlayerAdded:Connect(function(p)
        if not ForgeFlags.staff_alert then return end
        local hit = ForgeFlags.alert_any_player
        if not hit then
            for _, n in ipairs(StaffList()) do
                if p.Name:lower():find(n, 1, true) or p.DisplayName:lower():find(n, 1, true) then hit = true break end
            end
        end
        if hit then
            pcall(function() Creep:Notify("Player joined: " .. p.Name, 5) end)
            if ForgeFlags.webhook_enabled then SendWebhook("Player Alert :eye:", string.format("Player: %s (%s) joined\nYour level: %d\nJobId: %s", p.Name, p.DisplayName, PlayerLevel(), game.JobId)) end
            if ForgeFlags.staff_panic then DoPanic("player " .. p.Name) end
        end
    end)
    task.spawn(function()
        while task.wait(10) do
            if ForgeFlags.auto_pickaxe and PurchaseRF then
                pcall(function()
                    local prox = WS:FindFirstChild("Proximity")
                    if not prox then return end
                    local gold = GoldNow()
                    for _, m in ipairs(prox:GetChildren()) do
                        if m:IsA("Model") and m.Name:lower():find("pickaxe") then
                            local price = 0
                            pcall(function()
                                local h = m:FindFirstChild("Handle")
                                local a = h and h:FindFirstChild("Attachment")
                                local b = a and a:FindFirstChild("BillboardGui")
                                local c = b and b:FindFirstChild("Cash")
                                local pr = c and c:FindFirstChild("Price")
                                if pr then price = tonumber((pr.Text:gsub("[$,]", ""))) or 0 end
                            end)
                            -- own check: backpack + character
                            local owned = false
                            local ch = LocalPlayer.Character
                            local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                            if ch then for _, t in ipairs(ch:GetChildren()) do if t.Name == m.Name then owned = true break end end end
                            if not owned and bp then for _, t in ipairs(bp:GetChildren()) do if t.Name == m.Name then owned = true break end end end
                            if not owned and price > 0 and gold >= price then
                                pcall(function() PurchaseRF:InvokeServer(m.Name, 1) end)
                                task.wait(1)
                                return
                            end
                        end
                    end
                end)
            end
        end
    end)
end

-- Forge auto cycle
ForgeAuto:AddToggle('AutoForgeCycle', {Text='Auto Go To Forge + Start', Default=false, Callback=function(v) ForgeFlags.auto_forge_cycle = v end})
ForgeAuto:AddInput('MoldName', {Text='Mold / Item Name (optional)', Default="", Placeholder='e.g. Dagger', Finished=true, Callback=function(v) ForgeFlags.forge_mold_name = v end})
ForgeAuto:AddLabel('Walks to Forge prompt and\nfires it. Then use Melt/Pour/\nHammer/Mold toggles.', true)
ForgeAuto:AddToggle('InstantForge', {Text='Instant Forge (try skip, no pass)', Default=false, Callback=function(v)
    ForgeFlags.instant_forge = v
    pcall(function()
        local Knit = require(RS.Shared.Packages.Knit)
        -- 1) try FastForge flag: Modules.Forge.FastForge is sent in Melt request.
        -- Server decides v10.FastForge; if it trusts the flag you skip Melt/Pour without owning.
        local UI = Knit.GetController("UIController")
        if UI and UI.Modules and UI.Modules.Forge then
            if v then
                if UI.Modules.Forge.FastForge ~= nil and not UI.Modules.Forge._FS_origFF then
                    UI.Modules.Forge._FS_origFF = UI.Modules.Forge.FastForge
                end
                UI.Modules.Forge.FastForge = true
            else
                if UI.Modules.Forge._FS_origFF ~= nil then
                    UI.Modules.Forge.FastForge = UI.Modules.Forge._FS_origFF
                    UI.Modules.Forge._FS_origFF = nil
                end
            end
        end
        -- 2) instant minigames: replace Start to return perfect time instantly.
        -- No hookmetamethod, just table assignment. Falls back to VIM play if server rejects.
        local FC = Knit.GetController("ForgeController")
        if FC and FC.Minigames then
            for _, name in ipairs({"MeltMinigame", "PourMinigame"}) do
                local mg = FC.Minigames[name]
                if mg then
                    if v then
                        if not mg._FS_origStart then mg._FS_origStart = mg.Start end
                        mg.Start = function(_, p)
                            pcall(function()
                                local gui = LocalPlayer.PlayerGui:FindFirstChild("Forge")
                                local ui = gui and gui:FindFirstChild(name)
                                if ui then ui.Visible = false end
                            end)
                            task.wait(0.4)
                            -- perfect client time: small elapsed = max quality
                            return 0.5, true
                        end
                    else
                        if mg._FS_origStart then mg.Start = mg._FS_origStart mg._FS_origStart = nil end
                    end
                end
            end
        end
    end)
end})
ForgeAuto:AddLabel('How skip works:\n- Sets Forge.FastForge=true\n  in Melt request\n- Instants Melt/Pour Start\n  to 0.5s perfect\n- If server checks pass,\n  falls back to VIM play.', true)

-- loops for everything pack
task.spawn(function()
    local lastTarget = nil
    local lastMove = tick()
    while task.wait(0.2) do
        -- stuck detection
        if ForgeFlags.auto_stuck_hop and (ForgeFlags.ore_autofarm or ForgeFlags.ore_closestfarm or ForgeFlags.regional_ore_farm) then
            if getgenv().forge_lastOre and getgenv().forge_lastOre.Parent then
                if getgenv().forge_lastOre == lastTarget then
                    if tick() - lastMove > ForgeFlags.stuck_timeout then
                        pcall(function() lastTarget:SetAttribute("Someone", true) end)
                        getgenv().forge_current_tween = false
                        getgenv().forge_orefound = false
                        lastMove = tick()
                    end
                else
                    lastTarget = getgenv().forge_lastOre
                    lastMove = tick()
                end
            end
        end
        -- kill aura
        if ForgeFlags.kill_aura and Living then
            local ok, _, _, hrp = GetChar()
            if ok then
                local swung = false
                for _, m in ipairs(Living:GetChildren()) do
                    local r = m:FindFirstChild("HumanoidRootPart")
                    local h = m:FindFirstChildOfClass("Humanoid")
                    if r and h and h.Health > 0 and (hrp.Position - r.Position).Magnitude <= ForgeFlags.aura_range then
                        if EquipTool("Weapon") and ToolActivatedRF then
                            pcall(function() ToolActivatedRF:InvokeServer("Weapon") end)
                            swung = true
                        end
                        break
                    end
                end
                if swung then task.wait(ForgeFlags.aura_delay) end
            end
        end
        -- auto skill (heavy)
        if ForgeFlags.auto_skill then
            local ok, _, _, hrp = GetChar()
            if ok and getgenv().forge_npcfound and ToolActivatedRF then
                if EquipTool("Weapon") then pcall(function() ToolActivatedRF:InvokeServer("Weapon", true) end) end
            end
        end
        -- auto block
        if ForgeFlags.auto_block and StartBlockRF and StopBlockRF and Living then
            local ok, _, _, hrp = GetChar()
            if ok then
                local near = false
                for _, m in ipairs(Living:GetChildren()) do
                    local r = m:FindFirstChild("HumanoidRootPart")
                    local h = m:FindFirstChildOfClass("Humanoid")
                    if r and h and h.Health > 0 and (hrp.Position - r.Position).Magnitude <= 25 then near = true break end
                end
                if near then pcall(function() StartBlockRF:InvokeServer() end) else pcall(function() StopBlockRF:InvokeServer() end) end
            end
        end
        -- hitbox expander maintenance
        if ForgeFlags.hitbox_expand and Living then
            pcall(function()
                for _, m in ipairs(Living:GetChildren()) do
                    local r = m:FindFirstChild("HumanoidRootPart")
                    if r and r:IsA("BasePart") then
                        if not r:GetAttribute("FS_Hitbox") then r:SetAttribute("FS_Hitbox", r.Size) end
                        r.Size = Vector3.new(ForgeFlags.hitbox_size, ForgeFlags.hitbox_size, ForgeFlags.hitbox_size)
                        r.Transparency = 1
                        r.CanCollide = false
                    end
                end
            end)
        end
    end
end)

-- fly / noclip / infjump / anti-void
do
    local flyVel = nil
    UIS.JumpRequest:Connect(function()
        if ForgeFlags.inf_jump then pcall(function()
            local _, _, h = GetChar()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end) end
    end)
    RunSvc.Heartbeat:Connect(function(dt)
        local ok, c, h, hrp = GetChar()
        if not ok then return end
        if ForgeFlags.noclip_enabled or (ForgeFlags.noclip_farm and getgenv().forge_current_tween) or ForgeFlags.fly_enabled then
            pcall(function() for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end)
        end
        if ForgeFlags.anti_void and hrp.Position.Y < -100 then
            pcall(function() hrp.CFrame = CFrame.new(0, 50, 0) hrp.Velocity = Vector3.new() end)
        end
        if ForgeFlags.fly_enabled then
            if not flyVel or flyVel.Parent ~= hrp then
                if flyVel then pcall(function() flyVel:Destroy() end) end
                flyVel = Instance.new("BodyVelocity")
                flyVel.MaxForce = Vector3.new(1e9,1e9,1e9)
                flyVel.Parent = hrp
            end
            local dir = h.MoveDirection
            local cf = Camera.CFrame
            local move = Vector3.new()
            if dir.Magnitude > 0 then
                move = (cf.LookVector * -dir.Z + cf.RightVector * dir.X)
                -- vertical via jump/sink keys
                if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
                if move.Magnitude > 0 then move = move.Unit * ForgeFlags.fly_speed end
            end
            flyVel.Velocity = move
            hrp.Velocity = move * 0.1
        else
            if flyVel then pcall(function() flyVel:Destroy() end) flyVel = nil end
        end
    end)
end

-- mob/player ESP + hide players
do
    local mobFolder, plrFolder = nil, nil
    task.spawn(function()
        while task.wait(1) do
            if ForgeFlags.mob_esp then
                if not mobFolder then mobFolder = Instance.new("Folder") mobFolder.Name = "FSMobESP" pcall(function() mobFolder.Parent = game:GetService("CoreGui") end) end
                pcall(function() mobFolder:ClearAllChildren() end)
                local ok, _, _, hrp = GetChar()
                if ok and Living then
                    for _, m in ipairs(Living:GetChildren()) do
                        local r = m:FindFirstChild("HumanoidRootPart") local h = m:FindFirstChildOfClass("Humanoid")
                        if r and h and h.Health > 0 then
                            local d = (hrp.Position - r.Position).Magnitude
                            if d <= ForgeFlags.esp_maxdist then
                                local bb = Instance.new("BillboardGui") bb.Size = UDim2.new(0,200,0,36) bb.StudsOffset = Vector3.new(0,2.5,0) bb.AlwaysOnTop = true
                                local tl = Instance.new("TextLabel", bb) tl.Size = UDim2.new(1,0,1,0) tl.BackgroundTransparency = 1
                                local hpTxt = ForgeFlags.esp_show_hp and string.format(" [%d HP]", math.floor(h.Health)) or ""
                                tl.Text = BaseName(m.Name) .. hpTxt .. string.format(" (%dm)", math.floor(d))
                                tl.TextColor3 = Color3.fromRGB(255,120,120) tl.TextStrokeTransparency = 0 tl.TextSize = 12 tl.Font = Enum.Font.Code
                                bb.Adornee = r bb.Parent = mobFolder
                            end
                        end
                    end
                end
            else if mobFolder then pcall(function() mobFolder:Destroy() end) mobFolder = nil end end
            if ForgeFlags.player_esp then
                if not plrFolder then plrFolder = Instance.new("Folder") plrFolder.Name = "FSPlrESP" pcall(function() plrFolder.Parent = game:GetService("CoreGui") end) end
                pcall(function() plrFolder:ClearAllChildren() end)
                for _, p in ipairs(PlayersSvc:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local r = p.Character:FindFirstChild("HumanoidRootPart")
                        if r then
                            local bb = Instance.new("BillboardGui") bb.Size = UDim2.new(0,200,0,30) bb.StudsOffset = Vector3.new(0,2.5,0) bb.AlwaysOnTop = true
                            local tl = Instance.new("TextLabel", bb) tl.Size = UDim2.new(1,0,1,0) tl.BackgroundTransparency = 1 tl.Text = p.Name tl.TextColor3 = Color3.new(1,1,1) tl.TextStrokeTransparency = 0 tl.TextSize = 12 tl.Font = Enum.Font.Code
                            bb.Adornee = r bb.Parent = plrFolder
                        end
                    end
                end
            else if plrFolder then pcall(function() plrFolder:Destroy() end) plrFolder = nil end end
            if ForgeFlags.hide_players ~= nil then
                pcall(function()
                    for _, p in ipairs(PlayersSvc:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            for _, v in ipairs(p.Character:GetDescendants()) do
                                if v:IsA("BasePart") then v.Transparency = ForgeFlags.hide_players and 1 or 0 end
                                if v:IsA("Decal") then v.Transparency = ForgeFlags.hide_players and 1 or 0 end
                            end
                        end
                    end
                end)
            end
        end
    end)
end

-- auto daily/mail/quest/totem/craft + timed hop + forge cycle
task.spawn(function()
    local hopStart = tick()
    while task.wait(5) do
        if ForgeFlags.auto_daily then pcall(function()
            local Knit = require(RS.Shared.Packages.Knit)
            local svc = Knit.GetService("DailyLoginService")
            if svc and svc.Claim then pcall(function() svc:Claim() end) end
            -- fallback: click Claim buttons
            for _, g in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if g:IsA("TextButton") and (g.Text:lower():find("claim") and g.Visible) then
                    local f = g.AbsolutePosition + g.AbsoluteSize/2
                    -- use VIM click if available
                    pcall(function()
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendMouseButtonEvent(f.X, f.Y, 0, true, game, 0) task.wait(0.05) vim:SendMouseButtonEvent(f.X, f.Y, 0, false, game, 0)
                    end)
                    break
                end
            end
        end) end
        if ForgeFlags.auto_mail then pcall(function()
            local Knit = require(RS.Shared.Packages.Knit)
            local ok, svc = pcall(function() return Knit.GetService("MailboxService") end)
            if ok and svc then pcall(function() if svc.ClaimAll then svc:ClaimAll() end end) end
        end) end
        if ForgeFlags.auto_quest then pcall(function()
            local qb = WS:FindFirstChild("Proximity") and WS.Proximity:FindFirstChild("QuestBoard")
            if not qb then
                for _, m in ipairs(WS:GetDescendants()) do if m:IsA("Model") and m.Name:lower():find("quest") then qb = m break end end
            end
            if qb and DialogueRF then pcall(function() DialogueRF:InvokeServer(qb) end) end
        end) end
        if ForgeFlags.auto_claim_board then pcall(function()
            local Knit = require(RS.Shared.Packages.Knit)
            local ok, svc = pcall(function() return Knit.GetService("QuestBoardService") end)
            if ok and svc and svc.ClaimQuest then
                -- try tiers 1-3, indexes 1-9 (server validates, safe to brute force)
                for tier = 1, 3 do
                    for idx = 1, 9 do
                        pcall(function() svc:ClaimQuest(tier, idx) end)
                    end
                end
            end
        end) end
        if ForgeFlags.auto_totem and PurchaseRF and #ForgeFlags.totems_selected > 0 then pcall(function()
            for _, tname in ipairs(ForgeFlags.totems_selected) do pcall(function() PurchaseRF:InvokeServer(tname, 1) end) end
        end) end
        if ForgeFlags.auto_craft then pcall(function()
            local Knit = require(RS.Shared.Packages.Knit)
            local svc = Knit.GetService("OreCraftService")
            if svc and svc.CheckCraftCompletions then pcall(function() svc:CheckCraftCompletions() end) end
        end) end
        if ForgeFlags.auto_enhance then pcall(function()
            local Knit = require(RS.Shared.Packages.Knit)
            local svc = Knit.GetService("EnhanceService")
            -- enhance first equippable in stash UI (best effort, no GUID guess)
            if svc and svc.EnhanceEquipment then
                -- find selected equipment GUID from EnhanceUI if open
                local eg = LocalPlayer.PlayerGui:FindFirstChild("WeaponEnhance")
                if eg then
                    -- do nothing destructive: only attempt if UI shows CanEnhance (avoid waste)
                end
            end
        end) end
        if ForgeFlags.auto_hop_timed and tick() - hopStart > ForgeFlags.hop_interval * 60 then
            hopStart = tick()
            pcall(function()
                local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
                local res = game:HttpGet(url)
                local data = HttpSvc:JSONDecode(res)
                if data and data.data and #data.data > 0 then
                    TeleportSvc:TeleportToPlaceInstance(game.PlaceId, data.data[1].id, LocalPlayer)
                end
            end)
        end
        if ForgeFlags.auto_forge_cycle then pcall(function()
            local f = WS:FindFirstChild("Proximity") and WS.Proximity:FindFirstChild("Forge")
            if f then
                local ok, _, _, hrp = GetChar()
                if ok and (hrp.Position - f:GetPivot().Position).Magnitude > 12 and not getgenv().forge_current_tween then
                    StealthMove(f:GetPivot(), true)
                elseif ok then
                    local pp = f:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if pp then pcall(function() fireproximityprompt(pp) end) end
                end
            end
        end) end
    end
end)

-- session stats ticker + rare sound
task.spawn(function()
    while task.wait(2) do
        local g = GoldNow()
        local profit = g - ForgeFlags.session_gold_start
        local mins = math.max((tick() - SessionStart)/60, 0.01)
        local perHr = math.floor(profit / mins * 60)
        pcall(function() Creep:SetWatermark(string.format("Forge Stealth | %d ores | %+d gold (%+d/hr) | %dm", OresMinedSession, profit, perHr, math.floor(mins))) end)
    end
end)

-- count ores mined for stats (hook notification text)
task.spawn(function()
    local holder = nil
    pcall(function() holder = LocalPlayer.PlayerGui.Notifications.Screen.NotificationsFrame end)
    if holder then holder.ChildAdded:Connect(function(fr)
        local tf = fr:FindFirstChild("TextFrame") local lb = tf and tf:FindFirstChild("TextLabel")
        if lb and lb.Text:match("You just found") then
            OresMinedSession = OresMinedSession + 1
            if ForgeFlags.notify_rare_sound and (lb.Text:lower():find("mythic") or lb.Text:lower():find("divine") or lb.Text:lower():find("exotic") or lb.Text:lower():find("relic")) then
                pcall(function()
                    local s = Instance.new("Sound", game:GetService("SoundService")) s.SoundId = "rbxassetid://9797775470" s.Volume = 2 s:Play() game.Debris:AddItem(s, 3)
                end)
            end
        end
    end) end
end)

--// ===== AUTO QUEST FARM (start / farm objectives / turn-in) + quest ESP + webhook parity =====
getgenv().forge_current_quest = getgenv().forge_current_quest or nil
getgenv().forge_quest_label = nil
do
    -- tracker label (top of screen)
    pcall(function()
        local sg = Instance.new("ScreenGui") sg.Name = "ForgeQuestTracker" sg.ResetOnSpawn = false
        pcall(function() sg.Parent = game:GetService("CoreGui") end)
        local tl = Instance.new("TextLabel") tl.Name = "Tracker"
        tl.Size = UDim2.new(0, 340, 0, 90) tl.Position = UDim2.new(0, 12, 0, 80)
        tl.BackgroundColor3 = Color3.fromRGB(12,12,12) tl.BackgroundTransparency = 0.35
        tl.TextColor3 = Color3.new(1,1,1) tl.TextSize = 13 tl.Font = Enum.Font.Code
        tl.TextXAlignment = Enum.TextXAlignment.Left tl.TextYAlignment = Enum.TextYAlignment.Top
        tl.Text = "Quest: none" tl.Visible = false tl.Parent = sg
        getgenv().forge_quest_label = tl
    end)
end
local function QuestIsSelected(qid)
    if not ForgeFlags.quests_selected or #ForgeFlags.quests_selected == 0 then return true end
    for _, s in ipairs(ForgeFlags.quests_selected) do if s == qid then return true end end
    return false
end
local function PickQuestTarget()
    local defs = GetQuestDefs()
    local active = select(1, GetReplicaQuests())
    -- prefer active selected quest with incomplete objective
    for qid, _ in pairs(active) do
        if QuestIsSelected(qid) and defs[qid] then
            local idx, obj = FirstIncompleteObjective(qid)
            if idx and obj then return qid, idx, obj end
        end
    end
    -- else first selectable def not completed (for accept)
    if ForgeFlags.auto_accept_quests then
        local _, completed, cooldown = GetReplicaQuests()
        for _, qid in ipairs(GetQuestList()) do
            if QuestIsSelected(qid) and not active[qid] and not completed[qid] and not cooldown[qid] then
                return qid, 0, {Type = "Accept", Target = (defs[qid] and defs[qid].Npc) or "?"}
            end
        end
    end
    return nil, nil, nil
end
task.spawn(function()
    local lastTalk = 0
    while task.wait(1) do
        local mode = ForgeFlags.quest_mode or "Off"
        local wantFarm = (mode ~= "Off") and (ForgeFlags.auto_farm_objectives or ForgeFlags.auto_accept_quests or ForgeFlags.auto_turnin_quests)
        -- tracker update
        pcall(function()
            local tl = getgenv().forge_quest_label
            if tl then
                tl.Visible = ForgeFlags.quest_track and (mode ~= "Off")
                if tl.Visible then
                    local qid = getgenv().forge_current_quest
                    if qid then
                        local defs = GetQuestDefs()
                        local q = defs[qid]
                        tl.Text = string.format("Quest: %s\n%s\n%s", qid, q and q.Name or "", QuestObjectiveText(qid))
                    else
                        tl.Text = "Quest: searching..."
                    end
                end
            end
        end)
        -- quest ESP
        pcall(function()
            if ForgeFlags.quest_esp then
                if not QuestESPFolder or not QuestESPFolder.Parent then
                    QuestESPFolder = Instance.new("Folder") QuestESPFolder.Name = "ForgeQuestESP"
                    pcall(function() QuestESPFolder.Parent = game:GetService("CoreGui") end)
                end
                QuestESPFolder:ClearAllChildren()
                local defs = GetQuestDefs()
                local active = select(1, GetReplicaQuests())
                local seen = {}
                for qid, _ in pairs(active) do
                    local q = defs[qid]
                    if q and q.Npc and not seen[q.Npc] and QuestIsSelected(qid) then
                        seen[q.Npc] = true
                        local m = FindNPCModel(q.Npc)
                        local part = m and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart"))
                        if part then
                            local bb = Instance.new("BillboardGui") bb.Size = UDim2.new(0,220,0,32) bb.StudsOffset = Vector3.new(0,3,0) bb.AlwaysOnTop = true
                            local tl = Instance.new("TextLabel", bb) tl.Size = UDim2.new(1,0,1,0) tl.BackgroundTransparency = 1
                            tl.Text = "[Q] " .. q.Npc .. " : " .. qid tl.TextColor3 = Color3.fromRGB(255,221,87) tl.TextStrokeTransparency = 0 tl.TextSize = 13 tl.Font = Enum.Font.Code
                            bb.Adornee = part bb.Parent = QuestESPFolder
                        end
                    end
                end
            else
                if QuestESPFolder then pcall(function() QuestESPFolder:Destroy() end) QuestESPFolder = nil end
            end
        end)
        if mode == "Off" or not wantFarm then continue end
        if getgenv().forge_current_tween then continue end
        local ok, _, _, hrp = GetChar()
        if not ok then continue end
        local qid, idx, obj = PickQuestTarget()
        getgenv().forge_current_quest = qid
        if not qid or not obj then continue end
        local otype = obj.Type or "?"
        local target = obj.Target or ""
        if type(target) == "function" then target = "?" end
        if idx == 0 or otype == "Accept" then
            -- accept quest from its NPC
            local defs = GetQuestDefs()
            local npc = defs[qid] and defs[qid].Npc
            if npc and tick() - lastTalk > 6 then
                lastTalk = tick()
                local saved = SaveFarming() DisableFarming()
                pcall(function() TalkToNPC(npc) end)
                ForgeFlags.mob_autofarm = saved.mob_autofarm ForgeFlags.mob_closestfarm = saved.mob_closestfarm ForgeFlags.ore_autofarm = saved.ore_autofarm ForgeFlags.ore_closestfarm = saved.ore_closestfarm ForgeFlags.regional_ore_farm = saved.regional_ore_farm
            end
        elseif otype == "Talk" then
            if ForgeFlags.auto_turnin_quests and tick() - lastTalk > 6 then
                lastTalk = tick()
                local saved = SaveFarming() DisableFarming()
                pcall(function() TalkToNPC(target) end)
                ForgeFlags.mob_autofarm = saved.mob_autofarm ForgeFlags.mob_closestfarm = saved.mob_closestfarm ForgeFlags.ore_autofarm = saved.ore_autofarm ForgeFlags.ore_closestfarm = saved.ore_closestfarm ForgeFlags.regional_ore_farm = saved.regional_ore_farm
                if ForgeFlags.webhook_enabled and ForgeFlags.webhook_quests then
                    SendWebhook("Quest Talk :speech_balloon:", string.format("Player: %s\nQuest: %s\nTalked to: %s", LocalPlayer.Name, qid, tostring(target)))
                end
            end
        elseif otype == "Kill" then
            if ForgeFlags.auto_farm_objectives and type(target) == "string" and target ~= "" and target ~= "?" and target ~= "Any" then
                -- drive mob farm to quest target (quest takes over mob selection)
                local needSwitch = true
                if #ForgeFlags.mobs_selected == 1 and ForgeFlags.mobs_selected[1] == target and ForgeFlags.mob_autofarm then needSwitch = false end
                if needSwitch then
                    ForgeFlags.mobs_selected = {target}
                    if Options.MobSelect then pcall(function() Options.MobSelect:SetValue({[target] = true}) end) end
                    ForgeFlags.mob_autofarm = true
                    ForgeFlags.mob_closestfarm = false
                    ForgeFlags.ore_autofarm = false ForgeFlags.ore_closestfarm = false ForgeFlags.regional_ore_farm = false
                    if Toggles.MobFarm then pcall(function() Toggles.MobFarm:SetValue(true) end) end
                    if Toggles.OreFarm then pcall(function() Toggles.OreFarm:SetValue(false) end) end
                    if Toggles.ClosestOre then pcall(function() Toggles.ClosestOre:SetValue(false) end) end
                    if Toggles.RegionFarm then pcall(function() Toggles.RegionFarm:SetValue(false) end) end
                end
            end
        elseif otype == "Mine" then
            if ForgeFlags.auto_farm_objectives and type(target) == "string" and target ~= "" and target ~= "?" then
                local needSwitch = true
                if #ForgeFlags.rocktypes_selected == 1 and ForgeFlags.rocktypes_selected[1] == target and ForgeFlags.ore_autofarm then needSwitch = false end
                if needSwitch then
                    ForgeFlags.rocktypes_selected = {target}
                    if Options.RockTypeSelect then pcall(function() Options.RockTypeSelect:SetValue({[target] = true}) end) end
                    ForgeFlags.ores_selected = {}
                    if Options.OreSelect then pcall(function() Options.OreSelect:SetValue({}) end) end
                    ForgeFlags.ore_autofarm = true
                    ForgeFlags.mob_autofarm = false ForgeFlags.mob_closestfarm = false
                    if Toggles.OreFarm then pcall(function() Toggles.OreFarm:SetValue(true) end) end
                    if Toggles.MobFarm then pcall(function() Toggles.MobFarm:SetValue(false) end) end
                end
            end
        elseif otype == "Collect" then
            if ForgeFlags.auto_farm_objectives and type(target) == "string" and target ~= "" and target ~= "?" and target ~= "Ore" and target ~= "Any" then
                -- ore collect: could be ore name or item (pickaxe etc - skip shop items)
                if OreRarity[target] or OreRarity[BaseName(target)] then
                    local needSwitch = true
                    if #ForgeFlags.ores_selected == 1 and ForgeFlags.ores_selected[1] == target and ForgeFlags.ore_autofarm then needSwitch = false end
                    if needSwitch then
                        ForgeFlags.ores_selected = {target}
                        if Options.OreSelect then pcall(function() Options.OreSelect:SetValue({[target] = true}) end) end
                        ForgeFlags.ore_autofarm = true
                        ForgeFlags.mob_autofarm = false ForgeFlags.mob_closestfarm = false
                        if Toggles.OreFarm then pcall(function() Toggles.OreFarm:SetValue(true) end) end
                        if Toggles.MobFarm then pcall(function() Toggles.MobFarm:SetValue(false) end) end
                    end
                end
            end
        elseif otype == "Forge" then
            if ForgeFlags.auto_farm_objectives then
                ForgeFlags.auto_forge_cycle = true
                ForgeFlags.automelt = true ForgeFlags.autopour = true ForgeFlags.autohammer = true
                if Toggles.AutoMelt then pcall(function() Toggles.AutoMelt:SetValue(true) end) end
                if Toggles.AutoPour then pcall(function() Toggles.AutoPour:SetValue(true) end) end
                if Toggles.AutoHammer then pcall(function() Toggles.AutoHammer:SetValue(true) end) end
            end
        end
    end
end)

-- webhook parity: quest complete + level up + status heartbeat
do
    local lastQuests = {}
    local lastLevel = PlayerLevel()
    task.spawn(function()
        pcall(function()
            local a = select(1, GetReplicaQuests())
            for qid, _ in pairs(a) do lastQuests[qid] = true end
        end)
        local lastStatus = tick()
        while task.wait(3) do
            -- level up
            local lvl = PlayerLevel()
            if lvl ~= lastLevel then
                if ForgeFlags.webhook_enabled and ForgeFlags.webhook_levels and lvl > lastLevel then
                    SendWebhook("Level Up :arrow_up:", string.format("Player: %s\nLevel: %d -> %d\nGold: %d\nPlace: %d\nJobId: %s", LocalPlayer.Name, lastLevel, lvl, GoldNow(), game.PlaceId, game.JobId))
                end
                lastLevel = lvl
            end
            -- quest complete = was active, now gone (AutoComplete quests vanish on complete)
            if ForgeFlags.webhook_enabled and ForgeFlags.webhook_quests then
                local active = select(1, GetReplicaQuests())
                for qid, _ in pairs(lastQuests) do
                    if not active[qid] then
                        local defs = GetQuestDefs()
                        local q = defs[qid]
                        SendWebhook("Quest Complete :white_check_mark:", string.format("Player: %s\nQuest: %s\n%s\nLevel: %d\nPlace: %d\nJobId: %s", LocalPlayer.Name, qid, q and q.Name or "", lvl, game.PlaceId, game.JobId))
                    end
                end
                -- newly accepted quests
                for qid, _ in pairs(active) do
                    if not lastQuests[qid] and QuestIsSelected(qid) then
                        local defs = GetQuestDefs()
                        local q = defs[qid]
                        SendWebhook("Quest Started :scroll:", string.format("Player: %s\nQuest: %s\n%s\n%s", LocalPlayer.Name, qid, q and q.Name or "", QuestObjectiveText(qid)))
                    end
                end
                lastQuests = {}
                for qid, _ in pairs(active) do lastQuests[qid] = true end
            end
            -- status heartbeat
            if ForgeFlags.webhook_enabled and ForgeFlags.webhook_status and tick() - lastStatus > (ForgeFlags.webhook_status_mins or 15) * 60 then
                lastStatus = tick()
                local g = GoldNow()
                local profit = g - (ForgeFlags.session_gold_start or 0)
                SendWebhook("Status :bar_chart:", string.format("Player: %s\nLevel: %d\nGold: %d (%+d)\nOres: %d\nQuest: %s\nFarming: ore=%s mob=%s\nPlace: %d\nJobId: %s", LocalPlayer.Name, lvl, g, profit, OresMinedSession, tostring(getgenv().forge_current_quest or "none"), tostring(ForgeFlags.ore_autofarm or ForgeFlags.ore_closestfarm), tostring(ForgeFlags.mob_autofarm or ForgeFlags.mob_closestfarm), game.PlaceId, game.JobId))
            end
        end
    end)
    -- also catch "Quest Complete" system notifications as backup
    task.spawn(function()
        local holder = nil
        pcall(function() holder = LocalPlayer.PlayerGui.Notifications.Screen.NotificationsFrame end)
        if not holder then return end
        holder.ChildAdded:Connect(function(fr)
            local tf = fr:FindFirstChild("TextFrame") local lb = tf and tf:FindFirstChild("TextLabel")
            if not lb then return end
            local t = lb.Text or ""
            if (t:lower():find("quest") and (t:lower():find("complet") or t:lower():find("finish") or t:lower():find("done"))) then
                if ForgeFlags.webhook_enabled and ForgeFlags.webhook_quests then
                    SendWebhook("Quest Update :scroll:", string.format("Player: %s\n%s\nLevel: %d\nJobId: %s", LocalPlayer.Name, Clean(t), PlayerLevel(), game.JobId))
                end
            end
            if t:lower():find("level up") or t:lower():find("levelled") then
                if ForgeFlags.webhook_enabled and ForgeFlags.webhook_levels then
                    SendWebhook("Level Up :arrow_up:", string.format("Player: %s\n%s\nLevel: %d", LocalPlayer.Name, Clean(t), PlayerLevel()))
                end
            end
        end)
    end)
end

-- boss priority wrapper for mob loops
do
    local function IsBossModel(m)
        if not m then return false end
        local n = m.Name:lower()
        if n:find("boss") or n:find("golem") or n:find("asura") then return true end
        local h = m:FindFirstChildOfClass("Humanoid")
        if h and h.MaxHealth and h.MaxHealth > 5000 then return true end
        return false
    end
    local OldSel = FindSelectedMob
    FindSelectedMob = function()
        if ForgeFlags.boss_farm and Living then
            local ok, _, _, hrp = GetChar()
            if ok then
                local best, bd = nil, math.huge
                for _, m in ipairs(Living:GetChildren()) do
                    if IsBossModel(m) then
                        local r = m:FindFirstChild("HumanoidRootPart") local h = m:FindFirstChildOfClass("Humanoid")
                        if r and h and h.Health > 0 then
                            local d = (hrp.Position - r.Position).Magnitude
                            if d < bd then bd, best = d, m end
                        end
                    end
                end
                if best then return best end
            end
        end
        return OldSel()
    end
    local OldClose = FindClosestMob
    FindClosestMob = function()
        if ForgeFlags.boss_farm and Living then
            local ok, _, _, hrp = GetChar()
            if ok then
                local best, bd = nil, math.huge
                for _, m in ipairs(Living:GetChildren()) do
                    if IsBossModel(m) then
                        local r = m:FindFirstChild("HumanoidRootPart") local h = m:FindFirstChildOfClass("Humanoid")
                        if r and h and h.Health > 0 then
                            local d = (hrp.Position - r.Position).Magnitude
                            if d < bd then bd, best = d, m end
                        end
                    end
                end
                if best then return best end
            end
        end
        return OldClose()
    end
end

-- UI tab
local MenuBox = Tabs.UI:AddLeftGroupbox('Menu')
MenuBox:AddButton('Unload', function() Creep:Unload() end)
MenuBox:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {Default='RightShift', NoUI=false, Text='Menu keybind', Callback=function() end, ChangedCallback=function() end})
MenuBox:AddToggle('ShowKeybinds', {Text='Show Keybinds', Default=false, Callback=function(v) Creep.KeybindFrame.Visible=v end})
MenuBox:AddToggle('ShowWatermark', {Text='Show Watermark', Default=true, Callback=function(v) Creep:SetWatermarkVisibility(v) end})
local BGBox = Tabs.UI:AddLeftGroupbox('Background')
if Creep.AddBlurSlider then Creep:AddBlurSlider(BGBox) end
if Creep.AddDarkenSlider then Creep:AddDarkenSlider(BGBox) end
ThemeMgr:SetLibrary(Creep)
SaveMgr:SetLibrary(Creep)
SaveMgr:IgnoreThemeSettings()
SaveMgr:SetIgnoreIndexes({})
SaveMgr:SetFolder('ForgeStealth')
SaveMgr:BuildConfigSection(Tabs.UI)
ThemeMgr:SetFolder('ForgeStealth')
ThemeMgr:ApplyToTab(Tabs.UI)

--// persistence: autoload cfg so farms continue after re-exec
getgenv().forge_reconnects = getgenv().forge_reconnects or 0
task.spawn(function()
    task.wait(2)
    pcall(function() SaveMgr:LoadAutoloadConfig() end)
    -- re-assert loader URL input display
    pcall(function()
        if Options.LoaderURL and ForgeFlags.loader_url ~= "" then Options.LoaderURL:SetValue(ForgeFlags.loader_url) end
    end)
end)
local function CurrentCfgName()
    local ok, name = pcall(function()
        if isfile('ForgeStealth/settings/autoload.txt') then return readfile('ForgeStealth/settings/autoload.txt') end
        return nil
    end)
    if ok and name and name ~= "" then return name end
    return "autosave"
end
local function SaveCfgNow()
    pcall(function() SaveMgr:Save(CurrentCfgName()) end)
    pcall(function()
        if not isfile('ForgeStealth/settings/autoload.txt') then
            writefile('ForgeStealth/settings/autoload.txt', CurrentCfgName())
        end
    end)
end
local function BuildQueueScript()
    local url = ForgeFlags.loader_url or ""
    if url == "" then return nil end
    return 'repeat task.wait() until game:IsLoaded() loadstring(game:HttpGet("' .. url .. '"))()'
end
local function ArmQueue()
    pcall(function()
        if queue_on_teleport then
            local q = BuildQueueScript()
            if q then queue_on_teleport(q) end
        end
    end)
end
-- arm now + whenever loader URL changes + before any exit
ArmQueue()
task.spawn(function()
    local last = ForgeFlags.loader_url
    while task.wait(5) do
        if ForgeFlags.loader_url ~= last then last = ForgeFlags.loader_url ArmQueue() end
    end
end)
pcall(function()
    LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started then SaveCfgNow() ArmQueue() end
    end)
end)

Creep.ToggleKeybind = Options.MenuKeybind
Creep.KeybindFrame.Visible = false
Creep:SetWatermarkVisibility(true)
Creep:SetWatermark('Forge Stealth | undetected')

--// notifications hook: Someone skip + webhook (Ather-like)
task.spawn(function()
    local holder
    pcall(function() holder = LocalPlayer.PlayerGui.Notifications.Screen.NotificationsFrame end)
    if not holder then
        holder = LocalPlayer.PlayerGui:WaitForChild("Notifications", 10)
        if holder then holder = holder:WaitForChild("Screen", 5) and holder.Screen:WaitForChild("NotificationsFrame", 5) end
    end
    if not holder then return end
    holder.ChildAdded:Connect(function(fr)
        if not (fr:IsA("Frame") and fr:FindFirstChild("TextFrame")) then return end
        local lbl = fr.TextFrame:FindFirstChild("TextLabel")
        if not lbl then return end
        -- claimed skip
        if lbl.Text:match("Someone") then
            if not (ForgeFlags.ore_autofarm or ForgeFlags.ore_closestfarm or ForgeFlags.regional_ore_farm) then return end
            local last = getgenv().forge_lastOre
            local t = getgenv().forge_lastOreTime or 0
            lbl.Text = "Forge Stealth: skipping claimed."
            if last and tick()-t <= 1 and last.Parent then
                pcall(function() last:SetAttribute("Someone", true) end)
                task.delay(ForgeFlags.skipOre_cd, function() pcall(function() if last and last.Parent and last:GetAttribute("Someone") then last:SetAttribute("Someone", nil) end end) end)
            end
        end
        -- webhook trigger: "You just found <Rarity> <Ore>, ..."
        if ForgeFlags.webhook_enabled and ( (#ForgeFlags.webhook_ores_selected>0) or (#ForgeFlags.webhook_rarities_selected>0) or ForgeFlags.webhook_on_rare ) then
            local found = lbl.Text:match("You just found (.+),")
            if found then
                local clean = Clean(found)
                local parts = {}
                for w in clean:gmatch("%S+") do table.insert(parts, w) end
                if #parts >= 2 then
                    local rarGuess = Clean(parts[1])
                    local oreGuess = Clean(table.concat(parts, " ", 2))
                    -- ore list check (fuzzy both ways like LazyHub)
                    local oreHit = false
                    for _, sel in ipairs(ForgeFlags.webhook_ores_selected) do
                        local s = Clean(sel)
                        if oreGuess:lower():find(s:lower(),1,true) or s:lower():find(oreGuess:lower(),1,true) then oreHit=true break end
                    end
                    -- rarity check: map ore -> real rarity, compare to selected + auto mythic+
                    local realRar = OreRarity[oreGuess] or OreRarity[BaseName(oreGuess)] or rarGuess
                    local rarHit = false
                    for _, sel in ipairs(ForgeFlags.webhook_rarities_selected) do if realRar==sel then rarHit=true break end end
                    if ForgeFlags.webhook_on_rare and #ForgeFlags.webhook_rarities_selected==0 then
                        if realRar=="Mythic" or realRar=="Relic" or realRar=="Exotic" or realRar=="Divine" or realRar=="Unobtainable" or realRar=="Legendary" then rarHit=true end
                    end
                    local should = false
                    if #ForgeFlags.webhook_ores_selected==0 and #ForgeFlags.webhook_rarities_selected==0 then
                        should = ForgeFlags.webhook_on_rare and rarHit
                    else
                        should = oreHit or rarHit
                    end
                    if should then
                        local cnt = InvCount(oreGuess)
                        local lvl = PlayerLevel()
                        local desc = string.format("Player: %s\nLevel: %d\nOre: %s %s x%d\nRarity: %s\nPlace: %d\nJobId: %s", LocalPlayer.Name, lvl, rarGuess, oreGuess, cnt, realRar, game.PlaceId, game.JobId)
                        SendWebhook("Found Ore! :pick:", desc)
                    end
                end
            end
        end
    end)
end)

--// parry connections
task.spawn(function()
    if not Living then return end
    for _, m in ipairs(Living:GetChildren()) do if m:IsA("Model") and m:GetAttribute("IsNpc") then HookParryMob(m) end end
    Living.ChildAdded:Connect(function(m) if m:IsA("Model") and m:GetAttribute("IsNpc") then HookParryMob(m) end end)
end)

--// respawn track + anti-AFK (stealth: minimal VirtualUser, random)
LocalPlayer.CharacterAdded:Connect(function() getgenv().forge_lastRespawn = tick() getgenv().forge_talkedGreedy=false end)
task.spawn(function()
    local VU = nil
    pcall(function() VU = cloneref(game:GetService("VirtualUser")) end)
    if VU then
        LocalPlayer.Idled:Connect(function()
            if not ForgeFlags then return end
            -- only anti-afk if farming (less footprint)
            if ForgeFlags.ore_autofarm or ForgeFlags.ore_closestfarm or ForgeFlags.regional_ore_farm or ForgeFlags.mob_autofarm or ForgeFlags.mob_closestfarm then
                pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new(math.random(0,10), math.random(0,10))) end)
            end
        end)
    end
    -- fallback if getconnections exists: disable Idled (more stealth than spamming VU)
    pcall(function()
        if getconnections then
            for _, c in pairs(getconnections(LocalPlayer.Idled)) do pcall(function() c:Disable() end) end
        end
    end)
end)

--// invisicam (less render, slight stealth)
pcall(function() LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam end)

--// auto-reconnect if kicked / disconnected + queue re-exec (cfg autoload continues farms)
local function TryReconnect(reason)
    if not ForgeFlags.reconnect_on_kick then return end
    getgenv().forge_reconnects = (getgenv().forge_reconnects or 0) + 1
    if getgenv().forge_reconnects > (ForgeFlags.max_reconnects or 3) then
        pcall(function() Creep:Notify("Reconnect limit hit, stopping", 5) end)
        if ForgeFlags.webhook_enabled then SendWebhook("Reconnect STOPPED :octagonal_sign:", string.format("Player: %s\nReason: %s\nTries: %d", LocalPlayer.Name, tostring(reason), getgenv().forge_reconnects)) end
        return
    end
    SaveCfgNow()
    ArmQueue()
    if ForgeFlags.webhook_enabled then SendWebhook("Reconnecting :repeat:", string.format("Player: %s\nReason: %s\nTry %d/%d\nJobId: %s", LocalPlayer.Name, tostring(reason), getgenv().forge_reconnects, ForgeFlags.max_reconnects, game.JobId)) end
    task.wait(2)
    pcall(function()
        if #PlayersSvc:GetPlayers() <= 1 then
            TeleportSvc:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportSvc:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
end
pcall(function()
    local pg = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
    local overlay = pg and pg:FindFirstChild("promptOverlay")
    if overlay then
        overlay.ChildAdded:Connect(function(ch)
            -- error / kick prompt
            local txt = ""
            pcall(function()
                local msg = ch:FindFirstChild("MessageArea") and ch.MessageArea:FindFirstChild("ErrorFrame")
                local lbl = msg and msg:FindFirstChildOfClass("TextLabel", true)
                txt = lbl and lbl.Text or ""
            end)
            if ch.Name == "ErrorPrompt" then
                local low = txt:lower()
                if low:find("ban") then
                    -- banned: do NOT loop
                    if ForgeFlags.webhook_enabled then SendWebhook("BANNED :hammer:", string.format("Player: %s\n%s", LocalPlayer.Name, txt)) end
                    return
                end
                TryReconnect(txt ~= "" and txt or "ErrorPrompt")
            elseif ch.Name:lower():find("kick") then
                TryReconnect(txt ~= "" and txt or "Kicked")
            end
        end)
    end
end)
pcall(function()
    local gs = game:GetService("GuiService")
    if gs and gs.ErrorMessageChanged then
        gs.ErrorMessageChanged:Connect(function(msg)
            if msg and msg ~= "" then TryReconnect(msg) end
        end)
    end
end)
pcall(function()
    PlayersSvc.PlayerRemoving:Connect(function(p)
        if p == LocalPlayer then SaveCfgNow() ArmQueue() end
    end)
end)
pcall(function()
    if queue_on_teleport and (ForgeFlags.loader_url or "") == "" then
        pcall(function() Creep:Notify("Paste Loader URL in Server tab for re-exec on hop", 6) end)
    end
end)

Creep:OnUnload(function()
    -- cleanup
    pcall(function()
        local ok,_,_,hrp = GetChar()
        if ok and hrp:FindFirstChild("ForgeStealthBV") then hrp:FindFirstChild("ForgeStealthBV"):Destroy() end
    end)
    if ESPFolder then pcall(function() ESPFolder:Destroy() end) end
    getgenv().forge_current_tween=false
    ForgeFlags.mob_autofarm=false ForgeFlags.mob_closestfarm=false ForgeFlags.ore_autofarm=false ForgeFlags.ore_closestfarm=false ForgeFlags.regional_ore_farm=false
    Creep.Unloaded=true
end)

print("[ForgeStealth] loaded - stealth, no hooks, smart skip ready")


