local hook = hook
local net = net
local resource = resource
local string = string
local util = util

local AddHook = hook.Add
local StringLower = string.lower
local StringSub = string.sub

-- Hit Markers
-- Creator: Exho

util.AddNetworkString("TTT_DrawHitMarker")
util.AddNetworkString("TTT_CreateBlood")
util.AddNetworkString("TTT_OpenMixer")

resource.AddFile("sound/hitmarkers/mlghit.wav")
AddHook("EntityTakeDamage", "HitmarkerDetector", function(ent, dmginfo)
    local att = dmginfo:GetAttacker()
    local pos = dmginfo:GetDamagePosition()

    -- Only players and NPC targets show hitmarkers
    if IsPlayer(att) and att ~= ent and (ent:IsPlayer() or ent:IsNPC()) then
        local drawCrit = ent:GetNWBool("LastHitCrit", false) and not GetConVar("ttt_disable_headshots"):GetBool()

        net.Start("TTT_DrawHitMarker")
        net.WriteBool(drawCrit)
        net.Send(att) -- Send the message to the attacker

        net.Start("TTT_CreateBlood")
        net.WriteVector(pos)
        net.Broadcast()
    end
end)

AddHook("ScalePlayerDamage", "HitmarkerPlayerCritDetector", function(ply, hitgroup, dmginfo)
    ply:SetNWBool("LastHitCrit", hitgroup == HITGROUP_HEAD)
end)

AddHook("ScaleNPCDamage", "HitmarkerNPCCritDetector", function(npc, hitgroup, dmginfo)
    npc:SetNWBool("LastHitCrit", hitgroup == HITGROUP_HEAD)
end)

AddHook("PlayerSay", "ColorMixerOpen", function(ply, text, team_only)
    text = StringLower(text)
    if (StringSub(text, 1, 12) == "!hmcritcolor") then
        net.Start("TTT_OpenMixer")
        net.WriteBool(true)
        net.Send(ply)
        return false
    elseif (StringSub(text, 1, 8) == "!hmcolor") then
        net.Start("TTT_OpenMixer")
        net.WriteBool(false)
        net.Send(ply)
        return false
    end
end)