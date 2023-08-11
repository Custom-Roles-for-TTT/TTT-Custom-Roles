AddCSLuaFile()

local util = util
local net = net
local player = player
local hook = hook

local GetAllPlayers = player.GetAll
local AddHook = hook.Add

util.AddNetworkString("TTT_GuesserSelectRole")
util.AddNetworkString("TTT_GuesserGuessed")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_guesser_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a guesser was killed", 0, 4)
CreateConVar("ttt_guesser_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a guesser is killed", 0, 1)
CreateConVar("ttt_guesser_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a guesser is a killed", 0, 1)

local guesser_show_team_threshold = GetConVar("ttt_guesser_show_team_threshold")
local guesser_show_role_threshold = GetConVar("ttt_guesser_show_role_threshold")
local guesser_can_guess_detectives = GetConVar("ttt_guesser_can_guess_detectives")

-------------------
-- ROLE FEATURES --
-------------------

net.Receive("TTT_GuesserSelectRole", function(_, ply)
    if ply:IsActiveGuesser() then
        local role = net.ReadInt(8)
        ply:SetNWInt("TTTGuesserSelection", role)
    end
end)

------------
-- DAMAGE --
------------

AddHook("EntityTakeDamage", "Guesser_EntityTakeDamage", function(ent, dmginfo)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not IsPlayer(ent) then return end
    if not ent:IsGuesser() then return end

    local att = dmginfo:GetAttacker()
    if not IsPlayer(att) then return end

    local role = att:GetRole()

    -- We don't need to reveal the role for players that can't be guessed
    if att:GetNWBool("TTTGuesserWasGuesser", false) or (DETECTIVE_ROLES[role] and not guesser_can_guess_detectives:GetBool()) then
        dmginfo:SetDamage(0)
        return
    end

    local damage = dmginfo:GetDamage()
    local oldDamage = att:GetNWFloat("TTTGuesserDamageDealt", 0)
    local newDamage = oldDamage + damage
    att:SetNWFloat("TTTGuesserDamageDealt", newDamage)

    local team_threshold = guesser_show_team_threshold:GetInt()
    local role_threshold = guesser_show_role_threshold:GetInt()

    if oldDamage < team_threshold and newDamage >= team_threshold and not DETECTIVE_ROLES[role] then
        local message = att:Nick() .. " has damaged you enough for you to learn they are "
        if TRAITOR_ROLES[role] then message = message .. "a Traitor role"
        elseif MONSTER_ROLES[role] then message = message .. "a Monster role"
        elseif JESTER_ROLES[role] then message = message .. "a Jester role"
        elseif INDEPENDENT_ROLES[role] then message = message .. "an Independent role"
        else message = message .. "an Innocent role" end
        ent:QueueMessage(MSG_PRINTBOTH, message)
    end
    if oldDamage < role_threshold and newDamage >= role_threshold then
        if not DETECTIVE_ROLES[role] or GetConVar("ttt_detectives_hide_special_mode"):GetInt() >= SPECIAL_DETECTIVE_HIDE_FOR_ALL then
            ent:QueueMessage(MSG_PRINTBOTH, att:Nick() .. " has damaged you enough for you to learn that they are " .. ROLE_STRINGS_EXT[role])
        end
    end

    dmginfo:SetDamage(0)
end)

-------------
-- CLEANUP --
-------------

AddHook("TTTPrepareRound", "Guesser_TTTPrepareRound", function()
    for _, v in pairs(GetAllPlayers()) do
        v:SetNWInt("TTTGuesserSelection", ROLE_NONE)
        v:SetNWBool("TTTGuesserWasGuesser", false)
        v:SetNWString("TTTGuesserGuessedBy", "")
        v:SetNWFloat("TTTGuesserDamageDealt", 0)
    end
end)