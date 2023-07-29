AddCSLuaFile()

local net = net

-------------------
-- ROLE FEATURES --
-------------------

ROLE_IS_ACTIVE[ROLE_TURNCOAT] = function(ply)
    return ply:IsTraitorTeam()
end

function SetTurncoatTeam(ply, traitor)
    TRAITOR_ROLES[ROLE_TURNCOAT] = traitor
    INNOCENT_ROLES[ROLE_TURNCOAT] = not traitor

    UpdateRoleColours()

    if SERVER then
        net.Start("TTT_TurncoatTeamChange")
        net.WriteBool(traitor)
        if traitor then
            net.WriteString(ply:Nick())
        end
        net.Broadcast()
        hook.Call("TTTTurncoatTeamChanged", nil, ply, traitor)
    end
end

if CLIENT then
    net.Receive("TTT_TurncoatTeamChange", function()
        local traitor = net.ReadBool()
        if traitor then
            local nick = net.ReadString()
            CLSCORE:AddEvent({
                id = EVENT_TURNCOATCHANGED,
                nic = nick
            })
        end

        SetTurncoatTeam(nil, traitor)
    end)
end

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_turncoat_change_health", "10", FCVAR_REPLICATED, "The amount of health to set the turncoat to when they change teams", 1, 200)
CreateConVar("ttt_turncoat_change_innocent_kill", "0", FCVAR_REPLICATED, "Whether to change the turncoat's team when they kill a member of the innocent team", 0, 1)

ROLE_CONVARS[ROLE_TURNCOAT] = {}
table.insert(ROLE_CONVARS[ROLE_TURNCOAT], {
    cvar = "ttt_turncoat_change_max_health",
    type = ROLE_CONVAR_TYPE_BOOL
})
table.insert(ROLE_CONVARS[ROLE_TURNCOAT], {
    cvar = "ttt_turncoat_change_health",
    type = ROLE_CONVAR_TYPE_NUM,
    decimal = 0
})
table.insert(ROLE_CONVARS[ROLE_TURNCOAT], {
    cvar = "ttt_turncoat_change_innocent_kill",
    type = ROLE_CONVAR_TYPE_BOOL
})