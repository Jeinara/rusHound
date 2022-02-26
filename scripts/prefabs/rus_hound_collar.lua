local assets =
{
    Asset("ANIM", "anim/kokocollar.zip"),

    Asset("ATLAS", "images/inventoryimages/kokocollar.xml"),
    Asset("IMAGE", "images/inventoryimages/kokocollar.tex"),
}

local prefabs =
{
    "koko",
    "small_puff"
}

local function SpawnKoko(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst:Remove()
    SpawnPrefab("koko").Transform:SetPosition(x, y, z)
    SpawnPrefab("small_puff").Transform:SetPosition(x, y, z)
end

local function toground(inst)
    inst:DoTaskInTime(0.25, SpawnKoko)
end

local function fn(Sim)

    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst)

    anim:SetBank("kokocollar")
    anim:SetBuild("kokocollar")
    anim:PlayAnimation("idle")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "kokocollar"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/kokocollar.xml"

    inst:ListenForEvent("ondropped", toground)

    return inst
end

return  Prefab("common/inventory/rus_hound_collar", fn, assets, prefabs)