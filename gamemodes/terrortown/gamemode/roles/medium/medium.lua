AddCSLuaFile()

-------------
-- CONVARS --
-------------

CreateConVar("ttt_medium_spirit_color", "1")

hook.Add("TTTSyncGlobals", "Medium_TTTSyncGlobals", function()
    SetGlobalBool("ttt_medium_spirit_color", GetConVar("ttt_medium_spirit_color"):GetBool())
end)

-------------------
-- ROLE FEATURES --
-------------------

local spirits = {}
hook.Add("TTTPrepareRound", "Medium_Spirits_TTTPrepareRound", function()
    for _, ent in pairs(spirits) do
        SafeRemoveEntity(ent)
    end
    table.Empty(spirits)
end)

hook.Add("PlayerSpawn", "Medium_Spirits_PlayerSpawn", function(ply)
    local sid = ply:SteamID64()
    SafeRemoveEntity(spirits[sid])
    spirits[sid] = nil
end)

hook.Add("PlayerDisconnected", "Medium_Spirits_PlayerDisconnected", function(ply)
    local sid = ply:SteamID64()
    SafeRemoveEntity(spirits[sid])
    spirits[sid] = nil
end)

hook.Add("FinishMove", "Medium_Spirits_FinishMove", function(ply, mv)
    if not IsValid(ply) or not ply:IsSpec() then return end

    local spirit = spirits[ply:SteamID64()]
    if not IsValid(spirit) then return end

    spirit:SetPos(ply:GetPos())

    local show = ply:GetObserverMode() == OBS_MODE_ROAMING
    spirit:SetNWBool("MediumSpirit", show)
end)

hook.Add("PlayerDeath", "Medium_Spirits_PlayerDeath", function(victim, infl, attacker)
    -- Create spirit for the medium
    local mediums = {}
    for _, v in pairs(player.GetAll()) do
        if v:IsMedium() then table.insert(mediums, v) end
    end
    if #mediums > 0 then
        local spirit = ents.Create("npc_kleiner")
        spirit:SetPos(victim:GetPos())
        spirit:SetRenderMode(RENDERMODE_NONE)
        spirit:SetNotSolid(true)
        spirit:DrawShadow(false)
        spirit:SetNWBool("MediumSpirit", true)
        local col = Vector(1, 1, 1)
        if GetConVar("ttt_medium_spirit_color"):GetBool() then
            col = victim:GetNWVector("PlayerColor", Vector(1, 1, 1))
        end
        spirit:SetNWVector("SpiritColor", col)
        spirit:Spawn()
        spirits[victim:SteamID64()] = spirit
    end
end)