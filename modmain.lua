PrefabFiles = {
    "rus_hound_collar",
    "rus_hound",
    "hound_doghouse"
}

Assets = {

    Asset("IMAGE", "images/inventoryimages/kokocollar.tex"),
    Asset("ATLAS", "images/inventoryimages/kokocollar.xml"),

}

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS
local RECIPETABS = GLOBAL.RECIPETABS
local Recipe = GLOBAL.Recipe
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH

GLOBAL.STRINGS.NAMES.RUS_HOUND_COLLAR = "Ошейник"
STRINGS.RECIPE_DESC.RUS_HOUND_COLLAR = "Каждой гончей по ошейнику"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.RUS_HOUND_COLLAR = "Свистни - и твой верный друг появится"

GLOBAL.STRINGS.NAMES.HOUND_DOGHOUSE = "Будка"
STRINGS.RECIPE_DESC.HOUND_DOGHOUSE = "Уютный домик для домашней гончей"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HOUND_DOGHOUSE = "Как их там столько помещается?"

GLOBAL.STRINGS.NAMES.RUS_HOUND = "Русская Гончая"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.RUS_HOUND = "Верный друг"


-- Custom config options --

-- It's \n to start a new line in strings.

AddRecipe("rus_hound_collar", {Ingredient("cutgrass", 1)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.NONE, nil, nil, nil, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )
AddRecipe("hound_doghouse", {Ingredient("petals", 1)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.NONE, nil, nil, nil, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )