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

local function GetDenPos(inst)
    local den = inst.components.entitytracker:GetEntity("home")
    return den ~= nil and den:GetPosition() or nil
end

local rus_hound_brain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function rus_hound_brain:OnStart()

    local root = PriorityNode(
    {
        Follow(self.inst, function()return self.inst.components.follower.leader end, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME),
        RunAway(self.inst, ShouldRunAway, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
        FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
        IfNode(function() return self.inst.components.entitytracker:GetEntity("home") ~= nil end, true,
                Wander(self.inst, function() return GetDenPos(self.inst) end, MAX_WANDER_DIST,
                        {minwalktime = 2, randwalktime = 3, minwaittime = 2, randwaittime = 4 })),
        Wander(self.inst)
    }, .25)
    self.bt = BT(self.inst, root)
end

return rus_hound_brain