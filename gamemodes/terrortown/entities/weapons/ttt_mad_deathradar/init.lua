AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("TTT_DeathRadar")

local concommand = concommand
local ipairs = ipairs
local math = math
local net = net
local table = table

local FindEntsByClass = ents.FindByClass
local MathRound = math.Round

-- should mirror client
local chargetime = 30

local function DeathRadarScan(ply, cmd, args)
    if not IsPlayer(ply) or ply:IsSpec() then return end

    if ply:HasEquipmentItem(EQUIP_MAD_DEATHRADAR) then
        if ply.deathradar_charge > CurTime() then
            LANG.Msg(ply, "deathradar_charging")
            return
        end

        ply.deathradar_charge = CurTime() + chargetime

        local targets = {}
        for _, rag in ipairs(FindEntsByClass("prop_ragdoll")) do
            local p = CORPSE.GetPlayer(rag)
            if IsPlayer(p) then
                local pos = rag:LocalToWorld(rag:OBBCenter())

                -- Round off, easier to send and inaccuracy does not matter
                pos.x = MathRound(pos.x)
                pos.y = MathRound(pos.y)
                pos.z = MathRound(pos.z)

                table.insert(targets, { pos = pos })
            end
        end

        net.Start("TTT_DeathRadar")
        net.WriteUInt(#targets, 8)
        for _, tgt in ipairs(targets) do
            net.WriteInt(tgt.pos.x, 32)
            net.WriteInt(tgt.pos.y, 32)
            net.WriteInt(tgt.pos.z, 32)
        end
        net.Send(ply)

    -- Don't tell the role with a delayed shop that they don't have radar when they buy it
    -- Everyone else should get yelled at though
    elseif not ply:ShouldDelayShopPurchase() then
        LANG.Msg(ply, "deathradar_not_owned")
    end
end
concommand.Add("ttt_deathradar_scan", DeathRadarScan)

local function ResetDeathRadarState(ply, transition)
    ply.deathradar_charge = 0
end
hook.Add("PlayerSpawn", "DeathRadar_PlayerSpawn", ResetDeathRadarState)
hook.Add("PlayerInitialSpawn", "DeathRadar_PlayerInitialSpawn", ResetDeathRadarState)