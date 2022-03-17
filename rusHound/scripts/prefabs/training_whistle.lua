local assets =
{
    Asset("ANIM", "anim/kokocollar.zip"),

    Asset("ATLAS", "images/inventoryimages/kokocollar.xml"),
    Asset("IMAGE", "images/inventoryimages/kokocollar.tex"),
}

local prefabs =
{
    "small_puff"
}

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

    --inst:ListenForEvent("ondropped", toground)

    return inst
end

return Prefab("common/inventory/training_whistle", fn, assets, prefabs)