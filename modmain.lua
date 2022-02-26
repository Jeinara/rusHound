PrefabFiles = {
    "rus_hound_collar"
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

GLOBAL.STRINGS.NAMES.RUS_HOUND_COLLAR = "Collar"
STRINGS.RECIPE_DESC.RUS_HOUND_COLLAR = "Call forth the hounds!"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.RUS_HOUND_COLLAR= "A portal to a world unknown."

-- Custom config options --

-- It's \n to start a new line in strings.

AddRecipe("rus_hound_collar", {Ingredient("cutgrass", 1)}, GLOBAL.RECIPETABS.MAGIC, GLOBAL.TECH.NONE, nil, nil, nil, 1, nil, "images/inventoryimages/kokocollar.xml", "kokocollar.tex" )
