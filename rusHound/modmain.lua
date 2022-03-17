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

----------------

TUNING.HOUND_NEAR_HOME_DIST = 10

local cooking = require("cooking")

---------------- Для управления будкой
------ Послать домой



local HOUND_SEND_HOME = AddAction("HOUND_SEND_HOME", "Дать команду \"Домой\"", function(act)
    for _,recipes in pairs(cooking.recipes) do
        for foodName,recipe in pairs(recipes) do
            if (foodName == "gorge_fishpie" or foodName == "myth_food_ztf") then
                print("________" .. foodName)
                local item_tex = foodName..'.tex'
                local atlas = GLOBAL.GetInventoryItemAtlas(item_tex)
                local prefabData = GLOBAL.Prefabs[foodName]
                print(GLOBAL.resolvefilepath(atlas))
                print(atlas)
                if prefabData then
                    -- first run we find assets with exact match of prefab name
                    print("atlas", not atlas)
                    print("theSim", not GLOBAL.TheSim:AtlasContains(atlas, item_tex))
                    if not atlas or not GLOBAL.TheSim:AtlasContains(atlas, item_tex) then
                        print("both")
                        for _, asset in ipairs(prefabData.assets) do
                            if asset.type == "INV_IMAGE" then
                                print("INV_IMAGE")
                                item_tex = asset.file..'.tex'
                                atlas = GLOBAL.GetInventoryItemAtlas(item_tex)
                            elseif asset.type == "ATLAS" then
                                print("ATLAS")
                                atlas = asset.file
                            end
                        end
                    end
                end
                print(GLOBAL.resolvefilepath(atlas))
                for k, v in pairs(recipe) do
                    print(k, v)
                end
            end
        end
    end
    if
        act.target ~= nil
        and act.target.components.follower ~= nil
        and act.target.components.follower:GetLeader() == act.doer
        and act.doer:HasTag("near_hound_doghouse")
    then
        local x, y, z = act.target.Transform:GetWorldPosition()
        local den = GLOBAL.TheSim:FindEntities(x, y, z, TUNING.HOUND_NEAR_HOME_DIST, {"hound_doghouse"})[1]
        if den ~= nil then
            den.components.kitcoonden:AddKitcoon(act.target, act.doer)
            return true
        end
    end
    return false
end)
HOUND_SEND_HOME.priority = 10

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(HOUND_SEND_HOME, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(HOUND_SEND_HOME, "doshortaction"))


------ Забрать из дома

local HOUND_GET_BACK = AddAction("HOUND_GET_BACK", "Дать команду \"Ко мне\"", function(act)
    if
        act.target ~= nil
        and act.target.components.follower ~= nil
        and act.target.components.follower:GetLeader() == nil
        and act.doer:HasTag("near_hound_doghouse")
    then
        local x, y, z = act.target.Transform:GetWorldPosition()
        local den = GLOBAL.TheSim:FindEntities(x, y, z, TUNING.HOUND_NEAR_HOME_DIST, {"hound_doghouse"})[1]
        if den ~= nil then
            den.components.kitcoonden:RemoveKitcoon(act.target, act.doer)
            return true
        end
    end
    return false
end)
HOUND_GET_BACK.priority = 10

AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(HOUND_GET_BACK, "doshortaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(HOUND_GET_BACK, "doshortaction"))

-----
AddComponentAction("SCENE", "rus_hound", function(inst, doer, actions, right)
    if right then
        local x, y, z = inst.Transform:GetWorldPosition()
        local den = GLOBAL.TheSim:FindEntities(x, y, z, TUNING.HOUND_NEAR_HOME_DIST, {"hound_doghouse"})[1]

        if doer ~= nil and doer:HasTag("near_hound_doghouse") and den ~= nil then
            print(den)
            if (den:HasTag("hound_doghouse")) then
                if not inst:HasTag("sitting_home") then
                    if inst.replica.follower ~= nil and inst.replica.follower:GetLeader() == doer then
                        table.insert(actions, GLOBAL.ACTIONS.HOUND_SEND_HOME)
                    end
                else
                    if inst.replica.follower ~= nil and inst.replica.follower:GetLeader() == nil then
                        table.insert(actions, GLOBAL.ACTIONS.HOUND_GET_BACK)
                    end
                end
            end
        end
    end
end)
----------------
local Ingredient = GLOBAL.Ingredient

AddRecipeTab("DOGHOUSE", 100, "images/inventoryimages/kokocollar.xml", "kokocollar.tex", nil, true)
GLOBAL.STRINGS.TABS.DOGHOUSE = "Будка"

local custom_tech_tree = require("customtechtree")

custom_tech_tree.AddNewTechType("HOUND_DOGHOUSE_TECH")
GLOBAL.TECH.HOUND_DOGHOUSE_TECH_ONE = {HOUND_DOGHOUSE_TECH = 1}

custom_tech_tree.AddPrototyperTree("HOUND_DOGHOUSE_TREE", {HOUND_DOGHOUSE_TECH = 1})

-------------------
---- Продовые рецепты
--AddRecipe("rus_hound_collar", {Ingredient("glommerfuel", 1), Ingredient("nightmarefuel", 1), Ingredient("monstermeat", 1)}, GLOBAL.CUSTOM_RECIPETABS.DOGHOUSE, GLOBAL.TECH.HOUND_DOGHOUSE_TECH_ONE, nil, nil, true, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )
--AddRecipe("hound_doghouse", {Ingredient("log", 2), Ingredient("nightmarefuel", 5), Ingredient("transistor", 1)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.NONE, nil, nil, nil, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )
----- Тестовые рецепты
AddRecipe("rus_hound_collar", {Ingredient("petals", 1)}, GLOBAL.CUSTOM_RECIPETABS.DOGHOUSE, GLOBAL.TECH.HOUND_DOGHOUSE_TECH_ONE, nil, nil, true, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )
AddRecipe("hound_doghouse", {Ingredient("cutgrass", 1)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.NONE, nil, nil, nil, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )
------------------------

GLOBAL.KnownModIndex:IsModEnabled("workshop-1991746508")