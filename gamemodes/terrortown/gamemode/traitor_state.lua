function GetTraitors()
    local trs = {}
    for k, v in ipairs(player.GetAll()) do
        if v:GetTraitor() then table.insert(trs, v) end
    end

    return trs
end

function CountTraitors() return #GetTraitors() end

---- Role state communication

-- Send every player their role
local function SendPlayerRoles()
    for k, v in ipairs(player.GetAll()) do
        net.Start("TTT_Role")
        net.WriteUInt(v:GetRole(), 8)
        net.Send(v)
    end
end

local function SendRoleListMessage(role, role_ids, ply_or_rf)
    net.Start("TTT_RoleList")
    net.WriteUInt(role, 8)

    -- list contents
    local num_ids = #role_ids
    net.WriteUInt(num_ids, 8)
    for i = 1, num_ids do
        net.WriteUInt(role_ids[i] - 1, 7)
    end

    if ply_or_rf then net.Send(ply_or_rf)
    else net.Broadcast() end
end

local function SendRoleList(role, ply_or_rf, pred)
    local role_ids = {}
    for k, v in ipairs(player.GetAll()) do
        if v:IsRole(role) then
            if not pred or (pred and pred(v)) then
                table.insert(role_ids, v:EntIndex())
            end
        end
    end

    SendRoleListMessage(role, role_ids, ply_or_rf)
end

-- Tell traitors about other traitors

function SendTraitorList(ply_or_rf) SendRoleList(ROLE_TRAITOR, ply_or_rf) end
function SendDetectiveList(ply_or_rf) SendRoleList(ROLE_DETECTIVE, ply_or_rf) end
function SendInnocentList(ply_or_rf) SendRoleList(ROLE_INNOCENT, ply_or_rf) end
function SendJesterList(ply_or_rf) SendRoleList(ROLE_JESTER, ply_or_rf) end
function SendSwapperList(ply_or_rf) SendRoleList(ROLE_SWAPPER, ply_or_rf) end
function SendGlitchList(ply_or_rf) SendRoleList(ROLE_GLITCH, ply_or_rf) end
function SendPhantomList(ply_or_rf) SendRoleList(ROLE_PHANTOM, ply_or_rf) end
function SendHypnotistList(ply_or_rf) SendRoleList(ROLE_HYPNOTIST, ply_or_rf) end
function SendRomanticList(ply_or_rf) SendRoleList(ROLE_ROMANTIC, ply_or_rf) end
function SendDrunkList(ply_or_rf) SendRoleList(ROLE_DRUNK, ply_or_rf) end
function SendClownList(ply_or_rf) SendRoleList(ROLE_CLOWN, ply_or_rf) end
function SendDeputyList(ply_or_rf) SendRoleList(ROLE_DEPUTY, ply_or_rf) end
function SendImpersonatorList(ply_or_rf) SendRoleList(ROLE_IMPERSONATOR, ply_or_rf) end
function SendBeggarList(ply_or_rf) SendRoleList(ROLE_BEGGAR, ply_or_rf) end

function SendConfirmedTraitors(ply_or_rf)
    SendTraitorList(ply_or_rf, function(p) return p:GetNWBool("body_searched") end)
end

function SendFullStateUpdate()
    SendPlayerRoles()
    SendInnocentList()
    SendTraitorList()
    SendDetectiveList()
    SendJesterList()
    SendSwapperList()
    SendGlitchList()
    SendPhantomList()
    SendHypnotistList()
    SendRomanticList()
    SendDrunkList()
    SendClownList()
    SendDeputyList()
    SendImpersonatorList()
    SendBeggarList()
    -- not useful to sync confirmed traitors here
end

function SendRoleReset(ply_or_rf)
    local plys = player.GetAll()

    net.Start("TTT_RoleList")
    net.WriteUInt(ROLE_INNOCENT, 8)

    net.WriteUInt(#plys, 8)
    for k, v in ipairs(plys) do
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
        SendInnocentList(ply)
        SendTraitorList(ply)
        SendDetectiveList(ply)
        SendJesterList(ply)
        SendSwapperList(ply)
        SendGlitchList(ply)
        SendPhantomList(ply)
        SendHypnotistList(ply)
        SendRomanticList(ply)
        SendDrunkList(ply)
        SendClownList(ply)
        SendDeputyList(ply)
        SendImpersonatorList(ply)
        SendBeggarList(ply)
    end
end
concommand.Add("_ttt_request_rolelist", request_rolelist)

local function force_terror(ply)
    ply:SetRole(ROLE_INNOCENT)
    ply:UnSpectate()
    ply:SetTeam(TEAM_TERROR)

    ply:StripAll()

    ply:Spawn()
    ply:PrintMessage(HUD_PRINTTALK, "You are now on the terrorist team.")

    SendFullStateUpdate()
end
concommand.Add("ttt_force_terror", force_terror, nil, nil, FCVAR_CHEAT)

local function force_innocent(ply)
    ply:SetRole(ROLE_INNOCENT)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_innocent", force_innocent, nil, nil, FCVAR_CHEAT)

local function force_traitor(ply)
    ply:SetRole(ROLE_TRAITOR)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_traitor", force_traitor, nil, nil, FCVAR_CHEAT)

local function force_detective(ply)
    ply:SetRole(ROLE_DETECTIVE)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_detective", force_detective, nil, nil, FCVAR_CHEAT)

local function force_jester(ply)
    ply:SetRole(ROLE_JESTER)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_jester", force_jester, nil, nil, FCVAR_CHEAT)

local function force_swapper(ply)
    ply:SetRole(ROLE_SWAPPER)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_swapper", force_swapper, nil, nil, FCVAR_CHEAT)

local function force_glitch(ply)
    ply:SetRole(ROLE_GLITCH)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_glitch", force_glitch, nil, nil, FCVAR_CHEAT)

local function force_phantom(ply)
    ply:SetRole(ROLE_PHANTOM)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_phantom", force_phantom, nil, nil, FCVAR_CHEAT)

local function force_hypnotist(ply)
    ply:SetRole(ROLE_HYPNOTIST)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    ply:Give("weapon_ttt_brainwash")
    SendFullStateUpdate()
end
concommand.Add("ttt_force_hypnotist", force_hypnotist, nil, nil, FCVAR_CHEAT)

local function force_romantic(ply)
    ply:SetRole(ROLE_ROMANTIC)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_romantic", force_romantic, nil, nil, FCVAR_CHEAT)

local function force_drunk(ply)
    ply:SetRole(ROLE_DRUNK)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_drunk", force_drunk, nil, nil, FCVAR_CHEAT)

local function force_clown(ply)
    ply:SetRole(ROLE_CLOWN)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_clown", force_clown, nil, nil, FCVAR_CHEAT)

local function force_deputy(ply)
    ply:SetRole(ROLE_DEPUTY)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_deputy", force_deputy, nil, nil, FCVAR_CHEAT)

local function force_impersonator(ply)
    ply:SetRole(ROLE_IMPERSONATOR)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_impersonator", force_impersonator, nil, nil, FCVAR_CHEAT)

local function force_beggar(ply)
    ply:SetRole(ROLE_BEGGAR)
    if ply:HasWeapon("weapon_ttt_brainwash") then
        ply:StripWeapon("weapon_ttt_brainwash")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_beggar", force_beggar, nil, nil, FCVAR_CHEAT)

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
