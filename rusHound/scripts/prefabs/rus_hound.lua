local assets =
{
    Asset("ANIM", "anim/hound_basic.zip"),
    Asset("ANIM", "anim/hound_basic_water.zip"),
    Asset("ANIM", "anim/hound.zip"),
    Asset("ANIM", "anim/hound_ocean.zip"),

    Asset("SOUND", "sound/hound.fsb"),
}

local prefabs =
{
    "houndstooth",
    "monstermeat"
}

local brain = require("brains/rus_hound_brain")

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
    hurt = "dontstarve/creatures/hound/hurt",
}

local WAKE_TO_FOLLOW_DISTANCE = 6
local SHARE_TARGET_DIST = 30

-- Ночное поведение
local function ShouldWakeUp(inst)
    return
    (
        (inst.components.follower
         and inst.components.follower.leader
         and not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE)
        )
        or (inst.components.combat and inst.components.combat.target)
        or (TheWorld.state.isnight == false)
    )
end

local function ShouldSleep(inst)
    return
            TheWorld.state.isnight == true
            and not (inst.components.combat and inst.components.combat.target)
            and not (inst.components.burnable and inst.components.burnable:IsBurning())
end

local function OnNewTarget(inst, data)
    if inst.components.sleeper:IsAsleep() then
        inst.components.sleeper:WakeUp()
    end
end

local function OnKilled(inst)
    -- You are a horrible person.
    local collar = SpawnPrefab("rus_hound_collar")
    collar.Transform:SetPosition(x, y, z)
    collar.MyName = inst.name
end

------------
local function retargetfn(inst)
    if  inst.components.entitytracker:GetEntity("home") ~= nil then
        return
    end
    if
        inst.components.follower
        and inst.components.follower:GetLeader() == nil
    then
        local nearest =
        FindEntity(inst, 100, function(guy)
            return guy:HasTag("player")
        end, nil, nil)
        if nearest and nearest.components.leader then
            nearest.components.leader:AddFollower(inst)
        end
    end
end

local function KeepTarget(inst, target)
    if inst.components.health.currenthealth < (inst.components.health.maxhealth/3)
            or target:HasTag("rus_hound")
            or not inst.components.follower:IsNearLeader(WAKE_TO_FOLLOW_DISTANCE*2) then
        return false
    else
        return inst.components.combat:CanTarget(target)
                and inst:IsNear(target, TUNING.HOUND_FOLLOWER_TARGET_KEEP)
    end
end

------------
---Тебя атакуют
local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST,
            function(dude)
                return not (dude.components.health ~= nil and dude.components.health:IsDead())
                        and not dude:HasTag("rus_hound")
                        and data.attacker ~= (dude.components.follower ~= nil and dude.components.follower.leader or nil)
            end, 5)
end

local function OnAttackOther(inst, data)
    inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST,
            function(dude)
                return not (dude.components.health ~= nil and dude.components.health:IsDead())
                        and not dude:HasTag("rus_hound")
                        and data.target ~= (dude.components.follower ~= nil and dude.components.follower.leader or nil)
            end, 5)
end
------------

local function OnStartNight(inst)
    if inst.age < 50 then
        inst.age = inst.age + 1
        inst.components.combat:SetDefaultDamage(TUNING.HOUND_DAMAGE + (1 * inst.age))
        inst.components.health:SetMaxHealth(1000 + (50 * inst.age))
        inst.components.health:StartRegen(5 + (1 * inst.age), 0.2)
    end
end

local function OnSave(inst, data)
    data.ispet = inst:HasTag("rus_hound") or nil
    data.isInHome = inst:HasTag("sitting_home") or nil
    data.age = inst.age
end

local function OnLoad(inst, data)
    if data ~= nil then
        if data.ispet ~= nil then inst:AddTag("rus_hound") end
        if data.age ~= nil then
            inst.age = data.age
            inst.components.combat:SetDefaultDamage(TUNING.HOUND_DAMAGE + (1 * inst.age))
            inst.components.health:SetMaxHealth(1000 + (50 * inst.age))
            inst.components.health:StartRegen(5 + (1 * inst.age), 0.2)
        end
        if inst.sg ~= nil then
            inst.sg:GoToState("idle")
        end
    end
end

local function OnLoadPostPass(inst, newents, data)
    local den = inst.components.entitytracker:GetEntity("home")
    if den ~= nil and den.components.kitcoonden ~= nil then
        den.components.kitcoonden:AddKitcoon(inst)
    end
end

local function fncommon(bank, build, morphlist, custombrain, tag, data)
    data = data or {}

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(2.5, 1.5)
    inst.Transform:SetFourFaced()

    inst:AddTag("notraptrigger")
    inst:AddTag("companion")
    inst:AddTag("rus_hound")

    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("spawnfader")

    inst.entity:SetPristine()

    inst.age = 0

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = sounds

    inst:AddComponent("named")
    inst:AddComponent("named_replica")
    inst.components.named:SetName("Рекс")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = TUNING.HOUND_SPEED

    inst:SetStateGraph("SGhound")--

    --плавание
    if data.amphibious then
        inst:AddComponent("embarker")
        inst.components.embarker.embark_speed = inst.components.locomotor.runspeed
        inst.components.embarker.antic = true

        inst.components.locomotor:SetAllowPlatformHopping(true)

        inst:AddComponent("amphibiouscreature")
        inst.components.amphibiouscreature:SetBanks(bank, bank.."_water")
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
    end

    inst:SetBrain(custombrain or brain)

    inst:AddComponent("entitytracker")

    inst:AddComponent("rus_hound")

    inst:AddComponent("follower")
    inst.components.follower.keepdeadleader = true

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = 0.1

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.HOUND_DAMAGE + (1 * inst.age))
    inst.components.combat:SetAttackPeriod(TUNING.HOUND_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetHurtSound(inst.sounds.hurt)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1000 + (50 * inst.age))
    inst.components.health:StartRegen(5 + (1 * inst.age), 0.2)
    inst.components.health.fire_damage_scale = 1 -- Default

    inst:AddComponent("inspectable")
    inst.components.inspectable.description = ("Сидеть, " .. inst.name)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    inst:WatchWorldState("startnight", OnStartNight)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.OnLoadPostPass = OnLoadPostPass

    inst:ListenForEvent("newcombattarget", OnNewTarget)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("onattackother", OnAttackOther)
    inst:ListenForEvent("death", OnKilled)

    return inst
end

local function fndefault()
    local inst = fncommon("hound", "hound_ocean", nil, nil, nil, {amphibious = true})

    if not TheWorld.ismastersim then
        return inst
    end

    MakeMediumFreezableCharacter(inst, "hound_body")
    MakeMediumBurnableCharacter(inst, "hound_body")

    return inst
end

return Prefab("common/monsters/rus_hound", fndefault, assets, prefabs)