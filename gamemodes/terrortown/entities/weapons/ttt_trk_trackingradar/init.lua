AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("TTT_TrackRadar")

local concommand = concommand
local ipairs = ipairs
local math = math
local net = net
local table = table

local FindEntsByClass = ents.FindByClass
local GetAllPlayers = player.GetAll
local MathRound = math.Round
local MathRand = math.Rand

-- should mirror client
local chargetime = 30

local function TrackRadarScan(ply, cmd, args)
    if not IsPlayer(ply) or ply:IsSpec() then return end

    if ply:HasEquipmentItem(EQUIP_TRK_TRACKRADAR) then
        if ply.trackradar_charge > CurTime() then
            LANG.Msg(ply, "trackradar_charging")
            return
        end

        ply.trackradar_charge = CurTime() + chargetime

        local scan_ents = GetAllPlayers()
        table.Add(scan_ents, FindEntsByClass("ttt_decoy"))

        local targets = {}
        for _, p in ipairs(scan_ents) do
            if ply == p or not IsValid(p) then continue end

            local pos = p:LocalToWorld(p:OBBCenter())
            local col
            if IsPlayer(p) then
                col = p:GetNWVector("PlayerColor", Vector(1, 1, 1))
                if not p:Alive() or p:IsSpec() then
                    local rag = p.server_ragdoll or p:GetRagdollEntity()
                    if IsValid(rag) then
                        pos = rag:GetPos()
                    else
                        continue
                    end
                end
            -- Generate a random color for decoys
            else
                local color = HSLToColor(MathRand(0, 360), MathRand(0.5, 1), MathRand(0.25, 0.75))
                col = Vector(color.r / 255, color.g / 255, color.b / 255)
            end

            -- Round off, easier to send and inaccuracy does not matter
            pos.x = MathRound(pos.x)
            pos.y = MathRound(pos.y)
            pos.z = MathRound(pos.z)

            table.insert(targets, { pos = pos, col = col })
        end

        net.Start("TTT_TrackRadar")
        net.WriteUInt(#targets, 8)
        for _, tgt in ipairs(targets) do
            net.WriteInt(tgt.pos.x, 15)
            net.WriteInt(tgt.pos.y, 15)
            net.WriteInt(tgt.pos.z, 15)

            net.WriteFloat(tgt.col.x)
            net.WriteFloat(tgt.col.y)
            net.WriteFloat(tgt.col.z)
        end
        net.Send(ply)

    -- Don't tell the role with a delayed shop that they don't have radar when they buy it
    -- Everyone else should get yelled at though
    elseif not ply:ShouldDelayShopPurchase() then
        LANG.Msg(ply, "trackradar_not_owned")
    end
end
concommand.Add("ttt_trackradar_scan", TrackRadarScan)

local function ResetTrackRadarState(ply, transition)
    ply.trackradar_charge = 0
end
hook.Add("PlayerSpawn", "TrackRadar_PlayerSpawn", ResetTrackRadarState)
hook.Add("PlayerInitialSpawn", "TrackRadar_PlayerInitialSpawn", ResetTrackRadarState)