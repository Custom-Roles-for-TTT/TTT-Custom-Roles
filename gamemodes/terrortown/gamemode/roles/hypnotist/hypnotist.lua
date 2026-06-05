AddCSLuaFile()

local hook = hook
local IsValid = IsValid
local player = player

local AddHook = hook.Add
local RemoveHook = hook.Remove
local PlayerIterator = player.Iterator

CreateConVar("ttt_hypnotist_brainwash_credits", 0, FCVAR_NONE, "How many credits a hypnotized player should get", 0, 5)
local hypnotist_brainwash_muted = CreateConVar("ttt_hypnotist_brainwash_muted", 0, FCVAR_NONE, "Whether players brainwashed by the hypnotist should be muted", 0, 1)

------------------
-- ROLE WEAPONS --
------------------

-- Only allow the hypnotist to pick up hypnotist-specific weapons
local function Hypnotist_Weapons_PlayerCanPickupWeapon(ply, wep)
    if not IsValid(wep) or not IsValid(ply) then return end
    if ply:IsSpec() then return end

    if wep:GetClass() == "weapon_hyp_brainwash" then
        return ply:IsHypnotist()
    end
end

-------------------
-- ROLE FEATURES --
-------------------

local function Hypnotist_PlayerCanHearPlayersVoice(listener, speaker)
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not IsPlayer(listener) then return end
    if not listener:Alive() or listener:IsSpec() then return end

    if not IsPlayer(speaker) then return end
    if not speaker:IsSpeaking() then return end
    if not speaker:Alive() or speaker:IsSpec() then return end

    if speaker == listener then return end

    if not hypnotist_brainwash_muted:GetBool() then return end
    if not GetConVar("sv_voiceenable"):GetBool() then return end
    if not speaker:GetNWBool("WasHypnotised", false) then return end

    -- Warn them in chat periodically
    if not speaker.NextHypnotistMuteWarning or speaker.NextHypnotistMuteWarning <= CurTime() then
        speaker.NextHypnotistMuteWarning = CurTime() + 1
        speaker:PrintMessage(HUD_PRINTTALK, "You have not yet regained your ability to speak")
    end

    return false, false
end

local function Hypnotist_PlayerSay(ply, text, team_only)
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not IsPlayer(ply) then return end
    if not ply:Alive() or ply:IsSpec() then return end

    if not hypnotist_brainwash_muted:GetBool() then return end
    if not ply:GetNWBool("WasHypnotised", false) then return end

    ply:PrintMessage(HUD_PRINTTALK, "You have not yet regained your ability to speak")
    return ""
end

local function Hypnotist_TTTPlayerRadioCommand(ply, msg_name, msg_target)
    if GetRoundState() ~= ROUND_ACTIVE then return end

    if not IsPlayer(ply) then return end
    if not ply:Alive() or ply:IsSpec() then return end

    if not hypnotist_brainwash_muted:GetBool() then return end
    if not ply:GetNWBool("WasHypnotised", false) then return end

    ply:PrintMessage(HUD_PRINTTALK, "You have not yet regained your ability to speak")
    return true
end

----------------
-- ROLE STATE --
----------------

AddHook("TTTPrepareRound", "Hypnotist_PrepareRound", function()
    for _, v in PlayerIterator() do
        v:SetNWBool("WasHypnotised", false)
        v.NextHypnotistMuteWarning = nil
    end
end)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTER_HOOKS[ROLE_HYPNOTIST] = function()
    AddHook("PlayerCanHearPlayersVoice", "Hypnotist_PlayerCanHearPlayersVoice", Hypnotist_PlayerCanHearPlayersVoice)
    AddHook("PlayerCanPickupWeapon", "Hypnotist_Weapons_PlayerCanPickupWeapon", Hypnotist_Weapons_PlayerCanPickupWeapon)
    AddHook("PlayerSay", "Hypnotist_PlayerSay", Hypnotist_PlayerSay)
    AddHook("TTTPlayerRadioCommand", "Hypnotist_TTTPlayerRadioCommand", Hypnotist_TTTPlayerRadioCommand)
end

ROLE_UNREGISTER_HOOKS[ROLE_HYPNOTIST] = function()
    RemoveHook("PlayerCanHearPlayersVoice", "Hypnotist_PlayerCanHearPlayersVoice")
    RemoveHook("PlayerCanPickupWeapon", "Hypnotist_Weapons_PlayerCanPickupWeapon")
    RemoveHook("PlayerSay", "Hypnotist_PlayerSay")
    RemoveHook("TTTPlayerRadioCommand", "Hypnotist_TTTPlayerRadioCommand")
end