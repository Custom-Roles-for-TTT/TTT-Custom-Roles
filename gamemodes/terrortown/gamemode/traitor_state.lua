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
function SendJesterList(ply_or_rf) SendRoleList(ROLE_JESTER, ply_or_rf) end
function SendSwapperList(ply_or_rf) SendRoleList(ROLE_SWAPPER, ply_or_rf) end
function SendGlitchList(ply_or_rf) SendRoleList(ROLE_GLITCH, ply_or_rf) end
function SendPhantomList(ply_or_rf) SendRoleList(ROLE_PHANTOM, ply_or_rf) end
function SendHypnotistList(ply_or_rf) SendRoleList(ROLE_HYPNOTIST, ply_or_rf) end
function SendRevengerList(ply_or_rf) SendRoleList(ROLE_REVENGER, ply_or_rf) end
function SendDrunkList(ply_or_rf) SendRoleList(ROLE_DRUNK, ply_or_rf) end
function SendClownList(ply_or_rf) SendRoleList(ROLE_CLOWN, ply_or_rf) end
function SendDeputyList(ply_or_rf) SendRoleList(ROLE_DEPUTY, ply_or_rf) end
function SendImpersonatorList(ply_or_rf) SendRoleList(ROLE_IMPERSONATOR, ply_or_rf) end
function SendBeggarList(ply_or_rf) SendRoleList(ROLE_BEGGAR, ply_or_rf) end
function SendOldManList(ply_or_rf) SendRoleList(ROLE_OLDMAN, ply_or_rf) end
function SendMercenaryList(ply_or_rf) SendRoleList(ROLE_MERCENARY, ply_or_rf) end
function SendBodysnatcherList(ply_or_rf) SendRoleList(ROLE_BODYSNATCHER, ply_or_rf) end
function SendVeteranList(ply_or_rf) SendRoleList(ROLE_VETERAN, ply_or_rf) end
function SendAssassinList(ply_or_rf) SendRoleList(ROLE_ASSASSIN, ply_or_rf) end
function SendKillerList(ply_or_rf) SendRoleList(ROLE_KILLER, ply_or_rf) end
function SendZombieList(ply_or_rf) SendRoleList(ROLE_ZOMBIE, ply_or_rf) end
function SendVampireList(ply_or_rf) SendRoleList(ROLE_VAMPIRE, ply_or_rf) end
function SendDoctorList(ply_or_rf) SendRoleList(ROLE_DOCTOR, ply_or_rf) end
function SendQuackList(ply_or_rf) SendRoleList(ROLE_QUACK, ply_or_rf) end
function SendParasiteList(ply_or_rf) SendRoleList(ROLE_PARASITE, ply_or_rf) end
function SendTricksterList(ply_or_rf) SendRoleList(ROLE_TRICKSTER, ply_or_rf) end

function SendAllLists(ply_or_rf)
    SendInnocentList(ply_or_rf)
    SendTraitorList(ply_or_rf)
    SendDetectiveList(ply_or_rf)
    SendJesterList(ply_or_rf)
    SendSwapperList(ply_or_rf)
    SendGlitchList(ply_or_rf)
    SendPhantomList(ply_or_rf)
    SendHypnotistList(ply_or_rf)
    SendRevengerList(ply_or_rf)
    SendDrunkList(ply_or_rf)
    SendClownList(ply_or_rf)
    SendDeputyList(ply_or_rf)
    SendImpersonatorList(ply_or_rf)
    SendBeggarList(ply_or_rf)
    SendOldManList(ply_or_rf)
    SendMercenaryList(ply_or_rf)
    SendBodysnatcherList(ply_or_rf)
    SendVeteranList(ply_or_rf)
    SendAssassinList(ply_or_rf)
    SendKillerList(ply_or_rf)
    SendZombieList(ply_or_rf)
    SendVampireList(ply_or_rf)
    SendDoctorList(ply_or_rf)
    SendQuackList(ply_or_rf)
    SendParasiteList(ply_or_rf)
    SendTricksterList(ply_or_rf)
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

local function force_innocent(ply)
    ply:SetRoleAndBroadcast(ROLE_INNOCENT)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_innocent", force_innocent, nil, nil, FCVAR_CHEAT)

local function force_traitor(ply)
    ply:SetRoleAndBroadcast(ROLE_TRAITOR)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_traitor", force_traitor, nil, nil, FCVAR_CHEAT)

local function force_detective(ply)
    ply:SetRoleAndBroadcast(ROLE_DETECTIVE)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_detective", force_detective, nil, nil, FCVAR_CHEAT)

local function force_jester(ply)
    ply:SetRoleAndBroadcast(ROLE_JESTER)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_jester", force_jester, nil, nil, FCVAR_CHEAT)

local function force_swapper(ply)
    ply:SetRoleAndBroadcast(ROLE_SWAPPER)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_swapper", force_swapper, nil, nil, FCVAR_CHEAT)

local function force_glitch(ply)
    ply:SetRoleAndBroadcast(ROLE_GLITCH)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_glitch", force_glitch, nil, nil, FCVAR_CHEAT)

local function force_phantom(ply)
    ply:SetRoleAndBroadcast(ROLE_PHANTOM)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_phantom", force_phantom, nil, nil, FCVAR_CHEAT)

local function force_hypnotist(ply)
    ply:SetRoleAndBroadcast(ROLE_HYPNOTIST)
    clear_role_effects(ply)
    ply:Give("weapon_hyp_brainwash")
    SendFullStateUpdate()
end
concommand.Add("ttt_force_hypnotist", force_hypnotist, nil, nil, FCVAR_CHEAT)

local function force_revenger(ply)
    ply:SetRoleAndBroadcast(ROLE_REVENGER)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_revenger", force_revenger, nil, nil, FCVAR_CHEAT)

local function force_drunk(ply)
    ply:SetRoleAndBroadcast(ROLE_DRUNK)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_drunk", force_drunk, nil, nil, FCVAR_CHEAT)

local function force_clown(ply)
    ply:SetRoleAndBroadcast(ROLE_CLOWN)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_clown", force_clown, nil, nil, FCVAR_CHEAT)

local function force_deputy(ply)
    ply:SetRoleAndBroadcast(ROLE_DEPUTY)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_deputy", force_deputy, nil, nil, FCVAR_CHEAT)

local function force_impersonator(ply)
    ply:SetRoleAndBroadcast(ROLE_IMPERSONATOR)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_impersonator", force_impersonator, nil, nil, FCVAR_CHEAT)

local function force_beggar(ply)
    ply:SetRoleAndBroadcast(ROLE_BEGGAR)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_beggar", force_beggar, nil, nil, FCVAR_CHEAT)

local function force_oldman(ply)
    ply:SetRoleAndBroadcast(ROLE_OLDMAN)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_oldman", force_oldman, nil, nil, FCVAR_CHEAT)

local function force_mercenary(ply)
    ply:SetRoleAndBroadcast(ROLE_MERCENARY)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_mercenary", force_mercenary, nil, nil, FCVAR_CHEAT)

local function force_bodysnatcher(ply)
    ply:SetRoleAndBroadcast(ROLE_BODYSNATCHER)
    clear_role_effects(ply)
    ply:Give("weapon_bod_bodysnatch")
    SendFullStateUpdate()
end
concommand.Add("ttt_force_bodysnatcher", force_bodysnatcher, nil, nil, FCVAR_CHEAT)

local function force_veteran(ply)
    ply:SetRoleAndBroadcast(ROLE_VETERAN)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_veteran", force_veteran, nil, nil, FCVAR_CHEAT)

local function force_assassin(ply)
    ply:SetRoleAndBroadcast(ROLE_ASSASSIN)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_assassin", force_assassin, nil, nil, FCVAR_CHEAT)

local function force_killer(ply)
    ply:SetRoleAndBroadcast(ROLE_KILLER)
    clear_role_effects(ply)
    ply:StripWeapon("weapon_zm_improvised")
    ply:Give("weapon_kil_crowbar")
    ply:Give("weapon_kil_knife")
    SendFullStateUpdate()
end
concommand.Add("ttt_force_killer", force_killer, nil, nil, FCVAR_CHEAT)

local function force_zombie(ply)
    ply:SetRoleAndBroadcast(ROLE_ZOMBIE)
    clear_role_effects(ply)
    ply:Give("weapon_zom_claws")
    SendFullStateUpdate()
end
concommand.Add("ttt_force_zombie", force_zombie, nil, nil, FCVAR_CHEAT)

local function force_vampire(ply)
    ply:SetRoleAndBroadcast(ROLE_VAMPIRE)
    clear_role_effects(ply)
    ply:Give("weapon_vam_fangs")
    SendFullStateUpdate()
end
concommand.Add("ttt_force_vampire", force_vampire, nil, nil, FCVAR_CHEAT)

local function force_doctor(ply)
    ply:SetRoleAndBroadcast(ROLE_DOCTOR)
    clear_role_effects(ply)
    local mode = GetConVar("ttt_doctor_mode"):GetInt()
    if mode == DOCTOR_MODE_STATION then
        ply:Give("weapon_ttt_health_station")
    elseif mode == DOCTOR_MODE_EMT then
        ply:Give("weapon_doc_defib")
    end
    SendFullStateUpdate()
end
concommand.Add("ttt_force_doctor", force_doctor, nil, nil, FCVAR_CHEAT)

local function force_quack(ply)
    ply:SetRoleAndBroadcast(ROLE_QUACK)
    clear_role_effects(ply)
    ply:Give("weapon_qua_bomb_station")
    SendFullStateUpdate()
end
concommand.Add("ttt_force_quack", force_quack, nil, nil, FCVAR_CHEAT)

local function force_parasite(ply)
    ply:SetRoleAndBroadcast(ROLE_PARASITE)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_parasite", force_parasite, nil, nil, FCVAR_CHEAT)

local function force_trickster(ply)
    ply:SetRoleAndBroadcast(ROLE_TRICKSTER)
    clear_role_effects(ply)
    SendFullStateUpdate()
end
concommand.Add("ttt_force_trickster", force_trickster, nil, nil, FCVAR_CHEAT)

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
