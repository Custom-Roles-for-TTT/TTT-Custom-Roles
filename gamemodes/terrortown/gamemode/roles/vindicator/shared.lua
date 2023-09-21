AddCSLuaFile()

VINDICATOR_ANNOUNCE_NONE = 0
VINDICATOR_ANNOUNCE_TARGET = 1
VINDICATOR_ANNOUNCE_ALL = 2

-------------------
-- ROLE FEATURES --
-------------------

ROLE_IS_ACTIVE[ROLE_VINDICATOR] = function(ply)
    return ply:IsIndependentTeam()
end

function SetVindicatorTeam(independent)
    INDEPENDENT_ROLES[ROLE_VINDICATOR] = independent
    INNOCENT_ROLES[ROLE_VINDICATOR] = not independent

    UpdateRoleColours()

    if SERVER then
        net.Start("TTT_VindicatorTeamChange")
        net.WriteBool(independent)
        net.Broadcast()
    end
end

if CLIENT then
    net.Receive("TTT_VindicatorTeamChange", function()
        local independent = net.ReadBool()
        SetVindicatorTeam(independent)
    end)
end

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_vindicator_announcement_mode", "1", FCVAR_REPLICATED, "Who is notified when the vindicator respawns", 0, 2)
CreateConVar("ttt_vindicator_target_suicide_success", "1", FCVAR_REPLICATED)
CreateConVar("ttt_vindicator_kill_on_fail", "1", FCVAR_REPLICATED)
CreateConVar("ttt_vindicator_kill_on_success", "0", FCVAR_REPLICATED)
