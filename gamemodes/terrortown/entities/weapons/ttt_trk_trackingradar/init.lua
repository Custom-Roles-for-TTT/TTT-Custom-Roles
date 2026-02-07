AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("TTT_TrackRadar")

local concommand = concommand
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local player = player
local table = table

local CallHook = hook.Call
local MathRound = math.Round
local PlayerIterator = player.Iterator
local TableInsert = table.insert

-- should mirror client
local chargetime = 30

local function TrackRadarScan(ply, cmd, args)
    if not IsValid(ply) or ply:IsSpec() then return end

    if not ply:HasEquipmentItem(EQUIP_TRK_TRACKRADAR) then
        -- Don't tell the role with a delayed shop that they don't have radar when they buy it
        -- Everyone else should get yelled at though
        if not ply:ShouldDelayShopPurchase() then
            LANG.Msg(ply, "trackradar_not_owned")
        end
        return
    end

    if ply.trackradar_charge > CurTime() then
        LANG.Msg(ply, "trackradar_charging")
        return
    end

    if ply:IsTracker() and ply:IsRoleAbilityDisabled() then return end

    ply.trackradar_charge = CurTime() + chargetime

    local targets = {}
    for _, p in PlayerIterator() do
        if ply == p or not IsValid(p) then continue end

        local pos = p:LocalToWorld(p:OBBCenter())
        local col = p:GetNWVector("PlayerColor", Vector(1, 1, 1))

        -- Use ragdoll location for dead/spectator players, if they have one
        if not p:Alive() or p:IsSpec() then
            local rag = p.server_ragdoll or p:GetRagdollEntity()
            if IsValid(rag) then
                pos = rag:GetPos()
            else
                continue
            end
        end

        TableInsert(targets, {pos=pos, col=col, ent=p})
    end

    CallHook("TTTTrackRadarScan", nil, ply, targets)

    net.Start("TTT_TrackRadar")
        net.WriteUInt(#targets, 8)
        for _, tgt in ipairs(targets) do
            -- Round off, easier to send and inaccuracy does not matter
            net.WriteInt(MathRound(tgt.pos.x), 15)
            net.WriteInt(MathRound(tgt.pos.y), 15)
            net.WriteInt(MathRound(tgt.pos.z), 15)

            net.WriteFloat(tgt.col.x)
            net.WriteFloat(tgt.col.y)
            net.WriteFloat(tgt.col.z)
        end
    net.Send(ply)
end
concommand.Add("ttt_trackradar_scan", TrackRadarScan)

local function ResetTrackRadarState(ply, transition)
    ply.trackradar_charge = 0
end
hook.Add("PlayerSpawn", "TrackRadar_PlayerSpawn", ResetTrackRadarState)
hook.Add("PlayerInitialSpawn", "TrackRadar_PlayerInitialSpawn", ResetTrackRadarState)