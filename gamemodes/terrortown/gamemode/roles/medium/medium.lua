AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local pairs = pairs
local player = player
local table = table

local GetAllPlayers = player.GetAll
local CreateEntity = ents.Create

-------------
-- CONVARS --
-------------

local medium_spirit_color = CreateConVar("ttt_medium_spirit_color", "1")
local medium_spirit_vision = CreateConVar("ttt_medium_spirit_vision", "1")
local medium_dead_notify = CreateConVar("ttt_medium_dead_notify", "1")

hook.Add("TTTSyncGlobals", "Medium_TTTSyncGlobals", function()
    SetGlobalBool("ttt_medium_spirit_color", medium_spirit_color:GetBool())
    SetGlobalBool("ttt_medium_spirit_vision", medium_spirit_vision:GetBool())
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
    for _, v in pairs(GetAllPlayers()) do
        if v:IsMedium() then table.insert(mediums, v) end
    end
    if #mediums > 0 then
        local spirit = CreateEntity("npc_kleiner")
        spirit:SetPos(victim:GetPos())
        spirit:SetRenderMode(RENDERMODE_NONE)
        spirit:SetNotSolid(true)
        spirit:DrawShadow(false)
        spirit:SetNWBool("MediumSpirit", true)
        local col = Vector(1, 1, 1)
        if medium_spirit_color:GetBool() then
            col = victim:GetNWVector("PlayerColor", Vector(1, 1, 1))
        end
        spirit:SetNWVector("SpiritColor", col)
        spirit:Spawn()
        spirits[victim:SteamID64()] = spirit

        -- Let the player who died know there is a medium and this player isn't the only medium
        if medium_dead_notify:GetBool() and (#mediums > 1 or not victim:IsMedium()) then
            victim:PrintMessage(HUD_PRINTTALK, "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " senses your spirit.")
            victim:PrintMessage(HUD_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_MEDIUM] .. " senses your spirit.")
        end
    end
end)