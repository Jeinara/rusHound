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

local WAKE_TO_FOLLOW_DISTANCE = 8
local SLEEP_NEAR_HOME_DISTANCE = 10
local SHARE_TARGET_DIST = 30
local HOME_TELEPORT_DIST = 30

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
            not TheWorld.state.isday
            and not (inst.components.combat and inst.components.combat.target)
            and not (inst.components.burnable and inst.components.burnable:IsBurning())
            and (not inst.components.homeseeker or inst:IsNear(inst.components.homeseeker.home, SLEEP_NEAR_HOME_DISTANCE))
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
    --сейчас ретаргет происходит только в случае, если нет лидера, и то только для установки лидера
    if inst.components.follower and inst.components.follower:GetLeader() == nil then
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

local function GetReturnPos(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rad = 2
    local angle = math.random() * 2 * PI
    return x + rad * math.cos(angle), y, z - rad * math.sin(angle)
end

local function DoReturn(inst)
    print("DoReturn", inst)
    if inst.components.homeseeker ~= nil and inst.components.homeseeker:HasHome() then
        if inst:HasTag("rus_hound") then
            if inst.components.homeseeker.home:IsAsleep() and not inst:IsNear(inst.components.homeseeker.home, HOME_TELEPORT_DIST) then
                inst.Physics:Teleport(GetReturnPos(inst.components.homeseeker.home))
            end
        elseif inst.components.homeseeker.home.components.childspawner ~= nil then
            inst.components.homeseeker.home.components.childspawner:GoHome(inst)
        end
    end
end

local function OnEntitySleep(inst)
    --print("OnEntitySleep", inst)
    if not TheWorld.state.isday then
        DoReturn(inst)
    end
end

local function OnStopDay(inst)
    --print("OnStopDay", inst)
    if inst:IsAsleep() then
        DoReturn(inst)
    end
end

local function OnSave(inst, data)
    data.ispet = inst:HasTag("rus_hound") or nil
    print("OnSave", inst, data.ispet)
end

local function OnLoad(inst, data)
    print("OnLoad", inst, data.ispet)
    if data ~= nil and data.ispet then
        inst:AddTag("rus_hound")
        if inst.sg ~= nil then
            inst.sg:GoToState("idle")
        end
    end
end

local function OnStartFollowing(inst, data)
    -- Наверное понадобится, когда буду прорабатывать дом
end

local function RestoreLeader(inst)
    inst.leadertask = nil
    local leader = inst.components.entitytracker:GetEntity("leader")
    if leader ~= nil and not leader.components.health:IsDead() then
        inst.components.follower:SetLeader(leader)
        leader:PushEvent("restoredfollower", { follower = inst })
    end
end

local function OnStopFollowing(inst)
    --inst.leadertask = inst:DoTaskInTime(.2, RestoreLeader)
end

--TODO нужна система уровней

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

    inst:AddTag("notraptrigger")--
    inst:AddTag("companion")--
    inst:AddTag("rus_hound")

    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("spawnfader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.sounds = sounds

    inst:AddComponent("named")--
    inst:AddComponent("named_replica")
    inst.components.named:SetName("Макс")

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

    inst:AddComponent("entitytracker") --what are you?

    inst:AddComponent("rus_hound")

    inst:AddComponent("follower")
    inst:ListenForEvent("startfollowing", OnStartFollowing)
    inst:ListenForEvent("stopfollowing", OnStopFollowing)
    inst.components.follower.keepdeadleader = true

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = 5

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.HOUND_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.HOUND_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, retargetfn)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetHurtSound(inst.sounds.hurt)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1000)
    inst.components.health:StartRegen(5, 0.2)
    inst.components.health.fire_damage_scale = 1 -- Default

    inst:AddComponent("inspectable")
    inst.components.inspectable.description = ("Сидеть, " .. inst.name)

    inst:AddComponent("sleeper")
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWakeUp)

    inst:WatchWorldState("stopday", OnStopDay)
    inst.OnEntitySleep = OnEntitySleep

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

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