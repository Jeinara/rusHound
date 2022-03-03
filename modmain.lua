PrefabFiles = {
    "rus_hound_collar",
    "rus_hound",
    "hound_doghouse"
}

Assets = {

    Asset("IMAGE", "images/inventoryimages/kokocollar.tex"),
    Asset("ATLAS", "images/inventoryimages/kokocollar.xml"),

}

GLOBAL.STRINGS.NAMES.RUS_HOUND_COLLAR = "Ошейник"
GLOBAL.STRINGS.RECIPE_DESC.RUS_HOUND_COLLAR = "Каждой гончей по ошейнику"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RUS_HOUND_COLLAR = "Свистни - и твой верный друг появится"

GLOBAL.STRINGS.NAMES.HOUND_DOGHOUSE = "Будка"
GLOBAL.STRINGS.RECIPE_DESC.HOUND_DOGHOUSE = "Уютный домик для домашней гончей"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOUND_DOGHOUSE = "Как их там столько помещается?"

GLOBAL.STRINGS.NAMES.RUS_HOUND = "Русская Гончая"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.RUS_HOUND = "Верный друг"

TUNING.HOUND_NEAR_HOME_DIST = 10

---------------- Для управления будкой
------ Послать домой

local HOUND_SEND_HOME = AddAction("HOUND_SEND_HOME", "Послать гончую в будку", function(act)
    -- from gamescripts/actions
    if
        act.target ~= nil
                and act.target.components.follower ~= nil
                and act.target.components.follower:GetLeader() == act.doer
                and act.doer:HasTag("near_hound_doghouse") then
        local x, y, z = act.target.Transform:GetWorldPosition()
        local den = TheSim:FindEntities(x, y, z, TUNING.HOUND_NEAR_HOME_DIST, {"hound_doghouse"})[1]
        if den ~= nil then
            den.components.kitcoonden:AddKitcoon(act.target, act.doer)
            return true
        end
    end
    return false
end)
HOUND_SEND_HOME.priority = 10

AddComponentAction("SCENE", "rus_hound", function(inst, doer, actions, right)
    if right then
        if inst.replica.follower ~= nil and inst.replica.follower:GetLeader() == doer then
            local x, y, z = inst.Transform:GetWorldPosition()
            local den = TheSim:FindEntities(x, y, z, TUNING.HOUND_NEAR_HOME_DIST, {"hound_doghouse"})
            if doer ~= nil and doer:HasTag("near_hound_doghouse") and den ~= nil then
                table.insert(actions, GLOBAL.ACTIONS.HOUND_SEND_HOME)
            end
        end
    end
end)

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(HOUND_SEND_HOME, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(HOUND_SEND_HOME, "dolongaction"))


------ Забрать из дома

-----
local Ingredient = GLOBAL.Ingredient

AddRecipe("rus_hound_collar", {Ingredient("cutgrass", 1)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.NONE, nil, nil, nil, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )
AddRecipe("hound_doghouse", {Ingredient("petals", 1)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.NONE, nil, nil, nil, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )