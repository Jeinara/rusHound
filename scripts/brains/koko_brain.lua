require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/runaway"


local MAX_CHASE_TIME = 10
local WANDER_DIST = 4

local RUN_AWAY_DIST = 6
local STOP_RUN_AWAY_DIST = 12
local START_FACE_DIST = 5
local KEEP_FACE_DIST = 8
local MIN_FOLLOW_DIST = 1
local MAX_FOLLOW_DIST = 8
local MAX_WANDER_DIST = 6
local TARGET_FOLLOW_DIST = 4

local function GetFaceTargetFn(inst)
    return inst.components.follower.leader
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.follower.leader == target
end

local function ShouldRunAway(guy)
    return guy:HasTag("epic") and not guy:HasTag("notarget")
end

local koko_brain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function koko_brain:OnStart()
    


    local root = PriorityNode(
    {
        IfNode(function() return self.inst.partrolactive end, false,
            Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation(self.inst.patroltracker) end, MAX_WANDER_DIST)),
        Follow(self.inst, function()return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
        RunAway(self.inst, ShouldRunAway, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        Wander(self.inst)
    }, .25)
    
    self.bt = BT(self.inst, root)
end

return koko_brain