--[[
Copyright (C) 2018-2020 Zarklord

This file is part of Gem Core.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details
The source codes does not come with any warranty including
the implied warranty of merchandise.
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]

--keep a separate list of all the custom techs for use with techname_bonus
--more effecient than itterating through all the techs... just go through the custom ones...
local CustomTechTree = {}

local TechTree = require("techtree")

local function __techindex(t, k)
    local val = rawget(t, k)
    return (type(val) == "number" and val >= 1 and val) or 0
end

local function __technewindex(t, k, v)
    rawset(t, k, ((type(v) == "number" and v >= 1 and v) or nil))
end

local function __technext(t, k)
    local tech = TechTree.AVAILABLE_TECH[k == nil and 1 or table.findarrayindex(TechTree.AVAILABLE_TECH, k)]
    return tech, t[tech]
end

local function __techpairs(t)
    return coroutine.wrap(function()
        for _, tech in rawipairs(TechTree.AVAILABLE_TECH) do
            coroutine.yield(tech, t[tech])
        end
    end)
end

local _Create = TechTree.Create
TechTree.Create = function(t)
    return setmetatable(t or {}, {__index = __techindex, __newindex = __technewindex, __next = __technext, __pairs = __techpairs})
end

--sadly because of when this is exectued we have to redo any and all call's to TechTree.Create
TECH.NONE = TechTree.Create()

for k, v in pairs(AllRecipes) do
    v.level = TechTree.Create(v.level)
end

for k, v in pairs(TUNING.PROTOTYPER_TREES) do
    v = TechTree.Create(v)
end

local function ConvertTechToPrototyperTree(tech_level)
    local validmachines = {}

    for k, v in pairs(TUNING.PROTOTYPER_TREES) do
        local canbuild = CanPrototypeRecipe(tech_level, v)
        if canbuild then
            table.insert(validmachines, {TREE = tostring(k), SCORE = 0})
        end
    end

    if #validmachines > 0 then
        if #validmachines == 1 then
            --There's only once machine is valid. Return that one.
            return validmachines[1].TREE
        end

        --There's more than one machine that gives the valid tech level! We have to find the "lowest" one (taking bonus into account).
        for k,v in pairs(validmachines) do
            for rk, recipe_level in pairs(adjusted_level) do
                local prototyper_level = TUNING.PROTOTYPER_TREES[v.TREE][rk]
                if recipe_level and prototyper_level and (recipe_level > 0 or prototyper_level > 0) then
                    if recipe_level == prototyper_level then
                        v.SCORE = v.SCORE + 1
                    elseif recipe_level < prototyper_level then
                        v.SCORE = v.SCORE - (prototyper_level - recipe_level)
                    end
                end
            end
        end

        table.sort(validmachines, function(a,b) return (a.SCORE) > (b.SCORE) end)

        return validmachines[1].TREE
    end
end

function CustomTechTree.AddTechHint(Tech, NewHint)
    print("CustomTechTree.AddTechHint is depreciated,")
    print("recipe hints must now be added by doing STRINGS.UI.CRAFTING[\"NEEDS\"..TreeName] = \""..NewHint.."\"")
    local PROTOTYPER_TREE = ConvertTechToPrototyperTree(Tech)
    if PROTOTYPER_TREE then
        print("Found prototyper_tree for tech, applying.")
        STRINGS.UI.CRAFTING["NEEDS"..PROTOTYPER_TREE] = NewHint
    else
        print("Unable to find prototyper_tree for Tech to add recipe hint:")
        print(NewHint)
    end
end

function CustomTechTree.AddPrototyperTree(TreeName, Tech)
    --adds a prototyper tree to TUNING.PROTOTYPER_TREES how it should be done
    --note: this is only for what the prototyper machine should output
    --creating a tech for recipes can be done by doing: TECH.TECHNAME = {TECHTYPE = 1, OTHERTECHTYPE = 3}
    TUNING.PROTOTYPER_TREES[TreeName] = TechTree.Create(Tech)
end

--I shouldn't need to do this, BUT if someone messes with the TUNING.PROTOTYPER_TREES, this must happen.
local Prototyper = require("components/prototyper")
local _GetTechTrees = Prototyper.GetTechTrees
function Prototyper:GetTechTrees(...)
    return TechTree.Create(_GetTechTrees(self, ...))
end

function CustomTechTree.AddNewTechType(techtype, is_tech_ingredient, no_bonus)
    --add tech to all tech list
    table.insert(TechTree.AVAILABLE_TECH, techtype)

    if is_tech_ingredient then
        TECH_INGREDIENT[techtype] = string.lower(techtype).."_material"
    end
    if not no_bonus then
        --add to this list for custom bonus proccessing
        table.insert(TechTree.BONUS_TECH, techtype)
    end
end

return CustomTechTree