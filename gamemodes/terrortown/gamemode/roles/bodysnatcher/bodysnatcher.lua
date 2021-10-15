AddCSLuaFile()

-------------
-- CONVARS --
-------------

CreateConVar("ttt_bodysnatcher_destroy_body", "0")
CreateConVar("ttt_bodysnatcher_show_role", "1")
local bodysnatchers_are_independent = CreateConVar("ttt_bodysnatchers_are_independent", "0")
local bodysnatcher_reveal_traitor = CreateConVar("ttt_bodysnatcher_reveal_traitor", "1", FCVAR_NONE, "Who the bodysnatcher is revealed to when they join the traitor team", 0, 2)
local bodysnatcher_reveal_innocent = CreateConVar("ttt_bodysnatcher_reveal_innocent", "1", FCVAR_NONE, "Who the bodysnatcher is revealed to when they join the innocent team", 0, 2)
local bodysnatcher_reveal_monster = CreateConVar("ttt_bodysnatcher_reveal_monster", "1", FCVAR_NONE, "Who the bodysnatcher is revealed to when they join the monster team", 0, 2)
local bodysnatcher_reveal_independent = CreateConVar("ttt_bodysnatcher_reveal_independent", "1", FCVAR_NONE, "Who the bodysnatcher is revealed to when they join the independent team", 0, 2)

hook.Add("TTTSyncGlobals", "Bodysnatcher_TTTSyncGlobals", function()
    SetGlobalBool("ttt_bodysnatchers_are_independent", bodysnatchers_are_independent:GetBool())
    SetGlobalInt("ttt_bodysnatcher_reveal_traitor", bodysnatcher_reveal_traitor:GetInt())
    SetGlobalInt("ttt_bodysnatcher_reveal_innocent", bodysnatcher_reveal_innocent:GetInt())
    SetGlobalInt("ttt_bodysnatcher_reveal_monster", bodysnatcher_reveal_monster:GetInt())
    SetGlobalInt("ttt_bodysnatcher_reveal_independent", bodysnatcher_reveal_independent:GetInt())
end)

----------------
-- ROLE STATE --
----------------

-- Disable tracking that this player was a bodysnatcher at the start of a new round or if their role changes again (e.g. if they go bodysnatcher -> innocent -> dead -> hypnotist res to traitor)
hook.Add("TTTPrepareRound", "Bodysnatcher_PrepareRound", function()
    for _, v in pairs(player.GetAll()) do
        v:SetNWBool("WasBodysnatcher", false)
    end
end)

hook.Add("TTTPlayerRoleChanged", "Bodysnatcher_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
    if oldRole ~= ROLE_BODYSNATCHER then
        ply:SetNWBool("WasBodysnatcher", false)
    end
end)

------------------
-- ROLE WEAPONS --
------------------

-- Only allow the bodysnatcher to pick up bodysnatcher-specific weapons
hook.Add("PlayerCanPickupWeapon", "Bodysnatcher_Weapons_PlayerCanPickupWeapon", function(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return false end

    if wep:GetClass() == "weapon_bod_bodysnatch" then
        return ply:IsBodysnatcher()
    end
end)