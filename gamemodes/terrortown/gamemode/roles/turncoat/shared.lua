AddCSLuaFile()

local net = net

-------------------
-- ROLE FEATURES --
-------------------

function SetTurncoatTeam(nick, traitor)
    if SERVER then
        net.Start("TTT_TurncoatTeamChange")
        net.WriteBool(traitor)
        if traitor then
            net.WriteString(nick)
        end
        net.Broadcast()
    end

    TRAITOR_ROLES[ROLE_TURNCOAT] = traitor
    INNOCENT_ROLES[ROLE_TURNCOAT] = not traitor

    UpdateRoleColours()
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