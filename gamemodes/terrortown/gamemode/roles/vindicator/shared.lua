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

hook.Add("TTTIsPlayerRespawning", "Vindicator_TTTIsPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:GetNWBool("VindicatorIsRespawning", false) then
        return true
    end
end)

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

CreateConVar("ttt_vindicator_target_suicide_success", "1", FCVAR_REPLICATED)
CreateConVar("ttt_vindicator_kill_on_fail", "1", FCVAR_REPLICATED)
CreateConVar("ttt_vindicator_kill_on_success", "0", FCVAR_REPLICATED)
CreateConVar("ttt_vindicator_reset_on_success", "0", FCVAR_REPLICATED)
CreateConVar("ttt_vindicator_reset_win_on_success", "0", FCVAR_REPLICATED)
CreateConVar("ttt_vindicator_can_see_jesters", 0, FCVAR_REPLICATED)
CreateConVar("ttt_vindicator_update_scoreboard", 0, FCVAR_REPLICATED)

ROLE_CONVARS[ROLE_VINDICATOR] = {}
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_respawn_delay",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_respawn_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_announcement_mode",
    type = ROLE_CONVAR_TYPE_DROPDOWN,
    choices = {"No one", "The vindicator's killer", "Everyone"},
    isNumeric = true
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_prevent_revival",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_target_suicide_success",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_kill_on_fail",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_kill_on_success",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_reset_on_success",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_reset_win_on_success",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_can_see_jesters",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_VINDICATOR], {
    cvar = "ttt_vindicator_update_scoreboard",
    type = ROLE_CONVAR_TYPE_BOOL
})