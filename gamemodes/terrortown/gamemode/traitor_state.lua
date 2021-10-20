function GetTraitors()
    local trs = {}
    for _, v in ipairs(player.GetAll()) do
        if v:IsTraitorTeam() then table.insert(trs, v) end
    end

    return trs
end

function CountTraitors() return #GetTraitors() end

---- Role state communication

-- Send every player their role
local function SendPlayerRoles()
    for _, v in ipairs(player.GetAll()) do
        net.Start("TTT_Role")
        net.WriteInt(v:GetRole(), 8)
        net.Send(v)
    end
end

local function SendRoleListMessage(role, role_ids, ply_or_rf)
    net.Start("TTT_RoleList")
    net.WriteInt(role, 8)

    -- list contents
    local num_ids = #role_ids
    net.WriteUInt(num_ids, 8)
    for i = 1, num_ids do
        net.WriteUInt(role_ids[i] - 1, 7)
    end

    if ply_or_rf then net.Send(ply_or_rf)
    else net.Broadcast() end
end

function SendRoleList(role, ply_or_rf, pred)
    local role_ids = {}
    for _, v in ipairs(player.GetAll()) do
        if v:IsRole(role) then
            if not pred or (pred and pred(v)) then
                table.insert(role_ids, v:EntIndex())
            end
        end
    end

    SendRoleListMessage(role, role_ids, ply_or_rf)
end

-- Tell traitors about other traitors

function SendTraitorList(ply_or_rf, pred) SendRoleList(ROLE_TRAITOR, ply_or_rf, pred) end
function SendDetectiveList(ply_or_rf) SendRoleList(ROLE_DETECTIVE, ply_or_rf) end
function SendInnocentList(ply_or_rf) SendRoleList(ROLE_INNOCENT, ply_or_rf) end

function SendAllLists(ply_or_rf)
    for role = ROLE_NONE, ROLE_MAX do
        SendRoleList(role, ply_or_rf)
    end
end

function SendConfirmedTraitors(ply_or_rf)
    SendTraitorList(ply_or_rf, function(p) return p:GetNWBool("body_searched") end)
end

function SendFullStateUpdate()
    SendPlayerRoles()
    SendAllLists()
end

function SendRoleReset(ply_or_rf)
    local plys = player.GetAll()

    net.Start("TTT_RoleList")
    net.WriteInt(ROLE_INNOCENT, 8)

    net.WriteUInt(#plys, 8)
    for _, v in ipairs(plys) do
        net.WriteUInt(v:EntIndex() - 1, 7)
    end

    if ply_or_rf then net.Send(ply_or_rf)
    else net.Broadcast() end
end

---- Console commands

local function request_rolelist(ply)
    -- Client requested a state update. Note that the client can only use this
    -- information after entities have been initialised (e.g. in InitPostEntity).
    if GetRoundState() ~= ROUND_WAIT then

        SendRoleReset(ply)
        SendAllLists(ply)
    end
end
concommand.Add("_ttt_request_rolelist", request_rolelist)

local function force_terror(ply)
    ply:SetRoleAndBroadcast(ROLE_INNOCENT)
    ply:SetCredits(0)
    ply:UnSpectate()
    ply:SetTeam(TEAM_TERROR)

    ply:StripAll()

    ply:Spawn()
    ply:PrintMessage(HUD_PRINTTALK, "You are now on the terrorist team.")

    SendFullStateUpdate()
end
concommand.Add("ttt_force_terror", force_terror, nil, nil, FCVAR_CHEAT)

local function clear_role_effects(ply)
    ply:StripRoleWeapons()
    ply:Give("weapon_zm_improvised")
    ply:SetDefaultCredits()
    SetRoleHealth(ply)
end

for role = 0, ROLE_MAX do
    local rolestring = ROLE_STRINGS_RAW[role]
    concommand.Add("ttt_force_" .. rolestring, function(ply)
        ply:SetRoleAndBroadcast(role)
        clear_role_effects(ply)
        -- Give loadout weapons
        hook.Run("PlayerLoadout", ply)
        SendFullStateUpdate()
    end, nil, nil, FCVAR_CHEAT)
end

local function force_spectate(ply, cmd, arg)
    if IsValid(ply) then
        if #arg == 1 and tonumber(arg[1]) == 0 then
            ply:SetForceSpec(false)
        else
            if not ply:IsSpec() then
                ply:Kill()
            end

            GAMEMODE:PlayerSpawnAsSpectator(ply)
            ply:SetTeam(TEAM_SPEC)
            ply:SetForceSpec(true)
            ply:Spawn()

            ply:SetRagdollSpec(false) -- dying will enable this, we don't want it here
        end
    end
end
concommand.Add("ttt_spectate", force_spectate)
net.Receive("TTT_Spectate", function(l, pl)
    force_spectate(pl, nil, { net.ReadBool() and 1 or 0 })
end)
