local easing = require("easing")

local assets=
{
    Asset("ANIM", "anim/hound_basic.zip"),
    Asset("ANIM", "anim/hound_basic_water.zip"),
    Asset("ANIM", "anim/hound.zip"),
    Asset("ANIM", "anim/hound_ocean.zip"),
    Asset("ANIM", "anim/hound_red.zip"),
    Asset("ANIM", "anim/hound_red_ocean.zip"),
    Asset("ANIM", "anim/hound_ice.zip"),
    Asset("ANIM", "anim/hound_ice_ocean.zip"),

    Asset("ANIM", "anim/hound_gold.zip"),
    Asset("ANIM", "anim/hound_nightmare.zip"),
    Asset("ANIM", "anim/hound_cadence.zip"),

    Asset("SOUND", "sound/hound.fsb"),
}

local prefabs=
{
    "houndstooth",
    "monstermeat"
}

local brain = require "brains/koko_brain"
local peace_brain = require "brains/koko_peaceful_brain"

local sounds =
{
    pant = "dontstarve/creatures/hound/pant",
    attack = "dontstarve/creatures/hound/attack",
    bite = "dontstarve/creatures/hound/bite",
    bark = "dontstarve/creatures/hound/bark",
    death = "dontstarve/creatures/hound/death",
    sleep = "dontstarve/creatures/hound/sleep",
    growl = "dontstarve/creatures/hound/growl",
    howl = "dontstarve/creatures/together/clayhound/howl",
}

local WAKE_TO_FOLLOW_DISTANCE = 6
local Names = {"Aelita","Alyx","Ava","Bella","Bunny","Coraline","Cynthia","Daisy","Dawn","Destiny","Dust","Eden","Eva","Fluffybottoms","Georgia","Harley","Holly","Hunter","Iris","Ivy","Jackie","Jennie","Jester","Julie","Karma","Kate","Katrina","Koko","Lorena","Lucile","Maggie","Mercy","MikkuMikku","Nelly","Nikki","Oracle","Penelope","Piper","Precious","Princess","Quinn","Ravin","Rose","Roxanne","Ruby","Sarah","Sasha","Sue","Suzy","Tanya","Tiny Tina","Trixy","Useless","Valerie","Velma","Veronica","Vivi","Waxwell","Wilson","X","Yoda","Yvette","Zoe"}
local BonusNames = {"Cadence","Choral","Bard","Monk","Dove","Eli","Bolt","Dorian","Melody","Aria","Coda","Scooby"}
-- Names list is 1-63
-- Bonus list is 1-12

local function retargetfn(inst)
    if inst.components.follower and inst.components.follower:GetLeader() == nil then
        local nearest = FindEntity(inst, 100, function(guy)
            return guy:HasTag("player")
            end)
        if nearest and nearest.components.leader then
            nearest.components.leader:AddFollower(inst)
            inst.components.follower:AddLoyaltyTime(60)
        end
    end
end

local function OnStopFollowing(inst) 
    --inst:RemoveTag("companion") 
end

local function OnStartFollowing(inst) 
    --inst:AddTag("companion") 
end

local function KeepTarget(inst, target)
    if inst.components.health.currenthealth < (inst.components.health.maxhealth/3) or target:HasTag("mamahound") or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE*2) then
        return false
    else
        return inst.components.combat:CanTarget(target) and inst:IsNear(target, TUNING.HOUND_FOLLOWER_TARGET_KEEP)
    end
end

local function OnAttacked(inst, data)
    if inst.components.health.currenthealth > (inst.components.health.maxhealth/3) and not data.attacker:HasTag("mamahound") then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function OnNewTarget(inst, data)
--
end

local function OnKilled(inst)
-- You are a horrible person.
    if math.random(1,100)>75 then
        local x, y, z = inst.Transform:GetWorldPosition()
        local collar = SpawnPrefab("brokencollar")
        if collar ~= nil then
            collar.Transform:SetPosition(x, y, z)
            collar.MyName = inst.MyName
            collar.flavor = inst.flavor
            collar.houndsize = inst.houndsize
        end
    end
end

local function OnOpen(inst)
    inst:SetBrain(peace_brain)
end

local function OnClose(inst)
    inst:SetBrain(brain)
end

--
-- Change functions transform the hounds and set their variables respective to whatever form they take.
--

local function normalchange(inst)
    inst.AnimState:SetBank("hound")
    inst.AnimState:SetBuild("hound_ocean")

    inst.components.combat:SetDefaultDamage(10)
    inst.components.combat:SetAttackPeriod(1.75)
    inst.components.locomotor.runspeed = 10
    inst.components.health:SetMaxHealth(1000*HoundHealth)
    inst.components.health:StartRegen(3*HoundRegen, 0.2) -- ~1.5%
    inst.components.health.fire_damage_scale = 1
    inst.flavor = "normal"
    inst.sterile = false

    inst.components.inspectable.description = ("Hello, " .. inst.MyName)
end

local function icechange(inst)
    inst.AnimState:SetBank("hound")
    inst.AnimState:SetBuild("hound_ice_ocean")

    inst.components.combat:SetDefaultDamage(15) -- (20/2=10dps) default dps
    inst.components.combat:SetAttackPeriod(2) -- Normal Speed (35/2=17.5dps)
    inst.components.locomotor.runspeed = 10
    inst.components.health:SetMaxHealth(1500*HoundHealth)
    inst.components.health:StartRegen(6*HoundRegen, 0.2) -- 2X as strong
    inst.components.health.fire_damage_scale = 0.8 -- Fire resistant
    inst.flavor = "coldkoko"

    inst.components.inspectable.description = ("Stay frosty, " .. inst.MyName)
end

local function firechange(inst)
    inst.AnimState:SetBank("hound")
    inst.AnimState:SetBuild("hound_red_ocean")

    inst.components.combat:SetDefaultDamage(20) -- (20/2=10dps) default dps
    inst.components.combat:SetAttackPeriod(1.2) -- Faster Speed (30/1.5=20dps)
    inst.components.locomotor.runspeed = 10
    inst.components.health:SetMaxHealth(1500*HoundHealth)
    inst.components.health:StartRegen(4*HoundRegen, 0.2) -- 1.3X as strong
    inst.components.health.fire_damage_scale = 0 -- Fireproof
    inst.flavor = "hotkoko"

    inst.components.inspectable.description = (inst.MyName .. " looks fiesty.")
end

-- Tempmorarily disabled due to sprite issues.
local function crazychange(inst)
    normalchange(inst)
    --[[inst.AnimState:SetBuild("hound_nightmare")

    inst.components.combat:SetDefaultDamage(24) -- (20/2=10dps) default dps
    inst.components.combat:SetAttackPeriod(1) -- Faster Speed (40/1.5=~26.66dps)
    inst.components.locomotor.runspeed = 10
    inst.components.health:SetMaxHealth(1200*HoundHealth)
    inst.components.health:StartRegen(10*HoundRegen, 0.2) -- 3.3X as fast
    inst.components.health.fire_damage_scale = 0 -- Fireproof
    inst.flavor = "crazykoko"
    inst.sterile = true

    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED
    inst.components.inspectable.description = (inst.MyName .. "?")]]
end

-- Tempmorarily disabled due to sprite issues.
local function goldchange(inst)
    normalchange(inst)
    --[[inst.AnimState:SetBuild("hound_gold")

    inst.components.combat:SetDefaultDamage(20) -- (20/2=10dps) default dps
    inst.components.combat:SetAttackPeriod(0.5) -- Faster Speed (20/.5=40dps)
    inst.components.locomotor.runspeed = 10
    inst.components.health:SetMaxHealth(2000*HoundHealth)
    inst.components.health:StartRegen(3*HoundRegen, 0.1) -- 2X strength/speed (Net 4X)
    inst.components.health.fire_damage_scale = 0.5 -- Half Damage
    inst.flavor = "shinykoko"
    inst.sterile = true

    inst.components.inspectable.description = (inst.MyName .. " is shiny.")--]]
end

-- Tempmorarily disabled due to sprite issues.
local function transformCadence(inst)
    normalchange(inst)
    --[[inst.AnimState:SetBuild("hound_cadence")

    inst.components.combat:SetDefaultDamage(90) -- (20/2=10dps) default dps
    inst.components.combat:SetAttackPeriod(4) -- 1/2 Speed (90/4=22.5dps)
    inst.components.locomotor.runspeed = 15 -- Faster!
    inst.components.health:SetMaxHealth(10*HoundHealth)
    inst.components.health:StartRegen(10*HoundRegen, 0.1) -- 2X strength/speed (Net 4X)
    inst.components.health.fire_damage_scale = 0.75 -- Fire resistant
    inst.flavor = "unknown"

    inst.components.inspectable.description = ("...Cadence?")]]
end

local function  carrierchange(inst)
    inst.AnimState:SetBank("hound")
    inst.AnimState:SetBuild("hound_ocean")

    inst.components.combat:SetDefaultDamage(10) -- Does half damage!
    inst.components.combat:SetAttackPeriod(2)
    inst.components.locomotor.runspeed = 10
    inst.components.health:SetMaxHealth(1000*HoundHealth)
    inst.components.health:StartRegen(5*HoundRegen, 0.2)
    inst.components.health.fire_damage_scale = 1 -- Fire resistant
    inst.flavor = "chest"
    inst.sterile = true

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("chester")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose

    inst.components.inspectable.description = ("Thanks, " .. inst.MyName)
end

local function Rename(inst)
    local tempname = "Hound"
    inst.tempname = inst.MyName
    if math.random(1,100)>95 then
        inst.MyName = BonusNames[math.random(1, 12)] -- Rare names, 1% chance per hound.
    else
        inst.MyName = Names[math.random(1, 63)]
    end
    inst.components.named:SetName(inst.MyName)
    inst.components.inspectable.description = (inst.tempname .. ", you shall be known as " .. inst.MyName .. " from now on!")
end

-- This allows players to give items to the companions to change their behavior!
local function ShouldAcceptItem(inst, item)

    local nearest = FindEntity(inst, 100, function(guy)
    return guy:HasTag("player")
    end)

    if  nearest:HasTag("player") then
        if item.prefab == "bluegem" and inst.flavor ~= "shinykoko" and inst.flavor ~= "chest" then
            if inst.flavor == "coldkoko" then
                return false
            else
                icechange(inst)
                return true
            end

        elseif item.prefab == "redgem" and inst.flavor ~= "shinykoko" and inst.flavor ~= "chest" then
            if inst.flavor == "hotkoko" then
                return false
            else
                firechange(inst)
                return true
            end

        elseif item.prefab == "nightmaretreat" and inst.flavor ~= "shinykoko" and inst.flavor ~= "chest" then
            if inst.flavor == "crazykoko" then
                return false
            else
                if inst.crazy <= 1 then
                    inst.crazy = inst.crazy+1
                end
                if inst.crazy == 2 then
                    crazychange(inst)
                end
                return true
            end

        elseif item.prefab == "meat" then
            if inst.components.follower then
                local nearest = FindEntity(inst, 100, function(guy)
                    return guy:HasTag("player") or guy:HasTag("skalikas")
                    end)
                if nearest and nearest.components.leader then
                    nearest.components.leader:AddFollower(inst)
                    inst.components.follower:AddLoyaltyTime(999999)
                end
            end
            return true

        elseif item.prefab == "smallmeat" and inst.sterile == false then
            inst.fed = inst.fed+1
            return true

        elseif item.prefab == "purplegem" then
            inst.components.knownlocations:RememberLocation(inst.patrolcount, Point(inst.Transform:GetWorldPosition()))

            inst.patrolcount = inst.patrolcount + 1
            return false

        elseif item.prefab == "monstermeat" and inst.patrolcount > 0 then
            inst.patrolactive = true
            return true
        elseif item.prefab == "papyrus" then
            Rename(inst)
            return true

        -- New elseif calls for item.prefab go above. Below are debug commands.
        elseif nearest.userid == "KU_M27Zfz_d" then
            if item.prefab == "carrot" then -- Carrot = Make Baby!
                local x, y, z = inst.Transform:GetWorldPosition()
                SpawnPrefab("lana").Transform:SetPosition(x, y, z)
                return true
            elseif item.prefab == "goldnugget" then -- goldnugget = gold hound
                goldchange(inst)
                return true
            elseif item.prefab == "thulecite" then -- thulecite = Cadence
                transformCadence(inst)
                return true
            elseif item.prefab == "dragonpie" then -- Hounds keep me healthy.
                nearest.components.health:StartRegen(1, 10) -- +1 hp/10 seconds, same as poly.
                return false
            elseif item.prefab == "cactus_meat" then -- Blackout
                local delay = 0
                if TheWorld.state.isnight then
                    TheWorld:PushEvent("ms_nextphase")
                    delay = 1
                end
                inst:DoTaskInTime(delay, function()
                TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 1, night = 15})
                end)
            else -- Not a dev command
                return false
            end
        -- Final check for all other values returning false.
        else
            return false
        end
    else
        return false
    end
end

local function HavePuppy(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if(inst.flavor == "hotkoko") and math.random(1,100)>60 then
        SpawnPrefab("lanaflame").Transform:SetPosition(x, y, z)
        inst.fed = inst.fed-5
    elseif(inst.flavor == "coldkoko") and math.random(1,100)>60 then
        SpawnPrefab("lanafrost").Transform:SetPosition(x, y, z)
        inst.fed = inst.fed-5
    else
        SpawnPrefab("lana").Transform:SetPosition(x, y, z)
        inst.fed = inst.fed-5
    end
    if inst.fed < 0 then
            inst.fed = 0
    end
end

local function OnStartMoon(inst)
    local randomizer = math.random()
    -- Have a baby! More likely to happen on full moons than otherwise!
    if inst.sterile == false and randomizer > 1/(inst.fed+1) then
        HavePuppy(inst)
    end
    -- .1% chance of becoming a shiny hound per day alive.
    if inst.age >= 25 and randomizer < (.001*inst.age) and inst.flavor == "normal" then
        goldchange(inst)
    end
end

local function OnStartNight(inst)
    -- TheWorld.net.components.clock:OnUpdate(30*16*1) To Skip Days via console
    inst.age = inst.age+1
    if inst.flavor == "normal" then
        if inst.age <= 50 then
            inst.components.health:SetMaxHealth((1000+(inst.age*20))*HoundHealth) -- Default hounds go from 1K-2K health in 50 days.
        else
            inst.components.health:SetMaxHealth(2000*HoundHealth) -- Cap is 2K, can turn gold at 1.5K to instantly go to 2K.
        end
    end
    -- Have a baby!
    local randomizer = math.random()
    if inst.sterile == false and randomizer > 1/((inst.fed/3)+1) and inst.age < 50 then
        HavePuppy(inst)
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    -- Generic got item.
end

local function OnBrushed(inst, doer, numprizes)
    --  Do things when brushed.
end

local function OnRefuseItem(inst, item)
    -- Ignore Player.
end

local function ShouldWakeUp(inst)
    -- Won't wake up if below 25% health.
    if inst.components.health.currenthealth < (inst.components.health.maxhealth/2) then
        return false
    else
        return ((inst.components.follower and inst.components.follower.leader and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)) or (inst.components.combat and inst.components.combat.target) or (TheWorld.state.isnight == false))
    end
end

local function ShouldSleep(inst)
    -- Will never fall asleep if too far from leader
    -- Falls asleep at 33% health remaining, even in combat
    -- Falls asleep at night while not in combat
    if inst.components.follower and inst.components.follower.leader and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE) then
        return false
    elseif inst.components.health.currenthealth < (inst.components.health.maxhealth/3) then
        return true
    else
        return TheWorld.state.isnight and not (inst.components.combat and inst.components.combat.target)
    end
end

local function onupdate(inst, dt)
    -- Every second this is run.
    -- At five seconds, increment patrol pathway. If at end of path, turn off patrol.
    if inst.patrolactive == true then
        inst.patroltimer = inst.patroltimer + dt
        if inst.patroltimer > 5 then
            if inst.patroltracker == inst.patrolcount then
                inst.patrolactive = false
                inst.patroltracker = 0
                inst.patroltimer = 0
            else
                inst.patroltracker = inst.patroltracker + 1
                inst.patroltimer = 0
            end
        end
    end
end

--
-- Save/Load happen when a server closes and opens to keep hound variables when restarting the server.
--

local function OnSave(inst, data)
    data.MyName = inst.MyName
    data.flavor = inst.flavor
    data.age = inst.age
    data.crazy = inst.crazy
    data.alien = inst.alien
    data.fed = inst.fed
    data.newHound = inst.newHound
    data.houndsize = inst.houndsize
end

local function OnPreLoad(inst, data)
    if not data then return end

    if data.MyName ~= nil then
        inst.MyName = data.MyName
        inst.components.inspectable.description = ("Hello, " .. data.MyName)
    end

    if data.flavor == "normal" then
        normalchange(inst)
    elseif data.flavor == "coldkoko" then
        icechange(inst)
    elseif data.flavor == "hotkoko" then
        firechange(inst)
    elseif data.flavor == "shinykoko" then
        goldchange(inst)
    elseif data.flavor == "crazykoko" then
        crazychange(inst)
    end
    
    if data.age ~= nil then
        inst.age = data.age
    end

    if inst.flavor == "normal" and inst.age ~= nil then
        if inst.age <= 1000 then
            inst.components.health:SetMaxHealth((1000+(inst.age*20))*HoundHealth) -- Default hounds go from 1K-2K health in 50 days.
        else
            inst.components.health:SetMaxHealth(2000*HoundHealth) -- Cap is 2K, can turn gold at 1.5K to instantly go to 2K.
        end
    end

    if data.crazy ~= nil then
        inst.crazy = data.crazy
    end
    if data.alien ~= nil then
        inst.alien = data.alien
    end
    if data.fed ~= nil then
        inst.fed = data.fed
    end

    if data.newHound ~= nil then
        inst.newHound = data.newHound
    end

    if data.houndsize ~= nil then
        inst.houndsize = data.houndsize
        local scale = easing.inQuad(math.random(), 0.93+(inst.houndsize*.14), 0, 1) -- Base, Variance, ???
        inst.Transform:SetScale(scale, scale, scale)
    end
end

--
-- Main function that all hound companions share.
--

local function fn(bank, build)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)

    local flavor = "normal"
    local age = 0
    local crazy = 0
    local alien = false
    local sterile = false
    local fed = 0
    local newHound = true
    local patrolcount = 0
    local patroltracker = 0
    local patroltimer = 0
    local patrolactive = false


    inst.flavor = "normal"
    inst.age = 0
    inst.crazy = 0
    inst.alien = false
    inst.sterile = false
    inst.fed = 0
    inst.newHound = true
    inst.patrolcount = 0
    inst.patroltracker = 0
    inst.patroltimer = 0
    inst.patrolactive = false

    local houndsize = 1
    inst.houndsize = math.random()
    local scale = easing.inQuad(math.random(), 0.95+(inst.houndsize*.1), 0, 1) -- Base, Variance, ???
    inst.Transform:SetScale(scale, scale, scale)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = sounds

    inst:AddComponent("locomotor")
    inst.components.locomotor.runspeed = 10
    MakeCharacterPhysics(inst, 10, .5)
    inst.DynamicShadow:SetSize(2.5, 1.5)
    inst.Transform:SetFourFaced()

    inst:SetBrain(brain)
    inst:SetStateGraph("SGhound")

    inst:AddTag("companion")
    inst:AddTag("scarytoprey")
    inst:AddTag("notraptrigger")
    inst:AddTag("mamahound")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(20)
    inst.components.combat:SetAttackPeriod(2) -- (20/2=10dps)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetHurtSound("dontstarve/creatures/hound/hurt")
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("attacked", OnAttacked)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1000*HoundHealth)
    inst.components.health:StartRegen(5*HoundRegen, 0.2)
    inst.components.health.fire_damage_scale = 1 -- Default

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("death", OnKilled)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"houndstooth","houndstooth","monstermeat"})

    inst:AddComponent("follower")
    inst:ListenForEvent("stopfollowing", OnStopFollowing)
    inst:ListenForEvent("startfollowing", OnStartFollowing)
    inst.components.follower.maxfollowtime = 9999999
    inst.components.follower.keepdeadleader = true

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(3, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = 0

    inst:WatchWorldState("startnight", OnStartNight)
    inst:WatchWorldState("isfullmoon", OnStartMoon)

    inst:AddComponent("leader")

    -- Give then a name unless they already have one!
    if inst.MyName == nil then
        if math.random(1,100)>99 then
            inst.MyName = BonusNames[math.random(1, 12)] -- Rare names, 1% chance per hound.
        else
            inst.MyName = Names[math.random(1, 63)]
        end
    end

    inst:AddComponent("named")
    inst.components.named:SetName(inst.MyName)

    inst:AddComponent("inspectable")
    inst.components.inspectable.description = ("Hello, " .. inst.MyName)

    inst:AddComponent("brushable")
    inst.components.brushable.regrowthdays = 2
    inst.components.brushable.max = 1
    inst.components.brushable.prize = "ash"
    inst.components.brushable:SetOnBrushed(OnBrushed)

    inst:AddComponent("knownlocations")
    inst:DoPeriodicTask(1, onupdate, nil, 1) --arguments:(time, fn, delay, fnArguments)

    -- 1% chance that a new hound spawns transformed! :D
    if newHound == true then
        if math.random(1, 100) > 90 then
            if math.random(1, 100) > 99 then
                crazychange(inst)
            else
                if math.random(1, 100) > 50 then
                    icechange(inst)
                else
                    firechange(inst)
                end
            end
        end
        newHound = false
    end

    -- Copy of hound.lua for water walking
    inst:AddComponent("embarker")
    inst.components.embarker.embark_speed = inst.components.locomotor.runspeed
    inst.components.embarker.antic = true

    inst.components.locomotor:SetAllowPlatformHopping(true)

    inst:AddComponent("amphibiouscreature")
    inst.components.amphibiouscreature:SetBanks("hound", "hound_water")
    inst.components.amphibiouscreature:SetEnterWaterFn(
        function(inst)
            inst.landspeed = inst.components.locomotor.runspeed
            inst.components.locomotor.runspeed = TUNING.HOUND_SWIM_SPEED
            inst.hop_distance = inst.components.locomotor.hop_distance
            inst.components.locomotor.hop_distance = 4
        end)            
    inst.components.amphibiouscreature:SetExitWaterFn(
        function(inst)
        if inst.landspeed then
            inst.components.locomotor.runspeed = inst.landspeed 
            end
            if inst.hop_distance then
                inst.components.locomotor.hop_distance = inst.hop_distance
            end
        end)

    inst.components.locomotor.pathcaps = { allowocean = true }
    -- End copy of hound.lua

    inst.OnSave = OnSave
    inst.OnPreLoad = OnPreLoad

    return inst
end

--
-- C_Spawn("name") functions. These take over AFTER the main function, overwriting variables.
--

-- Summon a Basic hound.
function fnBasic()
    local inst = fn("hound", "hound_ocean")

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

-- Summon a Cadence hound.
function fnCadence()
    local inst = fn("hound","hound_cadence")

    if not TheWorld.ismastersim then
        return inst
    end

    transformCadence(inst)

    return inst
end

-- Summon a flame hound.
function fnflame()
    local inst = fn("hound","hound_red_ocean")
    
    if not TheWorld.ismastersim then
        return inst
    end

    firechange(inst)

    return inst
end

-- Summon a frost hound.
function fnfrost()
    local inst = fn("hound","hound_ice_ocean")

    if not TheWorld.ismastersim then
        return inst
    end

    icechange(inst)

    return inst
end

-- Summon a crazy hound.
function fncrazy()
    local inst = fn("hound","hound_nightmare")

    if not TheWorld.ismastersim then
        return inst
    end

    crazychange(inst)

    return inst
end

-- Summon a shiny hound.
function fnshiny()
    local inst = fn("hound","hound_gold")

    if not TheWorld.ismastersim then
        return inst
    end

    goldchange(inst)

    return inst
end

-- Summon a diseased hound.
function fndiseased()
    local inst = fn("hound","hound_ocean")

    if not TheWorld.ismastersim then
        return inst
    end

    if inst.components.health ~= nil then -- Let's not crash if it didn't update.
        inst.components.health:StartRegen(-5, 0.1)
    end

    return inst
end

-- Summon a carrier hound.
function fncarrier()
    local inst = fn("hound","hound_ocean")

    if not TheWorld.ismastersim then
        return inst
    end

    carrierchange(inst)

    return inst
end

-- Resummon a dead hound.
function fnghost()
    local inst = fn("hound","hound_ocean")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoTaskInTime(0.5, function()
        inst.components.inspectable.description = ("Hello, " .. inst.MyName)
        inst.components.named:SetName(inst.MyName)

        if inst.flavor == "normal" then
            normalchange(inst)
        elseif inst.flavor == "coldkoko" then
            icechange(inst)
        elseif inst.flavor == "hotkoko" then
            firechange(inst)
        elseif inst.flavor == "shinykoko" then
            goldchange(inst)
        elseif inst.flavor == "crazykoko" then
            crazychange(inst)
        end

        if inst.houndsize ~= nil then
            local scale = easing.inQuad(math.random(), 0.93+(inst.houndsize*.14), 0, 1) -- Base, Variance, ???
            inst.Transform:SetScale(scale, scale, scale)
        end
    end) -- Do task in time
    return inst
end

return  Prefab( "common/monsters/koko", fnBasic, assets, prefabs),
        Prefab( "common/monsters/kokocadence", fnCadence, assets, prefabs),
        Prefab( "common/monsters/kokoflame", fnflame, assets, prefabs),
        Prefab( "common/monsters/kokofrost", fnfrost, assets, prefabs),
        Prefab( "common/monsters/kokocrazy", fncrazy, assets, prefabs),
        Prefab( "common/monsters/kokoshiny", fnshiny, assets, prefabs),
        Prefab( "common/monsters/kokodiseased", fndiseased, assets, prefabs),
        Prefab( "common/monsters/kokocarrier", fncarrier, assets, prefabs),
        Prefab( "common/monsters/kokoghost", fnghost, assets, prefabs)