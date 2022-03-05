local assets =
{
    Asset("ANIM", "anim/kitcoonden.zip"),
}

local prefabs =
{
    "rus_hound_collar"
}

local function onhammered(inst)
    local ipos = inst:GetPosition()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(ipos:Get())
    fx:SetMaterial("wood")

    inst.components.lootdropper:DropLoot(ipos)

    inst:Remove()
end

local function onhit(inst)
    inst.AnimState:PlayAnimation("hit", false)
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("yotc_2022_2/common/den/place")

    local x, y, z = inst.Transform:GetWorldPosition()
    local rus_hounds = TheSim:FindEntities(x, y, z, TUNING.HOUND_NEAR_HOME_DIST, {"rus_hound"})
    for _, rus_hound in ipairs(rus_hounds) do
        if rus_hound.components.follower.leader == nil then
            inst.components.kitcoonden:AddKitcoon(rus_hound)
        end
    end

end

local function OnPlayerApproached(inst, player)
    player:AddTag("near_hound_doghouse")
end

local function OnPlayerLeft(inst, player)
    player:RemoveTag("near_hound_doghouse")
end

local function onremoved(inst)
    for player, v in pairs(inst.components.playerprox.closeplayers) do
        if player:IsValid() then
            OnPlayerLeft(inst, player)
        end
    end
end

local function OnAddHound(inst, rus_hound)
    rus_hound.components.follower:SetLeader(nil)
    rus_hound.components.entitytracker:TrackEntity("home", inst)
    rus_hound:AddTag("sitting_home")
    if rus_hound.components.sleeper ~= nil then
        rus_hound.components.sleeper:WakeUp()
    end
end

local function OnRemoveHound(inst, rus_hound)
    if rus_hound:IsValid() then
        rus_hound.components.entitytracker:ForgetEntity("home", inst)
        rus_hound:RemoveTag("sitting_home")
    end
end

local function OnBurnt(inst)
    DefaultBurntStructureFn(inst)

    inst:RemoveTag("hound_doghouse")

    inst:DoTaskInTime(0, function()
        inst.components.kitcoonden:RemoveAllKitcoons()
    end)
end
-------------------------

local function OnSave(inst, data)
    if inst:HasTag("burnt") or (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    print(inst.components.kitcoonden:GetDebugString())
    if data ~= nil then
        if data.burnt and not inst:HasTag("burnt") then
            OnBurnt(inst)
        end
    end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeSmallObstaclePhysics(inst, .5)

    inst.MiniMapEntity:SetIcon("kitcoonden.png")

    inst.AnimState:SetBank("kitcoonden")
    inst.AnimState:SetBuild("kitcoonden")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("structure")
    inst:AddTag("hound_doghouse")

    --inst:AddTag("prototyper")

    MakeSnowCoveredPristine(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    ---------------------
    inst:AddComponent("lootdropper")

    ---------------------
    MakeMediumBurnable(inst)
    inst.components.burnable:SetOnBurntFn(OnBurnt)

    MakeSmallPropagator(inst)

    ---------------------
    inst:AddComponent("inspectable")
    inst.components.inspectable.description = ("Собачья будка")

    ---------------------
    inst:AddComponent("kitcoonden")
    inst.components.kitcoonden.OnAddKitcoon = OnAddHound
    inst.components.kitcoonden.OnRemoveKitcoon = OnRemoveHound

    ---------------------
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetTargetMode(inst.components.playerprox.TargetModes.AllPlayers)
    inst.components.playerprox:SetDist(TUNING.HOUND_NEAR_HOME_DIST - 4,TUNING.HOUND_NEAR_HOME_DIST - 1)
    inst.components.playerprox:SetOnPlayerNear(OnPlayerApproached)
    inst.components.playerprox:SetOnPlayerFar(OnPlayerLeft)
    inst.components.playerprox:SetPlayerAliveMode(inst.components.playerprox.AliveModes.AliveOnly)

    ---------------------
    --inst:AddComponent("prototyper")
    --inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.HOUND_HOUSE
    ---------------------

    MakeSnowCovered(inst)

    ---------------------
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    ---------------------
    MakeHauntableWork(inst)

    ---------------------
    inst:ListenForEvent("onbuilt", onbuilt)
    inst:ListenForEvent("onremove", onremoved)

    return inst
end

return Prefab("hound_doghouse", fn, assets, prefabs),
MakePlacer("hound_doghouse_placer", "hound_doghouse", "hound_doghouse", "placer")
