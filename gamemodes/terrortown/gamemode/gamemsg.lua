---- Communicating game state to players

local concommand = concommand
local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local math = math
local net = net
local pairs = pairs
local string = string
local table = table

local GetAllPlayers = player.GetAll

-- NOTE: most uses of the Msg functions here have been moved to the LANG
-- functions. These functions are essentially deprecated, though they won't be
-- removed and can safely be used by SWEPs and the like.

function GameMsg(msg)
    net.Start("TTT_GameMsg")
    net.WriteString(msg)
    net.WriteBit(false)
    net.Broadcast()
end

function CustomMsg(ply_or_rf, msg, clr)
    clr = clr or COLOR_WHITE

    net.Start("TTT_GameMsgColor")
    net.WriteString(msg)
    net.WriteUInt(clr.r, 8)
    net.WriteUInt(clr.g, 8)
    net.WriteUInt(clr.b, 8)
    if ply_or_rf then net.Send(ply_or_rf)
    else net.Broadcast() end
end

-- Basic status message to single player or a recipientfilter
function PlayerMsg(ply_or_rf, msg, traitor_only)
    net.Start("TTT_GameMsg")
    net.WriteString(msg)
    net.WriteBit(traitor_only)
    if ply_or_rf then net.Send(ply_or_rf)
    else net.Broadcast() end
end

-- Traitor-specific message that will appear in a special color
function TraitorMsg(ply_or_rfilter, msg)
    PlayerMsg(ply_or_rfilter, msg, true)
end

local function ShouldHideTraitorBeggar()
    local beggarMode = GetGlobalInt("ttt_beggar_reveal_traitor", ANNOUNCE_REVEAL_ALL)
    return beggarMode == ANNOUNCE_REVEAL_NONE or beggarMode == ANNOUNCE_REVEAL_INNOCENTS
end

local function ShouldHideTraitorBodysnatcher()
    local bodysnatcherMode = GetGlobalInt("ttt_bodysnatcher_reveal_traitor", BODYSNATCHER_REVEAL_ALL)
    return bodysnatcherMode == BODYSNATCHER_REVEAL_NONE
end

-- Traitorchat
local function RoleChatMsg(sender, msg)
    net.Start("TTT_RoleChat")
    net.WriteInt(sender:GetRole(), 8)
    net.WriteEntity(sender)
    net.WriteString(msg)
    if sender:IsTraitorTeam() then
        net.Send(GetTraitorTeamFilterWithExcludes())
    elseif sender:IsDetectiveLike() then
        net.Send(GetDetectiveTeamFilter())
    elseif sender:IsMonsterTeam() then
        net.Send(GetMonsterTeamFilter())
    end
end

-- Round start info popup
function ShowRoundStartPopup()
    for _, v in ipairs(GetAllPlayers()) do
        if IsValid(v) and v:Team() == TEAM_TERROR and v:Alive() then
            v:ConCommand("ttt_cl_startpopup")
        end
    end
end

function GetPlayerFilter(pred)
    local filter = {}
    for _, v in ipairs(GetAllPlayers()) do
        if IsValid(v) and pred(v) then
            table.insert(filter, v)
        end
    end
    return filter
end

function GetRoleFilter(role, alive_only)
    return GetPlayerFilter(function(p) return p:IsRole(role) and (not alive_only or p:IsTerror()) end)
end

-- Dynamically generate all the new roles
for role = 0, ROLE_MAX do
    local name = string.gsub(ROLE_STRINGS[role], "%s+", "")
    _G["Get" .. name .. "Filter"] = function(alive_only) return GetRoleFilter(role, alive_only) end
end

function GetTraitorTeamFilter(alive_only)
    return GetPlayerFilter(function(p) return p:IsTraitorTeam() and (not alive_only or p:IsTerror()) end)
end

function GetTraitorTeamFilterWithExcludes(alive_only)
    local hideBeggar = ShouldHideTraitorBeggar()
    local hideBodysnatcher = ShouldHideTraitorBodysnatcher()

    return GetPlayerFilter(function(p)
        if not p:IsTraitorTeam() then return false end
        if alive_only and (not p:Alive() or p:IsSpec()) then return false end

        if hideBeggar and p:IsTraitor() and p:GetNWBool("WasBeggar", false) then return false end
        if hideBodysnatcher and p:GetNWBool("WasBodysnatcher", false) then return false end

        return true
    end)
end

function GetInnocentTeamFilter(alive_only)
    return GetPlayerFilter(function(p) return p:IsInnocentTeam() and (not alive_only or p:IsTerror()) end)
end

function GetJesterTeamFilter(alive_only)
    return GetPlayerFilter(function(p) return p:IsJesterTeam() and (not alive_only or p:IsTerror()) end)
end

function GetIndependentTeamFilter(alive_only)
    return GetPlayerFilter(function(p) return p:IsIndependentTeam() and (not alive_only or p:IsTerror()) end)
end

function GetMonsterTeamFilter(alive_only)
    return GetPlayerFilter(function(p) return p:IsMonsterTeam() and (not alive_only or p:IsTerror()) end)
end

function GetDetectiveTeamFilter(alive_only)
    -- Include promoted Deputies in this, but not Impersonators. They are included in GetTraitorTeamFilter
    return GetPlayerFilter(function(p) return (p:IsDetectiveTeam() or (p:GetDeputy() and p:IsRoleActive())) and (not alive_only or p:IsTerror()) end)
end

---- Communication control
CreateConVar("ttt_limit_spectator_chat", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY)
CreateConVar("ttt_limit_spectator_voice", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY)

function GM:PlayerCanSeePlayersChat(text, team_only, listener, speaker)
    if (not IsValid(listener)) then return false end
    if (not IsValid(speaker)) then
        if isentity(speaker) then
            return true
        else
            return false
        end
    end

    local sTeam = speaker:Team() == TEAM_SPEC
    local lTeam = listener:Team() == TEAM_SPEC

    -- Round isn't active
    if (GetRoundState() ~= ROUND_ACTIVE) or
            -- Spectators can chat freely
            (not GetConVar("ttt_limit_spectator_chat"):GetBool()) or
            -- Mumbling
            (not DetectiveMode()) or
            -- If someone alive talks (and not a special role in teamchat's case)
            (not sTeam and ((team_only and not speaker:IsSpecial()) or (not team_only))) or
            (not sTeam and team_only and speaker:GetRole() == listener:GetRole()) or
            -- If the speaker and listener are spectators
            (sTeam and lTeam) then
        return true
    end

    return false
end

local mumbles = {
    "mumble", "mm", "hmm", "hum", "mum", "mbm", "mble", "ham", "mammaries", "political situation", "mrmm", "hrm",
    "uzbekistan", "mumu", "cheese export", "hmhm", "mmh", "mumble", "mphrrt", "mrh", "hmm", "mumble", "mbmm", "hmml", "mfrrm"
}

-- While a round is active, spectators can only talk among themselves. When they
-- try to speak to all players they could divulge information about who killed
-- them. So we mumblify them. In detective mode, we shut them up entirely.
function GM:PlayerSay(ply, text, team_only)
    if not IsValid(ply) then return text or "" end

    if GetRoundState() == ROUND_ACTIVE then
        local team = ply:Team() == TEAM_SPEC
        if team and not DetectiveMode() then
            local filtered = {}
            for _, v in ipairs(string.Explode(" ", text)) do
                -- grab word characters and whitelisted interpunction
                -- necessary or leetspeek will be used (by trolls especially)
                local word, interp = string.match(v, "(%a*)([%.,;!%?]*)")
                if word ~= "" then
                    table.insert(filtered, mumbles[math.random(1, #mumbles)] .. interp)
                end
            end

            -- make sure we have something to say
            if table.IsEmpty(filtered) then
                table.insert(filtered, mumbles[math.random(1, #mumbles)])
            end

            table.insert(filtered, 1, "[MUMBLED]")
            return table.concat(filtered, " ")
        elseif team_only and not team and (ply:IsTraitorTeam() or ply:IsDetectiveLike() or ply:IsMonsterTeam()) then
            local hasGlitch = false
            for _, v in pairs(GetAllPlayers()) do
                if v:IsGlitch() then hasGlitch = true end
            end
            if ply:IsTraitorTeam() and hasGlitch then
                ply:PrintMessage(HUD_PRINTTALK, "The glitch is scrambling your communications")
                return ""
            elseif ply:IsTraitor() and ply:GetNWBool("WasBeggar", false) and ShouldHideTraitorBeggar() then
                ply:PrintMessage(HUD_PRINTTALK, "You still appear as " .. ROLE_STRINGS_EXT[ROLE_BEGGAR] .. " to " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " so you can't use team chat")
                return ""
            elseif ply:IsTraitorTeam() and ply:GetNWBool("WasBodysnatcher", false) and ShouldHideTraitorBodysnatcher() then
                ply:PrintMessage(HUD_PRINTTALK, "You still appear as " .. ROLE_STRINGS_EXT[ROLE_BODYSNATCHER] .. " to " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " so you can't use team chat")
                return ""
            else
                RoleChatMsg(ply, text)
                return ""
            end
        end
    end

    return text or ""
end

-- Mute players when we are about to run map cleanup, because it might cause
-- net buffer overflows on clients.
local mute_all = false
function MuteForRestart(state)
    mute_all = state
end

local loc_voice = CreateConVar("ttt_locational_voice", "0")

-- Of course voice has to be limited as well
function GM:PlayerCanHearPlayersVoice(listener, speaker)
    -- Enforced silence
    if mute_all or not GetConVar("sv_voiceenable"):GetBool() then
        return false, false
    end

    if (not IsValid(speaker)) or (not IsValid(listener)) or (listener == speaker) then
        return false, false
    end

    -- limited if specific convar is on, or we're in detective mode
    local limit = DetectiveMode() or GetConVar("ttt_limit_spectator_voice"):GetBool()

    -- Spectators should not be heard by living players during round
    if speaker:IsSpec() and (not listener:IsSpec()) and limit and GetRoundState() == ROUND_ACTIVE then
        return false, false
    end

    -- Specific mute
    if listener:IsSpec() and listener.mute_team == speaker:Team() or listener.mute_team == MUTE_ALL then
        return false, false
    end

    -- Specs should not hear each other locationally
    if speaker:IsSpec() and listener:IsSpec() then
        return true, false
    end

    -- Traitors "team" chat by default, non-locationally
    if speaker:IsActiveTraitorTeam() then
        local hasGlitch = false
        for _, v in pairs(GetAllPlayers()) do
            if v:IsGlitch() then hasGlitch = true end
        end

        if speaker.traitor_gvoice then
            return true, loc_voice:GetBool()
        elseif listener:IsActiveTraitorTeam() then
            -- Don't send voice to listener if either one of them was a beggar and the role change is not revealed
            if ((speaker:IsTraitor() and speaker:GetNWBool("WasBeggar", false)) or
                (listener:IsTraitor() and listener:GetNWBool("WasBeggar", false))) and
                ShouldHideTraitorBeggar() then
                return false, false
            end
            -- Do the same for bodysnatchers
            if (speaker:GetNWBool("WasBodysnatcher", false) or
                listener:GetNWBool("WasBodysnatcher", false)) and
                ShouldHideTraitorBodysnatcher() then
                return false, false
            end
            return not hasGlitch, false
        else
            -- unless traitor_gvoice is true, normal innos can't hear speaker
            return false, false
        end
    end

    return true, loc_voice:GetBool() and GetRoundState() ~= ROUND_POST
end

local function SendTraitorVoiceState(speaker, state)
    -- make it as small as possible, to get there as fast as possible
    -- we can fit it into a mere byte by being cheeky.
    net.Start("TTT_TraitorVoiceState")
    net.WriteUInt(speaker:EntIndex() - 1, 7) -- player ids can only be 1-128
    net.WriteBit(state)

    -- send umsg to living traitors that this is traitor-only talk
    net.Send(GetTraitorTeamFilterWithExcludes(true))
end

local function TraitorGlobalVoice(ply, cmd, args)
    if not IsValid(ply) or not ply:IsActiveTraitorTeam() then return end
    if #args ~= 1 then return end
    local state = tonumber(args[1])

    ply.traitor_gvoice = (state == 1)

    local hasGlitch = false
    for _, v in pairs(GetAllPlayers()) do
        if v:IsGlitch() then hasGlitch = true end
    end

    if not ply.traitor_gvoice then
        if hasGlitch then
            ply:PrintMessage(HUD_PRINTTALK, "The glitch is scrambling your communications")
            return
        elseif ply:IsTraitor() and ply:GetNWBool("WasBeggar", false) and ShouldHideTraitorBeggar() then
            ply:PrintMessage(HUD_PRINTTALK, "You still appear as " .. ROLE_STRINGS_EXT[ROLE_BEGGAR] .. " to " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " so you can't use team chat")
            return
        elseif ply:IsTraitorTeam() and ply:GetNWBool("WasBodysnatcher", false) and ShouldHideTraitorBodysnatcher() then
            ply:PrintMessage(HUD_PRINTTALK, "You still appear as " .. ROLE_STRINGS_EXT[ROLE_BODYSNATCHER] .. " to " .. ROLE_STRINGS_PLURAL[ROLE_TRAITOR] .. " so you can't use team chat")
            return
        end
    end

    SendTraitorVoiceState(ply, ply.traitor_gvoice)
end
concommand.Add("tvog", TraitorGlobalVoice)

local function MuteTeam(ply, cmd, args)
    if not IsValid(ply) then return end
    if not (#args == 1 and tonumber(args[1])) then return end
    if not ply:IsSpec() then
        ply.mute_team = -1
        return
    end

    local t = tonumber(args[1])
    ply.mute_team = t

    if t == MUTE_ALL then
        ply:ChatPrint("All muted.")
    elseif t == MUTE_NONE or t == TEAM_UNASSIGNED or not team.Valid(t) then
        ply:ChatPrint("None muted.")
    else
        ply:ChatPrint(team.GetName(t) .. " muted.")
    end
end
concommand.Add("ttt_mute_team", MuteTeam)

local ttt_lastwords = CreateConVar("ttt_lastwords_chatprint", "0")

local LastWordContext = {
    [KILL_NORMAL] = "",
    [KILL_SUICIDE] = " *kills self*",
    [KILL_FALL] = " *SPLUT*",
    [KILL_BURN] = " *crackle*"
};

local function LastWordsMsg(ply, words)
    -- only append "--" if there's no ending interpunction
    local final = string.match(words, "[\\.\\!\\?]$") ~= nil

    -- add optional context relating to death type
    local context = LastWordContext[ply.death_type] or ""

    net.Start("TTT_LastWordsMsg")
    net.WriteEntity(ply)
    net.WriteString(words .. (final and "" or "--") .. context)
    net.Broadcast()
end

local function LastWords(ply, cmd, args)
    if IsValid(ply) and (not ply:Alive()) and #args > 1 then
        local id = tonumber(args[1])
        if id and ply.last_words_id and id == ply.last_words_id then
            -- never allow multiple last word stuff
            ply.last_words_id = nil

            -- we will be storing this on the ragdoll
            local rag = ply.server_ragdoll
            if not (IsValid(rag) and rag.player_ragdoll) then
                rag = nil
            end

            --- last id'd person
            local last_seen = tonumber(args[2])
            if last_seen then
                local ent = Entity(last_seen)
                if IsPlayer(ent) and rag and (not rag.lastid) then
                    rag.lastid = { ent = ent, t = CurTime() }
                end
            end

            --- last words
            local words = string.Trim(args[3])

            -- nothing of interest
            if #words < 2 then return end

            -- ignore admin commands
            local firstchar = string.sub(words, 1, 1)
            if firstchar == "!" or firstchar == "@" or firstchar == "/" then return end

            if ttt_lastwords:GetBool() or ply.death_type == KILL_FALL then
                LastWordsMsg(ply, words)
            end

            if rag and (not rag.last_words) then
                rag.last_words = words
            end
        else
            ply.last_words_id = nil
        end
    end
end
concommand.Add("_deathrec", LastWords)

-- Override or hook in plugin for spam prevention and whatnot. Return true
-- to block a command.
function GM:TTTPlayerRadioCommand(ply, msg_name, msg_target)
    if ply.LastRadioCommand and ply.LastRadioCommand > (CurTime() - 0.5) then return true end
    ply.LastRadioCommand = CurTime()
end

local function RadioCommand(ply, cmd, args)
    if IsValid(ply) and ply:IsTerror() and #args == 2 then
        local msg_name = args[1]
        local msg_target = args[2]

        local name = ""
        local rag_name = nil

        if tonumber(msg_target) then
            -- player or corpse ent idx
            local ent = Entity(tonumber(msg_target))
            if IsValid(ent) then
                if ent:IsPlayer() then
                    name = ent:Nick()
                elseif ent:GetClass() == "prop_ragdoll" then
                    name = LANG.NameParam("quick_corpse_id")
                    rag_name = CORPSE.GetPlayerNick(ent, "A Terrorist")
                end
            end

            msg_target = ent
        else
            -- lang string
            name = LANG.NameParam(msg_target)
        end

        if hook.Call("TTTPlayerRadioCommand", GAMEMODE, ply, msg_name, msg_target) then
            return
        end

        net.Start("TTT_RadioMsg")
        net.WriteEntity(ply)
        net.WriteString(msg_name)
        net.WriteString(name)
        if rag_name then
            net.WriteString(rag_name)
        end
        net.Broadcast()
    end
end
concommand.Add("_ttt_radio_send", RadioCommand)
