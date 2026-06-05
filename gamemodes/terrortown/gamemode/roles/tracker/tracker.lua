AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local net = net
local player = player
local table = table

local AddHook = hook.Add
local RemoveHook = hook.Remove
local PlayerIterator = player.Iterator

-------------
-- CONVARS --
-------------

local tracker_footstep_time = GetConVar("ttt_tracker_footstep_time")
local tracker_footstep_color = GetConVar("ttt_tracker_footstep_color")

-------------------
-- ROLE FEATURES --
-------------------

local function Tracker_PlayerFootstep(ply, pos, foot, sound, volume, rf)
    if not IsValid(ply) or ply:IsSpec() or not ply:Alive() then return true end
    if ply:WaterLevel() ~= 0 then return end
    -- Trackers don't see their own footsteps
    if ply:IsTracker() then return end

    local footstep_time = tracker_footstep_time:GetInt()
    if footstep_time <= 0 then return end

    local tab = {}
    for k, p in PlayerIterator() do
        if p:IsActiveTracker() and not p:IsRoleAbilityDisabled() then
            table.insert(tab, p)
        end
    end

    -- Nobody to send to
    if #tab == 0 then return end

    net.Start("TTT_PlayerFootstep")
        net.WritePlayer(ply)
        net.WriteVector(pos)
        net.WriteAngle(ply:GetAimVector():Angle())
        net.WriteBit(foot)
        local col = Vector(1, 1, 1)
        if tracker_footstep_color:GetBool() then
            col = ply:GetNWVector("PlayerColor", Vector(1, 1, 1))
        end
        net.WriteTable(Color(col.x * 255, col.y * 255, col.z * 255))
        net.WriteUInt(footstep_time, 8)
        net.WriteFloat(1) -- Scale
    net.Send(tab)
end

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_TRACKER] = function()
    AddHook("PlayerFootstep", "Tracker_PlayerFootstep", Tracker_PlayerFootstep)
end

ROLE_UNREGISTER_HOOKS[ROLE_TRACKER] = function()
    RemoveHook("PlayerFootstep", "Tracker_PlayerFootstep")
end