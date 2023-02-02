AddCSLuaFile()

local hook = hook
local timer = timer

local GetAllPlayers = player.GetAll

util.AddNetworkString("TTT_UpdateShadowWins")

-------------
-- CONVARS --
-------------

local start_timer = CreateConVar("ttt_shadow_start_timer", "30", FCVAR_NONE, "How much time (in seconds) the shadow has to find their target at the start of the round", 1, 90)
local buffer_timer = CreateConVar("ttt_shadow_buffer_timer", "7", FCVAR_NONE, "How much time (in seconds) the shadow can stay of their target's radius", 1, 30)
local alive_radius = CreateConVar("ttt_shadow_alive_radius", "8", FCVAR_NONE, "The radius (in meters) from the living target that the shadow has to stay within", 1, 15)
local dead_radius = CreateConVar("ttt_shadow_dead_radius", "3", FCVAR_NONE, "The radius (in meters) from the death target that the shadow has to stay within", 1, 15)

hook.Add("TTTSyncGlobals", "Shadow_TTTSyncGlobals", function()
    SetGlobalInt("ttt_shadow_start_timer", start_timer:GetInt())
    SetGlobalInt("ttt_shadow_buffer_timer", buffer_timer:GetInt())
    SetGlobalFloat("ttt_shadow_alive_radius", alive_radius:GetFloat() * 52.49)
    SetGlobalFloat("ttt_shadow_dead_radius", dead_radius:GetFloat() * 52.49)
end)

-----------------------
-- TARGET ASSIGNMENT --
-----------------------

ROLE_ON_ROLE_ASSIGNED[ROLE_SHADOW] = function(ply)
    local closestTarget = nil
    local closestDistance = -1
    for _, p in pairs(GetAllPlayers()) do
        if p:Alive() and not p:IsSpec() and p ~= ply then
            local distance = ply:GetPos():Distance(p:GetPos())
            if closestDistance == -1 or distance < closestDistance then
                closestTarget = p
                closestDistance = distance
            end
        end
    end
    if closestTarget ~= nil then
        ply:SetNWString("ShadowTarget", closestTarget:SteamID64() or "")
        ply:PrintMessage(HUD_PRINTTALK, "Your target is " .. closestTarget:Nick() .. ".")
        ply:PrintMessage(HUD_PRINTCENTER, "Your target is " .. closestTarget:Nick() .. ".")
        ply:SetNWFloat("ShadowTimer", CurTime() + GetConVar("ttt_shadow_start_timer"):GetInt())
    end
end

-------------------
-- ROLE FEATURES --
-------------------

hook.Add("TTTBeginRound", "Shadow_TTTBeginRound", function()
    timer.Create("TTTShadowTimer", 0.1, 0, function()
        for _, v in pairs(GetAllPlayers()) do
            if v:IsActiveShadow() then
                local t = v:GetNWFloat("ShadowTimer", -1)
                if t > 0 and CurTime() > t then
                    v:Kill()
                    v:PrintMessage(HUD_PRINTCENTER, "You didn't stay close to your target!")
                    v:PrintMessage(HUD_PRINTTALK, "You didn't stay close to your target!")
                    v:SetNWBool("ShadowActive", false)
                    v:SetNWFloat("ShadowTimer", -1)
                else
                    local target = player.GetBySteamID64(v:GetNWString("ShadowTarget", ""))
                    local ent = target
                    local radius = alive_radius:GetFloat() * 52.49
                    if not target:IsActive() then
                        ent = target.server_ragdoll or target:GetRagdollEntity()
                        radius = dead_radius:GetFloat() * 52.49
                    end

                    if IsValid(ent) then
                        if v:GetPos():Distance(ent:GetPos()) <= radius then
                            if not v:GetNWBool("ShadowActive", false) then
                                v:SetNWBool("ShadowActive", true)
                            end
                            v:SetNWFloat("ShadowTimer", -1)
                        elseif v:GetNWFloat("ShadowTimer", -1) < 0 then
                            v:SetNWFloat("ShadowTimer", CurTime() + buffer_timer:GetInt())
                        end
                    end
                end
            end
        end
    end)
end)

hook.Add("PlayerSpawn", "Shadow_PlayerSpawn", function(player, transition)
    if player:IsShadow() then
        player:SetNWFloat("ShadowTimer", CurTime() + start_timer:GetInt())
    end
end)

hook.Add("PlayerDeath", "Shadow_KillCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not attacker:IsShadow() then return end

    if victim:SteamID64() == attacker:GetNWString("ShadowTarget", "") then
        attacker:Kill()
        attacker:PrintMessage(HUD_PRINTCENTER, "You killed your target!")
        attacker:PrintMessage(HUD_PRINTTALK, "You killed your target!")
        attacker:SetNWBool("ShadowActive", false)
        attacker:SetNWString("ShadowTarget", "")
        attacker:SetNWFloat("ShadowTimer", -1)
    end
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTWinCheckComplete", "Shadow_TTTWinCheckComplete", function(win_type)
    if win_type == WIN_NONE then return end
    if not player.IsRoleLiving(ROLE_SHADOW) then return end

    net.Start("TTT_UpdateShadowWins")
    net.WriteBool(true)
    net.Broadcast()
end)

-------------
-- CLEANUP --
-------------

hook.Add("TTTPrepareRound", "Shadow_PrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWBool("ShadowActive", false)
        v:SetNWString("ShadowTarget", "")
        v:SetNWFloat("ShadowTimer", -1)
    end
    timer.Remove("TTTShadowTimer")
end)

hook.Add("TTTPlayerRoleChanged", "Shadow_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole == ROLE_SHADOW and oldRole ~= newRole then
        ply:SetNWBool("ShadowActive", false)
        ply:SetNWString("ShadowTarget", "")
        ply:SetNWFloat("ShadowTimer", -1)
    end
end)

